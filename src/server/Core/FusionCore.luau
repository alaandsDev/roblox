--!strict
--[[
	Regras da Fusão (puro, testado fora do Roblox).
	    FusionCore.plan(data, uids, configs) -> (plano?, erro?)
	configs = { Fusion, Variants, Characters, Inventory = InventoryCore } (injetado: módulo puro)
	    plano = { characterId, fromVariant, toVariant, level, cost }
]]

local FusionCore = {}

export type Plan = { characterId: string, fromVariant: string, toVariant: string, level: number, cost: number }

function FusionCore.nextVariant(variants: any, id: string): string?
	local current = variants.ById[id or "Normal"]
	if not current then
		return nil
	end
	for _, v in variants.List do
		if v.Order == current.Order + 1 then
			return v.Id
		end
	end
	return nil
end

-- Quantas unidades a fusão para `variant` (variante de DESTINO) precisa
function FusionCore.required(configs: any, targetVariant: string): number
	return configs.Fusion.RequiredByTarget[targetVariant] or configs.Fusion.MaxRequired
end

function FusionCore.plan(data: any, uids: { string }, configs: any): (Plan?, string?)
	if #uids < 2 or #uids > configs.Fusion.MaxRequired then
		return nil, "fusion_count"
	end
	local seen = {}
	local first = nil
	local level = 1
	for _, uid in uids do
		if seen[uid] then
			return nil, "fusion_count"
		end
		seen[uid] = true
		local reason = configs.Inventory.protection(data, uid)
		if reason then
			return nil, reason
		end
		local item = data.Inventory[uid]
		if first == nil then
			first = item
		elseif item.Id ~= first.Id or (item.Variant or "Normal") ~= (first.Variant or "Normal") then
			return nil, "fusion_mismatch"
		end
		level = math.max(level, item.Level or 1)
	end
	assert(first)
	local fromVariant = first.Variant or "Normal"
	local toVariant = FusionCore.nextVariant(configs.Variants, fromVariant)
	if not toVariant then
		return nil, "fusion_max"
	end
	if #uids ~= FusionCore.required(configs, toVariant) then
		return nil, "fusion_count"
	end
	local character = configs.Characters.ById[first.Id]
	local cost = math.floor(character.BaseIncome * configs.Fusion.CostSeconds * configs.Variants.ById[toVariant].Order)
	return { characterId = first.Id, fromVariant = fromVariant, toVariant = toVariant, level = level, cost = cost }, nil
end

--[[
	Investimento da unidade resultante = SOMA do investimento em níveis das unidades consumidas
	(`investedOf` = SaleCore.invested). Política (DATA_SCHEMA.md):
	  - nenhuma instância sobrevive: as consumidas são removidas e nasce UMA unidade nova
	    (uid novo, variante seguinte);
	  - nível da nova = o MAIOR nível entre as consumidas (como antes);
	  - investimento da nova = soma do investimento de cada consumida, uma vez cada (uids
	    repetidos já são recusados no plano); o custo em dinheiro da fusão NÃO entra (é sink);
	  - venda posterior: base da variante nova + 75% desse investimento.
]]
function FusionCore.investment(data: any, uids: { string }, investedOf: (any) -> number): number
	local total, seen = 0, {}
	for _, uid in uids do
		local item = data.Inventory[uid]
		if item and not seen[uid] then
			seen[uid] = true
			total += math.max(0, investedOf(item))
		end
	end
	return total
end

