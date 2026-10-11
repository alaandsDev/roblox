local T = require("./TestLib")
local Rng = require("./Rng")
local JackpotCore = require("../src/shared/Modules/JackpotCore")
local JackpotConfig = require("../src/shared/Config/JackpotConfig")
local MonetizationConfig = require("../src/shared/Config/MonetizationConfig")
local describe, it, expect = T.describe, T.it, T.expect

describe("Jackpot e monetização", function()
	it("chances somam 1 e batem com a simulação", function()
		local chances = JackpotCore.chances(JackpotConfig.Rewards)
		local sum = 0
		for _, c in chances do
			sum += c
		end
		expect(math.abs(sum - 1) < 1e-9).toBeTruthy()
		local rand = Rng.new(3)
		local counts = {}
		local N = 200000
		for _ = 1, N do
			local r = JackpotCore.pick(JackpotConfig.Rewards, rand)
			counts[r.Id] = (counts[r.Id] or 0) + 1
		end
		for id, p in chances do
			expect(math.abs((counts[id] or 0) / N - p) < 0.01).toBeTruthy()
		end
	end)

	it("rand nos extremos devolve o primeiro e o último prêmio", function()
		expect(JackpotCore.pick(JackpotConfig.Rewards, function()
			return 0
		end).Id).toBe(JackpotConfig.Rewards[1].Id)
		expect(JackpotCore.pick(JackpotConfig.Rewards, function()
			return 0.999999
		end).Id).toBe(JackpotConfig.Rewards[#JackpotConfig.Rewards].Id)
	end)

	it("boost: maior vence, igual soma tempo", function()
		local b = JackpotCore.mergeBoost(nil, 2, 100, 1000)
		expect(b.ExpiresAt).toBe(1100)
		b = JackpotCore.mergeBoost(b, 2, 100, 1050)
		expect(b.ExpiresAt).toBe(1200)
		local stronger = JackpotCore.mergeBoost(b, 3, 50, 1060)
		expect(stronger.Multiplier).toBe(3)
		local weaker = JackpotCore.mergeBoost(stronger, 2, 500, 1070)
		expect(weaker.Multiplier).toBe(3)
		expect(weaker.ExpiresAt).toBe(1570)
	end)

	it("IDs ainda não criados (0) e nenhum ID repetido", function()
		local seen = {}
		for _, group in { MonetizationConfig.GamePasses, MonetizationConfig.Products } do
			for key, item in group do
				expect(type(item.PriceRobux) == "number" and item.PriceRobux > 0).toBeTruthy()
				if item.Id ~= 0 then
					expect(seen[item.Id]).toBeNil()
					seen[item.Id] = key
				end
			end
		end
	end)
end)

return true
