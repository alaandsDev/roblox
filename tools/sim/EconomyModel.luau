--!strict
--[[
	SIMULADOR ECONÔMICO (puro, determinístico por semente) — modelo ATUAL do jogo:
	  • roll por Dice: algoritmo IDÊNTICO ao DiceCore.roll (pesos aprovados, Luck real, pity 50/250,
	    Dice selecionado = o melhor desbloqueado); só os pesos ficam em cache por (Dice, Luck).
	    tests/EconomyModel.spec.luau prova a equivalência roll a roll com o DiceCore.
	  • números do jogo vêm dos módulos/configs reais: Formulas (renda, nível, venda, upgrades,
	    Luck, capacidade, rebirth), BattleCore (torres), DiceCore:prismPick (Prisma), configs de
	    Diário, Missões, Offline, Jackpot, Fusão, Monetização, BaseProgression.
	  • o jogador é um AGENTE (perfil): sessões por dia, AUTO, coleta, decisões periódicas.
	Usado por tools/sim/analyze_economy.luau (ECONOMY_BALANCE_ANALYSIS.md) e pelos testes.

	Hipóteses (documentadas no relatório): sem amigos no servidor; Jackpot com as gemas ganhas;
	missões diárias completadas com a probabilidade do perfil; personagem trocado na base é
	VENDIDO (o investimento em níveis volta só pelo refund simulado, 0% = jogo atual).
]]

local DiceCore = require("../../src/shared/Modules/DiceCore")
local Formulas = require("../../src/shared/Modules/Formulas")
local BattleCore = require("../../src/shared/Modules/BattleCore")
local JackpotCore = require("../../src/shared/Modules/JackpotCore")
local SaleCore = require("../../src/shared/Modules/SaleCore")
local DiceConfig = require("../../src/shared/Config/DiceConfig")
local CharacterConfig = require("../../src/shared/Config/CharacterConfig")
local RarityConfig = require("../../src/shared/Config/RarityConfig")
local RollConfig = require("../../src/shared/Config/RollConfig")
local UpgradeConfig = require("../../src/shared/Config/UpgradeConfig")
local EconomyConfig = require("../../src/shared/Config/EconomyConfig")
local LevelConfig = require("../../src/shared/Config/CharacterLevelConfig")
local VariantConfig = require("../../src/shared/Config/VariantConfig")
local RebirthConfig = require("../../src/shared/Config/RebirthConfig")
local TowerConfig = require("../../src/shared/Config/TowerConfig")
local DailyConfig = require("../../src/shared/Config/DailyConfig")
local MissionConfig = require("../../src/shared/Config/MissionConfig")
local OfflineIncomeConfig = require("../../src/shared/Config/OfflineIncomeConfig")
local JackpotConfig = require("../../src/shared/Config/JackpotConfig")
local FusionConfig = require("../../src/shared/Config/FusionConfig")
local MonetizationConfig = require("../../src/shared/Config/MonetizationConfig")
local PrismConfig = require("../../src/shared/Config/PrismConfig")
local IndexConfig = require("../../src/shared/Config/IndexConfig")
local BaseProgressionConfig = require("../../src/shared/Config/BaseProgressionConfig")
local Rng = require("../../tests/Rng")

local EconomyModel = {}

local core = DiceCore.new(DiceConfig, CharacterConfig, RarityConfig, RollConfig)
local formulas = Formulas.new({
	Dice = DiceConfig,
	Upgrades = UpgradeConfig,
	Roll = RollConfig,
	Economy = EconomyConfig,
	Characters = CharacterConfig,
	Levels = LevelConfig,
	Variants = VariantConfig,
	Rebirth = RebirthConfig,
})
local battle = BattleCore.new(TowerConfig, CharacterConfig, RarityConfig)
EconomyModel.core = core
EconomyModel.formulas = formulas

local DICE = core:diceList() -- ordem oficial
EconomyModel.DiceOrder = DICE
local TIER: { [string]: number } = {}
for _, r in RarityConfig.List do
	TIER[r.Id] = r.Tier
end
local VARIANTS = VariantConfig.List -- índice 1 = Normal ... 7 = Celestial
local VARIANT_INDEX: { [string]: number } = {}
for i, v in VARIANTS do
	VARIANT_INDEX[v.Id] = i
end

------------------------------------------------------------------------------------
-- ROLL (cache de pesos por Dice+Luck; mesma lógica do DiceCore.roll, sem alocar tabelas)

local PITY = RollConfig.Pity -- { Legendary 50, Mythic 250 }
local supportsCache: { [string]: { [string]: boolean } } = {}
for _, d in DICE do
	local s = {}
	for _, rule in PITY do
		s[rule.MinRarity] = core:supports(d.Id, rule.MinRarity)
	end
	supportsCache[d.Id] = s
end

local weightCache: { [string]: { rarities: { string }, weights: { number } } } = {}
local function weightsFor(diceId: string, luck: number): any
	local key = diceId .. "|" .. string.format("%.6f", luck)
	local cached = weightCache[key]
	if cached then
		return cached
	end
	local pool = core:pool(diceId)
	local w = core:rarityWeights(diceId, luck)
	local list = { rarities = pool.rarities, weights = {} }
	for i, rarity in pool.rarities do
		list.weights[i] = w[rarity]
	end
	weightCache[key] = list
	return list
