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

--[[
	v4 (balanceamento aplicado): investimento em níveis POR INSTÂNCIA + cap de nível 30.
	  - toda unidade com Level > 1 sem UpgradeInvestment válido recebe a soma EXATA da curva oficial
	    do nível 1 até o nível SALVO (calculada antes de qualquer corte): é o que o jogador pagou;
	  - unidade acima do novo cap (MaxLevel 30) passa a ter Level 30 — o investimento histórico fica
	    gravado e continua valendo na venda (75%) e na fusão (soma). Nenhum dinheiro é concedido aqui.
	A curva vem do contexto (PlayerDataService injeta SaleCore.curveInvestment com as configs do
	jogo). Sem contexto (ferramentas/testes que não injetam) a migração NÃO corta nível nem grava:
	o fallback (A) do SaleCore recalcula pela curva no nível salvo — nada se perde.
]]
local Context: { investmentOf: ((string, number) -> number)?, maxLevel: number? } = {}

Migrations[4] = function(data)
	local ctx = (Migrations :: any).Context or Context
	if type(data.Inventory) ~= "table" or not ctx.investmentOf or not ctx.maxLevel then
		return data
	end
	for _, item in data.Inventory do
		if type(item) == "table" and type(item.Id) == "string" then
			local level = if type(item.Level) == "number" and item.Level >= 1 then math.floor(item.Level) else 1
			local stored = item.UpgradeInvestment
			local valid = type(stored) == "number" and stored == stored and stored >= 0 and stored < math.huge
			if not valid then
				item.UpgradeInvestment = nil
				if level > 1 then
					item.UpgradeInvestment = ctx.investmentOf(item.Id, level)
				end
			end
			if level > ctx.maxLevel then
				level = ctx.maxLevel
			end
			item.Level = level
		end
	end
	return data
end

-- Contexto da v4 (PlayerDataService injeta: Migrations.Context.investmentOf / .maxLevel)
;(Migrations :: any).Context = Context

return Migrations
