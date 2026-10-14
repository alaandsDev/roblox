--!strict
--[[
	RollService: o roll (autoritativo). O cliente só pede RequestRoll() — sem argumentos: nunca
	escolhe Dice no pedido, raridade ou personagem.
	Fluxo: valida jogador/dados -> intervalo (RollConfig.RollSpeed: 1 roll/s, Roll Rápido 2/s; sem folga) ->
	Dice SELECIONADO válido (existe, sorteável, desbloqueado: DiceService.SelectedDice) ->
	inventário cheio? (bloqueia ANTES de sortear) -> Luck (upgrades + boost + ...) ->
	DiceCore no pool do Dice (raridade pelos pesos DO Dice, depois personagem; Random do servidor
	+ pity por Dice) -> Index -> auto-sell ou inventário (uid) -> resposta.
	PRISMA DA COLEÇÃO (RequestPrismRoll, sem argumentos): mesmo Dice selecionado, só entre os não
	descobertos (DiceCore:prismPick); usos/intervalo/pity/contagem de rolls em PrismConfig. Nada a
	descobrir, sem usos, intervalo ou inventário cheio -> recusa SEM gastar o uso.
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
local DiceService = require(script.Parent.DiceService)
local PrismConfig = require(Shared.Config.PrismConfig)

local log = Logger.new("Roll")

local RollService = {}

-- (player, resultado)
RollService.Rolled = Signal.new()

-- Relógio e gerador (substituíveis nos testes)
RollService._clock = os.clock
RollService._time = os.time
local random = Random.new()
RollService._rand = function(): number
	return random:NextNumber()
end

local core = DiceService.Core

-- Momento (RollService._clock) a partir do qual o próximo roll do jogador é aceito.
-- Sempre "agora + intervalo" do último roll ACEITO: sem folga, sem crédito acumulado (atraso
-- de rede ou spam nunca viram rajada). Ver RollConfig.RollSpeed.
local nextRollAt: { [Player]: number } = {}
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
	DiceId: string,
	Prism: boolean,
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

export type RollOptions = { granted: boolean?, minRarity: string?, prism: boolean? }

local function doRoll(player: Player, options: RollOptions?): RollResult
	local opts: RollOptions = options or {}
	local data = PlayerDataService.GetData(player)
	if not data then
		Net.fail(Net.Codes.NotReady)
	end
	assert(data)

	local now = RollService._clock()
	-- Dice do roll: o selecionado, validado pelo servidor a cada roll (inválido/bloqueado -> recusa)
	local selected = DiceService.SelectedDice(data)
	local prismPick: string? = nil
	if opts.prism then
		-- Prisma da Coleção: não usa a cadência do roll (tem o próprio intervalo); valida TUDO antes
		-- de gastar o uso
		if not PrismConfig.Enabled then
			Net.fail("prism_disabled")
		end
		if not data.OwnedDice[PrismConfig.DiceId] then
			Net.fail("prism_locked")
		end
		if (data.PrismCharges or 0) < 1 then
			Net.fail("prism_no_charges")
		end
		if RollService._time() - (data.PrismLastUsedAt or 0) < PrismConfig.CooldownSeconds then
			Net.fail("prism_cooldown")
		end
		if InventoryService.IsFull(player) then
			Net.fail("inventory_full")
		end
		prismPick = core:prismPick(selected, data.Index, Formulas:luck(data, os.time()), RollService._rand)
		if not prismPick then
			Net.fail("prism_dice_complete") -- nada a descobrir neste Dice: o uso NÃO é gasto
		end
		PlayerDataService.Set(player, "PrismCharges", data.PrismCharges - 1)
		PlayerDataService.Set(player, "PrismLastUsedAt", RollService._time())
	elseif not opts.granted then
		if now < (nextRollAt[player] or -math.huge) then
			Net.fail("cooldown")
		end
		-- Inventário cheio: bloqueia ANTES de gerar o resultado (roll de prêmio pode passar do limite)
		if InventoryService.IsFull(player) then
			if now - (lastFullWarning[player] or -math.huge) > 5 then
				lastFullWarning[player] = now
				AnalyticsService.Track(player, "InventoryFull", { capacity = InventoryService.Capacity(player) })
			end
			Net.fail("inventory_full")
		end
		nextRollAt[player] = now + Formulas:rollCooldown(data)
	end

	local luck = Formulas:luck(data, os.time())
	local rolled
	local diceId = selected
	if prismPick then
		local rarity = CharacterConfig.ById[prismPick].Rarity
		rolled = {
			rarity = rarity,
			characterId = prismPick,
			pity = if PrismConfig.AffectsPity then core:nextPity(diceId, data.Pity, rarity) else data.Pity,
			pityTriggered = nil,
		}
	elseif opts.minRarity then
		-- Prêmio (Jackpot): Dice selecionado se ele tem MinRarity; senão o primeiro Dice F2P que
		-- tem (DiceCore:grantDice). Sorteio natural nesse Dice; abaixo do piso vira EXATAMENTE
		-- MinRarity (nunca aumenta Divino/Secreto); não mexe no pity
		diceId = core:grantDice(selected, opts.minRarity) or selected
		local rarity = core:pickWithFloor(diceId, luck, RollService._rand, opts.minRarity)
		rolled = { rarity = rarity, characterId = core:pickCharacter(diceId, rarity, RollService._rand), pity = data.Pity, pityTriggered = nil }
	else
		rolled = core:roll(diceId, luck, data.Pity, RollService._rand)
	end
	local rarity, characterId = rolled.rarity, rolled.characterId
	PlayerDataService.Set(player, "Pity", rolled.pity)
	local countsAsRoll = not opts.prism or PrismConfig.CountsAsRoll
	local rolls = if countsAsRoll then PlayerDataService.Increment(player, "Rolls", 1) else data.Rolls
	-- só o roll natural conta para liberar o próximo Dice (Prisma e prêmios não)
	if not opts.prism and not opts.minRarity then
		local byDice = TableUtil.deepCopy(data.DiceRolls or {})
		byDice[diceId] = (byDice[diceId] or 0) + 1
		PlayerDataService.Set(player, "DiceRolls", byDice)
	end

	local isNew = IndexService.Register(player, characterId, "Normal")
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
		Odds = core:odds(characterId),
		DiceId = diceId,
		Prism = opts.prism == true,
	}
	-- Auto-sell: nunca vende uma descoberta nova (primeiro do Index) nem raridade protegida
	if not opts.granted and not isNew and SellService.ShouldAutoSell(player, rarity) then
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

function RollService.Roll(player: Player): RollResult
	return doRoll(player, nil)
end

-- Personagem garantido de minRarity ou melhor (prêmios). Ignora cooldown e inventário cheio
function RollService.GrantRoll(player: Player, minRarity: string): RollResult
	return doRoll(player, { granted = true, minRarity = minRarity })
end

-- Prisma da Coleção (sem argumentos: o Dice é o selecionado)
function RollService.PrismRoll(player: Player): RollResult
	return doRoll(player, { granted = true, prism = true })
end

function RollService.History(player: Player): { any }
	return table.clone(history[player] or {})
end

-- Para testes/DEV: zera o cooldown do jogador
function RollService.ResetCooldown(player: Player)
	nextRollAt[player] = nil
end

function RollService.Init()
	Net.handle("RequestRoll", RollService.Roll)
	Net.handle("RequestPrismRoll", RollService.PrismRoll)
end

function RollService.Start()
	Players.PlayerRemoving:Connect(function(player)
		nextRollAt[player] = nil
		history[player] = nil
		lastFullWarning[player] = nil
		lastAnnounce[player] = nil
	end)
end

return RollService
