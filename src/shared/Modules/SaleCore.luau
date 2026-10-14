--!strict
--[[
	SaleCore (puro): preço de venda de UMA unidade com reembolso do investimento em níveis.

	    Total = Base + Reembolso
	    Base       = Formulas:sellValue(Id, Variant)            (BaseIncome * SellSeconds * variante)
	    Investido  = investimento ELEGÍVEL em níveis da unidade (ver abaixo)
	    Reembolso  = floor(Investido * Percent),  Percent em [0, 1]

	Investimento elegível (POLÍTICA — ver DATA_SCHEMA.md "UpgradeInvestment"):
	    (B) item.UpgradeInvestment — gravado SÓ pelo servidor, por instância:
	          upgrade : += custo efetivamente cobrado (InventoryService.UpgradeCharacter)
	          fusão   : unidade NOVA recebe a soma do investimento das consumidas (que somem)
	          troca   : viaja com a instância (TradeCore copia o campo)
	    (A) campo ausente/inválido (save antigo) -> soma exata da curva oficial do nível 1 ao Level
	        (Migrations v4 grava (A) em todos os saves; o fallback fica só como rede de segurança).
	EconomyConfig.UpgradeRefundPercent = 0.75.

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
	-- saves antigos podem ter nível acima do cap atual (até LegacyMaxLevel): investimento real
	local levels = formulas.c.Levels
	local maxLevel = math.max(levels.MaxLevel, levels.LegacyMaxLevel or levels.MaxLevel)
	local lvl = math.clamp(math.floor(level), 1, maxLevel)
	if lvl <= 1 then
		return 0
	end
	return SaleCore.curveCost(formulas, characterId, 1, lvl)
end

-- Custo da curva oficial para ir de `fromLevel` até `toLevel` (sem o limite do MaxLevel atual)
function SaleCore.curveCost(formulas: any, characterId: string, fromLevel: number, toLevel: number): number
	local character = formulas.c.Characters.ById[characterId]
	if not character or toLevel <= fromLevel then
		return 0
	end
	local levels = formulas.c.Levels
	local baseCost = character.BaseUpgradeCost or character.BaseIncome * levels.BaseCostSeconds
	local total = 0
	for l = fromLevel, toLevel - 1 do
		total += math.floor(baseCost * levels.CostGrowth ^ (l - 1))
	end
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
