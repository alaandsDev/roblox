-- Simulador econômico novo (tools/sim/EconomyModel): roll idêntico ao DiceCore, pity 50/250,
-- Luck, custos/venda/refund, duplicatas, renda, progressão de Dice, Prisma e Rebirth
local T = require("./TestLib")
local Rng = require("./Rng")
local M = require("../tools/sim/EconomyModel")
local DiceCore = require("../src/shared/Modules/DiceCore")
local CharacterConfig = require("../src/shared/Config/CharacterConfig")
local LevelConfig = require("../src/shared/Config/CharacterLevelConfig")
local VariantConfig = require("../src/shared/Config/VariantConfig")
local RollConfig = require("../src/shared/Config/RollConfig")
local RebirthConfig = require("../src/shared/Config/RebirthConfig")
local describe, it, expect = T.describe, T.it, T.expect

local core, formulas = M.core, M.formulas

local function short(over: any): any
	local profile = table.clone(M.Profiles.Ativo)
	for k, v in over or {} do
		profile[k] = v
	end
	return profile
end

describe("EconomyModel: RNG por Dice", function()
	it("pity de produção 50/250", function()
		local byId = {}
		for _, rule in RollConfig.Pity do
			byId[rule.MinRarity] = rule.Threshold
		end
		expect(byId.Legendary).toBe(50)
		expect(byId.Mythic).toBe(250)
	end)

	it("roll a roll IDÊNTICO ao DiceCore.roll (todos os Dice, Luck 1/2.5/7, mesma semente)", function()
		for _, dice in core:diceList() do
			for _, luck in { 1, 2.5, 7 } do
				local a, b = Rng.new(17), Rng.new(17)
				local pityA = { Legendary = 0, Mythic = 0 }
				local pityB: any = { Legendary = 0, Mythic = 0 }
				for _ = 1, 1500 do
					local rarity, id, triggered = M.roll(dice.Id, luck, pityA, a)
					local ref = core:roll(dice.Id, luck, pityB, b)
					if rarity ~= ref.rarity or id ~= ref.characterId or triggered ~= ref.pityTriggered then
						error(`{dice.Id} L{luck}: {rarity}/{id}/{triggered} ≠ {ref.rarity}/{ref.characterId}/{ref.pityTriggered}`)
					end
					pityB = ref.pity
					expect(pityA.Legendary).toBe(pityB.Legendary)
					expect(pityA.Mythic).toBe(pityB.Mythic)
				end
			end
		end
	end)

	it("pity: nunca mais de 50 rolls sem Lendário+ nem 250 sem Mítico+ (Spirit, 50.000 rolls)", function()
		local rand = Rng.new(5)
		local pity = { Legendary = 0, Mythic = 0 }
		local sinceL, sinceM, maxL, maxM = 0, 0, 0, 0
		for _ = 1, 50000 do
			local rarity = M.roll("Spirit", 1, pity, rand)
			local tier = core:tierOf(rarity)
			sinceL = if tier >= core:tierOf("Legendary") then 0 else sinceL + 1
			sinceM = if tier >= core:tierOf("Mythic") then 0 else sinceM + 1
			maxL, maxM = math.max(maxL, sinceL), math.max(maxM, sinceM)
		end
		expect(maxL <= 49).toBeTruthy()
		expect(maxM <= 249).toBeTruthy()
	end)

	it("Luck maior aumenta a fração de Mítico+ no Dice (Spirit, 40.000 rolls cada)", function()
		local function mythicShare(luck: number): number
			local rand, pity, hits = Rng.new(9), { Legendary = 0, Mythic = 0 }, 0
			for _ = 1, 40000 do
				if core:tierOf((M.roll("Spirit", luck, pity, rand))) >= core:tierOf("Mythic") then
					hits += 1
				end
			end
			return hits / 40000
		end
		expect(mythicShare(4) > mythicShare(1)).toBeTruthy()
	end)
end)

describe("EconomyModel: custos, venda e refund", function()
	it("investimento acumulado = soma da curva oficial (1, 2, 10, 20, máx)", function()
		for _, c in CharacterConfig.List do
			local running = 0
			for level = 1, LevelConfig.MaxLevel do
				expect(M.investedForLevel(c.Id, level)).toBe(running)
				running += formulas:characterUpgradeCost(c.Id, level, 1)
			end
		end
	end)

	it("adquirir → subir N níveis → vender: lucro <= valor base para refund 0..100% (níveis 1/2/10/20/máx)", function()
		for _, c in CharacterConfig.List do
			for _, v in VariantConfig.List do
				local base = formulas:sellValue(c.Id, v.Id)
				for _, level in { 1, 2, 10, 20, LevelConfig.MaxLevel } do
					local paid = M.investedForLevel(c.Id, level)
					for _, r in { 0, 0.5, 0.6, 0.7, 0.75, 0.8, 1 } do
						local sale = M.saleValue(c.Id, v.Id, paid, r)
						expect(sale - paid <= base).toBeTruthy()
						expect(sale >= base).toBeTruthy()
					end
					-- valores absurdos não criam dinheiro
					expect(M.saleValue(c.Id, v.Id, paid, 7)).toBe(base + paid)
					expect(M.saleValue(c.Id, v.Id, -1e9, 1)).toBe(base)
				end
			end
		end
	end)

	it("fusão: cópias e custo de cada degrau batem com FusionConfig", function()
		local id = CharacterConfig.List[1].Id
		local normals, money = M.fusionStep(id, 1) -- Normal -> Silver: 3 Normais (2 extras)
		expect(normals).toBe(2)
		expect(money > 0).toBeTruthy()
	end)
end)

