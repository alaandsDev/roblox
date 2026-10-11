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

function FusionCore.plan(data: any, uids: { string }, configs: any): (Plan?, string?)
	if #uids ~= configs.Fusion.Required then
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
	local character = configs.Characters.ById[first.Id]
	local cost = math.floor(character.BaseIncome * configs.Fusion.CostSeconds * configs.Variants.ById[toVariant].Order)
	return { characterId = first.Id, fromVariant = fromVariant, toVariant = toVariant, level = level, cost = cost }, nil
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
		if #list >= configs.Fusion.Required then
			table.sort(list)
			local id, variant = string.match(key, "^(.-)|(.*)$")
			if FusionCore.nextVariant(configs.Variants, variant :: string) then
				table.insert(out, { characterId = id, variant = variant, uids = table.move(list, 1, configs.Fusion.Required, 1, {}), count = #list })
			end
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

return FusionCore
