--!strict
--[[
	SellService: venda de personagens e auto-sell.
	    SellCharacter({ uid })              -> vende os não protegidos (falha se nenhum puder)
	    SellBatch(modo, confirmar)          -> confirmar=false só devolve a prévia { count, total }
	    SetAutoSell(raridade, ligado)       -> Secret nunca (Definitions + RollConfig)
	    SellService.ShouldAutoSell(player, raridade)
	Preço sempre calculado no servidor (Formulas:sellValue). Travados, favoritos e equipados
	nunca são vendidos (nem em massa).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local CharacterConfig = require(Shared.Config.CharacterConfig)
local RollConfig = require(Shared.Config.RollConfig)
local Formulas = require(Shared.Modules.GameFormulas)
local TableUtil = require(Shared.Modules.TableUtil)
local Net = require(Shared.Modules.Net)

local InventoryCore = require(script.Parent.Parent.Core.InventoryCore)
local PlayerDataService = require(script.Parent.PlayerDataService)
local MapService = require(script.Parent.MapService)
local InventoryService = require(script.Parent.InventoryService)
local EconomyService = require(script.Parent.EconomyService)
local AnalyticsService = require(script.Parent.AnalyticsService)

local SellService = {}

local function dataOf(player: Player): any
	local data = PlayerDataService.GetData(player)
	if not data then
		Net.fail(Net.Codes.NotReady)
	end
	return data
end

local function valueOf(data: any): (string) -> number
	return function(uid: string): number
		local item = data.Inventory[uid]
		return if item then Formulas:sellValue(item.Id, item.Variant) else 0
	end
end

-- planSale recebe o characterId; aqui o preço depende da variante, então avaliamos por uid
local function plan(data: any, uids: { string }): InventoryCore.SellPlan
	local price = valueOf(data)
	local result = { uids = {}, total = 0, skipped = 0 }
	local seen = {}
	for _, uid in uids do
		if not seen[uid] then
			seen[uid] = true
			if InventoryCore.protection(data, uid) == nil then
				table.insert(result.uids, uid)
				result.total += price(uid)
			else
				result.skipped += 1
			end
		end
	end
	return result
end

local function execute(player: Player, data: any, sale: InventoryCore.SellPlan): number
	local _ = data
	InventoryService.Remove(player, sale.uids)
	if sale.total > 0 then
		EconomyService.AddMoney(player, sale.total, "Sell")
	end
	AnalyticsService.Track(player, "CharacterSold", { count = #sale.uids, total = sale.total })
	return sale.total
end

function SellService.SellCharacter(player: Player, uids: { string })
	local data = dataOf(player)
	if #uids == 1 then
		local reason = InventoryCore.protection(data, uids[1])
		if reason then
			Net.fail(reason)
		end
	end
	local sale = plan(data, uids)
	if #sale.uids == 0 then
		Net.fail("nothing_to_sell")
	end
	local total = execute(player, data, sale)
	return { count = #sale.uids, total = total, skipped = sale.skipped }
end

function SellService.SellBatch(player: Player, mode: string, confirm: boolean)
	local data = dataOf(player)
	local selected = InventoryCore.selectBatch(data, mode, CharacterConfig.ById)
	local sale = plan(data, selected)
	if not confirm then
		return { count = #sale.uids, total = sale.total, preview = true }
	end
	if #sale.uids == 0 then
		Net.fail("nothing_to_sell")
	end
	local total = execute(player, data, sale)
	return { count = #sale.uids, total = total, preview = false }
end

function SellService.ShouldAutoSell(player: Player, rarity: string): boolean
	if table.find(RollConfig.ProtectedFromAutoSell, rarity) then
		return false
	end
	local data = PlayerDataService.GetData(player)
	return data ~= nil and data.Settings.AutoSell[rarity] == true
end

function SellService.SetAutoSell(player: Player, rarity: string, enabled: boolean)
	local data = dataOf(player)
	if table.find(RollConfig.ProtectedFromAutoSell, rarity) then
		Net.fail("protected")
	end
	local settings = TableUtil.deepCopy(data.Settings)
	settings.AutoSell[rarity] = enabled
	PlayerDataService.Set(player, "Settings", settings)
	return settings.AutoSell
end

function SellService.Init()
	Net.handle("SellCharacter", SellService.SellCharacter)
	Net.handle("SellBatch", SellService.SellBatch)
	Net.handle("SetAutoSell", SellService.SetAutoSell)
	MapService.RegisterInteraction("Sell", function(player)
		Net.fire("OpenMenu", player, "Sell")
	end)
end

return SellService
