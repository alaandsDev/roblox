--!strict
--[[
	PlayerAuraBuilder: monta o VISUAL de uma PLAYER AURA no HumanoidRootPart do avatar.
	Identidade própria (NÃO reutiliza a Character Aura). ART PASS V2: identidade > quantidade.

	Composição em 3 alturas (PlayerAuraConfig.Visual):
	    PÉS      anel (círculo de 2–4 arcos Bézier) + brilho + onda periódica + rastro
	    TRONCO   energia corporal + ascendentes junto ao corpo + chamas nas laterais + orbitadores
	             + fluxos (beams curvos ANIMADOS dos quadris aos ombros) + coluna que respira
	    CABEÇA   auréola (Celestial+) e, só na ABSOLUTA, coroa de 4 pontas + faíscas
	Círculos: arcos Bézier com o eixo do attachment na TANGENTE (CurveSize = k·r) — 2 beams fazem
	um círculo inteiro; antes eram 12 segmentos retos (12 beams + 12 attachments).
	Movimento: fluxos com pontas e curvas animadas + textura correndo; auréola/coroa girando;
	anel e coluna com textura correndo (movimento sem escrita por quadro); orbitadores.
	Texturas nativas (rbxasset://); nada do Auras Pack; nenhum script no efeito; sem Highlight.

	    local fx = PlayerAuraBuilder.build(root, tierConfig)
	    PlayerAuraBuilder.clear(root)          -- respawn/troca de tier nunca duplica
	    PlayerAuraBuilder.flowPose(flow, t)    -- (puro) pose do fluxo no instante t
	    PlayerAuraBuilder.placeCircle(...)     -- reposiciona um círculo (auréola girando)
]]

local PlayerAuraBuilder = {}

local TEX = {
	Spark = "rbxasset://textures/particles/sparkles_main.dds",
	Fire = "rbxasset://textures/particles/fire_main.dds",
	Ember = "rbxasset://textures/particles/fire_sparks_main.dds",
	Smoke = "rbxasset://textures/particles/smoke_main.dds",
}
PlayerAuraBuilder.Textures = TEX

local PREFIX = "PA_"
local FOLDER = "PlayerAuraFX"
local UP = Vector3.new(0, 1, 0)

-- alturas em relação ao HumanoidRootPart (R6/R15 ~3 studs do chão)
PlayerAuraBuilder.FootY = -2.9
PlayerAuraBuilder.HeadY = 2.6
PlayerAuraBuilder.HaloY = 3.75

local function rgb(c: { number }): Color3
	return Color3.fromRGB(c[1], c[2], c[3])
end

local function attachment(root: BasePart, name: string, pos: Vector3): Attachment
	local a = Instance.new("Attachment")
	a.Name = PREFIX .. name
	a.Position = pos
	a.Parent = root
	return a
end

local function emitter(parent: Instance, name: string, props: { [string]: any }): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Name = PREFIX .. name
	e.LightEmission = 1
	e.LightInfluence = 0
	e.LockedToPart = false
	for k, v in props do
		(e :: any)[k] = v
	end
	e.Parent = parent
	return e
end

local function beam(folder: Instance, name: string, a0: Attachment, a1: Attachment, props: { [string]: any }): Beam
	local b = Instance.new("Beam")
	b.Name = PREFIX .. name
	b.Attachment0 = a0
	b.Attachment1 = a1
	b.FaceCamera = true
	b.LightEmission = 1
	b.LightInfluence = 0
	b.Segments = 12
	for k, v in props do
		(b :: any)[k] = v
	end
	b.Parent = folder
	return b
end

function PlayerAuraBuilder.clear(root: Instance)
	for _, child in root:GetChildren() do
		if string.sub(child.Name, 1, #PREFIX) == PREFIX or child.Name == FOLDER then
			child:Destroy()
		end
	end
end

-- distância do ponto de controle para um arco de círculo de `arcs` partes (Bézier cúbica)
function PlayerAuraBuilder.arcHandle(radius: number, arcs: number): number
	return (4 / 3) * math.tan(math.pi / (2 * arcs)) * radius
end

-- CFrame de um ponto do círculo: posição + eixo X (Axis) na tangente anti-horária
local function circleFrame(radius: number, y: number, angle: number, lift: number?): CFrame
	local pos = Vector3.new(math.cos(angle) * radius, y + (lift or 0), math.sin(angle) * radius)
	local tangent = Vector3.new(-math.sin(angle), 0, math.cos(angle))
	return CFrame.fromMatrix(pos, tangent, UP)
end

-- Reposiciona os pontos de um círculo (e as pontas da coroa, se houver) com giro `offset`
function PlayerAuraBuilder.placeCircle(points: { Attachment }, radius: number, y: number, offset: number, tips: { Attachment }?, tipHeight: number?)
	local n = #points
	for i, a in points do
		local angle = offset + (i - 1) / n * math.pi * 2
		a.CFrame = circleFrame(radius, y, angle)
	end
	if tips then
		local step = n / math.max(1, #tips)
		for i, tip in tips do
			local angle = offset + ((i - 1) * step) / n * math.pi * 2
			tip.CFrame = circleFrame(radius * 0.92, y, angle, tipHeight)
		end
	end
end

type Circle = { points: { Attachment }, beams: { Beam }, radius: number, y: number }

-- Círculo de `arcs` arcos Bézier (2 = dois beams entre os MESMOS 2 attachments)
local function circle(root: BasePart, folder: Instance, name: string, y: number, radius: number, arcs: number, props: { [string]: any }): Circle
	local points = {}
	for i = 1, arcs do
		local a = Instance.new("Attachment")
		a.Name = PREFIX .. name .. i
		a.CFrame = circleFrame(radius, y, (i - 1) / arcs * math.pi * 2)
		a.Parent = root
		table.insert(points, a)
	end
	local handle = PlayerAuraBuilder.arcHandle(radius, arcs)
	local beams = {}
	for i = 1, arcs do
		local merged = table.clone(props)
		merged.CurveSize0 = handle
		merged.CurveSize1 = handle
		table.insert(beams, beam(folder, name, points[i], points[i % arcs + 1], merged))
	end
	return { points = points, beams = beams, radius = radius, y = y }
end

export type Flow = { a0: Attachment, a1: Attachment, beam: Beam, angle: number, phase: number, width: number }

--[[
	Pose (pura) de um fluxo no instante t: sai do quadril e sobe girando até acima do ombro.
	Pontas e curvas oscilam com amplitude GRANDE (visível em 1–2 s); cada fluxo tem fase própria.
	Devolve (cf0, cf1, curve0, curve1).
]]
function PlayerAuraBuilder.flowPose(flow: { angle: number, phase: number }, t: number): (CFrame, CFrame, number, number)
	local p = flow.phase
	local swing = 0.55 * math.sin(t * 1.35 + p)
	local a0 = flow.angle + swing
	local a1 = flow.angle + 0.95 + 0.65 * math.sin(t * 1.8 + p * 1.7)
	local r0 = 1.35 + 0.15 * math.sin(t * 2.2 + p)
	local r1 = 1.05 + 0.2 * math.sin(t * 1.6 + p * 0.6)
	local y0 = -1.3 + 0.25 * math.sin(t * 1.9 + p)
	local y1 = PlayerAuraBuilder.HeadY + 0.4 + 0.45 * math.sin(t * 2.4 + p * 1.3)
	local cf0 = circleFrame(r0, y0, a0)
	local cf1 = circleFrame(r1, y1, a1)
	local curve0 = 2.4 * math.sin(t * 2.1 + p * 1.1)
	local curve1 = -2.1 * math.cos(t * 1.7 + p * 0.8)
	return cf0, cf1, curve0, curve1
end

export type Built = {
	tier: number,
	emitters: { { emitter: ParticleEmitter, rate: number, life: number } },
	beams: { { beam: Beam, width: number } },
	trails: { Trail },
	light: PointLight?,
	orbit: { Attachment },
	orbitRadius: number,
	flows: { Flow },
	halo: Circle?,
	crownTips: { Attachment },
	column: Beam?,
	columnWidth: number,
	pulse: ParticleEmitter?,
	pulseEvery: number,
	attachments: number,
}

-- Constrói (limpando antes). tier = linha da PlayerAuraConfig.List
function PlayerAuraBuilder.build(root: BasePart, tier: any): Built
	PlayerAuraBuilder.clear(root)
	local v = tier.Visual
	local color, accent = rgb(tier.Color), rgb(tier.Accent)
	local cs = ColorSequence.new({ ColorSequenceKeypoint.new(0, accent), ColorSequenceKeypoint.new(0.45, color), ColorSequenceKeypoint.new(1, color) })
	local folder = Instance.new("Folder")
	folder.Name = FOLDER
	folder.Parent = root
	local out: Built = {
		tier = tier.Tier,
		emitters = {},
		beams = {},
		trails = {},
		light = nil,
		orbit = {},
		orbitRadius = 2.1,
		flows = {},
		halo = nil,
		crownTips = {},
		column = nil,
		columnWidth = 0,
		pulse = nil,
		pulseEvery = v.Pulse or 0,
		attachments = 0,
	}
	local footY, headY = PlayerAuraBuilder.FootY, PlayerAuraBuilder.HeadY
	local scale = 1 + (tier.Tier - 1) * 0.12
	local function add(e: ParticleEmitter, rate: number, life: NumberRange)
		table.insert(out.emitters, { emitter = e, rate = rate, life = (life.Min + life.Max) / 2 })
	end

	-- TRONCO: energia corporal (superfície do tronco), atrás do corpo
	if v.Body > 0 then
		local life = NumberRange.new(0.6, 1.1)
		add(emitter(root, "Body", {
			Texture = TEX.Spark,
			Color = cs,
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4 * scale), NumberSequenceKeypoint.new(1, 0) }),
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) }),
			Lifetime = life,
			Speed = NumberRange.new(0.8, 1.8),
			SpreadAngle = Vector2.new(180, 180),
			Shape = Enum.ParticleEmitterShape.Box,
			ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface,
			Acceleration = Vector3.new(0, 2 + tier.Tier * 0.6, 0),
			ZOffset = -0.5,
		}), v.Body, life)
	end
	-- TRONCO -> CABEÇA: ascendentes junto ao corpo (sobem do tronco até acima da cabeça)
	if v.Rise > 0 then
		local life = NumberRange.new(1.0, 1.5)
		add(emitter(root, "Rise", {
			Texture = TEX.Ember,
			Color = cs,
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.32 * scale), NumberSequenceKeypoint.new(1, 0) }),
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }),
			Lifetime = life,
			Speed = NumberRange.new(2.5, 4 + tier.Tier * 0.4),
			SpreadAngle = Vector2.new(8, 8),
			EmissionDirection = Enum.NormalId.Top,
			Shape = Enum.ParticleEmitterShape.Box,
			ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
		}), v.Rise, life)
	end

	-- PÉS: brilho, anel (círculo Bézier com textura correndo), onda periódica
	local feet = attachment(root, "Feet", Vector3.new(0, footY, 0))
	if v.Ground > 0 then
		local life = NumberRange.new(0.8, 1.2)
		add(emitter(feet, "Ground", {
			Texture = TEX.Smoke,
			Color = ColorSequence.new(color),
			Size = NumberSequence.new(2 + tier.Tier * 0.35, 3 + tier.Tier * 0.45),
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.65), NumberSequenceKeypoint.new(1, 1) }),
			Lifetime = life,
			Speed = NumberRange.new(0, 0.2),
			Rotation = NumberRange.new(0, 360),
			Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
			EmissionDirection = Enum.NormalId.Top,
			ZOffset = -2,
		}), v.Ground, life)
	end
	if v.Ring then
		local ring = circle(root, folder, "Ring", footY + 0.12, v.Ring.Radius, v.Ring.Arcs, {
			Color = ColorSequence.new(color, accent),
			Width0 = v.Ring.Width,
			Width1 = v.Ring.Width,
			Transparency = NumberSequence.new(0.1),
			Texture = TEX.Smoke,
			TextureLength = 2,
			TextureSpeed = 1.2,
		})
		for _, b in ring.beams do
			table.insert(out.beams, { beam = b, width = v.Ring.Width })
		end
	end
	if v.Pulse then
		out.pulse = emitter(feet, "Pulse", {
			Texture = TEX.Smoke,
			Color = ColorSequence.new(accent),
			Size = NumberSequence.new(1, 8 + tier.Tier * 1.2),
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 1) }),
			Lifetime = NumberRange.new(0.7, 0.7),
			Speed = NumberRange.new(0, 0),
			Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
			EmissionDirection = Enum.NormalId.Top,
			Rate = 0,
			ZOffset = -2,
		})
	end
	if v.FootTrail then
		local l = attachment(root, "TrailL", Vector3.new(-0.6, footY + 0.2, 0))
		local r = attachment(root, "TrailR", Vector3.new(0.6, footY + 0.2, 0))
		local trail = Instance.new("Trail")
		trail.Name = PREFIX .. "FootTrail"
		trail.Attachment0, trail.Attachment1 = l, r
		trail.Color = ColorSequence.new(color)
		trail.Transparency = NumberSequence.new(0.35, 1)
		trail.Lifetime = 0.45
		trail.LightEmission = 1
		trail.FaceCamera = false
		trail.Parent = folder
		table.insert(out.trails, trail)
	end

	-- LATERAIS: energia subindo pelos quadris (assinatura a partir da Imperial)
	if v.Sides > 0 then
		local life = NumberRange.new(0.6, 0.9)
		for i, x in { -1.25, 1.25 } do
			local side = attachment(root, "Side" .. i, Vector3.new(x, -1.1, 0))
			add(emitter(side, "SideFlame", {
				Texture = TEX.Fire,
				Color = ColorSequence.new(accent, color),
				Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55 * scale), NumberSequenceKeypoint.new(1, 0.1) }),
				Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) }),
				Lifetime = life,
				Speed = NumberRange.new(3, 4.5),
				SpreadAngle = Vector2.new(10, 10),
				EmissionDirection = Enum.NormalId.Top,
				ZOffset = -0.8,
			}), v.Sides / 2, life)
		end
	end

	-- ORBITADORES importantes (poucos e grandes)
	for i = 1, v.Orbiters do
		local a = attachment(root, "Orbit" .. i, Vector3.new(out.orbitRadius, 0, 0))
		local life = NumberRange.new(0.35, 0.55)
		add(emitter(a, "OrbitSpark", {
			Texture = TEX.Spark,
			Color = ColorSequence.new(accent, color),
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, v.OrbitSize), NumberSequenceKeypoint.new(1, 0) }),
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }),
			Lifetime = life,
			Speed = NumberRange.new(0, 0.2),
		}), v.OrbitRate, life)
		table.insert(out.orbit, a)
	end

	-- FLUXOS: beams curvos dos quadris aos ombros, ANIMADOS (pontas + curvas) + textura correndo
	for i = 1, v.Flows do
		local angle = (i - 1) / v.Flows * math.pi * 2 + math.pi / 2
		local flow = { angle = angle, phase = i * 2.1 }
		local cf0, cf1, c0, c1 = PlayerAuraBuilder.flowPose(flow, 0)
		local a0 = Instance.new("Attachment")
		a0.Name = PREFIX .. "Flow" .. i .. "A"
		a0.CFrame = cf0
		a0.Parent = root
		local a1 = Instance.new("Attachment")
		a1.Name = PREFIX .. "Flow" .. i .. "B"
		a1.CFrame = cf1
		a1.Parent = root
		local b = beam(folder, "Flow", a0, a1, {
			Color = cs,
			Width0 = v.FlowWidth,
			Width1 = v.FlowWidth * 0.25,
			CurveSize0 = c0,
			CurveSize1 = c1,
			Texture = TEX.Fire,
			TextureMode = Enum.TextureMode.Stretch,
			TextureSpeed = 1.6,
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(0.7, 0.3), NumberSequenceKeypoint.new(1, 0.9) }),
			ZOffset = -1.2,
		})
		table.insert(out.beams, { beam = b, width = v.FlowWidth })
		table.insert(out.flows, { a0 = a0, a1 = a1, beam = b, angle = angle, phase = flow.phase, width = v.FlowWidth })
	end

	-- COLUNA vertical que respira (Celestial+)
	if v.Column then
		local top = attachment(root, "ColumnTop", Vector3.new(0, headY + 5.5, 0))
		out.columnWidth = 3.4 + tier.Tier * 0.25
		local col = beam(folder, "Column", feet, top, {
			Color = ColorSequence.new(color, accent),
			Width0 = out.columnWidth,
			Width1 = 0.8,
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.78), NumberSequenceKeypoint.new(1, 1) }),
			Texture = TEX.Smoke,
			TextureSpeed = 0.8,
			Segments = 4,
			ZOffset = -3,
		})
		table.insert(out.beams, { beam = col, width = out.columnWidth })
		out.column = col
	end

	-- CABEÇA: auréola (círculo Bézier girando) + coroa (só Absoluta) + faíscas
	if v.Halo then
		local halo = circle(root, folder, "Halo", PlayerAuraBuilder.HaloY, v.Halo.Radius, v.Halo.Arcs, {
			Color = ColorSequence.new(accent),
			Width0 = v.Halo.Width,
			Width1 = v.Halo.Width,
			Transparency = NumberSequence.new(0),
			Segments = 8,
		})
		for _, b in halo.beams do
			table.insert(out.beams, { beam = b, width = v.Halo.Width })
		end
		out.halo = halo
		for i = 1, v.Crown do
			local base = halo.points[(i - 1) % #halo.points + 1]
			local tip = Instance.new("Attachment")
			tip.Name = PREFIX .. "CrownTip" .. i
			tip.Parent = root
			table.insert(out.crownTips, tip)
			local b = beam(folder, "Crown", base, tip, {
				Color = ColorSequence.new(accent, color),
				Width0 = 0.42,
				Width1 = 0.02,
				Transparency = NumberSequence.new(0, 0.2),
				Segments = 1,
			})
			table.insert(out.beams, { beam = b, width = 0.42 })
		end
		PlayerAuraBuilder.placeCircle(halo.points, halo.radius, halo.y, 0, out.crownTips, 0.9)
		if v.CrownSparks > 0 then
			local head = attachment(root, "Head", Vector3.new(0, PlayerAuraBuilder.HaloY + 0.2, 0))
			local life = NumberRange.new(0.6, 0.9)
			add(emitter(head, "CrownSpark", {
				Texture = TEX.Spark,
				Color = ColorSequence.new(accent),
				Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) }),
				Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }),
				Lifetime = life,
				Speed = NumberRange.new(1, 2),
				SpreadAngle = Vector2.new(35, 35),
				EmissionDirection = Enum.NormalId.Top,
			}), v.CrownSparks, life)
		end
	end

	-- luz suave (complemento; nunca estoura)
	if v.Light > 0 then
		local light = Instance.new("PointLight")
		light.Name = PREFIX .. "Light"
		light.Color = color
		light.Brightness = v.Light
		light.Range = 8 + tier.Tier * 1.5
		light.Shadows = false
		light.Parent = root
		out.light = light
	end

	for _, child in root:GetChildren() do
		if child:IsA("Attachment") and string.sub(child.Name, 1, #PREFIX) == PREFIX then
			out.attachments += 1
		end
	end
	return out
end

return PlayerAuraBuilder
