--!strict
--[[
	TradeService (Fase 8): trocas entre jogadores do MESMO servidor.
	    RequestTrade(userId) -> convite (evento TradeRequest para o outro)
	    RespondTrade(userId, aceitar) -> abre a sessão
	    SetTradeOffer({ uid }) -> até MaxItems; mudar a oferta tira o PRONTO dos dois
	    SetTradeReady(bool) -> os dois PRONTOS habilitam CONFIRMAR
	    ConfirmTrade() -> os dois confirmam a MESMA versão da oferta -> troca atômica (TradeCore)
	    CancelTrade() / sair do jogo -> encerra
	Segurança: tudo validado de novo no momento da troca (dono, proteção, capacidade); os dois
	perfis estão travados neste servidor (sessão do DataStore), então não há duplicação.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Formulas = require(Shared.Modules.GameFormulas)
local Net = require(Shared.Modules.Net)

local Core = script.Parent.Parent.Core
local TradeCore = require(Core.TradeCore)
local InventoryCore = require(Core.InventoryCore)
local PlayerDataService = require(script.Parent.PlayerDataService)
local InventoryService = require(script.Parent.InventoryService)
local IndexService = require(script.Parent.IndexService)
local MapService = require(script.Parent.MapService)
local AnalyticsService = require(script.Parent.AnalyticsService)

local TradeService = {}

TradeService.MaxItems = 8
local REQUEST_TTL = 30

type Session = {
	a: Player,
	b: Player,
	offers: { [Player]: { string } },
	ready: { [Player]: boolean },
	confirmed: { [Player]: number },
	version: number,
}

local sessions: { [Player]: Session } = {}
local invites: { [Player]: { [Player]: number } } = {} -- convidado -> { quem convidou = expira }

local function other(session: Session, player: Player): Player
	return if session.a == player then session.b else session.a
end

local function publicItems(data: any, uids: { string }): { any }
	local out = {}
	for _, uid in uids do
		local item = data and data.Inventory[uid]
		if item then
			table.insert(out, { uid = uid, id = item.Id, level = item.Level, variant = item.Variant })
		end
	end
	return out
end

local function broadcast(session: Session)
	for _, player in { session.a, session.b } do
		local partner = other(session, player)
		Net.fire("TradeUpdate", player, {
			partnerId = partner.UserId,
			partnerName = partner.DisplayName,
			version = session.version,
			mine = publicItems(PlayerDataService.GetData(player), session.offers[player]),
			theirs = publicItems(PlayerDataService.GetData(partner), session.offers[partner]),
			myReady = session.ready[player] == true,
			theirReady = session.ready[partner] == true,
			myConfirmed = session.confirmed[player] == session.version,
			theirConfirmed = session.confirmed[partner] == session.version,
		})
	end
end

local function close(session: Session, reason: string)
	for _, player in { session.a, session.b } do
		if sessions[player] == session then
			sessions[player] = nil
			Net.fire("TradeClosed", player, reason)
		end
	end
end

function TradeService.SessionOf(player: Player): Session?
	return sessions[player]
end

function TradeService.Request(player: Player, userId: number)
	local target = Players:GetPlayerByUserId(userId)
	if not target or target == player then
		Net.fail("trade_no_player")
	end
	assert(target)
	if sessions[player] or sessions[target] then
		Net.fail("trade_busy")
	end
	invites[target] = invites[target] or {}
	invites[target][player] = os.clock() + REQUEST_TTL
	Net.fire("TradeRequest", target, player.UserId, player.DisplayName)
	return true
end

function TradeService.Respond(player: Player, userId: number, accept: boolean)
	local from = Players:GetPlayerByUserId(userId)
	local pending = invites[player]
	local expires = from and pending and pending[from]
	if not from or not expires or expires < os.clock() then
		Net.fail("trade_no_request")
	end
	assert(from and pending)
	pending[from] = nil
	if not accept then
		Net.fire("Notify", from, "trade.declined", { name = player.DisplayName })
		return false
	end
	if sessions[player] or sessions[from] then
		Net.fail("trade_busy")
	end
	local session: Session = { a = from, b = player, offers = { [from] = {}, [player] = {} }, ready = {}, confirmed = {}, version = 1 }
	sessions[from] = session
	sessions[player] = session
	broadcast(session)
	return true
end

local function sessionOf(player: Player): Session
	local session = sessions[player]
	if not session then
		Net.fail("trade_no_session")
	end
	return session :: Session
end

function TradeService.SetOffer(player: Player, uids: { string })
	local session = sessionOf(player)
	local data = PlayerDataService.GetData(player)
	local err = TradeCore.validateOffer(data, uids, TradeService.MaxItems, InventoryCore)
	if err then
		Net.fail(err)
	end
	session.offers[player] = table.clone(uids)
	session.version += 1
	table.clear(session.ready)
	broadcast(session)
	return session.version
end

function TradeService.SetReady(player: Player, ready: boolean)
	local session = sessionOf(player)
	session.ready[player] = ready
	broadcast(session)
	return ready
end

function TradeService.Confirm(player: Player)
	local session = sessionOf(player)
	local partner = other(session, player)
	if not (session.ready[player] and session.ready[partner]) then
		Net.fail("trade_not_ready")
	end
	session.confirmed[player] = session.version
	if session.confirmed[partner] ~= session.version then
		broadcast(session)
		return "waiting"
	end
	-- Os dois confirmaram a mesma versão: troca atômica
	local a, b = session.a, session.b
	local dataA, dataB = PlayerDataService.GetData(a), PlayerDataService.GetData(b)
	if not dataA or not dataB then
		close(session, "error")
		Net.fail(Net.Codes.NotReady)
	end
	local offerA, offerB = session.offers[a], session.offers[b]
	local ok, err, newA, newB = TradeCore.execute(dataA, dataB, offerA, offerB, Formulas:capacity(dataA), Formulas:capacity(dataB), os.time(), InventoryCore)
	if not ok then
		session.version += 1
		table.clear(session.ready)
		broadcast(session)
		Net.fail(err :: string)
	end
	assert(dataA and dataB)
	InventoryService.SendDelta(a, newA, offerA)
	InventoryService.SendDelta(b, newB, offerB)
	for _, uid in newA do
		IndexService.Register(a, dataA.Inventory[uid].Id)
	end
	for _, uid in newB do
		IndexService.Register(b, dataB.Inventory[uid].Id)
	end
	AnalyticsService.Track(a, "TradeCompleted", { given = #offerA, received = #offerB })
	AnalyticsService.Track(b, "TradeCompleted", { given = #offerB, received = #offerA })
	close(session, "completed")
	task.spawn(PlayerDataService.SaveNow, a)
	task.spawn(PlayerDataService.SaveNow, b)
	return "completed"
end

function TradeService.Cancel(player: Player)
	local session = sessions[player]
	if session then
		close(session, "cancelled")
	end
	return true
end

function TradeService.Init()
	Net.handle("RequestTrade", TradeService.Request)
	Net.handle("RespondTrade", TradeService.Respond)
	Net.handle("SetTradeOffer", TradeService.SetOffer)
	Net.handle("SetTradeReady", TradeService.SetReady)
	Net.handle("ConfirmTrade", TradeService.Confirm)
	Net.handle("CancelTrade", TradeService.Cancel)
	MapService.RegisterInteraction("Trade", function(player)
		Net.fire("OpenMenu", player, "Trade")
	end)
end

function TradeService.Start()
	Players.PlayerRemoving:Connect(function(player)
		local session = sessions[player]
		if session then
			close(session, "left")
		end
		invites[player] = nil
		for _, list in invites do
			list[player] = nil
		end
	end)
end

return TradeService
