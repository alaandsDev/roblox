--!strict
--[[
	UIKit: peças de interface prontas, todas seguindo o UITheme.
	    UIKit.screen("HUD", 10)                         -> ScreenGui com escala automática
	    UIKit.button(parent, { text = "...", color = ..., onClick = fn })
	    UIKit.iconButton(parent, { icon = "🎲", text = "ROLAR", size = ... })
	    UIKit.badge(button)                             -> função setBadge(texto | nil)
	    UIKit.window({ name, title, icon, size, header })-> janela com fundo escurecido, X e animação
	    UIKit.Windows.open("Inventory") / toggle / close -> uma janela aberta por vez
	    UIKit.confirm(texto, sim, nao, onYes)
	    UIKit.sound("Click")
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.Shared
local AssetLoader = require(Shared.Modules.AssetLoader)
local Signal = require(Shared.Modules.Signal)
local Localization = require(Shared.Localization.Localization)
local RarityConfig = require(Shared.Config.RarityConfig)
local Theme = require(script.Parent.UITheme)

local UIKit = {}
UIKit.Theme = Theme

local player = Players.LocalPlayer

------------------------------------------------------------------------------------
-- Básico

function UIKit.new(className: string, props: { [string]: any }?, parent: Instance?): any
	local instance = Instance.new(className)
	if props then
		for key, value in props do
			(instance :: any)[key] = value
		end
	end
	if parent then
		instance.Parent = parent
	end
	return instance
end

function UIKit.corner(parent: Instance, radius: number?): UICorner
	return UIKit.new("UICorner", { CornerRadius = UDim.new(0, radius or Theme.CornerRadius) }, parent)
end

function UIKit.stroke(parent: Instance, thickness: number?, color: Color3?, border: boolean?): UIStroke
	return UIKit.new("UIStroke", {
		Thickness = thickness or Theme.StrokeThickness,
		Color = color or Theme.StrokeColor,
		ApplyStrokeMode = if border then Enum.ApplyStrokeMode.Border else Enum.ApplyStrokeMode.Contextual,
	}, parent)
end

function UIKit.gradient(parent: Instance, top: Color3, bottom: Color3, rotation: number?): UIGradient
	return UIKit.new("UIGradient", { Color = ColorSequence.new(top, bottom), Rotation = rotation or 90 }, parent)
end

function UIKit.padding(parent: Instance, px: number?): UIPadding
	local p = UDim.new(0, px or Theme.Padding)
	return UIKit.new("UIPadding", { PaddingLeft = p, PaddingRight = p, PaddingTop = p, PaddingBottom = p }, parent)
end

function UIKit.list(parent: Instance, horizontal: boolean?, gap: number?, align: string?): UIListLayout
	return UIKit.new("UIListLayout", {
		FillDirection = if horizontal then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical,
		Padding = UDim.new(0, gap or Theme.Spacing),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = if align == "center" then Enum.HorizontalAlignment.Center else Enum.HorizontalAlignment.Left,
		VerticalAlignment = if align == "center" then Enum.VerticalAlignment.Center else Enum.VerticalAlignment.Top,
	}, parent)
end

function UIKit.lighten(color: Color3, amount: number): Color3
	return color:Lerp(Color3.new(1, 1, 1), amount)
end

function UIKit.darken(color: Color3, amount: number): Color3
	return color:Lerp(Color3.new(0, 0, 0), amount)
end

function UIKit.rarityColor(rarityId: string): Color3
	local rarity = RarityConfig.ById[rarityId]
	if not rarity then
		return Color3.new(1, 1, 1)
	end
	return Color3.fromRGB(rarity.Color[1], rarity.Color[2], rarity.Color[3])
end

export type TextOptions = {
	text: string?,
	size: UDim2?,
	position: UDim2?,
	anchor: Vector2?,
	color: Color3?,
	font: Enum.Font?,
	stroke: number?,
	align: Enum.TextXAlignment?,
	name: string?,
	order: number?,
	z: number?,
	wrap: boolean?,
}

function UIKit.text(parent: Instance, opts: TextOptions): TextLabel
	local label = UIKit.new("TextLabel", {
		Name = opts.name or "Text",
		BackgroundTransparency = 1,
		Size = opts.size or UDim2.fromScale(1, 1),
		Position = opts.position or UDim2.new(),
		AnchorPoint = opts.anchor or Vector2.zero,
		Font = opts.font or Theme.Font,
		Text = opts.text or "",
		TextColor3 = opts.color or Theme.Colors.Text,
		TextScaled = true,
		TextWrapped = opts.wrap == true,
		TextXAlignment = opts.align or Enum.TextXAlignment.Center,
		LayoutOrder = opts.order or 0,
		ZIndex = opts.z or 1,
	}, parent)
	if opts.stroke ~= 0 then
		UIKit.stroke(label, opts.stroke or Theme.TextStroke)
	end
	return label
end

------------------------------------------------------------------------------------
-- Som

local FALLBACK_SOUNDS: { [string]: string } = {
	Click = "rbxasset://sounds/electronicpingshort.wav",
	Reward = "rbxasset://sounds/electronicpingshort.wav",
	Error = "rbxasset://sounds/electronicpingshort.wav",
	Whoosh = "rbxasset://sounds/swordlunge.wav",
	Impact = "rbxasset://sounds/action_jump_land.mp3",
	Coin = "rbxasset://sounds/electronicpingshort.wav",
	-- Camadas da cinemática (TODO_ASSET: sons finais em Assets.Sounds com estes nomes)
	RareTrigger = "rbxasset://sounds/electronicpingshort.wav",
	RiftHum = "rbxasset://sounds/swordlunge.wav",
	FallingWhoosh = "rbxasset://sounds/swordlunge.wav",
	ImpactBass = "rbxasset://sounds/action_jump_land.mp3",
	ImpactDebris = "rbxasset://sounds/action_jump_land.mp3",
	RevealStinger = "rbxasset://sounds/electronicpingshort.wav",
	MythicStinger = "rbxasset://sounds/electronicpingshort.wav",
	DivineStinger = "rbxasset://sounds/electronicpingshort.wav",
	SecretStinger = "rbxasset://sounds/electronicpingshort.wav",
}
-- Volumes por som (camadas da cinemática não estouram o áudio)
local VOLUMES: { [string]: number } = {
	Click = 0.3,
	Coin = 0.25,
	Whoosh = 0.5,
	Impact = 0.8,
	Reward = 0.45,
	Error = 0.25,
	RareTrigger = 0.4,
	RiftHum = 0.35,
	FallingWhoosh = 0.5,
	ImpactBass = 0.85,
	ImpactDebris = 0.5,
	RevealStinger = 0.5,
	MythicStinger = 0.55,
	DivineStinger = 0.6,
	SecretStinger = 0.65,
}

-- Sons já existentes em Assets.Sounds (ver ASSETS.md) usados por cada nome lógico
local ALIASES: { [string]: string } = {
	Click = "UIClick",
	Coin = "Purchase",
	Reward = "LevelUp",
	Impact = "Impact",
	ImpactBass = "Impact",
	ImpactDebris = "Impact",
	RevealStinger = "LevelUp",
	MythicStinger = "LevelUp",
	DivineStinger = "Rebirth",
	SecretStinger = "Rebirth",
}

-- Toca Assets.Sounds.<nome> (TODO_ASSET), o asset equivalente (ALIASES) ou um som embutido
function UIKit.sound(name: string, volume: number?, pitch: number?)
	local sound: Sound? = nil
	local asset = AssetLoader.clone("Sounds", name)
	if not asset and ALIASES[name] then
		asset = AssetLoader.clone("Sounds", ALIASES[name])
	end
	if asset and asset:IsA("Sound") then
		sound = asset
	else
		local fallback = FALLBACK_SOUNDS[name]
		if not fallback then
			return
		end
		sound = Instance.new("Sound")
		assert(sound)
		sound.SoundId = fallback
	end
	assert(sound)
	sound.Volume = volume or VOLUMES[name] or 0.4
	sound.PlaybackSpeed = pitch or 1
	sound.Parent = SoundService
	sound:Play()
	sound.Ended:Once(function()
		sound:Destroy()
	end)
	task.delay(6, function()
		if sound.Parent then
			sound:Destroy()
		end
	end)
end

------------------------------------------------------------------------------------
-- Telas

function UIKit.isMobile(): boolean
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

local function viewportSize(): Vector2
	local camera = Workspace.CurrentCamera
	return if camera then camera.ViewportSize else Theme.ReferenceResolution
end

-- Escala da interface pelo tamanho da tela (PC, tablet, celular em pé/deitado)
function UIKit.uiScale(): number
	local size = viewportSize()
	local ref = Theme.ReferenceResolution
	return math.clamp(math.min(size.X / ref.X, size.Y / ref.Y), 0.45, 1.25)
end

local scaled: { UIScale } = {}
local function refreshScales()
	local value = UIKit.uiScale()
	for _, s in scaled do
		s.Scale = value
	end
end

function UIKit.screen(name: string, order: number?): ScreenGui
	local gui = UIKit.new("ScreenGui", {
		Name = name,
		ResetOnSpawn = false,
		DisplayOrder = order or 10,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = false,
	}, player:WaitForChild("PlayerGui"))
	return gui
end

-- Container que ocupa a tela toda e escala junto (filhos usam tamanhos de referência)
function UIKit.scaledRoot(gui: Instance, name: string?): Frame
	local root = UIKit.new("Frame", {
		Name = name or "Root",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, gui)
	local s = UIKit.new("UIScale", { Scale = UIKit.uiScale() }, root)
	table.insert(scaled, s)
	-- Reveals/cinemáticas criam e destroem roots: sai da lista ao ser destruído (sem vazamento)
	s.Destroying:Connect(function()
		local index = table.find(scaled, s)
		if index then
			table.remove(scaled, index)
		end
	end)
	-- Compensa a escala para continuar ocupando a tela toda
	local function fit()
		root.Size = UDim2.fromScale(1 / s.Scale, 1 / s.Scale)
	end
	s:GetPropertyChangedSignal("Scale"):Connect(fit)
	fit()
	return root
end

task.spawn(function()
	local camera = Workspace.CurrentCamera
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(refreshScales)
	end
end)

------------------------------------------------------------------------------------
-- Botões

local function pressAnimation(button: GuiButton)
	local s = button:FindFirstChildOfClass("UIScale") or UIKit.new("UIScale", {}, button)
	button.MouseEnter:Connect(function()
		TweenService:Create(s, TweenInfo.new(0.1), { Scale = 1.06 }):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(s, TweenInfo.new(0.1), { Scale = 1 }):Play()
	end)
	button.MouseButton1Down:Connect(function()
		TweenService:Create(s, TweenInfo.new(0.06), { Scale = 0.92 }):Play()
	end)
	button.MouseButton1Up:Connect(function()
		TweenService:Create(s, TweenInfo.new(0.1, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end)
end

export type ButtonOptions = {
	name: string?,
	text: string?,
	icon: string?,
	color: Color3?,
	size: UDim2?,
	position: UDim2?,
	anchor: Vector2?,
	order: number?,
	textColor: Color3?,
	onClick: (() -> ())?,
	silent: boolean?,
}

-- Botão retangular (ações de janela)
function UIKit.button(parent: Instance, opts: ButtonOptions): TextButton
	local color = opts.color or Theme.Colors.Primary
	local button = UIKit.new("TextButton", {
		Name = opts.name or "Button",
		Size = opts.size or UDim2.fromOffset(Theme.ButtonSizes.Action.X, Theme.ButtonSizes.Action.Y),
		Position = opts.position or UDim2.new(),
		AnchorPoint = opts.anchor or Vector2.zero,
		BackgroundColor3 = color,
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = opts.order or 0,
	}, parent)
	UIKit.corner(button, Theme.CornerRadiusSmall)
	UIKit.stroke(button, Theme.StrokeThickness, Theme.StrokeColor, true)
	UIKit.gradient(button, UIKit.lighten(color, 0.25), UIKit.darken(color, 0.15))
	local text = (opts.icon and (opts.icon .. " ") or "") .. (opts.text or "")
	UIKit.text(button, {
		name = "Label",
		text = text,
		size = UDim2.new(1, -16, 1, -10),
		position = UDim2.fromScale(0.5, 0.5),
		anchor = Vector2.new(0.5, 0.5),
		color = opts.textColor,
	})
	pressAnimation(button)
	if opts.onClick then
		local onClick = opts.onClick
		button.Activated:Connect(function()
			if not opts.silent then
				UIKit.sound("Click")
			end
			onClick()
		end)
	end
	return button
end

function UIKit.setButtonText(button: Instance, text: string)
	local label = button:FindFirstChild("Label")
	if label and label:IsA("TextLabel") then
		label.Text = text
	end
end

function UIKit.setButtonColor(button: GuiObject, color: Color3)
	button.BackgroundColor3 = color
	local gradient = button:FindFirstChildOfClass("UIGradient")
	if gradient then
		gradient.Color = ColorSequence.new(UIKit.lighten(color, 0.25), UIKit.darken(color, 0.15))
	end
end

-- Botão "quadrado" de HUD: ícone grande + texto embaixo (estilo simulator)
function UIKit.iconButton(parent: Instance, opts: ButtonOptions): TextButton
	local color = opts.color or Theme.Colors.Primary
	local button = UIKit.new("TextButton", {
		Name = opts.name or "IconButton",
		Size = opts.size or UDim2.fromOffset(Theme.ButtonSizes.Side.X, Theme.ButtonSizes.Side.Y),
		Position = opts.position or UDim2.new(),
		AnchorPoint = opts.anchor or Vector2.zero,
		BackgroundColor3 = color,
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = opts.order or 0,
	}, parent)
	UIKit.corner(button, Theme.CornerRadius)
	UIKit.stroke(button, Theme.StrokeThickness + 1, Theme.StrokeColor, true)
	UIKit.gradient(button, UIKit.lighten(color, 0.3), UIKit.darken(color, 0.2), 90)
	UIKit.text(button, {
		name = "Icon",
		text = opts.icon or "",
		size = UDim2.fromScale(0.8, 0.62),
		position = UDim2.fromScale(0.5, 0.05),
		anchor = Vector2.new(0.5, 0),
		stroke = 0,
	})
	UIKit.text(button, {
		name = "Label",
		text = opts.text or "",
		size = UDim2.fromScale(0.96, 0.3),
		position = UDim2.fromScale(0.5, 0.97),
		anchor = Vector2.new(0.5, 1),
		stroke = 2.5,
	})
	pressAnimation(button)
	if opts.onClick then
		local onClick = opts.onClick
		button.Activated:Connect(function()
			UIKit.sound("Click")
			onClick()
		end)
	end
	return button
end

-- Bolinha de aviso no canto do botão. Devolve setBadge(texto | nil)
function UIKit.badge(button: GuiObject): (string?) -> ()
	local badge = UIKit.new("Frame", {
		Name = "Badge",
		Size = UDim2.fromOffset(30, 30),
		Position = UDim2.new(1, 6, 0, -8),
		AnchorPoint = Vector2.new(1, 0),
		BackgroundColor3 = Theme.Colors.Danger,
		Visible = false,
		ZIndex = 5,
	}, button)
	UIKit.corner(badge, 15)
	UIKit.stroke(badge, 2.5, Color3.new(1, 1, 1), true)
	local label = UIKit.text(badge, { text = "!", size = UDim2.fromScale(0.8, 0.8), position = UDim2.fromScale(0.5, 0.5), anchor = Vector2.new(0.5, 0.5), z = 6, stroke = 0 })
	return function(text: string?)
		badge.Visible = text ~= nil
		label.Text = text or ""
	end
end

------------------------------------------------------------------------------------
-- Janelas (popups)

export type Window = {
	name: string,
	gui: ScreenGui,
	panel: Frame,
	content: Frame,
	title: TextLabel,
	Opened: any,
	Closed: any,
	isOpen: boolean,
	Open: (self: Window) -> (),
	Close: (self: Window) -> (),
}

local Windows = {}
UIKit.Windows = Windows
local registry: { [string]: Window } = {}
local current: Window? = nil

export type WindowOptions = {
	name: string,
	title: string,
	icon: string?,
	size: Vector2?,
	header: Color3?,
	order: number?,
}

function UIKit.window(opts: WindowOptions): Window
	local gui = UIKit.screen("Window_" .. opts.name, opts.order or 50)
	gui.Enabled = false
	gui.IgnoreGuiInset = true
	local dim = UIKit.new("TextButton", {
		Name = "Dim",
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Theme.Colors.Dim,
		BackgroundTransparency = Theme.DimTransparency,
		Size = UDim2.fromScale(1, 1),
	}, gui)
	local root = UIKit.scaledRoot(gui)
	local size = opts.size or Theme.PopupSizes.Medium
	local panel = UIKit.new("Frame", {
		Name = "Panel",
		Size = UDim2.fromOffset(size.X, size.Y),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Theme.Colors.PanelBackground,
	}, root)
	UIKit.corner(panel, Theme.CornerRadius + 4)
	UIKit.stroke(panel, Theme.StrokeThickness + 2, Theme.StrokeColor, true)
	local openScale = UIKit.new("UIScale", { Scale = 1 }, panel)
	-- Sombra
	local shadow = UIKit.new("Frame", {
		Name = "Shadow",
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromOffset(0, Theme.Shadow.Offset * 2),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = Theme.Shadow.Transparency,
		ZIndex = 0,
	}, panel)
	UIKit.corner(shadow, Theme.CornerRadius + 4)

	local headerColor = opts.header or Theme.Colors.HeaderRed
	local header = UIKit.new("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, Theme.HeaderHeight),
		BackgroundColor3 = headerColor,
		ZIndex = 2,
	}, panel)
	UIKit.corner(header, Theme.CornerRadius + 4)
	UIKit.gradient(header, UIKit.lighten(headerColor, 0.15), UIKit.darken(headerColor, 0.15))
	-- Cobre os cantos de baixo do header
	UIKit.new("Frame", {
		Size = UDim2.new(1, 0, 0, 16),
		Position = UDim2.new(0, 0, 1, -16),
		BackgroundColor3 = UIKit.darken(headerColor, 0.15),
		BorderSizePixel = 0,
		ZIndex = 2,
	}, header)
	UIKit.text(header, {
		name = "Icon",
		text = opts.icon or "",
		size = UDim2.fromOffset(52, 52),
		position = UDim2.new(0, 12, 0.5, 0),
		anchor = Vector2.new(0, 0.5),
		z = 3,
		stroke = 0,
	})
	local title = UIKit.text(header, {
		name = "Title",
		text = opts.title,
		size = UDim2.new(1, -150, 0, 44),
		position = UDim2.new(0, 72, 0.5, 0),
		anchor = Vector2.new(0, 0.5),
		align = Enum.TextXAlignment.Left,
		z = 3,
		stroke = 3,
	})
	local close = UIKit.new("TextButton", {
		Name = "Close",
		Size = UDim2.fromOffset(Theme.ButtonSizes.Close.X, Theme.ButtonSizes.Close.Y),
		Position = UDim2.new(1, -6, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = Theme.Colors.Danger,
		AutoButtonColor = false,
		Text = "",
		ZIndex = 3,
	}, header)
	UIKit.corner(close, Theme.CornerRadiusSmall)
	UIKit.stroke(close, 3, Theme.StrokeColor, true)
	UIKit.text(close, { text = "X", size = UDim2.fromScale(0.75, 0.75), position = UDim2.fromScale(0.5, 0.5), anchor = Vector2.new(0.5, 0.5), z = 4, stroke = 3 })
	pressAnimation(close)

	local content = UIKit.new("Frame", {
		Name = "Content",
		BackgroundColor3 = Theme.Colors.PanelInner,
		Size = UDim2.new(1, -24, 1, -(Theme.HeaderHeight + 18)),
		Position = UDim2.new(0, 12, 0, Theme.HeaderHeight + 6),
		ClipsDescendants = true,
		ZIndex = 1,
	}, panel)
	UIKit.corner(content, Theme.CornerRadiusSmall)

	local window = {
		name = opts.name,
		gui = gui,
		panel = panel,
		content = content,
		title = title,
		Opened = Signal.new(),
		Closed = Signal.new(),
		isOpen = false,
	} :: any

	function window.Open(self: Window)
		if current and current ~= self then
			current:Close()
		end
		current = self
		if self.isOpen then
			return
		end
		self.isOpen = true
		gui.Enabled = true
		openScale.Scale = Theme.OpenScaleFrom
		TweenService:Create(openScale, TweenInfo.new(Theme.OpenTime, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		self.Opened:Fire()
	end
	function window.Close(self: Window)
		if not self.isOpen then
			return
		end
		self.isOpen = false
		gui.Enabled = false
		if current == self then
			current = nil
		end
		self.Closed:Fire()
	end
	close.Activated:Connect(function()
		UIKit.sound("Click")
		window:Close()
	end)
	dim.Activated:Connect(function()
		window:Close()
	end)
	registry[opts.name] = window
	return window
end

function Windows.get(name: string): Window?
	return registry[name]
end

function Windows.open(name: string)
	local window = registry[name]
	if window then
		window:Open()
	end
end

function Windows.close(name: string)
	local window = registry[name]
	if window then
		window:Close()
	end
end

function Windows.toggle(name: string)
	local window = registry[name]
	if window then
		if window.isOpen then
			window:Close()
		else
			window:Open()
		end
	end
end

function Windows.closeAll()
	if current then
		current:Close()
	end
end

function Windows.anyOpen(): boolean
	return current ~= nil
end

------------------------------------------------------------------------------------
-- Confirmação ("Vender 23 personagens por $4.25K?")

local confirmGui: ScreenGui? = nil
function UIKit.confirm(message: string, yesText: string, noText: string, onYes: () -> ())
	if confirmGui then
		confirmGui:Destroy()
	end
	local gui = UIKit.screen("Confirm", 90)
	gui.IgnoreGuiInset = true
	confirmGui = gui
	UIKit.new("Frame", { BackgroundColor3 = Color3.new(), BackgroundTransparency = 0.5, Size = UDim2.fromScale(1, 1) }, gui)
	local root = UIKit.scaledRoot(gui)
	local panel = UIKit.new("Frame", {
		Size = UDim2.fromOffset(480, 230),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Theme.Colors.PanelBackground,
	}, root)
	UIKit.corner(panel, Theme.CornerRadius)
	UIKit.stroke(panel, 4, Theme.StrokeColor, true)
	UIKit.text(panel, { text = message, size = UDim2.new(1, -40, 0, 100), position = UDim2.fromOffset(20, 24), wrap = true })
	local function finish()
		gui:Destroy()
		if confirmGui == gui then
			confirmGui = nil
		end
	end
	UIKit.button(panel, {
		text = noText,
		color = Theme.Colors.Danger,
		size = UDim2.fromOffset(190, 60),
		position = UDim2.new(0.5, -12, 1, -24),
		anchor = Vector2.new(1, 1),
		onClick = finish,
	})
	UIKit.button(panel, {
		text = yesText,
		color = Theme.Colors.Success,
		size = UDim2.fromOffset(190, 60),
		position = UDim2.new(0.5, 12, 1, -24),
		anchor = Vector2.new(0, 1),
		onClick = function()
			finish()
			onYes()
		end,
	})
end

-- Texto traduzido (atalho)
function UIKit.t(key: string, params: { [string]: any }?): string
	return Localization.t(key, params)
end

return UIKit
