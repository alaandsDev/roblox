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

-- Assets sanitizados dos PILOTOS (pack sintético -> pipeline -> ReplicatedStorage.CharacterAssets).
-- O pack é destruído antes do jogo começar: o cliente só vê os assets.
do
	local SyntheticPack = require("./SyntheticPack")
	local pipelineRequire = env.newContext()
	local Pipeline = pipelineRequire(env.shared.Modules.CharacterAssetPipeline)
	local pack = SyntheticPack.build()
	local pilotIds = {}
	for _, pilot in pipelineRequire(env.shared.Config.CharacterConfig).Pilots do
		table.insert(pilotIds, pilot.Id)
	end
	local assets = Pipeline.buildAll(pack, pilotIds)
	pack:Destroy()
	assets.Parent = env.real.ReplicatedStorage
end

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
	"BoostService", "JackpotService", "LeaderboardService",
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
	"RebirthController", "FusionController", "TradeController", "MissionController", "StoreController", "MusicController",
	"FeedbackController", "LodController", "AuraController", "TutorialController",
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
do -- HUD icon-first (design system): chip visual compacto, toque grande, badge pequeno no canto
	local ok, minTouch = true, math.huge
	for _, name in { "Backpack", "Upgrades", "Shop", "Rebirth", "Index", "Daily", "Settings", "Roll" } do
		local b = find(hud, name)
		local chip = b and b:FindFirstChild("Chip")
		if not (b and chip and b.BackgroundTransparency == 1 and chip.Size.X.Scale < 0.9) then
			ok = false
		end
		if b then
			minTouch = math.min(minTouch, b.Size.X.Offset, b.Size.Y.Offset)
		end
	end
	check(ok, "HUD: botões icon-first (área de toque invisível + chip compacto com ícone)")
	check(minTouch >= 44, "HUD: área de toque >= 44 px em todos os botões (" .. minTouch .. ")")
	local roll = find(hud, "Roll")
	check(roll ~= nil and roll.Chip.Size.X.Scale > find(hud, "Backpack").Chip.Size.X.Scale, "HUD: ROLAR é o botão primário (chip maior)")
	C.HudController.SetBadge("Backpack", "3")
	local badge = find(hud, "Backpack").Chip:FindFirstChild("Badge")
	check(badge ~= nil and badge.Visible and badge.Size.Y.Offset <= 24 and find(hud, "Backpack").Size.X.Offset == 104, "HUD: badge pequeno no canto do ícone, sem aumentar o botão")
	C.HudController.SetBadge("Backpack", nil)
	UIKit.setDisabled(find(hud, "Index"), true)
	check(find(hud, "Index"):GetAttribute("Disabled") == true, "HUD: estado Disabled")
	UIKit.setDisabled(find(hud, "Index"), false)
end
check(gui("NavigationHud") ~= nil, "barra CENTRO/CASA/LOJA")

-- TUTORIAL (auditoria): jogador novo vê o passo 1 e o HUD reduzido
check(Env.waitFor(function()
	local t = gui("Tutorial")
	return t ~= nil and t.Enabled and find(t, "Step") ~= nil and string.find(find(t, "Step").Text, "1/7", 1, true) ~= nil
end, 2), "tutorial: jogador novo vê PASSO 1/7")
check(hud:FindFirstChild("Root"):FindFirstChild("Left").Visible == false, "tutorial: botões secundários escondidos no começo")

------------------------------------------------------------------------------------
-- ROLAR (reveal normal)

local rollButton = find(hud, "Roll")
local data = S.PlayerDataService.GetData(player)
-- Rolls do teste nunca passam de Raro: uma cinemática Lendária aleatória (1 em 77) travava os
-- passos seguintes. As cinemáticas são testadas uma a uma mais abaixo.
local realRollRand = S.RollService._rand
S.RollService._rand = function()
	return realRollRand() * 0.9
