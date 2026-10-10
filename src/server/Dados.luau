-- Estado dos jogadores: carregar/salvar, multiplicadores, recompensas e ovos.
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local Dados = {}

local store = DataStoreService:GetDataStore("SimuladorEscudo_v1")

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
for _, name in { "Acao", "Notificar", "OvoAberto" } do
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = remotes
end
remotes.Parent = ReplicatedStorage
Dados.remotes = remotes

Dados.data = {} :: { [Player]: any }
-- Jogadores cujo carregamento falhou: não salvamos para não apagar o progresso real
local loadFailed: { [Player]: boolean } = {}

function Dados.temPasse(player: Player, nome: string): boolean
	return player:GetAttribute(`Passe_{nome}`) == true
end

function Dados.notificar(player: Player, texto: string)
	remotes.Notificar:FireClient(player, texto)
end

function Dados.boostAtivo(data, id: string): boolean
	return data.Boosts[id] > os.time()
end

function Dados.petsEquipados(data): { any }
	local equipados = {}
	for _, petId in data.PetsEquipados do
		for _, pet in data.Pets do
			if pet.Id == petId then
				table.insert(equipados, pet)
				break
			end
		end
	end
	return equipados
end

function Dados.maxEquipados(player: Player, data): number
	local extra = if Dados.temPasse(player, "PetsExtra") then 3 else 0
	return Config.PetsEquipadosBase + data.Melhorias.Slots + extra
end

function Dados.multArmadura(player: Player, data): number
	local bonusPets = 0
	for _, pet in Dados.petsEquipados(data) do
		bonusPets += Config.bonusPet(pet.Tipo, pet.Dourado)
	end
	local mult = (1 + data.Nivel * Config.BonusPorNivel)
		* (1 + data.Rebirths * Config.BonusPorRebirth)
		* (1 + data.Melhorias.Armadura * 0.1)
		* (1 + bonusPets)
	if Dados.temPasse(player, "DobroArmadura") then
		mult *= 2
	end
	if Dados.boostAtivo(data, "Armadura") then
		mult *= Config.Pocoes.Armadura.Mult
	end
	if data.BoostCompradoAte > os.time() then
		mult *= data.BoostCompradoMult
	end
	return mult
end

function Dados.ganhoPorClique(player: Player, data): number
	local escudo = Config.getEscudo(data.EscudoEquipado) or Config.Escudos[1]
	-- Sem arredondar: bônus pequenos (pets, níveis) somam frações a cada toque
	return escudo.Bonus * Dados.multArmadura(player, data)
end

function Dados.multVitorias(player: Player, data): number
	local aura = Config.getAura(data.AuraEquipada)
	local mult = (1 + (if aura then aura.Bonus else 0)) * (1 + data.Melhorias.Vitorias * 0.1)
	if Dados.temPasse(player, "DobroVitorias") then
		mult *= 2
	end
	if Dados.boostAtivo(data, "Vitorias") then
		mult *= Config.Pocoes.Vitorias.Mult
	end
	return mult
end

function Dados.vidaParede(mundo: number, indice: number): number
	return Config.Paredes[indice].Vida * Config.Mundos[mundo].MultVida
end

function Dados.vitoriasParede(player: Player, data, mundo: number, indice: number): number
	local base = Config.Paredes[indice].Vitorias * Config.Mundos[mundo].MultVitorias
	return math.floor(base * Dados.multVitorias(player, data))
end

function Dados.darVitorias(data, quantidade: number)
	data.Vitorias += quantidade
	data.VitoriasTotais += quantidade
end

-- Soma progresso a um passo do tutorial do tipo contador
function Dados.contarTutorial(data, tipo: string, quantidade: number)
	local passo = Config.Tutorial[data.Tutorial]
	if passo and passo.Tipo == tipo and not passo.Absoluto then
		data.TutorialProgresso += quantidade
	end
end

local function avancarTutorial(player: Player, data)
	while true do
		local passo = Config.Tutorial[data.Tutorial]
		if not passo then
			return
		end
		if passo.Tipo == "Nivel" then
			data.TutorialProgresso = data.Nivel
		elseif passo.Tipo == "Vitorias" then
			data.TutorialProgresso = data.Vitorias
		end
		if data.TutorialProgresso < passo.Meta then
			return
		end
		data.Tutorial += 1
		data.TutorialProgresso = 0
		Dados.darVitorias(data, Config.TutorialRecompensa)
		Dados.notificar(player, `Passo concluído! +{Config.TutorialRecompensa} 🏆`)
	end
end

-- Copia os dados para atributos do jogador (a interface lê daí) e para o leaderboard
function Dados.sync(player: Player)
	local data = Dados.data[player]
	if not data then
		return
	end
	avancarTutorial(player, data)
	for key, value in data do
		if typeof(value) == "table" then
			player:SetAttribute(key, HttpService:JSONEncode(value))
		else
			player:SetAttribute(key, value)
		end
	end

	local visuais = {}
	for _, pet in Dados.petsEquipados(data) do
		table.insert(visuais, { Tipo = pet.Tipo, Dourado = pet.Dourado })
	end
	player:SetAttribute("PetsVisuais", HttpService:JSONEncode(visuais))
	player:SetAttribute("GanhoPorClique", Dados.ganhoPorClique(player, data))
	player:SetAttribute("MultArmadura", Dados.multArmadura(player, data))
	player:SetAttribute("MultVitorias", Dados.multVitorias(player, data))
	player:SetAttribute("MaxEquipados", Dados.maxEquipados(player, data))

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		leaderstats["🛡️ Armadura"].Value = math.floor(data.Armadura)
		leaderstats["🏆 Vitórias"].Value = data.Vitorias
		leaderstats["🔁 Rebirths"].Value = data.Rebirths
	end
