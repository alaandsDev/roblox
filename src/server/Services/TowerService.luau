--!strict
--[[
	TowerService (Fase 7 + sessão contínua): torres de batalha de cards.
	    StartTowerSession(towerId, auto) -> sessão contínua: andar a andar no servidor
	    TowerNext()                      -> próximo andar (modo manual, depois de uma vitória)
	    SetTowerAuto(ligado)             -> AUTO: vitória -> recompensa -> próximo sozinho
	    StopTowerSession()               -> PARAR
	    RequestEnterTower(towerId)       -> luta UM andar (legado; recusado com sessão ativa)
	    SetTowerTeam({ uid }) -> time de até 5 (vazio = os 5 mais fortes automaticamente)
	Sessão (TowerSessionCore): uma por jogador; acaba em derrota, PARAR, torre completa, teto de
	estágios, desconexão ou morte do personagem. Nunca recomeça do andar 1 sozinha. Recompensa só
	na 1ª vitória de cada andar (o progresso salvo garante; a sessão é idempotente por andar).
	OCULTAR é só do cliente (apresentação): o servidor faz exatamente o mesmo.
	O servidor monta as cartas (poder = Formulas:unitPower), simula com BattleCore e uma semente
	do Random do servidor, salva o progresso e entrega a recompensa da 1ª vitória.
	O cliente recebe o registro (log) só para animar.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local TowerConfig = require(Shared.Config.TowerConfig)
local CharacterConfig = require(Shared.Config.CharacterConfig)
local RarityConfig = require(Shared.Config.RarityConfig)
local BattleCore = require(Shared.Modules.BattleCore)
local Formulas = require(Shared.Modules.GameFormulas)
local TableUtil = require(Shared.Modules.TableUtil)
local Signal = require(Shared.Modules.Signal)
local Net = require(Shared.Modules.Net)
local TowerSessionCore = require(Shared.Modules.TowerSessionCore)

local PlayerDataService = require(script.Parent.PlayerDataService)
local EconomyService = require(script.Parent.EconomyService)
local MapService = require(script.Parent.MapService)
local AnalyticsService = require(script.Parent.AnalyticsService)

local TowerService = {}

-- (player, towerId, floor, won)
TowerService.BattleFinished = Signal.new()
TowerService._clock = os.clock
local random = Random.new()
TowerService._rand = function(): number
	return random:NextNumber()
end

local core = BattleCore.new(TowerConfig, CharacterConfig, RarityConfig)
local lastBattle: { [Player]: number } = {}
local sessions: { [Player]: TowerSessionCore.Session } = {}
-- agenda o próximo estágio do AUTO (trocável nos testes)
TowerService._schedule = function(delay: number, fn: () -> ())
	task.delay(delay, fn)
end

local function dataOf(player: Player): any
	local data = PlayerDataService.GetData(player)
	if not data then
		Net.fail(Net.Codes.NotReady)
	end
	return data
end

function TowerService.Highest(data: any, towerId: string): number
	local value = data.TowerProgress[towerId]
	return if type(value) == "number" then value else 0
end

function TowerService.IsUnlocked(data: any, towerId: string): boolean
	local tower = TowerConfig.ById[towerId]
	if not tower then
		return false
	end
	local previous = tower.Unlock.Tower
	return previous == nil or TowerService.Highest(data, previous) >= TowerConfig.ById[previous].Floors
end

-- Time: os uids escolhidos que ainda existem; se nenhum, os mais fortes
function TowerService.Team(data: any): { string }
	local team = {}
	local seen = {}
	for _, uid in data.TowerTeam do
		if data.Inventory[uid] and not seen[uid] and #team < TowerConfig.TeamSize then
			seen[uid] = true
			table.insert(team, uid)
		end
	end
	if #team > 0 then
		return team
	end
	local all = {}
	for uid in data.Inventory do
		table.insert(all, uid)
	end
	table.sort(all, function(a, b)
		local pa, pb = Formulas:unitPower(data.Inventory[a], data), Formulas:unitPower(data.Inventory[b], data)
		if pa ~= pb then
			return pa > pb
		end
		return a < b
	end)
	for i = 1, math.min(TowerConfig.TeamSize, #all) do
		table.insert(team, all[i])
	end
	return team
end

function TowerService.TeamPower(data: any): number
	local total = 0
	for _, uid in TowerService.Team(data) do
		total += Formulas:unitPower(data.Inventory[uid], data)
	end
	return total
end

local function publicCards(cards: { BattleCore.Card }): { any }
	local out = {}
	for _, card in cards do
		table.insert(out, { id = card.id, power = math.floor(card.power), maxHp = math.floor(card.maxHp), atk = math.floor(card.atk) })
	end
	return out
end

-- Luta o andar `floor` da torre no SERVIDOR e entrega a recompensa da vitória (só a 1ª: o andar
-- precisa ser exatamente o próximo do progresso salvo). Devolve o pacote para o cliente animar.
local function resolveFloor(player: Player, data: any, tower: any, floor: number): any
	local uids = TowerService.Team(data)
	if #uids == 0 then
		Net.fail("no_team")
	end
	local team = {}
	for i, uid in uids do
		local item = data.Inventory[uid]
		table.insert(team, core:card(item.Id, Formulas:unitPower(item, data), "team", i))
	end
	local enemies = core:enemies(tower, floor)
	local publicTeam, publicEnemies = publicCards(team), publicCards(enemies)
	local result = core:simulate(team, enemies, TowerService._rand)

	local rewards = { money = 0, gems = 0, completed = false }
	if result.won and TowerService.Highest(data, tower.Id) + 1 == floor then
		local progress = TableUtil.deepCopy(data.TowerProgress)
		progress[tower.Id] = floor
		PlayerDataService.Set(player, "TowerProgress", progress)
		local enemyPower = core:enemyPower(tower, floor)
		rewards.money = math.floor(math.max(enemyPower * TowerConfig.MoneyPerPower, Formulas:incomePerSecond(data) * TowerConfig.IncomeSeconds))
		EconomyService.AddMoney(player, rewards.money, "Tower")
		if floor % TowerConfig.GemsEvery == 0 then
			rewards.gems += TowerConfig.GemsPerMilestone * (floor // TowerConfig.GemsEvery)
		end
		if floor == tower.Floors then
			rewards.completed = true
			rewards.gems += tower.CompletionGems
		end
		if rewards.gems > 0 then
			PlayerDataService.Increment(player, "Gems", rewards.gems)
		end
		PlayerDataService.SaveSoon(player)
	end
	local hp, maxHp = 0, 0
	for _, card in result.team do
		hp += math.max(0, card.hp)
		maxHp += card.maxHp
	end
	AnalyticsService.Track(player, if result.won then "TowerWin" else "TowerLoss", { tower = tower.Id, floor = floor })
	TowerService.BattleFinished:Fire(player, tower.Id, floor, result.won)
	return {
		tower = tower.Id,
		floor = floor,
		won = result.won,
		rounds = result.rounds,
		log = result.log,
		team = publicTeam,
		enemies = publicEnemies,
		rewards = rewards,
		teamHp = if maxHp > 0 then hp / maxHp else 0,
	}
end

local function validTower(data: any, towerId: string): any
	local tower = TowerConfig.ById[towerId]
	if not tower then
		Net.fail("invalid_tower")
	end
	if not TowerService.IsUnlocked(data, towerId) then
		Net.fail("tower_locked")
	end
	if TowerService.Highest(data, towerId) + 1 > tower.Floors then
		Net.fail("tower_complete")
	end
	return tower
end

-- Luta UM andar (fluxo antigo). Com sessão contínua ativa é recusado (uma luta por vez).
function TowerService.Enter(player: Player, towerId: string)
	local data = dataOf(player)
	if TowerSessionCore.isActive(sessions[player]) then
		Net.fail("session_active")
	end
	local tower = validTower(data, towerId)
	local now = TowerService._clock()
	if now - (lastBattle[player] or -math.huge) < TowerConfig.BattleCooldown then
		Net.fail("cooldown")
	end
	if #TowerService.Team(data) == 0 then
		Net.fail("no_team")
	end
	lastBattle[player] = now
	return resolveFloor(player, data, tower, TowerService.Highest(data, towerId) + 1)
end

------------------------------------------------------------------------------------
-- Sessão contínua

function TowerService.SessionOf(player: Player): TowerSessionCore.Session?
	local session = sessions[player]
	return if TowerSessionCore.isActive(session) then session else nil
end

local function finish(player: Player, session: TowerSessionCore.Session, reason: string)
	TowerSessionCore.stop(session, reason)
	if sessions[player] == session then
		sessions[player] = nil
	end
	if player.Parent ~= nil then
		Net.fire("TowerSessionUpdate", player, TowerSessionCore.summary(session))
	end
end

-- Um estágio: valida, luta no servidor, aplica (idempotente) e agenda o próximo se AUTO
local function runStage(player: Player, session: TowerSessionCore.Session)
	if sessions[player] ~= session or not TowerSessionCore.isActive(session) then
		return
	end
	local data = PlayerDataService.GetData(player)
	if not data or player.Parent == nil then
		finish(player, session, "invalid")
		return
	end
	local now = TowerService._clock()
	local ok, why = TowerSessionCore.canFight(session, now, TowerConfig.Session.StageInterval)
	if not ok then
		if why == "cooldown" then
			TowerService._schedule(TowerConfig.Session.StageInterval, function()
				runStage(player, session)
			end)
		elseif why ~= "not_running" then
			finish(player, session, why :: string)
		end
		return
	end
	local tower = TowerConfig.ById[session.towerId]
	-- o andar sempre vem do progresso SALVO (nunca do cliente)
	if TowerService.Highest(data, session.towerId) + 1 ~= session.nextFloor or #TowerService.Team(data) == 0 then
		finish(player, session, "invalid")
		return
	end
	lastBattle[player] = now
	local floor = session.nextFloor
	local okFight, payload = pcall(resolveFloor, player, data, tower, floor)
	if not okFight then
		finish(player, session, "invalid")
		return
	end
	TowerSessionCore.applyResult(session, floor, payload.won, payload.rewards, payload.teamHp, now)
	payload.session = TowerSessionCore.summary(session)
	Net.fire("TowerStage", player, payload)
	if not TowerSessionCore.isActive(session) then
		finish(player, session, session.endReason or "ended")
	elseif session.auto and session.status == "running" then
		TowerService._schedule(TowerConfig.Session.StageInterval, function()
			runStage(player, session)
		end)
	end
end

function TowerService.StartSession(player: Player, towerId: string, auto: boolean)
	local data = dataOf(player)
	if TowerSessionCore.isActive(sessions[player]) then
		Net.fail("session_active")
	end
	local tower = validTower(data, towerId)
	if #TowerService.Team(data) == 0 then
		Net.fail("no_team")
	end
	local session, err = TowerSessionCore.new(towerId, TowerService.Highest(data, towerId), tower.Floors, auto == true, TowerConfig.Session.MaxStagesPerSession)
	if not session then
		Net.fail(err :: string)
	end
	assert(session)
	-- respeita o intervalo desde a última luta (não dá para encadear START/PARAR para lutar mais rápido)
	session.lastStageAt = math.max(lastBattle[player] or -math.huge, -math.huge)
	sessions[player] = session
	runStage(player, session)
	return TowerSessionCore.summary(session)
end

function TowerService.Next(player: Player)
	local session = sessions[player]
	if not TowerSessionCore.isActive(session) then
		Net.fail("no_session")
	end
	assert(session)
	if not TowerSessionCore.resume(session) then
		Net.fail("not_paused")
	end
	runStage(player, session)
	return TowerSessionCore.summary(session)
end

function TowerService.SetAuto(player: Player, auto: boolean)
	local session = sessions[player]
	if not TowerSessionCore.isActive(session) then
		Net.fail("no_session")
	end
	assert(session)
	local wasPaused = session.status == "paused"
	TowerSessionCore.setAuto(session, auto)
	if wasPaused and session.status == "running" then
		runStage(player, session)
	end
	return TowerSessionCore.summary(session)
end

function TowerService.StopSession(player: Player)
	local session = sessions[player]
	if not TowerSessionCore.isActive(session) then
		Net.fail("no_session")
	end
	assert(session)
	finish(player, session, "stopped")
	return TowerSessionCore.summary(session)
end

-- Desconexão / morte: encerra sem recompensa pendente (cada estágio já foi entregue ao terminar)
function TowerService.EndFor(player: Player, reason: string)
	local session = sessions[player]
	if session then
		finish(player, session, reason)
	end
	sessions[player] = nil
end

function TowerService.SetTeam(player: Player, uids: { string })
	local data = dataOf(player)
	local team = {}
	local seen = {}
	for _, uid in uids do
		if not data.Inventory[uid] then
			Net.fail("not_owned")
		end
		if not seen[uid] then
			seen[uid] = true
			table.insert(team, uid)
		end
	end
	PlayerDataService.Set(player, "TowerTeam", team)
	return team
end

function TowerService.Init()
	Net.handle("RequestEnterTower", TowerService.Enter)
	Net.handle("StartTowerSession", TowerService.StartSession)
	Net.handle("TowerNext", TowerService.Next)
	Net.handle("SetTowerAuto", TowerService.SetAuto)
	Net.handle("StopTowerSession", TowerService.StopSession)
	Net.handle("SetTowerTeam", TowerService.SetTeam)
	MapService.RegisterInteraction("Towers", function(player)
		Net.fire("OpenMenu", player, "Towers")
	end)
end

function TowerService.Start()
	Players.PlayerRemoving:Connect(function(player)
		TowerService.EndFor(player, "disconnect")
		lastBattle[player] = nil
	end)
	local function watchDeath(player: Player, character: Model)
		local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 10)
		if humanoid and humanoid:IsA("Humanoid") then
			humanoid.Died:Connect(function()
				TowerService.EndFor(player, "died")
			end)
		end
	end
	local function track(player: Player)
		player.CharacterAdded:Connect(function(character)
			watchDeath(player, character)
		end)
		if player.Character then
			task.spawn(watchDeath, player, player.Character)
		end
	end
	Players.PlayerAdded:Connect(track)
	for _, player in Players:GetPlayers() do
		track(player)
	end
end

return TowerService
