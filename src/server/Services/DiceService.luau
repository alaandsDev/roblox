--!strict
--[[
	DiceService: desbloquear (comprar) e SELECIONAR o Dice usado no roll (LOJA DE DADOS).
	Comprar: não exclusivo, ainda não tem, requisito (rolls + Dice anterior) e dinheiro.
	Selecionar (EquipDice / SelectDice): Dice existe, é sorteável (F2P) e está desbloqueado.
	O Dice selecionado fica em data.EquippedDice (= SelectedDiceId). O cliente nunca escolhe
	raridade nem personagem: o RollService sorteia no pool do Dice selecionado (DiceCore).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local DiceConfig = require(Shared.Config.DiceConfig)
local CharacterConfig = require(Shared.Config.CharacterConfig)
local RarityConfig = require(Shared.Config.RarityConfig)
local RollConfig = require(Shared.Config.RollConfig)
local DiceCore = require(Shared.Modules.DiceCore)
local TableUtil = require(Shared.Modules.TableUtil)
local Net = require(Shared.Modules.Net)

local PlayerDataService = require(script.Parent.PlayerDataService)
local EconomyService = require(script.Parent.EconomyService)
local MapService = require(script.Parent.MapService)
local AnalyticsService = require(script.Parent.AnalyticsService)

local DiceService = {}

-- Núcleo do roll por Dice (único; RollService/IndexService/DevService usam este)
DiceService.Core = DiceCore.new(DiceConfig, CharacterConfig, RarityConfig, RollConfig)

-- Motivo pelo qual o Dice não pode ser usado para rolar (nil = pode)
function DiceService.SelectError(data: any, diceId: any): string?
	local dice = type(diceId) == "string" and DiceConfig.ById[diceId] or nil
	if not dice then
		return "invalid_dice"
	end
	if not dice.Rollable or dice.Pool ~= "F2P" or not DiceService.Core:isRollable(diceId) then
		return "dice_not_rollable"
	end
	if not (data.OwnedDice and data.OwnedDice[diceId]) then
		return "dice_locked"
	end
	return nil
end

-- Dice selecionado JÁ VALIDADO (falha com o motivo se inválido/bloqueado)
function DiceService.SelectedDice(data: any): string
	local diceId = data.EquippedDice
	local reason = DiceService.SelectError(data, diceId)
	if reason then
		Net.fail(reason)
	end
	return diceId
end

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
	local reason = DiceService.SelectError(data, diceId)
	if reason then
		Net.fail(if reason == "dice_locked" then "not_owned" else reason)
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
