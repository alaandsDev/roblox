--!strict
--[[
	HUD provisório de navegação no topo da tela: [CENTRO] [CASA] [LOJA].
	O cliente só PEDE o teleporte (RequestTeleport); quem move o personagem é o servidor.
	Cada botão: ícone, texto, hover (PC), efeito de clique, som e cooldown de 1 s.
	Responsivo: UIScale ajustado ao tamanho da tela (PC, tablet, celular em pé/deitado).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Modules.Net)
local Localization = require(Shared.Localization.Localization)
local AssetLoader = require(Shared.Modules.AssetLoader)

local COOLDOWN = 1
-- NavButton do design system (HUD icon-first): pílula escura translúcida + chip colorido do ícone
local BUTTON_WIDTH, BUTTON_HEIGHT, GAP = 150, 52, 10

-- Ícones provisórios (emoji); trocar por imagens da Store depois (tools/FindAssets.lua)
local BUTTONS = {
	{ id = "Center", text = "nav.center", icon = "🎲", color = Color3.fromRGB(255, 190, 50) },
	{ id = "Home", text = "nav.home", icon = "🏠", color = Color3.fromRGB(70, 165, 255) },
	{ id = "Shop", text = "nav.shop", icon = "🛒", color = Color3.fromRGB(80, 215, 90) },
}

local NavigationController = {}

local busyUntil = 0
local buttons: { TextButton } = {}

local function playClick()
	local sound = AssetLoader.clone("Sounds", "UIClick")
	if sound and sound:IsA("Sound") then
		sound.Volume = 0.4
		sound.Parent = SoundService
		sound:Play()
		sound.Ended:Once(function()
			sound:Destroy()
		end)
	end
end

local function setEnabled(enabled: boolean)
	for _, button in buttons do
		button.AutoButtonColor = enabled
		local overlay = button:FindFirstChild("Cooldown") :: Frame
		overlay.Visible = not enabled
		if not enabled then
			overlay.Size = UDim2.fromScale(1, 1)
			TweenService:Create(overlay, TweenInfo.new(COOLDOWN, Enum.EasingStyle.Linear), { Size = UDim2.fromScale(0, 1) }):Play()
		end
	end
end

local function makeButton(info: any, parent: Instance, order: number): TextButton
	local button = Instance.new("TextButton")
	button.Name = info.id
	button.LayoutOrder = order
	button.Size = UDim2.fromOffset(BUTTON_WIDTH, BUTTON_HEIGHT)
	button.BackgroundColor3 = Color3.fromRGB(28, 27, 40)
	button.BackgroundTransparency = 0.2
	button.Text = ""
	button.AutoButtonColor = true
	button.ClipsDescendants = true
	button.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = button
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2.5
	stroke.Color = info.color
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = button
	-- chip colorido do ícone (mesma linguagem do CurrencyDisplay)
	local chip = Instance.new("Frame")
	chip.Name = "Chip"
	chip.BackgroundColor3 = info.color
	chip.Position = UDim2.new(0, 4, 0.5, 0)
	chip.AnchorPoint = Vector2.new(0, 0.5)
	chip.Size = UDim2.fromOffset(BUTTON_HEIGHT - 8, BUTTON_HEIGHT - 8)
	chip.Parent = button
	local chipCorner = Instance.new("UICorner")
	chipCorner.CornerRadius = UDim.new(0.5, 0)
	chipCorner.Parent = chip
	local scale = Instance.new("UIScale")
	scale.Name = "Feedback"
	scale.Parent = button

	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.BackgroundTransparency = 1
	icon.Position = UDim2.new(0, 9, 0, 9)
	icon.Size = UDim2.new(0, BUTTON_HEIGHT - 18, 1, -18)
	icon.ZIndex = 2
	icon.Text = info.icon
	icon.TextScaled = true
	icon.Parent = button

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.BackgroundTransparency = 1
	label.Position = UDim2.new(0, BUTTON_HEIGHT - 2, 0, 8)
	label.Size = UDim2.new(1, -(BUTTON_HEIGHT + 6), 1, -16)
	label.Font = Enum.Font.FredokaOne
	label.Text = Localization.t(info.text)
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	local textStroke = Instance.new("UIStroke")
	textStroke.Thickness = 2
	textStroke.Color = Color3.fromRGB(30, 25, 45)
	textStroke.Parent = label
	label.Parent = button

	local cooldown = Instance.new("Frame")
	cooldown.Name = "Cooldown"
	cooldown.BackgroundColor3 = Color3.new(0, 0, 0)
	cooldown.BackgroundTransparency = 0.55
	cooldown.BorderSizePixel = 0
	cooldown.Visible = false
	cooldown.ZIndex = 5
	cooldown.Parent = button

	local function tweenScale(value: number)
		TweenService:Create(scale, TweenInfo.new(0.08), { Scale = value }):Play()
	end
	button.MouseEnter:Connect(function()
		tweenScale(1.06)
	end)
	button.MouseLeave:Connect(function()
		tweenScale(1)
	end)
	button.MouseButton1Down:Connect(function()
		tweenScale(0.92)
	end)
	button.MouseButton1Up:Connect(function()
		tweenScale(1)
	end)

	button.Activated:Connect(function()
		if os.clock() < busyUntil then
			return
		end
		busyUntil = os.clock() + COOLDOWN
		playClick()
		setEnabled(false)
		task.delay(COOLDOWN, setEnabled, true)
		task.spawn(Net.request, "RequestTeleport", info.id)
	end)
	return button
end

function NavigationController.Start()
	local player = Players.LocalPlayer
	local gui = Instance.new("ScreenGui")
	gui.Name = "NavigationHud"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 10
	gui.Parent = player:WaitForChild("PlayerGui")

	local bar = Instance.new("Frame")
	bar.Name = "Bar"
	bar.AnchorPoint = Vector2.new(0.5, 0)
	bar.Position = UDim2.new(0.5, 0, 0, 6)
	bar.Size = UDim2.fromOffset(BUTTON_WIDTH * #BUTTONS + GAP * (#BUTTONS - 1), BUTTON_HEIGHT)
	bar.BackgroundTransparency = 1
	bar.Parent = gui

	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.Padding = UDim.new(0, GAP)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = bar

	-- Escala pela tela: em celular em pé fica menor, mas nunca ilegível
	local uiScale = Instance.new("UIScale")
	uiScale.Parent = bar
	local camera = workspace.CurrentCamera
	local function rescale()
		local viewport = camera.ViewportSize
		local fitWidth = (viewport.X - 24) / bar.Size.X.Offset
		uiScale.Scale = math.clamp(math.min(fitWidth, viewport.Y / 620, 1), 0.55, 1)
	end
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
	rescale()

	for order, info in BUTTONS do
		table.insert(buttons, makeButton(info, bar, order))
	end
end

return NavigationController
