local T = require("./TestLib")
local Formulas = require("../src/shared/Modules/Formulas")
local describe, it, expect = T.describe, T.it, T.expect

local DK = require("../src/shared/Config/CharacterConfig").ById.dragon_knight.BaseIncome
local LevelCfg = require("../src/shared/Config/CharacterLevelConfig")
local f = Formulas.new({
	Dice = require("../src/shared/Config/DiceConfig"),
	Upgrades = require("../src/shared/Config/UpgradeConfig"),
	Roll = require("../src/shared/Config/RollConfig"),
	Economy = require("../src/shared/Config/EconomyConfig"),
	Characters = require("../src/shared/Config/CharacterConfig"),
	Levels = require("../src/shared/Config/CharacterLevelConfig"),
	Variants = require("../src/shared/Config/VariantConfig"),
})

local function data(over: any?): any
	local d: any = { EquippedDice = "Normal", Upgrades = {}, Inventory = {}, EquippedCharacters = {} }
	for k, v in over or {} do
		d[k] = v
	end
	return d
end

describe("Formulas", function()
	it("Luck = dado * (1 + nível * 8%)", function()
		expect(f:luck(data())).toBe(1)
		expect(f:luck(data({ EquippedDice = "Flame" }))).toBe(1.6)
		expect(math.abs(f:luck(data({ EquippedDice = "Storm", Upgrades = { Luck = 5 } })) - 2.8) < 1e-9).toBeTruthy()
	end)

	it("dado inexistente usa o Normal", function()
		expect(f:luck(data({ EquippedDice = "Hacker" }))).toBe(1)
	end)

	it("velocidade do roll: 1 roll/s fixo; melhoria de velocidade não empilha (RollConfig.RollSpeed)", function()
		expect(f:rollCooldown(data())).toBe(1)
		expect(f:rollCooldown(data({ Upgrades = { RollSpeed = 999 } }))).toBe(1)
		expect(f:rollCooldown(data({ Runtime = { FastRoll = true } }))).toBe(0.5)
		expect(f:rollCooldown(data({ Runtime = { FastRoll = true }, Upgrades = { RollSpeed = 999 } }))).toBe(0.5)
		expect(f:rollsPerSecond(data())).toBe(1)
		expect(f:upgradeEnabled("RollSpeed")).toBe(false)
		expect(f:upgradeEnabled("Luck")).toBe(true)
		expect(f:perkEnabled("Speed")).toBe(false)
		expect(f:perkEnabled("Income")).toBe(true)
	end)

	it("capacidade cresce 10 por nível", function()
		expect(f:capacity(data())).toBe(100)
		expect(f:capacity(data({ Upgrades = { Inventory = 3 } }))).toBe(130)
	end)

	it("renda = soma dos equipados * multiplicador", function()
		local d = data({
			Inventory = { c1 = { Id = "flame_rookie" }, c2 = { Id = "dragon_knight" }, c3 = { Id = "void_emperor" } },
			EquippedCharacters = { ["1"] = "c1", ["2"] = "c2" },
			Upgrades = { Income = 2 },
		})
		expect(math.abs(f:incomePerSecond(d) - (1 + DK) * 1.2) < 1e-9).toBeTruthy()
	end)

	it("renda ignora uid equipado que não existe mais", function()
		expect(f:incomePerSecond(data({ EquippedCharacters = { ["1"] = "c99" } }))).toBe(0)
	end)

	it("valor de venda configurável por raridade", function()
		expect(f:sellValue("flame_rookie")).toBe(12)
		expect(f:sellValue("dragon_knight")).toBe(DK * 20)
		expect(f:sellValue("nao_existe")).toBe(0)
	end)

	it("renda por unidade: Level e Variant multiplicam", function()
		expect(f:unitIncome({ Id = "dragon_knight", Level = 1 })).toBe(DK)
		expect(f:unitIncome({ Id = "dragon_knight", Level = 5 })).toBe(DK * (1 + 4 * LevelCfg.IncomePerLevel))
		expect(f:unitIncome({ Id = "dragon_knight", Level = 1, Variant = "Gold" })).toBe(DK * 2)
		-- nível acima do máximo é limitado
		expect(f:unitIncome({ Id = "flame_rookie", Level = 9999 })).toBe(1 + (LevelCfg.MaxLevel - 1) * LevelCfg.IncomePerLevel)
	end)

	it("renda total usa o Level de cada estação", function()
		local d = data({
			Inventory = { c1 = { Id = "flame_rookie", Level = 3 }, c2 = { Id = "dragon_knight", Level = 1 } },
			EquippedCharacters = { ["1"] = "c1", ["2"] = "c2" },
		})
		expect(f:incomePerSecond(d)).toBe(1 + 2 * LevelCfg.IncomePerLevel + DK)
	end)

	it("custo de upgrade de personagem: fórmula e soma de x5", function()
		local one = f:characterUpgradeCost("dragon_knight", 1, 1)
		expect(one).toBe(math.floor(DK * LevelCfg.BaseCostSeconds))
		local five, n = f:characterUpgradeCost("dragon_knight", 1, 5)
		local sum = 0
		for L = 1, 5 do
			sum += f:characterUpgradeCost("dragon_knight", L, 1)
		end
		expect(n).toBe(5)
		expect(five).toBe(sum)
	end)

	it("custo de upgrade de personagem para no MaxLevel", function()
		local _, n = f:characterUpgradeCost("flame_rookie", 48, 10)
		expect(n).toBe(2)
		local cost, none = f:characterUpgradeCost("flame_rookie", 50, 1)
		expect(none).toBe(0)
		expect(cost).toBe(0)
	end)

	it("MAX: maior quantidade que o dinheiro paga", function()
		local c1 = f:characterUpgradeCost("dragon_knight", 1, 1)
		local c2 = f:characterUpgradeCost("dragon_knight", 2, 1)
		local count, spent = f:affordableLevels("dragon_knight", 1, c1 + c2 + 1)
		expect(count).toBe(2)
		expect(spent).toBe(c1 + c2)
	end)

	it("boost de Luck só vale até expirar", function()
		local d = data({ Boosts = { Luck = { Multiplier = 2, ExpiresAt = 1000 } } })
		expect(f:luck(d, 999)).toBe(2)
		expect(f:luck(d, 1000)).toBe(1)
		expect(f:luck(d)).toBe(1)
	end)

	it("venda usa multiplicador da variante", function()
		expect(f:sellValue("flame_rookie", "Gold")).toBe(24)
	end)

	it("Renascimento: multiplicadores permanentes, custo e fichas", function()
		local RebirthConfig = require("../src/shared/Config/RebirthConfig")
		local g = Formulas.new({
			Dice = require("../src/shared/Config/DiceConfig"),
			Upgrades = require("../src/shared/Config/UpgradeConfig"),
			Roll = require("../src/shared/Config/RollConfig"),
			Economy = require("../src/shared/Config/EconomyConfig"),
			Characters = require("../src/shared/Config/CharacterConfig"),
			Levels = LevelCfg,
			Variants = require("../src/shared/Config/VariantConfig"),
			Rebirth = RebirthConfig,
		})
		local d = data({ Rebirths = 2, RebirthPerks = { Income = 1, Luck = 2, Speed = 5, Capacity = 2 } })
		expect(math.abs(g:incomeMultiplier(d) - (1 + 2 * 0.25 + 0.15)) < 1e-9).toBeTruthy()
		expect(math.abs(g:luck(d) - (1 + 2 * RebirthConfig.LuckPerRebirth + 2 * RebirthConfig.PerksById.Luck.PerLevel)) < 1e-9).toBeTruthy()
		-- sorte do renascimento tem teto
		local many = data({ Rebirths = 36 })
		expect(math.abs(g:rebirthMultiplier(many, "Luck") - (1 + RebirthConfig.LuckRebirthCap)) < 1e-9).toBeTruthy()
		expect(g:effectiveLuck(many) <= 1 + require("../src/shared/Config/RollConfig").LuckSoftCap).toBeTruthy()
		expect(g:capacity(d)).toBe(100 + 50)
		-- perk "Mãos Rápidas" não muda o intervalo (RollSpeed.UpgradesAffectInterval = false)
		expect(g:rollCooldown(d)).toBe(1)
		expect(g:rebirthCost(0)).toBe(RebirthConfig.BaseCost)
		expect(g:rebirthCost(1)).toBe(RebirthConfig.BaseCost * RebirthConfig.Growth)
		expect(g:rebirthCost(RebirthConfig.MaxRebirths)).toBeNil()
		expect(g:rebirthTokens(1)).toBe(1)
		expect(g:rebirthTokens(5)).toBe(2)
		expect(g:perkCost("Luck", 0)).toBe(1)
		expect(g:perkCost("Luck", 10)).toBeNil()
		-- runtime (gamepass/amigos)
		d.Runtime = { Income = 2, Luck = 2, Capacity = 50 }
		expect(math.abs(g:incomeMultiplier(d) - 2 * (1 + 2 * 0.25 + 0.15)) < 1e-9).toBeTruthy()
		expect(g:capacity(d)).toBe(200)
	end)

	it("custo de upgrade cresce e para no nível máximo", function()
		local a, b = f:upgradeCost("Luck", 0), f:upgradeCost("Luck", 1)
		expect(a ~= nil and b ~= nil and (b :: number) > (a :: number)).toBeTruthy()
		expect(f:upgradeCost("Luck", 20)).toBeNil()
		expect(f:upgradeCost("Luck", 0)).toBe(require("../src/shared/Config/UpgradeConfig").ById.Luck.BaseCost)
		expect(f:upgradeCost("Nada", 0)).toBeNil()
	end)
end)

return true
