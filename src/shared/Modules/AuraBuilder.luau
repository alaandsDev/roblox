--!strict
--[[
	AuraBuilder V2: monta a aura de raridade (Lendário/Mítico/Divino/Secreto) a partir do PLANO do
	AuraPlanner, em ZONAS ao redor do personagem:
	    AuraCore   (Inner) volume do corpo: massa colorida (alfa) + fundo escuro (contraste)
	    AuraRing   (Mid)   cilindro ~2–4 studs: subida, profundidade frente/trás, assinatura
	    AuraOuter  (Outer) cilindro ~4–7 studs: coluna externa (alarga a silhueta)
	    AuraGround         disco no chão: anel/runas + shockwave
	    AuraCrown          acima da cabeça (Secreto): coroa/halo + erupção periódica
	    AuraOrbit*         attachments orbitando (rastro largo) — movidos pelo AuraController
	Contraste: as camadas principais usam mistura ALFA (LightEmission baixo) para a cor continuar
	saturada sobre fundo claro; só faíscas/raios/cabeças de órbita brilham (LightEmission alto).
	Tamanhos e opacidade são os MESMOS no Light e no Full (Light só reduz taxa e quantidade).
	Nada de script dentro do modelo; só texturas nativas do Roblox. O MOVIMENTO (órbitas, raios,
	fitas, pulsos, shockwave, erupção, contorno) é do AuraController (um loop central no cliente).
]]

local CollectionService = game:GetService("CollectionService")

local Shared = script.Parent.Parent
local AuraConfig = require(Shared.Config.AuraConfig)
local CharacterConfig = require(Shared.Config.CharacterConfig)
local DiceConfig = require(Shared.Config.DiceConfig)
local AuraPlanner = require(script.Parent.AuraPlanner)

local AuraBuilder = {}

AuraBuilder.Tag = "RollLegendsAura"

local planner = AuraPlanner.new(AuraConfig, CharacterConfig, DiceConfig)
AuraBuilder.planner = planner

function AuraBuilder.styleOf(characterId: string): string
	return planner:styleOf(characterId)
end

function AuraBuilder.resolve(characterId: string, rarity: string, mode: string, style: string?): AuraPlanner.Plan?
	return planner:resolve(characterId, rarity, mode, style)
end

------------------------------------------------------------------------------------
-- Utilidades

local function c3(list: { number }): Color3
	return Color3.fromRGB(list[1], list[2], list[3])
end

