--!strict
--[[
	TowerService (Fase 7): torres de batalha de cards.
	    RequestEnterTower(towerId) -> luta o PRÓXIMO andar daquela torre
	    SetTowerTeam({ uid }) -> time de até 5 (vazio = os 5 mais fortes automaticamente)
	O servidor monta as cartas (poder = Formulas:unitPower), simula com BattleCore e uma semente
	do Random do servidor, salva o progresso e entrega a recompensa da 1ª vitória.
	O cliente recebe o registro (log) só para animar.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local TowerConfig = require(Shared.Config.TowerConfig)
local CharacterConfig = require(Shared.Config.CharacterConfig)
local RarityConfig = require(Shared.Config.RarityConfig)
local BattleCore = require(Shared.Modules.BattleCore)
local Formulas = require(Shared.Modules.GameFormulas)
local TableUtil = require(Shared.Modules.TableUtil)
local Signal = require(Shared.Modules.Signal)
local Net = require(Shared.Modules.Net)

local PlayerDataService = require(script.Parent.PlayerDataService)
local EconomyService = require(script.Parent.EconomyService)
local MapService = require(script.Parent.MapService)
local AnalyticsService = require(script.Parent.AnalyticsService)

local TowerService = {}

-- (player, towerId, floor, won)
TowerService.BattleFinished = Signal.new()
TowerService._clock = os.clock
local random = Random.new()
TowerService._rand = function(): number
	return random:NextNumber()
end

local core = BattleCore.new(TowerConfig, CharacterConfig, RarityConfig)
local lastBattle: { [Player]: number } = {}

local function dataOf(player: Player): any
	local data = PlayerDataService.GetData(player)
	if not data then
		Net.fail(Net.Codes.NotReady)
	end
	return data
end

function TowerService.Highest(data: any, towerId: string): number
	local value = data.TowerProgress[towerId]
	return if type(value) == "number" then value else 0
end

function TowerService.IsUnlocked(data: any, towerId: string): boolean
	local tower = TowerConfig.ById[towerId]
	if not tower then
		return false
	end
	local previous = tower.Unlock.Tower
	return previous == nil or TowerService.Highest(data, previous) >= TowerConfig.ById[previous].Floors
end

-- Time: os uids escolhidos que ainda existem; se nenhum, os mais fortes
function TowerService.Team(data: any): { string }
	local team = {}
	local seen = {}
	for _, uid in data.TowerTeam do
		if data.Inventory[uid] and not seen[uid] and #team < TowerConfig.TeamSize then
			seen[uid] = true
			table.insert(team, uid)
		end
	end
	if #team > 0 then
		return team
	end
	local all = {}
	for uid in data.Inventory do
		table.insert(all, uid)
	end
	table.sort(all, function(a, b)
		local pa, pb = Formulas:unitPower(data.Inventory[a], data), Formulas:unitPower(data.Inventory[b], data)
		if pa ~= pb then
			return pa > pb
		end
		return a < b
	end)
	for i = 1, math.min(TowerConfig.TeamSize, #all) do
		table.insert(team, all[i])
	end
	return team
end

function TowerService.TeamPower(data: any): number
	local total = 0
	for _, uid in TowerService.Team(data) do
		total += Formulas:unitPower(data.Inventory[uid], data)
	end
	return total
end

local function publicCards(cards: { BattleCore.Card }): { any }
	local out = {}
	for _, card in cards do
		table.insert(out, { id = card.id, power = math.floor(card.power), maxHp = math.floor(card.maxHp), atk = math.floor(card.atk) })
	end
	return out
end

function TowerService.Enter(player: Player, towerId: string)
	local data = dataOf(player)
	local tower = TowerConfig.ById[towerId]
	if not tower then
		Net.fail("invalid_tower")
	end
	if not TowerService.IsUnlocked(data, towerId) then
		Net.fail("tower_locked")
	end
	local floor = TowerService.Highest(data, towerId) + 1
	if floor > tower.Floors then
		Net.fail("tower_complete")
	end
	local now = TowerService._clock()
	if now - (lastBattle[player] or -math.huge) < TowerConfig.BattleCooldown then
		Net.fail("cooldown")
	end
	local uids = TowerService.Team(data)
	if #uids == 0 then
		Net.fail("no_team")
	end
	lastBattle[player] = now

	local team = {}
	for i, uid in uids do
		local item = data.Inventory[uid]
		table.insert(team, core:card(item.Id, Formulas:unitPower(item, data), "team", i))
	end
	local enemies = core:enemies(tower, floor)
	local publicTeam, publicEnemies = publicCards(team), publicCards(enemies)
	local result = core:simulate(team, enemies, TowerService._rand)

	local rewards = { money = 0, gems = 0, completed = false }
	if result.won then
		local progress = TableUtil.deepCopy(data.TowerProgress)
		progress[towerId] = floor
		PlayerDataService.Set(player, "TowerProgress", progress)
		local enemyPower = core:enemyPower(tower, floor)
		rewards.money = math.floor(math.max(enemyPower * TowerConfig.MoneyPerPower, Formulas:incomePerSecond(data) * TowerConfig.IncomeSeconds))
		EconomyService.AddMoney(player, rewards.money, "Tower")
		if floor % TowerConfig.GemsEvery == 0 then
			rewards.gems += TowerConfig.GemsPerMilestone * (floor // TowerConfig.GemsEvery)
		end
		if floor == tower.Floors then
			rewards.completed = true
			rewards.gems += tower.CompletionGems
		end
		if rewards.gems > 0 then
			PlayerDataService.Increment(player, "Gems", rewards.gems)
		end
		PlayerDataService.SaveSoon(player)
	end
	AnalyticsService.Track(player, if result.won then "TowerWin" else "TowerLoss", { tower = towerId, floor = floor })
	TowerService.BattleFinished:Fire(player, towerId, floor, result.won)
	return {
		tower = towerId,
		floor = floor,
		won = result.won,
		rounds = result.rounds,
		log = result.log,
		team = publicTeam,
		enemies = publicEnemies,
		rewards = rewards,
	}
end

function TowerService.SetTeam(player: Player, uids: { string })
	local data = dataOf(player)
	local team = {}
	local seen = {}
	for _, uid in uids do
		if not data.Inventory[uid] then
			Net.fail("not_owned")
		end
		if not seen[uid] then
			seen[uid] = true
			table.insert(team, uid)
		end
	end
	PlayerDataService.Set(player, "TowerTeam", team)
	return team
end

function TowerService.Init()
	Net.handle("RequestEnterTower", TowerService.Enter)
	Net.handle("SetTowerTeam", TowerService.SetTeam)
	MapService.RegisterInteraction("Towers", function(player)
		Net.fire("OpenMenu", player, "Towers")
	end)
end

function TowerService.Start()
	Players.PlayerRemoving:Connect(function(player)
		lastBattle[player] = nil
	end)
end

return TowerService
