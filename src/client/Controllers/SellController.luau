--!strict
--[[
	SellController: janela VENDER (prompt do stand VENDER no mapa / botão do aviso de
	inventário cheio).
	    Vender selecionado (o selecionado na MOCHILA)  · Vender duplicatas · Vender comuns
	    Configurar Auto-Sell (Comum..Divino; Secreto sempre PROTEGIDO)
	Venda em massa: o servidor calcula a prévia (SellBatch confirmar=false) e só vende
	depois de "Vender 23 personagens por $4.25K?" [Cancelar] [Vender].
	Travados, favoritos e equipados nunca entram.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local CharacterConfig = require(Shared.Config.CharacterConfig)
local Definitions = require(Shared.Remotes.Definitions)
local Formulas = require(Shared.Modules.GameFormulas)
local NumberFormatter = require(Shared.Modules.NumberFormatter)
local Localization = require(Shared.Localization.Localization)
local Net = require(Shared.Modules.Net)

local UI = script.Parent.Parent.UI
local UIKit = require(UI.UIKit)
local Theme = require(UI.UITheme)
local DataController = require(script.Parent.DataController)
local NotificationController = require(script.Parent.NotificationController)
local InventoryController = require(script.Parent.InventoryController)

local SellController = {}

local window: UIKit.Window
local toggles: { [string]: TextButton } = {}
local selectedLabel: TextLabel

local function batch(mode: string)
	local preview = Net.request("SellBatch", mode, false)
	if not preview.ok then
		NotificationController.Show("error." .. tostring(preview.code))
		return
	end
	if preview.data.count == 0 then
		NotificationController.Show("error.nothing_to_sell")
		return
	end
	UIKit.confirm(
		Localization.t("sell.confirm", { count = preview.data.count, amount = NumberFormatter.money(preview.data.total) }),
		Localization.t("sell.yes"),
		Localization.t("sell.cancel"),
		function()
			local result = Net.request("SellBatch", mode, true)
			if result.ok then
				UIKit.sound("Coin")
				NotificationController.Show("sell.done", { count = result.data.count, amount = NumberFormatter.money(result.data.total) })
			else
				NotificationController.Show("error." .. tostring(result.code))
			end
		end
	)
end

local function refresh()
	local settings = DataController.Get("Settings") or {}
	local autoSell = settings.AutoSell or {}
	for rarity, button in toggles do
		local on = autoSell[rarity] == true
		UIKit.setButtonColor(button, if on then Theme.Colors.Success else Color3.fromRGB(70, 70, 92))
		UIKit.setButtonText(button, Localization.t("rarity." .. rarity) .. (if on then " ✓" else ""))
	end
	local data = DataController.GetAll()
	local uid = InventoryController.Selected()
	local item = data and uid and data.Inventory[uid]
	if item then
		selectedLabel.Text = Localization.t("sell.selected", { name = CharacterConfig.ById[item.Id].Name, amount = NumberFormatter.money(Formulas:sellValue(item.Id, item.Variant)) })
	else
		selectedLabel.Text = Localization.t("sell.none_selected")
	end
end

function SellController.Init()
	window = UIKit.window({ name = "Sell", title = Localization.t("sell.title"), icon = "💰", header = Color3.fromRGB(255, 150, 40) })
	local content = window.content
	UIKit.padding(content, 14)
	UIKit.list(content, false, 10)

	selectedLabel = UIKit.text(content, { size = UDim2.new(1, 0, 0, 30), order = 1, color = Theme.Colors.TextMuted })
	local actions = UIKit.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 60), LayoutOrder = 2 }, content)
	UIKit.list(actions, true, 10, "center")
	UIKit.button(actions, { text = Localization.t("sell.selected_button"), color = Theme.Colors.Danger, size = UDim2.fromOffset(220, 56), order = 1, onClick = function()
		local uid = InventoryController.Selected()
		local data = DataController.GetAll()
		local item = data and uid and data.Inventory[uid]
		if not item or not uid then
			UIKit.Windows.open("Inventory")
			NotificationController.Show("sell.pick_first")
			return
		end
		UIKit.confirm(
			Localization.t("sell.confirm_one", { name = CharacterConfig.ById[item.Id].Name, amount = NumberFormatter.money(Formulas:sellValue(item.Id, item.Variant)) }),
			Localization.t("sell.yes"),
			Localization.t("sell.cancel"),
			function()
				local result = Net.request("SellCharacter", { uid })
				if result.ok then
					UIKit.sound("Coin")
				else
					NotificationController.Show("error." .. tostring(result.code))
				end
				refresh()
			end
		)
	end })
	UIKit.button(actions, { text = Localization.t("sell.duplicates"), color = Theme.Colors.Orange, size = UDim2.fromOffset(220, 56), order = 2, onClick = function()
		batch("Duplicates")
	end })
	UIKit.button(actions, { text = Localization.t("sell.commons"), color = Theme.Colors.Primary, size = UDim2.fromOffset(220, 56), order = 3, onClick = function()
		batch("Rarity:Common")
	end })

	UIKit.text(content, { text = Localization.t("sell.autosell_title"), size = UDim2.new(1, 0, 0, 34), order = 3 })
	UIKit.text(content, { text = Localization.t("sell.autosell_hint"), size = UDim2.new(1, 0, 0, 22), order = 4, color = Theme.Colors.TextMuted })
	local grid = UIKit.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 130), LayoutOrder = 5 }, content)
	UIKit.new("UIGridLayout", { CellSize = UDim2.fromOffset(170, 56), CellPadding = UDim2.fromOffset(10, 10), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center }, grid)
	for i, rarity in Definitions.AutoSellRarities :: { string } do
		toggles[rarity] = UIKit.button(grid, { text = Localization.t("rarity." .. rarity), order = i, onClick = function()
			local settings = DataController.Get("Settings") or {}
			local on = settings.AutoSell and settings.AutoSell[rarity] == true
			local result = Net.request("SetAutoSell", rarity, not on)
			if not result.ok then
				NotificationController.Show("error." .. tostring(result.code))
			end
		end })
	end
	local secret = UIKit.button(grid, { text = "🔒 " .. Localization.t("rarity.Secret"), color = Theme.Colors.Locked, order = 99, onClick = function()
		NotificationController.Show("sell.secret_protected")
	end })
	secret.Name = "SecretProtected"
	window.Opened:Connect(refresh)
end

function SellController.Start()
	DataController.Changed:Connect(function(key)
		if key == "Settings" or key == "Inventory" then
			if window.isOpen then
				refresh()
			end
		end
	end)
end

return SellController
