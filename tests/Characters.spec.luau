local T = require("./TestLib")
local CharacterConfig = require("../src/shared/Config/CharacterConfig")
local RarityConfig = require("../src/shared/Config/RarityConfig")
local DiceConfig = require("../src/shared/Config/DiceConfig")
local UpgradeConfig = require("../src/shared/Config/UpgradeConfig")
local describe, it, expect = T.describe, T.it, T.expect

describe("Roster e configs de progressão", function()
	it("24 personagens na distribuição pedida", function()
		local expected = { Common = 5, Uncommon = 4, Rare = 4, Epic = 3, Legendary = 3, Mythic = 2, Divine = 2, Secret = 1 }
		local counts = {}
		for _, c in CharacterConfig.List do
			counts[c.Rarity] = (counts[c.Rarity] or 0) + 1
		end
		expect(CharacterConfig.Count).toBe(24)
		for id, n in expected do
			expect(counts[id]).toBe(n)
		end
	end)

	it("todo personagem tem os campos e uma raridade válida", function()
		local seenIndex = {}
		for _, c in CharacterConfig.List do
			expect(RarityConfig.ById[c.Rarity] ~= nil).toBeTruthy()
			expect(type(c.Name) == "string" and #c.Name > 0).toBeTruthy()
			expect(c.BasePower > 0 and c.BaseIncome > 0).toBeTruthy()
			expect(type(c.ModelName)).toBe("string")
			expect(type(c.Description)).toBe("string")
			expect(type(c.VisualTheme.Icon)).toBe("string")
			expect(seenIndex[c.IndexNumber]).toBeNil()
			seenIndex[c.IndexNumber] = true
		end
	end)

	it("raridade maior => renda maior (o menor da raridade supera o maior da anterior)", function()
		local maxOf, minOf = {}, {}
		for _, c in CharacterConfig.List do
			maxOf[c.Rarity] = math.max(maxOf[c.Rarity] or 0, c.BaseIncome)
			minOf[c.Rarity] = math.min(minOf[c.Rarity] or math.huge, c.BaseIncome)
		end
		for i = 2, #RarityConfig.Order do
			expect(minOf[RarityConfig.Order[i]] > maxOf[RarityConfig.Order[i - 1]]).toBeTruthy()
		end
	end)

	it("dados: Luck pedida, preço crescente e requisito do dado anterior", function()
		local luck = { Normal = 1, Lucky = 1.25, Flame = 1.6, Storm = 2, Void = 2.75, Celestial = 4 }
		local previous = nil
		for _, d in DiceConfig.List do
			if d.Exclusive then
				continue
			end
			expect(d.LuckMultiplier).toBe(luck[d.Id])
			if previous then
				expect(d.Price > previous.Price).toBeTruthy()
				expect(d.UnlockRequirement.Dice).toBe(previous.Id)
			end
			previous = d
		end
	end)

	it("dado exclusivo (Dia 7) não está à venda", function()
		expect(DiceConfig.ById.Prism.Exclusive).toBe(true)
	end)

	it("upgrades têm custo, crescimento e nível máximo", function()
		for _, id in { "Luck", "Income", "RollSpeed", "Inventory" } do
			local u = UpgradeConfig.ById[id]
			expect(u ~= nil and u.BaseCost > 0 and u.Growth > 1 and u.MaxLevel > 0).toBeTruthy()
		end
	end)
end)

return true