local function seq(...: Color3): ColorSequence
	local colors = { ... }
	local keys = {}
	for i, c in colors do
		table.insert(keys, ColorSequenceKeypoint.new((i - 1) / math.max(1, #colors - 1), c))
	end
	return ColorSequence.new(keys)
end

type Palette = { main: Color3, light: Color3, accent: Color3, dark: Color3 }

local function palette(style: any): Palette
	return { main = c3(style.Colors[1]), light = c3(style.Colors[2]), accent = c3(style.Colors[3]), dark = c3(style.Dark) }
end

local function numSeq(points: { { number } }): NumberSequence
	local keys = {}
	for _, p in points do
		table.insert(keys, NumberSequenceKeypoint.new(p[1], p[2]))
	end
	return NumberSequence.new(keys)
end

local function mark(obj: Instance, role: string?)
	obj:SetAttribute("VFXTier", "Light") -- o LodController liga/desliga pela distância
	if role then
		obj:SetAttribute("AuraRole", role)
	end
end

export type EmitterOpts = {
	texture: string?,
	color: ColorSequence,
	rate: number,
	life: { number }, -- {min, max}
	speed: { number },
	size: { { number } }, -- NumberSequence {t, valor}
	transparency: { { number } }?,
	lightEmission: number?,
	zOffset: number?,
	spread: Vector2?,
	shape: Enum.ParticleEmitterShape?,
	shapeStyle: Enum.ParticleEmitterShapeStyle?,
	inOut: Enum.ParticleEmitterShapeInOut?,
	direction: Enum.NormalId?,
	acceleration: Vector3?,
	drag: number?,
	orientation: Enum.ParticleOrientation?,
	squash: number?,
	rotSpeed: number?,
	enabled: boolean?,
	role: string?,
}

-- Presença: elementos maiores e mais sólidos (AuraConfig.Presence.Size/Fade), em Light e Full
local sizeScale, fade = 1, 1

local function scaledSize(points: { { number } }): { { number } }
	local peak = 0
	for _, p in points do
		peak = math.max(peak, p[2])
	end
	-- pico mínimo: partícula pequena demais vira invisível no mapa claro
	local minPeak = if sizeScale ~= 1 then (AuraConfig.Presence.MinPeak or 0) else 0
	local boost = if peak > 0 and peak * sizeScale < minPeak then minPeak / peak else sizeScale
	local out = {}
	for _, p in points do
		table.insert(out, { p[1], p[2] * boost })
	end
	return out
end

local function faded(points: { { number } }): { { number } }
	local out = {}
	for _, p in points do
		-- o fim da vida continua sumindo (1); o resto fica mais opaco
		table.insert(out, { p[1], if p[2] >= 1 then 1 else p[2] * fade })
	end
	return out
end

local function emitter(parent: Instance, name: string, o: EmitterOpts): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Name = name
	e.Texture = AuraConfig.Textures[o.texture or "Spark"]
	e.Color = o.color
	e.LightEmission = o.lightEmission or 0.2
	e.LightInfluence = 0
	e.Rate = o.rate
	e.Lifetime = NumberRange.new(o.life[1], o.life[2])
	e.Speed = NumberRange.new(o.speed[1], o.speed[2])
	e.Size = numSeq(scaledSize(o.size))
	e.Transparency = numSeq(faded(o.transparency or { { 0, 0.05 }, { 0.6, 0.3 }, { 1, 1 } }))
	e.ZOffset = o.zOffset or 0
	e.SpreadAngle = o.spread or Vector2.new(15, 15)
	e.Shape = o.shape or Enum.ParticleEmitterShape.Box
	e.ShapeStyle = o.shapeStyle or Enum.ParticleEmitterShapeStyle.Surface
	e.ShapeInOut = o.inOut or Enum.ParticleEmitterShapeInOut.Outward
	e.EmissionDirection = o.direction or Enum.NormalId.Top
	e.Acceleration = o.acceleration or Vector3.zero
	e.Drag = o.drag or 0
	e.Orientation = o.orientation or Enum.ParticleOrientation.FacingCamera
	if o.squash then
		e.Squash = NumberSequence.new(o.squash)
	end
	local rot = o.rotSpeed or 60
	e.RotSpeed = NumberRange.new(-rot, rot)
	e.Rotation = NumberRange.new(0, 360)
	e.Enabled = o.enabled ~= false
	e:SetAttribute("BaseRate", e.Rate)
	mark(e, o.role)
	e.Parent = parent
	return e
end

local function invisiblePart(model: Model, name: string, size: Vector3, cf: CFrame): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Transparency = 1
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.Parent = model
	return p
end

local function bounds(model: Model, fallbackHeight: number): (CFrame, Vector3)
	local ok, cf, size = pcall(function()
		return model:GetBoundingBox()
	end)
	if ok then
		return cf, size
	end
	return model:GetPivot() * CFrame.new(0, fallbackHeight / 2, 0), Vector3.new(2, fallbackHeight, 1.2)
end

local function attachment(parent: Instance, name: string, position: Vector3): Attachment
	local a = Instance.new("Attachment")
	a.Name = name
	a.Position = position
	a.Parent = parent
	return a
end

local function beam(parent: Instance, name: string, a0: Attachment, a1: Attachment, color: ColorSequence, width0: number, width1: number, role: string, opts: { [string]: any }?): Beam
	local o: { [string]: any } = opts or {}
	local b = Instance.new("Beam")
	b.Name = name
	b.Attachment0 = a0
	b.Attachment1 = a1
	b.Color = color
	b.LightEmission = o.lightEmission or 0.4
	b.LightInfluence = 0
	b.FaceCamera = true
	b.Segments = o.segments or 16
	b.Width0 = width0 * sizeScale
	b.Width1 = width1 * sizeScale
	b.ZOffset = o.zOffset or 0
	b.CurveSize0 = o.curve0 or 1.5
	b.CurveSize1 = o.curve1 or -1.5
	b.Transparency = o.transparency or numSeq({ { 0, 0.1 }, { 0.5, 0.15 }, { 1, 0.6 } })
	if o.texture then
		b.Texture = AuraConfig.Textures[o.texture]
		b.TextureSpeed = o.textureSpeed or 1
		b.TextureLength = o.textureLength or 2
	end
	mark(b, role)
	b.Parent = parent
	return b
end

------------------------------------------------------------------------------------
-- Geometria (zonas) e assinaturas por estilo

type Geo = {
	model: Model,
	core: Part,
	ring: Part,
	outer: Part,
	ground: Part,
	h: number, -- altura do personagem
	w: number, -- largura do personagem
	top: number, -- altura visual da composição (a partir do centro do corpo)
	rMid: number,
	rOuter: number,
	feet: CFrame,
	center: CFrame,
}

local function signatureRate(comp: AuraPlanner.Component): number
	return comp.rate
end

--[[
	Assinaturas: UM elemento reconhecível por estilo (sempre presente, Light e Full).
	n = quantidade (raios, fitas...) conforme a raridade; rate = partículas/s da assinatura.
]]
local Signatures: { [string]: (g: Geo, p: Palette, style: any, n: number, rate: number) -> () } = {}

-- Electric: arcos saindo do corpo para a zona média + flashes curtos
Signatures.Lightning = function(g, p, _style, n, rate)
	local h, w = g.h, g.w
	for i = 1, n do
		local angle = (i / n) * math.pi * 2
		local y0 = (((i * 37) % 7) / 7 - 0.4) * h * 0.7
		local a0 = attachment(g.core, "AuraBoltA" .. i, Vector3.new(math.cos(angle) * w * 0.35, y0, math.sin(angle) * w * 0.35))
		local a1 = attachment(g.core, "AuraBoltB" .. i, Vector3.new(math.cos(angle + 0.7) * g.rMid, y0 + h * 0.35, math.sin(angle + 0.7) * g.rMid))
		beam(g.core, "AuraBolt" .. i, a0, a1, seq(p.light, p.main, p.accent), 0.45, 0.15, "Bolt", { lightEmission = 1, segments = 14, curve0 = 2, curve1 = -2 })
	end
	local flash = emitter(g.ring, "AuraFlash", {
		texture = "Spark",
		color = seq(p.light, p.accent),
		rate = 0,
		life = { 0.12, 0.2 },
		speed = { 0, 0.5 },
		size = { { 0, 2.6 }, { 1, 0 } },
		transparency = { { 0, 0 }, { 1, 1 } },
		lightEmission = 1,
		enabled = false,
		role = "Burst",
	})
	flash:SetAttribute("AuraBurstEvery", 0.7)
	flash:SetAttribute("AuraBurstCount", math.max(2, n))
	emitter(g.ring, "AuraSparkStreaks", {
		texture = "Spark",
		color = seq(p.light, p.main),
		rate = rate * 0.6,
		life = { 0.25, 0.4 },
		speed = { 10, 16 },
		size = { { 0, 0.45 }, { 1, 0 } },
		lightEmission = 0.9,
		spread = Vector2.new(180, 180),
		orientation = Enum.ParticleOrientation.VelocityParallel,
		squash = 2.5,
	})
end

-- Flame: coluna de chamas subindo + brasas
Signatures.Flames = function(g, p, _style, n, rate)
	emitter(g.ring, "AuraFlames", {
		texture = "Fire",
		color = seq(p.light, p.main, p.accent),
		rate = rate * 0.65,
		life = { 0.7, 1.1 },
		speed = { 4 + n * 0.5, 7 + n },
		size = { { 0, 1.2 + n * 0.25 }, { 0.5, 1.8 + n * 0.25 }, { 1, 0.3 } },
		transparency = { { 0, 0 }, { 0.5, 0.15 }, { 1, 1 } },
		lightEmission = 0.35,
		spread = Vector2.new(8, 8),
		shape = Enum.ParticleEmitterShape.Cylinder,
	})
	emitter(g.ring, "AuraEmbers", {
		texture = "Ember",
		color = seq(p.light, p.accent),
		rate = rate * 0.35,
		life = { 0.8, 1.4 },
		speed = { 7, 12 },
		size = { { 0, 0.45 }, { 1, 0 } },
		lightEmission = 0.9,
		spread = Vector2.new(25, 25),
		shape = Enum.ParticleEmitterShape.Cylinder,
		acceleration = Vector3.new(0, 4, 0),
	})
end

-- Void: fragmentos escuros puxados para dentro + faíscas roxas na borda
Signatures.Fragments = function(g, p, _style, n, rate)
	emitter(g.outer, "AuraFragments", {
		texture = "Smoke",
		color = seq(p.dark, p.main),
		rate = rate * 0.7,
		life = { 0.9, 1.3 },
		speed = { 3, 5 },
		size = { { 0, 1.2 + n * 0.1 }, { 1, 0.2 } },
		transparency = { { 0, 0 }, { 0.7, 0.2 }, { 1, 1 } },
		lightEmission = 0,
		shape = Enum.ParticleEmitterShape.Cylinder,
		inOut = Enum.ParticleEmitterShapeInOut.Inward,
		rotSpeed = 180,
	})
	emitter(g.ring, "AuraRimSparks", {
		texture = "Spark",
		color = seq(p.light, p.main),
		rate = rate * 0.3,
		life = { 0.4, 0.7 },
		speed = { 2, 4 },
		size = { { 0, 0.7 }, { 1, 0 } },
		lightEmission = 0.8,
		shape = Enum.ParticleEmitterShape.Cylinder,
		spread = Vector2.new(60, 60),
	})
end

-- Dark: sombra densa subindo + faíscas carmim
Signatures.Shadows = function(g, p, _style, n, rate)
	emitter(g.ring, "AuraShadows", {
		texture = "Smoke",
		color = seq(p.dark, p.main, p.dark),
		rate = rate * 0.7,
		life = { 1.1, 1.6 },
		speed = { 2, 3.5 },
		size = { { 0, 1.6 + n * 0.15 }, { 0.6, 2.6 + n * 0.15 }, { 1, 3 } },
		transparency = { { 0, 0.05 }, { 0.6, 0.35 }, { 1, 1 } },
		lightEmission = 0,
		-- sombra densa ATRÁS do corpo (moldura escura): nunca na frente do personagem
		zOffset = -(g.w * 0.5 + 2),
		shape = Enum.ParticleEmitterShape.Cylinder,
		spread = Vector2.new(10, 10),
	})
	emitter(g.ring, "AuraCrimson", {
		texture = "Spark",
		color = seq(p.light, p.main),
		rate = rate * 0.3,
		life = { 0.4, 0.7 },
		speed = { 5, 9 },
		size = { { 0, 0.55 }, { 1, 0 } },
		lightEmission = 0.9,
		orientation = Enum.ParticleOrientation.VelocityParallel,
		squash = 2,
		spread = Vector2.new(30, 30),
	})
end

-- Celestial: estrelas cintilando na zona média + halo limpo acima da cabeça
Signatures.Stars = function(g, p, _style, n, rate)
	emitter(g.ring, "AuraStars", {
		texture = "Spark",
		color = seq(p.light, p.main),
		rate = rate * 0.65,
		life = { 1, 1.6 },
		speed = { 0.5, 1.5 },
		size = { { 0, 0 }, { 0.3, 1.3 + n * 0.1 }, { 1, 0 } },
		transparency = { { 0, 0 }, { 1, 0.4 } },
		lightEmission = 0.5,
		-- estrelas EM VOLTA do corpo (superfície do anel), não dentro do volume na frente dele
		shape = Enum.ParticleEmitterShape.Cylinder,
		rotSpeed = 120,
	})
	local halo = invisiblePart(g.model, "AuraHalo", Vector3.new(2.6, 0.1, 2.6), g.center * CFrame.new(0, g.h * 0.62, 0))
	emitter(halo, "AuraHaloRing", {
		texture = "Spark",
		color = seq(p.light, p.main),
		rate = rate * 0.35,
		life = { 0.7, 1 },
		speed = { 0.05, 0.1 },
		size = { { 0, 0.9 }, { 1, 0 } },
		transparency = { { 0, 0 }, { 1, 0.5 } },
		lightEmission = 0.6,
		shape = Enum.ParticleEmitterShape.Cylinder,
		orientation = Enum.ParticleOrientation.VelocityPerpendicular,
	})
end

-- Wind: fitas em espiral rápidas + streaks tangenciais
Signatures.Gusts = function(g, p, _style, n, rate)
	for i = 1, math.max(2, n) do
		local angle = (i / math.max(2, n)) * math.pi * 2
		local a0 = attachment(g.core, "AuraGustA" .. i, Vector3.new(math.cos(angle) * g.rMid, -g.h * 0.45, math.sin(angle) * g.rMid))
		local a1 = attachment(g.core, "AuraGustB" .. i, Vector3.new(math.cos(angle + 2.2) * g.rMid * 0.8, g.top * 0.55, math.sin(angle + 2.2) * g.rMid * 0.8))
		beam(g.core, "AuraGust" .. i, a0, a1, seq(p.light, p.main, p.accent), 0.7, 0.15, "Gust", { lightEmission = 0.3, curve0 = 3, curve1 = -3 })
	end
	emitter(g.ring, "AuraGustStreaks", {
		texture = "Spark",
		color = seq(p.light, p.main),
		rate = rate * 0.7,
		life = { 0.4, 0.7 },
		speed = { 9, 13 },
		size = { { 0, 0.5 }, { 1, 0 } },
		lightEmission = 0.5,
		spread = Vector2.new(80, 15),
		orientation = Enum.ParticleOrientation.VelocityParallel,
		squash = 3,
		shape = Enum.ParticleEmitterShape.Cylinder,
	})
end

-- Ice: cristais caindo + névoa fria no chão
Signatures.Shards = function(g, p, _style, n, rate)
	emitter(g.ring, "AuraShards", {
		texture = "Spark",
		color = seq(p.light, p.main, p.accent),
		rate = rate * 0.6,
		life = { 1, 1.4 },
		speed = { 1, 2 },
		size = { { 0, 0.7 + n * 0.08 }, { 1, 0.2 } },
		transparency = { { 0, 0 }, { 0.8, 0.2 }, { 1, 1 } },
		lightEmission = 0.25,
		direction = Enum.NormalId.Bottom,
		acceleration = Vector3.new(0, -5, 0),
		orientation = Enum.ParticleOrientation.VelocityParallel,
		squash = 3,
		shape = Enum.ParticleEmitterShape.Cylinder,
		shapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
		rotSpeed = 0,
	})
	emitter(g.ground, "AuraMist", {
		texture = "Smoke",
		color = seq(p.light, p.main),
		rate = rate * 0.4,
		life = { 1.4, 2 },
		speed = { 0.5, 1.2 },
		size = { { 0, 1.5 }, { 1, 3 } },
		transparency = { { 0, 0.3 }, { 1, 1 } },
		lightEmission = 0.1,
		shape = Enum.ParticleEmitterShape.Cylinder,
	})
end

-- Energy: anéis planos de energia pulsando na altura do peito + streaks
Signatures.Rings = function(g, p, _style, n, rate)
	local chest = invisiblePart(g.model, "AuraChest", Vector3.new(0.4, 0.1, 0.4), g.center * CFrame.new(0, g.h * 0.1, 0))
	local ring = emitter(chest, "AuraEnergyRing", {
		texture = "Spark",
		color = seq(p.light, p.main, p.accent),
		rate = 0,
		life = { 0.6, 0.7 },
		speed = { 0.02, 0.05 },
		size = { { 0, 1 }, { 1, g.rMid * 2.4 } },
		transparency = { { 0, 0.05 }, { 1, 1 } },
		lightEmission = 0.5,
		orientation = Enum.ParticleOrientation.VelocityPerpendicular,
		enabled = false,
		role = "Burst",
		rotSpeed = 0,
	})
	ring:SetAttribute("AuraBurstEvery", 1.1)
	ring:SetAttribute("AuraBurstCount", 1)
	emitter(g.core, "AuraEnergyStreaks", {
		texture = "Spark",
		color = seq(p.light, p.main),
		rate = rate * 0.8,
		life = { 0.35, 0.55 },
		speed = { 9, 13 },
		size = { { 0, 0.5 + n * 0.05 }, { 1, 0 } },
		lightEmission = 0.8,
		spread = Vector2.new(180, 180),
		orientation = Enum.ParticleOrientation.VelocityParallel,
		squash = 2.2,
	})
end

-- Spirit: almas/orbes subindo devagar + pontinhos brilhantes
Signatures.Wisps = function(g, p, _style, n, rate)
	emitter(g.ring, "AuraSpirits", {
		texture = "Smoke",
		color = seq(p.light, p.main),
		rate = rate * 0.55,
		life = { 1.8, 2.4 },
		speed = { 1.2, 2.2 },
		size = { { 0, 0.4 }, { 0.3, 1.5 + n * 0.1 }, { 1, 0.2 } },
		transparency = { { 0, 0.1 }, { 0.7, 0.3 }, { 1, 1 } },
		lightEmission = 0.3,
		shape = Enum.ParticleEmitterShape.Cylinder,
		shapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
	})
	emitter(g.ring, "AuraMotes", {
		texture = "Spark",
		color = seq(p.light, p.accent),
		rate = rate * 0.45,
		life = { 1.2, 1.8 },
		speed = { 1, 2 },
		size = { { 0, 0.55 }, { 1, 0 } },
		lightEmission = 0.8,
		shape = Enum.ParticleEmitterShape.Cylinder,
		shapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
	})
end

-- Gravity: matéria sendo puxada da borda para o corpo + destroços lentos
Signatures.Pull = function(g, p, _style, n, rate)
	emitter(g.outer, "AuraPull", {
		texture = "Ember",
		color = seq(p.light, p.main),
		rate = rate * 0.65,
		life = { 0.8, 1.1 },
		speed = { 4, 6 },
		size = { { 0, 0.6 + n * 0.05 }, { 1, 0.1 } },
		lightEmission = 0.6,
		shape = Enum.ParticleEmitterShape.Cylinder,
		inOut = Enum.ParticleEmitterShapeInOut.Inward,
		orientation = Enum.ParticleOrientation.VelocityParallel,
		squash = 2.5,
	})
	emitter(g.ring, "AuraDebris", {
		texture = "Smoke",
		color = seq(p.dark, p.main),
		rate = rate * 0.35,
		life = { 1.5, 2 },
		speed = { 0.3, 0.8 },
		size = { { 0, 0.9 }, { 1, 0.6 } },
		transparency = { { 0, 0.05 }, { 1, 0.9 } },
		lightEmission = 0,
		shape = Enum.ParticleEmitterShape.Cylinder,
		shapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
		rotSpeed = 200,
	})
end

------------------------------------------------------------------------------------
-- Montagem

-- Cria a aura no modelo. styleOverride: DEV/comparação (mesmo estilo em todas as raridades).
function AuraBuilder.attach(model: Model, characterId: string, rarity: string, mode: string, height: number?, styleOverride: string?): AuraPlanner.Plan?
	local plan = AuraBuilder.resolve(characterId, rarity, mode, styleOverride)
	if not plan then
		return nil
	end
	local style = AuraConfig.Styles[plan.style]
	local p = palette(style)
	sizeScale, fade = AuraConfig.Presence.Size, AuraConfig.Presence.Fade
	local cf, size = bounds(model, height or 5)
	local h = math.max(size.Y, 2)
	-- largura do CORPO, não da caixa: espadas/bisentos/capas abertas (Ulkiorra Liberado 21 studs,
	-- Barbalva 13) não podem inflar a aura (nem quebrar o clamp abaixo); corpo humano <= 0,6 × altura
	local w = math.clamp(math.max(size.X, size.Z), 1.2, h * 0.6)
	local S = plan.silhouette
	local Z = AuraConfig.Zones
	-- alcance externo cresce com a silhueta (Lendário ~1,8 · Secreto ~5,5 studs do eixo); o mínimo
	-- nunca passa do máximo (math.clamp com min > max lança erro)
	local outerMin = math.min(w / 2 + 0.6, Z.OuterMax)
	local rOuter = math.clamp(w / 2 + (S - 1) * h * 0.55, outerMin, Z.OuterMax)
	local rMid = math.clamp((w / 2 + rOuter) / 2 + 0.3, math.min(Z.MidMin, rOuter), math.max(Z.MidMax, math.min(Z.MidMin, rOuter)))
	local top = h * (S - 0.5) -- topo visual acima do centro do corpo
	local feet = cf * CFrame.new(0, -h / 2, 0)
	local core = invisiblePart(model, "AuraCore", Vector3.new(w * 0.95, h * 0.95, w * 0.75), cf)
	local ring = invisiblePart(model, "AuraRing", Vector3.new(rMid * 2, h * 0.9, rMid * 2), cf)
	local outer = invisiblePart(model, "AuraOuter", Vector3.new(rOuter * 2, h, rOuter * 2), cf * CFrame.new(0, (S - 1) * h * 0.25, 0))
	local ground = invisiblePart(model, "AuraGround", Vector3.new(rOuter * 1.6, 0.2, rOuter * 1.6), feet * CFrame.new(0, 0.15, 0))
	local g: Geo = { model = model, core = core, ring = ring, outer = outer, ground = ground, h = h, w = w, top = top, rMid = rMid, rOuter = rOuter, feet = feet, center = cf }
	local alpha = if plan.style == "Dark" or plan.style == "Void" then 0 else 0.2
	local main = seq(p.light, p.main, p.accent)
	local up = style.Direction == "Up"
	local down = style.Direction == "Down"
	local inward = style.Direction == "In"
	-- velocidade da subida para chegar ao topo da silhueta dentro da vida da partícula
	local riseSpeed = (top + h * 0.5) / 1.2

	for _, comp in plan.components do
		local kind = comp.kind
		if kind == "Body" then
			emitter(core, "AuraBody", {
				texture = style.Texture,
				color = main,
				rate = comp.rate,
				life = { style.Lifetime, style.Lifetime * 1.6 },
				speed = { style.Speed * 0.35, style.Speed * 0.7 },
				size = { { 0, style.Size * 0.6 }, { 0.3, style.Size * 1.15 }, { 1, 0 } },
				-- fumaça/fogo colados no corpo ficam ATRÁS dele (a aura emoldura, não esconde); faísca
				-- (Spark, pequena e brilhante) pode passar na frente
				transparency = { { 0, if style.Texture == "Spark" then 0.05 else 0.2 }, { 0.6, 0.3 }, { 1, 1 } },
				zOffset = if style.Texture == "Spark" then 0 else -(g.w * 0.5 + 1),
				lightEmission = alpha,
				inOut = if inward then Enum.ParticleEmitterShapeInOut.Inward else Enum.ParticleEmitterShapeInOut.Outward,
				acceleration = if up then Vector3.new(0, 4, 0) elseif down then Vector3.new(0, -2, 0) else nil,
				spread = if style.Direction == "Swirl" then Vector2.new(60, 60) else Vector2.new(25, 25),
				drag = style.Drag,
				orientation = if style.Streak then Enum.ParticleOrientation.VelocityParallel else nil,
				squash = if style.Streak then 1.6 else nil,
			})
		elseif kind == "Contrast" then
			-- fundo ESCURO atrás do corpo: separa a aura de céu/chão claros
			emitter(core, "AuraContrast", {
				texture = "Smoke",
				color = seq(p.dark, p.main),
				rate = comp.rate,
				life = { 1.2, 1.6 },
				speed = { 0.4, 0.9 },
				size = { { 0, style.Size * 1.6 }, { 1, style.Size * 2.6 } },
				transparency = { { 0, 0.25 }, { 0.6, 0.45 }, { 1, 1 } },
				lightEmission = 0,
				zOffset = -(g.w * 0.5 + 2.5),
				acceleration = Vector3.new(0, 1.5, 0),
			})
		elseif kind == "Depth" then
			emitter(ring, "AuraDepthFront", {
				texture = "Spark",
				color = seq(p.light, p.main),
				rate = comp.rate * 0.55,
				life = { 0.9, 1.3 },
				speed = { 1, 2.5 },
				size = { { 0, 0.8 }, { 1, 0 } },
				lightEmission = 0.6,
				zOffset = 2,
				shape = Enum.ParticleEmitterShape.Cylinder,
				shapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
			})
			emitter(ring, "AuraDepthBack", {
				texture = "Smoke",
				color = seq(p.main, p.dark),
				rate = comp.rate * 0.45,
				life = { 1.2, 1.6 },
				speed = { 0.8, 1.6 },
				size = { { 0, 1.8 }, { 1, 2.8 } },
				transparency = { { 0, 0.3 }, { 0.6, 0.5 }, { 1, 1 } },
				lightEmission = 0.1,
				zOffset = -2,
				shape = Enum.ParticleEmitterShape.Cylinder,
			})
		elseif kind == "Rise" then
			emitter(ring, "AuraRise", {
				texture = "Spark",
				color = seq(p.light, p.main),
				rate = comp.rate,
				life = { 1, 1.4 },
				speed = { riseSpeed * 0.7, riseSpeed },
				-- streaks subindo mais grossos (V2.1): a coluna subindo é o que lê a raridade de longe
				size = { { 0, 0.9 }, { 1, 0.3 } },
				lightEmission = 0.55,
				spread = Vector2.new(6, 6),
				shape = Enum.ParticleEmitterShape.Cylinder,
				orientation = Enum.ParticleOrientation.VelocityParallel,
				squash = 2.4,
			})
		elseif kind == "Outer" then
			emitter(outer, "AuraOuterColumn", {
				texture = if plan.style == "Flame" then "Fire" else "Smoke",
				color = seq(p.main, p.dark),
				rate = comp.rate,
				life = { 1.8, 2.6 },
				speed = { 1.5, 3 },
				size = { { 0, 1.6 }, { 0.5, 2.8 }, { 1, 3.4 } },
				transparency = { { 0, 0.35 }, { 0.6, 0.55 }, { 1, 1 } },
				lightEmission = 0.1,
				shape = Enum.ParticleEmitterShape.Cylinder,
			})
		elseif kind == "Orbit" then
			for i = 1, comp.count do
				local a0 = attachment(core, "AuraOrbit" .. i, Vector3.new(rMid, 0, 0))
				a0:SetAttribute("AuraRole", "Orbit")
				a0:SetAttribute("AuraIndex", i)
				a0:SetAttribute("AuraCount", comp.count)
				-- raio, altura, velocidade e sentido diferentes (nada sincronizado)
				a0:SetAttribute("AuraRadius", if i % 2 == 0 then rMid else (rMid + rOuter) / 2)
				a0:SetAttribute("AuraHeight", ((i - 0.5) / comp.count - 0.45) * (h + top * 0.6))
				a0:SetAttribute("AuraSpeed", style.OrbitSpeed * (0.8 + 0.25 * i) * (if i % 2 == 0 then -1 else 1))
				a0:SetAttribute("AuraBob", 0.35 + 0.15 * i)
				a0:SetAttribute("AuraWobble", style.OrbitWobble)
				local tail = attachment(a0, "AuraOrbitTail" .. i, Vector3.new(0, 0.9 * sizeScale, 0))
				local trail = Instance.new("Trail")
				trail.Name = "AuraOrbitTrail" .. i
				trail.Attachment0 = a0
				trail.Attachment1 = tail
				trail.Color = seq(p.light, p.main, p.accent)
				trail.LightEmission = 0.6
				trail.LightInfluence = 0
				trail.Lifetime = 0.55
				trail.FaceCamera = true
				trail.Transparency = numSeq({ { 0, 0 }, { 0.6, 0.35 }, { 1, 1 } })
				trail.WidthScale = numSeq({ { 0, 1 }, { 1, 0.1 } })
				mark(trail)
				trail.Parent = a0
				emitter(a0, "AuraOrbitHead" .. i, {
					texture = "Spark",
					color = seq(p.light, p.main),
					rate = comp.rate,
					life = { 0.4, 0.7 },
					speed = { 0.2, 0.6 },
					size = { { 0, 1.1 }, { 1, 0 } },
					lightEmission = 0.8,
				})
			end
		elseif kind == "Ribbon" then
			for i = 1, comp.count do
				local angle = (i / comp.count) * math.pi * 2
				local a0 = attachment(core, "AuraRibbonA" .. i, Vector3.new(math.cos(angle) * rMid, -h * 0.5, math.sin(angle) * rMid))
				local a1 = attachment(core, "AuraRibbonB" .. i, Vector3.new(math.cos(angle + 2.4) * rMid * 0.7, top * 0.75, math.sin(angle + 2.4) * rMid * 0.7))
				beam(core, "AuraRibbon" .. i, a0, a1, seq(p.light, p.main, p.dark), 1, 0.2, "Wisp", { lightEmission = 0.25, curve0 = 3.5, curve1 = -3.5, zOffset = -1 })
			end
		elseif kind == "Ground" then
			emitter(ground, "AuraGroundRing", {
				texture = "Spark",
				color = seq(p.light, p.main),
				rate = comp.rate * 0.75,
				life = { 1.2, 1.6 },
				speed = { 0.05, 0.1 },
				size = { { 0, 1.5 }, { 1, 0 } },
				transparency = { { 0, 0 }, { 1, 0.6 } },
				lightEmission = 0.45,
				shape = Enum.ParticleEmitterShape.Cylinder,
				orientation = Enum.ParticleOrientation.VelocityPerpendicular,
				rotSpeed = 40,
			})
			emitter(ground, "AuraGroundDisk", {
				texture = "Smoke",
				color = seq(p.main, p.dark),
				rate = comp.rate * 0.25,
				life = { 1.4, 1.8 },
				speed = { 0.02, 0.04 },
				size = { { 0, rOuter * 0.8 }, { 1, rOuter * 1.6 } },
				transparency = { { 0, 0.45 }, { 1, 1 } },
				lightEmission = 0.1,
				shape = Enum.ParticleEmitterShape.Box,
				orientation = Enum.ParticleOrientation.VelocityPerpendicular,
				rotSpeed = 20,
			})
		elseif kind == "Shockwave" then
			local shock = emitter(ground, "AuraShockwave", {
				texture = "Spark",
				color = seq(p.light, p.main),
				rate = 0,
				life = { 0.6, 0.7 },
				speed = { 0.02, 0.05 },
				size = { { 0, 1 }, { 1, rOuter * 2.6 } },
				transparency = { { 0, 0.05 }, { 1, 1 } },
				lightEmission = 0.5,
				orientation = Enum.ParticleOrientation.VelocityPerpendicular,
				enabled = false,
				role = "Burst",
				rotSpeed = 0,
			})
			shock:SetAttribute("AuraBurstEvery", plan.pulseEvery or 3)
			shock:SetAttribute("AuraBurstCount", 1)
		elseif kind == "Pulse" then
			local pulse = emitter(core, "AuraPulse", {
				texture = "Spark",
				color = seq(p.light, p.main),
				rate = 0,
				life = { 0.45, 0.6 },
				speed = { 9, 13 },
				size = { { 0, 1.2 }, { 1, 0 } },
				lightEmission = 0.8,
				spread = Vector2.new(180, 180),
				shape = Enum.ParticleEmitterShape.Sphere,
				enabled = false,
				role = "Burst",
			})
			pulse:SetAttribute("AuraBurstEvery", plan.pulseEvery or 4)
			pulse:SetAttribute("AuraBurstCount", 18)
		elseif kind == "Signature" then
			local build = Signatures[style.Signature] or Signatures.Rings
			build(g, p, style, comp.count, signatureRate(comp))
		elseif kind == "Crown" then
			local crown = invisiblePart(model, "AuraCrown", Vector3.new(3, 0.1, 3), cf * CFrame.new(0, h * 0.5 + 0.9, 0))
			emitter(crown, "AuraCrownRing", {
				texture = "Spark",
				color = seq(p.light, p.accent),
				rate = comp.rate,
				life = { 0.9, 1.3 },
				speed = { 0.4, 0.8 },
				size = { { 0, 1.1 }, { 1, 0 } },
				lightEmission = 0.7,
				shape = Enum.ParticleEmitterShape.Cylinder,
				orientation = Enum.ParticleOrientation.VelocityPerpendicular,
			})
			-- comportamento periódico EXCLUSIVO do Secreto: erupção vertical a partir do anel do chão
			local eruption = emitter(ground, "AuraEruption", {
				texture = "Spark",
				color = seq(p.light, p.main, p.accent),
				rate = 0,
				life = { 0.6, 0.9 },
				speed = { riseSpeed * 1.4, riseSpeed * 2 },
				size = { { 0, 0.9 }, { 1, 0.2 } },
				lightEmission = 0.8,
				spread = Vector2.new(4, 4),
				shape = Enum.ParticleEmitterShape.Cylinder,
				orientation = Enum.ParticleOrientation.VelocityParallel,
				squash = 3,
				enabled = false,
				role = "Burst",
			})
			eruption:SetAttribute("AuraBurstEvery", 6)
			eruption:SetAttribute("AuraBurstCount", 36)
		end
	end
	-- CONTORNO da silhueta (Mítico+): o AuraController liga só nas mais próximas (orçamento)
	if plan.highlight then
		local outline = Instance.new("Highlight")
		outline.Name = "AuraOutline"
		outline.Adornee = model
		outline.FillColor = p.main
		outline.FillTransparency = 0.85
		outline.OutlineColor = if plan.style == "Dark" or plan.style == "Void" then p.light else p.main
		outline.OutlineTransparency = 0.1
		outline.DepthMode = Enum.HighlightDepthMode.Occluded
		outline.Enabled = false
		outline:SetAttribute("AuraRole", "Outline")
		outline.Parent = model
	end
	if plan.glow > 0 then
		local light = Instance.new("PointLight")
		light.Name = "AuraGlow" -- complemento: nunca o efeito principal
		light.Color = p.main
		light.Range = 6 + plan.glow * 4
		light.Brightness = plan.glow
		mark(light)
		light.Parent = core
	end
	-- REGRA: a aura emoldura, nunca engole o personagem. Toda fumaça/fogo (texturas grandes e
	-- opacas) renderiza ATRÁS do corpo (ZOffset além do raio externo); faíscas pequenas e
	-- brilhantes podem passar na frente. Medido em tests/roblox/AuraVisualAudit.luau (oclusão <= 30%).
	local behind = -(2 * rOuter + 4) -- além do alcance que a fumaça percorre na vida dela
	for _, obj in model:GetDescendants() do
		if obj:IsA("ParticleEmitter") and string.sub(obj.Name, 1, 4) == "Aura" then
			if obj.Texture == AuraConfig.Textures.Smoke or obj.Texture == AuraConfig.Textures.Fire then
				obj.ZOffset = math.min(obj.ZOffset, behind)
			end
		elseif obj:IsA("Beam") and (obj:GetAttribute("AuraRole") == "Wisp" or obj:GetAttribute("AuraRole") == "Gust") then
			obj.ZOffset = math.min(obj.ZOffset, -rMid)
		end
	end
	sizeScale, fade = 1, 1
	model:SetAttribute("Aura", plan.tier)
	model:SetAttribute("AuraStyle", plan.style)
	model:SetAttribute("AuraMode", mode)
	model:SetAttribute("AuraLayers", plan.layers)
	model:SetAttribute("AuraSilhouette", S)
	model:SetAttribute("AuraReach", rOuter)
	CollectionService:AddTag(model, AuraBuilder.Tag)
	return plan
end

-- Partes/objetos da aura (para medir/limpar): tudo que o attach criou
function AuraBuilder.instances(model: Model): { Instance }
	local list = {}
	for _, d in model:GetDescendants() do
		local n = d.Name
		if string.sub(n, 1, 4) == "Aura" then
			table.insert(list, d)
		end
	end
	return list
end

return AuraBuilder
