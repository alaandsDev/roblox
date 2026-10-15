-- AFK Resilience (puro): estado de inatividade (só telemetria) e política de reconexão limitada
local T = require("./TestLib")
local AfkCore = require("../src/shared/Modules/AfkCore")
local ReconnectPolicy = require("../src/shared/Modules/ReconnectPolicy")
local AfkConfig = require("../src/shared/Config/AfkConfig")
local describe, it, expect = T.describe, T.it, T.expect

local R = AfkConfig.Reconnect

describe("AfkCore: Ativo / Inativo / Reconectando (sem gerar input)", function()
	it("fica Ativo até IdleAfter sem input real e vira Inativo depois", function()
		local t = AfkCore.new(AfkConfig, 100)
		expect(t:state(100)).toBe("Active")
		expect(t:state(100 + AfkConfig.IdleAfter - 1)).toBe("Active")
		expect(t:state(100 + AfkConfig.IdleAfter)).toBe("Idle")
		expect(t:idleFor(100 + 1200)).toBe(1200)
	end)

	it("input real volta para Ativo; relógio voltando não joga a atividade para o futuro", function()
		local t = AfkCore.new(AfkConfig, 0)
		t:activity(500)
		expect(t:state(510)).toBe("Active")
		t:activity(400)
		expect(t.lastActivity).toBe(500)
	end)

	it("SimulateIdle só mexe no estado interno (nenhum input, nenhum outro campo)", function()
		local t = AfkCore.new(AfkConfig, 1000)
		t:simulateIdle(1000, 1200)
		expect(t:state(1000)).toBe("Idle")
		expect(t:idleFor(1000)).toBe(1200)
		local keys = {}
		for k in t do
			table.insert(keys, k)
		end
		table.sort(keys)
		expect(table.concat(keys, ",")).toBe("idleAfter,lastActivity,reconnecting")
	end)

	it("Reconectando tem prioridade e sai com a primeira atividade", function()
		local t = AfkCore.new(AfkConfig, 0)
		t:setReconnecting(true)
		expect(t:state(5000)).toBe("Reconnecting")
		t:activity(5001)
		expect(t:state(5001)).toBe("Active")
	end)
end)

describe("ReconnectPolicy: classificação da queda", function()
	it("inatividade da PLATAFORMA e expulsão do jogo nunca reconectam sozinhas", function()
		for _, code in { "DisconnectIdle", "DisconnectLuaKick", "DisconnectDuplicatePlayer", "DisconnectClientRequest", "DisconnectRobloxMaintenance" } do
			expect((ReconnectPolicy.classify(code))).toBe("Never")
		end
		local _, reason = ReconnectPolicy.classify("DisconnectIdle")
		expect(reason).toBe("platform_idle")
	end)

	it("queda de rede/servidor fechando = automática; desconhecida = só botão", function()
		expect((ReconnectPolicy.classify("DisconnectConnectionLost"))).toBe("Auto")
		expect((ReconnectPolicy.classify("DisconnectEvicted"))).toBe("Auto")
		expect((ReconnectPolicy.classify("AlgoNovo"))).toBe("Manual")
		expect((ReconnectPolicy.classify(nil))).toBe("Manual")
	end)
end)

