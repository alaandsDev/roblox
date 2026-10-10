local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Modelos = require(ReplicatedStorage.Shared.Modelos)
local Dados = require(script.Parent.Dados)
local Mundo = require(script.Parent.Mundo)
local Ranking = require(script.Parent.Ranking)
local Conquistas = require(script.Parent.Conquistas)

local remotes = Dados.remotes
local data = Dados.data
local sync = Dados.sync
local notificar = Dados.notificar
local temPasse = Dados.temPasse
local efeito = Dados.efeito

Dados.aoSincronizar = Conquistas.verificar

local ultimoClique: { [Player]: number } = {}
local ultimaAcao: { [Player]: number } = {}
local toquesParede: { [Player]: { [BasePart]: number } } = {}
local inicioSessao: { [Player]: number } = {}
-- Chaves em texto para o JSON virar objeto, não lista
local presentesColetados: { [Player]: { [string]: boolean } } = {}

-- Personagem: velocidade, escudo no braço, aura ---------------------------------

local function atualizarPersonagem(player: Player)
	local character = player.Character
	local d = data[player]
	if not character or not d then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local bonus = if temPasse(player, "Velocidade") then Config.VelocidadeGamepass else 0
		humanoid.WalkSpeed = Config.VelocidadeBase + bonus + d.Melhorias.Velocidade * 2
	end

	local antigo = character:FindFirstChild("EscudoVisual")
	if antigo then
		antigo:Destroy()
	end
	local braco = character:FindFirstChild("LeftLowerArm") or character:FindFirstChild("Left Arm")
	local escudo = Config.getEscudo(d.EscudoEquipado)
	if braco and braco:IsA("BasePart") and escudo then
		local modelo = Modelos.clonar("Escudos", escudo.Id)
		if modelo then
			Modelos.ajustarTamanho(modelo, 2.6)
			Modelos.soldar(modelo)
		else
			modelo = Instance.new("Model")
			local disco = Instance.new("Part")
			disco.Shape = Enum.PartType.Cylinder
			disco.Size = Vector3.new(0.3, 2.4, 2.4)
			disco.Color = escudo.Cor
			disco.Material = Enum.Material.Metal
			disco.CanCollide = false
			disco.CanTouch = false
			disco.CanQuery = false
			disco.Massless = true
			disco.Parent = modelo
			modelo.PrimaryPart = disco
		end
		modelo.Name = "EscudoVisual"
		modelo:PivotTo(braco.CFrame * CFrame.new(-0.7, 0, 0))
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = braco
		weld.Part1 = modelo.PrimaryPart
		weld.Parent = modelo.PrimaryPart
		modelo.Parent = character
	end

	local raiz = character:FindFirstChild("HumanoidRootPart")
	if raiz then
		local auraAntiga = raiz:FindFirstChild("Aura")
		if auraAntiga then
			auraAntiga:Destroy()
		end
		local aura = Config.getAura(d.AuraEquipada)
		if aura then
			local particulas = Instance.new("ParticleEmitter")
			particulas.Name = "Aura"
			particulas.Color = ColorSequence.new(aura.Cor)
			particulas.LightEmission = 1
			particulas.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.6),
				NumberSequenceKeypoint.new(1, 0),
			})
			particulas.Transparency = NumberSequence.new(0.2)
			particulas.Lifetime = NumberRange.new(0.8, 1.2)
			particulas.Rate = 40
			particulas.Speed = NumberRange.new(2, 4)
			particulas.SpreadAngle = Vector2.new(180, 180)
			particulas.Parent = raiz
		end
	end
end

local function irParaMundo(player: Player)
	local character = player.Character
	local d = data[player]
	if character and d then
		character:PivotTo(Mundo.spawn(d.Mundo))
	end
end

-- Ações vindas do cliente ---------------------------------------------------------
-- Cada ação recebe (player, dados, ...) e retorna true se algo mudou.

local acoes = {}

