--[[
	Teste de PONTA A PONTA (Lune): Services REAIS do servidor + Controllers REAIS do cliente,
	em contextos de require separados, ligados por um Net falso que serializa (copia) os dados
	como a rede de verdade. Simula RenderStepped a ~60 FPS e cliques (Activated).

	Pega erros de execução da interface que o luau-lsp não vê: HUD, ROLAR, reveal normal,
	compacto e cinemática Hero Landing (limpeza!), janelas (MOCHILA, LOJA, MELHORIAS, VENDER,
	ÍNDICE, DIÁRIO, OFFLINE, CONFIGURAÇÕES), notificações agrupadas, LOD e feedback.
]]

local process = require("@lune/process")
local task = require("@lune/task")
local roblox = require("@lune/roblox")
local Env = require("./Env")

local Instance = roblox.Instance

local env = Env.create()
local T = Env.checker("Ponta a ponta: servidor + interface do cliente")
local check = T.check

------------------------------------------------------------------------------------
-- Rede falsa (servidor <-> cliente) com cópia dos dados, como a serialização real

local function copy(value, seen)
	if type(value) ~= "table" then
		return value
	end
	seen = seen or {}
	if seen[value] then
		return seen[value]
	end
	local out = {}
	seen[value] = out
	for k, v in value do
		out[copy(k, seen)] = copy(v, seen)
	end
	return out
end

local handlers = {}
local listeners = {}
local localPlayer
local fired = {}
local Net = {
	Codes = { RateLimited = "rate_limited", InvalidArgs = "invalid_args", NotReady = "not_ready", NotImplemented = "not_implemented", Internal = "internal" },
	initServer = function() end,
	handle = function(name, fn)
		handlers[name] = fn
	end,
	fail = function(code)
		error({ __netFail = true, code = code }, 0)
	end,
	fire = function(name, player, ...)
		fired[name] = (fired[name] or 0) + 1
		if player ~= localPlayer then
			return
		end
		local args = copy({ ... })
		for _, fn in listeners[name] or {} do
			task.spawn(Env.protect(fn), table.unpack(args))
		end
	end,
	fireAll = function() end,
	request = function(name, ...)
		local handler = handlers[name]
		if not handler then
			return { ok = false, code = "not_implemented" }
		end
		local args = copy({ ... })
		local ok, result = pcall(handler, localPlayer, table.unpack(args))
		if ok then
			return { ok = true, data = copy(result) }
		end
		if type(result) == "table" and result.__netFail then
			return { ok = false, code = result.code }
		end
		Env.record("handler " .. name .. ": " .. tostring(result))
		return { ok = false, code = "internal" }
	end,
	on = function(name, fn)
		listeners[name] = listeners[name] or {}
		table.insert(listeners[name], fn)
		return { Disconnect = function() end, Connected = true }
	end,
}
local overrides = { [env.shared.Modules.Net:GetFullName()] = Net }

------------------------------------------------------------------------------------
-- Stubs do cliente

local renderStepped = Env.signal()
env.stubs.RunService.RenderStepped = renderStepped
env.stubs.UserInputService = { TouchEnabled = false, KeyboardEnabled = true, InputBegan = Env.signal() }
env.stubs.SoundService = env.game:GetService("SoundService")
local camera = Instance.new("Camera")
camera.ViewportSize = roblox.Vector2.new(1280, 720)
camera.Parent = env.real.Workspace
pcall(function()
	env.real.Workspace.CurrentCamera = camera
end)
pcall(roblox.implementProperty, "Workspace", "CurrentCamera", function()
	return camera
end)

-- task protegido: erro em task.spawn/delay/defer do cliente vira falha do teste
local safeTask = setmetatable({}, { __index = task })
for _, name in { "spawn", "defer", "delay" } do
	safeTask[name] = function(...)
		local args = table.pack(...)
		local fnIndex = if name == "delay" then 2 else 1
		if type(args[fnIndex]) == "function" then
			args[fnIndex] = Env.protect(args[fnIndex])
		end
		return task[name](table.unpack(args, 1, args.n))
	end
