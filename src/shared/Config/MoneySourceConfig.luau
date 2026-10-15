--!strict
--[[
	Origem de TODA entrada de dinheiro (EconomyService.AddMoney). Fonte ÚNICA da classificação
	do LifetimeMoneyGenerated / Ranking Magnata (MAGNATE_RANKING_AUDIT.md §2–3):
	    GENERATED  produzida pelo jogo para a conta (renda/jogo)  -> CONTA no Lifetime
	    RECYCLED   item virando dinheiro (venda)                  -> não conta
	    REFUND     devolução do que o jogador pagou               -> não conta
	    TRANSFER   veio de outro jogador                          -> não conta
	    OTHER      Robux direto, Jackpot (gemas podem vir de Robux), DEV/admin -> não conta
	Origem desconhecida: AddMoney FALHA (nenhum sistema novo escapa da classificação; o teste
	tests/money_sources_test.py confere toda chamada do servidor contra esta tabela).
	Multiplicadores sobre gameplay legítimo (VIP, Player Aura, Rebirth, perk) já estão DENTRO do
	valor produzido: o valor FINAL conta uma vez. Dinheiro comprado direto (Product) não conta.
]]

return {
	Sources = {
		Collector = "GENERATED", -- renda das estações (coletor da base)
		Offline = "GENERATED", -- renda offline
		Tower = "GENERATED", -- 1ª vitória de cada andar
		Mission = "GENERATED", -- missões
		Daily = "GENERATED", -- recompensa diária
		Sell = "RECYCLED", -- venda (valor-base + parte do investimento)
		AutoSell = "RECYCLED", -- venda automática no roll
		Refund = "REFUND", -- reservado: devolução separada
		Trade = "TRANSFER", -- reservado: hoje as trocas NÃO movem dinheiro
		Jackpot = "OTHER", -- prêmio do Jackpot (gemas podem vir de Robux)
		Product = "OTHER", -- pacotes de dinheiro em Robux
		Admin = "OTHER", -- compensação administrativa (não existe hoje)
		Dev = "OTHER", -- comandos DEV (só Studio)
	} :: { [string]: string },
	-- teto de UMA entrada e do total (bem acima de qualquer valor real; protege contra bug/overflow)
	MaxGrant = 1e18,
	MaxLifetime = 1e24,
	-- ids de operação lembrados no save (idempotência de grants com opId)
	OpHistory = 100,
}
