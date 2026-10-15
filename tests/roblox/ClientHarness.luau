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
local historyBeforeHide = #C.RollController.History()
click(rollButton)
-- Resultado de roll NÃO vira texto flutuante "Nome • RARIDADE" (redundante com os rolls recentes)
local function rollToastOnScreen(): string?
	local CharacterConfigC = clientRequire(env.shared.Config.CharacterConfig)
	local last = C.RollController.History()[1]
	local name = last and CharacterConfigC.ById[last.CharacterId] and CharacterConfigC.ById[last.CharacterId].Name
	for _, screen in playerGui:GetChildren() do
		if screen.Name ~= "HUD" then -- a faixa de rolls recentes (HUD) não tem texto de nome
			for _, d in screen:GetDescendants() do
				if d:IsA("TextLabel") and d.Visible and (d.Name == "RollTip" or (name and string.find(d.Text, name, 1, true) and string.find(d.Text, "•", 1, true))) then
					return screen.Name .. "/" .. d.Name .. ": " .. d.Text
				end
			end
		end
	end
	return nil
end
check(Env.waitFor(function()
	return #C.RollController.History() > historyBeforeHide or historyBeforeHide >= 10
end, 3), "OCULTAR: o resultado entra na faixa de rolls recentes")
task.wait(0.2)
local toast = rollToastOnScreen()
check(toast == nil and gui("RevealCompact") == nil, "OCULTAR: nenhum toast/texto \"Nome • RARIDADE\" na tela (" .. tostring(toast) .. ")")
do -- ROLLS RECENTES sem "mini F5": um roll novo cria SÓ o chip dele; os outros mantêm o retrato
	local Preview = clientRequire(env.client.UI.CharacterPreview)
	local row = gui("HUD") and find(gui("HUD"), "History")
	local before = {}
	for _, chip in (row and row:GetChildren()) or {} do
		if chip:IsA("Frame") then
			before[chip] = chip:FindFirstChild("Preview")
		end
	end
	local st0 = Preview.stats()
	local historyBefore = #C.RollController.History()
	task.wait(1.1)
	click(rollButton)
	Env.waitFor(function()
		return #C.RollController.History() > historyBefore or historyBefore >= 10
	end, 3)
	task.wait(0.3)
	local st1 = Preview.stats()
	local kept, same = 0, true
	for chip, view in before do
		if chip.Parent == row then
			kept += 1
			same = same and chip:FindFirstChild("Preview") == view
		end
	end
	check(kept >= 1 and same, string.format("rolls recentes: %d chips antigos mantidos com o MESMO ViewportFrame (nada recriado)", kept))
	check(st1.viewportsCreated - st0.viewportsCreated <= 1 and st1.viewportsDestroyed - st0.viewportsDestroyed <= 1,
		string.format("rolls recentes: novo roll criou %d ViewportFrame(s) e destruiu %d (só o chip novo / o que saiu)", st1.viewportsCreated - st0.viewportsCreated, st1.viewportsDestroyed - st0.viewportsDestroyed))
