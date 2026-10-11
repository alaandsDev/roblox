local T = require("./TestLib")
local FusionCore = require("../src/server/Core/FusionCore")
local InventoryCore = require("../src/server/Core/InventoryCore")
local describe, it, expect = T.describe, T.it, T.expect

local configs = {
	Fusion = require("../src/shared/Config/FusionConfig"),
	Variants = require("../src/shared/Config/VariantConfig"),
	Characters = require("../src/shared/Config/CharacterConfig"),
	Inventory = InventoryCore,
}

local function fresh(): any
	return { Inventory = {}, EquippedCharacters = {}, NextUid = 1 }
end

describe("Fusão", function()
	it("3 iguais Normal -> Prata, nível = maior, custo pela fórmula", function()
		local d = fresh()
		local a = InventoryCore.add(d, "dragon_knight", 0)
		local b = InventoryCore.add(d, "dragon_knight", 0)
		local c = InventoryCore.add(d, "dragon_knight", 0)
		d.Inventory[b].Level = 7
		local plan, err = FusionCore.plan(d, { a, b, c }, configs)
		expect(err).toBeNil()
		assert(plan)
		expect(plan.toVariant).toBe("Silver")
		expect(plan.level).toBe(7)
		expect(plan.cost).toBe(configs.Characters.ById.dragon_knight.BaseIncome * configs.Fusion.CostSeconds * 2)
	end)

	it("recusa: quantidade errada, repetidos, personagens/variantes diferentes", function()
		local d = fresh()
		local a = InventoryCore.add(d, "dragon_knight", 0)
		local b = InventoryCore.add(d, "dragon_knight", 0)
		local c = InventoryCore.add(d, "flame_rookie", 0)
		local _, e1 = FusionCore.plan(d, { a, b }, configs)
		expect(e1).toBe("fusion_count")
		local _, e2 = FusionCore.plan(d, { a, a, b }, configs)
		expect(e2).toBe("fusion_count")
		local _, e3 = FusionCore.plan(d, { a, b, c }, configs)
		expect(e3).toBe("fusion_mismatch")
		local c2 = InventoryCore.add(d, "dragon_knight", 0, "Gold")
		local _, e4 = FusionCore.plan(d, { a, b, c2 }, configs)
		expect(e4).toBe("fusion_mismatch")
	end)

	it("protegidos não entram; não é dono não entra", function()
		local d = fresh()
		local a = InventoryCore.add(d, "dragon_knight", 0)
		local b = InventoryCore.add(d, "dragon_knight", 0)
		local c = InventoryCore.add(d, "dragon_knight", 0)
		InventoryCore.setFlag(d, a, "Locked", true)
		local _, e = FusionCore.plan(d, { a, b, c }, configs)
		expect(e).toBe("locked")
		local _, e2 = FusionCore.plan(d, { "c999", b, c }, configs)
		expect(e2).toBe("not_owned")
	end)

	it("Celestial é a última variante", function()
		local d = fresh()
		local u = {}
		for i = 1, 3 do
			u[i] = InventoryCore.add(d, "flame_rookie", 0, "Celestial")
		end
		local _, e = FusionCore.plan(d, u, configs)
		expect(e).toBe("fusion_max")
	end)

	it("Diamante -> Esmeralda precisa de 2; e 3 nessa etapa é recusado", function()
		local d = fresh()
		local a = InventoryCore.add(d, "void_emperor", 0, "Diamond")
		local b = InventoryCore.add(d, "void_emperor", 0, "Diamond")
		local c = InventoryCore.add(d, "void_emperor", 0, "Diamond")
		local plan = FusionCore.plan(d, { a, b }, configs)
		expect(plan ~= nil and plan.toVariant == "Emerald").toBeTruthy()
		local _, err = FusionCore.plan(d, { a, b, c }, configs)
		expect(err).toBe("fusion_count")
	end)

	it("matemática: cópias Normais acumuladas para cada variante (Celestial = 216)", function()
		local total = 1
		local expected = { Silver = 3, Gold = 9, Diamond = 27, Emerald = 54, Void = 108, Celestial = 216 }
		for _, v in configs.Variants.List do
			if v.Id ~= "Normal" then
				total *= FusionCore.required(configs, v.Id)
				expect(total).toBe(expected[v.Id])
			end
		end
	end)

	it("grupos prontos para fundir", function()
		local d = fresh()
		for _ = 1, 4 do
			InventoryCore.add(d, "flame_rookie", 0)
		end
		InventoryCore.add(d, "dragon_knight", 0)
		local groups = FusionCore.groups(d, configs)
		expect(#groups).toBe(1)
		expect(groups[1].characterId).toBe("flame_rookie")
		expect(#groups[1].uids).toBe(3)
		expect(groups[1].count).toBe(4)
	end)
end)

return true
