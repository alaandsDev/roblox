--!strict
--[[
	Parâmetros da ANÁLISE de balanceamento (não é gameplay). A proposta de pesos (commit e4b73ac)
	foi APROVADA com a Variante B + Divino reduzido e agora vive em DiceConfig (RarityWeights).
	Usado por tools/sim/DiceBalance.luau, tools/sim/analyze_dice_balance.luau
	(DICE_BALANCE_ANALYSIS.md) e tests/DiceBalance.spec.luau.

	Score: pontuação relativa por raridade SÓ para análise (Expected Rarity Value).
]]

return {
	-- Expected Rarity Value (ERV) = Σ P(raridade) × Score(raridade). Escala ~exponencial.
	Score = {
		Common = 1,
		Uncommon = 3,
		Rare = 10,
		Epic = 30,
		Legendary = 100,
		Mythic = 400,
		Divine = 2000,
		Secret = 15000,
	},

	-- Limites de pity avaliados (aprovado: Lendário 50 / Mítico 250)
	PityCandidates = {
		Legendary = { 50, 100, 150, 200 },
		Mythic = { 250, 400, 800 },
	},

}
