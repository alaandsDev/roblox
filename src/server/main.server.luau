local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Pista = require(script.Parent.Pista)

local AUTOSAVE_INTERVAL = 60

local store = DataStoreService:GetDataStore("SimuladorEscudo_v1")

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
for _, name in { "Click", "ComprarEscudo", "EquiparEscudo", "Rebirth", "Notificar" } do
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = remotes
end
remotes.Parent = ReplicatedStorage

local playerData: { [Player]: { [string]: any } } = {}
-- Jogadores cujo carregamento falhou: não salvamos para não apagar o progresso real
local loadFailed: { [Player]: boolean } = {}
local lastClick: { [Player]: number } = {}
local lastWallTouch: { [Player]: { [number]: number } } = {}

local function temPasse(player: Player, nome: string): boolean
	return player:GetAttribute(`Passe_{nome}`) == true
end

local function notificar(player: Player, texto: string)
	remotes.Notificar:FireClient(player, texto)
end

local function ganhoPorClique(player: Player, data): number
	return Config.ganhoPorClique(data.EscudoEquipado, data.Nivel, data.Rebirths, temPasse(player, "DobroArmadura"))
end

-- Soma progresso a um passo do tutorial do tipo contador (Clique, Parede, Escudo)
local function contarTutorial(data, tipo: string, quantidade: number)
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
		data.Vitorias += Config.TutorialRecompensa
		notificar(player, `Passo concluído! +{Config.TutorialRecompensa} 🏆`)
	end
end

-- Copia os dados para atributos (lidos pela UI) e para o leaderboard
local function sync(player: Player)
	local data = playerData[player]
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
	player:SetAttribute("GanhoPorClique", ganhoPorClique(player, data))

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		leaderstats["🛡️ Armadura"].Value = data.Armadura
		leaderstats["🏆 Vitórias"].Value = data.Vitorias
		leaderstats["🔁 Rebirths"].Value = data.Rebirths
	end
end

local function atualizarPersonagem(player: Player)
	local character = player.Character
	local data = playerData[player]
	if not character or not data then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local bonus = if temPasse(player, "Velocidade") then Config.VelocidadeGamepass else 0
		humanoid.WalkSpeed = Config.VelocidadeBase + bonus
	end

	-- Escudo simples preso ao braço esquerdo. Troque por um modelo seu se quiser.
	local antigo = character:FindFirstChild("EscudoVisual")
	if antigo then
		antigo:Destroy()
	end
	local braco = character:FindFirstChild("LeftLowerArm") or character:FindFirstChild("Left Arm")
	local escudo = Config.getEscudo(data.EscudoEquipado)
	if braco and escudo then
		local disco = Instance.new("Part")
		disco.Name = "EscudoVisual"
		disco.Shape = Enum.PartType.Cylinder
		disco.Size = Vector3.new(0.3, 2.4, 2.4)
		disco.Color = escudo.Cor
		disco.Material = Enum.Material.Metal
		disco.CanCollide = false
		disco.CanTouch = false
		disco.CanQuery = false
		disco.Massless = true
		disco.CFrame = braco.CFrame * CFrame.new(-0.7, 0, 0)
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = braco
		weld.Part1 = disco
		weld.Parent = disco
		disco.Parent = character
	end
end

local function save(player: Player)
	local data = playerData[player]
	if not data or loadFailed[player] then
		return
	end
	data.UltimoLogin = os.time()
	local ok, err = pcall(store.SetAsync, store, tostring(player.UserId), data)
	if not ok then
		warn(`Falha ao salvar dados de {player.Name}: {err}`)
	end
end

