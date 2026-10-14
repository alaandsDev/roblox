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
	  - releaseScope(container) ao fechar/refazer a janela; clear() destrói tudo.
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

local slots: { [GuiObject]: Slot } = {}
local pool: { [string]: { Model } } = {}
local pooledCount = 0
local activeCount = 0
local connection: RBXScriptConnection? = nil
local elapsed = 0

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
	for container, slot in slots do
		if container.Parent == nil then
			release(slot)
			slots[container] = nil
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
	slots[container] = {
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
	local slot = slots[container]
	if slot then
		release(slot)
		slots[container] = nil
		slot.viewport:Destroy()
	end
end

-- Solta todos os retratos dentro de `scope` (janela fechando / lista sendo refeita)
function CharacterPreview.releaseScope(scope: Instance)
	for container, slot in slots do
		if container == scope or container:IsDescendantOf(scope) or container.Parent == nil then
			release(slot)
			slots[container] = nil
		end
	end
end

-- Esvazia o pool (modelos destruídos) — ao fechar a MOCHILA
function CharacterPreview.trimPool()
	for k, list in pool do
		for _, model in list do
			model:Destroy()
		end
		pool[k] = nil
	end
	pooledCount = 0
end

function CharacterPreview.clear()
	for container in slots do
		CharacterPreview.detach(container)
	end
	CharacterPreview.trimPool()
end

function CharacterPreview.stats(): { registered: number, active: number, pooled: number }
	local registered = 0
	for _ in slots do
		registered += 1
	end
	return { registered = registered, active = activeCount, pooled = pooledCount }
end

return CharacterPreview
