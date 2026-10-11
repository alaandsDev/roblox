--!strict
--[[
	CharacterModelFactory: cria o modelo 3D de um personagem (servidor: estações da base;
	cliente: reveal/cinemática, sempre LOCAL).

	    local model = CharacterModelFactory.build("dragon_knight", { variant = "Normal", aura = true })
	    model:PivotTo(cframeNoPiso)                  -- pivô = centro dos pés, olhando para -Z
	    CharacterModelFactory.pose(model, "Crouch")  -- Idle | Crouch (hero landing) | Confident
	    CharacterModelFactory.lerpPose(model, "Crouch", "Confident", 0.5)

	Se existir ReplicatedStorage.Assets.Characters.<ModelName>, usa o asset (TODO_ASSET);
	senão monta um placeholder em blocos a partir do VisualTheme (cabeça, tronco, braços e
	pernas em 2 partes para poder posar, acessório de cabeça, arma, asas e aura).
	Tudo ancorado, sem colisão/toque/consulta (barato para 80+ personagens no mapa).
]]

local Shared = script.Parent.Parent
local CharacterConfig = require(Shared.Config.CharacterConfig)
local RarityConfig = require(Shared.Config.RarityConfig)
local VariantConfig = require(Shared.Config.VariantConfig)
local AssetLoader = require(script.Parent.AssetLoader)

local CharacterModelFactory = {}

-- Escala base: o placeholder (5 studs) fica do tamanho do boneco de escala da base (~6.3)
local BASE_SCALE = 1.25

type Bone = { name: string, parent: string?, joint: Vector3, size: Vector3, center: Vector3, ball: boolean? }

-- Esqueleto (escala 1). Frame "Root" = centro do quadril, 2 studs acima dos pés.
local BONES: { Bone } = {
	{ name = "Torso", joint = Vector3.new(0, 0, 0), size = Vector3.new(2, 2, 1), center = Vector3.new(0, 1, 0) },
	{ name = "Head", parent = "Torso", joint = Vector3.new(0, 2, 0), size = Vector3.new(1.3, 1.3, 1.3), center = Vector3.new(0, 0.65, 0), ball = true },
	{ name = "LeftUpperArm", parent = "Torso", joint = Vector3.new(-1.5, 1.85, 0), size = Vector3.new(0.95, 1.1, 0.95), center = Vector3.new(0, -0.45, 0) },
	{ name = "LeftLowerArm", parent = "LeftUpperArm", joint = Vector3.new(0, -1, 0), size = Vector3.new(0.9, 1.05, 0.9), center = Vector3.new(0, -0.5, 0) },
	{ name = "RightUpperArm", parent = "Torso", joint = Vector3.new(1.5, 1.85, 0), size = Vector3.new(0.95, 1.1, 0.95), center = Vector3.new(0, -0.45, 0) },
	{ name = "RightLowerArm", parent = "RightUpperArm", joint = Vector3.new(0, -1, 0), size = Vector3.new(0.9, 1.05, 0.9), center = Vector3.new(0, -0.5, 0) },
	{ name = "LeftUpperLeg", joint = Vector3.new(-0.5, 0, 0), size = Vector3.new(0.98, 1.05, 0.98), center = Vector3.new(0, -0.5, 0) },
	{ name = "LeftLowerLeg", parent = "LeftUpperLeg", joint = Vector3.new(0, -1, 0), size = Vector3.new(0.96, 1.05, 0.96), center = Vector3.new(0, -0.5, 0) },
	{ name = "RightUpperLeg", joint = Vector3.new(0.5, 0, 0), size = Vector3.new(0.98, 1.05, 0.98), center = Vector3.new(0, -0.5, 0) },
	{ name = "RightLowerLeg", parent = "RightUpperLeg", joint = Vector3.new(0, -1, 0), size = Vector3.new(0.96, 1.05, 0.96), center = Vector3.new(0, -0.5, 0) },
}
local HIP_HEIGHT = 2

export type Pose = { root: CFrame, joints: { [string]: CFrame } }

local function rad(x: number): number
	return math.rad(x)
end
local function rx(deg: number): CFrame
	return CFrame.Angles(rad(deg), 0, 0)
end
local function rxz(x: number, z: number): CFrame
	return CFrame.Angles(rad(x), 0, rad(z))
end

