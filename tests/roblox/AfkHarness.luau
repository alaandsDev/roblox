--[[
	AFK Resilience (Lune), com os Services REAIS, DataStore em memória (JSON) e TEMPO VIRTUAL:
	  A) AFK + AUTO: cadência exata (1 roll/s; Roll Rápido 0,5 s), sem rajada, sem fila, sem
	     crédito acumulado depois de uma pausa longa; AFK não muda Luck/renda/intervalo.
	  B) Saves: AFK continua salvando no autosave; nada de save por roll; LastLogout = momento do save.
	  C) Sair/voltar (reconexão): nada duplica (roll, personagem, dinheiro); AUTO só volta numa
	     RECONEXÃO pronta (save+base+personagem+serviços) e uma vez; entrada normal começa sem AUTO.
	  D) Offline não paga período já produzido online (AFK conectado -> sair -> voltar).
	  E) Trava do servidor antigo: a entrada espera (sem expulsar) e nunca assume a trava cedo.
	  F) Saída idempotente (PlayerRemoving + BindToClose juntos = 1 save).
	  G) Hero Landing/reveal só apresenta: o resultado já está no servidor (sem pedido de recompensa).
	  H) DEV: AFKStatus, SimulateIdle (sem input), SimulateActive, SimulateReconnect, ReconnectPlan.
]]

local process = require("@lune/process")
local task = require("@lune/task")
local serde = require("@lune/serde")
local fs = require("@lune/fs")
local Env = require("./Env")

local env = Env.create()
local T = Env.checker("AFK Resilience: cadência, saves, reconexão, offline, DEV")
local check = T.check

-- DataStore em memória (JSON de verdade) com contador de escritas e atraso opcional
local store, writes = {}, {}
local storeDelay = 0
env.gameProxy.GameId = 4242
env.stubs.DataStoreService = {
	GetDataStore = function()
		return {
			UpdateAsync = function(_, key, transform)
				if storeDelay > 0 then
					task.wait(storeDelay)
				end
				local old = if store[key] then serde.decode("json", store[key]) else nil
				local new = transform(old)
				if new ~= nil then
					store[key] = serde.encode("json", new)
					writes[key] = (writes[key] or 0) + 1
				end
				return new
			end,
		}
	end,
	GetOrderedDataStore = function()
		return {}
	end,
}
local bindToClose = {}
env.gameProxy.BindToClose = function(_, fn)
	table.insert(bindToClose, fn)
end

local handlers = {}
local firedTo = {} -- [evento] = { player, ... }
local runtimeErrors = {}
local NetStub = {
	Codes = { RateLimited = "rate_limited", InvalidArgs = "invalid_args", NotReady = "not_ready", NotImplemented = "not_implemented", Internal = "internal" },
	handle = function(name, fn)
		handlers[name] = fn
	end,
	fire = function(name, player)
		firedTo[name] = firedTo[name] or {}
		table.insert(firedTo[name], player)
	end,
	fireAll = function() end,
	fail = function(code)
		error({ code = code }, 0)
	end,
	initServer = function() end,
}
local overrides = { [env.shared.Modules.Net:GetFullName()] = NetStub }
local req = env.newContext(overrides)
local Services = env.server.Services

local ORDER = {
	"PlayerDataService", "MonetizationService", "MapService", "BaseService", "AnalyticsService",
	"EconomyService", "InventoryService", "IndexService", "SellService", "RollService",
	"DiceService", "UpgradeService", "StationService", "DailyService", "TowerService",
	"RebirthService", "FusionService", "TradeService", "MissionService",
	"BoostService", "JackpotService", "LeaderboardService", "AfkService", "DevService",
}
local S = {}
for _, name in ORDER do
	S[name] = req(Services[name])
end

-- Relógios VIRTUAIS (controlados pelo teste)
local now = 1_800_000_000 -- relógio de parede (os.time)
local clock = 1000 -- relógio monotônico (os.clock)
S.RollService._clock = function()
	return clock
end
S.TowerService._clock = function()
	return clock
end
S.AfkService._clock = function()
	return clock
end
S.AfkService._time = function()
	return now
end
S.PlayerDataService._time = function()
	return now
end
for _, name in { "EconomyService", "DailyService", "MissionService" } do
	S[name]._now = function()
		return now
	end
end
-- rolls nunca passam de Raro aqui (um Mítico+ pede SaveSoon e mudaria a contagem de saves)
local seed = 4242
S.RollService._rand = function()
	seed = (seed * 48271) % 2147483647
	return (seed / 2147483647) * 0.9
