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
	    Pool          "F2P" (roll normal) | "Exclusive" (recompensa; não sorteável nesta fase)
	    Rollable      pode ser usado para rolar
	    RarityWeights nil = BaseRarityPercent normalizado sobre as raridades que o Dice POSSUI
	                  (DiceCore.normalize). Override explícito por Dice: { [rarity] = % } cobrindo
	                  exatamente as raridades presentes.
	    CharacterWeights nil = peso igual dentro da raridade (futuro: peso por personagem)
	    LuckMultiplier multiplicador de Luck do Dice (entra na Luck junto com upgrades/boosts/passes,
	                  como antes). Âncoras mantêm o valor antigo (Lucky 1,25 · Flame 1,6 · Storm 2,0 ·
	                  Void 2,75 · Celestial 4,0) para não mudar o peso relativo da Luck paga; os
	                  novos foram interpolados (BALANCE_PENDING). Prism (exclusivo) 2,25 guardado.
	    LuckBehavior  "DiceRarities": a Luck redistribui SÓ entre as raridades do Dice
	    PityBehavior  "SupportedOnly": um pity só conta/dispara/é consumido em Dice que possui a
	                  raridade do piso (ver RNG.md)
	    Price/Currency/UnlockRequirement  desbloqueio (compra com dinheiro + rolls + Dice anterior)
	    Balance       "BALANCE_PENDING": pesos/preços/unlocks ainda NÃO balanceados (fase própria).
	                  Âncoras mantêm preço/requisito do sistema antigo; os novos foram interpolados.
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
	UnlockRequirement: { Rolls: number?, Dice: string? },
	Balance: string,
	-- Quantos personagens por raridade (C/U/R/E/L/M/D/S) a DICE_PROGRESSION_PROPOSAL aprovou: só
	-- AUDITORIA (DiceProbabilityReport acusa divergência), a lista vem do catálogo
	ExpectedCounts: { number }?,
	VisualModel: string,
	ColorTheme: { Body: { number }, Pips: { number } },
}

-- Distribuição BASE (soma 100%). Ponto de partida matemático, NÃO o balanceamento final: cada
-- Dice usa só as raridades que possui, renormalizadas para 100% (DiceCore.normalize).
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

local function f2p(order: number, id: string, catalogKey: string, luck: number, price: number, rolls: number, previous: string?, body: { number }, pips: { number }, expected: { number }): Dice
	return {
		ExpectedCounts = expected,
		Id = id,
		CatalogKey = catalogKey,
		Order = order,
		Pool = "F2P",
		Rollable = true,
		LuckMultiplier = luck,
		LuckBehavior = "DiceRarities",
		PityBehavior = "SupportedOnly",
		Price = price,
		Currency = "Money",
		UnlockRequirement = if previous then { Rolls = rolls, Dice = previous } else {},
		Balance = "BALANCE_PENDING",
		VisualModel = id .. "Dice",
		ColorTheme = { Body = body, Pips = pips },
	}
end

local list: { Dice } = {
	-- Âncoras (Starter = antigo Normal, Lucky, Flame, Storm, Void, Celestial): preço/requisito antigos
	f2p(1, "Starter", "starter", 1.0, 0, 0, nil, { 250, 250, 255 }, { 40, 40, 60 }, { 4, 2, 1, 1, 0, 0, 0, 0 }),
	f2p(2, "Lucky", "lucky", 1.25, 2500, 50, "Starter", { 120, 230, 120 }, { 255, 255, 255 }, { 2, 2, 2, 1, 0, 0, 0, 0 }),
	f2p(3, "Rampart", "rampart", 1.4, 10000, 125, "Lucky", { 150, 130, 100 }, { 245, 235, 210 }, { 1, 2, 2, 2, 0, 0, 0, 0 }),
	f2p(4, "Flame", "flame", 1.6, 40000, 300, "Rampart", { 255, 110, 40 }, { 255, 240, 120 }, { 0, 2, 2, 1, 1, 0, 0, 0 }),
	f2p(5, "Shinobi", "shinobi", 1.7, 75000, 425, "Flame", { 240, 140, 40 }, { 30, 30, 40 }, { 2, 2, 2, 2, 0, 0, 0, 0 }),
	f2p(6, "Blade", "blade", 1.8, 125000, 550, "Shinobi", { 200, 210, 225 }, { 30, 60, 110 }, { 0, 2, 3, 2, 1, 0, 0, 0 }),
	f2p(7, "Fighter", "fighter", 1.9, 225000, 775, "Blade", { 230, 70, 60 }, { 255, 230, 120 }, { 0, 3, 2, 1, 1, 0, 0, 0 }),
	f2p(8, "Storm", "storm", 2.0, 400000, 1000, "Fighter", { 70, 110, 220 }, { 255, 240, 100 }, { 0, 0, 3, 2, 2, 0, 0, 0 }),
	f2p(9, "Spirit", "spirit", 2.2, 750000, 1500, "Storm", { 150, 230, 255 }, { 40, 70, 120 }, { 0, 0, 1, 3, 2, 1, 0, 0 }),
	f2p(10, "Arcane", "arcane", 2.35, 1400000, 2000, "Spirit", { 120, 70, 200 }, { 255, 215, 120 }, { 0, 0, 3, 3, 1, 1, 0, 0 }),
	f2p(11, "Shadow", "shadow", 2.55, 2600000, 2500, "Arcane", { 45, 45, 55 }, { 230, 60, 70 }, { 0, 0, 0, 3, 2, 2, 0, 0 }),
	f2p(12, "Void", "void", 2.75, 5000000, 3000, "Shadow", { 35, 20, 55 }, { 190, 110, 255 }, { 0, 0, 0, 2, 2, 1, 1, 0 }),
	f2p(13, "Awakened", "awakened", 3.1, 12500000, 4500, "Void", { 255, 200, 60 }, { 255, 255, 255 }, { 0, 0, 0, 0, 3, 3, 0, 0 }),
	f2p(14, "Colossus", "colossus", 3.5, 30000000, 6000, "Awakened", { 110, 80, 60 }, { 255, 150, 60 }, { 0, 0, 0, 2, 2, 2, 0, 0 }),
	f2p(15, "Celestial", "celestial", 4.0, 75000000, 8000, "Colossus", { 255, 245, 210 }, { 255, 190, 60 }, { 0, 0, 0, 0, 2, 2, 3, 0 }),
	f2p(16, "Forbidden", "forbidden", 4.0, 750000000, 12000, "Celestial", { 20, 10, 25 }, { 255, 60, 90 }, { 0, 0, 0, 0, 0, 1, 3, 3 }),
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
}
