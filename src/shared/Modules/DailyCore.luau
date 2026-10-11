--!strict
--[[
	Recompensas diárias (puro). Estado salvo no perfil:
	    LastDailyClaim (os.time do servidor), DailyStreak, DailyCycleDay (último dia resgatado, 0..7)
	Dia do calendário = floor(tempo / DayLength) (UTC).

	DailyCore.status(state, now, config) -> { canClaim, day, reset, nextClaimAt }
	DailyCore.claim(state, now, config)  -> (novoEstado?, dia?, erro?)
]]

local DailyCore = {}

local function finite(n: any): boolean
	return type(n) == "number" and n == n and n ~= math.huge and n ~= -math.huge
end

local function sanitize(state: any): (number, number, number)
	local last = if finite(state.LastDailyClaim) and state.LastDailyClaim >= 0 then state.LastDailyClaim else 0
	local streak = if finite(state.DailyStreak) and state.DailyStreak >= 0 then math.floor(state.DailyStreak) else 0
	local cycle = if finite(state.DailyCycleDay) then math.clamp(math.floor(state.DailyCycleDay), 0, 7) else 0
	return last, streak, cycle
end

export type Status = { canClaim: boolean, day: number, reset: boolean, nextClaimAt: number, corrupted: boolean }

function DailyCore.status(state: any, now: number, config: any): Status
	local last, _, cycle = sanitize(state)
	local length = config.DayLength
	local today = math.floor(now / length)
	local cycleSize = #config.Rewards
	if last <= 0 then
		return { canClaim = true, day = 1, reset = false, nextClaimAt = now, corrupted = false }
	end
	local lastDay = math.floor(last / length)
	if lastDay > today then
		-- Último resgate "no futuro" (relógio alterado / dado corrompido): recomeça do Dia 1 hoje
		return { canClaim = true, day = 1, reset = true, nextClaimAt = now, corrupted = true }
	end
	if lastDay == today then
		local nextDay = if cycle >= cycleSize then 1 else cycle + 1
		return { canClaim = false, day = nextDay, reset = false, nextClaimAt = (today + 1) * length, corrupted = false }
	end
	if lastDay == today - 1 then
		local nextDay = if cycle >= cycleSize then 1 else cycle + 1
		return { canClaim = true, day = nextDay, reset = false, nextClaimAt = now, corrupted = false }
	end
	-- Perdeu pelo menos um dia inteiro: volta ao Dia 1
	return { canClaim = true, day = 1, reset = true, nextClaimAt = now, corrupted = false }
end

function DailyCore.claim(state: any, now: number, config: any): (any, number?, string?)
	if not finite(now) or now <= 0 then
		return nil, nil, "invalid_time"
	end
	local status = DailyCore.status(state, now, config)
	if not status.canClaim then
		return nil, nil, "already_claimed"
	end
	local _, streak = sanitize(state)
	local newState = {
		LastDailyClaim = now,
		DailyStreak = if status.reset then 1 else streak + 1,
		DailyCycleDay = status.day,
	}
	return newState, status.day, nil
end

return DailyCore
