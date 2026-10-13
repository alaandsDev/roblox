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
	"RebirthService", "FusionService", "TradeService", "MissionService",
	"BoostService", "JackpotService", "LeaderboardService",
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

do
	-- VELOCIDADE DO ROLL (servidor autoritativo, relógio simulado: nada espera de verdade)
	local RollCfg = req(env.shared.Config.RollConfig)
	check(RollCfg.RollSpeed.BaseInterval == 1 and RollCfg.RollSpeed.FastRollInterval == 0.5, "config central: 1 roll/s normal, 2 rolls/s com Roll Rápido")
	local savedCapacity = d1.Runtime.Capacity
	d1.Runtime.Capacity = 1e6 -- o teste é de cadência, não de inventário
	local existing = {}
	for uid in d1.Inventory do
		existing[uid] = true
	end
	-- Estado que os rolls do teste mexem (restaurado no fim para não afetar os testes seguintes)
	local saved = table.clone({ Index = table.clone(d1.Index), IndexRewards = table.clone(d1.IndexRewards), Rolls = d1.Rolls, Pity = table.clone(d1.Pity), Gems = d1.Gems, Money = d1.Money, Missions = d1.Missions })
	-- Janela de `seconds` com pedidos a cada `step` s (perStep pedidos juntos). Conta os aceitos
	local function window(seconds: number, step: number, perStep: number): number
		local accepted = 0
		local t0 = clock + 5 -- longe do último roll aceito
		for i = 0, math.floor(seconds / step + 0.5) - 1 do
			clock = t0 + i * step
			for _ = 1, perStep do
				if (call("RequestRoll", p1)) then
					accepted += 1
				end
			end
		end
		clock = t0 + seconds
		return accepted
	end
	local spam = window(60, 0.01, 1)
	check(spam == 60, "NORMAL: spam de clique/Remote a 100/s por 60 s = 60 rolls (veio " .. spam .. ")")
	local fps = window(60, 1 / 240, 1)
	check(fps == 60, "NORMAL: pedido a cada frame (240 FPS) = 60 rolls (veio " .. fps .. ")")
	local macro = window(60, 0.25, 4)
	check(macro <= 60, "NORMAL: macro com 4 pedidos simultâneos 4x/s: no máximo 60 (veio " .. macro .. ")")
	local fake = window(60, 0.5, 1)
	check(fake <= 60, "sem Roll Rápido tentando cadência de Roll Rápido (0,5 s): no máximo 60 (veio " .. fake .. ")")
	d1.Settings.HideRollAnimation = true
	local hidden = window(60, 0.01, 1)
	d1.Settings.HideRollAnimation = false
	check(hidden == 60, "OCULTAR não acelera: 60 rolls em 60 s (veio " .. hidden .. ")")
	-- Latência: 5 s sem nada e depois 5 pedidos de uma vez -> só 1 (sem crédito/rajada)
	clock += 10
	local burst = 0
	for _ = 1, 5 do
		if (call("RequestRoll", p1)) then
			burst += 1
		end
	end
	check(burst == 1, "atraso de 5 s não vira rajada: 5 pedidos juntos = 1 roll (veio " .. burst .. ")")
	clock += 0.999
	local early = call("RequestRoll", p1)
	clock += 0.001
	local onTime = call("RequestRoll", p1)
	check(not early and onTime, "cooldown exato no servidor: 0,999 s recusado, 1,0 s aceito (sem folga)")
	-- Roll Rápido (gamepass): 2 rolls/s, nunca mais
	d1.Runtime.FastRoll = true
	local fast = window(60, 0.01, 1)
	check(fast == 120, "ROLL RÁPIDO: spam por 60 s = 120 rolls (veio " .. fast .. ")")
	local fastMacro = window(60, 0.1, 5)
	check(fastMacro <= 120, "ROLL RÁPIDO: macro com 5 pedidos juntos 10x/s: no máximo 120 (veio " .. fastMacro .. ")")
	d1.Upgrades.RollSpeed = 11
	d1.RebirthPerks.Speed = 5
	local stacked = window(60, 0.01, 1)
	check(stacked == 120, "Roll Rápido + níveis antigos de velocidade no save: não empilha (veio " .. stacked .. ")")
	d1.Upgrades.RollSpeed = 0
	d1.RebirthPerks.Speed = nil
	d1.Runtime.FastRoll = false
	-- Limpa o que o teste criou
	local created = {}
	for uid in d1.Inventory do
		if not existing[uid] then
			table.insert(created, uid)
		end
	end
	S.InventoryService.Remove(p1, created)
	d1.Runtime.Capacity = savedCapacity
	for key, value in saved do
		d1[key] = value
	end
	clock += 5
