--!strict
--[[
	CharacterPreview: retrato REAL do personagem (CharacterAssets + CharacterModelFactory) num
	ViewportFrame, usado pela MOCHILA (corpo) e pela faixa de rolls recentes (cabeça/busto).
	Um único sistema, um único gerenciador:
	  - LAZY: só monta o modelo quando o card está na tela (com margem) — 100+ cards não viram
	    100+ modelos;
	  - TETO de previews ativos (MaxActive): o resto espera ficar visível;
	  - POOL por personagem|variante: card que sai da tela devolve o modelo, o próximo reaproveita
	    (sem montar de novo); pool limitado (MaxPooled);
	  - UM loop central (Heartbeat, ~5x/s) e só quando há algo registrado;
	  - releaseScope(container) ao fechar a janela; clear() destrói tudo.
	  - IDEMPOTENTE: set(container, id, variante, enquadramento) num container que já mostra o
	    MESMO personagem não faz nada (o retrato continua montado — sem piscar). Listas devem
	    atualizar cards existentes em vez de destruir e recriar (MOCHILA / rolls recentes).
	  - Instrumentação (testes/DEV): stats() conta modelos montados/reaproveitados/destruídos e
	    ViewportFrames criados/destruídos.
	  - FALLBACK: só se a montagem falhar de verdade, fica o ícone (texto) do personagem.
	Os modelos vêm SEM aura/VFX (VFXModes.Inventory) e sem scripts (assets sanitizados).
]]

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local CharacterModelFactory = require(Shared.Modules.CharacterModelFactory)
local CharacterAssetConfig = require(Shared.Config.CharacterAssetConfig)

local CharacterPreview = {}

CharacterPreview.MaxActive = 36
CharacterPreview.MaxPooled = 24
CharacterPreview.UpdateInterval = 0.2
CharacterPreview.Margin = 120 -- px além da área visível (pré-carrega quem está quase entrando)

export type Framing = "body" | "head"

type Slot = {
	container: GuiObject,
	viewport: ViewportFrame,
	camera: Camera,
	fallback: TextLabel?,
	characterId: string,
	variant: string,
	framing: Framing,
	model: Model?,
	failed: boolean,
}

-- Slots por ID numérico gravado no container (atributo PreviewSlotId), não pela Instance como
-- chave de tabela: a identidade fica estável mesmo onde a mesma Instance chega como userdata
-- diferente (ex.: ambiente de testes), e o set() idempotente sempre acha o slot certo.
local slots: { [number]: Slot } = {}
local nextSlotId = 0
local SLOT_ATTR = "PreviewSlotId"

local function slotIdOf(container: Instance, create: boolean): number?
	local id = container:GetAttribute(SLOT_ATTR)
	if type(id) == "number" then
		return id
	end
	if not create then
		return nil
	end
	nextSlotId += 1
	container:SetAttribute(SLOT_ATTR, nextSlotId)
	return nextSlotId
end

local function slotOf(container: Instance): Slot?
	local id = slotIdOf(container, false)
	return if id then slots[id] else nil
end
local pool: { [string]: { Model } } = {}
local pooledCount = 0
local activeCount = 0
local connection: RBXScriptConnection? = nil
local elapsed = 0
-- contadores cumulativos (stats()): provam que troca de seleção/novo roll não remonta tudo
local counters = { created = 0, reused = 0, destroyed = 0, viewportsCreated = 0, viewportsDestroyed = 0, setNoop = 0 }

local function key(slot: Slot): string
	return slot.characterId .. "|" .. slot.variant
end

