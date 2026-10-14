--!strict
--[[
	Análise de balanceamento dos 16 Dice (puro). Usa o MESMO DiceCore do servidor e as mesmas
	fórmulas de Luck (Formulas/Odds): só troca os RarityWeights pelos da proposta.
	Usado por tools/sim/analyze_dice_balance.luau e tests/DiceBalance.spec.luau.
]]

local DiceCore = require("../../src/shared/Modules/DiceCore")
local DiceConfig = require("../../src/shared/Config/DiceConfig")
local CharacterConfig = require("../../src/shared/Config/CharacterConfig")
local RarityConfig = require("../../src/shared/Config/RarityConfig")
local RollConfig = require("../../src/shared/Config/RollConfig")
local Odds = require("./Odds")
local Proposal = require("./DiceBalanceProposal")

local DiceBalance = {}
DiceBalance.Proposal = Proposal

-- Cópia do DiceConfig com RarityWeights explícitos (a produção não é tocada)
function DiceBalance.withWeights(weights: { [string]: { [string]: number } }): any
	local list, byId, byKey = {}, {}, {}
	for _, dice in DiceConfig.List do
		local copy = table.clone(dice)
		copy.RarityWeights = weights[dice.Id]
		table.insert(list, copy)
		byId[copy.Id] = copy
		if copy.CatalogKey then
			byKey[copy.CatalogKey] = copy
		end
	end
	local config = table.clone(DiceConfig)
	config.List, config.ById, config.ByCatalogKey = list, byId, byKey
	return config
end

DiceBalance.current = DiceCore.new(DiceConfig, CharacterConfig, RarityConfig, RollConfig)
DiceBalance.proposedConfig = DiceBalance.withWeights(Proposal.RarityWeights)
DiceBalance.proposed = DiceCore.new(DiceBalance.proposedConfig, CharacterConfig, RarityConfig, RollConfig)

-- Variante B: pesos da proposta + overrides de Shinobi/Colossus (a ordem é avaliada à parte)
local variantWeights = table.clone(Proposal.RarityWeights)
for id, weights in Proposal.VariantB.RarityWeights do
	variantWeights[id] = weights
end
DiceBalance.variantB = DiceCore.new(DiceBalance.withWeights(variantWeights), CharacterConfig, RarityConfig, RollConfig)

-- Luck por cenário para um Dice: 1.0 · Luck do próprio Dice · máximo F2P · máximo com monetização
local function scenario(id: string): any
	for _, s in Odds.Scenarios do
		if s.id == id then
			return s
		end
	end
	error("cenário inexistente " .. id)
end

function DiceBalance.luckScenarios(diceId: string): { { name: string, luck: number } }
	local function luckFor(id: string): number
		local data = table.clone(scenario(id).data)
		data.EquippedDice = diceId
		return Odds.formulas:luck(data, 0)
	end
	local own = Odds.formulas:luck({ EquippedDice = diceId, Upgrades = {}, Rebirths = 0, RebirthPerks = {}, Boosts = {}, Runtime = {} }, 0)
	return {
		{ name = "Luck 1,0x", luck = 1 },
		{ name = string.format("Luck do Dice (%.2fx)", own), luck = own },
		{ name = string.format("Máx. F2P (%.1fx)", luckFor("F")), luck = luckFor("F") },
		{ name = string.format("Máx. com monetização (%.1fx)", luckFor("G")), luck = luckFor("G") },
	}
end

-- Expected Rarity Value
function DiceBalance.erv(core: any, diceId: string, luck: number?): number
	local total = 0
	for rarity, p in core:rarityChances(diceId, luck) do
		total += p * Proposal.Score[rarity]
	end
	return total
end

