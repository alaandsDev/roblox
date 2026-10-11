--!strict
--[[
	Regras do inventário e dos personagens na base (puro, testável fora do Roblox).
	Opera direto na tabela de dados do jogador:
	    data.Inventory          = { [uid] = { Id, Level, Variant, Locked, Favorite, ObtainedAt } }
	    data.EquippedCharacters = { [tostring(slotId)] = uid }
	    data.NextUid            = contador para gerar uids únicos ("c1", "c2", ...)

	Toda função que pode falhar devolve (ok, códigoDoErro).
]]

local InventoryCore = {}

export type Item = { Id: string, Level: number, Variant: string, Locked: boolean, Favorite: boolean, ObtainedAt: number }

function InventoryCore.count(data: any): number
	local n = 0
	for _ in data.Inventory do
		n += 1
	end
	return n
end

function InventoryCore.add(data: any, characterId: string, now: number, variant: string?): string
	local uid = "c" .. tostring(data.NextUid)
	data.NextUid += 1
	assert(data.Inventory[uid] == nil, "uid repetido")
	data.Inventory[uid] = {
		Id = characterId,
		Level = 1,
		Variant = variant or "Normal",
		Locked = false,
		Favorite = false,
		ObtainedAt = now,
	}
	return uid
end

-- Slot onde o personagem está equipado (ou nil)
function InventoryCore.slotOf(data: any, uid: string): number?
	for slotKey, equipped in data.EquippedCharacters do
		if equipped == uid then
			return tonumber(slotKey)
		end
	end
	return nil
end

function InventoryCore.setFlag(data: any, uid: string, flag: string, value: boolean): (boolean, string?)
	local item = data.Inventory[uid]
	if not item then
		return false, "not_owned"
	end
	if flag ~= "Locked" and flag ~= "Favorite" then
		return false, "invalid_flag"
	end
	item[flag] = value
	return true, nil
end

-- Protegido contra venda (travado, favorito ou equipado)
function InventoryCore.protection(data: any, uid: string): string?
	local item = data.Inventory[uid]
	if not item then
		return "not_owned"
	end
	if item.Locked then
		return "locked"
	end
	if item.Favorite then
		return "favorite"
	end
	if InventoryCore.slotOf(data, uid) then
		return "equipped"
	end
	return nil
end

function InventoryCore.remove(data: any, uid: string): boolean
	if not data.Inventory[uid] then
		return false
	end
	local slot = InventoryCore.slotOf(data, uid)
	if slot then
		data.EquippedCharacters[tostring(slot)] = nil
	end
	data.Inventory[uid] = nil
	return true
end

--[[
	Coloca o personagem num slot da base.
	unlocked: { [slotId] = true } (vem da progressão da base). slotId nil = primeiro livre.
	Se o personagem já estava em outro slot, ele é movido.
]]
function InventoryCore.equip(data: any, uid: string, slotId: number?, unlocked: { [number]: boolean }): (boolean, string?, number?)
	if not data.Inventory[uid] then
		return false, "not_owned", nil
	end
	local target = slotId
	if target == nil then
		local candidates = {}
		for id in unlocked do
			if data.EquippedCharacters[tostring(id)] == nil then
				table.insert(candidates, id)
			end
		end
		table.sort(candidates)
		target = candidates[1]
		if target == nil then
			return false, "no_free_slot", nil
		end
	end
	assert(target)
	if not unlocked[target] then
		return false, "slot_locked", nil
	end
	local occupant = data.EquippedCharacters[tostring(target)]
	if occupant ~= nil and occupant ~= uid then
		return false, "slot_occupied", nil
	end
	local current = InventoryCore.slotOf(data, uid)
	if current then
		data.EquippedCharacters[tostring(current)] = nil
	end
	data.EquippedCharacters[tostring(target)] = uid
	return true, nil, target
end

function InventoryCore.unequip(data: any, uid: string): (boolean, string?)
	local slot = InventoryCore.slotOf(data, uid)
	if not slot then
		return false, "not_equipped"
	end
	data.EquippedCharacters[tostring(slot)] = nil
	return true, nil
end

