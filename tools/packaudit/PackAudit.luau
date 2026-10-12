--[[
	PackAudit (Lune): audita um pack de personagens exportado do Studio (.rbxm/.rbxmx) SEM
	EXECUTAR NADA. O arquivo é só desserializado (lido como dados); o código dos scripts é lido
	como TEXTO para procurar padrões perigosos. Nada é instalado no jogo.

	    local PackAudit = require("./PackAudit")
	    local report = PackAudit.audit(roots)        -- roots = { Instance }
	    local markdown = PackAudit.markdown(report, "Anime Pack", "14679137059")

	As notas de qualidade e a sugestão de raridade são HEURÍSTICAS (contagem de malhas, texturas,
	acessórios, VFX...). A decisão final de raridade precisa de olho humano no Studio.
]]

local PackAudit = {}

------------------------------------------------------------------------------------
-- Utilidades

local function path(instance): string
	local parts = {}
	local current = instance
	while current do
		table.insert(parts, 1, current.Name)
		current = current.Parent
	end
	return table.concat(parts, ".")
end

local function prop(instance, name): any
	local ok, value = pcall(function()
		return instance[name]
	end)
	return if ok then value else nil
end

local function isA(instance, className: string): boolean
	local ok, result = pcall(function()
		return instance:IsA(className)
	end)
	return ok and result
end

local function descendants(root): { any }
	local out = {}
	local function walk(node)
		for _, child in node:GetChildren() do
			table.insert(out, child)
			walk(child)
		end
	end
	walk(root)
	return out
end

local function lower(text: any): string
	return string.lower(tostring(text or ""))
end

local function assetId(content: any): string?
	local text = tostring(content or "")
	if text == "" or text == "Content(None)" or string.match(text, "^Content%(Uri=%)$") then
		return nil
	end
	return string.match(text, "(%d+)") or (if string.sub(text, 1, 8) == "Content(" then nil else text)
end

-- Arquivos novos guardam ids em propriedades *Content (MeshContent, TextureContent...)
local function contentOf(instance, names: { string }): string?
	for _, name in names do
		local ok, value = pcall(function()
			return instance[name]
		end)
		local id = ok and assetId(value) or nil
		if id then
			return id
		end
	end
	return nil
end
local MESH = { "MeshId", "MeshContent" }
local MESH_TEXTURE = { "TextureID", "TextureId", "TextureContent" }
local DECAL_TEXTURE = { "Texture", "TextureContent", "ColorMapContent" }

------------------------------------------------------------------------------------
-- Scripts: padrões procurados no TEXTO do código (nunca executado)

PackAudit.ScriptRules = {
	{ id = "remote_require", level = "ALTO", pattern = "require%s*%(%s*%d+", text = "require(<id numérico>): baixa e roda código de fora do jogo (backdoor clássico)" },
	{ id = "loadstring", level = "ALTO", pattern = "loadstring", text = "loadstring: executa texto como código" },
	{ id = "fenv", level = "ALTO", pattern = "[gs]etfenv", text = "getfenv/setfenv: manipula o ambiente (comum em ofuscação)" },
	{ id = "http", level = "ALTO", pattern = "HttpService", text = "HttpService: comunicação com servidores externos" },
	{ id = "insert", level = "ALTO", pattern = "InsertService", text = "InsertService: insere assets em tempo de execução" },
	{ id = "teleport", level = "ALTO", pattern = "TeleportService", text = "TeleportService: pode mandar jogadores para outro jogo" },
	{ id = "market", level = "ALTO", pattern = "MarketplaceService", text = "MarketplaceService: pode abrir janelas de compra" },
	{ id = "kick", level = "ALTO", pattern = ":%s*Kick%s*%(", text = "Kick: expulsa jogadores" },
	{ id = "obfuscated", level = "ALTO", pattern = "\\%d%d%d?\\%d%d%d?\\%d%d%d?", text = "sequências \\ddd: texto ofuscado" },
	{ id = "string_char", level = "MÉDIO", pattern = "string%.char", text = "string.char: monta texto escondido (pode ser ofuscação)" },
	{ id = "remotes", level = "MÉDIO", pattern = "Remote[EF][vu][en][nc]", text = "RemoteEvent/RemoteFunction: abre canal cliente/servidor" },
	{ id = "players", level = "MÉDIO", pattern = "Players", text = "acessa Players" },
	{ id = "datastore", level = "MÉDIO", pattern = "DataStoreService", text = "DataStoreService: grava dados" },
	{ id = "chat", level = "MÉDIO", pattern = "Chat", text = "acessa Chat/TextChat" },
	{ id = "clone_loop", level = "MÉDIO", pattern = "while%s+true", text = "loop infinito (custo de desempenho)" },
	{ id = "animation", level = "BAIXO", pattern = "LoadAnimation", text = "toca animações" },
	{ id = "tween", level = "BAIXO", pattern = "TweenService", text = "TweenService: efeito visual/movimento" },
	{ id = "particles", level = "BAIXO", pattern = "ParticleEmitter", text = "controla partículas" },
}

