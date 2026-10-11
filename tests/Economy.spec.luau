-- Regressão de balanceamento: a progressão não pode "quebrar" (ver ECONOMY.md)
local T = require("./TestLib")
local EconomySim = require("../tools/sim/EconomySim")
local UpgradeConfig = require("../src/shared/Config/UpgradeConfig")
local describe, it, expect = T.describe, T.it, T.expect

local function maxed(snapshot: any): number
	local n = 0
	for _, u in UpgradeConfig.List do
		if (snapshot.upgrades[u.Id] or 0) >= u.MaxLevel then
			n += 1
		end
	end
	return n
end

describe("Economia (simulação com as configs reais)", function()
	local hardcore = EconomySim.run(EconomySim.Profiles.Hardcore, 7200, 7, { 300, 3600, 7200 })
	local ativo = EconomySim.run(EconomySim.Profiles.Ativo, 7200, 11, { 300, 3600, 7200 })

	it("5 min (Hardcore): nada maximizado, no máximo o 3º dado", function()
		local s = hardcore[1]
		expect(maxed(s)).toBe(0)
		for _, u in UpgradeConfig.List do
			expect((s.upgrades[u.Id] or 0) < 10).toBeTruthy()
		end
		expect(s.dice == "Normal" or s.dice == "Lucky" or s.dice == "Flame").toBeTruthy()
		expect(s.avgStationLevel < 10).toBeTruthy()
	end)

	it("2 h (Ativo): ainda há o que comprar (sem Celestial, upgrades não todos no máximo)", function()
		local s = ativo[3]
		expect(s.dice ~= "Celestial").toBeTruthy()
		expect(maxed(s) < #UpgradeConfig.List).toBeTruthy()
	end)

	it("torres e renascimento: progressão longa (Vazio não é concluído em 2 h; renasce no máximo poucas vezes)", function()
		for _, s in { ativo[3], hardcore[3] } do
			expect(s.towerFloors < 120).toBeTruthy()
			expect(s.rebirths >= 1 and s.rebirths <= 6).toBeTruthy()
		end
		expect(hardcore[1].rebirths).toBe(0)
	end)

	it("8 h offline <= 1 h de renda passiva jogando ativo (no mesmo ponto do jogo)", function()
		for _, s in { ativo[2], ativo[3], hardcore[2] } do
			expect(EconomySim.offline(s.income) <= s.income * 3600).toBeTruthy()
		end
	end)
end)

return true
