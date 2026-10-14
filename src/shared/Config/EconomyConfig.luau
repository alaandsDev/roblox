--!strict
-- Economia básica (ver ECONOMY.md).

return {
	-- Valor de venda = BaseIncome do personagem * SellSeconds da raridade
	SellSeconds = {
		Common = 12,
		Uncommon = 12,
		Rare = 15,
		Epic = 18,
		Legendary = 20,
		Mythic = 25,
		Divine = 30,
		Secret = 40,
	},
	-- Renda gerada a cada IncomeTick segundos (acumula no coletor da base)
	IncomeTick = 1,
	-- Teto do dinheiro não coletado = renda por segundo * MaxUncollectedSeconds (evita AFK infinito)
	MaxUncollectedSeconds = 60 * 60,
	CollectCooldown = 0.5,
	-- Reembolso, na VENDA, do investimento em níveis da unidade (SaleCore). 0 = jogo atual:
	-- venda = só o valor base. Análise e proposta em ECONOMY_BALANCE_ANALYSIS.md (não aplicada).
	UpgradeRefundPercent = 0,
}
