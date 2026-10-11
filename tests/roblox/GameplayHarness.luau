--[[
	Teste de INTEGRAÇÃO das Fases 3–6 + estações / offline / diário (Lune), com os Services
	REAIS e jogadores falsos: roll, cooldown, pity, inventário cheio, auto-sell, equipar,
	estações (billboard/pad), nível individual, renda/coletor, dados, upgrades, venda,
	Index, dinheiro offline e recompensas diárias.
]]

local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")
local Env = require("./Env")

local CFrame = roblox.CFrame
local Instance = roblox.Instance
local Vector3 = roblox.Vector3

local env = Env.create()
local T = Env.checker("Integração: gameplay (roll -> inventário -> base -> economia)")
local check = T.check

local sent = {}
local handlers = {}
local NetStub = {
	Codes = { RateLimited = "rate_limited", InvalidArgs = "invalid_args", NotReady = "not_ready", NotImplemented = "not_implemented", Internal = "internal" },
	handle = function(name, fn)
		assert(handlers[name] == nil, "handler duplicado: " .. name)
		handlers[name] = fn
	end,
	fire = function(name, player, ...)
		table.insert(sent, { name = name, player = player, args = { ... } })
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

-- Chama um handler como o Net faria: (true, dados) ou (false, código)
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
	print("    erro:", result)
	return false, tostring(result)
end

local function lastEvent(name, player)
	for i = #sent, 1, -1 do
		if sent[i].name == name and (player == nil or sent[i].player == player) then
			return sent[i]
		end
	end
	return nil
end

local for_each_required = {
	"RequestRoll", "EquipCharacter", "UnequipCharacter", "EquipBest", "SetCharacterFlag", "UpgradeCharacter",
	"CollectMoney", "BuyDice", "EquipDice", "BuyUpgrade", "SellCharacter", "SellBatch", "SetAutoSell",
	"ClaimOfflineReward", "GetDailyStatus", "ClaimDaily",
}
local missing = {}
for _, name in for_each_required do
	if not handlers[name] then
		table.insert(missing, name)
	end
end
check(#missing == 0, "todos os remotes de gameplay têm handler" .. (if #missing > 0 then " (faltando: " .. table.concat(missing, ", ") .. ")" else ""))

local p1 = env.newPlayer("alandias123")
local p2 = env.newPlayer("rival")
env.join(p1)
env.join(p2)
check(Env.waitFor(function()
	return p1:GetAttribute("BaseId") ~= nil and p2:GetAttribute("BaseId") ~= nil
end), "jogadores carregados e com base")
local d1 = S.PlayerDataService.GetData(p1)
local d2 = S.PlayerDataService.GetData(p2)
check(d1.Version == 2 and d1.NextUid == 1 and d1.Pity.Legendary == 0, "perfil novo no schema v2")

-- Controle de tempo e sorte
local clock = 1000
S.RollService._clock = function()
	return clock
end
local fixed = nil
local realRand = S.RollService._rand
S.RollService._rand = function()
	if fixed then
		return fixed
	end
	return realRand()
end

------------------------------------------------------------------------------------
-- ROLL
local ok, r = call("RequestRoll", p1)
check(ok and type(r) == "table" and r.CharacterId and r.Rarity and r.Uid, "RequestRoll devolve personagem, raridade e uid")
check(ok and d1.Inventory[r.Uid] ~= nil and d1.Inventory[r.Uid].Level == 1 and d1.Inventory[r.Uid].Variant == "Normal", "unidade criada no inventário (Level 1, Normal)")
check(d1.Rolls == 1, "Rolls = 1")
check(ok and r.IsNew == true and d1.Index[r.CharacterId] ~= nil, "primeira vez: NOVO e registrado no Index")
check(lastEvent("InventoryDelta", p1) ~= nil, "cliente recebe só o delta do inventário")

local ok2, code = call("RequestRoll", p1)
check(not ok2 and code == "cooldown", "roll imediato recusado (cooldown no servidor)")
clock += 1.0
check((call("RequestRoll", p1)), "depois do cooldown: roll aceito")

-- Pity
clock += 2
d1.Pity = { Legendary = 49, Mythic = 10 }
fixed = 0 -- sem pity daria Comum
local okP, rp = call("RequestRoll", p1)
fixed = nil
local tier = { Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 5, Mythic = 6, Divine = 7, Secret = 8 }
check(okP and tier[rp.Rarity] >= 5 and rp.PityTriggered == "Legendary", "pity: 50º roll sem Lendário = Lendário garantido")
check(d1.Pity.Legendary == 0, "pity Lendário zerado depois")

-- Auto-sell
clock += 2
fixed = 0 -- Comum, primeiro da lista
call("RequestRoll", p1)
local countBefore = 0
for _ in d1.Inventory do
	countBefore += 1
end
check((call("SetAutoSell", p1, "Common", true)), "SetAutoSell(Common, true)")
local okS, codeS = call("SetAutoSell", p1, "Secret", true)
check(not okS and codeS == "protected", "Secreto nunca entra no auto-sell")
local moneyBefore = d1.Money
clock += 2
local okA, ra = call("RequestRoll", p1)
fixed = nil
local countAfter = 0
for _ in d1.Inventory do
	countAfter += 1
end
check(okA and ra.AutoSold and ra.Uid == nil and countAfter == countBefore, "auto-sell: não entra no inventário")
check(okA and d1.Money == moneyBefore + ra.SoldFor and ra.SoldFor > 0, "auto-sell: vira dinheiro")
check(okA and d1.Index[ra.CharacterId].Count >= 2, "auto-sell: Index continua contando")
call("SetAutoSell", p1, "Common", false)

-- Inventário cheio
local capacity = S.InventoryService.Capacity(p1)
while S.InventoryService.Count(p1) < capacity do
	S.InventoryService.Add(p1, "flame_rookie")
end
clock += 2
local rollsBefore = d1.Rolls
local okF, codeF = call("RequestRoll", p1)
check(not okF and codeF == "inventory_full" and d1.Rolls == rollsBefore, "inventário cheio: bloqueia ANTES de sortear")
local all = {}
for uid in d1.Inventory do
	table.insert(all, uid)
end
S.InventoryService.Remove(p1, all)

------------------------------------------------------------------------------------
-- EQUIPAR + ESTAÇÕES
local a = S.InventoryService.Add(p1, "dragon_knight")
local b = S.InventoryService.Add(p1, "flame_rookie")
local c = S.InventoryService.Add(p1, "void_emperor")
local okE, slot = call("EquipCharacter", p1, a)
check(okE and slot == 1 and d1.EquippedCharacters["1"] == a, "EquipCharacter: primeiro slot livre")
local base1 = S.BaseService.GetPlayerBase(p1)
local runtime = base1.RuntimeCharacters
check(Env.waitFor(function()
	return runtime:FindFirstChild("Station_1") ~= nil
end), "estação criada no pedestal (RuntimeCharacters/Station_1)")
local station = runtime:FindFirstChild("Station_1")
local info = station and station:FindFirstChild("InfoAnchor") and station.InfoAnchor:FindFirstChild("Info")
check(info ~= nil and info.Detail.Title.Text == "Dragon Knight", "billboard: nome")
check(info ~= nil and info.Detail.Rarity.Text ~= "" and info.Detail.Level.Text ~= "" and string.find(info.Income.Text, "/s") ~= nil, "billboard: raridade, nível e renda/s")
check(station and station:FindFirstChild("UpgradePad") ~= nil and station.UpgradePad.Cost.Cost.Text ~= "", "pad de upgrade com custo")
check(station and station:FindFirstChild("Plate") ~= nil, "placa do pedestal (produzido + nível)")
local figure = station and station:FindFirstChild("dragon_knight")
local okParts = figure ~= nil
if figure then
	for _, part in figure:GetDescendants() do
		if part:IsA("BasePart") and (part.CanCollide or part.CanTouch or part.CanQuery or not part.Anchored) then
			okParts = false
		end
	end
end
check(okParts, "personagem 3D sem colisão/toque/consulta e ancorado")

local okL, codeL = call("EquipCharacter", p1, b, 5)
check(not okL and codeL == "slot_locked", "RB0: slot 5 bloqueado")
local foreign = S.InventoryService.Add(p2, "flame_rookie")
local okO, codeO = call("EquipCharacter", p1, foreign)
check(not okO and codeO == "not_owned", "uid de outro jogador: recusado")
local okOc, codeOc = call("EquipCharacter", p1, a, 1)
check(okOc, "re-equipar no mesmo slot é ok")
call("EquipCharacter", p1, b, 2)
local okOcc, codeOcc = call("EquipCharacter", p1, c, 2)
check(not okOcc and codeOcc == "slot_occupied", "slot ocupado: recusado")

local okB, placed = call("EquipBest", p1)
check(okB and placed == 3 and d1.EquippedCharacters["1"] == c and d1.EquippedCharacters["2"] == a, "EQUIPAR MELHORES por renda")
check(Env.waitFor(function()
	return runtime:FindFirstChild("Station_3") ~= nil and runtime.Station_1:GetAttribute("Uid") == c
end), "estações seguem o equipamento")
local okU = call("UnequipCharacter", p1, b)
check(okU and runtime:FindFirstChild("Station_3") == nil, "desequipar remove a estação")
call("EquipCharacter", p1, b)

------------------------------------------------------------------------------------
-- NÍVEL INDIVIDUAL
d1.Money = 0
local okN, codeN = call("UpgradeCharacter", p1, a, 1)
check(not okN and codeN == "not_enough_money", "upgrade sem dinheiro: falha")
local Formulas = req(env.shared.Modules.GameFormulas)
local cost = Formulas:characterUpgradeCost("dragon_knight", 1, 1)
local incomeBefore = Formulas:incomePerSecond(d1)
d1.Money = cost
local okUp, up = call("UpgradeCharacter", p1, a, 1)
check(okUp and up.level == 2 and d1.Inventory[a].Level == 2, "upgrade: Level 1 -> 2")
check(d1.Money == 0, "upgrade desconta o custo exato")
check(Formulas:incomePerSecond(d1) > incomeBefore, "upgrade aumenta a renda")
local st1 = runtime:FindFirstChild("Station_2")
check(st1 and string.find(st1.InfoAnchor.Info.Detail.Level.Text, "2") ~= nil, "billboard atualiza o nível")
check(lastEvent("StationUpgraded", p1) ~= nil, "cliente recebe StationUpgraded (som/efeito)")
-- Spam: dinheiro para exatamente 1 nível
d1.Money = Formulas:characterUpgradeCost("dragon_knight", 2, 1)
local successes = 0
for _ = 1, 10 do
	if call("UpgradeCharacter", p1, a, 1) then
		successes += 1
	end
end
check(successes == 1 and d1.Inventory[a].Level == 3, "spam: só um upgrade é pago")
local loose = S.InventoryService.Add(p1, "shadow_scout")
d1.Money = 1e12
local okNE, codeNE = call("UpgradeCharacter", p1, loose, 1)
check(not okNE and codeNE == "not_equipped", "personagem não equipado: não melhora (regra: precisa estar na estação)")
local okFO, codeFO = call("UpgradeCharacter", p1, foreign, 1)
check(not okFO and codeFO == "not_owned", "uid de outro jogador: não melhora")
local okMax, upMax = call("UpgradeCharacter", p1, a, 100)
check(okMax and upMax.level == 50, "x100 para no MaxLevel (50)")
local okMx, codeMx = call("UpgradeCharacter", p1, a, 1)
check(not okMx and codeMx == "max_level", "no MaxLevel: recusado")

-- Pad: pisar melhora
local character = Instance.new("Model")
local root = Instance.new("Part")
root.Name = "HumanoidRootPart"
root.Parent = character
p1.Character = character
local padStation = runtime:FindFirstChild("Station_3")
local levelBefore = d1.Inventory[padStation:GetAttribute("Uid")].Level
root.CFrame = padStation.UpgradePad.CFrame * CFrame.new(0, 3, 0)
check(Env.waitFor(function()
	return d1.Inventory[padStation:GetAttribute("Uid")].Level > levelBefore
end, 2), "pisar no pad de upgrade melhora o personagem")
root.CFrame = CFrame.new(0, 500, 0)
task.wait(0.1)

------------------------------------------------------------------------------------
-- RENDA + COLETOR
d1.Money = 0
d1.UncollectedMoney = 0
local ips = Formulas:incomePerSecond(d1)
S.EconomyService.Tick(10)
check(math.abs(d1.UncollectedMoney - ips * 10) < 1e-6, "renda passiva vai para o coletor (UncollectedMoney)")
local amountLabel = base1.MoneyCollector.Label:FindFirstChild("Amount")
check(amountLabel ~= nil and string.sub(amountLabel.Text, 1, 1) == "$", "coletor mostra o valor acumulado")
local okC, codeC = call("CollectMoney", p1)
check(not okC and codeC == "too_far", "CollectMoney de longe: recusado")
local expected = math.floor(d1.UncollectedMoney)
root.CFrame = base1.MoneyCollector.CFrame * CFrame.new(0, 3, 0)
check(Env.waitFor(function()
	return d1.Money == expected
end, 2), "pisar no coletor transfere para Money")
check(lastEvent("MoneyCollected", p1) ~= nil, "efeito de moedas (MoneyCollected)")
root.CFrame = CFrame.new(0, 500, 0)
check(d1.UncollectedMoney < 1, "coletor zera depois de coletar")

------------------------------------------------------------------------------------
-- DADOS
d1.Money = 0
d1.Rolls = 0
local okD, codeD = call("BuyDice", p1, "Lucky")
check(not okD and codeD == "requires_rolls", "dado: requisito de rolls")
d1.Rolls = 50
local okD2, codeD2 = call("BuyDice", p1, "Lucky")
check(not okD2 and codeD2 == "not_enough_money", "dado: falta dinheiro")
d1.Money = 2500
check((call("BuyDice", p1, "Lucky")) and d1.OwnedDice.Lucky and d1.EquippedDice == "Lucky" and d1.Money == 0, "comprar Lucky: desconta e equipa")
check(Formulas:luck(d1, os.time()) == 1.25, "Luck do dado aplicada (1.25)")
local okD3, codeD3 = call("EquipDice", p1, "Void")
check(not okD3 and codeD3 == "not_owned", "equipar dado que não possui: recusado")
local okD4, codeD4 = call("BuyDice", p1, "Prism")
check(not okD4 and codeD4 == "exclusive", "dado exclusivo não está à venda")
check((call("EquipDice", p1, "Normal")) and d1.EquippedDice == "Normal", "trocar para dado possuído")

------------------------------------------------------------------------------------
-- UPGRADES GLOBAIS
d1.Money = Formulas:upgradeCost("Luck", 0)
check((call("BuyUpgrade", p1, "Luck")) and d1.Upgrades.Luck == 1 and d1.Money == 0, "upgrade global de Luck: nível 1, custo descontado")
d1.Upgrades.RollSpeed = 11
d1.Money = 1e15
local okUM, codeUM = call("BuyUpgrade", p1, "RollSpeed")
check(not okUM and codeUM == "max_level", "upgrade global no máximo: recusado")
check(Formulas:rollCooldown(d1) >= 0.45, "cooldown nunca abaixo do mínimo seguro")

------------------------------------------------------------------------------------
-- VENDA
local v1 = S.InventoryService.Add(p1, "spark_cadet")
local v2 = S.InventoryService.Add(p1, "spark_cadet")
local v3 = S.InventoryService.Add(p1, "tide_apprentice")
call("SetCharacterFlag", p1, v1, "Locked", true)
call("SetCharacterFlag", p1, v2, "Favorite", true)
local okL1, codeL1 = call("SellCharacter", p1, { v1 })
check(not okL1 and codeL1 == "locked", "vender travado: recusado")
local okL2, codeL2 = call("SellCharacter", p1, { v2 })
check(not okL2 and codeL2 == "favorite", "vender favorito: recusado")
local okL3, codeL3 = call("SellCharacter", p1, { a })
check(not okL3 and codeL3 == "equipped", "vender equipado: recusado")
d1.Money = 0
local okSell, sold = call("SellCharacter", p1, { v3 })
check(okSell and sold.total == Formulas:sellValue("tide_apprentice") and d1.Money == sold.total and d1.Inventory[v3] == nil, "vender livre: preço do servidor")
S.InventoryService.Add(p1, "wind_disciple")
S.InventoryService.Add(p1, "wind_disciple")
local before = {}
for uid in d1.Inventory do
	before[uid] = true
end
local okPrev, prev = call("SellBatch", p1, "Rarity:Common", false)
local unchanged = true
for uid in before do
	if not d1.Inventory[uid] then
		unchanged = false
	end
end
check(okPrev and prev.preview and prev.count >= 2 and unchanged, "SellBatch prévia não vende nada")
local okBatch, batch = call("SellBatch", p1, "Rarity:Common", true)
check(okBatch and batch.count == prev.count and batch.total == prev.total, "SellBatch confirmado = prévia")
check(d1.Inventory[v1] ~= nil and d1.Inventory[v2] ~= nil and d1.Inventory[b] ~= nil, "venda em massa nunca inclui travado/favorito/equipado")

------------------------------------------------------------------------------------
-- INDEX
local gemsBefore = d1.Gems
for _, id in { "flame_rookie", "wind_disciple", "stone_brawler", "spark_cadet", "tide_apprentice", "shadow_scout", "ember_archer" } do
	S.IndexService.Register(p1, id)
end
check(S.IndexService.Discovered(p1) >= 6 and d1.IndexRewards["25"] == true and d1.Gems > gemsBefore, "Index: marco de 25% entregue")
local gemsAfter = d1.Gems
S.IndexService.Register(p1, "leaf_ranger")
check(d1.Gems == gemsAfter, "marco não é entregue duas vezes")

------------------------------------------------------------------------------------
-- DINHEIRO OFFLINE
local now = os.time()
d1.LastLogout = now - 3600
d1.LastKnownIncomePerSecond = 100
d1.PendingOfflineReward = 0
S.EconomyService._resetOffline(p1)
S.EconomyService.CheckOffline(p1)
local OfflineCfg = req(env.shared.Config.OfflineIncomeConfig)
local expectedOffline = math.floor(100 * 3600 * OfflineCfg.Multiplier)
check(d1.PendingOfflineReward == expectedOffline, "offline: 1 h * 100/s * multiplicador = pendente")
d1.Money = 0
local okClaim, claimed = call("ClaimOfflineReward", p1)
check(okClaim and claimed == expectedOffline and d1.Money == expectedOffline and d1.PendingOfflineReward == 0, "resgatar offline entrega uma vez")
local okClaim2, codeClaim2 = call("ClaimOfflineReward", p1)
check(not okClaim2 and codeClaim2 == "nothing_to_claim" and d1.Money == expectedOffline, "resgatar de novo: nada")
d1.LastLogout = now + 99999
S.EconomyService._resetOffline(p1)
S.EconomyService.CheckOffline(p1)
check(d1.PendingOfflineReward == 0, "offline: timestamp futuro não paga")
d1.LastLogout = now - 7200
S.EconomyService._resetOffline(p1)
S.EconomyService.CheckOffline(p1)
local pending = d1.PendingOfflineReward
check(pending > 0, "fechar o popup sem resgatar: recompensa continua pendente")

------------------------------------------------------------------------------------
-- DIÁRIO
local dayNow = 20000 * 86400 + 3600
S.DailyService._now = function()
	return dayNow
end
local okSt, st = call("GetDailyStatus", p1)
check(okSt and st.canClaim and st.day == 1, "diário: Dia 1 disponível no primeiro login")
d1.Money = 0
local okDy, dy = call("ClaimDaily", p1)
check(okDy and dy.day == 1 and dy.kind == "Money" and d1.Money > 0, "diário: Dia 1 entrega dinheiro")
local spamOk = 0
for _ = 1, 10 do
	if call("ClaimDaily", p1) then
		spamOk += 1
	end
end
check(spamOk == 0, "diário: spam/mesmo dia não duplica")
dayNow += 86400
local gems = d1.Gems
local okD2y, d2y = call("ClaimDaily", p1)
check(okD2y and d2y.day == 2 and d1.Gems == gems + 25, "diário: dia seguinte = Dia 2 (gemas)")
dayNow += 86400
local okD3y, d3y = call("ClaimDaily", p1)
check(okD3y and d3y.kind == "LuckBoost" and d1.Boosts.Luck ~= nil, "diário: Dia 3 = boost de Luck")
dayNow += 86400 * 3
local okR, dr = call("ClaimDaily", p1)
check(okR and dr.day == 1 and d1.DailyStreak == 1, "diário: perdeu dias -> volta ao Dia 1")
-- Dia 7: dado exclusivo
d1.DailyCycleDay = 6
d1.LastDailyClaim = dayNow
dayNow += 86400
local ok7, d7 = call("ClaimDaily", p1)
check(ok7 and d7.day == 7 and d7.kind == "Dice" and d1.OwnedDice.Prism == true, "diário: Dia 7 = dado exclusivo Prism")

------------------------------------------------------------------------------------
-- TORRES (Fase 7)
local towerClock = 5000
S.TowerService._clock = function()
	return towerClock
end
local okTL, codeTL = call("RequestEnterTower", p1, "Storm")
check(not okTL and codeTL == "tower_locked", "torre 2 bloqueada até completar a 1ª")
local okTI, codeTI = call("RequestEnterTower", p1, "Nada")
check(not okTI and codeTI == "invalid_tower", "torre inválida recusada")
S.InventoryService.Add(p1, "eclipse_sovereign")
local moneyT = d1.Money
local okT, battle = call("RequestEnterTower", p1, "Ember")
check(okT and battle.floor == 1 and battle.won and #battle.log > 0, "andar 1 vencido com time forte (log de batalha)")
check(d1.TowerProgress.Ember == 1 and d1.Money > moneyT, "progresso salvo e dinheiro entregue")
local okTC, codeTC = call("RequestEnterTower", p1, "Ember")
check(not okTC and codeTC == "cooldown", "cooldown entre batalhas")
towerClock += 2
local okT2, battle2 = call("RequestEnterTower", p1, "Ember")
check(okT2 and battle2.floor == 2, "próxima batalha = próximo andar")
d1.TowerProgress.Ember = 30
towerClock += 2
local okTD, codeTD = call("RequestEnterTower", p1, "Ember")
check(not okTD and codeTD == "tower_complete", "torre completa não luta de novo")
towerClock += 2
check((call("RequestEnterTower", p1, "Storm")), "completar Brasas libera a Tempestade")
local okTeam, codeTeam = call("SetTowerTeam", p1, { "c999999" })
check(not okTeam and codeTeam == "not_owned", "time da torre só com personagens próprios")
local someUid = next(d1.Inventory)
check((call("SetTowerTeam", p1, { someUid, someUid })) and #d1.TowerTeam == 1, "time sem repetidos")
call("SetTowerTeam", p1, {})
-- time fraco perde e não avança
local weakData = d2
d2.Inventory = {}
d2.EquippedCharacters = {}
local okNT, codeNT = call("RequestEnterTower", p2, "Ember")
check(not okNT and codeNT == "no_team", "sem personagens: sem batalha")
S.InventoryService.Add(p2, "flame_rookie")
d2.TowerProgress.Ember = 19
towerClock += 2
local okW, lost = call("RequestEnterTower", p2, "Ember")
check(okW and lost.won == false and d2.TowerProgress.Ember == 19, "derrota não avança o andar")
local _ = weakData

------------------------------------------------------------------------------------
-- DEMO + SAÍDA
local placedDemo = S.StationService.PopulateDemo(p2, true)
local base2 = S.BaseService.GetPlayerBase(p2)
check(placedDemo == 8 and #base2.RuntimeCharacters:GetChildren() == 8, "PopulateDemoBase: 8 estações com raridades/níveis/variantes")
check(S.BaseService.Dev.PopulateDemoBase ~= nil, "atalho BaseService.Dev.PopulateDemoBase")
env.leave(p2)
check(Env.waitFor(function()
	return #base2.RuntimeCharacters:GetChildren() == 0
end), "ao sair: estações removidas")

local failures = T.finish()
process.exit(if failures > 0 then 1 else 0)
