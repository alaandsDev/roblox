--!strict
--[[
	DailyController: janela RECOMPENSAS DIÁRIAS (layout da referência):
	    [DIA 1][DIA 2][DIA 3] [        ]
	    [DIA 4][DIA 5][DIA 6] [ DIA 7  ]   <- Dia 7 maior (antecipação)
	Estados: RESGATADO (✓ verde), DISPONÍVEL (borda brilhando), BLOQUEADO (escuro).
	Botão 📅 DIÁRIO no topo direito com badge "1" quando há recompensa.
	Datas e regras ficam no SERVIDOR (GetDailyStatus / ClaimDaily).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local DailyConfig = require(Shared.Config.DailyConfig)
local NumberFormatter = require(Shared.Modules.NumberFormatter)
local Localization = require(Shared.Localization.Localization)
local Net = require(Shared.Modules.Net)

local UI = script.Parent.Parent.UI
local UIKit = require(UI.UIKit)
local Theme = require(UI.UITheme)
local DataController = require(script.Parent.DataController)
local NotificationController = require(script.Parent.NotificationController)
local HudController = require(script.Parent.HudController)

local DailyController = {}

local DAY_COLORS = {
	Color3.fromRGB(90, 200, 90),
	Color3.fromRGB(80, 160, 255),
	Color3.fromRGB(170, 90, 255),
	Color3.fromRGB(255, 200, 60),
	Color3.fromRGB(255, 80, 90),
	Color3.fromRGB(70, 110, 255),
	Color3.fromRGB(230, 90, 255),
}

local window: UIKit.Window
local cards: { { frame: TextButton, stroke: UIStroke, state: TextLabel, check: TextLabel } } = {}
local footer: TextLabel
local status: any = nil
local claiming = false

local function rewardText(reward: any): string
	if reward.Kind == "Money" then
		return NumberFormatter.money(reward.Amount) .. "+"
	elseif reward.Kind == "Gems" then
		return "x" .. reward.Amount
	elseif reward.Kind == "LuckBoost" then
		return string.format("%gx · %dmin", reward.Multiplier, reward.Duration // 60)
	elseif reward.Kind == "Dice" then
		return Localization.t("dice." .. reward.DiceId)
	end
	return ""
end

local function render()
	if not status then
		return
	end
	HudController.SetBadge("Daily", if status.canClaim then "1" else nil)
	-- Dias já resgatados neste ciclo
	local through = if status.canClaim then status.day - 1 else (status.claimedThrough or 0)
	for day, card in cards do
		local claimed = day <= through
		local available = status.canClaim and day == status.day
		local color = DAY_COLORS[day]
		if available then
			card.frame.BackgroundColor3 = UIKit.darken(color, 0.35)
			card.stroke.Color = Color3.fromRGB(255, 255, 255)
			card.stroke.Thickness = 5
			card.state.Text = Localization.t("daily.claim")
			card.check.Visible = false
		elseif claimed then
			card.frame.BackgroundColor3 = Color3.fromRGB(25, 30, 28)
			card.stroke.Color = UIKit.darken(color, 0.4)
			card.stroke.Thickness = 3
			card.state.Text = ""
			card.check.Visible = true
		else
			card.frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
			card.stroke.Color = color
			card.stroke.Thickness = 3
			card.state.Text = ""
			card.check.Visible = false
		end
	end
	if status.canClaim then
		footer.Text = Localization.t("daily.available")
		footer.TextColor3 = Theme.Colors.Success
	else
		footer.Text = Localization.t("daily.next", { time = NumberFormatter.duration(status.secondsLeft or 0) })
		footer.TextColor3 = Theme.Colors.TextMuted
	end
end

function DailyController.RefreshStatus()
	local result = Net.request("GetDailyStatus")
	if result.ok then
		status = result.data
		render()
	end
end

local function claim()
	if claiming or not status or not status.canClaim then
		return
	end
	claiming = true
	local result = Net.request("ClaimDaily")
	claiming = false
	if result.ok then
		UIKit.sound("Reward")
		local r = result.data
		local text
		if r.kind == "Money" then
			text = NumberFormatter.money(r.amount)
		elseif r.kind == "Gems" then
			text = "💎 " .. r.amount
		elseif r.kind == "LuckBoost" then
			text = string.format("🍀 %gx", r.multiplier)
		else
			text = Localization.t("dice." .. tostring(r.id))
		end
		NotificationController.Show("daily.claimed", { day = r.day, reward = text })
	else
		NotificationController.Show("error." .. tostring(result.code))
	end
	DailyController.RefreshStatus()
end

function DailyController.Init()
	window = UIKit.window({ name = "Daily", title = Localization.t("daily.title"), icon = "📅", size = Vector2.new(860, 500), header = Theme.Colors.HeaderRed })
	local content = window.content
	local cell = Vector2.new(170, 170)
	for day = 1, 7 do
		local reward = DailyConfig.Rewards[day]
		local big = day == 7
		local col = (day - 1) % 3
		local row = if day <= 3 then 0 else 1
		local size = if big then Vector2.new(250, cell.Y * 2 + 12) else cell
		local pos = if big then Vector2.new(3 * (cell.X + 12) + 12, 12) else Vector2.new(12 + col * (cell.X + 12), 12 + row * (cell.Y + 12))
		local frame = UIKit.new("TextButton", {
			Text = "",
			AutoButtonColor = false,
			Size = UDim2.fromOffset(size.X, size.Y),
			Position = UDim2.fromOffset(pos.X, pos.Y),
			BackgroundColor3 = Color3.fromRGB(30, 30, 40),
		}, content)
		UIKit.corner(frame, Theme.CornerRadiusSmall)
		local stroke = UIKit.stroke(frame, 3, DAY_COLORS[day], true)
		UIKit.text(frame, { text = Localization.t("daily.day", { day = day }), size = UDim2.new(0.9, 0, 0, if big then 54 else 40), position = UDim2.new(0.5, 0, 0, 8), anchor = Vector2.new(0.5, 0) })
		UIKit.text(frame, { text = reward.Icon, size = UDim2.fromScale(0.6, if big then 0.45 else 0.4), position = UDim2.fromScale(0.5, if big then 0.5 else 0.52), anchor = Vector2.new(0.5, 0.5), stroke = 0 })
		UIKit.text(frame, { text = rewardText(reward), size = UDim2.new(0.92, 0, 0, if big then 46 else 34), position = UDim2.new(0.5, 0, 1, -8), anchor = Vector2.new(0.5, 1) })
		local check = UIKit.text(frame, { text = "✔", size = UDim2.fromScale(0.6, 0.6), position = UDim2.fromScale(0.5, 0.5), anchor = Vector2.new(0.5, 0.5), color = Theme.Colors.Success, stroke = 4, z = 3 })
		check.Visible = false
		local state = UIKit.text(frame, { text = "", size = UDim2.new(0.9, 0, 0, 28), position = UDim2.new(0.5, 0, 0.78, 0), anchor = Vector2.new(0.5, 0.5), color = Theme.Colors.Warning, z = 3 })
		frame.Activated:Connect(function()
			if status and status.canClaim and status.day == day then
				task.spawn(claim)
			end
		end)
		cards[day] = { frame = frame, stroke = stroke, state = state, check = check }
	end
	footer = UIKit.text(content, { size = UDim2.new(1, -24, 0, 36), position = UDim2.new(0.5, 0, 1, -8), anchor = Vector2.new(0.5, 1) })
	window.Opened:Connect(DailyController.RefreshStatus)
end

function DailyController.Start()
	DataController.Wait()
	DailyController.RefreshStatus()
	-- Brilho leve no dia disponível + contagem regressiva
	task.spawn(function()
		local t = 0
		local second = 0
		while true do
			task.wait(0.1)
			t += 0.1
			second += 0.1
			if status and status.canClaim then
				local card = cards[status.day]
				if card then
					card.stroke.Transparency = 0.3 + 0.3 * math.sin(t * 5)
				end
			end
			if second >= 1 then
				second = 0
			else
				continue
			end
			if status and not status.canClaim and window.isOpen then
				status.secondsLeft = math.max(0, (status.secondsLeft or 0) - 1)
				render()
				if status.secondsLeft <= 0 then
					DailyController.RefreshStatus()
				end
			end
		end
	end)
	-- Verifica de tempos em tempos (virada do dia com o jogo aberto)
	task.spawn(function()
		while true do
			task.wait(60)
			DailyController.RefreshStatus()
		end
	end)
end

return DailyController
