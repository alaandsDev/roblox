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

local EconomySim = {}

local formulas = Formulas.new({
	Dice = DiceConfig,
	Upgrades = UpgradeConfig,
	Roll = RollConfig,
	Economy = EconomyConfig,
	Characters = CharacterConfig,
	Levels = LevelConfig,
	Variants = VariantConfig,
	Rebirth = require("../../src/shared/Config/RebirthConfig"),
})
local core = RollCore.new(RarityConfig, CharacterConfig, RollConfig)
EconomySim.Formulas = formulas

-- Slots liberados no RB0 (sem Rebirth nesta fase)
local UNLOCKED: { [number]: boolean } = {}
for _, slot in BaseProgressionConfig.Milestones[0].UnlockedSlots do
	UNLOCKED[slot] = true
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
}

EconomySim.Profiles = {
	Casual = { name = "Casual", manualInterval = 2.5, collectEvery = 120, thinkEvery = 60, levelSpend = 0.3 } :: Profile,
	Ativo = { name = "Ativo", collectEvery = 30, thinkEvery = 15, levelSpend = 0.5 } :: Profile,
	Hardcore = { name = "Hardcore", collectEvery = 5, thinkEvery = 3, levelSpend = 0.6, autoSellAfterRolls = 300 } :: Profile,
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
		if cost and cost < bestCost then
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

function EconomySim.run(profile: Profile, seconds: number, seed: number, checkpoints: { number }): { Snapshot }
	local rand = Rng.new(seed)
	local data = newData()
	local snapshots = {}
	local rollTimer = 0
	local earned = 0
	local nextCheckpoint = 1
	local bestTier, bestId = 0, ""
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
			InventoryCore.equipBest(data, UNLOCKED, CharacterConfig.ById)
			while tryBuyDice(data) do
			end
			for _ = 1, 20 do
				if not tryBuyUpgrade(data) then
					break
				end
			end
			levelStations(data, data.Money * profile.levelSpend)
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
			})
		end
	end
	return snapshots
end

-- Dinheiro offline (8 h) para uma renda/s
function EconomySim.offline(income: number, seconds: number?): number
	return math.floor(income * math.min(seconds or OfflineIncomeConfig.MaxSeconds, OfflineIncomeConfig.MaxSeconds) * OfflineIncomeConfig.Multiplier)
end

return EconomySim
