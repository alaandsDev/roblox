--[[
	Confere o assets/Characters.rbxm REAL (gerado na máquina do dev a partir do Anime Pack),
	quando ele existe: 10 pilotos, validate do runtime, factory (asset e não placeholder),
	pés no chão, 7 variantes e a interface DEV ServerStorage.RollLegendsDev:Invoke(...).
	Sem o arquivo, o teste é pulado (o jogo usa o placeholder).
]]
local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local Env = require("./Env")
local CFrame = roblox.CFrame

local FILE = "assets/Characters.rbxm"
if not fs.isFile(FILE) then
	print("\n[Assets reais dos pilotos] pulado: assets/Characters.rbxm não existe")
	return
end

local T = Env.checker("Assets reais dos pilotos (assets/Characters.rbxm)")
local check = T.check
local env = Env.create()
local folder = roblox.deserializeModel(fs.readFile(FILE))[1]
folder.Parent = env.real.ReplicatedStorage
local req = env.newContext()
local Config = req(env.shared.Config.CharacterAssetConfig)
local CharacterConfig = req(env.shared.Config.CharacterConfig)
local Pipeline = req(env.shared.Modules.CharacterAssetPipeline)
local Factory = req(env.shared.Modules.CharacterModelFactory)
local VariantConfig = req(env.shared.Config.VariantConfig)

check(folder.Name == Config.StorageName, "raiz do arquivo = " .. Config.StorageName)
local names = {}
for _, child in folder:GetChildren() do
	table.insert(names, child.Name)
end
table.sort(names)
local expected = {}
for id in Config.Assets do
	table.insert(expected, id)
end
table.sort(expected)
check(table.concat(names, ",") == table.concat(expected, ","), "exatamente os 10 pilotos: " .. table.concat(names, ", "))

for _, character in CharacterConfig.Pilots do
	local template = folder:FindFirstChild(character.Id)
	local problems, warnings = Pipeline.validate(template)
	check(#problems == 0, `{character.Id}: validate OK ({#warnings} aviso(s)) {table.concat(problems, "; ")}`)
	local bad = 0
	for _, obj in template:GetDescendants() do
		if obj:IsA("LuaSourceContainer") or obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") or obj:IsA("BindableEvent") or obj:IsA("BindableFunction") or obj:IsA("Sound") or obj:IsA("Animation") or obj:IsA("Animator") then
			bad += 1
		end
	end
	check(bad == 0, `{character.Id}: nenhum script/remote/bindable/som/animação`)
	local model = Factory.spawn(character.Id, CFrame.new(0, 5, 0), { vfx = "Light" })
	local legMin = Pipeline.boundsOf({ model:FindFirstChild("Left Leg"), model:FindFirstChild("Right Leg") }, CFrame.new(0, 5, 0))
	check(model:GetAttribute("AssetRig") == true and math.abs(legMin.Y) < 0.05, string.format("%s: factory usa o asset real, pés no alvo (%.3f)", character.Id, legMin.Y))
	model:Destroy()
end
for _, variant in VariantConfig.List do
	local model = Factory.build("char_ichiro_base", { variant = variant.Id, vfx = "Full" })
	-- No pack real o rosto fica num "FakeHead" preso à cabeça (osso Head), não na peça Head
	local face = model:FindFirstChild("FakeHead")
	check(model:GetAttribute("AssetRig") == true and model:GetAttribute("Variant") == variant.Id and face ~= nil and face:FindFirstChildOfClass("Decal") ~= nil and face:GetAttribute("Bone") == "Head" and model:FindFirstChildOfClass("Shirt") ~= nil, "Ichiro real na variante " .. variant.Id .. " (rosto e roupa preservados)")
	model:Destroy()
end

local failures = T.finish()
if failures > 0 then
	process.exit(1)
end
