-- AuraMotion: fitas/rajadas/raios das auras se movem como energia viva, com personalidade por estilo
local T = require("./TestLib")
local AuraMotion = require("../src/shared/Modules/AuraMotion")
local AuraConfig = require("../src/shared/Config/AuraConfig")
local AuraPlanner = require("../src/shared/Modules/AuraPlanner")
local CharacterConfig = require("../src/shared/Config/CharacterConfig")
local DiceConfig = require("../src/shared/Config/DiceConfig")
local describe, it, expect = T.describe, T.it, T.expect

local FIELDS = { "Speed", "Arc", "Spin", "Breath", "BreathSpeed", "Bob", "Rise", "Curve", "CurveSpeed", "Jitter", "JitterRate", "Step", "Asym", "Pulse", "PulseSpeed", "Tip" }
local RIBBON = { index = 1, angle = 0.4, twist = 1.6, radius = 3, y0 = -3, y1 = 3, curve = 2.5, amp = 1 }
local FPS = 30

local function ribbonWith(amp: number, index: number?): any
	local r = table.clone(RIBBON)
	r.amp = amp
	r.index = index or 1
	return r
end

-- percorre `seconds` a 30 Hz e mede amplitude/velocidade das pontas
local function sample(profile: any, ribbon: any, seconds: number, t0: number?)
	local minAx, maxAx, minBx, maxBx, minBy, maxBy = math.huge, -math.huge, math.huge, -math.huge, math.huge, -math.huge
	local travel, maxStep, still, steps = 0, 0, 0, 0
	local sumBy = 0
	local last = nil
	for f = 0, seconds * FPS do
		local p = AuraMotion.ribbon(profile, ribbon, (t0 or 0) + f / FPS)
		minAx, maxAx = math.min(minAx, p.ax), math.max(maxAx, p.ax)
		minBx, maxBx = math.min(minBx, p.bx), math.max(maxBx, p.bx)
		minBy, maxBy = math.min(minBy, p.by), math.max(maxBy, p.by)
		sumBy += p.by
		if last then
			local d = math.sqrt((p.bx - last.bx) ^ 2 + (p.by - last.by) ^ 2 + (p.bz - last.bz) ^ 2)
			travel += d
			maxStep = math.max(maxStep, d)
			steps += 1
			if d < 0.004 then
				still += 1
			end
		end
		last = p
	end
	return {
		rangeA = maxAx - minAx,
		rangeB = maxBx - minBx,
		rangeY = maxBy - minBy,
		speed = travel / seconds,
		maxStep = maxStep,
		stillFrac = still / math.max(steps, 1),
		meanBy = sumBy / (seconds * FPS + 1),
	}
end

describe("AuraMotion: formas grandes vivas (não uma fita presa nas costas)", function()
	it("todo estilo tem perfil de movimento completo", function()
		for name in AuraConfig.Styles do
			local m = AuraConfig.Motion[name]
			expect(m ~= nil).toBeTruthy()
			for _, k in FIELDS do
				expect(type(m[k]) == "number").toBeTruthy()
			end
		end
		expect(AuraConfig.DefaultMotion ~= nil).toBeTruthy()
	end)

	it("em todos os estilos as PONTAS se movem (não só a curvatura) e a curvatura muda", function()
		for name, m in AuraConfig.Motion do
			local s = sample(m, ribbonWith(1), 8)
			expect(s.rangeB > 0.4 and s.speed > 0.2).toBeTruthy()
			local c0a = AuraMotion.ribbon(m, ribbonWith(1), 0).curve0
			local c0b = AuraMotion.ribbon(m, ribbonWith(1), 1.3).curve0
			expect(math.abs(c0a - c0b) > 0.01).toBeTruthy()
			local _ = name
		end
	end)

	it("nada acumula: depois de horas a forma continua presa à aura (posição limitada)", function()
		for _, m in AuraConfig.Motion do
			for _, t in { 0, 3600, 100000, 1000000 } do
				for f = 0, 20 do
					local p = AuraMotion.ribbon(m, ribbonWith(AuraConfig.FullScale.Amplitude), t + f / FPS)
					local limit = RIBBON.radius * (1 + m.Breath * 1.5) * 1.05
					expect(math.sqrt(p.ax ^ 2 + p.az ^ 2) <= limit).toBeTruthy()
					expect(math.sqrt(p.bx ^ 2 + p.bz ^ 2) <= limit).toBeTruthy()
					expect(p.ay >= RIBBON.y0 - m.Bob * 1.5 - 0.01 and p.ay <= RIBBON.y0 + m.Bob * 1.5 + 0.01).toBeTruthy()
					expect(p.by <= RIBBON.y1 + (m.Bob + m.Rise) * 1.5 + 0.01).toBeTruthy()
					expect(p.width > 0 and p.width < 2).toBeTruthy()
				end
			end
		end
	end)

	it("a ponta de cima serpenteia mais que a de baixo (não gira como hélice rígida)", function()
		for _, m in AuraConfig.Motion do
			if m.Tip >= 0.5 and m.Step == 0 then
				local s = sample(m, ribbonWith(1), 12)
				expect(s.rangeB >= s.rangeA * 0.75).toBeTruthy()
			end
		end
	end)
end)

