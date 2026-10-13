--!strict
-- Migrações do formato dos dados do Roll Legends (para FUTURAS atualizações).
-- Módulo puro: testado fora do Roblox.
--
-- Migrations[N] recebe dados da versão N-1 e devolve dados na versão N.
-- Exemplo (quando SchemaVersion virar 2):
--   Migrations[2] = function(data)
--       data.Gems = data.Gems or 0
--       data.Settings.Music = true
--       return data
--   end
-- O ProfileCore aplica todas em sequência até DataConfig.SchemaVersion e depois
-- completa o que faltar com o Template.
-- NUNCA apague uma migração antiga: jogadores que ficaram meses fora ainda precisam dela.

local Migrations: { [number]: (data: { [string]: any }) -> { [string]: any } } = {}

-- v2 (Fases 3–6 + estações): unidades ganham Level/Variant/flags; campos novos vêm do Template.
Migrations[2] = function(data)
	if type(data.Inventory) ~= "table" then
		data.Inventory = {}
	end
	local maxUid = 0
	for uid, item in data.Inventory do
		if type(item) ~= "table" or type(item.Id) ~= "string" then
			data.Inventory[uid] = nil
			continue
		end
		item.Level = if type(item.Level) == "number" and item.Level >= 1 then math.floor(item.Level) else 1
		item.Variant = if type(item.Variant) == "string" then item.Variant else "Normal"
		item.Locked = item.Locked == true
		item.Favorite = item.Favorite == true
		item.ObtainedAt = if type(item.ObtainedAt) == "number" then item.ObtainedAt else 0
		local n = tonumber(string.match(tostring(uid), "^c(%d+)$"))
		if n and n > maxUid then
			maxUid = n
		end
	end
	-- NextUid sempre acima de qualquer uid existente (nunca repetir)
	if type(data.NextUid) ~= "number" or data.NextUid <= maxUid then
		data.NextUid = maxUid + 1
	end
	if type(data.EquippedCharacters) ~= "table" then
		data.EquippedCharacters = {}
	end
	for slot, uid in data.EquippedCharacters do
		if data.Inventory[uid] == nil then
			data.EquippedCharacters[slot] = nil
		end
	end
	return data
end

-- v3 (16 Dice por pool): o dado "Normal" virou "Starter" (mesmo papel: o primeiro, grátis). Os
-- outros ids antigos continuam (Lucky, Flame, Storm, Void, Celestial, Prism). Mapa congelado aqui
-- de propósito: a migração não pode mudar se o DiceConfig mudar depois.
local RENAMED_DICE_V3 = { Normal = "Starter" }
Migrations[3] = function(data)
	local owned = if type(data.OwnedDice) == "table" then data.OwnedDice else {}
	local renamed = {}
	for id, value in owned do
		if value == true and type(id) == "string" then
			renamed[RENAMED_DICE_V3[id] or id] = true
		end
	end
	renamed.Starter = true
	data.OwnedDice = renamed
	local equipped = data.EquippedDice
	data.EquippedDice = if type(equipped) == "string" then (RENAMED_DICE_V3[equipped] or equipped) else "Starter"
	return data
end

return Migrations
