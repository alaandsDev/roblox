local T = require("./TestLib")
local BaseLayout = require("../src/shared/Modules/BaseLayout")
local BaseConfig = require("../src/shared/Config/BaseConfig")
local describe, it, expect = T.describe, T.it, T.expect

local layout = BaseLayout.new(BaseConfig)

describe("BaseLayout (slots 4 + 4 por andar)", function()
	it("8 slots por andar: 4 no lado A e 4 no lado B", function()
		expect(layout:slotsPerFloor()).toBe(8)
		local a, b = 0, 0
		for _, id in layout:slotsForFloor(1) do
			if layout:slotInfo(id).side == "A" then
				a += 1
			else
				b += 1
			end
		end
		expect(a).toBe(4)
		expect(b).toBe(4)
	end)

	it("Floor01: lado A = 01-04, lado B = 05-08", function()
		for i = 1, 4 do
			expect(layout:slotId(1, "A", i)).toBe(i)
			expect(layout:slotId(1, "B", i)).toBe(4 + i)
		end
		expect(layout:slotInfo(5).side).toBe("B")
		expect(layout:slotInfo(5).index).toBe(1)
		expect(layout:slotInfo(4).side).toBe("A")
		expect(layout:slotInfo(4).index).toBe(4)
	end)

	it("Floor02: lado A = 09-12, lado B = 13-16", function()
		for i = 1, 4 do
			expect(layout:slotId(2, "A", i)).toBe(8 + i)
			expect(layout:slotId(2, "B", i)).toBe(12 + i)
		end
		local info = layout:slotInfo(9)
		expect(info.floor).toBe(2)
		expect(info.side).toBe("A")
		expect(info.index).toBe(1)
		expect(layout:slotInfo(16).floor).toBe(2)
	end)

	it("lado A em +X, lado B em -X, corredor livre no meio", function()
		for _, id in layout:slotsForFloor(1) do
			local p = layout:slotPosition(id)
			local side = layout:slotInfo(id).side
			if side == "A" then
				expect(p.x > 0).toBeTruthy()
			else
				expect(p.x < 0).toBeTruthy()
			end
			-- pedestal não invade o corredor
			expect(math.abs(p.x) - BaseConfig.PedestalSize / 2 >= BaseConfig.CorridorHalfWidth).toBeTruthy()
		end
	end)

	it("slots em fileira do fundo para a entrada, sem sobreposição", function()
		for index = 1, 3 do
			local a = layout:slotPosition(layout:slotId(1, "A", index))
			local b = layout:slotPosition(layout:slotId(1, "A", index + 1))
			expect(a.z > b.z).toBeTruthy() -- Slot01 mais ao fundo
			expect(a.z - b.z >= BaseConfig.PedestalSize).toBeTruthy()
			expect(a.x).toBe(b.x) -- mesma fileira
		end
	end)

	it("todos os slots dentro da base", function()
		for floor = 1, BaseConfig.MaxFloors do
			for _, id in layout:slotsForFloor(floor) do
				local p = layout:slotPosition(id)
				local half = BaseConfig.PedestalSize / 2
				expect(math.abs(p.x) + half <= BaseConfig.Width / 2).toBeTruthy()
				expect(math.abs(p.z) + half <= BaseConfig.Depth / 2).toBeTruthy()
			end
		end
	end)

	it("personagens olham para o corredor e levemente para a entrada (orientação consistente)", function()
		local a = layout:slotPosition(1)
		local b = layout:slotPosition(5)
		expect(a.lookX < 0).toBeTruthy()
		expect(b.lookX > 0).toBeTruthy()
		expect(a.lookZ < 0 and b.lookZ < 0).toBeTruthy()
		expect(math.abs(a.lookZ - b.lookZ) < 1e-9).toBeTruthy()
		for _, id in layout:slotsForFloor(1) do
			local p = layout:slotPosition(id)
			local ref = if layout:slotInfo(id).side == "A" then a else b
			expect(p.lookX).toBe(ref.lookX)
		end
	end)

	it("altura entre andares e slots do Floor02 acima do Floor01", function()
		expect(BaseConfig.FloorHeight >= 16).toBeTruthy()
		expect(layout:slotPosition(9).y - layout:slotPosition(1).y).toBe(BaseConfig.FloorHeight)
	end)

	it("poço da rampa não encosta em nenhum pedestal e alterna de lado", function()
		expect(layout:rampSide(1)).toBe("B")
		expect(layout:rampSide(2)).toBe("A")
		for floor = 1, 2 do
			local r = layout:rampRect(floor)
			expect(math.abs(r.maxX) <= BaseConfig.Width / 2 and math.abs(r.minX) <= BaseConfig.Width / 2).toBeTruthy()
			for _, id in layout:slotsForFloor(floor) do
				local p = layout:slotPosition(id)
				local half = BaseConfig.PedestalSize / 2
				local overlapX = p.x + half > r.minX and p.x - half < r.maxX
				local overlapZ = p.z + half > r.minZ and p.z - half < r.maxZ
				expect(overlapX and overlapZ).toBeFalsy()
			end
		end
	end)

	it("nomes padronizados", function()
		expect(layout:slotName(5)).toBe("Slot05")
		expect(layout:slotName(12)).toBe("Slot12")
		expect(layout:floorName(2)).toBe("Floor02")
		expect(BaseLayout.baseName(10)).toBe("Base10")
	end)
end)

return true
