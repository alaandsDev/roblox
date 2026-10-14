--!strict
--[[
	AuraBuilder: monta a aura de raridade (Lendário/Mítico/Divino/Secreto) a partir de AuraConfig.
	    AuraBuilder.styleOf(characterId)            -> estilo (override do personagem > Dice > padrão)
	    AuraBuilder.resolve(characterId, rarity, mode) -> PLANO puro (testável): componentes e taxas
	    AuraBuilder.attach(model, characterId, rarity, mode) -> cria as Instances no modelo
	Componentes ESTÁTICOS (partículas/beams) são criados aqui; o MOVIMENTO (órbita, raios piscando,
	pulsos) é do AuraController do cliente (um loop central, com culling e orçamento).
	Nada de script dentro do modelo; só texturas nativas do Roblox.
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

function AuraBuilder.resolve(characterId: string, rarity: string, mode: string): AuraPlanner.Plan?
	return planner:resolve(characterId, rarity, mode)
end

------------------------------------------------------------------------------------
-- Instances

local function c3(list: { number }): Color3
	return Color3.fromRGB(list[1], list[2], list[3])
end

local function colorSeq(style: any): ColorSequence
	local cs = style.Colors
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, c3(cs[2] or cs[1])),
		ColorSequenceKeypoint.new(0.35, c3(cs[1])),
		ColorSequenceKeypoint.new(1, c3(cs[3] or cs[1])),
	})
end

local function emitter(parent: Instance, name: string, style: any, opts: { [string]: any }): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Name = name
	e.Texture = AuraConfig.Textures[opts.texture or style.Texture]
	e.Color = opts.color or colorSeq(style)
	e.LightEmission = opts.lightEmission or 0.7
	e.LightInfluence = 0
	e.Rate = opts.rate or 10
	e.Lifetime = NumberRange.new((opts.lifetime or style.Lifetime) * 0.7, opts.lifetime or style.Lifetime)
	e.Speed = NumberRange.new((opts.speed or style.Speed) * 0.6, opts.speed or style.Speed)
	local size = opts.size or style.Size
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(0.6, size * 0.7), NumberSequenceKeypoint.new(1, 0) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(0.7, 0.45), NumberSequenceKeypoint.new(1, 1) })
	e.Drag = opts.drag or style.Drag
	e.RotSpeed = NumberRange.new(-90, 90)
	e.Rotation = NumberRange.new(0, 360)
	e.SpreadAngle = opts.spread or Vector2.new(15, 15)
	if opts.streak or (opts.streak == nil and style.Streak) then
		e.Orientation = Enum.ParticleOrientation.VelocityParallel
		e.Squash = NumberSequence.new(1.6)
	end
	if opts.acceleration then
		e.Acceleration = opts.acceleration
	end
	e.Shape = opts.shape or Enum.ParticleEmitterShape.Box
	e.ShapeStyle = opts.shapeStyle or Enum.ParticleEmitterShapeStyle.Surface
	e.ShapeInOut = opts.inOut or Enum.ParticleEmitterShapeInOut.Outward
	e.EmissionDirection = opts.direction or Enum.NormalId.Top
	e.Enabled = opts.enabled ~= false
	e:SetAttribute("BaseRate", e.Rate)
	e:SetAttribute("VFXTier", "Light")
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

