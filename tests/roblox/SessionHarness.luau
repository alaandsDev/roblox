--[[
	Auditoria pré-Studio (Lune), com os Services REAIS e um DataStore em memória (JSON de verdade):
	  A) SMOKE: jogador novo -> roll -> equipar -> coletar -> melhorar -> dado -> renascer ->
	     andar novo -> torre -> fusão -> troca -> diário -> missão -> sair (save) -> voltar (load)
	     e conferir que TUDO voltou igual.
	  B) SESSÃO LONGA: 10 jogadores, ~4 h lógicas, milhares de ações aleatórias (inclui trocas,
	     cancelamentos, sair no meio e voltar). Invariantes conferidos o tempo todo: sem NaN,
	     sem dinheiro negativo, sem UID repetido/futuro, sem UID equipado órfão, slot válido,
	     inventário dentro da capacidade, uma base por jogador, sessões de troca coerentes.
]]

local process = require("@lune/process")
local task = require("@lune/task")
local serde = require("@lune/serde")
local Env = require("./Env")

local env = Env.create()
local T = Env.checker("Sessão: smoke do ciclo completo + sessão longa (10 jogadores)")
local check = T.check

-- DataStore em memória: cada escrita passa por JSON (pega valores que não serializam)
local store = {}
env.gameProxy.GameId = 4242
env.stubs.DataStoreService = {
	GetDataStore = function()
		return {
			UpdateAsync = function(_, key, transform)
				local old = if store[key] then serde.decode("json", store[key]) else nil
				local new = transform(old)
				if new ~= nil then
					store[key] = serde.encode("json", new)
				end
				return new
			end,
		}
	end,
	GetOrderedDataStore = function()
		return {}
	end,
}

local handlers = {}
local runtimeErrors = {}
local NetStub = {
	Codes = { RateLimited = "rate_limited", InvalidArgs = "invalid_args", NotReady = "not_ready", NotImplemented = "not_implemented", Internal = "internal" },
	handle = function(name, fn)
		handlers[name] = fn
	end,
	fire = function() end,
	fireAll = function() end,
	fail = function(code)
		error({ code = code }, 0)
	end,
	initServer = function() end,
}
local overrides = { [env.shared.Modules.Net:GetFullName()] = NetStub }
local req = env.newContext(overrides)
local Services = env.server.Services
local BulkCore = req(env.shared.Modules.BulkSaleCore)
local InvCore = req(env.server.Core.InventoryCore)

local ORDER = {
	"PlayerDataService", "MonetizationService", "MapService", "BaseService", "AnalyticsService",
	"EconomyService", "InventoryService", "IndexService", "SellService", "RollService",
	"DiceService", "UpgradeService", "StationService", "DailyService", "TowerService",
	"RebirthService", "FusionService", "TradeService", "MissionService",
	"BoostService", "JackpotService", "LeaderboardService", "AfkService",
}
local S = {}
for _, name in ORDER do
	S[name] = req(Services[name])
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
local InventoryCore = req(env.server.Core.InventoryCore)
local CharacterConfig = req(env.shared.Config.CharacterConfig)
local VariantConfig = req(env.shared.Config.VariantConfig)
local TowerConfig = req(env.shared.Config.TowerConfig)
local RebirthConfig = req(env.shared.Config.RebirthConfig)
local FusionConfig = req(env.shared.Config.FusionConfig)

-- Relógios lógicos (controlados pelo teste)
local now = 1_800_000_000
local clock = 1000
S.RollService._clock = function()
	return clock
end
S.TowerService._clock = function()
	return clock
end
for _, name in { "EconomyService", "DailyService", "MissionService" } do
	S[name]._now = function()
		return now
	end
end
math.randomseed(12345) -- determinístico
local function rand(): number
	return math.random()
end
S.RollService._rand = rand
S.TowerService._rand = rand
S.JackpotService._rand = rand

-- Chama um handler como o Net faria. Erro que não é código (bug) é registrado
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

local function join(name, userId)
	local player = env.newPlayer(name)
	if userId then
		player.UserId = userId
	end
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

local function freeUnprotected(data)
	local list = {}
	for uid in data.Inventory do
		if InventoryCore.protection(data, uid) == nil then
			table.insert(list, uid)
		end
	end
	table.sort(list)
	return list
end

------------------------------------------------------------------------------------
-- Invariantes

