--[[
	Gera os CHARACTER ASSETS do Roll Legends a partir do pack de origem (sem executar nada do pack).
	Normalmente chamado por:  python tools/build_characters.py

	    lune run tools/characters/build_characters.luau <pack.rbxm|.rbxl> [saida.rbxm] [relatorio.md] [relatorio.json]

	- Lê o arquivo (modelo salvo com "Save to File" ou place inteiro: usa Workspace.Anime Pack).
	- Roda o CharacterAssetPipeline REAL (src/shared) em cada personagem de
	  CharacterAssetConfig.Assets: clona, sanitiza, normaliza e valida.
	- Salva só os assets aprovados em assets/Characters.rbxm (vira ReplicatedStorage.CharacterAssets
	  no build) + relatório por personagem (CHARACTER_PILOT_AUDIT.md e JSON).
	Saída 0 = todos OK/AVISO; 2 = algum personagem falhou (os outros são salvos mesmo assim).
]]
local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local Env = require("../../tests/roblox/Env")

local args = process.args
local input = args[1] or "third_party/AnimePack.rbxm"
local output = args[2] or "assets/Characters.rbxm"
local reportMd = args[3] or "CHARACTER_PILOT_AUDIT.md"
local reportJson = args[4] or "third_party/character_pilot_report.json"
-- Nome do arquivo de origem para o relatório (a ferramenta passa o original, não a cópia temporária)
local sourceLabel = args[5] or input
local clothingMd = args[6] or "CLOTHING_AUDIT.md"

if not fs.isFile(input) then
	print("Arquivo não encontrado: " .. input)
	process.exit(1)
end

local env = Env.create()
local requireModule = env.newContext()
local Config = requireModule(env.shared.Config.CharacterAssetConfig)
local CharacterConfig = requireModule(env.shared.Config.CharacterConfig)
local Pipeline = requireModule(env.shared.Modules.CharacterAssetPipeline)

-- Acha a raiz do pack (modelo salvo ou place inteiro)
local data = fs.readFile(input)
local pack
local lower = string.lower(input)
if string.sub(lower, -5) == ".rbxl" or string.sub(lower, -6) == ".rbxlx" then
	local place = roblox.deserializePlace(data)
	pack = place:GetService("Workspace"):FindFirstChild(Config.SourcePackName)
else
	local roots = roblox.deserializeModel(data)
	for _, root in roots do
		if root.Name == Config.SourcePackName then
			pack = root
		end
	end
	if not pack and #roots == 1 then
		pack = roots[1]
	end
end
if not pack then
	print(`"{Config.SourcePackName}" não encontrado em {input}`)
	process.exit(1)
end

local folder, reports = Pipeline.buildAll(pack)
fs.writeFile(output, roblox.serializeModel({ folder }))

local function joinList(list)
	return if #list == 0 then "—" else table.concat(list, "<br>")
end
local function others(map)
	local list = {}
	for className, count in map do
		table.insert(list, `{className} {count}`)
	end
	table.sort(list)
	return if #list == 0 then "—" else table.concat(list, ", ")
end
local reportById = {}
for _, r in reports do
	reportById[r.CharacterId] = r
end

-- Factory: cada asset gerado precisa montar em todos os contextos (Base, Mochila/Índice, Reveal/Hero)
folder.Parent = env.real.ReplicatedStorage
local Factory = requireModule(env.shared.Modules.CharacterModelFactory)
local factoryOk = {}
for _, r in reports do
	if folder:FindFirstChild(r.CharacterId) then
		local ok, err = pcall(function()
			for _, opts in { { vfx = "Light", variant = "Gold" }, { vfx = "None" }, { vfx = "Full", pose = "Reveal" } } do
				local model = Factory.build(r.CharacterId, opts)
				assert(model:GetAttribute("AssetRig") == true, "montou o placeholder em vez do asset")
				Factory.pose(model, "Crouch")
				Factory.lerpPose(model, "Crouch", "Confident", 0.5)
				model:Destroy()
			end
		end)
		factoryOk[r.CharacterId] = ok
		if not ok then
			table.insert(r.problems, "factory: " .. tostring(err))
			r.status = "FAIL"
		end
	end
