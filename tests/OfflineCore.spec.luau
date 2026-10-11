local T = require("./TestLib")
local OfflineCore = require("../src/shared/Modules/OfflineCore")
local Config = require("../src/shared/Config/OfflineIncomeConfig")
local describe, it, expect = T.describe, T.it, T.expect

local NOW = 1_800_000_000

describe("Dinheiro offline", function()
	it("0 segundos: nada", function()
		local amount, _, reason = OfflineCore.compute(NOW, NOW, 100, Config)
		expect(amount).toBe(0)
		expect(reason).toBe("too_short")
	end)

	local M = Config.Multiplier

	it("limite de 8 h e multiplicador configurados", function()
		expect(Config.MaxSeconds).toBe(28800)
		expect(M > 0 and M <= 1).toBeTruthy()
	end)

	it("1 minuto: renda * 60 * multiplicador", function()
		local amount, seconds = OfflineCore.compute(NOW - 60, NOW, 100, Config)
		expect(seconds).toBe(60)
		expect(amount).toBe(math.floor(100 * 60 * M))
	end)

	it("1 hora", function()
		expect((OfflineCore.compute(NOW - 3600, NOW, 100, Config))).toBe(math.floor(100 * 3600 * M))
	end)

	it("8 horas", function()
		expect((OfflineCore.compute(NOW - 8 * 3600, NOW, 100, Config))).toBe(math.floor(100 * 8 * 3600 * M))
	end)

	it("24 horas é limitado a 8 horas", function()
		local amount, seconds = OfflineCore.compute(NOW - 24 * 3600, NOW, 100, Config)
		expect(seconds).toBe(Config.MaxSeconds)
		expect(amount).toBe(math.floor(100 * Config.MaxSeconds * M))
	end)

	it("timestamp no futuro: nada", function()
		local amount, _, reason = OfflineCore.compute(NOW + 3600, NOW, 100, Config)
		expect(amount).toBe(0)
		expect(reason).toBe("future")
	end)

	it("timestamps inválidos (NaN, infinito, texto, nil, 0)", function()
		for _, bad in { 0 / 0, math.huge, -math.huge, "123", nil } do
			local amount = OfflineCore.compute(bad, NOW, 100, Config)
			expect(amount).toBe(0)
		end
		expect((OfflineCore.compute(0, NOW, 100, Config))).toBe(0)
		expect((OfflineCore.compute(NOW - 100, 0 / 0, 100, Config))).toBe(0)
		expect((OfflineCore.compute(NOW - 100, NOW, 0 / 0, Config))).toBe(0)
	end)

	it("renda zero ou negativa: nada", function()
		expect((OfflineCore.compute(NOW - 3600, NOW, 0, Config))).toBe(0)
		expect((OfflineCore.compute(NOW - 3600, NOW, -50, Config))).toBe(0)
	end)
end)

return true