-- Ângulo positivo em X = membro balança para a FRENTE (-Z); negativo no tronco = inclina à frente
CharacterModelFactory.Poses = {
	Idle = {
		root = CFrame.new(),
		joints = { LeftUpperArm = rxz(0, -6), RightUpperArm = rxz(0, 6) },
	} :: Pose,
	-- Aterrissagem de herói: joelho direito no chão, pé esquerdo à frente, punho direito no chão,
	-- tronco inclinado, cabeça baixa (pose ORIGINAL)
	Crouch = {
		root = CFrame.new(0, -1.05, 0) * rx(-22),
		joints = {
			Head = rx(-22),
			LeftUpperLeg = rx(112),
			LeftLowerLeg = rx(-90),
			RightUpperLeg = rx(22),
			RightLowerLeg = rx(-90),
			RightUpperArm = rxz(38, 4),
			RightLowerArm = rx(8),
			LeftUpperArm = rxz(55, -10),
			LeftLowerArm = rx(55),
		},
	} :: Pose,
	-- Pose final confiante: peito aberto, punho direito erguido, mão esquerda na cintura
	Confident = {
		root = rx(4),
		joints = {
			Head = rx(6),
			RightUpperArm = rxz(150, 18),
			RightLowerArm = rx(25),
			LeftUpperArm = rxz(-10, -35),
			LeftLowerArm = rxz(0, 75),
			LeftUpperLeg = rxz(0, -6),
			RightUpperLeg = rxz(0, 6),
		},
	} :: Pose,
}

-- Dados de pose por modelo (fraco: some quando o modelo é destruído)
type Rig = { scale: number, parts: { [string]: BasePart }, attached: { { part: BasePart, bone: string, offset: CFrame } } }
local rigs: { [Model]: Rig } = setmetatable({} :: any, { __mode = "k" })

local function rgb(list: { number }): Color3
	return Color3.fromRGB(list[1], list[2], list[3])
end

local function newPart(model: Model, name: string, size: Vector3, color: Color3, props: { [string]: any }?): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Massless = true
	if props then
		for key, value in props do
			(part :: any)[key] = value
		end
	end
	part.Parent = model
	return part
end

local function attach(rig: Rig, part: BasePart, bone: string, offset: CFrame)
	table.insert(rig.attached, { part = part, bone = bone, offset = offset })
end

-- Calcula o CFrame de cada osso e posiciona as peças (relativo ao pivô do modelo)
local function applyPose(model: Model, pose: Pose)
	local rig = rigs[model]
	local root = model.PrimaryPart
	if not rig or not root then
		return
	end
	local s = rig.scale
	local function scaled(cf: CFrame): CFrame
		return CFrame.new(cf.Position * s) * cf.Rotation
	end
	local base = root.CFrame * CFrame.new(0, HIP_HEIGHT * s - 0.1, 0) * scaled(pose.root)
	local frames: { [string]: CFrame } = {}
	for _, bone in BONES do
		local parentFrame = if bone.parent then frames[bone.parent] else base
		local rotation = pose.joints[bone.name] or CFrame.identity
		local frame = parentFrame * CFrame.new(bone.joint * s) * rotation
		frames[bone.name] = frame
		local part = rig.parts[bone.name]
		if part then
			part.CFrame = frame * CFrame.new(bone.center * s)
		end
	end
	for _, item in rig.attached do
		local frame = frames[item.bone]
		if frame then
			item.part.CFrame = frame * scaled(item.offset)
		end
	end
end

local function resolvePose(pose: string | Pose): Pose
	if type(pose) == "string" then
		return CharacterModelFactory.Poses[pose] or CharacterModelFactory.Poses.Idle
	end
	return pose
end

function CharacterModelFactory.pose(model: Model, pose: string | Pose)
	applyPose(model, resolvePose(pose))
end

-- Interpola entre duas poses (t de 0 a 1)
function CharacterModelFactory.lerpPose(model: Model, from: string | Pose, to: string | Pose, t: number)
	local a, b = resolvePose(from), resolvePose(to)
	local joints = {}
	for _, bone in BONES do
		local ja = a.joints[bone.name] or CFrame.identity
		local jb = b.joints[bone.name] or CFrame.identity
		joints[bone.name] = ja:Lerp(jb, t)
	end
	applyPose(model, { root = a.root:Lerp(b.root, t), joints = joints })
end

function CharacterModelFactory.isRigged(model: Model): boolean
	return rigs[model] ~= nil
end

------------------------------------------------------------------------------------
-- Acessórios (placeholder)

