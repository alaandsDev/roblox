local T = require("./TestLib")
local DailyCore = require("../src/shared/Modules/DailyCore")
local Config = require("../src/shared/Config/DailyConfig")
local describe, it, expect = T.describe, T.it, T.expect

local DAY = Config.DayLength
local START = 20000 * DAY + 3600 -- 01:00 UTC de um dia qualquer

local function empty(): any
	return { LastDailyClaim = 0, DailyStreak = 0, DailyCycleDay = 0 }
end

describe("Recompensas diárias", function()
	it("7 recompensas, Dia 7 é o dado exclusivo (original)", function()
		expect(#Config.Rewards).toBe(7)
		expect(Config.Rewards[7].Kind).toBe("Dice")
	end)

	it("primeiro login: Dia 1 disponível", function()
		local status = DailyCore.status(empty(), START, Config)
		expect(status.canClaim).toBe(true)
		expect(status.day).toBe(1)
	end)

	it("resgata Dia 1 e não resgata de novo no mesmo dia (double claim / spam)", function()
		local state, day = DailyCore.claim(empty(), START, Config)
		expect(day).toBe(1)
		for _ = 1, 20 do
			local again, d2, err = DailyCore.claim(state, START + 60, Config)
			expect(again).toBeNil()
			expect(d2).toBeNil()
			expect(err).toBe("already_claimed")
		end
		-- ainda no mesmo dia UTC (23:59)
		local _, _, err = DailyCore.claim(state, (20000 + 1) * DAY - 1, Config)
		expect(err).toBe("already_claimed")
	end)

	it("dia seguinte (mesmo com menos de 24 h) avança", function()
		local state = DailyCore.claim(empty(), (20000 + 1) * DAY - 60, Config) -- 23:59
		local s2, day = DailyCore.claim(state, (20000 + 1) * DAY + 60, Config) -- 00:01 do dia seguinte
		expect(day).toBe(2)
		expect(s2.DailyStreak).toBe(2)
	end)

	it("sequência até o Dia 7 e o ciclo recomeça no Dia 1 (streak continua)", function()
		local state = empty()
		for i = 1, 7 do
			local s, day = DailyCore.claim(state, START + (i - 1) * DAY, Config)
			expect(day).toBe(i)
			state = s
		end
		expect(state.DailyStreak).toBe(7)
		local s8, day8 = DailyCore.claim(state, START + 7 * DAY, Config)
		expect(day8).toBe(1)
		expect(s8.DailyStreak).toBe(8)
	end)

	it("perdeu um dia: volta ao Dia 1 e streak reinicia", function()
		local state = DailyCore.claim(empty(), START, Config)
		state = DailyCore.claim(state, START + DAY, Config)
		local status = DailyCore.status(state, START + 3 * DAY, Config)
		expect(status.reset).toBe(true)
		local s, day = DailyCore.claim(state, START + 3 * DAY, Config)
		expect(day).toBe(1)
		expect(s.DailyStreak).toBe(1)
	end)

	it("último resgate no futuro (corrompido): recomeça no Dia 1, sem travar o jogador", function()
		local status = DailyCore.status({ LastDailyClaim = START + 10 * DAY, DailyStreak = 4, DailyCycleDay = 4 }, START, Config)
		expect(status.canClaim).toBe(true)
		expect(status.day).toBe(1)
		expect(status.corrupted).toBe(true)
	end)

	it("estado inválido (NaN, texto) é tratado como vazio", function()
		local status = DailyCore.status({ LastDailyClaim = 0 / 0, DailyStreak = "x", DailyCycleDay = 99 }, START, Config)
		expect(status.canClaim).toBe(true)
		expect(status.day).toBe(1)
	end)

	it("relógio inválido: não entrega", function()
		local s, _, err = DailyCore.claim(empty(), 0 / 0, Config)
		expect(s).toBeNil()
		expect(err).toBe("invalid_time")
	end)
end)

return true
