local T = require("./TestLib")
local RateLimiter = require("../src/shared/Modules/RateLimiter")
local describe, it, expect = T.describe, T.it, T.expect

describe("RateLimiter", function()
	local now = 0
	local function clock()
		return now
	end

	it("permite até a capacidade e depois bloqueia", function()
		now = 0
		local limiter = RateLimiter.new(3, 1, clock)
		expect(limiter:allow("p1")).toBeTruthy()
		expect(limiter:allow("p1")).toBeTruthy()
		expect(limiter:allow("p1")).toBeTruthy()
		expect(limiter:allow("p1")).toBeFalsy()
	end)

	it("recarrega com o tempo", function()
		now = 0
		local limiter = RateLimiter.new(2, 1, clock)
		limiter:allow("p")
		limiter:allow("p")
		expect(limiter:allow("p")).toBeFalsy()
		now = 1
		expect(limiter:allow("p")).toBeTruthy()
		expect(limiter:allow("p")).toBeFalsy()
		now = 100
		expect(limiter:allow("p")).toBeTruthy()
		expect(limiter:allow("p")).toBeTruthy()
		expect(limiter:allow("p")).toBeFalsy() -- nunca passa da capacidade
	end)

	it("chaves são independentes e remove limpa", function()
		now = 0
		local limiter = RateLimiter.new(1, 0, clock)
		expect(limiter:allow("a")).toBeTruthy()
		expect(limiter:allow("b")).toBeTruthy()
		expect(limiter:allow("a")).toBeFalsy()
		limiter:remove("a")
		expect(limiter:allow("a")).toBeTruthy()
	end)

	it("relógio voltando no tempo não gera fichas extras", function()
		now = 10
		local limiter = RateLimiter.new(1, 1, clock)
		limiter:allow("p")
		now = 5
		expect(limiter:allow("p")).toBeFalsy()
	end)
end)

return true
