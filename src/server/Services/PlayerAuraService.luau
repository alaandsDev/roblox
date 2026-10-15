--!strict
--[[
	PlayerAuraService: PLAYER AURAS (avatar do jogador; NÃO é a Character Aura).
	    BuyPlayerAura(tier)    -> só o PRÓXIMO tier (Owned + 1); preço da config; permanente
	    EquipPlayerAura(tier)  -> visual 0..Owned (0 = nenhum); cosmético
	Server-authoritative: o cliente manda só o tier desejado. Preço, ordem, saldo, multiplicador e
	WalkSpeed são do servidor. Multiplicador/WalkSpeed vêm SEMPRE do maior tier comprado
	(Formulas:playerAuraMultiplier / :walkSpeed), nunca do visual equipado.
	Replicação para TODOS os clientes (que desenham as auras com LOD): atributos no Player
	    PlayerAuraTier   (maior comprado)
	    PlayerAuraVisual (visual equipado)
	Respawn: atributos ficam no Player; o BaseService reaplica o WalkSpeed a cada spawn; o
	PlayerAuraController reconstrói o visual (sem duplicar).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local PlayerAuraConfig = require(Shared.Config.PlayerAuraConfig)
local Formulas = require(Shared.Modules.GameFormulas)
local Net = require(Shared.Modules.Net)
local Logger = require(Shared.Modules.Logger)

local PlayerDataService = require(script.Parent.PlayerDataService)
local EconomyService = require(script.Parent.EconomyService)
local BaseService = require(script.Parent.BaseService)
local AnalyticsService = require(script.Parent.AnalyticsService)

local log = Logger.new("PlayerAura")

local PlayerAuraService = {}

local busy: { [Player]: boolean } = {}

local function state(data: any): (number, number)
	local owned = Formulas:playerAuraTier(data)
	local aura = data.PlayerAura
	local equipped = if type(aura) == "table" and type(aura.Equipped) == "number" then math.clamp(math.floor(aura.Equipped), 0, owned) else owned
	return owned, equipped
end

-- Atributos replicados (todos os clientes desenham a aura de todos)
function PlayerAuraService.Apply(player: Player)
	local data = PlayerDataService.GetData(player)
	if not data then
		return
	end
	local owned, equipped = state(data)
	player:SetAttribute("PlayerAuraTier", owned)
	player:SetAttribute("PlayerAuraVisual", equipped)
	BaseService.ApplyWalkSpeed(player)
end

function PlayerAuraService.Status(player: Player): { [string]: any }
	local data = PlayerDataService.GetData(player)
	if not data then
		return { loaded = false }
	end
	local owned, equipped = state(data)
	local nextTier = PlayerAuraConfig.List[owned + 1]
	return {
		loaded = true,
		owned = owned,
		equipped = equipped,
		ownedId = if owned > 0 then PlayerAuraConfig.List[owned].Id else nil,
		equippedId = if equipped > 0 then PlayerAuraConfig.List[equipped].Id else nil,
		multiplier = Formulas:playerAuraMultiplier(data),
		walkSpeed = Formulas:walkSpeed(data),
		nextId = if nextTier then nextTier.Id else nil,
		nextPrice = if nextTier then nextTier.Price else nil,
		money = data.Money,
		lifetime = data.LifetimeMoneyGenerated,
	}
end

-- Compra (permanente, sequencial). Replay/duplo clique: o 2º pedido do MESMO tier é recusado
-- (já possui) e nunca cobra de novo.
function PlayerAuraService.Buy(player: Player, tier: number): { [string]: any }
	local data = PlayerDataService.GetData(player)
	if not data then
		Net.fail(Net.Codes.NotReady)
	end
	assert(data)
	local config = PlayerAuraConfig.List[tier]
	if type(tier) ~= "number" or tier ~= math.floor(tier) or not config then
		Net.fail("aura_invalid")
	end
	if busy[player] then
		Net.fail("aura_busy")
	end
	local owned = Formulas:playerAuraTier(data)
	if tier <= owned then
		Net.fail("aura_owned")
	end
	if tier ~= owned + 1 then
		Net.fail("aura_order")
	end
	busy[player] = true
	-- sem yield entre conferir e debitar/gravar: duas compras simultâneas não passam juntas
	if not EconomyService.TrySpend(player, config.Price) then
		busy[player] = nil
		Net.fail("not_enough_money")
	end
	PlayerDataService.Set(player, "PlayerAura", { Owned = tier, Equipped = tier })
	busy[player] = nil
	PlayerAuraService.Apply(player)
	AnalyticsService.Track(player, "PlayerAuraPurchased", { tier = tier, id = config.Id })
	log:info(`{player.Name} comprou a Player Aura {config.Id}`)
	-- compra cara: salva já (não espera o autosave)
	task.spawn(PlayerDataService.SaveNow, player)
	return PlayerAuraService.Status(player)
end

-- Visual (cosmético): 0 = nenhum; até o maior comprado. Não muda multiplicador nem velocidade.
function PlayerAuraService.Equip(player: Player, tier: number): { [string]: any }
	local data = PlayerDataService.GetData(player)
	if not data then
		Net.fail(Net.Codes.NotReady)
	end
	assert(data)
	local owned = Formulas:playerAuraTier(data)
	if type(tier) ~= "number" or tier ~= math.floor(tier) or tier < 0 or tier > owned then
		Net.fail("aura_not_owned")
	end
	PlayerDataService.Set(player, "PlayerAura", { Owned = owned, Equipped = tier })
	PlayerAuraService.Apply(player)
	return PlayerAuraService.Status(player)
end

function PlayerAuraService.Init()
	Net.handle("BuyPlayerAura", PlayerAuraService.Buy)
	Net.handle("EquipPlayerAura", PlayerAuraService.Equip)
end

function PlayerAuraService.Start()
	PlayerDataService.Loaded:Connect(PlayerAuraService.Apply)
	for _, player in Players:GetPlayers() do
		if PlayerDataService.IsLoaded(player) then
			PlayerAuraService.Apply(player)
		end
	end
	Players.PlayerRemoving:Connect(function(player)
		busy[player] = nil
	end)
end

return PlayerAuraService
