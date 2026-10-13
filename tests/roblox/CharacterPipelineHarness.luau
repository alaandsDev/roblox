--[[
	Pipeline de personagens de ponta a ponta com um pack SINTÉTICO (tests/roblox/SyntheticPack):
	  SOURCE PACK PRESENT -> CharacterAssetPipeline gera os assets (sanitiza + valida)
	  -> salva em .rbxm (mesmo formato de assets/Characters.rbxm) -> o pack é DESTRUÍDO
	  -> FINAL GAME: ReplicatedStorage.CharacterAssets lido do arquivo -> CharacterModelFactory
	     (asset, fallback, variantes, VFX, poses, pivô, spawn, limpeza).
	Nenhum script do pack é executado: o Lune só lê/clona instâncias.
]]
local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local Env = require("./Env")
local SyntheticPack = require("./SyntheticPack")

local Vector3 = roblox.Vector3
local CFrame = Env.FixedCFrame
local T = Env.checker("Pipeline de personagens: sanitização (pack sintético)")
local check = T.check

local env = Env.create()
local requireModule = env.newContext()
local Config = requireModule(env.shared.Config.CharacterAssetConfig)
local CharacterConfig = requireModule(env.shared.Config.CharacterConfig)
local Pipeline = requireModule(env.shared.Modules.CharacterAssetPipeline)

local FORBIDDEN = { "LuaSourceContainer", "RemoteEvent", "RemoteFunction", "BindableEvent", "BindableFunction", "Sound", "Animation", "Animator", "ValueBase", "BillboardGui", "BodyMover", "JointInstance", "WeldConstraint", "Accessory" }

local function countIn(root, className)
	local n = 0
	for _, obj in root:GetDescendants() do
		if obj:IsA(className) then
			n += 1
		end
	end
	return n
end

local function forbiddenIn(root)
	local found = {}
	for _, obj in root:GetDescendants() do
		for _, className in FORBIDDEN do
			if obj:IsA(className) then
				table.insert(found, obj.ClassName .. " " .. obj.Name)
			end
		end
		if obj.Name == "LocalStand" or obj.Name == "BattleScript" or obj.Name == "Animate" then
			table.insert(found, "nome " .. obj.Name)
		end
	end
	return found
end

------------------------------------------------------------------------------------
-- 1) SOURCE PACK PRESENT: gera os assets
local pack = SyntheticPack.buildLaunch(Config.Assets)
pack.Parent = env.real.Workspace
-- Cópia em arquivo para o teste da ferramenta (tests/build_characters_test.py)
fs.writeDir("build")
fs.writeFile("build/test_AnimePack.rbxm", roblox.serializeModel({ pack }))
do -- variante com 2 modelos AUSENTES (teste de MISSING_SOURCE da ferramenta)
	local skip = { [Config.Assets.char_mikaza_formal.SourcePath] = true, [Config.Assets.char_iskander_base.SourcePath] = true }
	local partial = SyntheticPack.buildLaunch(Config.Assets, skip)
	fs.writeFile("build/test_AnimePack_missing.rbxm", roblox.serializeModel({ partial }))
	partial:Destroy()
end
local scriptsBefore = countIn(pack, "LuaSourceContainer")
local folder, reports = Pipeline.buildAll(pack)
do -- irmãos com o mesmo nome: "HXH.Hisoka (2ª ocorrência)" = o 2º "Hisoka" (não o 1º nem um nome literal)
	local twin = Pipeline.findSource(pack, Config.Assets.char_hizoka_base.SourcePath)
	check(twin ~= nil and twin.Name == "Hisoka" and twin:GetAttribute("SyntheticOccurrence") == 2, "fonte com nome repetido no pack: resolve a 2ª ocorrência")
	check(Pipeline.findSource(pack, "HXH.Hisoka (3ª ocorrência)") == nil, "ocorrência inexistente -> MISSING_SOURCE (nada de palpite)")
end
local byId = {}
for _, report in reports do
	byId[report.CharacterId] = report
end

local assetCount = 0
for _ in Config.Assets do
	assetCount += 1
