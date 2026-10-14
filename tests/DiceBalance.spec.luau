-- Proposta de balanceamento dos 16 Dice (tools/sim/DiceBalanceProposal.luau): validade, curva e
-- metas de raridade. A proposta NÃO está aplicada em produção (DiceConfig sem RarityWeights).
local T = require("./TestLib")
local B = require("../tools/sim/DiceBalance")
local DiceConfig = require("../src/shared/Config/DiceConfig")
local RollConfig = require("../src/shared/Config/RollConfig")
local describe, it, expect = T.describe, T.it, T.expect

local P = B.Proposal

describe("Balanceamento dos Dice (proposta, não aplicada)", function()
	it("produção inalterada: nenhum Dice com RarityWeights explícito; pity 50/800", function()
		for _, dice in DiceConfig.List do
			expect(dice.RarityWeights).toBeNil()
		end
		expect(RollConfig.Pity[1].Threshold).toBe(50)
		expect(RollConfig.Pity[2].Threshold).toBe(800)
	end)

	it("pesos propostos: os 16 Dice, soma 100%, só raridades que o pool possui (todas com peso)", function()
		local n = 0
		for _, dice in B.current:diceList() do
			n += 1
			local weights = P.RarityWeights[dice.Id]
			expect(weights ~= nil).toBeTruthy()
			local sum = 0
			for rarity, value in weights do
				expect(value > 0).toBeTruthy()
				expect(B.current:supports(dice.Id, rarity)).toBe(true)
				sum += value
			end
			for _, rarity in B.current:pool(dice.Id).rarities do
				expect(weights[rarity] ~= nil).toBeTruthy()
			end
			expect(math.abs(sum - 100) < 1e-9).toBeTruthy()
		end
		expect(n).toBe(16)
		expect(#B.proposed:diceList()).toBe(16)
	end)

	it("Expected Rarity Value estritamente crescente do #1 ao #16 (ordem atual)", function()
		local prev = -1
		for _, dice in B.current:diceList() do
			local erv = B.erv(B.proposed, dice.Id, 1)
			if erv <= prev then
				error(`{dice.Id}: ERV {erv} <= {prev}`)
			end
			prev = erv
		end
	end)

	it("Variante B também sem regressão na ordem dela", function()
		local prev = -1
		for _, id in P.VariantB.Order do
			local erv = B.erv(B.variantB, id, 1)
			if erv <= prev then
				error(`Variante B, {id}: ERV {erv} <= {prev}`)
			end
			prev = erv
		end
		expect(#P.VariantB.Order).toBe(16)
	end)

	it("Forbidden: Secreto bem abaixo de 1% e < 1/hora no máximo absoluto (Luck + monetização + Roll Rápido)", function()
		expect(P.RarityWeights.Forbidden.Secret < 0.1).toBeTruthy()
		local scenarios = B.luckScenarios("Forbidden")
		local maxLuck = scenarios[#scenarios].luck
		local secret = B.proposed:rarityChances("Forbidden", maxLuck).Secret
		local perHour = secret * 3600 / RollConfig.RollSpeed.FastRollInterval
		expect(perHour < 1).toBeTruthy()
	end)

	it("Divino raro e Secreto só no Forbidden", function()
		for _, dice in B.current:diceList() do
			local w = P.RarityWeights[dice.Id]
			if w.Divine then
				expect(w.Divine <= 2).toBeTruthy()
			end
			if w.Secret then
				expect(dice.Id).toBe("Forbidden")
			end
		end
	end)

	it("Luck nunca cria raridade ausente nem passa de 100% (proposta, Luck máxima)", function()
		for _, dice in B.current:diceList() do
			local scenarios = B.luckScenarios(dice.Id)
			local chances = B.proposed:rarityChances(dice.Id, scenarios[#scenarios].luck)
			local sum = 0
			for rarity, p in chances do
				expect(B.proposed:supports(dice.Id, rarity)).toBe(true)
				sum += p
			end
			expect(math.abs(sum - 1) < 1e-9).toBeTruthy()
		end
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
