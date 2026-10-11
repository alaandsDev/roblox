--!strict
--[[
	RollService: o roll (autoritativo). O cliente só pede RequestRoll() — sem argumentos.
	Fluxo: valida jogador/dados -> cooldown (Formulas:rollCooldown + folga de rede) ->
	inventário cheio? (bloqueia ANTES de sortear) -> Luck (dado + upgrades + boost) ->
	RollCore (Random do servidor + pity) -> Index -> auto-sell ou inventário (uid) -> resposta.
	Não grava no DataStore a cada roll (autosave); drops Míticos+ pedem um save em breve.
	Histórico de sessão (últimos RollConfig.HistorySize) só em memória.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local RarityConfig = require(Shared.Config.RarityConfig)
local CharacterConfig = require(Shared.Config.CharacterConfig)
local RollConfig = require(Shared.Config.RollConfig)
local RevealConfig = require(Shared.Config.RevealConfig)
local RollCore = require(Shared.Modules.RollCore)
local RevealPlanner = require(Shared.Modules.RevealPlanner)
local Formulas = require(Shared.Modules.GameFormulas)
local Logger = require(Shared.Modules.Logger)
local Signal = require(Shared.Modules.Signal)
local TableUtil = require(Shared.Modules.TableUtil)
local Net = require(Shared.Modules.Net)

local PlayerDataService = require(script.Parent.PlayerDataService)
local InventoryService = require(script.Parent.InventoryService)
local IndexService = require(script.Parent.IndexService)
local SellService = require(script.Parent.SellService)
local EconomyService = require(script.Parent.EconomyService)
local AnalyticsService = require(script.Parent.AnalyticsService)

local log = Logger.new("Roll")

local RollService = {}

-- (player, resultado)
RollService.Rolled = Signal.new()

-- Relógio e gerador (substituíveis nos testes)
RollService._clock = os.clock
local random = Random.new()
RollService._rand = function(): number
	return random:NextNumber()
end

local core = RollCore.new(RarityConfig, CharacterConfig, RollConfig)
local planner = RevealPlanner.new(RevealConfig, RarityConfig, CharacterConfig)

local lastRoll: { [Player]: number } = {}
local history: { [Player]: { any } } = {}
local lastFullWarning: { [Player]: number } = {}
local lastAnnounce: { [Player]: number } = {}

export type RollResult = {
	CharacterId: string,
	Rarity: string,
	Variant: string,
	Uid: string?,
	IsNew: boolean,
	AutoSold: boolean,
	SoldFor: number,
	PityTriggered: string?,
	Luck: number,
	TimesSeen: number,
	Odds: number,
}

local function announce(player: Player, result: RollResult)
	local social = RevealConfig.ByRarity[result.Rarity].Social
	if social == "None" then
		return
	end
	local now = os.clock()
	if now - (lastAnnounce[player] or -math.huge) < RevealConfig.SocialCooldown then
		return
	end
	lastAnnounce[player] = now
	local character = CharacterConfig.ById[result.CharacterId]
	local params = { player = player.DisplayName, name = character.Name, rarity = result.Rarity, odds = result.Odds }
	-- Só os OUTROS recebem o anúncio; quem rolou já está vendo a cinemática
	for _, other in Players:GetPlayers() do
		if other ~= player then
			Net.fire("Announce", other, "announce.drop", params, social)
		end
	end
end

function RollService.Roll(player: Player): RollResult
	local data = PlayerDataService.GetData(player)
	if not data then
		Net.fail(Net.Codes.NotReady)
	end
	assert(data)

	local now = RollService._clock()
	local cooldown = Formulas:rollCooldown(data)
	if now - (lastRoll[player] or -math.huge) < cooldown - RollConfig.CooldownTolerance then
		Net.fail("cooldown")
	end
	-- Inventário cheio: bloqueia ANTES de gerar o resultado
	if InventoryService.IsFull(player) then
		if now - (lastFullWarning[player] or -math.huge) > 5 then
			lastFullWarning[player] = now
			AnalyticsService.Track(player, "InventoryFull", { capacity = InventoryService.Capacity(player) })
		end
		Net.fail("inventory_full")
	end
	lastRoll[player] = now

	local luck = Formulas:luck(data, os.time())
	local rolled = core:roll(luck, data.Pity, RollService._rand)
	local rarity, characterId = rolled.rarity, rolled.characterId
	PlayerDataService.Set(player, "Pity", rolled.pity)
	local rolls = PlayerDataService.Increment(player, "Rolls", 1)

	local isNew = IndexService.Register(player, characterId)
	local views = TableUtil.deepCopy(data.RevealViews)
	local timesSeen = views[rarity] or 0
	views[rarity] = timesSeen + 1
	data.RevealViews = views

	local variant = "Normal"
	local result: RollResult = {
		CharacterId = characterId,
		Rarity = rarity,
		Variant = variant,
		Uid = nil,
		IsNew = isNew,
		AutoSold = false,
		SoldFor = 0,
		PityTriggered = rolled.pityTriggered,
		Luck = luck,
		TimesSeen = timesSeen,
		Odds = planner:odds(characterId),
	}
	-- Auto-sell: nunca vende uma descoberta nova (primeiro do Index) nem raridade protegida
	if not isNew and SellService.ShouldAutoSell(player, rarity) then
		result.AutoSold = true
		result.SoldFor = Formulas:sellValue(characterId, variant)
		EconomyService.AddMoney(player, result.SoldFor, "AutoSell")
		AnalyticsService.Track(player, "CharacterSold", { count = 1, total = result.SoldFor, auto = true })
	else
		result.Uid = InventoryService.Add(player, characterId, variant)
	end

	-- Histórico de sessão
	local list = history[player] or {}
	history[player] = list
	table.insert(list, 1, { CharacterId = characterId, Rarity = rarity, At = os.time() })
	while #list > RollConfig.HistorySize do
		table.remove(list)
	end

	local tier = RarityConfig.ById[rarity].Tier
	AnalyticsService.Track(player, "Roll", { rarity = rarity })
	if rolls == 1 then
		AnalyticsService.Track(player, "FirstRoll")
	end
	if tier >= RarityConfig.ById.Rare.Tier then
		AnalyticsService.Track(player, "RareObtained", { rarity = rarity })
	end
	if tier >= RarityConfig.ById.Legendary.Tier then
		AnalyticsService.Track(player, "LegendaryObtained", { rarity = rarity, id = characterId })
	end
	if tier >= RarityConfig.ById.Mythic.Tier then
		AnalyticsService.Track(player, "MythicObtained", { rarity = rarity, id = characterId })
		PlayerDataService.SaveSoon(player)
		log:info(`{player.Name} tirou {characterId} ({rarity})`)
	end
	announce(player, result)
	RollService.Rolled:Fire(player, result)
	return result
end

function RollService.History(player: Player): { any }
	return table.clone(history[player] or {})
end

-- Para testes/DEV: zera o cooldown do jogador
function RollService.ResetCooldown(player: Player)
	lastRoll[player] = nil
end

function RollService.Init()
	Net.handle("RequestRoll", RollService.Roll)
end

function RollService.Start()
	Players.PlayerRemoving:Connect(function(player)
		lastRoll[player] = nil
		history[player] = nil
		lastFullWarning[player] = nil
		lastAnnounce[player] = nil
	end)
end

return RollService