function acoes.Click(player, d)
	local agora = os.clock()
	if agora - (ultimoClique[player] or 0) < Config.ClickCooldown then
		return false
	end
	ultimoClique[player] = agora

	d.Armadura += Dados.ganhoPorClique(player, d)
	d.XP += 1
	while d.XP >= Config.xpParaNivel(d.Nivel) do
		d.XP -= Config.xpParaNivel(d.Nivel)
		d.Nivel += 1
	end
	Dados.contarTutorial(d, "Clique", 1)
	return true
end

function acoes.ComprarEscudo(player, d, id)
	local escudo = typeof(id) == "string" and Config.getEscudo(id)
	if not escudo or d.Escudos[escudo.Id] or d.Vitorias < escudo.Custo then
		return false
	end
	d.Vitorias -= escudo.Custo
	d.Escudos[escudo.Id] = true
	d.EscudoEquipado = escudo.Id
	Dados.contarTutorial(d, "Escudo", 1)
	atualizarPersonagem(player)
	efeito(player, "Compra")
	return true
end

function acoes.EquiparEscudo(player, d, id)
	if typeof(id) ~= "string" or not d.Escudos[id] or not Config.getEscudo(id) then
		return false
	end
	d.EscudoEquipado = id
	atualizarPersonagem(player)
	return true
end

function acoes.Rebirth(player, d)
	if d.Nivel < Config.nivelParaRebirth(d.Rebirths) then
		return false
	end
	d.Rebirths += 1
	d.Armadura = 0
	d.Vitorias = 0
	d.Nivel = 1
	d.XP = 0
	notificar(player, `Rebirth! Agora você tem x{1 + d.Rebirths * Config.BonusPorRebirth} de bônus`)
	efeito(player, "Rebirth")
	return true
end

function acoes.AbrirOvo(player, d, id)
	local ovo = typeof(id) == "string" and Config.getOvo(id)
	if not ovo or d.MundoMax < ovo.Mundo then
		return false
	end
	if d.Vitorias < ovo.Custo then
		notificar(player, "Vitórias insuficientes!")
		return false
	end
	if #d.Pets >= Config.MaxPets then
		notificar(player, "Inventário de pets cheio! Apague ou funda alguns.")
		return false
	end
	d.Vitorias -= ovo.Custo
	return Dados.chocarOvo(player, d, ovo.Id)
end

local function indicePet(d, id): number?
	for i, pet in d.Pets do
		if pet.Id == id then
			return i
		end
	end
	return nil
end

function acoes.EquiparPet(player, d, id)
	if not indicePet(d, id) or table.find(d.PetsEquipados, id) then
		return false
	end
	if #d.PetsEquipados >= Dados.maxEquipados(player, d) then
		notificar(player, "Todos os espaços de pet estão ocupados!")
		return false
	end
	table.insert(d.PetsEquipados, id)
	return true
end

function acoes.DesequiparPet(_player, d, id)
	local i = table.find(d.PetsEquipados, id)
	if not i then
		return false
	end
	table.remove(d.PetsEquipados, i)
	return true
end

