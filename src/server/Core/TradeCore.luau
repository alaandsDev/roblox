--!strict
--[[
	Regras da troca (puro). A troca é ATÔMICA: valida tudo dos dois lados antes de mover qualquer
	coisa. Itens travados, favoritos ou equipados não podem ser oferecidos.
	    TradeCore.validateOffer(data, uids, max, inventory) -> erro?
	    TradeCore.execute(a, b, offerA, offerB, capA, capB, now, inventory)
	        -> (ok, erro?, novosUidsDeA, novosUidsDeB)
	inventory = InventoryCore (injetado).
]]

local TradeCore = {}

function TradeCore.validateOffer(data: any, uids: { string }, max: number, inventory: any): string?
	if #uids > max then
		return "trade_too_many"
	end
	local seen = {}
	for _, uid in uids do
		if seen[uid] then
			return "trade_duplicate"
		end
		seen[uid] = true
		local reason = inventory.protection(data, uid)
		if reason then
			return reason
		end
	end
	return nil
end

local function count(data: any): number
	local n = 0
	for _ in data.Inventory do
		n += 1
	end
	return n
end

function TradeCore.execute(a: any, b: any, offerA: { string }, offerB: { string }, capA: number, capB: number, now: number, inventory: any): (boolean, string?, { string }, { string })
	local errA = TradeCore.validateOffer(a, offerA, math.huge, inventory)
	if errA then
		return false, errA, {}, {}
	end
	local errB = TradeCore.validateOffer(b, offerB, math.huge, inventory)
	if errB then
		return false, errB, {}, {}
	end
	if #offerA == 0 and #offerB == 0 then
		return false, "trade_empty", {}, {}
	end
	if count(a) - #offerA + #offerB > capA then
		return false, "trade_full_a", {}, {}
	end
	if count(b) - #offerB + #offerA > capB then
		return false, "trade_full_b", {}, {}
	end
	-- Copia os itens antes de remover (nível, variante, investimento em níveis); flags voltam ao padrão
	local fromA, fromB = {}, {}
	for _, uid in offerA do
		table.insert(fromA, table.clone(a.Inventory[uid]))
	end
	for _, uid in offerB do
		table.insert(fromB, table.clone(b.Inventory[uid]))
	end
	for _, uid in offerA do
		inventory.remove(a, uid)
	end
	for _, uid in offerB do
		inventory.remove(b, uid)
	end
	local newForA, newForB = {}, {}
	for _, item in fromB do
		local uid = inventory.add(a, item.Id, now, item.Variant)
		a.Inventory[uid].Level = item.Level or 1
		a.Inventory[uid].UpgradeInvestment = item.UpgradeInvestment
		table.insert(newForA, uid)
	end
	for _, item in fromA do
		local uid = inventory.add(b, item.Id, now, item.Variant)
		b.Inventory[uid].Level = item.Level or 1
		b.Inventory[uid].UpgradeInvestment = item.UpgradeInvestment
		table.insert(newForB, uid)
	end
	return true, nil, newForA, newForB
end

return TradeCore