end

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
d1.Upgrades.Inventory = 20
d1.Money = 1e15
local okUM, codeUM = call("BuyUpgrade", p1, "Inventory")
check(not okUM and codeUM == "max_level", "upgrade global no máximo: recusado")
d1.Upgrades.Inventory = 0
local moneyRS = d1.Money
local okRS, codeRS = call("BuyUpgrade", p1, "RollSpeed")
check(not okRS and codeRS == "upgrade_disabled" and d1.Money == moneyRS, "melhoria de velocidade fora da loja (velocidade fixa por config): nada é cobrado")
d1.Upgrades.RollSpeed = 11
check(Formulas:rollCooldown(d1) == 1, "nível antigo de 'Velocidade de Roll' no save não acelera o roll")
d1.Upgrades.RollSpeed = 0

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
do
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
end
do
-- RENASCIMENTO (Fase 8)
local RebirthCfg = req(env.shared.Config.RebirthConfig)
d1.Money = RebirthCfg.BaseCost - 1
local okR0, codeR0 = call("Rebirth", p1)
check(not okR0 and codeR0 == "not_enough_money", "renascer sem dinheiro: recusado")
d1.Money = RebirthCfg.BaseCost + 500
d1.Upgrades.Luck = 5
d1.Upgrades.Inventory = 3
d1.UncollectedMoney = 999
local rebirthsBefore = d1.Rebirths
local incomeBeforeR = Formulas:incomePerSecond(d1)
local okR, rb = call("Rebirth", p1)
check(okR and d1.Rebirths == rebirthsBefore + 1 and rb.tokens >= 1 and d1.RebirthTokens >= 1, "renascer: +1 renascimento e fichas")
check(d1.Money == 0 and d1.Upgrades.Luck == 0 and d1.UncollectedMoney == 0, "renascer reseta dinheiro, coletor e melhorias globais")
check(d1.Upgrades.Inventory == 3, "renascer mantém a Mochila (inventário nunca fica acima da capacidade)")
check(next(d1.Inventory) ~= nil and d1.OwnedDice.Prism == true and d1.TowerProgress.Ember ~= nil, "renascer mantém personagens, dados e torres")
local base1R = S.BaseService.GetPlayerBase(p1)
local slot5 = base1R.Floors.Floor01:FindFirstChild("Slot05", true)
check(slot5 and slot5:GetAttribute("Unlocked") == true, "renascimento 1 libera o Slot05 na base")
check((call("EquipCharacter", p1, next(d1.Inventory), 5)), "dá para equipar no slot novo")
check(Formulas:incomePerSecond(d1) > 0 and Formulas:incomeMultiplier(d1) > 1, "bônus permanente de renda ativo")
local _ = incomeBeforeR
d1.RebirthTokens = 1
check((call("BuyRebirthPerk", p1, "Luck")) and d1.RebirthPerks.Luck == 1 and d1.RebirthTokens == 0, "perk comprado com fichas")
local okP2, codeP2 = call("BuyRebirthPerk", p1, "Luck")
check(not okP2 and codeP2 == "not_enough_tokens", "perk sem fichas: recusado")

end
do
-- FUSÃO
local f1 = S.InventoryService.Add(p1, "solar_paladin")
local f2 = S.InventoryService.Add(p1, "solar_paladin")
local f3 = S.InventoryService.Add(p1, "solar_paladin")
d1.Inventory[f2].Level = 6
d1.Money = 0
local okF0, codeF0 = call("Fuse", p1, { f1, f2, f3 })
check(not okF0 and codeF0 == "not_enough_money" and d1.Inventory[f1] ~= nil, "fusão sem dinheiro: nada some")
d1.Money = 1e12
local okF, fused = call("Fuse", p1, { f1, f2, f3 })
check(okF and fused.variant == "Silver" and fused.level == 6, "fusão: 3 Normais -> 1 Prata com o maior nível")
check(d1.Inventory[f1] == nil and d1.Inventory[f2] == nil and d1.Inventory[fused.uid].Variant == "Silver", "as 3 usadas somem; a nova existe")
local okF2, codeF2 = call("Fuse", p1, { fused.uid, f1, f2 })
check(not okF2 and codeF2 == "not_owned", "fusão com uids que não existem mais: recusada")

end
do
-- TROCAS (p1 <-> p2)
local okT0, codeT0 = call("RequestTrade", p1, p1.UserId)
check(not okT0 and codeT0 == "trade_no_player", "não dá para trocar consigo mesmo")
check((call("RequestTrade", p1, p2.UserId)), "convite de troca enviado")
check(lastEvent("TradeRequest", p2) ~= nil, "o outro jogador recebe o convite")
check((call("RespondTrade", p2, p1.UserId, true)), "convite aceito: sessão aberta")
local give = S.InventoryService.Add(p1, "chrono_sage")
local take = S.InventoryService.Add(p2, "crystal_mage")
local lockedOffer = S.InventoryService.Add(p1, "chrono_sage")
call("SetCharacterFlag", p1, lockedOffer, "Locked", true)
local okLO, codeLO = call("SetTradeOffer", p1, { lockedOffer })
check(not okLO and codeLO == "locked", "personagem travado não pode ser oferecido")
check((call("SetTradeOffer", p1, { give })) and (call("SetTradeOffer", p2, { take })), "ofertas definidas")
local okCN, codeCN = call("ConfirmTrade", p1)
check(not okCN and codeCN == "trade_not_ready", "confirmar antes dos dois PRONTOS: recusado")
call("SetTradeReady", p1, true)
call("SetTradeReady", p2, true)
local okC1, w1 = call("ConfirmTrade", p1)
check(okC1 and w1 == "waiting", "1º confirmou: espera o outro")
-- mudar a oferta depois de confirmar invalida tudo
call("SetTradeOffer", p2, { take })
local okC2, codeC2 = call("ConfirmTrade", p2)
check(not okC2 and codeC2 == "trade_not_ready", "mudar a oferta tira o PRONTO dos dois")
call("SetTradeReady", p1, true)
call("SetTradeReady", p2, true)
call("ConfirmTrade", p1)
local okDone, done = call("ConfirmTrade", p2)
check(okDone and done == "completed", "os dois confirmaram: troca concluída")
local p1HasCrystal, p2HasChrono = false, false
for _, item in d1.Inventory do
	if item.Id == "crystal_mage" then
		p1HasCrystal = true
	end
