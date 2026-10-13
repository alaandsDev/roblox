--!strict
--[[
	IndexController: janela ÍNDICE.
	Topo: coleção PRINCIPAL "37 / 112 DESCOBERTOS" (só F2P: completar nunca depende de Robux) +
	marcos (25/50/75/100%) e, separado, "💎 Premium 2 / 9".
	Abas: uma por Dice F2P (16, com "5/8" de cada) + Premium. Só a aba aberta cria cards
	(ViewportFrames), e cada card é criado uma única vez (cache): no máximo ~8 por aba.
	Não descoberto: silhueta (ViewportFrame tingido de preto) e "???".
	"✦N" = variantes descobertas (Index[id].Variants, opcional).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local CharacterConfig = require(Shared.Config.CharacterConfig)
local IndexConfig = require(Shared.Config.IndexConfig)
local DiceConfig = require(Shared.Config.DiceConfig)
local RarityConfig = require(Shared.Config.RarityConfig)
local RollConfig = require(Shared.Config.RollConfig)
local DiceCore = require(Shared.Modules.DiceCore)
local CharacterModelFactory = require(Shared.Modules.CharacterModelFactory)
local CharacterAssetConfig = require(Shared.Config.CharacterAssetConfig)
local Localization = require(Shared.Localization.Localization)

local UI = script.Parent.Parent.UI
local UIKit = require(UI.UIKit)
local Theme = require(UI.UITheme)
local DataController = require(script.Parent.DataController)

local IndexController = {}

local PREMIUM_TAB = "Premium"

local window: UIKit.Window
local grid: ScrollingFrame
local tabRow: ScrollingFrame
local progressLabel: TextLabel
local premiumLabel: TextLabel
local progressFill: Frame
local milestoneRow: Frame
local cards: { [string]: { frame: Frame, viewport: ViewportFrame, name: TextLabel, rarity: TextLabel, count: TextLabel, stroke: UIStroke } } = {}
local tabs: { [string]: TextButton } = {}
local core = DiceCore.new(DiceConfig, CharacterConfig, RarityConfig, RollConfig)
local selectedTab: string? = nil

local function charactersOf(tab: string): { string }
	if tab == PREMIUM_TAB then
		local ids = {}
		for _, character in CharacterConfig.Premium do
			table.insert(ids, character.Id)
		end
		return ids
	end
	return core:charactersFor(tab)
end

local function card(id: string, order: number)
	local existing = cards[id]
	if existing then
		existing.frame.LayoutOrder = order
		existing.frame.Visible = true
		return existing
	end
	local character = CharacterConfig.ById[id]
	local frame = UIKit.new("Frame", { BackgroundColor3 = Theme.Colors.Card, LayoutOrder = order }, grid)
	UIKit.corner(frame, Theme.CornerRadiusSmall)
	local stroke = UIKit.stroke(frame, 3, Theme.Colors.Locked, true)
	local viewport = UIKit.new("ViewportFrame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -8, 0.62, 0),
		Position = UDim2.fromOffset(4, 4),
		Ambient = Color3.fromRGB(170, 170, 185),
	}, frame)
	local camera = Instance.new("Camera")
	camera.FieldOfView = 38
	camera.CFrame = CFrame.lookAt(Vector3.new(0, 4.5, 15), Vector3.new(0, 3.6, 0))
	camera.Parent = viewport
	viewport.CurrentCamera = camera
	local model = CharacterModelFactory.build(id, { aura = false, vfx = CharacterAssetConfig.VFXModes.Index })
	model:PivotTo(CFrame.Angles(0, math.pi * 0.85, 0))
	model.Parent = viewport
	UIKit.text(frame, { text = "#" .. character.IndexNumber, size = UDim2.fromOffset(48, 20), position = UDim2.fromOffset(6, 4), align = Enum.TextXAlignment.Left, color = Theme.Colors.TextMuted })
	local count = UIKit.text(frame, { text = "", size = UDim2.fromOffset(50, 20), position = UDim2.new(1, -6, 0, 4), anchor = Vector2.new(1, 0), align = Enum.TextXAlignment.Right })
	local name = UIKit.text(frame, { size = UDim2.new(1, -8, 0.17, 0), position = UDim2.new(0.5, 0, 0.64, 0), anchor = Vector2.new(0.5, 0) })
	local rarity = UIKit.text(frame, { size = UDim2.new(1, -8, 0.14, 0), position = UDim2.new(0.5, 0, 0.82, 0), anchor = Vector2.new(0.5, 0) })
	local entry = { frame = frame, viewport = viewport, name = name, rarity = rarity, count = count, stroke = stroke }
	cards[id] = entry
	return entry
end

local function discovered(index: any, ids: { string }): number
	local n = 0
	for _, id in ids do
		if index[id] then
			n += 1
		end
	end
	return n
end

function IndexController.Refresh()
	if not window.isOpen then
		return
	end
	local index = DataController.Get("Index") or {}
	local rewards = DataController.Get("IndexRewards") or {}
	local tab = selectedTab or DataController.Get("EquippedDice") or DiceConfig.Default
	if tab ~= PREMIUM_TAB and not core:isRollable(tab) then
		tab = DiceConfig.Default
	end
	selectedTab = tab

	-- Abas: Dice (descobertos / total) + Premium
	for id, button in tabs do
		local ids = charactersOf(id)
		local label = if id == PREMIUM_TAB then "💎 Premium" else Localization.t("dice." .. id)
		button.Text = `{label}  {discovered(index, ids)}/{#ids}`
		button.BackgroundColor3 = if id == tab then Theme.Colors.Primary else Theme.Colors.Card
	end

	-- Cards só da aba aberta
	for _, entry in cards do
		entry.frame.Visible = false
	end
	for order, id in charactersOf(tab) do
		local character = CharacterConfig.ById[id]
		local entry = card(id, order)
		local seen = index[id]
		local color = UIKit.rarityColor(character.Rarity)
		if seen then
			local variants = 0
			for _ in seen.Variants or {} do
				variants += 1
			end
			entry.viewport.ImageColor3 = Color3.new(1, 1, 1)
			entry.name.Text = character.Name
			entry.rarity.Text = Localization.t("rarity." .. character.Rarity)
			entry.rarity.TextColor3 = color
			entry.count.Text = "x" .. tostring(seen.Count or 1) .. (if variants > 1 then ` ✦{variants}` else "")
			entry.stroke.Color = color
		else
			entry.viewport.ImageColor3 = Color3.new(0, 0, 0)
			entry.name.Text = "???"
			entry.rarity.Text = Localization.t("rarity." .. character.Rarity)
			entry.rarity.TextColor3 = UIKit.darken(color, 0.35)
			entry.count.Text = ""
			entry.stroke.Color = Theme.Colors.Locked
		end
	end

	-- Coleção principal (112 F2P) e Premium (9) separados
	local found, foundPremium = 0, 0
	for _, character in CharacterConfig.List do
		if index[character.Id] then
			found += 1
		end
	end
	for _, character in CharacterConfig.Premium do
		if index[character.Id] then
			foundPremium += 1
		end
	end
	local total = CharacterConfig.Count
	local percent = math.floor(found / total * 100)
	progressLabel.Text = Localization.t("index.progress", { found = found, total = total, percent = percent })
	premiumLabel.Text = Localization.t("index.premium", { found = foundPremium, total = CharacterConfig.PremiumCount })
	progressFill.Size = UDim2.fromScale(found / total, 1)
	for _, child in milestoneRow:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	for i, milestone in IndexConfig.Milestones do
		local done = rewards[tostring(milestone.Percent)] == true
		local chip = UIKit.new("Frame", { BackgroundColor3 = if done then Theme.Colors.Success else Theme.Colors.Card, Size = UDim2.fromOffset(150, 34), LayoutOrder = i }, milestoneRow)
		UIKit.corner(chip, 8)
		UIKit.text(chip, { text = `{milestone.Percent}% · 💎{milestone.Reward.Amount}{if done then " ✓" else ""}`, size = UDim2.fromScale(0.9, 0.8), position = UDim2.fromScale(0.5, 0.5), anchor = Vector2.new(0.5, 0.5) })
	end
end

function IndexController.Init()
	window = UIKit.window({ name = "Index", title = Localization.t("index.title"), icon = "📘", size = Theme.PopupSizes.Large, header = Color3.fromRGB(70, 130, 255) })
	local content = window.content
	progressLabel = UIKit.text(content, { size = UDim2.new(0.34, 0, 0, 34), position = UDim2.fromOffset(12, 8), align = Enum.TextXAlignment.Left })
	premiumLabel = UIKit.text(content, { size = UDim2.new(0.16, 0, 0, 28), position = UDim2.new(0.34, 18, 0, 11), align = Enum.TextXAlignment.Left, color = Theme.Colors.Gems })
	local bar = UIKit.new("Frame", { BackgroundColor3 = Theme.Colors.Card, Size = UDim2.new(0.5, -24, 0, 14), Position = UDim2.fromOffset(12, 46) }, content)
	UIKit.corner(bar, 7)
	progressFill = UIKit.new("Frame", { BackgroundColor3 = Theme.Colors.Success, Size = UDim2.fromScale(0, 1) }, bar)
	UIKit.corner(progressFill, 7)
	milestoneRow = UIKit.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(0.5, -12, 0, 40), Position = UDim2.new(1, -12, 0, 12), AnchorPoint = Vector2.new(1, 0) }, content)
	local layout = UIKit.list(milestoneRow, true, 6)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	-- Abas: 16 Dice + Premium (rolagem horizontal)
	tabRow = UIKit.new("ScrollingFrame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -16, 0, 44),
		Position = UDim2.fromOffset(8, 68),
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		CanvasSize = UDim2.new(),
		ScrollingDirection = Enum.ScrollingDirection.X,
		ScrollBarThickness = 4,
		BorderSizePixel = 0,
	}, content)
	UIKit.list(tabRow, true, 6)
	local tabIds = {}
	for _, dice in core:diceList() do
		table.insert(tabIds, dice.Id)
	end
	table.insert(tabIds, PREMIUM_TAB)
	for order, id in tabIds do
		tabs[id] = UIKit.button(tabRow, {
			text = id,
			size = UDim2.fromOffset(190, 38),
			order = order,
			color = Theme.Colors.Card,
			onClick = function()
				selectedTab = id
				IndexController.Refresh()
			end,
		})
	end
	grid = UIKit.new("ScrollingFrame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -16, 1, -124),
		Position = UDim2.fromOffset(8, 118),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 8,
		BorderSizePixel = 0,
	}, content)
	UIKit.new("UIGridLayout", { CellSize = UDim2.fromOffset(128, 160), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder }, grid)
	window.Opened:Connect(IndexController.Refresh)
end

function IndexController.Start()
	DataController.Changed:Connect(function(key)
		if key == "Index" or key == "IndexRewards" or key == "EquippedDice" then
			IndexController.Refresh()
		end
	end)
end

return IndexController
