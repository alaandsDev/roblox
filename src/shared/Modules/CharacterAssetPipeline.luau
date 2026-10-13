--!strict
--[[
	CharacterAssetPipeline: transforma um modelo do pack de origem em um CHARACTER ASSET seguro.
	Usado pelas ferramentas (python tools/build_characters.py, via Lune, e a Barra de comandos
	do Studio em modo EDIÇÃO) e, em runtime, só para VALIDAR assets (o jogo nunca lê o pack).

	    local model, report = Pipeline.sanitize(sourceModel, "char_ichiro_base")
	    local problems, warnings = Pipeline.validate(model)
	    local folder, reports = Pipeline.buildAll(packRoot)        -- todos de CharacterAssetConfig.Assets

	SANITIZAÇÃO (nada do original é alterado: tudo acontece num clone)
	  1. Mede o original (peças, malhas, texturas, soldas, scripts, sons, VFX...).
	  2. Descobre o "osso" R6 de cada peça (Torso, Head, LeftArm, RightArm, LeftLeg, RightLeg)
	     seguindo Motor6D/Weld/WeldConstraint/acessórios: cabelo, arma e capa ficam no osso em
	     que estão soldados (assim acompanham as poses).
	  3. Remove tudo que não é visual: scripts, remotes, bindables, sons, animações, valores de
	     estado, GUIs, ferramentas, física/constraints, LocalStand/BattleScript/Animate, peças
	     invisíveis (hitbox) e a HumanoidRootPart. Acessórios viram Model simples.
	  4. VFX: só ficam efeitos PRÓPRIOS da whitelist do personagem (nunca os genéricos do jogo de
	     origem), com limite de quantidade e de taxa. Cada um recebe VFXTier = Light | Full.
	  5. Normaliza: corpo (pés ao topo da Head) = BodyHeight; pivô no centro dos pés, olhando
	     para -Z. As soldas são "assadas": tudo ancorado, sem juntas (posar = mover CFrames).
	  6. Peças: Anchored, sem colisão/toque/consulta, Massless; PivotRoot invisível = PrimaryPart.
]]

local Config = require(script.Parent.Parent.Config.CharacterAssetConfig)

local Pipeline = {}

-- Uma roupa usada pelo personagem (o relatório agrupa por AssetId)
export type ClothingUse = { kind: string, assetId: string, original: string, final: string, status: string }

-- Um objeto VISUAL (peça, malha, roupa, rosto, textura) que existia na origem e não está no
-- asset: o que era, onde estava, qual regra do sanitizer removeu e por quê.
export type VisualRemoval = {
	className: string,
	name: string,
	path: string, -- caminho dentro do modelo de origem
	transparency: number?, -- da própria peça/decal (malha: a da peça que a contém)
	size: { number }?,
	meshId: string?,
	textureId: string?,
	decals: { string }, -- Decal/Texture dentro do objeto
	joints: { string }, -- Weld/Motor6D/WeldConstraint ligados à peça (antes de assar)
	bone: string?, -- parte do corpo à qual a peça estava ligada
	vfxInside: { string }, -- efeitos dentro do objeto na origem
	visibleAtRest: boolean, -- aparecia com o personagem parado (Transparency < 0.99)?
	rule: string, -- regra do sanitizer (NO_RULE = destruído sem regra registrada)
	reason: string,
	verdict: string, -- JUSTIFIED | UNJUSTIFIED
}

export type Report = {
	CharacterId: string,
	SourceModelName: string,
	SourcePath: string,
	originalParts: number,
	sanitizedParts: number,
	meshes: number,
	textures: number,
	decals: number,
	welds: number,
	motors: number,
	accessories: number,
	vfxPreserved: { string },
	vfxRemoved: number,
	scriptsRemoved: number,
	remotesRemoved: number,
	bindablesRemoved: number,
	soundsRemoved: number,
	animationsRemoved: number,
	valuesRemoved: number,
	guisRemoved: number,
	hiddenPartsRemoved: number,
	otherRemoved: { [string]: number },
	unattachedParts: { string },
	humanoidKept: boolean,
	nameTagsRemoved: number,
	clothing: { ClothingUse },
	visualSource: { [string]: number },
	visualSanitized: { [string]: number },
	visualLost: { string },
	visualPreserved: number, -- objetos visuais da origem que estão no asset
	visualRemoved: { VisualRemoval }, -- removidos (JUSTIFIED e UNJUSTIFIED)
	sourceCandidates: { string }, -- MISSING_SOURCE: nomes parecidos no pack (nunca escolhidos sozinhos)
	-- Orçamento (medido no asset final) e status do lote
	finalCounts: { [string]: number },
	vfxTruncated: number,
	vfxExcluded: { string },
	catalogStatus: string,
	clothingStatus: string,
	optimizationStatus: string, -- OK | NEEDS_OPTIMIZATION
	vfxStatus: string, -- OK | REVIEW
	scaleFactor: number,
	boundsSize: { number },
	visualOffset: { number },
	status: string, -- OK | WARN | FAIL
	problems: { string },
	warnings: { string },
}

local function readProp(obj: Instance, property: string): any
	local ok, value = pcall(function(): any
		return (obj :: any)[property]
	end)
	return if ok then value else nil
end

-- Referência de asset de uma propriedade. Em .rbxm recente a MeshPart grava MeshContent /
-- TextureContent (Content) em vez de MeshId / TextureID: lê os dois formatos. "" se não houver.
function Pipeline.contentOf(obj: Instance, legacy: string, modern: string?): string
	local value = readProp(obj, legacy)
	if type(value) == "string" and value ~= "" then
		return value
	end
	if modern then
		local content = readProp(obj, modern)
		local uri = if content ~= nil then string.match(tostring(content), "Uri=([^%)]+)") else nil
		if uri then
			return uri
		end
	end
	return ""
end

-- Textura de MeshPart (TextureID) ou SpecialMesh (TextureId); "" se não houver
function Pipeline.textureOf(obj: Instance): string
	if obj:IsA("MeshPart") then
		return Pipeline.contentOf(obj, "TextureID", "TextureContent")
	elseif obj:IsA("SpecialMesh") then
		return Pipeline.contentOf(obj, "TextureId")
	end
	return ""
end

-- Malha de MeshPart (MeshId) ou SpecialMesh (MeshId); "" se não houver
function Pipeline.meshOf(obj: Instance): string
	if obj:IsA("MeshPart") then
		return Pipeline.contentOf(obj, "MeshId", "MeshContent")
	elseif obj:IsA("SpecialMesh") then
		return Pipeline.contentOf(obj, "MeshId")
	end
	return ""
end

local function isFileMesh(mesh: Instance): boolean
	local ok, value = pcall(function(): any
		return (mesh :: any).MeshType
	end)
	return ok and value == Enum.MeshType.FileMesh
