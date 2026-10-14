--[[
	Auditoria do "Auras Pack Not mine!" (Creator Store 15374038687) — NÃO executa nada do pack.
	    lune run tools/packaudit/audit_auras.luau third_party/AurasPack.rbxm
	(ou: python3 tools/audit_auras_pack.py)
	Lista a hierarquia por classe, TODO código executável (só nome/caminho/tamanho — nunca roda),
	remotes/bindables, sons/animações, constraints/body movers, malhas e texturas externas, e
	avalia cada efeito visual (ParticleEmitter/Beam/Trail) por PRESENÇA (taxa × vida × tamanho),
	separando os fortes dos fracos. Gera:
	    AURAS_PACK_AUDIT.md                       relatório
	    third_party/AurasPack_components.json     parâmetros dos componentes visuais (dados, sem código)
	O jogo NÃO depende deste pack em runtime: o sistema de auras é o AuraConfig/AuraBuilder.
]]
local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")

local file = process.args[1] or "third_party/AurasPack.rbxm"
if not fs.isFile(file) then
	print("arquivo não encontrado: " .. file)
	print("No Studio: botão direito no modelo do Auras Pack > Save to File... > " .. file)
	process.exit(1)
end
local bytes = fs.readFile(file)
local ok, roots = pcall(roblox.deserializeModel, bytes)
if not ok then
	local place = roblox.deserializePlace(bytes)
	roots = place:GetService("Workspace"):GetChildren()
end

local EXEC = { Script = true, LocalScript = true, ModuleScript = true }
local NET = { RemoteEvent = true, RemoteFunction = true, UnreliableRemoteEvent = true, BindableEvent = true, BindableFunction = true }
local MOVERS = {
	BodyVelocity = true, BodyPosition = true, BodyGyro = true, BodyForce = true, BodyAngularVelocity = true, BodyThrust = true,
	RocketPropulsion = true, LinearVelocity = true, AngularVelocity = true, AlignPosition = true, AlignOrientation = true, VectorForce = true, Torque = true,
}
local VISUAL = { ParticleEmitter = true, Beam = true, Trail = true, Attachment = true, Fire = true, Smoke = true, Sparkles = true, PointLight = true, SpotLight = true, SurfaceLight = true, Highlight = true }

local classes, executable, network, movers, constraints, sounds, animations, external = {}, {}, {}, {}, {}, {}, {}, {}
local components = {}

local function path(inst: any): string
	local parts = {}
	local node = inst
	while node do
		table.insert(parts, 1, node.Name)
		node = node.Parent
	end
	return table.concat(parts, ".")
end

