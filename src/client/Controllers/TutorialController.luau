--!strict
--[[
	TutorialController (auditoria): 7 passos curtos na primeira sessão (TutorialConfig).
	Um banner no topo mostra "PASSO X/7" + o que fazer + PULAR. Cada passo é detectado pelos
	próprios dados do jogador (nada de clique obrigatório em seta) e o servidor só deixa avançar.
	HUD progressivo: até o passo HideSecondaryUntil os botões secundários (esquerda/direita)
	ficam escondidos. Enquanto o tutorial está no começo, janelas automáticas esperam
	(NotificationController.AddBlocker).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.Shared
local TutorialConfig = require(Shared.Config.TutorialConfig)
local Localization = require(Shared.Localization.Localization)
local Net = require(Shared.Modules.Net)

local UI = script.Parent.Parent.UI
local UIKit = require(UI.UIKit)
local Theme = require(UI.UITheme)
local DataController = require(script.Parent.DataController)
local HudController = require(script.Parent.HudController)
local NotificationController = require(script.Parent.NotificationController)

local TutorialController = {}

local gui: ScreenGui
local stepLabel: TextLabel
local textLabel: TextLabel
local actionButton: TextButton
local sending = false
local visitedBase = false

local function done(): number
	return DataController.Get("Tutorial") or TutorialConfig.Total
end

function TutorialController.Active(): boolean
	return done() < TutorialConfig.Total
end

function TutorialController.Step(): number
	return math.min(done() + 1, TutorialConfig.Total)
end

local function nearBase(): boolean
	local player = Players.LocalPlayer
	local baseId = player and player:GetAttribute("BaseId")
	local bases = Workspace:FindFirstChild("Bases")
	local character = player and player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (baseId and bases and root and root:IsA("BasePart")) then
		return false
	end
	for _, base in bases:GetChildren() do
		if base:IsA("Model") and base:GetAttribute("BaseId") == baseId then
			return (base:GetPivot().Position - root.Position).Magnitude < TutorialConfig.BaseDistance
		end
	end
	return false
end

-- O passo `step` (1..Total) já foi cumprido?
local function satisfied(step: number): boolean
	local data: any = DataController.GetAll() or {}
	local id = TutorialConfig.Steps[step]
	if id == "roll" then
		return (data.Rolls or 0) >= 1
	elseif id == "backpack" then
		local window = UIKit.Windows.get("Inventory")
		return window ~= nil and window.isOpen
	elseif id == "equip" then
		return next(data.EquippedCharacters or {}) ~= nil
	elseif id == "base" then
		return visitedBase or nearBase()
	elseif id == "collect" then
		return (data.Money or 0) > 0
	elseif id == "upgrade" then
		for _, value in data.Upgrades or {} do
			if value > 0 then
				return true
			end
		end
		for _, item in data.Inventory or {} do
			if (item.Level or 1) >= 2 then
				return true
			end
		end
		return false
	end
	return false -- "goal": só com o botão OK
end

local function advance(step: number)
	if sending then
		return
	end
	sending = true
	Net.request("SetTutorialStep", step)
	sending = false
end

local function render()
	local active = TutorialController.Active()
	gui.Enabled = active
	HudController.SetTutorialHidden(active and TutorialController.Step() <= TutorialConfig.HideSecondaryUntil)
	if not active then
		return
	end
	local step = TutorialController.Step()
	local id = TutorialConfig.Steps[step]
	stepLabel.Text = Localization.t("tutorial.step", { step = step, total = TutorialConfig.Total })
	textLabel.Text = Localization.t("tutorial." .. id)
	actionButton.Visible = id == "base" or id == "goal"
	actionButton.Text = Localization.t(if id == "base" then "tutorial.go_base" else "tutorial.ok")
end

function TutorialController.Init()
	gui = UIKit.screen("Tutorial", 60)
	gui.Enabled = false
	local root = UIKit.scaledRoot(gui)
	local panel = UIKit.new("Frame", {
		Name = "Banner",
		Size = UDim2.fromOffset(640, 96),
		Position = UDim2.new(0.5, 0, 0, 70),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Theme.Colors.PanelBackground,
		BackgroundTransparency = 0.1,
	}, root)
	UIKit.corner(panel, Theme.CornerRadius)
	UIKit.stroke(panel, 3, Theme.Colors.Warning, true)
	stepLabel = UIKit.text(panel, { name = "Step", text = "", size = UDim2.fromOffset(160, 28), position = UDim2.fromOffset(14, 6), color = Theme.Colors.Warning, align = Enum.TextXAlignment.Left })
	textLabel = UIKit.text(panel, { name = "Text", text = "", size = UDim2.new(1, -200, 0, 54), position = UDim2.fromOffset(14, 34), align = Enum.TextXAlignment.Left })
	textLabel.TextWrapped = true
	actionButton = UIKit.button(panel, {
		name = "Action",
		text = "",
		color = Theme.Colors.Success,
		size = UDim2.fromOffset(170, 44),
		position = UDim2.new(1, -12, 0, 8),
		anchor = Vector2.new(1, 0),
		onClick = function()
			local step = TutorialController.Step()
			if TutorialConfig.Steps[step] == "base" then
				task.spawn(Net.request, "RequestTeleport", "Home")
				visitedBase = true
			end
			task.spawn(advance, step)
		end,
	})
	UIKit.button(panel, {
		name = "Skip",
		text = Localization.t("tutorial.skip"),
		color = Theme.Colors.Locked,
		size = UDim2.fromOffset(110, 34),
		position = UDim2.new(1, -12, 1, -8),
		anchor = Vector2.new(1, 1),
		onClick = function()
			task.spawn(advance, TutorialConfig.Total)
		end,
	})
	-- Janelas automáticas (offline etc.) esperam os 3 primeiros passos
	NotificationController.AddBlocker(function()
		return TutorialController.Active() and TutorialController.Step() <= TutorialConfig.HideSecondaryUntil
	end)
end

function TutorialController.Start()
	DataController.Wait()
	render()
	DataController.Changed:Connect(function(key)
		if key == "Tutorial" then
			render()
		end
	end)
	task.spawn(function()
		while TutorialController.Active() do
			task.wait(0.3)
			local step = TutorialController.Step()
			if TutorialController.Active() and satisfied(step) then
				advance(step)
			end
		end
		render()
	end)
end

return TutorialController