end
for _, item in d2.Inventory do
	if item.Id == "chrono_sage" then
		p2HasChrono = true
	end
end
check(d1.Inventory[give] == nil and d2.Inventory[take] == nil and p1HasCrystal and p2HasChrono, "itens trocaram de dono")
check(d2.Index.chrono_sage ~= nil, "personagem recebido entra no Índice")
check(S.TradeService.SessionOf(p1) == nil and S.TradeService.SessionOf(p2) == nil, "sessão encerrada")
local okNS, codeNS = call("ConfirmTrade", p1)
check(not okNS and codeNS == "trade_no_session", "confirmar de novo (spam): nada acontece")

end

do
-- TUTORIAL: só avança
d2.Tutorial = 0
local okT1, t1 = call("SetTutorialStep", p2, 3)
local okT2, t2 = call("SetTutorialStep", p2, 1)
check(okT1 and t1 == 3 and okT2 and t2 == 3 and d2.Tutorial == 3, "tutorial: avança, nunca volta")
call("SetTutorialStep", p2, 99)
check(d2.Tutorial == 7, "tutorial: passo acima do total vira 'terminado'")
end

do
-- AUDITORIA: casos de borda da TROCA
check((call("RequestTrade", p1, p2.UserId)) and (call("RespondTrade", p2, p1.UserId, true)), "borda: nova sessão de troca")
local x = S.InventoryService.Add(p1, "chrono_sage")
local z = S.InventoryService.Add(p1, "crystal_mage")
check((call("SetTradeOffer", p1, { x })), "borda: item X oferecido")
local okS, codeS = call("SellCharacter", p1, { x })
check(not okS and codeS == "in_trade" and d1.Inventory[x] ~= nil, "item em troca não pode ser vendido")
call("SellBatch", p1, "Rarity:Divine", true)
check(d1.Inventory[x] ~= nil, "venda em lote pula o item em troca")
local okE, codeE = call("EquipCharacter", p1, x)
check(not okE and codeE == "in_trade", "item em troca não pode ser equipado")
call("EquipBest", p1)
check((function()
	for _, uid in d1.EquippedCharacters do
		if uid == x then
			return false
		end
	end
	return true
end)(), "EQUIPAR MELHORES ignora item em troca")
call("UnequipCharacter", p1, d1.EquippedCharacters["1"]) -- deixa um slot livre para os testes abaixo
local fx1 = S.InventoryService.Add(p1, "chrono_sage")
local fx2 = S.InventoryService.Add(p1, "chrono_sage")
local okFu, codeFu = call("Fuse", p1, { x, fx1, fx2 })
check(not okFu and codeFu == "in_trade" and d1.Inventory[x] ~= nil, "item em troca não pode ser fundido")
local okNO, codeNO = call("SetTradeOffer", p2, { x })
check(not okNO and codeNO == "not_owned", "oferecer item do OUTRO jogador: recusado")
local y = S.InventoryService.Add(p2, "crystal_mage")
local okDu, codeDu = call("SetTradeOffer", p2, { y, y })
check(not okDu and codeDu == "trade_duplicate", "mesmo item duas vezes na oferta: recusado")
local many = {}
for _ = 1, S.TradeService.MaxItems + 1 do
	table.insert(many, S.InventoryService.Add(p2, "flame_rookie"))
end
local okMany, codeMany = call("SetTradeOffer", p2, many)
check(not okMany and codeMany == "trade_too_many", "oferta acima do limite: recusada")
S.InventoryService.Remove(p2, many)
check((call("SetTradeOffer", p2, { y })), "p2 oferece Y")
-- trocar a oferta libera o item antigo
check((call("SetTradeOffer", p1, { z })), "p1 troca X por Z na oferta")
local okEX, slotX = call("EquipCharacter", p1, x)
check(okEX and slotX ~= nil, "item que saiu da oferta volta a ser equipável")
call("UnequipCharacter", p1, x)
-- item some durante a troca (ex.: removido pelo servidor): confirmação falha sem mover nada
call("SetTradeReady", p1, true)
call("SetTradeReady", p2, true)
local okW1 = call("ConfirmTrade", p1)
local okW2 = call("ConfirmTrade", p1)
check(okW1 and okW2 and d1.Inventory[z] ~= nil, "confirmar duas vezes sozinho (spam): só espera o outro")
d2.Inventory[y] = nil
local countA, countB = 0, 0
for _ in d1.Inventory do
	countA += 1
