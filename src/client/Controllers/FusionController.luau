--!strict
--[[
	FusionController (Fase 8): janela FUSÃO (altar no Hub).
	Lista os personagens com 3+ cópias iguais (mesma variante, livres) e o resultado:
	"3x Dragon Knight → PRATA" + custo. O servidor confere tudo (FusionCore).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
			size = UDim2.new(0.55, 0, 0, 30),
			position = UDim2.fromOffset(80, 8),
			align = Enum.TextXAlignment.Left,
		})
		UIKit.text(row, { text = Localization.t("fusion.have", { count = #group.uids }) .. "  ·  " .. NumberFormatter.money(cost), size = UDim2.new(0.55, 0, 0, 24), position = UDim2.fromOffset(80, 44), align = Enum.TextXAlignment.Left, color = Theme.Colors.TextMuted })
		UIKit.button(row, {
			name = "Fuse_" .. group.id,
			text = "✨ " .. Localization.t("fusion.button"),
			color = Theme.Colors.Purple,
			size = UDim2.fromOffset(160, 54),
			position = UDim2.new(1, -10, 0.5, 0),
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
	window.Opened:Connect(FusionController.Refresh)
end

function FusionController.Start()
	DataController.InventoryChanged:Connect(function()
		FusionController.Refresh()
	end)
end

return FusionController
