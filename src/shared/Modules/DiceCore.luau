--!strict
--[[
	Núcleo do sorteio POR DICE (puro: o gerador aleatório é injetado). O servidor decide o roll
	com ele; o cliente usa as mesmas funções só para MOSTRAR chances.

	    local core = DiceCore.new(DiceConfig, CharacterConfig, RarityConfig, RollConfig)
	    core:charactersFor(diceId)                         --> { characterId } (ordem estável)
	    core:rarityChances(diceId, luck?, pity?)          --> { [rarity] = 0..1 } (soma 1)
	    core:characterProbability(diceId, id, luck?, pity?) --> 0..1 (0 = fora do Dice)
	    core:roll(diceId, luck, pity, rand)               --> { rarity, characterId, pity, pityTriggered }

	Probabilidade em DUAS etapas (nada de raridade global + reroll):
	    P(personagem) = P(raridade | Dice, Luck, pity) × P(personagem | raridade, Dice)
	    P(raridade | Dice) sem Luck = RarityWeights do Dice (soma 100%) — só raridades que o Dice POSSUI
	    P(personagem | raridade)   = peso / Σ pesos da raridade no Dice (hoje: 1 / quantidade)

	Luck (mesma filosofia do RollCore, aplicada sobre o Dice):
	    LuckEfetiva = 1 + (L − 1) / (1 + (L − 1) / LuckSoftCap)
	    peso(r)     = RarityWeights_Dice(r) × LuckEfetiva ^ LuckExponent(r)   (r ∈ raridades do Dice)
	    chance(r)   = peso(r) / Σ peso
	  Comum (expoente 0) só é diluído; raridade ausente no Dice nunca recebe chance.

	Pity (RollConfig.Pity, contadores salvos em data.Pity; ver RNG.md):
	  Uma regra é COMPATÍVEL com o Dice se o Dice possui a raridade do piso (MinRarity).
	    - Incrementa: roll num Dice compatível que saiu ABAIXO do piso.
	    - Dispara:    num Dice compatível, quando contador + 1 >= Threshold: o roll é sorteado
	                  normalmente; abaixo do piso vira EXATAMENTE o piso (existe no Dice).
	    - Zera:       qualquer roll que saia no piso ou acima (em qualquer Dice).
	    - Congela:    num Dice INCOMPATÍVEL, se saiu abaixo do piso: nem conta, nem dispara, nem é
	                  consumido (o contador fica como está até o jogador usar um Dice compatível).
]]

local DiceCore = {}
DiceCore.__index = DiceCore

export type RollResult = {
	rarity: string,
	characterId: string,
	pity: { [string]: number },
	pityTriggered: string?,
}

export type Pool = {
	id: string,
	config: any,
	characters: { string },
	byRarity: { [string]: { string } },
	rarities: { string }, -- raridades presentes, na ordem do RarityConfig
	percent: { [string]: number }, -- pesos base do Dice (soma 100)
}

local EPSILON = 1e-9

-- Pesos de `base` restritos às raridades `supported`, renormalizados para somar 100.
-- Raridade fora de `supported` não aparece no resultado (chance 0, nunca "redistribuída").
function DiceCore.normalize(base: { [string]: number }, supported: { [string]: boolean }): { [string]: number }
	local total = 0
	for rarity in supported do
		total += base[rarity] or 0
	end
	local out: { [string]: number } = {}
	if total <= 0 then
		return out
	end
	for rarity in supported do
		local w = base[rarity] or 0
		if w > 0 then
			out[rarity] = w / total * 100
		end
	end
	return out
end

