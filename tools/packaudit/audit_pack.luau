--[[
	Auditoria de um pack de personagens exportado do Studio (NÃO executa scripts do pack).
	    tools/bin/lune-0.10.4/lune run tools/packaudit/audit_pack.luau third_party/AnimePack.rbxm
	Gera ANIME_PACK_AUDIT.md na raiz do projeto.
]]
local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local PackAudit = require("./PackAudit")

local file = process.args[1] or "third_party/AnimePack.rbxm"
local output = process.args[2] or "ANIME_PACK_AUDIT.md"
if not fs.isFile(file) then
	print("arquivo não encontrado: " .. file)
	print("No Studio: clique com o botão direito no pack > Save to File... > salve em " .. file)
	process.exit(1)
end
local bytes = fs.readFile(file)
local ok, roots = pcall(roblox.deserializeModel, bytes)
if not ok then
	-- também aceita um place inteiro (.rbxl/.rbxlx): audita o DataModel todo
	roots = roblox.deserializePlace(bytes):GetChildren()
end
local report = PackAudit.audit(roots)
fs.writeFile(output, PackAudit.markdown(report, "Anime Pack", "14679137059", file))
print(string.format("%s: %d personagens, %d scripts -> %s", file, #report.characters, #report.scripts, output))