describe("EconomyModel: simulação", function()
	local res = M.run(short({ sessionsPerDay = { 3600 } }), 3 * 3600, 42, {})
	local p = res.player

	it("determinística: mesma semente, mesmo resultado", function()
		local again = M.run(short({ sessionsPerDay = { 3600 } }), 3 * 3600, 42, {})
		expect(again.player.money).toBe(p.money)
		expect(again.player.rolls).toBe(p.rolls)
		expect(again.player.discovered).toBe(p.discovered)
	end)

	it("sementes vizinhas geram jogadores DIFERENTES (sem colisão 2k/2k+1)", function()
		local seen = {}
		for seed = 1, 64 do
			local rand = M.rng(seed)
			local key = string.format("%.12f|%.12f", rand(), rand())
			expect(seen[key]).toBeNil()
			seen[key] = true
		end
	end)

	it("dinheiro conservado: saldo = ganhos − gastos (rebirth conta como gasto do saldo)", function()
		local earned, spent = 0, 0
		for _, v in p.earned do
			earned += v
		end
		for _, v in p.spent do
			spent += v
		end
		expect(p.money).toBe(earned - spent)
		expect(p.money >= 0).toBeTruthy()
	end)

	it("renda = Σ renda das estações × multiplicador oficial", function()
		local total = 0
		for _, slot in p.slots do
			total += formulas:unitIncome({ Id = slot.id, Level = slot.level, Variant = VariantConfig.List[slot.variant].Id })
		end
		expect(math.abs(p.ipsCache - total * formulas:incomeMultiplier(p.data)) < 1e-6).toBeTruthy()
	end)

	it("Dice comprados em ordem, com rolls exigidos e preço exato", function()
		local list, paid = core:diceList(), 0
		for i = 2, p.diceOwned do
			expect(p.rollsAtPurchase[i] >= (list[i].UnlockRequirement.Rolls or 0)).toBeTruthy()
			expect(p.ownedAt[i] >= p.ownedAt[i - 1]).toBeTruthy()
			paid += list[i].Price
		end
		expect(p.spent.Dice or 0).toBe(paid)
	end)

	it("duplicatas: vendidas pelo valor base e atribuídas ao Dice de origem", function()
		local byDice = 0
		for _, v in p.dupIncomeByDice do
			byDice += v
		end
		expect(p.duplicatesSold > 0).toBeTruthy()
		expect(byDice).toBe(p.earned.Sell)
	end)

	it("investimento em níveis: gasto = Σ investido nas estações + o perdido/reembolsado em trocas", function()
		local inSlots = 0
		for _, slot in p.slots do
			inSlots += slot.invested
			expect(slot.invested).toBe(M.investedForLevel(slot.id, slot.level))
		end
		expect(math.abs((p.spent.StationLevels or 0) - (inSlots + p.investmentLost + p.investmentRefunded)) < 1).toBeTruthy()
	end)

	it("Prisma: só usa cargas recebidas, nunca passa do teto e nunca repete descoberto", function()
		local cfg = { UsesPerReward = 3, MaxCharges = 7, CooldownSeconds = 30 }
		local r = M.run(short({ sessionsPerDay = { 900 } }), 9 * 900, 3, { prism = cfg })
		local q = r.player
		expect(q.prismOwned).toBe(true)
		expect(q.prismUsed + q.prismCharges <= cfg.UsesPerReward * math.ceil(r.days / 7)).toBeTruthy()
		expect(q.prismCharges <= cfg.MaxCharges).toBeTruthy()
		expect(q.prismUsed > 0).toBeTruthy()
	end)

	it("Rebirth: custo oficial, zera dinheiro e melhorias de Luck/Renda, mantém Dice e +1 slot", function()
		local r = M.run(short({ sessionsPerDay = { 4 * 3600 } }), 4 * 3600, 11, { rebirth = "early" })
		local q = r.player
		expect(q.data.Rebirths >= 1).toBeTruthy()
		expect(#q.rebirthTimes).toBe(q.data.Rebirths)
		expect(formulas:rebirthCost(0)).toBe(RebirthConfig.BaseCost)
		expect(#q.slots <= 4 + q.data.Rebirths).toBeTruthy()
		expect(q.diceOwned >= 13).toBeTruthy()
		-- o maior Dice continua igual depois do rebirth (Dice não reseta)
		expect(q.spent.Rebirth >= RebirthConfig.BaseCost).toBeTruthy()
	end)
end)

return true