-- Remove de slots que deixaram de existir/estar liberados (ex.: progressão mudou)
function InventoryCore.dropInvalidSlots(data: any, unlocked: { [number]: boolean })
	for slotKey, uid in data.EquippedCharacters do
		local id = tonumber(slotKey)
		if not id or not unlocked[id] or not data.Inventory[uid] then
			data.EquippedCharacters[slotKey] = nil
		end
	end
end

--[[
	Ordem de "melhor personagem": maior renda; empate -> maior power; empate -> uid (estável).
	characters = CharacterConfig.ById
]]
function InventoryCore.sortedByBest(data: any, characters: any): { string }
	local uids = {}
	for uid in data.Inventory do
		table.insert(uids, uid)
	end
	table.sort(uids, function(a, b)
		local ca = characters[data.Inventory[a].Id]
		local cb = characters[data.Inventory[b].Id]
		if ca.BaseIncome ~= cb.BaseIncome then
			return ca.BaseIncome > cb.BaseIncome
		end
		if ca.BasePower ~= cb.BasePower then
			return ca.BasePower > cb.BasePower
		end
		return a < b
	end)
	return uids
end

-- EQUIPAR MELHORES: troca tudo pelos melhores, nos slots liberados em ordem
function InventoryCore.equipBest(data: any, unlocked: { [number]: boolean }, characters: any): number
	local slots = {}
	for id in unlocked do
		table.insert(slots, id)
	end
	table.sort(slots)
	local best = InventoryCore.sortedByBest(data, characters)
	table.clear(data.EquippedCharacters)
	local placed = 0
	for i, slot in slots do
		local uid = best[i]
		if not uid then
			break
		end
		data.EquippedCharacters[tostring(slot)] = uid
		placed += 1
	end
	return placed
end

------------------------------------------------------------------------------------
-- Venda (seleção + proteção). valueOf(characterId) -> preço (vem do Formulas, no servidor)

export type SellPlan = { uids: { string }, total: number, skipped: number }

function InventoryCore.planSale(data: any, uids: { string }, valueOf: (string) -> number): SellPlan
	local plan = { uids = {}, total = 0, skipped = 0 }
	local seen = {}
	for _, uid in uids do
		if not seen[uid] then
			seen[uid] = true
			if InventoryCore.protection(data, uid) == nil then
				table.insert(plan.uids, uid)
				plan.total += valueOf(data.Inventory[uid].Id)
			else
				plan.skipped += 1
			end
		end
	end
	return plan
end

function InventoryCore.executeSale(data: any, plan: SellPlan): number
	for _, uid in plan.uids do
		InventoryCore.remove(data, uid)
	end
	return plan.total
end

--[[
	Seleção para venda em massa:
	  "Duplicates": de cada personagem, mantém 1 (prefere o protegido; senão o mais antigo)
	  "Rarity:<Id>": todos daquela raridade
	Protegidos (travado/favorito/equipado) nunca entram.
]]
function InventoryCore.selectBatch(data: any, mode: string, characters: any): { string }
	local selected = {}
	if mode == "Duplicates" then
		local groups: { [string]: { string } } = {}
		for uid, item in data.Inventory do
			groups[item.Id] = groups[item.Id] or {}
			table.insert(groups[item.Id], uid)
		end
		for _, uids in groups do
			if #uids > 1 then
				table.sort(uids, function(a, b)
					local pa = InventoryCore.protection(data, a) ~= nil
					local pb = InventoryCore.protection(data, b) ~= nil
					if pa ~= pb then
						return pa -- protegido primeiro (é o que fica)
					end
					local ta, tb = data.Inventory[a].ObtainedAt, data.Inventory[b].ObtainedAt
					if ta ~= tb then
						return ta < tb
					end
					return a < b
				end)
				for i = 2, #uids do
					if InventoryCore.protection(data, uids[i]) == nil then
						table.insert(selected, uids[i])
					end
				end
			end
		end
	elseif string.sub(mode, 1, 7) == "Rarity:" then
		local rarity = string.sub(mode, 8)
		for uid, item in data.Inventory do
			local character = characters[item.Id]
			if character and character.Rarity == rarity and InventoryCore.protection(data, uid) == nil then
				table.insert(selected, uid)
			end
		end
	end
	table.sort(selected)
	return selected
end

return InventoryCore