end
folder.Parent = nil

-- Possíveis duplicatas: mesmo conjunto de malhas/texturas/roupas/rostos em ids diferentes
local function prop(obj, name)
	local ok, value = pcall(function()
		return obj[name]
	end)
	return if ok and value ~= nil then tostring(value) else ""
end
local fingerprints = {}
for _, model in folder:GetChildren() do
	local keys = {}
	for _, obj in model:GetDescendants() do
		if obj:IsA("MeshPart") then
			table.insert(keys, "M" .. prop(obj, "MeshId") .. prop(obj, "TextureID"))
		elseif obj:IsA("SpecialMesh") then
			table.insert(keys, "S" .. prop(obj, "MeshId") .. prop(obj, "TextureId"))
		elseif obj:IsA("Shirt") then
			table.insert(keys, "C" .. prop(obj, "ShirtTemplate"))
		elseif obj:IsA("Pants") then
			table.insert(keys, "P" .. prop(obj, "PantsTemplate"))
		elseif obj:IsA("Decal") then
			table.insert(keys, "D" .. prop(obj, "Texture"))
		end
	end
	table.sort(keys)
	local key = table.concat(keys, "|")
	if #keys > 0 then
		fingerprints[key] = fingerprints[key] or {}
		table.insert(fingerprints[key], model.Name)
	end
end
local duplicates = {}
for _, ids in fingerprints do
	if #ids > 1 then
		table.sort(ids)
		table.insert(duplicates, ids)
		for _, id in ids do
			table.insert(reportById[id].warnings, "POSSIBLE_DUPLICATE: mesmo visual que " .. table.concat(ids, ", "))
		end
	end
end

local function others(map)
	local list = {}
	for className, count in map do
		table.insert(list, `{className} {count}`)
	end
	table.sort(list)
	return if #list == 0 then "—" else table.concat(list, ", ")
end

-- CLOTHING_AUDIT: uma linha por AssetId ÚNICO (roupa compartilhada = verificada/registrada uma vez)
local byAsset, assetOrder = {}, {}
for _, r in reports do
	for _, use in r.clothing or {} do
		local entry = byAsset[use.assetId]
		if not entry then
			entry = { use = use, characters = {} }
			byAsset[use.assetId] = entry
			table.insert(assetOrder, use.assetId)
		end
		if not table.find(entry.characters, r.CharacterId) then
			table.insert(entry.characters, r.CharacterId)
		end
	end
end
table.sort(assetOrder, function(a, b)
	local sa, sb = byAsset[a].use.status, byAsset[b].use.status
	if sa ~= sb then
		return sa == "REVIEW_REQUIRED" -- revisão primeiro
	end
	return a < b
end)
local ACTIONS = {
	OK = "nenhuma",
	UNCHECKED = "verificar no Studio: Invoke(\"ClothingCheck\") e registrar em ClothingStatus",
	REVIEW_REQUIRED = "aprovar uma roupa substituta e registrar em ClothingTemplateOverrides",
	OVERRIDDEN = "nenhuma (override aprovado)",
}
local counts = { OK = 0, UNCHECKED = 0, REVIEW_REQUIRED = 0, OVERRIDDEN = 0 }
local clothingLines = {
	"# CLOTHING AUDIT — Roll Legends",
	"",
	`Gerado por \`python tools/build_characters.py\` a partir de \`{sourceLabel}\`. Uma linha por AssetId (roupas compartilhadas aparecem uma vez com todos os personagens). Sem chamadas de rede: o status vem de \`CharacterAssetConfig.ClothingStatus\` (evidência do comando DEV ClothingCheck) e os substitutos aprovados de \`ClothingTemplateOverrides\`. REVIEW_REQUIRED não impede o build: o personagem é gerado com AVISO.`,
	"",
	"| AssetId | Tipo | Status | Personagens | Override | Observação | Ação necessária |",
	"|---|---|---|---|---|---|---|",
}
for _, id in assetOrder do
	local entry = byAsset[id]
	local audit = Config.ClothingStatus[id]
	local override = Config.ClothingTemplateOverrides[id]
	counts[entry.use.status] = (counts[entry.use.status] or 0) + 1
	table.insert(clothingLines, `| {id} | {entry.use.kind} | **{entry.use.status}** | {table.concat(entry.characters, "<br>")} | {override or "—"} | {if audit and audit.Note then audit.Note else "—"} | {ACTIONS[entry.use.status] or "?"} |`)