describe("ReconnectPolicy: tentativas limitadas, sem loop infinito de Teleport", function()
	it("1ª tentativa no MESMO servidor (se existir), depois qualquer servidor; para no limite", function()
		local plan = ReconnectPolicy.new(R, { kind = "Auto", code = "DisconnectConnectionLost", jobId = "job-1", chain = 0 })
		local s1 = plan:next(0)
		expect(s1.action).toBe("SameServer")
		expect(s1.at).toBe(R.Backoff[1])
		plan:failed("GameEnded") -- o servidor acabou: nunca prometido
		local s2 = plan:next(s1.at)
		expect(s2.action).toBe("AnyServer")
		expect(s2.at).toBe(R.Backoff[1] + R.Backoff[2])
		local s3 = plan:next(s2.at)
		expect(s3.action).toBe("AnyServer")
		local s4 = plan:next(s3.at)
		expect(s4.action).toBe("Manual")
		expect(s4.reason).toBe("attempts_exhausted")
	end)

	it("falha infinita do teleporte: no máximo MaxAttempts + MaxManual teleportes, nunca mais", function()
		local plan = ReconnectPolicy.new(R, { kind = "Auto", code = "DisconnectTimeout", jobId = "job-1", chain = 0 })
		local teleports, now = 0, 0
		for _ = 1, 1000 do
			local step = plan:next(now)
			if step.action == "SameServer" or step.action == "AnyServer" then
				teleports += 1
				now = step.at
				plan:failed("Failure")
			else
				break
			end
		end
		for _ = 1, 1000 do -- jogador clicando RECONECTAR sem parar
			now += 1
			local step = plan:manual(now)
			if step.action == "AnyServer" then
				teleports += 1
				plan:failed("Failure")
			elseif step.action == "Stop" then
				break
			end
		end
		expect(teleports).toBe(R.MaxAttempts + R.MaxManual)
		expect(plan:manual(now + 1000).action).toBe("Stop")
	end)

	it("cliques em RECONECTAR respeitam o intervalo mínimo", function()
		local plan = ReconnectPolicy.new(R, { kind = "Manual", jobId = "job-1" })
		expect(plan:next(0).action).toBe("Manual")
		expect(plan:manual(10).action).toBe("AnyServer")
		local early = plan:manual(11)
		expect(early.action).toBe("Wait")
		expect(early.at).toBe(10 + R.ManualCooldown)
	end)

	it("servidor fechando: nunca tenta o mesmo JobId", function()
		local plan = ReconnectPolicy.new(R, { kind = "Auto", code = "DisconnectEvicted", jobId = "job-1", chain = 0 })
		expect(plan:next(0).action).toBe("AnyServer")
	end)

	it("inatividade da plataforma / kick: nenhum teleporte, nem automático nem manual", function()
		local plan = ReconnectPolicy.new(R, { kind = "Never", code = "DisconnectIdle", jobId = "job-1" })
		expect(plan:next(0).action).toBe("Stop")
		expect(plan:manual(100).action).toBe("Stop")
	end)

	it("Unauthorized para tudo", function()
		local plan = ReconnectPolicy.new(R, { kind = "Auto", code = "DisconnectTimeout", jobId = "j", chain = 0 })
		plan:next(0)
		plan:failed("Unauthorized")
		expect(plan:next(100).action).toBe("Stop")
	end)

	it("reconexões ENCADEADAS param em MaxChain (sem pular de servidor em servidor)", function()
		local plan = ReconnectPolicy.new(R, { kind = "Auto", code = "DisconnectTimeout", jobId = "j", chain = R.MaxChain })
		local step = plan:next(0)
		expect(step.action).toBe("Manual")
		expect(step.reason).toBe("chain_limit")
		local data = ReconnectPolicy.new(R, { kind = "Auto", jobId = "j", chain = 1 }):teleportData(1000, "j")
		expect(data.Chain).toBe(2)
		expect(ReconnectPolicy.chainFrom(data, 1000 + 60, R)).toBe(2)
		expect(ReconnectPolicy.chainFrom(data, 1000 + R.ChainWindow + 1, R)).toBe(0)
		expect(ReconnectPolicy.chainFrom({ Reconnect = "sim", Chain = 9, At = 1000 }, 1000, R)).toBe(0)
		expect(ReconnectPolicy.chainFrom(nil, 1000, R)).toBe(0)
	end)
end)

describe("ReconnectPolicy.resumeAuto: AUTO só volta numa reconexão e com tudo pronto", function()
	local function input(over: { [string]: any }?): any
		local base = {
			autoSetting = true,
			reconnect = true,
			secondsSinceLogout = 30,
			window = AfkConfig.ResumeAutoWindow,
			dataLoaded = true,
			baseReady = true,
			characterReady = true,
			servicesReady = true,
		}
		for k, v in over or {} do
			base[k] = v
		end
		return base
	end
	it("tudo pronto -> Resume", function()
		expect((ReconnectPolicy.resumeAuto(input()))).toBe("Resume")
	end)
	it("entrada normal, AUTO desligado ou saída antiga -> não volta", function()
		expect((ReconnectPolicy.resumeAuto(input({ reconnect = false })))).toBe("No")
		expect((ReconnectPolicy.resumeAuto(input({ autoSetting = false })))).toBe("No")
		expect((ReconnectPolicy.resumeAuto(input({ secondsSinceLogout = AfkConfig.ResumeAutoWindow + 1 })))).toBe("No")
		expect((ReconnectPolicy.resumeAuto(input({ secondsSinceLogout = 0 / 0 })))).toBe("No")
	end)
	it("save, base, personagem e serviços: espera cada um (nunca rola antes do PlayerData)", function()
		for _, key in { "dataLoaded", "baseReady", "characterReady", "servicesReady" } do
			local decision = ReconnectPolicy.resumeAuto(input({ [key] = false }))
			expect(decision).toBe("Wait")
		end
	end)
end)

describe("AFK não é buff", function()
	it("a config de AFK não tem nenhum multiplicador de economia/roll", function()
		local forbidden = { "Luck", "Money", "Income", "Multiplier", "RollSpeed", "Pity", "Reward", "Bonus" }
		local function scan(t: any, path: string)
			for k, v in t do
				for _, word in forbidden do
					expect(string.find(tostring(k), word, 1, true) == nil).toBeTruthy()
				end
				if type(v) == "table" then
					scan(v, path .. "." .. tostring(k))
				end
			end
		end
		scan(AfkConfig, "AfkConfig")
	end)
end)

return true
