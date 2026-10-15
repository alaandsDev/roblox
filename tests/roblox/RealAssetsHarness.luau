--[[
	Confere o assets/Characters.rbxm REAL (gerado na máquina do dev a partir do Anime Pack),
	quando ele existe: só ids do catálogo de lançamento (no mínimo os 10 pilotos), validate do runtime, factory (asset e não placeholder),
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
local unknown, pilotsIn = {}, 0
for _, name in names do
	if not Config.Assets[name] then
		table.insert(unknown, name)
	end
end
for _, pilot in CharacterConfig.Pilots do
	pilotsIn += if folder:FindFirstChild(pilot.Id) then 1 else 0
end
check(#unknown == 0 and pilotsIn == #CharacterConfig.Pilots, `{#names}/{#CharacterConfig.Launch} do lançamento, todos com id do catálogo e os {#CharacterConfig.Pilots} pilotos presentes {table.concat(unknown, ", ")}`)
if #names < #CharacterConfig.Launch then
	print(`  (assets/Characters.rbxm ainda tem {#names} de {#CharacterConfig.Launch}: rode python tools/build_characters.py para gerar o lote completo)`)
end

for _, name in names do
	local character = CharacterConfig.ById[name]
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

-- Killuo real: a roupa EXISTE no asset (mesmos ids do pack); o factory normaliza a URL antiga
for _, id in { "char_killuo_base", "char_killuo_godspeed" } do
	local model = Factory.build(id, { vfx = "None" })
	local shirt, pants = model:FindFirstChildOfClass("Shirt"), model:FindFirstChildOfClass("Pants")
	check(shirt ~= nil and pants ~= nil and string.find(shirt.ShirtTemplate, "2065247269", 1, true) ~= nil and string.find(pants.PantsTemplate, "2065252088", 1, true) ~= nil, id .. ": Shirt/Pants presentes no asset real (" .. tostring(shirt and shirt.ShirtTemplate) .. ")")
	model:Destroy()
end

do
	-- REGRESSÃO (Barbalva / Ulkiorra Liberado sumindo da Base): personagens LARGOS (espada,
	-- bisento, capa) montam como o asset real COM aura, em Light e Full; e uma falha da aura
	-- nunca troca o personagem pelo placeholder (o modelo fica, sem aura)
	local AuraBuilder = req(env.shared.Modules.AuraBuilder)
	local wide = 0
	for _, character in CharacterConfig.List do
		local rarity = character.Rarity
		if Factory.hasAsset(character.Id) and (rarity == "Legendary" or rarity == "Mythic" or rarity == "Divine" or rarity == "Secret") then
			for _, mode in { "Light", "Full" } do
				local model = Factory.build(character.Id, { vfx = mode })
				local _, size = model:GetBoundingBox()
				if math.max(size.X, size.Z) > 12.8 then
					wide += 1
				end
				check(model:GetAttribute("AssetRig") == true and model:GetAttribute("TODO_ASSET") == nil and model:GetAttribute("Aura") ~= nil, `{character.Id} ({mode}): asset real + aura (largura {string.format("%.1f", math.max(size.X, size.Z))} studs)`)
				model:Destroy()
			end
		end
	end
	check(wide >= 2, `existem personagens largos (> 12,8 studs) no pacote para a regressão valer ({wide})`)
	local original = AuraBuilder.attach
	AuraBuilder.attach = function()
		error("falha simulada da aura")
	end
	local model = Factory.build("char_barbalva_base", { vfx = "Light" })
	AuraBuilder.attach = original
	local visible, auraLeft = 0, 0
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d.Transparency < 1 then
			visible += 1
		end
		if string.sub(d.Name, 1, 4) == "Aura" then
			auraLeft += 1
		end
	end
	check(model:GetAttribute("AssetRig") == true and visible > 5 and auraLeft == 0, `aura falhando: o personagem continua o asset real ({visible} partes visíveis), só sem aura`)
end

local failures = T.finish()
if failures > 0 then
	process.exit(1)
end