local function carregarPasses(player: Player)
	for nome, passe in Config.Gamepasses do
		if passe.Id ~= 0 then
			local ok, possui = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, passe.Id)
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

	local ok, saved = pcall(store.GetAsync, store, tostring(player.UserId))
	if not ok then
		warn(`Falha ao carregar dados de {player.Name}: {saved}`)
		loadFailed[player] = true
	end

	local data = Config.copiar(Config.StartingData)
	if ok and typeof(saved) == "table" then
		for key, default in data do
			if typeof(saved[key]) == typeof(default) then
				data[key] = Config.copiar(saved[key])
			end
		end
	end
	data.Escudos.Madeira = true
	if not data.Escudos[data.EscudoEquipado] or not Config.getEscudo(data.EscudoEquipado) then
		data.EscudoEquipado = "Madeira"
	end

	-- O jogador pode ter saído enquanto os dados carregavam
	if player.Parent ~= Players then
		loadFailed[player] = nil
		return
	end

	playerData[player] = data
	lastWallTouch[player] = {}

	if data.UltimoLogin > 0 then
		local minutos = math.min((os.time() - data.UltimoLogin) / 60, Config.OfflineMaxMinutos)
		local ganho = math.floor(minutos * Config.OfflineCliquesPorMinuto * ganhoPorClique(player, data))
		if ganho > 0 then
			data.Armadura += ganho
			task.delay(3, notificar, player, `Você ganhou {ganho} 🛡️ enquanto estava offline!`)
		end
	end

	sync(player)
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("Humanoid")
		atualizarPersonagem(player)
	end)
	if player.Character then
		atualizarPersonagem(player)
	end
end

local function onPlayerRemoving(player: Player)
	save(player)
	playerData[player] = nil
	loadFailed[player] = nil
	lastClick[player] = nil
	lastWallTouch[player] = nil
end

remotes.Click.OnServerEvent:Connect(function(player)
	local data = playerData[player]
	if not data then
		return
	end
	local now = os.clock()
	if now - (lastClick[player] or 0) < Config.ClickCooldown then
		return
	end
	lastClick[player] = now

	data.Armadura += ganhoPorClique(player, data)
	data.XP += 1
	while data.XP >= Config.xpParaNivel(data.Nivel) do
		data.XP -= Config.xpParaNivel(data.Nivel)
		data.Nivel += 1
	end
	contarTutorial(data, "Clique", 1)
	sync(player)
end)

remotes.ComprarEscudo.OnServerEvent:Connect(function(player, escudoId)
	local data = playerData[player]
	local escudo = typeof(escudoId) == "string" and Config.getEscudo(escudoId)
	if not data or not escudo or data.Escudos[escudo.Id] or data.Vitorias < escudo.Custo then
		return
	end
	data.Vitorias -= escudo.Custo
	data.Escudos[escudo.Id] = true
	data.EscudoEquipado = escudo.Id
	contarTutorial(data, "Escudo", 1)
	sync(player)
	atualizarPersonagem(player)
end)

remotes.EquiparEscudo.OnServerEvent:Connect(function(player, escudoId)
	local data = playerData[player]
	if not data or typeof(escudoId) ~= "string" or not data.Escudos[escudoId] or not Config.getEscudo(escudoId) then
		return
	end
	data.EscudoEquipado = escudoId
	sync(player)
	atualizarPersonagem(player)
end)

remotes.Rebirth.OnServerEvent:Connect(function(player)
	local data = playerData[player]
	if not data or data.Nivel < Config.nivelParaRebirth(data.Rebirths) then
		return
	end
	-- Mantém os escudos comprados; zera armadura, vitórias e nível
	data.Rebirths += 1
	data.Armadura = 0
	data.Vitorias = 0
	data.Nivel = 1
	data.XP = 0
	notificar(player, `Rebirth! Agora você tem x{1 + data.Rebirths * Config.BonusPorRebirth} de bônus`)
	sync(player)
end)

local function onParedeTocada(parede: BasePart, hit: BasePart)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	local data = player and playerData[player]
	if not data then
		return
	end
	local indice = parede:GetAttribute("Indice")
	local info = Config.Paredes[indice]
	if not info or data.Armadura < info.Vida then
		return
	end
	local now = os.clock()
	local toques = lastWallTouch[player]
	if now - (toques[indice] or 0) < Config.ParedeCooldown then
		return
	end
	toques[indice] = now

	local vitorias = if temPasse(player, "DobroVitorias") then info.Vitorias * 2 else info.Vitorias
	data.Vitorias += vitorias
	contarTutorial(data, "Parede", 1)
	sync(player)
end

for _, parede in Pista.obterParedes():GetChildren() do
	if parede:IsA("BasePart") then
		parede.Touched:Connect(function(hit)
			onParedeTocada(parede, hit)
		end)
	end
end

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

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

task.spawn(function()
	while true do
		task.wait(AUTOSAVE_INTERVAL)
		for player in playerData do
			task.spawn(save, player)
		end
	end
end)

game:BindToClose(function()
	local pending = 0
	for player in playerData do
		pending += 1
		task.spawn(function()
			save(player)
			pending -= 1
		end)
	end
	while pending > 0 do
		task.wait()
	end
end)