function acoes.EquiparMelhores(player, d)
	local ordenados = table.clone(d.Pets)
	table.sort(ordenados, function(a, b)
		return Config.bonusPet(a.Tipo, a.Dourado) > Config.bonusPet(b.Tipo, b.Dourado)
	end)
	d.PetsEquipados = {}
	for i = 1, math.min(#ordenados, Dados.maxEquipados(player, d)) do
		table.insert(d.PetsEquipados, ordenados[i].Id)
	end
	return true
end

function acoes.ApagarPet(_player, d, id)
	local i = indicePet(d, id)
	if not i then
		return false
	end
	table.remove(d.Pets, i)
	local e = table.find(d.PetsEquipados, id)
	if e then
		table.remove(d.PetsEquipados, e)
	end
	return true
end

-- Junta FusaoQuantidade pets iguais (não dourados) em 1 dourado
function acoes.FundirPet(player, d, tipo)
	if typeof(tipo) ~= "string" or not Config.Pets[tipo] then
		return false
	end
	local usados = {}
	-- Prefere usar os que não estão equipados
	for _, equipado in { false, true } do
		for _, pet in d.Pets do
			if #usados < Config.FusaoQuantidade and pet.Tipo == tipo and not pet.Dourado then
				if (table.find(d.PetsEquipados, pet.Id) ~= nil) == equipado then
					table.insert(usados, pet.Id)
				end
			end
		end
	end
	if #usados < Config.FusaoQuantidade then
		notificar(player, `Precisa de {Config.FusaoQuantidade} {Config.Pets[tipo].Nome} iguais para fundir`)
		return false
	end
	for _, id in usados do
		acoes.ApagarPet(player, d, id)
	end
	local novo = { Id = tostring(d.ProximoPetId), Tipo = tipo, Dourado = true }
	d.ProximoPetId += 1
	table.insert(d.Pets, novo)
	if #d.PetsEquipados < Dados.maxEquipados(player, d) then
		table.insert(d.PetsEquipados, novo.Id)
	end
	notificar(player, `✨ {Config.Pets[tipo].Nome} Dourado criado!`)
	efeito(player, "Rebirth")
	return true
end

function acoes.ComprarAura(player, d, id)
	local aura = typeof(id) == "string" and Config.getAura(id)
	if not aura or d.Auras[aura.Id] or d.Vitorias < aura.Custo then
		return false
	end
	d.Vitorias -= aura.Custo
	d.Auras[aura.Id] = true
	d.AuraEquipada = aura.Id
	atualizarPersonagem(player)
	efeito(player, "Compra")
	return true
end

function acoes.EquiparAura(player, d, id)
	if id == "" then
		d.AuraEquipada = ""
	elseif typeof(id) == "string" and d.Auras[id] then
		d.AuraEquipada = id
	else
		return false
	end
	atualizarPersonagem(player)
	return true
end

function acoes.ComprarMundo(player, d, indice)
	local mundo = typeof(indice) == "number" and Config.Mundos[indice]
	-- Só dá para liberar o próximo mundo da sequência
	if not mundo or indice ~= d.MundoMax + 1 or d.Vitorias < mundo.Custo then
		return false
	end
	d.Vitorias -= mundo.Custo
	d.MundoMax = indice
	d.Mundo = indice
	irParaMundo(player)
	notificar(player, `Bem-vindo ao {mundo.Nome}!`)
	efeito(player, "Rebirth")
	return true
end

function acoes.IrMundo(player, d, indice)
	if typeof(indice) ~= "number" or not Config.Mundos[indice] or indice > d.MundoMax then
		return false
	end
	d.Mundo = indice
	irParaMundo(player)
	return true
end

function acoes.ComprarMelhoria(player, d, id)
	local melhoria = typeof(id) == "string" and Config.getMelhoria(id)
	if not melhoria then
		return false
	end
	local nivel = d.Melhorias[melhoria.Id]
	local custo = Config.custoMelhoria(melhoria.Id, nivel)
	if nivel >= melhoria.Max or d.Vitorias < custo then
		return false
	end
	d.Vitorias -= custo
	d.Melhorias[melhoria.Id] += 1
	atualizarPersonagem(player)
	efeito(player, "Compra")
	return true
end

function acoes.UsarPocao(player, d, id)
	local pocao = typeof(id) == "string" and Config.Pocoes[id]
	if not pocao or d.Pocoes[id] <= 0 then
		return false
	end
	d.Pocoes[id] -= 1
	d.Boosts[id] = math.max(d.Boosts[id], os.time()) + pocao.Minutos * 60
	notificar(player, `🧪 {pocao.Nome} ativada!`)
	return true
end

function acoes.ColetarDiaria(player, d)
	local agora = os.time()
	if agora - d.UltimaDiaria < 20 * 3600 then
		return false
	end
	if agora - d.UltimaDiaria > 48 * 3600 then
		d.SequenciaDiaria = 0
	end
	local recompensa = Config.Diarias[d.SequenciaDiaria % #Config.Diarias + 1]
	d.SequenciaDiaria += 1
	d.UltimaDiaria = agora
	Dados.darRecompensa(player, d, recompensa)
	return true
end

function acoes.ColetarPresente(player, d, indice)
	local presente = typeof(indice) == "number" and Config.Presentes[indice]
	local coletados = presentesColetados[player]
	if not presente or coletados[tostring(indice)] then
		return false
	end
	if os.clock() - inicioSessao[player] < presente.Minutos * 60 then
		return false
	end
	coletados[tostring(indice)] = true
	player:SetAttribute("PresentesColetados", HttpService:JSONEncode(coletados))
	Dados.darRecompensa(player, d, presente.Recompensa)
	return true
end

function acoes.AlternarVitoriasAuto(player)
	if not temPasse(player, "VitoriasAuto") then
		local passe = Config.Gamepasses.VitoriasAuto
		if passe.Id ~= 0 then
			MarketplaceService:PromptGamePassPurchase(player, passe.Id)
		else
			notificar(player, `Configure o ID do gamepass "{passe.Nome}" no Config.luau`)
		end
		return false
	end
	player:SetAttribute("VitoriasAutoLigado", not player:GetAttribute("VitoriasAutoLigado"))
	return false
end

remotes.Acao.OnServerEvent:Connect(function(player, nome, ...)
	local d = data[player]
	local acao = typeof(nome) == "string" and acoes[nome]
	if not d or not acao then
		return
	end
	-- Limite simples contra spam (o Click tem o próprio cooldown)
	if nome ~= "Click" then
		local agora = os.clock()
		if agora - (ultimaAcao[player] or 0) < 0.15 then
			return
		end
		ultimaAcao[player] = agora
	end
	if acao(player, d, ...) then
		sync(player)
	end
end)

-- Paredes e ovos do mapa ----------------------------------------------------------

local function aoAbrirOvo(player: Player, ovoId: string)
	local d = data[player]
	if d and acoes.AbrirOvo(player, d, ovoId) then
		sync(player)
	end
end

for _, parede in Mundo.construir(aoAbrirOvo) do
	parede.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		local d = player and data[player]
		if not d then
			return
		end
		local mundo, indice = parede:GetAttribute("Mundo"), parede:GetAttribute("Indice")
		if d.Armadura < Dados.vidaParede(mundo, indice) then
			return
		end
		local agora = os.clock()
		local toques = toquesParede[player]
		if agora - (toques[parede] or 0) < Config.ParedeCooldown then
			return
		end
		toques[parede] = agora
		Dados.darVitorias(d, Dados.vitoriasParede(player, d, mundo, indice))
		Dados.contarTutorial(d, "Parede", 1)
		efeito(player, "Parede", hit.Position)
		sync(player)
	end)
end

Ranking.iniciar(function(player)
	return data[player]
end)

-- Entrada e saída de jogadores ---------------------------------------------------

local function carregarPasses(player: Player)
	local liberar = RunService:IsStudio() and Config.LiberarPassesNoStudio
	for nome, passe in Config.Gamepasses do
		if liberar then
			player:SetAttribute(`Passe_{nome}`, true)
		elseif passe.Id ~= 0 then
			local ok, possui =
				pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, passe.Id)
			if ok and possui then
				player:SetAttribute(`Passe_{nome}`, true)
			end
		end
	end
