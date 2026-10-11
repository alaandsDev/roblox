--!strict
--[[
	UpgradesController: janela MELHORIAS (globais: Luck, Renda, Velocidade de Roll,
	Capacidade). Mostra "NÍVEL 3/20", o próximo benefício e o custo. Abre pelo botão
	MELHORIAS e pela área MELHORIAS da base. Badge no HUD = quantas dá para comprar.
	(As melhorias de cada personagem ficam nos pads das estações da base.)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local UpgradeConfig = require(Shared.Config.UpgradeConfig)
local Formulas = require(Shared.Modules.GameFormulas)
local NumberFormatter = require(Shared.Modules.NumberFormatter)
local Localization = require(Shared.Localization.Localization)
local Net = require(Shared.Modules.Net)

local UI = script.Parent.Parent.UI
local UIKit = require(UI.UIKit)
local Theme = require(UI.UITheme)
local DataController = require(script.Parent.DataController)
local NotificationController = require(script.Parent.NotificationController)
local HudController = require(script.Parent.HudController)

local UpgradesController = {}

local ICONS = { Luck = "🍀", Income = "💵", RollSpeed = "⚡", Inventory = "🎒" }

local window: UIKit.Window
local list: Frame

local function benefit(id: string, level: number): string
	local upgrade = UpgradeConfig.ById[id]
	if id == "Inventory" then
		return Localization.t("upg.benefit.Inventory", { now = level * upgrade.PerLevel, next = (level + 1) * upgrade.PerLevel })
	end
	return Localization.t("upg.benefit." .. id, {
		now = math.floor(level * upgrade.PerLevel * 100 + 0.5),
		next = math.floor((level + 1) * upgrade.PerLevel * 100 + 0.5),
	})
end

local function affordable(data: any): number
	local n = 0
	for _, upgrade in UpgradeConfig.List do
		local cost = Formulas:upgradeCost(upgrade.Id, Formulas:upgradeLevel(data, upgrade.Id))
		if cost and data.Money >= cost then
			n += 1
		end
	end
	return n
end

function UpgradesController.Refresh()
	local data = DataController.GetAll()
	if not data then
		return
	end
	local n = affordable(data)
	HudController.SetBadge("Upgrades", if n > 0 then tostring(n) else nil)
	if not window.isOpen then
		return
	end
	for _, child in list:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	for _, upgrade in UpgradeConfig.List do
		local level = Formulas:upgradeLevel(data, upgrade.Id)
		local cost = Formulas:upgradeCost(upgrade.Id, level)
		local row = UIKit.new("Frame", { BackgroundColor3 = Theme.Colors.Card, Size = UDim2.new(1, 0, 0, 92), LayoutOrder = upgrade.Order }, list)
		UIKit.corner(row, Theme.CornerRadiusSmall)
		UIKit.text(row, { text = ICONS[upgrade.Id] or "⬆️", size = UDim2.fromOffset(64, 64), position = UDim2.fromOffset(12, 14), stroke = 0 })
		UIKit.text(row, { text = Localization.t("upg." .. upgrade.Id), size = UDim2.new(0.4, 0, 0, 32), position = UDim2.fromOffset(88, 10), align = Enum.TextXAlignment.Left })
		UIKit.text(row, { text = if cost then benefit(upgrade.Id, level) else Localization.t("upg.maxed"), size = UDim2.new(0.45, 0, 0, 24), position = UDim2.fromOffset(88, 50), align = Enum.TextXAlignment.Left, color = Theme.Colors.TextMuted })
		UIKit.text(row, { text = Localization.t("upg.level", { level = level, max = upgrade.MaxLevel }), size = UDim2.new(0.2, 0, 0, 30), position = UDim2.new(0.52, 0, 0.5, 0), anchor = Vector2.new(0, 0.5), color = Color3.fromRGB(150, 230, 255) })
		UIKit.button(row, {
			text = if cost then NumberFormatter.money(cost) else Localization.t("station.max"),
			color = if cost and data.Money >= cost then Theme.Colors.Success elseif cost then Theme.Colors.Locked else Theme.Colors.Warning,
			size = UDim2.fromOffset(170, 56),
			position = UDim2.new(1, -12, 0.5, 0),
			anchor = Vector2.new(1, 0.5),
			onClick = function()
				if not cost then
					return
				end
				local result = Net.request("BuyUpgrade", upgrade.Id)
				if result.ok then
					UIKit.sound("Reward", nil, 1.15)
				else
					NotificationController.Show("error." .. tostring(result.code))
				end
			end,
		})
	end
end

function UpgradesController.Init()
	window = UIKit.window({ name = "Upgrades", title = Localization.t("upg.title"), icon = "⬆️", header = Color3.fromRGB(60, 190, 80) })
	list = UIKit.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -20, 1, -20), Position = UDim2.fromOffset(10, 10) }, window.content)
	UIKit.list(list, false, 10)
	window.Opened:Connect(UpgradesController.Refresh)
end

function UpgradesController.Start()
	DataController.Wait()
	UpgradesController.Refresh()
	DataController.Changed:Connect(function(key)
		if key == "Money" or key == "Upgrades" then
			UpgradesController.Refresh()
		end
	end)
end

return UpgradesController
