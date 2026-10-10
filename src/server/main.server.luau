local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local AUTOSAVE_INTERVAL = 60

local store = DataStoreService:GetDataStore("SimulatorData_v1")

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
for _, name in { "Click", "Sell", "BuyUpgrade", "Rebirth" } do
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = remotes
end
remotes.Parent = ReplicatedStorage

local playerData: { [Player]: { [string]: number } } = {}
-- Jogadores cujo carregamento falhou: não salvamos para não apagar o progresso real
local loadFailed: { [Player]: boolean } = {}
local lastClick: { [Player]: number } = {}

-- Copia os dados para atributos (lidos pela UI) e para o leaderboard
local function sync(player: Player)
	local data = playerData[player]
	if not data then
		return
	end
	for key, value in data do
		player:SetAttribute(key, value)
	end
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		leaderstats.Moedas.Value = data.Moedas
		leaderstats.Rebirths.Value = data.Rebirths
	end
end

local function save(player: Player)
	local data = playerData[player]
	if not data or loadFailed[player] then
		return
	end
	local ok, err = pcall(store.SetAsync, store, tostring(player.UserId), data)
	if not ok then
		warn(`Falha ao salvar dados de {player.Name}: {err}`)
	end
end

local function onPlayerAdded(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	for _, name in { "Moedas", "Rebirths" } do
		local value = Instance.new("NumberValue")
		value.Name = name
		value.Parent = leaderstats
	end
	leaderstats.Parent = player

	local ok, saved = pcall(store.GetAsync, store, tostring(player.UserId))
	if not ok then
		warn(`Falha ao carregar dados de {player.Name}: {saved}`)
		loadFailed[player] = true
	end

	local data = table.clone(Config.StartingData)
	if ok and typeof(saved) == "table" then
		for key in data do
			if typeof(saved[key]) == "number" then
				data[key] = saved[key]
			end
		end
	end

	-- O jogador pode ter saído enquanto os dados carregavam
	if player.Parent ~= Players then
		loadFailed[player] = nil
		return
	end

	playerData[player] = data
	sync(player)
end

local function onPlayerRemoving(player: Player)
	save(player)
	playerData[player] = nil
	loadFailed[player] = nil
	lastClick[player] = nil
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

	local gain = Config.clickGain(data.ClickPower, data.Rebirths)
	data.Energia = math.min(data.Capacidade, data.Energia + gain)
	sync(player)
end)

remotes.Sell.OnServerEvent:Connect(function(player)
	local data = playerData[player]
	if not data or data.Energia <= 0 then
		return
	end
	data.Moedas += data.Energia * Config.SellRate
	data.Energia = 0
	sync(player)
end)

remotes.BuyUpgrade.OnServerEvent:Connect(function(player, upgradeId)
	local data = playerData[player]
	if not data or typeof(upgradeId) ~= "string" or not Config.Upgrades[upgradeId] then
		return
	end
	local cost = Config.upgradeCost(upgradeId, data[upgradeId])
	if data.Moedas < cost then
		return
	end
	data.Moedas -= cost
	data[upgradeId] += Config.Upgrades[upgradeId].Incremento
	sync(player)
end)

remotes.Rebirth.OnServerEvent:Connect(function(player)
	local data = playerData[player]
	if not data or data.Moedas < Config.rebirthCost(data.Rebirths) then
		return
	end
	local rebirths = data.Rebirths + 1
	for key, value in Config.StartingData do
		data[key] = value
	end
	data.Rebirths = rebirths
	sync(player)
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
