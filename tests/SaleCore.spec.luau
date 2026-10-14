-- SaleCore: venda = base + reembolso do investimento em níveis (nunca lucro, nunca negativo)
local T = require("./TestLib")
local SaleCore = require("../src/shared/Modules/SaleCore")
local Formulas = require("../src/shared/Modules/Formulas")
local CharacterConfig = require("../src/shared/Config/CharacterConfig")
local LevelConfig = require("../src/shared/Config/CharacterLevelConfig")
local VariantConfig = require("../src/shared/Config/VariantConfig")
local EconomyConfig = require("../src/shared/Config/EconomyConfig")
local describe, it, expect = T.describe, T.it, T.expect

local f = Formulas.new({
	Dice = require("../src/shared/Config/DiceConfig"),
	Upgrades = require("../src/shared/Config/UpgradeConfig"),
	Roll = require("../src/shared/Config/RollConfig"),
	Economy = EconomyConfig,
	Characters = CharacterConfig,
	Levels = LevelConfig,
	Variants = VariantConfig,
})

local MAX = LevelConfig.MaxLevel
local LEVELS = { 1, 2, 10, 20, 30, MAX }
local PERCENTS = { 0, 0.5, 0.6, 0.7, 0.75, 0.8, 1 }

-- soma independente da curva oficial: floor(base * growth^(L-1)) para L = 1..level-1
local function manualCurve(id: string, level: number): number
	local c = CharacterConfig.ById[id]
	local base = c.BaseUpgradeCost or c.BaseIncome * LevelConfig.BaseCostSeconds
	local total = 0
	for L = 1, level - 1 do
		total += math.floor(base * LevelConfig.CostGrowth ^ (L - 1))
	end
	return total
end

describe("SaleCore (venda com reembolso)", function()
	it("produção: refund 75% — total = base + floor(75% do investido); nível 1 = só a base", function()
		expect(EconomyConfig.UpgradeRefundPercent).toBe(0.75)
		for _, c in CharacterConfig.List do
			for _, v in VariantConfig.List do
				for _, level in LEVELS do
					local q = SaleCore.quote(f, { Id = c.Id, Variant = v.Id, Level = level }, EconomyConfig.UpgradeRefundPercent)
					local paid = manualCurve(c.Id, level)
					expect(q.Base).toBe(f:sellValue(c.Id, v.Id))
					expect(q.Invested).toBe(paid)
					expect(q.Refund).toBe(math.floor(paid * 0.75))
					expect(q.Total).toBe(q.Base + q.Refund)
					if level == 1 then
						expect(q.Total).toBe(q.Base)
					end
				end
			end
		end
	end)

	it("investimento acumulado = soma exata da curva oficial (níveis 1, 2, 10, 20, máx)", function()
		for _, c in CharacterConfig.List do
			for _, level in LEVELS do
				expect(SaleCore.curveInvestment(f, c.Id, level)).toBe(manualCurve(c.Id, level))
			end
			expect(SaleCore.curveInvestment(f, c.Id, 1)).toBe(0)
			expect(SaleCore.curveInvestment(f, c.Id, 2)).toBe(f:characterUpgradeCost(c.Id, 1, 1))
		end
	end)

	it("comprar níveis e vender NUNCA dá lucro (todas as raridades, variantes, níveis e %)", function()
		for _, c in CharacterConfig.List do
			for _, v in VariantConfig.List do
				for _, level in LEVELS do
					for _, r in PERCENTS do
						local q = SaleCore.quote(f, { Id = c.Id, Variant = v.Id, Level = level }, r)
						local paid = manualCurve(c.Id, level)
						expect(q.Invested).toBe(paid)
						expect(q.Refund <= paid).toBeTruthy()
						-- lucro do ciclo (subir níveis e vender) <= valor base que já existia sem níveis
						expect(q.Total - paid <= q.Base).toBeTruthy()
						expect(q.Total >= q.Base and q.Total >= 0).toBeTruthy()
					end
				end
			end
		end
	end)

	it("percentual inválido é limitado: >1 vira 100%, <0/NaN/texto viram 0", function()
		local item = { Id = CharacterConfig.List[1].Id, Level = 20 }
		local invested = SaleCore.curveInvestment(f, item.Id, 20)
		expect(SaleCore.quote(f, item, 5).Refund).toBe(invested)
		expect(SaleCore.quote(f, item, -1).Refund).toBe(0)
		expect(SaleCore.quote(f, item, 0 / 0).Refund).toBe(0)
		expect(SaleCore.quote(f, item, math.huge).Refund).toBe(0)
		expect(SaleCore.quote(f, item, "1" :: any).Refund).toBe(0)
	end)

	it("item inexistente / inválido vale 0; nível inválido não gera investimento negativo", function()
		expect(SaleCore.quote(f, nil, 1).Total).toBe(0)
		expect(SaleCore.quote(f, { Id = "nao_existe", Level = 30 }, 1).Total).toBe(0)
		local id = CharacterConfig.List[1].Id
		expect(SaleCore.quote(f, { Id = id, Level = -5 }, 1).Invested).toBe(0)
		expect(SaleCore.quote(f, { Id = id, Level = 0 / 0 }, 1).Invested).toBe(0)
		-- save antigo acima do cap (até o LegacyMaxLevel 50): investimento real daquele nível;
		-- acima disso é limitado (não inventa investimento)
		expect(SaleCore.quote(f, { Id = id, Level = 45 }, 1).Invested).toBe(manualCurve(id, 45))
		expect(SaleCore.quote(f, { Id = id, Level = 500 }, 1).Invested).toBe(manualCurve(id, LevelConfig.LegacyMaxLevel))
	end)

	it("investimento gravado por instância (B) vence a curva; negativo/NaN caem na curva (A)", function()
		local id = CharacterConfig.List[1].Id
		expect(SaleCore.invested(f, { Id = id, Level = 10, UpgradeInvestment = 1234 })).toBe(1234)
		expect(SaleCore.invested(f, { Id = id, Level = 10, UpgradeInvestment = -50 })).toBe(manualCurve(id, 10))
		expect(SaleCore.invested(f, { Id = id, Level = 10, UpgradeInvestment = 0 / 0 })).toBe(manualCurve(id, 10))
		-- duas instâncias do mesmo personagem: cada uma com o SEU investimento
		local a = SaleCore.quote(f, { Id = id, Level = 10, UpgradeInvestment = 100 }, 1)
		local b = SaleCore.quote(f, { Id = id, Level = 10, UpgradeInvestment = 900 }, 1)
		expect(a.Refund).toBe(100)
		expect(b.Refund).toBe(900)
	end)
end)

return true
