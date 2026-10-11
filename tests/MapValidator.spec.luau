local T = require("./TestLib")
local MapValidator = require("../src/server/Core/MapValidator")
local describe, it, expect = T.describe, T.it, T.expect

local function goodBase(id)
	local function side(name, first)
		local slots = {}
		for i = 1, 4 do
			table.insert(slots, { name = string.format("Slot%02d", first + i - 1), slotId = first + i - 1, side = name, index = i, floorId = 1 })
		end
		return slots
	end
	return {
		name = string.format("Base%02d", id),
		baseId = id,
		hasPlayerSpawn = true,
		hasOwnerSign = true,
		hasMoneyCollector = true,
		hasUpgradeArea = true,
		hasRuntimeCharacters = true,
		floors = { { name = "Floor01", floorId = 1, sides = { A = side("A", 1), B = side("B", 5) } } },
	}
end

local function goodMap()
	local bases = {}
	for id = 1, 10 do
		table.insert(bases, goodBase(id))
	end
	return { points = { HubSpawn = true, ShopSpawn = true, TowerEntrance = true }, bases = bases }
end

local function has(problems, text)
	for _, p in problems do
		if string.find(p, text, 1, true) then
			return true
		end
	end
	return false
end

describe("MapValidator", function()
	it("mapa correto: sem problemas", function()
		expect(#MapValidator.validate(goodMap(), 10, 4)).toBe(0)
	end)

	it("detecta base faltando", function()
		local map = goodMap()
		table.remove(map.bases)
		expect(has(MapValidator.validate(map, 10, 4), "esperadas 10 bases")).toBeTruthy()
	end)

	it("detecta BaseId repetido", function()
		local map = goodMap()
		map.bases[2].baseId = 1
		expect(has(MapValidator.validate(map, 10, 4), "BaseId 1 repetido")).toBeTruthy()
	end)

	it("detecta falta de PlayerSpawn/OwnerSign/MoneyCollector/UpgradeArea", function()
		local map = goodMap()
		map.bases[3].hasPlayerSpawn = false
		map.bases[4].hasOwnerSign = false
		map.bases[5].hasMoneyCollector = false
		map.bases[6].hasUpgradeArea = false
		local problems = MapValidator.validate(map, 10, 4)
		expect(has(problems, "Base03: falta PlayerSpawn")).toBeTruthy()
		expect(has(problems, "Base04: falta OwnerSign")).toBeTruthy()
		expect(has(problems, "Base05: falta MoneyCollector")).toBeTruthy()
		expect(has(problems, "Base06: falta UpgradeArea")).toBeTruthy()
	end)

	it("detecta lado com quantidade errada de slots (ex.: 2+2)", function()
		local map = goodMap()
		table.remove(map.bases[1].floors[1].sides.A)
		table.remove(map.bases[1].floors[1].sides.A)
		expect(has(MapValidator.validate(map, 10, 4), "SideA: esperados 4 slots, encontrados 2")).toBeTruthy()
	end)

	it("detecta Floor01 ou SideB ausentes", function()
		local map = goodMap()
		map.bases[1].floors = {}
		map.bases[2].floors[1].sides.B = nil
		local problems = MapValidator.validate(map, 10, 4)
		expect(has(problems, "Base01: falta Floor01")).toBeTruthy()
		expect(has(problems, "Base02/Floor01: falta SideB")).toBeTruthy()
	end)

	it("detecta SlotId repetido e lado errado", function()
		local map = goodMap()
		map.bases[1].floors[1].sides.B[1].slotId = 1
		map.bases[1].floors[1].sides.B[2].side = "A"
		local problems = MapValidator.validate(map, 10, 4)
		expect(has(problems, "SlotId 1 repetido")).toBeTruthy()
		expect(has(problems, "atributo Side = A, esperado B")).toBeTruthy()
	end)

	it("detecta pontos de teleporte ausentes", function()
		local map = goodMap()
		map.points.ShopSpawn = nil
		expect(has(MapValidator.validate(map, 10, 4), "ponto ShopSpawn")).toBeTruthy()
	end)
end)

return true
