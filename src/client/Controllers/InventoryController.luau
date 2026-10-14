--!strict
--[[
	InventoryController: janela MOCHILA.
	    grade de cards (retrato, nome, raridade, Power, Income) + filtros
	    (Todos / Raridade / Power / Income / Recentes) + busca por nome
	    painel de detalhes: EQUIPAR / DESEQUIPAR / TRAVAR / FAVORITAR / VENDER
	    EQUIPAR MELHORES e capacidade (45/100)
	Toda ação é um PEDIDO; o servidor valida (dono, slot, proteção) e responde.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local CharacterConfig = require(Shared.Config.CharacterConfig)
local RarityConfig = require(Shared.Config.RarityConfig)
local Formulas = require(Shared.Modules.GameFormulas)
local SaleCore = require(Shared.Modules.SaleCore)
local EconomyConfig = require(Shared.Config.EconomyConfig)
local CharacterModelFactory = require(Shared.Modules.CharacterModelFactory)
local CharacterAssetConfig = require(Shared.Config.CharacterAssetConfig)
local NumberFormatter = require(Shared.Modules.NumberFormatter)
local Localization = require(Shared.Localization.Localization)
local Net = require(Shared.Modules.Net)

local UI = script.Parent.Parent.UI
local UIKit = require(UI.UIKit)
local CharacterPreview = require(UI.CharacterPreview)
local Theme = require(UI.UITheme)
local DataController = require(script.Parent.DataController)
local NotificationController = require(script.Parent.NotificationController)
local HudController = require(script.Parent.HudController)

local InventoryController = {}

local FILTERS = { "All", "Rarity", "Power", "Income", "Recent" }

local window: UIKit.Window
local grid: ScrollingFrame
local capacityLabel: TextLabel
local searchBox: TextBox
local filterButtons: { [string]: TextButton } = {}
local detail: Frame
local detailLabels: { [string]: TextLabel } = {}
local detailButtons: { [string]: TextButton } = {}
local portrait: ViewportFrame
local duplicates: { [string]: number } = {}
local portraitModel: Model? = nil

local filter = "All"
local search = ""
local selected: string? = nil
local dirty = true

function InventoryController.Selected(): string?
	return selected
end

local function tierOf(item: any): number
	local character = CharacterConfig.ById[item.Id]
	return if character then RarityConfig.ById[character.Rarity].Tier else 0
end

local function isEquipped(data: any, uid: string): boolean
	for _, equipped in data.EquippedCharacters or {} do
		if equipped == uid then
			return true
		end
	end
	return false
end

local function sortedUids(data: any): { string }
	local list = {}
	local query = string.lower(search)
	for uid, item in data.Inventory do
		local character = CharacterConfig.ById[item.Id]
		if character and (query == "" or string.find(string.lower(character.Name), query, 1, true)) then
			table.insert(list, uid)
		end
	end
	local inventory = data.Inventory
	table.sort(list, function(a, b)
		local ia, ib = inventory[a], inventory[b]
		local ca, cb = CharacterConfig.ById[ia.Id], CharacterConfig.ById[ib.Id]
		if filter == "Power" then
			if ca.BasePower ~= cb.BasePower then
				return ca.BasePower > cb.BasePower
			end
		elseif filter == "Income" then
			local xa, xb = Formulas:unitIncome(ia), Formulas:unitIncome(ib)
			if xa ~= xb then
				return xa > xb
			end
		elseif filter == "Recent" then
			if ia.ObtainedAt ~= ib.ObtainedAt then
				return ia.ObtainedAt > ib.ObtainedAt
			end
		else
			local ta, tb = tierOf(ia), tierOf(ib)
			if ta ~= tb then
				return ta > tb
			end
			if filter == "All" then
				local xa, xb = Formulas:unitIncome(ia), Formulas:unitIncome(ib)
				if xa ~= xb then
					return xa > xb
				end
			end
		end
		return a < b
	end)
	return list
end

local function setPortrait(characterId: string?, variant: string?)
	if portraitModel then
		portraitModel:Destroy()
		portraitModel = nil
	end
	if characterId then
		local model = CharacterModelFactory.build(characterId, { variant = variant, aura = false, vfx = CharacterAssetConfig.VFXModes.Inventory })
		model:PivotTo(CFrame.Angles(0, math.pi, 0))
		model.Parent = portrait
		portraitModel = model
	end
end

local function refreshDetail()
	local data = DataController.GetAll()
	local item = data and selected and data.Inventory[selected]
	if not data or not item then
		selected = nil
		detail.Visible = false
		setPortrait(nil)
		return
	end
	detail.Visible = true
	local character = CharacterConfig.ById[item.Id]
	setPortrait(item.Id, item.Variant)
	detailLabels.Name.Text = character.Name
	detailLabels.Rarity.Text = Localization.t("rarity." .. character.Rarity)
	detailLabels.Rarity.TextColor3 = UIKit.rarityColor(character.Rarity)
	local variant = if item.Variant and item.Variant ~= "Normal" then Localization.t("variant." .. item.Variant) .. " · " else ""
	detailLabels.Level.Text = variant .. Localization.t("station.level", { level = item.Level or 1 })
	detailLabels.Power.Text = "⚔️ " .. NumberFormatter.abbreviate(character.BasePower)
	detailLabels.Income.Text = "💵 " .. NumberFormatter.money(Formulas:unitIncome(item)) .. "/s"
	local equipped = isEquipped(data, selected :: string)
	UIKit.setButtonText(detailButtons.Equip, Localization.t(if equipped then "inv.unequip" else "inv.equip"))
	UIKit.setButtonColor(detailButtons.Equip, if equipped then Theme.Colors.Orange else Theme.Colors.Success)
	UIKit.setButtonText(detailButtons.Lock, (if item.Locked then "🔒 " else "🔓 ") .. Localization.t(if item.Locked then "inv.unlock" else "inv.lock"))
	UIKit.setButtonText(detailButtons.Favorite, (if item.Favorite then "⭐ " else "☆ ") .. Localization.t(if item.Favorite then "inv.unfavorite" else "inv.favorite"))
	local inTeam = table.find(data.TowerTeam or {}, selected) ~= nil
	UIKit.setButtonText(detailButtons.Team, (if inTeam then "✓ " else "🗼 ") .. Localization.t("inv.tower_team"))
	-- só exibição (mesma conta do servidor: base + 75% do investido em níveis)
	local quote = SaleCore.quote(Formulas, item, EconomyConfig.UpgradeRefundPercent)
	UIKit.setButtonText(detailButtons.Sell, Localization.t("inv.sell", { amount = NumberFormatter.money(quote.Total) }))
end

local function card(data: any, uid: string, order: number)
	local item = data.Inventory[uid]
	local character = CharacterConfig.ById[item.Id]
	local color = UIKit.rarityColor(character.Rarity)
	local button = UIKit.new("TextButton", {
		Name = uid,
		Text = "",
		AutoButtonColor = true,
		BackgroundColor3 = if uid == selected then Theme.Colors.CardHover else Theme.Colors.Card,
		LayoutOrder = order,
	}, grid)
	UIKit.corner(button, Theme.CornerRadiusSmall)
	UIKit.stroke(button, if uid == selected then 4 else 3, color, true)
	UIKit.gradient(button, UIKit.darken(color, 0.45), Theme.Colors.Card, 90)
	-- retrato REAL (lazy + pool; ícone só se o asset falhar)
	local portraitArea = UIKit.new("Frame", { Name = "Portrait", BackgroundTransparency = 1, Size = UDim2.fromScale(0.86, 0.5), Position = UDim2.fromScale(0.5, 0.02), AnchorPoint = Vector2.new(0.5, 0) }, button)
	CharacterPreview.attach(portraitArea, item.Id, item.Variant, "body", character.VisualTheme.Icon)
	if (item.Variant or "Normal") ~= "Normal" then
		UIKit.text(button, { name = "Variant", text = Localization.t("variant." .. item.Variant), size = UDim2.new(0.6, 0, 0.12, 0), position = UDim2.new(0, 4, 0.4, 0), align = Enum.TextXAlignment.Left, color = Color3.fromRGB(255, 225, 120) })
	end
	local copies = duplicates[item.Id] or 1
	if copies > 1 then
		UIKit.text(button, { name = "Copies", text = "x" .. copies, size = UDim2.new(0.4, 0, 0.12, 0), position = UDim2.new(1, -4, 0.4, 0), anchor = Vector2.new(1, 0), align = Enum.TextXAlignment.Right, color = Theme.Colors.TextMuted })
	end
	UIKit.text(button, { text = character.Name, size = UDim2.fromScale(0.94, 0.17), position = UDim2.fromScale(0.5, 0.52), anchor = Vector2.new(0.5, 0) })
	UIKit.text(button, { text = Localization.t("rarity." .. character.Rarity), size = UDim2.fromScale(0.9, 0.12), position = UDim2.fromScale(0.5, 0.69), anchor = Vector2.new(0.5, 0), color = color })
	UIKit.text(button, { text = NumberFormatter.money(Formulas:unitIncome(item)) .. "/s", size = UDim2.fromScale(0.9, 0.14), position = UDim2.fromScale(0.5, 0.83), anchor = Vector2.new(0.5, 0), color = Theme.Colors.Money })
	local tags = (if item.Locked then "🔒" else "") .. (if item.Favorite then "⭐" else "") .. (if isEquipped(data, uid) then "🏠" else "")
	if tags ~= "" then
		UIKit.text(button, { text = tags, size = UDim2.new(1, -8, 0.16, 0), position = UDim2.fromOffset(4, 2), align = Enum.TextXAlignment.Left, stroke = 0 })
	end
	if (item.Level or 1) > 1 then
		UIKit.text(button, { text = "Nv " .. item.Level, size = UDim2.new(0.5, 0, 0.14, 0), position = UDim2.new(1, -4, 0, 2), anchor = Vector2.new(1, 0), align = Enum.TextXAlignment.Right, color = Color3.fromRGB(150, 230, 255) })
	end
	button.Activated:Connect(function()
		selected = uid
		dirty = true
		InventoryController.Refresh()
	end)
end

function InventoryController.Refresh()
	local data = DataController.GetAll()
	if not data or not window.isOpen then
		dirty = true
		return
	end
	dirty = false
	CharacterPreview.releaseScope(grid) -- devolve os modelos ao pool antes de refazer os cards
	for _, child in grid:GetChildren() do
		if child:IsA("GuiButton") then
			child:Destroy()
		end
	end
	table.clear(duplicates)
	for _, it in data.Inventory do
		duplicates[it.Id] = (duplicates[it.Id] or 0) + 1
	end
	local list = sortedUids(data)
	for i, uid in list do
		card(data, uid, i)
	end
	local count = 0
	for _ in data.Inventory do
		count += 1
	end
	capacityLabel.Text = string.format("%d / %d", count, Formulas:capacity(data))
	capacityLabel.TextColor3 = if count >= Formulas:capacity(data) then Theme.Colors.Danger else Theme.Colors.Text
	for id, button in filterButtons do
		UIKit.setButtonColor(button, if id == filter then Theme.Colors.Primary else Color3.fromRGB(70, 70, 92))
	end
	refreshDetail()
	CharacterPreview.update()
end

local function request(name: string, ...: any)
	local result = Net.request(name, ...)
	if not result.ok then
		NotificationController.Show("error." .. tostring(result.code))
	end
	return result
end

local function build()
	window = UIKit.window({ name = "Inventory", title = Localization.t("inv.title"), icon = "🎒", size = Theme.PopupSizes.Large, header = Color3.fromRGB(100, 110, 255) })
	local content = window.content
	UIKit.padding(content, 10)

	-- Barra superior: filtros, busca, capacidade, equipar melhores
	local top = UIKit.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 44) }, content)
	UIKit.list(top, true, 6)
	for i, id in FILTERS do
		filterButtons[id] = UIKit.button(top, {
			text = Localization.t("inv.filter." .. id),
			size = UDim2.fromOffset(92, 40),
			order = i,
			onClick = function()
				filter = id
				InventoryController.Refresh()
			end,
		})
	end
	searchBox = UIKit.new("TextBox", {
		Size = UDim2.fromOffset(150, 40),
		BackgroundColor3 = Theme.Colors.Card,
		PlaceholderText = Localization.t("inv.search"),
		Text = "",
		Font = Theme.Font,
		TextScaled = true,
		TextColor3 = Theme.Colors.Text,
		ClearTextOnFocus = false,
		LayoutOrder = 10,
	}, top)
	UIKit.corner(searchBox, 8)
	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		search = string.sub(searchBox.Text, 1, 30)
		InventoryController.Refresh()
	end)
	capacityLabel = UIKit.text(top, { text = "0 / 100", size = UDim2.fromOffset(90, 40), order = 11 })

	-- Grade
	grid = UIKit.new("ScrollingFrame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -280, 1, -54),
		Position = UDim2.fromOffset(0, 54),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 8,
		BorderSizePixel = 0,
	}, content)
	UIKit.new("UIGridLayout", {
		CellSize = UDim2.fromOffset(112, 138),
		CellPadding = UDim2.fromOffset(8, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, grid)
	UIKit.padding(grid, 4)

	-- Detalhes
	detail = UIKit.new("Frame", {
		BackgroundColor3 = Theme.Colors.Card,
		Size = UDim2.new(0, 268, 1, -54),
		Position = UDim2.new(1, 0, 0, 54),
		AnchorPoint = Vector2.new(1, 0),
		Visible = false,
	}, content)
	UIKit.corner(detail, Theme.CornerRadiusSmall)
	portrait = UIKit.new("ViewportFrame", {
		Size = UDim2.new(1, -16, 0, 150),
		Position = UDim2.fromOffset(8, 6),
		BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(170, 170, 185),
	}, detail)
	local camera = Instance.new("Camera")
	camera.FieldOfView = 35
	camera.CFrame = CFrame.lookAt(Vector3.new(0, 4.5, 15), Vector3.new(0, 3.5, 0))
	camera.Parent = portrait
	portrait.CurrentCamera = camera
	local y = 158
	for _, key in { "Name", "Rarity", "Level", "Power", "Income" } do
		local h = if key == "Name" then 30 else 22
		detailLabels[key] = UIKit.text(detail, { name = key, size = UDim2.new(1, -16, 0, h), position = UDim2.fromOffset(8, y) })
		y += h + 2
	end
	detailLabels.Income.TextColor3 = Theme.Colors.Money
	local actions = UIKit.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -16, 0, 150), Position = UDim2.new(0, 8, 1, -156) }, detail)
	UIKit.new("UIGridLayout", { CellSize = UDim2.new(0.5, -4, 0, 44), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder }, actions)
	detailButtons.Equip = UIKit.button(actions, { text = "", color = Theme.Colors.Success, order = 1, onClick = function()
		local data = DataController.GetAll()
		local uid = selected
		if not data or not uid then
			return
		end
		if isEquipped(data, uid) then
			request("UnequipCharacter", uid)
		else
			request("EquipCharacter", uid)
		end
		InventoryController.Refresh()
	end })
	detailButtons.Lock = UIKit.button(actions, { text = "", color = Color3.fromRGB(90, 90, 120), order = 2, onClick = function()
		local data = DataController.GetAll()
		local item = data and selected and data.Inventory[selected]
		if item then
			request("SetCharacterFlag", selected, "Locked", not item.Locked)
		end
	end })
	detailButtons.Favorite = UIKit.button(actions, { text = "", color = Color3.fromRGB(230, 170, 40), order = 3, onClick = function()
		local data = DataController.GetAll()
		local item = data and selected and data.Inventory[selected]
		if item then
			request("SetCharacterFlag", selected, "Favorite", not item.Favorite)
		end
	end })
	detailButtons.Sell = UIKit.button(actions, { text = "", color = Theme.Colors.Danger, order = 4, onClick = function()
		local uid = selected
		if not uid then
			return
		end
		local data = DataController.GetAll()
		local item = data and data.Inventory[uid]
		if not item then
			return
		end
		-- prévia AUTORITATIVA do servidor (a venda recebe exatamente este total)
		local preview = request("PreviewSale", { uid })
		local quote = preview.ok and preview.data.items[uid]
		if not quote then
			return
		end
		UIKit.confirm(
			Localization.t("sell.confirm_breakdown", {
				name = CharacterConfig.ById[item.Id].Name,
				base = NumberFormatter.money(quote.Base),
				invested = NumberFormatter.money(quote.Invested),
				percent = math.floor(quote.Percent * 100 + 0.5),
				refund = NumberFormatter.money(quote.Refund),
				total = NumberFormatter.money(quote.Total),
			}),
			Localization.t("sell.yes"),
			Localization.t("sell.cancel"),
			function()
				local result = request("SellCharacter", { uid })
				if result.ok then
					UIKit.sound("Coin")
					selected = nil
				end
			end
		)
	end })
	detailButtons.Best = UIKit.button(actions, { text = Localization.t("inv.equip_best"), color = Theme.Colors.Purple, order = 5, onClick = function()
		local result = request("EquipBest")
		if result.ok then
			NotificationController.Show("inv.best_done", { count = result.data })
		end
	end })
	detailButtons.Team = UIKit.button(actions, { text = "", color = Color3.fromRGB(120, 70, 220), order = 6, onClick = function()
		local data = DataController.GetAll()
		local uid = selected
		if not data or not uid then
			return
		end
		local team = table.clone(data.TowerTeam or {})
		local index = table.find(team, uid)
		if index then
			table.remove(team, index)
		elseif #team >= 5 then
			NotificationController.Show("tower.team_full")
			return
		else
			table.insert(team, uid)
		end
		request("SetTowerTeam", team)
	end })
	detailButtons.Sell.Name = "SellOne"
	-- EQUIPAR MELHORES também na barra (sem precisar selecionar)
	UIKit.button(top, {
		text = "⚡ " .. Localization.t("inv.equip_best"),
		color = Theme.Colors.Purple,
		size = UDim2.fromOffset(200, 40),
		order = 12,
		onClick = function()
			local result = request("EquipBest")
			if result.ok then
				NotificationController.Show("inv.best_done", { count = result.data })
			end
		end,
	})
	-- fechar a MOCHILA: solta todos os retratos e esvazia o pool (nenhum modelo fica vivo)
	window.Closed:Connect(function()
		CharacterPreview.releaseScope(grid)
		CharacterPreview.trimPool()
	end)
	window.Opened:Connect(function()
		InventoryController.Refresh()
	end)
end

function InventoryController.Init()
	build()
end

function InventoryController.Start()
	DataController.Wait()
	local pending = false
	local function schedule()
		if pending then
			return
		end
		pending = true
		task.delay(0.15, function()
			pending = false
			if window.isOpen then
				InventoryController.Refresh()
			else
				dirty = true
			end
		end)
	end
	DataController.InventoryChanged:Connect(schedule)
	DataController.Changed:Connect(function(key)
		if key == "EquippedCharacters" or key == "Upgrades" or key == "TowerTeam" then
			schedule()
		end
	end)
	-- Aviso na MOCHILA quando estiver cheia
	local function badge()
		local data = DataController.GetAll()
		if not data then
			return
		end
		local count = 0
		for _ in data.Inventory do
			count += 1
		end
		HudController.SetBadge("Backpack", if count >= Formulas:capacity(data) then "!" else nil)
	end
	DataController.InventoryChanged:Connect(badge)
	badge()
	local _ = dirty
end

return InventoryController
