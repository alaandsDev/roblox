-- Balanceamento APLICADO (ECONOMY_BALANCE_ANALYSIS.md): refund 75% por instância, fusão/troca
-- carregando investimento, migração v4, cap de nível 30, preços/rolls, duplicatas, Rebirth, offline,
-- marcos do Índice, loja de gemas e Prisma inalterado. Os fluxos de servidor são reproduzidos com
-- os MESMOS módulos puros que os Services usam (SaleCore, FusionCore, TradeCore, InventoryCore).
local T = require("./TestLib")
local SaleCore = require("../src/shared/Modules/SaleCore")
local Formulas = require("../src/shared/Modules/Formulas")
local DiceCore = require("../src/shared/Modules/DiceCore")
local MissionCore = require("../src/shared/Modules/MissionCore")
local OfflineCore = require("../src/shared/Modules/OfflineCore")
local FusionCore = require("../src/server/Core/FusionCore")
local TradeCore = require("../src/server/Core/TradeCore")
local InventoryCore = require("../src/server/Core/InventoryCore")
local Migrations = require("../src/server/Core/Migrations")
local CharacterConfig = require("../src/shared/Config/CharacterConfig")
local LevelConfig = require("../src/shared/Config/CharacterLevelConfig")
local VariantConfig = require("../src/shared/Config/VariantConfig")
local EconomyConfig = require("../src/shared/Config/EconomyConfig")
local FusionConfig = require("../src/shared/Config/FusionConfig")
local DiceConfig = require("../src/shared/Config/DiceConfig")
local RebirthConfig = require("../src/shared/Config/RebirthConfig")
local OfflineIncomeConfig = require("../src/shared/Config/OfflineIncomeConfig")
local MissionConfig = require("../src/shared/Config/MissionConfig")
local JackpotConfig = require("../src/shared/Config/JackpotConfig")
local PrismConfig = require("../src/shared/Config/PrismConfig")
local RarityConfig = require("../src/shared/Config/RarityConfig")
local RollConfig = require("../src/shared/Config/RollConfig")
local describe, it, expect = T.describe, T.it, T.expect

local f = Formulas.new({
	Dice = DiceConfig,
	Upgrades = require("../src/shared/Config/UpgradeConfig"),
	Roll = RollConfig,
	Economy = EconomyConfig,
	Characters = CharacterConfig,
	Levels = LevelConfig,
	Variants = VariantConfig,
	Rebirth = RebirthConfig,
})
local R = EconomyConfig.UpgradeRefundPercent
local ID = "dragon_knight"

local function newData(): any
	return { Inventory = {}, NextUid = 1, EquippedCharacters = {}, Trade = nil }
end

-- MESMA regra do InventoryService.UpgradeCharacter: cobra o custo e soma na instância
local function upgrade(item: any, levels: number): number
	local cost, n = f:characterUpgradeCost(item.Id, item.Level, levels)
	item.UpgradeInvestment = SaleCore.invested(f, item) + cost
	item.Level += n
	return cost
end

local function sell(item: any): SaleCore.Quote
	return SaleCore.quote(f, item, R)
end

local fusionConfigs = { Fusion = FusionConfig, Variants = VariantConfig, Characters = CharacterConfig, Inventory = InventoryCore }

-- MESMA sequência do FusionService.Fuse
local function fuse(data: any, uids: { string }): (string?, number)
	local plan, err = FusionCore.plan(data, uids, fusionConfigs)
	assert(plan, err)
	local invested = FusionCore.investment(data, uids, function(item)
		return SaleCore.invested(f, item)
	end)
	for _, uid in uids do
		InventoryCore.remove(data, uid)
	end
	local uid = InventoryCore.add(data, plan.characterId, 0, plan.toVariant)
	data.Inventory[uid].Level = plan.level
	data.Inventory[uid].UpgradeInvestment = invested
	return uid, plan.cost
end