describe("AuraMotion: personalidade por estilo", function()
	local M = AuraConfig.Motion
	it("Electric é rápido e nervoso (saltos); Void/Dark lentos e pesados", function()
		local e = sample(M.Electric, ribbonWith(1), 8)
		local v = sample(M.Void, ribbonWith(1), 8)
		local d = sample(M.Dark, ribbonWith(1), 8)
		local c = sample(M.Celestial, ribbonWith(1), 8)
		expect(e.speed > v.speed * 2 and e.speed > d.speed * 2).toBeTruthy()
		-- saltos bruscos: o maior passo de um quadro é bem maior que o passo médio
		expect(e.maxStep > (e.speed / FPS) * 3).toBeTruthy()
		-- os suaves não saltam
		expect(c.maxStep < (c.speed / FPS) * 3).toBeTruthy()
	end)

	it("Flame sobe (a ponta de cima fica acima da posição-base em média)", function()
		local f = sample(M.Flame, ribbonWith(1), 10)
		local v = sample(M.Void, ribbonWith(1), 10)
		expect(f.meanBy > RIBBON.y1 + 0.3).toBeTruthy()
		expect(f.meanBy > v.meanBy).toBeTruthy()
	end)

	it("Ice é preciso: anda em degraus (muitos quadros parados entre saltos curtos)", function()
		local i = sample(M.Ice, ribbonWith(1), 12)
		local w = sample(M.Wind, ribbonWith(1), 12)
		expect(i.stillFrac > w.stillFrac).toBeTruthy()
	end)

	it("Wind e Celestial circulam (giro contínuo); cada fita gira num sentido", function()
		for _, name in { "Wind", "Celestial" } do
			local m = M[name]
			expect(m.Spin > 0).toBeTruthy()
			-- soma dos deltas DESENROLADOS (o giro é guardado em módulo 2π)
			local function turned(index: number): number
				local total, last = 0, AuraMotion.swing(m, index, 0, 1)
				for f = 1, 10 * FPS do
					local now = AuraMotion.swing(m, index, f / FPS, 1)
					local d = (now - last + math.pi) % (2 * math.pi) - math.pi
					total += d
					last = now
				end
				return total
			end
			local a1, a2 = turned(1), turned(2)
			expect(math.abs(a1) > 2 and math.abs(a2) > 2 and a1 * a2 < 0).toBeTruthy()
		end
		expect(sample(M.Wind, ribbonWith(1), 8).speed > sample(M.Celestial, ribbonWith(1), 8).speed).toBeTruthy()
	end)

	it("Energy e Gravity respiram (expandem/contraem); Void/Dark/Spirit assimétricos entre fitas", function()
		expect(M.Energy.Breath >= 0.25 and M.Gravity.Breath >= 0.25).toBeTruthy()
		for _, name in { "Void", "Dark", "Spirit" } do
			expect(M[name].Asym >= 0.5).toBeTruthy()
		end
	end)
end)

describe("Light × Full: a mesma aura, Full liberada", function()
	local planner = AuraPlanner.new(AuraConfig, CharacterConfig, DiceConfig)
	local function anyOf(rarity: string): string
		for _, c in CharacterConfig.List do
			if c.Rarity == rarity then
				return c.Id
			end
		end
		error(rarity)
	end
	local function count(plan: any, kind: string): number
		for _, c in plan.components do
			if c.kind == kind then
				return c.count
			end
		end
		return 0
	end

	it("Full: mais amplitude de movimento, fita extra e pulsos mais frequentes; Light com as mesmas camadas", function()
		for _, rarity in { "Divine", "Secret" } do
			local light = planner:resolve(anyOf(rarity), rarity, "Light")
			local full = planner:resolve(anyOf(rarity), rarity, "Full")
			assert(light and full)
			expect(light.amplitude).toBe(1)
			expect(full.amplitude > 1.3).toBeTruthy()
			expect(count(full, "Ribbon")).toBe(count(light, "Ribbon") + AuraConfig.FullScale.ExtraRibbons)
			expect((full.pulseEvery :: number) < (light.pulseEvery :: number)).toBeTruthy()
			expect(light.layers).toBe(full.layers)
		end
		for _, name in { "Void", "Flame", "Celestial" } do
			local m = AuraConfig.Motion[name]
			local l = sample(m, ribbonWith(1), 10)
			local f = sample(m, ribbonWith(AuraConfig.FullScale.Amplitude), 10)
			expect(f.speed > l.speed and f.rangeY >= l.rangeY).toBeTruthy()
		end
	end)

	it("o Light NÃO foi enfraquecido: órbitas e assinaturas iguais ao Full, emissão 55%", function()
		for _, rarity in { "Mythic", "Divine", "Secret" } do
			local light = planner:resolve(anyOf(rarity), rarity, "Light")
			local full = planner:resolve(anyOf(rarity), rarity, "Full")
			assert(light and full)
			expect(light.orbiters).toBe(full.orbiters)
			expect(light.signatureCount).toBe(full.signatureCount)
			expect(AuraConfig.LightScale.Rate >= 0.55 and AuraConfig.LightScale.Rate <= 0.6).toBeTruthy()
		end
	end)
end)

return true
