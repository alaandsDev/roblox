-- Venda em massa (BulkSaleCore): mesma fonte de verdade da venda individual, sem criar dinheiro
local T = require("./TestLib")
local BulkSaleCore = require("../src/shared/Modules/BulkSaleCore")
local SaleCore = require("../src/shared/Modules/SaleCore")
local InventoryCore = require("../src/server/Core/InventoryCore")
local FusionCore = require("../src/server/Core/FusionCore")
local Formulas = require("../src/shared/Modules/Formulas")
local CharacterConfig = require("../src/shared/Config/CharacterConfig")
local EconomyConfig = require("../src/shared/Config/EconomyConfig")
local Rng = require("./Rng")
local describe, it, expect = T.describe, T.it, T.expect

local function seeded(seed: number)
	local rand = Rng.new(seed)
	return {
		int = function(_, lo: number, hi: number): number
			return lo + math.floor(rand() * (hi - lo + 1))
		end,
	}
end

local f = Formulas.new({
	Dice = require("../src/shared/Config/DiceConfig"),
	Upgrades = require("../src/shared/Config/UpgradeConfig"),
	Roll = require("../src/shared/Config/RollConfig"),
	Economy = EconomyConfig,
	Characters = CharacterConfig,
	Levels = require("../src/shared/Config/CharacterLevelConfig"),
	Variants = require("../src/shared/Config/VariantConfig"),
})
local PCT = EconomyConfig.UpgradeRefundPercent

local function fresh(): any
	return { Inventory = {}, EquippedCharacters = {}, TowerTeam = {}, NextUid = 1 }
end
local function quoter(data: any)
	return function(uid: string)
		return SaleCore.quote(f, data.Inventory[uid], PCT)
	end
end
local function plan(data: any, uids: { any })
	return BulkSaleCore.plan(data, uids, InventoryCore.protection, quoter(data))
end
-- "venda individual": exatamente o que SellService faz para { uid } (protection + SaleCore.quote)
local function individual(data: any, uid: string): number
	if InventoryCore.protection(data, uid) ~= nil then
		return 0
	end
	local total = SaleCore.quote(f, data.Inventory[uid], PCT).Total
	InventoryCore.remove(data, uid)
	return total
end
local function reasonOf(p: any, uid: string): string?
	for _, s in p.skipped do
		if s.uid == uid then
			return s.reason
		end
	end
	return nil
end

local ID = CharacterConfig.List[1].Id
local ID2 = CharacterConfig.List[2].Id