local function guessPurpose(script, source: string): string
	local name = lower(script.Name)
	local src = lower(source)
	if name == "animate" then
		return "Animate padrão do Roblox (andar/pular/idle)"
	elseif string.find(src, "loadanimation") or string.find(src, ":play%(") then
		return "toca animação"
	elseif string.find(src, "particleemitter") or string.find(src, ":emit%(") then
		return "efeito visual (partículas)"
	elseif string.find(src, "tweenservice") or string.find(src, "cframe%.angles") or string.find(src, "rotate") then
		return "movimento/rotação decorativa"
	elseif string.find(src, "health") or string.find(src, "damage") or string.find(src, "takedamage") then
		return "combate/dano (lógica de arma)"
	elseif string.find(src, "tool") and (string.find(src, "activated") or string.find(src, "equipped")) then
		return "lógica de ferramenta/arma"
	elseif source == "" then
		return "vazio"
	end
	return "não identificada (ler manualmente)"
end

local function auditScript(script): any
	local source = tostring(prop(script, "Source") or "")
	local flags = {}
	local worst = "NENHUM"
	local rank = { NENHUM = 0, BAIXO = 1, ["MÉDIO"] = 2, ALTO = 3 }
	for _, rule in PackAudit.ScriptRules do
		if string.find(source, rule.pattern) then
			table.insert(flags, rule)
			if rank[rule.level] > rank[worst] then
				worst = rule.level
			end
		end
	end
	local longest = 0
	for lineText in string.gmatch(source .. "\n", "(.-)\n") do
		longest = math.max(longest, #lineText)
	end
	if longest > 1000 then
		table.insert(flags, { id = "long_line", level = "ALTO", text = string.format("linha com %d caracteres (código ofuscado/minificado)", longest) })
		worst = "ALTO"
	end
	local _, lineCount = string.gsub(source, "\n", "")
	local purpose = guessPurpose(script, source)
	local visualOnly = worst ~= "ALTO" and (purpose == "Animate padrão do Roblox (andar/pular/idle)" or purpose == "toca animação" or purpose == "efeito visual (partículas)" or purpose == "movimento/rotação decorativa" or purpose == "vazio")
	return {
		path = path(script),
		name = script.Name,
		className = script.ClassName,
		disabled = prop(script, "Disabled") == true or prop(script, "Enabled") == false,
		lines = lineCount + (if source ~= "" then 1 else 0),
		bytes = #source,
		risk = worst,
		flags = flags,
		purpose = purpose,
		visualOnly = visualOnly,
		-- Para o Roll Legends: nenhum script de terceiros entra no jogo final
		removable = true,
	}
end

------------------------------------------------------------------------------------
-- Personagens

local R15_PARTS = { "UpperTorso", "LowerTorso", "LeftUpperArm", "RightUpperArm", "LeftUpperLeg", "RightUpperLeg", "LeftHand", "RightFoot" }
local R6_PARTS = { "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg" }
local WEAPON_WORDS = { "sword", "katana", "blade", "gun", "pistol", "rifle", "weapon", "staff", "scythe", "spear", "axe", "bow", "dagger", "hammer", "lance", "knife", "sabre", "saber", "wand", "shield", "fist", "claw", "zanpakuto", "odachi" }
local VFX_CLASSES = { "ParticleEmitter", "Beam", "Trail", "Fire", "Smoke", "Sparkles", "PointLight", "SpotLight", "SurfaceLight", "Highlight" }

local function isCharacter(model): boolean
	if not isA(model, "Model") then
		return false
	end
	return model:FindFirstChildOfClass("Humanoid") ~= nil
		or model:FindFirstChildOfClass("AnimationController") ~= nil
		or model:FindFirstChild("HumanoidRootPart") ~= nil
end

function PackAudit.findCharacters(roots: { any }): { any }
	local found = {}
	local function walk(node)
		if isCharacter(node) then
			table.insert(found, node)
			return -- não procura personagens dentro de personagens
		end
		for _, child in node:GetChildren() do
			walk(child)
		end
	end
	for _, root in roots do
		walk(root)
	end
	return found
end

local function rigOf(model, humanoid): string
	local rigType = humanoid and prop(humanoid, "RigType")
	local hasR15, hasR6 = 0, 0
	for _, name in R15_PARTS do
		if model:FindFirstChild(name, true) then
			hasR15 += 1
		end
	end
	for _, name in R6_PARTS do
		if model:FindFirstChild(name, true) then
			hasR6 += 1
		end
	end
	if hasR15 >= 6 then
		return "R15"
	elseif hasR6 >= 4 then
		return "R6"
	elseif rigType then
		return "custom (RigType " .. tostring(rigType) .. ")"
	end
	return "custom"
end

local function auditCharacter(model): any
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local all = descendants(model)
	local c = {
		name = model.Name,
		path = path(model),
		rig = rigOf(model, humanoid),
		humanoid = humanoid ~= nil,
		animationController = model:FindFirstChildOfClass("AnimationController") ~= nil,
		parts = 0,
		meshParts = 0,
		specialMeshes = 0,
		meshIds = {},
		textureIds = {},
		accessories = {},
		hair = {},
		shirt = nil,
		pants = nil,
		tshirt = nil,
		face = nil,
		faceControls = false,
		decals = 0,
		textures = 0,
		surfaceAppearance = 0,
		weapons = {},
		tools = 0,
		vfx = {},
		animations = {},
		scripts = {},
		motors = 0,
		anchoredParts = 0,
		problems = {},
	}
	local meshSet, texSet = {}, {}
	for _, d in all do
		local cls = d.ClassName
		if isA(d, "BasePart") then
			c.parts += 1
			if prop(d, "Anchored") then
				c.anchoredParts += 1
			end
		end
		if cls == "MeshPart" then
			c.meshParts += 1
			local id = contentOf(d, MESH)
			if id then
				meshSet[id] = true
			end
			local tex = contentOf(d, MESH_TEXTURE)
			if tex then
				texSet[tex] = true
			end
		elseif cls == "SpecialMesh" then
			c.specialMeshes += 1
			local id = contentOf(d, MESH)
			if id then
				meshSet[id] = true
			end
			local tex = contentOf(d, MESH_TEXTURE)
			if tex then
				texSet[tex] = true
			end
		elseif cls == "Accessory" or cls == "Hat" then
			local accessoryType = tostring(prop(d, "AccessoryType") or "")
			table.insert(c.accessories, d.Name)
			if string.find(lower(d.Name), "hair") or string.find(lower(accessoryType), "hair") then
				table.insert(c.hair, d.Name)
			end
		elseif cls == "Shirt" then
			c.shirt = contentOf(d, { "ShirtTemplate", "ShirtTemplateContent" }) or d.Name
		elseif cls == "Pants" then
			c.pants = contentOf(d, { "PantsTemplate", "PantsTemplateContent" }) or d.Name
		elseif cls == "ShirtGraphic" then
			c.tshirt = contentOf(d, { "Graphic", "GraphicContent" }) or d.Name
		elseif cls == "Decal" then
			c.decals += 1
			if lower(d.Name) == "face" or (d.Parent and d.Parent.Name == "Head") then
				c.face = contentOf(d, DECAL_TEXTURE) or d.Name
			end
			local tex = contentOf(d, DECAL_TEXTURE)
			if tex then
				texSet[tex] = true
			end
		elseif cls == "Texture" then
			c.textures += 1
		elseif cls == "SurfaceAppearance" then
			c.surfaceAppearance += 1
		elseif cls == "FaceControls" then
			c.faceControls = true
		elseif cls == "Tool" then
			c.tools += 1
			table.insert(c.weapons, d.Name .. " (Tool)")
		elseif cls == "Motor6D" then
			c.motors += 1
		elseif cls == "Animation" then
			table.insert(c.animations, d.Name .. " = " .. tostring(contentOf(d, { "AnimationId" }) or "?"))
		elseif cls == "KeyframeSequence" then
			table.insert(c.animations, d.Name .. " (KeyframeSequence local)")
		elseif cls == "Script" or cls == "LocalScript" or cls == "ModuleScript" then
			table.insert(c.scripts, auditScript(d))
		end
		if table.find(VFX_CLASSES, cls) then
			table.insert(c.vfx, cls .. " " .. d.Name)
		end
		if cls ~= "Tool" and (isA(d, "BasePart") or isA(d, "Model") or cls == "Accessory") then
			local n = lower(d.Name)
			for _, word in WEAPON_WORDS do
				if string.find(n, word, 1, true) then
					table.insert(c.weapons, d.Name .. " (pelo nome)")
					break
				end
			end
		end
	end
	for id in meshSet do
		table.insert(c.meshIds, id)
	end
	for id in texSet do
		table.insert(c.textureIds, id)
	end
	table.sort(c.meshIds)
	table.sort(c.textureIds)
	-- Rosto por malha (cabeça MeshPart com textura) quando não há decal
	if not c.face then
		local head = model:FindFirstChild("Head")
		if head and head.ClassName == "MeshPart" and contentOf(head, MESH_TEXTURE) then
			c.face = "textura da cabeça (MeshPart)"
		elseif c.faceControls then
			c.face = "FaceControls (rosto dinâmico)"
		end
	end

	-- Problemas para o Roll Legends
	if not model:FindFirstChild("HumanoidRootPart") then
		table.insert(c.problems, "sem HumanoidRootPart (precisa de âncora para posicionar no pedestal)")
	end
	if c.parts > 120 then
		table.insert(c.problems, string.format("%d peças: pesado para 400 personagens na tela", c.parts))
	end
	if #c.vfx > 6 then
		table.insert(c.problems, string.format("%d efeitos de VFX: precisa de LOD/ReducedEffects", #c.vfx))
	end
	if #c.scripts > 0 then
		table.insert(c.problems, string.format("%d script(s) de terceiros (remover)", #c.scripts))
	end
	for _, s in c.scripts do
		if s.risk == "ALTO" then
			table.insert(c.problems, "script de risco ALTO: " .. s.path)
		end
	end
	if c.rig:sub(1, 6) == "custom" and c.motors == 0 then
		table.insert(c.problems, "rig sem Motor6D (estático; não anima)")
	end
	if c.meshParts + c.specialMeshes == 0 and not c.shirt and #c.accessories == 0 then
		table.insert(c.problems, "visual muito simples (sem malhas, roupas ou acessórios)")
	end

	-- Nota de qualidade (0–100), só heurística
	local score = 0
	score += math.min(30, #c.meshIds * 3)
	score += math.min(20, #c.textureIds * 3)
	score += math.min(15, #c.accessories * 3)
	score += if c.shirt or c.pants then 8 else 0
	score += if c.face then 7 else 0
	score += if c.surfaceAppearance > 0 then 5 else 0
	score += math.min(10, #c.vfx * 2)
	score += if #c.weapons > 0 then 5 else 0
	c.score = math.min(100, score)
	local scriptProblems = 0
	for _, problem in c.problems do
		if string.find(problem, "script", 1, true) then
			scriptProblems += 1
		end
	end
	c.compatibility = if #c.problems == 0 then "ALTA"
		elseif #c.problems == scriptProblems then "ALTA depois de remover scripts"
		else "MÉDIA (corrigir: ver problemas)"
	return c
end

------------------------------------------------------------------------------------
-- Categorias (pastas do pack: DBZ, NARUTO...) e formas/transformações

-- Pasta logo abaixo da raiz do pack onde o personagem está ("(raiz)" se estiver solto)
function PackAudit.categoryOf(model, roots: { any }): string
	-- (instâncias do Lune não servem como chave de tabela: compara com ==)
	local function isRoot(node): boolean
		for _, root in roots do
			if node == root then
				return true
			end
		end
		return false
	end
	local current = model
	while current.Parent and not isRoot(current.Parent) do
		current = current.Parent
	end
	if current == model or isRoot(current) or not current.Parent then
		return "(raiz)"
	end
	return current.Name
end

-- Palavras que indicam forma/transformação/versão (removidas para achar o "nome base")
PackAudit.FormWords = {
	"ssj", "ssj1", "ssj2", "ssj3", "ssj4", "ssjb", "ssjg", "ssgss", "ssg", "ssb", "ssr", "lssj", "super", "saiyan", "saiyajin",
	"ultra", "instinct", "ui", "mui", "base", "form", "forma", "mode", "modo", "sage", "kyuubi", "kurama", "chakra",
	"bankai", "shikai", "hollow", "hollowfied", "vasto", "lorde", "resurreccion", "gear", "awakened", "awakening",
	"awaken", "transformed", "transformation", "final", "full", "power", "god", "blue", "rose", "golden", "gold",
	"black", "evil", "dark", "kid", "young", "old", "adult", "teen", "child", "armor", "armored", "titan", "dragon",
	"force", "etherion", "release", "released", "susanoo", "rinnegan", "sharingan", "mangekyo", "six", "paths",
	"baryon", "boss", "rage", "berserk", "true", "perfect", "imperfect", "max", "mk", "alt", "alternate", "skin",
	"outfit", "costume", "version", "ver", "v", "ii", "iii", "iv", "the", "of", "and",
}
local formWordSet = {}
for _, word in PackAudit.FormWords do
	formWordSet[word] = true
end

function PackAudit.baseName(name: string): string
	local text = string.lower(name)
	text = string.gsub(text, "[%(%)%[%]{}_%-%.,:/|]", " ")
	text = string.gsub(text, "(%a)(%d)", "%1 %2")
	text = string.gsub(text, "(%d)(%a)", "%1 %2")
	local kept = {}
	for word in string.gmatch(text, "%S+") do
		if not formWordSet[word] and not string.match(word, "^%d+$") then
			table.insert(kept, word)
		end
	end
	return table.concat(kept, " ")
end

-- Grupos com 2+ modelos que parecem o mesmo personagem (mesma categoria + mesmo nome base,
-- ou mesma roupa/rosto). Só pistas: confirmar no Studio.
function PackAudit.forms(characters: { any }): { any }
	local groups: { [string]: { any } } = {}
	local order = {}
	for _, c in characters do
		local base = PackAudit.baseName(c.name)
		if base == "" then
			base = string.lower(c.name)
		end
		c.baseName = base
		local key = c.category .. "|" .. base
		if not groups[key] then
			groups[key] = {}
			table.insert(order, key)
		end
		table.insert(groups[key], c)
	end
	local out = {}
	for _, key in order do
		local members = groups[key]
		if #members >= 2 then
			local names = {}
			for _, c in members do
				table.insert(names, c.name)
				c.formGroup = members[1].baseName
			end
			table.insert(out, { category = members[1].category, base = members[1].baseName, members = names, reason = "nome" })
		end
	end
	-- Mesma roupa (Shirt+Pants) ou mesmo rosto em nomes diferentes
	local byLook: { [string]: { any } } = {}
	for _, c in characters do
		if c.shirt or c.face then
			local look = tostring(c.shirt) .. "|" .. tostring(c.pants) .. "|" .. tostring(c.face)
			byLook[look] = byLook[look] or {}
			table.insert(byLook[look], c)
		end
	end
	for _, members in byLook do
		if #members >= 2 then
			local sameBase = true
			for _, c in members do
				if c.baseName ~= members[1].baseName then
					sameBase = false
				end
			end
			if not sameBase then
				local names = {}
				for _, c in members do
					table.insert(names, c.name)
				end
				table.sort(names)
				table.insert(out, { category = members[1].category, base = members[1].baseName, members = names, reason = "mesma roupa/rosto" })
			end
		end
	end
	table.sort(out, function(a, b)
		if a.category ~= b.category then
			return a.category < b.category
		end
		return a.base < b.base
	end)
	return out
end

-- Texto com o código de TODOS os scripts (só para leitura humana; nunca executado)
function PackAudit.scriptDump(roots: { any }): string
	local out = {}
	local function walk(node)
		if node.ClassName == "Script" or node.ClassName == "LocalScript" or node.ClassName == "ModuleScript" then
			local info = auditScript(node)
			table.insert(out, string.rep("=", 80))
			table.insert(out, string.format("%s  [%s]  risco %s  linhas %d", info.path, info.className, info.risk, info.lines))
			table.insert(out, string.rep("=", 80))
			table.insert(out, tostring(prop(node, "Source") or ""))
			table.insert(out, "")
		end
		for _, child in node:GetChildren() do
			walk(child)
		end
	end
	for _, root in roots do
		walk(root)
	end
	return table.concat(out, "\n")
end

-- Resumo compacto (JSON) para análise fora do Studio
function PackAudit.summary(report: any): any
	local characters = {}
	for _, c in report.characters do
		table.insert(characters, {
			name = c.name, category = c.category, path = c.path, rig = c.rig, score = c.score,
			parts = c.parts, meshParts = c.meshParts, specialMeshes = c.specialMeshes, meshIds = #c.meshIds,
			-- listas completas: permitem provar duplicatas exatas (mesmas malhas/texturas)
			meshIdList = c.meshIds, textureIdList = c.textureIds,
			textureIds = #c.textureIds, accessories = c.accessories, hair = c.hair, shirt = c.shirt, pants = c.pants,
			face = c.face, weapons = c.weapons, vfx = c.vfx, animations = c.animations, motors = c.motors,
			humanoid = c.humanoid, animationController = c.animationController, surfaceAppearance = c.surfaceAppearance,
			scripts = #c.scripts, problems = c.problems, compatibility = c.compatibility, formGroup = c.formGroup,
		})
	end
	local scripts = {}
	for _, s in report.scripts do
		local flags = {}
		for _, f in s.flags do
			table.insert(flags, f.id)
		end
		table.insert(scripts, { path = s.path, class = s.className, risk = s.risk, purpose = s.purpose, lines = s.lines, disabled = s.disabled, flags = flags })
	end
	return { totalInstances = report.totalInstances, classes = report.classes, rigs = report.rigs, categories = report.categories, forms = report.forms, characters = characters, scripts = scripts }
end

------------------------------------------------------------------------------------
-- Relatório

function PackAudit.audit(roots: { any }): any
	local report = { characters = {}, scripts = {}, classes = {}, totalInstances = 0, looseScripts = {} }
	for _, root in roots do
		local all = descendants(root)
		table.insert(all, 1, root)
		for _, d in all do
			report.totalInstances += 1
			report.classes[d.ClassName] = (report.classes[d.ClassName] or 0) + 1
			if d.ClassName == "Script" or d.ClassName == "LocalScript" or d.ClassName == "ModuleScript" then
				table.insert(report.scripts, auditScript(d))
			end
		end
	end
	for _, model in PackAudit.findCharacters(roots) do
		local c = auditCharacter(model)
		c.category = PackAudit.categoryOf(model, roots)
		table.insert(report.characters, c)
	end
	report.forms = PackAudit.forms(report.characters)
	report.categories = {}
	for _, c in report.characters do
		report.categories[c.category] = (report.categories[c.category] or 0) + 1
	end
	table.sort(report.scripts, function(a, b)
		return a.path < b.path
	end)
	-- Rigs predominantes
	local rigs = {}
	for _, c in report.characters do
		rigs[c.rig] = (rigs[c.rig] or 0) + 1
	end
	report.rigs = rigs
	-- Sugestão de raridade por nota (8 faixas, melhor = Secreto). Só recomendação visual.
	local ranked = table.clone(report.characters)
	table.sort(ranked, function(a, b)
		if a.score ~= b.score then
			return a.score > b.score
		end
		return a.name < b.name
	end)
	local tiers = { "Secret", "Divine", "Mythic", "Legendary", "Epic", "Rare", "Uncommon", "Common" }
	local quota = { Secret = 1, Divine = 2, Mythic = 2, Legendary = 3, Epic = 3, Rare = 4, Uncommon = 4, Common = 5 } -- = roster atual (24)
	local index = 1
	for _, tier in tiers do
		for _ = 1, quota[tier] do
			local c = ranked[index]
			if c then
				c.suggestedRarity = tier
				index += 1
			end
		end
	end
	report.ranked = ranked
	return report
end

local function list(items: { string }, empty: string?): string
	if #items == 0 then
		return empty or "—"
	end
	local shown = {}
	for i = 1, math.min(6, #items) do
		shown[i] = items[i]
	end
	return table.concat(shown, ", ") .. (if #items > 6 then string.format(" (+%d)", #items - 6) else "")
end

function PackAudit.markdown(report: any, packName: string, assetIdText: string, sourceFile: string): string
	local out = {}
	local function line(text: string?)
		table.insert(out, text or "")
	end
	line("# ANIME_PACK_AUDIT — " .. packName .. " (asset " .. assetIdText .. ")")
	line()
	line("> Gerado por `tools/packaudit/audit_pack.luau` a partir de `" .. sourceFile .. "`.")
	line("> O arquivo foi só **lido** (desserializado): nenhum script do pack foi executado.")
	line("> Notas de qualidade e raridades sugeridas são heurísticas — confirmar visualmente no Studio.")
	line()
	line("## Resumo")
	line()
	line(string.format("- Instâncias no pack: **%d**", report.totalInstances))
	line(string.format("- Personagens/modelos encontrados: **%d**", #report.characters))
	local rigText = {}
	for rig, n in report.rigs do
		table.insert(rigText, rig .. ": " .. n)
	end
	table.sort(rigText)
	line("- Rigs: " .. (if #rigText > 0 then table.concat(rigText, " · ") else "—"))
	line(string.format("- Scripts (Script/LocalScript/ModuleScript): **%d**", #report.scripts))
	local classNames = {}
	for name in report.classes do
		table.insert(classNames, name)
	end
	table.sort(classNames)
	local classText = {}
	for _, name in classNames do
		table.insert(classText, name .. " " .. report.classes[name])
	end
	line("- Classes: " .. table.concat(classText, ", "))
	line()

	local categoryNames = {}
	for name in report.categories or {} do
		table.insert(categoryNames, name)
	end
	table.sort(categoryNames)
	line("## Categorias")
	line()
	line("| Categoria | Personagens |")
	line("|---|---:|")
	for _, name in categoryNames do
		line(string.format("| %s | %d |", name, report.categories[name]))
	end
	line()
	line("## Formas / transformações (mesmo personagem em versões diferentes — pistas, confirmar no Studio)")
	line()
	if #(report.forms or {}) == 0 then
		line("Nenhum grupo encontrado pelos nomes/roupas.")
	else
		line("| Categoria | Personagem base | Versões | Pista |")
		line("|---|---|---|---|")
		for _, group in report.forms do
			line(string.format("| %s | %s | %s | %s |", group.category, group.base, table.concat(group.members, ", "), group.reason))
		end
	end
	line()

	line("## 1. Segurança — todos os scripts")
	line()
	if #report.scripts == 0 then
		line("Nenhum Script/LocalScript/ModuleScript no pack.")
	else
		line("| Caminho | Classe | Linhas | Risco | Função aparente | Só visual? | Remover? | Padrões encontrados |")
		line("|---|---|---:|---|---|---|---|---|")
		for _, s in report.scripts do
			local flags = {}
			for _, f in s.flags do
				table.insert(flags, f.level .. ": " .. f.text)
			end
			line(string.format("| `%s` | %s%s | %d | **%s** | %s | %s | SIM | %s |", s.path, s.className, if s.disabled then " (desativado)" else "", s.lines, s.risk, s.purpose, if s.visualOnly then "sim" else "não", if #flags > 0 then table.concat(flags, "<br>") else "—"))
		end
		line()
		line("Regra do Roll Legends: **nenhum script de terceiros entra no jogo**. O CharacterModelFactory")
		line("já anima/posiciona os modelos; os scripts do pack são removidos na importação.")
	end
	line()

	line("## 2. Personagens")
	line()
	line("| # | Categoria | Nome atual | Rig | Nota | Peças (Mesh) | Cabelo | Roupa | Rosto | Arma | Acessórios | VFX | Animações | Scripts | Compatibilidade |")
	line("|---:|---|---|---:|---|---|---|---|---|---|---:|---:|---:|---|")
	for i, c in report.characters do
		local clothes = {}
		if c.shirt then
			table.insert(clothes, "Shirt " .. c.shirt)
		end
		if c.pants then
			table.insert(clothes, "Pants " .. c.pants)
		end
		if c.tshirt then
			table.insert(clothes, "T-Shirt " .. c.tshirt)
		end
		line(string.format("| %d | %s | %s | %s | %d | %d (%d) | %s | %s | %s | %s | %d | %d | %d | %d | %s |", i, c.category or "—", c.name, c.rig, c.score, c.parts, c.meshParts + c.specialMeshes,
			list(c.hair), if #clothes > 0 then table.concat(clothes, ", ") else "—", c.face or "—", list(c.weapons), #c.accessories, #c.vfx, #c.animations, #c.scripts, c.compatibility))
	end
	line()
	for i, c in report.characters do
		line(string.format("### %d. %s", i, c.name))
		line()
		line("- Caminho: `" .. c.path .. "` · Categoria: " .. tostring(c.category) .. (if c.formGroup then " · Forma de: **" .. c.formGroup .. "**" else ""))
		line(string.format("- Rig: %s · Humanoid: %s · AnimationController: %s · Motor6D: %d · peças ancoradas: %d", c.rig, if c.humanoid then "sim" else "não", if c.animationController then "sim" else "não", c.motors, c.anchoredParts))
		line(string.format("- Malhas: %d MeshPart, %d SpecialMesh, %d MeshIds únicos · Texturas únicas: %d · Decals: %d · SurfaceAppearance: %d", c.meshParts, c.specialMeshes, #c.meshIds, #c.textureIds, c.decals, c.surfaceAppearance))
		line("- Acessórios: " .. list(c.accessories))
		line("- Armas: " .. list(c.weapons))
		line("- VFX: " .. list(c.vfx))
		line("- Animações: " .. list(c.animations))
		local scriptNames = {}
		for _, s in c.scripts do
			table.insert(scriptNames, s.name .. " [" .. s.risk .. "]")
		end
		line("- Scripts: " .. list(scriptNames))
		line("- Problemas: " .. list(c.problems, "nenhum"))
		line("- Compatibilidade com Roll Legends: **" .. c.compatibility .. "**")
		line()
	end

	line("## 3. Sugestão visual de raridade (heurística — NÃO altera o balanceamento)")
	line()
	line("Ordenado pela nota de qualidade; as cotas repetem o roster atual (5/4/4/3/3/2/2/1 = 24).")
	line()
	line("| Raridade sugerida | Modelo | Nota |")
	line("|---|---|---:|")
	for _, c in report.ranked do
		if c.suggestedRarity then
			line(string.format("| %s | %s | %d |", c.suggestedRarity, c.name, c.score))
		end
	end
	line()
	return table.concat(out, "\n")
end

return PackAudit
