--!strict
--[[
	HudController: organização da HUD (segue a hierarquia da referência, com skin própria).

	    TOPO CENTRO     [CENTRO] [CASA] [LOJA]            (NavigationController)
	    TOPO DIREITA    [🎁 OFFLINE] [📅 DIÁRIO] [⚙️]
	    ESQUERDA        [LOJA] [RENASCIMENTO] [ÍNDICE]
	    DIREITA         reservado (VIP / roll especial / jackpot no futuro)
	    BAIXO CENTRO    [MOCHILA] [ROLAR] [MELHORIAS]     (ROLAR vem do RollController)
	    BAIXO ESQUERDA  $ dinheiro, 🍀 Luck, Impulso de Amigos

	Outros controllers usam HudController.Containers e HudController.SetBadge(nome, texto?).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local NumberFormatter = require(Shared.Modules.NumberFormatter)
local Formulas = require(Shared.Modules.GameFormulas)
local FriendBoostConfig = require(Shared.Config.FriendBoostConfig)
local Localization = require(Shared.Localization.Localization)

local UI = script.Parent.Parent.UI
local UIKit = require(UI.UIKit)
local Theme = require(UI.UITheme)
local DataController = require(script.Parent.DataController)
local NotificationController = require(script.Parent.NotificationController)

local HudController = {}

HudController.Containers = {} :: { [string]: Frame }
local badges: { [string]: (string?) -> () } = {}
local buttons: { [string]: GuiButton } = {}

local moneyLabel: TextLabel
local gemsLabel: TextLabel
local luckLabel: TextLabel
local boostLabel: TextLabel
local friendLabel: TextLabel

function HudController.SetBadge(name: string, text: string?)
	local set = badges[name]
	if set then
		set(text)
	end
end

function HudController.Button(name: string): GuiButton?
	return buttons[name]
end

-- Posição na tela do dinheiro (efeito de moedas voando)
function HudController.MoneyAnchor(): GuiObject?
	return moneyLabel
end

local function container(root: Instance, name: string, props: { [string]: any }): Frame
	local frame = UIKit.new("Frame", props, root)
	frame.Name = name
	frame.BackgroundTransparency = 1
	HudController.Containers[name] = frame
	return frame
end

local function refreshStats()
	local data = DataController.GetAll()
	if not data then
		return
	end
	moneyLabel.Text = NumberFormatter.money(data.Money or 0)
	gemsLabel.Text = NumberFormatter.abbreviate(data.Gems or 0)
	local now = os.time()
	-- Mostra a Luck EFETIVA (a que entra no sorteio, com retornos decrescentes)
	local luck = Formulas:effectiveLuck(data, now)
	luckLabel.Text = string.format("%sx", NumberFormatter.abbreviate(math.floor(luck * 100 + 0.5) / 100))
	local runtime = data.Runtime or {}
	friendLabel.Text = Localization.t("hud.friend_boost", { percent = math.floor((runtime.FriendBonus or 0) * 100 + 0.5) })
	local boost = data.Boosts and data.Boosts.Luck
	if boost and type(boost.ExpiresAt) == "number" and boost.ExpiresAt > now then
		boostLabel.Visible = true
		boostLabel.Text = Localization.t("hud.boost", { mult = boost.Multiplier, time = NumberFormatter.duration(boost.ExpiresAt - now) })
	else
		boostLabel.Visible = false
	end
end

--[[
	Layout responsivo (auditoria mobile). Medidas em "unidades da interface" (tela ÷ escala):
	    largo (PC/tablet deitado) -> layout padrão
	    estreito (< COMPACT_WIDTH) -> status (dinheiro/sorte) sobem para cima do histórico
	    em pé (altura > largura)  -> status no topo à esquerda; some a coluna da direita
	                                 (atalhos da loja; a loja continua no MERCADO) e o histórico
]]
local COMPACT_WIDTH = 1200
HudController.Mode = "wide"
local tutorialHidden = false

-- Tutorial: esconde os botões secundários (esquerda e direita) nos primeiros passos
function HudController.SetTutorialHidden(hidden: boolean)
	if tutorialHidden ~= hidden then
		tutorialHidden = hidden
		HudController.Layout()
	end
end

function HudController.Layout()
	local root = HudController.Containers.Left and HudController.Containers.Left.Parent
	if not root then
		return
	end
	local viewport = UIKit.viewportSize()
	local scale = UIKit.uiScale()
	local width = viewport.X / scale
	local mode = if viewport.Y > viewport.X then "portrait" elseif width < COMPACT_WIDTH then "compact" else "wide"
	HudController.Mode = mode
	root:SetAttribute("LayoutMode", mode)
	local stats = HudController.Containers.BottomLeft
	local right = HudController.Containers.Right
	local history = root:FindFirstChild("History")
	if mode == "portrait" then
		stats.AnchorPoint = Vector2.new(0, 0)
		stats.Position = UDim2.new(0, 16, 0, 70)
	elseif mode == "compact" then
		stats.AnchorPoint = Vector2.new(0, 1)
		stats.Position = UDim2.new(0, 16, 1, -(Theme.ButtonSizes.Roll.Y + 130))
	else
		stats.AnchorPoint = Vector2.new(0, 1)
		stats.Position = UDim2.new(0, 16, 1, -10)
	end
	right.Visible = mode ~= "portrait" and not tutorialHidden
	local left = HudController.Containers.Left
	left.Visible = not tutorialHidden
	-- Botões "só no retrato" (ex.: ✨ AURAS, cujo atalho normal fica na coluna da direita, que
	-- some no celular em pé): aparecem na coluna da esquerda e ela cresce para caber
	local shown = 0
	for _, child in left:GetChildren() do
		if child:IsA("GuiButton") then
			if child:GetAttribute("PortraitOnly") == true then
				child.Visible = mode == "portrait"
			end
			if child.Visible then
				shown += 1
			end
		end
	end
	left.Size = UDim2.fromOffset(Theme.ButtonSizes.Side.X, Theme.ButtonSizes.Side.Y * math.max(4, shown) + 12 * (math.max(4, shown) - 1))
	if history and history:IsA("GuiObject") then
		history.Visible = mode ~= "portrait"
	end
end

function HudController.Init()
	local gui = UIKit.screen("HUD", 5)
	-- Celular com notch/ilha: o HUD respeita a área segura do aparelho
	pcall(function()
		(gui :: any).ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
	end)
	local root = UIKit.scaledRoot(gui)

	-- ESQUERDA
	local left = container(root, "Left", {
		Size = UDim2.fromOffset(Theme.ButtonSizes.Side.X, Theme.ButtonSizes.Side.Y * 4 + 36),
		Position = UDim2.new(0, 14, 0.5, -10),
		AnchorPoint = Vector2.new(0, 0.5),
	})
	UIKit.list(left, false, 12)
	local function side(name: string, icon: string, key: string, color: Color3, order: number, onClick: () -> ())
		local button = UIKit.iconButton(left, { name = name, icon = icon, text = Localization.t(key), color = color, order = order, onClick = onClick })
		buttons[name] = button
		badges[name] = UIKit.badge(button)
		return button
	end
	side("Shop", "🎲", "hud.shop", Color3.fromRGB(240, 90, 200), 1, function()
		UIKit.Windows.toggle("DiceShop")
	end)
	side("Rebirth", "♻️", "hud.rebirth", Color3.fromRGB(235, 70, 80), 2, function()
		UIKit.Windows.toggle("Rebirth")
	end)
	side("Index", "📘", "hud.index", Color3.fromRGB(70, 140, 255), 3, function()
		UIKit.Windows.toggle("Index")
	end)
	side("Missions", "📜", "hud.missions", Color3.fromRGB(230, 150, 40), 4, function()
		UIKit.Windows.toggle("Missions")
	end)

	-- BAIXO CENTRO
	local bottom = container(root, "BottomCenter", {
		Size = UDim2.fromOffset(520, Theme.ButtonSizes.Roll.Y + 10),
		Position = UDim2.new(0.5, 0, 1, -10),
		AnchorPoint = Vector2.new(0.5, 1),
	})
	local bottomList = UIKit.list(bottom, true, 18, "center")
	bottomList.VerticalAlignment = Enum.VerticalAlignment.Bottom
	local bag = UIKit.iconButton(bottom, {
		name = "Backpack",
		icon = "🎒",
		text = Localization.t("hud.backpack"),
		color = Color3.fromRGB(110, 120, 255),
		size = UDim2.fromOffset(Theme.ButtonSizes.Bottom.X, Theme.ButtonSizes.Bottom.Y),
		order = 1,
		onClick = function()
			UIKit.Windows.toggle("Inventory")
		end,
	})
	buttons.Backpack = bag
	badges.Backpack = UIKit.badge(bag)
	local upgrades = UIKit.iconButton(bottom, {
		name = "Upgrades",
		icon = "⬆️",
		text = Localization.t("hud.upgrades"),
		color = Color3.fromRGB(70, 200, 90),
		size = UDim2.fromOffset(Theme.ButtonSizes.Bottom.X, Theme.ButtonSizes.Bottom.Y),
		order = 3,
		onClick = function()
			UIKit.Windows.toggle("Upgrades")
		end,
	})
	buttons.Upgrades = upgrades
	badges.Upgrades = UIKit.badge(upgrades)

	-- TOPO DIREITA
	-- (icon-first: chip pequeno + rótulo curto; toque de 74 px)
	local topRight = container(root, "TopRight", {
		Size = UDim2.fromOffset(300, 78),
		Position = UDim2.new(1, -12, 0, 6),
		AnchorPoint = Vector2.new(1, 0),
	})
	local trList = UIKit.list(topRight, true, 6)
	trList.HorizontalAlignment = Enum.HorizontalAlignment.Right
	local function pill(name: string, icon: string, text: string, color: Color3, order: number, onClick: () -> ())
		local button = UIKit.iconButton(topRight, {
			name = name,
			icon = icon,
			text = text,
			color = color,
			size = UDim2.fromOffset(74, 78),
			order = order,
			onClick = onClick,
		})
		buttons[name] = button
		badges[name] = UIKit.badge(button)
		return button
	end
	local offline = pill("Offline", "🎁", Localization.t("hud.offline"), Color3.fromRGB(80, 200, 110), 1, function()
		UIKit.Windows.open("Offline")
	end)
	offline.Visible = false
	pill("Daily", "📅", Localization.t("hud.daily"), Color3.fromRGB(255, 120, 90), 2, function()
		UIKit.Windows.toggle("Daily")
	end)
	pill("Settings", "⚙️", "", Color3.fromRGB(110, 115, 150), 3, function()
		UIKit.Windows.toggle("Settings")
	end)

	-- DIREITA (reservado para monetização futura)
	container(root, "Right", {
		-- 4 atalhos de 100 px (VIP, Sorte, Jackpot, AURAS) + espaçamento
		Size = UDim2.fromOffset(170, 448),
		Position = UDim2.new(1, -12, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
	})

	-- BAIXO ESQUERDA: dinheiro, Luck, impulso de amigos
	local stats = container(root, "BottomLeft", {
		Size = UDim2.fromOffset(420, 170),
		Position = UDim2.new(0, 16, 1, -10),
		AnchorPoint = Vector2.new(0, 1),
	})
	-- CurrencyDisplay: pílulas (ícone + valor) em vez de texto solto
	boostLabel = UIKit.text(stats, { name = "Boost", size = UDim2.fromOffset(300, 26), position = UDim2.fromOffset(0, 0), color = Theme.Colors.Luck, align = Enum.TextXAlignment.Left })
	local _, luck = UIKit.currency(stats, { name = "LuckPill", valueName = "Luck", icon = "🍀", color = Theme.Colors.Luck, size = UDim2.fromOffset(150, 36), position = UDim2.fromOffset(0, 28) })
	local _, gems = UIKit.currency(stats, { name = "GemsPill", valueName = "Gems", icon = "💎", color = Theme.Colors.Gems, size = UDim2.fromOffset(150, 36), position = UDim2.fromOffset(160, 28) })
	local _, money = UIKit.currency(stats, { name = "MoneyPill", valueName = "Money", icon = "💵", color = Theme.Colors.Money, size = UDim2.fromOffset(330, 58), position = UDim2.fromOffset(0, 70) })
	luckLabel, gemsLabel, moneyLabel = luck, gems, money
	moneyLabel.Text = "$0"
	friendLabel = UIKit.text(stats, {
		name = "FriendBoost",
		text = Localization.t("hud.friend_boost", { percent = 0 }),
		size = UDim2.fromOffset(330, 34),
		position = UDim2.fromOffset(0, 132),
		align = Enum.TextXAlignment.Left,
	})
	friendLabel.TextTransparency = if FriendBoostConfig.Enabled then 0 else 0.35
	boostLabel.Visible = false
end

function HudController.Start()
	UIKit.ViewportChanged:Connect(HudController.Layout)
	DataController.Wait()
	refreshStats()
	-- Depois que os outros controllers criaram seus widgets (histórico do roll)
	task.defer(HudController.Layout)
	DataController.Changed:Connect(function(key: string)
		if key == "Money" or key == "Gems" or key == "EquippedDice" or key == "Upgrades" or key == "Boosts" or key == "Runtime" or key == "Rebirths" or key == "RebirthPerks" then
			refreshStats()
		end
		if key == "PendingOfflineReward" then
			local pending = DataController.Get("PendingOfflineReward") or 0
			local button = buttons.Offline
			if button then
				button.Visible = pending > 0
			end
		end
	end)
	local pending = DataController.Get("PendingOfflineReward") or 0
	buttons.Offline.Visible = pending > 0
	-- Timer do boost
	task.spawn(function()
		while true do
			task.wait(1)
			refreshStats()
		end
	end)
end

return HudController
