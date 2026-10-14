--!strict
-- Economia básica (ver ECONOMY.md).

return {
	-- Valor de venda = BaseIncome do personagem * SellSeconds da raridade
	-- (balanceamento aplicado: era 12/12/15/18/20/25/30/40 — duplicatas valiam quase nada)
	SellSeconds = {
		Common = 20,
		Uncommon = 20,
		Rare = 25,
		Epic = 30,
		Legendary = 35,
		Mythic = 45,
		Divine = 60,
		Secret = 90,
	},
	-- Renda gerada a cada IncomeTick segundos (acumula no coletor da base)
	IncomeTick = 1,
	-- Teto do dinheiro não coletado = renda por segundo * MaxUncollectedSeconds (evita AFK infinito)
	MaxUncollectedSeconds = 60 * 60,
	CollectCooldown = 0.5,
	-- Reembolso, na VENDA, do investimento em níveis gravado na própria unidade (SaleCore):
	-- venda = valor base + 75% do investido. Nunca dá lucro (25% fica como sink). Ver
	-- ECONOMY_BALANCE_ANALYSIS.md e DATA_SCHEMA.md (UpgradeInvestment).
	UpgradeRefundPercent = 0.75,
}
