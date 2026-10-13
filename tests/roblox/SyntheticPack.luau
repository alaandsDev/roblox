--[[
	Pack SINTÉTICO que imita a estrutura do Anime Pack auditado (ANIME_PACK_AUDIT.md), para
	testar o pipeline de personagens sem o arquivo real (que fica só na máquina do dev).
	Cada rig R6 traz o "lixo" típico do pack: Humanoid + Animator + Animate (LocalScript com
	Animations), scripts do jogo (Health, BattleScript), RemoteEvent/RemoteFunction,
	BindableEvent, sons, valores de estado, BillboardGui, BodyGyro, hitbox invisível e os VFX
	genéricos (MoveT, Break, Bubbles... SenzuEat). Por cima, o que é próprio de cada piloto:
	espada na mão, espada nas costas, cabelo (Accessory), casaco/capa, máscara, VFX próprio.
	Os rigs ficam em posições, ângulos e escalas diferentes (como no pack real).
]]
local roblox = require("@lune/roblox")

local Instance = roblox.Instance
local Vector3 = roblox.Vector3
local CFrame = roblox.CFrame
local Color3 = roblox.Color3
local Enum = roblox.Enum

local SyntheticPack = {}

local GENERIC_EMITTERS = { "Break", "Bubbles", "Slider", "Smoke", "Hit2", "Hit1", "Block", "SoruP", "LevelParticle", "SenzuEat" }

local function new(className, name, parent, props)
	local obj = Instance.new(className)
	obj.Name = name
	for key, value in props or {} do
		obj[key] = value
	end
	obj.Parent = parent
	return obj
end

local function weld(className, parent, part0, part1)
	local joint = new(className, className, parent)
	joint.Part0 = part0
	joint.Part1 = part1
	return joint
end