-- Visível = dentro da tela e dentro do ScrollingFrame pai (com margem). Trocável nos testes.
function CharacterPreview._isVisible(gui: GuiObject): boolean
	local screen = gui:FindFirstAncestorWhichIsA("LayerCollector")
	if not screen or (screen:IsA("ScreenGui") and not screen.Enabled) then
		return false
	end
	local node: Instance? = gui
	while node and node:IsA("GuiObject") do
		if not node.Visible then
			return false
		end
		node = node.Parent
	end
	-- (sem layout calculado — ex.: fora do motor — não há como saber: trata como invisível)
	local okPos, pos = pcall(function()
		return gui.AbsolutePosition
	end)
	local okSize, size = pcall(function()
		return gui.AbsoluteSize
	end)
	if not okPos or not okSize or size.X <= 0 or size.Y <= 0 then
		return false
	end
	local scroller = gui:FindFirstAncestorWhichIsA("ScrollingFrame")
	if scroller then
		local sp, ss = scroller.AbsolutePosition, scroller.AbsoluteSize
		local m = CharacterPreview.Margin
		if pos.Y + size.Y < sp.Y - m or pos.Y > sp.Y + ss.Y + m or pos.X + size.X < sp.X - m or pos.X > sp.X + ss.X + m then
			return false
		end
	end
	return true
end

local function frame(slot: Slot, model: Model)
	local ok, cf, size = pcall(function()
		return model:GetBoundingBox()
	end)
	if not ok then
		-- sem caixa (fora do motor): altura conhecida do personagem, centro acima do pivô (pés)
		local h = CharacterModelFactory.height(slot.characterId)
		cf, size = model:GetPivot() * CFrame.new(0, h / 2, 0), Vector3.new(2, h, 1)
	end
	local height = math.max(size.Y, 0.5)
	local center = cf.Position
	if slot.framing == "head" then
		-- rosto/cabelo/cabeça + topo do torso
		local top = center.Y + height / 2
		local focus = Vector3.new(center.X, top - height * 0.17, center.Z)
		local viewHeight = height * 0.42
		local distance = (viewHeight / 2) / math.tan(math.rad(slot.camera.FieldOfView / 2)) + size.Z / 2
		slot.camera.CFrame = CFrame.lookAt(focus + Vector3.new(0, height * 0.02, distance), focus)
	else
		local distance = (height * 0.62) / math.tan(math.rad(slot.camera.FieldOfView / 2)) + size.Z / 2
		slot.camera.CFrame = CFrame.lookAt(center + Vector3.new(0, height * 0.05, distance), center)
	end
end

local function acquire(slot: Slot): Model?
	local list = pool[key(slot)]
	if list and #list > 0 then
		pooledCount -= 1
		counters.reused += 1
		return table.remove(list)
	end
	local ok, model = pcall(CharacterModelFactory.build, slot.characterId, {
		variant = slot.variant,
		aura = false,
		vfx = CharacterAssetConfig.VFXModes.Inventory,
	})
	if not ok then
		return nil
	end
	counters.created += 1
	model:PivotTo(CFrame.Angles(0, math.pi, 0))
	return model
end

local function release(slot: Slot)
	local model = slot.model
	if not model then
		return
	end
	slot.model = nil
	activeCount -= 1
	model.Parent = nil
	local k = key(slot)
	if pooledCount < CharacterPreview.MaxPooled then
		pool[k] = pool[k] or {}
		table.insert(pool[k], model)
		pooledCount += 1
	else
		counters.destroyed += 1
		model:Destroy()
	end
end

local function render(slot: Slot)
	if slot.model or slot.failed or activeCount >= CharacterPreview.MaxActive then
		return
	end
	local model = acquire(slot)
	if not model then
		slot.failed = true
		if slot.fallback then
			slot.fallback.Visible = true
		end
		return
	end
	model.Parent = slot.viewport
	slot.model = model
	activeCount += 1
	frame(slot, model)
	if slot.fallback then
		slot.fallback.Visible = false
	end
end

function CharacterPreview.update()
	for id, slot in slots do
		if slot.container.Parent == nil then
			release(slot)
			slots[id] = nil
		elseif CharacterPreview._isVisible(slot.viewport) then
			render(slot)
		else
			release(slot)
		end
	end
end

local function ensureLoop()
	if connection then
		return
	end
	connection = RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < CharacterPreview.UpdateInterval then
			return
		end
		elapsed = 0
		if next(slots) == nil then
			return
		end
		CharacterPreview.update()
	end)
end

