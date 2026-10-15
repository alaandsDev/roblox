--!strict
--[[
	AfkService: RESILIÊNCIA DE SESSÃO (ver AFK_RESILIENCE.md). Não é "anti-AFK":
	  - nunca gera input, nunca simula atividade, nunca tenta evitar o timeout do Roblox;
	  - o estado Active/Idle/Reconnecting é só UX/telemetria (atributo "AfkState" no Player +
	    Analytics). NENHUMA fórmula lê esse estado: AFK não muda RNG, cadência (1 roll/s;
	    Roll Rápido 0,5 s), Luck, pity, renda nem recompensas;
	  - AUTO depois de uma RECONEXÃO: só se o jogador o tinha ligado (Settings.AutoRoll), a saída
	    foi há pouco (AfkConfig.ResumeAutoWindow) e save + base + personagem + serviços estão
	    prontos (ReconnectPolicy.resumeAuto). Aí o servidor avisa o cliente (ResumeAuto) UMA vez.
	    Entrada normal: AUTO começa desligado (a preferência transitória é limpa).

	Atividade: o cliente manda ReportActivity quando há input REAL (no máximo a cada
	AfkConfig.ActivityReportEvery s). Rolls do AUTO NÃO contam como atividade.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local AfkConfig = require(Shared.Config.AfkConfig)
local AfkCore = require(Shared.Modules.AfkCore)
local ReconnectPolicy = require(Shared.Modules.ReconnectPolicy)
local Formulas = require(Shared.Modules.GameFormulas)
local TableUtil = require(Shared.Modules.TableUtil)
local Logger = require(Shared.Modules.Logger)
local Net = require(Shared.Modules.Net)

local PlayerDataService = require(script.Parent.PlayerDataService)
local BaseService = require(script.Parent.BaseService)
local AnalyticsService = require(script.Parent.AnalyticsService)

local log = Logger.new("Afk")

local AfkService = {}

-- Relógios (substituíveis nos testes: tempo virtual)
AfkService._clock = os.clock
AfkService._time = os.time

-- desistir de religar o AUTO se a sessão não ficar pronta neste tempo
local RESUME_GIVE_UP = 60

type Session = {
	joinedAt: number,
	reconnect: boolean,
	chain: number,
	fromJobId: string,
	-- "Pending" (aguardando ficar pronto) | "Done" | "No"
	resume: string,
	resumeReason: string,
	resumeSince: number,
	simulated: boolean,
}

local trackers: { [Player]: AfkCore.Tracker } = {}
local sessions: { [Player]: Session } = {}
local lastState: { [Player]: string } = {}

local function teleportDataOf(player: Player): any
	local ok, joinData = pcall(function()
		return (player :: any):GetJoinData()
	end)
	if ok and type(joinData) == "table" then
		return joinData.TeleportData
	end
	return nil
end

local function ensure(player: Player): (AfkCore.Tracker, Session)
	local tracker = trackers[player]
	if not tracker then
		tracker = AfkCore.new(AfkConfig, AfkService._clock())
		trackers[player] = tracker
	end
	local session = sessions[player]
	if not session then
		local data = teleportDataOf(player)
		local chain = ReconnectPolicy.chainFrom(data, AfkService._time(), AfkConfig.Reconnect)
		session = {
			joinedAt = AfkService._time(),
			reconnect = chain > 0,
			chain = chain,
			fromJobId = if type(data) == "table" and type(data.FromJobId) == "string" then string.sub(data.FromJobId, 1, 64) else "",
			resume = "No",
			resumeReason = "not_evaluated",
			resumeSince = AfkService._clock(),
			simulated = false,
		}
		sessions[player] = session
	end
	return tracker, session :: Session
end

-- Prontidão para religar o AUTO (nunca rola antes do PlayerData)
local function readiness(player: Player): { [string]: boolean }
	local data = PlayerDataService.GetData(player)
	local runtime = data and data.Runtime
	return {
		dataLoaded = data ~= nil,
		baseReady = BaseService.GetPlayerBase(player) ~= nil,
		characterReady = (player :: any).Character ~= nil,
		-- BoostService já recalculou os multiplicadores da sessão (Roll Rápido, gamepasses)
		servicesReady = type(runtime) == "table" and runtime.Income ~= nil,
	}
end

local function sinceLogout(player: Player): number?
	local info = PlayerDataService.SessionInfo(player)
	if not info or info.previousLogout <= 0 then
		return nil
	end
	return info.loadedAt - info.previousLogout
end

local function evaluateResume(player: Player): (string, string)
	local data = PlayerDataService.GetData(player)
	local _, session = ensure(player)
	local ready = readiness(player)
	return ReconnectPolicy.resumeAuto({
		autoSetting = data ~= nil and data.Settings.AutoRoll == true,
		reconnect = session.reconnect,
		secondsSinceLogout = if session.simulated then 0 else sinceLogout(player),
		window = AfkConfig.ResumeAutoWindow,
		dataLoaded = ready.dataLoaded,
		baseReady = ready.baseReady,
		characterReady = ready.characterReady,
		servicesReady = ready.servicesReady,
	})
end

local function setAutoSetting(player: Player, on: boolean)
	local data = PlayerDataService.GetData(player)
	if data and data.Settings.AutoRoll ~= on then
		local settings = TableUtil.deepCopy(data.Settings)
		settings.AutoRoll = on
		PlayerDataService.Set(player, "Settings", settings)
	end
end

-- Save carregado: decide se esta sessão PODE religar o AUTO (o "quando" é no tick)
local function onLoaded(player: Player)
	local _, session = ensure(player)
	local decision, reason = evaluateResume(player)
	session.resumeSince = AfkService._clock()
	if decision == "No" then
		session.resume, session.resumeReason = "No", reason
		-- entrada normal: AUTO é estado transitório, começa desligado
		setAutoSetting(player, false)
	else
		session.resume, session.resumeReason = "Pending", reason
	end
	if session.reconnect then
		AnalyticsService.Track(player, "Reconnected", { chain = session.chain })
	end
end

local function refreshState(player: Player)
	local tracker = ensure(player)
	local state = tracker:state(AfkService._clock())
	if lastState[player] ~= state then
		local previous = lastState[player]
		lastState[player] = state
		player:SetAttribute("AfkState", state)
		if previous ~= nil then
			AnalyticsService.Track(player, if state == "Idle" then "AfkIdle" else "AfkActive", { state = state })
		end
	end
end

-- Um passo do loop central (1/s; exposto para testes com tempo virtual)
function AfkService._tick()
	for _, player in Players:GetPlayers() do
		refreshState(player)
		local session = sessions[player]
		if session and session.resume == "Pending" then
			local decision, reason = evaluateResume(player)
			session.resumeReason = reason
			if decision == "Resume" then
				session.resume = "Done"
				Net.fire("ResumeAuto", player)
				AnalyticsService.Track(player, "AutoResumed", { chain = session.chain })
				log:info(`{player.Name}: AUTO religado depois da reconexão`)
			elseif decision == "No" then
				session.resume = "No"
			elseif AfkService._clock() - session.resumeSince > RESUME_GIVE_UP then
				session.resume, session.resumeReason = "No", "timeout_" .. reason
			end
		end
	end
end

------------------------------------------------------------------------------------
-- API (DEV/testes)

function AfkService.ReportActivity(player: Player)
	local tracker = ensure(player)
	tracker:activity(AfkService._clock())
	refreshState(player)
	return true
end

function AfkService.State(player: Player): string
	return (ensure(player)):state(AfkService._clock())
end

-- Status completo (DEV AFKStatus). Só leitura.
function AfkService.Status(player: Player): { [string]: any }
	local tracker, session = ensure(player)
	local now = AfkService._clock()
	local data = PlayerDataService.GetData(player)
	local stats = PlayerDataService.SaveStats(player)
	local lastSave = if data then tonumber(data.LastSave) or 0 else 0
	return {
		state = tracker:state(now),
		idleSeconds = math.floor(tracker:idleFor(now)),
		autoRoll = data ~= nil and data.Settings.AutoRoll == true,
		fastRoll = data ~= nil and Formulas:hasFastRoll(data),
		rollInterval = if data then Formulas:rollCooldown(data) else nil,
		hide = data ~= nil and data.Settings.HideRollAnimation == true,
		lastSave = lastSave,
		secondsSinceSave = if lastSave > 0 then AfkService._time() - lastSave else nil,
		saves = stats,
		offlineProfile = PlayerDataService.IsOfflineProfile(player),
		jobId = if game.JobId ~= "" then game.JobId else "studio",
		session = {
			joinedAt = session.joinedAt,
			reconnect = session.reconnect,
			chain = session.chain,
			fromJobId = session.fromJobId,
			resume = session.resume,
			resumeReason = session.resumeReason,
			simulated = session.simulated,
		},
		loaded = data ~= nil,
	}
end

-- Só o estado INTERNO (nenhum input é gerado): testar UI, saves, AUTO, timers e telemetria
function AfkService.SimulateIdle(player: Player, seconds: number)
	local tracker = ensure(player)
	tracker:simulateIdle(AfkService._clock(), seconds)
	refreshState(player)
end

-- DEV: trata a sessão atual como se tivesse chegado por reconexão (Studio não teleporta).
-- Grava a preferência AUTO como viria do save e re-roda a regra de prontidão.
function AfkService.SimulateReconnect(player: Player, autoRoll: boolean?)
	local _, session = ensure(player)
	session.reconnect = true
	session.chain = math.max(session.chain, 1)
	session.simulated = true
	setAutoSetting(player, autoRoll ~= false)
	session.resume, session.resumeReason, session.resumeSince = "Pending", "simulated", AfkService._clock()
end

function AfkService.Init()
	Net.handle("ReportActivity", AfkService.ReportActivity)
end

function AfkService.Start()
	Players.PlayerAdded:Connect(function(player)
		ensure(player)
	end)
	PlayerDataService.Loaded:Connect(onLoaded)
	for _, player in Players:GetPlayers() do
		ensure(player)
		if PlayerDataService.IsLoaded(player) then
			onLoaded(player)
		end
	end
	Players.PlayerRemoving:Connect(function(player)
		trackers[player] = nil
		sessions[player] = nil
		lastState[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(1)
			AfkService._tick()
		end
	end)
end

return AfkService
