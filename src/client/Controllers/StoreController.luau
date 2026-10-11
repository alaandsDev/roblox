--!strict
--[[
	StoreController (Fase 10): janela LOJA (MERCADO no Hub e botões da direita).
	    GAMEPASSES (Robux) · PRODUTOS (Robux) · LOJA DE GEMAS (Jackpot, boost, dinheiro)
	Compras em Robux: o cliente só pede RequestPurchase(chave); o servidor abre a janela do
	Roblox e entrega pelo ProcessReceipt. IDs = 0 -> "ainda não está à venda".
	Prêmios chegam pelo evento JackpotResult: animação do giro + reveal se for personagem.
	Lado direito do HUD: VIP, SORTE x2 e GIRO DO JACKPOT (atalhos para a loja).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage.Shared
local MonetizationConfig = require(Shared.Config.MonetizationConfig)
local JackpotConfig = require(Shared.Config.JackpotConfig)
local JackpotCore = require(Shared.Modules.JackpotCore)
local NumberFormatter = require(Shared.Modules.NumberFormatter)
local Localization = require(Shared.Localization.Localization)
local Net = require(Shared.Modules.Net)

local UI = script.Parent.Parent.UI
local UIKit = require(UI.UIKit)
local Theme = require(UI.UITheme)
local DataController = require(script.Parent.DataController)
local NotificationController = require(script.Parent.NotificationController)
local HudController = require(script.Parent.HudController)
local RevealController = require(script.Parent.RevealController)

local StoreController = {}

local window: UIKit.Window
local scroll: ScrollingFrame
local spinGui: ScreenGui

local function sorted(map: { [string]: any }): { any }
	local list = {}
	for key, item in map do
		table.insert(list, { key = key, item = item })
	end
	table.sort(list, function(a, b)
		return a.item.Order < b.item.Order
	end)
	return list
end

local function section(title: string, order: number)
	UIKit.text(scroll, { text = title, size = UDim2.new(1, 0, 0, 34), order = order, color = Theme.Colors.Warning })
end

local function card(order: number, icon: string, title: string, subtitle: string, buttonText: string, color: Color3, name: string, onClick: () -> ())
	local row = UIKit.new("Frame", { Name = name, BackgroundColor3 = Theme.Colors.Card, Size = UDim2.new(1, -8, 0, 74), LayoutOrder = order }, scroll)
	UIKit.corner(row, Theme.CornerRadiusSmall)
	UIKit.text(row, { text = icon, size = UDim2.fromOffset(56, 56), position = UDim2.fromOffset(10, 9), stroke = 0 })
	UIKit.text(row, { text = title, size = UDim2.new(0.55, 0, 0, 30), position = UDim2.fromOffset(76, 8), align = Enum.TextXAlignment.Left })
	UIKit.text(row, { text = subtitle, size = UDim2.new(0.55, 0, 0, 22), position = UDim2.fromOffset(76, 42), align = Enum.TextXAlignment.Left, color = Theme.Colors.TextMuted })
	UIKit.button(row, { name = "Buy", text = buttonText, color = color, size = UDim2.fromOffset(170, 52), position = UDim2.new(1, -10, 0.5, 0), anchor = Vector2.new(1, 0.5), onClick = onClick })
end

local function purchase(key: string)
	local result = Net.request("RequestPurchase", key)
	if not result.ok and result.code ~= "not_configured" then
		NotificationController.Show("error." .. tostring(result.code))
	end
end

function StoreController.Refresh()
	if not window.isOpen then
		return
	end
	for _, child in scroll:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	local data: any = DataController.GetAll() or {}
	local owned = (data.Runtime and data.Runtime.Passes) or {}
	section(Localization.t("store.passes"), 0)
	local order = 1
	for _, entry in sorted(MonetizationConfig.GamePasses) do
		local has = owned[entry.key] == true
		card(order, entry.item.Icon, entry.item.Name, Localization.t("store.pass." .. entry.key), if has then Localization.t("store.owned") else "R$ " .. entry.item.PriceRobux, if has then Theme.Colors.Locked else Theme.Colors.Success, "Pass_" .. entry.key, function()
			if not has then
				purchase(entry.key)
			end
		end)
		order += 1
	end
	section(Localization.t("store.products"), 100)
	order = 101
	for _, entry in sorted(MonetizationConfig.Products) do
		card(order, entry.item.Icon, entry.item.Name, Localization.t("store.product." .. entry.key), "R$ " .. entry.item.PriceRobux, Theme.Colors.Success, "Product_" .. entry.key, function()
			purchase(entry.key)
		end)
		order += 1
	end
	section(Localization.t("store.gems", { gems = NumberFormatter.abbreviate(data.Gems or 0) }), 200)
	order = 201
	for _, item in JackpotConfig.GemShop do
		card(order, item.Icon, Localization.t("store.gem." .. item.Id), Localization.t("store.gem_desc." .. item.Id), "💎 " .. item.Cost, Theme.Colors.Primary, "Gem_" .. item.Id, function()
			local result = Net.request("BuyGemItem", item.Id)
			if not result.ok then
				NotificationController.Show("error." .. tostring(result.code))
			end
		end)
		order += 1
	end
	-- Transparência: chances do Jackpot
	section(Localization.t("store.odds"), 300)
	local chances = JackpotCore.chances(JackpotConfig.Rewards)
	for i, reward in JackpotConfig.Rewards do
		UIKit.text(scroll, {
			text = string.format("%s %s — %.1f%%", reward.Icon, Localization.t("jackpot." .. reward.Id), chances[reward.Id] * 100),
			size = UDim2.new(1, 0, 0, 24),
			order = 300 + i,
			color = Theme.Colors.TextMuted,
			align = Enum.TextXAlignment.Left,
		})
	end
end

------------------------------------------------------------------------------------
-- Prêmio (giro)

local function prizeText(result: any): string
	if result.kind == "Money" then
		return "+" .. NumberFormatter.money(result.amount)
	elseif result.kind == "Gems" then
		return "💎 +" .. tostring(result.amount)
	elseif result.kind == "LuckBoost" then
		return string.format("🍀 %gx · %d min", result.multiplier, (result.duration or 0) // 60)
	end
	return Localization.t("jackpot.character")
end

function StoreController.ShowPrize(result: any)
	for _, child in spinGui:GetChildren() do
		child:Destroy()
	end
	spinGui.Enabled = true
	UIKit.new("Frame", { BackgroundColor3 = Color3.new(), BackgroundTransparency = 0.45, Size = UDim2.fromScale(1, 1) }, spinGui)
	local root = UIKit.scaledRoot(spinGui)
	local panel = UIKit.new("Frame", { Name = "Prize", Size = UDim2.fromOffset(460, 300), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Theme.Colors.PanelBackground }, root)
	UIKit.corner(panel, Theme.CornerRadius)
	UIKit.stroke(panel, 5, Theme.Colors.Warning, true)
	UIKit.text(panel, { text = Localization.t("jackpot.title"), size = UDim2.new(1, -20, 0, 44), position = UDim2.fromOffset(10, 10), color = Theme.Colors.Warning })
	local reel = UIKit.text(panel, { name = "Reel", text = "🎰", size = UDim2.fromOffset(140, 110), position = UDim2.fromScale(0.5, 0.45), anchor = Vector2.new(0.5, 0.5), stroke = 0 })
	local label = UIKit.text(panel, { name = "PrizeText", text = "", size = UDim2.new(1, -20, 0, 44), position = UDim2.new(0.5, 0, 1, -70), anchor = Vector2.new(0.5, 1), color = Theme.Colors.Money })
	-- Rolo girando pelos ícones (desacelera) e para no prêmio
	local icons = {}
	for _, reward in JackpotConfig.Rewards do
		table.insert(icons, reward.Icon)
	end
	local delay = 0.04
	for i = 1, 18 do
		reel.Text = icons[(i % #icons) + 1]
		UIKit.sound("Click", 0.15, 1 + i * 0.02)
		task.wait(delay)
		delay *= 1.15
	end
	reel.Text = result.icon or "🎁"
	local s = UIKit.new("UIScale", { Scale = 1.5 }, reel)
	TweenService:Create(s, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	label.Text = prizeText(result)
	UIKit.sound("Reward")
	UIKit.button(panel, { name = "ClosePrize", text = Localization.t("reveal.continue"), color = Theme.Colors.Success, size = UDim2.fromOffset(200, 52), position = UDim2.new(0.5, 0, 1, -12), anchor = Vector2.new(0.5, 1), onClick = function()
		spinGui.Enabled = false
		for _, child in spinGui:GetChildren() do
			child:Destroy()
		end
		if result.roll then
			task.spawn(RevealController.Play, result.roll)
		end
	end })
end

function StoreController.Init()
	window = UIKit.window({ name = "Store", title = Localization.t("store.title"), icon = "🛍️", size = Theme.PopupSizes.Large, header = Color3.fromRGB(40, 170, 90) })
	scroll = UIKit.new("ScrollingFrame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -16, 1, -16),
		Position = UDim2.fromOffset(8, 8),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 8,
		BorderSizePixel = 0,
	}, window.content)
	UIKit.list(scroll, false, 8)
	window.Opened:Connect(StoreController.Refresh)
	spinGui = UIKit.screen("Jackpot", 140)
	spinGui.IgnoreGuiInset = true
	spinGui.Enabled = false
end

function StoreController.Start()
	-- Lado direito do HUD (atalhos de monetização)
	local right = HudController.Containers.Right
	if right then
		UIKit.list(right, false, 12, "center")
		local function shortcut(name: string, icon: string, key: string, color: Color3, order: number, onClick: () -> ())
			UIKit.iconButton(right, { name = name, icon = icon, text = Localization.t(key), color = color, size = UDim2.fromOffset(120, 120), order = order, onClick = onClick })
		end
		shortcut("VipShortcut", "👑", "store.short.vip", Color3.fromRGB(255, 190, 40), 1, function()
			UIKit.Windows.open("Store")
		end)
		shortcut("LuckShortcut", "🍀", "store.short.luck", Color3.fromRGB(70, 200, 90), 2, function()
			UIKit.Windows.open("Store")
		end)
		shortcut("JackpotShortcut", "🎰", "store.short.jackpot", Color3.fromRGB(170, 80, 255), 3, function()
			local result = Net.request("SpinJackpot")
			if not result.ok then
				NotificationController.Show("error." .. tostring(result.code))
				UIKit.Windows.open("Store")
			end
		end)
	end
	Net.on("JackpotResult", function(result: any)
		task.spawn(StoreController.ShowPrize, result)
	end)
	DataController.Changed:Connect(function(key)
		if key == "Gems" or key == "Runtime" then
			StoreController.Refresh()
		end
	end)
end

return StoreController