end
-- warn do cliente: "[ERRO]" do Logger também conta como falha
local function clientWarn(...)
	local parts = table.pack(...)
	for i = 1, parts.n do
		parts[i] = tostring(parts[i])
	end
	local text = table.concat(parts, " ")
	print("[warn]", text)
	if string.find(text, "[ERRO]", 1, true) or string.find(text, "falhou", 1, true) or string.find(text, "erro", 1, true) then
		Env.record(text)
	end
end

------------------------------------------------------------------------------------
-- Servidor

local serverRequire = env.newContext(overrides)
local Services = env.server.Services
local ORDER = {
	"PlayerDataService", "MonetizationService", "MapService", "BaseService", "AnalyticsService",
	"EconomyService", "InventoryService", "IndexService", "SellService", "RollService",
	"DiceService", "UpgradeService", "StationService", "DailyService", "TowerService",
	"RebirthService", "FusionService", "TradeService", "MissionService",
}
local S = {}
for _, name in ORDER do
	S[name] = serverRequire(Services[name])
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

local player = env.newPlayer("alandias123")
localPlayer = player
local playerGui = Instance.new("Folder")
playerGui.Name = "PlayerGui"
player.PlayerGui = playerGui
player.CharacterRemoving = Env.signal()
function player:WaitForChild(name)
	return self[name]
end
function player:FindFirstChild(name)
	return self[name]
end
env.Players.LocalPlayer = player
env.join(player)
check(Env.waitFor(function()
	return S.PlayerDataService.IsLoaded(player) and player:GetAttribute("BaseId") ~= nil
end), "jogador carregado com base")

------------------------------------------------------------------------------------
-- Cliente (mesma ordem do Bootstrap.client)

local clientRequire = env.newContext(overrides, { task = safeTask, warn = clientWarn })
local ClientControllers = env.client.Controllers
local CLIENT_ORDER = {
	"NotificationController", "DataController", "HudController", "NavigationController", "AmbientController",
	"RevealController", "RollController", "InventoryController", "DiceShopController", "UpgradesController",
	"SellController", "IndexController", "DailyController", "OfflineController", "SettingsController", "TowerController",
	"RebirthController", "FusionController", "TradeController", "MissionController",
	"FeedbackController", "LodController",
}
local C = {}
for _, name in CLIENT_ORDER do
	local ok, controller = pcall(clientRequire, ClientControllers[name])
	check(ok, "require " .. name .. (if ok then "" else ": " .. tostring(controller)))
	C[name] = if ok then controller else {}
end
for _, name in CLIENT_ORDER do
	if C[name].Init then
		local ok, err = pcall(C[name].Init)
		if not ok then
			Env.record(name .. ".Init: " .. tostring(err))
		end
	end
end
for _, name in CLIENT_ORDER do
	if C[name].Start then
		task.spawn(Env.protect(C[name].Start))
	end
end

-- ~60 FPS
local running = true
task.spawn(function()
	while running do
		renderStepped:Fire(1 / 60)
		task.wait(1 / 60)
	end
end)

local UIKit = clientRequire(env.client.UI.UIKit)
local DataController = C.DataController
check(Env.waitFor(function()
	return DataController.IsReady()
end, 5), "DataController recebeu o snapshot")

local function find(root, name)
	for _, d in root:GetDescendants() do
		if d.Name == name then
			return d
		end
	end
	return nil
end
local function click(button)
	Env.eventOf(button, "Activated"):Fire()
end
local function gui(name)
	return playerGui:FindFirstChild(name)
end

------------------------------------------------------------------------------------
-- HUD

check(Env.waitFor(function()
	return gui("HUD") ~= nil and find(gui("HUD"), "Roll") ~= nil
end), "HUD criado com o botão ROLAR")
local hud = gui("HUD")
for _, name in { "Backpack", "Upgrades", "Shop", "Rebirth", "Index", "Daily", "Settings", "Money", "Luck", "FriendBoost", "Auto", "Hide" } do
	check(find(hud, name) ~= nil, "HUD tem " .. name)
end
check(gui("NavigationHud") ~= nil, "barra CENTRO/CASA/LOJA")

------------------------------------------------------------------------------------
-- ROLAR (reveal normal)

