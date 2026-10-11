local T = require("./TestLib")
local BaseProgression = require("../src/shared/Modules/BaseProgression")
local BaseProgressionConfig = require("../src/shared/Config/BaseProgressionConfig")
local BaseConfig = require("../src/shared/Config/BaseConfig")
local describe, it, expect = T.describe, T.it, T.expect

local progression = BaseProgression.new(BaseProgressionConfig, BaseConfig.SlotsPerSide * 2)

describe("BaseProgression (Rebirth -> andares/slots)", function()
	it("configuração atual é válida", function()
		local problems = progression:validate(BaseConfig.MaxFloors)
		if #problems > 0 then
			error(table.concat(problems, "; "))
		end
	end)

	it("RB0: só Floor01, slots 1-4 liberados (lado A inteiro)", function()
		local s = progression:state(0)
		expect(s.unlockedFloors).toBe(1)
		expect(s.count).toBe(4)
		for slot = 1, 4 do
			expect(progression:isSlotUnlocked(0, slot)).toBe(true)
		end
	end)

	it("RB0: slots 5-8 (lado B) bloqueados", function()
		for slot = 5, 8 do
			expect(progression:isSlotUnlocked(0, slot)).toBe(false)
		end
	end)

	it("RB0: Floor02 não existe", function()
		expect(progression:isFloorUnlocked(0, 1)).toBe(true)
		expect(progression:isFloorUnlocked(0, 2)).toBe(false)
	end)

	it("RB1-RB4 (regra final da Fase 8): +1 slot do lado B por rebirth, ainda 1 andar", function()
		for rb = 1, 4 do
			local s = progression:state(rb)
			expect(s.rebirth).toBe(rb)
			expect(s.count).toBe(4 + rb)
			expect(s.unlockedFloors).toBe(1)
			expect(progression:isSlotUnlocked(rb, 4 + rb)).toBe(true)
			expect(progression:isSlotUnlocked(rb, 5 + rb)).toBe(false)
		end
	end)

	it("RB5: Floor02 permitido", function()
		expect(progression:isFloorUnlocked(5, 2)).toBe(true)
		expect(progression:state(5).unlockedFloors).toBe(2)
	end)

	it("RB5: Slot09 permitido, total 9; Slot10 ainda bloqueado", function()
		expect(progression:isSlotUnlocked(5, 9)).toBe(true)
		expect(progression:state(5).count).toBe(9)
		expect(progression:isSlotUnlocked(5, 10)).toBe(false)
		for slot = 1, 8 do
			expect(progression:isSlotUnlocked(5, slot)).toBe(true)
		end
	end)

	it("rebirth acima do último marco usa o último marco (RB36 = 40 slots, 5 andares)", function()
		expect(progression:state(99).rebirth).toBe(36)
		expect(progression:state(99).count).toBe(40)
		expect(progression:state(99).unlockedFloors).toBe(5)
	end)

	it("requisito de cada slot (nil = ainda não definido)", function()
		expect(progression:slotUnlockRebirth(1)).toBe(0)
		expect(progression:slotUnlockRebirth(5)).toBe(1)
		expect(progression:slotUnlockRebirth(9)).toBe(5)
		expect(progression:slotUnlockRebirth(10)).toBe(6)
		expect(progression:slotUnlockRebirth(41)).toBeNil()
		expect(progression:floorUnlockRebirth(2)).toBe(5)
		expect(progression:floorUnlockRebirth(3)).toBe(13)
		expect(progression:floorUnlockRebirth(5)).toBe(29)
	end)

	it("detecta configuração inválida", function()
		local bad = BaseProgression.new({
			Milestones = {
				[1] = { UnlockedFloors = 1, UnlockedSlots = { 1, 2, 9 } }, -- sem RB0; slot 9 sem andar
				[3] = { UnlockedFloors = 1, UnlockedSlots = { 1 } }, -- bloqueia de novo o 2
			},
		}, 8)
		local problems = bad:validate(5)
		expect(#problems >= 3).toBeTruthy()
	end)

	it("configuração usa lista explícita (sem fórmula)", function()
		for _, milestone in BaseProgressionConfig.Milestones do
			expect(type(milestone.UnlockedSlots)).toBe("table")
		end
	end)
end)

return true
