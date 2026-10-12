--!strict
--[[
	IndexController: janela ÍNDICE com todos os personagens.
	Não descoberto: silhueta (ViewportFrame tingido de preto) e "???".
	Topo: "12 / 24 DESCOBERTOS" + % + marcos (25/50/75/100%) com recompensa.
	Os ViewportFrames só são criados quando a janela abre pela primeira vez.
	No Studio, os PILOTOS do pipeline de assets aparecem no fim (🧪), fora do progresso.
	"✦N" = variantes descobertas (Index[id].Variants, opcional).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local CharacterConfig = require(Shared.Config.CharacterConfig)
local IndexConfig = require(Shared.Config.IndexConfig)
local CharacterModelFactory = require(Shared.Modules.CharacterModelFactory)
local CharacterAssetConfig = require(Shared.Config.CharacterAssetConfig)
local Localization = require(Shared.Localization.Localization)

local UI = script.Parent.Parent.UI
local UIKit = require(UI.UIKit)
local Theme = require(UI.UITheme)
local DataController = require(script.Parent.DataController)

local IndexController = {}

local window: UIKit.Window
local grid: ScrollingFrame
local progressLabel: TextLabel
local progressFill: Frame
local milestoneRow: Frame
local cards: { [string]: { viewport: ViewportFrame, name: TextLabel, rarity: TextLabel, count: TextLabel, stroke: UIStroke } } = {}
local built = false

-- Roster do Índice + pilotos (só no Studio: validação do pipeline, não contam no progresso)
local function visibleCharacters(): { CharacterConfig.Character }
	local list = table.clone(CharacterConfig.List)
	if RunService:IsStudio() then
		for _, pilot in CharacterConfig.Pilots do
			table.insert(list, pilot)
		end
	end
	return list
end

local function buildCards()
	built = true
	for _, character in visibleCharacters() do
		local frame = UIKit.new("Frame", { BackgroundColor3 = Theme.Colors.Card, LayoutOrder = character.IndexNumber }, grid)
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
		local model = CharacterModelFactory.build(character.Id, { aura = false, vfx = CharacterAssetConfig.VFXModes.Index })
		model:PivotTo(CFrame.Angles(0, math.pi * 0.85, 0))
		model.Parent = viewport
		UIKit.text(frame, { text = "#" .. character.IndexNumber, size = UDim2.fromOffset(40, 20), position = UDim2.fromOffset(6, 4), align = Enum.TextXAlignment.Left, color = Theme.Colors.TextMuted })
		local count = UIKit.text(frame, { text = "", size = UDim2.fromOffset(50, 20), position = UDim2.new(1, -6, 0, 4), anchor = Vector2.new(1, 0), align = Enum.TextXAlignment.Right })
		local name = UIKit.text(frame, { size = UDim2.new(1, -8, 0.17, 0), position = UDim2.new(0.5, 0, 0.64, 0), anchor = Vector2.new(0.5, 0) })
		local rarity = UIKit.text(frame, { size = UDim2.new(1, -8, 0.14, 0), position = UDim2.new(0.5, 0, 0.82, 0), anchor = Vector2.new(0.5, 0) })
		cards[character.Id] = { viewport = viewport, name = name, rarity = rarity, count = count, stroke = stroke }
	end
end

function IndexController.Refresh()
	if not window.isOpen then
		return
	end
	if not built then
		buildCards()
	end
	local index = DataController.Get("Index") or {}
	local rewards = DataController.Get("IndexRewards") or {}
	local found = 0
	for _, character in visibleCharacters() do
		local entry = index[character.Id]
		local card = cards[character.Id]
		local color = UIKit.rarityColor(character.Rarity)
		if entry then
			if not character.Pilot then
				found += 1
			end
			local variants = 0
			for _ in entry.Variants or {} do
				variants += 1
			end
			card.viewport.ImageColor3 = Color3.new(1, 1, 1)
			card.name.Text = (if character.Pilot then "🧪 " else "") .. character.Name
			card.rarity.Text = Localization.t("rarity." .. character.Rarity)
			card.rarity.TextColor3 = color
			card.count.Text = "x" .. tostring(entry.Count or 1) .. (if variants > 1 then ` ✦{variants}` else "")
			card.stroke.Color = color
		else
			card.viewport.ImageColor3 = Color3.new(0, 0, 0)
			card.name.Text = "???"
			card.rarity.Text = Localization.t("rarity." .. character.Rarity)
			card.rarity.TextColor3 = UIKit.darken(color, 0.35)
			card.count.Text = ""
			card.stroke.Color = Theme.Colors.Locked
		end
	end
	local total = CharacterConfig.Count
	local percent = math.floor(found / total * 100)
	progressLabel.Text = Localization.t("index.progress", { found = found, total = total, percent = percent })
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
	progressLabel = UIKit.text(content, { size = UDim2.new(0.5, 0, 0, 34), position = UDim2.fromOffset(12, 8), align = Enum.TextXAlignment.Left })
	local bar = UIKit.new("Frame", { BackgroundColor3 = Theme.Colors.Card, Size = UDim2.new(0.5, -24, 0, 14), Position = UDim2.fromOffset(12, 46) }, content)
	UIKit.corner(bar, 7)
	progressFill = UIKit.new("Frame", { BackgroundColor3 = Theme.Colors.Success, Size = UDim2.fromScale(0, 1) }, bar)
	UIKit.corner(progressFill, 7)
	milestoneRow = UIKit.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(0.5, -12, 0, 40), Position = UDim2.new(1, -12, 0, 12), AnchorPoint = Vector2.new(1, 0) }, content)
	local layout = UIKit.list(milestoneRow, true, 6)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	grid = UIKit.new("ScrollingFrame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -16, 1, -76),
		Position = UDim2.fromOffset(8, 70),
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
		if key == "Index" or key == "IndexRewards" then
			IndexController.Refresh()
		end
	end)
end

return IndexController
