--!strict
--[[
	RollController: botão ROLAR (baixo centro), AUTO, OCULTAR e histórico da sessão.
	O cliente só PEDE (RequestRoll sem argumentos); o resultado vem do servidor e o
	RevealController apresenta. Cadência: RollConfig.RollSpeed (1 roll/s; Roll Rápido 2/s) para
	manual, AUTO e OCULTAR — o servidor valida cada roll. Raridades com AutoRoll = "Pause" (RevealConfig)
	pausam o AUTO enquanto a cinemática toca e ele continua depois.
	Inventário cheio: para o AUTO e mostra a ação [VENDER] [MOCHILA] (sem spam).
	AUTO (AFK Resilience): a escolha do jogador vira Settings.AutoRoll (o servidor limpa numa entrada
	normal e só manda ResumeAuto numa RECONEXÃO pronta). O AUTO ocioso continua igual: um pedido por
	vez, nenhuma fila, nenhum roll "devido" acumulado (readyAt = envio + intervalo).
	RECENT ROLLS some sozinho 20 s depois do último roll (AutoHideTimer) e volta na hora com o
	próximo. Esconder é só APRESENTAÇÃO (fade + leve deslize): a faixa continua montada, os
	retratos (ViewportFrame/câmera/modelo do CharacterPreview) não são destruídos nem recriados.
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
local AutoHideTimer = require(Shared.Modules.AutoHideTimer)
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
local started = false
local readyAt = 0
local history: { any } = {}

local rollButton: TextButton
local cooldownBar: Frame
local autoButton: TextButton
local hideButton: TextButton
local historyRow: Frame
local historyBase: UDim2 = UDim2.new()

-- RECENT ROLLS: some depois de HISTORY_HIDE_AFTER s sem roll novo
local HISTORY_HIDE_AFTER = 20
local HISTORY_FADE = 0.25
local historyTimer = AutoHideTimer.new(HISTORY_HIDE_AFTER)
local historyShown = false
local clockFn = os.clock -- trocável nos testes (tempos exatos)

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
-- rosto/cabelo/busto. INCREMENTAL: cada chip pertence a UM roll (identidade = a entrada da lista,
-- não o índice). Um roll novo cria só o chip dele; os outros só mudam de posição (LayoutOrder) —
-- o retrato deles continua montado (sem piscar). Quem sai do fim da faixa é liberado.
local chipOf: { [any]: Frame } = setmetatable({}, { __mode = "k" }) :: any
local renderGeneration = 0

-- propriedades de transparência que o fade controla (o valor original fica num atributo)
local FADE_PROPS: { [string]: { string } } = {
	Frame = { "BackgroundTransparency" },
	ViewportFrame = { "ImageTransparency", "BackgroundTransparency" },
	TextLabel = { "TextTransparency", "TextStrokeTransparency" },
	ImageLabel = { "ImageTransparency" },
	UIStroke = { "Transparency" },
}

local function fadeTargets(): { { obj: Instance, prop: string, base: number } }
	local out = {}
	for _, obj in historyRow:GetDescendants() do
		local props = FADE_PROPS[obj.ClassName]
		if props then
			for _, prop in props do
				local key = "FadeBase_" .. prop
				local base = obj:GetAttribute(key)
				if type(base) ~= "number" then
					base = (obj :: any)[prop]
					obj:SetAttribute(key, base)
				end
				table.insert(out, { obj = obj, prop = prop, base = base :: number })
			end
		end
	end
	return out
end

-- Mostra/esconde a faixa SEM Visible = false (o CharacterPreview liberaria os modelos e o
-- retorno piscaria): só transparência + deslize de 14 px
local function setHistoryShown(on: boolean, instant: boolean?)
	if historyShown == on and not instant then
		return
	end
	historyShown = on
	historyRow:SetAttribute("AutoHidden", not on)
	local time = if instant then 0 else (if on then HISTORY_FADE * 0.6 else HISTORY_FADE)
	local info = TweenInfo.new(time, Enum.EasingStyle.Quad, if on then Enum.EasingDirection.Out else Enum.EasingDirection.In)
	local target = if on then historyBase else historyBase + UDim2.fromOffset(0, 14)
	-- tween (mesmo de duração 0) cancela um fade em andamento na mesma propriedade
	TweenService:Create(historyRow, info, { Position = target }):Play()
	if time <= 0 then
		historyRow.Position = target
	end
	for _, item in fadeTargets() do
		local goal = if on then item.base else 1
		TweenService:Create(item.obj, info, { [item.prop] = goal }):Play()
		if time <= 0 then
			(item.obj :: any)[item.prop] = goal
		end
	end
end

-- (loop de 0,25 s e testes) aplica a regra dos 20 s para o instante `now`
local function updateHistoryVisibility(now: number)
	if historyRow then
		setHistoryShown(historyTimer:visible(now))
	end
end

local function renderHistory()
	renderGeneration += 1
	for i, entry in history do
		local chip = chipOf[entry]
		if not chip or chip.Parent ~= historyRow then
			local character = CharacterConfig.ById[entry.CharacterId]
			local newChip = UIKit.new("Frame", {
				Size = UDim2.fromOffset(44, 44),
				BackgroundColor3 = UIKit.darken(UIKit.rarityColor(entry.Rarity), 0.55),
				ClipsDescendants = true,
			}, historyRow)
			UIKit.corner(newChip, 10)
			UIKit.stroke(newChip, 2.5, UIKit.rarityColor(entry.Rarity), true)
			CharacterPreview.set(newChip, entry.CharacterId, entry.Variant, "head", character and character.VisualTheme.Icon or "?")
			chipOf[entry] = newChip
			chip = newChip
		end
		local c = chip :: Frame
		c.Name = "Recent" .. i
		c.LayoutOrder = i
		c:SetAttribute("RenderGeneration", renderGeneration)
	end
	-- chips que saíram da faixa (marcados por geração; nada de Instance como chave de tabela)
	for _, child in historyRow:GetChildren() do
		if child:IsA("Frame") and child:GetAttribute("RenderGeneration") ~= renderGeneration then
			CharacterPreview.detach(child)
			child:Destroy()
		end
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

-- Preferência AUTO no save (só quando o JOGADOR liga/desliga ou o inventário enche)
local function persistAuto(on: boolean)
	local settings = DataController.Get("Settings")
	if type(settings) == "table" and settings.AutoRoll ~= on then
		task.spawn(DataController.SetSetting, "AutoRoll", on)
	end
end

local function inventoryFull()
	auto = false
	refreshToggles()
	persistAuto(false)
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
	-- roll novo: a faixa aparece NA HORA e o contador de 20 s recomeça
	historyTimer:bump(clockFn())
	setHistoryShown(true, true)
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

-- Reconexão pronta (servidor mandou ResumeAuto): religa o AUTO sem mexer na cadência
function RollController.ResumeAuto(): boolean
	if not started or auto then
		return false
	end
	RollController.SetAuto(true)
	return true
end

function RollController.IsAuto(): boolean
	return auto
end

function RollController.IsReady(): boolean
	return started
end

function RollController.History(): { any }
	return table.clone(history)
end

-- (testes) relógio, "chegou um roll" e "agora é t" com tempos exatos; estado da faixa
function RollController._setClock(fn: () -> number)
	clockFn = fn
end
function RollController._historyRolled(now: number)
	historyTimer:bump(now)
	setHistoryShown(true, true)
end
RollController._historyAt = updateHistoryVisibility
function RollController.HistoryShown(): boolean
	return historyShown
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
		primary = true, -- HUDPrimaryButton: ação principal, chip maior
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
	}, rollButton:FindFirstChild("Chip") or rollButton)
	UIKit.new("UICorner", { CornerRadius = UDim.new(Theme.Hud.ChipRoundness, 0) }, cooldownBar)

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
			persistAuto(auto)
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
	historyBase = historyRow.Position
	setHistoryShown(false, true) -- sem rolls ainda: nada a mostrar
	task.spawn(function()
		while true do
			task.wait(0.25)
			updateHistoryVisibility(clockFn())
		end
	end)
	refreshToggles()
	DataController.Changed:Connect(function(key)
		if key == "Settings" then
			refreshToggles()
		end
	end)
	started = true
	-- Atalho de teclado (PC): R = rolar
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.R then
			task.spawn(RollController.Roll)
		end
	end)
end

return RollController
