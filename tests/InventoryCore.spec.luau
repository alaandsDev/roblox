local T = require("./TestLib")
local InventoryCore = require("../src/server/Core/InventoryCore")
local CharacterConfig = require("../src/shared/Config/CharacterConfig")
local describe, it, expect = T.describe, T.it, T.expect

local RB0 = { [1] = true, [2] = true, [3] = true, [4] = true }

local function fresh(): any
	return { Inventory = {}, EquippedCharacters = {}, NextUid = 1 }
end

describe("InventoryCore: uids", function()
	it("uids únicos (10.000 adições)", function()
		local d = fresh()
		local seen = {}
		for i = 1, 10000 do
			local uid = InventoryCore.add(d, "flame_rookie", i)
			expect(seen[uid]).toBeNil()
			seen[uid] = true
		end
		expect(InventoryCore.count(d)).toBe(10000)
	end)

	it("uid não é reaproveitado depois de remover", function()
		local d = fresh()
		local a = InventoryCore.add(d, "flame_rookie", 0)
		InventoryCore.remove(d, a)
		expect(InventoryCore.add(d, "flame_rookie", 0) ~= a).toBeTruthy()
	end)

	it("instância nova tem os campos do schema", function()
		local d = fresh()
		local item = d.Inventory[InventoryCore.add(d, "dragon_knight", 123)]
		expect(item.Id).toBe("dragon_knight")
		expect(item.Locked).toBe(false)
		expect(item.Favorite).toBe(false)
		expect(item.Variant).toBe("Normal")
		expect(item.ObtainedAt).toBe(123)
	end)
end)

describe("InventoryCore: equipar", function()
	it("equipa no primeiro slot livre (RB0 = 1..4)", function()
		local d = fresh()
		local uids = {}
		for i = 1, 5 do
			uids[i] = InventoryCore.add(d, "flame_rookie", i)
		end
		for i = 1, 4 do
			local ok, _, slot = InventoryCore.equip(d, uids[i], nil, RB0)
			expect(ok).toBe(true)
			expect(slot).toBe(i)
		end
		local ok, err = InventoryCore.equip(d, uids[5], nil, RB0)
		expect(ok).toBe(false)
		expect(err).toBe("no_free_slot")
	end)

	it("RB0 recusa slot 5..8 (bloqueado)", function()
		local d = fresh()
		local uid = InventoryCore.add(d, "flame_rookie", 0)
		local ok, err = InventoryCore.equip(d, uid, 5, RB0)
		expect(ok).toBe(false)
		expect(err).toBe("slot_locked")
		local _, err2 = InventoryCore.equip(d, uid, 99, RB0)
		expect(err2).toBe("slot_locked")
	end)

	it("recusa uid que não é do jogador", function()
		local _, err = InventoryCore.equip(fresh(), "c404", nil, RB0)
		expect(err).toBe("not_owned")
	end)

	it("recusa slot ocupado e move o próprio personagem de slot", function()
		local d = fresh()
		local a = InventoryCore.add(d, "flame_rookie", 0)
		local b = InventoryCore.add(d, "flame_rookie", 0)
		InventoryCore.equip(d, a, 1, RB0)
		local _, err = InventoryCore.equip(d, b, 1, RB0)
		expect(err).toBe("slot_occupied")
		expect(InventoryCore.equip(d, a, 3, RB0)).toBe(true)
		expect(d.EquippedCharacters["1"]).toBeNil()
		expect(d.EquippedCharacters["3"]).toBe(a)
	end)

	it("um personagem nunca ocupa dois slots", function()
		local d = fresh()
		local a = InventoryCore.add(d, "flame_rookie", 0)
		InventoryCore.equip(d, a, 1, RB0)
		InventoryCore.equip(d, a, nil, RB0)
		local n = 0
		for _, uid in d.EquippedCharacters do
			if uid == a then
				n += 1
			end
		end
		expect(n).toBe(1)
	end)

	it("desequipar", function()
		local d = fresh()
		local a = InventoryCore.add(d, "flame_rookie", 0)
		InventoryCore.equip(d, a, 2, RB0)
		expect(InventoryCore.unequip(d, a)).toBe(true)
		expect(InventoryCore.slotOf(d, a)).toBeNil()
		local _, err = InventoryCore.unequip(d, a)
		expect(err).toBe("not_equipped")
	end)

	it("EQUIPAR MELHORES: maior renda, empate por power", function()
		local d = fresh()
		local ids = { "flame_rookie", "dragon_knight", "stone_brawler", "spark_cadet", "void_emperor", "wind_disciple" }
		for _, id in ids do
			InventoryCore.add(d, id, 0)
		end
		expect(InventoryCore.equipBest(d, RB0, CharacterConfig.ById)).toBe(4)
		local equipped = {}
		for slot, uid in d.EquippedCharacters do
			equipped[tonumber(slot) :: number] = d.Inventory[uid].Id
		end
		expect(equipped[1]).toBe("void_emperor")
		expect(equipped[2]).toBe("dragon_knight")
		-- stone_brawler e spark_cadet têm renda 2; stone tem mais power
		expect(equipped[3]).toBe("stone_brawler")
		expect(equipped[4]).toBe("spark_cadet")
	end)

	it("slots inválidos são limpos quando a progressão muda", function()
		local d = fresh()
		local a = InventoryCore.add(d, "flame_rookie", 0)
		d.EquippedCharacters["7"] = a
		d.EquippedCharacters["2"] = "c999"
		InventoryCore.dropInvalidSlots(d, RB0)
		expect(next(d.EquippedCharacters)).toBeNil()
	end)
end)

