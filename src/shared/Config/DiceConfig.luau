--!strict
--[[
	DADOS (16 Dice F2P + exclusivos). Cada Dice é a FONTE da distribuição do roll: o sorteio
	escolhe a raridade com os pesos DO DICE e depois um personagem daquela raridade DENTRO do
	Dice (DiceCore; ver RNG.md). Não existe mais sorteio global de raridade.

	Personagens de cada Dice: NÃO são listados aqui. Vêm do catálogo de lançamento
	(CharacterConfig.Launch, campo DefaultDice = CatalogKey), que é a fonte de verdade.
	Premium (LaunchPool = "Premium") nunca entra em Dice F2P.

	Campos:
	    Id            chave persistente (save: EquippedDice/OwnedDice). Âncoras do sistema antigo
	                  mantêm o Id (Lucky, Flame, Storm, Void, Celestial); Normal -> Starter (migração v3).
	    CatalogKey    valor de DefaultDice no catálogo ("starter", "lucky", ...)
	    Order         ordem de desbloqueio
	    Pool          "F2P" (roll normal) | "Exclusive" (Prism: Prisma da Coleção, ver PrismConfig)
	    Rollable      pode ser usado para rolar
	    RarityWeights OBRIGATÓRIO em Dice sorteável: { [rarity] = % } aprovado em
	                  DICE_BALANCE_ANALYSIS.md, soma 100, só as raridades presentes no pool. Sem
	                  fallback: Dice sorteável sem pesos = erro (DiceCore).
	    CharacterWeights nil = peso igual dentro da raridade (futuro: peso por personagem)
	    LuckMultiplier multiplicador de Luck do Dice (entra na Luck junto com upgrades/boosts/passes,
	                  como antes). Âncoras mantêm o valor antigo (Lucky 1,25 · Flame 1,6 · Storm 2,0 ·
	                  Void 2,75 · Celestial 4,0) para não mudar o peso relativo da Luck paga; os
	                  novos foram interpolados. É do DICE (não da posição): com a ordem da Variante B,
	                  Shinobi (#4) 1,7 > Flame (#5) 1,6 e Colossus (#13) 3,5 > Awakened (#14) 3,1.
	    LuckBehavior  "DiceRarities": a Luck redistribui SÓ entre as raridades do Dice
	    PityBehavior  "SupportedOnly": um pity só conta/dispara/é consumido em Dice que possui a
	                  raridade do piso (ver RNG.md)
	    Price/Currency/UnlockRequirement  desbloqueio (compra com dinheiro + rolls + Dice anterior)
	    Balance       pesos APROVADOS; preço/unlock ainda pendentes da fase de economia.
]]

export type Dice = {
	Id: string,
	CatalogKey: string?,
	Order: number,
	Pool: string,
	Rollable: boolean,
	RarityWeights: { [string]: number }?,
	CharacterWeights: { [string]: number }?,
	LuckMultiplier: number,
	LuckBehavior: string,
	PityBehavior: string,
	Price: number,
	Currency: string,
	-- Exclusivo: não aparece à venda (vem de recompensa, ex.: Dia 7 do Diário)
	Exclusive: boolean?,
	UnlockRequirement: { Rolls: number?, Dice: string?, RollsOnPrevious: number? },
	Balance: string,
	-- Quantos personagens por raridade (C/U/R/E/L/M/D/S) a DICE_PROGRESSION_PROPOSAL aprovou: só
	-- AUDITORIA (DiceProbabilityReport acusa divergência), a lista vem do catálogo
	ExpectedCounts: { number }?,
	VisualModel: string,
	ColorTheme: { Body: { number }, Pips: { number } },
}

-- Tabela GLOBAL antiga (soma 100%): só REFERÊNCIA/comparação na análise de balanceamento.
-- NÃO define pesos de produção: todo Dice sorteável tem RarityWeights explícitos (sem fallback).
local BASE_RARITY_PERCENT: { [string]: number } = {
	Common = 55,
	Uncommon = 25,
	Rare = 12,
	Epic = 5,
	Legendary = 2,
	Mythic = 0.75,
	Divine = 0.20,
	Secret = 0.05,
}

-- Rolls que o jogador precisa fazer COM o Dice anterior antes de comprar o próximo
-- (data.DiceRolls). Impede a compra em cascata: a auditoria mostrou dinheiro de missões/coletor
-- chegando em bloco e pagando 2–3 Dice de uma vez (92% dos Ativos nunca rolavam o Shinobi).
-- 60 rolls = 1 min no ritmo normal (30 s com Roll Rápido): o pool de 6–8 personagens tem chance real.
local ROLLS_ON_PREVIOUS = 60

local function f2p(order: number, id: string, catalogKey: string, luck: number, price: number, rolls: number, previous: string?, body: { number }, pips: { number }, expected: { number }, weights: { [string]: number }): Dice
	return {
		ExpectedCounts = expected,
		Id = id,
		CatalogKey = catalogKey,
		Order = order,
		Pool = "F2P",
		Rollable = true,
		RarityWeights = weights,
		LuckMultiplier = luck,
		LuckBehavior = "DiceRarities",
		PityBehavior = "SupportedOnly",
		Price = price,
		Currency = "Money",
		UnlockRequirement = if previous then { Rolls = rolls, Dice = previous, RollsOnPrevious = ROLLS_ON_PREVIOUS } else {},
		Balance = "WEIGHTS_APPROVED · ECONOMY_PENDING",
		VisualModel = id .. "Dice",
		ColorTheme = { Body = body, Pips = pips },
	}
end

--[[
	Ordem oficial (Variante B de DICE_BALANCE_ANALYSIS.md): Shinobi antes do Flame e Colossus antes
	do Awakened. Pools iguais (personagens não mudaram de Dice).
	Preço e rolls de desbloqueio pertencem à POSIÇÃO (#4 = 40k / 300 rolls, #5 = 75k / 450 ...;
	balanceamento aplicado: Flame 425->450, Blade 550->650 rolls, Forbidden 750M->400M);
	LuckMultiplier pertence ao Dice (não mudou com a troca de posição).
	RarityWeights: aprovados (% por raridade, soma 100, só raridades do pool).
]]
local list: { Dice } = {
	f2p(1, "Starter", "starter", 1.0, 0, 0, nil, { 250, 250, 255 }, { 40, 40, 60 }, { 4, 2, 1, 1, 0, 0, 0, 0 },
		{ Common = 62, Uncommon = 26, Rare = 9, Epic = 3 }),
	f2p(2, "Lucky", "lucky", 1.25, 2500, 50, "Starter", { 120, 230, 120 }, { 255, 255, 255 }, { 2, 2, 2, 1, 0, 0, 0, 0 },
		{ Common = 55, Uncommon = 28, Rare = 12, Epic = 5 }),
	f2p(3, "Rampart", "rampart", 1.4, 10000, 125, "Lucky", { 150, 130, 100 }, { 245, 235, 210 }, { 1, 2, 2, 2, 0, 0, 0, 0 },
		{ Common = 45, Uncommon = 32, Rare = 16, Epic = 7 }),
	f2p(4, "Shinobi", "shinobi", 1.7, 40000, 300, "Rampart", { 240, 140, 40 }, { 30, 30, 40 }, { 2, 2, 2, 2, 0, 0, 0, 0 },
		{ Common = 35, Uncommon = 33, Rare = 22, Epic = 10 }),
	-- Primeiro Lendário: 1% (1 personagem)
	f2p(5, "Flame", "flame", 1.6, 75000, 450, "Shinobi", { 255, 110, 40 }, { 255, 240, 120 }, { 0, 2, 2, 1, 1, 0, 0, 0 },
		{ Uncommon = 60, Rare = 28, Epic = 11, Legendary = 1 }),
	f2p(6, "Blade", "blade", 1.8, 125000, 650, "Flame", { 200, 210, 225 }, { 30, 60, 110 }, { 0, 2, 3, 2, 1, 0, 0, 0 },
		{ Uncommon = 50, Rare = 32, Epic = 16, Legendary = 2 }),
	f2p(7, "Fighter", "fighter", 1.9, 225000, 775, "Blade", { 230, 70, 60 }, { 255, 230, 120 }, { 0, 3, 2, 1, 1, 0, 0, 0 },
		{ Uncommon = 45, Rare = 33, Epic = 19, Legendary = 3 }),
	f2p(8, "Storm", "storm", 2.0, 400000, 1000, "Fighter", { 70, 110, 220 }, { 255, 240, 100 }, { 0, 0, 3, 2, 2, 0, 0, 0 },
		{ Rare = 60, Epic = 32, Legendary = 8 }),
	-- Primeiro Mítico: 1%
	f2p(9, "Spirit", "spirit", 2.2, 750000, 1500, "Storm", { 150, 230, 255 }, { 40, 70, 120 }, { 0, 0, 1, 3, 2, 1, 0, 0 },
		{ Rare = 50, Epic = 36, Legendary = 13, Mythic = 1 }),
	f2p(10, "Arcane", "arcane", 2.35, 1400000, 2000, "Spirit", { 120, 70, 200 }, { 255, 215, 120 }, { 0, 0, 3, 3, 1, 1, 0, 0 },
		{ Rare = 45, Epic = 37, Legendary = 16, Mythic = 2 }),
	f2p(11, "Shadow", "shadow", 2.55, 2600000, 2500, "Arcane", { 45, 45, 55 }, { 230, 60, 70 }, { 0, 0, 0, 3, 2, 2, 0, 0 },
		{ Epic = 65, Legendary = 30, Mythic = 5 }),
	-- Primeiro Divino: 0,3% (1 personagem)
	f2p(12, "Void", "void", 2.75, 5000000, 3000, "Shadow", { 35, 20, 55 }, { 190, 110, 255 }, { 0, 0, 0, 2, 2, 1, 1, 0 },
		{ Epic = 55, Legendary = 36, Mythic = 8.7, Divine = 0.3 }),
	f2p(13, "Colossus", "colossus", 3.5, 12500000, 4500, "Void", { 110, 80, 60 }, { 255, 150, 60 }, { 0, 0, 0, 2, 2, 2, 0, 0 },
		{ Epic = 40, Legendary = 45, Mythic = 15 }),
	f2p(14, "Awakened", "awakened", 3.1, 30000000, 6000, "Colossus", { 255, 200, 60 }, { 255, 255, 255 }, { 0, 0, 0, 0, 3, 3, 0, 0 },
		{ Legendary = 85, Mythic = 15 }),
	-- Divino reduzido (cada um dos 3: 1 em 600)
	f2p(15, "Celestial", "celestial", 4.0, 75000000, 8000, "Awakened", { 255, 245, 210 }, { 255, 190, 60 }, { 0, 0, 0, 0, 2, 2, 3, 0 },
		{ Legendary = 64, Mythic = 35.5, Divine = 0.5 }),
	-- Endgame: Secreto 0,0045% (< 1/h mesmo no máximo absoluto); Divino reduzido 0,75%
	f2p(16, "Forbidden", "forbidden", 4.0, 400000000, 12000, "Celestial", { 20, 10, 25 }, { 255, 60, 90 }, { 0, 0, 0, 0, 0, 1, 3, 3 },
		{ Mythic = 99.2455, Divine = 0.75, Secret = 0.0045 }),
	-- Exclusivo da recompensa diária (Dia 7). Sem pool próprio nesta fase: fica na coleção do
	-- jogador, mas não é sorteável (decisão de design pendente para a fase de balanceamento).
	{
		Id = "Prism",
		Order = 99,
		Pool = "Exclusive",
		Rollable = false,
		LuckMultiplier = 2.25,
		LuckBehavior = "DiceRarities",
		PityBehavior = "SupportedOnly",
		Price = 0,
		Currency = "Money",
		Exclusive = true,
		UnlockRequirement = {},
		Balance = "BALANCE_PENDING",
		VisualModel = "PrismDice",
		ColorTheme = { Body = { 255, 140, 220 }, Pips = { 120, 240, 255 } },
	},
}

local byId: { [string]: Dice } = {}
local byCatalogKey: { [string]: Dice } = {}
for _, dice in list do
	assert(byId[dice.Id] == nil, "Dice repetido: " .. dice.Id)
	byId[dice.Id] = dice
	if dice.CatalogKey then
		byCatalogKey[dice.CatalogKey] = dice
	end
end

return {
	List = list,
	ById = byId,
	ByCatalogKey = byCatalogKey,
	Default = "Starter",
	-- Ids antigos que mudaram (migração v3 do save)
	Renamed = { Normal = "Starter" },
	BaseRarityPercent = BASE_RARITY_PERCENT,
	F2PCount = 16,
	RollsOnPrevious = ROLLS_ON_PREVIOUS,
}
