--!strict
--[[
	PlayerAuraShopController: janela PLAYER AURAS (aura do AVATAR — não confundir com a aura dos
	personagens). Atalho "✨ AURAS" na coluna direita do HUD.
	Cada aura: nome, cor/ícone, preço, Renda ×, Velocidade e estado:
	    🔒 BLOQUEADA (precisa da anterior) · 💰 $25B COMPRAR (a próxima) · EQUIPAR VISUAL · ✓ EQUIPADA
	A próxima aura fica destacada (aspiracional). Comprar pede confirmação (valores altos); o
	servidor revalida tudo. Bônus de renda/velocidade = maior aura comprada, qualquer que seja o
	visual. Mostra também "👑 Gerado: $X" (LifetimeMoneyGenerated, Ranking Magnata).
	Prévia visual: o próprio avatar (a aura aparece na hora ao equipar); ViewportFrame não
	renderiza partículas, por isso não há retrato aqui.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local PlayerAuraConfig = require(Shared.Config.PlayerAuraConfig)
local MovementConfig = require(Shared.Config.MovementConfig)
local NumberFormatter = require(Shared.Modules.NumberFormatter)
local Localization = require(Shared.Localization.Localization)
local Formulas = require(Shared.Modules.GameFormulas)
local Net = require(Shared.Modules.Net)

local UI = script.Parent.Parent.UI
local UIKit = require(UI.UIKit)
local Theme = require(UI.UITheme)
local DataController = require(script.Parent.DataController)
local HudController = require(script.Parent.HudController)
local NotificationController = require(script.Parent.NotificationController)

local PlayerAuraShopController = {}

local window: UIKit.Window
local list: ScrollingFrame
local summary: TextLabel
local confirmFrame: Frame
local confirmText: TextLabel
local pendingTier: number? = nil
local busy = false

local function rgb(c: { number }): Color3
	return Color3.fromRGB(c[1], c[2], c[3])
end

local function auraName(id: string): string
	return Localization.t("paura.name." .. id)
end

-- Estado de uma aura para o jogador: "Equipped" | "Owned" | "Next" | "Locked"
function PlayerAuraShopController.StateOf(data: any, tier: number): string
	local owned = Formulas:playerAuraTier(data)
	local aura = data.PlayerAura
	local equipped = if type(aura) == "table" and type(aura.Equipped) == "number" then aura.Equipped else owned
	if tier <= owned then
		return if equipped == tier then "Equipped" else "Owned"
	end
	return if tier == owned + 1 then "Next" else "Locked"
end

function PlayerAuraShopController.Refresh()
	local data = DataController.GetAll()
	if not data or not window or not window.isOpen then
		return
	end
	summary.Text = Localization.t("paura.summary", {
		mult = string.format("%.2f", Formulas:playerAuraMultiplier(data)),
		speed = Formulas:walkSpeed(data),
		base = MovementConfig.BaseWalkSpeed,
		lifetime = NumberFormatter.money(math.floor(data.LifetimeMoneyGenerated or 0)),
	})
	for _, child in list:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	for _, tier in PlayerAuraConfig.List do
		local state = PlayerAuraShopController.StateOf(data, tier.Tier)
		local color = rgb(tier.Color)
		local card = UIKit.new("Frame", {
			Name = "Aura_" .. tier.Id,
			BackgroundColor3 = if state == "Locked" then Color3.fromRGB(40, 40, 52) else Theme.Colors.Card,
			Size = UDim2.new(1, -8, 0, 86),
			LayoutOrder = tier.Tier,
		}, list)
		card:SetAttribute("State", state)
		UIKit.corner(card, Theme.CornerRadiusSmall)
		UIKit.stroke(card, if state == "Next" then 4 else 2, if state == "Next" then Color3.fromRGB(255, 220, 90) else color, true)
		local swatch = UIKit.new("Frame", { Name = "Swatch", BackgroundColor3 = color, Size = UDim2.fromOffset(62, 62), Position = UDim2.fromOffset(12, 12) }, card)
		UIKit.corner(swatch, 31)
		UIKit.stroke(swatch, 3, rgb(tier.Accent), true)
		UIKit.text(swatch, { text = tier.Icon, size = UDim2.fromScale(0.8, 0.8), position = UDim2.fromScale(0.1, 0.1), stroke = 0 })
		UIKit.text(card, {
			name = "Name",
			text = string.upper(auraName(tier.Id)) .. (if state == "Next" then "  · " .. Localization.t("paura.next") else ""),
			size = UDim2.new(1, -330, 0, 30),
			position = UDim2.fromOffset(88, 8),
			align = Enum.TextXAlignment.Left,
			color = color,
		})
		UIKit.text(card, {
			name = "Stats",
			text = Localization.t("paura.stats", { price = NumberFormatter.money(tier.Price), mult = string.format("%.2f", tier.MoneyMultiplier), speed = tier.WalkSpeed }),
			size = UDim2.new(1, -330, 0, 24),
			position = UDim2.fromOffset(88, 46),
			align = Enum.TextXAlignment.Left,
			color = Theme.Colors.TextMuted,
		})
		local text, buttonColor, onClick
		if state == "Equipped" then
			text, buttonColor = "✓ " .. Localization.t("paura.equipped"), Theme.Colors.Success
			onClick = function()
				task.spawn(PlayerAuraShopController.Equip, 0)
			end
		elseif state == "Owned" then
			text, buttonColor = Localization.t("paura.equip"), Theme.Colors.Primary
			onClick = function()
				task.spawn(PlayerAuraShopController.Equip, tier.Tier)
			end
		elseif state == "Next" then
			text, buttonColor = "💰 " .. NumberFormatter.money(tier.Price) .. "  " .. Localization.t("paura.buy"), Theme.Colors.Orange
			onClick = function()
				PlayerAuraShopController.AskBuy(tier.Tier)
			end
		else
			text, buttonColor = "🔒 " .. Localization.t("paura.locked"), Color3.fromRGB(80, 80, 96)
			onClick = function()
				NotificationController.Show("error.aura_order")
			end
		end
		UIKit.button(card, {
			name = "Action",
			text = text,
			color = buttonColor,
			size = UDim2.fromOffset(220, 54),
			position = UDim2.new(1, -12, 0.5, 0),
			anchor = Vector2.new(1, 0.5),
			onClick = onClick,
		})
	end
end

function PlayerAuraShopController.AskBuy(tier: number)
	local config = PlayerAuraConfig.List[tier]
	if not config then
		return
	end
	pendingTier = tier
	confirmText.Text = Localization.t("paura.confirm", {
		name = string.upper(auraName(config.Id)),
		price = NumberFormatter.money(config.Price),
		mult = string.format("%.2f", config.MoneyMultiplier),
		speed = config.WalkSpeed,
	})
	confirmFrame.Visible = true
end

function PlayerAuraShopController.ConfirmBuy(): boolean
	local tier = pendingTier
	if not tier or busy then
		return false
	end
	busy = true
	pendingTier = nil
	confirmFrame.Visible = false
	local result = Net.request("BuyPlayerAura", tier)
	busy = false
	if not result.ok then
		NotificationController.Show("error." .. tostring(result.code))
		return false
	end
	UIKit.sound("RevealStinger")
	NotificationController.Show("paura.bought", { name = auraName(PlayerAuraConfig.List[tier].Id) })
	PlayerAuraShopController.Refresh()
	return true
end

function PlayerAuraShopController.Equip(tier: number): boolean
	local result = Net.request("EquipPlayerAura", tier)
	if not result.ok then
		NotificationController.Show("error." .. tostring(result.code))
		return false
	end
	PlayerAuraShopController.Refresh()
	return true
end

function PlayerAuraShopController.Init()
	window = UIKit.window({ name = "PlayerAuras", title = Localization.t("paura.title"), icon = "✨", header = Color3.fromRGB(200, 60, 120) })
	UIKit.text(window.content, { name = "Hint", text = Localization.t("paura.hint"), size = UDim2.new(1, -24, 0, 22), position = UDim2.fromOffset(12, 6), color = Theme.Colors.TextMuted })
	summary = UIKit.text(window.content, { name = "Summary", text = "", size = UDim2.new(1, -24, 0, 26), position = UDim2.fromOffset(12, 30), color = Color3.fromRGB(255, 220, 90) })
	list = UIKit.new("ScrollingFrame", {
		Name = "List",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -16, 1, -70),
		Position = UDim2.fromOffset(8, 62),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 8,
		BorderSizePixel = 0,
	}, window.content)
	UIKit.list(list, false, 8)
	confirmFrame = UIKit.new("Frame", {
		Name = "BuyConfirm",
		BackgroundColor3 = Color3.fromRGB(30, 24, 48),
		Size = UDim2.new(0.8, 0, 0, 240),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Visible = false,
		ZIndex = 20,
	}, window.content)
	UIKit.corner(confirmFrame, 14)
	UIKit.stroke(confirmFrame, 3, Color3.fromRGB(255, 220, 90), true)
	confirmText = UIKit.text(confirmFrame, { name = "Body", text = "", size = UDim2.new(1, -24, 0, 160), position = UDim2.fromOffset(12, 10), wrap = true, z = 21 })
	UIKit.button(confirmFrame, {
		name = "Cancel",
		text = Localization.t("paura.cancel"),
		color = Color3.fromRGB(90, 90, 110),
		size = UDim2.fromOffset(150, 48),
		position = UDim2.new(0.5, -10, 1, -12),
		anchor = Vector2.new(1, 1),
		onClick = function()
			pendingTier = nil
			confirmFrame.Visible = false
		end,
	})
	UIKit.button(confirmFrame, {
		name = "Confirm",
		text = Localization.t("paura.buy"),
		color = Theme.Colors.Orange,
		size = UDim2.fromOffset(170, 48),
		position = UDim2.new(0.5, 10, 1, -12),
		anchor = Vector2.new(0, 1),
		onClick = function()
			task.spawn(PlayerAuraShopController.ConfirmBuy)
		end,
	})
	window.Opened:Connect(PlayerAuraShopController.Refresh)
end

function PlayerAuraShopController.Start()
	DataController.Wait()
	local right = HudController.Containers.Right
	if right then
		UIKit.iconButton(right, {
			name = "AurasShortcut",
			icon = "✨",
			text = Localization.t("paura.short"),
			color = Color3.fromRGB(200, 60, 120),
			size = UDim2.fromOffset(96, 100),
			order = 4,
			onClick = function()
				UIKit.Windows.toggle("PlayerAuras")
			end,
		})
	end
	DataController.Changed:Connect(function(key)
		if key == "PlayerAura" or key == "Money" or key == "LifetimeMoneyGenerated" then
			PlayerAuraShopController.Refresh()
		end
	end)
end

return PlayerAuraShopController
