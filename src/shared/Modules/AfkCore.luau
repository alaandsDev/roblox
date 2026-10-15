--!strict
--[[
	AfkCore (puro): estado de inatividade de UM jogador, só para UX/telemetria.
	    local t = AfkCore.new(AfkConfig, now)
	    t:activity(now)              -- input REAL reportado pelo cliente (ou entrada no jogo)
	    t:simulateIdle(now, 1200)    -- DEV/testes: só o estado interno (nenhum input é gerado)
	    t:state(now)                 -- "Active" | "Idle" | "Reconnecting"
	Nunca é usado para gerar input, e nenhuma fórmula de jogo lê este estado.
]]

local AfkCore = {}
AfkCore.__index = AfkCore

export type State = "Active" | "Idle" | "Reconnecting"

export type Tracker = typeof(setmetatable(
	{} :: { idleAfter: number, lastActivity: number, reconnecting: boolean, idleSince: number? },
	AfkCore
))

function AfkCore.new(config: { IdleAfter: number }, now: number): Tracker
	return setmetatable({ idleAfter = config.IdleAfter, lastActivity = now, reconnecting = false, idleSince = nil }, AfkCore)
end

function AfkCore.activity(self: Tracker, now: number)
	-- relógio voltando (ou repetido) nunca "rejuvenesce" para o futuro
	if now > self.lastActivity then
		self.lastActivity = now
	end
	self.reconnecting = false
end

function AfkCore.simulateIdle(self: Tracker, now: number, seconds: number)
	self.lastActivity = now - math.max(0, seconds)
end

function AfkCore.idleFor(self: Tracker, now: number): number
	return math.max(0, now - self.lastActivity)
end

function AfkCore.setReconnecting(self: Tracker, on: boolean)
	self.reconnecting = on
end

function AfkCore.state(self: Tracker, now: number): State
	if self.reconnecting then
		return "Reconnecting"
	end
	return if AfkCore.idleFor(self, now) >= self.idleAfter then "Idle" else "Active"
end

return AfkCore
