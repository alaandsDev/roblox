--!strict
-- Sorteio do Jackpot (puro). pick(rewards, rand) -> prêmio; chances(rewards) -> { [id] = 0..1 }
local JackpotCore = {}

function JackpotCore.pick(rewards: { any }, rand: () -> number): any
	local total = 0
	for _, r in rewards do
		total += r.Weight
	end
	local target = rand() * total
	for _, r in rewards do
		if target < r.Weight then
			return r
		end
		target -= r.Weight
	end
	return rewards[#rewards]
end

function JackpotCore.chances(rewards: { any }): { [string]: number }
	local total = 0
	for _, r in rewards do
		total += r.Weight
	end
	local out = {}
	for _, r in rewards do
		out[r.Id] = r.Weight / total
	end
	return out
end

-- Boost de sorte: o maior multiplicador vence; mesmo valor soma tempo (mesma regra do Diário)
function JackpotCore.mergeBoost(current: any, multiplier: number, duration: number, now: number): any
	local active = type(current) == "table" and type(current.ExpiresAt) == "number" and current.ExpiresAt > now
	if active and current.Multiplier == multiplier then
		return { Multiplier = multiplier, ExpiresAt = current.ExpiresAt + duration }
	elseif active and current.Multiplier > multiplier then
		return { Multiplier = current.Multiplier, ExpiresAt = math.max(current.ExpiresAt, now + duration) }
	end
	return { Multiplier = multiplier, ExpiresAt = now + duration }
end

return JackpotCore
