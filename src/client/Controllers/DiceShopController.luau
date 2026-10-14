--!strict
--[[
	DiceShopController: janela LOJA DE DADOS (abre pelo prompt da loja no mapa e pelo botão
	LOJA da esquerda). Lista rolável com os 16 Dice (DiceConfig + DiceCore): nome, nº de
	personagens, chances REAIS por raridade do Dice (sem Luck), preço, requisito e
	COMPRAR / BLOQUEADO / USAR / EM USO. Quem decide se pode comprar/usar é o servidor.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local DiceConfig = require(Shared.Config.DiceConfig)
local CharacterConfig = require(Shared.Config.CharacterConfig)
local RarityConfig = require(Shared.Config.RarityConfig)
local RollConfig = require(Shared.Config.RollConfig)
local DiceCore = require(Shared.Modules.DiceCore)
local NumberFormatter = require(Shared.Modules.NumberFormatter)
local Localization = require(Shared.Localization.Localization)
local Net = require(Shared.Modules.Net)

local UI = script.Parent.Parent.UI
local UIKit = require(UI.UIKit)
local Theme = require(UI.UITheme)
local DataController = require(script.Parent.DataController)
local NotificationController = require(script.Parent.NotificationController)
local RevealController = require(script.Parent.RevealController)
local PrismConfig = require(Shared.Config.PrismConfig)

local DiceShopController = {}

local window: UIKit.Window
local list: ScrollingFrame
local core = DiceCore.new(DiceConfig, CharacterConfig, RarityConfig, RollConfig)

-- "Comum 56,7% · Incomum 25,8% · ..." (chance base da raridade no Dice)
local function chancesText(diceId: string): string
	local weights = core:rarityWeights(diceId)
	local parts = {}
	for _, rarity in RarityConfig.Order do
		local value = weights[rarity]
		if value then
			table.insert(parts, string.format("%s %s%%", Localization.t("rarity." .. rarity), if value >= 1 then string.format("%.1f", value) else string.format("%.2f", value)))
		end
	end
	return table.concat(parts, " · ")
end

local function rgb(c: { number }): Color3
	return Color3.fromRGB(c[1], c[2], c[3])
end

local function requirementText(dice: any): string
	local req = dice.UnlockRequirement
	local parts = {}
	if req.Rolls then
		table.insert(parts, Localization.t("dice.req_rolls", { rolls = NumberFormatter.thousands(req.Rolls) }))
	end
	if req.Dice then
		table.insert(parts, Localization.t("dice.req_dice", { dice = Localization.t("dice." .. req.Dice) }))
	end
	if req.Dice and req.RollsOnPrevious then
		table.insert(parts, Localization.t("dice.req_dice_rolls", { rolls = req.RollsOnPrevious, dice = Localization.t("dice." .. req.Dice) }))
	end
	return table.concat(parts, " · ")
end

function DiceShopController.Refresh()
	local data = DataController.GetAll()
	if not data or not window.isOpen then
		return
	end
	for _, child in list:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	for _, dice in DiceConfig.List do
		local owned = data.OwnedDice[dice.Id] == true
		if dice.Exclusive and not owned then
			continue
		end
		local rollable = core:isRollable(dice.Id)
		local row = UIKit.new("Frame", { BackgroundColor3 = Theme.Colors.Card, Size = UDim2.new(1, -8, 0, 112), LayoutOrder = dice.Order }, list)
		UIKit.corner(row, Theme.CornerRadiusSmall)
		local icon = UIKit.new("Frame", { BackgroundColor3 = rgb(dice.ColorTheme.Body), Size = UDim2.fromOffset(74, 74), Position = UDim2.fromOffset(12, 11), Rotation = 8 }, row)
		UIKit.corner(icon, 14)
		UIKit.stroke(icon, 3, Theme.StrokeColor, true)
		UIKit.text(icon, { text = "⚅", color = rgb(dice.ColorTheme.Pips), size = UDim2.fromScale(0.9, 0.9), position = UDim2.fromScale(0.5, 0.5), anchor = Vector2.new(0.5, 0.5), stroke = 0 })
		UIKit.text(row, { text = Localization.t("dice." .. dice.Id), size = UDim2.new(0.4, 0, 0, 34), position = UDim2.fromOffset(100, 10), align = Enum.TextXAlignment.Left })
		if rollable then
			UIKit.text(row, { text = Localization.t("dice.characters", { count = #core:charactersFor(dice.Id) }), size = UDim2.new(0.3, 0, 0, 24), position = UDim2.fromOffset(100, 46), align = Enum.TextXAlignment.Left, color = Theme.Colors.Luck })
			UIKit.text(row, { text = chancesText(dice.Id), size = UDim2.new(1, -300, 0, 22), position = UDim2.fromOffset(100, 80), align = Enum.TextXAlignment.Left, color = Theme.Colors.TextMuted })
		end
		local req = if dice.Exclusive then Localization.t("dice.exclusive") else requirementText(dice)
		UIKit.text(row, { text = req, size = UDim2.new(0.38, 0, 0, 24), position = UDim2.new(0.42, 0, 0, 14), align = Enum.TextXAlignment.Left, color = Theme.Colors.TextMuted })
		if dice.Price > 0 and not owned then
			UIKit.text(row, { text = NumberFormatter.money(dice.Price), size = UDim2.new(0.25, 0, 0, 30), position = UDim2.new(0.42, 0, 0, 50), align = Enum.TextXAlignment.Left, color = Theme.Colors.Money })
		end
		local text, color, action
		if data.EquippedDice == dice.Id then
			text, color = Localization.t("dice.equipped"), Color3.fromRGB(70, 70, 92)
		elseif owned and dice.Id == PrismConfig.DiceId and PrismConfig.Enabled then
			-- Prisma da Coleção: usa o Dice SELECIONADO, só entre os não descobertos
			local uses = data.PrismCharges or 0
			text = Localization.t("dice.prism_use", { uses = uses })
			color = if uses > 0 then Color3.fromRGB(240, 90, 200) else Color3.fromRGB(70, 70, 92)
			action = if uses > 0 then "RequestPrismRoll" else nil
		elseif owned and not rollable then
			text, color = Localization.t("dice.not_rollable"), Color3.fromRGB(70, 70, 92)
		elseif owned then
			text, color, action = Localization.t("dice.equip"), Theme.Colors.Primary, "EquipDice"
		else
			-- mesma regra do servidor (DiceCore.unlockBlocker); o servidor decide na compra
			if DiceCore.unlockBlocker(dice, data) == nil then
				text, color, action = Localization.t("dice.buy"), Theme.Colors.Success, "BuyDice"
			else
				text, color = "🔒 " .. Localization.t("dice.locked"), Theme.Colors.Locked
			end
		end
		UIKit.button(row, {
			text = text,
			color = color,
			size = UDim2.fromOffset(170, 56),
			position = UDim2.new(1, -12, 0.5, 0),
			anchor = Vector2.new(1, 0.5),
			onClick = function()
				if not action then
					return
				end
				if action == "RequestPrismRoll" then
					local prism = Net.request("RequestPrismRoll")
					if prism.ok then
						UIKit.Windows.close("DiceShop")
						RevealController.Play(prism.data)
					else
						NotificationController.Show("error." .. tostring(prism.code))
					end
					return
				end
				local result = Net.request(action, dice.Id)
				if result.ok then
					UIKit.sound("Reward")
					NotificationController.Show(if action == "BuyDice" then "dice.bought" else "dice.equipped_now", { dice = Localization.t("dice." .. dice.Id) })
				else
					NotificationController.Show("error." .. tostring(result.code))
				end
			end,
		})
	end
end

function DiceShopController.Init()
	window = UIKit.window({ name = "DiceShop", title = Localization.t("dice.title"), icon = "🎲", header = Color3.fromRGB(240, 90, 200) })
	list = UIKit.new("ScrollingFrame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -16, 1, -16),
		Position = UDim2.fromOffset(8, 8),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 8,
		BorderSizePixel = 0,
	}, window.content)
	UIKit.list(list, false, 8)
	window.Opened:Connect(DiceShopController.Refresh)
end

function DiceShopController.Start()
	DataController.Changed:Connect(function(key)
		if key == "OwnedDice" or key == "EquippedDice" or key == "Money" or key == "Rolls" or key == "DiceRolls" or key == "PrismCharges" then
			DiceShopController.Refresh()
		end
	end)
end

return DiceShopController