end
local okGone, codeGone = call("ConfirmTrade", p2)
for _ in d1.Inventory do
	countB += 1
end
check(not okGone and codeGone == "not_owned" and d1.Inventory[z] ~= nil and countA == countB, "item sumiu antes do commit: troca recusada, nada muda")
local okRe, codeRe = call("ConfirmTrade", p1)
check(not okRe and codeRe == "trade_not_ready", "depois da falha os dois precisam ficar PRONTOS de novo")
-- terceiro jogador: não dá para abrir duas trocas
local p3 = env.newPlayer("terceiro")
env.join(p3)
check(Env.waitFor(function()
	return p3:GetAttribute("BaseId") ~= nil
end), "3º jogador entrou")
local okBusy, codeBusy = call("RequestTrade", p3, p1.UserId)
check(not okBusy and codeBusy == "trade_busy", "jogador já em troca não recebe outra")
call("CancelTrade", p2)
check(S.TradeService.SessionOf(p1) == nil and S.TradeService.SessionOf(p2) == nil, "cancelar fecha para os dois")
local okFree = call("EquipCharacter", p1, z)
check(okFree, "troca cancelada: itens oferecidos ficam livres")
call("UnequipCharacter", p1, z)
-- sair no meio da troca
check((call("RequestTrade", p3, p1.UserId)) and (call("RespondTrade", p1, p3.UserId, true)), "p1 <-> p3 em troca")
call("SetTradeOffer", p1, { z })
env.leave(p3)
check(S.TradeService.SessionOf(p1) == nil and lastEvent("TradeClosed", p1) ~= nil and lastEvent("TradeClosed", p1).args[1] == "left", "o outro saiu: troca encerrada com aviso")
check(d1.Inventory[z] ~= nil and (call("EquipCharacter", p1, z)), "quem ficou mantém o item e ele fica livre")
call("UnequipCharacter", p1, z)
local okLeft, codeLeft = call("RespondTrade", p1, p3.UserId, true)
check(not okLeft and codeLeft == "trade_no_request", "aceitar convite de quem saiu: nada")
end

do
-- AUDITORIA: casos de borda da FUSÃO, RENASCIMENTO e TORRE
local a1 = S.InventoryService.Add(p1, "solar_paladin")
local a2 = S.InventoryService.Add(p1, "solar_paladin")
local a3 = S.InventoryService.Add(p1, "solar_paladin")
local other = S.InventoryService.Add(p1, "chrono_sage")
d1.Money = 1e12
local okR, codeR = call("Fuse", p1, { a1, a1, a1 })
check(not okR and codeR == "fusion_count", "fusão com o mesmo uid repetido: recusada")
local okI, codeI = call("Fuse", p1, { a1, a2, "c999999" })
check(not okI and codeI == "not_owned", "fusão com uid inexistente: recusada")
local okM, codeM = call("Fuse", p1, { a1, a2, other })
check(not okM and codeM == "fusion_mismatch", "fusão com personagens diferentes: recusada")
call("SetCharacterFlag", p1, a3, "Favorite", true)
local okFav, codeFav = call("Fuse", p1, { a1, a2, a3 })
check(not okFav and codeFav == "favorite", "fusão com favorito: recusada")
call("SetCharacterFlag", p1, a3, "Favorite", false)
call("EquipCharacter", p1, a3)
local okEq, codeEq = call("Fuse", p1, { a1, a2, a3 })
check(not okEq and codeEq == "equipped", "fusão com personagem na base: recusada")
call("UnequipCharacter", p1, a3)
local okBad, codeBad = call("Fuse", p1, { 1, {}, "x" })
check(not okBad, "fusão com tipos inválidos: recusada")
local okOne = call("Fuse", p1, { a1, a2, a3 })
local okTwo, codeTwo = call("Fuse", p1, { a1, a2, a3 })
check(okOne and not okTwo and codeTwo == "not_owned", "fusão repetida (spam): só a primeira vale")
-- Renascimento: spam com dinheiro para só 1
local cost = Formulas:rebirthCost(d1.Rebirths)
d1.Money = cost
local before = d1.Rebirths
local okRb1 = call("Rebirth", p1)
local okRb2, codeRb2 = call("Rebirth", p1)
check(okRb1 and not okRb2 and codeRb2 == "not_enough_money" and d1.Rebirths == before + 1, "renascer 2x seguidas: só 1 vale")
-- Torre: id inválido e torre bloqueada
local okTv, codeTv = call("RequestEnterTower", p1, "NaoExiste")
check(not okTv and codeTv == "invalid_tower", "torre inexistente: recusada")
local okTl, codeTl = call("RequestEnterTower", p1, "Void")
check(not okTl and codeTl == "tower_locked", "torre ainda bloqueada: recusada")
end

