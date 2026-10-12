--!strict
--[[
	Simulador de economia (puro): usa as MESMAS configs/fórmulas do jogo (Formulas, RollCore,
	InventoryCore) para simular perfis de jogador segundo a segundo.
	    local snapshots = EconomySim.run(EconomySim.Profiles.Ativo, 7200, seed, { 300, 600, 1800, 3600, 7200 })
	Usado por tools/sim/simulate_economy.luau (gera ECONOMY.md) e por tests/Economy.spec.luau.
]]

local RollCore = require("../../src/shared/Modules/RollCore")
local Formulas = require("../../src/shared/Modules/Formulas")
local InventoryCore = require("../../src/server/Core/InventoryCore")
local RarityConfig = require("../../src/shared/Config/RarityConfig")
local CharacterConfig = require("../../src/shared/Config/CharacterConfig")
local RollConfig = require("../../src/shared/Config/RollConfig")
local DiceConfig = require("../../src/shared/Config/DiceConfig")
local UpgradeConfig = require("../../src/shared/Config/UpgradeConfig")
local EconomyConfig = require("../../src/shared/Config/EconomyConfig")
local LevelConfig = require("../../src/shared/Config/CharacterLevelConfig")
local VariantConfig = require("../../src/shared/Config/VariantConfig")
local OfflineIncomeConfig = require("../../src/shared/Config/OfflineIncomeConfig")
local BaseProgressionConfig = require("../../src/shared/Config/BaseProgressionConfig")
local Rng = require("../../tests/Rng")
local TowerConfig = require("../../src/shared/Config/TowerConfig")
local RebirthConfig = require("../../src/shared/Config/RebirthConfig")
local BattleCore = require("../../src/shared/Modules/BattleCore")

local EconomySim = {}

local formulas = Formulas.new({
	Dice = DiceConfig,
	Upgrades = UpgradeConfig,
	Roll = RollConfig,
	Economy = EconomyConfig,
	Characters = CharacterConfig,
	Levels = LevelConfig,
	Variants = VariantConfig,
	Rebirth = RebirthConfig,
})
local battle = BattleCore.new(TowerConfig, CharacterConfig, RarityConfig)
local core = RollCore.new(RarityConfig, CharacterConfig, RollConfig)
EconomySim.Formulas = formulas

-- Slots liberados pela progressão (cada Rebirth = +1 slot)
local function unlockedFor(rebirths: number): { [number]: boolean }
	local best = 0
	for rb in BaseProgressionConfig.Milestones do
		if rb <= rebirths and rb > best then
			best = rb
		end
	end
	local map = {}
	for _, slot in BaseProgressionConfig.Milestones[best].UnlockedSlots do
		map[slot] = true
	end
	return map
end

export type Profile = {
	name: string,
	-- segundos entre rolls (nil = usa o cooldown, AUTO)
	manualInterval: number?,
	collectEvery: number,
	thinkEvery: number,
	-- fração do dinheiro que aceita gastar em níveis de estação por decisão
	levelSpend: number,
	autoSellAfterRolls: number?,
	-- renasce quando o dinheiro passa de custo * margem (nil = nunca)
	rebirthMargin: number?,
	towers: boolean?,
	-- junta dinheiro (para de gastar) quando o renascimento custa até X segundos de renda
	saveForRebirthSeconds: number?,
}

EconomySim.Profiles = {
	Casual = { name = "Casual", manualInterval = 2.5, collectEvery = 120, thinkEvery = 60, levelSpend = 0.3, rebirthMargin = 1, towers = true, saveForRebirthSeconds = 1200 } :: Profile,
	Ativo = { name = "Ativo", collectEvery = 30, thinkEvery = 15, levelSpend = 0.5, rebirthMargin = 1, towers = true, saveForRebirthSeconds = 1800 } :: Profile,
	Hardcore = { name = "Hardcore", collectEvery = 5, thinkEvery = 3, levelSpend = 0.6, autoSellAfterRolls = 300, rebirthMargin = 1, towers = true, saveForRebirthSeconds = 2400 } :: Profile,
}

export type Snapshot = {
	time: number,
	money: number,
	earned: number,
	rolls: number,
	dice: string,
	luck: number,
	income: number,
	upgrades: { [string]: number },
	avgStationLevel: number,
	best: string,
	discovered: number,
	rebirths: number,
	towerFloors: number,
	nextRebirthCost: number,
	rebirthTimes: { number },
	cooldown: number,
}

local function newData(): any
	return {
		Money = 0,
		Rolls = 0,
		EquippedDice = "Normal",
		OwnedDice = { Normal = true },
		Upgrades = { Luck = 0, Income = 0, RollSpeed = 0, Inventory = 0 },
		Inventory = {},
		EquippedCharacters = {},
		NextUid = 1,
		Pity = { Legendary = 0, Mythic = 0 },
		UncollectedMoney = 0,
		Index = {},
		Rebirths = 0,
		RebirthTokens = 0,
		RebirthPerks = {},
		TowerProgress = {},
	}
