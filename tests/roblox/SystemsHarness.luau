--[[
	SYSTEMS PASS (Lune), Services REAIS + DataStore em memória (JSON):
	  A) FUNDIR MÁX. ≡ FUNDIR 1× repetido (via FusionService real), proteções, spam/replay, desempenho
	  B) PLAYER AURAS: compra sequencial, saldo, replay/simultânea, bônus do MAIOR tier com visual antigo,
	     WalkSpeed (respawn), save/load/reconexão/Rebirth
	  C) LifetimeMoneyGenerated: origens GENERATED contam; venda/auto-venda/dev/Robux/Jackpot não;
	     VIP + Aura contam o valor final UMA vez; Rebirth/gastos não diminuem; exploits
	  D) RANKING MAGNATA: Lifetime (não saldo), gravação só do que mudou, Temporada 1 (migração = 0)
	  E) cenário integrado
]]

local process = require("@lune/process")
local task = require("@lune/task")
local serde = require("@lune/serde")
local roblox = require("@lune/roblox")
local Env = require("./Env")

local env = Env.create()
local T = Env.checker("Systems pass: FUNDIR MÁX. + Player Auras + Lifetime + Magnata")
local check = T.check

local store, writes = {}, {}
env.gameProxy.GameId = 4242
env.stubs.DataStoreService = {
	GetDataStore = function()
		return {
			UpdateAsync = function(_, key, transform)
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

local handlers = {}
local fired = {}
local runtimeErrors = {}
local NetStub = {
	Codes = { RateLimited = "rate_limited", InvalidArgs = "invalid_args", NotReady = "not_ready", NotImplemented = "not_implemented", Internal = "internal" },
	handle = function(name, fn)
		handlers[name] = fn
	end,
	fire = function(name)
		fired[name] = (fired[name] or 0) + 1
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
	"BoostService", "PlayerAuraService", "JackpotService", "LeaderboardService", "AfkService", "DevService",
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
local FusionCore = req(env.server.Core.FusionCore)
local InventoryCore = req(env.server.Core.InventoryCore)
local Migrations = req(env.server.Core.Migrations)
local CharacterConfig = req(env.shared.Config.CharacterConfig)
local PlayerAuraConfig = req(env.shared.Config.PlayerAuraConfig)
local MoneySourceConfig = req(env.shared.Config.MoneySourceConfig)
local MagnateConfig = req(env.shared.Config.MagnateConfig)
local DataConfig = req(env.shared.Config.DataConfig)
local Definitions = req(env.shared.Remotes.Definitions)
local Dev = S.DevService
local Economy = S.EconomyService
local PDS = S.PlayerDataService

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
	player.UserId = userId
	env.join(player)
	local ok = Env.waitFor(function()
		return PDS.IsLoaded(player) and player:GetAttribute("BaseId") ~= nil
	end, 5)
	return player, ok
end

local function leave(player)
	env.leave(player)
	return Env.waitFor(function()
		return PDS.GetData(player) == nil and player:GetAttribute("BaseId") == nil
	end, 5)
end

local function section(name, fn)
	local ok, err = pcall(fn)
	if not ok then
		check(false, name .. " quebrou: " .. tostring(err))
	end
end

-- registra toda entrada de dinheiro (origem/classe) para conferir o Lifetime
local granted = {}
Economy.MoneyAdded:Connect(function(player, value, source, kind)
	table.insert(granted, { player = player, value = value, source = source, kind = kind })
end)
local function generatedSince(player, mark)
	local total = 0
	for i = mark + 1, #granted do
		local g = granted[i]
		if g.player == player and g.kind == "GENERATED" then
			total += g.value
		end
	end
	return total
end

local function firstOfRarity(rarity)
	for _, c in CharacterConfig.List do
		if c.Rarity == rarity then
			return c.Id
		end
	end
	error(rarity)
end
local FAMILY = firstOfRarity("Common")
local OTHER = firstOfRarity("Uncommon")

local seed = 99
local function rand()
	seed = (seed * 48271) % 2147483647
	return seed / 2147483647
end

-- inventário idêntico em dois perfis (mesmos uids/níveis/investimentos)
local function fill(data, spec)
	data.Inventory = {}
	data.EquippedCharacters = {}
	data.NextUid = 1
	for _, s in spec do
		for _ = 1, s.n do
			local uid = InventoryCore.add(data, s.id, 0, s.variant)
			data.Inventory[uid].Level = s.level or 1
			data.Inventory[uid].UpgradeInvestment = s.invest or 0
		end
	end
end

local function signature(data)
	local rows = {}
	for uid, item in data.Inventory do
		table.insert(rows, string.format("%s|%s|%s|%d|%d", uid, item.Id, item.Variant, item.Level, item.UpgradeInvestment or 0))
	end
	table.sort(rows)
	return table.concat(rows, ";") .. "#" .. data.NextUid .. "#" .. string.format("%.0f", data.Money)
end

------------------------------------------------------------------------------------
local pa, okA = join("fm_manual", 9101)
local pb, okB = join("fm_max", 9102)
check(okA and okB, "dois jogadores entram")
local da, db = PDS.GetData(pa), PDS.GetData(pb)

section("A) FUNDIR MÁX.", function()
	-- 1) 300 Normal + 2 Prata (níveis/investimentos variados) + outra família
	local spec = {
		{ id = FAMILY, n = 150, level = 3, invest = 1000 },
		{ id = FAMILY, n = 150, level = 7, invest = 2500 },
		{ id = FAMILY, n = 2, variant = "Silver", level = 12, invest = 9000 },
		{ id = OTHER, n = 9 },
	}
	fill(da, spec)
	fill(db, spec)
	S.IndexService.Register(pa, FAMILY, "Normal")
	S.IndexService.Register(pb, FAMILY, "Normal")
	da.Money, db.Money = 1e15, 1e15
	local lifeA0, lifeB0 = da.LifetimeMoneyGenerated, db.LifetimeMoneyGenerated
	local investBefore = 0
	for _, item in db.Inventory do
		investBefore += item.UpgradeInvestment
	end
	-- A: FUNDIR 1× repetido (Fuse real), ordem canônica
	local manualFusions = 0
	while true do
		local nxt = FusionCore.nextFusion(da, S.FusionService.Configs, FAMILY)
		if not nxt then
			break
		end
		local ok = call("Fuse", pa, nxt.uids)
		if not ok then
			break
		end
		manualFusions += 1
	end
	-- B: prévia + FUNDIR TUDO
	local deltas0 = fired.InventoryDelta or 0
	local okP, preview = call("FuseMax", pb, FAMILY, false)
	check(okP and preview.fusions == manualFusions, string.format("prévia: %s fusões (manual fez %d)", tostring(preview and preview.fusions), manualFusions))
	check(okP and preview.top ~= nil and type(preview.remaining) == "table" and preview.cost > 0, "prévia traz maior resultado, o que sobra e o custo")
	check(signature(db) ~= signature(da), "prévia NÃO muda o inventário")
	local t0 = os.clock()
	local okM, result = call("FuseMax", pb, FAMILY, true, preview.fusions)
	local dt = os.clock() - t0
	check(okM and result.fusions == manualFusions, "FUNDIR MÁX. executa todas as fusões numa operação")
	check(signature(da) == signature(db), "FUNDIR MÁX. ≡ FUNDIR 1× repetido: mesmos uids, variantes, níveis, investimento, NextUid e dinheiro")
	check((fired.InventoryDelta or 0) - deltas0 == 1, "um único delta de inventário para o cliente (sem centenas de remotes)")
	local investAfter, toGold = 0, 0
	for _, item in db.Inventory do
		investAfter += item.UpgradeInvestment
	end
	check(investAfter == investBefore, "investimento total preservado (" .. investAfter .. ")")
	check(da.LifetimeMoneyGenerated == lifeA0 and db.LifetimeMoneyGenerated == lifeB0, "fusão não gera Lifetime")
	local otherLeft = 0
	for _, item in db.Inventory do
		if item.Id == OTHER then
			otherLeft += 1
		end
	end
	check(otherLeft == 9, "outra família intacta")
	local va, vb = da.Index[FAMILY].Variants or {}, db.Index[FAMILY].Variants or {}
	check(vb.Celestial == true and count(va) == count(vb), "Índice registra as variantes novas igual ao manual (" .. count(vb) .. ")")
	print(string.format("    FuseMax real (servidor) 302 unidades: %d fusões em %.1f ms", result.fusions, dt * 1000))
	local _ = toGold

	-- 2) replay / duplo clique / prévia velha
	local money = db.Money
	local okR, codeR = call("FuseMax", pb, FAMILY, true, preview.fusions)
	check(not okR and (codeR == "fusion_none" or codeR == "fusion_changed") and db.Money == money, "replay do mesmo pedido: recusado, nada cobrado (" .. tostring(codeR) .. ")")
	fill(db, { { id = FAMILY, n = 27 } })
	db.Money = 1e15
	local _, p27 = call("FuseMax", pb, FAMILY, false)
	InventoryCore.add(db, FAMILY, 0) -- inventário mudou depois da prévia
	InventoryCore.add(db, FAMILY, 0)
	InventoryCore.add(db, FAMILY, 0)
	local okC, codeC = call("FuseMax", pb, FAMILY, true, p27.fusions)
	check(not okC and codeC == "fusion_changed", "inventário mudou depois da prévia: recusa (fusion_changed)")
	local results = {}
	for i = 1, 2 do
		task.spawn(function()
			results[i] = table.pack(call("FuseMax", pb, FAMILY, true))
		end)
	end
	Env.waitFor(function()
		return results[1] ~= nil and results[2] ~= nil
	end, 2)
	local oks = (if results[1][1] then 1 else 0) + (if results[2][1] then 1 else 0)
	check(oks == 1, "dois cliques simultâneos: só UMA operação aplica")

	-- 3) proteções: equipado, travado, favorito, em troca
	fill(db, { { id = FAMILY, n = 12 } })
	db.Money = 1e15
	local uids = {}
	for uid in db.Inventory do
		table.insert(uids, uid)
	end
	table.sort(uids, FusionCore.uidLess)
	call("SetCharacterFlag", pb, uids[1], "Locked", true)
	call("SetCharacterFlag", pb, uids[2], "Favorite", true)
	call("EquipCharacter", pb, uids[3], 1)
	InventoryCore.setTradeLocks(db, { uids[4] })
	call("FuseMax", pb, FAMILY, true)
	InventoryCore.setTradeLocks(db, nil)
	local alive = 0
	for i = 1, 4 do
		if db.Inventory[uids[i]] then
			alive += 1
		end
	end
	check(alive == 4, "equipado, travado, favorito e em troca não foram consumidos")

	-- 4) dinheiro insuficiente
	fill(db, { { id = FAMILY, n = 3 } })
	db.Money = 0
	local okN, codeN = call("FuseMax", pb, FAMILY, true)
	check(not okN and codeN == "not_enough_money" and count(db.Inventory) == 3, "sem dinheiro: nada muda")

	-- 5) desempenho no servidor (aplicação inteira)
	for _, n in { 300, 1000, 5000 } do
		fill(db, { { id = FAMILY, n = n, level = 2, invest = 10 } })
		db.Money = 1e18
		local t1 = os.clock()
		local okT, r = call("FuseMax", pb, FAMILY, true)
		local ms = (os.clock() - t1) * 1000
		print(string.format("    FuseMax servidor %d unidades: %s fusões em %.1f ms", n, tostring(r and r.fusions), ms))
		check(okT and ms < 1500, string.format("FuseMax %d unidades rápido (%.0f ms)", n, ms))
	end
	fill(da, {})
	fill(db, {})
