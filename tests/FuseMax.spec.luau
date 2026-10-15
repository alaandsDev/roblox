-- FUNDIR MÁX.: a cadeia inteira de uma família numa operação, EQUIVALENTE a FUNDIR 1× repetido
local T = require("./TestLib")
local FusionCore = require("../src/server/Core/FusionCore")
local InventoryCore = require("../src/server/Core/InventoryCore")
local describe, it, expect = T.describe, T.it, T.expect

local configs = {
	Fusion = require("../src/shared/Config/FusionConfig"),
	Variants = require("../src/shared/Config/VariantConfig"),
	Characters = require("../src/shared/Config/CharacterConfig"),
	Inventory = InventoryCore,
}
local ID = "dragon_knight"
local OTHER = "flame_rookie"

local function investedOf(item: any): number
	return item.UpgradeInvestment or 0
end

local function fresh(): any
	return { Inventory = {}, EquippedCharacters = {}, NextUid = 1, Money = 1e30 }
end

local function deepCopy(t: any): any
	if type(t) ~= "table" then
		return t
	end
	local out = {}
	for k, v in t do
		out[k] = deepCopy(v)
	end
	return out
end

local seed = 7
local function rand(): number
	seed = (seed * 48271) % 2147483647
	return seed / 2147483647
end

local function add(d: any, id: string, n: number, variant: string?, randomize: boolean?)
	for _ = 1, n do
		local uid = InventoryCore.add(d, id, 0, variant)
		if randomize then
			d.Inventory[uid].Level = 1 + math.floor(rand() * 30)
			d.Inventory[uid].UpgradeInvestment = math.floor(rand() * 1e6)
		end
	end
end

-- A) o jogador clicando FUNDIR 1× até não dar mais (mesma ordem canônica), com as regras do Fuse
local function manual(d: any, id: string): (number, number)
	local fusions, spent = 0, 0
	while true do
		local nxt = FusionCore.nextFusion(d, configs, id)
		if not nxt then
			break
		end
		local plan = FusionCore.plan(d, nxt.uids, configs)
		assert(plan)
		if d.Money < plan.cost then
			break
		end
		d.Money -= plan.cost
		spent += plan.cost
		local invested = FusionCore.investment(d, nxt.uids, investedOf)
		for _, uid in nxt.uids do
			InventoryCore.remove(d, uid)
		end
		local uid = InventoryCore.add(d, plan.characterId, 0, plan.toVariant)
		d.Inventory[uid].Level = plan.level
		d.Inventory[uid].UpgradeInvestment = invested
		fusions += 1
	end
	return fusions, spent
end

-- B) FUNDIR MÁX. (mesma aplicação do FusionService)
local function fuseMax(d: any, id: string): (any, string?)
	local plan, err = FusionCore.fuseMaxPlan(d, id, configs, investedOf, d.Money)
	if not plan then
		return nil, err
	end
	d.Money -= plan.cost
	for _, step in plan.steps do
		for _, uid in step.uids do
			InventoryCore.remove(d, uid)
		end
		local uid = InventoryCore.add(d, id, 0, step.toVariant)
		assert(uid == step.uid)
		d.Inventory[uid].Level = step.level
		d.Inventory[uid].UpgradeInvestment = step.investment
	end
	return plan, nil
end

local function signature(d: any): string
	local rows = {}
	for uid, item in d.Inventory do
		table.insert(rows, string.format("%s|%s|%s|%d|%d|%s|%s", uid, item.Id, item.Variant, item.Level, item.UpgradeInvestment or 0, tostring(item.Locked), tostring(item.Favorite)))
	end
	table.sort(rows)
	return table.concat(rows, "\n") .. "\nNext=" .. d.NextUid .. "\nMoney=" .. string.format("%.0f", d.Money)
end

local function totalInvestment(d: any, id: string?): number
	local total = 0
	for _, item in d.Inventory do
		if not id or item.Id == id then
			total += item.UpgradeInvestment or 0
		end
	end
	return total
end

local function countOf(d: any, id: string, variant: string): number
	local n = 0
	for _, item in d.Inventory do
		if item.Id == id and item.Variant == variant then
			n += 1
		end
	end
	return n
end

local function equivalent(d: any, id: string): (boolean, any)
	local a, b = deepCopy(d), deepCopy(d)
	local fusions = manual(a, id)
	local plan = fuseMax(b, id)
	local same = signature(a) == signature(b)
	return same and ((plan and plan.fusions or 0) == fusions), plan
end