end

for _, name in ORDER do
	if S[name].Init then
		S[name].Init()
	end
end
for _, name in ORDER do
	if S[name].Start then
		task.spawn(S[name].Start)
	end
end

local Formulas = req(env.shared.Modules.GameFormulas)
local DataConfig = req(env.shared.Config.DataConfig)
local AfkConfig = req(env.shared.Config.AfkConfig)
local OfflineIncomeConfig = req(env.shared.Config.OfflineIncomeConfig)
local OfflineCore = req(env.shared.Modules.OfflineCore)
local RollConfig = req(env.shared.Config.RollConfig)
local Dev = S.DevService

local function call(name, player, ...)
	local fn = handlers[name]
	if not fn then
		return false, "sem handler " .. name
	end
	local ok, result = pcall(fn, player, ...)
	if ok then
		return true, result
	end
	if type(result) == "table" then
		return false, result.code
	end
	table.insert(runtimeErrors, name .. ": " .. tostring(result))
	return false, tostring(result)
end

local function count(map)
	local n = 0
	for _ in map or {} do
		n += 1
	end
	return n
end

local function firedCount(name, player)
	local n = 0
	for _, p in firedTo[name] or {} do
		if p == player then
			n += 1
		end
	end
	return n
end

local function newPlayer(name, userId, teleportData)
	local player = env.newPlayer(name)
	if userId then
		player.UserId = userId
	end
	function player:GetJoinData()
		return { TeleportData = teleportData }
	end
	return player
end

local function join(name, userId, teleportData)
	local player = newPlayer(name, userId, teleportData)
	env.join(player)
	local ok = Env.waitFor(function()
		return S.PlayerDataService.IsLoaded(player) and player:GetAttribute("BaseId") ~= nil
	end, 5)
	return player, ok
end

local function leave(player)
	env.leave(player)
	return Env.waitFor(function()
		return S.PlayerDataService.GetData(player) == nil and player:GetAttribute("BaseId") == nil
	end, 5)
end

local function wipeInventory(data)
	for uid in data.Inventory do
		local equipped = false
		for _, e in data.EquippedCharacters do
			if e == uid then
				equipped = true
			end
		end
		if not equipped then
			data.Inventory[uid] = nil
		end
	end
end

-- Cliente AUTO "ganancioso" (pior caso): tenta a cada 50 ms (como o autoLoop), sem respeitar
-- nada do lado do cliente. O servidor é quem garante a cadência. Devolve os instantes aceitos.
local function greedyAuto(player, data, seconds)
	local accepted = {}
	local start = clock
	local steps = math.floor(seconds * 20 + 0.5)
	for i = 0, steps do
		clock = start + i / 20
		if i % 200 == 0 then
			wipeInventory(data) -- inventário nunca enche (o teste é de cadência)
		end
		local ok = call("RequestRoll", player)
		if ok then
			table.insert(accepted, clock)
		end
	end
	return accepted
end

local function minGap(list)
	local gap = math.huge
	for i = 2, #list do
		gap = math.min(gap, list[i] - list[i - 1])
	end
	return gap
end

local function section(name, fn)
	local ok, err = pcall(fn)
	if not ok then
		check(false, name .. " quebrou: " .. tostring(err))
	end
end

------------------------------------------------------------------------------------
local p1, okJoin = join("afk_one", 5001)
check(okJoin, "jogador entra (DataStore em memória)")
local d1 = S.PlayerDataService.GetData(p1)
check(Env.waitFor(function()
	return type(d1.Runtime) == "table" and d1.Runtime.Income ~= nil
end, 3), "BoostService calculou o runtime da sessão")