end

local function onPlayerAdded(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	for _, name in { "🛡️ Armadura", "🏆 Vitórias", "🔁 Rebirths" } do
		local value = Instance.new("NumberValue")
		value.Name = name
		value.Parent = leaderstats
	end
	leaderstats.Parent = player

	carregarPasses(player)
	local d = Dados.carregar(player)

	-- O jogador pode ter saído enquanto os dados carregavam
	if player.Parent ~= Players then
		Dados.descartarFalha(player)
		return
	end

	data[player] = d
	toquesParede[player] = {}
	inicioSessao[player] = os.clock()
	presentesColetados[player] = {}
	player:SetAttribute("InicioSessao", workspace:GetServerTimeNow())
	player:SetAttribute("PresentesColetados", "{}")

	if d.UltimoLogin > 0 then
		local minutos = math.min((os.time() - d.UltimoLogin) / 60, Config.OfflineMaxMinutos)
		local ganho = math.floor(minutos * Config.OfflineCliquesPorMinuto * Dados.ganhoPorClique(player, d))
		if ganho > 0 then
			d.Armadura += ganho
			task.delay(3, notificar, player, `Você ganhou {ganho} 🛡️ enquanto estava offline!`)
		end
	end

	sync(player)
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("HumanoidRootPart")
		task.wait()
		irParaMundo(player)
		atualizarPersonagem(player)
	end)
	if player.Character then
		irParaMundo(player)
		atualizarPersonagem(player)
	end
