--!strict
--[[
	ReconnectPolicy (puro): decide SE e COMO tentar voltar depois que a sessão cai.
	Só APIs oficiais (o ReconnectController chama TeleportService); nunca input falso, nunca
	contornar o timeout de inatividade da plataforma.

	    ReconnectPolicy.classify("DisconnectConnectionLost") -> "Auto" | "Manual" | "Never"
	    local plan = ReconnectPolicy.new(AfkConfig.Reconnect, { kind = "Auto", jobId = game.JobId, chain = 0 })
	    plan:next(now)        -> { action = "SameServer" | "AnyServer" | "Manual" | "Stop", at, attempt }
	    plan:failed("GameEnded")   (TeleportInitFailed) -> o mesmo servidor não é tentado de novo
	    plan:manual(now)      -> clique em RECONECTAR (input real): limitado e com intervalo

	MESMO servidor: só na 1ª tentativa, só se a queda não indica servidor fechando, e NUNCA é
	prometido (o JobId pode não existir mais: a falha cai para "qualquer servidor do place").
	Limites: MaxAttempts automáticas, MaxManual cliques, MaxChain reconexões encadeadas (sem loop).
]]

local ReconnectPolicy = {}
ReconnectPolicy.__index = ReconnectPolicy

export type Kind = "Auto" | "Manual" | "Never"
export type Action = "SameServer" | "AnyServer" | "Manual" | "Wait" | "Stop"
export type Step = { action: Action, at: number, attempt: number, reason: string? }

-- Quedas em que o jogo NÃO tenta voltar sozinho (nomes de Enum.ConnectionError)
local NEVER: { [string]: string } = {
	-- regra de inatividade da PLATAFORMA (~20 min sem input): respeitada, nunca contornada
	DisconnectIdle = "platform_idle",
	-- o próprio jogo expulsou (save travado/indisponível, versão nova do save...): voltar em loop pioraria
	DisconnectLuaKick = "game_kick",
	-- a mesma conta entrou em outro lugar
	DisconnectDuplicatePlayer = "duplicate",
	DisconnectDuplicateTicket = "duplicate",
	-- o jogador saiu / segurança / versão
	DisconnectClientRequest = "left",
	DisconnectBySecurityPolicy = "security",
	DisconnectBlockedIP = "security",
	DisconnectSecurityKeyMismatch = "security",
	DisconnectNewSecurityKeyMismatch = "security",
	DisconnectBadhash = "security",
	DisconnectIllegalTeleport = "security",
	DisconnectProtocolMismatch = "version",
	DisconnectWrongVersion = "version",
	DisconnectCloudEditKick = "studio",
	-- manutenção da plataforma: não martelar
	DisconnectRobloxMaintenance = "maintenance",
}

-- Quedas de rede / servidor fechando: tentativa automática (limitada)
local AUTO: { [string]: boolean } = {
	DisconnectConnectionLost = true,
	DisconnectTimeout = true,
	DisconnectHashTimeout = true,
	DisconnectReceivePacketError = true,
	DisconnectReceivePacketStreamError = true,
	DisconnectSendPacketError = true,
	DisconnectRaknetErrors = true,
	DisconnectErrors = true,
	DisconnectOnRemoteSysStats = true,
	-- servidor encerrado (atualização do jogo / servidor desligando): só "qualquer servidor"
	DisconnectEvicted = true,
	DisconnectDevMaintenance = true,
	DisconnectPlayerless = true,
}

-- Quedas em que o servidor antigo com certeza acabou (não adianta tentar o mesmo JobId)
local SERVER_GONE: { [string]: boolean } = {
	DisconnectEvicted = true,
	DisconnectDevMaintenance = true,
	DisconnectPlayerless = true,
}

-- Falhas de teleporte (Enum.TeleportResult) em que parar é o certo
local TELEPORT_STOP: { [string]: boolean } = {
	Unauthorized = true,
}

function ReconnectPolicy.classify(code: string?): (string, string)
	if type(code) ~= "string" then
		return "Manual", "unknown"
	end
	local never = NEVER[code]
	if never then
		return "Never", never
	end
	if AUTO[code] then
		return "Auto", if SERVER_GONE[code] then "server_gone" else "network"
	end
	return "Manual", "unknown"
end

export type Options = {
	kind: string, -- Kind
	code: string?,
	jobId: string?,
	-- reconexões automáticas que já trouxeram o jogador até aqui (TeleportData)
	chain: number?,
}

