--!strict
--[[
	👑 RANKING MAGNATA (MAGNATE_RANKING_AUDIT.md). Métrica: LifetimeMoneyGenerated (riqueza
	GERADA desde a ativação; nunca o saldo Money). TEMPORADA 1: todo save começa em 0 (sem
	estimar histórico). Temporadas futuras: trocar Season/Store (novo OrderedDataStore) e zerar
	um contador de temporada — a arquitetura (LeaderboardService) não muda.
	OrderedDataStore só guarda inteiros: pontuação = floor(Lifetime / ScoreUnit) (precisão $1K,
	invisível em "$12.4T"), teto 2^53.
]]

return {
	Season = 1,
	Store = "RollLegends_LB_Magnate_S1",
	Top = 10,
	ScoreUnit = 1000,
	MaxScore = 2 ^ 53,
}
