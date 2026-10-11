--!strict
--[[
	Odds reais por cenário (puro): junta TODOS os multiplicadores (dado, upgrade de Luck,
	Renascimento + perk, boosts, gamepasses) e a velocidade de roll (cooldown + AUTO).
	Usado por tools/sim/simulate_rng.luau (RNG_SIMULATION.md) e tests/Odds.spec.luau.
]]

local RollCore = require("../../src/shared/Modules/RollCore")
local Formulas = require("../../src/shared/Modules/Formulas")
local RarityConfig = require("../../src/shared/Config/RarityConfig")
local CharacterConfig = require("../../src/shared/Config/CharacterConfig")
local RollConfig = require("../../src/shared/Config/RollConfig")
local DiceConfig = require("../../src/shared/Config/DiceConfig")
local UpgradeConfig = require("../../src/shared/Config/UpgradeConfig")
local RebirthConfig = require("../../src/shared/Config/RebirthConfig")
local MonetizationConfig = require("../../src/shared/Config/MonetizationConfig")

local Odds = {}

Odds.core = RollCore.new(RarityConfig, CharacterConfig, RollConfig)
Odds.formulas = Formulas.new({
	Dice = DiceConfig,
	Upgrades = UpgradeConfig,
	Roll = RollConfig,
	Economy = require("../../src/shared/Config/EconomyConfig"),
	Characters = CharacterConfig,
	Levels = require("../../src/shared/Config/CharacterLevelConfig"),
	Variants = require("../../src/shared/Config/VariantConfig"),
	Rebirth = RebirthConfig,
})

local function profile(dice: string, luckLevel: number, speedLevel: number, rebirths: number, perks: { [string]: number }, boost: number, passes: { string }): any
	local runtime = { Income = 1, Luck = 1, Cooldown = 1, Capacity = 0 }
	for _, key in passes do
		for effect, value in MonetizationConfig.GamePasses[key].Effects or {} do
			if effect ~= "Capacity" then
				runtime[effect] *= value
			end
		end
	end
	return {
		EquippedDice = dice,
		Upgrades = { Luck = luckLevel, RollSpeed = speedLevel, Income = 0, Inventory = 0 },
		Rebirths = rebirths,
		RebirthPerks = perks,
		Boosts = if boost > 1 then { Luck = { Multiplier = boost, ExpiresAt = math.huge } } else {},
		Runtime = runtime,
	}
end

local maxPerks = {}
for _, perk in RebirthConfig.Perks do
	maxPerks[perk.Id] = perk.MaxLevel
end
local luckMax = UpgradeConfig.ById.Luck.MaxLevel
local speedMax = UpgradeConfig.ById.RollSpeed.MaxLevel

-- Cenários (B/C/D vêm do perfil Ativo da simulação de economia; ver ECONOMY.md)
Odds.Scenarios = {
	{ id = "A", name = "Jogador novo", data = profile("Normal", 0, 0, 0, {}, 1, {}) },
	{ id = "B", name = "30 minutos", data = profile("Storm", 10, 7, 0, {}, 1, {}) },
	{ id = "C", name = "1 hora", data = profile("Void", 12, 9, 1, { Luck = 1 }, 1, {}) },
	{ id = "D", name = "Midgame (~4 h)", data = profile("Celestial", 16, 11, 4, { Luck = 3, Speed = 1 }, 1, {}) },
	{ id = "E", name = "Late game (~RB 15)", data = profile("Celestial", luckMax, speedMax, 15, { Luck = 8, Speed = 3 }, 1, {}) },
	{ id = "F", name = "Máximo F2P (RB máx + boost diário 2x)", data = profile("Celestial", luckMax, speedMax, RebirthConfig.MaxRebirths, maxPerks, 2, {}) },
	{ id = "G", name = "Máximo com monetização (F + VIP + Sorte x2 + Roll Rápido)", data = profile("Celestial", luckMax, speedMax, RebirthConfig.MaxRebirths, maxPerks, 2, { "VIP", "LuckX2", "FastRoll" }) },
}

-- Rolls esperados entre eventos "tier >= X" com pity de N rolls: (1 - (1-p)^N) / p
local function withPity(p: number, threshold: number?): number
	if not threshold or p <= 0 then
		return if p > 0 then 1 / p else math.huge
	end
	return (1 - (1 - p) ^ threshold) / p
end

function Odds.evaluate(data: any): any
	local luck = Odds.formulas:luck(data, 0)
	local cooldown = Odds.formulas:rollCooldown(data)
	local perMinute = 60 / (cooldown + RollConfig.AutoRollExtraDelay)
	local chances = Odds.core:chances(luck)
	local atLeast = {}
	local acc = 0
	for i = #RarityConfig.List, 1, -1 do
		local id = RarityConfig.List[i].Id
		acc += chances[id] or 0
		atLeast[id] = acc
	end
	local pity = {}
	for _, rule in RollConfig.Pity do
		pity[rule.MinRarity] = rule.Threshold
	end
	local out = { luck = luck, effectiveLuck = Odds.core:effectiveLuck(luck), perMinute = perMinute, rarity = {} }
	for _, id in { "Legendary", "Mythic", "Divine", "Secret" } do
		-- "1 em X" = chance de ESSA raridade ou melhor (com pity onde existe)
		local rolls = withPity(atLeast[id], pity[id])
		out.rarity[id] = { oneIn = rolls, minutes = rolls / perMinute, perHour = 60 * perMinute / rolls }
	end
	return out
end

return Odds
