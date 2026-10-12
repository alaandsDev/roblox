--!strict
--[[
	OfflineController: popup "BEM-VINDO DE VOLTA!" (layout da referência):
	título grande, ícone central, valor bem legível, botão verde RESGATAR, X no canto.
	O valor vem do SERVIDOR (PendingOfflineReward). Fechar no X não apaga: o botão
	🎁 OFFLINE no topo direito reabre enquanto houver valor pendente.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage.Shared
local NumberFormatter = require(Shared.Modules.NumberFormatter)
local Localization = require(Shared.Localization.Localization)
local Net = require(Shared.Modules.Net)

local UI = script.Parent.Parent.UI
local UIKit = require(UI.UIKit)
local Theme = require(UI.UITheme)
local DataController = require(script.Parent.DataController)
local NotificationController = require(script.Parent.NotificationController)

local OfflineController = {}

local window: UIKit.Window
local amountLabel: TextLabel
local claiming = false

local function refresh()
	amountLabel.Text = NumberFormatter.money(DataController.Get("PendingOfflineReward") or 0)
end

function OfflineController.Init()
	window = UIKit.window({ name = "Offline", title = Localization.t("offline.title"), icon = "⏳", size = Theme.PopupSizes.Small, header = Color3.fromRGB(235, 160, 70) })
	local content = window.content
	UIKit.text(content, { text = Localization.t("offline.subtitle"), size = UDim2.new(0.9, 0, 0, 46), position = UDim2.new(0.5, 0, 0, 14), anchor = Vector2.new(0.5, 0) })
	local icon = UIKit.text(content, { text = "💵", size = UDim2.fromOffset(120, 100), position = UDim2.new(0.5, 0, 0, 66), anchor = Vector2.new(0.5, 0), stroke = 0 })
	local iconScale = UIKit.new("UIScale", { Scale = 1 }, icon)
	amountLabel = UIKit.text(content, { text = "$0", size = UDim2.new(0.9, 0, 0, 70), position = UDim2.new(0.5, 0, 0, 170), anchor = Vector2.new(0.5, 0), color = Theme.Colors.Money, stroke = 4 })
	UIKit.button(content, {
		name = "Claim",
		text = Localization.t("offline.claim"),
		color = Theme.Colors.Success,
		size = UDim2.fromOffset(240, 64),
		position = UDim2.new(0.5, 0, 1, -16),
		anchor = Vector2.new(0.5, 1),
		onClick = function()
			if claiming then
				return
			end
			claiming = true
			local result = Net.request("ClaimOfflineReward")
			claiming = false
			if result.ok then
				UIKit.sound("Reward")
				NotificationController.Show("offline.claimed", { amount = NumberFormatter.money(result.data :: number) })
				window:Close()
			else
				NotificationController.Show("error." .. tostring(result.code))
				window:Close()
			end
		end,
	})
	window.Opened:Connect(function()
		refresh()
		iconScale.Scale = 0.6
		TweenService:Create(iconScale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end)
end

function OfflineController.Start()
	DataController.Wait()
	DataController.Changed:Connect(function(key)
		if key == "PendingOfflineReward" then
			refresh()
			if (DataController.Get("PendingOfflineReward") or 0) <= 0 then
				window:Close()
			elseif not window.isOpen then
				-- Recompensa nova (ex.: SimulateOffline no Studio): entra na fila de janelas
				NotificationController.QueueModal("Offline", NotificationController.Priority.REWARD, function()
					if (DataController.Get("PendingOfflineReward") or 0) > 0 then
						window:Open()
					end
				end)
			end
		end
	end)
	-- Mostra ao entrar se houver dinheiro offline
	-- (entra na fila: não abre por cima de reveal, outra janela ou passo do tutorial)
	if (DataController.Get("PendingOfflineReward") or 0) > 0 then
		task.wait(1.5)
		NotificationController.QueueModal("Offline", NotificationController.Priority.REWARD, function()
			if (DataController.Get("PendingOfflineReward") or 0) > 0 then
				window:Open()
			end
		end)
	end
end

return OfflineController