end

-- pity: { Legendary = n, Mythic = n } (mutado no lugar). Devolve rarity, characterId, pityTriggered
function EconomyModel.roll(diceId: string, luck: number, pity: { [string]: number }, rand: () -> number): (string, string, string?)
	local supports = supportsCache[diceId]
	-- pityFor: regra compatível com contador+1 >= limite; maior raridade vence
	local floor, floorId, floorTier = nil, nil, 0
	for _, rule in PITY do
		if supports[rule.MinRarity] and (pity[rule.Id] or 0) + 1 >= rule.Threshold then
			local tier = TIER[rule.MinRarity]
			if tier > floorTier then
				floor, floorId, floorTier = rule.MinRarity, rule.Id, tier
			end
		end
	end
	-- pickRarity (mesmo algoritmo: target = rand() * 100, na ordem do pool)
	local cache = weightsFor(diceId, luck)
	local target = rand() * 100
	local rarity = cache.rarities[#cache.rarities]
	for i, r in cache.rarities do
		local w = cache.weights[i]
		if target < w then
			rarity = r
			break
		end
		target -= w
	end
	local triggered: string? = nil
	if floor then
		if TIER[rarity] < floorTier then
			rarity = floor
		end
		-- igual ao DiceCore: só NÃO conta como pity se o natural passou do piso
		if TIER[rarity] <= floorTier then
			triggered = floorId
		end
	end
	local characterId = core:pickCharacter(diceId, rarity, rand)
	-- nextPity
	local tier = TIER[rarity]
	for _, rule in PITY do
		if tier >= TIER[rule.MinRarity] then
			pity[rule.Id] = 0
		elseif supports[rule.MinRarity] then
			pity[rule.Id] = (pity[rule.Id] or 0) + 1
		end
	end
	return rarity, characterId, triggered
end

------------------------------------------------------------------------------------
-- CUSTOS (curva oficial) e VENDA COM REFUND

-- Investimento acumulado para chegar do nível 1 ao `level` (soma exata da curva oficial)
function EconomyModel.investedForLevel(characterId: string, level: number): number
	if level <= 1 then
		return 0
	end
	local total = formulas:characterUpgradeCost(characterId, 1, level - 1)
	return total
end

-- Venda com refund: base (Formulas:sellValue) + refund% × investimento ELEGÍVEL (nunca negativo)
-- (mesma conta do servidor: SaleCore.quote com o investimento gravado na instância)
function EconomyModel.saleValue(characterId: string, variantId: string?, invested: number, refundPercent: number): number
	local item = { Id = characterId, Variant = variantId, Level = 1, UpgradeInvestment = math.max(0, invested) }
	return SaleCore.quote(formulas, item, refundPercent).Total
end

-- Fusão: cópias Normais e dinheiro para levar UMA unidade da variante v para v+1
local function normalsFor(v: number): number
	local n = 1
	for i = 2, v do
		n *= FusionConfig.RequiredByTarget[VARIANTS[i].Id]
	end
	return n
end
local function fuseCost(characterId: string, toIndex: number): number
	return math.floor(CharacterConfig.ById[characterId].BaseIncome * FusionConfig.CostSeconds * VARIANTS[toIndex].Order)
end
local function makeCost(characterId: string, v: number): number
	if v <= 1 then
		return 0
	end
	return FusionConfig.RequiredByTarget[VARIANTS[v].Id] * makeCost(characterId, v - 1) + fuseCost(characterId, v)
end
-- (cópias Normais extras, dinheiro) para subir a unidade equipada de v para v+1
function EconomyModel.fusionStep(characterId: string, v: number): (number, number)
	local req = FusionConfig.RequiredByTarget[VARIANTS[v + 1].Id]
	return (req - 1) * normalsFor(v), (req - 1) * makeCost(characterId, v) + fuseCost(characterId, v + 1)
end

------------------------------------------------------------------------------------
-- PERFIS

export type Profile = {
	name: string,
	sessionsPerDay: { number }, -- duração (s) de cada sessão no dia
	rollActivity: number, -- fração dos segundos com roll (AUTO ligado)
	collectEvery: number,
	thinkEvery: number,
	levelPaybackSeconds: number, -- compra nível de estação se custo / Δrenda <= isso
	levelBudget: number, -- fração do dinheiro por decisão em níveis de estação
	incomeUpgradePayback: number,
	luckBudget: number, -- compra Luck se custo <= fração do dinheiro
	fusion: boolean,
	towersEvery: number?, -- segundos entre tentativas nas torres (nil = não joga)
	missionCompletion: number, -- probabilidade de completar cada missão diária
	jackpot: boolean,
	prismUse: number, -- probabilidade de usar o prisma quando disponível (por decisão)
	rebirth: string, -- "early" | "medium" | "late" | "never"
	passes: { string },
}

EconomyModel.Profiles = {
	Casual = {
		name = "Casual F2P",
		sessionsPerDay = { 20 * 60 },
		rollActivity = 0.7,
		collectEvery = 180,
		thinkEvery = 60,
		levelPaybackSeconds = 600,
		levelBudget = 0.3,
		incomeUpgradePayback = 600,
		luckBudget = 0.1,
		fusion = false,
		towersEvery = 900,
		missionCompletion = 0.6,
		jackpot = false,
		prismUse = 0.5,
		rebirth = "early",
		passes = {},
	} :: Profile,
	Ativo = {
		name = "Ativo F2P",
		sessionsPerDay = { 60 * 60, 60 * 60 },
		rollActivity = 1,
		collectEvery = 30,
		thinkEvery = 15,
		levelPaybackSeconds = 1200,
		levelBudget = 0.6,
		incomeUpgradePayback = 1800,
		luckBudget = 0.2,
		fusion = true,
		towersEvery = 300,
		missionCompletion = 1,
		jackpot = true,
		prismUse = 1,
		rebirth = "medium",
		passes = {},
	} :: Profile,
	Otimizador = {
		name = "Otimizador F2P",
		sessionsPerDay = { 2 * 60 * 60, 2 * 60 * 60 },
		rollActivity = 1,
		collectEvery = 10,
		thinkEvery = 5,
		levelPaybackSeconds = 1800,
		levelBudget = 0.8,
		incomeUpgradePayback = 3600,
		luckBudget = 0.15,
		fusion = true,
		towersEvery = 120,
		missionCompletion = 1,
		jackpot = true,
		prismUse = 1,
		rebirth = "medium",
		passes = {},
	} :: Profile,
	Pago = {
		name = "Pago Moderado",
		sessionsPerDay = { 60 * 60, 60 * 60 },
		rollActivity = 1,
		collectEvery = 30,
		thinkEvery = 15,
		levelPaybackSeconds = 1200,
		levelBudget = 0.6,
		incomeUpgradePayback = 1800,
		luckBudget = 0.2,
		fusion = true,
		towersEvery = 300,
		missionCompletion = 1,
		jackpot = true,
		prismUse = 1,
		rebirth = "medium",
		-- só o que existe em MonetizationConfig: Roll Rápido, VIP, Sorte x2, Mochila Gigante
		passes = { "FastRoll", "VIP", "LuckX2", "BigBackpack" },
	} :: Profile,
}

export type Options = {
	refundPercent: number?, -- 0 = jogo atual
	prism: { UsesPerReward: number, MaxCharges: number, CooldownSeconds: number }?,
	rebirth: string?, -- sobrepõe o perfil
	checkpoints: { number }?,
}

------------------------------------------------------------------------------------
-- JOGADOR

local function newPlayer(profile: Profile): any
	local runtime: { [string]: any } = { Income = 1, Luck = 1, FastRoll = false, Capacity = 0 }
	for _, key in profile.passes do
		for effect, value in MonetizationConfig.GamePasses[key].Effects or {} do
			if type(value) == "boolean" then
				runtime[effect] = value
			elseif effect == "Capacity" then
				runtime.Capacity += value
			else
				runtime[effect] *= value
			end
		end
	end
	local data = {
		EquippedDice = "Starter",
		Upgrades = { Luck = 0, Income = 0, RollSpeed = 0, Inventory = 0 },
		Rebirths = 0,
		RebirthPerks = {},
		Boosts = {},
		Runtime = runtime,
	}
	return {
		data = data, -- forma do save que o Formulas lê
		money = 0,
		uncollected = 0,
		earned = {} :: { [string]: number },
		spent = {} :: { [string]: number },
		rolls = 0,
		rollsByDice = {} :: { [string]: number },
		diceOwned = 1, -- quantos Dice (em ordem) o jogador tem
		ownedAt = { 0 } :: { number }, -- tempo ativo em que cada Dice foi comprado
		rollsAtPurchase = { 0 } :: { number },
		ipsAtPurchase = { 0 } :: { number }, -- renda/s quando comprou cada Dice
		rollUnlockAt = { 0 } :: { number }, -- tempo em que atingiu os rolls exigidos de cada Dice
		nextRollUnlock = 2,
		deadRolls = {} :: { [string]: number }, -- rolls num Dice já 100% completo (nada novo)
		swaps = 0, -- estações trocadas por personagem melhor (o antigo é vendido)
		prismWasted = 0, -- cargas perdidas por bater no teto
		index = {} :: { [string]: boolean },
		discovered = 0,
		discoveredByDice = {} :: { [string]: number },
		completion = {} :: { [string]: { [number]: number } }, -- Dice -> % -> tempo
		copies = {} :: { [string]: number },
		copiesTotal = 0,
		slots = {} :: { any },
		pity = { Legendary = 0, Mythic = 0 },
		pityTriggers = { Legendary = 0, Mythic = 0 },
		rebirthTimes = {} :: { number },
		tokens = 0,
		gems = 0,
		towers = {} :: { [string]: number },
		prismCharges = 0,
		prismOwned = false,
		prismUsed = 0,
		prismLast = -math.huge,
		dailyDay = 0,
		indexMilestones = {} :: { [number]: boolean },
		firsts = {} :: { [string]: number },
		duplicatesSold = 0,
		dupIncomeByDice = {} :: { [string]: number },
		investmentLost = 0,
		investmentRefunded = 0,
		stationLevelsBought = 0,
		ipsCache = 0,
		lastIps = 0,
	}
end

local function add(map: { [string]: number }, key: string, value: number)
	map[key] = (map[key] or 0) + value
end

local function earn(p: any, source: string, amount: number)
	amount = math.floor(amount)
	if amount <= 0 then
		return
	end
	p.money += amount
	add(p.earned, source, amount)
end

local function spend(p: any, sink: string, amount: number): boolean
	if p.money < amount then
		return false
	end
	p.money -= amount
	add(p.spent, sink, amount)
	return true
end

local function slotsAvailable(p: any): number
	local best = 0
	for rb in BaseProgressionConfig.Milestones do
		if rb <= p.data.Rebirths and rb > best then
			best = rb
		end
	end
	return #BaseProgressionConfig.Milestones[best].UnlockedSlots
end

local function itemOf(slot: any): any
	return { Id = slot.id, Level = slot.level, Variant = VARIANTS[slot.variant].Id }
end

local function recomputeIncome(p: any)
	local total = 0
	for _, slot in p.slots do
		total += formulas:unitIncome(itemOf(slot))
	end
	p.ipsCache = total * formulas:incomeMultiplier(p.data)
end

local function capacity(p: any): number
	return formulas:capacity(p.data)
end

local function inventoryCount(p: any): number
	return p.copiesTotal + #p.slots
end

local function selectedDice(p: any): string
	return DICE[p.diceOwned].Id
end

local function nextRebirthCost(p: any): number
	return formulas:rebirthCost(p.data.Rebirths) or math.huge
end

-- Registra um personagem obtido (roll, prisma ou prêmio)
local function obtain(p: any, characterId: string, rarity: string, now: number)
	local tierKey = "first" .. rarity
	if not p.firsts[tierKey] then
		p.firsts[tierKey] = now
	end
	if not p.index[characterId] then
		p.index[characterId] = true
		local character = CharacterConfig.ById[characterId]
		if character.LaunchPool == "F2P" then
			p.discovered += 1
			local diceId = core:diceOfCharacter(characterId) :: string
			p.discoveredByDice[diceId] = (p.discoveredByDice[diceId] or 0) + 1
			local total = #core:charactersFor(diceId)
			local done = p.discoveredByDice[diceId] / total
			local marks = p.completion[diceId] or {}
			p.completion[diceId] = marks
			for _, mark in { 50, 75, 90, 100 } do
				if done * 100 >= mark - 1e-9 and not marks[mark] then
					marks[mark] = now
				end
			end
			-- marcos do Índice (gemas)
			local percent = p.discovered / CharacterConfig.Count * 100
			for _, milestone in IndexConfig.Milestones do
				if percent >= milestone.Percent and not p.indexMilestones[milestone.Percent] then
					p.indexMilestones[milestone.Percent] = true
					p.gems += milestone.Reward.Amount
				end
			end
		end
	end
	p.copies[characterId] = (p.copies[characterId] or 0) + 1
	p.copiesTotal += 1
end

------------------------------------------------------------------------------------
-- DECISÕES

-- Vende cópias que não servem (fusão de equipados guarda as necessárias); devolve o total
local function sellDuplicates(p: any, profile: Profile, all: boolean)
	local keep: { [string]: number } = {}
	if profile.fusion then
		for _, slot in p.slots do
			if slot.variant < #VARIANTS then
				local need = EconomyModel.fusionStep(slot.id, slot.variant)
				keep[slot.id] = (keep[slot.id] or 0) + need
			end
		end
	end
	for id, n in p.copies do
		-- sempre guarda 1 cópia de cada personagem ainda não equipado (pode entrar na base)
		local reserve = keep[id] or 0
		local sellable = n - reserve
		if not all then
			sellable = math.min(sellable, n - 1)
		end
		if sellable > 0 and CharacterConfig.ById[id].Rarity ~= "Secret" then
			local value = formulas:sellValue(id, "Normal") * sellable
			p.copies[id] = n - sellable
			p.copiesTotal -= sellable
			p.duplicatesSold += sellable
			earn(p, "Sell", value)
			local diceId = core:diceOfCharacter(id)
			if diceId then
				add(p.dupIncomeByDice, diceId, value)
			end
		end
	end
end

-- Coloca na base os melhores (renda atual); o trocado é vendido (investimento: refund simulado)
local function equipBest(p: any, refund: number)
	local slots = slotsAvailable(p)
	local changed = false
	-- preenche slots vazios com a melhor cópia
	local function bestCopy(): (string?, number)
		local bestId, bestIncome = nil, -1
		for id, n in p.copies do
			if n > 0 then
				local income = CharacterConfig.ById[id].BaseIncome
				if income > bestIncome then
					bestId, bestIncome = id, income
				end
			end
		end
		return bestId, bestIncome
	end
	while #p.slots < slots do
		local id = bestCopy()
		if not id then
			break
		end
		p.copies[id] -= 1
		p.copiesTotal -= 1
		table.insert(p.slots, { id = id, variant = 1, level = 1, invested = 0 })
		changed = true
	end
	-- troca o pior equipado por uma cópia que já rende mais no nível 1
	for _ = 1, 40 do
		local id, income = bestCopy()
		if not id then
			break
		end
		local worst, worstIncome = nil, math.huge
		for i, slot in p.slots do
			local unit = formulas:unitIncome(itemOf(slot))
			if unit < worstIncome then
				worst, worstIncome = i, unit
			end
		end
		if not worst then
			break
		end
		-- troca se a cópia já rende mais agora, OU se o potencial (mesmo nível) é >= 2x e o
		-- jogador tem dinheiro para recolocar a nova em ~1/4 do nível da antiga
		local old0 = p.slots[worst]
		local potentialOld = CharacterConfig.ById[old0.id].BaseIncome * VARIANTS[old0.variant].IncomeMultiplier
		local better = income > worstIncome
			or (
				income >= 2 * potentialOld
				and p.money >= EconomyModel.investedForLevel(id, old0.level) * 0.25
				-- perder o investimento pesa: precisa ter em caixa o que NÃO volta na venda
				and p.money >= old0.invested * (1 - math.clamp(refund, 0, 1))
			)
		if not better then
			break
		end
		local old = p.slots[worst]
		local value = EconomyModel.saleValue(old.id, VARIANTS[old.variant].Id, old.invested, refund)
		p.investmentLost += old.invested - (value - formulas:sellValue(old.id, VARIANTS[old.variant].Id))
		p.investmentRefunded += value - formulas:sellValue(old.id, VARIANTS[old.variant].Id)
		earn(p, "SellUpgraded", value)
		p.swaps += 1
		p.copies[id] -= 1
		p.copiesTotal -= 1
		p.slots[worst] = { id = id, variant = 1, level = 1, invested = 0 }
		changed = true
	end
	if changed then
		recomputeIncome(p)
	end
end

local function buyDice(p: any): boolean
	local nextDice = DICE[p.diceOwned + 1]
	if not nextDice then
		return false
	end
	local req = nextDice.UnlockRequirement
	if p.rolls < (req.Rolls or 0) then
		return false
	end
	if not spend(p, "Dice", nextDice.Price) then
		return false
	end
	p.diceOwned += 1
	p.ownedAt[p.diceOwned] = p.now
	p.rollsAtPurchase[p.diceOwned] = p.rolls
	p.ipsAtPurchase[p.diceOwned] = p.ipsCache
	p.data.EquippedDice = nextDice.Id
	return true
end

-- Rebirth: "early" = assim que pagar; "medium" = paga e o próximo Dice custa mais que 2× o
-- rebirth (ou não há próximo); "late" = só depois do Celestial (ou com 4× o custo)
-- A política quer renascer no estado atual (ignorando o dinheiro)?
local function rebirthDesired(p: any, policy: string): boolean
	local cost = nextRebirthCost(p)
	if policy == "never" or cost == math.huge then
		return false
	end
	if policy == "early" then
		return true
	end
	local nextDice = DICE[p.diceOwned + 1]
	if policy == "medium" then
		return not nextDice or nextDice.Price > 2 * cost
	end
	return p.diceOwned >= 15 or p.money >= 4 * cost
end

local function wantsRebirth(p: any, policy: string): boolean
	return p.money >= nextRebirthCost(p) and rebirthDesired(p, policy)
end
EconomyModel._rebirthDesired = rebirthDesired

local function doRebirth(p: any, now: number)
	add(p.spent, "Rebirth", p.money) -- o renascimento zera o dinheiro (sink = tudo que havia)
	p.money = 0
	p.uncollected = 0
	p.data.Upgrades = { Luck = 0, Income = 0, RollSpeed = 0, Inventory = p.data.Upgrades.Inventory }
	p.data.Rebirths += 1
	p.tokens += formulas:rebirthTokens(p.data.Rebirths)
	for _ = 1, 30 do
		local bought = false
		for _, id in { "Income", "Luck", "Power", "Capacity" } do
			local level = formulas:perkLevel(p.data, id)
			local cost = formulas:perkCost(id, level)
			if cost and p.tokens >= cost and formulas:perkEnabled(id) then
				p.tokens -= cost
				p.data.RebirthPerks[id] = level + 1
				bought = true
				break
			end
		end
		if not bought then
			break
		end
	end
	table.insert(p.rebirthTimes, now)
	recomputeIncome(p)
end

local function buyUpgrades(p: any, profile: Profile)
	for _ = 1, 30 do
		local bought = false
		-- Renda por payback
		local incomeCost = formulas:upgradeCost("Income", p.data.Upgrades.Income)
		if incomeCost and p.ipsCache > 0 then
			local base = p.ipsCache / formulas:incomeMultiplier(p.data)
			local delta = base * UpgradeConfig.ById.Income.PerLevel * formulas:rebirthMultiplier(p.data, "Income") * formulas:runtime(p.data, "Income")
			if delta > 0 and incomeCost / delta <= profile.incomeUpgradePayback and spend(p, "UpgradeIncome", incomeCost) then
				p.data.Upgrades.Income += 1
				bought = true
			end
		end
		local luckCost = formulas:upgradeCost("Luck", p.data.Upgrades.Luck)
		if luckCost and luckCost <= p.money * profile.luckBudget and spend(p, "UpgradeLuck", luckCost) then
			p.data.Upgrades.Luck += 1
			bought = true
		end
		local invCost = formulas:upgradeCost("Inventory", p.data.Upgrades.Inventory)
		if invCost and inventoryCount(p) >= capacity(p) * 0.85 and invCost <= p.money * 0.2 and spend(p, "UpgradeInventory", invCost) then
			p.data.Upgrades.Inventory += 1
			bought = true
		end
		if not bought then
			break
		end
	end
	recomputeIncome(p)
end

local function levelStations(p: any, profile: Profile)
	local budget = p.money * profile.levelBudget
	local mult = formulas:incomeMultiplier(p.data)
	for _ = 1, 400 do
		local best, bestCost, bestPayback = nil, 0, math.huge
		for _, slot in p.slots do
			if slot.level < LevelConfig.MaxLevel then
				local cost = formulas:characterUpgradeCost(slot.id, slot.level, 1)
				local delta = CharacterConfig.ById[slot.id].BaseIncome * LevelConfig.IncomePerLevel * VARIANTS[slot.variant].IncomeMultiplier * mult
				local payback = cost / delta
				if payback < bestPayback then
					best, bestCost, bestPayback = slot, cost, payback
				end
			end
		end
		if not best or bestPayback > profile.levelPaybackSeconds or bestCost > budget or not spend(p, "StationLevels", bestCost) then
			break
		end
		budget -= bestCost
		best.level += 1
		best.invested += bestCost
		p.stationLevelsBought += 1
		if not p.firsts.firstStationUpgrade then
			p.firsts.firstStationUpgrade = p.now
		end
	end
	recomputeIncome(p)
end

local function fuse(p: any, profile: Profile)
	if not profile.fusion then
		return
	end
	local mult = formulas:incomeMultiplier(p.data)
	for _, slot in p.slots do
		while slot.variant < #VARIANTS do
			local normals, cost = EconomyModel.fusionStep(slot.id, slot.variant)
			if (p.copies[slot.id] or 0) < normals then
				break
			end
			local gain = formulas:unitIncome({ Id = slot.id, Level = slot.level, Variant = VARIANTS[slot.variant + 1].Id })
				- formulas:unitIncome(itemOf(slot))
			if gain * mult <= 0 or cost / (gain * mult) > profile.levelPaybackSeconds * 2 or not spend(p, "Fusion", cost) then
				break
			end
			p.copies[slot.id] -= normals
			p.copiesTotal -= normals
			slot.variant += 1
		end
	end
	recomputeIncome(p)
end

local function climbTowers(p: any, rand: () -> number)
	-- time = 5 de maior poder (estações + melhores cópias no nível 1)
	local units = {}
	for _, slot in p.slots do
		table.insert(units, { item = itemOf(slot) })
	end
	for id, n in p.copies do
		if n > 0 then
			table.insert(units, { item = { Id = id, Level = 1, Variant = "Normal" } })
		end
	end
	for _, u in units do
		u.power = formulas:unitPower(u.item, p.data)
	end
	table.sort(units, function(a, b)
		return a.power > b.power
	end)
	for _, tower in TowerConfig.List do
		local previous = tower.Unlock.Tower
		if previous and (p.towers[previous] or 0) < TowerConfig.ById[previous].Floors then
			return
		end
		while true do
			local floor = (p.towers[tower.Id] or 0) + 1
			if floor > tower.Floors or #units == 0 then
				break
			end
			local team = {}
			for i = 1, math.min(TowerConfig.TeamSize, #units) do
				table.insert(team, battle:card(units[i].item.Id, units[i].power, "team", i))
			end
			local result = battle:simulate(team, battle:enemies(tower, floor), rand)
			if not result.won then
				return
			end
			p.towers[tower.Id] = floor
			earn(p, "Tower", math.max(battle:enemyPower(tower, floor) * TowerConfig.MoneyPerPower, p.ipsCache * TowerConfig.IncomeSeconds))
			if floor % TowerConfig.GemsEvery == 0 then
				p.gems += TowerConfig.GemsPerMilestone
			end
			if floor == tower.Floors then
				p.gems += tower.CompletionGems
			end
		end
	end
end

local function luckNow(p: any): number
	return formulas:luck(p.data, p.now)
end

local function spinJackpot(p: any, rand: () -> number)
	while p.gems >= JackpotConfig.GemCost do
		p.gems -= JackpotConfig.GemCost
		local prize = JackpotCore.pick(JackpotConfig.Rewards, rand)
		if prize.Kind == "Money" then
			earn(p, "Jackpot", math.max(prize.Min, p.ipsCache * prize.Seconds))
		elseif prize.Kind == "Gems" then
			p.gems += prize.Amount
		elseif prize.Kind == "LuckBoost" then
			local merged = JackpotCore.mergeBoost(p.data.Boosts.Luck, prize.Multiplier, prize.Duration, p.now)
			p.data.Boosts.Luck = merged
		elseif prize.Kind == "Roll" then
			local diceId = core:grantDice(selectedDice(p), prize.MinRarity) or selectedDice(p)
			local rarity = core:pickWithFloor(diceId, luckNow(p), rand, prize.MinRarity)
			obtain(p, core:pickCharacter(diceId, rarity, rand), rarity, p.now)
		end
	end
end

local function usePrism(p: any, profile: Profile, prismCfg: any, rand: () -> number)
	while p.prismCharges > 0 and p.now - p.prismLast >= prismCfg.CooldownSeconds and rand() < profile.prismUse do
		-- o Prisma age no Dice SELECIONADO; se ele já está completo, o jogador seleciona o
		-- maior Dice que ainda tem personagem a descobrir (e volta depois)
		local target = nil
		for i = p.diceOwned, 1, -1 do
			local diceId = DICE[i].Id
			if (p.discoveredByDice[diceId] or 0) < #core:charactersFor(diceId) then
				target = diceId
				break
			end
		end
		if not target then
			return -- tudo completo: não gasta
		end
		local data = p.data
		local previous = data.EquippedDice
		data.EquippedDice = target
		local id = core:prismPick(target, p.index, luckNow(p), rand)
		data.EquippedDice = previous
		if not id then
			return -- Dice completo: não gasta
		end
		p.prismCharges -= 1
		p.prismUsed += 1
		p.prismLast = p.now
		obtain(p, id, CharacterConfig.ById[id].Rarity, p.now)
		if inventoryCount(p) >= capacity(p) then
			return
		end
	end
end

local function claimDaily(p: any, prismCfg: any)
	p.dailyDay = p.dailyDay % #DailyConfig.Rewards + 1
	local reward = DailyConfig.Rewards[p.dailyDay]
	if reward.Kind == "Money" then
		earn(p, "Daily", math.max(reward.Amount, p.ipsCache * (reward.IncomeSeconds or 0)))
	elseif reward.Kind == "Gems" then
		p.gems += reward.Amount
	elseif reward.Kind == "LuckBoost" then
		p.data.Boosts.Luck = JackpotCore.mergeBoost(p.data.Boosts.Luck, reward.Multiplier, reward.Duration, p.now)
	elseif reward.Kind == "Dice" then
		if p.prismOwned then
			p.gems += reward.Fallback.Amount
		end
		p.prismOwned = true
		local total = p.prismCharges + prismCfg.UsesPerReward
		p.prismWasted += math.max(0, total - prismCfg.MaxCharges)
		p.prismCharges = math.min(prismCfg.MaxCharges, total)
	end
end

local function missions(p: any, profile: Profile, rand: () -> number)
	local pool = table.clone(MissionConfig.Pool)
	for _ = 1, MissionConfig.DailyCount do
		local i = math.clamp(math.floor(rand() * #pool) + 1, 1, #pool)
		local mission = table.remove(pool, i)
		if rand() < profile.missionCompletion then
			local r = mission.Reward
			if r.Kind == "Money" then
				earn(p, "Mission", math.max(r.Amount, p.ipsCache * (r.IncomeSeconds or 0)))
			else
				p.gems += r.Amount
			end
		end
	end
end

------------------------------------------------------------------------------------
-- SIMULAÇÃO

EconomyModel.DefaultCheckpoints = { 5 * 60, 10 * 60, 20 * 60, 30 * 60, 3600, 3 * 3600, 5 * 3600, 10 * 3600, 20 * 3600 }

-- Patrimônio = saldo + coletor + valor de venda de TUDO (estações com refund% + cópias)
function EconomyModel.patrimony(p: any, refund: number): number
	local total = p.money + p.uncollected
	for _, slot in p.slots do
		total += EconomyModel.saleValue(slot.id, VARIANTS[slot.variant].Id, slot.invested, refund)
	end
	for id, n in p.copies do
		if n > 0 then
			total += formulas:sellValue(id, "Normal") * n
		end
	end
	return total
end

local function snapshot(p: any, now: number): any
	local levels, count = 0, 0
	for _, slot in p.slots do
		levels += slot.level
		count += 1
	end
	local earned = 0
	for _, v in p.earned do
		earned += v
	end
	return {
		time = now,
		money = p.money,
		earned = earned,
		rolls = p.rolls,
		dice = p.diceOwned,
		diceId = selectedDice(p),
		discovered = p.discovered,
		rebirths = p.data.Rebirths,
		avgLevel = if count > 0 then levels / count else 0,
		ips = p.ipsCache,
		upgrades = table.clone(p.data.Upgrades),
		prismUsed = p.prismUsed,
		prismCharges = p.prismCharges,
		duplicatesSold = p.duplicatesSold,
		towerFloors = (p.towers.Ember or 0) + (p.towers.Storm or 0) + (p.towers.Void or 0),
		slots = count,
		earnedBy = table.clone(p.earned),
		spentBy = table.clone(p.spent),
		patrimony = EconomyModel.patrimony(p, p.refund or 0),
	}
end

-- Gerador por jogador. tests/Rng faz bor(seed, 1) (sementes 2k e 2k+1 dariam o MESMO jogador)
-- e sementes vizinhas começam correlacionadas: espalha a semente (hash multiplicativo) e
-- descarta os primeiros valores.
function EconomyModel.rng(seed: number): () -> number
	local mixed = (math.floor(seed) * 2654435761 + 40503) % 4294967296
	local rand = Rng.new(mixed)
	for _ = 1, 16 do
		rand()
	end
	return rand
end

-- Roda UM jogador por `activeSeconds` de jogo ATIVO (sessões por dia do perfil; o resto é offline)
function EconomyModel.run(profile: Profile, activeSeconds: number, seed: number, options: Options?): any
	local opts: Options = options or {}
	local refund = opts.refundPercent or 0
	local prismCfg = opts.prism or PrismConfig
	local policy = opts.rebirth or profile.rebirth
	local checkpoints = opts.checkpoints or EconomyModel.DefaultCheckpoints
	local rand = EconomyModel.rng(seed)
	local p = newPlayer(profile)
	p.now = 0
	p.refund = refund
	local snapshots = {}
	local nextCheckpoint = 1
	local interval = formulas:rollCooldown(p.data)
	local rollsPerSecond = math.floor(1 / interval + 0.5)
	local day = 0
	local lastSessionEnd: number? = nil -- relógio de parede (s)
	local wall = 0
	recomputeIncome(p)
	while p.now < activeSeconds do
		day += 1
		claimDaily(p, prismCfg)
		local missionsDone = false
		for sessionIndex, length in profile.sessionsPerDay do
			if p.now >= activeSeconds then
				break
			end
			-- relógio de parede: sessões espalhadas no dia
			local sessionStart = (day - 1) * 86400 + (sessionIndex - 1) * 8 * 3600 + 18 * 3600
			if lastSessionEnd then
				local offline = sessionStart - lastSessionEnd
				if offline >= OfflineIncomeConfig.MinSeconds then
					local amount = p.lastIps * math.min(offline, OfflineIncomeConfig.MaxSeconds) * OfflineIncomeConfig.Multiplier
					amount = math.min(amount, nextRebirthCost(p) * OfflineIncomeConfig.MaxRebirthFraction)
					earn(p, "Offline", amount)
				end
			end
			wall = sessionStart
			local sessionEnd = p.now + length
			while p.now < sessionEnd and p.now < activeSeconds do
				p.now += 1
				-- rolls (AUTO na cadência oficial)
				if rand() < profile.rollActivity then
					for _ = 1, rollsPerSecond do
						if inventoryCount(p) >= capacity(p) then
							sellDuplicates(p, profile, false)
							if inventoryCount(p) >= capacity(p) then
								break
							end
						end
						local diceId = selectedDice(p)
						local rarity, id, triggered = EconomyModel.roll(diceId, luckNow(p), p.pity, rand)
						if triggered then
							p.pityTriggers[triggered] += 1
						end
						p.rolls += 1
						p.rollsByDice[diceId] = (p.rollsByDice[diceId] or 0) + 1
						if (p.discoveredByDice[diceId] or 0) >= #core:charactersFor(diceId) then
							p.deadRolls[diceId] = (p.deadRolls[diceId] or 0) + 1
						end
						while DICE[p.nextRollUnlock] and p.rolls >= (DICE[p.nextRollUnlock].UnlockRequirement.Rolls or 0) do
							p.rollUnlockAt[p.nextRollUnlock] = p.now
							p.nextRollUnlock += 1
						end
						obtain(p, id, rarity, p.now)
					end
				end
				-- renda passiva no coletor (teto de 1 h de renda)
				p.uncollected = math.min(p.uncollected + p.ipsCache, math.max(p.ipsCache * EconomyConfig.MaxUncollectedSeconds, p.uncollected))
				if p.now % profile.collectEvery == 0 then
					earn(p, "Collector", p.uncollected)
					p.uncollected = 0
				end
				if p.now % profile.thinkEvery == 0 then
					if wantsRebirth(p, policy) then
						doRebirth(p, p.now)
					end
					equipBest(p, refund)
					while buyDice(p) do
					end
					-- guardando para o rebirth (já tem metade): não gasta em melhorias/níveis/fusão
					local saving = policy ~= "late" and rebirthDesired(p, policy) and p.money >= nextRebirthCost(p) * 0.5
					if not saving then
						fuse(p, profile)
						buyUpgrades(p, profile)
						levelStations(p, profile)
					end
					if profile.jackpot then
						spinJackpot(p, rand)
					end
					if p.prismOwned then
						usePrism(p, profile, prismCfg, rand)
					end
					if inventoryCount(p) >= capacity(p) * 0.9 then
						sellDuplicates(p, profile, false)
					end
				end
				if profile.towersEvery and p.now % profile.towersEvery == 0 then
					climbTowers(p, rand)
				end
				if not missionsDone and p.now % 600 == 0 then
					missionsDone = true
					missions(p, profile, rand)
				end
				p.lastIps = p.ipsCache
				if nextCheckpoint <= #checkpoints and p.now == checkpoints[nextCheckpoint] then
					table.insert(snapshots, snapshot(p, p.now))
					nextCheckpoint += 1
				end
			end
			earn(p, "Collector", p.uncollected)
			p.uncollected = 0
			lastSessionEnd = wall + length
		end
	end
	return {
		snapshots = snapshots,
		player = p,
		days = day,
	}
end

return EconomyModel
