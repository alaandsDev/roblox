--!strict
--[[
	Batalha de cards (puro, determinístico por semente). O SERVIDOR simula e manda o registro
	(log) para o cliente só ANIMAR — o cliente nunca decide quem venceu.

	    local core = BattleCore.new(TowerConfig, CharacterConfig, RarityConfig)
	    core:card(characterId, power)               -> carta { id, power, hp, maxHp, atk, speed, crit }
	    core:enemies(tower, floor)                  -> lista de cartas inimigas
	    core:simulate(time, inimigos, rand)         -> { won, rounds, log, team, enemies }

	Regras: a cada rodada, todas as cartas vivas agem em ordem de velocidade (empate: time do
	jogador primeiro, depois a posição). Cada ataque acerta a primeira carta viva do outro lado.
	Crítico multiplica o dano. Passou de MaxRounds: vitória do defensor (inimigos).
]]

local BattleCore = {}
BattleCore.__index = BattleCore

export type Card = {
	id: string,
	side: string,
	slot: number,
	power: number,
	hp: number,
	maxHp: number,
	atk: number,
	speed: number,
	crit: number,
}

export type Action = { side: string, slot: number, target: number, damage: number, crit: boolean, ko: boolean }

export type Result = { won: boolean, rounds: number, log: { Action }, team: { Card }, enemies: { Card } }

function BattleCore.new(towerConfig: any, characterConfig: any, rarityConfig: any): any
	local byTier: { [number]: { string } } = {}
	for _, character in characterConfig.List do
		local tier = rarityConfig.ById[character.Rarity].Tier
		byTier[tier] = byTier[tier] or {}
		table.insert(byTier[tier], character.Id)
	end
	return setmetatable({ c = towerConfig, characters = characterConfig, rarities = rarityConfig, byTier = byTier }, BattleCore)
end

function BattleCore:tierOf(characterId: string): number
	local character = self.characters.ById[characterId]
	return if character then self.rarities.ById[character.Rarity].Tier else 1
end

function BattleCore:card(characterId: string, power: number, side: string?, slot: number?): Card
	local tier = self:tierOf(characterId)
	local p = math.max(1, power)
	return {
		id = characterId,
		side = side or "team",
		slot = slot or 1,
		power = p,
		hp = p * self.c.HpPerPower,
		maxHp = p * self.c.HpPerPower,
		atk = p * self.c.AtkPerPower,
		speed = self.c.SpeedByTier[tier] or 10,
		crit = self.c.CritByTier[tier] or 0.05,
	}
end

function BattleCore:enemyPower(tower: any, floor: number): number
	return tower.BasePower * tower.Growth ^ (floor - 1)
end

function BattleCore:isBoss(floor: number): boolean
	return floor % self.c.BossEvery == 0
end

-- Inimigos do andar (determinísticos: mesmo andar = mesmos inimigos)
function BattleCore:enemies(tower: any, floor: number): { Card }
	local total = self:enemyPower(tower, floor)
	local list = {}
	if self:isBoss(floor) then
		local tier = math.clamp(2 + math.floor(floor / 10) + tower.Order, 1, 8)
		local pool = self.byTier[tier] or self.byTier[8]
		table.insert(list, self:card(pool[(floor % #pool) + 1], total * self.c.BossMultiplier, "enemy", 1))
		return list
	end
	local count = math.clamp(1 + math.floor((floor - 1) / 3), 1, self.c.MaxEnemies)
	for i = 1, count do
		local tier = math.clamp(1 + math.floor((floor + i) / 8) + (tower.Order - 1) * 2, 1, 7)
		local pool = self.byTier[tier] or self.byTier[1]
		table.insert(list, self:card(pool[((floor + i) % #pool) + 1], total / count, "enemy", i))
	end
	return list
end

local function firstAlive(cards: { Card }): number?
	for i, card in cards do
		if card.hp > 0 then
			return i
		end
	end
	return nil
end

function BattleCore:simulate(team: { Card }, enemies: { Card }, rand: () -> number): Result
	local log: { Action } = {}
	local rounds = 0
	local won = false
	for i, card in team do
		card.side, card.slot = "team", i
	end
	for i, card in enemies do
		card.side, card.slot = "enemy", i
	end
	while rounds < self.c.MaxRounds do
		rounds += 1
		local order = {}
		for _, card in team do
			table.insert(order, card)
		end
		for _, card in enemies do
			table.insert(order, card)
		end
		table.sort(order, function(a, b)
			if a.speed ~= b.speed then
				return a.speed > b.speed
			end
			if a.side ~= b.side then
				return a.side == "team"
			end
			return a.slot < b.slot
		end)
		for _, attacker in order do
			if attacker.hp > 0 then
				local targets = if attacker.side == "team" then enemies else team
				local index = firstAlive(targets)
				if not index then
					break
				end
				local target = targets[index]
				local crit = rand() < attacker.crit
				local damage = attacker.atk * (if crit then self.c.CritMultiplier else 1)
				target.hp = math.max(0, target.hp - damage)
				table.insert(log, {
					side = attacker.side,
					slot = attacker.slot,
					target = index,
					damage = math.floor(damage),
					crit = crit,
					ko = target.hp <= 0,
				})
			end
		end
		if not firstAlive(enemies) then
			won = true
			break
		end
		if not firstAlive(team) then
			break
		end
	end
	return { won = won, rounds = rounds, log = log, team = team, enemies = enemies }
end

return BattleCore
