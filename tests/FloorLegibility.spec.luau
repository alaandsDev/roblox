-- Letreiros entre andares (FloorLegibility): renda > personagem > raridade/nível
local T = require("./TestLib")
local FloorLegibility = require("../src/shared/Modules/FloorLegibility")
local BaseConfig = require("../src/shared/Config/BaseConfig")
local describe, it, expect = T.describe, T.it, T.expect

local C = { FloorHeight = BaseConfig.FloorHeight, Tolerance = BaseConfig.FloorLegibility.Tolerance, IncomeMaxGap = BaseConfig.FloorLegibility.IncomeMaxGap }
local H = BaseConfig.FloorHeight

describe("FloorLegibility: andar do jogador × andar da estação", function()
	it("mesmo andar: pés no piso, subindo, pulando ou um pouco abaixo (borda/rampa)", function()
		for _, feet in { 0, 0.5, 6, H - C.Tolerance - 0.1, -C.Tolerance + 0.1 } do
			expect(FloorLegibility.gap(100 + feet, 100, C)).toBe(0)
		end
	end)

	it("andar de cima/baixo = 1; dois andares = 2 (vale para Floor01..Floor05, nada fixo no 02)", function()
		for floor = 1, BaseConfig.MaxFloors do
			local floorY = 10 + (floor - 1) * H
			expect(FloorLegibility.gap(floorY + H, floorY, C)).toBe(1)
			expect(FloorLegibility.gap(floorY - H, floorY, C)).toBe(1)
			expect(FloorLegibility.gap(floorY + 2 * H, floorY, C)).toBe(2)
		end
	end)

	it("sem personagem/sem andar: trata como mesmo andar (nunca esconde à toa)", function()
		expect(FloorLegibility.gap(nil, 100, C)).toBe(0)
		expect(FloorLegibility.gap(100, nil, C)).toBe(0)
	end)

	it("mesmo andar: tudo (Detail só de perto, como antes); vizinho: só a renda; 2+: nada", function()
		local near = FloorLegibility.view(1, 0, C)
		expect(near.detail and near.income and near.plate).toBeTruthy()
		local mid = FloorLegibility.view(2, 0, C)
		expect(not mid.detail and mid.income and mid.plate).toBeTruthy()
		for level = 1, 3 do
			local other = FloorLegibility.view(level, 1, C)
			expect(not other.detail and other.income and not other.plate).toBeTruthy()
			local far = FloorLegibility.view(level, 2, C)
			expect(not far.detail and not far.income and not far.plate).toBeTruthy()
		end
	end)
end)

return true
