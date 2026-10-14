-- Economia por Dice: renda base = Dice × Raridade (CharacterConfig.IncomeCurve), fonte única
local T = require("./TestLib")
local CharacterConfig = require("../src/shared/Config/CharacterConfig")
local DiceConfig = require("../src/shared/Config/DiceConfig")
local RarityConfig = require("../src/shared/Config/RarityConfig")
local EconomyConfig = require("../src/shared/Config/EconomyConfig")
local LevelConfig = require("../src/shared/Config/CharacterLevelConfig")
local VariantConfig = require("../src/shared/Config/VariantConfig")
local Formulas = require("../src/shared/Modules/Formulas")
local SaleCore = require("../src/shared/Modules/SaleCore")
local InventoryCore = require("../src/server/Core/InventoryCore")
local TradeCore = require("../src/server/Core/TradeCore")
local FusionCore = require("../src/server/Core/FusionCore")
local EconomyModel = require("../tools/sim/EconomyModel")
local describe, it, expect = T.describe, T.it, T.expect

local f = Formulas.new({
	Dice = DiceConfig,
	Upgrades = require("../src/shared/Config/UpgradeConfig"),
	Roll = require("../src/shared/Config/RollConfig"),
	Economy = EconomyConfig,
	Characters = CharacterConfig,
	Levels = LevelConfig,
	Variants = VariantConfig,
	Rebirth = require("../src/shared/Config/RebirthConfig"),
})
local curve = CharacterConfig.IncomeCurve

local function orderOf(c: any): number
	return curve.OrderOf[c.DefaultDice]
end

-- renda por (raridade, ordem do Dice)
local grid: { [string]: { [number]: number } } = {}
for _, c in CharacterConfig.List do
	grid[c.Rarity] = grid[c.Rarity] or {}
	local o = orderOf(c)
	if grid[c.Rarity][o] then
		expect(grid[c.Rarity][o]).toBe(c.BaseIncome) -- mesmo Dice + mesma raridade = mesma renda
	end
	grid[c.Rarity][o] = c.BaseIncome
end

local function byDice(rarity: string): { { order: number, income: number } }
	local list = {}
	for o, v in grid[rarity] or {} do
		table.insert(list, { order = o, income = v })
	end
	table.sort(list, function(a, b)
		return a.order < b.order
	end)
	return list
end

