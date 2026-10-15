--!strict
--[[
	LeaderboardService (Fase 11): rankings dos painéis do Hub + leaderstats.
	    Painéis: MAIS REBIRTHS, MAIOR TORRE (soma dos andares), MAIS ROLLS — top 5;
	    👑 MAGNATA · TEMPORADA 1 (Panel4) — top 10 por LifetimeMoneyGenerated (NUNCA o saldo),
	    valor em $ (NumberFormatter.money). Ver MagnateConfig.
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
local MagnateConfig = require(Shared.Config.MagnateConfig)
local Logger = require(Shared.Modules.Logger)

local PlayerDataService = require(script.Parent.PlayerDataService)

local log = Logger.new("Leaderboard")

local LeaderboardService = {}

type Board = { panel: string, stat: string, store: string, top: number, money: boolean?, unit: number? }
local BOARDS: { Board } = {
	{ panel = "Panel1", stat = "Rebirths", store = "RollLegends_LB_Rebirths_v1", top = 5 },
	{ panel = "Panel2", stat = "TowerFloors", store = "RollLegends_LB_Tower_v1", top = 5 },
	{ panel = "Panel3", stat = "Rolls", store = "RollLegends_LB_Rolls_v1", top = 5 },
	-- OrderedDataStore guarda a pontuação em milhares de $ (unit); a tela mostra em $
	{ panel = "Panel4", stat = "Magnate", store = MagnateConfig.Store, top = MagnateConfig.Top, money = true, unit = MagnateConfig.ScoreUnit },
}
LeaderboardService.Boards = BOARDS
local TOP = 5
local REFRESH_INTERVAL = 60
local WRITE_INTERVAL = 120

local stores: { [string]: any } = {}
local lastWrite: { [Player]: number } = {}
-- último valor gravado por jogador/quadro: só regrava o que mudou (sem SetAsync à toa)
local lastWritten: { [Player]: { [string]: number } } = {}
LeaderboardService.Writes = 0
local names: { [number]: string } = {}

function LeaderboardService.Stat(data: any, stat: string): number
	if stat == "Magnate" then
		local lifetime = data.LifetimeMoneyGenerated
		return if type(lifetime) == "number" and lifetime == lifetime and lifetime > 0 and lifetime < math.huge then math.floor(lifetime) else 0
	end
	return MissionCore.stat(data, stat)
end

-- Pontuação gravada no OrderedDataStore (inteiro; Magnata em milhares de $, teto 2^53)
function LeaderboardService.Score(board: any, data: any): number
	local value = LeaderboardService.Stat(data, board.stat)
	if board.unit then
		return math.min(math.floor(value / board.unit), MagnateConfig.MaxScore)
	end
	return math.floor(value)
end

-- Top local (jogadores do servidor)
function LeaderboardService.LocalTop(stat: string, count: number?): { { name: string, value: number } }
	local limit = count or TOP
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
	for i = 1, math.min(limit, #list) do
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
	local ok, pages = pcall(store.GetSortedAsync, store, false, board.top)
	if not ok or not pages then
		return nil
	end
	local top = {}
	for _, entry in pages:GetCurrentPage() do
		table.insert(top, { name = nameOf(tonumber(entry.key) or 0), value = entry.value * (board.unit or 1) })
	end
	return top
end

-- Preenche as linhas fixas do painel (Row1..RowN: Rank | PlayerName | Value). Só troca textos.
function LeaderboardService.Render(panelName: string, top: { { name: string, value: number } }, rows: number?, money: boolean?)
	local map = workspace:FindFirstChild("Map")
	local panel = map and map:FindFirstChild(panelName, true)
	local sign = panel and panel:FindFirstChild("Sign")
	if not sign then
		return
	end
	for i = 1, rows or TOP do
		local row = sign:FindFirstChild("Row" .. i)
		if row then
			local entry = top[i]
			local name, value = row:FindFirstChild("PlayerName"), row:FindFirstChild("Value")
			if name and name:IsA("TextLabel") then
				name.Text = if entry then entry.name else "—"
			end
			if value and value:IsA("TextLabel") then
				value.Text = if not entry then "" elseif money then NumberFormatter.money(math.floor(entry.value)) else NumberFormatter.abbreviate(math.floor(entry.value))
			end
		end
	end
end

function LeaderboardService.Refresh()
	for _, board in BOARDS do
		LeaderboardService.Render(board.panel, globalTop(board) or LeaderboardService.LocalTop(board.stat, board.top), board.top, board.money)
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
	local written = lastWritten[player] or {}
	lastWritten[player] = written
	for _, board in BOARDS do
		local store = stores[board.stat]
		if store then
			local value = LeaderboardService.Score(board, data)
			-- só grava o que mudou desde a última gravação (dirty): sem SetAsync repetido
			if written[board.stat] ~= value then
				LeaderboardService.Writes += 1
				local ok, err = pcall(store.SetAsync, store, tostring(player.UserId), value)
				if ok then
					written[board.stat] = value
				else
					log:debug("falha ao gravar ranking", board.stat, err)
				end
			end
		end
	end
end

-- (testes/DEV) grava agora / injeta um OrderedDataStore falso
LeaderboardService._write = write
function LeaderboardService._setStore(stat: string, store: any)
	stores[stat] = store
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
		lastWritten[player] = nil
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
