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
local Theme = require(UI.UITheme)
local DataController = require(script.Parent.DataController)
local NotificationController = require(script.Parent.NotificationController)

local TowerController = {}

local core = BattleCore.new(TowerConfig, CharacterConfig, RarityConfig)

local window: UIKit.Window
local list: Frame
local teamRow: Frame
local teamLabel: TextLabel
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

function TowerController.PlayBattle(result: any)
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
	local function row(y: number): Frame
		local frame = UIKit.new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(820, 200), Position = UDim2.new(0.5, 0, y, 0), AnchorPoint = Vector2.new(0.5, 0.5) }, root)
		UIKit.list(frame, true, 12, "center")
		return frame
	end
	local enemyRow, teamRowFrame = row(0.3), row(0.66)
	local sides = { enemy = {}, team = {} }
	for i, info in result.enemies do
		local frame, fill = cardFrame(enemyRow, info, i)
		sides.enemy[i] = { frame = frame, fill = fill, hp = info.maxHp, maxHp = info.maxHp }
	end
	for i, info in result.team do
		local frame, fill = cardFrame(teamRowFrame, info, i)
		sides.team[i] = { frame = frame, fill = fill, hp = info.maxHp, maxHp = info.maxHp }
	end
	UIKit.text(root, { text = "VS", size = UDim2.fromOffset(120, 50), position = UDim2.fromScale(0.5, 0.48), anchor = Vector2.new(0.5, 0.5), color = Theme.Colors.Danger })

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

	for _, action in result.log do
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
				task.wait(0.22)
			end
			if action.ko then
				defender.frame.BackgroundTransparency = 0.6
				defender.fill.Size = UDim2.fromScale(0, 1)
			end
		end
	end
	skip.Visible = false

	local banner = UIKit.text(root, {
		name = "Outcome",
		text = Localization.t(if result.won then "tower.victory" else "tower.defeat"),
		size = UDim2.fromOffset(700, 90),
		position = UDim2.fromScale(0.5, 0.48),
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
		UIKit.text(root, { name = "Rewards", text = table.concat(parts, "   "), size = UDim2.fromOffset(700, 44), position = UDim2.fromScale(0.5, 0.88), anchor = Vector2.new(0.5, 0.5), color = Theme.Colors.Money, z = 8 })
	end
	UIKit.button(root, {
		name = "CloseBattle",
		text = Localization.t("reveal.continue"),
		color = Theme.Colors.Success,
		size = UDim2.fromOffset(220, 60),
		position = UDim2.new(0.5, 0, 1, -20),
		anchor = Vector2.new(0.5, 1),
		onClick = function()
			battleGui.Enabled = false
			for _, child in battleGui:GetChildren() do
				child:Destroy()
			end
			window:Open()
		end,
	})
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
		local chip = UIKit.new("Frame", { Size = UDim2.fromOffset(52, 52), BackgroundColor3 = Theme.Colors.Card, LayoutOrder = i }, teamRow)
		UIKit.corner(chip, 10)
		UIKit.stroke(chip, 3, UIKit.rarityColor(character.Rarity), true)
		UIKit.text(chip, { text = character.VisualTheme.Icon, size = UDim2.fromScale(0.8, 0.8), position = UDim2.fromScale(0.5, 0.5), anchor = Vector2.new(0.5, 0.5), stroke = 0 })
	end
	teamLabel.Text = Localization.t(if #(data.TowerTeam or {}) > 0 then "tower.team_custom" else "tower.team_auto", { power = NumberFormatter.abbreviate(teamPower) })
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
			text, color = "⚔️ " .. Localization.t("tower.fight"), Theme.Colors.Danger
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
				local result = Net.request("RequestEnterTower", tower.Id)
				if result.ok then
					window:Close()
					TowerController.PlayBattle(result.data)
				else
					NotificationController.Show("error." .. tostring(result.code))
				end
				fighting = false
			end,
		})
	end
end

function TowerController.Init()
	window = UIKit.window({ name = "Towers", title = Localization.t("tower.title"), icon = "🗼", size = Theme.PopupSizes.Medium, header = Color3.fromRGB(120, 70, 220) })
	local content = window.content
	local top = UIKit.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -20, 0, 60), Position = UDim2.fromOffset(10, 8) }, content)
	teamLabel = UIKit.text(top, { size = UDim2.new(0.42, 0, 0, 28), position = UDim2.fromOffset(0, 16), align = Enum.TextXAlignment.Left })
	teamRow = UIKit.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(0.38, 0, 1, 0), Position = UDim2.fromScale(0.42, 0) }, top)
	UIKit.list(teamRow, true, 6)
	UIKit.button(top, {
		text = Localization.t("tower.auto_team"),
		color = Theme.Colors.Purple,
		size = UDim2.fromOffset(150, 48),
		position = UDim2.new(1, 0, 0.5, 0),
		anchor = Vector2.new(1, 0.5),
		onClick = function()
			Net.request("SetTowerTeam", {})
		end,
	})
	list = UIKit.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -20, 1, -84), Position = UDim2.fromOffset(10, 76) }, content)
	UIKit.list(list, false, 10)
	window.Opened:Connect(TowerController.Refresh)
	battleGui = UIKit.screen("Battle", 120)
	battleGui.IgnoreGuiInset = true
	battleGui.Enabled = false
end

function TowerController.Start()
	DataController.Changed:Connect(function(key)
		if key == "TowerProgress" or key == "TowerTeam" or key == "Inventory" then
			TowerController.Refresh()
		end
	end)
end

return TowerController