-- Monta um rig R6 com o "lixo" do pack. opts: at, yaw, scale, scripts, weapon, hair, coat,
-- mask, vfx = { {name, className, part, count} }, stand, loose
function SyntheticPack.rig(parent, name, opts)
	local s = opts.scale or 1
	local origin = CFrame.new(opts.at or Vector3.zero) * CFrame.Angles(0, math.rad(opts.yaw or 0), 0)
	local model = new("Model", name, parent)
	local function part(className, partName, size, localCf, owner, props)
		local p = new(className, partName, owner or model, props)
		p.Size = size * s
		p.CFrame = origin * (CFrame.new(localCf.Position * s) * localCf.Rotation)
		p.Anchored = false
		p.CanCollide = true
		p.Color = Color3.fromRGB(200, 170, 140)
		return p
	end

	local hrp = part("Part", "HumanoidRootPart", Vector3.new(2, 2, 1), CFrame.new(0, 3, 0), nil, { Transparency = 1 })
	local torso = part("Part", "Torso", Vector3.new(2, 2, 1), CFrame.new(0, 3, 0))
	local head = part("Part", "Head", Vector3.new(2, 1, 1), CFrame.new(0, 4.5, 0))
	new("SpecialMesh", "Mesh", head, { MeshType = Enum.MeshType.Head, Scale = Vector3.new(1.25, 1.25, 1.25) })
	new("Decal", "face", head, { Texture = "rbxassetid://7074", Face = Enum.NormalId.Front })
	local la = part("Part", "Left Arm", Vector3.new(1, 2, 1), CFrame.new(-1.5, 3, 0))
	local ra = part("Part", "Right Arm", Vector3.new(1, 2, 1), CFrame.new(1.5, 3, 0))
	local ll = part("Part", "Left Leg", Vector3.new(1, 2, 1), CFrame.new(-0.5, 1, 0))
	local rl = part("Part", "Right Leg", Vector3.new(1, 2, 1), CFrame.new(0.5, 1, 0))
	weld("Motor6D", hrp, hrp, torso).Name = "RootJoint"
	weld("Motor6D", torso, torso, head).Name = "Neck"
	weld("Motor6D", torso, torso, la).Name = "Left Shoulder"
	weld("Motor6D", torso, torso, ra).Name = "Right Shoulder"
	weld("Motor6D", torso, torso, ll).Name = "Left Hip"
	weld("Motor6D", torso, torso, rl).Name = "Right Hip"

	local humanoid = new("Humanoid", "Humanoid", model)
	new("Animator", "Animator", humanoid)
	if opts.legacyClothing then
		-- Como o Killua real: instâncias "Clothing" com a URL antiga (criadas por script no jogo de origem)
		new("Shirt", "Clothing", model, { ShirtTemplate = "http://www.roblox.com/asset/?id=2065247269" })
		new("Pants", "Clothing", model, { PantsTemplate = "http://www.roblox.com/asset/?id=2065252088" })
	else
		new("Shirt", "Shirt", model, { ShirtTemplate = "rbxassetid://1001" })
		new("Pants", "Pants", model, { PantsTemplate = "rbxassetid://1002" })
	end
	if opts.nameTag ~= false then
		-- Placa de título do jogo de origem (todos os pilotos reais têm): Model + Humanoid + Head minúscula
		local tag = new("Model", "[ SEMI-PRO ]", model)
		part("Part", "Head", Vector3.new(0.05, 0.28, 0.05), CFrame.new(0, 6, 0), tag)
		new("Humanoid", "XX", tag)
	end
	new("BodyColors", "Body Colors", model)

	-- Lixo de jogo (todos os pilotos, exceto o "simples")
	if (opts.scripts or 0) > 0 then
		local animate = new("LocalScript", "Animate", model, { Source = "-- animate padrão" })
		for _, animName in { "walk", "idle", "jump" } do
			local value = new("StringValue", animName, animate)
			new("Animation", "Animation1", value, { AnimationId = "rbxassetid://180435571" })
		end
		new("Script", "Health", model, { Source = "while true do task.wait(1) end" })
		if opts.scripts > 1 then
			new("ModuleScript", "BattleScript", model, { Source = "return {}" })
		end
		local remotes = new("Folder", "Remotes", model)
		new("RemoteEvent", "Attack", remotes)
		new("RemoteFunction", "Info", remotes)
		new("BindableEvent", "Hit", model)
		new("Sound", "Punch", hrp, { SoundId = "rbxassetid://12222" })
		new("Sound", "Swing", torso, { SoundId = "rbxassetid://12223" })
		local values = new("Folder", "Values", model)
		new("BoolValue", "Stunned", values)
		new("StringValue", "Move", values)
		new("NumberValue", "Level", model)
		local gui = new("BillboardGui", "Overhead", head)
		new("TextLabel", "NameTag", gui)
		new("BodyGyro", "BodyGyro", hrp)
		local hitbox = part("Part", "Hitbox", Vector3.new(4, 5, 3), CFrame.new(0, 3, 0), nil, { Transparency = 1 })
		weld("Weld", hitbox, hrp, hitbox)
		-- VFX genéricos do jogo de origem
		for _, limb in { la, ra, ll, rl } do
			new("Attachment", "MoveA", limb)
			new("Trail", "MoveT", limb)
		end
		for _, emitterName in GENERIC_EMITTERS do
			new("ParticleEmitter", emitterName, hrp, { Rate = 50 })
		end
	end

	if opts.weapon == "Hand" then
		local sword = new("Model", "Sword", model)
		local handle = part("Part", "Handle", Vector3.new(0.4, 1.2, 0.4), CFrame.new(1.5, 1.9, -0.4), sword)
		local blade = part("MeshPart", "Blade", Vector3.new(0.25, 0.7, 4.2), CFrame.new(1.5, 2.1, -2.8), sword, { MeshId = "rbxassetid://5001", TextureID = "" })
		blade.Color = Color3.fromRGB(220, 225, 235)
		weld("Weld", handle, ra, handle)
		weld("WeldConstraint", blade, handle, blade)
		new("Trail", "Trail", blade)
	elseif opts.weapon == "Back" then
		local sword = part("MeshPart", "BackSword", Vector3.new(0.4, 7.5, 2.6), CFrame.new(0, 3.6, 0.85) * CFrame.Angles(0, 0, math.rad(35)), nil, { MeshId = "rbxassetid://5002" })
		weld("ManualWeld", sword, torso, sword)
	end
	if opts.hair then
		local accessory = new("Accessory", "GokuHair", model)
		local handle = part("MeshPart", "Handle", Vector3.new(2.6, 1.8, 2.4), CFrame.new(0, 5.4, 0.1), accessory, { MeshId = "rbxassetid://6001", TextureID = "rbxassetid://6002" })
		new("Attachment", "HairAttachment", handle)
		new("Attachment", "HairAttachment", head)
		if opts.hair == "Welded" then
			weld("Weld", handle, handle, head).Name = "AccessoryWeld"
		end
	end
	if opts.coat then
		local coat = part("MeshPart", "Coat", Vector3.new(2.5, 3.4, 1.5), CFrame.new(0, 2.6, 0.1), nil, { MeshId = "rbxassetid://7001", TextureID = "rbxassetid://7002" })
		weld("WeldConstraint", coat, torso, coat)
		local cape = part("Part", "Cape", Vector3.new(2.2, 3.6, 0.2), CFrame.new(0, 2.8, 0.7))
		cape.Color = Color3.fromRGB(240, 240, 245)
		new("Texture", "CapeTexture", cape, { Texture = "rbxassetid://7003", StudsPerTileU = 2, StudsPerTileV = 2 })
		weld("Weld", cape, torso, cape)
		local mustache = part("MeshPart", "Mustache", Vector3.new(1.8, 0.4, 0.4), CFrame.new(0, 4.4, -0.55), nil, { MeshId = "rbxassetid://7004" })
		weld("ManualWeld", mustache, head, mustache)
	end
	if opts.mask then
		local mask = part("MeshPart", "Mask", Vector3.new(1.3, 1.1, 0.4), CFrame.new(0, 4.5, -0.6), nil, { MeshId = "rbxassetid://8001", TextureID = "rbxassetid://8002" })
		weld("Weld", mask, head, mask)
	end
	for _, spec in opts.vfx or {} do
		local holder = ({ Torso = torso, ["Right Arm"] = ra, ["Left Arm"] = la, Head = head })[spec[3]] or torso
		for _ = 1, spec[4] or 1 do
			local effect = new(spec[2], spec[1], holder)
			if spec[2] == "ParticleEmitter" then
				effect.Rate = 40
			end
		end
	end
	if opts.stand then
		local stand = new("Model", "LocalStand", model)
		part("Part", "StandTorso", Vector3.new(2, 2, 1), CFrame.new(2, 4, 2), stand)
		new("Script", "StandAI", stand, { Source = "-- stand" })
	end
	if opts.loose then
		local belt = part("Part", "Belt", Vector3.new(2.1, 0.3, 1.1), CFrame.new(0, 2.2, 0))
		belt.Color = Color3.fromRGB(40, 40, 50)
	end
	return model
