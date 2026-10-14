--!strict
--[[
	CharacterModelFactory: ÚNICA fonte do visual de um personagem (servidor: estações da base e
	galeria DEV; cliente: reveal, inventário, índice, hero landing — sempre LOCAL).

	    local model = CharacterModelFactory.build("char_ichiro_base", { variant = "Gold", vfx = "Light" })
	    model:PivotTo(cframeNoPiso)                  -- pivô = centro dos pés, olhando para -Z
	    CharacterModelFactory.spawn(id, cframe, opts) -- build + PivotTo (+ Parent opcional)
	    CharacterModelFactory.pose(model, "Reveal")  -- Idle | Reveal | Combat | Crouch | Confident
	    CharacterModelFactory.lerpPose(model, "Crouch", "Confident", 0.5)

	Origem do visual:
	  1. ReplicatedStorage.CharacterAssets.<CharacterId>: asset SANITIZADO pelo pipeline
	     (CharacterAssetPipeline). O template é validado uma vez; inválido = não é usado.
	  2. Placeholder em blocos a partir do VisualTheme (FALLBACK: asset ausente/inválido ou
	     CharacterId desconhecido; avisa uma vez no Output).
	Modos de VFX (opts.vfx): None | Light | Full (padrão: Light; aura = false -> None).
	Tudo ancorado, sem colisão/toque/consulta, sem scripts (barato para 400 personagens).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = script.Parent.Parent
local CharacterConfig = require(Shared.Config.CharacterConfig)
local RarityConfig = require(Shared.Config.RarityConfig)
local VariantConfig = require(Shared.Config.VariantConfig)
local CharacterAssetConfig = require(Shared.Config.CharacterAssetConfig)
local Pipeline = require(script.Parent.CharacterAssetPipeline)
local VariantVisualModifier = require(script.Parent.VariantVisualModifier)
local AuraBuilder = require(script.Parent.AuraBuilder)

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
	-- Reveal: braço direito erguido, cabeça levantada
	Reveal = {
		root = rx(3),
		joints = { Head = rx(8), RightUpperArm = rxz(165, 10), RightLowerArm = rx(10), LeftUpperArm = rxz(-15, -25), LeftUpperLeg = rxz(0, -6), RightUpperLeg = rxz(0, 6) },
	} :: Pose,
	-- Combate/card: base aberta, braços à frente
	Combat = {
		root = CFrame.new(0, -0.15, 0) * rx(-6),
		joints = {
			RightUpperArm = rxz(80, 10),
			RightLowerArm = rx(20),
			LeftUpperArm = rxz(45, -15),
			LeftLowerArm = rx(30),
			RightUpperLeg = rxz(-15, 8),
			LeftUpperLeg = rxz(20, -8),
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

------------------------------------------------------------------------------------
-- Poses do ASSET R6 (próprias do Roll Legends; nenhuma animação do pack é usada).
-- Ossos: Head, LeftArm, RightArm, LeftLeg, RightLeg (+ root = tronco inteiro, a partir do quadril).
-- Mesma convenção: X positivo = membro para a FRENTE; Z negativo no braço esquerdo = para fora.

local R6_BONES = { "Head", "LeftArm", "RightArm", "LeftLeg", "RightLeg" }

CharacterModelFactory.R6Poses = {
	Idle = {
		root = CFrame.new(),
		joints = { LeftArm = rxz(0, -4), RightArm = rxz(0, 4) },
	} :: Pose,
	Reveal = {
		root = rx(3),
		joints = { Head = rx(8), RightArm = rxz(165, 10), LeftArm = rxz(-15, -25), LeftLeg = rxz(0, -6), RightLeg = rxz(0, 6) },
	} :: Pose,
	Combat = {
		root = CFrame.new(0, -0.15, 0) * rx(-6),
		joints = { RightArm = rxz(80, 10), LeftArm = rxz(45, -15), RightLeg = rxz(-15, 8), LeftLeg = rxz(20, -8) },
	} :: Pose,
	-- Aterrissagem de herói (R6 não dobra joelho: perna esquerda à frente, direita para trás)
	Crouch = {
		root = CFrame.new(0, -0.9, 0) * rx(-18),
		joints = { Head = rx(-18), LeftLeg = rx(75), RightLeg = rx(-35), RightArm = rxz(45, 4), LeftArm = rxz(55, -10) },
	} :: Pose,
	Confident = {
		root = rx(4),
		joints = { Head = rx(6), RightArm = rxz(155, 15), LeftArm = rxz(-10, -35), LeftLeg = rxz(0, -6), RightLeg = rxz(0, 6) },
	} :: Pose,
}

local function isAssetRig(model: Model): boolean
	return model:GetAttribute("AssetRig") == true
end

-- Pivôs das juntas no espaço do pivô (pose de repouso, já escalada)
local function restOf(part: Instance?): CFrame?
	local rest = part and part:GetAttribute("Rest")
	return if typeof(rest) == "CFrame" then rest else nil
end

local function assetJoints(model: Model): ({ [string]: CFrame }?, CFrame?)
	local torso = model:FindFirstChild("Torso")
	local torsoRest = restOf(torso)
	if not torso or not torso:IsA("BasePart") or not torsoRest then
		return nil
	end
	local hip = CFrame.new((torsoRest * CFrame.new(0, -torso.Size.Y / 2, 0)).Position)
	local pivots: { [string]: CFrame } = {
		Head = CFrame.new((torsoRest * CFrame.new(0, torso.Size.Y / 2, 0)).Position),
	}
	local limbs: { [string]: string } = { LeftArm = "Left Arm", RightArm = "Right Arm", LeftLeg = "Left Leg", RightLeg = "Right Leg" }
	for bone, name in limbs do
		local limb = model:FindFirstChild(name)
		local rest = restOf(limb)
		if limb and limb:IsA("BasePart") and rest then
			local top = if string.find(bone, "Arm") then limb.Size.Y / 2 - limb.Size.X / 2 else limb.Size.Y / 2
			pivots[bone] = CFrame.new((rest * CFrame.new(0, top, 0)).Position)
		end
	end
	return pivots, hip
end

local function applyAssetPose(model: Model, pose: Pose)
	local root = model.PrimaryPart
	local joints, hip = assetJoints(model)
	if not root or not joints or not hip then
		return
	end
	local s = (model:GetAttribute("RuntimeScale") :: number?) or 1
	local scaled = CFrame.new(pose.root.Position * s) * pose.root.Rotation
	local base = root.CFrame * hip * scaled * hip:Inverse()
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			local bone = part:GetAttribute("Bone")
			local rest = restOf(part)
			if rest and bone ~= "Root" then
				local pivot = joints[bone :: string]
				if pivot then
					local rotation = pose.joints[bone :: string] or CFrame.identity
					part.CFrame = base * pivot * rotation * pivot:Inverse() * rest
				else
					part.CFrame = base * rest
				end
			end
		end
	end
end

local function resolvePose(pose: string | Pose, asset: boolean): Pose
	if type(pose) == "string" then
		local poses = if asset then CharacterModelFactory.R6Poses else CharacterModelFactory.Poses
		return poses[pose] or poses.Idle
	end
	return pose
end

function CharacterModelFactory.pose(model: Model, pose: string | Pose)
	if isAssetRig(model) then
		applyAssetPose(model, resolvePose(pose, true))
	else
		applyPose(model, resolvePose(pose, false))
	end
end

-- Interpola entre duas poses (t de 0 a 1)
function CharacterModelFactory.lerpPose(model: Model, from: string | Pose, to: string | Pose, t: number)
	local asset = isAssetRig(model)
	local a, b = resolvePose(from, asset), resolvePose(to, asset)
	local joints = {}
	local names: { string } = if asset then R6_BONES else {}
	if not asset then
		for _, bone in BONES do
			table.insert(names, bone.name)
		end
	end
	for _, name in names do
		local ja = a.joints[name] or CFrame.identity
		local jb = b.joints[name] or CFrame.identity
		joints[name] = ja:Lerp(jb, t)
	end
	local blended = { root = a.root:Lerp(b.root, t), joints = joints }
	if asset then
		applyAssetPose(model, blended)
	else
		applyPose(model, blended)
	end
end

function CharacterModelFactory.isRigged(model: Model): boolean
	return rigs[model] ~= nil or isAssetRig(model)
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

-- Aura de raridade: Épico = suave (acima); Lendário+ = sistema de auras (AuraConfig/AuraBuilder:
-- raridade = intensidade, estilo do personagem = comportamento). Nada disso é só "glow".
local function rarityAura(model: Model, character: any, rarity: any, mode: string, torso: BasePart)
	if AuraBuilder.resolve(character.Id, character.Rarity, mode) then
		AuraBuilder.attach(model, character.Id, character.Rarity, mode, CharacterModelFactory.height(character.Id))
	elseif rarity.Aura then
		aura(model, torso, rarity.Aura, rgb(rarity.Color))
	end
end

------------------------------------------------------------------------------------

export type BuildOptions = {
	variant: string?,
	aura: boolean?, -- false = sem aura de raridade (e VFX None, se vfx não for informado)
	scale: number?,
	vfx: string?, -- None | Light | Full
	pose: string?, -- pose inicial (padrão Idle)
}

local VFX_CLASSES = { "ParticleEmitter", "Beam", "Trail", "Fire", "Smoke", "Sparkles", "PointLight", "SpotLight" }

-- Avisos de desenvolvimento (uma vez por personagem)
local warned: { [string]: boolean } = {}
local function warnOnce(key: string, message: string)
	if not warned[key] then
		warned[key] = true
		warn("[CharacterModelFactory] " .. message)
	end
end

-- Template validado (cache por CharacterId): Model, ou false se ausente/inválido
local templates: { [string]: Model | false } = {}

local function storage(): Instance?
	return ReplicatedStorage:FindFirstChild(CharacterAssetConfig.StorageName)
end

function CharacterModelFactory.template(characterId: string): Model?
	local cached = templates[characterId]
	if cached == false then
		return nil
	elseif cached ~= nil then
		return cached :: Model
	end
	local folder = storage()
	local template = folder and folder:FindFirstChild(characterId)
	if not template then
		templates[characterId] = false
		if CharacterAssetConfig.Assets[characterId] then
			warnOnce(characterId, `asset de {characterId} não encontrado em ReplicatedStorage.{CharacterAssetConfig.StorageName}: usando placeholder`)
		end
		return nil
	end
	local problems = Pipeline.validate(template)
	if #problems > 0 then
		templates[characterId] = false
		warnOnce(characterId, `asset de {characterId} INVÁLIDO ({problems[1]}): usando placeholder`)
		return nil
	end
	templates[characterId] = template :: Model
	return template :: Model
end

-- Esquece o cache (DEV: depois de trocar ReplicatedStorage.CharacterAssets)
function CharacterModelFactory.clearCache()
	table.clear(templates)
	table.clear(warned)
end

function CharacterModelFactory.hasAsset(characterId: string): boolean
	return CharacterModelFactory.template(characterId) ~= nil
end

-- Remove/mantém efeitos conforme o modo (None | Light | Full)
local function applyVFXMode(model: Model, mode: string)
	for _, obj in model:GetDescendants() do
		local isVFX = false
		for _, className in VFX_CLASSES do
			if obj:IsA(className) then
				isVFX = true
				break
			end
		end
		if isVFX then
			local tier = obj:GetAttribute("VFXTier")
			if mode == "None" or (mode == "Light" and tier ~= "Light") then
				obj:Destroy()
			end
		end
	end
	model:SetAttribute("VFXMode", mode)
end

local function buildAsset(template: Model, character: CharacterConfig.Character, opts: BuildOptions, mode: string): Model
	local rarity = RarityConfig.ById[character.Rarity]
	local scale = CharacterAssetConfig.RuntimeScale * rarity.ModelScale * CharacterAssetConfig.visualScale(character.Id) * (opts.scale or 1)
	local model = template:Clone()
	-- Correções de roupa centralizadas (ClothingTemplateOverrides) valem já no runtime
	Pipeline.normalizeClothing(model)
	local root = model.PrimaryPart :: BasePart
	-- O template fica no pivô de origem; o clone é escalado em volta do PivotRoot
	local pivot = root.CFrame
	Pipeline.scale(model, scale, pivot)
	local offset = CharacterAssetConfig.visualOffset(character.Id)
	local shift = Vector3.new(offset[1], offset[2], offset[3]) * scale
	for _, part in Pipeline.basePartsOf(model) do
		if part.Name ~= "PivotRoot" and shift.Magnitude > 0 then
			part.CFrame = part.CFrame + pivot:VectorToWorldSpace(shift)
		end
	end
	model.Name = character.Id
	model:SetAttribute("CharacterId", character.Id)
	model:SetAttribute("Rarity", character.Rarity)
	model:SetAttribute("RuntimeScale", scale)
	model:SetAttribute("AssetRig", true)
	VariantVisualModifier.apply(model, opts.variant, mode, scale)
	-- Pose de repouso de cada peça (relativa ao pivô) para as poses próprias
	for _, part in Pipeline.basePartsOf(model) do
		part:SetAttribute("Rest", pivot:ToObjectSpace(part.CFrame))
	end
	applyVFXMode(model, mode)
	local torso = model:FindFirstChild("Torso")
	if mode ~= "None" and opts.aura ~= false and rarity.Aura and torso and torso:IsA("BasePart") then
		rarityAura(model, character, rarity, mode, torso)
	end
	model.WorldPivot = pivot
	return model
end

-- Personagem desconhecido: placeholder neutro (o jogo nunca quebra por um id inválido)
local UNKNOWN: CharacterConfig.Character = {
	Id = "unknown",
	IndexNumber = 0,
	Name = "?",
	Rarity = "Common",
	BasePower = 0,
	BaseIncome = 0,
	ModelName = "unknown",
	Description = "",
	VisualTheme = { Primary = { 120, 120, 130 }, Secondary = { 80, 80, 90 }, Skin = { 220, 220, 225 }, Headgear = "None", Weapon = "None", Wings = false, Icon = "❔" },
}

function CharacterModelFactory.build(characterId: string, options: BuildOptions?): Model
	local opts: BuildOptions = options or {}
	local character = CharacterConfig.ById[characterId]
	if not character then
		warnOnce("unknown:" .. tostring(characterId), `CharacterId desconhecido: {characterId} (placeholder)`)
		character = UNKNOWN
	end
	local rarity = RarityConfig.ById[character.Rarity]
	local scale = BASE_SCALE * rarity.ModelScale * (opts.scale or 1)
	local mode = opts.vfx or (if opts.aura == false then "None" else "Light")

	local template = if character ~= UNKNOWN then CharacterModelFactory.template(character.Id) else nil
	if template then
		local ok, result = pcall(buildAsset, template, character, opts, mode)
		if ok then
			CharacterModelFactory.pose(result, opts.pose or "Idle")
			return result
		end
		warnOnce("build:" .. character.Id, `falha ao montar o asset de {character.Id} ({result}): usando placeholder`)
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
	model:SetAttribute("Variant", opts.variant or "Normal")
	-- Placeholder: o asset final vem do pipeline (ReplicatedStorage.CharacterAssets)
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
	if mode ~= "None" and opts.aura ~= false and rarity.Aura then
		rarityAura(model, character, rarity, mode, rig.parts.Torso)
	end

	root.CFrame = CFrame.new(0, 0.1, 0)
	model.WorldPivot = CFrame.new()
	applyPose(model, resolvePose(opts.pose or "Idle", false))
	-- Pivô no centro dos pés (o Root fica no chão)
	model.WorldPivot = root.CFrame * CFrame.new(0, -0.1, 0)
	return model
end

-- SpawnCharacter: monta e coloca com os pés em targetCFrame (centralizado, em pé, virado
-- para o LookVector do alvo). parent opcional.
function CharacterModelFactory.spawn(characterId: string, target: CFrame, options: BuildOptions?, parent: Instance?): Model
	local model = CharacterModelFactory.build(characterId, options)
	model:PivotTo(target)
	if parent then
		model.Parent = parent
	end
	return model
end

-- Altura aproximada do modelo (para posicionar o BillboardGui acima da cabeça)
function CharacterModelFactory.height(characterId: string): number
	local character = CharacterConfig.ById[characterId]
	local rarity = character and RarityConfig.ById[character.Rarity]
	local modelScale = if rarity then rarity.ModelScale else 1
	local template = character and CharacterModelFactory.template(characterId)
	if template then
		-- Corpo normalizado + cabelo/arma acima da cabeça (limitado a 40% a mais)
		local bounds = template:GetAttribute("BoundsSize")
		local body = CharacterAssetConfig.BodyHeight
		local top = if typeof(bounds) == "Vector3" then math.clamp(bounds.Y, body, body * 1.4) else body
		return (top + 0.3) * CharacterAssetConfig.RuntimeScale * modelScale * CharacterAssetConfig.visualScale(characterId)
	end
	return 5.6 * BASE_SCALE * modelScale
end

return CharacterModelFactory
