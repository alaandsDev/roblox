-- Balanceamento APROVADO dos 16 Dice (Variante B + Divino reduzido, em DiceConfig): validade,
-- curva (ERV), metas de raridade e pity. Análise completa: DICE_BALANCE_ANALYSIS.md.
local T = require("./TestLib")
local B = require("../tools/sim/DiceBalance")
local DiceConfig = require("../src/shared/Config/DiceConfig")
local RollConfig = require("../src/shared/Config/RollConfig")
local describe, it, expect = T.describe, T.it, T.expect

local final = B.final

describe("Balanceamento dos Dice (aprovado, em produção)", function()
	it("ordem oficial da Variante B, com preço/rolls por POSIÇÃO e Luck por Dice", function()
		local order = { "Starter", "Lucky", "Rampart", "Shinobi", "Flame", "Blade", "Fighter", "Storm", "Spirit", "Arcane", "Shadow", "Void", "Colossus", "Awakened", "Celestial", "Forbidden" }
		local prices = { 0, 2500, 10000, 40000, 75000, 125000, 225000, 400000, 750000, 1400000, 2600000, 5000000, 12500000, 30000000, 75000000, 400000000 }
		local rolls = { 0, 50, 125, 300, 450, 650, 775, 1000, 1500, 2000, 2500, 3000, 4500, 6000, 8000, 12000 }
		for i, dice in final:diceList() do
			expect(dice.Id).toBe(order[i])
			expect(dice.Price).toBe(prices[i])
			expect(dice.UnlockRequirement.Rolls or 0).toBe(rolls[i])
			expect(dice.UnlockRequirement.Dice).toBe(order[i - 1])
		end
		expect(DiceConfig.ById.Shinobi.LuckMultiplier).toBe(1.7)
		expect(DiceConfig.ById.Flame.LuckMultiplier).toBe(1.6)
		expect(DiceConfig.ById.Colossus.LuckMultiplier).toBe(3.5)
		expect(DiceConfig.ById.Awakened.LuckMultiplier).toBe(3.1)
	end)

	it("pesos explícitos: os 16 Dice, soma 100%, só raridades que o pool possui (todas com peso)", function()
		local n = 0
		for _, dice in final:diceList() do
			n += 1
			local weights = dice.RarityWeights
			expect(weights ~= nil).toBeTruthy()
			local sum = 0
			for rarity, value in weights do
				expect(value > 0).toBeTruthy()
				expect(final:supports(dice.Id, rarity)).toBe(true)
				sum += value
			end
			for _, rarity in final:pool(dice.Id).rarities do
				expect(weights[rarity] ~= nil).toBeTruthy()
			end
			expect(math.abs(sum - 100) < 1e-9).toBeTruthy()
		end
		expect(n).toBe(16)
	end)

	it("Expected Rarity Value estritamente crescente do #1 ao #16 (Luck 1)", function()
		local prev = -1
		for _, dice in final:diceList() do
			local erv = B.erv(final, dice.Id, 1)
			if erv <= prev then
				error(`{dice.Id}: ERV {erv} <= {prev}`)
			end
			prev = erv
		end
	end)

	it("Forbidden: Secreto 0,0045% e < 1/hora no máximo absoluto (Luck + monetização + Roll Rápido)", function()
		expect(DiceConfig.ById.Forbidden.RarityWeights.Secret).toBe(0.0045)
		local scenarios = B.luckScenarios("Forbidden")
		local maxLuck = scenarios[#scenarios].luck
		local secret = final:rarityChances("Forbidden", maxLuck).Secret
		expect(secret * 3600 / RollConfig.RollSpeed.FastRollInterval < 1).toBeTruthy()
	end)

	it("Divino reduzido (Celestial 0,5% / Forbidden 0,75%) e Secreto só no Forbidden", function()
		expect(DiceConfig.ById.Celestial.RarityWeights.Divine).toBe(0.5)
		expect(DiceConfig.ById.Forbidden.RarityWeights.Divine).toBe(0.75)
		for _, dice in final:diceList() do
			local w = dice.RarityWeights
			if w.Divine then
				expect(w.Divine <= 0.75).toBeTruthy()
			end
			if w.Secret then
				expect(dice.Id).toBe("Forbidden")
			end
		end
	end)

	it("Luck nunca cria raridade ausente nem passa de 100% (Luck máxima)", function()
		for _, dice in final:diceList() do
			local scenarios = B.luckScenarios(dice.Id)
			local chances = final:rarityChances(dice.Id, scenarios[#scenarios].luck)
			local sum = 0
			for rarity, p in chances do
				expect(final:supports(dice.Id, rarity)).toBe(true)
				sum += p
			end
			expect(math.abs(sum - 1) < 1e-9).toBeTruthy()
		end
	end)

	it("pity aprovado: Lendário 50 · Mítico 250", function()
		expect(RollConfig.Pity[1].Id).toBe("Legendary")
		expect(RollConfig.Pity[1].Threshold).toBe(50)
		expect(RollConfig.Pity[2].Id).toBe("Mythic")
		expect(RollConfig.Pity[2].Threshold).toBe(250)
		-- Mítico 250 no Spirit (Mítico 1%): ~8% dos Míticos pelo pity, ~92 rolls entre Míticos
		local p = B.atLeast(final, "Spirit", "Mythic", 1)
		local s = B.pity(p, 250)
		expect(s.reach > 0.07 and s.reach < 0.09).toBeTruthy()
		expect(s.effectiveRolls > 90 and s.effectiveRolls < 93).toBeTruthy()
	end)

	it("fórmulas de pity da análise", function()
		local s = B.pity(0.01, 50)
		expect(math.abs(s.reach - 0.99 ^ 49) < 1e-12).toBeTruthy()
		expect(math.abs(s.effectiveRolls - (1 - 0.99 ^ 50) / 0.01) < 1e-9).toBeTruthy()
		expect(B.duration(1000)).toBe("16m40s")
		expect(B.duration(500)).toBe("8m20s")
	end)
end)

return true
