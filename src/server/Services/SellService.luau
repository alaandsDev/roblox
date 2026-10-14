--!strict
--[[
	SellService: venda de personagens e auto-sell.
	    SellCharacter({ uid })              -> vende os não protegidos (falha se nenhum puder)
	    SellBatch(modo, confirmar)          -> confirmar=false só devolve a prévia { count, total }
	    SetAutoSell(raridade, ligado)       -> Secret nunca (Definitions + RollConfig)
	    PreviewSale({ uid })                -> só mostra: por unidade { Base, Invested, Percent,
	                                           Refund, Total } + somas. Mesma conta da venda.
	    SellService.ShouldAutoSell(player, raridade)
	VENDA EM MASSA da Mochila (BulkSaleCore; o cliente só manda UIDs):
	    PreviewBulkSale({ uid })            -> prévia autoritativa com motivo de cada uid recusado
	    SellBulk({ uid }, totalEsperado, requestId)
	        revalida TUDO no estado atual (dono, repetido, travado, favorito, equipado, time da
	        Torre, em troca), recalcula o preço com o MESMO SaleCore.quote da venda individual
	        (total = Σ cotações unitárias), recusa "price_changed" se o total mudou desde a prévia
	        mostrada, nunca paga uid inválido e devolve { sold, count, total, skipped = {uid, reason} }.
	        Replay do mesmo requestId devolve o resultado anterior SEM pagar de novo; requisições
	        simultâneas do mesmo jogador são recusadas ("busy").
	Preço sempre calculado no servidor (SaleCore.quote: valor base + reembolso do investimento em
	níveis, EconomyConfig.UpgradeRefundPercent = 0 hoje). Travados, favoritos e equipados
	nunca são vendidos (nem em massa).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local CharacterConfig = require(Shared.Config.CharacterConfig)
local RollConfig = require(Shared.Config.RollConfig)
local EconomyConfig = require(Shared.Config.EconomyConfig)
local Formulas = require(Shared.Modules.GameFormulas)
local TableUtil = require(Shared.Modules.TableUtil)
local SaleCore = require(Shared.Modules.SaleCore)
local BulkSaleCore = require(Shared.Modules.BulkSaleCore)
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

-- Cotação de UMA unidade do inventário do servidor (nunca valores do cliente)
local function quoteOf(data: any, uid: string): SaleCore.Quote
	return SaleCore.quote(Formulas, data.Inventory[uid], EconomyConfig.UpgradeRefundPercent)
end

local function valueOf(data: any): (string) -> number
	return function(uid: string): number
		return quoteOf(data, uid).Total
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

-- Prévia autoritativa (não vende): só unidades que existem e PODEM ser vendidas
function SellService.PreviewSale(player: Player, uids: { string })
	local data = dataOf(player)
	local sale = plan(data, uids)
	local items, sum = {}, { Base = 0, Invested = 0, Refund = 0, Total = 0 }
	for _, uid in sale.uids do
		local quote = quoteOf(data, uid)
		items[uid] = quote
		sum.Base += quote.Base
		sum.Invested += quote.Invested
		sum.Refund += quote.Refund
		sum.Total += quote.Total
	end
	return {
		items = items,
		count = #sale.uids,
		skipped = sale.skipped,
		percent = SaleCore.percent(EconomyConfig.UpgradeRefundPercent),
		base = sum.Base,
		invested = sum.Invested,
		refund = sum.Refund,
		total = sum.Total,
	}
end

------------------------------------------------------------------------------------
-- Venda em massa (Mochila)

local bulkBusy: { [Player]: boolean } = setmetatable({}, { __mode = "k" }) :: any
-- últimos requestIds processados por jogador (sessão): replay não paga duas vezes
local bulkDone: { [Player]: { ids: { string }, results: { [string]: any } } } = setmetatable({}, { __mode = "k" }) :: any
local REPLAY_MEMORY = 16

local function bulkPlan(data: any, uids: { string }): BulkSaleCore.Plan
	return BulkSaleCore.plan(data, uids, InventoryCore.protection, function(uid: string)
		return quoteOf(data, uid)
	end)
end

function SellService.PreviewBulkSale(player: Player, uids: { string })
	local data = dataOf(player)
	local p = bulkPlan(data, uids)
	return {
		uids = p.uids,
		count = #p.uids,
		total = p.total,
		base = p.base,
		invested = p.invested,
		refund = p.refund,
		percent = SaleCore.percent(EconomyConfig.UpgradeRefundPercent),
		skipped = p.skipped,
	}
end

function SellService.SellBulk(player: Player, uids: { string }, expectedTotal: number?, requestId: string?)
	local data = dataOf(player)
	local memory = bulkDone[player]
	if requestId and memory and memory.results[requestId] then
		local previous: any = table.clone(memory.results[requestId])
		previous.replay = true
		return previous
	end
	if bulkBusy[player] then
		Net.fail("busy")
	end
	bulkBusy[player] = true
	local ok, result = pcall(function()
		local p = bulkPlan(data, uids)
		if #p.uids == 0 then
			Net.fail("nothing_to_sell")
		end
		if expectedTotal ~= nil and expectedTotal ~= p.total then
			Net.fail("price_changed") -- o cliente pede a prévia de novo e o jogador reconfirma
		end
		-- planejamento e execução sem yield entre eles: o estado não muda no meio
		local total = execute(player, data, { uids = p.uids, total = p.total, skipped = #p.skipped })
		return {
			sold = p.uids,
			count = #p.uids,
			total = total,
			base = p.base,
			invested = p.invested,
			refund = p.refund,
			skipped = p.skipped,
			requestId = requestId,
		}
	end)
	bulkBusy[player] = nil
	if not ok then
		error(result, 0)
	end
	if requestId then
		memory = memory or { ids = {}, results = {} }
		bulkDone[player] = memory
		table.insert(memory.ids, requestId)
		memory.results[requestId] = result
		if #memory.ids > REPLAY_MEMORY then
			local oldest = table.remove(memory.ids, 1)
			if oldest then
				memory.results[oldest] = nil
			end
		end
	end
	return result :: any
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
	Net.handle("PreviewSale", SellService.PreviewSale)
	Net.handle("PreviewBulkSale", SellService.PreviewBulkSale)
	Net.handle("SellBulk", SellService.SellBulk)
	MapService.RegisterInteraction("Sell", function(player)
		Net.fire("OpenMenu", player, "Sell")
	end)
end

return SellService
