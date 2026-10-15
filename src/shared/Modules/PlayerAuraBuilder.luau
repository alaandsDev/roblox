--!strict
--[[
	PlayerAuraBuilder: monta o VISUAL de uma PLAYER AURA no HumanoidRootPart do avatar.
	Identidade própria (NÃO reutiliza a Character Aura): energia corporal, chão, órbitas, rastro
	nos pés, fitas, coluna de luz e — só na ABSOLUTA — auréola/coroa + anel duplo (inconfundível).
	Texturas nativas (rbxasset://, as mesmas famílias da AuraConfig); nada do Auras Pack; nenhum
	script dentro do efeito; sem Highlight.

	    local fx = PlayerAuraBuilder.build(root, tierConfig, { scale = 1 })
	    fx.emitters  { { emitter, rate } }     emissão base (o controlador aplica LOD/mobile)
	    fx.beams / fx.trails / fx.light
	    fx.orbit     { attachment }             posições animadas pelo loop central
	    fx.ring / fx.halo  { attachment }       anéis (pulsam no loop central)
	    fx.ribbons   { { a0, a1 } }              fitas que giram no loop central
	    fx.pulse     emitter?                    pulso periódico (Emit)
	PlayerAuraBuilder.clear(root) remove tudo (respawn/troca de tier nunca duplica).
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

-- altura do chão em relação ao HumanoidRootPart (R6/R15 ~3 studs)
PlayerAuraBuilder.FootY = -2.9
PlayerAuraBuilder.HeadY = 2.6

local function rgb(c: { number }): Color3
	return Color3.fromRGB(c[1], c[2], c[3])
end

local function attachment(root: BasePart, name: string, pos: Vector3): Attachment
	local a = Instance.new("Attachment")
	a.Name = PREFIX .. name
	a.Position = pos
	a:SetAttribute("PlayerAura", true)
	a.Parent = root
	return a
end

local function seq(a: number, b: number): NumberSequence
	return NumberSequence.new(a, b)
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
	b.Segments = 10
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

export type Built = {
	tier: number,
	emitters: { { emitter: ParticleEmitter, rate: number } },
	beams: { { beam: Beam, width: number } },
	trails: { Trail },
	light: PointLight?,
	orbit: { Attachment },
	orbitRadius: number,
	ring: { Attachment },
	ringRadius: number,
	halo: { Attachment },
	haloRadius: number,
	ribbons: { { a0: Attachment, a1: Attachment, angle: number } },
	pulse: ParticleEmitter?,
	attachments: number,
}

-- Constrói (limpando antes). tier = linha da PlayerAuraConfig.List
function PlayerAuraBuilder.build(root: BasePart, tier: any): Built
	PlayerAuraBuilder.clear(root)
	local color, accent = rgb(tier.Color), rgb(tier.Accent)
	local cs = ColorSequence.new({ ColorSequenceKeypoint.new(0, accent), ColorSequenceKeypoint.new(0.5, color), ColorSequenceKeypoint.new(1, color) })
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
		orbitRadius = 2.2,
		ring = {},
		ringRadius = 2.6 + tier.Tier * 0.15,
		halo = {},
		haloRadius = 0.95,
		ribbons = {},
		pulse = nil,
		attachments = 0,
	}
	local rate = tier.Rate
	local footY, headY = PlayerAuraBuilder.FootY, PlayerAuraBuilder.HeadY

	-- 1) energia corporal (todas): faíscas saindo do tronco, atrás do corpo (ZOffset)
	local body = emitter(root, "Body", {
		Texture = TEX.Spark,
		Color = cs,
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35 + tier.Tier * 0.05), NumberSequenceKeypoint.new(1, 0) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 1) }),
		Lifetime = NumberRange.new(0.6, 1.1),
		Speed = NumberRange.new(0.8, 2),
		SpreadAngle = Vector2.new(180, 180),
		Shape = Enum.ParticleEmitterShape.Box,
		ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface,
		Acceleration = Vector3.new(0, 1.5, 0),
		ZOffset = -0.5,
	})
	table.insert(out.emitters, { emitter = body, rate = rate * 0.45 })

	-- 2) chão: brilho pequeno nos pés (todas)
	local feet = attachment(root, "Feet", Vector3.new(0, footY, 0))
	local ground = emitter(feet, "Ground", {
		Texture = TEX.Smoke,
		Color = ColorSequence.new(color),
		Size = seq(1.6 + tier.Tier * 0.3, 2.4 + tier.Tier * 0.4),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 1) }),
		Lifetime = NumberRange.new(0.8, 1.2),
		Speed = NumberRange.new(0, 0.3),
		Rotation = NumberRange.new(0, 360),
		Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
		EmissionDirection = Enum.NormalId.Top,
		ZOffset = -2,
	})
	table.insert(out.emitters, { emitter = ground, rate = rate * 0.15 })

	-- 3) subindo (Celestial+): partículas ascendentes em volta
	if tier.Pillar then
		local rise = emitter(feet, "Rise", {
			Texture = TEX.Ember,
			Color = cs,
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0) }),
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }),
			Lifetime = NumberRange.new(1.2, 1.8),
			Speed = NumberRange.new(3, 5),
			SpreadAngle = Vector2.new(12, 12),
			EmissionDirection = Enum.NormalId.Top,
			Shape = Enum.ParticleEmitterShape.Cylinder,
			ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface,
		})
		table.insert(out.emitters, { emitter = rise, rate = rate * 0.25 })
		-- coluna de luz (beam vertical largo e translúcido)
		local top = attachment(root, "PillarTop", Vector3.new(0, headY + 5, 0))
		local pillar = beam(folder, "Pillar", feet, top, {
			Color = ColorSequence.new(color),
			Width0 = 4.2,
			Width1 = 1.2,
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.82), NumberSequenceKeypoint.new(1, 1) }),
			Texture = TEX.Smoke,
			TextureSpeed = 0.6,
			ZOffset = -3,
		})
		table.insert(out.beams, { beam = pillar, width = 4.2 })
	end

	-- 4) órbitas (Imperial+): pontos de energia girando no meio do corpo
	for i = 1, tier.Orbiters do
		local a = attachment(root, "Orbit" .. i, Vector3.new(out.orbitRadius, 0, 0))
		local spark = emitter(a, "OrbitSpark", {
			Texture = TEX.Spark,
			Color = ColorSequence.new(accent, color),
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 0) }),
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }),
			Lifetime = NumberRange.new(0.35, 0.5),
			Speed = NumberRange.new(0, 0.2),
		})
		table.insert(out.emitters, { emitter = spark, rate = rate * 0.15 / tier.Orbiters + 4 })
		table.insert(out.orbit, a)
	end

	-- 5) rastro nos pés (Imperial+)
	if tier.FootTrail then
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

	-- 6) anel no chão (Divina+): polígono de beams; Absoluta = anel DUPLO
	if tier.GroundRing then
		local rings = if tier.Halo then 2 else 1
		for ring = 1, rings do
			local n = 12
			local radius = out.ringRadius * (if ring == 2 then 1.35 else 1)
			local points = {}
			for i = 1, n do
				local ang = (i / n) * math.pi * 2
				local a = attachment(root, `Ring{ring}_{i}`, Vector3.new(math.cos(ang) * radius, footY + 0.1, math.sin(ang) * radius))
				a:SetAttribute("RingRadius", radius)
				a:SetAttribute("RingAngle", ang)
				table.insert(points, a)
				table.insert(out.ring, a)
			end
			for i = 1, n do
				local b = beam(folder, `Ring{ring}`, points[i], points[i % n + 1], {
					Color = ColorSequence.new(if ring == 2 then accent else color),
					Width0 = 0.32,
					Width1 = 0.32,
					Transparency = NumberSequence.new(if ring == 2 then 0.35 else 0.15),
					FaceCamera = true,
					Segments = 1,
				})
				table.insert(out.beams, { beam = b, width = 0.32 })
			end
		end
		-- pulso: onda que sai do anel de tempos em tempos
		out.pulse = emitter(feet, "Pulse", {
			Texture = TEX.Smoke,
			Color = ColorSequence.new(accent),
			Size = seq(1, 9 + tier.Tier),
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 1) }),
			Lifetime = NumberRange.new(0.7, 0.7),
			Speed = NumberRange.new(0, 0),
			Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
			EmissionDirection = Enum.NormalId.Top,
			Rate = 0,
			ZOffset = -2,
		})
	end

	-- 7) fitas de energia (Divina+): beams curvos girando em volta do corpo
	for i = 1, tier.Ribbons do
		local ang = (i / math.max(1, tier.Ribbons)) * math.pi * 2
		local a0 = attachment(root, "Ribbon" .. i .. "A", Vector3.new(math.cos(ang) * 1.6, footY + 0.6, math.sin(ang) * 1.6))
		local a1 = attachment(root, "Ribbon" .. i .. "B", Vector3.new(math.cos(ang + 1.4) * 1.3, headY, math.sin(ang + 1.4) * 1.3))
		local b = beam(folder, "Ribbon", a0, a1, {
			Color = cs,
			Width0 = 0.55,
			Width1 = 0.12,
			CurveSize0 = 1.6,
			CurveSize1 = -1.6,
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(0.6, 0.35), NumberSequenceKeypoint.new(1, 0.9) }),
			ZOffset = -1.5,
		})
		table.insert(out.beams, { beam = b, width = 0.55 })
		table.insert(out.ribbons, { a0 = a0, a1 = a1, angle = ang })
	end

	-- 8) ABSOLUTA: auréola/coroa acima da cabeça (assinatura exclusiva, não cobre o rosto)
	if tier.Halo then
		local n = 10
		local points = {}
		for i = 1, n do
			local ang = (i / n) * math.pi * 2
			local a = attachment(root, "Halo" .. i, Vector3.new(math.cos(ang) * out.haloRadius, headY + 1.25, math.sin(ang) * out.haloRadius))
			table.insert(points, a)
			table.insert(out.halo, a)
		end
		for i = 1, n do
			local b = beam(folder, "Halo", points[i], points[i % n + 1], {
				Color = ColorSequence.new(accent),
				Width0 = 0.22,
				Width1 = 0.22,
				Transparency = NumberSequence.new(0),
				Segments = 1,
			})
			table.insert(out.beams, { beam = b, width = 0.22 })
		end
		-- pontas da coroa: 5 raios curtos subindo da auréola
		for i = 1, 5 do
			local base = points[(i - 1) * 2 + 1]
			local tip = attachment(root, "Crown" .. i, base.Position + Vector3.new(0, 0.7, 0))
			local b = beam(folder, "Crown", base, tip, {
				Color = ColorSequence.new(accent, color),
				Width0 = 0.3,
				Width1 = 0.02,
				Transparency = NumberSequence.new(0, 0.3),
				Segments = 1,
			})
			table.insert(out.beams, { beam = b, width = 0.3 })
		end
	end

	-- 9) luz suave (complemento; nunca estoura)
	if tier.Light > 0 then
		local light = Instance.new("PointLight")
		light.Name = PREFIX .. "Light"
		light.Color = color
		light.Brightness = tier.Light
		light.Range = 7 + tier.Tier
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
