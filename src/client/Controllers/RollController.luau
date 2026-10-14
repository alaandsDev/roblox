--!strict
--[[
	RollController: botão ROLAR (baixo centro), AUTO, OCULTAR e histórico da sessão.
	O cliente só PEDE (RequestRoll sem argumentos); o resultado vem do servidor e o
	RevealController apresenta. Cadência: RollConfig.RollSpeed (1 roll/s; Roll Rápido 2/s) para
	manual, AUTO e OCULTAR — o servidor valida cada roll. Raridades com AutoRoll = "Pause" (RevealConfig)
	pausam o AUTO enquanto a cinemática toca e ele continua depois.
	Inventário cheio: para o AUTO e mostra a ação [VENDER] [MOCHILA] (sem spam).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage.Shared
local RollConfig = require(Shared.Config.RollConfig)
local CharacterConfig = require(Shared.Config.CharacterConfig)
local Formulas = require(Shared.Modules.GameFormulas)
local Localization = require(Shared.Localization.Localization)
local Signal = require(Shared.Modules.Signal)
local Net = require(Shared.Modules.Net)

local UI = script.Parent.Parent.UI
local UIKit = require(UI.UIKit)
local CharacterPreview = require(UI.CharacterPreview)
local Theme = require(UI.UITheme)
local DataController = require(script.Parent.DataController)
local HudController = require(script.Parent.HudController)
local NotificationController = require(script.Parent.NotificationController)
local RevealController = require(script.Parent.RevealController)

local RollController = {}

-- (resultado) depois de cada roll
RollController.Rolled = Signal.new()

local requesting = false
local auto = false
local readyAt = 0
local history: { any } = {}

local rollButton: TextButton
local cooldownBar: Frame
local autoButton: TextButton
local hideButton: TextButton
local historyRow: Frame

local function setToggle(button: TextButton, on: boolean, key: string)
	UIKit.setButtonColor(button, if on then Theme.Colors.Success else Color3.fromRGB(70, 70, 92))
	UIKit.setButtonText(button, Localization.t(key) .. (if on then " ✓" else ""))
end

local function refreshToggles()
	local settings = DataController.Get("Settings") or {}
	setToggle(autoButton, auto, "roll.auto")
	setToggle(hideButton, settings.HideRollAnimation == true, "roll.hide")
end

-- Faixa dos últimos rolls: MESMO sistema de retrato da MOCHILA (CharacterPreview), enquadrado no
-- rosto/cabelo/busto. Os chips são reaproveitados (o modelo volta ao pool e é reusado).
local function renderHistory()
	CharacterPreview.releaseScope(historyRow)
	for _, child in historyRow:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	for i, entry in history do
		local character = CharacterConfig.ById[entry.CharacterId]
		local chip = UIKit.new("Frame", {
			Name = "Recent" .. i,
			Size = UDim2.fromOffset(44, 44),
			BackgroundColor3 = UIKit.darken(UIKit.rarityColor(entry.Rarity), 0.55),
			LayoutOrder = i,
			ClipsDescendants = true,
		}, historyRow)
		UIKit.corner(chip, 10)
		UIKit.stroke(chip, 2.5, UIKit.rarityColor(entry.Rarity), true)
		CharacterPreview.attach(chip, entry.CharacterId, entry.Variant, "head", character and character.VisualTheme.Icon or "?")
	end
	CharacterPreview.update()
end

local function cooldownSeconds(): number
	local data = DataController.GetAll()
	return if data then Formulas:rollCooldown(data) else RollConfig.RollSpeed.BaseInterval
end

local function animateCooldown(seconds: number)
	cooldownBar.Size = UDim2.fromScale(1, 1)
	cooldownBar.Visible = true
	local tween = TweenService:Create(cooldownBar, TweenInfo.new(seconds, Enum.EasingStyle.Linear), { Size = UDim2.fromScale(1, 0) })
	tween:Play()
	tween.Completed:Once(function()
		cooldownBar.Visible = false
	end)
end

local function inventoryFull()
	auto = false
	refreshToggles()
	NotificationController.ShowAction("error.inventory_full", {
		{ text = Localization.t("roll.full_sell"), color = Theme.Colors.Orange, onClick = function()
			UIKit.Windows.open("Sell")
		end },
		{ text = Localization.t("roll.full_backpack"), color = Theme.Colors.Primary, onClick = function()
			UIKit.Windows.open("Inventory")
		end },
	})
end

-- Um roll. Devolve true se o servidor aceitou
function RollController.Roll(): boolean
	if requesting or RevealController.Busy() or os.clock() < readyAt then
		return false
	end
	requesting = true
	local sentAt = os.clock()
	local result = Net.request("RequestRoll")
	requesting = false
	if not result.ok then
		if result.code == "inventory_full" then
			inventoryFull()
		elseif result.code ~= "cooldown" and result.code ~= "rate_limited" then
			NotificationController.Show("error." .. tostring(result.code))
		end
		return false
	end
	local roll = result.data
	local seconds = cooldownSeconds()
	-- Conta do ENVIO: com latência a cadência fica perto de 1/intervalo (o servidor é quem
	-- garante o limite; se chegar cedo ele recusa com "cooldown" e o AUTO tenta de novo)
	readyAt = sentAt + seconds
	animateCooldown(seconds)
	table.insert(history, 1, roll)
	while #history > RollConfig.HistorySize do
		table.remove(history)
	end
	renderHistory()
	RollController.Rolled:Fire(roll)
	RevealController.Play(roll, { autoRoll = auto })
	return true
end

local function autoLoop()
	while auto do
		if not RevealController.Busy() and not requesting then
			local waitFor = readyAt - os.clock()
			if waitFor > 0 then
				task.wait(waitFor + RollConfig.AutoRollExtraDelay)
			end
			if auto then
				RollController.Roll()
			end
		end
		task.wait(0.05)
	end
end

function RollController.SetAuto(on: boolean)
	if auto == on then
		return
	end
	auto = on
	refreshToggles()
	if on then
		task.spawn(autoLoop)
	end
end

function RollController.History(): { any }
	return table.clone(history)
end

function RollController.Start()
	DataController.Wait()
	local bottom = HudController.Containers.BottomCenter
	rollButton = UIKit.iconButton(bottom, {
		name = "Roll",
		icon = "🎲",
		text = Localization.t("roll.button"),
		color = Color3.fromRGB(255, 170, 40),
		size = UDim2.fromOffset(Theme.ButtonSizes.Roll.X, Theme.ButtonSizes.Roll.Y),
		order = 2,
		onClick = function()
			task.spawn(RollController.Roll)
		end,
	})
	cooldownBar = UIKit.new("Frame", {
		Name = "Cooldown",
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.fromScale(1, 0),
		Visible = false,
		ZIndex = 4,
	}, rollButton)
	UIKit.corner(cooldownBar, Theme.CornerRadius)

	-- AUTO e OCULTAR acima do ROLAR + histórico acima deles
	local toggles = UIKit.new("Frame", {
		Name = "RollToggles",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(330, 46),
		Position = UDim2.new(0.5, 0, 1, -(Theme.ButtonSizes.Roll.Y + 24)),
		AnchorPoint = Vector2.new(0.5, 1),
	}, bottom.Parent)
	UIKit.list(toggles, true, 10, "center")
	autoButton = UIKit.button(toggles, {
		name = "Auto",
		text = Localization.t("roll.auto"),
		size = UDim2.fromOffset(150, 44),
		order = 1,
		onClick = function()
			RollController.SetAuto(not auto)
		end,
	})
	hideButton = UIKit.button(toggles, {
		name = "Hide",
		text = Localization.t("roll.hide"),
		size = UDim2.fromOffset(150, 44),
		order = 2,
		onClick = function()
			local settings = DataController.Get("Settings") or {}
			task.spawn(DataController.SetSetting, "HideRollAnimation", not settings.HideRollAnimation)
		end,
	})
	historyRow = UIKit.new("Frame", {
		Name = "History",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(500, 46),
		Position = UDim2.new(0.5, 0, 1, -(Theme.ButtonSizes.Roll.Y + 76)),
		AnchorPoint = Vector2.new(0.5, 1),
	}, bottom.Parent)
	UIKit.list(historyRow, true, 4, "center")
	refreshToggles()
	DataController.Changed:Connect(function(key)
		if key == "Settings" then
			refreshToggles()
		end
	end)
	-- Atalho de teclado (PC): R = rolar
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.R then
			task.spawn(RollController.Roll)
		end
	end)
end

return RollController
