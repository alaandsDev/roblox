--!strict
--[[
	SaleCore (puro): preço de venda de UMA unidade com reembolso do investimento em níveis.

	    Total = Base + Reembolso
	    Base       = Formulas:sellValue(Id, Variant)            (BaseIncome * SellSeconds * variante)
	    Investido  = investimento ELEGÍVEL em níveis da unidade (ver abaixo)
	    Reembolso  = floor(Investido * Percent),  Percent em [0, 1]

	Investimento elegível:
	    (B) item.UpgradeInvestment — gravado pelo SERVIDOR por instância, se for número finito >= 0;
	    (A) senão, recalculado pela curva oficial: soma de characterUpgradeCost do nível 1 ao Level.
	O jogo atual NÃO grava (B) e usa EconomyConfig.UpgradeRefundPercent = 0, então
	Total == sellValue (venda idêntica à anterior). Ver ECONOMY_BALANCE_ANALYSIS.md.

	Garantias (tests/SaleCore.spec.luau): nunca negativo; Percent fora de [0,1] / NaN / não
	número é limitado; Reembolso <= Investido, logo comprar níveis e vender nunca dá lucro:
	    Total - Investido = Base - (1 - Percent) * Investido <= Base.
]]

export type Quote = {
	Base: number,
	Invested: number,
	Percent: number,
	Refund: number,
	Total: number,
}

local SaleCore = {}

local function finite(x: any): boolean
	return type(x) == "number" and x == x and x ~= math.huge and x ~= -math.huge
end

function SaleCore.percent(value: any): number
	if not finite(value) then
		return 0
	end
	return math.clamp(value, 0, 1)
end

-- Soma exata da curva oficial do nível 1 até `level` (0 no nível 1 ou inválido)
function SaleCore.curveInvestment(formulas: any, characterId: string, level: any): number
	if not finite(level) then
		return 0
	end
	local maxLevel = formulas.c.Levels.MaxLevel
	local lvl = math.clamp(math.floor(level), 1, maxLevel)
	if lvl <= 1 then
		return 0
	end
	local total = formulas:characterUpgradeCost(characterId, 1, lvl - 1)
	return total
end

function SaleCore.invested(formulas: any, item: any): number
	if type(item) ~= "table" or type(item.Id) ~= "string" then
		return 0
	end
	local stored = item.UpgradeInvestment
	if finite(stored) and stored >= 0 then
		return math.floor(stored)
	end
	return SaleCore.curveInvestment(formulas, item.Id, item.Level)
end

function SaleCore.quote(formulas: any, item: any, percent: any): Quote
	if type(item) ~= "table" or type(item.Id) ~= "string" then
		return { Base = 0, Invested = 0, Percent = 0, Refund = 0, Total = 0 }
	end
	local base = math.max(0, formulas:sellValue(item.Id, item.Variant))
	local invested = SaleCore.invested(formulas, item)
	local p = SaleCore.percent(percent)
	local refund = math.max(0, math.floor(invested * p))
	return { Base = base, Invested = invested, Percent = p, Refund = refund, Total = base + refund }
end

return SaleCore