describe("FUNDIR MÁX.: cadeia completa", function()
	it("3 / 9 / 27 Normais -> 1 Prata / 1 Ouro / 1 Diamante", function()
		for n, variant in { [3] = "Silver", [9] = "Gold", [27] = "Diamond" } do
			local d = fresh()
			add(d, ID, n)
			local plan = fuseMax(d, ID)
			assert(plan)
			expect(plan.top).toBe(variant)
			expect(countOf(d, ID, variant)).toBe(1)
			expect(InventoryCore.count(d)).toBe(1)
		end
	end)

	it("300 Normais: Prata 100 -> Ouro 33 (+1 Prata) -> Diamante 11 -> Esmeralda 5 (+1) -> Vazio 2 (+1) -> Celestial 1", function()
		local d = fresh()
		add(d, ID, 300)
		local plan = fuseMax(d, ID)
		assert(plan)
		expect(plan.fusions).toBe(100 + 33 + 11 + 5 + 2 + 1)
		expect(countOf(d, ID, "Celestial")).toBe(1)
		expect(countOf(d, ID, "Silver")).toBe(1)
		expect(countOf(d, ID, "Emerald")).toBe(1)
		expect(countOf(d, ID, "Void")).toBe(0)
		expect(plan.top).toBe("Celestial")
		expect(plan.remaining.Silver).toBe(1)
	end)

	it("usa as variantes já existentes: 300 Normal + 2 Prata -> 102 Prata -> 34 Ouro", function()
		local d = fresh()
		add(d, ID, 300)
		add(d, ID, 2, "Silver")
		local plan = FusionCore.fuseMaxPlan(d, ID, configs, investedOf, d.Money)
		assert(plan)
		local toGold = 0
		for _, step in plan.steps do
			if step.toVariant == "Gold" then
				toGold += 1
			end
		end
		expect(toGold).toBe(34)
		expect(plan.consumed).toBe(302)
	end)

	it("para na variante MÁXIMA real (VariantConfig): Celestial nunca é consumida", function()
		local d = fresh()
		add(d, ID, 5, "Celestial")
		local plan, err = fuseMax(d, ID)
		expect(plan).toBeNil()
		expect(err).toBe("fusion_none")
		expect(countOf(d, ID, "Celestial")).toBe(5)
	end)

	it("só a família pedida: outros personagens (mesma raridade ou não) ficam intactos", function()
		local d = fresh()
		add(d, ID, 9)
		add(d, OTHER, 9)
		fuseMax(d, ID)
		expect(countOf(d, OTHER, "Normal")).toBe(9)
		expect(countOf(d, ID, "Gold")).toBe(1)
	end)

	it("equipado, travado, favorito e em troca NUNCA são consumidos", function()
		local d = fresh()
		add(d, ID, 12)
		local uids = {}
		for uid in d.Inventory do
			table.insert(uids, uid)
		end
		table.sort(uids, FusionCore.uidLess)
		d.Inventory[uids[1]].Locked = true
		d.Inventory[uids[2]].Favorite = true
		d.EquippedCharacters["1"] = uids[3]
		InventoryCore.setTradeLocks(d, { uids[4] })
		local protectedUids = { uids[1], uids[2], uids[3], uids[4] }
		local plan = FusionCore.fuseMaxPlan(d, ID, configs, investedOf, d.Money)
		assert(plan)
		expect(plan.consumed).toBe(8 - 8 % 3 + 0)
		InventoryCore.setTradeLocks(d, nil)
		for _, step in plan.steps do
			for _, uid in step.uids do
				for _, p in protectedUids do
					expect(uid ~= p).toBeTruthy()
				end
			end
		end
	end)

	it("dinheiro limitado: para na 1ª fusão que não cabe (como o Fuse normal)", function()
		local d = fresh()
		add(d, ID, 27)
		local silverCost = FusionCore.cost(configs, ID, "Silver")
		d.Money = silverCost * 5 + 1
		local ok, plan = equivalent(d, ID)
		expect(ok).toBeTruthy()
		assert(plan)
		expect(plan.fusions).toBe(5)
		expect(plan.limitedByMoney).toBeTruthy()
		local broke = fresh()
		add(broke, ID, 3)
		broke.Money = 0
		local _, err = fuseMax(broke, ID)
		expect(err).toBe("not_enough_money")
	end)
end)

describe("FUNDIR MÁX. ≡ FUNDIR 1× repetido (quantidade, variantes, níveis, investimento, dinheiro)", function()
	it("inventários determinísticos 3/9/27/30/300", function()
		for _, n in { 3, 9, 27, 30, 300 } do
			local d = fresh()
			add(d, ID, n, nil, true)
			local ok = equivalent(d, ID)
			expect(ok).toBeTruthy()
		end
	end)

	it("40 inventários aleatórios mistos (variantes existentes, protegidos, outra família, dinheiro)", function()
		local variants = { "Normal", "Silver", "Gold", "Diamond", "Emerald", "Void", "Celestial" }
		for _ = 1, 40 do
			local d = fresh()
			for _, v in variants do
				add(d, ID, math.floor(rand() * (if v == "Normal" then 200 else 6)), v, true)
			end
			add(d, OTHER, math.floor(rand() * 20), nil, true)
			for uid, item in d.Inventory do
				local r = rand()
				if r < 0.03 then
					item.Locked = true
				elseif r < 0.06 then
					item.Favorite = true
				elseif r < 0.08 then
					d.EquippedCharacters[tostring(math.floor(rand() * 64) + 1)] = uid
				end
			end
			if rand() < 0.3 then
				d.Money = math.floor(rand() * 5e8)
			end
			local before = totalInvestment(d)
			local ok, plan = equivalent(d, ID)
			expect(ok).toBeTruthy()
			-- investimento não é criado nem destruído
			local after = deepCopy(d)
			fuseMax(after, ID)
			expect(totalInvestment(after)).toBe(before)
			local _ = plan
		end
	end)
end)

describe("FUNDIR MÁX.: desempenho", function()
	it("300 / 1.000 / 5.000 unidades planejam rápido (< 0,25 s)", function()
		for _, n in { 300, 1000, 5000 } do
			local d = fresh()
			add(d, ID, n, nil, true)
			local t0 = os.clock()
			local plan = FusionCore.fuseMaxPlan(d, ID, configs, investedOf, d.Money)
			local dt = os.clock() - t0
			assert(plan)
			print(string.format("    FuseMax %d unidades: %d fusões, plano em %.1f ms", n, plan.fusions, dt * 1000))
			expect(dt < 0.25).toBeTruthy()
		end
	end)
end)

return true
