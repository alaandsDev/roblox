--!strict
--[[
	FeedbackController: retornos rápidos e satisfatórios do jogo.
	    MoneyCollected  -> moedas voando até o dinheiro + "+$X" + som
	    StationUpgraded -> som subindo de tom + "NÍVEL N!" (o pad pisca no servidor)
	    Announce        -> drop raro de OUTRO jogador (discreto / global / destaque)
	    OpenMenu        -> abre a janela pedida por um prompt do mapa (loja, vender, melhorias)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage.Shared
local NumberFormatter = require(Shared.Modules.NumberFormatter)
local Localization = require(Shared.Localization.Localization)
local Net = require(Shared.Modules.Net)

local UI = script.Parent.Parent.UI
local UIKit = require(UI.UIKit)
local Theme = require(UI.UITheme)
local HudController = require(script.Parent.HudController)
local NotificationController = require(script.Parent.NotificationController)

local FeedbackController = {}

local MENUS = {
	DiceShop = true,
	Sell = true,
	Upgrades = true,
	Inventory = true,
	Index = true,
	Daily = true,
	Towers = true,
	Rebirth = true,
	Fusion = true,
	Trade = true,
	Missions = true,
	Store = true,
}

local root: Frame
local upgradeCombo = 0
local lastUpgrade = 0

local function coins(amount: number)
	UIKit.sound("Coin", nil, 1.1)
	-- Coordenadas do root são "antes do UIScale": converte pixels reais dividindo pela escala
	local scale = UIKit.uiScale()
	local target = HudController.MoneyAnchor()
	local targetPos = if target
		then (target.AbsolutePosition - root.AbsolutePosition) / scale + Vector2.new(60, 30)
		else Vector2.new(80, 600)
	local start = root.AbsoluteSize / scale / 2
	for i = 1, 8 do
		local coin = UIKit.text(root, {
			text = "🪙",
			size = UDim2.fromOffset(40, 40),
			position = UDim2.fromOffset(start.X + math.random(-80, 80), start.Y + math.random(-40, 40)),
			anchor = Vector2.new(0.5, 0.5),
			stroke = 0,
			z = 20,
		})
		task.delay(i * 0.03, function()
			local tween = TweenService:Create(coin, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Position = UDim2.fromOffset(targetPos.X, targetPos.Y),
				TextTransparency = 0.4,
			})
			tween:Play()
			tween.Completed:Once(function()
				coin:Destroy()
			end)
		end)
	end
	local label = UIKit.text(root, {
		text = "+" .. NumberFormatter.money(amount),
		size = UDim2.fromOffset(360, 60),
		position = UDim2.fromScale(0.5, 0.42),
		anchor = Vector2.new(0.5, 0.5),
		color = Theme.Colors.Money,
		stroke = 4,
		z = 21,
	})
	TweenService:Create(label, TweenInfo.new(0.9), { Position = UDim2.fromScale(0.5, 0.34), TextTransparency = 1 }):Play()
	task.delay(0.9, label.Destroy, label)
end

local function stationUpgraded(_uid: string, level: number)
	local now = os.clock()
	upgradeCombo = if now - lastUpgrade < 1.2 then upgradeCombo + 1 else 0
	lastUpgrade = now
	UIKit.sound("Reward", 0.35, 1 + math.min(upgradeCombo, 12) * 0.05)
	local label = UIKit.text(root, {
		text = Localization.t("station.level_up", { level = level }),
		size = UDim2.fromOffset(300, 48),
		position = UDim2.fromScale(0.5, 0.36),
		anchor = Vector2.new(0.5, 0.5),
		color = Color3.fromRGB(150, 230, 255),
		stroke = 4,
		z = 21,
	})
	TweenService:Create(label, TweenInfo.new(0.7), { Position = UDim2.fromScale(0.5, 0.3), TextTransparency = 1 }):Play()
	task.delay(0.7, label.Destroy, label)
end

function FeedbackController.Start()
	local gui = UIKit.screen("Feedback", 60)
	root = UIKit.scaledRoot(gui)
	Net.on("MoneyCollected", function(amount: number)
		coins(amount)
	end)
	Net.on("StationUpgraded", stationUpgraded)
	Net.on("Announce", function(_key: string, params: { [string]: any }, level: string)
		local data = table.clone(params)
		data.rarity = Localization.t("rarity." .. tostring(params.rarity))
		data.odds = NumberFormatter.thousands(tonumber(params.odds) or 0)
		NotificationController.ShowText(Localization.t("announce." .. level, data), if level == "Discreet" then "Info" else "Reward")
		if level == "Highlight" then
			UIKit.sound("SecretStinger", 0.3)
		end
	end)
	Net.on("OpenMenu", function(name: string)
		if MENUS[name] then
			UIKit.Windows.open(name)
		end
	end)
end

return FeedbackController