end

-- Os 10 pilotos, nos mesmos caminhos do pack real (CharacterAssetConfig.Assets.SourcePath)
SyntheticPack.Rigs = {
	{ path = { "AOT" }, name = "Sasha", opts = { at = Vector3.new(10, 0, 4), yaw = 0, scale = 0.95, scripts = 0 } },
	{ path = { "Bleach Pack" }, name = "Ichigo", opts = { at = Vector3.new(-40, 2, 18), yaw = 90, scripts = 1, weapon = "Hand" } },
	{ path = { "Bleach Pack", "Hollow Ichigo" }, name = "Hollow Ichigo", opts = { at = Vector3.new(-50, 2, 18), yaw = 180, scripts = 2, weapon = "Hand", mask = true } },
	{ path = { "DBZ" }, name = "Goku", opts = { at = Vector3.new(30, 0, -12), yaw = -45, scripts = 1, hair = "Welded" } },
	{ path = { "One Piece Pack" }, name = "Whitebeard", opts = { at = Vector3.new(60, 5, 60), yaw = 30, scale = 1.4, scripts = 1, coat = true, vfx = { { "FX", "ParticleEmitter", "Torso", 1 } } } },
	{ path = { "HXH" }, name = "Killua", opts = { at = Vector3.new(0, 0, 80), yaw = 0, scale = 0.9, scripts = 1, hair = "Attachment", legacyClothing = true } },
	{ path = { "HXH" }, name = "Killua Godspeed", opts = { at = Vector3.new(8, 0, 80), yaw = 0, scale = 0.9, scripts = 2, legacyClothing = true, vfx = { { "Lightning", "ParticleEmitter", "Torso", 4 }, { "Reiatsu", "ParticleEmitter", "Torso", 4 }, { "Lightning", "ParticleEmitter", "Right Arm", 4 }, { "Reiatsu", "ParticleEmitter", "Left Arm", 4 } } } },
	{ path = { "NARUTO" }, name = "Zabuza", opts = { at = Vector3.new(-80, 0, -80), yaw = 270, scripts = 1, weapon = "Back", stand = true } },
	{ path = { "Bleach Pack" }, name = "Yamamoto", opts = { at = Vector3.new(-30, 0, 18), yaw = 0, scale = 1.1, scripts = 1, weapon = "Hand", vfx = { { "Fire", "ParticleEmitter", "Right Arm", 2 }, { "Trail", "Trail", "Right Arm", 1 }, { "Beam", "Beam", "Torso", 1 }, { "PointLight", "PointLight", "Torso", 1 } } } },
	{ path = { "JJK" }, name = "Gojo Satoru", opts = { at = Vector3.new(100, 0, -30), yaw = 137, scale = 1.1, scripts = 1, loose = true } },
}

