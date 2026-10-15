--!strict
--[[
	AutoHideTimer (puro): "some depois de N segundos sem atividade".
	    local t = AutoHideTimer.new(20)
	    t:bump(now)        -- atividade (ex.: novo roll): volta a contar do zero
	    t:visible(now)     -- true enquanto now - última atividade < N
	Sem relógio próprio (o chamador passa o tempo): testável de forma determinística
	(tests/AutoHideTimer.spec.luau). Usado pela faixa RECENT ROLLS (RollController).
]]

local AutoHideTimer = {}
AutoHideTimer.__index = AutoHideTimer

export type Timer = { seconds: number, lastAt: number? }

function AutoHideTimer.new(seconds: number): any
	return setmetatable({ seconds = seconds, lastAt = nil }, AutoHideTimer)
end

function AutoHideTimer:bump(now: number)
	self.lastAt = now
end

function AutoHideTimer:visible(now: number): boolean
	local last = self.lastAt
	return last ~= nil and now - last < self.seconds
end

-- segundos até esconder (0 = já escondido / nunca houve atividade)
function AutoHideTimer:remaining(now: number): number
	local last = self.lastAt
	if last == nil then
		return 0
	end
	return math.max(0, self.seconds - (now - last))
end

return AutoHideTimer
