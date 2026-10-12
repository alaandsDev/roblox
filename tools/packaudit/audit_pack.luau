--[[
	Auditoria de um pack de personagens exportado do Studio (NÃO executa scripts do pack).
	    lune run tools/packaudit/audit_pack.luau third_party/AnimePack.rbxm
	Aceita o pack salvo sozinho (.rbxm/.rbxmx) ou um place inteiro (.rbxl/.rbxlx): neste caso
	usa Workspace["Anime Pack"].
	Gera (todos pequenos, podem ir para o Git):
	    ANIME_PACK_AUDIT.md                  relatório
	    third_party/AnimePack_summary.json   resumo por personagem
	    third_party/AnimePack_scripts.txt    código de TODOS os scripts, como texto
]]
local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local PackAudit = require("./PackAudit")

local PACK_NAME = "Anime Pack"
local file = process.args[1] or "third_party/AnimePack.rbxm"
if not fs.isFile(file) then
	print("arquivo não encontrado: " .. file)
	print("No Studio: botão direito em Workspace > Anime Pack > Save to File... > " .. file)
	process.exit(1)
end
local bytes = fs.readFile(file)
local roots
local ok, model = pcall(roblox.deserializeModel, bytes)
if ok then
	roots = model
else
	local place = roblox.deserializePlace(bytes)
	local pack = place:GetService("Workspace"):FindFirstChild(PACK_NAME)
	if not pack then
		print("place sem Workspace." .. PACK_NAME)
		process.exit(1)
	end
	roots = { pack }
end
-- Se o arquivo tiver mais coisas, foca na pasta "Anime Pack"
for _, root in roots do
	local found = if root.Name == PACK_NAME then root else root:FindFirstChild(PACK_NAME, true)
	if found then
		roots = { found }
		break
	end
end

local report = PackAudit.audit(roots)
fs.writeFile("ANIME_PACK_AUDIT.md", PackAudit.markdown(report, PACK_NAME, "14679137059", file))
fs.writeDir("third_party")
fs.writeFile("third_party/AnimePack_summary.json", serde.encode("json", PackAudit.summary(report), true))
fs.writeFile("third_party/AnimePack_scripts.txt", PackAudit.scriptDump(roots))
print(string.format("%s: %d instâncias, %d personagens, %d scripts, %d grupos de formas",
	file, report.totalInstances, #report.characters, #report.scripts, #report.forms))
print("Gerados: ANIME_PACK_AUDIT.md, third_party/AnimePack_summary.json, third_party/AnimePack_scripts.txt")