end
table.insert(clothingLines, "")
table.insert(clothingLines, `Total: {#assetOrder} AssetId(s) — OK {counts.OK} · UNCHECKED {counts.UNCHECKED} · REVIEW_REQUIRED {counts.REVIEW_REQUIRED} · OVERRIDDEN {counts.OVERRIDDEN}`)
fs.writeFile(clothingMd, table.concat(clothingLines, "\n") .. "\n")

------------------------------------------------------------------------------------
-- CHARACTER_LAUNCH_AUDIT: resumo + uma linha por personagem de lançamento
local launch = CharacterConfig.Launch
local counted = { generated = 0, failed = 0, missing = 0, factory = 0, F2P = 0, Premium = 0, F2Pok = 0, Premiumok = 0, optOk = 0, optNeed = 0, vfxOk = 0, vfxReview = 0 }
local clothingByStatus = { OK = 0, UNCHECKED = 0, REVIEW_REQUIRED = 0, OVERRIDDEN = 0 }
for _, use in assetOrder do
	clothingByStatus[byAsset[use].use.status] = (clothingByStatus[byAsset[use].use.status] or 0) + 1
end
local rows = {}
local idsSeen = {}
for _, character in launch do
	idsSeen[character.Id] = true
	local r = reportById[character.Id]
	local pool = character.LaunchPool or "?"
	counted[pool] = (counted[pool] or 0) + 1
	local result
	if not r then
		result = "NOT_PROCESSED"
	elseif string.find(table.concat(r.problems, " "), "modelo de origem não encontrado", 1, true) then
		result = "MISSING_SOURCE"
		counted.missing += 1
	elseif r.status == "FAIL" then
		result = "FAIL"
		counted.failed += 1
	else
		result = if r.status == "WARN" then "OK (avisos)" else "OK"
		counted.generated += 1
		counted[pool .. "ok"] = (counted[pool .. "ok"] or 0) + 1
	end
	if r and factoryOk[character.Id] then
		counted.factory += 1
	end
	if r and result ~= "MISSING_SOURCE" then
		if r.optimizationStatus == "OK" then
			counted.optOk += 1
		else
			counted.optNeed += 1
		end
		if r.vfxStatus == "OK" then
			counted.vfxOk += 1
		else
			counted.vfxReview += 1
		end
	end
	local final = if r and r.finalCounts.Parts then r.finalCounts.Parts else "—"
	table.insert(rows, `| \`{character.Id}\` | {character.Name} | {character.SourceModelName or "?"} | {character.Rarity} | {pool} | {character.DefaultDice or "?"} | {character.CharacterFamily or "?"} | {character.FormTier or "?"} | {if r then r.originalParts else "—"} | {final} | {if r then r.clothingStatus else "—"} | {if r then r.optimizationStatus .. (if r.catalogStatus ~= "APPROVED" then " (catálogo: " .. r.catalogStatus .. ")" else "") else "—"} | {if r then r.vfxStatus else "—"} | **{result}** |`)
end
local uniqueIds = 0
for _ in idsSeen do
	uniqueIds += 1
end
local sanitizerPass = counted.failed == 0
local largest = {}
for _, r in reports do
	if r.finalCounts.Instances then
		table.insert(largest, r)
	end