end

local function toSet(list: { string }): { [string]: boolean }
	local set = {}
	for _, item in list do
		set[item] = true
	end
	return set
end

local ALLOWED = toSet(Config.AllowedClasses)
local VFX_CLASSES = toSet(Config.VFXClasses)
local GENERIC_VFX = toSet(Config.GenericVFXNames)
local FORBIDDEN_NAMES = toSet({ "LocalStand", "BattleScript", "Animate" })
local LIGHT_CLASSES = toSet({ "PointLight", "SpotLight", "SurfaceLight" })
local ACCESSORY_CLASSES = toSet({ "Accessory", "Accoutrement", "Hat" })

local function isForbidden(obj: Instance): boolean
	for _, className in Config.ForbiddenClasses do
		if obj:IsA(className) then
			return true
		end
	end
	return false
end

local function category(obj: Instance): string
	if obj:IsA("LuaSourceContainer") then
		return "scriptsRemoved"
	elseif obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") or obj.ClassName == "UnreliableRemoteEvent" then
		return "remotesRemoved"
	elseif obj:IsA("BindableEvent") or obj:IsA("BindableFunction") then
		return "bindablesRemoved"
	elseif obj:IsA("Sound") or obj:IsA("SoundGroup") or obj:IsA("SoundEffect") then
		return "soundsRemoved"
	elseif obj:IsA("Animation") or obj:IsA("Animator") or obj:IsA("AnimationController") or obj:IsA("KeyframeSequence") then
		return "animationsRemoved"
	elseif obj:IsA("ValueBase") then
		return "valuesRemoved"
	elseif obj:IsA("LayerCollector") or obj:IsA("GuiObject") then
		return "guisRemoved"
	end
	return "other"
end

------------------------------------------------------------------------------------
-- Geometria

-- Caixa (min, max) de uma peça em coordenadas de "frame"
local function partBounds(part: BasePart, frame: CFrame): (Vector3, Vector3)
	local cf = frame:ToObjectSpace(part.CFrame)
	local h = part.Size / 2
	local minV, maxV = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
	for _, sx in { -1, 1 } do
		for _, sy in { -1, 1 } do
			for _, sz in { -1, 1 } do
				local p = cf * Vector3.new(h.X * sx, h.Y * sy, h.Z * sz)
				minV = minV:Min(p)
				maxV = maxV:Max(p)
			end
		end
	end
	return minV, maxV
end

local function boundsOf(parts: { BasePart }, frame: CFrame): (Vector3, Vector3)
	local minV, maxV = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
	for _, part in parts do
		local a, b = partBounds(part, frame)
		minV = minV:Min(a)
		maxV = maxV:Max(b)
	end
	return minV, maxV
end
Pipeline.boundsOf = boundsOf

local function scaleSequence(sequence: NumberSequence, factor: number): NumberSequence
	local points = {}
	for _, key in sequence.Keypoints do
		table.insert(points, NumberSequenceKeypoint.new(key.Time, key.Value * factor, key.Envelope * factor))
	end
	return NumberSequence.new(points)
end

local function basePartsOf(root: Instance): { BasePart }
	local parts = {}
	for _, obj in root:GetDescendants() do
		if obj:IsA("BasePart") then
			table.insert(parts, obj)
		end
	end
	return parts
end
Pipeline.basePartsOf = basePartsOf

--[[
	Escala um modelo em volta de "pivot" (CFrame no mundo): posições e tamanhos das peças,
	malhas de arquivo, offsets, attachments, texturas e tamanho dos efeitos. Não depende de
	Model:ScaleTo (funciona igual no Roblox, no Lune e em ViewportFrame).
]]
function Pipeline.scale(root: Instance, factor: number, pivot: CFrame)
	if math.abs(factor - 1) < 1e-6 then
		return
	end
	-- Propriedade opcional: lê com segurança (no Lune, propriedade nunca definida não tem valor)
	local function update(obj: Instance, property: string, fn: (any) -> any)
		local ok, value = pcall(function(): any
			return (obj :: any)[property]
		end)
		if ok and value ~= nil then
			(obj :: any)[property] = fn(value)
		end
	end
	local function times(value: any): any
		return value * factor
	end
	for _, obj in root:GetDescendants() do
		if obj:IsA("BasePart") then
			local rel = pivot:ToObjectSpace(obj.CFrame)
			obj.Size = obj.Size * factor
			obj.CFrame = pivot * (CFrame.new(rel.Position * factor) * rel.Rotation)
		elseif obj:IsA("SpecialMesh") then
			if isFileMesh(obj) then
				update(obj, "Scale", times)
			end
			update(obj, "Offset", times)
		elseif obj:IsA("DataModelMesh") then
			update(obj, "Offset", times)
		elseif obj:IsA("Attachment") then
			update(obj, "CFrame", function(cf: CFrame): CFrame
				return CFrame.new(cf.Position * factor) * cf.Rotation
			end)
		elseif obj:IsA("Texture") then
			update(obj, "StudsPerTileU", times)
			update(obj, "StudsPerTileV", times)
		elseif obj:IsA("ParticleEmitter") then
			update(obj, "Size", function(sequence: NumberSequence): NumberSequence
				return scaleSequence(sequence, factor)
			end)
		elseif obj:IsA("Beam") then
			update(obj, "Width0", times)
			update(obj, "Width1", times)
		elseif obj:IsA("Fire") then
			update(obj, "Size", times)
		elseif obj:IsA("PointLight") or obj:IsA("SpotLight") then
			update(obj, "Range", times)
		end
	end
end

------------------------------------------------------------------------------------
-- Ossos (qual grupo R6 cada peça acompanha)

-- Chave estável por peça (no Lune, cada acesso a uma Instance devolve um objeto novo; no
-- Roblox é a mesma). O atributo temporário é removido no fim da sanitização.
local ID_ATTRIBUTE = "PipelineId"
local function keyOf(part: Instance): number
	return part:GetAttribute(ID_ATTRIBUTE) :: number
end

local function bodyParts(model: Instance): { [string]: BasePart }
	local found = {}
	for name, bone in Config.R6Parts do
		local part = model:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			found[bone] = part
		end
	end
	return found
end

