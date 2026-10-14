--!strict
--[[
	Nível individual de cada personagem (estação da base). Ver ECONOMY.md.

	Renda da unidade   = BaseIncome * (1 + (Level - 1) * IncomePerLevel) * Variant.IncomeMultiplier
	Custo do próximo   = BaseUpgradeCost * CostGrowth ^ (Level - 1)
	                     (BaseUpgradeCost do personagem; padrão BaseIncome * BaseCostSeconds)
	Custo de N níveis  = soma dos custos de cada nível (x1 / x5 / x10 / MAX, ver Formulas)
]]

return {
	-- Cap oficial (ECONOMY_BALANCE_ANALYSIS.md: o 31–50 nunca se pagava). Saves antigos acima disso
	-- são migrados (Migrations v4): nível vira 30 e o investimento histórico fica gravado em
	-- item.UpgradeInvestment (venda/fusão continuam reconhecendo o que foi pago).
	MaxLevel = 30,
	-- Maior nível que já existiu (antes da v4): só para recalcular investimento de saves antigos
	LegacyMaxLevel = 50,
	IncomePerLevel = 0.25,
	-- Gancho para as Torres (fase futura)
	PowerPerLevel = 0.10,
	BaseCostSeconds = 60,
	CostGrowth = 1.2,
	-- Só personagens equipados (na estação) podem ser melhorados
	RequireEquipped = true,
	-- Pisando no pad de upgrade: 1 nível a cada X segundos (segurar = vários níveis)
	PadRepeatInterval = 0.4,
	-- Quantidades aceitas no pedido (o servidor limita ao que dá para pagar / ao nível máximo)
	MaxBatch = 100,
}
