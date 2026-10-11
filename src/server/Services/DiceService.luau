--!strict
--[[
	DiceService: comprar e equipar dados (LOJA DE DADOS).
	Comprar: não exclusivo, ainda não tem, requisito (rolls + dado anterior) e dinheiro.
	Equipar: só dado que o jogador possui (OwnedDice).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local DiceConfig = require(Shared.Config.DiceConfig)
local TableUtil = require(Shared.Modules.TableUtil)
local Net = require(Shared.Modules.Net)

local PlayerDataService = require(script.Parent.PlayerDataService)
local EconomyService = require(script.Parent.EconomyService)
local MapService = require(script.Parent.MapService)
local AnalyticsService = require(script.Parent.AnalyticsService)

local DiceService = {}

local function dataOf(player: Player): any
	local data = PlayerDataService.GetData(player)
	if not data then
		Net.fail(Net.Codes.NotReady)
	end
	return data
end

-- Motivo pelo qual não pode comprar (nil = pode)
function DiceService.CanBuy(data: any, diceId: string): string?
	local dice = DiceConfig.ById[diceId]
	if not dice then
		return "invalid_dice"
	end
	if dice.Exclusive then
		return "exclusive"
	end
	if data.OwnedDice[diceId] then
		return "already_owned"
	end
	local req = dice.UnlockRequirement
	if req.Dice and not data.OwnedDice[req.Dice] then
		return "requires_previous"
	end
	if req.Rolls and data.Rolls < req.Rolls then
		return "requires_rolls"
	end
	if data.Money < dice.Price then
		return "not_enough_money"
	end
	return nil
end

function DiceService.Grant(player: Player, diceId: string)
	local data = PlayerDataService.GetData(player)
	if data and DiceConfig.ById[diceId] then
		local owned = TableUtil.deepCopy(data.OwnedDice)
		owned[diceId] = true
		PlayerDataService.Set(player, "OwnedDice", owned)
	end
end

function DiceService.Buy(player: Player, diceId: string)
	local data = dataOf(player)
	local reason = DiceService.CanBuy(data, diceId)
	if reason then
		Net.fail(reason)
	end
	local dice = DiceConfig.ById[diceId]
	if not EconomyService.TrySpend(player, dice.Price) then
		Net.fail("not_enough_money")
	end
	DiceService.Grant(player, diceId)
	-- Comprou: já equipa (é sempre melhor que o anterior)
	PlayerDataService.Set(player, "EquippedDice", diceId)
	AnalyticsService.Track(player, "DicePurchased", { id = diceId })
	PlayerDataService.SaveSoon(player)
	return diceId
end

function DiceService.Equip(player: Player, diceId: string)
	local data = dataOf(player)
	if not DiceConfig.ById[diceId] then
		Net.fail("invalid_dice")
	end
	if not data.OwnedDice[diceId] then
		Net.fail("not_owned")
	end
	PlayerDataService.Set(player, "EquippedDice", diceId)
	return diceId
end

function DiceService.Init()
	Net.handle("BuyDice", DiceService.Buy)
	Net.handle("EquipDice", DiceService.Equip)
	MapService.RegisterInteraction("DiceShop", function(player)
		Net.fire("OpenMenu", player, "DiceShop")
	end)
end

return DiceService