end

local function tryBuyDice(data: any): boolean
	for _, dice in DiceConfig.List do
		if not dice.Exclusive and not data.OwnedDice[dice.Id] then
			local req = dice.UnlockRequirement
			if (not req.Dice or data.OwnedDice[req.Dice]) and (not req.Rolls or data.Rolls >= req.Rolls) and data.Money >= dice.Price then
				data.Money -= dice.Price
				data.OwnedDice[dice.Id] = true
				data.EquippedDice = dice.Id
				return true
			end
			return false -- próximo dado ainda não liberado
		end
	end
	return false
end

local function tryBuyUpgrade(data: any): boolean
	-- compra o mais barato disponível
	local bestId, bestCost = nil, math.huge
	for _, upgrade in UpgradeConfig.List do
		local cost = formulas:upgradeCost(upgrade.Id, data.Upgrades[upgrade.Id] or 0)
		if cost and cost < bestCost and formulas:upgradeEnabled(upgrade.Id) then
			bestId, bestCost = upgrade.Id, cost
		end
	end
	if bestId and data.Money >= bestCost then
		data.Money -= bestCost
		data.Upgrades[bestId] = (data.Upgrades[bestId] or 0) + 1
		return true
	end
	return false
end

local function levelStations(data: any, budget: number): number
	local spent = 0
	local guard = 0
	while guard < 500 do
		guard += 1
		-- melhora a estação com o nível mais barato
		local bestUid, bestCost = nil, math.huge
		for _, uid in data.EquippedCharacters do
			local item = data.Inventory[uid]
			if item and item.Level < LevelConfig.MaxLevel then
				local cost = formulas:characterUpgradeCost(item.Id, item.Level, 1)
				if cost < bestCost then
					bestUid, bestCost = uid, cost
				end
			end
		end
		if not bestUid or spent + bestCost > budget or bestCost > data.Money then
			break
		end
		data.Money -= bestCost
		spent += bestCost
		data.Inventory[bestUid].Level += 1
	end
	return spent
end

local function sellExtras(data: any): number
	-- inventário cheio: vende duplicatas e comuns/incomuns não equipados (mantém 1 de cada e o Secreto)
	local uids = InventoryCore.selectBatch(data, "Duplicates", CharacterConfig.ById)
	for uid, item in data.Inventory do
		local tier = RarityConfig.ById[CharacterConfig.ById[item.Id].Rarity].Tier
		if tier <= 2 and not InventoryCore.slotOf(data, uid) then
			table.insert(uids, uid)
		end
	end
	local plan = InventoryCore.planSale(data, uids, function(id)
		return formulas:sellValue(id)
	end)
	return InventoryCore.executeSale(data, plan)
end

local function tryRebirth(data: any, margin: number?): boolean
	if not margin then
		return false
	end
	local cost = formulas:rebirthCost(data.Rebirths)
	if not cost or data.Money < cost * margin then
		return false
	end
	data.Money = 0
	data.UncollectedMoney = 0
	data.Upgrades = { Luck = 0, Income = 0, RollSpeed = 0, Inventory = data.Upgrades.Inventory or 0 }
	data.Rebirths += 1
	data.RebirthTokens += formulas:rebirthTokens(data.Rebirths)
	-- gasta fichas no perk mais barato (prioridade: Renda, Sorte, Poder, Capacidade, Velocidade)
	for _ = 1, 20 do
		local bought = false
		for _, id in { "Income", "Luck", "Power", "Capacity", "Speed" } do
			local cost2 = formulas:perkCost(id, formulas:perkLevel(data, id))
			if cost2 and data.RebirthTokens >= cost2 and formulas:perkEnabled(id) then
				data.RebirthTokens -= cost2
				data.RebirthPerks[id] = formulas:perkLevel(data, id) + 1
				bought = true
				break
			end
		end
		if not bought then
			break
		end
	end
	return true
end

