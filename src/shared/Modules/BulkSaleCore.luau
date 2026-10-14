--!strict
--[[
	BulkSaleCore (puro): VENDA EM MASSA da Mochila — seleção de duplicatas e plano de venda.
	Usado pelo servidor (SellService.SellBulk/PreviewBulkSale, autoridade do dinheiro) e pelo
	cliente (só para PRÉ-SELECIONAR; o valor exibido vem sempre da prévia do servidor).

	Mesma fonte de verdade da venda individual: o preço de cada unidade é o SaleCore.quote
	(base + 75% do investimento elegível) passado em "quote"; o total do lote é a SOMA das
	cotações unitárias — logo BulkSale(conjunto válido) = Σ vendas individuais, sem criar dinheiro.

	Bloqueios (nunca vendidos em massa; o jogador precisa desvincular antes):
	    protection(data, uid)  -> not_owned | in_trade | locked | favorite | equipped (InventoryCore)
	    "tower_team"           -> está no time escolhido da Torre (data.TowerTeam)
	    "duplicate_uid"        -> uid repetido na mesma requisição (pago no máximo uma vez)
	    "invalid_uid"          -> não é texto
]]

local BulkSaleCore = {}

BulkSaleCore.MaxItems = 500

export type Protection = (data: any, uid: string) -> string?
export type Skip = { uid: string, reason: string }
export type Plan = {
	uids: { string },
	total: number,
	base: number,
	invested: number,
	refund: number,
	quotes: { [string]: any },
	skipped: { Skip },
}

local function inTowerTeam(data: any, uid: string): boolean
	local team = data.TowerTeam
	if type(team) ~= "table" then
		return false
	end
	return table.find(team, uid) ~= nil
end

-- Motivo para NÃO vender em massa (nil = pode)
function BulkSaleCore.blocked(data: any, uid: any, protection: Protection): string?
	if type(uid) ~= "string" then
		return "invalid_uid"
	end
	local reason = protection(data, uid)
	if reason then
		return reason
	end
	if inTowerTeam(data, uid) then
		return "tower_team"
	end
	return nil
end

-- Chave da duplicata: mesmo personagem E mesma variante (Normal/Gold/... nunca se misturam)
function BulkSaleCore.key(item: any): string
	return tostring(item.Id) .. "|" .. tostring(item.Variant or "Normal")
end

local function investedOf(item: any): number
	local v = item.UpgradeInvestment
	return if type(v) == "number" and v == v then v else 0
end

--[[
	SELECIONAR DUPLICATAS: só as cópias EXCEDENTES de cada Id+Variante, sempre mantendo >= 1.
	A cópia que fica é escolhida assim:
	    1. se alguma cópia está bloqueada (favorita, travada, equipada, no time da Torre, em
	       troca), ELA conta como a que fica — e nunca é selecionada;
	    2. senão fica a "melhor": maior nível, depois maior investimento, depois a mais antiga.
	Nenhuma unidade bloqueada é selecionada.
]]
function BulkSaleCore.selectDuplicates(data: any, protection: Protection): { string }
	local groups: { [string]: { string } } = {}
	for uid, item in data.Inventory do
		local key = BulkSaleCore.key(item)
		groups[key] = groups[key] or {}
		table.insert(groups[key], uid)
	end
	local selected = {}
	for _, uids in groups do
		if #uids > 1 then
			table.sort(uids, function(a, b)
				local ia, ib = data.Inventory[a], data.Inventory[b]
				local ba = BulkSaleCore.blocked(data, a, protection) ~= nil
				local bb = BulkSaleCore.blocked(data, b, protection) ~= nil
				if ba ~= bb then
					return ba -- bloqueada primeiro: é a que fica
				end
				if (ia.Level or 1) ~= (ib.Level or 1) then
					return (ia.Level or 1) > (ib.Level or 1)
				end
				if investedOf(ia) ~= investedOf(ib) then
					return investedOf(ia) > investedOf(ib)
				end
				if (ia.ObtainedAt or 0) ~= (ib.ObtainedAt or 0) then
					return (ia.ObtainedAt or 0) < (ib.ObtainedAt or 0)
				end
				return a < b
			end)
			for i = 2, #uids do
				if BulkSaleCore.blocked(data, uids[i], protection) == nil then
					table.insert(selected, uids[i])
				end
			end
		end
	end
	table.sort(selected)
	return selected
end

--[[
	Plano de venda (não altera nada): revalida CADA uid no estado atual do servidor.
	quote(uid) -> { Base, Invested, Refund, Total } da unidade (SaleCore.quote no servidor).
]]
function BulkSaleCore.plan(data: any, uids: { any }, protection: Protection, quote: (string) -> any): Plan
	local result: Plan = { uids = {}, total = 0, base = 0, invested = 0, refund = 0, quotes = {}, skipped = {} }
	local seen: { [string]: boolean } = {}
	for i, uid in uids do
		if i > BulkSaleCore.MaxItems then
			break
		end
		if type(uid) == "string" and seen[uid] then
			table.insert(result.skipped, { uid = uid, reason = "duplicate_uid" })
		else
			local reason = BulkSaleCore.blocked(data, uid, protection)
			if type(uid) == "string" then
				seen[uid] = true
			end
			if reason then
				table.insert(result.skipped, { uid = if type(uid) == "string" then uid else "?", reason = reason })
			else
				local q = quote(uid)
				result.quotes[uid] = q
				table.insert(result.uids, uid)
				result.total += q.Total
				result.base += q.Base
				result.invested += q.Invested
				result.refund += q.Refund
			end
		end
	end
	return result
end

return BulkSaleCore