describe("Balanceamento aplicado: venda com refund 75% por instância", function()
	it("config: 75%; venda de nível 1 = só a base", function()
		expect(R).toBe(0.75)
		local item = { Id = ID, Level = 1, Variant = "Normal" }
		expect(sell(item).Total).toBe(f:sellValue(ID, "Normal"))
	end)

	it("upgrade -> venda nos níveis 1/2/10/20/30, todas as variantes: recebe base + 75% do pago, nunca lucro", function()
		for _, v in VariantConfig.List do
			for _, target in { 1, 2, 10, 20, 30 } do
				local item = { Id = ID, Level = 1, Variant = v.Id }
				local paid = upgrade(item, target - 1)
				expect(item.Level).toBe(target)
				expect(item.UpgradeInvestment).toBe(paid)
				local q = sell(item)
				expect(q.Invested).toBe(paid)
				expect(q.Refund).toBe(math.floor(paid * 0.75))
				expect(q.Total).toBe(f:sellValue(ID, v.Id) + math.floor(paid * 0.75))
				-- o ciclo comprar níveis + vender nunca rende mais que vender sem nível
				expect(q.Total - paid <= q.Base).toBeTruthy()
			end
		end
	end)

	it("upgrades em várias compras somam exatamente o pago (igual à curva)", function()
		local item = { Id = ID, Level = 1, Variant = "Normal" }
		local paid = 0
		for _ = 1, 29 do
			paid += upgrade(item, 1)
		end
		expect(item.Level).toBe(30)
		expect(item.UpgradeInvestment).toBe(paid)
		expect(paid).toBe(SaleCore.curveInvestment(f, ID, 30))
	end)

	it("personagem antigo (sem investimento gravado): curva oficial; ao upar, curva + custo novo", function()
		local legacy = { Id = ID, Level = 10, Variant = "Normal" }
		local curve = SaleCore.curveInvestment(f, ID, 10)
		expect(sell(legacy).Invested).toBe(curve)
		local cost = upgrade(legacy, 1)
		expect(legacy.UpgradeInvestment).toBe(curve + cost)
	end)

	it("upgrade -> troca -> venda: investimento viaja com a instância; nada é criado", function()
		local a, b = newData(), newData()
		local uid = InventoryCore.add(a, ID, 0, "Normal")
		local paid = upgrade(a.Inventory[uid], 9)
		local giveB = InventoryCore.add(b, "flame_rookie", 0, "Normal")
		local ok, err, forA, forB = TradeCore.execute(a, b, { uid }, { giveB }, 100, 100, 0, InventoryCore)
		expect(ok).toBe(true)
		expect(err).toBeNil()
		expect(a.Inventory[uid]).toBeNil()
		local received = b.Inventory[forB[1]]
		expect(received.Level).toBe(10)
		expect(received.UpgradeInvestment).toBe(paid)
		expect(sell(received).Total).toBe(f:sellValue(ID, "Normal") + math.floor(paid * 0.75))
		expect(#forA).toBe(1)
	end)

	it("upgrade -> fusão -> venda: a nova unidade soma o investimento das consumidas, uma vez", function()
		local data = newData()
		local uids, paid = {}, 0
		for i = 1, 3 do
			local uid = InventoryCore.add(data, ID, 0, "Normal")
			paid += upgrade(data.Inventory[uid], i * 3) -- níveis 4, 7, 10
			table.insert(uids, uid)
		end
		local fused = fuse(data, uids)
		assert(fused)
		for _, uid in uids do
			expect(data.Inventory[uid]).toBeNil() -- consumidas somem: investimento não fica em 2 lugares
		end
		local item = data.Inventory[fused]
		expect(item.Variant).toBe("Silver")
		expect(item.Level).toBe(10) -- maior nível das consumidas
		expect(item.UpgradeInvestment).toBe(paid)
		local q = sell(item)
		expect(q.Total).toBe(f:sellValue(ID, "Silver") + math.floor(paid * 0.75))
		expect(q.Refund < paid).toBeTruthy()
	end)

	it("fusão com uid repetido é recusada (não soma investimento duas vezes)", function()
		local data = newData()
		local uid = InventoryCore.add(data, ID, 0, "Normal")
		upgrade(data.Inventory[uid], 5)
		local other = InventoryCore.add(data, ID, 0, "Normal")
		local plan, err = FusionCore.plan(data, { uid, uid, other }, fusionConfigs)
		expect(plan).toBeNil()
		expect(err).toBe("fusion_count")
		expect(FusionCore.investment(data, { uid, uid }, function(item)
			return SaleCore.invested(f, item)
		end)).toBe(data.Inventory[uid].UpgradeInvestment)
	end)

	it("upgrade -> fusão -> troca -> venda: nenhum fluxo gera dinheiro do nada", function()
		local a, b = newData(), newData()
		local uids, paidLevels = {}, 0
		for _ = 1, 3 do
			local uid = InventoryCore.add(a, ID, 0, "Normal")
			paidLevels += upgrade(a.Inventory[uid], 8)
			table.insert(uids, uid)
		end
		local fused, fusionCost = fuse(a, uids)
		assert(fused)
		local giveB = InventoryCore.add(b, "flame_rookie", 0, "Normal")
		local ok, _, _, forB = TradeCore.execute(a, b, { fused }, { giveB }, 100, 100, 0, InventoryCore)
		expect(ok).toBe(true)
		local got = sell(b.Inventory[forB[1]])
		expect(got.Invested).toBe(paidLevels)
		-- tudo que entrou na unidade (3 bases + níveis + fusão) é maior que o que sai na venda
		local spentTotal = paidLevels + fusionCost
		local baseOfInputs = 3 * f:sellValue(ID, "Normal")
		expect(got.Total < spentTotal + baseOfInputs).toBeTruthy()
		expect(got.Total - got.Base <= paidLevels).toBeTruthy()
	end)

	it("fusão repetida (Normal -> Prata -> Ouro): soma acumula sem duplicar", function()
		local data = newData()
		local silvers, paid = {}, 0
		for _ = 1, 3 do
			local trio = {}
			for _ = 1, 3 do
				local uid = InventoryCore.add(data, ID, 0, "Normal")
				paid += upgrade(data.Inventory[uid], 4)
				table.insert(trio, uid)
			end
			table.insert(silvers, (fuse(data, trio)))
		end
		local gold = fuse(data, silvers)
		assert(gold)
		expect(data.Inventory[gold].Variant).toBe("Gold")
		expect(data.Inventory[gold].UpgradeInvestment).toBe(paid)
		local total = 0
		for _, item in data.Inventory do
			total += SaleCore.invested(f, item)
		end
		expect(total).toBe(paid) -- o investimento existe em UM lugar só
	end)

	it("troca repetida (A -> B -> A) e save/load JSON: investimento intacto, uma cópia só", function()
		local a, b = newData(), newData()
		local uid = InventoryCore.add(a, ID, 0, "Normal")
		local paid = upgrade(a.Inventory[uid], 12)
		local current, owner, other = uid, a, b
		for _ = 1, 4 do
			local filler = InventoryCore.add(other, "flame_rookie", 0, "Normal")
			local ok, _, forOwner, forOther = TradeCore.execute(owner, other, { current }, { filler }, 100, 100, 0, InventoryCore)
			expect(ok).toBe(true)
			expect(#forOwner).toBe(1)
			current = forOther[1]
			owner, other = other, owner
		end
		local item = owner.Inventory[current]
		expect(item.UpgradeInvestment).toBe(paid)
		local copies = 0
		for _, data in { a, b } do
			for _, it2 in data.Inventory do
				if it2.Id == ID then
					copies += 1
				end
			end
		end
		expect(copies).toBe(1)
		-- save/load: o campo é número simples e sobrevive ao JSON do DataStore
		local roundTrip = { Id = item.Id, Level = item.Level, Variant = item.Variant, UpgradeInvestment = tonumber(tostring(item.UpgradeInvestment)) }
		expect(sell(roundTrip).Total).toBe(sell(item).Total)
	end)
end)

describe("Balanceamento aplicado: migração v4 (investimento + cap 30)", function()
	local function withContext(fn: () -> ())
		local old = Migrations.Context
		Migrations.Context = {
			investmentOf = function(id: string, level: number): number
				return SaleCore.curveInvestment(f, id, level)
			end,
			maxLevel = LevelConfig.MaxLevel,
		}
		fn()
		Migrations.Context = old
	end

	it("grava a curva no nível SALVO e corta acima de 30 sem perder investimento; não dá dinheiro", function()
		withContext(function()
			local data = {
				Money = 123,
				Inventory = {
					c1 = { Id = ID, Level = 1, Variant = "Normal" },
					c2 = { Id = ID, Level = 20, Variant = "Gold" },
					c3 = { Id = ID, Level = 45, Variant = "Normal" },
					c4 = { Id = ID, Level = 12, Variant = "Normal", UpgradeInvestment = 777 },
					c5 = { Id = ID, Level = 8, Variant = "Normal", UpgradeInvestment = -5 },
				},
			}
			local out = Migrations[4](data)
			expect(out.Money).toBe(123)
			expect(out.Inventory.c1.UpgradeInvestment).toBeNil()
			expect(out.Inventory.c2.UpgradeInvestment).toBe(SaleCore.curveInvestment(f, ID, 20))
			expect(out.Inventory.c2.Level).toBe(20)
			expect(out.Inventory.c3.Level).toBe(30)
			expect(out.Inventory.c3.UpgradeInvestment).toBe(SaleCore.curveInvestment(f, ID, 45))
			expect(out.Inventory.c3.UpgradeInvestment > SaleCore.curveInvestment(f, ID, 30)).toBeTruthy()
			expect(out.Inventory.c4.UpgradeInvestment).toBe(777) -- já gravado pelo servidor: mantido
			expect(out.Inventory.c5.UpgradeInvestment).toBe(SaleCore.curveInvestment(f, ID, 8))
			-- idempotente: rodar de novo não muda nada (nunca soma duas vezes)
			local again = Migrations[4](out)
			expect(again.Inventory.c3.UpgradeInvestment).toBe(SaleCore.curveInvestment(f, ID, 45))
		end)
	end)

	it("sem contexto: não corta nível nem grava (o fallback da curva cobre)", function()
		local data = { Inventory = { c1 = { Id = ID, Level = 45 } } }
		local out = Migrations[4](data)
		expect(out.Inventory.c1.Level).toBe(45)
		expect(out.Inventory.c1.UpgradeInvestment).toBeNil()
		expect(SaleCore.invested(f, out.Inventory.c1)).toBe(SaleCore.curveInvestment(f, ID, 45))
	end)
end)

describe("Balanceamento aplicado: números", function()
	it("nível máximo 30: renda para em 30 e não há custo para passar dele", function()
		expect(LevelConfig.MaxLevel).toBe(30)
		local cost, n = f:characterUpgradeCost(ID, 30, 1)
		expect(cost).toBe(0)
		expect(n).toBe(0)
		expect(f:unitIncome({ Id = ID, Level = 45 })).toBe(f:unitIncome({ Id = ID, Level = 30 }))
	end)

	it("Forbidden 400M; rolls Shinobi 300 / Flame 450 / Blade 650; demais iguais", function()
		local byId = DiceConfig.ById
		expect(byId.Forbidden.Price).toBe(400000000)
		expect(byId.Shinobi.UnlockRequirement.Rolls).toBe(300)
		expect(byId.Flame.UnlockRequirement.Rolls).toBe(450)
		expect(byId.Blade.UnlockRequirement.Rolls).toBe(650)
		expect(byId.Fighter.UnlockRequirement.Rolls).toBe(775)
		expect(byId.Forbidden.UnlockRequirement.Rolls).toBe(12000)
		-- pesos do Forbidden/Celestial intocados
		expect(byId.Forbidden.RarityWeights.Secret).toBe(0.0045)
		expect(byId.Celestial.RarityWeights.Divine).toBe(0.5)
		-- requisitos crescem na ordem oficial
		local last = -1
		for _, dice in DiceConfig.List do
			if dice.Pool == "F2P" then
				local r = dice.UnlockRequirement.Rolls or 0
				expect(r > last).toBeTruthy()
				last = r
			end
		end
	end)

	it("desbloqueio: rolls totais + rolls COM o Dice anterior (sem compra em cascata)", function()
		local flame = DiceConfig.ById.Flame
		local data = { OwnedDice = { Starter = true, Lucky = true, Rampart = true, Shinobi = true }, Rolls = 1000, DiceRolls = {} }
		local reason, missing = DiceCore.unlockBlocker(flame, data)
		expect(reason).toBe("requires_dice_rolls")
		expect(missing).toBe(DiceConfig.RollsOnPrevious)
		data.DiceRolls.Shinobi = DiceConfig.RollsOnPrevious
		expect(DiceCore.unlockBlocker(flame, data)).toBeNil()
		data.Rolls = 100
		expect(DiceCore.unlockBlocker(flame, data)).toBe("requires_rolls")
		expect(DiceCore.unlockBlocker(flame, { OwnedDice = { Starter = true }, Rolls = 99999, DiceRolls = { Shinobi = 999 } })).toBe("requires_previous")
		expect(DiceCore.unlockBlocker(DiceConfig.ById.Starter, { OwnedDice = {} })).toBeNil()
	end)

	it("venda base (duplicatas) 20–90 s de renda, monotônica por raridade", function()
		local expected = { Common = 20, Uncommon = 20, Rare = 25, Epic = 30, Legendary = 35, Mythic = 45, Divine = 60, Secret = 90 }
		local last = 0
		local list = table.clone(RarityConfig.List)
		table.sort(list, function(a, b)
			return a.Tier < b.Tier
		end)
		for _, r in list do
			local s = EconomyConfig.SellSeconds[r.Id]
			expect(s).toBe(expected[r.Id])
			expect(s >= last).toBeTruthy()
			last = s
		end
	end)

	it("Rebirth: 15M × 2,2^n (sequência)", function()
		expect(f:rebirthCost(0)).toBe(15000000)
		expect(f:rebirthCost(1)).toBe(33000000)
		expect(f:rebirthCost(2)).toBe(math.floor(15000000 * 2.2 ^ 2))
		for n = 1, RebirthConfig.MaxRebirths - 1 do
			expect(f:rebirthCost(n) > (f:rebirthCost(n - 1) :: number)).toBeTruthy()
		end
	end)

	it("offline: teto de 25% do próximo Rebirth", function()
		expect(OfflineIncomeConfig.MaxRebirthFraction).toBe(0.25)
		expect(OfflineIncomeConfig.Multiplier).toBe(0.12) -- offline continua existindo
		-- 8 h offline com renda alta: o valor bruto passa do teto e é cortado em 25% de 15M
		local amount = OfflineCore.compute(1000000, 1000000 + 8 * 3600, 10000, OfflineIncomeConfig)
		expect(amount > 0).toBeTruthy()
		expect(math.min(amount, (f:rebirthCost(0) :: number) * OfflineIncomeConfig.MaxRebirthFraction)).toBe(3750000)
	end)

	it("conquista do Índice: 14/28/56/112 (12,5/25/50/100% do roster F2P); Premium não conta", function()
		local index
		for _, a in MissionConfig.Achievements do
			if a.Id == "index" then
				index = a
			end
		end
		expect(index.Tiers[1]).toBe(14)
		expect(index.Tiers[4]).toBe(CharacterConfig.Count)
		expect(CharacterConfig.Count).toBe(112)
		for i, frac in { 0.125, 0.25, 0.5, 1 } do
			expect(index.Tiers[i]).toBe(math.floor(CharacterConfig.Count * frac))
		end
		local data = { Index = {}, Missions = { Achievements = {} } }
		local n = 0
		for _, c in CharacterConfig.List do
			if c.LaunchPool == "F2P" and n < 13 then
				data.Index[c.Id] = { Count = 1 }
				n += 1
			end
		end
		for _, c in CharacterConfig.Premium do
			data.Index[c.Id] = { Count = 1 }
		end
		expect(MissionCore.stat(data, "Discovered", CharacterConfig.ById)).toBe(13)
		expect(MissionCore.claimableTier(data, index, CharacterConfig.ById)).toBeNil()
	end)

	it("loja de gemas: pacote de dinheiro 60 gemas; Prisma inalterado (3 / 21 / 30 s)", function()
		local pack
		for _, entry in JackpotConfig.GemShop do
			if entry.Id == "MoneyPack" then
				pack = entry
			end
		end
		expect(pack.Cost).toBe(60)
		expect(pack.Seconds).toBe(900)
		expect(PrismConfig.UsesPerReward).toBe(3)
		expect(PrismConfig.MaxCharges).toBe(21)
		expect(PrismConfig.CooldownSeconds).toBe(30)
	end)

	it("RNG intocado: pity 50/250 e cadência 1/s (2/s Roll Rápido)", function()
		local byId = {}
		for _, rule in RollConfig.Pity do
			byId[rule.MinRarity] = rule.Threshold
		end
		expect(byId.Legendary).toBe(50)
		expect(byId.Mythic).toBe(250)
		expect(RollConfig.RollSpeed.BaseInterval).toBe(1)
		expect(RollConfig.RollSpeed.FastRollInterval).toBe(0.5)
		local core = DiceCore.new(DiceConfig, CharacterConfig, RarityConfig, RollConfig)
		expect(#core:diceList()).toBe(16)
	end)
end)

return true