local function seqAvg(seq: any): number
	local ok2, kps = pcall(function()
		return seq.Keypoints
	end)
	if not ok2 or not kps then
		return 0
	end
	local total = 0
	for _, kp in kps do
		total += kp.Value
	end
	return total / math.max(1, #kps)
end

local function read(inst: any, prop: string): any
	local ok2, value = pcall(function()
		return inst[prop]
	end)
	return if ok2 then value else nil
end

local function visit(inst: any)
	local cls = inst.ClassName
	classes[cls] = (classes[cls] or 0) + 1
	if EXEC[cls] then
		local source = read(inst, "Source") or ""
		table.insert(executable, { path = path(inst), class = cls, bytes = #source })
	elseif NET[cls] then
		table.insert(network, path(inst) .. " (" .. cls .. ")")
	elseif MOVERS[cls] then
		table.insert(movers, path(inst) .. " (" .. cls .. ")")
	elseif string.find(cls, "Constraint", 1, true) or cls == "Weld" or cls == "WeldConstraint" or cls == "Motor6D" then
		table.insert(constraints, path(inst) .. " (" .. cls .. ")")
	elseif cls == "Sound" then
		table.insert(sounds, path(inst) .. " = " .. tostring(read(inst, "SoundId")))
	elseif cls == "Animation" then
		table.insert(animations, path(inst) .. " = " .. tostring(read(inst, "AnimationId")))
	end
	for _, prop in { "Texture", "MeshId", "TextureID", "TextureId", "SoundId", "AnimationId" } do
		local v = read(inst, prop)
		if type(v) == "string" and v ~= "" and not string.find(v, "^rbxasset://") then
			external[v] = (external[v] or 0) + 1
		end
	end
	if cls == "ParticleEmitter" then
		local rate = read(inst, "Rate") or 0
		local life = read(inst, "Lifetime")
		local lifeMax = if life then life.Max else 0
		local size = seqAvg(read(inst, "Size"))
		local transparency = seqAvg(read(inst, "Transparency"))
		local presence = rate * lifeMax * size * (1 - math.clamp(transparency, 0, 1))
		table.insert(components, {
			path = path(inst),
			class = cls,
			texture = read(inst, "Texture"),
			rate = rate,
			lifetime = lifeMax,
			size = size,
			transparency = transparency,
			speed = (read(inst, "Speed") or { Max = 0 }).Max,
			lightEmission = read(inst, "LightEmission"),
			presence = presence,
		})
	elseif cls == "Beam" or cls == "Trail" then
		table.insert(components, { path = path(inst), class = cls, texture = read(inst, "Texture"), presence = 5, lightEmission = read(inst, "LightEmission") })
	end
	for _, child in inst:GetChildren() do
		visit(child)
	end
end

for _, root in roots do
	visit(root)
end

table.sort(components, function(a, b)
	return (a.presence or 0) > (b.presence or 0)
end)
local strong, weak = 0, 0
for _, c in components do
	if (c.presence or 0) >= 8 then
		strong += 1
	else
		weak += 1
	end
end

local out = {}
local function line(t: string?)
	table.insert(out, t or "")
end
line("# Auditoria — Auras Pack (\"Not mine!\", Creator Store 15374038687)")
line()
line("> Gerado por `python3 tools/audit_auras_pack.py` sem executar nada do pack. O nome do asset diz")
line("> \"Not mine\": proveniência/direito de uso NÃO confirmados. O jogo não depende dele em runtime.")
line()
line("## Classes")
line()
line("| Classe | Quantidade |")
line("|---|---|")
local names = {}
for cls in classes do
	table.insert(names, cls)
end
table.sort(names)
for _, cls in names do
	line(`| {cls} | {classes[cls]} |`)
end
local function list(title: string, items: { any }, fmt: ((any) -> string)?)
	line()
	line(`## {title} ({#items})`)
	line()
	if #items == 0 then
		line("Nenhum.")
	end
	for _, item in items do
		line("- " .. (if fmt then fmt(item) else tostring(item)))
	end
end
list("Código executável (REMOVER/IGNORAR — nunca copiado)", executable, function(e)
	return `{e.path} ({e.class}, {e.bytes} bytes)`
end)
list("Remotes / Bindables", network)
list("Body movers", movers)
list("Constraints / welds", constraints)
list("Sons", sounds)
list("Animações", animations)
local ext = {}
for id, n in external do
	table.insert(ext, `{id} ×{n}`)
end
table.sort(ext)
list("Assets externos referenciados (texturas/malhas)", ext)
line()
line(`## Componentes visuais: {strong} fortes, {weak} fracos (presença = taxa × vida × tamanho × opacidade)`)
line()
line("| Presença | Classe | Caminho | Taxa | Vida | Tamanho |")
line("|---|---|---|---|---|---|")
for i, c in components do
	if i > 40 then
		break
	end
	line(string.format("| %.1f | %s | %s | %s | %s | %s |", c.presence or 0, c.class, c.path, tostring(c.rate or "—"), tostring(c.lifetime or "—"), tostring(c.size or "—")))
end
line()
line("Uso: só PARÂMETROS e conceitos (densidade, direção, camadas) servem de referência para o")
line("AuraConfig. Texturas do pack só entram depois de confirmar o direito de uso; até lá o jogo usa")
line("apenas texturas nativas do Roblox.")
fs.writeFile("AURAS_PACK_AUDIT.md", table.concat(out, "\n") .. "\n")
fs.writeDir("third_party")
fs.writeFile("third_party/AurasPack_components.json", serde.encode("json", components, true))
print(`AURAS_PACK_AUDIT.md: {#executable} scripts, {#network} remotes/bindables, {#components} componentes visuais ({strong} fortes)`)
