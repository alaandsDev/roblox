-- Metas de raridade da auditoria pré-Studio (ver RNG.md / RNG_SIMULATION.md)
local T = require("./TestLib")
local Rng = require("./Rng")
local Odds = require("../tools/sim/Odds")
local RollConfig = require("../src/shared/Config/RollConfig")
local describe, it, expect = T.describe, T.it, T.expect

local results = {}
for _, scenario in Odds.Scenarios do
	results[scenario.id] = Odds.evaluate(scenario.data)
end

describe("Odds reais por cenário (todos os multiplicadores + velocidade do AUTO)", function()
	it("Secreto: jogador novo ≈ 1 a cada 2+ dias de AUTO", function()
		expect(results.A.rarity.Secret.perHour < 0.05).toBeTruthy()
	end)

	it("Secreto: 30 min / 1 h continuam excepcionais (< 1 a cada 5 h)", function()
		expect(results.B.rarity.Secret.perHour < 0.2).toBeTruthy()
		expect(results.C.rarity.Secret.perHour < 0.2).toBeTruthy()
	end)

	it("Secreto: midgame/late alcançável mas raro (< 1 a cada 2 h)", function()
		expect(results.D.rarity.Secret.perHour < 0.5).toBeTruthy()
		expect(results.E.rarity.Secret.perHour < 0.5).toBeTruthy()
	end)

	it("Secreto: máximo absoluto (F2P e com monetização) nunca vira drop comum (< 1 por hora)", function()
		expect(results.F.rarity.Secret.perHour < 1).toBeTruthy()
		expect(results.G.rarity.Secret.perHour < 1).toBeTruthy()
	end)

	it("Pay-to-win limitado: sorte paga < 25% por roll; Roll Rápido = no máximo 2x rolls por hora", function()
		-- chance POR ROLL (1 em X): retornos decrescentes da Luck seguram a monetização
		expect(results.G.rarity.Secret.oneIn > results.F.rarity.Secret.oneIn / 1.25).toBeTruthy()
		-- cadência: normal 60/min, Roll Rápido 120/min (RollConfig.RollSpeed), nunca mais que isso
		expect(results.F.perMinute).toBe(60)
		expect(results.G.perMinute).toBe(120)
		expect(results.G.rarity.Secret.perHour < results.F.rarity.Secret.perHour * 2 * 1.25).toBeTruthy()
	end)

	it("Divino é um grande acontecimento (novo < 0.5/h, máximo < 3/h)", function()
		expect(results.A.rarity.Divine.perHour < 0.5).toBeTruthy()
		expect(results.G.rarity.Divine.perHour < 3).toBeTruthy()
	end)

	it("Mítico é raro (novo < 10/h) e Lendário é alcançável (novo > 30/h)", function()
		expect(results.A.rarity.Mythic.perHour < 10).toBeTruthy()
		expect(results.A.rarity.Legendary.perHour > 30).toBeTruthy()
	end)

	it("Luck 1x -> 2x é perceptível (Secreto ao menos 2x mais provável)", function()
		local base = Odds.core:chances(1).Secret
		local double = Odds.core:chances(2).Secret
		expect(double / base > 2).toBeTruthy()
	end)

	it("Luck alta satura: 100x não dá nem 25x a chance base do Secreto", function()
		expect(Odds.core:chances(100).Secret / Odds.core:chances(1).Secret < 25).toBeTruthy()
	end)
end)

describe("Pity não infla raridades acima do piso", function()
	it("com o pity Lendário ativo, a chance de Secreto é a NATURAL (simulação de 300.000 rolls)", function()
		local N = 300000
		local rand1, rand2 = Rng.new(77), Rng.new(77)
		local withPity, natural = 0, 0
		for _ = 1, N do
			if Odds.core:pickWithFloor(1, rand1, "Legendary") == "Secret" then
				withPity += 1
			end
			if Odds.core:pickRarity(1, rand2) == "Secret" then
				natural += 1
			end
		end
		-- mesma sequência aleatória => exatamente a mesma quantidade
		expect(withPity).toBe(natural)
	end)

	it("pity dispara -> raridade EXATA do piso quando o sorteio natural ficou abaixo", function()
		local result = Odds.core:roll(1, { Legendary = 49, Mythic = 0 }, function()
			return 0
		end)
		expect(result.rarity).toBe("Legendary")
		expect(result.pityTriggered).toBe("Legendary")
		local mythic = Odds.core:roll(1, { Legendary = 0, Mythic = RollConfig.Pity[2].Threshold - 1 }, function()
			return 0
		end)
		expect(mythic.rarity).toBe("Mythic")
	end)
end)

return true