--[[
	Coloca o retrato dentro de `container` (preenche o container; fica atrás do texto do card).
	fallbackText: ícone mostrado só se a montagem falhar.
]]
function CharacterPreview.attach(container: GuiObject, characterId: string, variant: string?, framing: Framing?, fallbackText: string?): ViewportFrame
	CharacterPreview.detach(container)
	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "Preview"
	viewport.BackgroundTransparency = 1
	viewport.Size = UDim2.fromScale(1, 1)
	viewport.Ambient = Color3.fromRGB(190, 190, 205)
	viewport.LightColor = Color3.fromRGB(255, 250, 240)
	viewport.LightDirection = Vector3.new(-0.4, -1, -0.6)
	viewport.ZIndex = container.ZIndex
	counters.viewportsCreated += 1
	local camera = Instance.new("Camera")
	camera.FieldOfView = if framing == "head" then 30 else 32
	camera.Parent = viewport
	viewport.CurrentCamera = camera
	viewport.Parent = container
	local fallback: TextLabel? = nil
	if fallbackText then
		local label = Instance.new("TextLabel")
		label.Name = "Fallback"
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.Text = fallbackText
		label.TextScaled = true
		label.Visible = false
		label.Parent = viewport
		fallback = label
	end
	slots[slotIdOf(container, true) :: number] = {
		container = container,
		viewport = viewport,
		camera = camera,
		fallback = fallback,
		characterId = characterId,
		variant = variant or "Normal",
		framing = framing or "body",
		model = nil,
		failed = false,
	}
	ensureLoop()
	return viewport
end

function CharacterPreview.detach(container: GuiObject)
	local slot = slotOf(container)
	if slot then
		release(slot)
		slots[slotIdOf(container, false) :: number] = nil
		counters.viewportsDestroyed += 1
		slot.viewport:Destroy()
	end
end

--[[
	Versão IDEMPOTENTE do attach: se o container já mostra o mesmo personagem/variante/enquadramento,
	não faz nada (retrato continua montado). Se mudou, troca só o modelo (o ViewportFrame e a câmera
	ficam). Sem registro ainda: equivale ao attach.
]]
function CharacterPreview.set(container: GuiObject, characterId: string, variant: string?, framing: Framing?, fallbackText: string?): ViewportFrame
	local slot = slotOf(container)
	local v = variant or "Normal"
	local f: Framing = framing or "body"
	if slot and slot.viewport.Parent ~= nil and slot.viewport:IsDescendantOf(container) then
		if slot.characterId == characterId and slot.variant == v and slot.framing == f then
			counters.setNoop += 1
			return slot.viewport
		end
		release(slot)
		slot.characterId, slot.variant, slot.framing, slot.failed = characterId, v, f, false
		if slot.fallback and fallbackText then
			slot.fallback.Text = fallbackText
			slot.fallback.Visible = false
		end
		if CharacterPreview._isVisible(slot.viewport) then
			render(slot)
		end
		return slot.viewport
	end
	return CharacterPreview.attach(container, characterId, variant, framing, fallbackText)
end

-- Solta todos os retratos dentro de `scope` (janela fechando / lista sendo refeita)
function CharacterPreview.releaseScope(scope: Instance)
	for id, slot in slots do
		local container = slot.container
		if container == scope or container.Parent == nil or container:IsDescendantOf(scope) then
			release(slot)
			slots[id] = nil
		end
	end
end

-- Esvazia o pool (modelos destruídos) — ao fechar a MOCHILA
function CharacterPreview.trimPool()
	for k, list in pool do
		for _, model in list do
			counters.destroyed += 1
			model:Destroy()
		end
		pool[k] = nil
	end
	pooledCount = 0
end

function CharacterPreview.clear()
	for _, slot in slots do
		CharacterPreview.detach(slot.container)
	end
	CharacterPreview.trimPool()
end

function CharacterPreview.stats(): { [string]: number }
	local registered = 0
	for _ in slots do
		registered += 1
	end
	return {
		registered = registered,
		active = activeCount,
		pooled = pooledCount,
		created = counters.created,
		reused = counters.reused,
		destroyed = counters.destroyed,
		viewportsCreated = counters.viewportsCreated,
		viewportsDestroyed = counters.viewportsDestroyed,
		setNoop = counters.setNoop,
	}
end

return CharacterPreview