function ReconnectPolicy.new(config: any, options: Options)
	local kind = options.kind
	local chain = options.chain or 0
	local autoAllowed = kind == "Auto" and chain < config.MaxChain
	local sameServer = autoAllowed
		and type(options.jobId) == "string"
		and options.jobId ~= ""
		and not (options.code ~= nil and SERVER_GONE[options.code :: string])
	return setmetatable({
		config = config,
		kind = kind,
		chain = chain,
		autoAllowed = autoAllowed,
		sameServer = sameServer,
		attempts = 0, -- automáticas já feitas
		manualUsed = 0,
		lastManual = -math.huge,
		lastAt = nil :: number?,
		stopped = false,
		stopReason = nil :: string?,
	}, ReconnectPolicy)
end

-- Próximo passo automático (e já o registra). "Manual" = mostrar o botão RECONECTAR.
function ReconnectPolicy.next(self: any, now: number): Step
	if self.stopped or self.kind == "Never" then
		return { action = "Stop", at = now, attempt = self.attempts, reason = self.stopReason or "never" }
	end
	if not self.autoAllowed then
		return {
			action = "Manual",
			at = now,
			attempt = self.attempts,
			reason = if self.kind == "Auto" then "chain_limit" else "unknown_disconnect",
		}
	end
	if self.attempts >= self.config.MaxAttempts then
		return { action = "Manual", at = now, attempt = self.attempts, reason = "attempts_exhausted" }
	end
	self.attempts += 1
	local wait = self.config.Backoff[self.attempts] or self.config.Backoff[#self.config.Backoff]
	local at = math.max(now, (self.lastAt or now)) + wait
	self.lastAt = at
	local action: Action = if self.attempts == 1 and self.sameServer then "SameServer" else "AnyServer"
	return { action = action, at = at, attempt = self.attempts }
end

-- TeleportInitFailed (ou erro ao chamar o teleporte): o mesmo servidor sai da lista
function ReconnectPolicy.failed(self: any, result: string?)
	self.sameServer = false
	if result and TELEPORT_STOP[result] then
		self.stopped = true
		self.stopReason = "teleport_" .. result
	end
end

-- Clique em RECONECTAR (input real). Limitado por MaxManual e ManualCooldown.
function ReconnectPolicy.manual(self: any, now: number): Step
	if self.stopped or self.kind == "Never" then
		return { action = "Stop", at = now, attempt = self.attempts, reason = self.stopReason or "never" }
	end
	if self.manualUsed >= self.config.MaxManual then
		return { action = "Stop", at = now, attempt = self.attempts, reason = "manual_exhausted" }
	end
	local ready = self.lastManual + self.config.ManualCooldown
	if now < ready then
		return { action = "Wait", at = ready, attempt = self.attempts }
	end
	self.manualUsed += 1
	self.lastManual = now
	return { action = "AnyServer", at = now, attempt = self.attempts + self.manualUsed }
end

-- TeleportData levado para o servidor novo (o servidor só usa como DICA de preferência:
-- vem do cliente, nunca vale dinheiro/roll)
function ReconnectPolicy.teleportData(self: any, nowUnix: number, jobId: string?): { [string]: any }
	return { Reconnect = true, Chain = self.chain + 1, FromJobId = jobId or "", At = nowUnix }
end

-- Quantas reconexões automáticas seguidas trouxeram o jogador (0 = entrada normal)
function ReconnectPolicy.chainFrom(data: any, nowUnix: number, config: any): number
	if type(data) ~= "table" or data.Reconnect ~= true then
		return 0
	end
	local chain, at = data.Chain, data.At
	if type(chain) ~= "number" or type(at) ~= "number" or chain ~= chain then
		return 0
	end
	if nowUnix - at > config.ChainWindow or nowUnix - at < -120 then
		return 0
	end
	return math.clamp(math.floor(chain), 0, 1000)
end

export type ResumeInput = {
	autoSetting: boolean,
	reconnect: boolean,
	secondsSinceLogout: number?,
	window: number,
	dataLoaded: boolean,
	baseReady: boolean,
	characterReady: boolean,
	servicesReady: boolean,
}

-- AUTO depois de reconectar: "Resume" | "Wait" (ainda carregando) | "No"
function ReconnectPolicy.resumeAuto(input: ResumeInput): (string, string)
	if not input.reconnect then
		return "No", "not_reconnect"
	end
	if not input.autoSetting then
		return "No", "auto_off"
	end
	local since = input.secondsSinceLogout
	if type(since) ~= "number" or since ~= since or since < -120 or since > input.window then
		return "No", "too_old"
	end
	if not input.dataLoaded then
		return "Wait", "data"
	end
	if not input.baseReady then
		return "Wait", "base"
	end
	if not input.characterReady then
		return "Wait", "character"
	end
	if not input.servicesReady then
		return "Wait", "services"
	end
	return "Resume", "ok"
end

return ReconnectPolicy
