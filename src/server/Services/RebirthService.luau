--!strict
--[[
	RebirthService (Fase 8): Renascimento + perks permanentes.
	    Rebirth()            -> confere dinheiro, reseta (Money, coletor, melhorias globais),
	                            Rebirths + 1, fichas, base ganha +1 slot (efeito de andar novo)
	    BuyRebirthPerk(id)   -> gasta fichas num perk permanente
	O que reseta / fica: ver RebirthConfig.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local RebirthConfig = require(Shared.Config.RebirthConfig)
local Formulas = require(Shared.Modules.GameFormulas)
local TableUtil = require(Shared.Modules.TableUtil)
local Signal = require(Shared.Modules.Signal)
local Net = require(Shared.Modules.Net)

local PlayerDataService = require(script.Parent.PlayerDataService)
local BaseService = require(script.Parent.BaseService)
local InventoryService = require(script.Parent.InventoryService)
local UpgradeService = require(script.Parent.UpgradeService)
local AnalyticsService = require(script.Parent.AnalyticsService)

local RebirthService = {}

-- (player, novoTotal)
RebirthService.Reborn = Signal.new()

local function dataOf(player: Player): any
	local data = PlayerDataService.GetData(player)
	if not data then
		Net.fail(Net.Codes.NotReady)
	end
	return data
end

function RebirthService.Rebirth(player: Player)
	local data = dataOf(player)
	local cost = Formulas:rebirthCost(data.Rebirths)
	if not cost then
		Net.fail("max_rebirth")
	end
	assert(cost)
	if data.Money < cost then
		Net.fail("not_enough_money")
	end
	local count = data.Rebirths + 1
	local tokens = Formulas:rebirthTokens(count)
	-- Tudo sem yield: um segundo pedido simultâneo vê o novo custo
	PlayerDataService.Set(player, "Money", 0)
	data.UncollectedMoney = 0
	PlayerDataService.Set(player, "Upgrades", { Luck = 0, Income = 0, RollSpeed = 0, Inventory = 0 })
	PlayerDataService.Set(player, "Rebirths", count)
	PlayerDataService.Increment(player, "RebirthTokens", tokens)
	BaseService.RefreshBase(player)
	InventoryService.Revalidate(player)
	UpgradeService.Purchased:Fire(player, "Rebirth", count)
	AnalyticsService.Track(player, "Rebirth", { count = count })
	RebirthService.Reborn:Fire(player, count)
	Net.fire("Notify", player, "rebirth.done", { count = count, tokens = tokens })
	PlayerDataService.SaveSoon(player)
	return { rebirths = count, tokens = tokens }
end

function RebirthService.BuyPerk(player: Player, perkId: string)
	local data = dataOf(player)
	if not RebirthConfig.PerksById[perkId] then
		Net.fail("invalid_perk")
	end
	local level = Formulas:perkLevel(data, perkId)
	local cost = Formulas:perkCost(perkId, level)
	if not cost then
		Net.fail("max_level")
	end
	assert(cost)
	if data.RebirthTokens < cost then
		Net.fail("not_enough_tokens")
	end
	PlayerDataService.Set(player, "RebirthTokens", data.RebirthTokens - cost)
	local perks = TableUtil.deepCopy(data.RebirthPerks)
	perks[perkId] = level + 1
	PlayerDataService.Set(player, "RebirthPerks", perks)
	UpgradeService.Purchased:Fire(player, "Perk:" .. perkId, level + 1)
	PlayerDataService.SaveSoon(player)
	return { id = perkId, level = level + 1 }
end

function RebirthService.Init()
	Net.handle("Rebirth", RebirthService.Rebirth)
	Net.handle("BuyRebirthPerk", RebirthService.BuyPerk)
end

return RebirthService
