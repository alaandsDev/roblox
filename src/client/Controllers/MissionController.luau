--!strict
--[[
	MissionController (Fase 9): janela MISSÕES (quadro no Hub e botão da esquerda).
	Diárias (barra de progresso + RESGATAR) e conquistas por nível. Badge com quantas dá para
	resgatar. Progresso e regras ficam no servidor (data.Missions replicado).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local MissionConfig = require(Shared.Config.MissionConfig)
local CharacterConfig = require(Shared.Config.CharacterConfig)
local MissionCore = require(Shared.Modules.MissionCore)
local NumberFormatter = require(Shared.Modules.NumberFormatter)
local Localization = require(Shared.Localization.Localization)
local Net = require(Shared.Modules.Net)

local UI = script.Parent.Parent.UI
local UIKit = require(UI.UIKit)
local Theme = require(UI.UITheme)
local DataController = require(script.Parent.DataController)
local NotificationController = require(script.Parent.NotificationController)
local HudController = require(script.Parent.HudController)

local MissionController = {}

local window: UIKit.Window
local list: ScrollingFrame

local function rewardText(r: any): string
	return if r.Kind == "Gems" then "💎 " .. r.Amount else "💵 " .. NumberFormatter.money(r.Amount) .. "+"
end

local function claimable(data: any): number
	local n = 0
	local missions = data.Missions or {}
	for id, entry in missions.Daily or {} do
		local mission = MissionCore.byId(MissionConfig, id)
		if mission and not entry.Claimed and entry.Progress >= mission.Target then
			n += 1
		end
	end
	for _, achievement in MissionConfig.Achievements do
		if MissionCore.claimableTier(data, achievement, CharacterConfig.ById) then
			n += 1
		end
	end
	return n
end

local function row(order: number, title: string, progress: number, target: number, rewardLabel: string, state: string, onClaim: () -> ())
	local frame = UIKit.new("Frame", { BackgroundColor3 = Theme.Colors.Card, Size = UDim2.new(1, -8, 0, 74), LayoutOrder = order }, list)
	UIKit.corner(frame, Theme.CornerRadiusSmall)
	UIKit.text(frame, { text = title, size = UDim2.new(0.55, 0, 0, 28), position = UDim2.fromOffset(12, 6), align = Enum.TextXAlignment.Left })
	local bar = UIKit.new("Frame", { BackgroundColor3 = Color3.fromRGB(30, 30, 45), Size = UDim2.new(0.5, 0, 0, 16), Position = UDim2.fromOffset(12, 44) }, frame)
	UIKit.corner(bar, 8)
	local fill = UIKit.new("Frame", { BackgroundColor3 = Theme.Colors.Success, Size = UDim2.fromScale(math.clamp(progress / target, 0, 1), 1) }, bar)
	UIKit.corner(fill, 8)
	UIKit.text(frame, { text = string.format("%s / %s", NumberFormatter.abbreviate(math.min(progress, target)), NumberFormatter.abbreviate(target)), size = UDim2.new(0.18, 0, 0, 22), position = UDim2.new(0.53, 8, 0, 41), color = Theme.Colors.TextMuted })
	UIKit.text(frame, { text = rewardLabel, size = UDim2.new(0.2, 0, 0, 26), position = UDim2.new(0.62, 0, 0, 8), color = Theme.Colors.Warning })
	local color = if state == "ready" then Theme.Colors.Success elseif state == "done" then Theme.Colors.Locked else Color3.fromRGB(70, 70, 92)
	local text = if state == "ready" then Localization.t("daily.claim") elseif state == "done" then "✔" else Localization.t("mission.in_progress")
	UIKit.button(frame, { text = text, color = color, size = UDim2.fromOffset(150, 50), position = UDim2.new(1, -10, 0.5, 0), anchor = Vector2.new(1, 0.5), onClick = function()
		if state == "ready" then
			onClaim()
		end
	end })
end

local function claim(kind: string, id: string)
	local result = Net.request("ClaimMission", kind, id)
	if result.ok then
		UIKit.sound("Reward")
		local r = result.data
		NotificationController.Show("mission.claimed", { reward = if r.kind == "Gems" then "💎 " .. r.amount else NumberFormatter.money(r.amount) })
	else
		NotificationController.Show("error." .. tostring(result.code))
	end
end

function MissionController.Refresh()
	local data = DataController.GetAll()
	if not data then
		return
	end
	local n = claimable(data)
	HudController.SetBadge("Missions", if n > 0 then tostring(n) else nil)
	if not window.isOpen then
		return
	end
	for _, child in list:GetChildren() do
		if child:IsA("GuiObject") and not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end
	UIKit.text(list, { text = Localization.t("mission.daily_title"), size = UDim2.new(1, 0, 0, 30), order = 0, color = Theme.Colors.Warning })
	local order = 1
	local daily = (data.Missions and data.Missions.Daily) or {}
	local ids = {}
	for id in daily do
		table.insert(ids, id)
	end
	table.sort(ids)
	for _, id in ids do
		local entry = daily[id]
		local mission = MissionCore.byId(MissionConfig, id)
		if mission then
			local state = if entry.Claimed then "done" elseif entry.Progress >= mission.Target then "ready" else "progress"
			row(order, Localization.t("mission." .. id), entry.Progress, mission.Target, rewardText(mission.Reward), state, function()
				claim("Daily", id)
			end)
			order += 1
		end
	end
	UIKit.text(list, { text = Localization.t("mission.achievements_title"), size = UDim2.new(1, 0, 0, 30), order = 100, color = Theme.Colors.Warning })
	order = 101
	for _, achievement in MissionConfig.Achievements do
		local claimed = (data.Missions and data.Missions.Achievements and data.Missions.Achievements[achievement.Id]) or 0
		local tier = math.min(claimed + 1, #achievement.Tiers)
		local target = achievement.Tiers[tier]
		local done = claimed >= #achievement.Tiers
		local state = if done then "done" elseif MissionCore.claimableTier(data, achievement, CharacterConfig.ById) then "ready" else "progress"
		row(order, Localization.t("mission.ach." .. achievement.Id, { tier = tier, max = #achievement.Tiers }), MissionCore.stat(data, achievement.Stat, CharacterConfig.ById), target, rewardText({ Kind = achievement.Reward.Kind, Amount = achievement.Reward.Amount * tier }), state, function()
			claim("Achievement", achievement.Id)
		end)
		order += 1
	end
end

function MissionController.Init()
	window = UIKit.window({ name = "Missions", title = Localization.t("mission.title"), icon = "📜", size = Theme.PopupSizes.Large, header = Color3.fromRGB(230, 150, 40) })
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
	window.Opened:Connect(MissionController.Refresh)
end

function MissionController.Start()
	DataController.Wait()
	MissionController.Refresh()
	DataController.Changed:Connect(function(key)
		if key == "Missions" or key == "Rolls" or key == "Index" or key == "Rebirths" or key == "TowerProgress" then
			MissionController.Refresh()
		end
	end)
end

return MissionController