-- Liga peças por juntas (Motor6D/Weld/ManualWeld/Snap/WeldConstraint) e acessórios
local function jointGraph(model: Instance, body: { [string]: BasePart }): { [number]: { number } }
	local edges: { [number]: { number } } = {}
	local function link(a: Instance?, b: Instance?)
		if a and b and a:IsA("BasePart") and b:IsA("BasePart") and a:IsDescendantOf(model) and b:IsDescendantOf(model) then
			local ka, kb = keyOf(a), keyOf(b)
			if ka == kb then
				return
			end
			edges[ka] = edges[ka] or {}
			edges[kb] = edges[kb] or {}
			table.insert(edges[ka], kb)
			table.insert(edges[kb], ka)
		end
	end
	for _, obj in model:GetDescendants() do
		if obj:IsA("JointInstance") then
			link(obj.Part0, obj.Part1)
		elseif obj:IsA("WeldConstraint") then
			link(obj.Part0, obj.Part1)
		elseif ACCESSORY_CLASSES[obj.ClassName] then
			-- Acessório sem solda salva: liga pelo Attachment de mesmo nome no corpo (ex.: HairAttachment)
			local handle = obj:FindFirstChild("Handle")
			if handle and handle:IsA("BasePart") then
				for _, attachment in handle:GetChildren() do
					if attachment:IsA("Attachment") then
						for _, part in body do
							if part:FindFirstChild(attachment.Name) then
								link(handle, part)
							end
						end
					end
				end
			end
		end
	end
	return edges
end

local function assignBones(model: Instance, body: { [string]: BasePart }, root: BasePart?): ({ [number]: string }, { number })
	local bones: { [number]: string } = {}
	local queue: { number } = {}
	for bone, part in body do
		bones[keyOf(part)] = bone
		table.insert(queue, keyOf(part))
	end
	if root then
		-- O que está preso na HumanoidRootPart acompanha o tronco
		bones[keyOf(root)] = "Torso"
		table.insert(queue, keyOf(root))
	end
	local edges = jointGraph(model, body)
	-- BFS a partir do corpo: cada peça pega o osso da parte do corpo mais próxima (em juntas)
	local head = 1
	while head <= #queue do
		local current = queue[head]
		head += 1
		local neighbors = edges[current]
		if neighbors then
			for _, other in neighbors do
				if bones[other] == nil then
					bones[other] = bones[current]
					table.insert(queue, other)
				end
			end
		end
	end
	-- Peças soltas (sem junta): osso da parte do corpo mais próxima, e entra no relatório
	local unattached = {}
	for _, part in basePartsOf(model) do
		if bones[keyOf(part)] == nil then
			local best, bestDistance = "Torso", math.huge
			for bone, bodyPart in body do
				local distance = (bodyPart.CFrame.Position - part.CFrame.Position).Magnitude
				if distance < bestDistance then
					best, bestDistance = bone, distance
				end
			end
			bones[keyOf(part)] = best
			table.insert(unattached, keyOf(part))
		end
	end
	return bones, unattached
end

------------------------------------------------------------------------------------
-- Sanitização

local function newReport(characterId: string): Report
	local spec = Config.Assets[characterId]
	return {
		CharacterId = characterId,
		SourceModelName = if spec then spec.SourceModelName else "?",
		SourcePath = if spec then spec.SourcePath else "?",
		originalParts = 0,
		sanitizedParts = 0,
		meshes = 0,
		textures = 0,
		decals = 0,
		welds = 0,
		motors = 0,
		accessories = 0,
		vfxPreserved = {},
		vfxRemoved = 0,
		scriptsRemoved = 0,
		remotesRemoved = 0,
		bindablesRemoved = 0,
		soundsRemoved = 0,
		animationsRemoved = 0,
		valuesRemoved = 0,
		guisRemoved = 0,
		hiddenPartsRemoved = 0,
		otherRemoved = {},
		unattachedParts = {},
		humanoidKept = false,
		nameTagsRemoved = 0,
		clothing = {},
		visualSource = {},
		visualSanitized = {},
		visualLost = {},
		visualPreserved = 0,
		visualRemoved = {},
		sourceCandidates = {},
		finalCounts = {},
		vfxTruncated = 0,
		vfxExcluded = if spec and spec.VFXExcluded then table.clone(spec.VFXExcluded) else {},
		catalogStatus = if spec and spec.CatalogStatus then spec.CatalogStatus else "APPROVED",
		clothingStatus = "NONE",
		optimizationStatus = "OK",
		vfxStatus = "OK",
		scaleFactor = 1,
		boundsSize = { 0, 0, 0 },
		visualOffset = { 0, 0, 0 },
		status = "FAIL",
		problems = {},
		warnings = {},
	}
end

-- Contagens do modelo ORIGINAL (só leitura)
local function measureSource(source: Instance, report: Report)
	for _, obj in source:GetDescendants() do
		if obj:IsA("BasePart") then
			report.originalParts += 1
			if obj:IsA("MeshPart") then
				report.meshes += 1
				if Pipeline.textureOf(obj) ~= "" then
					report.textures += 1
				end
			end
		elseif obj:IsA("SpecialMesh") then
			if isFileMesh(obj) then
				report.meshes += 1
			end
			if Pipeline.textureOf(obj) ~= "" then
				report.textures += 1
			end
		elseif obj:IsA("Texture") then
			report.textures += 1
		elseif obj:IsA("Decal") then
			report.decals += 1
		elseif obj:IsA("Motor6D") then
			report.motors += 1
		elseif obj:IsA("JointInstance") or obj:IsA("WeldConstraint") then
			report.welds += 1
		elseif ACCESSORY_CLASSES[obj.ClassName] then
			report.accessories += 1
		end
	end
end

local function hasClothing(model: Instance): boolean
	for _, obj in model:GetChildren() do
		if obj:IsA("Clothing") or obj:IsA("ShirtGraphic") or obj:IsA("BodyColors") then
			return true
		end
	end
	return false
end

-- Peça invisível sem nada visível dentro (hitbox, colisor, marcador do jogo de origem)
local function isHiddenPart(part: BasePart): boolean
	if part.Transparency < 0.99 then
		return false
	end
	for _, child in part:GetDescendants() do
		-- Decal/Texture aparecem mesmo numa peça transparente (roupa/estampa desenhada na peça)
		if child:IsA("Decal") or child:IsA("ParticleEmitter") or child:IsA("Beam") or child:IsA("Trail") or child:IsA("Fire") then
			return false
		end
	end
	return true
end

local function inList(list: { string }?, name: string): boolean
	return list ~= nil and table.find(list, name) ~= nil
end

local function setSafe(obj: Instance, property: string, value: any)
	pcall(function()
		(obj :: any)[property] = value
	end)
end

------------------------------------------------------------------------------------
-- Roupa: referência do template

-- Número do asset em "rbxassetid://N" ou "http(s)://www.roblox.com/asset/?id=N" (nil se não achar)
function Pipeline.assetIdOf(content: string?): string?
	if type(content) ~= "string" then
		return nil
	end
	return string.match(content, "^rbxassetid://(%d+)") or string.match(content, "[?&][iI][dD]=(%d+)")
end

local CLOTHING_PROPERTY = { Shirt = "ShirtTemplate", Pants = "PantsTemplate", ShirtGraphic = "Graphic" }

