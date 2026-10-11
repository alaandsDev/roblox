--!strict
--[[
	LeaderboardService (Fase 11): rankings dos 3 painéis do Hub + leaderstats.
	    Painéis: MAIS REBIRTHS, MAIOR TORRE (soma dos andares), MAIS ROLLS — top 5.
	    Fonte: OrderedDataStore global quando disponível (jogo publicado); senão os jogadores
	    do servidor. Gravação limitada (a cada WRITE_INTERVAL por jogador) e leitura a cada
	    REFRESH_INTERVAL para respeitar os limites do DataStore.
	    leaderstats: Renascimentos e Rolls na lista de jogadores do Roblox.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local MissionCore = require(Shared.Modules.MissionCore)
local NumberFormatter = require(Shared.Modules.NumberFormatter)
local Logger = require(Shared.Modules.Logger)

local PlayerDataService = require(script.Parent.PlayerDataService)

local log = Logger.new("Leaderboard")

local LeaderboardService = {}

local BOARDS = {
	{ panel = "Panel1", stat = "Rebirths", store = "RollLegends_LB_Rebirths_v1" },
	{ panel = "Panel2", stat = "TowerFloors", store = "RollLegends_LB_Tower_v1" },
	{ panel = "Panel3", stat = "Rolls", store = "RollLegends_LB_Rolls_v1" },
}
local TOP = 5
local REFRESH_INTERVAL = 60
local WRITE_INTERVAL = 120

local stores: { [string]: any } = {}
local lastWrite: { [Player]: number } = {}
local names: { [number]: string } = {}

function LeaderboardService.Stat(data: any, stat: string): number
	return MissionCore.stat(data, stat)
end

-- Top local (jogadores do servidor)
function LeaderboardService.LocalTop(stat: string): { { name: string, value: number } }
	local list = {}
	for _, player in Players:GetPlayers() do
		local data = PlayerDataService.GetData(player)
		if data then
			table.insert(list, { name = player.DisplayName, value = LeaderboardService.Stat(data, stat) })
		end
	end
	table.sort(list, function(a, b)
		if a.value ~= b.value then
			return a.value > b.value
		end
		return a.name < b.name
	end)
	local top = {}
	for i = 1, math.min(TOP, #list) do
		top[i] = list[i]
	end
	return top
end

local function nameOf(userId: number): string
	if names[userId] then
		return names[userId]
	end
	local ok, name = pcall(Players.GetNameFromUserIdAsync, Players, userId)
	names[userId] = if ok and type(name) == "string" then name else "?"
	return names[userId]
end

local function globalTop(board: any): { { name: string, value: number } }?
	local store = stores[board.stat]
	if not store then
		return nil
	end
	local ok, pages = pcall(store.GetSortedAsync, store, false, TOP)
	if not ok or not pages then
		return nil
	end
	local top = {}
	for _, entry in pages:GetCurrentPage() do
		table.insert(top, { name = nameOf(tonumber(entry.key) or 0), value = entry.value })
	end
	return top
end

local function render(board: any, top: { { name: string, value: number } })
	local map = workspace:FindFirstChild("Map")
	local panel = map and map:FindFirstChild(board.panel, true)
	local sign = panel and panel:FindFirstChild("Sign")
	if not sign then
		return
	end
	local labels = {}
	for _, d in sign:GetDescendants() do
		if d:IsA("TextLabel") then
			table.insert(labels, d)
		end
	end
	table.sort(labels, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
	for i = 2, #labels do
		local entry = top[i - 1]
		labels[i].Text = if entry then string.format("%d. %s — %s", i - 1, entry.name, NumberFormatter.abbreviate(entry.value)) else string.format("%d. —", i - 1)
	end
end

function LeaderboardService.Refresh()
	for _, board in BOARDS do
		render(board, globalTop(board) or LeaderboardService.LocalTop(board.stat))
	end
end

local function write(player: Player, force: boolean?)
	local data = PlayerDataService.GetData(player)
	if not data then
		return
	end
	local now = os.clock()
	if not force and now - (lastWrite[player] or -math.huge) < WRITE_INTERVAL then
		return
	end
	lastWrite[player] = now
	for _, board in BOARDS do
		local store = stores[board.stat]
		if store then
			local value = math.floor(LeaderboardService.Stat(data, board.stat))
			local ok, err = pcall(store.SetAsync, store, tostring(player.UserId), value)
			if not ok then
				log:debug("falha ao gravar ranking", board.stat, err)
			end
		end
	end
end

-- leaderstats (lista de jogadores do Roblox)
local function leaderstats(player: Player)
	if typeof(player) ~= "Instance" then
		return
	end
	local folder: Instance = player:FindFirstChild("leaderstats") or Instance.new("Folder")
	folder.Name = "leaderstats"
	for _, stat in { "Rebirths", "Rolls" } do
		local value: Instance = folder:FindFirstChild(stat) or Instance.new("IntValue")
		value.Name = stat
		value.Parent = folder
	end
	folder.Parent = player
end

local function updateStats(player: Player)
	if typeof(player) ~= "Instance" then
		return
	end
	local data = PlayerDataService.GetData(player)
	local folder = player:FindFirstChild("leaderstats")
	if data and folder then
		for _, stat in { "Rebirths", "Rolls" } do
			local value = folder:FindFirstChild(stat)
			if value and value:IsA("IntValue") then
				value.Value = math.floor(data[stat] or 0)
			end
		end
	end
end

function LeaderboardService.Start()
	-- Só usa o DataStore global no jogo publicado (no Studio sem API fica local)
	if not (RunService:IsStudio() and game.GameId == 0) then
		for _, board in BOARDS do
			local ok, store = pcall(DataStoreService.GetOrderedDataStore, DataStoreService, board.store)
			if ok then
				stores[board.stat] = store
			end
		end
	end
	PlayerDataService.Loaded:Connect(function(player)
		leaderstats(player)
		updateStats(player)
	end)
	for _, player in Players:GetPlayers() do
		if PlayerDataService.IsLoaded(player) then
			leaderstats(player)
		end
	end
	Players.PlayerRemoving:Connect(function(player)
		write(player, true)
		lastWrite[player] = nil
	end)
	task.spawn(function()
		while true do
			for _, player in Players:GetPlayers() do
				updateStats(player)
				task.spawn(write, player)
			end
			LeaderboardService.Refresh()
			task.wait(REFRESH_INTERVAL)
		end
	end)
end

return LeaderboardService