local function headgear(model: Model, rig: Rig, kind: string, primary: Color3, secondary: Color3)
	local gold = Color3.fromRGB(255, 205, 70)
	if kind == "Hood" then
		local hood = newPart(model, "Hood", Vector3.new(1.55, 1.2, 1.5), primary)
		attach(rig, hood, "Head", CFrame.new(0, 0.85, 0.12))
	elseif kind == "Helmet" then
		local helmet = newPart(model, "Helmet", Vector3.new(1.45, 0.8, 1.45), secondary, { Material = Enum.Material.Metal })
		attach(rig, helmet, "Head", CFrame.new(0, 1.05, 0))
		local crest = newPart(model, "Crest", Vector3.new(0.2, 0.6, 1.2), primary)
		attach(rig, crest, "Head", CFrame.new(0, 1.6, 0.1))
	elseif kind == "Spikes" then
		for i = -1, 1 do
			local spike = Instance.new("WedgePart")
			spike.Name = "Spike"
			spike.Size = Vector3.new(0.35, 0.9, 0.7)
			spike.Color = secondary
			spike.Anchored, spike.CanCollide, spike.CanTouch, spike.CanQuery, spike.CastShadow = true, false, false, false, false
			spike.Parent = model
			attach(rig, spike, "Head", CFrame.new(i * 0.4, 1.35, 0.15))
		end
	elseif kind == "Crown" then
		local crown = newPart(model, "Crown", Vector3.new(1.2, 0.45, 1.2), gold, { Material = Enum.Material.Neon })
		attach(rig, crown, "Head", CFrame.new(0, 1.42, 0))
	elseif kind == "Horns" then
		for _, side in { -1, 1 } do
			local horn = newPart(model, "Horn", Vector3.new(0.3, 0.9, 0.3), secondary)
			attach(rig, horn, "Head", CFrame.new(side * 0.5, 1.45, 0) * CFrame.Angles(0, 0, math.rad(-side * 25)))
		end
	elseif kind == "Halo" then
		local halo = newPart(model, "Halo", Vector3.new(0.15, 1.4, 1.4), gold, { Shape = Enum.PartType.Cylinder, Material = Enum.Material.Neon })
		attach(rig, halo, "Head", CFrame.new(0, 1.65, 0) * CFrame.Angles(0, 0, math.rad(90)))
	elseif kind == "Mask" then
		local mask = newPart(model, "Mask", Vector3.new(1.2, 0.5, 0.25), secondary)
		attach(rig, mask, "Head", CFrame.new(0, 0.5, -0.6))
	elseif kind == "Hat" then
		local brim = newPart(model, "HatBrim", Vector3.new(0.12, 2.2, 2.2), primary, { Shape = Enum.PartType.Cylinder })
		attach(rig, brim, "Head", CFrame.new(0, 1.2, 0) * CFrame.Angles(0, 0, math.rad(90)))
		local top = newPart(model, "HatTop", Vector3.new(0.9, 1.0, 1.0), primary, { Shape = Enum.PartType.Cylinder })
		attach(rig, top, "Head", CFrame.new(0, 1.55, 0) * CFrame.Angles(0, 0, math.rad(90)))
	elseif kind == "Ears" then
		for _, side in { -1, 1 } do
			local ear = newPart(model, "Ear", Vector3.new(0.35, 0.7, 0.2), primary)
			attach(rig, ear, "Head", CFrame.new(side * 0.45, 1.4, 0) * CFrame.Angles(0, 0, math.rad(-side * 15)))
		end
	end
end