do
-- MISSÕES (Fase 9)
check(type(d1.Missions.Daily) == "table" and next(d1.Missions.Daily) ~= nil, "missões diárias sorteadas ao entrar")
d1.Missions.Daily = { roll_50 = { Progress = 49, Claimed = false }, tower_3 = { Progress = 0, Claimed = false } }
local okInc, codeInc = call("ClaimMission", p1, "Daily", "tower_3")
check(not okInc and codeInc == "mission_incomplete", "missão incompleta não paga")
S.AnalyticsService.Track(p1, "Roll", { rarity = "Common" })
check(Env.waitFor(function()
	return d1.Missions.Daily.roll_50.Progress == 50
end, 1), "evento do jogo avança a missão")
local moneyM = d1.Money
local okM, given = call("ClaimMission", p1, "Daily", "roll_50")
check(okM and given.kind == "Money" and d1.Money > moneyM, "missão completa: recompensa entregue")
local okM2, codeM2 = call("ClaimMission", p1, "Daily", "roll_50")
check(not okM2 and codeM2 == "already_claimed", "resgatar de novo: nada")
local okBad, codeBad = call("ClaimMission", p1, "Daily", "nao_existe")
check(not okBad and codeBad == "mission_invalid", "missão que não é sua: recusada")
d1.Rolls = 150
local gemsA = d1.Gems
local okA, ach = call("ClaimMission", p1, "Achievement", "rolls")
check(okA and ach.kind == "Gems" and d1.Gems == gemsA + 25 and d1.Missions.Achievements.rolls == 1, "conquista nível 1 (100 rolls)")
local okA2, codeA2 = call("ClaimMission", p1, "Achievement", "rolls")
check(not okA2 and codeA2 == "mission_incomplete", "próximo nível exige 1000 rolls")
S.MissionService._now = function()
	return os.time() + 86400
end
S.AnalyticsService.Track(p1, "Roll", {})
check(Env.waitFor(function()
	return d1.Missions.Day == math.floor((os.time() + 86400) / 86400)
end, 1), "virada do dia: novas diárias, conquistas mantidas")
check(d1.Missions.Achievements.rolls == 1, "conquista resgatada continua registrada")
end

do
-- MONETIZAÇÃO (Fase 10)
local okNC, codeNC = call("RequestPurchase", p1, "VIP")
check(not okNC and codeNC == "not_configured", "gamepass sem ID: recusado com aviso")
d1.Gems = 10
local okJ0, codeJ0 = call("SpinJackpot", p1)
check(not okJ0 and codeJ0 == "not_enough_gems" and d1.Gems == 10, "Jackpot sem gemas: recusado")
d1.Gems = 1000
S.JackpotService._rand = function()
	return 0
end
local okJm, prizeM = call("SpinJackpot", p1)
check(okJm and prizeM.kind == "Money" and d1.Gems == 850, "Jackpot: gasta 150 gemas e entrega o prêmio")
S.JackpotService._rand = function()
	return 0.99999
end
local invCount = 0
for _ in d1.Inventory do
	invCount += 1
end
local okJ, prize = call("SpinJackpot", p1)
check(okJ and prize.kind == "Roll" and prize.roll ~= nil, "Jackpot: prêmio personagem garantido")
local tiers = { Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 5, Mythic = 6, Divine = 7, Secret = 8 }
check(okJ and tiers[prize.roll.Rarity] >= 6, "prêmio Mítico+ respeita a raridade mínima")
local invAfter = 0
for _ in d1.Inventory do
	invAfter += 1
end
check(invAfter == invCount + 1, "personagem do prêmio vai para a mochila")
check(lastEvent("JackpotResult", p1) ~= nil, "cliente recebe o resultado do giro")
local okG, gemItem = call("BuyGemItem", p1, "LuckBoost")
check(okG and gemItem.kind == "LuckBoost" and d1.Boosts.Luck.Multiplier >= 2, "loja de gemas: boost de sorte")
local okGI, codeGI = call("BuyGemItem", p1, "Nada")
check(not okGI and codeGI == "invalid_item", "item inválido na loja de gemas")
local incomeNoVip = Formulas:incomePerSecond(d1)
local capNoPass = Formulas:capacity(d1)
S.MonetizationService.Dev.GrantPass(p1, "VIP")
S.MonetizationService.Dev.GrantPass(p1, "BigBackpack")
check(Env.waitFor(function()
	return d1.Runtime.Income and d1.Runtime.Income >= 1.5
end, 1), "VIP aplica renda x1.5 (Runtime)")
check(Formulas:incomePerSecond(d1) > incomeNoVip * 1.4, "renda com VIP maior")
check(Formulas:capacity(d1) == capNoPass + 100, "Mochila Gigante: +100 espaços")
check(d1.Runtime.Passes.VIP == true, "loja sabe que o VIP foi comprado")
local moneyP = d1.Money
check(S.MonetizationService.Dev.DeliverProduct(p1, "MoneySmall") and d1.Money >= moneyP + 10000, "produto Pacote de Dinheiro entregue")
local gemsP = d1.Gems
check(S.MonetizationService.Dev.DeliverProduct(p1, "Gems500") and d1.Gems == gemsP + 500, "produto 500 gemas entregue")
-- Impulso de amigos
function p1:IsFriendsWith(userId)
	return userId == p2.UserId
end
S.BoostService.ClearFriendCache(p1)
S.BoostService.Refresh(p1)
check(d1.Runtime.Friends == 1 and math.abs(d1.Runtime.FriendBonus - 0.05) < 1e-9, "impulso de amigos: +5% com 1 amigo no servidor")
-- Runtime salvo nunca é confiado
d1.Runtime = { Income = 999 }
S.BoostService.Refresh(p1)
check(d1.Runtime.Income < 999, "Runtime é recalculado (valor salvo ignorado)")
end