end
do -- RECENT ROLLS some 20 s depois do último roll (tempos exatos) SEM recriar retratos
	local RC = C.RollController
	local Preview = clientRequire(env.client.UI.CharacterPreview)
	local row = gui("HUD") and find(gui("HUD"), "History")
	local fake = 1000
	RC._setClock(function()
		return fake
	end)
	-- o relógio falso acompanha cada instante (o loop real de 0,25 s também lê este relógio)
	local function at(t: number)
		fake = t
		RC._historyAt(t)
	end
	local function rolled(t: number)
		fake = t
		RC._historyRolled(t)
	end
	local function chips()
		local list = {}
		for _, chip in (row and row:GetChildren()) or {} do
			if chip:IsA("Frame") then
				table.insert(list, { chip = chip, view = chip:FindFirstChild("Preview", true) })
			end
		end
		return list
	end
	rolled(1000)
	check(RC.HistoryShown() and row:GetAttribute("AutoHidden") == false, "rolls recentes: T=0 roll -> visível")
	at(1019.9)
	check(RC.HistoryShown(), "rolls recentes: 19,9 s sem roll -> continua visível")
	local before = chips()
	local st0 = Preview.stats()
	at(1020)
	check(not RC.HistoryShown() and row:GetAttribute("AutoHidden") == true, "rolls recentes: 20,0 s sem roll -> esconde")
	task.wait(0.4)
	Preview.update()
	local faded, intact = true, #before > 0
	for _, item in before do
		local view = item.view
		if view and view:IsA("ViewportFrame") then
			faded = faded and view.ImageTransparency >= 0.99
		end
		intact = intact and item.chip.Parent == row and (item.view == nil or item.view.Parent ~= nil)
	end
	local st1 = Preview.stats()
	check(faded and intact and row.Visible, "rolls recentes: escondida por FADE (a faixa e os chips continuam montados; Visible não muda)")
	check(st1.created == st0.created and st1.destroyed == st0.destroyed and st1.viewportsCreated == st0.viewportsCreated and st1.viewportsDestroyed == st0.viewportsDestroyed,
		string.format("rolls recentes: esconder não cria/destrói previews (created %d->%d, destroyed %d->%d, viewports +%d/-%d)", st0.created, st1.created, st0.destroyed, st1.destroyed, st1.viewportsCreated - st0.viewportsCreated, st1.viewportsDestroyed - st0.viewportsDestroyed))
	rolled(1030)
	local back = RC.HistoryShown()
	local restored, same = true, true
	for i, item in chips() do
		local view = item.view
		if view and view:IsA("ViewportFrame") then
			restored = restored and view.ImageTransparency < 0.99
		end
		same = same and before[i] ~= nil and item.view == before[i].view
	end
	Preview.update()
	local st2 = Preview.stats()
	check(back and restored and same, "rolls recentes: novo roll -> reaparece NA HORA com os MESMOS retratos")
	check(st2.created == st0.created and st2.destroyed == st0.destroyed and st2.viewportsCreated == st0.viewportsCreated and st2.viewportsDestroyed == st0.viewportsDestroyed,
		"rolls recentes: reaparecer reutiliza tudo (PreviewCreated = 0, PreviewDestroyed = 0)")
	rolled(1040) -- roll aos 10 s do anterior
	at(1059)
	local at29 = RC.HistoryShown()
	at(1060)
	check(at29 and not RC.HistoryShown(), "rolls recentes: roll no meio reinicia (19 s do 2º visível; 20 s do 2º esconde)")
	local alwaysOn = true
	for t = 2000, 2120, 0.5 do
		rolled(t)
		at(t + 0.45)
		alwaysOn = alwaysOn and RC.HistoryShown()
	end
	check(alwaysOn, "rolls recentes: AUTO/Roll Rápido rolando sem parar nunca esconde")
	-- roll DE VERDADE (botão) também reinicia o contador
	fake = 5000
	local count0 = #RC.History()
	task.wait(1.1)
	click(rollButton)
	Env.waitFor(function()
		return #RC.History() > count0 or count0 >= 10
	end, 3)
	fake = 5019.9
	RC._historyAt(5019.9)
	local onReal = RC.HistoryShown()
	fake = 5020
	RC._historyAt(5020)
	check(onReal and not RC.HistoryShown(), "rolls recentes: roll pelo botão reinicia o contador de 20 s")
	RC._setClock(os.clock)
	RC._historyRolled(os.clock())
end

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
	if stage and stage:GetAttribute("Stage") == "World" then
		-- Divino/Secreto: palco NO MUNDO (local), para a Aura Full renderizar (viewport não renderiza partículas)
		local world = env.real.Workspace:FindFirstChild("JackpotStage")
		check(world ~= nil and find(world, case[2]) ~= nil, case[1] .. ": palco local no mundo com o personagem")
	else
		check(stage ~= nil and find(stage, "Stage") ~= nil and find(stage, case[2]) ~= nil, case[1] .. ": palco local com o personagem")
	end
	local continue = stage and find(stage, "Continue")
	check(Env.waitFor(function()
		return continue ~= nil and continue.Visible
	end, 9), case[1] .. ": botão CONTINUAR aparece")
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