-- [{ rarity, p, rolls, count }] na ordem das raridades
function DiceBalance.rarityRows(core: any, diceId: string, luck: number?): { any }
	local chances = core:rarityChances(diceId, luck)
	local pool = core:pool(diceId)
	local rows = {}
	for _, rarity in pool.rarities do
		local p = chances[rarity] or 0
		table.insert(rows, { rarity = rarity, p = p, rolls = if p > 0 then 1 / p else math.huge, count = #pool.byRarity[rarity] })
	end
	return rows
end

-- [{ id, name, rarity, p, rolls }] do mais raro para o mais comum
function DiceBalance.characterRows(core: any, diceId: string, luck: number?): { any }
	local rows = {}
	for _, id in core:charactersFor(diceId) do
		local p = core:characterProbability(diceId, id, luck)
		table.insert(rows, { id = id, name = CharacterConfig.ById[id].Name, rarity = CharacterConfig.ById[id].Rarity, p = p, rolls = if p > 0 then 1 / p else math.huge })
	end
	table.sort(rows, function(a, b)
		return a.p < b.p
	end)
	return rows
end

-- Chance natural de tirar a raridade do piso OU MELHOR num roll
function DiceBalance.atLeast(core: any, diceId: string, rarity: string, luck: number?): number
	local tier = RarityConfig.ById[rarity].Tier
	local total = 0
	for r, p in core:rarityChances(diceId, luck) do
		if RarityConfig.ById[r].Tier >= tier then
			total += p
		end
	end
	return total
end

--[[
	Pity com limite N e chance natural p por roll (raridade do piso ou melhor):
	  chegar ao pity     = (1 − p)^(N − 1)          (fração dos ciclos que terminam pelo pity)
	  rolls entre acertos = (1 − (1 − p)^N) / p      (com pity) · 1/p sem pity
]]
function DiceBalance.pity(p: number, threshold: number): { reach: number, effectiveRolls: number, naturalRolls: number, boost: number }
	if p <= 0 then
		return { reach = 1, effectiveRolls = threshold, naturalRolls = math.huge, boost = math.huge }
	end
	local reach = (1 - p) ^ (threshold - 1)
	local effective = (1 - (1 - p) ^ threshold) / p
	return { reach = reach, effectiveRolls = effective, naturalRolls = 1 / p, boost = (1 / effective) / p }
end

-- Rolls esperados para completar o pool (todos os personagens ao menos 1x; coletor de cupons
-- com probabilidades diferentes): E[T] = ∫ (1 − Π(1 − e^(−p_i·t))) dt (integração numérica)
function DiceBalance.completionRolls(core: any, diceId: string, luck: number?): number
	local ps = {}
	local minP = math.huge
	for _, id in core:charactersFor(diceId) do
		local p = core:characterProbability(diceId, id, luck)
		table.insert(ps, p)
		minP = math.min(minP, p)
	end
	local horizon = 40 / minP
	local steps = 20000
	local dt = horizon / steps
	local sum = 0
	for i = 0, steps - 1 do
		local t = (i + 0.5) * dt
		local all = 1
		for _, p in ps do
			all *= 1 - math.exp(-p * t)
		end
		sum += (1 - all) * dt
	end
	return sum
end

function DiceBalance.duration(seconds: number): string
	if seconds == math.huge then
		return "—"
	end
	local s = math.floor(seconds + 0.5)
	local d = s // 86400
	local h = (s % 86400) // 3600
	local m = (s % 3600) // 60
	local sec = s % 60
	if d > 0 then
		return string.format("%dd %02dh", d, h)
	elseif h > 0 then
		return string.format("%dh%02dm", h, m)
	elseif m > 0 then
		return string.format("%dm%02ds", m, sec)
	end
	return string.format("%ds", sec)
end

-- "Rolls · tempo Normal (1/s) · tempo Roll Rápido (2/s)"
function DiceBalance.timing(rolls: number): (string, string)
	return DiceBalance.duration(rolls * RollConfig.RollSpeed.BaseInterval), DiceBalance.duration(rolls * RollConfig.RollSpeed.FastRollInterval)
end

return DiceBalance