do
-- RANKINGS (Fase 11)
S.LeaderboardService.Refresh()
local top = S.LeaderboardService.LocalTop("Rolls")
check(#top >= 1 and top[1].value >= top[#top].value, "ranking local ordenado")
local panel = env.real.Workspace.Map:FindFirstChild("Panel3", true)
local filled = false
for _, d in panel.Sign:GetDescendants() do
	if d:IsA("TextLabel") and string.find(d.Text, "1. ", 1, true) == 1 and d.Text ~= "1. —" then
		filled = true
	end
end
check(filled, "painel MAIS ROLLS do Hub preenchido")
end

------------------------------------------------------------------------------------
do
-- PILOTOS DO PIPELINE DE PERSONAGENS (assets sanitizados de um pack sintético, sem o pack no jogo)
local SyntheticPack = require("./SyntheticPack")
local Pipeline = req(env.shared.Modules.CharacterAssetPipeline)
local Factory = req(env.shared.Modules.CharacterModelFactory)
local CharacterConfig = req(env.shared.Config.CharacterConfig)
local pack = SyntheticPack.build()
local assets = Pipeline.buildAll(pack)
pack:Destroy()
assets.Parent = env.real.ReplicatedStorage
Factory.clearCache()
check(#CharacterConfig.List == 24 and CharacterConfig.Count == 24 and #CharacterConfig.Pilots >= 8, "roster do roll intacto (24); pilotos só em ById/Pilots")
for _, pilot in CharacterConfig.Pilots do
	local inList = false
	for _, c in CharacterConfig.List do
		inList = inList or c.Id == pilot.Id
	end
	assert(not inList)
end

-- Inventário guarda só o CharacterId (nada de Instance no save)
local pid = S.InventoryService.Add(p1, "char_ichiro_base")
local item = d1.Inventory[pid]
local onlyData = item.Id == "char_ichiro_base"
for _, value in item do
	onlyData = onlyData and (type(value) == "string" or type(value) == "number" or type(value) == "boolean" or type(value) == "nil")
end
check(onlyData, "inventário: piloto guardado como CharacterId (sem modelo/instância)")

-- Base: piloto no pedestal blocky (pés no topo, virado, nome/raridade/variante/renda/nível)
for _, uid in table.clone(d1.EquippedCharacters) do
	pcall(S.InventoryService.Unequip, p1, uid)
end
local okEq, slot = call("EquipCharacter", p1, pid, 1)
local base = S.BaseService.GetPlayerBase(p1)
local station = base and base.RuntimeCharacters:FindFirstChild("Station_" .. tostring(slot))
local figure = station and station:FindFirstChild("char_ichiro_base")
local point = base and base:FindFirstChild(string.format("Slot%02d", slot or 0), true)
point = point and point:FindFirstChild("CharacterPoint")
check(okEq and figure ~= nil and figure:GetAttribute("AssetRig") == true, "base: estação do piloto usa o asset sanitizado")
if figure and point then
	local legMin = Pipeline.boundsOf({ figure:FindFirstChild("Left Leg"), figure:FindFirstChild("Right Leg") }, point.CFrame)
	local torso = figure:FindFirstChild("Torso")
	local localTorso = point.CFrame:PointToObjectSpace(torso.CFrame.Position)
	check(math.abs(legMin.Y) < 0.05, string.format("base: pés no topo do pedestal (%.3f), sem flutuar nem atravessar", legMin.Y))
	check(math.abs(localTorso.X) < 0.05 and math.abs(localTorso.Z) < 0.1 and torso.CFrame.LookVector:Dot(point.CFrame.LookVector) > 0.99, "base: centralizado no pedestal e virado como o slot")
	check(figure:GetAttribute("VFXMode") == "Light" and figure:GetAttribute("Variant") == "Normal", "base: VFX Light, variante Normal")
	local detail = station.InfoAnchor.Info.Detail
	check(detail.Title.Text == "Ichiro" and detail.Rarity.Text ~= "" and detail.Level.Text ~= "" and string.find(station.InfoAnchor.Info.Income.Text, "/s", 1, true) ~= nil, "base: nome (DisplayName), raridade, nível e renda no billboard")
	local physics = 0
	for _, part in figure:GetDescendants() do
		if part:IsA("BasePart") and (part.CanCollide or part.CanTouch or not part.Anchored) then
			physics += 1
		end
		if part:IsA("LuaSourceContainer") or part:IsA("Humanoid") and #part:GetChildren() > 0 then
			physics += 1
		end
	end
	check(physics == 0, "base: zero script, zero física no personagem")
end
-- Trocar o personagem do slot substitui o visual antigo
local pid2 = S.InventoryService.Add(p1, "char_killuo_godspeed", "Gold")
local okSwap = call("EquipCharacter", p1, pid2, slot)
if not okSwap then
	S.InventoryService.Unequip(p1, pid)
	okSwap = call("EquipCharacter", p1, pid2, slot)
end
local swapped = base.RuntimeCharacters:FindFirstChild("Station_" .. tostring(slot))
check(okSwap and swapped ~= nil and swapped:FindFirstChild("char_ichiro_base") == nil and swapped:FindFirstChild("char_killuo_godspeed") ~= nil, "trocar personagem do slot: visual antigo destruído, novo no lugar")
check(swapped and swapped.char_killuo_godspeed:GetAttribute("Variant") == "Gold" and swapped.char_killuo_godspeed:FindFirstChild("VariantRing") ~= nil and swapped.InfoAnchor.Info.Detail.Variant.Text ~= "", "base: variante Gold aparece (anel + texto)")
local stations = 0
for _, child in base.RuntimeCharacters:GetChildren() do
	if child:GetAttribute("Slot") == slot or child.Name == "Station_" .. tostring(slot) then
		stations += 1
	end
end
check(stations == 1, "um único modelo por slot (sem clone acumulado)")

-- Índice: piloto registrado com variante, sem mexer no progresso do roster
local discovered = S.IndexService.Discovered(p1)
S.IndexService.Register(p1, "char_sacha_base", "Normal")
check(S.IndexService.Discovered(p1) == discovered and d1.Index.char_sacha_base ~= nil and d1.Index.char_sacha_base.Variants.Normal == true, "índice: piloto descoberto (com variante) sem contar no progresso")

-- Fusão pelo CharacterId: 3 Normal -> Silver, 3 Silver -> Gold (mesma regra/economia)
d1.Money = 1e12
local n1, n2, n3 = S.InventoryService.Add(p1, "char_sacha_base"), S.InventoryService.Add(p1, "char_sacha_base"), S.InventoryService.Add(p1, "char_sacha_base")
local okFS, fusedS = call("Fuse", p1, { n1, n2, n3 })
check(okFS and fusedS.characterId == "char_sacha_base" and fusedS.variant == "Silver", "fusão do piloto: 3 Normal -> Silver")
local s1, s2 = S.InventoryService.Add(p1, "char_sacha_base", "Silver"), S.InventoryService.Add(p1, "char_sacha_base", "Silver")
local okFG, fusedG = call("Fuse", p1, { fusedS.uid, s1, s2 })
check(okFG and fusedG.variant == "Gold" and d1.Inventory[fusedG.uid].Id == "char_sacha_base", "fusão do piloto: 3 Silver -> Gold")
check(d1.Index.char_sacha_base.Variants.Silver == true and d1.Index.char_sacha_base.Variants.Gold == true and d1.Index.char_sacha_base.Count == 1, "índice: variantes Silver/Gold descobertas pela fusão (Count intacto)")

-- Torres: piloto no time, combate do Roll Legends (stats do config, nenhum script do pack)
S.TowerService._clock = function()
	return 9e9
end
local tid = S.InventoryService.Add(p1, "char_goju_base")
check((call("SetTowerTeam", p1, { tid })), "torres: piloto aceito no time")
local okTP, battleP = call("RequestEnterTower", p1, "Storm")
check(okTP and battleP and #battleP.log > 0, "torres: batalha com o piloto roda no sistema atual")
call("SetTowerTeam", p1, {})

-- Ferramentas DEV: galeria, variantes, poses, relatório e prova de independência do pack
local Dev = req(env.server.Services.DevService)
local function galleryModels()
	local gallery = env.real.Workspace:FindFirstChild("DevGallery")
	local models = {}
	for _, child in (if gallery then gallery:GetChildren() else {}) do
		if child:IsA("Model") then
			table.insert(models, child)
		end
	end
	return models
end
local resultG = Dev.Run("CharacterGallery", p1)
local models = galleryModels()
local allAssets = #models == #CharacterConfig.Pilots
for _, model in models do
	allAssets = allAssets and model:GetAttribute("AssetRig") == true
end
check(allAssets, "DEV CharacterGallery: " .. tostring(resultG) .. " (todos do asset sanitizado)")
Dev.Run("ShowCharacterVariants", p1, "char_ichiro_base")
local variantsSeen = {}
for _, model in galleryModels() do
	variantsSeen[model:GetAttribute("Variant")] = true
end
local seven = 0
for _ in variantsSeen do
	seven += 1
end
check(#galleryModels() == 7 and seven == 7, "DEV ShowCharacterVariants: as 7 variantes lado a lado (galeria anterior substituída)")
Dev.Run("ShowCharacterPoses", p1, "char_zabuzo_base")
check(#galleryModels() == 5, "DEV ShowCharacterPoses: 5 poses")
local report = Dev.Run("CharacterAssetReport")
local okCount = 0
for _ in string.gmatch(report, ": OK") do
	okCount += 1
end
check(string.find(report, "10 assets", 1, true) ~= nil and okCount >= 8, "DEV CharacterAssetReport: assets validados no runtime")
local packCheck = Dev.Run("SourcePackCheck")
check(string.find(packCheck, "10/10 montados sem o pack", 1, true) ~= nil and string.find(packCheck, "10 do asset sanitizado", 1, true) ~= nil and string.find(packCheck, "problemas: nenhum", 1, true) ~= nil, "DEV SourcePackCheck: " .. packCheck)
local gave = Dev.Run("GivePilots", p1)
check(gave == "10 pilotos adicionados" and d1.Index.char_goju_base ~= nil, "DEV GivePilots: 1 de cada no inventário e no índice")
Dev.Run("ClearGallery")
check(env.real.Workspace:FindFirstChild("DevGallery") == nil, "DEV ClearGallery limpa tudo")

end

do
-- Interface da Barra de comandos: ServerStorage.RollLegendsDev (BindableFunction), só no Studio
local Dev = req(env.server.Services.DevService)
local function galleryModels()
	local gallery = env.real.Workspace:FindFirstChild("DevGallery")
	local models = {}
	for _, child in (if gallery then gallery:GetChildren() else {}) do
		if child:IsA("Model") then
			table.insert(models, child)
		end
	end
	return models
end
local storage = env.real.ServerStorage
env.stubs.RunService.IsStudio = function()
	return false
end
Dev.Init()
check(storage:FindFirstChild("RollLegendsDev") == nil, "produção (fora do Studio): interface DEV NÃO é criada")
env.stubs.RunService.IsStudio = function()
	return true
end
local okInit, errInit = pcall(Dev.Init)
local bindable = storage:FindFirstChild("RollLegendsDev")
check(okInit and bindable ~= nil and bindable:IsA("BindableFunction"), "Studio: ServerStorage.RollLegendsDev (BindableFunction) criada " .. tostring(errInit or ""))
local help = Dev.Run("Help")
check(string.find(help, 'RollLegendsDev:Invoke("Comando"', 1, true) ~= nil and string.find(help, "CharacterGallery", 1, true) ~= nil, "Help explica o uso pela Barra de comandos")
-- Mesmo formato que o usuário cola: sem o jogador no 1º argumento
local noPlayer = {
	{ "SourcePackCheck" },
	{ "CharacterAssetReport" },
	{ "CharacterGallery" },
	{ "GivePilots" },
	{ "ShowCharacterVariants", "char_ichiro_base" },
	{ "ShowCharacterPoses", "char_zabuzo_base" },
}
for _, call_ in noPlayer do
	-- Exatamente o que se cola na Barra de comandos (servidor)
	local result = bindable and bindable:Invoke(table.unpack(call_))
	local ok = type(result) == "string" and string.sub(result, 1, 5) ~= "erro:" and string.find(result, "desconhecido", 1, true) == nil
	check(ok, `Invoke("{table.concat(call_, '", "')}") sem jogador: {string.sub(tostring(result), 1, 70)}`)
end
local shown = galleryModels()
check(#shown == 5 and shown[1].Name == "char_zabuzo_base", "ShowCharacterPoses aceitou o CharacterId direto (5 poses do Zabuzo no Workspace)")
Dev.Run("ShowCharacterVariants", "char_ichiro_base")
check(#galleryModels() == 7 and galleryModels()[1].Name == "char_ichiro_base", "ShowCharacterVariants aceitou o CharacterId direto (7 variantes)")
Dev.Run("CharacterGallery")
check(#galleryModels() == 10 and env.real.Workspace:FindFirstChild("DevGallery") ~= nil, "CharacterGallery cria a galeria no Workspace (não abre o Índice)")
-- ClothingCheck: id de ITEM da loja (Shirt/Pants) vira a IMAGEM certa (HumanoidDescription)
env.stubs.MarketplaceService.GetProductInfo = function(_, id)
	return { AssetTypeId = if id == 2065247269 then 11 elseif id == 2065252088 then 12 else 1 }
end
env.stubs.ContentProvider = {
	PreloadAsync = function(_, list, callback)
		for _, item in list do
			callback(tostring(item), roblox.Enum.AssetFetchStatus.Success)
		end
	end,
}
env.Players.CreateHumanoidModelFromDescription = function(_, description)
	local dummy = Instance.new("Model")
	local shirt = Instance.new("Shirt")
	shirt.ShirtTemplate = "rbxassetid://" .. tostring(description.Shirt - 1)
	shirt.Parent = dummy
	local pants = Instance.new("Pants")
	pants.PantsTemplate = "rbxassetid://" .. tostring(description.Pants - 1)
	pants.Parent = dummy
	return dummy
end
local clothingReport = bindable:Invoke("ClothingCheck", "char_killuo_base")
check(string.find(clothingReport, "Shirt 2065247269 = Shirt", 1, true) ~= nil and string.find(clothingReport, '["2065247269"] = "rbxassetid://2065247268"', 1, true) ~= nil and string.find(clothingReport, '["2065252088"] = "rbxassetid://2065252087"', 1, true) ~= nil, "ClothingCheck: detecta item da loja e imprime a linha de override com a imagem")
local okReport = bindable:Invoke("ClothingCheck", "char_sacha_base")
check(string.find(okReport, "= Image", 1, true) ~= nil and string.find(okReport, "Cole em", 1, true) == nil, "ClothingCheck: template que já é imagem fica OK (sem override)")
check(bindable:Invoke("ShowCharacterVariants", p1, "char_goko_base") ~= nil and #galleryModels() == 7, "formato antigo (jogador primeiro) continua funcionando")
Dev.Run("ClearGallery")
end

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