-- Pools por Dice a partir do catálogo (personagens com LaunchPool F2P e DefaultDice = CatalogKey)
function DiceCore.buildPools(diceConfig: any, characterConfig: any): { [string]: { [string]: { string } } }
	local pools: { [string]: { [string]: { string } } } = {}
	for _, dice in diceConfig.List do
		if dice.Rollable then
			pools[dice.Id] = {}
		end
	end
	for _, character in characterConfig.Launch do
		local dice = character.DefaultDice and diceConfig.ByCatalogKey[character.DefaultDice]
		if dice and dice.Rollable and character.LaunchPool == "F2P" then
			local pool = pools[dice.Id]
			pool[character.Rarity] = pool[character.Rarity] or {}
			table.insert(pool[character.Rarity], character.Id)
		end
	end
	for _, pool in pools do
		for _, ids in pool do
			table.sort(ids) -- ordem estável: o mesmo valor aleatório sempre dá o mesmo personagem
		end
	end
	return pools
end

--[[
	Auditoria da configuração (usada no DiceProbabilityReport e nos testes). Acusa:
	  total de pesos != 100%, raridade com peso e sem personagem, personagem em dois Dice,
	  F2P sem Dice, Premium dentro de Dice F2P, raridade do personagem diferente do catálogo,
	  contagem por raridade diferente da aprovada (ExpectedCounts), nº de Dice/F2P errado.
	`pools` e `weights` podem ser injetados (testes); por padrão vêm do catálogo.
]]
function DiceCore.validate(diceConfig: any, characterConfig: any, rarityConfig: any, pools: any?, weights: any?): { string }
	local problems = {}
	local actualPools = pools or DiceCore.buildPools(diceConfig, characterConfig)
	local seen: { [string]: string } = {}
	local rollable, total = 0, 0
	for _, dice in diceConfig.List do
		if not dice.Rollable then
			continue
		end
		rollable += 1
		local pool = actualPools[dice.Id] or {}
		local supported: { [string]: boolean } = {}
		for rarity, ids in pool do
			if #ids > 0 then
				supported[rarity] = true
			end
			for _, id in ids do
				total += 1
				local character = characterConfig.ById[id]
				if not character then
					table.insert(problems, `{dice.Id}: personagem inexistente {id}`)
					continue
				end
				if seen[id] then
					table.insert(problems, `{id} duplicado: {seen[id]} e {dice.Id}`)
				end
				seen[id] = dice.Id
				if character.Rarity ~= rarity then
					table.insert(problems, `{dice.Id}: {id} está como {rarity}, mas o catálogo diz {character.Rarity}`)
				end
				if character.LaunchPool ~= "F2P" then
					table.insert(problems, `{dice.Id}: {id} é {tostring(character.LaunchPool)} (Premium/fora do F2P) dentro de Dice F2P`)
				end
			end
		end
		local percent = (weights and weights[dice.Id]) or dice.RarityWeights or DiceCore.normalize(diceConfig.BaseRarityPercent, supported)
		local sum = 0
		for rarity, value in percent do
			sum += value
			if value > 0 and not supported[rarity] then
				table.insert(problems, `{dice.Id}: raridade {rarity} com {value}% e nenhum personagem`)
			end
		end
		for rarity in supported do
			if (percent[rarity] or 0) <= 0 then
				table.insert(problems, `{dice.Id}: raridade {rarity} tem personagens mas 0%`)
			end
		end
		if math.abs(sum - 100) > 1e-6 then
			table.insert(problems, `{dice.Id}: pesos somam {string.format("%.6f", sum)}% (esperado 100%)`)
		end
		if dice.ExpectedCounts then
			for i, rarity in rarityConfig.Order do
				local count = if pool[rarity] then #pool[rarity] else 0
				if count ~= (dice.ExpectedCounts[i] or 0) then
					table.insert(problems, `{dice.Id}: {rarity} tem {count} personagem(ns), aprovado {dice.ExpectedCounts[i] or 0}`)
				end
			end
		end
	end
	for _, character in characterConfig.Launch do
		if character.LaunchPool == "F2P" and not seen[character.Id] then
			table.insert(problems, `{character.Id}: F2P sem Dice (DefaultDice = {tostring(character.DefaultDice)})`)
		end
	end
	if rollable ~= diceConfig.F2PCount then
		table.insert(problems, `{rollable} Dice sorteáveis (esperado {diceConfig.F2PCount})`)
	end
	local f2p = 0
	for _, character in characterConfig.Launch do
		if character.LaunchPool == "F2P" then
			f2p += 1
		end
	end
	if total ~= f2p then
		table.insert(problems, `{total} personagens nos Dice (F2P no catálogo: {f2p})`)
	end
	return problems