do
	-- JACKPOT REVEAL (Divino/Secreto): câmera real, Aura Full no impacto, HUD some e volta,
	-- tudo restaurado no fim; OCULTAR não esconde Divino/Secreto
	local RevealCfg = clientRequire(env.shared.Config.RevealConfig)
	local CharCfg = clientRequire(env.shared.Config.CharacterConfig)
	local function firstOf(rarity: string): string
		for _, c in CharCfg.List do
			if c.Rarity == rarity then
				return c.Id
			end
		end
		error("sem " .. rarity)
	end
	local divineId, secretId = firstOf("Divine"), firstOf("Secret")
	local function hudEnabled(): number
		local n = 0
		for _, g in playerGui:GetChildren() do
			if g:IsA("ScreenGui") and g.Enabled and g.Name ~= "HeroLanding" then
				n += 1
			end
		end
		return n
	end
	for _, case in { { "Divine", divineId }, { "Secret", secretId } } do
		local rarity, id = case[1], case[2]
		local preset = RevealCfg.Cinematics[rarity]
		local hudBefore = hudEnabled()
		local typeBefore = camera.CameraType
		local fovBefore = camera.FieldOfView
		local posBefore = camera.CFrame.Position
		playDev(rarity, id)
		check(Env.waitFor(function()
			return gui("HeroLanding") ~= nil
		end, 2), rarity .. " (jackpot): começou")
		local stage = gui("HeroLanding")
		local world = env.real.Workspace:FindFirstChild("JackpotStage")
		local model = world and find(world, id)
		check(camera.CameraType == roblox.Enum.CameraType.Scriptable and hudEnabled() == 0, rarity .. " (jackpot): câmera real em Scriptable e HUD escondido durante a apresentação")
		-- queda VISÍVEL: o personagem começa bem alto e desce
		local startY = model and model:GetPivot().Position.Y
		task.wait(preset.FallStart + 0.25)
		local midY = model and model:GetPivot().Position.Y
		local groundY = RevealCfg.JackpotStage.Position[2]
		check(startY ~= nil and midY ~= nil and midY > groundY + 5 and midY < startY, string.format("%s (jackpot): queda visível (%.0f -> %.0f, chão %d)", rarity, startY or -1, midY or -1, groundY))
		-- impacto: Aura FULL no próprio personagem do palco (no mundo, partículas renderizam)
		check(Env.waitFor(function()
			return model ~= nil and model:GetAttribute("AuraMode") == "Full"
		end, preset.Impact + 2), rarity .. " (jackpot): Aura " .. rarity .. " Full entra no impacto")
		local onAt, total = 0, 0
		for _, d in (model :: any):GetDescendants() do
			-- rajadas (AuraRole Burst) são disparadas por :Emit, nunca ficam ligadas
			if d:IsA("ParticleEmitter") and string.sub(d.Name, 1, 4) == "Aura" and d:GetAttribute("AuraRole") ~= "Burst" then
				total += 1
				if d.Enabled then
					onAt += 1
				end
			end
		end
		if preset.AuraEntry == "Layers" then
			check(total > 0 and onAt < total, string.format("Secret (jackpot): aura entra em CAMADAS (%d/%d emissores ligados logo após o impacto)", onAt, total))
			check(Env.waitFor(function()
				local on = 0
				for _, d in (model :: any):GetDescendants() do
					if d:IsA("ParticleEmitter") and string.sub(d.Name, 1, 4) == "Aura" and d:GetAttribute("AuraRole") ~= "Burst" and d.Enabled then
						on += 1
					end
				end
				return on == total
			end, 3), "Secret (jackpot): todas as camadas da aura ligadas em seguida")
		else
			check(total > 0 and onAt == total, string.format("Divine (jackpot): Aura Full inteira no impacto (%d/%d)", onAt, total))
		end
		check(find(world, "GroundRing") ~= nil and find(world, "ImpactSparks") ~= nil, rarity .. " (jackpot): anel no chão + faíscas do impacto")
		local continue = stage and find(stage, "Continue")
		check(Env.waitFor(function()
			return continue ~= nil and continue.Visible
		end, 9), rarity .. " (jackpot): CONTINUAR aparece")
		local rarityLabel = stage and find(stage, "Rarity")
		local nameLabel = stage and find(stage, "Name")
		check(rarityLabel ~= nil and rarityLabel.Text ~= "" and nameLabel ~= nil and nameLabel.Text ~= "", rarity .. " (jackpot): nome + raridade dentro da apresentação")
		if continue then
			click(continue)
		end
		check(Env.waitFor(function()
			return gui("HeroLanding") == nil and not C.RevealController.Busy()
		end, 2), rarity .. " (jackpot): termina")
		check(env.real.Workspace:FindFirstChild("JackpotStage") == nil and camera:FindFirstChild("JackpotGrade") == nil, rarity .. " (jackpot): palco e pós-efeito destruídos")
		check(camera.CameraType == typeBefore and camera.FieldOfView == fovBefore and (camera.CFrame.Position - posBefore).Magnitude < 0.01 and hudEnabled() == hudBefore, rarity .. " (jackpot): câmera (tipo, FOV, enquadramento) e HUD restaurados exatamente")
	end
	-- morrer no meio do Secreto: limpa tudo e devolve a câmera
	local typeBefore = camera.CameraType
	playDev("Secret", secretId)
	check(Env.waitFor(function()
		return gui("HeroLanding") ~= nil
	end, 2), "Secret (jackpot): para teste de morte")
	task.wait(0.4)
	player.CharacterRemoving:Fire()
	check(Env.waitFor(function()
		return gui("HeroLanding") == nil and env.real.Workspace:FindFirstChild("JackpotStage") == nil
	end, 2) and camera.CameraType == typeBefore, "morrer no meio do Secreto: palco destruído e câmera devolvida")
	Env.waitFor(function()
		return not C.RevealController.Busy()
	end, 2)
	-- OCULTAR ligado: Divino ainda toca a apresentação completa (evento excepcional)
	task.spawn(DataController.SetSetting, "HideRollAnimation", true)
	Env.waitFor(function()
		return (DataController.Get("Settings") or {}).HideRollAnimation == true
	end, 2)
	playDev("Divine", divineId)
	check(Env.waitFor(function()
		local g = gui("HeroLanding")
		return g ~= nil and g:GetAttribute("Stage") == "World"
	end, 2), "OCULTAR ligado: Divino ainda toca o Jackpot Reveal")
	C.RevealController.Cancel()
	Env.waitFor(function()
		return not C.RevealController.Busy() and gui("HeroLanding") == nil
	end, 2)
	task.spawn(DataController.SetSetting, "HideRollAnimation", false)
	Env.waitFor(function()
		return (DataController.Get("Settings") or {}).HideRollAnimation == false
	end, 2)