-- Monta o "Workspace.Anime Pack" sintético
function SyntheticPack.build()
	local pack = new("Folder", "Anime Pack", nil)
	for _, entry in SyntheticPack.Rigs do
		local parent = pack
		for _, name in entry.path do
			parent = parent:FindFirstChild(name) or new(if parent == pack then "Folder" else "Model", name, parent)
		end
		SyntheticPack.rig(parent, entry.name, entry.opts)
	end
	-- Um personagem fora do piloto (nunca deve ser processado)
	SyntheticPack.rig(pack:FindFirstChild("DBZ"), "Speed Guy", { scripts = 2 })
	return pack
end

-- Pack com TODOS os personagens de lançamento: os 10 rigs detalhados + um rig genérico (com o
-- mesmo "lixo" do pack) em cada SourcePath que falta. specs = CharacterAssetConfig.Assets.
-- skip = SourcePaths que NÃO devem existir (para testar MISSING_SOURCE).
function SyntheticPack.buildLaunch(specs, skip)
	local pack = SyntheticPack.build()
	local paths = {}
	for _, spec in specs do
		table.insert(paths, spec.SourcePath)
	end
	table.sort(paths)
	for i, path in paths do
		if skip and skip[path] then
			continue
		end
		local names = string.split(path, ".")
		local parent = pack
		for j = 1, #names - 1 do
			parent = parent:FindFirstChild(names[j]) or new(if parent == pack then "Folder" else "Model", names[j], parent)
		end
		-- "Nome (Nª ocorrência)": como no pack real, N irmãos com o MESMO nome (o alvo é o N-ésimo)
		local leaf = names[#names]
		local base, nth = string.match(leaf, "^(.-) %((%d+)ª ocorrência%)$")
		if base then
			for k = 1, tonumber(nth) - 1 do
				local decoy = SyntheticPack.rig(parent, base, { at = Vector3.new(-20 - k * 9, 0, i * 9), yaw = 0, scale = 0.7, scripts = 1 })
				decoy:SetAttribute("SyntheticOccurrence", k)
			end
			local target = SyntheticPack.rig(parent, base, {
				at = Vector3.new((i % 12) * 9, 0, math.floor(i / 12) * 9),
				yaw = 0,
				scale = 1,
				scripts = 1,
				vfx = { { "Aura", "ParticleEmitter", "Torso", 1 } },
			})
			target:SetAttribute("SyntheticOccurrence", tonumber(nth))
		elseif not parent:FindFirstChild(leaf) then
			SyntheticPack.rig(parent, leaf, {
				at = Vector3.new((i % 12) * 9, 0, math.floor(i / 12) * 9),
				yaw = (i * 37) % 360,
				scale = 0.9 + (i % 5) * 0.08,
				scripts = 1 + (i % 2),
				weapon = if i % 4 == 0 then "Hand" elseif i % 7 == 0 then "Back" else nil,
				hair = if i % 3 == 0 then "Welded" else nil,
				vfx = { { "Aura", "ParticleEmitter", "Torso", 1 } },
			})
		end
	end
	return pack
end

return SyntheticPack