local function finite(v)
	return type(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge
end

local function invariants(players): { string }
	local problems = {}
	local function bad(player, text)
		table.insert(problems, player.Name .. ": " .. text)
	end
	local owners = {}
	local bases = env.real.Workspace:FindFirstChild("Bases")
	for _, base in (bases and bases:GetChildren() or {}) do
		local owner = base:GetAttribute("OwnerUserId")
		if owner and owner ~= 0 then
			if owners[owner] then
				table.insert(problems, "duas bases com o mesmo dono " .. tostring(owner))
			end
			owners[owner] = true
		end
	end
	for _, player in players do
		local d = S.PlayerDataService.GetData(player)
		if not d then
			continue
		end
		for _, key in { "Money", "Gems", "UncollectedMoney", "RebirthTokens", "PendingOfflineReward", "Rolls" } do
			if not finite(d[key]) or d[key] < 0 then
				bad(player, key .. " inválido: " .. tostring(d[key]))
			end
		end
		local maxUid = 0
		for uid, item in d.Inventory do
			local n = tonumber(string.match(uid, "^c(%d+)$"))
			if not n then
				bad(player, "uid fora do padrão " .. uid)
			else
				maxUid = math.max(maxUid, n)
			end
			if not CharacterConfig.ById[item.Id] then
				bad(player, "personagem inexistente " .. tostring(item.Id))
			end
			if not VariantConfig.ById[item.Variant or "Normal"] then
				bad(player, "variante inválida " .. tostring(item.Variant))
			end
			if not finite(item.Level) or item.Level < 1 or item.Level > 50 then
				bad(player, "nível inválido " .. tostring(item.Level))
			end
		end
		if d.NextUid <= maxUid then
			bad(player, "NextUid repetiria um uid existente")
		end
		local unlocked = S.InventoryService.UnlockedSlots(player)
		local seen = {}
		for slot, uid in d.EquippedCharacters do
			if not d.Inventory[uid] then
				bad(player, "uid equipado órfão " .. tostring(uid))
			end
			if seen[uid] then
				bad(player, "uid equipado em dois slots " .. tostring(uid))
			end
			seen[uid] = true
			if not unlocked[tonumber(slot)] then
				bad(player, "slot inválido " .. tostring(slot))
			end
		end
		if count(d.Inventory) > Formulas:capacity(d) then
			bad(player, string.format("inventário acima da capacidade (%d > %d)", count(d.Inventory), Formulas:capacity(d)))
		end
		for towerId, floor in d.TowerProgress do
			local tower = TowerConfig.ById[towerId]
			if not tower or floor > tower.Floors or floor < 0 then
				bad(player, "torre inválida " .. tostring(towerId))
			end
		end
		if d.Rebirths > RebirthConfig.MaxRebirths then
			bad(player, "renascimentos acima do máximo")
		end
		local base = S.BaseService.GetPlayerBase(player)
		if not base or base:GetAttribute("OwnerUserId") ~= player.UserId then
			bad(player, "sem base própria")
		end
		local session = S.TradeService.SessionOf(player)
		if session then
			local other = if session.a == player then session.b else session.a
			if S.TradeService.SessionOf(other) ~= session or other.Parent == nil then
				bad(player, "sessão de troca incoerente")
			end
		end
	end
	return problems
end

local function section(name, fn)
	local ok, err = pcall(fn)
	if not ok then
		check(false, name .. " quebrou: " .. tostring(err))
	end
end

------------------------------------------------------------------------------------
-- A) SMOKE DO CICLO COMPLETO
section("smoke", function()
	local p1, ok1 = join("novato")
	local p2, ok2 = join("amigo")
	check(ok1 and ok2, "smoke: dois jogadores entram (DataStore em memória)")
	local d1 = S.PlayerDataService.GetData(p1)
	check(d1.Rolls == 0 and d1.Tutorial == 0 and count(d1.Inventory) == 0, "smoke: perfil novo, tutorial no começo")

	-- ROLL
	local rolled = 0
	for _ = 1, 30 do
		clock += 10
		if (call("RequestRoll", p1)) then
			rolled += 1
		end
	end
	check(rolled == 30 and d1.Rolls == 30 and count(d1.Inventory) > 0, "smoke: 30 rolls viram personagens no inventário")
	call("SetTutorialStep", p1, 1)

	-- EQUIPAR + RENDA + COLETAR
	local placed = select(2, call("EquipBest", p1))
	check(type(placed) == "number" and placed > 0 and next(d1.EquippedCharacters) ~= nil, "smoke: EQUIPAR MELHORES coloca na base")
	S.EconomyService.Tick(120)
	-- Pisar no coletor = EconomyService.Collect (a checagem de distância está no GameplayHarness)
	local got = S.EconomyService.Collect(p1)
	check(got > 0 and d1.Money == got, "smoke: renda acumula e COLETAR dá dinheiro")

	-- MELHORAR personagem + dado + melhoria global
	d1.Money += 1e7
	local _, firstUid = next(d1.EquippedCharacters)
	local okU = call("UpgradeCharacter", p1, firstUid, 5)
	check(okU and d1.Inventory[firstUid].Level == 6, "smoke: personagem melhorado (nível 6)")
	d1.Rolls = math.max(d1.Rolls, 50)
	d1.DiceRolls = { Starter = math.max((d1.DiceRolls or {}).Starter or 0, 60) }
	check((call("BuyDice", p1, "Lucky")) and (call("EquipDice", p1, "Lucky")) and d1.EquippedDice == "Lucky", "smoke: dado da Sorte comprado e equipado")
	check((call("BuyUpgrade", p1, "Luck")) and d1.Upgrades.Luck == 1, "smoke: melhoria global de Sorte")

	-- RENASCER x5 -> andar novo (slot 9 no Floor02)
	for _ = 1, 5 do
		d1.Money = Formulas:rebirthCost(d1.Rebirths)
		call("Rebirth", p1)
	end
	local unlocked = S.InventoryService.UnlockedSlots(p1)
	check(d1.Rebirths == 5 and unlocked[9] == true, "smoke: 5 renascimentos liberam o slot 9 (2º andar)")
	local base = S.BaseService.GetPlayerBase(p1)
	local slot9 = base and base:FindFirstChild("Slot09", true)
	check(slot9 ~= nil and slot9:GetAttribute("Unlocked") == true, "smoke: slot 9 aparece liberado no mapa")
	local extra = InventoryCore.add(d1, "solar_paladin", now)
	check((call("EquipCharacter", p1, extra, 9)), "smoke: personagem equipado no andar novo")

	-- TORRE
	clock += 10
	local okT, battle = call("RequestEnterTower", p1, "Ember")
	check(okT and type(battle) == "table", "smoke: batalha na torre resolvida no servidor")

	-- FUSÃO
	d1.Money = 1e12
	local f = {}
	for i = 1, 3 do
		f[i] = S.InventoryService.Add(p1, "flame_rookie")
	end
	-- investimento gravado pelo servidor em cada cópia (como depois de UpgradeCharacter)
	for i = 1, 3 do
		d1.Inventory[f[i]].Level = 1 + i
		d1.Inventory[f[i]].UpgradeInvestment = 1000 * i
	end
	local okF, fused = call("Fuse", p1, f)
	check(okF and fused.variant == "Silver", "smoke: fusão 3 Normais -> Prata")
	check(d1.Inventory[fused.uid].UpgradeInvestment == 6000 and d1.Inventory[fused.uid].Level == 4, "smoke: fusão soma o investimento (1000+2000+3000) e fica com o maior nível")

	-- TROCA: uma SEGUNDA unidade fundida vai para o outro jogador levando o investimento
	local g = {}
	for i = 1, 3 do
		g[i] = S.InventoryService.Add(p1, "flame_rookie")
		d1.Inventory[g[i]].Level = 1 + i
		d1.Inventory[g[i]].UpgradeInvestment = 1000 * i
	end
	local okG, fusedToGive = call("Fuse", p1, g)
	check(okG, "smoke: segunda fusão (para trocar)")
	local give = fusedToGive.uid
	local d2 = S.PlayerDataService.GetData(p2)
	local take = S.InventoryService.Add(p2, "chrono_sage")
	call("RequestTrade", p1, p2.UserId)
	call("RespondTrade", p2, p1.UserId, true)
	call("SetTradeOffer", p1, { give })
	call("SetTradeOffer", p2, { take })
	call("SetTradeReady", p1, true)
	call("SetTradeReady", p2, true)
	call("ConfirmTrade", p1)
	local okTr, tr = call("ConfirmTrade", p2)
	check(okTr and tr == "completed" and d1.Inventory[give] == nil and d2.Inventory[take] == nil, "smoke: troca concluída")
	do -- upgrade -> fusão -> troca -> venda: o investimento viaja e a venda paga base + 75%
		local received
		for uid, item in d2.Inventory do
			if item.Id == "flame_rookie" and item.Variant == "Silver" then
				received = uid
			end
		end
		check(received ~= nil and d2.Inventory[received].UpgradeInvestment == 6000, "smoke: troca levou o investimento da instância")
		local okPv, pv = call("PreviewSale", p2, { received })
		local before = d2.Money
		local okS, sold = call("SellCharacter", p2, { received })
		check(
			okPv and okS and pv.items[received].Refund == 4500 and sold.total == pv.total and d2.Money == before + pv.total,
			"smoke: venda depois de fusão+troca = base + 75% do investido (prévia == recebido)"
		)
	end

	-- DIÁRIO + MISSÃO
	local okD = call("ClaimDaily", p1)
	check(okD and d1.DailyStreak >= 1, "smoke: recompensa diária resgatada")
	local missionId = next(d1.Missions.Daily or {})
	if missionId then
		d1.Missions.Daily[missionId].Progress = 1e9
	end
	local okM = missionId ~= nil and (call("ClaimMission", p1, "Daily", missionId))
	check(okM, "smoke: missão diária resgatada")

	-- VENDA EM MASSA antes do save: o que foi vendido não volta, o dinheiro fica
	local bulkA = S.InventoryService.Add(p1, "wind_disciple")
	local bulkB = S.InventoryService.Add(p1, "wind_disciple")
	local okBulkPv, bulkPv = call("PreviewBulkSale", p1, { bulkA, bulkB })
	local okBulk, bulkRes = call("SellBulk", p1, { bulkA, bulkB }, okBulkPv and bulkPv.total or nil, "smoke-bulk")
	check(okBulk and bulkRes.count == 2 and d1.Inventory[bulkA] == nil and d1.Inventory[bulkB] == nil, "smoke: venda em massa (2) com a prévia do servidor")

	-- SAIR (save) -> VOLTAR (load)
	local snapshot = {
		Money = d1.Money, Gems = d1.Gems, Rolls = d1.Rolls, Rebirths = d1.Rebirths,
		-- 50+ rolls ao voltar = veterano: o tutorial é marcado como terminado
		Tutorial = 7,
		Inventory = count(d1.Inventory), Equipped = count(d1.EquippedCharacters), Index = count(d1.Index),
		Dice = d1.EquippedDice, Ember = d1.TowerProgress.Ember, Streak = d1.DailyStreak, NextUid = d1.NextUid,
		Level = d1.Inventory[firstUid].Level, Fused = d1.Inventory[fused.uid] and d1.Inventory[fused.uid].Variant,
	}
	local userId = p1.UserId
	check(leave(p1), "smoke: saiu e o perfil foi salvo/liberado")
	local raw = store["Player_" .. userId]
	check(raw ~= nil and #raw < 200_000, "smoke: save gravado em JSON (" .. tostring(raw and #raw) .. " bytes)")
	local back, okBack = join("novato", userId)
	check(okBack, "smoke: voltou e carregou o perfil salvo")
	local r = S.PlayerDataService.GetData(back)
	local same = r ~= nil and r.Money == snapshot.Money and r.Gems == snapshot.Gems and r.Rolls == snapshot.Rolls
		and r.Rebirths == snapshot.Rebirths and r.Tutorial == snapshot.Tutorial and count(r.Inventory) == snapshot.Inventory
		and count(r.EquippedCharacters) == snapshot.Equipped and count(r.Index) == snapshot.Index and r.EquippedDice == snapshot.Dice
		and r.TowerProgress.Ember == snapshot.Ember and r.DailyStreak == snapshot.Streak and r.NextUid == snapshot.NextUid
		and r.Inventory[firstUid] and r.Inventory[firstUid].Level == snapshot.Level
		and r.Inventory[fused.uid] and r.Inventory[fused.uid].Variant == snapshot.Fused
	check(same, "smoke: tudo voltou igual depois do save/load")
	check(r ~= nil and r.Inventory[bulkA] == nil and r.Inventory[bulkB] == nil, "smoke: vendidos em massa não voltam depois do save/load")
	check(S.InventoryService.UnlockedSlots(back)[9] == true and r.EquippedCharacters["9"] == extra, "smoke: andar novo e personagem do slot 9 mantidos")
	local problems = invariants({ back, p2 })
	check(#problems == 0, "smoke: invariantes OK" .. (if #problems > 0 then " — " .. problems[1] else ""))
	leave(back)
	leave(p2)
end)

------------------------------------------------------------------------------------
-- B) SESSÃO LONGA: 10 jogadores, ~4 h lógicas
section("sessão longa", function()
	local players = {}
	for i = 1, 10 do
		local player, ok = join("jogador" .. i)
		if ok then
			table.insert(players, player)
		end
	end
	check(#players == 10, "longa: 10 jogadores com base")
	local ROUNDS = tonumber(process.env.SESSION_ROUNDS) or 1440 -- 1440 rodadas x 10 s = 4 h
	local DT = 10
	local stats = { actions = 0, trades = 0, rebirths = 0, fusions = 0, rejoins = 0, rolls = 0, checks = 0 }
	local allProblems = {}

	local function pick(list)
		return list[math.floor(rand() * #list) + 1]
	end

	local function tryFuse(player, d)
		local buckets = {}
		for _, uid in freeUnprotected(d) do
			local item = d.Inventory[uid]
			local key = item.Id .. "|" .. (item.Variant or "Normal")
			buckets[key] = buckets[key] or {}
			table.insert(buckets[key], uid)
		end
		for _, uids in buckets do
			local item = d.Inventory[uids[1]]
			local order = VariantConfig.ById[item.Variant or "Normal"].Order
			local target = VariantConfig.List[order + 1]
			local need = target and (FusionConfig.RequiredByTarget[target.Id] or FusionConfig.MaxRequired)
			if need and #uids >= need then
				if (call("Fuse", player, { table.unpack(uids, 1, need) })) then
					stats.fusions += 1
				end
				return
			end
		end
	end

	local function tryTrade(a, b)
		if S.TradeService.SessionOf(a) or S.TradeService.SessionOf(b) then
			return
		end
		call("RequestTrade", a, b.UserId)
		call("RespondTrade", b, a.UserId, rand() < 0.9)
		if not S.TradeService.SessionOf(a) then
			return
		end
		local da, db = S.PlayerDataService.GetData(a), S.PlayerDataService.GetData(b)
		local fa, fb = freeUnprotected(da), freeUnprotected(db)
		call("SetTradeOffer", a, if #fa > 0 then { pick(fa) } else {})
		call("SetTradeOffer", b, if #fb > 0 then { pick(fb) } else {})
		local roll = rand()
		if roll < 0.1 then
			call("CancelTrade", b)
			return
		end
		call("SetTradeReady", a, true)
		call("SetTradeReady", b, true)
		call("ConfirmTrade", a)
		if roll < 0.2 and #fa > 0 then
			-- muda a oferta depois de confirmar (invalida a confirmação)
			call("SetTradeOffer", a, { pick(fa) })
		end
		local ok, result = call("ConfirmTrade", b)
		if ok and result == "completed" then
			stats.trades += 1
		end
		call("CancelTrade", a)
	end

	for round = 1, ROUNDS do
		now += DT
		clock += DT
		S.EconomyService.Tick(DT)
		for index, player in players do
			local d = S.PlayerDataService.GetData(player)
			if not d then
				continue
			end
			stats.actions += 1
			local r = rand()
			if r < 0.40 then
				if (call("RequestRoll", player)) then
					stats.rolls += 1
				elseif rand() < 0.5 then
					if rand() < 0.5 then
						call("SellBatch", player, pick({ "Duplicates", "Rarity:Common", "Rarity:Uncommon" }), true)
					else
						-- Mochila: SELECIONAR DUPLICATAS (mesmo critério do cliente) + SellBulk com a prévia
						local pd = S.PlayerDataService.GetData(player)
						local sel = pd and BulkCore.selectDuplicates(pd, InvCore.protection) or {}
						if #sel > 0 then
							local okPv, pv = call("PreviewBulkSale", player, sel)
							if okPv then
								call("SellBulk", player, sel, pv.total, nil)
							end
						end
					end
				end
			elseif r < 0.50 then
				S.EconomyService.Collect(player)
			elseif r < 0.58 then
				call("EquipBest", player)
			elseif r < 0.66 then
				local _, uid = next(d.EquippedCharacters)
				if uid then
					call("UpgradeCharacter", player, uid, math.floor(rand() * 10) + 1)
				end
			elseif r < 0.72 then
				call("BuyUpgrade", player, pick({ "Luck", "Income", "RollSpeed", "Inventory" }))
			elseif r < 0.75 then
				call("BuyDice", player, pick({ "Lucky", "Flame", "Storm", "Void", "Celestial" }))
			elseif r < 0.79 then
				local before = d.Rebirths
				call("Rebirth", player)
				if d.Rebirths > before then
					stats.rebirths += 1
					call("BuyRebirthPerk", player, pick({ "Income", "Luck", "Power", "Capacity", "Speed" }))
				end
			elseif r < 0.84 then
				call("RequestEnterTower", player, pick({ "Ember", "Ember", "Storm", "Void" }))
			elseif r < 0.88 then
				tryFuse(player, d)
			elseif r < 0.93 then
				local other = players[(index + math.floor(rand() * 9)) % #players + 1]
				if other ~= player then
					tryTrade(player, other)
				end
			elseif r < 0.95 then
				-- spam / entradas ruins: nunca podem quebrar nada
				call("Fuse", player, { "c1", "c1", "c1" })
				call("SellCharacter", player, { "c999999" })
				call("EquipCharacter", player, "c999999", 99)
				call("ConfirmTrade", player)
				call("Rebirth", player)
			elseif r < 0.97 then
				call("ClaimDaily", player)
			else
				local missionId = next((d.Missions and d.Missions.Daily) or {})
				if missionId then
					call("ClaimMission", player, "Daily", missionId)
				end
			end
		end
		-- A cada 30 min lógicos um jogador "baleia" recebe o custo do renascimento (exercita o caminho)
		if round % 180 == 0 then
			local whale = players[(round // 180) % #players + 1]
			local dw = S.PlayerDataService.GetData(whale)
			if dw then
				dw.Money += Formulas:rebirthCost(dw.Rebirths) or 0
				local before = dw.Rebirths
				call("Rebirth", whale)
				call("Rebirth", whale) -- spam: o 2º não pode passar sem dinheiro
				if dw.Rebirths == before + 1 then
					stats.rebirths += 1
				elseif dw.Rebirths > before + 1 then
					table.insert(allProblems, "renascimento duplo com dinheiro para um")
				end
			end
		end
		-- De vez em quando alguém sai no meio de uma troca e volta
		if round % 240 == 0 then
			local index = math.floor(rand() * #players) + 1
			local player = players[index]
			local other = players[index % #players + 1]
			call("RequestTrade", player, other.UserId)
			call("RespondTrade", other, player.UserId, true)
			local userId, name = player.UserId, player.Name
			leave(player)
			local back, ok = join(name, userId)
			if ok then
				players[index] = back
				stats.rejoins += 1
			end
		end
		if round % 120 == 0 then
			stats.checks += 1
			for _, problem in invariants(players) do
				table.insert(allProblems, string.format("rodada %d: %s", round, problem))
			end
		end
	end
	for _, problem in invariants(players) do
		table.insert(allProblems, "final: " .. problem)
	end

	print(string.format("    %d ações, %d rolls, %d trocas, %d renascimentos, %d fusões, %d reentradas, %d checagens",
		stats.actions, stats.rolls, stats.trades, stats.rebirths, stats.fusions, stats.rejoins, stats.checks))
	for i = 1, math.min(5, #allProblems) do
		print("    ! " .. allProblems[i])
	end
	check(stats.actions >= 14000 and stats.trades > 0 and stats.rebirths > 0 and stats.fusions > 0 and stats.rejoins > 0, "longa: 4 h lógicas com trocas, renascimentos, fusões e reentradas")
	check(#allProblems == 0, "longa: nenhum invariante quebrado (NaN, negativo, UID, slot, base, troca)")
	-- Todo save gravado pode ser lido de volta
	local saved = 0
	local okJson = true
	for _, player in players do
		local d = S.PlayerDataService.GetData(player)
		local okEncode, text = pcall(serde.encode, "json", d)
		okJson = okJson and okEncode and #text > 0
		saved += 1
	end
	check(okJson and saved == #players, "longa: todos os perfis serializam em JSON")
end)

for i = 1, math.min(5, #runtimeErrors) do
	print("    erro: " .. runtimeErrors[i])
end
check(#runtimeErrors == 0, "nenhum erro de execução nos handlers (" .. #runtimeErrors .. ")")
check(#Env.errors == 0, "nenhum erro em threads do servidor (" .. #Env.errors .. ")")

local failures = T.finish()
process.exit(if failures > 0 then 1 else 0)