-- Cria a aura no modelo. Devolve o plano usado (nil = sem aura).
function AuraBuilder.attach(model: Model, characterId: string, rarity: string, mode: string, height: number?): AuraPlanner.Plan?
	local plan = AuraBuilder.resolve(characterId, rarity, mode)
	if not plan then
		return nil
	end
	local style = AuraConfig.Styles[plan.style]
	local cf, size = bounds(model, height or 5)
	local h = math.max(size.Y, 2)
	local w = math.max(math.max(size.X, size.Z), 1.2)
	-- volume um pouco MAIOR que o corpo: as partículas nascem fora da silhueta
	local core = invisiblePart(model, "AuraCore", Vector3.new(w * 0.9, h * 0.95, w * 0.7), cf)
	local feet = cf * CFrame.new(0, -h / 2, 0)
	local dirUp = style.Direction == "Up"
	local inward = style.Direction == "In"

	for _, comp in plan.components do
		if comp.kind == "Body" then
			for layer = 1, comp.count do
				emitter(core, "AuraBody" .. layer, style, {
					rate = comp.rate,
					size = style.Size * (1 + (layer - 1) * 0.35),
					lifetime = style.Lifetime * (1 + (layer - 1) * 0.3),
					inOut = if inward then Enum.ParticleEmitterShapeInOut.Inward else Enum.ParticleEmitterShapeInOut.Outward,
					acceleration = if dirUp then Vector3.new(0, 4 + layer, 0) else nil,
					spread = if style.Direction == "Swirl" then Vector2.new(60, 60) else Vector2.new(20, 20),
					lightEmission = if plan.style == "Dark" or plan.style == "Void" then 0.15 else 0.8,
				})
			end
		elseif comp.kind == "Rise" then
			emitter(core, "AuraRise", style, {
				rate = comp.rate,
				texture = "Spark",
				size = 0.35,
				speed = 9,
				lifetime = 0.7,
				streak = true,
				shapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
				direction = Enum.NormalId.Top,
				spread = Vector2.new(4, 4),
				acceleration = Vector3.new(0, 6, 0),
			})
		elseif comp.kind == "Sparks" then
			emitter(core, "AuraSparks", style, {
				rate = comp.rate,
				texture = "Spark",
				size = 0.22,
				speed = 14,
				lifetime = 0.25,
				streak = true,
				spread = Vector2.new(180, 180),
				lightEmission = 1,
			})
		elseif comp.kind == "Orbit" then
			for i = 1, comp.count do
				local a0 = Instance.new("Attachment")
				a0.Name = "AuraOrbit" .. i
				a0:SetAttribute("AuraRole", "Orbit")
				a0:SetAttribute("AuraIndex", i)
				a0:SetAttribute("AuraCount", comp.count)
				a0:SetAttribute("AuraRadius", w * 0.85 + 0.6)
				a0:SetAttribute("AuraHeight", (i / (comp.count + 1) - 0.5) * h * 0.8)
				a0:SetAttribute("AuraSpeed", style.OrbitSpeed * (if i % 2 == 0 then -1 else 1))
				a0.Parent = core
				local a1 = Instance.new("Attachment")
				a1.Name = "AuraOrbitTail" .. i
				a1.Parent = a0
				a1.Position = Vector3.new(0, 0.5, 0)
				local trail = Instance.new("Trail")
				trail.Name = "AuraOrbitTrail" .. i
				trail.Attachment0 = a0
				trail.Attachment1 = a1
				trail.Color = colorSeq(style)
				trail.LightEmission = 1
				trail.Lifetime = 0.35
				trail.FaceCamera = true
				trail.Transparency = NumberSequence.new(0.1, 1)
				trail.WidthScale = NumberSequence.new(1, 0)
				trail.Parent = a0
				trail:SetAttribute("VFXTier", "Light")
				emitter(core, "AuraOrbitSpark" .. i, style, { rate = 0, texture = "Spark", size = 0.4, speed = 0.5, lifetime = 0.4, enabled = false })
			end
		elseif comp.kind == "Bolt" or comp.kind == "Wisp" then
			-- pontos do corpo: ombros, mãos, peito, quadris (relativos ao volume — vale p/ qualquer rig)
			local points = {
				Vector3.new(-w * 0.45, h * 0.3, 0), Vector3.new(-w * 0.55, -h * 0.05, 0), -- braço esq.
				Vector3.new(w * 0.45, h * 0.3, 0), Vector3.new(w * 0.55, -h * 0.05, 0), -- braço dir.
				Vector3.new(0, h * 0.35, -w * 0.3), Vector3.new(0, -h * 0.1, -w * 0.3), -- torso
				Vector3.new(-w * 0.3, -h * 0.25, 0), Vector3.new(w * 0.3, h * 0.1, 0), -- diagonal
			}
			for i = 1, comp.count do
				local p0 = points[((i - 1) * 2) % #points + 1]
				local p1 = points[((i - 1) * 2 + 1) % #points + 1]
				local a0 = Instance.new("Attachment")
				a0.Name = "AuraBoltA" .. i
				a0.Position = p0
				a0.Parent = core
				local a1 = Instance.new("Attachment")
				a1.Name = "AuraBoltB" .. i
				a1.Position = p1
				a1.Parent = core
				local beam = Instance.new("Beam")
				beam.Name = "Aura" .. comp.kind .. i
				beam.Attachment0 = a0
				beam.Attachment1 = a1
				beam.Color = colorSeq(style)
				beam.LightEmission = 1
				beam.FaceCamera = true
				beam.Segments = if comp.kind == "Bolt" then 12 else 18
				beam.Width0 = if comp.kind == "Bolt" then 0.22 else 0.6
				beam.Width1 = if comp.kind == "Bolt" then 0.12 else 0.1
				beam.CurveSize0 = 1
				beam.CurveSize1 = -1
				if comp.kind == "Wisp" then
					beam.Texture = AuraConfig.Textures.Smoke
					beam.TextureSpeed = 1.5
					beam.Transparency = NumberSequence.new(0.2, 0.8)
				end
				beam:SetAttribute("AuraRole", comp.kind)
				beam:SetAttribute("VFXTier", "Light")
				beam.Parent = core
			end
		elseif comp.kind == "Pulse" then
			local pulse = emitter(core, "AuraPulse", style, {
				rate = 0,
				size = style.Size * 1.3,
				speed = 12,
				lifetime = 0.5,
				spread = Vector2.new(180, 180),
				shape = Enum.ParticleEmitterShape.Sphere,
				lightEmission = 1,
				enabled = false,
			})
			pulse:SetAttribute("AuraRole", "Pulse")
			pulse:SetAttribute("AuraPulseEvery", plan.pulseEvery or 3)
			pulse:SetAttribute("AuraPulseCount", AuraConfig.Tiers[plan.tier].PulseCount)
		elseif comp.kind == "Ground" then
			local ground = invisiblePart(model, "AuraGround", Vector3.new(w * 2.2, 0.2, w * 2.2), feet * CFrame.new(0, 0.15, 0))
			emitter(ground, "AuraGroundRing", style, {
				rate = comp.rate,
				size = 0.6,
				speed = 1.5,
				lifetime = 0.9,
				shape = Enum.ParticleEmitterShape.Cylinder,
				shapeStyle = Enum.ParticleEmitterShapeStyle.Surface,
				direction = Enum.NormalId.Top,
				acceleration = Vector3.new(0, 2, 0),
			})
		end
	end
	if plan.glow > 0 then
		local light = Instance.new("PointLight")
		light.Name = "AuraGlow" -- complemento: nunca o efeito principal
		light.Color = c3(style.Colors[1])
		light.Range = 6 + plan.glow * 4
		light.Brightness = plan.glow
		light:SetAttribute("VFXTier", "Light") -- o LodController desliga de longe
		light.Parent = core
	end
	model:SetAttribute("Aura", plan.tier)
	model:SetAttribute("AuraStyle", plan.style)
	model:SetAttribute("AuraMode", mode)
	CollectionService:AddTag(model, AuraBuilder.Tag)
	return plan
end

return AuraBuilder
