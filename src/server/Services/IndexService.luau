--!strict
--[[
	IndexService: coleção de personagens descobertos.
	    IndexService.Register(player, characterId) -> true se é a PRIMEIRA vez (NOVO!)
	    IndexService.Discovered(player)        -> F2P descobertos (coleção principal, x / 112)
	    IndexService.DiscoveredPremium(player) -> Premium descobertos (x / 9, separado)
	    IndexService.GetCharactersForDice(diceId) / GetDiscoveredForDice(player, diceId) -> por Dice
	data.Index = { [characterId] = { Count, FirstAt, Variants? } }. Personagens vendidos (inclusive no
	auto-sell) continuam descobertos. Marcos (IndexConfig) dão recompensa uma única vez.
	Variants = { [variantId] = true } (campo novo e opcional: saves antigos continuam válidos,
	sem migração). Coleção principal = 112 F2P (CharacterConfig.List): os marcos usam SÓ ela, então
	completar o jogo nunca depende de Premium (Robux). Premium (9) tem progresso próprio. Legados,
	reserva, evento, limited e stands não contam em nada.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local CharacterConfig = require(Shared.Config.CharacterConfig)
local IndexConfig = require(Shared.Config.IndexConfig)
local Net = require(Shared.Modules.Net)

local PlayerDataService = require(script.Parent.PlayerDataService)
local DiceService = require(script.Parent.DiceService)
local AnalyticsService = require(script.Parent.AnalyticsService)

local IndexService = {}

-- Coleção principal = 112 F2P; Premium = 9 (separado)
local official: { [string]: boolean } = {}
for _, character in CharacterConfig.List do
	official[character.Id] = true
end
local premium: { [string]: boolean } = {}
for _, character in CharacterConfig.Premium do
	premium[character.Id] = true
end

local function countIn(player: Player, set: { [string]: boolean }): number
	local data = PlayerDataService.GetData(player)
	local n = 0
	if data then
		for id in data.Index do
			if set[id] then
				n += 1
			end
		end
	end
	return n
end

function IndexService.Discovered(player: Player): number
	return countIn(player, official)
end

function IndexService.DiscoveredPremium(player: Player): number
	return countIn(player, premium)
end

-- Personagens do Dice (ordem do pool: raridade, id)
function IndexService.GetCharactersForDice(diceId: string): { string }
	return DiceService.Core:charactersFor(diceId)
end

-- (descobertos, total) do Dice para o jogador
function IndexService.GetDiscoveredForDice(player: Player, diceId: string): (number, number)
	local ids = IndexService.GetCharactersForDice(diceId)
	local data = PlayerDataService.GetData(player)
	local n = 0
	for _, id in ids do
		if data and data.Index[id] then
			n += 1
		end
	end
	return n, #ids
end

local function checkMilestones(player: Player, data: any)
	local percent = IndexService.Discovered(player) / CharacterConfig.Count * 100
	for _, milestone in IndexConfig.Milestones do
		local key = tostring(milestone.Percent)
		if percent >= milestone.Percent and not data.IndexRewards[key] then
			data.IndexRewards[key] = true
			local reward = milestone.Reward
			if reward.Kind == "Gems" then
				PlayerDataService.Increment(player, "Gems", reward.Amount)
			end
			PlayerDataService.Replicate(player, "IndexRewards")
			Net.fire("Notify", player, "index.milestone", { percent = milestone.Percent, amount = reward.Amount })
			AnalyticsService.Track(player, "IndexMilestone", { percent = milestone.Percent })
		end
	end
end

-- Variante descoberta (não mexe em Count nem nos marcos). Ex.: Fusão Normal -> Silver.
function IndexService.RegisterVariant(player: Player, characterId: string, variant: string?)
	local data = PlayerDataService.GetData(player)
	local entry = data and data.Index[characterId]
	if not entry or not variant then
		return
	end
	entry.Variants = entry.Variants or {}
	if not entry.Variants[variant] then
		entry.Variants[variant] = true
		PlayerDataService.Replicate(player, "Index")
	end
end

function IndexService.Register(player: Player, characterId: string, variant: string?): boolean
	local data = PlayerDataService.GetData(player)
	if not data or not CharacterConfig.ById[characterId] then
		return false
	end
	local entry = data.Index[characterId]
	local isNew = entry == nil
	if isNew then
		entry = { Count = 1, FirstAt = os.time() }
		data.Index[characterId] = entry
	else
		entry.Count = (entry.Count or 0) + 1
	end
	if variant then
		entry.Variants = entry.Variants or {}
		entry.Variants[variant] = true
	end
	PlayerDataService.Replicate(player, "Index")
	if isNew then
		checkMilestones(player, data)
	end
	return isNew
end

return IndexService