describe("BulkSaleCore: plano autoritativo", function()
	it("1 unidade = venda individual (mesma cotação SaleCore)", function()
		local d = fresh()
		local a = InventoryCore.add(d, ID, 1)
		local p = plan(d, { a })
		expect(#p.uids).toBe(1)
		expect(p.total).toBe(SaleCore.quote(f, d.Inventory[a], PCT).Total)
		expect(d.Inventory[a] ~= nil).toBeTruthy() -- planejar não vende
	end)

	it("várias unidades: total = Σ cotações; base/investido/reembolso somados", function()
		local d = fresh()
		local uids = {}
		for i = 1, 6 do
			table.insert(uids, InventoryCore.add(d, if i % 2 == 0 then ID else ID2, i))
		end
		local p = plan(d, uids)
		local sum, base, refund = 0, 0, 0
		for _, uid in uids do
			local q = SaleCore.quote(f, d.Inventory[uid], PCT)
			sum += q.Total
			base += q.Base
			refund += q.Refund
		end
		expect(p.total).toBe(sum)
		expect(p.base).toBe(base)
		expect(p.refund).toBe(refund)
		expect(#p.skipped).toBe(0)
	end)

	it("uid repetido é pago UMA vez (duplicate_uid)", function()
		local d = fresh()
		local a = InventoryCore.add(d, ID, 1)
		local p = plan(d, { a, a, a })
		expect(#p.uids).toBe(1)
		expect(p.total).toBe(SaleCore.quote(f, d.Inventory[a], PCT).Total)
		expect(#p.skipped).toBe(2)
		expect(p.skipped[1].reason).toBe("duplicate_uid")
	end)

	it("inexistente, de outro jogador e inválido: nunca pagos, com motivo", function()
		local d, other = fresh(), fresh()
		other.NextUid = 900
		local theirs = InventoryCore.add(other, ID, 1)
		local mine = InventoryCore.add(d, ID, 1)
		local p = plan(d, { "c99999", theirs, 42 :: any, mine })
		expect(#p.uids).toBe(1)
		expect(p.uids[1]).toBe(mine)
		expect(reasonOf(p, "c99999")).toBe("not_owned")
		expect(reasonOf(p, theirs)).toBe("not_owned")
		expect(reasonOf(p, "?")).toBe("invalid_uid")
	end)

	it("favorito, travado, equipado, time da Torre e em troca: recusados com motivo", function()
		local d = fresh()
		local fav, lock, eq, team, trade, free = InventoryCore.add(d, ID, 1), InventoryCore.add(d, ID, 2), InventoryCore.add(d, ID, 3), InventoryCore.add(d, ID, 4), InventoryCore.add(d, ID, 5), InventoryCore.add(d, ID, 6)
		d.Inventory[fav].Favorite = true
		d.Inventory[lock].Locked = true
		d.EquippedCharacters["1"] = eq
		d.TowerTeam = { team }
		InventoryCore.setTradeLocks(d, { trade })
		local p = plan(d, { fav, lock, eq, team, trade, free })
		InventoryCore.setTradeLocks(d, nil)
		expect(#p.uids).toBe(1)
		expect(p.uids[1]).toBe(free)
		expect(reasonOf(p, fav)).toBe("favorite")
		expect(reasonOf(p, lock)).toBe("locked")
		expect(reasonOf(p, eq)).toBe("equipped")
		expect(reasonOf(p, team)).toBe("tower_team")
		expect(reasonOf(p, trade)).toBe("in_trade")
	end)

	it("upgradado (investimento B), migrado (curva A), fundido e trocado: reembolso de 75% igual ao individual", function()
		local d = fresh()
		local up = InventoryCore.add(d, ID, 1)
		d.Inventory[up].Level = 10
		d.Inventory[up].UpgradeInvestment = SaleCore.curveInvestment(f, ID, 10)
		local migrated = InventoryCore.add(d, ID, 2)
		d.Inventory[migrated].Level = 12 -- save antigo: sem UpgradeInvestment -> curva oficial
		local fused = InventoryCore.add(d, ID, 3)
		d.Inventory[fused].Variant = "Gold"
		d.Inventory[fused].UpgradeInvestment = 5000 -- soma das consumidas (FusionCore.investment)
		local traded = InventoryCore.add(d, ID2, 4)
		d.Inventory[traded].Level = 5
		d.Inventory[traded].UpgradeInvestment = 777 -- viajou com a instância (TradeCore)
		local uids = { up, migrated, fused, traded }
		local p = plan(d, uids)
		expect(#p.uids).toBe(4)
		for _, uid in uids do
			local q = p.quotes[uid]
			expect(q.Refund).toBe(math.floor(SaleCore.invested(f, d.Inventory[uid]) * PCT))
			expect(q.Total).toBe(SaleCore.quote(f, d.Inventory[uid], PCT).Total)
		end
		expect(p.quotes[migrated].Invested).toBe(SaleCore.curveInvestment(f, ID, 12))
		expect(p.quotes[fused].Invested).toBe(5000)
		local _ = FusionCore
	end)

	it("limite de itens por pedido (MaxItems)", function()
		local d = fresh()
		local uids = {}
		for i = 1, BulkSaleCore.MaxItems + 20 do
			table.insert(uids, InventoryCore.add(d, ID, i))
		end
		expect(#plan(d, uids).uids).toBe(BulkSaleCore.MaxItems)
	end)
end)

describe("BulkSaleCore: SELECIONAR DUPLICATAS", function()
	it("mantém >= 1 por Id+Variante; variantes diferentes não são duplicatas", function()
		local d = fresh()
		local n1, n2, n3 = InventoryCore.add(d, ID, 1), InventoryCore.add(d, ID, 2), InventoryCore.add(d, ID, 3)
		local g1 = InventoryCore.add(d, ID, 4)
		d.Inventory[g1].Variant = "Gold"
		local single = InventoryCore.add(d, ID2, 5)
		local sel = BulkSaleCore.selectDuplicates(d, InventoryCore.protection)
		expect(#sel).toBe(2)
		expect(table.find(sel, g1)).toBeNil()
		expect(table.find(sel, single)).toBeNil()
		local kept = 0
		for _, uid in { n1, n2, n3 } do
			if not table.find(sel, uid) then
				kept += 1
			end
		end
		expect(kept).toBe(1)
	end)

	it("fica a melhor cópia (maior nível/investimento); favorita/travada/equipada/time contam como a que fica", function()
		local d = fresh()
		local low, high = InventoryCore.add(d, ID, 1), InventoryCore.add(d, ID, 2)
		d.Inventory[high].Level = 9
		local sel = BulkSaleCore.selectDuplicates(d, InventoryCore.protection)
		expect(sel[1]).toBe(low)
		-- favorita de nível 1 + outra de nível 9: a favorita fica e a de nível 9 (livre) é excedente
		d.Inventory[low].Favorite = true
		sel = BulkSaleCore.selectDuplicates(d, InventoryCore.protection)
		expect(#sel).toBe(1)
		expect(sel[1]).toBe(high)
		-- todas bloqueadas: nada é selecionado
		d.Inventory[high].Locked = true
		expect(#BulkSaleCore.selectDuplicates(d, InventoryCore.protection)).toBe(0)
		d.Inventory[high].Locked = false
		d.TowerTeam = { high }
		expect(#BulkSaleCore.selectDuplicates(d, InventoryCore.protection)).toBe(0)
		d.TowerTeam = {}
		d.EquippedCharacters["2"] = high
		expect(#BulkSaleCore.selectDuplicates(d, InventoryCore.protection)).toBe(0)
	end)

	it("nunca seleciona bloqueados (500 inventários aleatórios)", function()
		local rng = seeded(77)
		for _ = 1, 500 do
			local d = fresh()
			for i = 1, rng:int(1, 30) do
				local uid = InventoryCore.add(d, CharacterConfig.List[rng:int(1, 4)].Id, i)
				local item = d.Inventory[uid]
				item.Variant = if rng:int(1, 4) == 1 then "Gold" else "Normal"
				item.Favorite = rng:int(1, 6) == 1
				item.Locked = rng:int(1, 6) == 1
				if rng:int(1, 8) == 1 then
					d.EquippedCharacters[tostring(i)] = uid
				end
				if rng:int(1, 8) == 1 then
					table.insert(d.TowerTeam, uid)
				end
			end
			local sel = BulkSaleCore.selectDuplicates(d, InventoryCore.protection)
			local remaining = {}
			for uid, item in d.Inventory do
				if not table.find(sel, uid) then
					remaining[BulkSaleCore.key(item)] = true
				end
			end
			for _, uid in sel do
				expect(BulkSaleCore.blocked(d, uid, InventoryCore.protection)).toBeNil()
			end
			for _, item in d.Inventory do
				expect(remaining[BulkSaleCore.key(item)]).toBeTruthy() -- >= 1 por Id+Variante
			end
		end
	end)
end)

describe("BulkSaleCore: prova de conservação (BulkSale = Σ vendas individuais)", function()
	it("1.000 pedidos aleatórios (repetidos, lixo, protegidos, upgradados): bulk = Σ individual, sem criar dinheiro", function()
		local rng = seeded(2024)
		for _ = 1, 1000 do
			local a, b = fresh(), fresh()
			local pool = {}
			for i = 1, rng:int(1, 25) do
				local id = CharacterConfig.List[rng:int(1, 8)].Id
				local level = rng:int(1, 30)
				local variant = if rng:int(1, 5) == 1 then "Gold" else "Normal"
				local fav, lock = rng:int(1, 7) == 1, rng:int(1, 7) == 1
				local invested = if rng:int(1, 3) == 1 then nil else SaleCore.curveInvestment(f, id, level)
				for _, d in { a, b } do
					local uid = InventoryCore.add(d, id, i)
					local item = d.Inventory[uid]
					item.Level, item.Variant, item.Favorite, item.Locked, item.UpgradeInvestment = level, variant, fav, lock, invested
				end
				table.insert(pool, "c" .. i)
			end
			local request = {}
			for _ = 1, rng:int(1, 40) do
				local r = rng:int(1, 10)
				table.insert(request, if r == 1 then "c9999" else pool[rng:int(1, #pool)])
			end
			-- A: venda em massa
			local p = plan(a, request)
			local paidBulk = p.total
			for _, uid in p.uids do
				InventoryCore.remove(a, uid)
			end
			-- B: a mesma lista vendida uma a uma (repetidos/inexistentes rendem 0)
			local paidIndividual = 0
			for _, uid in request do
				if b.Inventory[uid] then
					paidIndividual += individual(b, uid)
				end
			end
			expect(paidBulk).toBe(paidIndividual)
			-- os dois inventários terminam iguais
			for uid in a.Inventory do
				expect(b.Inventory[uid] ~= nil).toBeTruthy()
			end
			for uid in b.Inventory do
				expect(a.Inventory[uid] ~= nil).toBeTruthy()
			end
			-- replay do mesmo pedido depois da venda: nada a pagar
			expect(plan(a, request).total).toBe(0)
		end
	end)
end)

return true