section("A) AFK + AUTO: cadência", function()
	check(not (call("RequestRoll", newPlayer("ghost", 5999))), "nunca rola antes do PlayerData carregar (not_ready)")

	local luck0, cd0, ips0 = Formulas:luck(d1, now), Formulas:rollCooldown(d1), Formulas:incomePerSecond(d1)
	S.AfkService.SimulateIdle(p1, 1200)
	check(S.AfkService.State(p1) == "Idle" and p1:GetAttribute("AfkState") == "Idle", "SimulateIdle(1200): estado Idle (atributo replicado para a UI)")
	check(Formulas:luck(d1, now) == luck0 and Formulas:rollCooldown(d1) == cd0 and Formulas:incomePerSecond(d1) == ips0, "AFK não muda Luck, intervalo de roll nem renda/s (não é buff nem penalidade)")
	check(cd0 == RollConfig.RollSpeed.BaseInterval, "intervalo normal = 1,0 s")

	local pity0 = table.clone(d1.Pity)
	local rolls0 = d1.Rolls
	clock += 10
	local accepted = greedyAuto(p1, d1, 1200) -- 20 min AFK com AUTO
	check(#accepted == 1201, "AFK 20 min + AUTO: exatamente 1 roll/s (" .. #accepted .. " em 1200 s, esperado 1201)")
	check(math.abs(minGap(accepted) - 1.0) < 1e-6, string.format("nenhum par de rolls com menos de 1,0 s (menor intervalo %.3f s): sem rajada", minGap(accepted)))
	check(d1.Rolls == rolls0 + #accepted, "cada roll aceito conta uma vez (Rolls)")
	check(S.AfkService.State(p1) == "Idle", "rolls do AUTO NÃO contam como atividade (continua Idle)")
	local _ = pity0

	-- pausa longa (cliente parado: reveal, janela minimizada...) e volta: nenhum roll "devido"
	clock += 300
	local after = greedyAuto(p1, d1, 0.95)
	check(#after == 1, "depois de 5 min sem pedir, a volta aceita 1 roll no 1º segundo (sem catch-up/crédito)")

	-- Roll Rápido: exatamente 0,5 s
	d1.Runtime.FastRoll = true
	check(Formulas:rollCooldown(d1) == RollConfig.RollSpeed.FastRollInterval, "Roll Rápido = 0,5 s")
	clock += 5
	local fast = greedyAuto(p1, d1, 60)
	check(#fast == 121, "AFK + Roll Rápido: exatamente 2 rolls/s (" .. #fast .. " em 60 s, esperado 121)")
	check(math.abs(minGap(fast) - 0.5) < 1e-6, string.format("Roll Rápido: menor intervalo %.3f s (nunca < 0,5)", minGap(fast)))
	d1.Runtime.FastRoll = false

	-- spam do cliente não vira fila: pedidos recusados não ficam guardados
	clock += 5
	local burst = 0
	for _ = 1, 50 do
		if call("RequestRoll", p1) then
			burst += 1
		end
	end
	check(burst == 1, "50 pedidos no mesmo instante = 1 roll (nenhuma fila infinita)")
end)

section("B) Saves durante AFK", function()
	local key = DataConfig.KeyPrefix .. p1.UserId
	local w0 = writes[key] or 0
	local stats0 = S.PlayerDataService.SaveStats(p1).count
	local rolls0 = d1.Rolls
	-- 20 min virtuais: rolls a 1/s e uma rodada de autosave a cada AutosaveInterval
	for minute = 1, 20 do
		greedyAuto(p1, d1, 59.95)
		clock += 0.05
		now += 60
		if (minute * 60) % DataConfig.AutosaveInterval == 0 then
			S.PlayerDataService._autosaveRound(0)
		end
	end
	local rounds = 1200 // DataConfig.AutosaveInterval
	local w = (writes[key] or 0) - w0
	check(d1.Rolls - rolls0 >= 1190, "AFK: o AUTO seguiu rolando (" .. (d1.Rolls - rolls0) .. " rolls)")
	check(w == rounds, string.format("AFK 20 min: %d gravações no DataStore (= %d rodadas de autosave), nunca uma por roll", w, rounds))
	check(S.PlayerDataService.SaveStats(p1).count - stats0 == rounds and S.PlayerDataService.SaveStats(p1).lastOk == true, "SaveStats conta os saves da sessão (DEV AFKStatus)")
	local saved = serde.decode("json", store[key])
	check(saved.Data.LastLogout == now, "todo save grava LastLogout = agora (offline começa no último estado salvo)")
	check(saved.Data.Rolls == d1.Rolls and count(saved.Data.Inventory) == count(d1.Inventory), "save AFK guarda Rolls e inventário atuais")
end)

local equippedIncome = 0
section("C/D) Sair -> voltar: nada duplica; offline não paga o período online", function()
	-- renda real: equipa os melhores e deixa o Tick atualizar a renda conhecida
	clock += 2
	for _ = 1, 8 do
		clock += 1
		call("RequestRoll", p1)
	end
	call("EquipBest", p1)
	S.EconomyService.Tick(1)
	equippedIncome = d1.LastKnownIncomePerSecond
	check(equippedIncome > 0, "base com renda (" .. tostring(equippedIncome) .. "/s)")

	-- AUTO ligado pelo JOGADOR (preferência salva)
	call("SetSetting", p1, "AutoRoll", true)
	check(d1.Settings.AutoRoll == true, "AUTO ligado vira preferência (Settings.AutoRoll)")

	-- AFK conectado por 20 min (autosaves), depois cai
	for _ = 1, 10 do
		now += 120
		S.PlayerDataService._autosaveRound(0)
	end
	local leftAt = now
	local before = {
		Money = d1.Money,
		Rolls = d1.Rolls,
		NextUid = d1.NextUid,
		Inventory = count(d1.Inventory),
		Pending = d1.PendingOfflineReward,
		Index = count(d1.Index),
		Rebirths = d1.Rebirths,
		HideRollAnimation = d1.Settings.HideRollAnimation,
	}
	local key = DataConfig.KeyPrefix .. p1.UserId
	local wBefore = writes[key] or 0
	check(leave(p1), "saiu: perfil salvo e liberado")
	check((writes[key] or 0) - wBefore == 1, "saída = exatamente 1 gravação")

	-- volta 10 min depois por RECONEXÃO (TeleportData do cliente)
	now += 600
	local back, okBack = join("afk_one", 5001, { Reconnect = true, Chain = 1, FromJobId = "job-old", At = now - 5 })
	check(okBack, "voltou (reconexão) e carregou o save")
	local d = S.PlayerDataService.GetData(back)
	check(d.Money == before.Money and d.Rolls == before.Rolls and d.NextUid == before.NextUid and count(d.Inventory) == before.Inventory and count(d.Index) == before.Index and d.Rebirths == before.Rebirths, "reconexão: Money, Rolls, inventário, Index, Rebirth e NextUid iguais (nenhum roll/personagem/dinheiro duplicado)")
	check(d.Settings.HideRollAnimation == before.HideRollAnimation, "preferência Ocultar mantida")
	local expected = OfflineCore.compute(leftAt, now, equippedIncome, OfflineIncomeConfig)
	local cap = math.floor(equippedIncome * OfflineIncomeConfig.MaxSeconds * OfflineIncomeConfig.Multiplier)
	expected = math.min(before.Pending + expected, math.max(cap, expected), S.EconomyService.OfflineRebirthCap(d))
	check(d.PendingOfflineReward == expected, string.format("offline = só os 600 s fora do jogo (%s; esperado %s), não os 20 min AFK online", tostring(d.PendingOfflineReward), tostring(expected)))
	local wrong = OfflineCore.compute(leftAt - 1200, now, equippedIncome, OfflineIncomeConfig)
	check(wrong > expected or expected == 0, "(controle) contar o AFK online daria mais — não aconteceu")

	-- AUTO: espera save + base + personagem + serviços; dispara UMA vez
	S.AfkService._tick()
	check(firedCount("ResumeAuto", back) == 0, "AUTO não volta sem o personagem carregado")
	check(S.AfkService.Status(back).session.resume == "Pending", "AUTO pendente (reconexão recente + preferência salva)")
	back.Character = { Name = "afk_one" }
	S.AfkService._tick()
	S.AfkService._tick()
	check(firedCount("ResumeAuto", back) == 1, "com tudo pronto o servidor manda ResumeAuto exatamente 1 vez")
	check(S.TowerService.SessionOf(back) == nil, "Torre: nenhuma retomada automática no meio de batalha")

	-- entrada NORMAL: AUTO começa desligado (preferência transitória limpa)
	check(leave(back), "saiu de novo")
	now += 30
	local normal = join("afk_one", 5001, nil)
	normal.Character = {}
	S.AfkService._tick()
	local dn = S.PlayerDataService.GetData(normal)
	check(dn.Settings.AutoRoll == false and firedCount("ResumeAuto", normal) == 0, "entrada normal: AUTO desligado e nenhum ResumeAuto")
	check(dn.Money == before.Money and dn.Rolls == before.Rolls and dn.NextUid == before.NextUid, "segunda volta: nada duplicou")

	-- reconexão ANTIGA (fora da janela): não religa
	call("SetSetting", normal, "AutoRoll", true)
	check(leave(normal), "saiu com AUTO ligado")
	now += AfkConfig.ResumeAutoWindow + 60
	local late = join("afk_one", 5001, { Reconnect = true, Chain = 1, At = now - 5 })
	late.Character = {}
	S.AfkService._tick()
	check(firedCount("ResumeAuto", late) == 0 and S.PlayerDataService.GetData(late).Settings.AutoRoll == false, "reconexão muito depois da saída: AUTO não volta")
	p1 = late
	d1 = S.PlayerDataService.GetData(late)
end)

section("E) Trava do servidor antigo na reconexão", function()
	local savedDelay, savedWait = DataConfig.LockedRetryDelay, DataConfig.LockedJoinWait
	DataConfig.LockedRetryDelay = 0.1
	S.PlayerDataService._wait = function(s)
		task.wait(s)
	end
	-- perfil ainda travado por OUTRO servidor (que está salvando a saída)
	local key = DataConfig.KeyPrefix .. "6001"
	store[key] = serde.encode("json", { Data = { Version = DataConfig.SchemaVersion, Money = 77, Rolls = 5 }, Meta = { SessionLock = { JobId = "old-server", LockedAt = os.time() } } })
	task.delay(0.35, function()
		local rec = serde.decode("json", store[key])
		rec.Meta.SessionLock = nil
		store[key] = serde.encode("json", rec)
	end)
	local p, ok = join("relock", 6001)
	check(ok and p.kicked == nil, "entrada espera o servidor antigo liberar a trava (sem expulsar)")
	local info = S.PlayerDataService.SessionInfo(p)
	check(info ~= nil and info.waitedForLock > 0 and S.PlayerDataService.GetData(p).Money == 77, "carregou o save que o servidor antigo liberou")
	check(firedCount("Notify", p) >= 1, "jogador avisado enquanto espera")
	leave(p)

	-- trava que não sai dentro da espera: expulsa com a mensagem de sempre (nunca assume cedo)
	DataConfig.LockedJoinWait = 0.3
	local key2 = DataConfig.KeyPrefix .. "6002"
	store[key2] = serde.encode("json", { Data = { Version = DataConfig.SchemaVersion, Money = 5 }, Meta = { SessionLock = { JobId = "old-server", LockedAt = os.time() } } })
	local stuck = newPlayer("stuck", 6002)
	env.join(stuck)
	check(Env.waitFor(function()
		return stuck.kicked ~= nil
	end, 3), "trava presa: expulsa com aviso depois da espera (não assume a trava antes do timeout)")
	check(serde.decode("json", store[key2]).Meta.SessionLock.JobId == "old-server", "a trava do outro servidor continua intacta")
	env.leave(stuck)
	DataConfig.LockedRetryDelay, DataConfig.LockedJoinWait = savedDelay, savedWait
end)

section("G) Hero Landing / reveal: só apresentação", function()
	for _, path in { "src/client/Effects/HeroLanding.luau", "src/client/Effects/JackpotReveal.luau", "src/client/Controllers/RevealController.luau" } do
		local text = fs.readFile(path)
		check(string.find(text, "Net.request", 1, true) == nil, path .. ": nenhum pedido ao servidor (a apresentação nunca dá prêmio)")
	end
	clock += 5
	wipeInventory(d1)
	local rolls, nextUid = d1.Rolls, d1.NextUid
	local ok, result = call("RequestRoll", p1)
	check(ok and d1.Rolls == rolls + 1 and (result.AutoSold or d1.Inventory[result.Uid] ~= nil), "o resultado já está no servidor quando o roll responde (perder a apresentação não perde o prêmio)")
	check(d1.NextUid >= nextUid, "uid nunca volta")
end)

section("H) DEV", function()
	local text = Dev.Run("AFKStatus", p1)
	for _, field in { "estado:", "inativo há", "Auto Roll", "Roll Rápido", "Ocultar", "último save", "JobId", "sessão" } do
		check(type(text) == "string" and string.find(text, field, 1, true) ~= nil, "AFKStatus mostra " .. field)
	end
	local reports0 = 0
	local idle = Dev.Run("SimulateIdle", p1, 1200)
	check(string.find(idle, "Idle", 1, true) ~= nil and string.find(idle, "1200 s", 1, true) ~= nil, "SimulateIdle(1200): Idle, inativo há 1200 s")
	check(reports0 == 0 and S.AfkService.State(p1) == "Idle", "SimulateIdle não gera input nem atividade")
	local active = Dev.Run("SimulateActive", p1)
	check(string.find(active, "Active", 1, true) ~= nil, "SimulateActive volta a Active")
	p1.Character = p1.Character or {}
	local before = firedCount("ResumeAuto", p1)
	local simText = Dev.Run("SimulateReconnect", p1, true)
	if firedCount("ResumeAuto", p1) ~= before + 1 then
		print(simText)
	end
	check(firedCount("ResumeAuto", p1) == before + 1, "SimulateReconnect: AUTO religa pelo mesmo caminho da reconexão real")
	check(string.find(Dev.Run("ReconnectPlan", "DisconnectIdle"), "Never", 1, true) ~= nil, "ReconnectPlan: inatividade da plataforma = Never")
	check(string.find(Dev.Run("ReconnectPlan", "DisconnectConnectionLost"), "SameServer", 1, true) ~= nil, "ReconnectPlan: queda de rede tenta o mesmo servidor 1º")
	local counts = S.AnalyticsService.Counts()
	check((counts.AfkIdle or 0) >= 1 and (counts.AfkActive or 0) >= 1 and (counts.Reconnected or 0) >= 1 and (counts.AutoResumed or 0) >= 1, "telemetria: AfkIdle/AfkActive/Reconnected/AutoResumed")
	local ok = call("ReportActivity", p1)
	check(ok and S.AfkService.State(p1) == "Active", "ReportActivity (input real do cliente) marca atividade")
end)

section("F) Saída idempotente (PlayerRemoving + BindToClose; por último: desliga o servidor)", function()
	local p, ok = join("closing", 7001)
	check(ok, "jogador para o desligamento")
	local key = DataConfig.KeyPrefix .. "7001"
	local w0 = writes[key] or 0
	storeDelay = 0.1 -- o save demora: os dois caminhos se cruzam de verdade
	local done = false
	task.spawn(function()
		for _, fn in bindToClose do
			fn()
		end
		done = true
	end)
	env.leave(p)
	check(Env.waitFor(function()
		return done and S.PlayerDataService.GetData(p) == nil
	end, 5), "BindToClose terminou")
	storeDelay = 0
	check((writes[key] or 0) - w0 == 1, "PlayerRemoving + BindToClose juntos = 1 gravação (sem save duplicado)")
end)

section("AFK não é buff (estático)", function()
	-- nenhuma fórmula/serviço de jogo lê o estado AFK
	local allowed = {
		["src/server/Services/AfkService.luau"] = true,
		["src/server/Services/DevService.luau"] = true,
		["src/client/Controllers/SessionController.luau"] = true,
		["src/shared/Modules/AfkCore.luau"] = true,
		["src/server/Bootstrap.server.luau"] = true, -- só a lista de Services
	}
	local offenders = {}
	local function scan(dir)
		for _, entry in fs.readDir(dir) do
			local full = dir .. "/" .. entry
			if fs.isDir(full) then
				scan(full)
			elseif string.sub(entry, -5) == ".luau" and not allowed[full] then
				local text = fs.readFile(full)
				if string.find(text, "AfkState", 1, true) or string.find(text, "AfkService", 1, true) or string.find(text, "AfkCore", 1, true) then
					table.insert(offenders, full)
				end
			end
		end
	end
	scan("src")
	check(#offenders == 0, "nenhum outro módulo lê o estado AFK" .. (if #offenders > 0 then ": " .. table.concat(offenders, ", ") else ""))
	local forbidden = { "VirtualUser", "VirtualInputManager", "CoreGui", "SendKeyEvent", "SendMouse", "CaptureController", "ClickButton" }
	local hits = {}
	local function scanForbidden(dir)
		for _, entry in fs.readDir(dir) do
			local full = dir .. "/" .. entry
			if fs.isDir(full) then
				scanForbidden(full)
			elseif string.sub(entry, -5) == ".luau" then
				local text = fs.readFile(full)
				for _, word in forbidden do
					if string.find(text, word, 1, true) then
						table.insert(hits, full .. ":" .. word)
					end
				end
			end
		end
	end
	scanForbidden("src")
	check(#hits == 0, "nenhum VirtualUser/input falso/CoreGui no código" .. (if #hits > 0 then ": " .. table.concat(hits, ", ") else ""))
end)

check(#runtimeErrors == 0, "nenhum erro de execução nos handlers (" .. #runtimeErrors .. ")" .. (if #runtimeErrors > 0 then ": " .. runtimeErrors[1] else ""))
check(#Env.errors == 0, "nenhum erro em threads do servidor (" .. #Env.errors .. ")" .. (if #Env.errors > 0 then ": " .. tostring(Env.errors[1]) else ""))

local failures = T.finish()
process.exit(if failures == 0 then 0 else 1)
