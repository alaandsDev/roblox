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

local function perkLevel(data: any, id: string): number
	local perks = data.RebirthPerks
	return if type(perks) == "table" and type(perks[id]) == "number" then perks[id] else 0
end

function Formulas:perkLevel(data: any, id: string): number
	return perkLevel(data, id)
end

-- Bônus permanentes do Renascimento: kind = "Luck" | "Income" | "Power"
function Formulas:rebirthMultiplier(data: any, kind: string): number
	local rebirth = self.c.Rebirth
	if not rebirth then
		return 1
	end
	local rebirths = if type(data.Rebirths) == "number" then data.Rebirths else 0
	local perRebirth = if kind == "Luck" then rebirth.LuckPerRebirth elseif kind == "Income" then rebirth.IncomePerRebirth else rebirth.PowerPerRebirth
	local fromRebirths = rebirths * perRebirth
	if kind == "Luck" and rebirth.LuckRebirthCap then
		fromRebirths = math.min(fromRebirths, rebirth.LuckRebirthCap)
	end
	local perk = rebirth.PerksById[kind]
	return 1 + fromRebirths + (if perk then perkLevel(data, kind) * perk.PerLevel else 0)
end

-- Multiplicadores de sessão (gamepasses, impulso de amigos) postos pelo servidor em data.Runtime
function Formulas:runtime(data: any, kind: string): number
	local runtime = data.Runtime
	local value = if type(runtime) == "table" then runtime[kind] else nil
	return if type(value) == "number" and value > 0 then value else 1
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
	return math.max(1, base * self:luckBoost(data, now) * self:rebirthMultiplier(data, "Luck") * self:runtime(data, "Luck"))
end

-- Luck que realmente entra nos pesos (retornos decrescentes; MESMA fórmula do RollCore)
function Formulas:effectiveLuck(data: any, now: number?): number
	local l = self:luck(data, now)
	local cap = self.c.Roll.LuckSoftCap
	if cap and cap > 0 then
		return 1 + (l - 1) / (1 + (l - 1) / cap)
	end
	return l
end

-- Tem o gamepass Roll Rápido nesta sessão? (posto pelo BoostService em data.Runtime)
function Formulas:hasFastRoll(data: any): boolean
	local runtime = data.Runtime
	return type(runtime) == "table" and runtime.FastRoll == true
end

-- Intervalo mínimo entre rolls (segundos). Ver RollConfig.RollSpeed
function Formulas:rollCooldown(data: any): number
	local speed = self.c.Roll.RollSpeed
	local interval = if self:hasFastRoll(data) then speed.FastRollInterval else speed.BaseInterval
	if speed.UpgradesAffectInterval then
		local upgrade = self.c.Upgrades.ById.RollSpeed
		local speedPerk = if self.c.Rebirth then perkLevel(data, "Speed") * self.c.Rebirth.PerksById.Speed.PerLevel else 0
		interval = math.max(speed.MinInterval, interval * (1 - level(data, "RollSpeed") * upgrade.PerLevel) * (1 - speedPerk))
	end
	return interval
end

-- Rolls por segundo no máximo (para simulações/HUD)
function Formulas:rollsPerSecond(data: any): number
	return 1 / self:rollCooldown(data)
end

-- Melhorias/perks de velocidade só existem se a config permitir (sem empilhar por acidente)
function Formulas:upgradeEnabled(id: string): boolean
	return id ~= "RollSpeed" or self.c.Roll.RollSpeed.UpgradesAffectInterval == true
end

function Formulas:perkEnabled(id: string): boolean
	return id ~= "Speed" or self.c.Roll.RollSpeed.UpgradesAffectInterval == true
end

function Formulas:capacity(data: any): number
	local upgrade = self.c.Upgrades.ById.Inventory
	local perk = if self.c.Rebirth then perkLevel(data, "Capacity") * self.c.Rebirth.PerksById.Capacity.PerLevel else 0
	return self.c.Roll.InventoryBaseCapacity + level(data, "Inventory") * upgrade.PerLevel + perk + self:runtimeAdd(data, "Capacity")
end

-- Valores somados de sessão (ex.: gamepass de mochila maior)
function Formulas:runtimeAdd(data: any, kind: string): number
	local runtime = data.Runtime
	local value = if type(runtime) == "table" then runtime[kind] else nil
	return if type(value) == "number" then value else 0
end

-- PLAYER AURA: maior tier COMPRADO (0..MaxTier). O visual equipado não importa aqui.
function Formulas:playerAuraTier(data: any): number
	local auras = self.c.PlayerAuras
	local aura = data.PlayerAura
	local owned = if type(aura) == "table" then aura.Owned else nil
	if not auras or type(owned) ~= "number" or owned ~= owned then
		return 0
	end
	return math.clamp(math.floor(owned), 0, auras.MaxTier)
end

-- Multiplicador de renda da Player Aura (×1 sem aura). Não empilha entre auras.
function Formulas:playerAuraMultiplier(data: any): number
	local tier = self:playerAuraTier(data)
	return if tier > 0 then self.c.PlayerAuras.List[tier].MoneyMultiplier else 1
end

-- WalkSpeed do avatar: base do jogo ou a da MAIOR aura comprada, sempre <= MaxWalkSpeed
function Formulas:walkSpeed(data: any?): number
	local movement = self.c.Movement
	local base = if movement then movement.BaseWalkSpeed else 16
	local tier = if data then self:playerAuraTier(data) else 0
	local speed = if tier > 0 then math.max(base, self.c.PlayerAuras.List[tier].WalkSpeed) else base
	return if movement then math.min(speed, movement.MaxWalkSpeed) else speed
end

-- Fator ÚNICO da renda/s: upgrade Renda × Rebirth × sessão (VIP/amigos) × Player Aura.
-- Tudo que é "renda/s" ou "N segundos de renda" (coletor, offline, Torre, Missão, Diário,
-- Jackpot) passa por aqui; venda, refund, troca, fusão e custos NÃO.
function Formulas:incomeMultiplier(data: any): number
	return (1 + level(data, "Income") * self.c.Upgrades.ById.Income.PerLevel)
		* self:rebirthMultiplier(data, "Income")
		* self:runtime(data, "Income")
		* self:playerAuraMultiplier(data)
end

function Formulas:rebirthCost(rebirths: number): number?
	local rebirth = self.c.Rebirth
	if not rebirth or rebirths >= rebirth.MaxRebirths then
		return nil
	end
	return math.floor(rebirth.BaseCost * rebirth.Growth ^ rebirths)
end

function Formulas:rebirthTokens(newRebirthCount: number): number
	local rebirth = self.c.Rebirth
	return rebirth.TokensBase + newRebirthCount // rebirth.TokensBonusEvery
end

function Formulas:perkCost(id: string, currentLevel: number): number?
	local perk = self.c.Rebirth and self.c.Rebirth.PerksById[id]
	if not perk or currentLevel >= perk.MaxLevel then
		return nil
	end
	return perk.BaseCost + currentLevel * perk.CostStep
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

-- Multiplicador global de poder (Rebirth + perk Power)
function Formulas:powerMultiplier(data: any): number
	return self:rebirthMultiplier(data, "Power")
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
