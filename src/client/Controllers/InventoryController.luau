--!strict
--[[
	InventoryController: janela MOCHILA.
	    grade de cards (retrato, nome, raridade, Power, Income) + filtros
	    (Todos / Raridade / Power / Income / Recentes) + busca por nome
	    painel de detalhes: EQUIPAR / DESEQUIPAR / TRAVAR / FAVORITAR / VENDER
	    EQUIPAR MELHORES e capacidade (45/100)
	Cabeçalho RESPONSIVO (ResponsiveLayout.backpackHeader): MOCHILA + capacidade · filtros +
	busca · EQUIPAR MELHORES + 🗑; uma linha no largo, duas no compacto/retrato (reorganiza,
	não só encolhe). A janela acompanha a tela (UIKit.fitWindow).
	MODO VENDA (🗑): tocar nos cards marca/desmarca (borda vermelha, ✓, véu discreto — o
	retrato continua visível e NENHUM ViewportFrame é recriado); rodapé com "X selecionados",
	"Você receberá" (prévia do SERVIDOR, PreviewBulkSale), SELECIONAR DUPLICATAS, CANCELAR e
	VENDER; sempre pede confirmação; o servidor revalida tudo (SellBulk). Favoritos, travados,
	na base e no time da Torre não são selecionáveis (o jogador desvincula antes).
	Toda ação é um PEDIDO; o servidor valida (dono, slot, proteção) e responde.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local CharacterConfig = require(Shared.Config.CharacterConfig)
local RarityConfig = require(Shared.Config.RarityConfig)
local Formulas = require(Shared.Modules.GameFormulas)
local SaleCore = require(Shared.Modules.SaleCore)
local BulkSaleCore = require(Shared.Modules.BulkSaleCore)
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
local ResponsiveLayout = require(UI.ResponsiveLayout)
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

-- cabeçalho/rodapé responsivos
local header: Frame
local headerParts: { [string]: GuiObject } = {}
local footer: Frame
local footerParts: { [string]: GuiObject } = {}
local footerInfo: TextLabel
local detailClose: TextButton
local layoutSize = Vector2.new(856, 478)

-- MODO VENDA
local saleMode = false
local saleSelection: { [string]: boolean } = {}
local salePreview: any = nil
local salePending = false
local saleToken = 0
local saleRequests = 0

-- motivo de bloqueio no CLIENTE (só para não deixar selecionar; o servidor revalida tudo)
local function clientProtection(data: any, uid: string): string?
	local item = data.Inventory[uid]
	if not item then
		return "not_owned"
	end
	if item.Locked then
		return "locked"
	end
	if item.Favorite then
		return "favorite"
	end
	for _, equipped in data.EquippedCharacters or {} do
		if equipped == uid then
			return "equipped"
		end
	end
	return nil
end

-- textos fixos por motivo (o verificador de chaves exige chaves literais)
local BLOCK_KEYS = {
	locked = "error.locked",
	favorite = "error.favorite",
	equipped = "error.equipped",
	tower_team = "error.tower_team",
	in_trade = "error.in_trade",
	not_owned = "error.not_owned",
}

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

-- Cards PERSISTENTES por uid: Refresh só ATUALIZA o que mudou (textos, ordem, visibilidade) —
-- nunca destrói/recria a grade inteira; o retrato (CharacterPreview.set) fica montado enquanto o
-- card representa o mesmo personagem/variante. Seleção muda só o card antigo, o novo e o painel.
local cards: { [string]: TextButton } = {}

local function setSelectedVisual(button: TextButton?, on: boolean)
	if not button then
		return
	end
	button.BackgroundColor3 = if on then Theme.Colors.CardHover else Theme.Colors.Card
	local stroke = button:FindFirstChild("RarityStroke") :: UIStroke?
	if stroke and not (saleMode and saleSelection[button.Name]) then
		stroke.Thickness = if on then 4 else 3
	end
end

local function setText(button: Instance, name: string, text: string, visible: boolean?)
	local label = button:FindFirstChild(name) :: TextLabel?
	if label then
		if label.Text ~= text then
			label.Text = text
		end
		label.Visible = if visible == nil then true else visible
	end
end

-- Atualiza o card no lugar (textos/tags/retrato só se mudou)
local function updateCard(button: TextButton, data: any, uid: string)
	local item = data.Inventory[uid]
	local character = CharacterConfig.ById[item.Id]
	local variant = item.Variant or "Normal"
	setText(button, "Variant", if variant ~= "Normal" then Localization.t("variant." .. variant) else "", variant ~= "Normal")
	local copies = duplicates[item.Id] or 1
	setText(button, "Copies", "x" .. copies, copies > 1)
	setText(button, "Income", NumberFormatter.money(Formulas:unitIncome(item)) .. "/s")
	local tags = (if item.Locked then "🔒" else "") .. (if item.Favorite then "⭐" else "") .. (if isEquipped(data, uid) then "🏠" else "")
	setText(button, "Tags", tags, tags ~= "")
	setText(button, "Level", "Nv " .. tostring(item.Level or 1), (item.Level or 1) > 1)
	local portraitArea = button:FindFirstChild("Portrait") :: Frame?
	if portraitArea then
		CharacterPreview.set(portraitArea, item.Id, variant, "body", character.VisualTheme.Icon)
	end
end

local function card(data: any, uid: string, order: number): TextButton
	local item = data.Inventory[uid]
	local character = CharacterConfig.ById[item.Id]
	local color = UIKit.rarityColor(character.Rarity)
	local button = UIKit.new("TextButton", {
		Name = uid,
		Text = "",
		AutoButtonColor = true,
		BackgroundColor3 = Theme.Colors.Card,
		LayoutOrder = order,
	}, grid)
	UIKit.corner(button, Theme.CornerRadiusSmall)
	local stroke = UIKit.stroke(button, 3, color, true)
	stroke.Name = "RarityStroke"
	button:SetAttribute("RarityColor", color)
	UIKit.gradient(button, UIKit.darken(color, 0.45), Theme.Colors.Card, 90)
	-- retrato REAL (lazy + pool; ícone só se o asset falhar)
	UIKit.new("Frame", { Name = "Portrait", BackgroundTransparency = 1, Size = UDim2.fromScale(0.86, 0.5), Position = UDim2.fromScale(0.5, 0.02), AnchorPoint = Vector2.new(0.5, 0) }, button)
	UIKit.text(button, { name = "Variant", text = "", size = UDim2.new(0.6, 0, 0.12, 0), position = UDim2.new(0, 4, 0.4, 0), align = Enum.TextXAlignment.Left, color = Color3.fromRGB(255, 225, 120) })
	UIKit.text(button, { name = "Copies", text = "", size = UDim2.new(0.4, 0, 0.12, 0), position = UDim2.new(1, -4, 0.4, 0), anchor = Vector2.new(1, 0), align = Enum.TextXAlignment.Right, color = Theme.Colors.TextMuted })
	UIKit.text(button, { name = "CharName", text = character.Name, size = UDim2.fromScale(0.94, 0.17), position = UDim2.fromScale(0.5, 0.52), anchor = Vector2.new(0.5, 0) })
	UIKit.text(button, { name = "Rarity", text = Localization.t("rarity." .. character.Rarity), size = UDim2.fromScale(0.9, 0.12), position = UDim2.fromScale(0.5, 0.69), anchor = Vector2.new(0.5, 0), color = color })
	UIKit.text(button, { name = "Income", text = "", size = UDim2.fromScale(0.9, 0.14), position = UDim2.fromScale(0.5, 0.83), anchor = Vector2.new(0.5, 0), color = Theme.Colors.Money })
	UIKit.text(button, { name = "Tags", text = "", size = UDim2.new(1, -8, 0.16, 0), position = UDim2.fromOffset(4, 2), align = Enum.TextXAlignment.Left, stroke = 0 })
	UIKit.text(button, { name = "Level", text = "", size = UDim2.new(0.5, 0, 0.14, 0), position = UDim2.new(1, -4, 0, 2), anchor = Vector2.new(1, 0), align = Enum.TextXAlignment.Right, color = Color3.fromRGB(150, 230, 255) })
	button.Activated:Connect(function()
		if saleMode then
			InventoryController.ToggleSale(uid)
			return
		end
		InventoryController.Select(uid)
	end)
	cards[uid] = button
	updateCard(button, data, uid)
	return button
end

-- Seleção: só o card antigo, o novo e o painel de detalhes mudam (nenhum retrato da grade remonta)
function InventoryController.Select(uid: string?)
	local previous = selected
	selected = uid
	if previous and previous ~= uid then
		setSelectedVisual(cards[previous], false)
	end
	if uid then
		setSelectedVisual(cards[uid], true)
	end
	refreshDetail()
end

------------------------------------------------------------------------------------
-- MODO VENDA: só muda o visual dos cards existentes (nenhum card/ViewportFrame é recriado)

local function cardOf(uid: string): GuiButton?
	local b = grid:FindFirstChild(uid)
	return if b and b:IsA("GuiButton") then b else nil
end

local function saleVisual(button: GuiButton, uid: string, data: any)
	local picked = saleMode and saleSelection[uid] == true
	local blocked = saleMode and (clientProtection(data, uid) ~= nil or table.find(data.TowerTeam or {}, uid) ~= nil)
	local stroke = button:FindFirstChild("RarityStroke") :: UIStroke?
	if stroke then
		stroke.Color = if picked then Theme.Colors.Danger else (button:GetAttribute("RarityColor") :: Color3? or stroke.Color)
		stroke.Thickness = if picked then 5 else 3
	end
	local veil = button:FindFirstChild("SaleVeil") :: Frame?
	if (picked or blocked) and not veil then
		local v = UIKit.new("Frame", {
			Name = "SaleVeil",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Theme.Colors.Danger,
			BackgroundTransparency = 0.82,
			ZIndex = 6,
			Active = false,
		}, button)
		UIKit.corner(v, Theme.CornerRadiusSmall)
		local check = UIKit.text(v, { name = "Check", text = "✓", size = UDim2.fromOffset(28, 28), position = UDim2.new(1, -4, 0, 4), anchor = Vector2.new(1, 0), z = 7, stroke = 2 })
		local badge = UIKit.new("Frame", { Name = "CheckBadge", Size = UDim2.fromOffset(30, 30), Position = UDim2.new(1, -3, 0, 3), AnchorPoint = Vector2.new(1, 0), BackgroundColor3 = Theme.Colors.Danger, ZIndex = 6 }, v)
		UIKit.corner(badge, 15)
		UIKit.text(v, { name = "Blocked", text = "🔒", size = UDim2.fromOffset(28, 28), position = UDim2.new(0.5, 0, 0.3, 0), anchor = Vector2.new(0.5, 0.5), z = 7, stroke = 0 })
		local _ = check
		veil = v
	end
	if veil then
		veil.Visible = picked or blocked
		veil.BackgroundColor3 = if blocked then Color3.new(0, 0, 0) else Theme.Colors.Danger
		veil.BackgroundTransparency = if blocked then 0.55 else 0.82
		for _, name in { "Check", "CheckBadge" } do
			local part = veil:FindFirstChild(name) :: GuiObject?
			if part then
				part.Visible = picked
			end
		end
		local lockIcon = veil:FindFirstChild("Blocked") :: GuiObject?
		if lockIcon then
			lockIcon.Visible = blocked
		end
	end
end

local function saleUids(): { string }
	local list = {}
	for uid in saleSelection do
		table.insert(list, uid)
	end
	table.sort(list)
	return list
end

local function updateFooter()
	if not footer then
		return
	end
	local count = #saleUids()
	local sellButton = footerParts.Sell :: TextButton
	if count == 0 then
		footerInfo.Text = Localization.t("bulk.mode") .. " · " .. Localization.t("bulk.selected", { count = 0 })
		UIKit.setButtonText(sellButton, Localization.t("bulk.sell_empty"))
		UIKit.setDisabled(sellButton, true)
		return
	end
	if salePending or not salePreview then
		footerInfo.Text = Localization.t("bulk.selected", { count = count }) .. " · " .. Localization.t("bulk.calculating")
		UIKit.setButtonText(sellButton, Localization.t("bulk.sell_empty"))
		UIKit.setDisabled(sellButton, true)
		return
	end
	local amount = NumberFormatter.money(salePreview.total)
	footerInfo.Text = Localization.t("bulk.selected", { count = count }) .. " · " .. Localization.t("bulk.receive", { amount = amount })
	UIKit.setButtonText(sellButton, Localization.t("bulk.sell", { count = salePreview.count, amount = amount }))
	UIKit.setDisabled(sellButton, salePreview.count == 0)
end

-- prévia AUTORITATIVA (debounce 0,25 s: tocar em vários cards gera 1 pedido)
local function schedulePreview()
	saleToken += 1
	local token = saleToken
	salePreview = nil
	salePending = next(saleSelection) ~= nil
	updateFooter()
	if not salePending then
		return
	end
	task.delay(0.25, function()
		if token ~= saleToken or not saleMode then
			return
		end
		local uids = saleUids()
		local result = Net.request("PreviewBulkSale", uids)
		if token ~= saleToken then
			return
		end
		salePending = false
		salePreview = if result.ok then result.data else nil
		if not result.ok then
			NotificationController.Show("error." .. tostring(result.code))
		end
		updateFooter()
	end)
end

local function applySaleVisuals()
	local data = DataController.GetAll()
	if not data or not grid then
		return
	end
	for uid in saleSelection do
		if not data.Inventory[uid] then
			saleSelection[uid] = nil
		end
	end
	for _, child in grid:GetChildren() do
		if child:IsA("GuiButton") then
			saleVisual(child, child.Name, data)
		end
	end
end

function InventoryController.ToggleSale(uid: string)
	local data = DataController.GetAll()
	if not data or not saleMode then
		return
	end
	local reason = clientProtection(data, uid) or (if table.find(data.TowerTeam or {}, uid) then "tower_team" else nil)
	if reason then
		NotificationController.Show(BLOCK_KEYS[reason] or "bulk.protected")
		return
	end
	if saleSelection[uid] then
		saleSelection[uid] = nil
	else
		saleSelection[uid] = true
	end
	local button = cardOf(uid)
	if button then
		saleVisual(button, uid, data)
	end
	schedulePreview()
end

function InventoryController.SelectDuplicates()
	local data = DataController.GetAll()
	if not data or not saleMode then
		return
	end
	local picked = BulkSaleCore.selectDuplicates(data, clientProtection)
	if #picked == 0 then
		NotificationController.Show("bulk.no_dupes")
		return
	end
	table.clear(saleSelection)
	for _, uid in picked do
		saleSelection[uid] = true
	end
	applySaleVisuals()
	schedulePreview()
end

function InventoryController.SaleMode(): boolean
	return saleMode
end

function InventoryController.SaleSelection(): { string }
	return saleUids()
end

function InventoryController.SetSaleMode(on: boolean)
	if saleMode == on then
		return
	end
	saleMode = on
	table.clear(saleSelection)
	salePreview = nil
	salePending = false
	saleToken += 1
	if on then
		InventoryController.Select(nil)
	end
	if footer then
		footer.Visible = on
		InventoryController.Layout()
	end
	applySaleVisuals()
	updateFooter()
end

local function sellSelected()
	local preview = salePreview
	if not saleMode or salePending or not preview or preview.count == 0 then
		return
	end
	local uids = saleUids()
	local amount = NumberFormatter.money(preview.total)
	UIKit.confirm(Localization.t("bulk.confirm", { count = preview.count, amount = amount }), Localization.t("bulk.confirm_yes"), Localization.t("bulk.cancel"), function()
		saleRequests += 1
		local requestId = string.format("bulk-%d-%d", math.floor(os.clock() * 1000) % 1000000000, saleRequests)
		local result = Net.request("SellBulk", uids, preview.total, requestId)
		if not result.ok then
			NotificationController.Show("error." .. tostring(result.code))
			if result.code == "price_changed" then
				schedulePreview()
			end
			return
		end
		UIKit.sound("Coin")
		NotificationController.Show("bulk.done", { count = result.data.count, amount = NumberFormatter.money(result.data.total) })
		if #(result.data.skipped or {}) > 0 then
			NotificationController.Show("bulk.done_skipped", { count = #result.data.skipped })
		end
		table.clear(saleSelection)
		salePreview = nil
		applySaleVisuals()
		updateFooter()
	end)
end

function InventoryController.Refresh()
	local data = DataController.GetAll()
	if not data or not window.isOpen then
		dirty = true
		return
	end
	dirty = false
	table.clear(duplicates)
	for _, it in data.Inventory do
		duplicates[it.Id] = (duplicates[it.Id] or 0) + 1
	end
	-- 1) cards de unidades que saíram do inventário (vendidas/fundidas/trocadas)
	for uid, button in cards do
		if not data.Inventory[uid] then
			local portraitArea = button:FindFirstChild("Portrait")
			if portraitArea and portraitArea:IsA("GuiObject") then
				CharacterPreview.detach(portraitArea)
			end
			button:Destroy()
			cards[uid] = nil
		end
	end
	-- 2) ordem/filtro: só LayoutOrder e Visible mudam; card novo só para uid novo
	local shown: { [string]: boolean } = {}
	for i, uid in sortedUids(data) do
		shown[uid] = true
		local button = cards[uid]
		if button then
			button.LayoutOrder = i
			button.Visible = true
			updateCard(button, data, uid)
		else
			button = card(data, uid, i)
		end
		setSelectedVisual(button, uid == selected)
	end
	for uid, button in cards do
		if not shown[uid] then
			button.Visible = false
		end
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
	if headerParts.FilterCycle then
		UIKit.setButtonText(headerParts.FilterCycle :: TextButton, Localization.t("inv.filter_cycle", { name = Localization.t("inv.filter." .. filter) }))
	end
	refreshDetail()
	if saleMode then
		applySaleVisuals()
		updateFooter()
	end
	CharacterPreview.update()
end

-- Fechar a MOCHILA: solta os retratos, esvazia o pool e descarta os cards (reabrir monta de novo)
local function disposeCards()
	CharacterPreview.releaseScope(grid)
	CharacterPreview.trimPool()
	for uid, button in cards do
		button:Destroy()
		cards[uid] = nil
	end
end

local function request(name: string, ...: any)
	local result = Net.request(name, ...)
	if not result.ok then
		NotificationController.Show("error." .. tostring(result.code))
	end
	return result
end

local function place(gui: GuiObject?, r: ResponsiveLayout.Rect?)
	if not gui then
		return
	end
	gui.Visible = r ~= nil
	if r then
		gui.Position = UDim2.fromOffset(r.x, r.y)
		gui.Size = UDim2.fromOffset(r.w, r.h)
		gui.AnchorPoint = Vector2.zero
	end
end

-- Reorganiza cabeçalho, grade, detalhes e rodapé para a largura atual (sem UIScale)
function InventoryController.Layout()
	if not header then
		return
	end
	local w, h = layoutSize.X, layoutSize.Y
	local hd = ResponsiveLayout.backpackHeader(w)
	header.Size = UDim2.fromOffset(w, hd.height)
	header:SetAttribute("LayoutMode", hd.mode)
	place(headerParts.Title, hd.title)
	place(headerParts.Capacity, hd.capacity)
	place(headerParts.Search, hd.search)
	place(headerParts.EquipBest, hd.equipBest)
	place(headerParts.Trash, hd.trash)
	for i, id in FILTERS do
		place(filterButtons[id], hd.filters[i])
	end
	place(headerParts.FilterCycle, hd.filterCycle)
	UIKit.setButtonText(headerParts.EquipBest :: TextButton, if hd.equipBestIconOnly then "⚡" else "⚡ " .. Localization.t("inv.equip_best"))
	UIKit.setButtonText(headerParts.FilterCycle :: TextButton, Localization.t("inv.filter_cycle", { name = Localization.t("inv.filter." .. filter) }))
	local ft = ResponsiveLayout.backpackFooter(w)
	footer.Position = UDim2.fromOffset(0, h - ft.height)
	footer.Size = UDim2.fromOffset(w, ft.height)
	footer:SetAttribute("LayoutMode", ft.mode)
	place(footerParts.Info, ft.info)
	place(footerParts.Dupes, ft.dupes)
	place(footerParts.Cancel, ft.cancel)
	place(footerParts.Sell, ft.sell)
	footer.Visible = saleMode
	local body = ResponsiveLayout.backpackBody(w, h, hd.height, if saleMode then ft.height else nil)
	grid.Position = UDim2.fromOffset(body.grid.x, body.grid.y)
	grid.Size = UDim2.fromOffset(body.grid.w, body.grid.h)
	detail.Position = UDim2.fromOffset(body.detail.x, body.detail.y)
	detail.Size = UDim2.fromOffset(body.detail.w, body.detail.h)
	detail.AnchorPoint = Vector2.zero
	detailClose.Visible = body.detailOverlay
end

-- (testes/DEV) força uma área interna para conferir os modos wide/compact/portrait
function InventoryController._layoutFor(w: number, h: number)
	layoutSize = Vector2.new(w, h)
	InventoryController.Layout()
end

local function build()
	window = UIKit.window({ name = "Inventory", title = Localization.t("inv.title"), icon = "🎒", size = Theme.PopupSizes.Large, header = Color3.fromRGB(100, 110, 255) })
	local content = window.content
	UIKit.padding(content, 10)

	-- CABEÇALHO (3 áreas, posições pelo ResponsiveLayout.backpackHeader em Layout())
	header = UIKit.new("Frame", { Name = "Header", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 44) }, content)
	headerParts.Title = UIKit.text(header, { name = "Title", text = Localization.t("inv.title"), align = Enum.TextXAlignment.Left, color = Theme.Colors.TextMuted })
	capacityLabel = UIKit.text(header, { name = "Capacity", text = "0 / 100" })
	headerParts.Capacity = capacityLabel
	for i, id in FILTERS do
		filterButtons[id] = UIKit.button(header, {
			name = "Filter_" .. id,
			text = Localization.t("inv.filter." .. id),
			size = UDim2.fromOffset(92, 44),
			order = i,
			onClick = function()
				filter = id
				InventoryController.Refresh()
			end,
		})
	end
	-- retrato: um botão só que cicla os filtros (cabe com a busca na 2ª linha)
	headerParts.FilterCycle = UIKit.button(header, {
		name = "FilterCycle",
		text = "",
		color = Theme.Colors.Primary,
		onClick = function()
			local index = table.find(FILTERS, filter) or 1
			filter = FILTERS[index % #FILTERS + 1]
			InventoryController.Refresh()
		end,
	})
	searchBox = UIKit.new("TextBox", {
		Name = "Search",
		BackgroundColor3 = Theme.Colors.Card,
		PlaceholderText = Localization.t("inv.search"),
		Text = "",
		Font = Theme.Font,
		TextScaled = true,
		TextColor3 = Theme.Colors.Text,
		ClearTextOnFocus = false,
	}, header)
	UIKit.corner(searchBox, 8)
	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		search = string.sub(searchBox.Text, 1, 30)
		InventoryController.Refresh()
	end)
	headerParts.Search = searchBox
	-- EQUIPAR MELHORES (sem precisar selecionar) e a LIXEIRA (modo venda), separados
	headerParts.EquipBest = UIKit.button(header, {
		name = "EquipBestTop",
		text = "⚡ " .. Localization.t("inv.equip_best"),
		color = Theme.Colors.Purple,
		onClick = function()
			local result = request("EquipBest")
			if result.ok then
				NotificationController.Show("inv.best_done", { count = result.data })
			end
		end,
	})
	headerParts.Trash = UIKit.button(header, {
		name = "SellMode",
		text = "🗑",
		color = Theme.Colors.Danger,
		onClick = function()
			InventoryController.SetSaleMode(not saleMode)
		end,
	})

	-- Grade
	grid = UIKit.new("ScrollingFrame", {
		Name = "Grid",
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

	-- RODAPÉ do MODO VENDA (escondido fora do modo)
	footer = UIKit.new("Frame", { Name = "SaleFooter", BackgroundColor3 = Theme.Colors.Card, Visible = false, ZIndex = 5 }, content)
	UIKit.corner(footer, Theme.CornerRadiusSmall)
	UIKit.stroke(footer, 3, Theme.Colors.Danger, true)
	footerInfo = UIKit.text(footer, { name = "Info", text = "", align = Enum.TextXAlignment.Left, z = 6 })
	footerParts.Info = footerInfo
	footerParts.Dupes = UIKit.button(footer, { name = "SelectDuplicates", text = Localization.t("bulk.select_dupes"), color = Theme.Colors.Purple, onClick = function()
		InventoryController.SelectDuplicates()
	end })
	footerParts.Cancel = UIKit.button(footer, { name = "CancelSale", text = Localization.t("bulk.cancel"), color = Color3.fromRGB(90, 90, 120), onClick = function()
		InventoryController.SetSaleMode(false)
	end })
	footerParts.Sell = UIKit.button(footer, { name = "SellSelected", text = Localization.t("bulk.sell_empty"), color = Theme.Colors.Danger, onClick = sellSelected })

	-- Detalhes
	detail = UIKit.new("Frame", {
		Name = "Detail",
		ZIndex = 4,
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
					InventoryController.Select(nil)
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
	-- tela estreita: os detalhes sobrepõem a grade e ganham um ✕
	detailClose = UIKit.button(detail, { name = "DetailClose", text = "✕", color = Color3.fromRGB(90, 90, 120), size = UDim2.fromOffset(44, 44), position = UDim2.new(1, -6, 0, 6), anchor = Vector2.new(1, 0), onClick = function()
		InventoryController.Select(nil)
	end })
	detailClose.Visible = false
	UIKit.fitWindow(window, Vector2.new(1180, 640), function(w, h)
		layoutSize = Vector2.new(w - 20, h - 20) -- área interna (padding 10)
		InventoryController.Layout()
	end)
	-- fechar a MOCHILA: solta todos os retratos e esvazia o pool (nenhum modelo fica vivo)
	window.Closed:Connect(function()
		InventoryController.SetSaleMode(false)
		disposeCards()
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
