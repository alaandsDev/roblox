--!strict
--[[
	Núcleo do sorteio (puro: o gerador aleatório é injetado). Usado SÓ pelo servidor para
	decidir resultados; o cliente usa apenas chances/weights para mostrar odds.

	    local core = RollCore.new(RarityConfig, CharacterConfig, RollConfig)
	    core:chances(luck)                 --> { [rarityId] = probabilidade 0..1 }
	    core:roll(luck, pity, rand)        --> { rarity, characterId, pity (novo), pityTriggered }

	Fórmula da Luck (ver RNG.md):  pesoEfetivo(r) = Weight(r) * luck ^ LuckExponent(r)
	Pity: se algum contador atingiu o limite, o sorteio é restrito às raridades >= MinRarity
	(mantendo as proporções entre elas).
]]

local RollCore = {}
RollCore.__index = RollCore

export type RollResult = {
	rarity: string,
	characterId: string,
	pity: { [string]: number },
	pityTriggered: string?,
}

function RollCore.new(rarityConfig: any, characterConfig: any, rollConfig: any): any
	local byRarity: { [string]: { string } } = {}
	for _, character in characterConfig.List do
		byRarity[character.Rarity] = byRarity[character.Rarity] or {}
		table.insert(byRarity[character.Rarity], character.Id)
	end
	for _, list in byRarity do
		table.sort(list) -- ordem estável (o mesmo sorteio sempre dá o mesmo personagem)
	end
	return setmetatable({
		rarities = rarityConfig,
		rollConfig = rollConfig,
		charactersByRarity = byRarity,
	}, RollCore)
end

function RollCore:tierOf(rarityId: string): number
	return self.rarities.ById[rarityId].Tier
end

-- Pesos efetivos para uma Luck (Luck < 1 é tratada como 1)
function RollCore:weights(luck: number, minTier: number?): { [string]: number }
	local l = math.max(1, luck)
	local weights = {}
	for _, rarity in self.rarities.List do
		if (not minTier or rarity.Tier >= minTier) and self.charactersByRarity[rarity.Id] then
			weights[rarity.Id] = rarity.Weight * l ^ rarity.LuckExponent
		end
	end
	return weights
end

function RollCore:chances(luck: number, minTier: number?): { [string]: number }
	local weights = self:weights(luck, minTier)
	local total = 0
	for _, w in weights do
		total += w
	end
	local chances = {}
	for id, w in weights do
		chances[id] = w / total
	end
	return chances
end

-- Sorteio ponderado na ordem das raridades (determinístico para um mesmo valor de rand)
function RollCore:pickRarity(luck: number, rand: () -> number, minTier: number?): string
	local weights = self:weights(luck, minTier)
	local total = 0
	for _, w in weights do
		total += w
	end
	local target = rand() * total
	local last = ""
	for _, rarity in self.rarities.List do
		local w = weights[rarity.Id]
		if w then
			last = rarity.Id
			if target < w then
				return rarity.Id
			end
			target -= w
		end
	end
	return last
end

function RollCore:pickCharacter(rarity: string, rand: () -> number): string
	local list = self.charactersByRarity[rarity]
	local index = math.clamp(math.floor(rand() * #list) + 1, 1, #list)
	return list[index]
end

-- Pity a aplicar neste roll (a regra de MAIOR raridade vence)
function RollCore:pityFor(pity: { [string]: number }): (string?, number?)
	local chosenId, chosenTier = nil, nil
	for _, rule in self.rollConfig.Pity do
		local count = pity[rule.Id] or 0
		if count + 1 >= rule.Threshold then
			local tier = self:tierOf(rule.MinRarity)
			if not chosenTier or tier > chosenTier then
				chosenId, chosenTier = rule.Id, tier
			end
		end
	end
	return chosenId, chosenTier
end

-- Novo estado de pity depois de tirar `rarity`
function RollCore:nextPity(pity: { [string]: number }, rarity: string): { [string]: number }
	local tier = self:tierOf(rarity)
	local updated = {}
	for _, rule in self.rollConfig.Pity do
		if tier >= self:tierOf(rule.MinRarity) then
			updated[rule.Id] = 0
		else
			updated[rule.Id] = (pity[rule.Id] or 0) + 1
		end
	end
	return updated
end

function RollCore:roll(luck: number, pity: { [string]: number }, rand: () -> number): RollResult
	local pityId, minTier = self:pityFor(pity)
	local rarity = self:pickRarity(luck, rand, minTier)
	return {
		rarity = rarity,
		characterId = self:pickCharacter(rarity, rand),
		pity = self:nextPity(pity, rarity),
		pityTriggered = pityId,
	}
end

return RollCore