describe("Economia por Dice: fonte única Dice × Raridade", function()
	it("ordem da curva = ordem oficial dos 16 Dice F2P (DiceConfig)", function()
		local n = 0
		for _, d in DiceConfig.List do
			if d.Pool == "F2P" then
				n += 1
				expect(curve.OrderOf[d.CatalogKey]).toBe(d.Order)
			end
		end
		expect(n).toBe(16)
		expect(#curve.DiceOrder).toBe(16)
	end)

	it("todo F2P usa a curva (BaseIncome = IncomeCurve(raridade, Dice)); Premium/legados ficam fora", function()
		expect(#CharacterConfig.List).toBe(112)
		for _, c in CharacterConfig.List do
			expect(c.BaseIncome).toBe(curve.baseIncome(c.Rarity, c.DefaultDice))
			expect(c.BaseIncome > 0).toBeTruthy()
		end
		for _, c in CharacterConfig.Premium do
			expect(c.BaseIncome > 0).toBeTruthy()
		end
	end)

	it("dois Míticos de Dice diferentes NÃO têm a mesma renda (o bug do $160/s em todo Mítico)", function()
		local mythic = byDice("Mythic")
		expect(#mythic >= 6).toBeTruthy()
		expect(mythic[1].income ~= mythic[#mythic].income).toBeTruthy()
		-- e nenhuma raridade repete a renda entre Dice diferentes
		for _, rarity in RarityConfig.Order do
			local seen = {}
			for _, row in byDice(rarity) do
				expect(seen[row.income]).toBeNil()
				seen[row.income] = true
			end
		end
	end)

	it("renda cresce com a progressão e cada Dice posterior é avanço real, sem salto absurdo", function()
		for _, rarity in RarityConfig.Order do
			local rows = byDice(rarity)
			for i = 2, #rows do
				local steps = rows[i].order - rows[i - 1].order
				local ratio = rows[i].income / rows[i - 1].income
				expect(ratio > 1).toBeTruthy()
				-- por passo de Dice: entre +5% e +20% (arredondamento incluso)
				expect(ratio ^ (1 / steps) >= 1.05 - 1e-9).toBeTruthy()
				expect(ratio ^ (1 / steps) <= 1.2).toBeTruthy()
			end
		end
		-- Mítico: Spirit < Arcane < Shadow < Void < Colossus < Awakened < Celestial < Forbidden
		local last = 0
		for _, key in { "spirit", "arcane", "shadow", "void", "colossus", "awakened", "celestial", "forbidden" } do
			local v = curve.baseIncome("Mythic", key)
			expect(v ~= nil and v > last).toBeTruthy()
			last = v :: number
		end
	end)

	it("Lendário de Dice bem posterior passa o Mítico antigo; no MESMO Dice a raridade manda", function()
		expect(curve.baseIncome("Legendary", "celestial") > curve.baseIncome("Mythic", "spirit")).toBeTruthy()
		for _, key in curve.DiceOrder do
			local previous = 0
			for _, rarity in RarityConfig.Order do
				local v = curve.baseIncome(rarity, key)
				if v then
					expect(v > previous).toBeTruthy()
					previous = v
				end
			end
		end
	end)
end)

describe("Economia por Dice: o resto da economia continua coerente", function()
	it("upgrades sem arbitragem: payback de um nível igual em todo Dice; vender upado nunca dá lucro", function()
		for _, c in CharacterConfig.List do
			for _, level in { 1, 10, 29 } do
				local cost = f:characterUpgradeCost(c.Id, level, 1)
				local gain = c.BaseIncome * LevelConfig.IncomePerLevel
				-- custo do nível ∝ BaseIncome: o tempo para se pagar não depende do Dice
				local payback = cost / gain
				local expected = math.floor(c.BaseIncome * LevelConfig.BaseCostSeconds * LevelConfig.CostGrowth ^ (level - 1)) / gain
				expect(math.abs(payback - expected) < 1e-6).toBeTruthy()
			end
			local item = { Id = c.Id, Level = 30, Variant = "Normal", UpgradeInvestment = SaleCore.curveInvestment(f, c.Id, 30) }
			local q = SaleCore.quote(f, item, EconomyConfig.UpgradeRefundPercent)
			expect(q.Total - q.Invested <= q.Base).toBeTruthy()
		end
	end)

	it("venda usa a renda nova: base = BaseIncome × SellSeconds × variante", function()
		for _, c in CharacterConfig.List do
			for _, v in VariantConfig.List do
				local expected = math.floor(c.BaseIncome * EconomyConfig.SellSeconds[c.Rarity] * v.SellMultiplier)
				expect(f:sellValue(c.Id, v.Id)).toBe(expected)
			end
		end
	end)

	it("fusão preserva o investimento; troca e save/load não mudam a renda", function()
		local a, b = { Inventory = {}, EquippedCharacters = {}, NextUid = 1 }, { Inventory = {}, EquippedCharacters = {}, NextUid = 500 }
		local mythic = CharacterConfig.List[#CharacterConfig.List]
		local x = InventoryCore.add(a, mythic.Id, 0, "Gold")
		a.Inventory[x].Level = 12
		a.Inventory[x].UpgradeInvestment = 9999
		local before = f:unitIncome(a.Inventory[x])
		local y = InventoryCore.add(b, CharacterConfig.List[1].Id, 0)
		local ok, _, _, newB = TradeCore.execute(a, b, { x }, { y }, 100, 100, 1, InventoryCore)
		expect(ok).toBe(true)
		expect(f:unitIncome(b.Inventory[newB[1]])).toBe(before)
		expect(b.Inventory[newB[1]].UpgradeInvestment).toBe(9999)
		-- save/load: a renda vem só de Id/Nível/Variante (nada de renda gravada no save)
		local saved = table.clone(b.Inventory[newB[1]])
		expect(saved.BaseIncome).toBeNil()
		expect(f:unitIncome(saved)).toBe(before)
		-- fusão: a unidade nova recebe a soma do investimento das consumidas
		local d = { Inventory = {}, EquippedCharacters = {}, NextUid = 1 }
		local uids = {}
		for i = 1, 3 do
			local u = InventoryCore.add(d, mythic.Id, 0)
			d.Inventory[u].UpgradeInvestment = 1000 * i
			table.insert(uids, u)
		end
		expect(FusionCore.investment(d, uids, function(item)
			return SaleCore.invested(f, item)
		end)).toBe(6000)
	end)

	it("Rebirth/pacing saudável no simulador oficial (Ativo, 3 jogadores, 40 h ativas)", function()
		local firsts, counts, forbidden = {}, {}, {}
		for seed = 1, 3 do
			local r = EconomyModel.run(EconomyModel.Profiles.Ativo, 40 * 3600, 2000 + seed, { checkpoints = {} })
			table.insert(firsts, r.player.rebirthTimes[1] or math.huge)
			table.insert(counts, #r.player.rebirthTimes)
			table.insert(forbidden, r.player.ownedAt[16] or math.huge)
		end
		table.sort(firsts)
		table.sort(counts)
		table.sort(forbidden)
		-- linha de base aprovada (antes da curva): 1º Rebirth ~127 min, 13 Rebirths, Forbidden ~283 min
		expect(firsts[2] >= 90 * 60 and firsts[2] <= 160 * 60).toBeTruthy()
		expect(counts[2] >= 10 and counts[2] <= 16).toBeTruthy()
		expect(forbidden[2] >= 200 * 60 and forbidden[2] <= 330 * 60).toBeTruthy()
	end)
end)

return true