-- Torres: luta enquanto vence (mesmo BattleCore do servidor), recebendo a recompensa
local function climbTowers(data: any, rand: () -> number): number
	local earned = 0
	local uids = {}
	for uid in data.Inventory do
		table.insert(uids, uid)
	end
	table.sort(uids, function(a, b)
		return formulas:unitPower(data.Inventory[a], data) > formulas:unitPower(data.Inventory[b], data)
	end)
	for _, tower in TowerConfig.List do
		local previous = tower.Unlock.Tower
		if previous and (data.TowerProgress[previous] or 0) < TowerConfig.ById[previous].Floors then
			break
		end
		for _ = 1, 5 do
			local floor = (data.TowerProgress[tower.Id] or 0) + 1
			if floor > tower.Floors then
				break
			end
			local team = {}
			for i = 1, math.min(TowerConfig.TeamSize, #uids) do
				local item = data.Inventory[uids[i]]
				table.insert(team, battle:card(item.Id, formulas:unitPower(item, data), "team", i))
			end
			if #team == 0 then
				return earned
			end
			local result = battle:simulate(team, battle:enemies(tower, floor), rand)
			if not result.won then
				break
			end
			data.TowerProgress[tower.Id] = floor
			local reward = math.floor(math.max(battle:enemyPower(tower, floor) * TowerConfig.MoneyPerPower, formulas:incomePerSecond(data) * TowerConfig.IncomeSeconds))
			data.Money += reward
			earned += reward
		end
	end
	return earned
end

function EconomySim.run(profile: Profile, seconds: number, seed: number, checkpoints: { number }): { Snapshot }
	local rand = Rng.new(seed)
	local data = newData()
	local snapshots = {}
	local rollTimer = 0
	local earned = 0
	local nextCheckpoint = 1
	local bestTier, bestId = 0, ""
	local rebirthTimes = {}
	for t = 1, seconds do
		-- Rolls
		local interval = profile.manualInterval or (formulas:rollCooldown(data) + RollConfig.AutoRollExtraDelay)
		rollTimer += 1
		while rollTimer >= interval do
			rollTimer -= interval
			if InventoryCore.count(data) >= formulas:capacity(data) then
				local gained = sellExtras(data)
				data.Money += gained
				earned += gained
				if InventoryCore.count(data) >= formulas:capacity(data) then
					break
				end
			end
			local result = core:roll(formulas:luck(data, 0), data.Pity, rand)
			data.Pity = result.pity
			data.Rolls += 1
			local isNew = data.Index[result.characterId] == nil
			data.Index[result.characterId] = true
			local tier = RarityConfig.ById[result.rarity].Tier
			if tier > bestTier then
				bestTier, bestId = tier, result.characterId
			end
			if not isNew and profile.autoSellAfterRolls and data.Rolls > profile.autoSellAfterRolls and tier <= 2 then
				local value = formulas:sellValue(result.characterId)
				data.Money += value
				earned += value
			else
				InventoryCore.add(data, result.characterId, t)
			end
		end
		-- Renda passiva
		local ips = formulas:incomePerSecond(data)
		data.UncollectedMoney = math.min(data.UncollectedMoney + ips, math.max(ips * EconomyConfig.MaxUncollectedSeconds, data.UncollectedMoney))
		if t % profile.collectEvery == 0 then
			local amount = math.floor(data.UncollectedMoney)
			data.UncollectedMoney -= amount
			data.Money += amount
			earned += amount
		end
		-- Decisões
		if t % profile.thinkEvery == 0 then
			if tryRebirth(data, profile.rebirthMargin) then
				table.insert(rebirthTimes, t)
			end
			InventoryCore.equipBest(data, unlockedFor(data.Rebirths), CharacterConfig.ById)
			if profile.towers and t % 60 == 0 then
				earned += climbTowers(data, rand)
			end
			local cost = formulas:rebirthCost(data.Rebirths)
			local saving = profile.saveForRebirthSeconds ~= nil and cost ~= nil and cost <= formulas:incomePerSecond(data) * (profile.saveForRebirthSeconds :: number)
			while tryBuyDice(data) do
			end
			if not saving then
				for _ = 1, 20 do
					if not tryBuyUpgrade(data) then
						break
					end
				end
				levelStations(data, data.Money * profile.levelSpend)
			end
		end
		if nextCheckpoint <= #checkpoints and t == checkpoints[nextCheckpoint] then
			nextCheckpoint += 1
			local levels, count = 0, 0
			for _, uid in data.EquippedCharacters do
				levels += data.Inventory[uid].Level
				count += 1
			end
			local discovered = 0
			for _ in data.Index do
				discovered += 1
			end
			table.insert(snapshots, {
				time = t,
				money = data.Money,
				earned = earned,
				rolls = data.Rolls,
				dice = data.EquippedDice,
				luck = formulas:luck(data, 0),
				income = ips,
				upgrades = table.clone(data.Upgrades),
				avgStationLevel = if count > 0 then levels / count else 0,
				best = bestId,
				discovered = discovered,
				rebirths = data.Rebirths,
				nextRebirthCost = formulas:rebirthCost(data.Rebirths) or math.huge,
				rebirthTimes = table.clone(rebirthTimes),
				cooldown = formulas:rollCooldown(data),
				towerFloors = (data.TowerProgress.Ember or 0) + (data.TowerProgress.Storm or 0) + (data.TowerProgress.Void or 0),
			})
		end
	end
	return snapshots
end

-- Dinheiro offline (8 h) para uma renda/s (com o teto do próximo renascimento, se informado)
function EconomySim.offline(income: number, seconds: number?, nextRebirthCost: number?): number
	local amount = math.floor(income * math.min(seconds or OfflineIncomeConfig.MaxSeconds, OfflineIncomeConfig.MaxSeconds) * OfflineIncomeConfig.Multiplier)
	if nextRebirthCost and OfflineIncomeConfig.MaxRebirthFraction and nextRebirthCost < math.huge then
		amount = math.min(amount, math.floor(nextRebirthCost * OfflineIncomeConfig.MaxRebirthFraction))
	end
	return amount
end

return EconomySim
