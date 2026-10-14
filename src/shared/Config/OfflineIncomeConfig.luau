--!strict
--[[
	Dinheiro offline (ver ECONOMY.md):
	    OfflineIncome = LastKnownIncomePerSecond * min(OfflineSeconds, MaxSeconds) * Multiplier
	Tempo sempre pelo relógio do SERVIDOR (os.time). Timestamps inválidos/futuros = nada.
]]

return {
	MaxSeconds = 8 * 60 * 60,
	-- 12%: 8 h offline ≈ 1 h de renda passiva ativa. Com 50% (sugestão inicial), 8 h pagavam
	-- ~2,3x tudo que um jogador ativo ganha em 2 h e pulavam a progressão (ver ECONOMY.md).
	Multiplier = 0.12,
	-- Menos que isso fora do jogo não gera recompensa (evita popup a cada reconexão)
	MinSeconds = 60,
	-- Teto extra (auditoria): o dinheiro offline nunca passa desta fração do custo do PRÓXIMO
	-- renascimento — voltar do offline não compra renascimentos de uma vez
	-- 50% -> 25% (auditoria: 68% da renda do Casual vinha do offline)
	MaxRebirthFraction = 0.25,
	MinAmount = 1,
	-- Folga para relógios de servidores diferentes
	ClockSkewTolerance = 120,
}
