--!strict
--[[
	JackpotService (Fase 10): Giro do Jackpot, loja de gemas e entrega dos produtos Robux.
	    SpinJackpot()      -> gasta JackpotConfig.GemCost gemas e sorteia um prêmio
	    BuyGemItem(id)     -> itens da loja de gemas
	    Produtos (ProcessReceipt): MoneySmall, MoneyLarge, LuckBoost, JackpotSpin, Gems500
	Prêmios resolvidos no servidor; o cliente recebe JackpotResult para mostrar (e o reveal
	quando o prêmio é personagem). A loja MERCADO no Hub abre a janela da loja.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local JackpotConfig = require(Shared.Config.JackpotConfig)
local MonetizationConfig = require(Shared.Config.MonetizationConfig)
local JackpotCore = require(Shared.Modules.JackpotCore)
local Formulas = require(Shared.Modules.GameFormulas)
local Net = require(Shared.Modules.Net)

local PlayerDataService = require(script.Parent.PlayerDataService)
local EconomyService = require(script.Parent.EconomyService)
local RollService = require(script.Parent.RollService)
local MonetizationService = require(script.Parent.MonetizationService)
local MapService = require(script.Parent.MapService)
local AnalyticsService = require(script.Parent.AnalyticsService)

local JackpotService = {}

local random = Random.new()
JackpotService._rand = function(): number
	return random:NextNumber()
end

local function luckBoost(player: Player, data: any, multiplier: number, duration: number)
	local boosts = table.clone(data.Boosts or {})
	boosts.Luck = JackpotCore.mergeBoost(boosts.Luck, multiplier, duration, os.time())
	PlayerDataService.Set(player, "Boosts", boosts)
end

local function moneyFor(data: any, seconds: number, minimum: number): number
	return math.floor(math.max(minimum, Formulas:incomePerSecond(data) * seconds))
end

-- Entrega um prêmio do Jackpot (sem cobrar). Devolve a descrição enviada ao cliente
function JackpotService.Grant(player: Player, prize: any): { [string]: any }
	local data = PlayerDataService.GetData(player)
	assert(data, "dados não carregados")
	local result: { [string]: any } = { id = prize.Id, kind = prize.Kind, icon = prize.Icon }
	if prize.Kind == "Money" then
		result.amount = moneyFor(data, prize.Seconds, prize.Min)
		EconomyService.AddMoney(player, result.amount, "Jackpot")
	elseif prize.Kind == "Gems" then
		result.amount = prize.Amount
		PlayerDataService.Increment(player, "Gems", prize.Amount)
	elseif prize.Kind == "LuckBoost" then
		result.multiplier, result.duration = prize.Multiplier, prize.Duration
		luckBoost(player, data, prize.Multiplier, prize.Duration)
	elseif prize.Kind == "Roll" then
		result.roll = RollService.GrantRoll(player, prize.MinRarity)
	end
	Net.fire("JackpotResult", player, result)
	PlayerDataService.SaveSoon(player)
	return result
end

function JackpotService.SpinFree(player: Player): { [string]: any }
	return JackpotService.Grant(player, JackpotCore.pick(JackpotConfig.Rewards, JackpotService._rand))
end

local function spendGems(player: Player, data: any, cost: number)
	if (data.Gems or 0) < cost then
		Net.fail("not_enough_gems")
	end
	PlayerDataService.Set(player, "Gems", data.Gems - cost)
end

function JackpotService.Spin(player: Player)
	local data = PlayerDataService.GetData(player)
	if not data then
		Net.fail(Net.Codes.NotReady)
	end
	spendGems(player, data, JackpotConfig.GemCost)
	AnalyticsService.Track(player, "PurchaseCompleted", { item = "JackpotSpin", currency = "Gems" })
	return JackpotService.SpinFree(player)
end

function JackpotService.BuyGemItem(player: Player, id: string)
	local data = PlayerDataService.GetData(player)
	if not data then
		Net.fail(Net.Codes.NotReady)
	end
	local item
	for _, entry in JackpotConfig.GemShop do
		if entry.Id == id then
			item = entry
		end
	end
	if not item then
		Net.fail("invalid_item")
	end
	if item.Id == "JackpotSpin" then
		return JackpotService.Spin(player)
	end
	spendGems(player, data, item.Cost)
	AnalyticsService.Track(player, "PurchaseCompleted", { item = id, currency = "Gems" })
	return JackpotService.Grant(player, { Id = item.Id, Kind = item.Kind, Seconds = item.Seconds, Min = item.Min, Multiplier = item.Multiplier, Duration = item.Duration, Icon = item.Icon })
end

function JackpotService.Init()
	Net.handle("SpinJackpot", JackpotService.Spin)
	Net.handle("BuyGemItem", JackpotService.BuyGemItem)
	MapService.RegisterInteraction("Market", function(player)
		Net.fire("OpenMenu", player, "Store")
	end)
	-- Produtos em Robux (entregues pelo ProcessReceipt idempotente)
	for key, pack in MonetizationConfig.MoneyPacks do
		MonetizationService.RegisterProduct(key, function(player, data)
			local amount = moneyFor(data, pack.Seconds, pack.Min)
			EconomyService.AddMoney(player, amount, "Product")
			Net.fire("JackpotResult", player, { id = key, kind = "Money", amount = amount, icon = "💰" })
			AnalyticsService.Track(player, "PurchaseCompleted", { item = key, currency = "Robux" })
			return true
		end)
	end
	MonetizationService.RegisterProduct("LuckBoost", function(player, data)
		local cfg = MonetizationConfig.LuckBoostProduct
		luckBoost(player, data, cfg.Multiplier, cfg.Duration)
		Net.fire("JackpotResult", player, { id = "LuckBoost", kind = "LuckBoost", multiplier = cfg.Multiplier, duration = cfg.Duration, icon = "🌟" })
		AnalyticsService.Track(player, "PurchaseCompleted", { item = "LuckBoost", currency = "Robux" })
		return true
	end)
	MonetizationService.RegisterProduct("JackpotSpin", function(player)
		JackpotService.SpinFree(player)
		AnalyticsService.Track(player, "PurchaseCompleted", { item = "JackpotSpin", currency = "Robux" })
		return true
	end)
	for key, amount in MonetizationConfig.GemsProduct do
		MonetizationService.RegisterProduct(key, function(player)
			PlayerDataService.Increment(player, "Gems", amount)
			Net.fire("JackpotResult", player, { id = key, kind = "Gems", amount = amount, icon = "💎" })
			AnalyticsService.Track(player, "PurchaseCompleted", { item = key, currency = "Robux" })
			return true
		end)
	end
end

return JackpotService