local rollButton = find(hud, "Roll")
local data = S.PlayerDataService.GetData(player)
click(rollButton)
check(Env.waitFor(function()
	return data.Rolls == 1
end, 3), "clicar ROLAR faz o roll no servidor")
check(Env.waitFor(function()
	local count = 0
	for _ in DataController.Get("Inventory") or {} do
		count += 1
	end
	return count == 1
end, 3), "cliente recebe o personagem (InventoryDelta)")
check(Env.waitFor(function()
	return not C.RevealController.Busy()
end, 5), "reveal normal termina sozinho")
check(#C.RollController.History() == 1, "histórico da sessão com 1 roll")

-- Compacto (OCULTAR)
click(find(hud, "Hide"))
check(Env.waitFor(function()
	return data.Settings.HideRollAnimation == true
end, 2), "OCULTAR salva a configuração no servidor")
task.wait(1.1)
click(rollButton)
check(Env.waitFor(function()
	local compact = gui("RevealCompact")
	return compact ~= nil and find(compact, "Compact") ~= nil
end, 3), "OCULTAR: cartão compacto no topo")
click(find(hud, "Hide"))
task.wait(0.3)

------------------------------------------------------------------------------------
-- Cinemáticas (Hero Landing) via DevReveal, com limpeza

local function playDev(rarity, id)
	Net.fire("DevReveal", player, { CharacterId = id, Rarity = rarity, IsNew = true })
end

for _, case in { { "Legendary", "dragon_knight" }, { "Mythic", "void_emperor" }, { "Divine", "celestial_monk" }, { "Secret", "eclipse_sovereign" } } do
	playDev(case[1], case[2])
	check(Env.waitFor(function()
		return gui("HeroLanding") ~= nil
	end, 2), case[1] .. ": cinemática começou")
	local stage = gui("HeroLanding")
	check(stage ~= nil and find(stage, "Stage") ~= nil and find(stage, case[2]) ~= nil, case[1] .. ": palco local com o personagem")
	local continue = stage and find(stage, "Continue")
	check(Env.waitFor(function()
		return continue ~= nil and continue.Visible
	end, 6), case[1] .. ": botão CONTINUAR aparece")
	local rarityLabel = stage and find(stage, "Rarity")
	check(rarityLabel ~= nil and rarityLabel.Text ~= "", case[1] .. ": raridade/nome/odds na tela")
	if continue then
		click(continue)
	end
	check(Env.waitFor(function()
		return gui("HeroLanding") == nil and not C.RevealController.Busy()
	end, 2), case[1] .. ": limpeza completa (GUI destruída)")
end

-- Pular / morrer no meio
playDev("Legendary", "solar_paladin")
check(Env.waitFor(function()
	return gui("HeroLanding") ~= nil
end, 2), "cinemática para teste de morte")
task.wait(0.5)
player.CharacterRemoving:Fire()
check(Env.waitFor(function()
	return gui("HeroLanding") == nil
end, 2), "morrer no meio da cinemática limpa tudo")

------------------------------------------------------------------------------------
-- Janelas

local function openWindow(name)
	UIKit.Windows.open(name)
	task.wait(0.3)
	local window = UIKit.Windows.get(name)
	return window
end

S.InventoryService.Add(player, "dragon_knight")
S.InventoryService.Add(player, "flame_rookie")
S.InventoryService.Add(player, "flame_rookie")
task.wait(0.4)
local inv = openWindow("Inventory")
check(inv ~= nil and inv.isOpen and inv.gui.Enabled, "MOCHILA abre")
local cards = 0
for _, d in inv.content:GetDescendants() do
	if d:IsA("TextButton") and string.sub(d.Name, 1, 1) == "c" and tonumber(string.sub(d.Name, 2)) then
		cards += 1
	end
end
check(cards >= 4, "MOCHILA mostra os cards (" .. cards .. ")")
-- seleciona o primeiro card e equipa
local firstCard
for _, d in inv.content:GetDescendants() do
	if d:IsA("TextButton") and d.Name == "c3" then
		firstCard = d
	end
end
if firstCard then
	click(firstCard)
	task.wait(0.3)
end
check(C.InventoryController.Selected() == "c3", "selecionar card")
local equipButton
for _, d in inv.content:GetDescendants() do
	if d:IsA("TextButton") and d:FindFirstChild("Label") and d.Label.Text == "EQUIPAR" then
		equipButton = d
		break
	end
end
if equipButton then
	click(equipButton)
end
check(Env.waitFor(function()
	return S.InventoryService and data.EquippedCharacters["1"] ~= nil
end, 2), "EQUIPAR pela MOCHILA coloca na base")
for _, name in { "DiceShop", "Upgrades", "Sell", "Index", "Daily", "Settings" } do
	local w = openWindow(name)
	check(w ~= nil and w.isOpen, name .. " abre")
end
UIKit.Windows.closeAll()

-- Diário: resgatar Dia 1
local daily = openWindow("Daily")
task.wait(0.3)
local moneyBefore = data.Money
local dayCard
for _, d in daily.content:GetChildren() do
	if d:IsA("TextButton") then
		local day = d:FindFirstChild("Text")
		dayCard = dayCard or d
	end
end
if dayCard then
	click(dayCard)
end
check(Env.waitFor(function()
	return data.DailyCycleDay == 1 and data.Money > moneyBefore
end, 2), "DIÁRIO: clicar no Dia 1 resgata")
UIKit.Windows.closeAll()

-- Offline: popup + resgatar
data.LastLogout = os.time() - 3600
data.LastKnownIncomePerSecond = 100
S.EconomyService._resetOffline(player)
S.EconomyService.CheckOffline(player)
check(Env.waitFor(function()
	return (DataController.Get("PendingOfflineReward") or 0) > 0
end, 2), "cliente recebe PendingOfflineReward")
local offline = openWindow("Offline")
local claim = find(offline.content, "Claim")
local before = data.Money
click(claim)
check(Env.waitFor(function()
	return data.PendingOfflineReward == 0 and data.Money > before
end, 2), "OFFLINE: RESGATAR paga e fecha")

-- Vender duplicatas: prévia + confirmação (3 cópias soltas garantem duplicatas)
for _ = 1, 3 do
	S.InventoryService.Add(player, "tide_apprentice")
end
task.wait(0.3)
UIKit.Windows.open("Sell")
task.wait(0.3)
local sell = UIKit.Windows.get("Sell")
local dupButton
for _, d in sell.content:GetDescendants() do
	if d:IsA("TextButton") and d:FindFirstChild("Label") and d.Label.Text == "VENDER DUPLICATAS" then
		dupButton = d
	end
end
check(dupButton ~= nil, "botão VENDER DUPLICATAS")
if dupButton then
	click(dupButton)
end
check(Env.waitFor(function()
	return gui("Confirm") ~= nil
end, 2), "venda em massa pede confirmação")
local confirmGui = gui("Confirm")
local yes
if confirmGui then
	for _, d in confirmGui:GetDescendants() do
		if d:IsA("TextButton") and d:FindFirstChild("Label") and d.Label.Text == "VENDER" then
			yes = d
		end
	end
end
local invBefore = 0
for _ in data.Inventory do
	invBefore += 1
end
if yes then
	click(yes)
end
check(Env.waitFor(function()
	local n = 0
	for _ in data.Inventory do
		n += 1
	end
	return n < invBefore
end, 2), "confirmar vende as duplicatas")
UIKit.Windows.closeAll()

-- Configurações
local settingsWindow = openWindow("Settings")
local toggles = {}
for _, d in settingsWindow.content:GetDescendants() do
	if d:IsA("TextButton") then
		table.insert(toggles, d)
	end
end
if toggles[3] then
	click(toggles[3])
end
check(Env.waitFor(function()
	return data.Settings.ReducedEffects == true
end, 2), "CONFIGURAÇÕES: Efeitos reduzidos salvo")
UIKit.Windows.closeAll()

-- Torres: abrir, lutar, animação da batalha, fechar
S.InventoryService.Add(player, "eclipse_sovereign")
local towers = openWindow("Towers")
check(towers ~= nil and towers.isOpen, "TORRES abre")
local fight = find(towers.content, "Fight_Ember")
check(fight ~= nil, "botão LUTAR da Torre das Brasas")
if fight then
	click(fight)
end
check(Env.waitFor(function()
	local battle = gui("Battle")
	return battle ~= nil and battle.Enabled and find(battle, "Outcome") ~= nil
end, 15), "batalha animada até VITÓRIA/DERROTA")
check(data.TowerProgress.Ember == 1, "andar 1 vencido")
local closeBattle = gui("Battle") and find(gui("Battle"), "CloseBattle")
if closeBattle then
	click(closeBattle)
end
check(Env.waitFor(function()
	return not gui("Battle").Enabled
end, 2), "fechar a batalha")
UIKit.Windows.closeAll()

-- Fase 8: Fusão, Renascimento e Trocas pela interface
do
	for _ = 1, 3 do
		S.InventoryService.Add(player, "abyss_warlock")
	end
	data.Money = 1e12
	task.wait(0.3)
	local fusion = openWindow("Fusion")
	local fuseButton = find(fusion.content, "Fuse_abyss_warlock")
	check(fuseButton ~= nil, "FUSÃO lista o grupo de 3 iguais")
	if fuseButton then
		click(fuseButton)
	end
	check(Env.waitFor(function()
		for _, item in data.Inventory do
			if item.Id == "abyss_warlock" and item.Variant == "Silver" then
				return true
			end
		end
		return false
	end, 2), "FUNDIR cria a variante Prata")
	UIKit.Windows.closeAll()

	local rebirths = data.Rebirths
	local rebirth = openWindow("Rebirth")
	local doRebirth = find(rebirth.content, "DoRebirth")
	if doRebirth then
		click(doRebirth)
	end
	check(Env.waitFor(function()
		return gui("Confirm") ~= nil
	end, 2), "RENASCER pede confirmação")
	local yesButton
	for _, d in gui("Confirm"):GetDescendants() do
		if d:IsA("TextButton") and d:FindFirstChild("Label") and d.Label.Text == "RENASCER" then
			yesButton = d
		end
	end
	if yesButton then
		click(yesButton)
	end
	check(Env.waitFor(function()
		return data.Rebirths == rebirths + 1 and data.Money == 0
	end, 2), "renascimento feito pela interface")
	local perk = find(rebirth.content, "Perk_Luck")
	if perk then
		click(perk)
	end
	check(Env.waitFor(function()
		return (data.RebirthPerks.Luck or 0) == 1
	end, 2), "perk comprado pela LOJA DE FICHAS")
	UIKit.Windows.closeAll()

	local trade = openWindow("Trade")
	check(trade ~= nil and trade.isOpen and find(trade.content, "Lobby").Visible, "TROCAS abre no lobby (sem sessão)")
	UIKit.Windows.closeAll()
end

-- Missões
do
	data.Missions.Daily = { roll_50 = { Progress = 50, Claimed = false } }
	S.PlayerDataService.Replicate(player, "Missions")
	task.wait(0.3)
	local missions = openWindow("Missions")
	check(missions ~= nil and missions.isOpen, "MISSÕES abre")
	local claimButton
	for _, d in missions.content:GetDescendants() do
		if d:IsA("TextButton") and d:FindFirstChild("Label") and d.Label.Text == "RESGATAR!" then
			claimButton = d
		end
	end
	check(claimButton ~= nil, "missão completa mostra RESGATAR")
	if claimButton then
		click(claimButton)
	end
	check(Env.waitFor(function()
		return data.Missions.Daily.roll_50.Claimed == true
	end, 2), "resgatar missão pela interface")
	UIKit.Windows.closeAll()
end

-- Notificações agrupadas
C.NotificationController.Show("error.inventory_full")
C.NotificationController.Show("error.inventory_full")
C.NotificationController.Show("error.inventory_full")
task.wait(0.1)
local stack = find(gui("Notifications"), "Stack")
local lines = 0
local grouped = false
for _, d in stack:GetChildren() do
	if d:IsA("TextLabel") then
		lines += 1
		if string.find(d.Text, "[x3]", 1, true) then
			grouped = true
		end
	end
end
check(grouped, "mensagens repetidas agrupadas ([x3])")

-- Estação + LOD + feedback de upgrade
data.Money = 1e9
local okUp = pcall(S.InventoryService.UpgradeCharacter, player, data.EquippedCharacters["1"], 1)
check(okUp, "upgrade da estação")
task.wait(1.2)

------------------------------------------------------------------------------------

running = false
task.wait(0.1)
check(#Env.errors == 0, "nenhum erro de execução no cliente/servidor (" .. #Env.errors .. ")")
for i, err in Env.errors do
	if i <= 15 then
		print("    · " .. string.sub(err, 1, 400))
	end
end
local failures = T.finish()
process.exit(if failures > 0 then 1 else 0)
