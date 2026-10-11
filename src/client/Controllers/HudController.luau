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
	gemsLabel.Text = "💎 " .. NumberFormatter.abbreviate(data.Gems or 0)
	local now = os.time()
	local luck = Formulas:luck(data, now)
	luckLabel.Text = string.format("🍀 %sx", NumberFormatter.abbreviate(math.floor(luck * 100 + 0.5) / 100))
	local boost = data.Boosts and data.Boosts.Luck
	if boost and type(boost.ExpiresAt) == "number" and boost.ExpiresAt > now then
		boostLabel.Visible = true
		boostLabel.Text = Localization.t("hud.boost", { mult = boost.Multiplier, time = NumberFormatter.duration(boost.ExpiresAt - now) })
	else
		boostLabel.Visible = false
	end
end

function HudController.Init()
	local gui = UIKit.screen("HUD", 5)
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
	local topRight = container(root, "TopRight", {
		Size = UDim2.fromOffset(420, 54),
		Position = UDim2.new(1, -12, 0, 8),
		AnchorPoint = Vector2.new(1, 0),
	})
	local trList = UIKit.list(topRight, true, 10)
	trList.HorizontalAlignment = Enum.HorizontalAlignment.Right
	local function pill(name: string, text: string, color: Color3, order: number, width: number, onClick: () -> ())
		local button = UIKit.button(topRight, {
			name = name,
			text = text,
			color = color,
			size = UDim2.fromOffset(width, 50),
			order = order,
			onClick = onClick,
		})
		buttons[name] = button
		badges[name] = UIKit.badge(button)
		return button
	end
	local offline = pill("Offline", "🎁 " .. Localization.t("hud.offline"), Color3.fromRGB(80, 200, 110), 1, 140, function()
		UIKit.Windows.open("Offline")
	end)
	offline.Visible = false
	pill("Daily", "📅 " .. Localization.t("hud.daily"), Color3.fromRGB(45, 45, 65), 2, 140, function()
		UIKit.Windows.toggle("Daily")
	end)
	pill("Settings", "⚙️", Color3.fromRGB(45, 45, 65), 3, 54, function()
		UIKit.Windows.toggle("Settings")
	end)

	-- DIREITA (reservado para monetização futura)
	container(root, "Right", {
		Size = UDim2.fromOffset(170, 420),
		Position = UDim2.new(1, -12, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
	})

	-- BAIXO ESQUERDA: dinheiro, Luck, impulso de amigos
	local stats = container(root, "BottomLeft", {
		Size = UDim2.fromOffset(420, 170),
		Position = UDim2.new(0, 16, 1, -10),
		AnchorPoint = Vector2.new(0, 1),
	})
	boostLabel = UIKit.text(stats, { name = "Boost", size = UDim2.fromOffset(300, 26), position = UDim2.fromOffset(0, 0), color = Theme.Colors.Luck, align = Enum.TextXAlignment.Left })
	luckLabel = UIKit.text(stats, { name = "Luck", size = UDim2.fromOffset(160, 32), position = UDim2.fromOffset(0, 28), color = Theme.Colors.Luck, align = Enum.TextXAlignment.Left })
	gemsLabel = UIKit.text(stats, { name = "Gems", size = UDim2.fromOffset(150, 32), position = UDim2.fromOffset(170, 28), color = Theme.Colors.Gems, align = Enum.TextXAlignment.Left })
	moneyLabel = UIKit.text(stats, { name = "Money", text = "$0", size = UDim2.fromOffset(400, 70), position = UDim2.fromOffset(0, 60), color = Theme.Colors.Money, align = Enum.TextXAlignment.Left, stroke = 4 })
	local friend = UIKit.text(stats, {
		name = "FriendBoost",
		text = Localization.t("hud.friend_boost", { percent = 0 }),
		size = UDim2.fromOffset(330, 34),
		position = UDim2.fromOffset(0, 132),
		align = Enum.TextXAlignment.Left,
	})
	friend.TextTransparency = if FriendBoostConfig.Enabled then 0 else 0.35
	boostLabel.Visible = false
end

function HudController.Start()
	DataController.Wait()
	refreshStats()
	DataController.Changed:Connect(function(key: string)
		if key == "Money" or key == "Gems" or key == "EquippedDice" or key == "Upgrades" or key == "Boosts" then
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
