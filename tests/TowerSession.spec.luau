-- Torre contínua (TowerSessionCore): estados, AUTO, idempotência da recompensa, fim da sessão
local T = require("./TestLib")
local TowerSessionCore = require("../src/shared/Modules/TowerSessionCore")
local TowerConfig = require("../src/shared/Config/TowerConfig")
local describe, it, expect = T.describe, T.it, T.expect

local INTERVAL = TowerConfig.Session.StageInterval
local function reward(m: number?): any
	return { money = m or 100, gems = 0 }
end

describe("Torre contínua (sessão)", function()
	it("config: intervalo >= cooldown de batalha e teto de estágios", function()
		expect(INTERVAL >= TowerConfig.BattleCooldown).toBeTruthy()
		expect(TowerConfig.Session.MaxStagesPerSession > 0).toBeTruthy()
	end)

	it("começa no próximo andar do progresso salvo; torre completa não abre sessão", function()
		local s = TowerSessionCore.new("Ember", 7, 30, true, 50)
		assert(s)
		expect(s.nextFloor).toBe(8)
		expect(s.status).toBe("running")
		local none, err = TowerSessionCore.new("Ember", 30, 30, true, 50)
		expect(none).toBeNil()
		expect(err).toBe("tower_complete")
	end)

	it("AUTO: vitória -> recompensa uma vez -> próximo andar, continua rodando", function()
		local s = TowerSessionCore.new("Ember", 0, 30, true, 50)
		assert(s)
		expect(TowerSessionCore.canFight(s, 0, INTERVAL)).toBe(true)
		expect(TowerSessionCore.applyResult(s, 1, true, reward(150), 0.8, 0)).toBe(true)
		expect(s.nextFloor).toBe(2)
		expect(s.status).toBe("running")
		expect(s.totals.money).toBe(150)
		-- respeita o intervalo
		local ok, why = TowerSessionCore.canFight(s, INTERVAL - 0.1, INTERVAL)
		expect(ok).toBe(false)
		expect(why).toBe("cooldown")
		expect(TowerSessionCore.canFight(s, INTERVAL, INTERVAL)).toBe(true)
	end)

	it("idempotente: o mesmo andar nunca recompensa duas vezes; andar errado é recusado", function()
		local s = TowerSessionCore.new("Ember", 0, 30, true, 50)
		assert(s)
		expect(TowerSessionCore.applyResult(s, 1, true, reward(), 1, 0)).toBe(true)
		expect(TowerSessionCore.applyResult(s, 1, true, reward(), 1, 10)).toBe(false)
		expect(TowerSessionCore.applyResult(s, 5, true, reward(), 1, 20)).toBe(false)
		expect(s.totals.money).toBe(100)
		expect(s.totals.floors).toBe(1)
	end)

	it("derrota encerra a sessão e NÃO volta ao andar 1", function()
		local s = TowerSessionCore.new("Ember", 3, 30, true, 50)
		assert(s)
		TowerSessionCore.applyResult(s, 4, false, reward(0), 0, 0)
		expect(s.status).toBe("ended")
		expect(s.endReason).toBe("defeat")
		expect(s.nextFloor).toBe(4)
		expect(TowerSessionCore.canFight(s, 100, INTERVAL)).toBe(false)
		expect(TowerSessionCore.resume(s)).toBe(false)
	end)

	it("manual: vitória pausa; PRÓXIMO continua; ligar AUTO na pausa continua", function()
		local s = TowerSessionCore.new("Ember", 0, 30, false, 50)
		assert(s)
		TowerSessionCore.applyResult(s, 1, true, reward(), 1, 0)
		expect(s.status).toBe("paused")
		expect(TowerSessionCore.canFight(s, 100, INTERVAL)).toBe(false)
		expect(TowerSessionCore.resume(s)).toBe(true)
		TowerSessionCore.applyResult(s, 2, true, reward(), 1, 10)
		expect(s.status).toBe("paused")
		TowerSessionCore.setAuto(s, true)
		expect(s.status).toBe("running")
	end)

	it("PARAR / desconexão encerram; teto de estágios e torre completa também", function()
		local s = TowerSessionCore.new("Ember", 0, 30, true, 50)
		assert(s)
		TowerSessionCore.stop(s, "stopped")
		expect(TowerSessionCore.isActive(s)).toBe(false)
		expect(TowerSessionCore.applyResult(s, 1, true, reward(), 1, 0)).toBe(false)

		local capped = TowerSessionCore.new("Ember", 0, 30, true, 3)
		assert(capped)
		for floor = 1, 3 do
			TowerSessionCore.applyResult(capped, floor, true, reward(), 1, floor * 10)
		end
		expect(capped.endReason).toBe("session_limit")

		local last = TowerSessionCore.new("Ember", 29, 30, true, 50)
		assert(last)
		TowerSessionCore.applyResult(last, 30, true, reward(), 1, 0)
		expect(last.endReason).toBe("tower_complete")
	end)

	it("sessão finita: no máximo os andares restantes da torre (sem farm infinito)", function()
		local tower = TowerConfig.ById.Ember
		local s = TowerSessionCore.new("Ember", 0, tower.Floors, true, 1000)
		assert(s)
		local rewarded = 0
		for step = 1, 500 do
			if not TowerSessionCore.isActive(s) then
				break
			end
			if TowerSessionCore.applyResult(s, s.nextFloor, true, reward(), 1, step * INTERVAL) then
				rewarded += 1
			end
		end
		expect(rewarded).toBe(tower.Floors)
		expect(s.endReason).toBe("tower_complete")
	end)

	it("resumo para o painel OCULTAR: andar, HP do time, ganhos", function()
		local s = TowerSessionCore.new("Storm", 0, 40, true, 50)
		assert(s)
		TowerSessionCore.applyResult(s, 1, true, { money = 500, gems = 5 }, 0.42, 0)
		local sum = TowerSessionCore.summary(s)
		expect(sum.floor).toBe(2)
		expect(sum.teamHp).toBe(0.42)
		expect(sum.money).toBe(500)
		expect(sum.gems).toBe(5)
		expect(sum.auto).toBe(true)
	end)
end)

return true