end
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
do -- faixa de rolls recentes: retrato do MESMO sistema (CharacterPreview), sem ícone de Dice
	local Preview = clientRequire(env.client.UI.CharacterPreview)
	Preview._isVisible = function(g)
		return g:FindFirstAncestorWhichIsA("LayerCollector") ~= nil
	end
	Preview.update()
	local chip = gui("HUD") and find(gui("HUD"), "Recent1")
	local view = chip and chip:FindFirstChild("Preview")
	check(view ~= nil and view:FindFirstChildOfClass("Model") ~= nil, "faixa de rolls: retrato 3D do personagem (enquadrado no rosto)")
end

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
do -- retratos reais (CharacterPreview): lazy, teto de ativos, pool e limpeza ao fechar
	local Preview = clientRequire(env.client.UI.CharacterPreview)
	Preview._isVisible = function(g)
		return g:FindFirstAncestorWhichIsA("LayerCollector") ~= nil
	end
	Preview.update()
	local withPreview, withModel = 0, 0
	for _, d in inv.content:GetDescendants() do
		if d:IsA("ViewportFrame") and d.Name == "Preview" then
			withPreview += 1
			if d:FindFirstChildOfClass("Model") then
				withModel += 1
			end
		end
	end
	check(withPreview >= cards and withModel >= 4, "MOCHILA: cada card tem retrato 3D real (" .. withModel .. " modelos)")
	check(Preview.stats().active <= Preview.MaxActive, "MOCHILA: teto de retratos ativos respeitado")
	_G.__previewModule = Preview
end
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
do -- fechar a MOCHILA solta todos os retratos e esvazia o pool
	local Preview = _G.__previewModule
	Preview.update()
	local st = Preview.stats()
	local alive = 0
	for _, d in inv.content:GetDescendants() do
		if d:IsA("ViewportFrame") and d.Name == "Preview" and d:FindFirstChildOfClass("Model") then
			alive += 1
		end
	end
	check(st.pooled == 0 and alive == 0, "MOCHILA fechada: nenhum modelo de retrato vivo, pool vazio")
end

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