end

local function onPlayerRemoving(player: Player)
	Dados.salvar(player)
	Dados.remover(player)
	ultimoClique[player] = nil
	ultimaAcao[player] = nil
	toquesParede[player] = nil
	inicioSessao[player] = nil
	presentesColetados[player] = nil
	Conquistas.remover(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

-- Compras com Robux ----------------------------------------------------------------

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passeId, comprou)
	if not comprou then
		return
	end
	for nome, passe in Config.Gamepasses do
		if passe.Id == passeId then
			player:SetAttribute(`Passe_{nome}`, true)
			notificar(player, `Obrigado por comprar {passe.Nome}!`)
		end
	end
	sync(player)
	atualizarPersonagem(player)
end)

MarketplaceService.ProcessReceipt = function(info)
	local player = Players:GetPlayerByUserId(info.PlayerId)
	local d = player and data[player]
	if not d then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	for _, produto in Config.Produtos do
		if produto.Id ~= 0 and produto.Id == info.ProductId then
			local agora = os.time()
			local ativo = d.BoostCompradoAte > agora
			if ativo and d.BoostCompradoMult == produto.Mult then
				d.BoostCompradoAte += produto.Minutos * 60
			else
				d.BoostCompradoMult = math.max(produto.Mult, if ativo then d.BoostCompradoMult else 1)
				d.BoostCompradoAte = agora + produto.Minutos * 60
			end
			notificar(player, `⚡ {produto.Nome} ativado!`)
			sync(player)
			Dados.salvar(player)
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

-- Loop: vitórias automáticas e atualização dos boosts que expiram -------------------

local tempoVitoriasAuto = 0
while true do
	task.wait(1)
	tempoVitoriasAuto += 1
	local darAuto = tempoVitoriasAuto >= Config.VitoriasAutoIntervalo
	if darAuto then
		tempoVitoriasAuto = 0
	end
	for player, d in data do
		-- Segurança extra: quem cair abaixo do mapa volta para o spawn do mundo
		local character = player.Character
		local raiz = character and character:FindFirstChild("HumanoidRootPart")
		if raiz and raiz:IsA("BasePart") and raiz.Position.Y < -25 then
			irParaMundo(player)
		end
		if darAuto and player:GetAttribute("VitoriasAutoLigado") and temPasse(player, "VitoriasAuto") then
			-- Ganha como se tivesse quebrado a parede mais forte possível no mundo atual
			for indice = #Config.Paredes, 1, -1 do
				if d.Armadura >= Dados.vidaParede(d.Mundo, indice) then
					Dados.darVitorias(d, Dados.vitoriasParede(player, d, d.Mundo, indice))
					break
				end
			end
		end
		if darAuto or tempoVitoriasAuto % 5 == 0 then
			sync(player)
		end
	end
end
