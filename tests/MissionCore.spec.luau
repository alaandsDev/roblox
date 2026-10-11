local T = require("./TestLib")
local MissionCore = require("../src/shared/Modules/MissionCore")
local MissionConfig = require("../src/shared/Config/MissionConfig")
local describe, it, expect = T.describe, T.it, T.expect

local DAY = MissionConfig.DayLength

describe("Missões", function()
	it("3 diárias, sem repetir, iguais para o mesmo jogador e dia", function()
		local a = MissionCore.dailyIds(123, 20000, MissionConfig)
		local b = MissionCore.dailyIds(123, 20000, MissionConfig)
		expect(#a).toBe(MissionConfig.DailyCount)
		expect(table.concat(a, ",")).toBe(table.concat(b, ","))
		local seen = {}
		for _, id in a do
			expect(seen[id]).toBeNil()
			seen[id] = true
		end
	end)

	it("dias diferentes costumam trocar as missões", function()
		local different = 0
		for day = 1, 10 do
			if table.concat(MissionCore.dailyIds(5, day, MissionConfig), ",") ~= table.concat(MissionCore.dailyIds(5, day + 1, MissionConfig), ",") then
				different += 1
			end
		end
		expect(different >= 7).toBeTruthy()
	end)

	it("vira o dia: zera as diárias e mantém as conquistas", function()
		local m = MissionCore.ensureDay(nil, 1, 100 * DAY, MissionConfig)
		m.Achievements.rolls = 2
		local same, changed = MissionCore.ensureDay(m, 1, 100 * DAY + 50, MissionConfig)
		expect(changed).toBe(false)
		expect(same).toBe(m)
		local nextDay, changed2 = MissionCore.ensureDay(m, 1, 101 * DAY + 1, MissionConfig)
		expect(changed2).toBe(true)
		expect(nextDay.Day).toBe(101)
		expect(nextDay.Achievements.rolls).toBe(2)
	end)

	it("eventos avançam só as missões certas e param no alvo", function()
		local m = { Day = 1, Daily = { roll_50 = { Progress = 49, Claimed = false }, tower_3 = { Progress = 0, Claimed = false } }, Achievements = {} }
		local changed = MissionCore.apply(m, "Roll", {}, MissionConfig)
		expect(#changed).toBe(1)
		expect(m.Daily.roll_50.Progress).toBe(50)
		MissionCore.apply(m, "Roll", {}, MissionConfig)
		expect(m.Daily.roll_50.Progress).toBe(50)
		expect(m.Daily.tower_3.Progress).toBe(0)
	end)

	it("conquistas: estatísticas e nível resgatável", function()
		local data = { Rolls = 1500, Index = { a = {}, b = {} }, TowerProgress = { Ember = 12, Storm = 3 }, Missions = { Achievements = { rolls = 1 } } }
		expect(MissionCore.stat(data, "Discovered")).toBe(2)
		expect(MissionCore.stat(data, "TowerFloors")).toBe(15)
		local rolls = MissionConfig.Achievements[1]
		expect(MissionCore.claimableTier(data, rolls)).toBe(2)
		data.Missions.Achievements.rolls = 2
		expect(MissionCore.claimableTier(data, rolls)).toBeNil()
	end)
end)

return true
