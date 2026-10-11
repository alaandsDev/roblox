local T = require("./TestLib")
local TradeCore = require("../src/server/Core/TradeCore")
local InventoryCore = require("../src/server/Core/InventoryCore")
local describe, it, expect = T.describe, T.it, T.expect

local function fresh(): any
	return { Inventory = {}, EquippedCharacters = {}, NextUid = 1 }
end

describe("Trocas", function()
	it("troca atômica: itens mudam de dono com nível e variante", function()
		local a, b = fresh(), fresh()
		local x = InventoryCore.add(a, "dragon_knight", 0, "Gold")
		a.Inventory[x].Level = 9
		local y = InventoryCore.add(b, "void_emperor", 0)
		local ok, err, newA, newB = TradeCore.execute(a, b, { x }, { y }, 100, 100, 50, InventoryCore)
		expect(ok).toBe(true)
		expect(err).toBeNil()
		expect(a.Inventory[x]).toBeNil()
		expect(a.Inventory[newA[1]].Id).toBe("void_emperor")
		local got = b.Inventory[newB[1]]
		expect(got.Id).toBe("dragon_knight")
		expect(got.Variant).toBe("Gold")
		expect(got.Level).toBe(9)
	end)

	it("protegidos não podem ser oferecidos", function()
		local a = fresh()
		local x = InventoryCore.add(a, "dragon_knight", 0)
		local y = InventoryCore.add(a, "dragon_knight", 0)
		InventoryCore.setFlag(a, x, "Favorite", true)
		InventoryCore.equip(a, y, 1, { [1] = true })
		expect(TradeCore.validateOffer(a, { x }, 8, InventoryCore)).toBe("favorite")
		expect(TradeCore.validateOffer(a, { y }, 8, InventoryCore)).toBe("equipped")
		expect(TradeCore.validateOffer(a, { "c99" }, 8, InventoryCore)).toBe("not_owned")
	end)

	it("limites: máximo de itens, repetidos, troca vazia, inventário cheio", function()
		local a, b = fresh(), fresh()
		local x = InventoryCore.add(a, "flame_rookie", 0)
		expect(TradeCore.validateOffer(a, { x, x }, 8, InventoryCore)).toBe("trade_duplicate")
		expect(TradeCore.validateOffer(a, { x }, 0, InventoryCore)).toBe("trade_too_many")
		local ok, err = TradeCore.execute(a, b, {}, {}, 100, 100, 0, InventoryCore)
		expect(ok).toBe(false)
		expect(err).toBe("trade_empty")
		InventoryCore.add(b, "flame_rookie", 0)
		local ok2, err2 = TradeCore.execute(a, b, { x }, {}, 100, 1, 0, InventoryCore)
		expect(ok2).toBe(false)
		expect(err2).toBe("trade_full_b")
		-- nada mudou depois da falha
		expect(a.Inventory[x] ~= nil).toBeTruthy()
	end)
end)

return true