end
table.sort(largest, function(a, b)
	return a.finalCounts.Instances > b.finalCounts.Instances
end)
local out = {
	"# CHARACTER LAUNCH AUDIT — Roll Legends",
	"",
	`Gerado por \`python tools/build_characters.py\` a partir de \`{sourceLabel}\` (nenhum script do pack é executado). Assets em \`{output}\` → \`ReplicatedStorage.{Config.StorageName}\`. Roster do roll/Índice oficial NÃO muda nesta fase.`,
	"",
	"## Resumo",
	"",
	"```",
	`Launch characters: {counted.generated}/{#launch}`,
	`F2P: {counted.F2Pok or 0}/{counted.F2P or 0}`,
	`Premium: {counted.Premiumok or 0}/{counted.Premium or 0}`,
	"",
	`Sanitizer: {if sanitizerPass then "PASS" else "FAIL"} ({counted.failed} falha(s))`,
	`CharacterIds únicos: {uniqueIds}/{#launch}`,
	`Source models encontrados: {#launch - counted.missing}/{#launch}`,
	`Factory: {counted.factory}/{#launch}`,
	"",
	`Clothing (por AssetId único, {#assetOrder} ids):`,
	`  OK: {clothingByStatus.OK}`,
	`  UNCHECKED: {clothingByStatus.UNCHECKED}`,
	`  REVIEW_REQUIRED: {clothingByStatus.REVIEW_REQUIRED}`,
	`  OVERRIDDEN: {clothingByStatus.OVERRIDDEN}`,
	"",
	`Optimization (orçamento: {Config.Budget.MaxParts} peças, {Config.Budget.MaxInstances} instâncias):`,
	`  OK: {counted.optOk}`,
	`  NEEDS_OPTIMIZATION: {counted.optNeed}`,
	"",
	`VFX (limites: {Config.VFXLimits.MaxFull} guardados, {Config.VFXLimits.MaxLight} no modo Light, {Config.VFXLimits.MaxLights} luz):`,
	`  OK: {counted.vfxOk}`,
	`  REVIEW: {counted.vfxReview}`,
	"",
	`Possíveis duplicatas: {#duplicates}`,
	"```",
	"",
	"## Personagens",
	"",
	"| CharacterId | DisplayName | SourceModelName | Rarity | LaunchPool | Dice | Family | FormTier | SourceParts | FinalParts | ClothingStatus | OptimizationStatus | VFXStatus | Result |",
	"|---|---|---|---|---|---|---|---|---|---|---|---|---|---|",
}
for _, row in rows do
	table.insert(out, row)
