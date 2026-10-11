local T = require("./TestLib")
local Rng = require("./Rng")
local RollCore = require("../src/shared/Modules/RollCore")
local RarityConfig = require("../src/shared/Config/RarityConfig")
local CharacterConfig = require("../src/shared/Config/CharacterConfig")
local RollConfig = require("../src/shared/Config/RollConfig")
local describe, it, expect = T.describe, T.it, T.expect

local core = RollCore.new(RarityConfig, CharacterConfig, RollConfig)

local function near(a: number, b: number, tolerance: number): boolean
	return math.abs(a - b) <= tolerance
end

describe("RollCore: pesos e Luck", function()
	it("pesos base somam 100.000 e batem com as % pedidas", function()
		local expected = { Common = 55, Uncommon = 25, Rare = 12, Epic = 5, Legendary = 2, Mythic = 0.75, Divine = 0.2, Secret = 0.05 }
		local total = 0
		for _, rarity in RarityConfig.List do
			total += rarity.Weight
			expect(rarity.Weight / 1000).toBe(expected[rarity.Id])
		end
		expect(total).toBe(100000)
	end)

	it("Luck 1: chances = pesos base", function()
		local chances = core:chances(1)
		expect(near(chances.Common, 0.55, 1e-9)).toBeTruthy()
		expect(near(chances.Secret, 0.0005, 1e-9)).toBeTruthy()
	end)

	it("Luck < 1 é tratada como 1", function()
		expect(near(core:chances(0.2).Common, 0.55, 1e-9)).toBeTruthy()
	end)

	it("mais Luck => toda raridade alta fica mais provável e a Comum menos", function()
		local previous = core:chances(1)
		for _, luck in { 1.25, 1.6, 2, 2.75, 4, 10 } do
			local chances = core:chances(luck)
			expect(chances.Common < previous.Common).toBeTruthy()
			for _, id in { "Rare", "Epic", "Legendary", "Mythic", "Divine", "Secret" } do
				expect(chances[id] > previous[id]).toBeTruthy()
			end
			previous = chances
		end
	end)

	it("Luck favorece mais as raridades mais altas (ganho relativo cresce com o tier)", function()
		local base, lucky = core:chances(1), core:chances(4)
		local lastGain = 0
		for _, id in RarityConfig.Order do
			local gain = lucky[id] / base[id]
			expect(gain > lastGain).toBeTruthy()
			lastGain = gain
		end
	end)

	it("chances sempre somam 1", function()
		for _, luck in { 1, 3, 10.4 } do
			local sum = 0
			for _, c in core:chances(luck) do
				sum += c
			end
			expect(near(sum, 1, 1e-9)).toBeTruthy()
		end
	end)

	it("pickRarity: rand 0 -> Comum, rand ~1 -> Secreto", function()
		expect(core:pickRarity(1, function()
			return 0
		end)).toBe("Common")
		expect(core:pickRarity(1, function()
			return 0.99999
		end)).toBe("Secret")
	end)

	it("pickCharacter devolve personagem da raridade pedida", function()
		local rand = Rng.new(7)
		for _ = 1, 200 do
			for _, id in RarityConfig.Order do
				local characterId = core:pickCharacter(id, rand)
				expect(CharacterConfig.ById[characterId].Rarity).toBe(id)
			end
		end
	end)
end)

describe("RollCore: pity", function()
	it("pity Lendário: roll nº 50 sem Lendário+ é garantido Lendário ou melhor", function()
		local result = core:roll(1, { Legendary = 49, Mythic = 49 }, function()
			return 0
		end)
		expect(result.pityTriggered).toBe("Legendary")
		expect(core:tierOf(result.rarity) >= core:tierOf("Legendary")).toBeTruthy()
		expect(result.pity.Legendary).toBe(0)
		expect(result.pity.Mythic).toBe(50)
	end)

	it("pity Mítico vence o Lendário quando os dois disparam", function()
		local result = core:roll(1, { Legendary = 60, Mythic = 249 }, function()
			return 0
		end)
		expect(result.pityTriggered).toBe("Mythic")
		expect(result.rarity).toBe("Mythic")
		expect(result.pity.Legendary).toBe(0)
		expect(result.pity.Mythic).toBe(0)
	end)

	it("abaixo do limite não força nada", function()
		local result = core:roll(1, { Legendary = 10, Mythic = 10 }, function()
			return 0
		end)
		expect(result.pityTriggered).toBeNil()
		expect(result.rarity).toBe("Common")
		expect(result.pity.Legendary).toBe(11)
		expect(result.pity.Mythic).toBe(11)
	end)

	it("tirar Lendário naturalmente zera só o pity Lendário", function()
		local updated = core:nextPity({ Legendary = 20, Mythic = 120 }, "Legendary")
		expect(updated.Legendary).toBe(0)
		expect(updated.Mythic).toBe(121)
	end)

	it("pity vazio (perfil antigo) funciona", function()
		local result = core:roll(1, {}, Rng.new(3))
		expect(result.pity.Legendary ~= nil).toBeTruthy()
	end)

	it("nunca passa de 50 rolls sem Lendário+ (simulação de 20.000 rolls)", function()
		local rand = Rng.new(99)
		local pity = {}
		local streak, worst = 0, 0
		for _ = 1, 20000 do
			local result = core:roll(1, pity, rand)
			pity = result.pity
			if core:tierOf(result.rarity) >= core:tierOf("Legendary") then
				streak = 0
			else
				streak += 1
				worst = math.max(worst, streak)
			end
		end
		expect(worst <= 49).toBeTruthy()
	end)
end)

describe("RollCore: simulação de 1.000.000 rolls (Luck 1, sem pity)", function()
	it("distribuição observada bate com a teórica", function()
		local rand = Rng.new(12345)
		local counts = {}
		local N = 1000000
		for _ = 1, N do
			local id = core:pickRarity(1, rand)
			counts[id] = (counts[id] or 0) + 1
		end
		for id, p in core:chances(1) do
			local expected = p * N
			-- 5 desvios-padrão de folga (binomial)
			local tolerance = 5 * math.sqrt(N * p * (1 - p))
			if not near(counts[id] or 0, expected, tolerance) then
				error(`{id}: observado {counts[id]}, esperado {expected}`)
			end
		end
	end)
end)

return true
