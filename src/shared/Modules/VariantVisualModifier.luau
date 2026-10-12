--!strict
--[[
	VariantVisualModifier: mostra a Variante (Silver, Gold, Diamond, Emerald, Void, Celestial)
	em cima do MESMO modelo base — sem sete modelos e sem pintar o personagem inteiro.

	O que muda (só complementa):
	  - Anel no chão (VariantRing) na cor da variante.
	  - "Acentos": peças que NÃO são o corpo (armas, cabelo, acessórios, capas) puxam um pouco
	    para a cor da variante (Tint). Peças com textura própria só recebem um tom leve
	    (SpecialMesh.VertexColor); MeshPart com textura não muda.
	  - Brilhos (ParticleEmitter leve) nas variantes altas e luz nas duas maiores (só no modo Full).
	O que NUNCA muda: corpo (Head/Torso/braços/pernas), rosto (Decal), roupas (Shirt/Pants),
	BodyColors e texturas.

	    VariantVisualModifier.apply(model, "Gold", "Light", scale)
]]

local Shared = script.Parent.Parent
local VariantConfig = require(Shared.Config.VariantConfig)
local CharacterAssetConfig = require(Shared.Config.CharacterAssetConfig)
local Pipeline = require(script.Parent.CharacterAssetPipeline)

local VariantVisualModifier = {}

export type Style = {
	Tint: number, -- 0..1: quanto os acentos puxam para a cor da variante
	Reflectance: number,
	RingNeon: boolean,
	Sparkles: number, -- partículas/s (0 = sem brilho)
	Light: boolean, -- PointLight (só no modo Full)
}

VariantVisualModifier.Styles = {
	Silver = { Tint = 0.3, Reflectance = 0.15, RingNeon = false, Sparkles = 0, Light = false },
	Gold = { Tint = 0.4, Reflectance = 0.2, RingNeon = false, Sparkles = 2, Light = false },
	Diamond = { Tint = 0.35, Reflectance = 0.3, RingNeon = true, Sparkles = 3, Light = false },
	Emerald = { Tint = 0.4, Reflectance = 0.2, RingNeon = true, Sparkles = 3, Light = false },
	Void = { Tint = 0.45, Reflectance = 0.1, RingNeon = true, Sparkles = 4, Light = true },
	Celestial = { Tint = 0.35, Reflectance = 0.25, RingNeon = true, Sparkles = 5, Light = true },
} :: { [string]: Style }

local BODY = {}
for name in CharacterAssetConfig.R6Parts do
	BODY[name] = true
end
BODY.PivotRoot = true

-- Peças de acento = tudo que não é o corpo R6 (armas, cabelo, acessórios, capas)
function VariantVisualModifier.isAccent(part: BasePart): boolean
	return not BODY[part.Name] and part:GetAttribute("VariantFX") == nil
end

local function decor(part: BasePart)
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	part.CastShadow = false
end

function VariantVisualModifier.apply(model: Model, variantId: string?, vfxMode: string?, scale: number?)
	local variant = VariantConfig.ById[variantId or "Normal"]
	local style = variant and VariantVisualModifier.Styles[variant.Id]
	model:SetAttribute("Variant", if variant then variant.Id else "Normal")
	if not variant or not style then
		return
	end
	local color = Color3.fromRGB(variant.Color[1], variant.Color[2], variant.Color[3])
	local s = scale or 1
	local mode = vfxMode or "Light"

	for _, obj in model:GetDescendants() do
		if obj:IsA("BasePart") and VariantVisualModifier.isAccent(obj) and obj.Transparency < 1 then
			local textured = Pipeline.textureOf(obj) ~= ""
			local mesh = obj:FindFirstChildOfClass("SpecialMesh")
			if mesh and Pipeline.textureOf(mesh) ~= "" then
				local tone = Vector3.new(1, 1, 1):Lerp(Vector3.new(color.R, color.G, color.B), style.Tint * 0.6)
				mesh.VertexColor = Vector3.new(mesh.VertexColor.X * tone.X, mesh.VertexColor.Y * tone.Y, mesh.VertexColor.Z * tone.Z)
			elseif not textured then
				obj.Color = obj.Color:Lerp(color, style.Tint)
			end
			obj.Reflectance = math.max(obj.Reflectance, style.Reflectance)
		end
	end

	local root = model.PrimaryPart
	local torso = model:FindFirstChild("Torso")
	if root then
		local ring = Instance.new("Part")
		ring.Name = "VariantRing"
		ring.Shape = Enum.PartType.Cylinder
		ring.Size = Vector3.new(0.12, 4.2 * s, 4.2 * s)
		ring.CFrame = root.CFrame * CFrame.new(0, 0.06, 0) * CFrame.Angles(0, 0, math.rad(90))
		ring.Color = color
		ring.Material = if style.RingNeon then Enum.Material.Neon else Enum.Material.SmoothPlastic
		ring.Transparency = 0.35
		decor(ring)
		ring:SetAttribute("VariantFX", true)
		ring:SetAttribute("Bone", "Root")
		ring.Parent = model
	end
	if torso and mode ~= "None" and style.Sparkles > 0 then
		local sparkle = Instance.new("ParticleEmitter")
		sparkle.Name = "VariantSparkle"
		sparkle.Color = ColorSequence.new(color)
		sparkle.LightEmission = 1
		sparkle.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35 * s), NumberSequenceKeypoint.new(1, 0) })
		sparkle.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
		sparkle.Lifetime = NumberRange.new(0.6, 1.1)
		sparkle.Speed = NumberRange.new(0.5, 1.5)
		sparkle.SpreadAngle = Vector2.new(180, 180)
		sparkle.Rate = style.Sparkles
		sparkle:SetAttribute("VFXTier", "Light")
		sparkle:SetAttribute("VariantFX", true)
		sparkle.Parent = torso
	end
	if torso and mode == "Full" and style.Light then
		local light = Instance.new("PointLight")
		light.Name = "VariantLight"
		light.Color = color
		light.Range = 8 * s
		light.Brightness = 1.2
		light:SetAttribute("VFXTier", "Full")
		light:SetAttribute("VariantFX", true)
		light.Parent = torso
	end
end

return VariantVisualModifier