end

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
do -- MOCHILA sem "mini F5": trocar a seleção / modo venda NÃO recria cards nem retratos
	local Preview = _G.__previewModule
	Preview.update()
	local function snapshot()
		local map = {}
		for _, d in inv.content:GetDescendants() do
			if d:IsA("TextButton") and string.match(d.Name, "^c%d+$") then
				map[d.Name] = { button = d, view = d:FindFirstChild("Preview", true), model = (function()
					local v = d:FindFirstChild("Preview", true)
					return v and v:FindFirstChildOfClass("Model")
				end)() }
			end
		end
		return map
	end
	local function stable(a, b)
		local n = 0
		for uid, x in a do
			local y = b[uid]
			if not y or y.button ~= x.button or y.view ~= x.view or (x.model and y.model ~= x.model) then
				return false, uid
			end
			n += 1
		end
		return n > 0, n
	end
	local s0, st0 = snapshot(), Preview.stats()
	local uids = {}
	for uid in s0 do
		table.insert(uids, uid)
	end
	table.sort(uids)
	for _, uid in { uids[1], uids[2], uids[#uids], uids[1] } do
		click(s0[uid].button)
		task.wait(0.05)
	end
	Preview.update()
	local s1, st1 = snapshot(), Preview.stats()
	local ok, n = stable(s0, s1)
	check(ok and C.InventoryController.Selected() == uids[1], string.format("MOCHILA: trocar seleção X→Y→Z não recria cards nem retratos (%s cards estáveis)", tostring(n)))
	check(st1.viewportsCreated == st0.viewportsCreated and st1.viewportsDestroyed == st0.viewportsDestroyed and st1.created == st0.created and st1.destroyed == st0.destroyed,
		string.format("MOCHILA: seleção = 0 ViewportFrames/modelos criados ou destruídos (criados %d, destruídos %d)", st1.created - st0.created, st1.destroyed - st0.destroyed))
	-- modo venda: marcar, desmarcar, SELECIONAR DUPLICATAS e sair
	local header = find(inv.content, "Header")
	click(find(header, "SellMode"))
	click(s0[uids[2]].button)
	click(s0[uids[2]].button)
	click(s0[uids[#uids]].button)
	click(find(find(inv.content, "SaleFooter"), "SelectDuplicates"))
	click(find(find(inv.content, "SaleFooter"), "CancelSale"))
	Preview.update()
	local s2, st2 = snapshot(), Preview.stats()
	ok, n = stable(s0, s2)
	check(ok and st2.viewportsCreated == st0.viewportsCreated and st2.created == st0.created,
		"MOCHILA: venda em massa (marcar/desmarcar/duplicatas/cancelar) não reconstrói a grade nem os retratos")
	-- abrir/fechar o painel de detalhes (✕) também não mexe na grade
	click(s0[uids[1]].button)
	C.InventoryController.Select(nil)
	Preview.update()
	ok = stable(s0, snapshot())
	check(ok and Preview.stats().viewportsCreated == st0.viewportsCreated, "MOCHILA: abrir/fechar detalhes não invalida os retratos")
	check(Preview.stats().active <= Preview.MaxActive and Preview.stats().pooled <= Preview.MaxPooled, "MOCHILA: limites do pool/ativos preservados")
end
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
	model.Parent = env.real.Workspace
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
	-- V2: 12 auras Mítico+ perto da câmera -> contornos (Highlight) limitados a MaxHighlights;
	-- órbitas com raios/alturas diferentes; nenhuma conexão/instância órfã ao remover
	local AuraCfgC = clientRequire(env.shared.Config.AuraConfig)
	local CharCfgC = clientRequire(env.shared.Config.CharacterConfig)
	local divineId
	for _, c in CharCfgC.List do
		if c.Rarity == "Divine" then
			divineId = c.Id
			break
		end
	end
	local models = {}
	for i = 1, 12 do
		local m = Factory.build(divineId, { vfx = "Light" })
		m:PivotTo(roblox.CFrame.new(i * 6, 0, 0))
		m.Parent = env.real.Workspace
		table.insert(models, m)
	end
	task.wait(0.1)
	C.AuraController._step(0.6)
	local outlines = C.AuraController.Outlines()
	local radii, heights = {}, {}
	for _, d in models[1]:GetDescendants() do
		if d:IsA("Attachment") and d:GetAttribute("AuraRole") == "Orbit" then
			radii[d:GetAttribute("AuraRadius")] = true
			heights[d:GetAttribute("AuraHeight")] = true
		end
	end
	local nR, nH = 0, 0
	for _ in radii do
		nR += 1
	end
	for _ in heights do
		nH += 1
	end
	check(outlines >= 1 and outlines <= AuraCfgC.Budget.MaxHighlights, string.format("auras V2: %d contornos ligados para 12 auras (teto %d)", outlines, AuraCfgC.Budget.MaxHighlights))
	check(nR >= 2 and nH >= 2, "auras V2: órbitas com raios e alturas diferentes (nada sincronizado)")
	local orbitV2
	for _, d in models[1]:GetDescendants() do
		if d:IsA("Attachment") and d:GetAttribute("AuraRole") == "Orbit" then
			orbitV2 = d
		end
	end
	local p0 = orbitV2 and orbitV2.Position
	C.AuraController._step(0.15)
	check(orbitV2 ~= nil and (orbitV2.Position - p0).Magnitude > 0.05, "auras V2: órbita do Divino se move no loop central")
	local before = C.AuraController.Count()
	for _, m in models do
		m:Destroy()
	end
	task.wait(0.1)
	C.AuraController._step(0.6)
	local after = C.AuraController.Count()
	check(after <= before - 12 and C.AuraController.Outlines() == 0, string.format("auras V2: remover as auras libera o controlador (%d -> %d registradas, 0 contornos)", before, after))
end

do -- Letreiros entre andares (LodController + FloorLegibility): outro andar não polui o do jogador
	local function fakeStation(floorY: number)
		local station = Instance.new("Model")
		station:SetAttribute("FloorY", floorY)
		local anchor = Instance.new("Part")
		anchor.Name = "InfoAnchor"
		anchor.Parent = station
		local info = Instance.new("BillboardGui")
		info.Name = "Info"
		info.Parent = anchor
		local detail = Instance.new("Frame")
		detail.Name = "Detail"
		detail.Parent = info
		local plate = Instance.new("Part")
		plate.Name = "Plate"
		plate.Parent = station
		local plateGui = Instance.new("BillboardGui")
		plateGui.Name = "PlateGui"
		plateGui.Parent = plate
		local pad = Instance.new("Part")
		pad.Name = "UpgradePad"
		pad.Parent = station
		local cost = Instance.new("BillboardGui")
		cost.Name = "Cost"
		cost.Parent = pad
		return station, info, detail, plateGui, cost
	end
	local H = 20
	local same, sInfo, sDetail, sPlate, sCost = fakeStation(10)
	local above, aInfo, aDetail, aPlate, aCost = fakeStation(10 + H)
	local twoUp, tInfo = fakeStation(10 + 2 * H)
	local feet = 10.2 -- jogador no Floor01
	C.LodController._apply(same, 10, false, feet)
	C.LodController._apply(above, 10, false, feet)
	C.LodController._apply(twoUp, 10, false, feet)
	check(sInfo.Enabled and sDetail.Visible and sPlate.Enabled and sCost.Enabled, "andares: no andar do jogador o letreiro fica completo (perto)")
	check(aInfo.Enabled and not aDetail.Visible and not aPlate.Enabled and not aCost.Enabled, "andares: andar de cima só mostra a renda (sem nome/raridade/nível, sem placa MÁX/custo)")
	check(not tInfo.Enabled, "andares: 2 andares acima, letreiro oculto")
	-- o jogador sobe para o Floor02: a regra se inverte (nada fixo no andar)
	feet = 10 + H + 0.2
	C.LodController._apply(same, 10, false, feet)
	C.LodController._apply(above, 10, false, feet)
	check(aInfo.Enabled and aDetail.Visible and aPlate.Enabled and not sDetail.Visible and not sPlate.Enabled and sInfo.Enabled, "andares: no Floor02 o letreiro dele volta completo e o do Floor01 fica só com a renda")
	-- sem personagem: nada é escondido
	C.LodController._apply(twoUp, 10, false, nil)
	check(tInfo.Enabled, "andares: sem personagem, nada é escondido")
end

do -- LOD DE AURA NUNCA SOME COM O PERSONAGEM: 10 estações, perto -> longe -> perto e troca de andar
	local Factory = clientRequire(env.shared.Modules.CharacterModelFactory)
	local CharCfg = clientRequire(env.shared.Config.CharacterConfig)
	local AuraCfgL = clientRequire(env.shared.Config.AuraConfig)
	local picks = {}
	for _, rarity in { "Legendary", "Mythic", "Divine", "Secret" } do
		for _, c in CharCfg.List do
			if c.Rarity == rarity then
				table.insert(picks, c.Id)
				break
			end
		end
	end
	local stations = {}
	for i = 1, 10 do
		local station = Instance.new("Model")
		station.Name = "LodStation" .. i
		station:SetAttribute("FloorY", 0)
		local figure = Factory.build(picks[(i - 1) % #picks + 1], { vfx = "Light" })
		figure:PivotTo(roblox.CFrame.new(i * 12, 0, 0))
		figure.Parent = station
		local anchor = Instance.new("Part")
		anchor.Name = "InfoAnchor"
		anchor.CFrame = roblox.CFrame.new(i * 12, 8, 0)
		anchor.Parent = station
		local info = Instance.new("BillboardGui")
		info.Name = "Info"
		info.Parent = anchor
		station.Parent = env.real.Workspace
		local parts = {}
		for _, d in figure:GetDescendants() do
			if d:IsA("BasePart") and string.sub(d.Name, 1, 4) ~= "Aura" then
				table.insert(parts, { part = d, transparency = d.Transparency })
			end
		end
		table.insert(stations, { station = station, figure = figure, parts = parts })
	end
	local function allVisible(): (boolean, string)
		for i, s in stations do
			if s.figure.Parent ~= s.station or s.station.Parent == nil then
				return false, "estação " .. i .. ": modelo fora da estação"
			end
			for _, p in s.parts do
				if p.part.Parent == nil or p.part.Transparency ~= p.transparency then
					return false, "estação " .. i .. ": parte " .. p.part.Name .. " escondida/removida"
				end
			end
		end
		return true, ""
	end
	local function auraOn(s): number
		local on = 0
		for _, d in s.figure:GetDescendants() do
			if d:IsA("ParticleEmitter") and d:GetAttribute("VFXTier") ~= nil and d.Enabled then
				on += 1
			end
		end
		return on
	end
	local function frame(distance: number, feet: number?)
		camera.CFrame = roblox.CFrame.new(60, 6, -distance)
		for i, s in stations do
			local d = (roblox.Vector3.new(i * 12, 8, 0) - camera.CFrame.Position).Magnitude
			C.LodController._apply(s.station, d, false, feet)
		end
		task.wait(0.05)
		C.AuraController._step(0.6)
	end
	local ok, why
	frame(15)
	ok, why = allVisible()
	check(ok, "LOD perto: os 10 personagens visíveis " .. why)
	check(auraOn(stations[5]) > 0, "LOD perto: aura ligada")
	local _, active = C.AuraController.Count()
	check(active <= AuraCfgL.Budget.MaxAnimated, "LOD: no máximo MaxAnimated auras animadas (" .. active .. ")")
	frame(400)
	ok, why = allVisible()
	check(ok, "LOD longe (além do Cull): personagens continuam visíveis, só a aura apaga " .. why)
	check(auraOn(stations[5]) == 0, "LOD longe: aura desligada")
	frame(15)
	ok, why = allVisible()
	check(ok and auraOn(stations[5]) > 0, "LOD perto de novo: personagens visíveis e aura volta " .. why)
	frame(15, 0 + 40) -- jogador 2 andares acima
	ok, why = allVisible()
	check(ok, "troca de andar: personagens do outro andar continuam visíveis " .. why)
	frame(15, 0)
	ok, why = allVisible()
	check(ok, "volta ao andar: nenhum personagem sumiu " .. why)
	check(AuraCfgL.Budget.DistanceRates[1][2] == 1 and C.AuraController.distanceRate(100) > 0 and C.AuraController.distanceRate(100) < C.AuraController.distanceRate(10), "taxa por distância progressiva (100% perto, cai até o Cull, nunca zero dentro dele)")
	for _, s in stations do
		s.station:Destroy()
	end
	task.wait(0.05)
	C.AuraController._step(0.6)
end

do -- AURA MOTION: fitas vivas, presas ao personagem (andar/virar/teleporte/andar de prédio), sem acumular
	local Factory = clientRequire(env.shared.Modules.CharacterModelFactory)
	local CharCfg = clientRequire(env.shared.Config.CharacterConfig)
	local divine
	for _, c in CharCfg.List do
		if c.Rarity == "Divine" then
			divine = c.Id
			break
		end
	end
	local model = Factory.build(divine, { vfx = "Full" })
	model:PivotTo(roblox.CFrame.new(0, 0, 0))
	model.Parent = env.real.Workspace
	camera.CFrame = roblox.CFrame.new(0, 6, -20)
	task.wait(0.05)
	C.AuraController._step(0.6)
	local stats = C.AuraController.Stats()
	local shapes = {}
	for _, d in model:GetDescendants() do
		if d:IsA("Beam") and d:GetAttribute("MotionIndex") ~= nil then
			table.insert(shapes, { beam = d, p0 = d.Attachment1.Position, w = d.Width0, c = d.CurveSize0 })
		end
	end
	check(#shapes >= 3 and stats.shapes >= #shapes, string.format("aura motion: %d fitas animadas no loop central (Stats %d)", #shapes, stats.shapes))
	C.AuraController._step(0.35)
	local moved, curved = 0, 0
	for _, sh in shapes do
		if (sh.beam.Attachment1.Position - sh.p0).Magnitude > 0.02 then
			moved += 1
		end
		if math.abs(sh.beam.CurveSize0 - sh.c) > 0.01 then
			curved += 1
		end
	end
	check(moved == #shapes and curved == #shapes, "aura motion: as PONTAS das fitas se movem (não só a curvatura) e a curvatura muda")
	local function attachedWithin(): boolean
		local pivot = model:GetPivot()
		for _, sh in shapes do
			for _, a in { sh.beam.Attachment0, sh.beam.Attachment1 } do
				local world = a.Parent.CFrame:PointToWorldSpace(a.Position)
				if (world - pivot.Position).Magnitude > 25 then
					return false
				end
			end
		end
		return true
	end
	-- andando/virando/teleporte/andar de cima: tudo é relativo ao AuraCore -> acompanha
	for _, target in { roblox.CFrame.new(3, 0, 2), roblox.CFrame.new(3, 0, 2) * roblox.CFrame.Angles(0, math.pi / 2, 0), roblox.CFrame.new(800, 40, -600), roblox.CFrame.new(800, 60, -600) } do
		model:PivotTo(target)
		camera.CFrame = target * roblox.CFrame.new(0, 6, -20)
		C.AuraController._step(0.2)
		check(attachedWithin(), "aura motion: fitas continuam presas ao personagem em " .. tostring(target.Position))
	end
	-- horas de animação: nada acumula nem deforma infinitamente
	local bounded = true
	for _ = 1, 300 do
		C.AuraController._step(12.5)
		for _, sh in shapes do
			local r = sh.beam:GetAttribute("MotionRadius") :: number
			for _, a in { sh.beam.Attachment0, sh.beam.Attachment1 } do
				local horizontal = math.sqrt(a.Position.X ^ 2 + a.Position.Z ^ 2)
				bounded = bounded and horizontal <= r * 1.8 and math.abs(a.Position.Y) < 30
			end
			bounded = bounded and sh.beam.Width0 > 0 and sh.beam.Width0 < sh.w * 2.5
		end
	end
	check(bounded, "aura motion: depois de ~1 h de animação nada acumulou (posições/larguras limitadas)")
	local before = C.AuraController.Count()
	model:Destroy()
	task.wait(0.05)
	C.AuraController._step(0.6)
	check(C.AuraController.Count() < before, "aura motion: personagem removido -> aura sai do loop central (nada órfão)")
end

-- Torres: abrir, lutar, animação da batalha, fechar
S.InventoryService.Add(player, "eclipse_sovereign")
local towers = openWindow("Towers")
check(towers ~= nil and towers.isOpen, "TORRES abre")
do -- TORRE: cabeçalho em 2 linhas, AUTO e TIME AUTO separados, chips dentro, em várias larguras
	local top = find(towers.content, "TowerHeader")
	for _, w in { 940, 716, 520, 340 } do
		C.TowerController._layoutFor(w)
		local function r(name)
			local g = top and top:FindFirstChild(name, true)
			return g and { x = g.Position.X.Offset, y = g.Position.Y.Offset, w = g.Size.X.Offset, h = g.Size.Y.Offset }
		end
		local auto, team, label = r("AutoPreference"), r("AutoTeam"), r("TeamLabel")
		local function ov(a, b)
			return a.x < b.x + b.w and b.x < a.x + a.w and a.y < b.y + b.h and b.y < a.y + a.h
		end
		local ok = auto ~= nil and team ~= nil and label ~= nil and auto.y ~= team.y and not ov(auto, team) and not ov(auto, label) and not ov(team, label)
			and auto.x + auto.w <= w and team.x + team.w <= w and auto.h >= 44 and team.h >= 44
		local row = top and top:FindFirstChild("TeamRow")
		for _, chip in (row and row:GetChildren()) or {} do
			if chip:IsA("Frame") then
				local c = { x = chip.Position.X.Offset, y = chip.Position.Y.Offset, w = chip.Size.X.Offset, h = chip.Size.Y.Offset }
				ok = ok and c.x + c.w <= w and c.y + c.h <= top.Size.Y.Offset and not ov(c, team) and not ov(c, auto)
			end
		end
		check(ok, "TORRE cabeçalho " .. w .. ": AUTO e TIME AUTO separados, chips dentro dos limites")
	end
	-- tooltip: dentro da tela e sem cobrir os controles críticos (posicionamento por ResponsiveLayout)
	local L = clientRequire(env.client.UI.ResponsiveLayout)
	local tipRect = L.placeTooltip({ x = 1000, y = 150, w = 150, h = 44 }, 200, 34, 1280, 720, { { x = 1000, y = 200, w = 170, h = 44 } })
	check(tipRect.x + tipRect.w <= 1280 and tipRect.y >= 0 and not L.overlaps(tipRect, { x = 1000, y = 200, w = 170, h = 44 }) and not L.overlaps(tipRect, { x = 1000, y = 150, w = 150, h = 44 }),
		"tooltip da TORRE: dentro da tela, sem cobrir AUTO/TIME AUTO")
end
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
	do -- AUTO/OCULTAR: nenhum texto de resultado acumulado na tela (sem spam de nome/raridade)
		local found = nil
		for _, screen in playerGui:GetChildren() do
			for _, x in screen:GetDescendants() do
				if x:IsA("TextLabel") and x.Visible and x.Name == "RollTip" then
					found = x.Text
				end
			end
		end
		check(found == nil and gui("RevealCompact") == nil, "AUTO + OCULTAR: sem spam de nome/raridade na tela")
	end
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
	-- Jackpot Reveal (Divino) com AUTO + ROLL RÁPIDO + OCULTAR: AUTO pausa (nenhum roll perdido,
	-- duplicado ou em rajada depois) e volta na cadência normal do servidor
	S.PlayerDataService.Set(player, "EquippedDice", "Starter")
	local rt = table.clone(d.Runtime or {})
	rt.FastRoll = true
	S.PlayerDataService.Set(player, "Runtime", rt)
	task.spawn(DataController.SetSetting, "HideRollAnimation", true)
	Env.waitFor(function()
		return (DataController.Get("Settings") or {}).HideRollAnimation == true and (DataController.Get("Runtime") or {}).FastRoll == true
	end, 2)
	RC.SetAuto(true)
	task.wait(1.2)
	local divineAuto
	for _, c in clientRequire(env.shared.Config.CharacterConfig).List do
		if c.Rarity == "Divine" then
			divineAuto = c.Id
			break
		end
	end
	Net.fire("DevReveal", player, { CharacterId = divineAuto, Rarity = "Divine", IsNew = true })
	check(Env.waitFor(function()
		local g = gui("HeroLanding")
		return g ~= nil and g:GetAttribute("Stage") == "World"
	end, 2), "AUTO + ROLL RÁPIDO + OCULTAR: Divino toca o Jackpot Reveal")
	local atStart = d.Rolls
	local peak = atStart
	while gui("HeroLanding") ~= nil do
		peak = math.max(peak, d.Rolls)
		task.wait(0.05)
	end
	-- no máximo o roll que já estava em voo quando a apresentação começou
	check(peak <= atStart + 1, string.format("AUTO pausado durante o Jackpot Reveal (%d -> %d)", atStart, peak))
	local resumeFrom = d.Rolls
	task.wait(1.6)
	local after = d.Rolls - resumeFrom
	check(after >= 1 and after <= 4, string.format("depois do Jackpot Reveal o AUTO volta na cadência (0,5 s), sem rajada de atrasados (%d rolls em 1,6 s)", after))
	RC.SetAuto(false)
	rt = table.clone(d.Runtime)
	rt.FastRoll = false
	S.PlayerDataService.Set(player, "Runtime", rt)
	task.spawn(DataController.SetSetting, "HideRollAnimation", false)
	Env.waitFor(function()
		return not C.RevealController.Busy() and (DataController.Get("Settings") or {}).HideRollAnimation == false
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
	-- Divino agora é Jackpot Reveal: o modelo fica no palco do MUNDO (local), não no viewport
	local worldStage = env.real.Workspace:FindFirstChild("JackpotStage")
	local heroModel = stage and (find(stage, "char_goju_base") or (worldStage and find(worldStage, "char_goju_base")))
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
