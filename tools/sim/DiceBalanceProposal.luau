--!strict
--[[
	PROPOSTA de balanceamento dos 16 Dice (fase de análise). NÃO é usada em produção: o jogo
	continua com DiceConfig (pesos normalizados da tabela global) até a aprovação.
	Usada por tools/sim/DiceBalance.luau, tools/sim/analyze_dice_balance.luau
	(DICE_BALANCE_ANALYSIS.md) e tests/DiceBalance.spec.luau.

	RarityWeights: % por raridade (soma 100), só raridades que o pool do Dice possui. Os pools
	(personagens) NÃO mudam.
	Score: pontuação relativa por raridade SÓ para análise (Expected Rarity Value), não é gameplay.
]]

return {
	RarityWeights = {
		Starter = { Common = 62, Uncommon = 26, Rare = 9, Epic = 3 },
		Lucky = { Common = 55, Uncommon = 28, Rare = 12, Epic = 5 },
		Rampart = { Common = 45, Uncommon = 32, Rare = 16, Epic = 7 },
		-- Primeiro Lendário: 1% (1 personagem = 1 em 100)
		Flame = { Uncommon = 60, Rare = 28, Epic = 11, Legendary = 1 },
		-- Pool SEM Lendário depois do Flame: só melhora pelo Épico (ver "Regressões estruturais")
		Shinobi = { Common = 20, Uncommon = 32, Rare = 30, Epic = 18 },
		Blade = { Uncommon = 50, Rare = 32, Epic = 16, Legendary = 2 },
		Fighter = { Uncommon = 45, Rare = 33, Epic = 19, Legendary = 3 },
		Storm = { Rare = 60, Epic = 32, Legendary = 8 },
		-- Primeiro Mítico: 1%
		Spirit = { Rare = 50, Epic = 36, Legendary = 13, Mythic = 1 },
		Arcane = { Rare = 45, Epic = 37, Legendary = 16, Mythic = 2 },
		Shadow = { Epic = 65, Legendary = 30, Mythic = 5 },
		-- Primeiro Divino: 0,3% (1 personagem = 1 em ~333)
		Void = { Epic = 55, Legendary = 36, Mythic = 8.7, Divine = 0.3 },
		Awakened = { Legendary = 85, Mythic = 15 },
		-- E/L/M depois do L/M do Awakened: o Épico é compensado por mais Mítico
		Colossus = { Epic = 25, Legendary = 48, Mythic = 27 },
		-- Divino 1% (cada um dos 3 Divinos: 1 em 300)
		Celestial = { Legendary = 63.5, Mythic = 35.5, Divine = 1 },
		-- Endgame: Secreto 0,0045% (1 em ~22.200; cada um dos 3 Secretos 1 em ~66.700) com Luck 1.
		-- Calibrado para a meta já auditada do jogo: < 1 Secreto/hora mesmo com Luck máxima,
		-- monetização e Roll Rápido (0,005% dava 1,01/h). Divino 1,5% (cada um 1 em 200).
		Forbidden = { Mythic = 98.4955, Divine = 1.5, Secret = 0.0045 },
	},

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

	-- Limites de pity avaliados (o atual é Lendário 50 / Mítico 800)
	PityCandidates = {
		Legendary = { 50, 100, 150, 200 },
		Mythic = { 250, 400, 800 },
	},

	-- VARIANTE B (alternativa, NÃO aplicada): troca 2 pares de posição para a curva ficar natural
	-- sem mexer em pool — Shinobi (sem Lendário) antes do Flame e Colossus (E/L/M) antes do
	-- Awakened (L/M). Nessa ordem, Shinobi e Colossus ficam mais modestos (Épico 10%, Mítico 15%).
	VariantB = {
		Order = { "Starter", "Lucky", "Rampart", "Shinobi", "Flame", "Blade", "Fighter", "Storm", "Spirit", "Arcane", "Shadow", "Void", "Colossus", "Awakened", "Celestial", "Forbidden" },
		RarityWeights = {
			Shinobi = { Common = 35, Uncommon = 33, Rare = 22, Epic = 10 },
			Colossus = { Epic = 40, Legendary = 45, Mythic = 15 },
		},
	},
}
