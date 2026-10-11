--!strict
--[[
	RebirthController (Fase 8): janela RENASCIMENTO (botão RENASCER da esquerda).
	Mostra custo, o que ganha (permanente), o que reseta e a loja de perks (fichas).
	O servidor faz tudo; aqui só confirmação e exibição.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local RebirthConfig = require(Shared.Config.RebirthConfig)
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

local RebirthController = {}

local ICONS = { Luck = "🍀", Income = "💵", Speed = "⚡", Capacity = "🎒", Power = "⚔️" }

local window: UIKit.Window
local header: TextLabel
local gains: TextLabel
local resets: TextLabel
local rebirthButton: TextButton
local perkList: Frame

local function perkEffect(id: string, level: number): string
	local perk = RebirthConfig.PerksById[id]
	if id == "Capacity" then
		return Localization.t("rebirth.perk_effect_flat", { value = level * perk.PerLevel })
	end
	return Localization.t("rebirth.perk_effect", { value = math.floor(level * perk.PerLevel * 100 + 0.5) })
end

function RebirthController.Refresh()
	local data = DataController.GetAll()
	if not data then
		return
	end
	local cost = Formulas:rebirthCost(data.Rebirths or 0)
	HudController.SetBadge("Rebirth", if cost and data.Money >= cost then "!" else nil)
	if not window.isOpen then
		return
	end
	header.Text = Localization.t("rebirth.header", { count = data.Rebirths or 0, tokens = data.RebirthTokens or 0 })
	if cost then
		local next = (data.Rebirths or 0) + 1
		gains.Text = Localization.t("rebirth.gains", {
			income = math.floor(RebirthConfig.IncomePerRebirth * 100),
			luck = math.floor(RebirthConfig.LuckPerRebirth * 100),
			power = math.floor(RebirthConfig.PowerPerRebirth * 100),
			tokens = Formulas:rebirthTokens(next),
		})
		UIKit.setButtonText(rebirthButton, Localization.t("rebirth.button", { cost = NumberFormatter.money(cost) }))
		UIKit.setButtonColor(rebirthButton, if data.Money >= cost then Theme.Colors.Danger else Theme.Colors.Locked)
	else
		gains.Text = Localization.t("rebirth.max")
		UIKit.setButtonText(rebirthButton, Localization.t("station.max"))
		UIKit.setButtonColor(rebirthButton, Theme.Colors.Warning)
	end
	resets.Text = Localization.t("rebirth.resets")
	for _, child in perkList:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	for _, perk in RebirthConfig.Perks do
		local level = Formulas:perkLevel(data, perk.Id)
		local perkCost = Formulas:perkCost(perk.Id, level)
		local row = UIKit.new("Frame", { BackgroundColor3 = Theme.Colors.Card, Size = UDim2.new(1, 0, 0, 52), LayoutOrder = perk.Order }, perkList)
		UIKit.corner(row, 10)
		UIKit.text(row, { text = (ICONS[perk.Id] or "") .. " " .. Localization.t("rebirth.perk." .. perk.Id), size = UDim2.new(0.42, 0, 0, 28), position = UDim2.new(0, 10, 0.5, 0), anchor = Vector2.new(0, 0.5), align = Enum.TextXAlignment.Left })
		UIKit.text(row, { text = string.format("%d/%d · %s", level, perk.MaxLevel, perkEffect(perk.Id, level)), size = UDim2.new(0.3, 0, 0, 22), position = UDim2.new(0.44, 0, 0.5, 0), anchor = Vector2.new(0, 0.5), color = Theme.Colors.TextMuted })
		UIKit.button(row, {
			name = "Perk_" .. perk.Id,
			text = if perkCost then "🎟️ " .. perkCost else Localization.t("station.max"),
			color = if perkCost and (data.RebirthTokens or 0) >= perkCost then Theme.Colors.Success else Theme.Colors.Locked,
			size = UDim2.fromOffset(120, 42),
			position = UDim2.new(1, -8, 0.5, 0),
			anchor = Vector2.new(1, 0.5),
			onClick = function()
				local result = Net.request("BuyRebirthPerk", perk.Id)
				if result.ok then
					UIKit.sound("Reward")
				else
					NotificationController.Show("error." .. tostring(result.code))
				end
			end,
		})
	end
end

function RebirthController.Init()
	window = UIKit.window({ name = "Rebirth", title = Localization.t("rebirth.title"), icon = "♻️", size = Theme.PopupSizes.Large, header = Color3.fromRGB(220, 60, 80) })
	local content = window.content
	header = UIKit.text(content, { size = UDim2.new(1, -24, 0, 36), position = UDim2.fromOffset(12, 8) })
	gains = UIKit.text(content, { size = UDim2.new(0.48, 0, 0, 120), position = UDim2.fromOffset(12, 54), wrap = true, color = Theme.Colors.Success, align = Enum.TextXAlignment.Left })
	resets = UIKit.text(content, { size = UDim2.new(0.48, 0, 0, 70), position = UDim2.fromOffset(12, 180), wrap = true, color = Theme.Colors.Danger, align = Enum.TextXAlignment.Left })
	rebirthButton = UIKit.button(content, {
		name = "DoRebirth",
		text = "",
		color = Theme.Colors.Danger,
		size = UDim2.fromOffset(300, 64),
		position = UDim2.new(0.25, 0, 1, -16),
		anchor = Vector2.new(0.5, 1),
		onClick = function()
			local data = DataController.GetAll()
			local cost = data and Formulas:rebirthCost(data.Rebirths or 0)
			if not data or not cost then
				return
			end
			UIKit.confirm(Localization.t("rebirth.confirm", { cost = NumberFormatter.money(cost) }), Localization.t("rebirth.yes"), Localization.t("sell.cancel"), function()
				local result = Net.request("Rebirth")
				if result.ok then
					UIKit.sound("Reward", 0.6, 0.8)
				else
					NotificationController.Show("error." .. tostring(result.code))
				end
			end)
		end,
	})
	UIKit.text(content, { text = Localization.t("rebirth.perks_title"), size = UDim2.new(0.48, 0, 0, 30), position = UDim2.new(0.5, 6, 0, 54), color = Theme.Colors.Warning })
	perkList = UIKit.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(0.5, -18, 1, -100), Position = UDim2.new(0.5, 6, 0, 90) }, content)
	UIKit.list(perkList, false, 6)
	window.Opened:Connect(RebirthController.Refresh)
end

function RebirthController.Start()
	DataController.Wait()
	RebirthController.Refresh()
	DataController.Changed:Connect(function(key)
		if key == "Money" or key == "Rebirths" or key == "RebirthTokens" or key == "RebirthPerks" then
			RebirthController.Refresh()
		end
	end)
end

return RebirthController
