--[[
	Leitura ESTÁTICA do Auras Pack via Lune (chamado por tools/audit_auras_pack.py).
	    lune run tools/packaudit/auras_dump.luau <arquivo.rbxm> <saida.json>
	Só DESERIALIZA o arquivo e lê propriedades: nenhum script do pack é executado ou requerido
	(o código vira texto e só sai daqui para o Python calcular tamanho/hash — nunca vai para o
	relatório). A análise (grupos, riscos, relatório) é feita em tools/packaudit/auras_report.py.
	Código de saída: 0 ok; 1 arquivo ausente; o erro de leitura do Lune é propagado (o Python
	identifica "Type mismatch: Property X.Y" e decide o fallback).
]]
local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")

local file = process.args[1]
local out = process.args[2]
if not file or not fs.isFile(file) then
	print("arquivo não encontrado: " .. tostring(file))
	process.exit(1)
end
local bytes = fs.readFile(file)
local ok, roots = pcall(roblox.deserializeModel, bytes)
if not ok then
	local okPlace, place = pcall(roblox.deserializePlace, bytes)
	if not okPlace then
		error(roots) -- mensagem original do Lune (o Python lê "Type mismatch: Property X.Y")
	end
	roots = place:GetService("Workspace"):GetChildren()
end

-- Propriedades lidas por classe (o resto não importa para a auditoria)
local COMMON = { "Enabled", "Disabled" }
local PROPS: { [string]: { string } } = {
	ParticleEmitter = { "Texture", "Rate", "Lifetime", "Size", "Transparency", "Speed", "SpreadAngle", "LightEmission", "LightInfluence", "Color", "Drag", "LockedToPart", "EmissionDirection", "Shape", "ZOffset", "Rotation", "RotSpeed", "Acceleration", "VelocityInheritance", "Squash", "FlipbookLayout" },
	Beam = { "Texture", "Width0", "Width1", "LightEmission", "Segments", "CurveSize0", "CurveSize1", "TextureSpeed", "TextureLength", "Color", "Transparency", "FaceCamera", "Attachment0", "Attachment1" },
	Trail = { "Texture", "Lifetime", "LightEmission", "MinLength", "MaxLength", "WidthScale", "Color", "Transparency", "FaceCamera", "Attachment0", "Attachment1" },
	Attachment = { "Position", "Orientation" },
	PointLight = { "Brightness", "Range", "Color", "Shadows" },
	SpotLight = { "Brightness", "Range", "Color", "Angle", "Shadows" },
	SurfaceLight = { "Brightness", "Range", "Color", "Angle", "Shadows" },
	Sound = { "SoundId", "AudioContent", "Volume", "Looped", "Playing", "PlayOnRemove" },
	Animation = { "AnimationId", "AnimationContent" },
	MeshPart = { "MeshId", "MeshContent", "TextureID", "TextureContent", "Size", "Transparency", "Material" },
	SpecialMesh = { "MeshId", "TextureId", "MeshType", "Scale" },
	Decal = { "Texture", "TextureContent", "Transparency", "Face" },
	Texture = { "Texture", "TextureContent", "Transparency", "Face" },
	Part = { "Size", "Transparency", "Material", "Anchored", "CanCollide" },
	Fire = { "Size", "Heat", "Color" },
	Smoke = { "Size", "Opacity", "RiseVelocity", "Color" },
	Sparkles = { "SparkleColor" },
	Highlight = { "FillColor", "OutlineColor", "FillTransparency" },
	Script = { "RunContext" },
	LocalScript = {},
	ModuleScript = {},
	Weld = { "Part0", "Part1" },
	WeldConstraint = { "Part0", "Part1" },
	Motor6D = { "Part0", "Part1" },
	ImageLabel = { "Image" },
	ImageButton = { "Image" },
	Shirt = { "ShirtTemplate" },
	Pants = { "PantsTemplate" },
	ShirtGraphic = { "Graphic" },
}

local function path(inst: any): string
	local parts = {}
	local node = inst
	while node do
		table.insert(parts, 1, node.Name)
		node = node.Parent
	end
	return table.concat(parts, "/")
end

local function avgSeq(seq: any): number?
	local okK, kps = pcall(function()
		return seq.Keypoints
	end)
	if not okK or type(kps) ~= "table" or #kps == 0 then
		return nil
	end
	local total = 0
	for _, kp in kps do
		local v = kp.Value
		if typeof(v) == "Color3" then
			return nil
		end
		total += v
	end
	return total / #kps
end

local function convert(v: any): any
	local t = typeof(v)
	if t == "number" or t == "boolean" or t == "string" then
		return v
	elseif t == "EnumItem" then
		return v.Name
	elseif t == "Color3" then
		return { math.floor(v.R * 255 + 0.5), math.floor(v.G * 255 + 0.5), math.floor(v.B * 255 + 0.5) }
	elseif t == "Vector3" then
		return { v.X, v.Y, v.Z }
	elseif t == "NumberRange" then
		return { v.Min, v.Max }
	elseif t == "NumberSequence" then
		return avgSeq(v)
	elseif t == "ColorSequence" then
		local okK, kps = pcall(function()
			return v.Keypoints
		end)
		if okK and kps and kps[1] then
			local c = kps[1].Value
			return { math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5) }
		end
		return nil
	elseif t == "Instance" then
		return path(v)
	elseif t == "Content" then
		local okU, uri = pcall(function()
			return v.Uri
		end)
		return if okU then uri else tostring(v)
	end
	return nil
end

local EXEC = { Script = true, LocalScript = true, ModuleScript = true }
local list = {}
local function visit(inst: any, parentIndex: number?)
	local cls = inst.ClassName
	local record: { [string]: any } = { class = cls, name = inst.Name, path = path(inst), parent = parentIndex, props = {} }
	local names = table.clone(COMMON)
	for _, p in PROPS[cls] or {} do
		table.insert(names, p)
	end
	for _, p in names do
		local okR, value = pcall(function()
			return inst[p]
		end)
		if okR and value ~= nil then
			local c = convert(value)
			if c ~= nil then
				record.props[p] = c
			end
		end
	end
	if EXEC[cls] then
		-- código como DADO (texto); o Python calcula tamanho/hash e descarta
		local okS, source = pcall(function()
			return inst.Source
		end)
		record.source = if okS and type(source) == "string" then source else ""
	end
	table.insert(list, record)
	local index = #list
	for _, child in inst:GetChildren() do
		visit(child, index)
	end
end
for _, root in roots do
	visit(root, nil)
end
fs.writeFile(out, serde.encode("json", { reader = "lune", instances = list }, false))
print(`auras_dump: {#list} instâncias lidas`)