end

function DiceCore.new(diceConfig: any, characterConfig: any, rarityConfig: any, rollConfig: any): any
	local pools = DiceCore.buildPools(diceConfig, characterConfig)
	local byDice: { [string]: Pool } = {}
	local diceOf: { [string]: string } = {}
	for _, dice in diceConfig.List do
		local pool = pools[dice.Id]
		if not pool then
			continue
		end
		local supported: { [string]: boolean } = {}
		local rarities, characters = {}, {}
		for _, rarity in rarityConfig.Order do
			local ids = pool[rarity]
			if ids and #ids > 0 then
				supported[rarity] = true
				table.insert(rarities, rarity)
				for _, id in ids do
					table.insert(characters, id)
					diceOf[id] = dice.Id
				end
			end
		end
		byDice[dice.Id] = {
			id = dice.Id,
			config = dice,
			characters = characters,
			byRarity = pool,
			rarities = rarities,
			percent = dice.RarityWeights or DiceCore.normalize(diceConfig.BaseRarityPercent, supported),
		}
	end
	return setmetatable({
		diceConfig = diceConfig,
		characterConfig = characterConfig,
		rarityConfig = rarityConfig,
		rollConfig = rollConfig,
		pools = byDice,
		diceOf = diceOf,
	}, DiceCore)
end

function DiceCore:pool(diceId: string): Pool?
	return self.pools[diceId]
end

function DiceCore:isRollable(diceId: string): boolean
	return self.pools[diceId] ~= nil
end

function DiceCore:charactersFor(diceId: string): { string }
	local pool = self.pools[diceId]
	return if pool then table.clone(pool.characters) else {}
end

-- Dice F2P do personagem (nil = Premium/legado/fora dos Dice)
function DiceCore:diceOfCharacter(characterId: string): string?
	return self.diceOf[characterId]
end

function DiceCore:tierOf(rarity: string): number
	return self.rarityConfig.ById[rarity].Tier
end

function DiceCore:supports(diceId: string, rarity: string): boolean
	local pool = self.pools[diceId]
	return pool ~= nil and pool.byRarity[rarity] ~= nil and #pool.byRarity[rarity] > 0
end

-- Luck usada nos pesos (retornos decrescentes; mesma fórmula do RollCore/Formulas)
function DiceCore:effectiveLuck(luck: number?): number
	local l = math.max(1, luck or 1)
	local cap = self.rollConfig.LuckSoftCap
	if cap and cap > 0 then
		return 1 + (l - 1) / (1 + (l - 1) / cap)
	end
	return l
end

-- Pesos com Luck (só raridades do Dice; somam 100)
function DiceCore:rarityWeights(diceId: string, luck: number?): { [string]: number }
	local pool = self.pools[diceId]
	if not pool then
		return {}
	end
	local l = self:effectiveLuck(luck)
	local weights, total = {}, 0
	for _, rarity in pool.rarities do
		local w = (pool.percent[rarity] or 0) * l ^ self.rarityConfig.ById[rarity].LuckExponent
		weights[rarity] = w
		total += w
	end
	for rarity, w in weights do
		weights[rarity] = w / total * 100
	end
	return weights
end

-- Pity aplicável neste roll do Dice (só regras compatíveis; a de MAIOR raridade vence)
function DiceCore:pityFor(diceId: string, pity: { [string]: number }?): (string?, string?)
	local chosenId, chosenFloor, chosenTier = nil, nil, nil
	for _, rule in self.rollConfig.Pity do
		if self:supports(diceId, rule.MinRarity) and ((pity and pity[rule.Id]) or 0) + 1 >= rule.Threshold then
			local tier = self:tierOf(rule.MinRarity)
			if not chosenTier or tier > chosenTier then
				chosenId, chosenFloor, chosenTier = rule.Id, rule.MinRarity, tier
			end
		end
	end
	return chosenId, chosenFloor