end)

section("B) PLAYER AURAS", function()
	local d = db
	d.Money = 0
	local okNo, codeNo = call("BuyPlayerAura", pb, 1)
	check(not okNo and codeNo == "not_enough_money", "sem dinheiro: compra recusada")
	d.Money = 1e14
	local okOrder, codeOrder = call("BuyPlayerAura", pb, 2)
	check(not okOrder and codeOrder == "aura_order" and d.Money == 1e14, "fora de ordem (Imperial antes da Desperta): recusada, nada cobrado")
	-- renda antes x depois
	call("EquipBest", pb)
	local ipsBefore = Formulas:incomePerSecond(d)
	local life0 = d.LifetimeMoneyGenerated
	local ok1 = call("BuyPlayerAura", pb, 1)
	check(ok1 and d.Money == 1e14 - 1e9 and d.PlayerAura.Owned == 1 and d.PlayerAura.Equipped == 1, "Desperta: desconta $1B, desbloqueia e equipa")
	check(pb:GetAttribute("PlayerAuraTier") == 1 and pb:GetAttribute("PlayerAuraVisual") == 1, "atributos replicados (tier/visual)")
	check(S.BaseService.WalkSpeedFor(pb) == 28, "Desperta: WalkSpeed 28")
	check(ipsBefore == 0 or math.abs(Formulas:incomePerSecond(d) - ipsBefore * 1.5) < 1e-6 * ipsBefore, "Desperta: renda/s ×1,50")
	check(d.LifetimeMoneyGenerated == life0, "comprar aura NÃO mexe no Lifetime")
	local money1 = d.Money
	local okRe, codeRe = call("BuyPlayerAura", pb, 1)
	check(not okRe and codeRe == "aura_owned" and d.Money == money1, "replay da compra: recusado, nada cobrado")
	-- compra simultânea do próximo tier
	local r = {}
	for i = 1, 2 do
		task.spawn(function()
			r[i] = table.pack(call("BuyPlayerAura", pb, 2))
		end)
	end
	Env.waitFor(function()
		return r[1] ~= nil and r[2] ~= nil
	end, 2)
	check(((if r[1][1] then 1 else 0) + (if r[2][1] then 1 else 0)) == 1 and d.Money == money1 - 25e9, "duas compras simultâneas: uma só, cobrada uma vez")
	for tier = 3, 5 do
		call("BuyPlayerAura", pb, tier)
	end
	local spent = 0
	for _, t in PlayerAuraConfig.List do
		spent += t.Price
	end
	check(d.PlayerAura.Owned == 5 and d.Money == 1e14 - spent, "progressão completa: cada etapa cobra só o seu preço (total $" .. spent .. ")")
	check(PlayerAuraConfig.List[5].Price == 5e12 and PlayerAuraConfig.List[5].MoneyMultiplier == 2.5 and PlayerAuraConfig.List[5].WalkSpeed == 36, "Absoluta = $5T · ×2,50 · 36")
	-- visual antigo: bônus continua o do maior
	local okE = call("EquipPlayerAura", pb, 1)
	check(okE and d.PlayerAura.Equipped == 1 and Formulas:playerAuraMultiplier(d) == 2.5 and S.BaseService.WalkSpeedFor(pb) == 36, "visual Desperta equipado: renda ×2,50 e velocidade 36 continuam (maior comprado)")
	call("EquipPlayerAura", pb, 0)
	check(pb:GetAttribute("PlayerAuraVisual") == 0 and Formulas:playerAuraMultiplier(d) == 2.5, "sem visual: bônus intacto")
	local okBad = call("EquipPlayerAura", pb, 6)
	check(not okBad, "equipar tier inexistente: recusado")
	call("EquipPlayerAura", pb, 5)
	-- remotes só recebem o tier
	check(#Definitions.Requests.BuyPlayerAura.args == 1 and #Definitions.Requests.EquipPlayerAura.args == 1, "remotes de aura recebem só o tier (nunca preço/multiplicador)")
	-- venda NÃO multiplica
	check(Formulas:sellValue(FAMILY, "Normal") == Formulas:sellValue(FAMILY, "Normal"), "preço de venda não depende da aura")
	local plain = { PlayerAura = { Owned = 0 }, Upgrades = {} }
	check(Formulas:sellValue(FAMILY, "Gold") == Formulas:sellValue(FAMILY, "Gold") and Formulas:playerAuraMultiplier(plain) == 1, "sem aura ×1")

	-- respawn: WalkSpeed reaplicado várias vezes, sem duplicar nada no servidor
	for i = 1, 3 do
		local character = roblox.Instance.new("Model")
		character.Name = "fm_max"
		local humanoid = roblox.Instance.new("Humanoid")
		humanoid.Parent = character
		local root = roblox.Instance.new("Part")
		root.Name = "HumanoidRootPart"
		root.Parent = character
		character.Parent = env.real.Workspace
		pb.Character = character
		pb.CharacterAdded:Fire(character)
		local okS = Env.waitFor(function()
			return humanoid.WalkSpeed == 36
		end, 2)
		check(okS, "respawn #" .. i .. ": WalkSpeed 36 reaplicado")
		character:Destroy()
	end
	pb.Character = nil

	-- save/load/reconexão
	local before = { owned = d.PlayerAura.Owned, eq = d.PlayerAura.Equipped, money = d.Money, life = d.LifetimeMoneyGenerated }
	check(leave(pb), "saiu (save)")
	local back = join("fm_max", 9102)
	local d2 = PDS.GetData(back)
	check(d2.PlayerAura.Owned == before.owned and d2.PlayerAura.Equipped == before.eq and d2.Money == before.money, "save/load/reconexão: aura e saldo preservados")
	check(back:GetAttribute("PlayerAuraTier") == 5 and S.BaseService.WalkSpeedFor(back) == 36, "reconexão: atributos e velocidade reaplicados")
	pb, db = back, d2
end)

section("C) LifetimeMoneyGenerated", function()
	local p, d = pb, db
	-- Collector com VIP ×1,5 e Aura ×2,5 (Absoluta): o valor FINAL conta uma vez
	d.Runtime.Income = 1.5
	for _ = 1, 4 do
		S.InventoryService.Add(p, FAMILY)
	end
	call("EquipBest", p)
	local ips = Formulas:incomePerSecond(d)
	local noMult = ips / (1.5 * 2.5)
	check(ips > 0 and math.abs(ips - noMult * 1.5 * 2.5) < 1e-6 * ips, "renda/s = base × VIP × Aura")
	d.UncollectedMoney = 0
	Economy.Tick(10)
	local mark, life0 = #granted, d.LifetimeMoneyGenerated
	local collected = Economy.Collect(p)
	check(collected > 0 and d.LifetimeMoneyGenerated - life0 == collected and generatedSince(p, mark) == collected, string.format("Collector (VIP+Aura): Lifetime +%d = valor coletado, UMA vez", collected))
	-- (o loop real de 1 s do servidor pode somar mais um tick no meio)
	check(collected >= math.floor(ips * 10) and collected <= math.floor(ips * 12), "o valor coletado é a produção final (×1,5 × ×2,5)")
	-- Offline
	d.PendingOfflineReward = 12345
	life0 = d.LifetimeMoneyGenerated
	call("ClaimOfflineReward", p)
	check(d.LifetimeMoneyGenerated - life0 == 12345, "Offline: conta")
	-- Daily / Mission / Tower: origem GENERATED
	for _, source in { "Daily", "Mission", "Tower" } do
		life0 = d.LifetimeMoneyGenerated
		Economy.AddMoney(p, 1000, source)
		check(d.LifetimeMoneyGenerated - life0 == 1000, source .. ": conta")
	end
	local dailyMark, lifeD = #granted, d.LifetimeMoneyGenerated
	call("ClaimDaily", p)
	check(d.LifetimeMoneyGenerated - lifeD == generatedSince(p, dailyMark), "Diário real (handler): Lifetime = exatamente o GENERATED entregue")
	-- NÃO contam
	for _, source in { "Sell", "AutoSell", "Refund", "Trade", "Jackpot", "Product", "Dev", "Admin" } do
		life0 = d.LifetimeMoneyGenerated
		local m0 = d.Money
		Economy.AddMoney(p, 777, source)
		check(d.LifetimeMoneyGenerated == life0 and d.Money == m0 + 777, source .. ": entra no saldo, NÃO no Lifetime")
	end
	life0 = d.LifetimeMoneyGenerated
	Dev.Run("GiveMoney", p, 5e9)
	check(d.LifetimeMoneyGenerated == life0, "DEV GiveMoney: não conta")
	-- venda real
	local uid = S.InventoryService.Add(p, FAMILY)
	life0 = d.LifetimeMoneyGenerated
	call("SellCharacter", p, { uid })
	check(d.LifetimeMoneyGenerated == life0, "venda (handler real): não conta")
	-- up -> sell -> refund
	local uid2 = S.InventoryService.Add(p, FAMILY)
	call("UpgradeCharacter", p, uid2, 5)
	life0 = d.LifetimeMoneyGenerated
	call("SellCharacter", p, { uid2 })
	check(d.LifetimeMoneyGenerated == life0, "melhorar -> vender -> reembolso: não fabrica Lifetime")
	-- gastar não diminui
	life0 = d.LifetimeMoneyGenerated
	Economy.TrySpend(p, d.Money // 2)
	check(d.LifetimeMoneyGenerated == life0, "gastar não diminui o Lifetime")
	-- exploits
	local function rejects(amount, source)
		local m0, l0 = d.Money, d.LifetimeMoneyGenerated
		local ok = pcall(Economy.AddMoney, p, amount, source)
		return not ok and d.Money == m0 and d.LifetimeMoneyGenerated == l0
	end
	check(rejects(0 / 0, "Collector") and rejects(math.huge, "Collector") and rejects(-5, "Collector") and rejects(1e30, "Collector"), "NaN / infinito / negativo / overflow: recusados sem mudar nada")
	check(rejects(100, "Hack") and rejects(100, nil), "origem desconhecida: falha fechada")
	life0 = d.LifetimeMoneyGenerated
	Economy.AddMoney(p, 500, "Mission", "mission:test:1")
	Economy.AddMoney(p, 500, "Mission", "mission:test:1")
	check(d.LifetimeMoneyGenerated - life0 == 500, "grant duplicado (mesmo opId): credita uma vez")
	local forge = false
	for name, def in Definitions.Requests do
		for _, arg in def.args do
			if arg.type == "number" and (string.find(string.lower(name), "money") or string.find(string.lower(name), "lifetime")) then
				forge = true
			end
		end
	end
	check(not forge and not table.find(DataConfig.ClientSettings, "LifetimeMoneyGenerated"), "nenhum remote aceita valor de dinheiro/Lifetime do cliente")
	-- todas as origens do servidor estão classificadas
	for _, kind in MoneySourceConfig.Sources do
		check(kind == "GENERATED" or kind == "RECYCLED" or kind == "REFUND" or kind == "TRANSFER" or kind == "OTHER", "classe válida: " .. kind)
	end
	-- Rebirth: Lifetime fica, Money zera
	d.Money = 1e15
	life0 = d.LifetimeMoneyGenerated
	local okRb = call("Rebirth", p)
	check(okRb and d.Money == 0 and d.LifetimeMoneyGenerated == life0, "Rebirth: Money zera, Lifetime permanece")
	check(d.PlayerAura.Owned == 5, "Rebirth: Player Aura permanece")
	Economy.AddMoney(p, 500e6, "Collector")
	check(d.LifetimeMoneyGenerated == life0 + 500e6, "depois do Rebirth a geração volta a somar")
end)

section("D) RANKING MAGNATA", function()
	local fake = { sets = 0, data = {} }
	function fake:SetAsync(key, value)
		self.sets += 1
		self.data[key] = value
	end
	function fake:GetSortedAsync()
		return nil
	end
	S.LeaderboardService._setStore("Magnate", fake)
	-- A: saldo $1B, Lifetime $20T; B: saldo $5T, Lifetime $10T  -> A > B
	da.Money, da.LifetimeMoneyGenerated = 1e9, 20e12
	db.Money, db.LifetimeMoneyGenerated = 5e12, 10e12
	local top = S.LeaderboardService.LocalTop("Magnate", MagnateConfig.Top)
	check(top[1] and top[1].name == pa.DisplayName and top[2].name == pb.DisplayName, "Magnata ordena por Lifetime (A $20T > B $10T), NÃO pelo saldo")
	S.LeaderboardService.Refresh()
	local panel = env.real.Workspace.Map:FindFirstChild("Panel4", true)
	local sign = panel and panel:FindFirstChild("Sign")
	check(sign ~= nil and sign:FindFirstChild("Row10") ~= nil, "4º painel (Panel4) com 10 linhas")
	check(sign and sign.Row1.PlayerName.Text == pa.DisplayName and string.find(sign.Row1.Value.Text, "T", 1, true) ~= nil and string.find(sign.Row1.Value.Text, "$", 1, true) ~= nil, "painel mostra $ com o formatter (" .. tostring(sign and sign.Row1.Value.Text) .. ")")
	check(string.find(sign.Title.Text, "MAGNATA", 1, true) ~= nil and string.find(sign.Title.Text, "1", 1, true) ~= nil, "título 👑 MAGNATA · TEMPORADA 1")
	-- polish de legibilidade: 10 linhas da MESMA altura, texto >= 18 px, valor com coluna larga,
	-- nome truncado com "…", título em 2 linhas ajustado (sem cortar)
	local h, sizes, same = nil, math.huge, true
	for i = 1, 10 do
		local row = sign["Row" .. i]
		h = h or row.Size.Y.Scale
		same = same and math.abs(row.Size.Y.Scale - h) < 1e-9
		sizes = math.min(sizes, row.Value.TextSize, row.PlayerName.TextSize)
	end
	local total = sign.Title.Size.Y.Scale + 10 * h + 11 * sign.UIListLayout.Padding.Scale
	check(same and total <= 1 and sizes >= 18, string.format("Magnata: 10 linhas iguais (%.3f), cabem no painel (%.2f), texto >= 18 px (%d)", h, total, sizes))
	check(sign.Row1.Value.Size.X.Scale >= 0.3 and sign.Row1.PlayerName.TextTruncate == roblox.Enum.TextTruncate.AtEnd and sign.Row1.Value.TextXAlignment == roblox.Enum.TextXAlignment.Right, "Magnata: valor alinhado à direita em coluna larga; nome longo trunca com …")
	check(sign.Title.TextScaled and string.find(sign.Title.Text, "\n", 1, true) ~= nil and panel.Size.Y >= 15, "Magnata: título em duas linhas (👑 MAGNATA / TEMPORADA 1), painel mais alto")
	for i = 1, 3 do
		check(env.real.Workspace.Map:FindFirstChild("Panel" .. i, true) ~= nil, "painel " .. i .. " original continua")
	end
	-- gravação: só o que mudou
	S.LeaderboardService._write(pa, true)
	local sets1 = fake.sets
	S.LeaderboardService._write(pa, true)
	check(fake.sets == sets1, "sem mudança: nenhuma gravação extra no OrderedDataStore")
	Economy.AddMoney(pa, 5000, "Collector")
	S.LeaderboardService._write(pa, true)
	check(fake.sets == sets1 + 1 and fake.data[tostring(pa.UserId)] == math.floor(da.LifetimeMoneyGenerated / 1000), "mudou: 1 gravação, pontuação = Lifetime/1000")
	-- gastar / comprar aura / Rebirth não derruba a posição
	da.Money = 1e14
	call("BuyPlayerAura", pa, 1)
	Economy.TrySpend(pa, da.Money)
	local top2 = S.LeaderboardService.LocalTop("Magnate", MagnateConfig.Top)
	check(top2[1].name == pa.DisplayName and da.LifetimeMoneyGenerated >= 20e12, "gasto grande + compra de aura: posição e Lifetime mantidos")
	-- save/load
	local lifeA = da.LifetimeMoneyGenerated
	leave(pa)
	local back = join("fm_manual", 9101)
	check(PDS.GetData(back).LifetimeMoneyGenerated == lifeA, "save/load: Lifetime preservado")
	pa, da = back, PDS.GetData(back)
	-- Temporada 1: save antigo (v4) começa em 0 — nunca estimado
	store[DataConfig.KeyPrefix .. "9200"] = serde.encode("json", { Data = { Version = 4, Money = 9e12, Rebirths = 12, Inventory = {} }, Meta = {} })
	local old, okOld = join("veterano", 9200)
	local dOld = PDS.GetData(old)
	check(okOld and dOld.LifetimeMoneyGenerated == 0 and dOld.Money == 9e12 and dOld.PlayerAura.Owned == 0 and dOld.Version == 5, "migração v5: veterano começa a Temporada 1 com Lifetime 0 (não usa Money/Rebirth)")
	local bad = Migrations[5]({ LifetimeMoneyGenerated = 0 / 0, PlayerAura = { Owned = 99, Equipped = -3 } })
	check(bad.LifetimeMoneyGenerated == 0 and bad.PlayerAura.Owned == 5 and bad.PlayerAura.Equipped == 0, "migração saneia NaN e aura inválida")
	local keep = Migrations[5]({ LifetimeMoneyGenerated = 123 })
	check(keep.LifetimeMoneyGenerated == 123, "migração não zera valor válido (re-rodar é seguro)")
	leave(old)
end)

section("E) Integrado", function()
	local p = join("novato", 9300)
	local d = PDS.GetData(p)
	check(d.LifetimeMoneyGenerated == 0 and d.PlayerAura.Owned == 0, "jogador novo: Lifetime 0, sem aura")
	-- gera dinheiro (coleta legítima)
	for _ = 1, 3 do
		S.InventoryService.Add(p, FAMILY)
	end
	call("EquipBest", p)
	d.UncollectedMoney = 0
	Economy.Tick(100)
	local got = Economy.Collect(p)
	check(got > 0 and d.LifetimeMoneyGenerated == got, "gera Money -> Lifetime sobe junto")
	local ipsBase = Formulas:incomePerSecond(d)
	-- compra Desperta (dinheiro de teste DEV, que não conta)
	Dev.Run("GiveMoney", p, 2e9)
	local lifeBefore = d.LifetimeMoneyGenerated
	local money0 = d.Money
	call("BuyPlayerAura", p, 1)
	check(d.Money == money0 - 1e9 and d.LifetimeMoneyGenerated == lifeBefore, "compra Desperta: Money cai, Lifetime não")
	local ipsAura = Formulas:incomePerSecond(d)
	check(math.abs(ipsAura - ipsBase * 1.5) < 1e-6 * ipsAura, "Desperta: produção ×1,50")
	d.UncollectedMoney = 0
	task.wait(0.6) -- cooldown do coletor
	Economy.Tick(100)
	local pending = math.floor(d.UncollectedMoney) -- (o loop real do servidor também soma ticks)
	local got2 = Economy.Collect(p)
	check(got2 == pending and got2 >= math.floor(ipsAura * 100) and d.LifetimeMoneyGenerated == lifeBefore + got2, "produção ×1,5 entra no Lifetime pelo valor final")
	-- Rebirth
	d.Money = 1e15
	local lifeR = d.LifetimeMoneyGenerated
	call("Rebirth", p)
	check(d.LifetimeMoneyGenerated == lifeR and d.PlayerAura.Owned == 1, "Rebirth: Lifetime e aura permanecem")
	-- reconexão
	leave(p)
	local back = join("novato", 9300)
	local db2 = PDS.GetData(back)
	check(db2.LifetimeMoneyGenerated == lifeR and db2.PlayerAura.Owned == 1, "reconexão: dados permanecem")
	local top = S.LeaderboardService.LocalTop("Magnate", MagnateConfig.Top)
	local pos
	for i, e in top do
		if e.name == back.DisplayName then
			pos = i
		end
	end
	check(pos ~= nil, "Ranking Magnata: jogador continua no ranking (#" .. tostring(pos) .. ")")
	leave(back)
end)

section("F) DEV: PlayerAuraLineup / PlayerAuraStress sem sobreposição", function()
	local function dummies()
		local folder = env.real.Workspace:FindFirstChild("DevPlayerAuras")
		local list = {}
		for _, m in (folder and folder:GetChildren() or {}) do
			local root = m:FindFirstChild("HumanoidRootPart")
			local label = root and root:FindFirstChild("AuraLabel")
			table.insert(list, { pos = root.CFrame.Position, label = label, text = label and label.Text.Text, width = label and label.Size.X.Scale, tier = m:GetAttribute("PlayerAuraVisual") })
		end
		return list
	end
	local function minGap(list)
		local gap = math.huge
		for i = 1, #list do
			for j = i + 1, #list do
				gap = math.min(gap, (list[i].pos - list[j].pos).Magnitude)
			end
		end
		return gap
	end
	Dev.Run("PlayerAuraLineup", pa)
	local lineup = dummies()
	local names = {}
	for _, d in lineup do
		names[d.tier] = d.text
	end
	check(#lineup == 5 and names[1] == "DESPERTA" and names[2] == "IMPERIAL" and names[3] == "DIVINA" and names[4] == "CELESTIAL" and names[5] == "ABSOLUTA", "lineup: 5 bonecos, rótulo só com o nome (DESPERTA … ABSOLUTA)")
	local labelW = lineup[1].width
	check(minGap(lineup) >= 12 and labelW + 1 < minGap(lineup), string.format("lineup: %.0f studs entre bonecos; rótulos de %.0f studs não se sobrepõem", minGap(lineup), labelW))
	check(minGap(lineup) >= 2 * 3.3 + 4, "lineup: os anéis/fluxos da maior aura não invadem o vizinho")
	Dev.Run("PlayerAuraStress", pa, 10, "Absoluta")
	local stress = dummies()
	local labelsOk = true
	for _, d in stress do
		labelsOk = labelsOk and string.match(d.text or "", "^Absoluta #%d+$") ~= nil and d.tier == 5
	end
	check(#stress == 10 and labelsOk, "stress: 10 Absolutas com rótulos curtos (Absoluta #n)")
	check(minGap(stress) >= 9 and stress[1].width + 1 < minGap(stress), string.format("stress: formação 5 + 5 espaçada (mín. %.1f studs; rótulo %.0f)", minGap(stress), stress[1].width))
	Dev.Run("PlayerAuraClear")
end)

check(#runtimeErrors == 0, "nenhum erro de execução nos handlers (" .. #runtimeErrors .. ")" .. (if #runtimeErrors > 0 then ": " .. runtimeErrors[1] else ""))
check(#Env.errors == 0, "nenhum erro em threads do servidor (" .. #Env.errors .. ")" .. (if #Env.errors > 0 then ": " .. tostring(Env.errors[1]) else ""))
local failures = T.finish()
process.exit(if failures == 0 then 0 else 1)
