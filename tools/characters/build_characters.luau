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
local lines = {
	"# CHARACTER PILOT AUDIT — Roll Legends",
	"",
	`Gerado por \`python tools/build_characters.py\` a partir de \`{sourceLabel}\` (nenhum script do pack é executado).`,
	`Assets aprovados em \`{output}\` → \`ReplicatedStorage.{Config.StorageName}\` no build.`,
	"",
	`Regras: corpo normalizado para {Config.BodyHeight} studs (pés ao topo da Head), pivô no centro dos pés olhando para -Z, tudo ancorado sem colisão/toque/consulta, soldas assadas, sem scripts/remotes/sons/animações/estado. Meta de peças: <= {Config.PreferredMaxParts}.`,
	"",
	"| CharacterId | DisplayName | SourceModelName | Peças (orig → final) | Malhas | Texturas | Decals | Soldas | Motor6D | VFX mantidos | VFX removidos | Scripts | Remotes | Sons | Animações | Caixa final (studs, corpo=5) | Offset | Status |",
	"|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|",
}
local failed = 0
local summary = {}
for _, r in reports do
	local character = CharacterConfig.ById[r.CharacterId]
	local display = if character then character.Name else "?"
	local bounds = string.format("%.1f × %.1f × %.1f", r.boundsSize[1], r.boundsSize[2], r.boundsSize[3])
	local offset = string.format("%g, %g, %g", r.visualOffset[1], r.visualOffset[2], r.visualOffset[3])
	table.insert(lines, `| \`{r.CharacterId}\` | {display} | {r.SourceModelName} | {r.originalParts} → {r.sanitizedParts} | {r.meshes} | {r.textures} | {r.decals} | {r.welds} | {r.motors} | {joinList(r.vfxPreserved)} | {r.vfxRemoved} | {r.scriptsRemoved} | {r.remotesRemoved} | {r.soundsRemoved} | {r.animationsRemoved} | {bounds} | {offset} | **{r.status}** |`)
	if r.status == "FAIL" then
		failed += 1
	end
	table.insert(summary, { report = r, display = display })
end
table.insert(lines, "")
table.insert(lines, "## Detalhes")
for _, item in summary do
	local r = item.report
	table.insert(lines, "")
	table.insert(lines, `### {item.display} (\`{r.CharacterId}\`) — {r.status}`)
	table.insert(lines, `- Origem: \`{Config.SourcePackName}.{r.SourcePath}\``)
	table.insert(lines, `- Escala aplicada na normalização: {string.format("%.3f", r.scaleFactor)} · Humanoid mantido (roupas): {if r.humanoidKept then "sim" else "não"} · Acessórios convertidos: {r.accessories}`)
	table.insert(lines, `- Removidos: bindables {r.bindablesRemoved}, valores de estado {r.valuesRemoved}, GUIs {r.guisRemoved}, peças invisíveis {r.hiddenPartsRemoved}, outros: {others(r.otherRemoved)}`)
	local visual = {}
	for _, className in Pipeline.VisualClasses do
		local before, after = r.visualSource[className] or 0, r.visualSanitized[className] or 0
		if before > 0 or after > 0 then
			table.insert(visual, `{className} {before}→{after}`)
		end
	end
	table.insert(lines, `- Visual (origem → asset, só o que deve ficar): {table.concat(visual, ", ")} · perdas: {if #r.visualLost == 0 then "nenhuma" else table.concat(r.visualLost, ", ")}`)
	local clothing = {}
	for _, use in r.clothing do
		table.insert(clothing, `{use.kind} {use.assetId} ({use.status})`)
	end
	table.insert(lines, `- Roupa: {if #clothing == 0 then "—" else table.concat(clothing, "; ")} · placas de título removidas: {r.nameTagsRemoved}`)
	if #r.problems > 0 then
		table.insert(lines, "- **Problemas:** " .. table.concat(r.problems, "; "))
	end
	if #r.warnings > 0 then
		table.insert(lines, "- Avisos: " .. table.concat(r.warnings, "; "))
	end
end
fs.writeFile(reportMd, table.concat(lines, "\n") .. "\n")
fs.writeFile(reportJson, serde.encode("json", reports, true))

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

print(`{#reports - failed}/{#reports} personagens gerados em {output}`)
for _, item in summary do
	local r = item.report
	print(string.format("  %-22s %-5s %3d -> %3d peças  %s", r.CharacterId, r.status, r.originalParts, r.sanitizedParts, table.concat(r.problems, "; ")))
end
print(`Relatório: {reportMd}`)
print(`Roupas: {clothingMd} ({#assetOrder} AssetId(s), {counts.REVIEW_REQUIRED} para revisão)`)
process.exit(if failed > 0 then 2 else 0)