end

-- Chance de cada raridade NESTE roll (Luck + pity). Com pity: a massa abaixo do piso vai
-- para o piso (o sorteio natural é mantido acima dele). Soma 1.
function DiceCore:rarityChances(diceId: string, luck: number?, pity: { [string]: number }?): { [string]: number }
	local weights = self:rarityWeights(diceId, luck)
	local _, floor = self:pityFor(diceId, pity)
	local chances: { [string]: number } = {}
	for rarity, w in weights do
		chances[rarity] = w / 100
	end
	if floor then
		local floorTier = self:tierOf(floor)
		local moved = 0
		for rarity, p in chances do
			if self:tierOf(rarity) < floorTier then
				moved += p
				chances[rarity] = 0
			end
		end
		chances[floor] = (chances[floor] or 0) + moved
	end
	return chances
end

-- P(personagem | raridade) dentro do Dice (CharacterWeights opcional; hoje peso igual)
function DiceCore:characterShare(diceId: string, characterId: string): number
	local pool = self.pools[diceId]
	local character = self.characterConfig.ById[characterId]
	if not pool or not character then
		return 0
	end
	local ids = pool.byRarity[character.Rarity]
	if not ids or not table.find(ids, characterId) then
		return 0
	end
	local weights = pool.config.CharacterWeights
	if not weights then
		return 1 / #ids
	end
	local total = 0
	for _, id in ids do
		total += weights[id] or 1
	end
	return (weights[characterId] or 1) / total
end

-- GetCharacterProbability: chance EFETIVA do personagem no Dice (0 se não pertence a ele)
function DiceCore:characterProbability(diceId: string, characterId: string, luck: number?, pity: { [string]: number }?): number
	local character = self.characterConfig.ById[characterId]
	local share = self:characterShare(diceId, characterId)
	if not character or share == 0 then
		return 0
	end
	return (self:rarityChances(diceId, luck, pity)[character.Rarity] or 0) * share
end

-- "1 em X" da chance BASE (sem Luck/pity) no Dice do personagem; 0 se fora dos Dice
function DiceCore:odds(characterId: string): number
	local diceId = self.diceOf[characterId]
	local p = if diceId then self:characterProbability(diceId, characterId) else 0
	return if p > 0 then math.floor(1 / p + 0.5) else 0
end

