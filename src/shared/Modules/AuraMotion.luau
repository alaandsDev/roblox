--!strict
--[[
	AuraMotion (puro): movimento ORGÂNICO das formas grandes da aura (fitas, rajadas, raios) e
	personalidade das órbitas, por estilo (AuraConfig.Motion). Usado pelo AuraController no loop
	central (nenhum Tween, nenhum loop por aura); testado em tests/AuraMotion.spec.luau.

	Tudo é ABSOLUTO no tempo (posição = f(t)): nada acumula, nada "foge" do personagem, e o
	resultado é relativo ao AuraCore (segue o personagem quando ele anda/vira/teleporta).

	Ingredientes (combinados por estilo):
	    swing   balanço parcial em volta do corpo (soma de senos = "ruído" barato e determinístico)
	    spin    giro contínuo (Celestial/Wind/Energy), com sentido alternado por fita
	    breath  raio respirando (expande/contrai)
	    bob     sobe/desce
	    rise    a ponta de cima sobe e cai como chama (Flame)
	    jitter  saltos curtos e bruscos em tempos discretos (Electric)
	    step    ângulo em degraus com transição curta (Ice: preciso/rígido)
	    asym    cada fita com frequência própria (Void/Dark/Spirit: assimétrico)
	    pulse   largura pulsando (Energy/Ice)
	    tip     a ponta de cima anda mais que a de baixo (a fita serpenteia, não gira rígida)
]]

local AuraMotion = {}

export type Profile = {
	Speed: number,
	Arc: number,
	Spin: number,
	Breath: number,
	BreathSpeed: number,
	Bob: number,
	Rise: number,
	Curve: number,
	CurveSpeed: number,
	Jitter: number,
	JitterRate: number,
	Step: number,
	Asym: number,
	Pulse: number,
	PulseSpeed: number,
	Tip: number,
}

-- parâmetros de UMA fita (gravados como atributos no Beam pelo AuraBuilder)
export type Ribbon = {
	index: number,
	angle: number, -- ângulo-base da ponta de baixo (rad)
	twist: number, -- quanto a ponta de cima está girada em relação à de baixo (rad)
	radius: number,
	y0: number,
	y1: number,
	curve: number, -- curvatura-base
	amp: number, -- 1 = Light; Full > 1
}

export type Pose = {
	ax: number,
	ay: number,
	az: number,
	bx: number,
	by: number,
	bz: number,
	curve0: number,
	curve1: number,
	width: number, -- fator da largura
}

local TAU = math.pi * 2

-- hash determinístico em [-1, 1] (jitter do Electric)
local function hash(a: number, b: number): number
	local x = math.sin(a * 12.9898 + b * 78.233) * 43758.5453
	return (x - math.floor(x)) * 2 - 1
end

local function smoothstep(x: number): number
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end

-- ângulo em degraus (Ice): fica parado e salta suavemente para o próximo
local function stepped(angle: number, steps: number): number
	if steps <= 0 then
		return angle
	end
	local unit = TAU / steps
	local a = angle / unit
	local base = math.floor(a)
	local frac = smoothstep((a - base - 0.7) / 0.3)
	return (base + frac) * unit
end

-- deslocamento angular orgânico de uma forma no instante t
function AuraMotion.swing(profile: Profile, index: number, t: number, amp: number): number
	local phase = index * 1.7
	local freq = profile.Speed * (1 + profile.Asym * math.sin(index * 2.3))
	local swing = profile.Arc * amp * (math.sin(t * freq + phase) + 0.35 * math.sin(t * freq * 1.73 + phase * 2.1))
	local dir = if index % 2 == 0 then -1 else 1
	-- Full (amp > 1) também gira mais rápido: a aura "liberada"
	local spin = profile.Spin * (1 + 0.5 * (amp - 1))
	local angle = swing + ((spin * t * dir) % TAU)
	if profile.Jitter > 0 then
		local tick = math.floor(t * profile.JitterRate)
		angle += profile.Jitter * amp * hash(tick, index)
	end
	return stepped(angle, profile.Step)
end

function AuraMotion.ribbon(profile: Profile, r: Ribbon, t: number): Pose
	local phase = r.index * 1.7
	local amp = r.amp
	local turn = AuraMotion.swing(profile, r.index, t, amp)
	local breath = 1 + profile.Breath * amp * math.sin(t * profile.BreathSpeed + phase)
	local radius = r.radius * breath
	local bob = profile.Bob * amp
	local f = profile.Speed * (1 + profile.Asym * math.sin(r.index * 2.3))
	-- ponta de baixo: balança e respira
	local a = r.angle + turn
	local ay = r.y0 + bob * math.sin(t * f * 0.8 + phase)
	-- ponta de cima: anda MAIS (Tip) e com fase própria -> a fita serpenteia
	local b = r.angle + r.twist + turn * (1 + profile.Tip) + 0.4 * profile.Arc * amp * math.sin(t * f * 1.37 + phase * 1.3)
	local rb = radius * (0.78 + 0.12 * math.sin(t * profile.BreathSpeed * 1.21 + phase))
	local rise = profile.Rise * amp * (0.5 + 0.5 * math.sin(t * f * 1.6 + phase * 0.7)) ^ 2
	local by = r.y1 + bob * math.sin(t * f * 1.1 + phase + 1.3) + rise
	local cs = profile.CurveSpeed
	local curve0 = r.curve + profile.Curve * amp * math.sin(t * cs + phase)
	local curve1 = -r.curve - profile.Curve * amp * math.cos(t * cs * 1.27 + phase * 1.3)
	if profile.Jitter > 0 then
		local tick = math.floor(t * profile.JitterRate * 1.5)
		curve0 += profile.Curve * 0.8 * hash(tick, r.index + 0.5)
		curve1 += profile.Curve * 0.8 * hash(tick + 0.3, r.index)
	end
	local width = 1 + profile.Pulse * math.sin(t * profile.PulseSpeed + phase)
	return {
		ax = math.cos(a) * radius,
		ay = ay,
		az = math.sin(a) * radius,
		bx = math.cos(b) * rb,
		by = by,
		bz = math.sin(b) * rb,
		curve0 = curve0,
		curve1 = curve1,
		width = math.max(0.35, width),
	}
end

-- personalidade das órbitas: deslocamento extra de ângulo, raio e altura (somado à órbita base)
function AuraMotion.orbitOffset(profile: Profile, index: number, t: number, amp: number): (number, number, number)
	local phase = index * 2.1
	local dAngle = 0
	if profile.Jitter > 0 then
		dAngle += profile.Jitter * 0.6 * amp * hash(math.floor(t * profile.JitterRate), index)
	end
	local radiusScale = 1 + profile.Breath * amp * math.sin(t * profile.BreathSpeed + phase)
	local dy = profile.Rise * 0.4 * amp * (0.5 + 0.5 * math.sin(t * profile.Speed * 1.3 + phase))
	return dAngle, radiusScale, dy
end

return AuraMotion
