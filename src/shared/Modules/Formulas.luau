--!strict
--[[
	Fórmulas de jogo (puras). O SERVIDOR usa para decidir; o cliente usa só para MOSTRAR.
	    local f = Formulas.new({ Dice, Upgrades, Roll, Economy, Characters, Levels, Variants })
	    f:luck(data, now)  f:rollCooldown(data)  f:capacity(data)  f:incomePerSecond(data)
	    f:unitIncome(item)  f:characterUpgradeCost(characterId, nivel, quantidade)
	    f:sellValue(characterId, variant)  f:upgradeCost(id, nivelAtual)

	DOIS tipos de melhoria (não misturar):
	  GLOBAIS (Upgrades): Luck, Income, RollSpeed, Inventory
	  DE PERSONAGEM (item.Level): renda individual de cada estação da base
]]

local Formulas = {}
Formulas.__index = Formulas

function Formulas.new(configs: any): any
	return setmetatable({ c = configs }, Formulas)
end

local function level(data: any, id: string): number
	local upgrades = data.Upgrades
	return if type(upgrades) == "table" and type(upgrades[id]) == "number" then upgrades[id] else 0
end

function Formulas:upgradeLevel(data: any, id: string): number
	return level(data, id)
end

function Formulas:diceLuck(diceId: string?): number
	local dice = self.c.Dice.ById[diceId or ""] or self.c.Dice.ById[self.c.Dice.Default]
	return dice.LuckMultiplier
end

-- Boost de Luck temporário ativo (Diário). now = os.time() do servidor
function Formulas:luckBoost(data: any, now: number?): number
	local boost = type(data.Boosts) == "table" and data.Boosts.Luck
	if type(boost) == "table" and type(boost.Multiplier) == "number" and type(boost.ExpiresAt) == "number" then
		if now and now < boost.ExpiresAt then
			return math.max(1, boost.Multiplier)
		end
	end
	return 1
end

-- Luck efetiva = Luck do dado * (1 + nível * PerLevel) * boost. Nunca menor que 1.
function Formulas:luck(data: any, now: number?): number
	local upgrade = self.c.Upgrades.ById.Luck
	local base = self:diceLuck(data.EquippedDice) * (1 + level(data, "Luck") * upgrade.PerLevel)
	return math.max(1, base * self:luckBoost(data, now))
end

function Formulas:rollCooldown(data: any): number
	local roll = self.c.Roll
	local upgrade = self.c.Upgrades.ById.RollSpeed
	return math.max(roll.MinCooldown, roll.BaseCooldown * (1 - level(data, "RollSpeed") * upgrade.PerLevel))
end

function Formulas:capacity(data: any): number
	local upgrade = self.c.Upgrades.ById.Inventory
	return self.c.Roll.InventoryBaseCapacity + level(data, "Inventory") * upgrade.PerLevel
end

function Formulas:incomeMultiplier(data: any): number
	return 1 + level(data, "Income") * self.c.Upgrades.ById.Income.PerLevel
end

function Formulas:variant(id: string?): any
	local variants = self.c.Variants
	return variants.ById[id or ""] or variants.ById[variants.Default]
end

function Formulas:levelMultiplier(lvl: number?): number
	local l = math.clamp(math.floor(tonumber(lvl) or 1), 1, self.c.Levels.MaxLevel)
	return 1 + (l - 1) * self.c.Levels.IncomePerLevel
end

-- Poder de UMA unidade (Torres): BasePower * (1 + (Level-1) * PowerPerLevel) * Variante * bônus de Rebirth
function Formulas:unitPower(item: any, data: any?): number
	local character = item and self.c.Characters.ById[item.Id]
	if not character then
		return 0
	end
	local l = math.clamp(math.floor(tonumber(item.Level) or 1), 1, self.c.Levels.MaxLevel)
	local power = character.BasePower * (1 + (l - 1) * self.c.Levels.PowerPerLevel) * self:variant(item.Variant).PowerMultiplier
	return power * (if data then self:powerMultiplier(data) else 1)
end

-- Multiplicador global de poder (Rebirth / perks). Sem configuração = 1
function Formulas:powerMultiplier(data: any): number
	local rebirth = self.c.Rebirth
	if not rebirth then
		return 1
	end
	local perks = type(data.RebirthPerks) == "table" and data.RebirthPerks or {}
	local perk = rebirth.PerksById and rebirth.PerksById.Power
	return 1 + (data.Rebirths or 0) * (rebirth.PowerPerRebirth or 0) + (if perk then (perks.Power or 0) * perk.PerLevel else 0)
end

-- Renda/s de UMA unidade, sem multiplicadores globais (Level * Variant)
function Formulas:unitIncome(item: any): number
	local character = item and self.c.Characters.ById[item.Id]
	if not character then
		return 0
	end
	return character.BaseIncome * self:levelMultiplier(item.Level) * self:variant(item.Variant).IncomeMultiplier
end

-- Renda/s de uma unidade COM os multiplicadores globais (o que aparece na estação)
function Formulas:stationIncome(data: any, item: any): number
	return self:unitIncome(item) * self:incomeMultiplier(data)
end

-- Renda por segundo total = soma das estações * multiplicadores globais
function Formulas:incomePerSecond(data: any): number
	local total = 0
	for _, uid in data.EquippedCharacters or {} do
		local item = data.Inventory and data.Inventory[uid]
		if item then
			total += self:unitIncome(item)
		end
	end
	return total * self:incomeMultiplier(data)
end

--[[
	Custo para subir `count` níveis a partir de `currentLevel` (x1, x5, x10...).
	Retorna (custo total, níveis que realmente dá para subir até o MaxLevel).
	Custo de um nível L -> L+1 = BaseUpgradeCost * CostGrowth ^ (L - 1)
]]
function Formulas:characterUpgradeCost(characterId: string, currentLevel: number, count: number?): (number, number)
	local character = self.c.Characters.ById[characterId]
	if not character then
		return 0, 0
	end
	local levels = self.c.Levels
	local baseCost = character.BaseUpgradeCost or character.BaseIncome * levels.BaseCostSeconds
	local n = math.max(0, math.min(math.floor(count or 1), levels.MaxLevel - currentLevel))
	local total = 0
	for k = 0, n - 1 do
		total += math.floor(baseCost * levels.CostGrowth ^ (currentLevel - 1 + k))
	end
	return total, n
end

-- Quantos níveis dá para comprar com `money` (botão MAX). Retorna (níveis, custo)
function Formulas:affordableLevels(characterId: string, currentLevel: number, money: number): (number, number)
	local levels = self.c.Levels
	local count, spent = 0, 0
	while currentLevel + count < levels.MaxLevel do
		local cost = self:characterUpgradeCost(characterId, currentLevel + count, 1)
		if spent + cost > money then
			break
		end
		spent += cost
		count += 1
	end
	return count, spent
end

function Formulas:sellValue(characterId: string, variantId: string?): number
	local character = self.c.Characters.ById[characterId]
	if not character then
		return 0
	end
	local base = character.BaseIncome * (self.c.Economy.SellSeconds[character.Rarity] or 10)
	return math.floor(base * self:variant(variantId).SellMultiplier)
end

function Formulas:upgradeCost(id: string, currentLevel: number): number?
	local upgrade = self.c.Upgrades.ById[id]
	if not upgrade or currentLevel >= upgrade.MaxLevel then
		return nil
	end
	return math.floor(upgrade.BaseCost * upgrade.Growth ^ currentLevel)
end

return Formulas