local function weapon(model: Model, rig: Rig, kind: string, primary: Color3, secondary: Color3)
	local steel = Color3.fromRGB(215, 220, 230)
	local wood = Color3.fromRGB(120, 80, 50)
	-- Na mão direita: ponta da mão = (0, -1.05) do antebraço; arma apontando para a frente/cima
	local hand = CFrame.new(0, -1.05, 0)
	if kind == "Sword" or kind == "Katana" or kind == "Dagger" then
		local length = if kind == "Dagger" then 1.4 elseif kind == "Katana" then 3.6 else 3
		local width = if kind == "Katana" then 0.18 else 0.35
		local blade = newPart(model, "Blade", Vector3.new(0.12, width, length), steel, { Material = Enum.Material.Metal })
		attach(rig, blade, "RightLowerArm", hand * CFrame.new(0, 0, -length / 2 - 0.3))
		local guard = newPart(model, "Guard", Vector3.new(0.25, 0.8, 0.2), secondary)
		attach(rig, guard, "RightLowerArm", hand * CFrame.new(0, 0, -0.25))
	elseif kind == "Staff" then
		local pole = newPart(model, "Staff", Vector3.new(0.25, 4.4, 0.25), wood)
		attach(rig, pole, "RightLowerArm", hand * CFrame.new(0, 0.9, 0))
		local orb = newPart(model, "Orb", Vector3.new(0.8, 0.8, 0.8), secondary, { Shape = Enum.PartType.Ball, Material = Enum.Material.Neon })
		attach(rig, orb, "RightLowerArm", hand * CFrame.new(0, 3.2, 0))
	elseif kind == "Spear" then
		local pole = newPart(model, "Spear", Vector3.new(0.2, 5, 0.2), wood)
		attach(rig, pole, "RightLowerArm", hand * CFrame.new(0, 1.2, 0))
		local tip = newPart(model, "SpearTip", Vector3.new(0.12, 0.9, 0.35), secondary, { Material = Enum.Material.Neon })
		attach(rig, tip, "RightLowerArm", hand * CFrame.new(0, 4.1, 0))
	elseif kind == "Scythe" then
		local pole = newPart(model, "Scythe", Vector3.new(0.22, 5, 0.22), Color3.fromRGB(40, 35, 45))
		attach(rig, pole, "RightLowerArm", hand * CFrame.new(0, 1.2, 0))
		local blade = newPart(model, "ScytheBlade", Vector3.new(0.12, 0.45, 2.4), secondary, { Material = Enum.Material.Neon })
		attach(rig, blade, "RightLowerArm", hand * CFrame.new(0, 3.5, 1.0))
	elseif kind == "Hammer" then
		local handle = newPart(model, "HammerHandle", Vector3.new(0.25, 2.6, 0.25), wood)
		attach(rig, handle, "RightLowerArm", hand * CFrame.new(0, 0.6, 0))
		local head = newPart(model, "HammerHead", Vector3.new(0.9, 0.9, 1.6), secondary, { Material = Enum.Material.Metal })
		attach(rig, head, "RightLowerArm", hand * CFrame.new(0, 1.9, 0))
	elseif kind == "Bow" then
		for i = -1, 1 do
			local limb = newPart(model, "Bow", Vector3.new(0.18, 1.1, 0.18), wood)
			attach(rig, limb, "LeftLowerArm", CFrame.new(0, -1.05, -0.35) * CFrame.new(0, i * 0.95, math.abs(i) * 0.3) * CFrame.Angles(math.rad(-i * 30), 0, 0))
		end
	elseif kind == "Shield" then
		local shield = newPart(model, "Shield", Vector3.new(0.25, 2, 2), secondary, { Shape = Enum.PartType.Cylinder, Material = Enum.Material.Metal })
		attach(rig, shield, "LeftLowerArm", CFrame.new(-0.6, -0.5, 0) * CFrame.Angles(0, 0, 0))
	elseif kind == "Fists" then
		for _, bone in { "LeftLowerArm", "RightLowerArm" } do
			local glove = newPart(model, "Glove", Vector3.new(1.05, 0.55, 1.05), secondary, { Material = Enum.Material.Neon })
			attach(rig, glove, bone, CFrame.new(0, -0.85, 0))
		end
	end
	local _ = primary
end

local function wings(model: Model, rig: Rig, color: Color3)
	for _, side in { -1, 1 } do
		local wing = newPart(model, "Wing", Vector3.new(0.15, 2.6, 1.6), color, { Material = Enum.Material.Neon, Transparency = 0.15 })
		attach(rig, wing, "Torso", CFrame.new(side * 1.3, 1.6, 0.85) * CFrame.Angles(0, math.rad(side * 30), math.rad(side * 25)))
	end
end

-- Aura: brilho + partículas leves. LOD/qualidade podem desligar (atributo "Aura")
local function aura(model: Model, torso: BasePart, kind: string, color: Color3)
	local light = Instance.new("PointLight")
	light.Name = "AuraLight"
	light.Color = color
	light.Range = if kind == "Soft" then 8 else 12
	light.Brightness = if kind == "Soft" then 0.8 else 1.6
	light.Parent = torso
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "Aura"
	emitter.Color = ColorSequence.new(color)
	emitter.LightEmission = 1
	emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1) })
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) })
	emitter.Lifetime = NumberRange.new(0.8, 1.4)
	emitter.Speed = NumberRange.new(1.5, 3)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Rate = if kind == "Soft" then 4 elseif kind == "Strong" then 8 else 14
	emitter.Parent = torso
	model:SetAttribute("Aura", kind)
