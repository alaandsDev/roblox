--!strict
--[[
	TowerController (Fase 7): janela TORRES + tela de batalha.
	    Janela: cada torre com "ANDAR x/y", poder do próximo andar, poder do time, LUTAR.
	    Time: até 5 (escolhidos na MOCHILA com "TIME DA TORRE"); vazio = os mais fortes.
	    Batalha: o servidor já simulou; aqui só ANIMAMOS o registro (ataques, críticos, nocautes),
	    com PULAR, e mostramos VITÓRIA/DERROTA + recompensas.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage.Shared
local TowerConfig = require(Shared.Config.TowerConfig)
local CharacterConfig = require(Shared.Config.CharacterConfig)
local RarityConfig = require(Shared.Config.RarityConfig)
local BattleCore = require(Shared.Modules.BattleCore)
local Formulas = require(Shared.Modules.GameFormulas)
local NumberFormatter = require(Shared.Modules.NumberFormatter)
local Localization = require(Shared.Localization.Localization)
local Net = require(Shared.Modules.Net)

local UI = script.Parent.Parent.UI
local UIKit = require(UI.UIKit)
local CharacterPreview = require(UI.CharacterPreview)
local ResponsiveLayout = require(UI.ResponsiveLayout)
local Theme = require(UI.UITheme)
local DataController = require(script.Parent.DataController)
local NotificationController = require(script.Parent.NotificationController)

local TowerController = {}

local core = BattleCore.new(TowerConfig, CharacterConfig, RarityConfig)

local window: UIKit.Window
local list: Frame
local teamRow: Frame
local teamLabel: TextLabel
local towerTop: Frame
local autoButton: TextButton
local autoTeamButton: TextButton
local towerSize = Vector2.new(736, 438)
local fighting = false
local battleGui: ScreenGui

local function rgb(c: { number }): Color3
	return Color3.fromRGB(c[1], c[2], c[3])
end

local function highest(data: any, towerId: string): number
	local value = data.TowerProgress and data.TowerProgress[towerId]
	return if type(value) == "number" then value else 0
end

local function unlocked(data: any, tower: any): boolean
	local previous = tower.Unlock.Tower
	return previous == nil or highest(data, previous) >= TowerConfig.ById[previous].Floors
end

-- Mesmo critério do servidor (só para MOSTRAR)
function TowerController.Team(data: any): { string }
	local team = {}
	for _, uid in data.TowerTeam or {} do
		if data.Inventory[uid] and #team < TowerConfig.TeamSize and not table.find(team, uid) then
			table.insert(team, uid)
		end
	end
	if #team > 0 then
		return team
	end
	local all = {}
	for uid in data.Inventory do
		table.insert(all, uid)
	end
	table.sort(all, function(a, b)
		local pa, pb = Formulas:unitPower(data.Inventory[a], data), Formulas:unitPower(data.Inventory[b], data)
		if pa ~= pb then
			return pa > pb
		end
		return a < b
	end)
	for i = 1, math.min(TowerConfig.TeamSize, #all) do
		table.insert(team, all[i])
	end
	return team
end

------------------------------------------------------------------------------------
-- Batalha

local function cardFrame(parent: Instance, info: any, order: number): (Frame, Frame)
	local character = CharacterConfig.ById[info.id]
	local color = UIKit.rarityColor(character and character.Rarity or "Common")
	local frame = UIKit.new("Frame", { Name = "Card" .. order, Size = UDim2.fromOffset(150, 190), BackgroundColor3 = Theme.Colors.Card, LayoutOrder = order }, parent)
	UIKit.corner(frame, Theme.CornerRadiusSmall)
	UIKit.stroke(frame, 3, color, true)
	UIKit.gradient(frame, UIKit.darken(color, 0.4), Theme.Colors.Card, 90)
	UIKit.text(frame, { name = "Icon", text = character and character.VisualTheme.Icon or "?", size = UDim2.fromScale(0.7, 0.42), position = UDim2.fromScale(0.5, 0.06), anchor = Vector2.new(0.5, 0), stroke = 0 })
	UIKit.text(frame, { text = character and character.Name or "?", size = UDim2.new(0.94, 0, 0, 24), position = UDim2.new(0.5, 0, 0.5, 0), anchor = Vector2.new(0.5, 0) })
	UIKit.text(frame, { text = "⚔️ " .. NumberFormatter.abbreviate(info.atk), size = UDim2.new(0.9, 0, 0, 20), position = UDim2.new(0.5, 0, 0.66, 0), anchor = Vector2.new(0.5, 0), color = Theme.Colors.Warning })
	local bar = UIKit.new("Frame", { Size = UDim2.new(0.86, 0, 0, 14), Position = UDim2.new(0.07, 0, 0.84, 0), BackgroundColor3 = Color3.fromRGB(40, 20, 25) }, frame)
	UIKit.corner(bar, 6)
	local fill = UIKit.new("Frame", { Name = "Fill", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Colors.Success }, bar)
	UIKit.corner(fill, 6)
	return frame, fill
end

local function floatText(parent: Frame, text: string, color: Color3)
	local label = UIKit.text(parent, { text = text, size = UDim2.new(1, 0, 0, 34), position = UDim2.fromScale(0.5, 0.25), anchor = Vector2.new(0.5, 0.5), color = color, stroke = 3, z = 5 })
	TweenService:Create(label, TweenInfo.new(0.6), { Position = UDim2.fromScale(0.5, -0.05), TextTransparency = 1 }):Play()
	task.delay(0.6, label.Destroy, label)
end

--[[
	Sessão contínua (servidor = TowerService/TowerSessionCore). O cliente só:
	    pede START / PRÓXIMO / AUTO / PARAR e anima cada estágio que chega (TowerStage).
	OCULTAR: esconde a tela de batalha e mostra o painel compacto. NÃO muda nada no servidor
	(mesmos estágios, mesmo intervalo, mesma recompensa) — só não anima.
]]
local session: any = nil -- último resumo recebido
local hidden = false
local autoWanted = true
local animToken = 0
local compact: Frame? = nil

local END_KEYS = {
	defeat = "tower.end_defeat",
	stopped = "tower.end_stopped",
	tower_complete = "tower.end_tower_complete",
	session_limit = "tower.end_session_limit",
	disconnect = "tower.end_disconnect",
	died = "tower.end_died",
	invalid = "tower.end_invalid",
}
local function endReasonText(reason: string?): string
	return Localization.t(END_KEYS[reason or "stopped"] or "tower.end_ended")
end

local function updateCompact()
	if not compact then
		return
	end
	local active = session ~= nil and session.status ~= "ended"
	compact.Visible = hidden and session ~= nil
	if not compact.Visible then
		return
	end
	local title = compact:FindFirstChild("Title") :: TextLabel
	local info = compact:FindFirstChild("Info") :: TextLabel
	title.Text = if active then Localization.t("tower.running") else endReasonText(session.endReason)
	info.Text = Localization.t("tower.compact_info", {
		floor = session.floor,
		hp = math.floor((session.teamHp or 0) * 100 + 0.5),
		money = NumberFormatter.money(session.money or 0),
		gems = session.gems or 0,
	})
	local stop = compact:FindFirstChild("CompactStop")
	if stop then
		UIKit.setButtonText(stop, Localization.t(if active then "tower.stop" else "tower.close"))
	end
end

local function closeBattle()
	animToken += 1
	battleGui.Enabled = false
	for _, child in battleGui:GetChildren() do
		child:Destroy()
	end
end

local function stopSession()
	if session and session.status ~= "ended" then
		Net.request("StopTowerSession")
	end
end

local function setHidden(value: boolean)
	hidden = value
	if hidden then
		closeBattle()
	end
	updateCompact()
end

-- Barra de controles da tela de batalha (AUTO, OCULTAR, PRÓXIMO, PARAR/FECHAR)
local function controls(root: Frame, payload: any)
	local bar = UIKit.new("Frame", { Name = "Controls", BackgroundTransparency = 1, Size = UDim2.fromOffset(900, 64), Position = UDim2.new(0.5, 0, 1, -16), AnchorPoint = Vector2.new(0.5, 1), ZIndex = 9 }, root)
	UIKit.list(bar, true, 12, "center")
	local sum = payload.session or session or {}
	local active = sum.status ~= "ended"
	if active then
		UIKit.button(bar, {
			name = "AutoToggle",
			text = Localization.t(if sum.auto then "tower.auto_on" else "tower.auto_off"),
			color = if sum.auto then Theme.Colors.Success else Color3.fromRGB(70, 70, 92),
			size = UDim2.fromOffset(170, 56),
			order = 1,
			onClick = function()
				autoWanted = not sum.auto
				Net.request("SetTowerAuto", autoWanted)
			end,
		})
		if sum.status == "paused" then
			UIKit.button(bar, {
				name = "NextFloor",
				text = Localization.t("tower.next"),
				color = Theme.Colors.Primary,
				size = UDim2.fromOffset(170, 56),
				order = 2,
				onClick = function()
					local result = Net.request("TowerNext")
					if not result.ok then
						NotificationController.Show("error." .. tostring(result.code))
					end
				end,
			})
		end
		UIKit.button(bar, {
			name = "HideBattle",
			text = Localization.t("tower.hide"),
			color = Color3.fromRGB(70, 70, 92),
			size = UDim2.fromOffset(170, 56),
			order = 3,
			onClick = function()
				setHidden(true)
			end,
		})
	end
	UIKit.button(bar, {
		name = "CloseBattle",
		text = Localization.t(if active then "tower.stop" else "tower.close"),
		color = if active then Theme.Colors.Danger else Theme.Colors.Success,
		size = UDim2.fromOffset(170, 56),
		order = 4,
		onClick = function()
			stopSession()
			closeBattle()
			session = nil
			updateCompact()
			window:Open()
		end,
	})
end

-- Anima UM estágio (o servidor já resolveu tudo). Um estágio novo interrompe a animação anterior.
function TowerController.PlayBattle(result: any)
	animToken += 1
	local token = animToken
	for _, child in battleGui:GetChildren() do
		child:Destroy()
	end
	battleGui.Enabled = true
	UIKit.new("Frame", { BackgroundColor3 = Color3.fromRGB(10, 8, 20), BackgroundTransparency = 0.15, Size = UDim2.fromScale(1, 1) }, battleGui)
	local root = UIKit.scaledRoot(battleGui)
	local tower = TowerConfig.ById[result.tower]
	UIKit.text(root, {
		text = Localization.t("tower.battle_title", { tower = Localization.t("tower." .. result.tower), floor = result.floor }),
		size = UDim2.fromOffset(800, 50),
		position = UDim2.new(0.5, 0, 0, 20),
		anchor = Vector2.new(0.5, 0),
		color = rgb(tower.Theme),
	})
	if result.session then
		UIKit.text(root, {
			name = "SessionInfo",
			text = Localization.t("tower.session_info", { money = NumberFormatter.money(result.session.money or 0), gems = result.session.gems or 0, floors = result.session.floors or 0 }),
			size = UDim2.fromOffset(800, 30),
			position = UDim2.new(0.5, 0, 0, 70),
			anchor = Vector2.new(0.5, 0),
			color = Theme.Colors.Money,
		})
	end
	local function row(y: number): Frame
		local frame = UIKit.new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(820, 200), Position = UDim2.new(0.5, 0, y, 0), AnchorPoint = Vector2.new(0.5, 0.5) }, root)
		UIKit.list(frame, true, 12, "center")
		return frame
	end
	local enemyRow, teamRowFrame = row(0.3), row(0.64)
	local sides = { enemy = {}, team = {} }
	for i, info in result.enemies do
		local frame, fill = cardFrame(enemyRow, info, i)
		sides.enemy[i] = { frame = frame, fill = fill, hp = info.maxHp, maxHp = info.maxHp }
	end
	for i, info in result.team do
		local frame, fill = cardFrame(teamRowFrame, info, i)
		sides.team[i] = { frame = frame, fill = fill, hp = info.maxHp, maxHp = info.maxHp }
	end
	UIKit.text(root, { text = "VS", size = UDim2.fromOffset(120, 50), position = UDim2.fromScale(0.5, 0.47), anchor = Vector2.new(0.5, 0.5), color = Theme.Colors.Danger })

	local skipping = false
	local skip = UIKit.button(root, {
		name = "SkipBattle",
		text = Localization.t("reveal.skip"),
		color = Color3.fromRGB(70, 70, 90),
		size = UDim2.fromOffset(150, 48),
		position = UDim2.new(1, -20, 0, 20),
		anchor = Vector2.new(1, 0),
		onClick = function()
			skipping = true
		end,
	})
	-- no AUTO a animação cabe no intervalo entre estágios (mais rápida)
	local step = if result.session and result.session.auto then 0.12 else 0.22

	for _, action in result.log do
		if token ~= animToken then
			return
		end
		local attackerSide = sides[action.side]
		local defenderSide = sides[if action.side == "team" then "enemy" else "team"]
		local attacker = attackerSide[action.slot]
		local defender = defenderSide[action.target]
		if attacker and defender then
			defender.hp = math.max(0, defender.hp - action.damage)
			defender.fill.Size = UDim2.fromScale(defender.hp / defender.maxHp, 1)
			if not skipping then
				local s = attacker.frame:FindFirstChildOfClass("UIScale") or UIKit.new("UIScale", {}, attacker.frame)
				s.Scale = 1.12
				TweenService:Create(s, TweenInfo.new(0.15), { Scale = 1 }):Play()
				floatText(defender.frame, (if action.crit then "💥 " else "-") .. NumberFormatter.abbreviate(action.damage), if action.crit then Theme.Colors.Warning else Theme.Colors.Danger)
				UIKit.sound(if action.crit then "Impact" else "Click", if action.crit then 0.5 else 0.15)
				task.wait(step)
			end
			if action.ko then
				defender.frame.BackgroundTransparency = 0.6
				defender.fill.Size = UDim2.fromScale(0, 1)
			end
		end
	end
	if token ~= animToken then
		return
	end
	skip.Visible = false

	local banner = UIKit.text(root, {
		name = "Outcome",
		text = Localization.t(if result.won then "tower.victory" else "tower.defeat"),
		size = UDim2.fromOffset(700, 90),
		position = UDim2.fromScale(0.5, 0.47),
		anchor = Vector2.new(0.5, 0.5),
		color = if result.won then Theme.Colors.Success else Theme.Colors.Danger,
		stroke = 5,
		z = 8,
	})
	local s = UIKit.new("UIScale", { Scale = 1.6 }, banner)
	TweenService:Create(s, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	UIKit.sound(if result.won then "Reward" else "Error")
	if result.won then
		local parts = { "+" .. NumberFormatter.money(result.rewards.money) }
		if result.rewards.gems > 0 then
			table.insert(parts, "💎 +" .. result.rewards.gems)
		end
		if result.rewards.completed then
			table.insert(parts, Localization.t("tower.completed"))
		end
		UIKit.text(root, { name = "Rewards", text = table.concat(parts, "   "), size = UDim2.fromOffset(700, 44), position = UDim2.fromScale(0.5, 0.79), anchor = Vector2.new(0.5, 0.5), color = Theme.Colors.Money, z = 8 })
	end
	controls(root, result)
end

-- Estágio resolvido pelo servidor
local function onStage(payload: any)
	session = payload.session
	if hidden then
		updateCompact()
	else
		task.spawn(TowerController.PlayBattle, payload)
	end
end

local function onSessionUpdate(summary: any)
	session = summary
	updateCompact()
	if not hidden and summary.status == "ended" and battleGui.Enabled then
		-- redesenha só a barra (fim: FECHAR)
		local root = battleGui:FindFirstChild("Root", true)
		local bar = root and root:FindFirstChild("Controls")
		if bar and root then
			bar:Destroy()
			controls(root :: Frame, { session = summary })
		end
	end
end

local function buildCompact()
	local gui = UIKit.screen("TowerCompact", 60)
	local root = UIKit.scaledRoot(gui)
	local panel = UIKit.new("Frame", { Name = "TowerCompactPanel", Size = UDim2.fromOffset(320, 150), Position = UDim2.new(1, -16, 0.42, 0), AnchorPoint = Vector2.new(1, 0.5), BackgroundColor3 = Theme.Colors.Card, Visible = false }, root)
	UIKit.corner(panel, Theme.CornerRadiusSmall)
	UIKit.stroke(panel, 3, Color3.fromRGB(150, 90, 255), true)
	UIKit.text(panel, { name = "Title", text = "", size = UDim2.new(1, -16, 0, 28), position = UDim2.fromOffset(8, 6), color = Color3.fromRGB(200, 160, 255) })
	UIKit.text(panel, { name = "Info", text = "", size = UDim2.new(1, -16, 0, 56), position = UDim2.fromOffset(8, 36), color = Theme.Colors.Text })
	UIKit.button(panel, {
		name = "CompactShow",
		text = Localization.t("tower.show"),
		color = Theme.Colors.Primary,
		size = UDim2.fromOffset(140, 44),
		position = UDim2.new(0, 10, 1, -8),
		anchor = Vector2.new(0, 1),
		onClick = function()
			hidden = false
			updateCompact()
			if session then
				closeBattle()
				battleGui.Enabled = true
				local root2 = UIKit.scaledRoot(battleGui)
				UIKit.text(root2, { name = "Waiting", text = Localization.t("tower.waiting_stage"), size = UDim2.fromOffset(700, 60), position = UDim2.fromScale(0.5, 0.45), anchor = Vector2.new(0.5, 0.5) })
				controls(root2, { session = session })
			end
		end,
	})
	UIKit.button(panel, {
		name = "CompactStop",
		text = Localization.t("tower.stop"),
		color = Theme.Colors.Danger,
		size = UDim2.fromOffset(140, 44),
		position = UDim2.new(1, -10, 1, -8),
		anchor = Vector2.new(1, 1),
		onClick = function()
			if session and session.status ~= "ended" then
				stopSession()
			else
				session = nil
				hidden = false
				updateCompact()
			end
		end,
	})
	compact = panel
end

------------------------------------------------------------------------------------
-- Janela

function TowerController.Refresh()
	local data = DataController.GetAll()
	if not data or not window.isOpen then
		return
	end
	for _, child in list:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	CharacterPreview.releaseScope(teamRow)
	for _, child in teamRow:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	local team = TowerController.Team(data)
	local teamPower = 0
	for i, uid in team do
		local item = data.Inventory[uid]
		teamPower += Formulas:unitPower(item, data)
		local character = CharacterConfig.ById[item.Id]
		local chip = UIKit.new("Frame", { Name = "TeamChip" .. i, Size = UDim2.fromOffset(44, 44), BackgroundColor3 = Theme.Colors.Card, LayoutOrder = i, ClipsDescendants = true }, teamRow)
		UIKit.corner(chip, 10)
		UIKit.stroke(chip, 3, UIKit.rarityColor(character.Rarity), true)
		-- retrato real (mesmo CharacterPreview da Mochila); ícone só se o asset falhar
		CharacterPreview.attach(chip, item.Id, item.Variant, "head", character.VisualTheme.Icon)
		local power = Formulas:unitPower(item, data)
		UIKit.tooltip(chip, character.Name .. " · ⚔️ " .. NumberFormatter.abbreviate(power), function()
			return { autoButton, autoTeamButton }
		end)
	end
	teamLabel.Text = Localization.t(if #(data.TowerTeam or {}) > 0 then "tower.team_custom" else "tower.team_auto", { power = NumberFormatter.abbreviate(teamPower) })
	TowerController.Layout()
	CharacterPreview.update()
	for _, tower in TowerConfig.List do
		local high = highest(data, tower.Id)
		local isUnlocked = unlocked(data, tower)
		local done = high >= tower.Floors
		local row = UIKit.new("Frame", { BackgroundColor3 = Theme.Colors.Card, Size = UDim2.new(1, 0, 0, 92), LayoutOrder = tower.Order }, list)
		UIKit.corner(row, Theme.CornerRadiusSmall)
		UIKit.stroke(row, 3, rgb(tower.Theme), true)
		UIKit.text(row, { text = Localization.t("tower." .. tower.Id), size = UDim2.new(0.4, 0, 0, 34), position = UDim2.fromOffset(16, 8), align = Enum.TextXAlignment.Left, color = rgb(tower.Theme) })
		UIKit.text(row, { text = Localization.t("tower.floor", { floor = high, max = tower.Floors }), size = UDim2.new(0.4, 0, 0, 26), position = UDim2.fromOffset(16, 50), align = Enum.TextXAlignment.Left })
		local enemyText = if done then Localization.t("tower.completed") else Localization.t("tower.enemy_power", { power = NumberFormatter.abbreviate(core:enemyPower(tower, high + 1) * (if core:isBoss(high + 1) then TowerConfig.BossMultiplier else 1)) })
		UIKit.text(row, { text = enemyText .. (if not done and core:isBoss(high + 1) then "  👑" else ""), size = UDim2.new(0.3, 0, 0, 26), position = UDim2.new(0.42, 0, 0.5, 0), anchor = Vector2.new(0, 0.5), color = Theme.Colors.TextMuted })
		local text, color
		if not isUnlocked then
			text, color = "🔒 " .. Localization.t("tower.locked"), Theme.Colors.Locked
		elseif done then
			text, color = "✔ " .. Localization.t("tower.done"), Theme.Colors.Warning
		else
			text, color = "▶ " .. Localization.t("tower.start"), Theme.Colors.Danger
		end
		UIKit.button(row, {
			name = "Fight_" .. tower.Id,
			text = text,
			color = color,
			size = UDim2.fromOffset(170, 56),
			position = UDim2.new(1, -12, 0.5, 0),
			anchor = Vector2.new(1, 0.5),
			onClick = function()
				if not isUnlocked or done or fighting then
					return
				end
				fighting = true
				-- sessão contínua: o servidor luta o andar 1 agora e manda o estágio (TowerStage)
				hidden = false
				local result = Net.request("StartTowerSession", tower.Id, autoWanted)
				if result.ok then
					window:Close()
				else
					NotificationController.Show("error." .. tostring(result.code))
				end
				fighting = false
			end,
		})
	end
end

-- Cabeçalho em 2 linhas pela largura atual: AUTO e TIME AUTO nunca se sobrepõem
local function place(g: GuiObject, r: ResponsiveLayout.Rect)
	g.AnchorPoint = Vector2.zero
	g.Position = UDim2.fromOffset(r.x, r.y)
	g.Size = UDim2.fromOffset(r.w, r.h)
end

function TowerController.Layout()
	if not towerTop or not autoButton then
		return
	end
	local chips = {}
	for _, child in teamRow:GetChildren() do
		if child:IsA("Frame") then
			table.insert(chips, child)
		end
	end
	table.sort(chips, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
	local th = ResponsiveLayout.towerHeader(towerSize.X, #chips)
	towerTop.Size = UDim2.fromOffset(towerSize.X, th.height)
	towerTop:SetAttribute("LayoutMode", th.mode)
	place(teamLabel, th.label)
	place(autoButton, th.auto)
	place(autoTeamButton, th.autoTeam)
	-- chips posicionados à mão (sem UIListLayout competindo)
	local layout = teamRow:FindFirstChildOfClass("UIListLayout")
	if layout then
		layout:Destroy()
	end
	teamRow.Position = UDim2.fromOffset(0, 0)
	teamRow.Size = UDim2.fromOffset(towerSize.X, th.height)
	for i, chip in chips do
		place(chip, th.chips[i])
	end
	list.Position = UDim2.fromOffset(10, th.height + 16)
	list.Size = UDim2.new(1, -20, 1, -(th.height + 18))
end

function TowerController.Init()
	window = UIKit.window({ name = "Towers", title = Localization.t("tower.title"), icon = "🗼", size = Theme.PopupSizes.Medium, header = Color3.fromRGB(120, 70, 220) })
	local content = window.content
	-- CABEÇALHO em 2 linhas (ResponsiveLayout.towerHeader, posições em Layout()):
	--   "Time automático · ⚔ poder" ........ [AUTO: ON]
	--   [chip][chip][chip][chip][chip] ..... [TIME AUTO]
	local top = UIKit.new("Frame", { Name = "TowerHeader", BackgroundTransparency = 1, Size = UDim2.new(1, -20, 0, 94), Position = UDim2.fromOffset(10, 8) }, content)
	towerTop = top
	teamLabel = UIKit.text(top, { name = "TeamLabel", size = UDim2.new(0.42, 0, 0, 28), position = UDim2.fromOffset(0, 16), align = Enum.TextXAlignment.Left })
	teamRow = UIKit.new("Frame", { Name = "TeamRow", BackgroundTransparency = 1, Size = UDim2.new(0.38, 0, 1, 0), Position = UDim2.fromScale(0.42, 0) }, top)
	UIKit.list(teamRow, true, 6)
	autoTeamButton = UIKit.button(top, {
		name = "AutoTeam",
		text = Localization.t("tower.auto_team"),
		color = Theme.Colors.Purple,
		onClick = function()
			Net.request("SetTowerTeam", {})
		end,
	})
	UIKit.tooltip(autoTeamButton, Localization.t("tower.tip_auto_team"), function()
		return { autoButton }
	end)
	list = UIKit.new("ScrollingFrame", { Name = "TowerList", BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 6, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, -20, 1, -112), Position = UDim2.fromOffset(10, 110) }, content) :: any
	UIKit.list(list, false, 10)
	window.Opened:Connect(TowerController.Refresh)
	battleGui = UIKit.screen("Battle", 120)
	battleGui.IgnoreGuiInset = true
	battleGui.Enabled = false
	buildCompact()
	-- AUTO (preferência deste cliente; o servidor decide o resto)
	autoButton = UIKit.button(top, {
		name = "AutoPreference",
		text = Localization.t(if autoWanted then "tower.auto_on" else "tower.auto_off"),
		color = if autoWanted then Theme.Colors.Success else Color3.fromRGB(70, 70, 92),
		onClick = function()
			autoWanted = not autoWanted
			UIKit.setButtonText(autoButton, Localization.t(if autoWanted then "tower.auto_on" else "tower.auto_off"))
			UIKit.setButtonColor(autoButton, if autoWanted then Theme.Colors.Success else Color3.fromRGB(70, 70, 92))
		end,
	})
	UIKit.tooltip(autoButton, Localization.t("tower.tip_auto"), function()
		return { autoTeamButton }
	end)
	window.Closed:Connect(function()
		UIKit.hideTooltip()
		CharacterPreview.releaseScope(teamRow)
	end)
	UIKit.fitWindow(window, Vector2.new(980, 600), function(w, h)
		towerSize = Vector2.new(w - 20, h)
		TowerController.Layout()
	end)
end

-- (testes/DEV) força uma largura para conferir os modos do cabeçalho
function TowerController._layoutFor(w: number)
	towerSize = Vector2.new(w, towerSize.Y)
	TowerController.Layout()
end

function TowerController.Start()
	Net.on("TowerStage", onStage)
	Net.on("TowerSessionUpdate", onSessionUpdate)
	DataController.Changed:Connect(function(key)
		if key == "TowerProgress" or key == "TowerTeam" or key == "Inventory" then
			TowerController.Refresh()
		end
	end)
end

return TowerController
