--!strict
--[[
	TradeController (Fase 8): janela TROCAS (mesas de troca no Hub).
	Sem sessão: lista de jogadores do servidor com CONVIDAR.
	Convite recebido: aviso com [ACEITAR] [RECUSAR].
	Em sessão: "SUA OFERTA" (clique nos seus personagens livres para pôr/tirar, até 8) e
	"OFERTA DE <nome>"; PRONTO (os dois) -> CONFIRMAR (os dois) -> troca no servidor.
	Mudar a oferta tira o PRONTO dos dois (sem surpresas de última hora).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local CharacterConfig = require(Shared.Config.CharacterConfig)
local Localization = require(Shared.Localization.Localization)
local Net = require(Shared.Modules.Net)

local UI = script.Parent.Parent.UI
local UIKit = require(UI.UIKit)
local Theme = require(UI.UITheme)
local DataController = require(script.Parent.DataController)
local NotificationController = require(script.Parent.NotificationController)

local TradeController = {}

local MAX_ITEMS = 8

local window: UIKit.Window
local lobby: ScrollingFrame
local session: Frame
local mineFrame: ScrollingFrame
local theirsFrame: Frame
local status: TextLabel
local theirsTitle: TextLabel
local readyButton: TextButton
local confirmButton: TextButton
local state: any = nil

local function clear(frame: Instance)
	for _, child in frame:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local function chip(parent: Instance, item: any, selected: boolean, order: number, onClick: (() -> ())?): TextButton
	local character = CharacterConfig.ById[item.id or item.Id]
	local button = UIKit.new("TextButton", {
		Name = "Item_" .. tostring(item.uid or ""),
		Text = "",
		AutoButtonColor = onClick ~= nil,
		Size = UDim2.fromOffset(78, 92),
		BackgroundColor3 = if selected then Color3.fromRGB(60, 120, 70) else Theme.Colors.Card,
		LayoutOrder = order,
	}, parent)
	UIKit.corner(button, 8)
	UIKit.stroke(button, 2.5, UIKit.rarityColor(character and character.Rarity or "Common"), true)
	UIKit.text(button, { text = character and character.VisualTheme.Icon or "?", size = UDim2.fromScale(0.8, 0.5), position = UDim2.fromScale(0.5, 0.05), anchor = Vector2.new(0.5, 0), stroke = 0 })
	UIKit.text(button, { text = character and character.Name or "?", size = UDim2.new(0.95, 0, 0.22, 0), position = UDim2.fromScale(0.5, 0.56), anchor = Vector2.new(0.5, 0) })
	local variant = item.variant or item.Variant
	UIKit.text(button, { text = "Nv " .. tostring(item.level or item.Level or 1) .. (if variant and variant ~= "Normal" then " · " .. Localization.t("variant." .. variant) else ""), size = UDim2.new(0.95, 0, 0.18, 0), position = UDim2.fromScale(0.5, 0.8), anchor = Vector2.new(0.5, 0), color = Theme.Colors.TextMuted })
	if onClick then
		button.Activated:Connect(onClick)
	end
	return button
end

local function request(name: string, ...: any)
	local result = Net.request(name, ...)
	if not result.ok then
		NotificationController.Show("error." .. tostring(result.code))
	end
	return result
end

local function renderLobby()
	clear(lobby)
	local count = 0
	for _, other in Players:GetPlayers() do
		if other ~= Players.LocalPlayer then
			count += 1
			local row = UIKit.new("Frame", { BackgroundColor3 = Theme.Colors.Card, Size = UDim2.new(1, -8, 0, 58), LayoutOrder = count }, lobby)
			UIKit.corner(row, 10)
			UIKit.text(row, { text = other.DisplayName, size = UDim2.new(0.6, 0, 0, 30), position = UDim2.new(0, 12, 0.5, 0), anchor = Vector2.new(0, 0.5), align = Enum.TextXAlignment.Left })
			UIKit.button(row, {
				text = Localization.t("trade.invite"),
				color = Theme.Colors.Primary,
				size = UDim2.fromOffset(150, 44),
				position = UDim2.new(1, -8, 0.5, 0),
				anchor = Vector2.new(1, 0.5),
				onClick = function()
					if request("RequestTrade", other.UserId).ok then
						NotificationController.Show("trade.sent", { name = other.DisplayName })
					end
				end,
			})
		end
	end
	if count == 0 then
		UIKit.text(lobby, { text = Localization.t("trade.alone"), size = UDim2.new(1, 0, 0, 40), color = Theme.Colors.TextMuted })
	end
end

local function renderSession()
	local data = DataController.GetAll()
	if not data or not state then
		return
	end
	theirsTitle.Text = Localization.t("trade.theirs", { name = state.partnerName })
	-- Minha oferta: todos os meus personagens livres; os oferecidos ficam verdes
	clear(mineFrame)
	local offered = {}
	for _, item in state.mine do
		offered[item.uid] = true
	end
	local uids = {}
	for uid, item in data.Inventory do
		local equipped = false
		for _, e in data.EquippedCharacters do
			if e == uid then
				equipped = true
			end
		end
		if not item.Locked and not item.Favorite and not equipped then
			table.insert(uids, uid)
		end
	end
	table.sort(uids)
	local layoutOrder = 0
	for _, uid in uids do
		layoutOrder += 1
		local item = data.Inventory[uid]
		chip(mineFrame, { uid = uid, id = item.Id, level = item.Level, variant = item.Variant }, offered[uid] == true, if offered[uid] then layoutOrder - 1000 else layoutOrder, function()
			local list = {}
			for _, it in state.mine do
				if it.uid ~= uid then
					table.insert(list, it.uid)
				end
			end
			if not offered[uid] then
				if #list >= MAX_ITEMS then
					NotificationController.Show("error.trade_too_many")
					return
				end
				table.insert(list, uid)
			end
			request("SetTradeOffer", list)
		end)
	end
	clear(theirsFrame)
	for i, item in state.theirs do
		chip(theirsFrame, item, false, i, nil)
	end
	local lines = {}
	table.insert(lines, Localization.t(if state.myReady then "trade.you_ready" else "trade.you_not_ready"))
	table.insert(lines, Localization.t(if state.theirReady then "trade.they_ready" else "trade.they_not_ready"))
	if state.myConfirmed then
		table.insert(lines, Localization.t("trade.waiting_confirm"))
	end
	status.Text = table.concat(lines, "   ·   ")
	UIKit.setButtonText(readyButton, Localization.t(if state.myReady then "trade.unready" else "trade.ready"))
	UIKit.setButtonColor(readyButton, if state.myReady then Theme.Colors.Orange else Theme.Colors.Primary)
	local canConfirm = state.myReady and state.theirReady and not state.myConfirmed
	UIKit.setButtonColor(confirmButton, if canConfirm then Theme.Colors.Success else Theme.Colors.Locked)
end

function TradeController.Refresh()
	if not window.isOpen then
		return
	end
	lobby.Visible = state == nil
	session.Visible = state ~= nil
	if state then
		renderSession()
	else
		renderLobby()
	end
end

function TradeController.State(): any
	return state
end

function TradeController.Init()
	window = UIKit.window({ name = "Trade", title = Localization.t("trade.title"), icon = "🤝", size = Theme.PopupSizes.Large, header = Color3.fromRGB(60, 170, 200) })
	local content = window.content
	lobby = UIKit.new("ScrollingFrame", {
		Name = "Lobby",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -16, 1, -16),
		Position = UDim2.fromOffset(8, 8),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		BorderSizePixel = 0,
	}, content)
	UIKit.list(lobby, false, 8)
	session = UIKit.new("Frame", { Name = "Session", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false }, content)
	UIKit.text(session, { text = Localization.t("trade.mine"), size = UDim2.new(0.48, 0, 0, 28), position = UDim2.fromOffset(10, 6), align = Enum.TextXAlignment.Left })
	theirsTitle = UIKit.text(session, { size = UDim2.new(0.48, 0, 0, 28), position = UDim2.new(0.5, 6, 0, 6), align = Enum.TextXAlignment.Left })
	mineFrame = UIKit.new("ScrollingFrame", {
		Name = "Mine",
		BackgroundColor3 = Theme.Colors.PanelBackground,
		Size = UDim2.new(0.5, -14, 1, -140),
		Position = UDim2.fromOffset(8, 38),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		BorderSizePixel = 0,
	}, session)
	UIKit.new("UIGridLayout", { CellSize = UDim2.fromOffset(78, 92), CellPadding = UDim2.fromOffset(6, 6), SortOrder = Enum.SortOrder.LayoutOrder }, mineFrame)
	theirsFrame = UIKit.new("Frame", { Name = "Theirs", BackgroundColor3 = Theme.Colors.PanelBackground, Size = UDim2.new(0.5, -14, 1, -140), Position = UDim2.new(0.5, 6, 0, 38) }, session)
	UIKit.new("UIGridLayout", { CellSize = UDim2.fromOffset(78, 92), CellPadding = UDim2.fromOffset(6, 6), SortOrder = Enum.SortOrder.LayoutOrder }, theirsFrame)
	status = UIKit.text(session, { size = UDim2.new(1, -20, 0, 26), position = UDim2.new(0, 10, 1, -96), color = Theme.Colors.TextMuted })
	local buttons = UIKit.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 60), Position = UDim2.new(0, 0, 1, -64) }, session)
	UIKit.list(buttons, true, 12, "center")
	readyButton = UIKit.button(buttons, { name = "Ready", text = "", size = UDim2.fromOffset(190, 54), order = 1, onClick = function()
		if state then
			request("SetTradeReady", not state.myReady)
		end
	end })
	confirmButton = UIKit.button(buttons, { name = "Confirm", text = Localization.t("trade.confirm"), color = Theme.Colors.Success, size = UDim2.fromOffset(190, 54), order = 2, onClick = function()
		request("ConfirmTrade")
	end })
	UIKit.button(buttons, { name = "CancelTrade", text = Localization.t("sell.cancel"), color = Theme.Colors.Danger, size = UDim2.fromOffset(190, 54), order = 3, onClick = function()
		request("CancelTrade")
	end })
	window.Opened:Connect(TradeController.Refresh)
end

function TradeController.Start()
	Net.on("TradeRequest", function(userId: number, name: string)
		NotificationController.ShowAction("trade.request", {
			{ text = Localization.t("trade.accept"), color = Theme.Colors.Success, onClick = function()
				if request("RespondTrade", userId, true).ok then
					UIKit.Windows.open("Trade")
				end
			end },
			{ text = Localization.t("trade.decline"), color = Theme.Colors.Danger, onClick = function()
				request("RespondTrade", userId, false)
			end },
		})
		NotificationController.Show("trade.request_from", { name = name })
	end)
	Net.on("TradeUpdate", function(newState: any)
		state = newState
		if not window.isOpen then
			window:Open()
		end
		TradeController.Refresh()
	end)
	Net.on("TradeClosed", function(reason: string)
		state = nil
		NotificationController.Show("trade.closed_" .. tostring(reason))
		if reason == "completed" then
			UIKit.sound("Reward")
		end
		TradeController.Refresh()
	end)
	DataController.InventoryChanged:Connect(function()
		if state then
			TradeController.Refresh()
		end
	end)
end

return TradeController