end

------------------------------------------------------------------------------------

export type BuildOptions = { variant: string?, aura: boolean?, scale: number? }

function CharacterModelFactory.build(characterId: string, options: BuildOptions?): Model
	local opts: BuildOptions = options or {}
	local character = CharacterConfig.ById[characterId]
	assert(character, `personagem desconhecido: {characterId}`)
	local rarity = RarityConfig.ById[character.Rarity]
	local scale = BASE_SCALE * rarity.ModelScale * (opts.scale or 1)

	-- Asset final (quando existir)
	local asset = AssetLoader.model("Characters", character.ModelName, 6.3 * rarity.ModelScale * (opts.scale or 1))
	if asset then
		asset.Name = character.Id
		asset:SetAttribute("CharacterId", character.Id)
		return asset
	end

	local theme = character.VisualTheme
	local primary, secondary, skin = rgb(theme.Primary), rgb(theme.Secondary), rgb(theme.Skin)
	local variant = VariantConfig.ById[opts.variant or "Normal"]
	if variant and variant.Id ~= "Normal" then
		secondary = rgb(variant.Color)
	end

	local model = Instance.new("Model")
	model.Name = character.Id
	model:SetAttribute("CharacterId", character.Id)
	model:SetAttribute("Rarity", character.Rarity)
	-- Placeholder: trocar pelo modelo final em Assets.Characters (ver ASSETS.md)
	model:SetAttribute("TODO_ASSET", true)

	local root = newPart(model, "Root", Vector3.new(1, 0.2, 1), primary, { Transparency = 1 })
	model.PrimaryPart = root

	local rig: Rig = { scale = scale, parts = {}, attached = {} }
	rigs[model] = rig
	local colors = {
		Torso = primary,
		Head = skin,
		LeftUpperArm = primary,
		RightUpperArm = primary,
		LeftLowerArm = skin,
		RightLowerArm = skin,
		LeftUpperLeg = secondary,
		RightUpperLeg = secondary,
		LeftLowerLeg = Color3.fromRGB(45, 45, 60),
		RightLowerLeg = Color3.fromRGB(45, 45, 60),
	}
	for _, bone in BONES do
		local part = newPart(model, bone.name, bone.size * scale, colors[bone.name])
		if bone.ball then
			part.Shape = Enum.PartType.Ball
		end
		rig.parts[bone.name] = part
	end
	local face = Instance.new("Decal")
	face.Name = "face"
	face.Texture = "rbxasset://textures/face.png"
	face.Face = Enum.NormalId.Front
	face.Parent = rig.parts.Head
	-- Faixa/cinto com a cor secundária
	local belt = newPart(model, "Belt", Vector3.new(2.05, 0.35, 1.05) * scale, secondary)
	attach(rig, belt, "Torso", CFrame.new(0, 0.2, 0))

	headgear(model, rig, theme.Headgear, primary, secondary)
	weapon(model, rig, theme.Weapon, primary, secondary)
	if theme.Wings then
		wings(model, rig, secondary)
	end
	-- Acessórios escalam junto
	for _, item in rig.attached do
		if item.part.Name ~= "Belt" then
			item.part.Size *= scale
		end
	end
	if opts.aura ~= false and rarity.Aura then
		aura(model, rig.parts.Torso, rarity.Aura, rgb(rarity.Color))
	end

	root.CFrame = CFrame.new(0, 0.1, 0)
	model.WorldPivot = CFrame.new()
	applyPose(model, CharacterModelFactory.Poses.Idle)
	-- Pivô no centro dos pés (o Root fica no chão)
	model.WorldPivot = root.CFrame * CFrame.new(0, -0.1, 0)
	return model
end

-- Altura aproximada do modelo (para posicionar o BillboardGui acima da cabeça)
function CharacterModelFactory.height(characterId: string): number
	local character = CharacterConfig.ById[characterId]
	local rarity = character and RarityConfig.ById[character.Rarity]
	return 5.6 * BASE_SCALE * (if rarity then rarity.ModelScale else 1)
end

return CharacterModelFactory