do -- MOCHILA: cabeçalho responsivo + MODO VENDA (seleção sem recriar retratos, confirmação, servidor)
	local function rectOf(g)
		return { x = g.Position.X.Offset, y = g.Position.Y.Offset, w = g.Size.X.Offset, h = g.Size.Y.Offset }
	end
	local function overlaps(a, b)
		return a.x < b.x + b.w and b.x < a.x + a.w and a.y < b.y + b.h and b.y < a.y + a.h
	end
	local inv2 = openWindow("Inventory")
	task.wait(0.3)
	local header = find(inv2.content, "Header")
	for _, size in { { 1136, 520, "wide" }, { 820, 480, "compact" }, { 460, 600, "portrait" } } do
		C.InventoryController._layoutFor(size[1], size[2])
		local parts = {}
		for _, name in { "Title", "Capacity", "Search", "EquipBestTop", "SellMode", "Filter_All", "Filter_Rarity", "Filter_Power", "Filter_Income", "Filter_Recent", "FilterCycle" } do
			local g = header and header:FindFirstChild(name)
			if g and g.Visible then
				table.insert(parts, { name = name, r = rectOf(g) })
			end
		end
		local ok = header ~= nil and header:GetAttribute("LayoutMode") == size[3] and #parts >= 6
		for i, a in parts do
			ok = ok and a.r.x >= 0 and a.r.x + a.r.w <= size[1] and a.r.y + a.r.h <= header.Size.Y.Offset and a.r.h >= 44
			for j = i + 1, #parts do
				if overlaps(a.r, parts[j].r) then
					ok = false
					print("    sobreposição:", a.name, parts[j].name)
				end
			end
		end
		check(ok, "MOCHILA cabeçalho " .. size[3] .. ": MOCHILA+capacidade, filtros+busca, EQUIPAR MELHORES e 🗑 sem sobreposição nem corte")
	end
	C.InventoryController._layoutFor(1136, 520)
	-- inventário de teste: 3 cópias iguais + 1 favorita
	local dupes = {}
	for _ = 1, 3 do
		table.insert(dupes, S.InventoryService.Add(player, "tide_apprentice"))
	end
	local favUid = S.InventoryService.Add(player, "tide_apprentice")
	data.Inventory[favUid].Favorite = true
	S.InventoryService.SendDelta(player, { favUid }, nil)
	task.wait(0.5)
	C.InventoryController.Refresh()
	local function card(uid)
		local grid = find(inv2.content, "Grid")
		return grid and grid:FindFirstChild(uid)
	end
	local cardA = card(dupes[1])
	local viewA = cardA and cardA:FindFirstChild("Preview", true)
	click(find(header, "SellMode"))
	local footer = find(inv2.content, "SaleFooter")
	check(C.InventoryController.SaleMode() and footer and footer.Visible, "🗑 entra no MODO VENDA com rodapé")
	if cardA then
		click(cardA)
	end
	local veil = cardA and cardA:FindFirstChild("SaleVeil")
	check(#C.InventoryController.SaleSelection() == 1 and veil and veil.Visible and veil:FindFirstChild("Check").Visible, "MODO VENDA: tocar no card marca (borda vermelha, ✓, véu discreto)")
	check(card(dupes[1]) == cardA and (cardA and cardA:FindFirstChild("Preview", true)) == viewA, "MODO VENDA: selecionar NÃO recria o card nem o ViewportFrame do retrato")
	local favCard = card(favUid)
	if favCard then
		click(favCard)
	end
	check(#C.InventoryController.SaleSelection() == 1, "MODO VENDA: favorito não é selecionável (aviso, sem vender em silêncio)")
	click(find(footer, "SelectDuplicates"))
	local picked = C.InventoryController.SaleSelection()
	local hasFav = table.find(picked, favUid) ~= nil
	check(#picked >= 2 and not hasFav, "SELECIONAR DUPLICATAS: só excedentes, nunca o favorito (" .. #picked .. ")")
	local info = find(footer, "Info")
	check(Env.waitFor(function()
		return info ~= nil and string.find(info.Text, "Você receberá", 1, true) ~= nil
	end, 3), "rodapé: X selecionados + Você receberá (prévia do servidor)")
	local invCount = 0
	for _ in data.Inventory do
		invCount += 1
	end
	local moneyBeforeBulk = data.Money
	click(find(footer, "SellSelected"))
	check(Env.waitFor(function()
		return gui("Confirm") ~= nil
	end, 2), "VENDER pede confirmação (Vender X personagens por $Y?)")
	local nowCount = 0
	for _ in data.Inventory do
		nowCount += 1
	end
	check(nowCount == invCount, "nada é vendido antes de confirmar")
	local confirmYes
	for _, d in gui("Confirm"):GetDescendants() do
		if d:IsA("TextButton") and d:FindFirstChild("Label") and d.Label.Text == "CONFIRMAR VENDA" then
			confirmYes = d
		end
	end
	if confirmYes then
		click(confirmYes)
	end
	check(Env.waitFor(function()
		local n = 0
		for _ in data.Inventory do
			n += 1
		end
		return n == invCount - #picked and data.Money > moneyBeforeBulk and data.Inventory[favUid] ~= nil
	end, 3), "CONFIRMAR VENDA: servidor vende as selecionadas, paga e o favorito fica")
	click(find(footer, "CancelSale"))
	check(not C.InventoryController.SaleMode() and not footer.Visible, "CANCELAR sai do MODO VENDA")
	data.Inventory[favUid].Favorite = false
	S.InventoryService.SendDelta(player, { favUid }, nil)
	UIKit.Windows.closeAll()
end

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

do -- AuraController: um loop central anima órbitas/raios das auras com tag (servidor monta, cliente move)
	local Factory = clientRequire(env.shared.Modules.CharacterModelFactory)
	local model = Factory.build("char_killuo_godspeed", { vfx = "Full" })
	model.Parent = workspace
	task.wait(0.1)
	local total = C.AuraController.Count()
	local orbit, before
	for _, d in model:GetDescendants() do
		if d:IsA("Attachment") and d:GetAttribute("AuraRole") == "Orbit" then
			orbit = d
		end
	end
	C.AuraController._step(0.6) -- força o ranking (perto da câmera) e um passo de animação
	before = orbit and orbit.Position
	C.AuraController._step(0.1)
	local moved = orbit == nil or (orbit.Position - before).Magnitude > 0.01
	check(total >= 1 and moved, "auras: AuraController registra a aura (tag) e anima no loop central")
	model:Destroy()
end

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
do -- OCULTAR: painel compacto (andar, HP, ganhos) com MOSTRAR e PARAR; só apresentação
	local hide = gui("Battle") and find(gui("Battle"), "HideBattle")
	check(hide ~= nil, "TORRE: botão OCULTAR na batalha")
	if hide then
		click(hide)
	end
	check(Env.waitFor(function()
		local panel = gui("TowerCompact") and find(gui("TowerCompact"), "TowerCompactPanel")
		return panel ~= nil and panel.Visible and not gui("Battle").Enabled and string.find(find(panel, "Info").Text, "Andar") ~= nil
	end, 3), "TORRE: OCULTAR mostra o painel compacto (Andar / HP / Ganhos)")
	local show = find(gui("TowerCompact"), "CompactShow")
	if show then
		click(show)
	end
	check(Env.waitFor(function()
		return gui("Battle").Enabled and find(gui("Battle"), "CloseBattle") ~= nil
	end, 3), "TORRE: MOSTRAR volta para a tela da batalha")
end
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

-- Loja e Jackpot
do
	local store = openWindow("Store")
	check(store ~= nil and store.isOpen and find(store.content, "Pass_VIP") ~= nil, "LOJA mostra os gamepasses")
	check(find(store.content, "Gem_JackpotSpin") ~= nil, "LOJA mostra a loja de gemas")
	UIKit.Windows.closeAll()
	data.Gems = 500
	S.JackpotService._rand = function()
		return 0 -- prêmio determinístico (dinheiro) para conferir o custo
	end
	local jackpot = find(gui("HUD"), "JackpotShortcut")
	check(jackpot ~= nil, "atalho JACKPOT no lado direito")
	if jackpot then
		click(jackpot)
	end
	check(Env.waitFor(function()
		local g = gui("Jackpot")
		return g ~= nil and g.Enabled and find(g, "ClosePrize") ~= nil
	end, 6), "giro do Jackpot animado e prêmio mostrado")
	check(data.Gems == 350, "giro cobrou 150 gemas")
	local closePrize = find(gui("Jackpot"), "ClosePrize")
	if closePrize then
		click(closePrize)
	end
	task.wait(0.2)
	-- Se o prêmio foi personagem, o reveal toca; espera terminar (ou fecha a cinemática)
	Env.waitFor(function()
		local stage = gui("HeroLanding")
		if stage then
			local continue = find(stage, "Continue")
			if continue and continue.Visible then
				click(continue)
			end
		end
		return not C.RevealController.Busy()
	end, 8)
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

do
	-- Fila de janelas automáticas: nunca por cima de outra janela; maior prioridade primeiro
	local NC = C.NotificationController
	local opened = {}
	UIKit.Windows.open("Settings")
	NC.QueueModal("Info", NC.Priority.INFO, function()
		table.insert(opened, "Info")
	end)
	NC.QueueModal("Reward", NC.Priority.REWARD, function()
		table.insert(opened, "Reward")
	end)
	NC.QueueModal("Reward", NC.Priority.REWARD, function()
		table.insert(opened, "RewardDup")
	end)
	task.wait(0.6)
	check(#opened == 0, "fila: com janela aberta nada abre por cima")
	UIKit.Windows.closeAll()
	check(Env.waitFor(function()
		return #opened >= 1
	end, 2) and opened[1] == "Reward", "fila: abre a de maior prioridade primeiro")
	check(Env.waitFor(function()
		return #opened == 2
	end, 2) and opened[2] == "Info" and table.find(opened, "RewardDup") == nil, "fila: uma por vez e sem repetir")
	check(NC.PriorityOf("error.inventory_full") == NC.Priority.WARNING and NC.PriorityOf("daily.claimed") == NC.Priority.REWARD, "prioridade das mensagens por tipo")
end

do
	-- AUTO / OCULTAR / ROLL RÁPIDO no cliente de verdade (tempo real curto) + cinemática pausando o AUTO
	local RC = C.RollController
	local d = S.PlayerDataService.GetData(player)
	UIKit.Windows.closeAll()
	d.Pity = { Legendary = 0, Mythic = 0 }
	S.PlayerDataService.Set(player, "Inventory", {})
	S.PlayerDataService.Set(player, "EquippedCharacters", {})
	local function autoFor(seconds: number): number
		local before = d.Rolls
		RC.SetAuto(true)
		task.wait(seconds)
		RC.SetAuto(false)
		Env.waitFor(function()
			return not C.RevealController.Busy()
		end, 3)
		return d.Rolls - before
	end
	task.wait(1.1)
	local normal = autoFor(3.2)
	check(normal >= 2 and normal <= 4, "AUTO: ~1 roll/s (3,2 s -> " .. normal .. " rolls, máximo 4)")
	task.spawn(DataController.SetSetting, "HideRollAnimation", true)
	Env.waitFor(function()
		return (DataController.Get("Settings") or {}).HideRollAnimation == true
	end, 2)
	task.wait(1.1)
	local hidden = autoFor(3.2)
	check(hidden >= 2 and hidden <= 4, "OCULTAR + AUTO: mesma cadência de 1 roll/s (" .. hidden .. " rolls)")
	local runtime = table.clone(d.Runtime or {})
	runtime.FastRoll = true
	S.PlayerDataService.Set(player, "Runtime", runtime)
	Env.waitFor(function()
		return (DataController.Get("Runtime") or {}).FastRoll == true
	end, 2)
	task.wait(1.1)
	local fast = autoFor(3.2)
	check(fast >= 4 and fast <= 7, "ROLL RÁPIDO + AUTO: ~2 rolls/s (3,2 s -> " .. fast .. " rolls, máximo 7)")
	runtime = table.clone(d.Runtime)
	runtime.FastRoll = false
	S.PlayerDataService.Set(player, "Runtime", runtime)
	task.spawn(DataController.SetSetting, "HideRollAnimation", false)
	Env.waitFor(function()
		return (DataController.Get("Settings") or {}).HideRollAnimation == false and (DataController.Get("Runtime") or {}).FastRoll == false
	end, 2)
	-- Cinemática (Lendário) pausa o AUTO e ele volta sozinho depois. O Starter não tem Lendário:
	-- o roll vem do Flame (Dice com Lendário)
	S.DiceService.Grant(player, "Flame")
	S.PlayerDataService.Set(player, "EquippedDice", "Flame")
	task.wait(1.1)
	local capped = S.RollService._rand
	local forced = false
	S.RollService._rand = function()
		if not forced then
			forced = true
			return 0.9985 -- Lendário no Flame (1º sorteio = raridade; última faixa do Dice)
		end
		return capped()
	end
	local startRolls = d.Rolls
	RC.SetAuto(true)
	check(Env.waitFor(function()
		return gui("HeroLanding") ~= nil
	end, 3), "Lendário no AUTO: cinemática começa")
	local duringStart = d.Rolls
	local maxDuring = duringStart
	while gui("HeroLanding") ~= nil do
		maxDuring = math.max(maxDuring, d.Rolls)
		task.wait(0.05)
	end
	check(maxDuring == duringStart and duringStart == startRolls + 1, "AUTO fica pausado durante a cinemática (nenhum roll a mais, sem comprimir a cinemática)")
	check(Env.waitFor(function()
		return d.Rolls > duringStart
	end, 3), "depois da cinemática o AUTO volta sozinho")
	RC.SetAuto(false)
	S.RollService._rand = capped
	Env.waitFor(function()
		return not C.RevealController.Busy()
	end, 3)
end

do
	-- TUTORIAL: os passos avançaram jogando; PULAR termina e devolve o HUD completo
	local data2 = S.PlayerDataService.GetData(player)
	check((data2.Tutorial or 0) >= 3, "tutorial: avançou sozinho jogando (passo " .. tostring(data2.Tutorial) .. ")")
	click(find(gui("Tutorial"), "Skip"))
	check(Env.waitFor(function()
		return data2.Tutorial == 7 and gui("Tutorial").Enabled == false
	end, 2), "tutorial: PULAR termina o tutorial")
	check(gui("HUD"):FindFirstChild("Root"):FindFirstChild("Left").Visible == true, "tutorial terminado: HUD completo")
end

do
	-- HUD responsivo (auditoria mobile): celular em pé e de volta ao PC
	local hud = gui("HUD")
	local hudRoot = hud and hud:FindFirstChild("Root")
	Env.setViewport(camera, 390, 844)
	task.wait(0.05)
	local right = hudRoot and hudRoot:FindFirstChild("Right")
	local stats = hudRoot and hudRoot:FindFirstChild("BottomLeft")
	local history = hudRoot and hudRoot:FindFirstChild("History")
	check(hudRoot ~= nil and hudRoot:GetAttribute("LayoutMode") == "portrait", "celular em pé: layout retrato")
	check(right ~= nil and right.Visible == false and history ~= nil and history.Visible == false, "retrato: some a coluna da direita e o histórico")
	check(stats ~= nil and stats.Position.Y.Scale == 0, "retrato: dinheiro/sorte vão para o topo")
	Env.setViewport(camera, 1024, 768)
	task.wait(0.05)
	check(hudRoot:GetAttribute("LayoutMode") == "compact" or hudRoot:GetAttribute("LayoutMode") == "wide", "tablet deitado: sem modo retrato")
	Env.setViewport(camera, 1280, 720)
	task.wait(0.05)
	check(hudRoot:GetAttribute("LayoutMode") == "wide" and right.Visible and history.Visible and stats.Position.Y.Scale == 1, "volta ao PC: layout padrão")
end

do
	-- PILOTOS do pipeline de personagens no cliente: Reveal, Hero Landing, Mochila e Índice
	-- (retratos dos CARDS ficam em ViewportFrames "Preview" e são do pool; aqui conta só o resto)
	local function count(root, name)
		local n = 0
		for _, d in root:GetDescendants() do
			if d.Name == name and not d:FindFirstAncestor("Preview") then
				n += 1
			end
		end
		return n
	end
	UIKit.Windows.closeAll()
	check(Env.waitFor(function()
		return not C.RevealController.Busy()
	end, 5), "pilotos: nenhum reveal pendente")

	-- Reveal normal (Raro): modelo do asset, pose Reveal, limpa no fim
	playDev("Rare", "char_killuo_base")
	local revealModel
	check(Env.waitFor(function()
		local reveal = gui("Reveal")
		revealModel = reveal and find(reveal, "char_killuo_base")
		return revealModel ~= nil
	end, 3), "Reveal: piloto aparece no reveal atual")
	check(revealModel ~= nil and revealModel:GetAttribute("AssetRig") == true and revealModel:GetAttribute("VFXMode") == "Full", "Reveal: asset sanitizado com VFX Full")
	check(Env.waitFor(function()
		return not C.RevealController.Busy()
	end, 6) and count(gui("Reveal"), "char_killuo_base") == 0, "Reveal: modelo destruído ao terminar")

	-- Hero Landing (Divino): asset, pose própria, VFX controlado, limpeza total
	local guisBefore = #playerGui:GetChildren()
	local instancesBefore = #playerGui:GetDescendants()
	playDev("Divine", "char_goju_base")
	check(Env.waitFor(function()
		return gui("HeroLanding") ~= nil
	end, 2), "Hero Landing: cinemática do piloto Divino começou")
	local stage = gui("HeroLanding")
	local heroModel = stage and find(stage, "char_goju_base")
	check(heroModel ~= nil and heroModel:GetAttribute("AssetRig") == true and heroModel:GetAttribute("VFXMode") == "Full", "Hero Landing: piloto do asset sanitizado (VFX Full)")
	local continue = stage and find(stage, "Continue")
	check(Env.waitFor(function()
		return continue ~= nil and continue.Visible
	end, 6), "Hero Landing: CONTINUAR aparece")
	check(heroModel ~= nil and heroModel:FindFirstChildOfClass("Shirt") ~= nil and heroModel.Head:FindFirstChild("face") ~= nil and heroModel.Head:FindFirstChild("face").Transparency < 1, "Hero Landing: roupa e rosto voltam depois da silhueta")
	if continue then
		click(continue)
	end
	check(Env.waitFor(function()
		return gui("HeroLanding") == nil and not C.RevealController.Busy()
	end, 2), "Hero Landing: GUI destruída")
	check(#playerGui:GetChildren() == guisBefore and #playerGui:GetDescendants() <= instancesBefore + 2 and count(gui("Reveal"), "char_goju_base") == 0 and count(env.real.Workspace, "char_goju_base") == 0, string.format("Hero Landing: nenhum modelo/partícula órfão (%d -> %d instâncias na PlayerGui)", instancesBefore, #playerGui:GetDescendants()))

	-- Mochila: retrato do piloto; trocar a seleção não acumula clones
	local uidA = S.InventoryService.Add(player, "char_ichiro_hollow")
	local uidB = S.InventoryService.Add(player, "char_zabuzo_base")
	S.InventoryService.SendDelta(player, { uidA, uidB }, nil)
	task.wait(0.4)
	local inv = openWindow("Inventory")
	local function cardOf(uid)
		for _, d in inv.content:GetDescendants() do
			if d:IsA("TextButton") and d.Name == uid then
				return d
			end
		end
		return nil
	end
	for _, uid in { uidA, uidB, uidA, uidB } do
		local card = cardOf(uid)
		if card then
			click(card)
		end
		task.wait(0.15)
	end
	local portraitZabuza = count(inv.gui, "char_zabuzo_base")
	local portraitHollow = count(inv.gui, "char_ichiro_hollow")
	check(C.InventoryController.Selected() == uidB and portraitZabuza == 1 and portraitHollow == 0, "Mochila: retrato do piloto selecionado, sem acumular clones")
	local portraitModel = find(inv.gui, "char_zabuzo_base")
	check(portraitModel ~= nil and portraitModel:GetAttribute("AssetRig") == true and portraitModel:GetAttribute("VFXMode") == "None", "Mochila: asset com VFX None")
	UIKit.Windows.closeAll()

	-- Índice: abre na aba do Dice em uso; cards criados uma vez só (cache ao reabrir)
	S.PlayerDataService.Set(player, "EquippedDice", "Starter")
	task.wait(0.2)
	local index = openWindow("Index")
	task.wait(0.2)
	UIKit.Windows.closeAll()
	openWindow("Index")
	task.wait(0.2)
	check(count(index.gui, "char_sacha_base") == 1, "Índice: card do piloto criado uma vez, sem clones ao reabrir")
	local indexModel = find(index.gui, "char_sacha_base")
	check(indexModel ~= nil and indexModel:GetAttribute("AssetRig") == true and indexModel:GetAttribute("VFXMode") == "None", "Índice: asset com VFX None")
	UIKit.Windows.closeAll()
end

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
