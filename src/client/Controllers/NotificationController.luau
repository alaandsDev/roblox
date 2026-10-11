--!strict
--[[
	NotificationController: mensagens grandes no centro-inferior da tela (estilo da referência).
	Mensagens IGUAIS são agrupadas ("Inventário cheio! [x3]") em vez de empilhar labels.
	    NotificationController.Show("error.inventory_full")          -> chave da Localization
	    NotificationController.ShowText("texto pronto", "Info")
	    NotificationController.ShowAction("error.inventory_full", { {text, color, onClick}, ... })
	Estilos: Error (vermelho), Info (branco), Success (verde), Reward (dourado).
	No máximo MAX_LINES linhas ao mesmo tempo.

	Prioridade (auditoria): CRITICAL > RARE_DROP > REWARD > WARNING > INFO.
	  - Durante uma cinemática de raridade (RevealController.Busy) só CRITICAL/RARE_DROP/WARNING
	    aparecem; REWARD/INFO esperam a cinemática acabar.
	  - Janelas automáticas (offline, recompensas) entram em NotificationController.QueueModal e
	    abrem UMA por vez, por prioridade, só quando não há reveal, janela aberta ou passo de
	    tutorial bloqueando (NotificationController.AddBlocker).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Modules.Net)
local Localization = require(Shared.Localization.Localization)
local RevealController = require(script.Parent.RevealController)

local UI = script.Parent.Parent.UI
local UIKit = require(UI.UIKit)
local Theme = require(UI.UITheme)

local DURATION = 3
local MAX_LINES = 3
local COLORS = {
	Error = Color3.fromRGB(255, 60, 60),
	Info = Color3.fromRGB(255, 255, 255),
	Success = Color3.fromRGB(90, 245, 90),
	Reward = Color3.fromRGB(255, 215, 70),
}

local NotificationController = {}

NotificationController.Priority = { CRITICAL = 1, RARE_DROP = 2, REWARD = 3, WARNING = 4, INFO = 5 }
local PRIORITY = NotificationController.Priority

type Modal = { name: string, priority: number, seq: number, open: () -> () }
local modals: { Modal } = {}
local modalSeq = 0
local blockers: { () -> boolean } = {}
local deferred: { { text: string, style: string? } } = {}

type Line = { text: string, count: number, label: TextLabel, expires: number }
local lines: { Line } = {}
local stack: Frame
local actionBar: Frame
local actionKey: string? = nil
local pending: { { text: string, style: string? } } = {}

local function styleOf(key: string): string
	if string.sub(key, 1, 6) == "error." then
		return "Error"
	elseif string.sub(key, 1, 6) == "daily." or string.sub(key, 1, 6) == "index." or string.sub(key, 1, 8) == "offline." then
		return "Reward"
	end
	return "Info"
end

-- Prioridade de uma chave de texto
function NotificationController.PriorityOf(key: string): number
	if string.sub(key, 1, 9) == "critical." or key == "error.data_load" then
		return PRIORITY.CRITICAL
	elseif string.sub(key, 1, 5) == "rare." then
		return PRIORITY.RARE_DROP
	elseif string.sub(key, 1, 6) == "error." then
		return PRIORITY.WARNING
	elseif styleOf(key) == "Reward" or string.sub(key, 1, 8) == "mission." then
		return PRIORITY.REWARD
	end
	return PRIORITY.INFO
end

local function blocked(): boolean
	if RevealController.Busy() then
		return true
	end
	for _, fn in blockers do
		if fn() then
			return true
		end
	end
	return false
end

-- Algo (ex.: passo do tutorial) que impede janelas automáticas enquanto devolver true
function NotificationController.AddBlocker(fn: () -> boolean)
	table.insert(blockers, fn)
end

-- Janela automática na fila (uma por vez, maior prioridade primeiro; mesmo nome não repete)
function NotificationController.QueueModal(name: string, priority: number, open: () -> ())
	for _, modal in modals do
		if modal.name == name then
			return
		end
	end
	modalSeq += 1
	table.insert(modals, { name = name, priority = priority, seq = modalSeq, open = open })
end

function NotificationController.PendingModals(): { string }
	local out = {}
	for _, modal in modals do
		table.insert(out, modal.name)
	end
	return out
end

local function pumpModals()
	if #modals == 0 or blocked() or UIKit.Windows.anyOpen() then
		return
	end
	table.sort(modals, function(a, b)
		if a.priority ~= b.priority then
			return a.priority < b.priority
		end
		return a.seq < b.seq
	end)
	local modal = table.remove(modals, 1)
	if modal then
		modal.open()
	end
end

local function render(line: Line)
	line.label.Text = if line.count > 1 then `{line.text} [x{line.count}]` else line.text
end

local function remove(line: Line)
	local index = table.find(lines, line)
	if index then
		table.remove(lines, index)
	end
	local label = line.label
	TweenService:Create(label, TweenInfo.new(0.2), { TextTransparency = 1 }):Play()
	task.delay(0.2, label.Destroy, label)
end

function NotificationController.ShowText(text: string, style: string?)
	if not stack then
		table.insert(pending, { text = text, style = style })
		return
	end
	local now = os.clock()
	for _, line in lines do
		if line.text == text then
			line.count += 1
			line.expires = now + DURATION
			render(line)
			local s = line.label:FindFirstChildOfClass("UIScale")
			if s then
				s.Scale = 1.12
				TweenService:Create(s, TweenInfo.new(0.15), { Scale = 1 }):Play()
			end
			return
		end
	end
	if #lines >= MAX_LINES then
		remove(lines[1])
	end
	local label = UIKit.text(stack, {
		text = text,
		size = UDim2.new(1, 0, 0, 46),
		color = COLORS[style or "Info"] or COLORS.Info,
		stroke = 3,
	})
	UIKit.new("UIScale", { Scale = 1 }, label)
	local line = { text = text, count = 1, label = label, expires = now + DURATION }
	label.LayoutOrder = math.floor(now * 1000) % 1e9
	table.insert(lines, line)
	render(line)
end

function NotificationController.Show(key: string, params: { [string]: any }?)
	local text = Localization.t(key, params)
	local priority = NotificationController.PriorityOf(key)
	if priority >= PRIORITY.REWARD and priority ~= PRIORITY.WARNING and RevealController.Busy() then
		table.insert(deferred, { text = text, style = styleOf(key) })
		return
	end
	NotificationController.ShowText(text, styleOf(key))
end

export type Action = { text: string, color: Color3?, onClick: () -> () }

-- Mensagem com botões (ex.: inventário cheio -> [VENDER] [MOCHILA]). Não repete enquanto visível.
function NotificationController.ShowAction(key: string, actions: { Action })
	NotificationController.Show(key)
	if not actionBar then
		return
	end
	if actionKey == key and actionBar.Visible then
		return
	end
	actionKey = key
	for _, child in actionBar:GetChildren() do
		if child:IsA("GuiButton") then
			child:Destroy()
		end
	end
	for i, action in actions do
		UIKit.button(actionBar, {
			text = action.text,
			color = action.color or Theme.Colors.Primary,
			size = UDim2.fromOffset(170, 50),
			order = i,
			onClick = function()
				actionBar.Visible = false
				action.onClick()
			end,
		})
	end
	actionBar.Visible = true
	task.delay(DURATION + 1, function()
		if actionKey == key then
			actionBar.Visible = false
			actionKey = nil
		end
	end)
end

function NotificationController.Start()
	local gui = UIKit.screen("Notifications", 80)
	local root = UIKit.scaledRoot(gui)
	stack = UIKit.new("Frame", {
		Name = "Stack",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(1100, 160),
		Position = UDim2.new(0.5, 0, 1, -200),
		AnchorPoint = Vector2.new(0.5, 1),
	}, root)
	local layout = UIKit.list(stack, false, 2, "center")
	layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	actionBar = UIKit.new("Frame", {
		Name = "Actions",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(400, 52),
		Position = UDim2.new(0.5, 0, 1, -146),
		AnchorPoint = Vector2.new(0.5, 1),
		Visible = false,
	}, root)
	UIKit.list(actionBar, true, 12, "center")

	for _, item in pending do
		NotificationController.ShowText(item.text, item.style)
	end
	table.clear(pending)
	Net.on("Notify", function(key: string, params: { [string]: any }?)
		NotificationController.Show(key, params)
	end)
	task.spawn(function()
		while true do
			task.wait(0.25)
			if #deferred > 0 and not RevealController.Busy() then
				for _, item in deferred do
					NotificationController.ShowText(item.text, item.style)
				end
				table.clear(deferred)
			end
			pumpModals()
			local now = os.clock()
			for i = #lines, 1, -1 do
				if lines[i].expires <= now then
					remove(lines[i])
				end
			end
		end
	end)
end

return NotificationController
