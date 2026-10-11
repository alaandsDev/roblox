--!strict
--[[
	NotificationController: avisos curtos ("toasts") no topo da tela.
	O servidor manda só a CHAVE do texto + parâmetros; o texto vem da Localization.
	    NotificationController.Show("settings.saved")
	Fila: um aviso por vez, cada um por DURATION segundos.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Modules.Net)
local Localization = require(Shared.Localization.Localization)

local DURATION = 3
local MAX_QUEUE = 5

local NotificationController = {}

local queue: { string } = {}
local showing = false
local label: TextLabel

local function build()
	local gui = Instance.new("ScreenGui")
	gui.Name = "Notifications"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 100
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.Position = UDim2.new(0.5, 0, 0, 72)
	label.Size = UDim2.new(0.6, 0, 0, 44)
	label.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	label.BackgroundTransparency = 0.15
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.Visible = false
	label.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = label
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.PaddingTop = UDim.new(0, 6)
	padding.PaddingBottom = UDim.new(0, 6)
	padding.Parent = label
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(640, 44)
	limit.Parent = label
end

local function showNext()
	if showing or #queue == 0 then
		return
	end
	showing = true
	label.Text = table.remove(queue, 1) :: string
	label.TextTransparency = 1
	label.BackgroundTransparency = 1
	label.Visible = true
	TweenService:Create(label, TweenInfo.new(0.2), { TextTransparency = 0, BackgroundTransparency = 0.15 }):Play()
	task.delay(DURATION, function()
		label.Visible = false
		showing = false
		showNext()
	end)
end

function NotificationController.Show(key: string, params: { [string]: any }?)
	if #queue >= MAX_QUEUE then
		table.remove(queue, 1)
	end
	table.insert(queue, Localization.t(key, params))
	showNext()
end

function NotificationController.Start()
	build()
	Net.on("Notify", function(key: string, params: { [string]: any }?)
		NotificationController.Show(key, params)
	end)
end

return NotificationController
