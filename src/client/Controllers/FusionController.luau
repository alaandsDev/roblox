--!strict
--[[
	FusionController (Fase 8): janela FUSÃO (altar no Hub).
	Lista os personagens com 3+ cópias iguais (mesma variante, livres) e o resultado:
	"3x Dragon Knight → PRATA" + custo. O servidor confere tudo (FusionCore).
	[FUNDIR 1×] = comportamento de sempre. [⚡ FUNDIR MÁX.] = a cadeia inteira da família numa
	operação do servidor: prévia curta (fusões, maior resultado, o que sobra, custo) -> confirmar ->
	UMA animação/aviso com o resumo (nenhum ViewportFrame por unidade).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage.Shared
local FusionConfig = require(Shared.Config.FusionConfig)
local VariantConfig = require(Shared.Config.VariantConfig)
local CharacterConfig = require(Shared.Config.CharacterConfig)
local NumberFormatter = require(Shared.Modules.NumberFormatter)
local Localization = require(Shared.Localization.Localization)
local Net = require(Shared.Modules.Net)

local UI = script.Parent.Parent.UI
local UIKit = require(UI.UIKit)
local Theme = require(UI.UITheme)
local DataController = require(script.Parent.DataController)
local NotificationController = require(script.Parent.NotificationController)

local FusionController = {}

local window: UIKit.Window
local list: ScrollingFrame
local empty: TextLabel
local confirmFrame: Frame
local confirmText: TextLabel
local resultFrame: Frame
local resultText: TextLabel
local pending: { id: string, fusions: number }? = nil
local maxBusy = false

local function variantName(id: string): string
	return Localization.t("variant." .. id)
end

-- "1× Celestial · 2× Vazio" (maior variante primeiro)
function FusionController.DescribeCounts(counts: { [string]: number }?): string
	local parts = {}
	local order = table.clone(VariantConfig.List)
	table.sort(order, function(a, b)
		return a.Order > b.Order
	end)
	for _, v in order do
		local n = counts and counts[v.Id]
		if n and n > 0 then
			table.insert(parts, string.format("%d× %s", n, variantName(v.Id)))
		end
	end
	return if #parts > 0 then table.concat(parts, " · ") else "—"
end

-- ⚡ FUNDIR MÁX.: pede a PRÉVIA ao servidor e mostra a confirmação
function FusionController.RequestMax(characterId: string)
	if maxBusy then
		return
	end
	local result = Net.request("FuseMax", characterId, false)
	if not result.ok then
		NotificationController.Show("error." .. tostring(result.code))
		return
	end
	local preview = result.data
	pending = { id = characterId, fusions = preview.fusions }
	local character = CharacterConfig.ById[characterId]
	confirmText.Text = Localization.t("fusion.max_preview", {
		name = character and character.Name or characterId,
		fusions = preview.fusions,
		top = if preview.top then variantName(preview.top) else "—",
		left = FusionController.DescribeCounts(preview.remaining),
		cost = NumberFormatter.money(preview.cost),
	}) .. (if preview.limitedByMoney then "\n" .. Localization.t("fusion.max_limited") else "")
	confirmFrame.Visible = true
end

-- Confirmou: UMA operação no servidor, UMA animação
function FusionController.ConfirmMax(): boolean
	local p = pending
	if not p or maxBusy then
		return false
	end
	maxBusy = true
	confirmFrame.Visible = false
	pending = nil
	local result = Net.request("FuseMax", p.id, true, p.fusions)
	maxBusy = false
	if not result.ok then
		NotificationController.Show("error." .. tostring(result.code))
		return false
	end
	UIKit.sound("RevealStinger")
	resultText.Text = Localization.t("fusion.max_done", { fusions = result.data.fusions, created = FusionController.DescribeCounts(result.data.created) })
	resultFrame.Visible = true
	resultFrame.Size = UDim2.new(0.86, 0, 0, 10)
	TweenService:Create(resultFrame, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.new(0.86, 0, 0, 110) }):Play()
	task.delay(3.5, function()
		resultFrame.Visible = false
	end)
	return true
end

function FusionController.CancelMax()
	pending = nil
	confirmFrame.Visible = false
end

local function nextVariant(id: string): any
	local current = VariantConfig.ById[id]
	for _, v in VariantConfig.List do
		if current and v.Order == current.Order + 1 then
			return v
		end
	end
	return nil
end

local function free(data: any, uid: string): boolean
	local item = data.Inventory[uid]
	if not item or item.Locked or item.Favorite then
		return false
	end
	for _, equipped in data.EquippedCharacters do
		if equipped == uid then
			return false
		end
	end
	return true
end

function FusionController.Groups(data: any): { any }
	local buckets = {}
	for uid, item in data.Inventory do
		if free(data, uid) then
			local key = item.Id .. "|" .. (item.Variant or "Normal")
			buckets[key] = buckets[key] or { id = item.Id, variant = item.Variant or "Normal", uids = {} }
			table.insert(buckets[key].uids, uid)
		end
	end
	local out = {}
	for _, group in buckets do
		local target = nextVariant(group.variant)
		if target and #group.uids >= (FusionConfig.RequiredByTarget[target.Id] or FusionConfig.MaxRequired) then
			group.need = FusionConfig.RequiredByTarget[target.Id] or FusionConfig.MaxRequired
			table.sort(group.uids)
			table.insert(out, group)
		end
	end
	table.sort(out, function(a, b)
		return a.id .. a.variant < b.id .. b.variant
	end)
	return out
end

function FusionController.Refresh()
	local data = DataController.GetAll()
	if not data or not window.isOpen then
		return
	end
	for _, child in list:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	local groups = FusionController.Groups(data)
	empty.Visible = #groups == 0
	for i, group in groups do
		local character = CharacterConfig.ById[group.id]
		local target = nextVariant(group.variant)
		local cost = math.floor(character.BaseIncome * FusionConfig.CostSeconds * target.Order)
		local row = UIKit.new("Frame", { BackgroundColor3 = Theme.Colors.Card, Size = UDim2.new(1, -8, 0, 80), LayoutOrder = i }, list)
		UIKit.corner(row, Theme.CornerRadiusSmall)
		UIKit.stroke(row, 3, Color3.fromRGB(target.Color[1], target.Color[2], target.Color[3]), true)
		UIKit.text(row, { text = character.VisualTheme.Icon, size = UDim2.fromOffset(60, 60), position = UDim2.fromOffset(10, 10), stroke = 0 })
		UIKit.text(row, {
			text = string.format("%dx %s (%s) → %s", group.need, character.Name, Localization.t("variant." .. group.variant), Localization.t("variant." .. target.Id)),
			size = UDim2.new(1, -400, 0, 30),
			position = UDim2.fromOffset(80, 8),
			align = Enum.TextXAlignment.Left,
		})
		UIKit.text(row, { text = Localization.t("fusion.have", { count = #group.uids }) .. "  ·  " .. NumberFormatter.money(cost), size = UDim2.new(1, -400, 0, 24), position = UDim2.fromOffset(80, 44), align = Enum.TextXAlignment.Left, color = Theme.Colors.TextMuted })
		UIKit.button(row, {
			name = "FuseMax_" .. group.id,
			text = "⚡ " .. Localization.t("fusion.max_button"),
			color = Theme.Colors.Orange,
			size = UDim2.fromOffset(150, 54),
			position = UDim2.new(1, -10, 0.5, 0),
			anchor = Vector2.new(1, 0.5),
			onClick = function()
				task.spawn(FusionController.RequestMax, group.id)
			end,
		})
		UIKit.button(row, {
			name = "Fuse_" .. group.id,
			text = "✨ " .. Localization.t("fusion.button"),
			color = Theme.Colors.Purple,
			size = UDim2.fromOffset(130, 54),
			position = UDim2.new(1, -170, 0.5, 0),
			anchor = Vector2.new(1, 0.5),
			onClick = function()
				local uids = table.move(group.uids, 1, group.need, 1, {})
				local result = Net.request("Fuse", uids)
				if result.ok then
					UIKit.sound("RevealStinger")
					NotificationController.Show("fusion.done", { name = character.Name, variant = Localization.t("variant." .. result.data.variant) })
				else
					NotificationController.Show("error." .. tostring(result.code))
				end
			end,
		})
	end
end

function FusionController.Init()
	window = UIKit.window({ name = "Fusion", title = Localization.t("fusion.title"), icon = "✨", header = Color3.fromRGB(170, 80, 255) })
	UIKit.text(window.content, { text = Localization.t("fusion.hint"), size = UDim2.new(1, -24, 0, 26), position = UDim2.fromOffset(12, 8), color = Theme.Colors.TextMuted })
	list = UIKit.new("ScrollingFrame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -16, 1, -48),
		Position = UDim2.fromOffset(8, 40),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 8,
		BorderSizePixel = 0,
	}, window.content)
	UIKit.list(list, false, 8)
	empty = UIKit.text(window.content, { text = Localization.t("fusion.empty"), size = UDim2.new(0.9, 0, 0, 40), position = UDim2.fromScale(0.5, 0.5), anchor = Vector2.new(0.5, 0.5), color = Theme.Colors.TextMuted })
	-- Confirmação do FUNDIR MÁX. (por cima da lista, sem retratos)
	confirmFrame = UIKit.new("Frame", {
		Name = "FuseMaxConfirm",
		BackgroundColor3 = Color3.fromRGB(30, 24, 48),
		Size = UDim2.new(0.86, 0, 0, 250),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Visible = false,
		ZIndex = 20,
	}, window.content)
	UIKit.corner(confirmFrame, 14)
	UIKit.stroke(confirmFrame, 3, Theme.Colors.Orange, true)
	UIKit.text(confirmFrame, { name = "Title", text = "⚡ " .. Localization.t("fusion.max_title"), size = UDim2.new(1, -20, 0, 34), position = UDim2.fromOffset(10, 8), color = Theme.Colors.Orange, z = 21 })
	confirmText = UIKit.text(confirmFrame, { name = "Body", text = "", size = UDim2.new(1, -24, 0, 130), position = UDim2.fromOffset(12, 46), wrap = true, z = 21 })
	confirmText.TextScaled = true
	UIKit.button(confirmFrame, {
		name = "Cancel",
		text = Localization.t("fusion.max_cancel"),
		color = Color3.fromRGB(90, 90, 110),
		size = UDim2.fromOffset(150, 48),
		position = UDim2.new(0.5, -10, 1, -12),
		anchor = Vector2.new(1, 1),
		onClick = FusionController.CancelMax,
	})
	UIKit.button(confirmFrame, {
		name = "Confirm",
		text = "⚡ " .. Localization.t("fusion.max_confirm"),
		color = Theme.Colors.Orange,
		size = UDim2.fromOffset(190, 48),
		position = UDim2.new(0.5, 10, 1, -12),
		anchor = Vector2.new(0, 1),
		onClick = function()
			task.spawn(FusionController.ConfirmMax)
		end,
	})
	resultFrame = UIKit.new("Frame", {
		Name = "FuseMaxResult",
		BackgroundColor3 = Color3.fromRGB(60, 30, 90),
		Size = UDim2.new(0.86, 0, 0, 110),
		Position = UDim2.new(0.5, 0, 0, 44),
		AnchorPoint = Vector2.new(0.5, 0),
		Visible = false,
		ZIndex = 22,
		ClipsDescendants = true,
	}, window.content)
	UIKit.corner(resultFrame, 14)
	UIKit.stroke(resultFrame, 3, Color3.fromRGB(255, 220, 90), true)
	resultText = UIKit.text(resultFrame, { name = "Body", text = "", size = UDim2.new(1, -20, 1, -12), position = UDim2.fromOffset(10, 6), wrap = true, z = 23 })
	window.Opened:Connect(FusionController.Refresh)
end

function FusionController.Start()
	DataController.InventoryChanged:Connect(function()
		FusionController.Refresh()
	end)
end

return FusionController