--[[
	Normaliza as roupas de um modelo (mesma função no pipeline e no factory):
	  - CharacterAssetConfig.ClothingTemplateOverrides[id] substitui o template (ex.: o pack
	    aponta para o ITEM da loja em vez da IMAGEM; o comando DEV ClothingCheck descobre a imagem);
	  - senão, a URL antiga "http://www.roblox.com/asset/?id=N" vira "rbxassetid://N" (mesmo asset).
	Devolve as roupas encontradas (classe, AssetId, template original/final e status da auditoria).
	Nenhuma chamada de rede: o status vem de CharacterAssetConfig.ClothingStatus.
]]
function Pipeline.normalizeClothing(model: Instance): { ClothingUse }
	local uses: { ClothingUse } = {}
	for _, obj in model:GetDescendants() do
		local property = CLOTHING_PROPERTY[obj.ClassName]
		if property then
			local ok, current = pcall(function(): any
				return (obj :: any)[property]
			end)
			local id = ok and Pipeline.assetIdOf(current) or nil
			if id then
				local final = Config.ClothingTemplateOverrides[id] or ("rbxassetid://" .. id)
				if final ~= current then
					setSafe(obj, property, final)
				end
				table.insert(uses, { kind = obj.ClassName, assetId = id, original = tostring(current), final = final, status = Config.clothingStatus(id) })
			end
		end
	end
	return uses
end

------------------------------------------------------------------------------------
-- Comparação visual (source x sanitizado)

-- Classes que formam o visual; perder alguma sem justificativa = problema
Pipeline.VisualClasses = { "Shirt", "Pants", "ShirtGraphic", "BodyColors", "Decal", "Texture", "SurfaceAppearance", "MeshPart", "SpecialMesh", "Part", "UnionOperation", "WedgePart" }
local VISUAL_SET = toSet(Pipeline.VisualClasses)

-- Contagem por classe visual, ignorando o que "skip" disser (remoções justificadas)
function Pipeline.visualSignature(root: Instance, skip: ((Instance) -> boolean)?): { [string]: number }
	local counts: { [string]: number } = {}
	for _, obj in root:GetDescendants() do
		if VISUAL_SET[obj.ClassName] and not (skip and skip(obj)) then
			counts[obj.ClassName] = (counts[obj.ClassName] or 0) + 1
		end
	end
	return counts
end

-- Classes que diminuíram (ex.: { "Shirt 1 -> 0" })
function Pipeline.visualLoss(before: { [string]: number }, after: { [string]: number }): { string }
	local lost = {}
	for _, className in Pipeline.VisualClasses do
		local a, b = before[className] or 0, after[className] or 0
		if b < a then
			table.insert(lost, `{className} {a} -> {b}`)
		end
	end
	return lost
end

--[[
	Regras de remoção de objetos VISUAIS (cada remoção registra regra + motivo):
	  NameTag               placa de título do jogo de origem ("[ SEMI-PRO ]": Model + Humanoid
	                        próprio + peças < 0.5)                                -> JUSTIFIED
	  ForbiddenContainer    dentro de LocalStand/BattleScript/Animate (stand e combate) -> JUSTIFIED
	  RootPart              HumanoidRootPart (peça raiz)    -> JUSTIFIED só se invisível parado
	  InvisibleHitbox       Transparency >= 0.99, sem Decal/Texture/VFX     -> JUSTIFIED
	  InvisibleCombatHelper Transparency >= 0.99 e o único conteúdo visível eram VFX removidos pela
	                        política de VFX (ex.: espada "sacada" só no golpe, com Trail) -> JUSTIFIED
	  ForbiddenClass        classe proibida/não permitida (ou dentro de uma) -> JUSTIFIED só se invisível
	  NO_RULE               destruído sem regra registrada                    -> UNJUSTIFIED
	Qualquer UNJUSTIFIED = perda visual = FAIL.
]]
local VISUAL_KEY = "PipelineVisualKey"
local NO_RULE = "NO_RULE"
local ALWAYS_JUSTIFIED = toSet({ "NameTag", "ForbiddenContainer", "InvisibleHitbox", "InvisibleCombatHelper" })
local JUSTIFIED_IF_INVISIBLE = toSet({ "RootPart", "ForbiddenClass" })

-- Transparency que vale para o objeto (malha/aparência: a da peça que a contém)
local function effectiveTransparency(obj: Instance): number?
	if obj:IsA("BasePart") or obj:IsA("Decal") then
		local value = readProp(obj, "Transparency")
		return if type(value) == "number" then value else 0
	end
	if obj:IsA("DataModelMesh") or obj.ClassName == "SurfaceAppearance" then
		local parent = obj.Parent
		return if parent and parent:IsA("BasePart") then effectiveTransparency(parent) else nil
	end
	return nil
end

local function relativePath(obj: Instance, root: Instance): string
	local names = {}
	local node: Instance? = obj
	while node and node ~= root do
		table.insert(names, 1, node.Name)
		node = node.Parent
	end
	return table.concat(names, ".")
end

-- Ficha de um objeto visual da origem (antes de qualquer remoção)
local function describeVisual(obj: Instance, model: Instance, joints: { [number]: { string } }, bones: { [number]: string }): VisualRemoval
	local transparency = effectiveTransparency(obj)
	local record: VisualRemoval = {
		className = obj.ClassName,
		name = obj.Name,
		path = relativePath(obj, model),
		transparency = transparency,
		decals = {},
		joints = {},
		vfxInside = {},
		visibleAtRest = transparency == nil or transparency < 0.99,
		rule = NO_RULE,
		reason = "",
		verdict = "UNJUSTIFIED",
	}
	if obj:IsA("BasePart") then
		local size = obj.Size
		record.size = { size.X, size.Y, size.Z }
		local key = obj:GetAttribute(ID_ATTRIBUTE)
		if type(key) == "number" then
			record.joints = joints[key] or {}
			record.bone = bones[key]
		end
	end
	local meshId = Pipeline.meshOf(obj)
	if meshId ~= "" then
		record.meshId = meshId
	end
	local texture = Pipeline.textureOf(obj)
	if texture == "" and obj:IsA("Decal") then
		texture = Pipeline.contentOf(obj, "Texture", "TextureContent")
	end
	if texture ~= "" then
		record.textureId = texture
	end
	for _, child in obj:GetDescendants() do
		if child:IsA("Decal") then
			table.insert(record.decals, `{child.ClassName} {child.Name} {Pipeline.contentOf(child, "Texture", "TextureContent")}`)
		elseif VFX_CLASSES[child.ClassName] then
			table.insert(record.vfxInside, `{child.ClassName} {child.Name}`)
		end
	end
	return record
end