end

-- Sorteia um pet do ovo e entrega ao jogador. Não cobra nada (quem chama cobra).
function Dados.chocarOvo(player: Player, data, ovoId: string): boolean
	local ovo = Config.getOvo(ovoId)
	if not ovo then
		return false
	end
	if #data.Pets >= Config.MaxPets then
		Dados.notificar(player, "Inventário de pets cheio! Apague ou funda alguns.")
		return false
	end

	local sorte = Dados.boostAtivo(data, "Sorte")
	local total = 0
	local pesos = {}
	for i, entrada in ovo.Pets do
		local peso = entrada.Chance
		if sorte and entrada.Chance < 10 then
			peso *= Config.Pocoes.Sorte.Mult
		end
		pesos[i] = peso
		total += peso
	end
	local sorteio = math.random() * total
	local escolhido = ovo.Pets[#ovo.Pets].Pet
	for i, entrada in ovo.Pets do
		sorteio -= pesos[i]
		if sorteio <= 0 then
			escolhido = entrada.Pet
			break
		end
	end

	local pet = { Id = tostring(data.ProximoPetId), Tipo = escolhido, Dourado = false }
	data.ProximoPetId += 1
	table.insert(data.Pets, pet)
	if #data.PetsEquipados < Dados.maxEquipados(player, data) then
		table.insert(data.PetsEquipados, pet.Id)
	end
	Dados.contarTutorial(data, "Ovo", 1)
	remotes.OvoAberto:FireClient(player, ovoId, escolhido)
	return true
end

function Dados.darRecompensa(player: Player, data, r)
	if r.Tipo == "Vitorias" then
		Dados.darVitorias(data, r.Qtd)
	elseif r.Tipo == "Armadura" then
		data.Armadura += r.Qtd
	elseif r.Tipo == "Pocao" then
		data.Pocoes[r.Pocao] += r.Qtd
	elseif r.Tipo == "Ovo" then
		for _ = 1, r.Qtd do
			Dados.chocarOvo(player, data, r.Ovo)
		end
	end
	Dados.notificar(player, `Você ganhou {Config.descreverRecompensa(r)}!`)
end

-- Tabelas cujos campos são mesclados um a um (campos novos ganham o valor inicial)
local MESCLAR_CAMPOS = { Pocoes = true, Boosts = true, Melhorias = true }

-- Junta os dados salvos com os valores padrão
local function mesclar(padrao, salvo)
	for key, default in padrao do
		local valor = salvo[key]
		if typeof(valor) ~= typeof(default) then
			continue
		end
		if MESCLAR_CAMPOS[key] then
			for campo, valorPadrao in default do
				if typeof(valor[campo]) == typeof(valorPadrao) then
					default[campo] = valor[campo]
				end
			end
		else
			padrao[key] = Config.copiar(valor)
		end
	end
end

function Dados.carregar(player: Player)
	local ok, salvo = pcall(store.GetAsync, store, tostring(player.UserId))
	if not ok then
		warn(`Falha ao carregar dados de {player.Name}: {salvo}`)
		loadFailed[player] = true
	end

	local data = Config.copiar(Config.StartingData)
	if ok and typeof(salvo) == "table" then
		mesclar(data, salvo)
	end
	data.Escudos.Madeira = true
	if not data.Escudos[data.EscudoEquipado] or not Config.getEscudo(data.EscudoEquipado) then
		data.EscudoEquipado = "Madeira"
	end
	if not Config.Mundos[data.Mundo] or data.Mundo > data.MundoMax then
		data.Mundo = 1
	end
	-- Remove pets que não existem mais no Config
	for i = #data.Pets, 1, -1 do
		if not Config.Pets[data.Pets[i].Tipo] then
			table.remove(data.Pets, i)
		end
	end
	return data
end

function Dados.salvar(player: Player)
	local data = Dados.data[player]
	if not data or loadFailed[player] then
		return
	end
	data.UltimoLogin = os.time()
	local ok, err = pcall(store.SetAsync, store, tostring(player.UserId), data)
	if not ok then
		warn(`Falha ao salvar dados de {player.Name}: {err}`)
	end
end

function Dados.remover(player: Player)
	Dados.data[player] = nil
	loadFailed[player] = nil
end

function Dados.descartarFalha(player: Player)
	loadFailed[player] = nil
end

game:BindToClose(function()
	local pendentes = 0
	for player in Dados.data do
		pendentes += 1
		task.spawn(function()
			Dados.salvar(player)
			pendentes -= 1
		end)
	end
	while pendentes > 0 do
		task.wait()
	end
end)

task.spawn(function()
	while true do
		task.wait(60)
		for player in Dados.data do
			task.spawn(Dados.salvar, player)
		end
	end
end)

return Dados
