--!strict
--[[
	SessionController (cliente): RESILIÊNCIA DE SESSÃO (ver AFK_RESILIENCE.md).

	1. Atividade: input REAL (teclado, mouse, toque, controle) -> ReportActivity no máximo a cada
	   AfkConfig.ActivityReportEvery s. Nada aqui gera input, simula atividade ou mexe no timeout
	   de inatividade do Roblox (simular input/atividade ou mexer na interface do Roblox: proibido).
	2. Indicador "💤 AFK" (atributo AfkState do servidor): só UX. AFK não muda nada no jogo.
	3. ResumeAuto: o servidor só manda numa RECONEXÃO com save + base + personagem + serviços
	   prontos; o AUTO é religado UMA vez, com a cadência de sempre.
	4. Queda de conexão (GuiService.ErrorMessageChanged): ReconnectPolicy decide; TeleportService
	   (API oficial) tenta voltar — 1ª tentativa no MESMO servidor quando faz sentido (nunca
	   prometido), depois qualquer servidor do place; limite de tentativas, espera, botão
	   RECONECTAR (clique real) limitado, e NUNCA loop. Inatividade da plataforma e expulsão do
	   jogo não reconectam. Há quedas em que nenhum código do jogo roda (ver AFK_RESILIENCE.md).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage.Shared
local AfkConfig = require(Shared.Config.AfkConfig)
local ReconnectPolicy = require(Shared.Modules.ReconnectPolicy)
local Localization = require(Shared.Localization.Localization)
local Net = require(Shared.Modules.Net)

local UI = script.Parent.Parent.UI
local UIKit = require(UI.UIKit)
local Theme = require(UI.UITheme)
local DataController = require(script.Parent.DataController)
local RollController = require(script.Parent.RollController)
local NotificationController = require(script.Parent.NotificationController)

local SessionController = {}

local player = Players.LocalPlayer
local lastReport = -math.huge
local reports = 0

-- trocáveis nos testes
SessionController._clock = os.clock
SessionController._delay = function(seconds: number, fn: () -> ())
	task.delay(seconds, fn)
end
-- vigia de teleporte sem resposta (separado da espera entre tentativas)
SessionController._watchdog = function(seconds: number, fn: () -> ())
	task.delay(seconds, fn)
end
-- Studio não teleporta (o place local não existe no Roblox): só mostra o que faria
SessionController._allowTeleport = not RunService:IsStudio()

local gui: ScreenGui? = nil
local chip: TextLabel? = nil
local banner: Frame? = nil
local bannerText: TextLabel? = nil
local reconnectButton: TextButton? = nil

local plan: any = nil
local planCode: string? = nil
local teleports: { { action: string, at: number } } = {}
local inFlight = false

local function service(name: string): any
	local ok, s = pcall(function()
		return game:GetService(name)
	end)
	return if ok then s else nil
end

------------------------------------------------------------------------------------
-- Atividade real (telemetria)

local function reportActivity()
	local now = SessionController._clock()
	if now - lastReport < AfkConfig.ActivityReportEvery then
		return
	end
	lastReport = now
	reports += 1
	task.spawn(Net.request, "ReportActivity")
end

------------------------------------------------------------------------------------
-- Interface: indicador AFK + faixa de reconexão

local function buildGui()
	local screen = UIKit.screen("SessionStatus", 40)
	gui = screen
	chip = UIKit.text(screen, {
		name = "AfkChip",
		text = Localization.t("afk.chip_idle"),
		size = UDim2.fromOffset(190, 26),
		position = UDim2.new(0.5, 0, 0, 6),
		anchor = Vector2.new(0.5, 0),
		color = Theme.Colors.Text,
	})
	local c = chip :: TextLabel
	c.BackgroundTransparency = 0.35
	c.BackgroundColor3 = Color3.fromRGB(30, 30, 46)
	c.Visible = false
	UIKit.corner(c, 8)

	local frame = UIKit.new("Frame", {
		Name = "Reconnect",
		Size = UDim2.fromOffset(460, 96),
		Position = UDim2.new(0.5, 0, 0, 40),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Color3.fromRGB(24, 24, 36),
		BackgroundTransparency = 0.1,
		Visible = false,
	}, screen)
	UIKit.corner(frame, 12)
	banner = frame
	bannerText = UIKit.text(frame, {
		name = "Message",
		text = "",
		size = UDim2.new(1, -20, 0, 40),
		position = UDim2.fromOffset(10, 6),
		wrap = true,
	})
	reconnectButton = UIKit.button(frame, {
		name = "ReconnectButton",
		text = Localization.t("afk.reconnect_button"),
		size = UDim2.fromOffset(180, 40),
		position = UDim2.new(0.5, 0, 1, -8),
		anchor = Vector2.new(0.5, 1),
		color = Theme.Colors.Primary,
		onClick = function()
			SessionController.ManualReconnect()
		end,
	})
	;(reconnectButton :: TextButton).Visible = false
end

local function refreshChip()
	if not chip then
		return
	end
	local state = player:GetAttribute("AfkState")
	local idle = state == "Idle"
	local c = chip :: TextLabel
	c.Visible = idle and plan == nil
	if idle then
		c.Text = Localization.t(if RollController.IsAuto() then "afk.chip_idle_auto" else "afk.chip_idle")
	end
end

local function showBanner(text: string, withButton: boolean)
	if not banner then
		return
	end
	(banner :: Frame).Visible = true;
	(bannerText :: TextLabel).Text = text;
	(reconnectButton :: TextButton).Visible = withButton
	refreshChip()
end

------------------------------------------------------------------------------------
-- Reconexão (TeleportService, limitada)

local function teleportService(): any
	return service("TeleportService")
end

local schedule: (step: any) -> ()

local function attempt(step: any)
	if not plan or inFlight then
		return
	end
	table.insert(teleports, { action = step.action, at = SessionController._clock() })
	if not SessionController._allowTeleport then
		return
	end
	local ts = teleportService()
	if not ts then
		plan:failed(nil)
		schedule(plan:next(SessionController._clock()))
		return
	end
	inFlight = true
	local data = plan:teleportData(os.time(), game.JobId)
	local ok = pcall(function()
		if step.action == "SameServer" then
			ts:TeleportToPlaceInstance(game.PlaceId, game.JobId, player, nil, data)
		else
			ts:Teleport(game.PlaceId, player, data)
		end
	end)
	if not ok then
		inFlight = false
		plan:failed(nil)
		schedule(plan:next(SessionController._clock()))
		return
	end
	-- sem resposta (nem sucesso nem TeleportInitFailed) em 30 s: conta como falha
	local mine = #teleports
	SessionController._watchdog(30, function()
		if inFlight and #teleports == mine and plan then
			inFlight = false
			plan:failed(nil)
			schedule(plan:next(SessionController._clock()))
		end
	end)
end

schedule = function(step: any)
	if not plan then
		return
	end
	if step.action == "SameServer" or step.action == "AnyServer" then
		showBanner(Localization.t("afk.reconnecting", { attempt = step.attempt, max = AfkConfig.Reconnect.MaxAttempts }), false)
		local now = SessionController._clock()
		SessionController._delay(math.max(0, step.at - now), function()
			attempt(step)
		end)
	elseif step.action == "Manual" then
		showBanner(Localization.t("afk.reconnect_wait"), true)
	elseif step.action == "Stop" then
		showBanner(Localization.t(if planCode == "DisconnectIdle" then "afk.disconnected_idle" else "afk.reconnect_stopped"), false)
	end
end

-- Queda detectada (ErrorMessageChanged). Só o PRIMEIRO aviso cria o plano.
function SessionController.OnDisconnected(code: string?)
	if plan then
		return
	end
	local kind = ReconnectPolicy.classify(code)
	local ts = teleportService()
	local chain = 0
	if ts then
		local ok, data = pcall(function()
			return ts:GetLocalPlayerTeleportData()
		end)
		if ok then
			chain = ReconnectPolicy.chainFrom(data, os.time(), AfkConfig.Reconnect)
		end
	end
	planCode = code
	plan = ReconnectPolicy.new(AfkConfig.Reconnect, { kind = kind, code = code, jobId = game.JobId, chain = chain })
	schedule(plan:next(SessionController._clock()))
end

-- TeleportInitFailed: o mesmo servidor sai da lista; próxima tentativa (se houver)
function SessionController.OnTeleportFailed(result: string?)
	if not plan then
		return
	end
	inFlight = false
	plan:failed(result)
	schedule(plan:next(SessionController._clock()))
end

-- Botão RECONECTAR (clique real do jogador)
function SessionController.ManualReconnect()
	if not plan or inFlight then
		return
	end
	local step = plan:manual(SessionController._clock())
	if step.action == "AnyServer" then
		showBanner(Localization.t("afk.reconnecting", { attempt = step.attempt, max = AfkConfig.Reconnect.MaxAttempts + AfkConfig.Reconnect.MaxManual }), false)
		attempt(step)
	elseif step.action == "Stop" then
		schedule(step)
	end
end

-- (testes/DEV) tentativas de teleporte feitas nesta sessão do cliente
function SessionController.Teleports(): { { action: string, at: number } }
	return table.clone(teleports)
end
function SessionController.ActivityReports(): number
	return reports
end
function SessionController._reset()
	plan, planCode, inFlight = nil, nil, false
	table.clear(teleports)
	if banner then
		(banner :: Frame).Visible = false
	end
end

------------------------------------------------------------------------------------

function SessionController.Start()
	DataController.Wait()
	buildGui()

	-- input REAL apenas (nenhum evento é criado aqui)
	UserInputService.InputBegan:Connect(function()
		reportActivity()
	end)
	local changed = (UserInputService :: any).InputChanged
	if changed then
		changed:Connect(function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				reportActivity()
			end
		end)
	end
	reportActivity()

	Net.on("ResumeAuto", function()
		task.spawn(function()
			local deadline = SessionController._clock() + 30
			while not RollController.IsReady() and SessionController._clock() < deadline do
				task.wait(0.2)
			end
			if RollController.ResumeAuto() then
				NotificationController.Show("afk.auto_resumed")
			end
		end)
	end)

	local guiService = service("GuiService")
	if guiService and guiService.ErrorMessageChanged then
		guiService.ErrorMessageChanged:Connect(function(message: string)
			if message == "" then
				return
			end
			local ok, code = pcall(function()
				return guiService:GetErrorCode()
			end)
			SessionController.OnDisconnected(if ok and typeof(code) == "EnumItem" then code.Name else nil)
		end)
	end
	local ts = teleportService()
	if ts and ts.TeleportInitFailed then
		ts.TeleportInitFailed:Connect(function(who: Player, result: Enum.TeleportResult)
			if who == player then
				SessionController.OnTeleportFailed(result.Name)
			end
		end)
	end

	-- indicador AFK (barato: 1x/s)
	task.spawn(function()
		while gui do
			refreshChip()
			task.wait(1)
		end
	end)
end

return SessionController