-- Grupos que já podem ser fundidos: { characterId, variant, uids (os Required primeiros livres) }
function FusionCore.groups(data: any, configs: any): { any }
	local buckets: { [string]: { string } } = {}
	for uid, item in data.Inventory do
		if configs.Inventory.protection(data, uid) == nil then
			local key = item.Id .. "|" .. (item.Variant or "Normal")
			buckets[key] = buckets[key] or {}
			table.insert(buckets[key], uid)
		end
	end
	local out = {}
	for key, list in buckets do
		local id, variant = string.match(key, "^(.-)|(.*)$")
		local target = FusionCore.nextVariant(configs.Variants, variant :: string)
		local need = if target then FusionCore.required(configs, target) else math.huge
		if #list >= need then
			table.sort(list)
			table.insert(out, { characterId = id, variant = variant, uids = table.move(list, 1, need, 1, {}), count = #list })
		end
	end
	table.sort(out, function(a, b)
		if a.characterId ~= b.characterId then
			return a.characterId < b.characterId
		end
		return a.variant < b.variant
	end)
	return out
end

------------------------------------------------------------------------------------
-- FUNDIR MÁX. (batch): resolve a CADEIA inteira de UMA família (mesmo CharacterId) com as
-- MESMAS regras do Fuse normal. Equivalente a chamar o Fuse repetidamente na ordem canônica:
--   família -> variante mais baixa primeiro -> uids em ordem numérica (c1, c2, ..., c10).
-- Usa as unidades livres já existentes de TODAS as variantes (102 Prata = 100 novas + 2 antigas).
-- Nunca entra: equipado, travado, favorito, em troca (InventoryCore.protection).
-- Puro: não mexe em `data`; o FusionService aplica o plano de uma vez.

local function uidNumber(uid: string): number
	return tonumber(string.match(uid, "^c(%d+)$")) or math.huge
end

-- ordem canônica dos uids (numérica; "c10" depois de "c9")
function FusionCore.uidLess(a: string, b: string): boolean
	local na, nb = uidNumber(a), uidNumber(b)
	if na ~= nb then
		return na < nb
	end
	return a < b
end

local function variantsInOrder(variants: any): { any }
	local list = table.clone(variants.List)
	table.sort(list, function(a: any, b: any): boolean
		return a.Order < b.Order
	end)
	return list
end

-- Custo de UMA fusão para `targetVariant` (mesma conta do plan)
function FusionCore.cost(configs: any, characterId: string, targetVariant: string): number
	local character = configs.Characters.ById[characterId]
	return math.floor(character.BaseIncome * configs.Fusion.CostSeconds * configs.Variants.ById[targetVariant].Order)
end

-- Unidades LIVRES de uma família por variante, em ordem canônica
local function freeByVariant(data: any, characterId: string, configs: any): { [string]: { string } }
	local buckets: { [string]: { string } } = {}
	for uid, item in data.Inventory do
		if item.Id == characterId and configs.Inventory.protection(data, uid) == nil then
			local v = item.Variant or "Normal"
			buckets[v] = buckets[v] or {}
			table.insert(buckets[v], uid)
		end
	end
	for _, list in buckets do
		table.sort(list, FusionCore.uidLess)
	end
	return buckets
end

-- Próxima fusão na ordem canônica (o que um jogador clicando FUNDIR 1× faria). Usado pelos
-- testes de equivalência e para saber se uma família ainda tem fusão possível.
function FusionCore.nextFusion(data: any, configs: any, characterId: string?): { characterId: string, uids: { string }, toVariant: string }?
	local ids = {}
	if characterId then
		ids = { characterId }
	else
		local seen = {}
		for _, item in data.Inventory do
			if not seen[item.Id] then
				seen[item.Id] = true
				table.insert(ids, item.Id)
			end
		end
		table.sort(ids)
	end
	for _, id in ids do
		local buckets = freeByVariant(data, id, configs)
		for _, v in variantsInOrder(configs.Variants) do
			local target = FusionCore.nextVariant(configs.Variants, v.Id)
			local list = buckets[v.Id]
			if target and list then
				local need = FusionCore.required(configs, target)
				if #list >= need then
					return { characterId = id, uids = table.move(list, 1, need, 1, {}), toVariant = target }
				end
			end
		end
	end
	return nil
end

export type MaxStep = {
	uids: { string },
	fromVariant: string,
	toVariant: string,
	uid: string, -- uid que a unidade nova vai receber (NextUid em sequência)
	level: number,
	investment: number,
	cost: number,
}
export type MaxPlan = {
	characterId: string,
	steps: { MaxStep },
	fusions: number,
	cost: number,
	created: { [string]: number }, -- unidades NOVAS que sobram no fim, por variante
	remaining: { [string]: number }, -- livres da família no fim (inclui as novas), por variante
	top: string?, -- maior variante criada
	limitedByMoney: boolean,
	consumed: number, -- unidades já existentes consumidas
}

--[[
	Plano completo da Fusão Máxima para `characterId`.
	budget: dinheiro disponível (a cadeia para na 1ª fusão que não couber, como o Fuse normal).
	investedOf(item) = SaleCore.invested (investimento em níveis de uma unidade).
	Erros: "fusion_invalid" (personagem inexistente) · "fusion_none" (nada a fundir).
]]
function FusionCore.fuseMaxPlan(data: any, characterId: string, configs: any, investedOf: (any) -> number, budget: number): (MaxPlan?, string?)
	if type(characterId) ~= "string" or not configs.Characters.ById[characterId] then
		return nil, "fusion_invalid"
	end
	local buckets = freeByVariant(data, characterId, configs)
	-- unidades "virtuais" do plano: uid -> { level, investment, new }
	local units: { [string]: { level: number, investment: number, new: boolean } } = {}
	for _, list in buckets do
		for _, uid in list do
			local item = data.Inventory[uid]
			units[uid] = { level = item.Level or 1, investment = math.max(0, investedOf(item)), new = false }
		end
	end
	local nextUid = data.NextUid
	local steps: { MaxStep } = {}
	local total, limited, consumed = 0, false, 0
	local order = variantsInOrder(configs.Variants)
	for _, v in order do
		local target = FusionCore.nextVariant(configs.Variants, v.Id)
		local list = buckets[v.Id]
		if not target or not list then
			continue
		end
		local need = FusionCore.required(configs, target)
		local cost = FusionCore.cost(configs, characterId, target)
		local i = 1
		while #list - i + 1 >= need do
			if total + cost > budget then
				limited = true
				break
			end
			local uids = table.move(list, i, i + need - 1, 1, {})
			local level, investment = 1, 0
			for _, uid in uids do
				local u = units[uid]
				level = math.max(level, u.level)
				investment += u.investment
				if not u.new then
					consumed += 1
				end
				units[uid] = nil
			end
			local uid = "c" .. tostring(nextUid)
			nextUid += 1
			units[uid] = { level = level, investment = investment, new = true }
			buckets[target] = buckets[target] or {}
			-- uid novo é maior que todos os existentes: continua em ordem canônica
			table.insert(buckets[target], uid)
			table.insert(steps, { uids = uids, fromVariant = v.Id, toVariant = target, uid = uid, level = level, investment = investment, cost = cost })
			total += cost
			i += need
		end
		buckets[v.Id] = table.move(list, i, #list, 1, {})
		if limited then
			break
		end
	end
	if #steps == 0 then
		return nil, if limited then "not_enough_money" else "fusion_none"
	end
	local created, remaining = {}, {}
	local top: string? = nil
	for variant, list in buckets do
		for _, uid in list do
			remaining[variant] = (remaining[variant] or 0) + 1
			if units[uid] and units[uid].new then
				created[variant] = (created[variant] or 0) + 1
				if not top or configs.Variants.ById[variant].Order > configs.Variants.ById[top].Order then
					top = variant
				end
			end
		end
	end
	return {
		characterId = characterId,
		steps = steps,
		fusions = #steps,
		cost = total,
		created = created,
		remaining = remaining,
		top = top,
		limitedByMoney = limited,
		consumed = consumed,
	}, nil
end

return FusionCore
