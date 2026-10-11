--!strict
--[[
	SettingsController: janela CONFIGURAÇÕES (⚙️ no topo direito).
	    Ocultar animação do roll · Tremer câmera · Efeitos reduzidos (qualidade Low)
	Salvas no servidor (SetSetting só aceita estas chaves).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Localization = require(Shared.Localization.Localization)

local UI = script.Parent.Parent.UI
local UIKit = require(UI.UIKit)
local Theme = require(UI.UITheme)
local DataController = require(script.Parent.DataController)

local SettingsController = {}

local OPTIONS = { "HideRollAnimation", "CameraShake", "ReducedEffects" }

local window: UIKit.Window
local buttons: { [string]: TextButton } = {}

local function refresh()
	local settings = DataController.Get("Settings") or {}
	for key, button in buttons do
		local on = settings[key] == true
		UIKit.setButtonColor(button, if on then Theme.Colors.Success else Color3.fromRGB(70, 70, 92))
		UIKit.setButtonText(button, Localization.t(if on then "settings.on" else "settings.off"))
	end
end

function SettingsController.Init()
	window = UIKit.window({ name = "Settings", title = Localization.t("settings.title"), icon = "⚙️", size = Theme.PopupSizes.Small, header = Color3.fromRGB(70, 70, 95) })
	local content = window.content
	UIKit.padding(content, 16)
	UIKit.list(content, false, 12)
	for i, key in OPTIONS do
		local row = UIKit.new("Frame", { BackgroundColor3 = Theme.Colors.Card, Size = UDim2.new(1, 0, 0, 70), LayoutOrder = i }, content)
		UIKit.corner(row, Theme.CornerRadiusSmall)
		UIKit.text(row, { text = Localization.t("settings." .. key), size = UDim2.new(0.6, 0, 0, 34), position = UDim2.new(0, 14, 0.5, 0), anchor = Vector2.new(0, 0.5), align = Enum.TextXAlignment.Left })
		buttons[key] = UIKit.button(row, {
			text = "",
			size = UDim2.fromOffset(130, 50),
			position = UDim2.new(1, -12, 0.5, 0),
			anchor = Vector2.new(1, 0.5),
			onClick = function()
				local settings = DataController.Get("Settings") or {}
				task.spawn(DataController.SetSetting, key, not settings[key])
			end,
		})
	end
	window.Opened:Connect(refresh)
end

function SettingsController.Start()
	DataController.Changed:Connect(function(key)
		if key == "Settings" then
			refresh()
		end
	end)
end

return SettingsController