end
check(assetCount == 121 and #CharacterConfig.Launch == 121, `catálogo de lançamento com 121 personagens ({assetCount} specs, {#CharacterConfig.Launch} metadados)`)
check(#reports == assetCount, "um relatório por personagem de lançamento (Speed Guy e o resto do pack ignorados)")
check(folder.Name == Config.StorageName, "pasta de saída = " .. Config.StorageName)
check(countIn(pack, "LuaSourceContainer") == scriptsBefore, "pack de origem intacto (sanitização só mexe em clones)")

-- Lote inteiro: checagens agregadas (lista quem falhou)
local failures = { gerado = {}, proibido = {}, validate = {}, pivo = {}, corpo = {}, frente = {}, fisica = {}, pecas = {}, ids = {}, humanoid = {}, roupa = {}, hrp = {} }
for _, report in reports do
	local id = report.CharacterId
	local model = folder:FindFirstChild(id)
	if not model or report.status == "FAIL" then
		table.insert(failures.gerado, id .. " " .. table.concat(report.problems, "; "))
		continue
	end
	if #forbiddenIn(model) > 0 then
		table.insert(failures.proibido, id)
	end
	if #Pipeline.validate(model) > 0 then
		table.insert(failures.validate, id)
	end
	if not (model.PrimaryPart ~= nil and model.PrimaryPart.Name == "PivotRoot" and model.PrimaryPart.CFrame.Position.Magnitude < 1e-4) then
		table.insert(failures.pivo, id)
	end
	local legMin = Pipeline.boundsOf({ model:FindFirstChild("Left Leg"), model:FindFirstChild("Right Leg") }, CFrame.new())
	local _, headMax = Pipeline.boundsOf({ model:FindFirstChild("Head") }, CFrame.new())
	if not (math.abs(legMin.Y) < 0.01 and math.abs(headMax.Y - Config.BodyHeight) < 0.02) then
		table.insert(failures.corpo, id)
	end
	local torso = model:FindFirstChild("Torso")
	if not (torso.CFrame.LookVector:Dot(Vector3.new(0, 0, -1)) > 0.999 and math.abs(torso.CFrame.Position.X) < 0.01) then
		table.insert(failures.frente, id)
	end
	for _, part in Pipeline.basePartsOf(model) do
		if not part.Anchored or part.CanCollide or part.CanTouch or part.CanQuery then
			table.insert(failures.fisica, id)
			break
		end
	end
	if not (report.originalParts > 0 and model:GetAttribute("PartCount") == report.sanitizedParts and report.finalCounts.Instances ~= nil) then
		table.insert(failures.pecas, id)
	end
	if not (model:GetAttribute("SourceModelName") == Config.Assets[id].SourceModelName and model:GetAttribute("CharacterId") == id) then
		table.insert(failures.ids, id)
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid or #humanoid:GetChildren() > 0 then
		table.insert(failures.humanoid, id)
	end
	if not (model:FindFirstChildOfClass("Shirt") and model:FindFirstChildOfClass("Pants") and model.Head:FindFirstChild("face")) then
		table.insert(failures.roupa, id)
	end
	if model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Hitbox", true) then
		table.insert(failures.hrp, id)
	end
end
local function none(list, message)
	check(#list == 0, `{message} ({assetCount - #list}/{assetCount}){if #list > 0 then ": " .. table.concat(list, ", ") else ""}`)
end
none(failures.gerado, "lote: asset gerado sem FALHA")
none(failures.proibido, "lote: nenhum Script/Remote/Bindable/Sound/Animation/Value/GUI/junta/LocalStand")
none(failures.validate, "lote: validate sem problemas")
none(failures.pivo, "lote: PivotRoot na origem")
none(failures.corpo, "lote: pés em y=0 e corpo = 5")
none(failures.frente, "lote: centralizado e olhando para -Z")
none(failures.fisica, "lote: tudo ancorado, sem colisão/toque/consulta")
none(failures.pecas, "lote: peças e orçamento registrados")
none(failures.ids, "lote: CharacterId e SourceModelName gravados no asset")
none(failures.humanoid, "lote: Humanoid inerte (só por causa das roupas)")
none(failures.roupa, "lote: roupas e rosto preservados")
none(failures.hrp, "lote: HumanoidRootPart e hitbox removidas")
local statusAttr = 0
for _, model in folder:GetChildren() do
	if model:GetAttribute("ClothingStatus") and model:GetAttribute("OptimizationStatus") and model:GetAttribute("VFXStatus") then
		statusAttr += 1
	end
end
check(statusAttr == assetCount, "lote: status de roupa/otimização/VFX gravados no asset (filtros da galeria)")
local vfxReview, excluded = 0, 0
for _, r in reports do
	if r.vfxStatus == "REVIEW" then
		vfxReview += 1
	end
	if #r.vfxExcluded > 0 then
		excluded += 1
	end
end
check(vfxReview >= excluded and excluded > 0, `VFX de golpe/rastro fora da whitelist marcados VFX REVIEW ({vfxReview})`)

-- Casos específicos
local function bone(id, partName)
	local part = folder:FindFirstChild(id):FindFirstChild(partName, true)
	return part and part:GetAttribute("Bone")
end
check(bone("char_ichiro_base", "Blade") == "RightArm" and bone("char_ichiro_base", "Handle") == "RightArm", "Ichiro: espada (Weld + WeldConstraint) acompanha o braço direito")
check(bone("char_ichiro_hollow", "Mask") == "Head", "Ichiro Mascarado: máscara acompanha a cabeça")
check(bone("char_goko_base", "Handle") == "Head" and folder.char_goko_base:FindFirstChild("GokuHair") ~= nil and folder.char_goko_base.GokuHair:IsA("Model"), "Goko: cabelo (Accessory -> Model) preso na cabeça")
check(bone("char_killuo_base", "Handle") == "Head", "Killuo: acessório só com Attachment (sem solda) achado pela HairAttachment")
check(bone("char_zabuzo_base", "BackSword") == "Torso" and folder.char_zabuzo_base:FindFirstChild("LocalStand", true) == nil, "Zabuzo: espada das costas no tronco; LocalStand removido")
check(bone("char_barbalva_base", "Coat") == "Torso" and bone("char_barbalva_base", "Mustache") == "Head" and bone("char_barbalva_base", "Cape") == "Torso", "Barbalva: casaco/capa no tronco, bigode na cabeça")
check(folder.char_barbalva_base:FindFirstChild("Cape"):FindFirstChildOfClass("Texture") ~= nil, "Barbalva: textura da capa preservada")
check(math.abs(byId.char_barbalva_base.scaleFactor - 1 / 1.4) < 0.01 and math.abs(byId.char_sacha_base.scaleFactor - 1 / 0.95) < 0.01, "normalização: rig grande (x1,4) e pequeno (x0,95) chegam ao mesmo corpo")
check(#byId.char_goju_base.unattachedParts == 1 and byId.char_goju_base.status == "WARN", "Goju: peça sem junta presa pelo osso mais próximo e marcada como AVISO")

local function vfxOf(id)
	local list = {}
	for _, obj in folder:FindFirstChild(id):GetDescendants() do
		if table.find(Config.VFXClasses, obj.ClassName) then
			table.insert(list, obj)
		end
	end
	return list
end
for _, id in { "char_sacha_base", "char_ichiro_base", "char_goko_base", "char_barbalva_base", "char_zabuzo_base", "char_goju_base" } do
	check(#vfxOf(id) == 0, `{id}: nenhum VFX (genéricos e não autorizados removidos)`)
end
local godspeed = vfxOf("char_killuo_godspeed")
local lightTier, highRate = 0, 0
for _, effect in godspeed do
	if effect:GetAttribute("VFXTier") == "Light" then
		lightTier += 1
	end
	if effect:IsA("ParticleEmitter") and effect.Rate > Config.VFXLimits.MaxRate then
		highRate += 1
	end
end
check(#godspeed == Config.VFXLimits.MaxFull and lightTier == Config.VFXLimits.MaxLight and highRate == 0, `Killuo Relâmpago: raios próprios limitados ({#godspeed} Full, {lightTier} Light, taxa <= {Config.VFXLimits.MaxRate})`)
local fire, lights, others = 0, 0, 0
for _, effect in vfxOf("char_yamamotu_base") do
	if effect.Name == "Fire" then
		fire += 1
	elseif effect:IsA("PointLight") then
		lights += 1
	else
		others += 1
	end
end
check(fire == 2 and lights == 1 and others == 0, "Yamamotu: fogo (2) + 1 luz; Trail/Beam fora da whitelist removidos")
check(byId.char_killuo_godspeed.vfxRemoved > 0 and byId.char_ichiro_hollow.scriptsRemoved == 3 and byId.char_ichiro_hollow.remotesRemoved == 2 and byId.char_ichiro_hollow.soundsRemoved == 2 and byId.char_ichiro_hollow.animationsRemoved >= 4, "relatório conta scripts/remotes/sons/animações removidos")

-- Roupa e estrutura visual (bug do Killuo: roupa "Clothing" com URL antiga + placa de título)
local lostAny, nestedAny = {}, {}
for _, report in reports do
	if #report.visualLost > 0 or (report.visualSource.Shirt or 0) ~= (report.visualSanitized.Shirt or 0) or (report.visualSource.Pants or 0) ~= (report.visualSanitized.Pants or 0) then
		table.insert(lostAny, report.CharacterId)
	end
	local model = folder:FindFirstChild(report.CharacterId)
	local nested = 0
	for _, obj in (if model then model:GetDescendants() else {}) do
		if obj:IsA("Humanoid") and obj.Parent.Name ~= report.CharacterId then
			nested += 1
		end
	end
	if nested > 0 or report.nameTagsRemoved ~= 1 or (model and model:FindFirstChild("[ SEMI-PRO ]")) then
		table.insert(nestedAny, report.CharacterId)
	end
end
none(lostAny, "lote: nenhuma classe visual perdida (Shirt/Pants/Decal/Texture/MeshPart/SpecialMesh...)")
none(nestedAny, "lote: placa de título com Humanoid aninhado removida")
local killuoModel = folder:FindFirstChild("char_killuo_base")
local shirt, pants = killuoModel:FindFirstChildOfClass("Shirt"), killuoModel:FindFirstChildOfClass("Pants")
check(shirt ~= nil and pants ~= nil and shirt.ShirtTemplate == "rbxassetid://2065247269" and pants.PantsTemplate == "rbxassetid://2065252088", "Killuo: Shirt/Pants preservados e URL antiga normalizada (mesmo asset)")
local killuoUses = byId.char_killuo_base.clothing
check(#killuoUses == 2 and killuoUses[1].assetId ~= nil and string.find(killuoUses[1].original, "roblox.com/asset", 1, true) ~= nil, "relatório lista a roupa (AssetId, template original -> final)")
-- Roupa com asset externo problemático: personagem GERADO (AVISO), não FALHA
for _, id in { "char_killuo_base", "char_killuo_godspeed" } do
	local r = byId[id]
	local review = 0
	for _, use in r.clothing do
		if use.status == "REVIEW_REQUIRED" then
			review += 1
		end
	end
	check(folder:FindFirstChild(id) ~= nil and r.status == "WARN" and review == 2 and string.find(table.concat(r.warnings, " "), "roupa REVIEW_REQUIRED", 1, true) ~= nil, `{id}: roupa REVIEW_REQUIRED -> gerado com AVISO (não bloqueia o lote)`)
end
check(byId.char_sacha_base.clothing[1].status == "UNCHECKED" and byId.char_sacha_base.status == "OK", "roupa não verificada = UNCHECKED, sem aviso")
check(Config.clothingStatus("2065247269") == "REVIEW_REQUIRED" and Config.clothingStatus("999") == "UNCHECKED", "status vem do config (sem rede)")

-- Correção centralizada por id (ClothingTemplateOverrides): vale para todo personagem com o mesmo id
Config.ClothingTemplateOverrides["2065247269"] = "rbxassetid://777001"
local fixedModel, fixedReport = Pipeline.sanitize(Pipeline.findSource(pack, "HXH.Killua Godspeed"), "char_killuo_godspeed")
check(fixedModel ~= nil and fixedModel:FindFirstChildOfClass("Shirt").ShirtTemplate == "rbxassetid://777001" and fixedModel:FindFirstChildOfClass("Pants").PantsTemplate == "rbxassetid://2065252088", "override de template aplicado pelo pipeline (só no id configurado)")
local overridden = false
for _, use in fixedReport.clothing do
	overridden = overridden or (use.assetId == "2065247269" and use.status == "OVERRIDDEN" and use.final == "rbxassetid://777001")
end
check(overridden, "override aprovado: status OVERRIDDEN e template final no relatório")
fixedModel:Destroy()
Config.ClothingTemplateOverrides["2065247269"] = nil

-- Detecção de perda visual: arma dentro de um Tool (classe não permitida) some -> FALHA com motivo
local lossPack = roblox.Instance.new("Folder")
local lossRig = SyntheticPack.rig(lossPack, "Teste", { scripts = 1 })
local tool = roblox.Instance.new("Tool")
tool.Parent = lossRig
local blade = roblox.Instance.new("MeshPart")
blade.Name = "ToolBlade"
blade.Size = Vector3.new(0.3, 4, 0.3)
blade.CFrame = lossRig["Right Arm"].CFrame * CFrame.new(0, -1, -2)
blade.Parent = tool
local lostModel, lostReport = Pipeline.sanitize(lossRig, "char_sacha_base")
check(lostModel == nil and lostReport.status == "FAIL" and string.find(table.concat(lostReport.problems, " "), "perdeu visual sem justificativa: MeshPart", 1, true) ~= nil, "perda visual (MeshPart dentro de Tool) detectada: FALHA com motivo")
-- Peça transparente com Texture (roupa desenhada numa camada) NÃO é descartada como hitbox
local layerRig = SyntheticPack.rig(lossPack, "Camada", { scripts = 0 })
local layer = roblox.Instance.new("Part")
layer.Name = "ClothLayer"
layer.Size = Vector3.new(2.05, 2.05, 1.05)
layer.Transparency = 1
layer.CFrame = layerRig.Torso.CFrame
layer.Parent = layerRig
local texture = roblox.Instance.new("Texture")
texture.Parent = layer
local weld = roblox.Instance.new("Weld")
weld.Part0 = layerRig.Torso
weld.Part1 = layer
weld.Parent = layer
local layerModel, layerReport = Pipeline.sanitize(layerRig, "char_sacha_base")
check(layerModel ~= nil and layerModel:FindFirstChild("ClothLayer") ~= nil and layerModel.ClothLayer:FindFirstChildOfClass("Texture") ~= nil and #layerReport.visualLost == 0, "peça transparente com Texture (camada de roupa) preservada")
-- Justificativa objeto a objeto: o que sumiu, qual regra removeu, por quê
local function removalOf(report, name, className)
	for _, record in report.visualRemoved do
		if record.name == name and (className == nil or record.className == className) then
			return record
		end
	end
	return nil
end
local function caseRig(name, opts, build)
	local rig = SyntheticPack.rig(lossPack, name, opts)
	if build then
		build(rig)
	end
	return rig
end
local function inTool(rig, className, partName, props)
	local holder = roblox.Instance.new("Tool")
	holder.Parent = rig
	local piece = roblox.Instance.new(className)
	piece.Name = partName
	piece.Size = Vector3.new(0.5, 3, 0.5)
	piece.CFrame = rig["Right Arm"].CFrame * CFrame.new(0, -1, -1.5)
	for key, value in props or {} do
		(piece :: any)[key] = value
	end
	piece.Parent = holder
	return piece
end
-- Part / MeshPart / UnionOperation / SpecialMesh VISÍVEIS removidos -> UNJUSTIFIED -> FAIL
for _, case in { { "Part", "VisiblePart" }, { "MeshPart", "VisibleMesh" }, { "UnionOperation", "VisibleUnion" } } do
	local rig = caseRig("Caso" .. case[1], { scripts = 0 }, function(r)
		inTool(r, case[1], case[2])
	end)
	local m, report = Pipeline.sanitize(rig, "char_sacha_base")
	local record = removalOf(report, case[2], case[1])
	check(m == nil and report.status == "FAIL" and record ~= nil and record.verdict == "UNJUSTIFIED" and record.rule == "ForbiddenClass" and record.visibleAtRest and string.find(table.concat(report.problems, " "), `perdeu visual sem justificativa: {case[1]} "{case[2]}"`, 1, true) ~= nil, `{case[1]} visível removido -> FAIL (regra {record and record.rule}, {record and record.verdict})`)
end
do
	local rig = caseRig("CasoSpecialMesh", { scripts = 0 }, function(r)
		local piece = inTool(r, "Part", "MeshHolder")
		local mesh = roblox.Instance.new("SpecialMesh")
		mesh.Name = "RealMesh"
		mesh.MeshType = roblox.Enum.MeshType.FileMesh
		mesh.MeshId = "rbxassetid://9001"
		mesh.Parent = piece
	end)
	local m, report = Pipeline.sanitize(rig, "char_sacha_base")
	local record = removalOf(report, "RealMesh", "SpecialMesh")
	check(m == nil and record ~= nil and record.verdict == "UNJUSTIFIED" and record.meshId == "rbxassetid://9001" and string.find(record.reason, "removido junto com Tool", 1, true) ~= nil, "SpecialMesh visível removido -> FAIL, com MeshId e o container que o levou: " .. tostring(record and record.reason))
end
-- Hitbox, placa [ SEMI-PRO ] e helper de combate -> JUSTIFIED (não falham), com ficha completa
do
	local rig = caseRig("CasoJustificado", { scripts = 1, combatHelper = true })
	local m, report = Pipeline.sanitize(rig, "char_sacha_base")
	local hitbox = removalOf(report, "Hitbox", "Part")
	local tagHead = nil
	for _, record in report.visualRemoved do
		if string.find(record.path, "[ SEMI-PRO ]", 1, true) then
			tagHead = record
		end
	end
	local drawn = removalOf(report, "SwordDrawn1", "MeshPart")
	local fxPart, fxMesh = removalOf(report, "FXPart", "Part"), removalOf(report, "Mesh", "SpecialMesh")
	check(m ~= nil and report.status ~= "FAIL" and #report.visualLost == 0, "remoções justificadas não derrubam o asset")
	check(hitbox ~= nil and hitbox.verdict == "JUSTIFIED" and hitbox.rule == "InvisibleHitbox" and not hitbox.visibleAtRest, "hitbox invisível -> JUSTIFIED (InvisibleHitbox)")
	check(tagHead ~= nil and tagHead.verdict == "JUSTIFIED" and tagHead.rule == "NameTag", "placa [ SEMI-PRO ] -> JUSTIFIED (NameTag)")
	check(drawn ~= nil and drawn.verdict == "JUSTIFIED" and drawn.rule == "InvisibleCombatHelper" and table.find(drawn.vfxInside, "Trail Trail") ~= nil, "espada sacada (Transparency 1 + Trail) -> JUSTIFIED (InvisibleCombatHelper)")
	check(fxPart ~= nil and fxPart.rule == "InvisibleCombatHelper" and fxMesh ~= nil and fxMesh.verdict == "JUSTIFIED" and string.find(fxMesh.reason, "removido junto com Part", 1, true) ~= nil, "peça de efeito (Part + SpecialMesh + emissor) -> Part e SpecialMesh JUSTIFIED")
	check(drawn ~= nil and drawn.path == "SwordDrawn1" and drawn.meshId == "rbxassetid://5101" and drawn.textureId == "rbxassetid://5102" and drawn.transparency == 1 and drawn.size ~= nil and drawn.bone == "RightArm" and #drawn.joints == 1 and string.find(drawn.joints[1], "Right Arm", 1, true) ~= nil, "ficha: caminho, MeshId, TextureId, Transparency, Size, solda e parte do corpo")
end
-- Remoção SEM regra registrada -> UNJUSTIFIED -> FAIL
do
	local rig = caseRig("CasoSemRegra", { scripts = 0, loose = true })
	local m, report = Pipeline.sanitize(rig, "char_sacha_base", function(model)
		model.Belt:Destroy()
	end)
	local record = removalOf(report, "Belt", "Part")
	check(m == nil and report.status == "FAIL" and record ~= nil and record.rule == "NO_RULE" and record.verdict == "UNJUSTIFIED", "objeto visual destruído sem regra registrada -> FAIL (NO_RULE)")
end
check(#layerReport.visualRemoved == 0 or removalOf(layerReport, "ClothLayer") == nil, "camada com Texture legítima: PRESERVADA (fora da lista de remoções)")
lossPack:Destroy()

-- MISSING_SOURCE: candidatos parecidos (nunca escolhidos sozinhos)
do
	local lancerPack = roblox.Instance.new("Folder")
	local fate = roblox.Instance.new("Folder")
	fate.Name = "FATE"
	fate.Parent = lancerPack
	for _, name in { "Lancer ", "Lancer Mode", "Saber" } do
		local m = roblox.Instance.new("Model")
		m.Name = name
		m.Parent = fate
	end
	local candidates = Pipeline.sourceCandidates(lancerPack, "FATE.Lancer")
	check(Pipeline.findSource(lancerPack, "FATE.Lancer") == nil and Pipeline.findSource(lancerPack, "FATE.Lancer ") ~= nil, "nome com espaço no fim: só o caminho EXATO acha o modelo (sem fuzzy)")
	check(#candidates == 2 and candidates[1] == '"FATE.Lancer "' and candidates[2] == '"FATE.Lancer Mode"', "candidatos do MISSING_SOURCE listados entre aspas: " .. table.concat(candidates, ", "))
	local _, missingReports = Pipeline.buildAll(lancerPack, { "char_iskander_base" })
	check(string.find(missingReports[1].problems[1], "candidatos: nenhum", 1, true) ~= nil, "MISSING_SOURCE sem candidato diz \"nenhum\"")
	lancerPack:Destroy()
end

------------------------------------------------------------------------------------
-- 2) Salva como assets/Characters.rbxm e DESTRÓI o pack (o jogo final não tem o pack)
fs.writeDir("build")
local file = "build/test_CharacterAssets.rbxm"
fs.writeFile(file, roblox.serializeModel({ folder }))
pack:Destroy()
folder:Destroy()
check(env.real.Workspace:FindFirstChild(Config.SourcePackName) == nil, "SOURCE PACK REMOVIDO do Workspace antes do jogo final")

local loaded = roblox.deserializeModel(fs.readFile(file))[1]
loaded.Parent = env.real.ReplicatedStorage
check(loaded.Name == Config.StorageName and #loaded:GetChildren() == assetCount, "assets (121) lidos do .rbxm em ReplicatedStorage." .. Config.StorageName)

local failures = T.finish()

------------------------------------------------------------------------------------
-- 3) FINAL GAME: factory só com os assets sanitizados
local F = Env.checker("Pipeline de personagens: factory/variantes/poses (sem o pack)")
check = F.check
local Factory = requireModule(env.shared.Modules.CharacterModelFactory)
local VariantConfig = requireModule(env.shared.Config.VariantConfig)
local RarityConfig = requireModule(env.shared.Config.RarityConfig)

local function feetAndHeight(model)
	local pivot = model.PrimaryPart.CFrame
	local legMin = Pipeline.boundsOf({ model:FindFirstChild("Left Leg"), model:FindFirstChild("Right Leg") }, pivot)
	local _, headMax = Pipeline.boundsOf({ model:FindFirstChild("Head") }, pivot)
	return legMin.Y, headMax.Y - legMin.Y
end

for _, character in CharacterConfig.Pilots do
	local id = character.Id
	local model = Factory.build(id, { variant = "Normal", vfx = "Light" })
	local scale = Config.RuntimeScale * RarityConfig.ById[character.Rarity].ModelScale
	check(model:GetAttribute("TODO_ASSET") == nil and model:GetAttribute("AssetRig") == true, `{id}: factory usa o asset sanitizado (não o placeholder)`)
	local feet, height = feetAndHeight(model)
	check(math.abs(feet) < 0.02 and math.abs(height - Config.BodyHeight * scale) < 0.05, string.format("%s: escala da raridade (corpo %.2f = %.2f)", id, height, Config.BodyHeight * scale))
	-- SpawnCharacter(id, alvo): pés na superfície, centralizado, virado para o alvo
	local target = CFrame.new(40, 7.2, -15) * CFrame.Angles(0, math.rad(60), 0)
	local spawned = Factory.spawn(id, target, { vfx = "None" })
	local legMin = Pipeline.boundsOf({ spawned:FindFirstChild("Left Leg"), spawned:FindFirstChild("Right Leg") }, target)
	local torso = spawned:FindFirstChild("Torso")
	local localTorso = target:PointToObjectSpace(torso.CFrame.Position)
	check(math.abs(legMin.Y) < 0.02 and math.abs(localTorso.X) < 0.02 and math.abs(localTorso.Z) < 0.05 and torso.CFrame.LookVector:Dot(target.LookVector) > 0.99, `{id}: spawn com pés no alvo, centralizado e virado certo`)
	model:Destroy()
	spawned:Destroy()
end

-- Lote inteiro no factory: Base (Light + variante), Mochila/Índice (None), Reveal/Hero (Full + poses)
local factoryBad = {}
local t0 = os.clock()
for _, character in CharacterConfig.Launch do
	local ok, err = pcall(function()
		local base = Factory.spawn(character.Id, CFrame.new(0, 2, 0), { vfx = "Light", variant = "Gold" })
		assert(base:GetAttribute("AssetRig") == true, "placeholder")
		local legMin = Pipeline.boundsOf({ base:FindFirstChild("Left Leg"), base:FindFirstChild("Right Leg") }, CFrame.new(0, 2, 0))
		assert(math.abs(legMin.Y) < 0.05, "pés fora do alvo")
		base:Destroy()
		local viewport = Factory.build(character.Id, { vfx = "None" })
		assert(viewport:GetAttribute("VFXMode") == "None")
		viewport:Destroy()
		local hero = Factory.build(character.Id, { vfx = "Full", pose = "Reveal" })
		Factory.pose(hero, "Crouch")
		Factory.lerpPose(hero, "Crouch", "Confident", 0.5)
		hero:Destroy()
	end)
	if not ok then
		table.insert(factoryBad, character.Id .. ": " .. tostring(err))
	end
end
check(#factoryBad == 0, string.format("factory monta os 121 (Base/Mochila-Índice/Reveal-Hero) em %.1fs%s", os.clock() - t0, if #factoryBad > 0 then ": " .. table.concat(factoryBad, "; ") else ""))
-- Variantes reaproveitam o MESMO modelo-base (sem cópias físicas no pack de assets)
local copies = 0
for _, child in loaded:GetChildren() do
	if string.find(child.Name, "Silver", 1, true) or string.find(child.Name, "Gold", 1, true) or child:GetAttribute("Variant") then
		copies += 1
	end
end
check(copies == 0 and #loaded:GetChildren() == #CharacterConfig.Launch, "variantes: 1 asset por CharacterId (nenhuma cópia por variante)")
-- Formas continuam ids separados (não viram variante)
check(loaded:FindFirstChild("char_ichiro_base") ~= nil and loaded:FindFirstChild("char_ichiro_hollow") ~= nil and CharacterConfig.ById.char_ichiro_hollow.FormTier == 2 and CharacterConfig.ById.char_ichiro_hollow.CharacterFamily == CharacterConfig.ById.char_ichiro_base.CharacterFamily, "formas: ids/assets separados com a mesma família e FormTier diferente")

-- Variantes: as 7 em pilotos com e sem acentos (sem pintar corpo/rosto/roupa)
for _, id in { "char_ichiro_base", "char_goko_base", "char_barbalva_base" } do
	local normal = Factory.build(id, { variant = "Normal", vfx = "Full" })
	local bodyColor = normal.Torso.Color
	local accent = (normal:FindFirstChild("Blade", true) or normal:FindFirstChild("Cape", true) or normal:FindFirstChild("Handle", true))
	local accentColor = accent.Color
	for _, variant in VariantConfig.List do
		local model = Factory.build(id, { variant = variant.Id, vfx = "Full" })
		local ring = model:FindFirstChild("VariantRing")
		local intact = model.Torso.Color == bodyColor and model.Head:FindFirstChild("face") ~= nil and model:FindFirstChildOfClass("Shirt") ~= nil and model:FindFirstChildOfClass("Pants") ~= nil
		local sameAccent = (model:FindFirstChild(accent.Name, true).Color == accentColor)
		local textured = Pipeline.textureOf(accent) ~= ""
		local ok
		if variant.Id == "Normal" then
			ok = ring == nil and sameAccent
		else
			ok = ring ~= nil and (textured or not sameAccent)
		end
		check(intact and ok and model:GetAttribute("Variant") == variant.Id, `{id}: variante {variant.Id} (corpo/rosto/roupa intactos, acento e anel)`)
		model:Destroy()
	end
	normal:Destroy()
end

-- Override de roupa vale também no runtime (assets antigos, sem precisar gerar de novo)
Config.ClothingTemplateOverrides["2065252088"] = "rbxassetid://777002"
local dressed = Factory.build("char_killuo_godspeed", { vfx = "None" })
check(dressed:FindFirstChildOfClass("Pants").PantsTemplate == "rbxassetid://777002" and dressed:FindFirstChildOfClass("Shirt").ShirtTemplate == "rbxassetid://2065247269", "factory aplica ClothingTemplateOverrides no clone (runtime)")
dressed:Destroy()
Config.ClothingTemplateOverrides["2065252088"] = nil

-- Modos de VFX
local function effects(model)
	local n = 0
	for _, obj in model:GetDescendants() do
		if table.find(Config.VFXClasses, obj.ClassName) then
			n += 1
		end
	end
	return n
end
local none = Factory.build("char_killuo_godspeed", { vfx = "None" })
local light = Factory.build("char_killuo_godspeed", { vfx = "Light", aura = false })
local full = Factory.build("char_killuo_godspeed", { vfx = "Full", aura = false })
check(effects(none) == 0 and effects(light) == Config.VFXLimits.MaxLight and effects(full) == Config.VFXLimits.MaxFull, `VFXMode None/Light/Full = {effects(none)}/{effects(light)}/{effects(full)}`)
local based = Factory.build("char_killuo_godspeed", { vfx = "Light" })
check(based:FindFirstChild("Aura", true) ~= nil and effects(based) <= Config.VFXLimits.MaxLight + 2, "Base (Light): raios leves + aura da raridade, nada além disso")
for _, m in { none, light, full, based } do
	m:Destroy()
end

-- Poses próprias (R6): mexem braços, mantêm os pés no chão em Idle/Reveal/Combat
local posed = Factory.build("char_ichiro_base", { vfx = "None" })
local armIdle = posed["Right Arm"].CFrame
local bladeIdle = posed:FindFirstChild("Blade", true).CFrame
for _, poseName in { "Reveal", "Combat", "Idle" } do
	Factory.pose(posed, poseName)
	local feet = feetAndHeight(posed)
	check(feet > -0.35 and feet < 0.35, `pose {poseName}: pés no chão ({string.format("%.2f", feet)})`)
	if poseName == "Reveal" then
		local arm = posed["Right Arm"].CFrame
		local blade = posed:FindFirstChild("Blade", true).CFrame
		check(not arm.Position:FuzzyEq(armIdle.Position, 0.1) and (arm:ToObjectSpace(blade).Position - armIdle:ToObjectSpace(bladeIdle).Position).Magnitude < 0.01, "pose Reveal: braço erguido e a espada acompanha o braço (solda assada)")
	end
end
check(posed["Right Arm"].CFrame.Position:FuzzyEq(armIdle.Position, 0.001), "voltar para Idle restaura a pose")
Factory.lerpPose(posed, "Crouch", "Confident", 0.5)
check(posed.Head.CFrame.Position.Y < armIdle.Position.Y + 10, "lerpPose (hero landing) funciona no asset R6")
posed:Destroy()

-- Fallback: id sem asset, asset inválido, id desconhecido -> placeholder, sem quebrar
local fallbackOk = pcall(function()
	local unknown = Factory.build("char_nao_existe", {})
	assert(unknown:GetAttribute("TODO_ASSET") == true)
	unknown:Destroy()
end)
check(fallbackOk, "CharacterId desconhecido: placeholder, sem erro")
local flame = Factory.build("flame_rookie", {})
check(flame:GetAttribute("TODO_ASSET") == true, "personagem do roster sem asset: placeholder (fallback atual)")
flame:Destroy()
-- Asset adulterado (um Script injetado) é rejeitado no validate do runtime
local infected = loaded:FindFirstChild("char_sacha_base")
local backdoor = roblox.Instance.new("Script")
backdoor.Name = "Backdoor"
backdoor.Parent = infected.Torso
Factory.clearCache()
local rejected = Factory.build("char_sacha_base", {})
check(rejected:GetAttribute("TODO_ASSET") == true and rejected:FindFirstChild("Backdoor", true) == nil, "asset com Script injetado: rejeitado, usa placeholder")
rejected:Destroy()
backdoor:Destroy()
Factory.clearCache()
-- Sem a pasta de assets: tudo vira placeholder (pipeline nunca é dependência obrigatória)
loaded.Parent = nil
local orphan = Factory.build("char_goju_base", {})
check(orphan:GetAttribute("TODO_ASSET") == true, "sem ReplicatedStorage.CharacterAssets: placeholder")
orphan:Destroy()
loaded.Parent = env.real.ReplicatedStorage
Factory.clearCache()

-- Altura do billboard: acima do corpo, sem exagero
local height = Factory.height("char_zabuzo_base")
local body = Config.BodyHeight * Config.RuntimeScale * RarityConfig.ById.Rare.ModelScale
check(height > body and height < body * 1.5, string.format("altura do billboard %.2f (corpo %.2f)", height, body))

-- Limpeza: destruir o modelo leva tudo junto (nada fica pendurado no mundo)
local container = roblox.Instance.new("Folder")
container.Parent = env.real.Workspace
for _ = 1, 5 do
	local m = Factory.build("char_killuo_godspeed", { variant = "Celestial", vfx = "Full" })
	m.Parent = container
	m:Destroy()
end
check(#container:GetChildren() == 0 and #container:GetDescendants() == 0, "5 builds destruídos: nenhuma instância órfã")

failures += F.finish()
if failures > 0 then
	process.exit(1)
end