describe("InventoryCore: venda", function()
	local function value(): number
		return 10
	end

	it("travado, favorito e equipado nunca são vendidos", function()
		local d = fresh()
		local locked = InventoryCore.add(d, "flame_rookie", 0)
		local fav = InventoryCore.add(d, "flame_rookie", 0)
		local equipped = InventoryCore.add(d, "flame_rookie", 0)
		local free = InventoryCore.add(d, "flame_rookie", 0)
		InventoryCore.setFlag(d, locked, "Locked", true)
		InventoryCore.setFlag(d, fav, "Favorite", true)
		InventoryCore.equip(d, equipped, 1, RB0)
		local plan = InventoryCore.planSale(d, { locked, fav, equipped, free, free, "c999" }, value)
		expect(#plan.uids).toBe(1)
		expect(plan.uids[1]).toBe(free)
		expect(plan.total).toBe(10)
		expect(plan.skipped).toBe(4)
		expect(InventoryCore.executeSale(d, plan)).toBe(10)
		expect(d.Inventory[free]).toBeNil()
		expect(d.Inventory[locked] ~= nil).toBeTruthy()
	end)

	it("flag inválida é recusada", function()
		local d = fresh()
		local a = InventoryCore.add(d, "flame_rookie", 0)
		local ok, err = InventoryCore.setFlag(d, a, "Equipped", true)
		expect(ok).toBe(false)
		expect(err).toBe("invalid_flag")
	end)

	it("vender duplicatas mantém 1 de cada (o protegido ou o mais antigo)", function()
		local d = fresh()
		local oldest = InventoryCore.add(d, "flame_rookie", 1)
		InventoryCore.add(d, "flame_rookie", 2)
		InventoryCore.add(d, "flame_rookie", 3)
		local fav = InventoryCore.add(d, "spark_cadet", 5)
		local spark2 = InventoryCore.add(d, "spark_cadet", 1)
		InventoryCore.setFlag(d, fav, "Favorite", true)
		InventoryCore.add(d, "dragon_knight", 1)
		local selected = InventoryCore.selectBatch(d, "Duplicates", CharacterConfig.ById)
		expect(#selected).toBe(3)
		expect(table.find(selected, oldest)).toBeNil()
		expect(table.find(selected, fav)).toBeNil()
		expect(table.find(selected, spark2) ~= nil).toBeTruthy()
	end)

	it("vender comuns pula protegidos e outras raridades", function()
		local d = fresh()
		local a = InventoryCore.add(d, "flame_rookie", 0)
		local b = InventoryCore.add(d, "wind_disciple", 0)
		InventoryCore.add(d, "shadow_scout", 0)
		InventoryCore.setFlag(d, b, "Locked", true)
		local selected = InventoryCore.selectBatch(d, "Rarity:Common", CharacterConfig.ById)
		expect(#selected).toBe(1)
		expect(selected[1]).toBe(a)
	end)

	it("item em troca: protegido contra venda/fusão e não equipável; a trava é só em memória", function()
		local d = fresh()
		local a = InventoryCore.add(d, "flame_rookie", 0)
		local b = InventoryCore.add(d, "flame_rookie", 0)
		InventoryCore.setTradeLocks(d, { a })
		expect(InventoryCore.protection(d, a)).toBe("in_trade")
		expect(InventoryCore.protection(d, b)).toBeNil()
		local ok, err = InventoryCore.equip(d, a, 1, { [1] = true })
		expect(ok).toBe(false)
		expect(err).toBe("in_trade")
		local selected = InventoryCore.selectBatch(d, "Rarity:Common", CharacterConfig.ById)
		expect(#selected).toBe(1)
		expect(selected[1]).toBe(b)
		expect(d.TradeLocks).toBeNil()
		InventoryCore.setTradeLocks(d, nil)
		expect(InventoryCore.protection(d, a)).toBeNil()
	end)
end)

return true
