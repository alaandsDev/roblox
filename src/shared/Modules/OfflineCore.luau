--!strict
--[[
	Dinheiro offline (puro). O SERVIDOR chama com o próprio relógio (os.time()):
	    local amount, seconds, reason = OfflineCore.compute(lastLogout, now, incomePerSecond, config)
	reason: "ok" | "no_logout" | "invalid" | "future" | "too_short" | "no_income"
	Nunca devolve negativo, NaN ou infinito.
]]

local OfflineCore = {}

local function finite(n: any): boolean
	return type(n) == "number" and n == n and n ~= math.huge and n ~= -math.huge
end

function OfflineCore.compute(lastLogout: any, now: any, incomePerSecond: any, config: any): (number, number, string)
	if not finite(now) or not finite(lastLogout) or not finite(incomePerSecond) then
		return 0, 0, "invalid"
	end
	if lastLogout <= 0 then
		return 0, 0, "no_logout"
	end
	local elapsed = now - lastLogout
	if elapsed < -config.ClockSkewTolerance then
		return 0, 0, "future"
	end
	if elapsed < config.MinSeconds then
		return 0, 0, "too_short"
	end
	if incomePerSecond <= 0 then
		return 0, 0, "no_income"
	end
	local seconds = math.min(elapsed, config.MaxSeconds)
	local amount = math.floor(incomePerSecond * seconds * config.Multiplier)
	if amount < config.MinAmount then
		return 0, seconds, "no_income"
	end
	return amount, seconds, "ok"
end

return OfflineCore
