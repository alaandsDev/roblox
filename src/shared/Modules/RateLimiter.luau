--!strict
-- Rate limiter "token bucket" por chave (ex.: um balde por jogador+remote).
-- Cada chave começa com "capacity" fichas; cada ação gasta 1; as fichas voltam
-- a "refillPerSecond". Módulo puro: o relógio pode ser injetado nos testes.

local RateLimiter = {}
RateLimiter.__index = RateLimiter

type Bucket = { tokens: number, updated: number }

export type RateLimiter = typeof(setmetatable(
	{} :: {
		capacity: number,
		refill: number,
		clock: () -> number,
		buckets: { [any]: Bucket },
	},
	RateLimiter
))

function RateLimiter.new(capacity: number, refillPerSecond: number, clock: (() -> number)?): RateLimiter
	assert(capacity > 0 and refillPerSecond >= 0, "RateLimiter: parâmetros inválidos")
	return setmetatable({
		capacity = capacity,
		refill = refillPerSecond,
		clock = clock or os.clock,
		buckets = {},
	}, RateLimiter)
end

-- Retorna true se a ação é permitida (e consome uma ficha).
function RateLimiter.allow(self: RateLimiter, key: any): boolean
	local now = self.clock()
	local bucket = self.buckets[key]
	if not bucket then
		bucket = { tokens = self.capacity, updated = now }
		self.buckets[key] = bucket
	else
		local elapsed = math.max(0, now - bucket.updated)
		bucket.tokens = math.min(self.capacity, bucket.tokens + elapsed * self.refill)
		bucket.updated = now
	end
	if bucket.tokens >= 1 then
		bucket.tokens -= 1
		return true
	end
	return false
end

-- Libera a memória de uma chave (ex.: quando o jogador sai).
function RateLimiter.remove(self: RateLimiter, key: any)
	self.buckets[key] = nil
end

-- Remove todas as chaves que satisfazem o filtro (ex.: todas de um jogador).
function RateLimiter.removeWhere(self: RateLimiter, predicate: (key: any) -> boolean)
	for key in self.buckets do
		if predicate(key) then
			self.buckets[key] = nil
		end
	end
end

return RateLimiter