function DiceCore:pickRarity(diceId: string, luck: number?, rand: () -> number): string
	local pool = self.pools[diceId]
	assert(pool, "Dice não sorteável: " .. tostring(diceId))
	local weights = self:rarityWeights(diceId, luck)
	local target = rand() * 100
	local last = pool.rarities[#pool.rarities]
	for _, rarity in pool.rarities do
		local w = weights[rarity]
		if target < w then
			return rarity
		end
		target -= w
	end
	return last
end

function DiceCore:pickCharacter(diceId: string, rarity: string, rand: () -> number): string
	local pool = self.pools[diceId]
	local ids = pool.byRarity[rarity]
	assert(ids and #ids > 0, `{diceId} não tem {rarity}`)
	local weights = pool.config.CharacterWeights
	if not weights then
		return ids[math.clamp(math.floor(rand() * #ids) + 1, 1, #ids)]
	end
	local total = 0
	for _, id in ids do
		total += weights[id] or 1
	end
	local target = rand() * total
	for _, id in ids do
		target -= weights[id] or 1
		if target < 0 then
			return id
		end
	end
	return ids[#ids]
end

-- Novo estado de pity depois de tirar `rarity` no Dice (regras: ver cabeçalho)
function DiceCore:nextPity(diceId: string, pity: { [string]: number }?, rarity: string): { [string]: number }
	local tier = self:tierOf(rarity)
	local updated = {}
	for _, rule in self.rollConfig.Pity do
		local count = (pity and pity[rule.Id]) or 0
		if tier >= self:tierOf(rule.MinRarity) then
			updated[rule.Id] = 0
		elseif self:supports(diceId, rule.MinRarity) then
			updated[rule.Id] = count + 1
		else
			updated[rule.Id] = count -- Dice incompatível: congelado
		end
	end
	return updated
end

-- Sorteio natural com piso opcional (o piso precisa existir no Dice)
function DiceCore:pickWithFloor(diceId: string, luck: number?, rand: () -> number, floor: string?): string
	local rarity = self:pickRarity(diceId, luck, rand)
	if floor and self:supports(diceId, floor) and self:tierOf(rarity) < self:tierOf(floor) then
		return floor
	end
	return rarity
end

function DiceCore:roll(diceId: string, luck: number?, pity: { [string]: number }?, rand: () -> number): RollResult
	local pityId, floor = self:pityFor(diceId, pity)
	local rarity = self:pickWithFloor(diceId, luck, rand, floor)
	local natural = floor ~= nil and self:tierOf(rarity) > self:tierOf(floor :: string)
	return {
		rarity = rarity,
		characterId = self:pickCharacter(diceId, rarity, rand),
		pity = self:nextPity(diceId, pity, rarity),
		pityTriggered = if natural then nil else pityId,
	}
end

--[[
	Dice usado num PRÊMIO "personagem de MinRarity ou melhor" (Jackpot). Regra explícita:
	o Dice selecionado, se ele possui MinRarity; senão o primeiro Dice F2P (por Order) que possui.
	(Nunca troca o piso por outra raridade.)
]]
function DiceCore:grantDice(selectedId: string?, minRarity: string): string?
	if selectedId and self:supports(selectedId, minRarity) then
		return selectedId
	end
	local best: any = nil
	for id, pool in self.pools do
		if self:supports(id, minRarity) and (not best or pool.config.Order < best.config.Order) then
			best = pool
		end
	end
	return if best then best.id else nil
end

-- Lista ordenada dos Dice sorteáveis
function DiceCore:diceList(): { any }
	local list = {}
	for _, pool in self.pools do
		table.insert(list, pool.config)
	end
	table.sort(list, function(a, b)
		return a.Order < b.Order
	end)
	return list
end

-- Relatório de probabilidade de um Dice (texto). EPSILON só para a checagem da soma.
function DiceCore:probabilityReport(diceId: string): ({ string }, { string })
	local pool = self.pools[diceId]
	local lines, problems = {}, {}
	if not pool then
		return { `{diceId}: Dice não sorteável` }, { `{diceId}: Dice não sorteável` }
	end
	table.insert(lines, string.upper(diceId))
	table.insert(lines, `Characters: {#pool.characters}`)
	table.insert(lines, "Rarities:")
	local sum = 0
	for _, rarity in pool.rarities do
		local value = pool.percent[rarity]
		sum += value
		table.insert(lines, string.format("  %s: %.4f%% (%d personagem(ns))", rarity, value, #pool.byRarity[rarity]))
	end
	table.insert(lines, string.format("Total: %.6f%%", sum))
	if math.abs(sum - 100) > 1e-6 then
		table.insert(problems, `{diceId}: total {sum}%`)
	end
	table.insert(lines, "CHARACTERS:")
	local charSum = 0
	for _, id in pool.characters do
		local p = self:characterProbability(diceId, id)
		charSum += p
		table.insert(lines, string.format("  %s (%s): %.4f%%", id, self.characterConfig.ById[id].Rarity, p * 100))
	end
	table.insert(lines, string.format("Soma dos personagens: %.6f%%", charSum * 100))
	if math.abs(charSum - 1) > EPSILON * 100 then
		table.insert(problems, `{diceId}: personagens somam {charSum * 100}%`)
	end
	return lines, problems
end

return DiceCore