function Pipeline.sanitize(source: Model, characterId: string, debugAfterRemoval: ((Model) -> ())?): (Model?, Report)
	local report = newReport(characterId)
	local spec = Config.Assets[characterId]
	if not spec then
		table.insert(report.problems, "CharacterId sem especificação em CharacterAssetConfig.Assets")
		return nil, report
	end
	measureSource(source, report)

	local model = source:Clone() :: Model
	for i, part in basePartsOf(model) do
		part:SetAttribute(ID_ATTRIBUTE, i)
	end
	local body = bodyParts(model)
	for name, bone in Config.R6Parts do
		if not body[bone] then
			table.insert(report.problems, "R6 incompleto: falta " .. name)
		end
	end
	if #report.problems > 0 then
		model:Destroy()
		return nil, report
	end
	local hrp = model:FindFirstChild("HumanoidRootPart")
	local rootPart: BasePart? = if hrp and hrp:IsA("BasePart") then hrp else nil
	local bones, unattached = assignBones(model, body, rootPart)

	-- Ficha de TODO objeto visual da origem: no fim, o que sumiu precisa ter regra + motivo
	local joints: { [number]: { string } } = {}
	for _, obj in model:GetDescendants() do
		if obj:IsA("JointInstance") or obj:IsA("WeldConstraint") then
			local a, b = readProp(obj, "Part0"), readProp(obj, "Part1")
			for _, pair in { { a, b }, { b, a } } do
				local part, other = pair[1], pair[2]
				local key = part and part:GetAttribute(ID_ATTRIBUTE)
				if key then
					joints[key] = joints[key] or {}
					table.insert(joints[key], `{obj.Name} ({obj.ClassName}) -> {if other then other.Name else "nil"}`)
				end
			end
		end
	end
	local records: { VisualRemoval } = {}
	for _, obj in model:GetDescendants() do
		if VISUAL_SET[obj.ClassName] then
			table.insert(records, describeVisual(obj, model, joints, bones))
			obj:SetAttribute(VISUAL_KEY, #records)
		end
	end
	-- Registra a regra de remoção do objeto e de tudo que vai junto com ele
	local function mark(obj: Instance, rule: string, reason: string)
		local list = obj:GetDescendants()
		table.insert(list, obj)
		for _, item in list do
			local key = item:GetAttribute(VISUAL_KEY)
			local record = if type(key) == "number" then records[key] else nil
			if record and record.rule == NO_RULE then
				record.rule = rule
				record.reason = if item == obj then reason else `{reason} (removido junto com {obj.ClassName} "{obj.Name}")`
			end
		end
	end

	-- Referencial: pés no centro, olhando para a frente do rig (LookVector sem inclinação)
	local reference = rootPart or body.Torso
	local look = reference.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	if flat.Magnitude < 1e-3 then
		flat = Vector3.new(0, 0, -1)
	end
	flat = flat.Unit
	local up = Vector3.new(0, 1, 0)
	local yaw = CFrame.fromMatrix(Vector3.zero, flat:Cross(up).Unit, up, -flat)
	local legMin = math.huge
	for _, bone in { "LeftLeg", "RightLeg" } do
		local a = partBounds(body[bone], yaw)
		legMin = math.min(legMin, a.Y)
	end
	local _, headMax = partBounds(body.Head, yaw)
	local bodyHeight = headMax.Y - legMin
	if bodyHeight <= 0.5 then
		table.insert(report.problems, "altura do corpo inválida")
		model:Destroy()
		return nil, report
	end
	local center = reference.CFrame.Position
	local origin = CFrame.new(center.X, (yaw * Vector3.new(0, legMin, 0)).Y, center.Z) * yaw

	-- 1) Acessórios viram Model simples (o Humanoid não tenta soldar nada de novo)
	for _, obj in model:GetDescendants() do
		if ACCESSORY_CLASSES[obj.ClassName] and obj.Parent then
			local holder = Instance.new("Model")
			holder.Name = obj.Name
			for _, child in obj:GetChildren() do
				child.Parent = holder
			end
			holder.Parent = obj.Parent
			obj:Destroy()
		end
	end

	-- 2) Remoção de tudo que não é visual
	local keepHumanoid = hasClothing(model)
	-- "Placa de título" do jogo de origem: Model com Humanoid próprio e peças minúsculas
	-- (ex.: "[ SEMI-PRO ]"). O nome do Model aparecia em cima do personagem. Não é visual do corpo.
	local nameTags: { Instance } = {}
	for _, obj in model:GetDescendants() do
		if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then
			local tiny = true
			for _, part in basePartsOf(obj) do
				local size = part.Size
				tiny = tiny and math.max(size.X, size.Y, size.Z) < 0.5
			end
			if tiny then
				obj:SetAttribute("PipelineNameTag", true)
				table.insert(nameTags, obj)
			end
		end
	end
	report.visualSource = Pipeline.visualSignature(model)
	for _, tag in nameTags do
		report.nameTagsRemoved += 1
		mark(tag, "NameTag", `placa de título do jogo de origem: Model "{tag.Name}" com Humanoid próprio e peças < 0.5`)
		tag:Destroy()
	end
	local rootKey = if rootPart then keyOf(rootPart) else nil
	local vfx: { Instance } = {}
	local all = model:GetDescendants()
	for _, obj in all do
		-- já foi junto com um pai removido?
		local alive = pcall(function()
			assert(obj.Parent ~= nil and obj:IsDescendantOf(model))
		end)
		if not alive then
			continue
		end
		local className = obj.ClassName
		local remove = false
		local rule, reason = NO_RULE, ""
		if FORBIDDEN_NAMES[obj.Name] then
			remove = true
			rule, reason = "ForbiddenContainer", `"{obj.Name}" (stand/script de combate do pack)`
		elseif obj:IsA("JointInstance") or obj:IsA("WeldConstraint") then
			remove = true -- soldas assadas: tudo ancorado na pose original
		elseif VFX_CLASSES[className] then
			local wanted = spec.VFX and inList(spec.VFX.Full, obj.Name)
			if wanted and not GENERIC_VFX[obj.Name] then
				table.insert(vfx, obj)
			else
				report.vfxRemoved += 1
				obj:Destroy()
			end
			continue
		elseif className == "Humanoid" then
			-- só o Humanoid do próprio personagem (roupas); Humanoids aninhados saem
			remove = not keepHumanoid or obj.Parent ~= model
		elseif obj:IsA("BasePart") and rootKey ~= nil and keyOf(obj) == rootKey then
			remove = true
			rule, reason = "RootPart", "HumanoidRootPart: peça raiz do rig"
		elseif not ALLOWED[className] or isForbidden(obj) then
			remove = true
			rule, reason = "ForbiddenClass", `classe {className} não permitida no asset`
		end
		if remove then
			mark(obj, rule, reason)
			-- conta tudo que vai junto (scripts dentro de uma pasta removida, etc.)
			local removed = obj:GetDescendants()
			table.insert(removed, obj)
			for _, item in removed do
				local kind = category(item)
				if VFX_CLASSES[item.ClassName] then
					report.vfxRemoved += 1
				elseif kind == "other" then
					if not item:IsA("JointInstance") and not item:IsA("WeldConstraint") and not item:IsA("BasePart") then
						report.otherRemoved[item.ClassName] = (report.otherRemoved[item.ClassName] or 0) + 1
					end
				else
					(report :: any)[kind] += 1
				end
			end
			obj:Destroy()
		end
	end
	-- Hitboxes/peças invisíveis e pastas que ficaram vazias
	for _, part in basePartsOf(model) do
		if not Config.R6Parts[part.Name] and isHiddenPart(part) then
			report.hiddenPartsRemoved += 1
			local key = part:GetAttribute(VISUAL_KEY)
			local record = if type(key) == "number" then records[key] else nil
			local transparency = string.format("%.2f", part.Transparency)
			if record and #record.vfxInside > 0 then
				-- invisível parado; só aparecia pelos efeitos, que a política de VFX removeu
				mark(part, "InvisibleCombatHelper", `Transparency={transparency}; o único conteúdo visível eram VFX removidos pela política de VFX ({table.concat(record.vfxInside, ", ")})`)
			else
				mark(part, "InvisibleHitbox", `Transparency={transparency}, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)`)
			end
			part:Destroy()
		end
	end
	local function prune(container: Instance)
		for _, child in container:GetChildren() do
			prune(child)
			if (child:IsA("Folder") or child:IsA("Model")) and #child:GetChildren() == 0 then
				child:Destroy()
			end
		end
	end
	prune(model)

	-- Peças sem junta que sobraram (as de containers removidos, como LocalStand, não contam)
	for _, part in basePartsOf(model) do
		if table.find(unattached, keyOf(part)) then
			table.insert(report.unattachedParts, part.Name)
		end
	end

	-- Roupas: template normalizado / corrigido (ClothingTemplateOverrides)
	report.clothing = Pipeline.normalizeClothing(model)
	if debugAfterRemoval then
		debugAfterRemoval(model) -- só testes: simula uma remoção sem regra registrada
	end
	-- Nada visual pode sumir sem justificativa (roupa, rosto, textura, malha, peça visível):
	-- cada objeto da origem que não está no asset precisa de uma regra que o justifique
	report.visualSanitized = Pipeline.visualSignature(model)
	local present: { [number]: boolean } = {}
	for _, obj in model:GetDescendants() do
		local key = obj:GetAttribute(VISUAL_KEY)
		if type(key) == "number" then
			present[key] = true
			obj:SetAttribute(VISUAL_KEY, nil)
		end
	end
	for key, record in records do
		if present[key] then
			report.visualPreserved += 1
			continue
		end
		if record.rule == NO_RULE then
			record.reason = "destruído sem regra registrada no sanitizer"
		elseif ALWAYS_JUSTIFIED[record.rule] or (JUSTIFIED_IF_INVISIBLE[record.rule] and not record.visibleAtRest) then
			record.verdict = "JUSTIFIED"
		else
			record.reason ..= `; mas era VISÍVEL parado (Transparency {string.format("%.2f", record.transparency or 0)})`
		end
		table.insert(report.visualRemoved, record)
		if record.verdict ~= "JUSTIFIED" then
			table.insert(report.visualLost, `{record.className} "{record.name}" ({record.path}) · regra {record.rule}: {record.reason}`)
		end
	end

	-- 3) VFX: limites (quantidade, luzes, taxa) e camada Light/Full. Os nomes da lista Light
	-- vêm primeiro (nunca são cortados pelo limite), depois ordem estável pelo caminho.
	local function lightRank(effect: Instance): number
		return if spec.VFX and inList(spec.VFX.Light, effect.Name) then 0 else 1
	end
	table.sort(vfx, function(a, b)
		local ra, rb = lightRank(a), lightRank(b)
		if ra ~= rb then
			return ra < rb
		end
		return a:GetFullName() < b:GetFullName()
	end)
	local limits = Config.VFXLimits
	local kept, lights, lightTier = 0, 0, 0
	for _, effect in vfx do
		local isLight = LIGHT_CLASSES[effect.ClassName] == true
		if kept >= limits.MaxFull or (isLight and lights >= limits.MaxLights) then
			report.vfxRemoved += 1
			report.vfxTruncated += 1
			effect:Destroy()
			continue
		end
		kept += 1
		if isLight then
			lights += 1
		end
		local tier = "Full"
		if spec.VFX and inList(spec.VFX.Light, effect.Name) and lightTier < limits.MaxLight then
			tier = "Light"
			lightTier += 1
		end
		effect:SetAttribute("VFXTier", tier)
		if effect:IsA("ParticleEmitter") then
			effect.Rate = math.min(effect.Rate, limits.MaxRate)
		end
		table.insert(report.vfxPreserved, `{effect.ClassName} {effect.Name} ({tier})`)
	end

	-- 4) Normalização: pivô nos pés, corpo = BodyHeight
	local factor = Config.BodyHeight / bodyHeight
	report.scaleFactor = factor
	for _, part in basePartsOf(model) do
		part.CFrame = origin:ToObjectSpace(part.CFrame)
	end
	Pipeline.scale(model, factor, CFrame.new())

	-- 5) Peças: ancoradas, sem física; osso em atributo
	local parts = basePartsOf(model)
	for _, part in parts do
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.Massless = true
		part:SetAttribute("Bone", bones[keyOf(part)] or "Torso")
		part:SetAttribute(ID_ATTRIBUTE, nil)
	end
	if keepHumanoid then
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		if humanoid then
			report.humanoidKept = true
			for _, child in humanoid:GetChildren() do
				child:Destroy()
			end
			setSafe(humanoid, "DisplayDistanceType", Enum.HumanoidDisplayDistanceType.None)
			setSafe(humanoid, "HealthDisplayType", Enum.HumanoidHealthDisplayType.AlwaysOff)
			setSafe(humanoid, "NameDisplayDistance", 0)
			setSafe(humanoid, "HealthDisplayDistance", 0)
			setSafe(humanoid, "RequiresNeck", false)
			setSafe(humanoid, "BreakJointsOnDeath", false)
			setSafe(humanoid, "EvaluateStateMachine", false)
			setSafe(humanoid, "AutoRotate", false)
		end
	end
	local pivotRoot = Instance.new("Part")
	pivotRoot.Name = "PivotRoot"
	pivotRoot.Size = Vector3.new(0.2, 0.2, 0.2)
	pivotRoot.CFrame = CFrame.new()
	pivotRoot.Transparency = 1
	pivotRoot.Anchored = true
	pivotRoot.CanCollide = false
	pivotRoot.CanTouch = false
	pivotRoot.CanQuery = false
	pivotRoot.Massless = true
	pivotRoot:SetAttribute("Bone", "Root")
	pivotRoot.Parent = model
	model.PrimaryPart = pivotRoot
	model.WorldPivot = CFrame.new()
	model.Name = characterId

	local minV, maxV = boundsOf(parts, CFrame.new())
	local size = maxV - minV
	report.boundsSize = { size.X, size.Y, size.Z }
	report.sanitizedParts = #parts
	report.visualOffset = table.clone(Config.visualOffset(characterId))
	model:SetAttribute("CharacterId", characterId)
	model:SetAttribute("SourceModelName", spec.SourceModelName)
	model:SetAttribute("AssetVersion", Config.AssetVersion)
	model:SetAttribute("PartCount", #parts)
	model:SetAttribute("BodyHeight", Config.BodyHeight)
	model:SetAttribute("BoundsSize", size)

	local problems, warnings = Pipeline.validate(model)
	for _, lost in report.visualLost do
		table.insert(problems, "perdeu visual sem justificativa: " .. lost)
	end
	report.problems = problems
	report.warnings = warnings
	-- Orçamento do asset final (mobile: até 40 por base)
	local counts: { [string]: number } = { Parts = #parts, MeshParts = 0, Attachments = 0, Emitters = 0, Trails = 0, Beams = 0, Lights = 0, Instances = #model:GetDescendants() }
	for _, obj in model:GetDescendants() do
		if obj:IsA("MeshPart") then
			counts.MeshParts += 1
		elseif obj:IsA("Attachment") then
			counts.Attachments += 1
		elseif obj:IsA("ParticleEmitter") then
			counts.Emitters += 1
		elseif obj:IsA("Trail") then
			counts.Trails += 1
		elseif obj:IsA("Beam") then
			counts.Beams += 1
		elseif obj:IsA("Light") then
			counts.Lights += 1
		end
	end
	report.finalCounts = counts
	local budget = Config.Budget
	if counts.Parts > budget.MaxParts or counts.Instances > budget.MaxInstances then
		report.optimizationStatus = "NEEDS_OPTIMIZATION"
	end
	if report.vfxTruncated > 0 or #report.vfxExcluded > 0 then
		report.vfxStatus = "REVIEW"
	end
	-- Status de roupa do personagem = o pior entre as roupas dele
	local rank = { NONE = 0, OK = 1, OVERRIDDEN = 2, UNCHECKED = 3, REVIEW_REQUIRED = 4 }
	for _, use in report.clothing do
		if (rank[use.status] or 0) > (rank[report.clothingStatus] or 0) then
			report.clothingStatus = use.status
		end
	end
	-- Atributos para filtros da galeria DEV (sem rede, sem relatório em runtime)
	model:SetAttribute("ClothingStatus", report.clothingStatus)
	model:SetAttribute("OptimizationStatus", report.optimizationStatus)
	model:SetAttribute("VFXStatus", report.vfxStatus)

	-- Roupa com asset externo problemático: gera o personagem, mas marca para revisão
	for _, use in report.clothing do
		if use.status == "REVIEW_REQUIRED" then
			table.insert(report.warnings, `roupa REVIEW_REQUIRED: {use.kind} {use.assetId} (veja CLOTHING_AUDIT.md)`)
		end
	end
	if #report.unattachedParts > 0 then
		table.insert(report.warnings, `{#report.unattachedParts} peça(s) sem junta (presas pelo osso mais próximo): {table.concat(report.unattachedParts, ", ")}`)
	end
	if #parts > Config.PreferredMaxParts then
		table.insert(report.warnings, `{#parts} peças (meta preferencial: {Config.PreferredMaxParts})`)
	end
	report.status = if #problems > 0 then "FAIL" elseif #report.warnings > 0 then "WARN" else "OK"
	if #problems > 0 then
		model:Destroy()
		return nil, report
	end
	return model, report
end

------------------------------------------------------------------------------------
-- Validação (ferramenta e runtime)

local VALID_BONES = toSet({ "Root", "Torso", "Head", "LeftArm", "RightArm", "LeftLeg", "RightLeg" })

-- Devolve (problemas, avisos). Qualquer problema = asset rejeitado (o factory usa o placeholder).
function Pipeline.validate(model: Instance): ({ string }, { string })
	local problems, warnings = {}, {}
	if not model:IsA("Model") then
		return { "não é um Model" }, warnings
	end
	local root = model:FindFirstChild("PivotRoot")
	if not root or not root:IsA("BasePart") or (model :: Model).PrimaryPart ~= root then
		table.insert(problems, "PivotRoot ausente ou não é o PrimaryPart")
	end
	for name in Config.R6Parts do
		local part = model:FindFirstChild(name)
		if not part or not part:IsA("BasePart") then
			table.insert(problems, "R6: falta " .. name)
		end
	end
	local vfxCount, lightCount = 0, 0
	for _, obj in model:GetDescendants() do
		local className = obj.ClassName
		if isForbidden(obj) then
			table.insert(problems, "classe proibida: " .. className .. " " .. obj:GetFullName())
		elseif not ALLOWED[className] then
			table.insert(problems, "classe fora da whitelist: " .. className)
		elseif FORBIDDEN_NAMES[obj.Name] then
			table.insert(problems, "nome proibido: " .. obj.Name)
		elseif obj:IsA("JointInstance") or obj:IsA("WeldConstraint") then
			table.insert(problems, "junta não assada: " .. obj.Name)
		end
		if VFX_CLASSES[className] then
			vfxCount += 1
			if LIGHT_CLASSES[className] then
				lightCount += 1
			end
			if GENERIC_VFX[obj.Name] then
				table.insert(problems, "VFX genérico do jogo de origem: " .. obj.Name)
			end
			local tier = obj:GetAttribute("VFXTier")
			if tier ~= "Light" and tier ~= "Full" then
				table.insert(problems, "VFX sem VFXTier: " .. obj.Name)
			end
		end
		if obj:IsA("BasePart") then
			if not obj.Anchored or obj.CanCollide or obj.CanTouch or obj.CanQuery then
				table.insert(problems, "peça com física/colisão: " .. obj.Name)
			end
			if not VALID_BONES[tostring(obj:GetAttribute("Bone") or "")] then
				table.insert(problems, "peça sem osso: " .. obj.Name)
			end
		end
		if obj:IsA("Humanoid") and #obj:GetChildren() > 0 then
			table.insert(problems, "Humanoid com filhos (Animator/estado)")
		end
		if obj:IsA("Humanoid") and obj.Parent ~= model then
			table.insert(warnings, "Humanoid aninhado (placa de título do pack): gere os assets de novo")
		end
	end
	if vfxCount > Config.VFXLimits.MaxFull then
		table.insert(problems, `VFX demais: {vfxCount}`)
	end
	if lightCount > Config.VFXLimits.MaxLights then
		table.insert(problems, `luzes demais: {lightCount}`)
	end
	if #problems > 0 then
		return problems, warnings
	end

	-- Pivô, pés e altura do corpo (relativos ao PivotRoot: vale para o template e para clones)
	local pivot = (root :: BasePart).CFrame
	local scale = (model:GetAttribute("RuntimeScale") :: number?) or 1
	local legs = { model:FindFirstChild("Left Leg") :: BasePart, model:FindFirstChild("Right Leg") :: BasePart }
	local legMin = boundsOf(legs, pivot)
	local _, headMax = boundsOf({ model:FindFirstChild("Head") :: BasePart }, pivot)
	local tolerance = Config.FeetTolerance * scale
	if math.abs(legMin.Y) > tolerance then
		table.insert(problems, string.format("pés fora do pivô (%.2f)", legMin.Y))
	end
	local expected = Config.BodyHeight * scale
	if math.abs((headMax.Y - legMin.Y) - expected) > tolerance * 2 then
		table.insert(problems, string.format("altura do corpo %.2f (esperado %.2f)", headMax.Y - legMin.Y, expected))
	end
	local parts = basePartsOf(model)
	local count = model:GetAttribute("PartCount")
	if count ~= nil and count ~= #parts - 1 and count ~= #parts then
		table.insert(warnings, `PartCount registrado {count}, encontrado {#parts}`)
	end
	local minV, maxV = boundsOf(parts, pivot)
	local size = (maxV - minV) / scale
	local max = Config.MaxBounds
	if size.X > max.X or size.Y > max.Y or size.Z > max.Z then
		table.insert(warnings, string.format("caixa total grande: %.1f x %.1f x %.1f (corpo = %d)", size.X, size.Y, size.Z, Config.BodyHeight))
	end
	return problems, warnings
end

------------------------------------------------------------------------------------
-- Lote (ferramentas)

-- Acha o modelo de origem pelo caminho "Categoria.Sub.Nome" dentro do pack. Irmãos com o
-- MESMO nome (ex.: dois "Hisoka" em HXH) vêm da auditoria como "Nome (2ª ocorrência)": o
-- N-ésimo filho com esse nome, na ordem do arquivo.
local OCCURRENCE = "^(.-) %((%d+)ª ocorrência%)$"
function Pipeline.findSource(pack: Instance, path: string): Model?
	local current: Instance? = pack
	for name in string.gmatch(path, "[^%.]+") do
		local parent = current
		if not parent then
			break
		end
		local base, nth = string.match(name, OCCURRENCE)
		if base and nth then
			current = nil
			local seen = 0
			for _, child in parent:GetChildren() do
				if child.Name == base then
					seen += 1
					if seen == tonumber(nth) then
						current = child
						break
					end
				end
			end
		else
			current = parent:FindFirstChild(name)
		end
	end
	if current and current:IsA("Model") then
		return current
	end
	return nil
end

-- MISSING_SOURCE: nomes PARECIDOS no pack (mesma pasta; ignora maiúsculas e espaços), para o
-- relatório. Nunca escolhe sozinho: o SourcePath do catálogo é que tem de ser corrigido.
local function looseName(name: string): string
	return string.lower((string.gsub(name, "%s+", "")))
end
function Pipeline.sourceCandidates(pack: Instance, path: string): { string }
	local segments = string.split(path, ".")
	local parent: Instance = pack
	local prefix = {}
	for i, segment in segments do
		local child = Pipeline.findSource(parent, segment) or parent:FindFirstChild(segment)
		if not child or i == #segments then
			local target = looseName((string.gsub(segment, " %(%d+ª ocorrência%)$", "")))
			local found = {}
			for _, sibling in parent:GetChildren() do
				local name = looseName(sibling.Name)
				if #name >= 3 and #target >= 3 and (name == target or string.find(name, target, 1, true) or string.find(target, name, 1, true)) then
					local full = table.clone(prefix)
					table.insert(full, sibling.Name)
					table.insert(found, `"{table.concat(full, ".")}"`)
				end
			end
			table.sort(found)
			return found
		end
		table.insert(prefix, segment)
		parent = child
	end
	return {}
end

-- Sanitiza todos de CharacterAssetConfig.Assets (ou só "ids"). Devolve (Folder, relatórios)
function Pipeline.buildAll(pack: Instance, ids: { string }?): (Folder, { Report })
	local folder = Instance.new("Folder")
	folder.Name = Config.StorageName
	local list = ids
	if not list then
		local all = {}
		for id in Config.Assets do
			table.insert(all, id)
		end
		table.sort(all)
		list = all
	end
	local reports = {}
	for _, id in list :: { string } do
		local spec = Config.Assets[id]
		local source = spec and Pipeline.findSource(pack, spec.SourcePath)
		if not source then
			local report = newReport(id)
			report.sourceCandidates = if spec then Pipeline.sourceCandidates(pack, spec.SourcePath) else {}
			table.insert(report.problems, `modelo de origem não encontrado: "{if spec then spec.SourcePath else id}" · candidatos: {if #report.sourceCandidates == 0 then "nenhum" else table.concat(report.sourceCandidates, ", ")}`)
			table.insert(reports, report)
			continue
		end
		local model, report = Pipeline.sanitize(source, id)
		if model then
			model.Parent = folder
		end
		table.insert(reports, report)
	end
	return folder, reports
end

--[[
	Alternativa ao python tools/build_characters.py, direto no Studio, em modo EDIÇÃO (sem Play:
	no Play os scripts do pack rodariam). Na Barra de comandos:
	    print(require(game.ReplicatedStorage.Shared.Modules.CharacterAssetPipeline).buildInStudio())
	Cria ReplicatedStorage.CharacterAssets a partir do Workspace.Anime Pack. Para o build do Rojo:
	botão direito em ReplicatedStorage.CharacterAssets > Save to File... > assets/Characters.rbxm.
]]
function Pipeline.buildInStudio(): string
	if game:GetService("RunService"):IsRunning() then
		error("use em modo EDIÇÃO (pare o Play): no Play os scripts do pack rodam")
	end
	local pack = workspace:FindFirstChild(Config.SourcePackName)
	if not pack then
		error(`Workspace.{Config.SourcePackName} não encontrado`)
	end
	local folder, reports = Pipeline.buildAll(pack)
	local storage = game:GetService("ReplicatedStorage")
	local old = storage:FindFirstChild(Config.StorageName)
	if old then
		old:Destroy()
	end
	folder.Parent = storage
	local lines = { `{#folder:GetChildren()}/{#reports} assets em ReplicatedStorage.{Config.StorageName}` }
	for _, report in reports do
		table.insert(lines, `{report.CharacterId}: {report.status} {report.originalParts} -> {report.sanitizedParts} peças {table.concat(report.problems, "; ")}`)
	end
	return table.concat(lines, "\n")
end

return Pipeline