end
local function section(title, filter, describe)
	local items = {}
	for _, character in launch do
		local r = reportById[character.Id]
		if r and filter(r) then
			table.insert(items, `- \`{character.Id}\` ({character.Name}): {describe(r)}`)
		end
	end
	table.insert(out, "")
	table.insert(out, `## {title} ({#items})`)
	table.insert(out, "")
	table.insert(out, if #items == 0 then "Nenhum." else table.concat(items, "\n"))
end
section("FAIL / MISSING_SOURCE", function(r)
	return r.status == "FAIL"
end, function(r)
	return table.concat(r.problems, "; ")
end)
section("Roupa REVIEW_REQUIRED", function(r)
	return r.clothingStatus == "REVIEW_REQUIRED"
end, function(r)
	local ids = {}
	for _, use in r.clothing do
		if use.status == "REVIEW_REQUIRED" then
			table.insert(ids, `{use.kind} {use.assetId}`)
		end
	end
	return table.concat(ids, ", ") .. " (CLOTHING_AUDIT.md)"
end)
section("NEEDS_OPTIMIZATION", function(r)
	return r.optimizationStatus ~= "OK"
end, function(r)
	local c = r.finalCounts
	return `{c.Parts} peças, {c.Instances} instâncias, {c.MeshParts} MeshParts, {c.Attachments} attachments, {c.Emitters} emissores (nada foi cortado)`
end)
section("VFX REVIEW", function(r)
	return r.vfxStatus ~= "OK"
end, function(r)
	local parts = {}
	if r.vfxTruncated > 0 then
		table.insert(parts, `{r.vfxTruncated} efeito(s) próprio(s) acima do limite`)
	end
	if #r.vfxExcluded > 0 then
		table.insert(parts, "fora da whitelist (golpe/rastro): " .. table.concat(r.vfxExcluded, ", "))
	end
	return table.concat(parts, "; ")
end)
table.insert(out, "")
table.insert(out, `## POSSIBLE_DUPLICATE ({#duplicates})`)
table.insert(out, "")
if #duplicates == 0 then
	table.insert(out, "Nenhuma.")
else
	for _, ids in duplicates do
		table.insert(out, "- " .. table.concat(ids, " = "))
	end
end
table.insert(out, "")
table.insert(out, "## Maiores personagens (instâncias no asset final)")
table.insert(out, "")
for i = 1, math.min(10, #largest) do
	local r = largest[i]
	table.insert(out, `- \`{r.CharacterId}\`: {r.finalCounts.Instances} instâncias, {r.finalCounts.Parts} peças, {r.finalCounts.MeshParts} MeshParts`)
end
table.insert(out, "")
table.insert(out, "## Detalhes por personagem")
for _, character in launch do
	local r = reportById[character.Id]
	if not r then
		continue
	end
	table.insert(out, "")
	table.insert(out, `### {character.Name} (\`{r.CharacterId}\`) — {r.status}`)
	table.insert(out, `- Origem: \`{Config.SourcePackName}.{r.SourcePath}\` · escala {string.format("%.3f", r.scaleFactor)} · Humanoid (roupa): {if r.humanoidKept then "sim" else "não"}`)
	table.insert(out, `- Removidos: scripts {r.scriptsRemoved}, remotes {r.remotesRemoved}, sons {r.soundsRemoved}, animações {r.animationsRemoved}, bindables {r.bindablesRemoved}, estado {r.valuesRemoved}, GUIs {r.guisRemoved}, peças invisíveis {r.hiddenPartsRemoved}, placas de título {r.nameTagsRemoved}, VFX {r.vfxRemoved}, outros: {others(r.otherRemoved)}`)
	local visual = {}
	for _, className in Pipeline.VisualClasses do
		local before, after = r.visualSource[className] or 0, r.visualSanitized[className] or 0
		if before > 0 or after > 0 then
			table.insert(visual, `{className} {before}→{after}`)
		end
	end
	table.insert(out, `- Visual (origem → asset): {table.concat(visual, ", ")} · perdas: {if #r.visualLost == 0 then "nenhuma" else table.concat(r.visualLost, ", ")}`)
	table.insert(out, `- VFX mantidos: {if #r.vfxPreserved == 0 then "—" else table.concat(r.vfxPreserved, ", ")}`)
	if #r.problems > 0 then
		table.insert(out, "- **Problemas:** " .. table.concat(r.problems, "; "))
	end
	if #r.warnings > 0 then
		table.insert(out, "- Avisos: " .. table.concat(r.warnings, "; "))
	end
end
fs.writeFile(reportMd, table.concat(out, "\n") .. "\n")
fs.writeFile(reportJson, serde.encode("json", reports, true))
local failed = counted.failed

print(`{counted.generated}/{#launch} personagens de lançamento gerados em {output} (F2P {counted.F2Pok or 0}/{counted.F2P or 0} · Premium {counted.Premiumok or 0}/{counted.Premium or 0})`)
print(`Sanitizer: {if sanitizerPass then "PASS" else "FAIL"} · source encontrados {#launch - counted.missing}/{#launch} · factory {counted.factory}/{#launch}`)
print(`Roupas (AssetIds únicos): OK {clothingByStatus.OK} · UNCHECKED {clothingByStatus.UNCHECKED} · REVIEW_REQUIRED {clothingByStatus.REVIEW_REQUIRED} · OVERRIDDEN {clothingByStatus.OVERRIDDEN}`)
print(`Otimização: OK {counted.optOk} · NEEDS_OPTIMIZATION {counted.optNeed} · VFX: OK {counted.vfxOk} · REVIEW {counted.vfxReview} · possíveis duplicatas {#duplicates}`)
for _, r in reports do
	if r.status == "FAIL" then
		print(string.format("  FAIL %-26s %s", r.CharacterId, table.concat(r.problems, "; ")))
	end
end
print(`Relatório: {reportMd}`)
print(`Roupas: {clothingMd} ({#assetOrder} AssetId(s), {counts.REVIEW_REQUIRED} para revisão)`)
process.exit(if failed > 0 or counted.missing > 0 then 2 else 0)
