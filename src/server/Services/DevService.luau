--!strict
--[[
	DevService: comandos de teste, SÓ no Studio.

	Por que existe: a Barra de comandos do Studio roda em outra máquina Luau. Um require()
	feito nela recebe uma CÓPIA NOVA dos módulos (estado vazio, Init nunca executado).
	Este serviço cria ServerStorage.RollLegendsDev (BindableFunction), que executa os comandos
	no contexto REAL do servidor.

	Uso na Barra de comandos (contexto Servidor):
	    local Dev = game.ServerStorage.RollLegendsDev
	    print(Dev:Invoke("Help"))
	    print(Dev:Invoke("GetPlayerBase", game.Players:GetPlayers()[1]))

	Outros Services registram comandos com DevService.Register(nome, descrição, função).
]]

local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Logger = require(game:GetService("ReplicatedStorage").Shared.Modules.Logger)
local BaseService = require(script.Parent.BaseService)
local PlayerDataService = require(script.Parent.PlayerDataService)

local Shared = game:GetService("ReplicatedStorage").Shared
local CharacterConfig = require(Shared.Config.CharacterConfig)
local Formulas = require(Shared.Modules.GameFormulas)
local Net = require(Shared.Modules.Net)
local InventoryService = require(script.Parent.InventoryService)
local RollService = require(script.Parent.RollService)
local EconomyService = require(script.Parent.EconomyService)
local StationService = require(script.Parent.StationService)
local AnalyticsService = require(script.Parent.AnalyticsService)

local log = Logger.new("Dev")

local DevService = {}

type Command = { description: string, run: (...any) -> any }
local commands: { [string]: Command } = {}

function DevService.Register(name: string, description: string, run: (...any) -> any)
	commands[name] = { description = description, run = run }
end

local function playerBaseInfo(player: Player): string
	local base = BaseService.GetPlayerBase(player)
	if not base then
		return `{player.Name}: sem base`
	end
	local owner = BaseService.GetBaseOwner(base)
	return string.format(
		"%s: %s (BaseId %s, OwnerUserId %s, dono %s)",
		player.Name,
		base.Name,
		tostring(base:GetAttribute("BaseId")),
		tostring(base:GetAttribute("OwnerUserId")),
		if owner then owner.Name else "nil"
	)
end

DevService.Register("Help", "lista os comandos", function()
	local lines = {}
	for name, command in commands do
		table.insert(lines, `{name} — {command.description}`)
	end
	table.sort(lines)
	table.insert(lines, 1, "USO: Play > aba TEST > Current: Server > Barra de comandos:")
	table.insert(lines, 2, '  game.ServerStorage.RollLegendsDev:Invoke("Comando", args...)')
	table.insert(lines, 3, "  ([player] = jogador opcional; sem [ ] o jogador vem primeiro: game.Players:GetPlayers()[1])")
	return table.concat(lines, "\n")
end)
DevService.Register("GetPlayerBase", "(player) base do jogador", playerBaseInfo)
DevService.Register("GetData", "(player, chave) valor salvo do jogador", function(player, key)
	local data = PlayerDataService.GetData(player)
	if not data then
		return "dados não carregados"
	end
	local value = data[key]
	if type(value) == "table" then
		return game:GetService("HttpService"):JSONEncode(value)
	end
	return value
end)
DevService.Register("ShowDummies", "(player|baseId, bool) bonecos de escala nos slots", function(target, show)
	BaseService.Dev.ShowDummies(target, show)
	return "ok"
end)
DevService.Register("PreviewFloors", "(player|baseId, andares) prévia de andares", function(target, floors)
	BaseService.Dev.PreviewFloors(target, floors)
	return "ok"
end)
DevService.Register("ResetBase", "(player|baseId) volta a base ao estado real", function(target)
	BaseService.Dev.Reset(target)
	return "ok"
end)

------------------------------------------------------------------------------------
-- Fases 3–6 + estações / offline / diário / reveal

local function data(player: Player): any
	local d = PlayerDataService.GetData(player)
	assert(d, "dados não carregados")
	return d
end

DevService.Register("GiveMoney", "(player, valor) adiciona dinheiro", function(player, amount)
	return EconomyService.AddMoney(player, amount, "Dev")
end)
DevService.Register("SetRolls", "(player, n) define o total de rolls (requisito dos dados)", function(player, n)
	PlayerDataService.Set(player, "Rolls", n)
	return n
end)
DevService.Register("GiveCharacter", "(player, id, quantidade?, nivel?) dá personagens", function(player, id, count, level)
	assert(CharacterConfig.ById[id], "personagem inválido: " .. tostring(id))
	local uids = {}
	for _ = 1, count or 1 do
		local uid = InventoryService.Add(player, id)
		data(player).Inventory[uid].Level = level or 1
		table.insert(uids, uid)
	end
	InventoryService.SendDelta(player, uids, nil)
	return table.concat(uids, ",")
end)
DevService.Register("Roll", "(player, n) faz n rolls agora (ignora cooldown) e resume", function(player, n)
	local counts = {}
	for _ = 1, n or 1 do
		RollService.ResetCooldown(player)
		local ok, result = pcall(RollService.Roll, player)
		if not ok then
			return "parou: " .. (if type(result) == "table" then tostring((result :: any).code) else tostring(result))
		end
		counts[result.Rarity] = (counts[result.Rarity] or 0) + 1
	end
	return game:GetService("HttpService"):JSONEncode(counts)
end)
DevService.Register("SetPity", "(player, lendario, mitico) contadores de pity", function(player, legendary, mythic)
	PlayerDataService.Set(player, "Pity", { Legendary = legendary or 0, Mythic = mythic or 0 })
	return "ok"
end)
DevService.Register("GetLuck", "(player) Luck efetiva", function(player)
	local d = data(player)
	return string.format("Luck %.2f (efetiva no sorteio %.2f)", Formulas:luck(d, os.time()), Formulas:effectiveLuck(d, os.time()))
end)
DevService.Register("Income", "(player) renda/s e dinheiro não coletado", function(player)
	local d = data(player)
	return string.format("renda %.2f/s, não coletado %.2f, money %d", Formulas:incomePerSecond(d), d.UncollectedMoney, d.Money)
end)
DevService.Register("FillInventory", "(player) enche o inventário de comuns", function(player)
	local free = InventoryService.Capacity(player) - InventoryService.Count(player)
	for _ = 1, free do
		InventoryService.Add(player, "flame_rookie")
	end
	return InventoryService.Count(player)
end)
DevService.Register("ClearInventory", "(player) apaga TODO o inventário", function(player)
	local uids = {}
	for uid in data(player).Inventory do
		table.insert(uids, uid)
	end
	InventoryService.Remove(player, uids)
	return #uids
end)
DevService.Register("PopulateDemoBase", "(player, todos8?) base demo com raridades/níveis/variantes", function(player, all)
	return StationService.PopulateDemo(player, all)
end)
DevService.Register("SimulateOffline", "(player, segundos, renda/s?) simula ter ficado offline", function(player, seconds, ips)
	local d = data(player)
	d.LastLogout = os.time() - seconds
	if ips then
		d.LastKnownIncomePerSecond = ips
	end
	EconomyService._resetOffline(player)
	EconomyService.CheckOffline(player)
	return d.PendingOfflineReward
end)
DevService.Register("SetDaily", "(player, diasAtras, diaDoCiclo) estado do diário", function(player, daysAgo, cycleDay)
	local now = os.time()
	PlayerDataService.Set(player, "LastDailyClaim", if daysAgo then now - daysAgo * 86400 else 0)
	PlayerDataService.Set(player, "DailyCycleDay", cycleDay or 0)
	return "ok"
end)
DevService.Register("PlayReveal", "(player, raridade, personagemId?, novo?) toca o reveal sem RNG", function(player, rarity, id, isNew)
	local chosen = id
	if not chosen then
		for _, c in CharacterConfig.List do
			if c.Rarity == rarity then
				chosen = c.Id
				break
			end
		end
	end
	assert(chosen and CharacterConfig.ById[chosen], "personagem inválido")
	Net.fire("DevReveal", player, { CharacterId = chosen, Rarity = CharacterConfig.ById[chosen].Rarity, IsNew = isNew ~= false })
	return chosen
end)
DevService.Register("PlayAllReveals", "(player) Lendário, Mítico, Divino e Secreto em sequência", function(player)
	Net.fire("DevReveal", player, { All = true })
	return "ok"
end)
DevService.Register("RollHistory", "(player) últimos rolls da sessão", function(player)
	return game:GetService("HttpService"):JSONEncode(RollService.History(player))
end)
DevService.Register("GiveGems", "(player, n) dá gemas", function(player, n)
	return PlayerDataService.Increment(player, "Gems", n)
end)
DevService.Register("GrantPass", "(player, chave) simula ter o gamepass (VIP, LuckX2, BigBackpack, FastRoll)", function(player, key)
	require(script.Parent.MonetizationService).Dev.GrantPass(player, key)
	return "ok"
end)
DevService.Register("DeliverProduct", "(player, chave) entrega um produto sem Robux (MoneySmall, LuckBoost, JackpotSpin...)", function(player, key)
	return require(script.Parent.MonetizationService).Dev.DeliverProduct(player, key)
end)
DevService.Register("Rebirth", "(player) renasce agora (dá o dinheiro necessário)", function(player)
	local d = data(player)
	d.Money = math.max(d.Money, Formulas:rebirthCost(d.Rebirths) or 0)
	return require(script.Parent.RebirthService).Rebirth(player)
end)
DevService.Register("SetTowerFloor", "(player, torre, andar) progresso da torre", function(player, tower, floor)
	local progress = table.clone(data(player).TowerProgress)
	progress[tower] = floor
	PlayerDataService.Set(player, "TowerProgress", progress)
	return "ok"
end)
DevService.Register("SetTutorial", "(player, passos) passos do tutorial feitos (0 = recomeçar, 7 = terminado)", function(player: Player, steps: number)
	PlayerDataService.Set(player, "Tutorial", math.clamp(math.floor(tonumber(steps) or 0), 0, 7))
	return "tutorial = " .. tostring((PlayerDataService.GetData(player) :: any).Tutorial)
end)

-- Tour visual do mapa: posiciona o jogador na altura normal da câmera, olhando para cada área
local MapConfig = require(Shared.Config.MapConfig)
local VISUAL_POINTS: { { name: string, from: { number }, to: { number } } } = {
	{ name = "Hub", from = { 0, -50 }, to = { 0, 0 } },
	{ name = "Base", from = { 0, 0 }, to = { 0, 0 } }, -- calculado: PlayerSpawn da base do jogador
	{ name = "Conveyor", from = { MapConfig.Conveyor.HalfX - 20, -98 }, to = { MapConfig.Conveyor.HalfX + 10, -84 } },
	{ name = "DiceShop", from = { 0, -40 }, to = { 0, -76 } },
	{ name = "Market", from = { -24, -45 }, to = { -38, -68 } },
	{ name = "Sell", from = { 24, -45 }, to = { 38, -68 } },
	{ name = "Fusion", from = { -40, 0 }, to = { -68, 12 } },
	{ name = "Towers", from = { 0, 70 }, to = { 0, 118 } },
	{ name = "Missions", from = { -25, 75 }, to = { -50, 98 } },
	{ name = "Trades", from = { 40, 0 }, to = { 68, 12 } },
	{ name = "Rankings", from = { 25, 75 }, to = { 50, 98 } },
}
DevService.Register("VisualCheck", "(player, ponto?) teleporta para conferir o visual: Hub, Base, Conveyor, DiceShop, Market, Sell, Fusion, Towers, Missions, Trades, Rankings", function(player: Player, point: string?)
	local names = {}
	for _, p in VISUAL_POINTS do
		table.insert(names, p.name)
	end
	local character = player.Character
	if not point or not character then
		return "pontos: " .. table.concat(names, ", ")
	end
	for _, p in VISUAL_POINTS do
		if string.lower(p.name) == string.lower(point) then
			local from = Vector3.new(p.from[1], 4, p.from[2])
			local to = Vector3.new(p.to[1], 4, p.to[2])
			if p.name == "Base" then
				local base = BaseService.GetPlayerBase(player)
				local spawn = base and base:FindFirstChild("PlayerSpawn") :: BasePart?
				if not spawn then
					return "jogador sem base"
				end
				from = spawn.Position + Vector3.new(0, 4, 0)
				to = from + spawn.CFrame.LookVector * 20
			end
			character:PivotTo(CFrame.lookAt(from, Vector3.new(to.X, from.Y, to.Z)))
			return "teleportado para " .. p.name
		end
	end
	return "ponto desconhecido; " .. table.concat(names, ", ")
end)

------------------------------------------------------------------------------------
-- Pipeline de personagens (PILOTO): galeria, variantes, poses e checagens

local CharacterAssetConfig = require(Shared.Config.CharacterAssetConfig)
local CharacterModelFactory = require(Shared.Modules.CharacterModelFactory)
local CharacterAssetPipeline = require(Shared.Modules.CharacterAssetPipeline)
local VariantConfigDev = require(Shared.Config.VariantConfig)
local IndexService = require(script.Parent.IndexService)

-- O jogador é OPCIONAL nos comandos dos pilotos: na Barra de comandos basta
--   game.ServerStorage.RollLegendsDev:Invoke("ShowCharacterVariants", "char_ichiro_base")
-- Se o 1º argumento for um jogador, ele é usado; senão, o primeiro jogador do servidor.
local function splitPlayer(...: any): (Player?, ...any)
	local first = ...
	local isPlayer = (typeof(first) == "Instance" and first:IsA("Player")) or (type(first) == "table" and first.UserId ~= nil)
	if isPlayer then
		return ...
	end
	return game:GetService("Players"):GetPlayers()[1], ...
end

-- Área livre no caminho sul (entre a Loja de Dados e a entrada), longe das bases
local GALLERY_Z = -205
local GALLERY_SPACING = 7

local function galleryFolder(): Folder
	local old = workspace:FindFirstChild("DevGallery")
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "DevGallery"
	folder.Parent = workspace
	return folder
end

local function galleryLabel(model: Model, title: string, subtitle: string)
	local anchor = model:FindFirstChild("Head")
	if not anchor or not anchor:IsA("BasePart") then
		return
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "GalleryLabel"
	gui.Size = UDim2.fromOffset(220, 60)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 4, 0)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.Parent = anchor
	for i, text in { title, subtitle } do
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 0.5)
		label.Position = UDim2.fromScale(0, (i - 1) * 0.5)
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
		label.TextColor3 = if i == 1 then Color3.new(1, 1, 1) else Color3.fromRGB(255, 220, 120)
		label.TextStrokeTransparency = 0
		label.Text = text
		label.Parent = gui
	end
end

-- Coloca uma fileira de personagens virados para +Z e o jogador olhando para eles
local function showRow(player: Player?, entries: { { id: string, title: string, subtitle: string, opts: any, pose: string? } }): string
	local folder = galleryFolder()
	local floor = Instance.new("Part")
	floor.Name = "GalleryFloor"
	floor.Anchored = true
	floor.CanCollide = true
	floor.Size = Vector3.new(#entries * GALLERY_SPACING + 6, 1, 12)
	floor.CFrame = CFrame.new(0, 0.5, GALLERY_Z)
	floor.Color = Color3.fromRGB(60, 55, 80)
	floor.Parent = folder
	local width = (#entries - 1) * GALLERY_SPACING
	for i, entry in entries do
		local target = CFrame.new(-width / 2 + (i - 1) * GALLERY_SPACING, 1, GALLERY_Z) * CFrame.Angles(0, math.pi, 0)
		local model = CharacterModelFactory.spawn(entry.id, target, entry.opts)
		if entry.pose then
			CharacterModelFactory.pose(model, entry.pose)
		end
		galleryLabel(model, entry.title, entry.subtitle)
		model.Parent = folder
	end
	local character = player and player.Character
	if character then
		character:PivotTo(CFrame.lookAt(Vector3.new(0, 5, GALLERY_Z + 22), Vector3.new(0, 4, GALLERY_Z)))
	end
	return `{#entries} modelos em Workspace.DevGallery`
end

local function assetStatus(id: string): string
	return if CharacterModelFactory.hasAsset(id) then "asset" else "PLACEHOLDER"
end

DevService.Register("CharacterGallery", "([player], vfx?) pilotos lado a lado no Workspace (asset ou placeholder)", function(...)
	local player, vfx = splitPlayer(...)
	local entries = {}
	for _, character in CharacterConfig.Pilots do
		table.insert(entries, {
			id = character.Id,
			title = character.Name,
			subtitle = `{character.Rarity} · {assetStatus(character.Id)}`,
			opts = { vfx = vfx or CharacterAssetConfig.VFXModes.Gallery },
		})
	end
	return showRow(player, entries)
end)
DevService.Register("ShowCharacterVariants", "([player], characterId, vfx?) as 7 variantes lado a lado", function(...)
	local player, id, vfx = splitPlayer(...)
	assert(CharacterConfig.ById[id], "personagem inválido: " .. tostring(id))
	local entries = {}
	for _, variant in VariantConfigDev.List do
		table.insert(entries, { id = id, title = variant.Id, subtitle = CharacterConfig.ById[id].Name, opts = { variant = variant.Id, vfx = vfx or "Light" } })
	end
	return showRow(player, entries)
end)
DevService.Register("ShowCharacterPoses", "([player], characterId) Idle/Reveal/Combat/Crouch/Confident", function(...)
	local player, id = splitPlayer(...)
	assert(CharacterConfig.ById[id], "personagem inválido: " .. tostring(id))
	local entries = {}
	for _, pose in { "Idle", "Reveal", "Combat", "Crouch", "Confident" } do
		table.insert(entries, { id = id, title = pose, subtitle = CharacterConfig.ById[id].Name, opts = { vfx = "None" }, pose = pose })
	end
	return showRow(player, entries)
end)
DevService.Register("ClearGallery", "() remove Workspace.DevGallery", function()
	local old = workspace:FindFirstChild("DevGallery")
	if old then
		old:Destroy()
	end
	return "ok"
end)
DevService.Register("GivePilots", "([player], variante?) 1 de cada piloto no inventário (e no Índice)", function(...)
	local player, variant = splitPlayer(...)
	assert(player, "nenhum jogador no servidor (entre em Play)")
	local uids = {}
	for _, character in CharacterConfig.Pilots do
		table.insert(uids, InventoryService.Add(player, character.Id, variant))
		IndexService.Register(player, character.Id, variant or "Normal")
	end
	InventoryService.SendDelta(player, uids, nil)
	return `{#uids} pilotos adicionados`
end)
DevService.Register("CharacterAssetReport", "() status dos assets dos pilotos (validação do runtime)", function()
	CharacterModelFactory.clearCache()
	local folder = game:GetService("ReplicatedStorage"):FindFirstChild(CharacterAssetConfig.StorageName)
	local lines = { `ReplicatedStorage.{CharacterAssetConfig.StorageName}: {if folder then #folder:GetChildren() .. " assets" else "AUSENTE (rode python tools/build_characters.py)"}` }
	for _, character in CharacterConfig.Pilots do
		local template = folder and folder:FindFirstChild(character.Id)
		local problems, warnings = {}, {}
		if template then
			problems, warnings = CharacterAssetPipeline.validate(template)
		end
		local status = if not template then "sem asset (placeholder)" elseif #problems > 0 then "INVÁLIDO: " .. problems[1] elseif #warnings > 0 then "AVISO: " .. warnings[1] else "OK"
		local parts = template and template:GetAttribute("PartCount") or "-"
		table.insert(lines, `{character.Id} ({character.Name}, {character.Rarity}): {status} · peças {parts}`)
	end
	return table.concat(lines, "\n")
end)
-- Roupa dos assets: cada template é IMAGEM (ok), ITEM da loja (Shirt/Pants: imagem descoberta
-- pelo HumanoidDescription) ou falha ao carregar. Imprime as linhas para ClothingTemplateOverrides.
--[[
	ClothingCheck: diagnóstico das roupas, em SEGUNDO PLANO (nunca prende o Invoke da Barra de
	comandos). As APIs usadas esperam a rede e NÃO têm timeout/cancelamento no Roblox:
	  MarketplaceService:GetProductInfo, ContentProvider:PreloadAsync,
	  Players:CreateHumanoidModelFromDescription, InsertService:LoadAsset.
	Por isso cada chamada roda numa thread própria; o diagnóstico só PARA DE ESPERAR depois de
	CLOTHING_WAIT segundos (marca "SEM RESPOSTA") e segue para a próxima. Se a chamada responder
	depois, o resultado tardio também é registrado. Progresso no Output: "[ClothingCheck] ...".
	    game.ServerStorage.RollLegendsDev:Invoke("ClothingCheck")                      -- todas as roupas
	    game.ServerStorage.RollLegendsDev:Invoke("ClothingCheck", "2065247269", "2065252088")
	    game.ServerStorage.RollLegendsDev:Invoke("ClothingCheckStatus")                -- resultado
	Classificação: A = imagem utilizável · B = item da loja (Shirt/Pants) que aponta para uma imagem
	· C = removido/moderado/privado · D = consulta indisponível/sem resposta · E = outro formato.
	Nada é aplicado automaticamente: os overrides sugeridos só entram no config com aprovação.
]]
local ASSET_TYPES = { [1] = "Image", [2] = "TShirt", [11] = "Shirt", [12] = "Pants", [13] = "Decal" }
DevService.ClothingWait = 15 -- segundos esperando cada chamada externa antes de seguir
type ClothingEntry = { id: string, property: string, users: { string }, steps: { string }, class: string?, image: string? }
local clothingJob: { running: boolean, startedAt: number, finishedAt: number?, entries: { ClothingEntry }, log: { string } }? = nil

local function clothingLog(job: any, text: string)
	local line = string.format("[ClothingCheck %5.1fs] %s", os.clock() - job.startedAt, text)
	table.insert(job.log, line)
	print(line)
end

-- Roda fn numa thread própria e espera no máximo "wait" segundos. Devolve (status, ok, valor)
-- status = "done" | "pending". Não cancela a chamada (a API não permite): só para de esperar.
local function callWithWait(job: any, label: string, wait: number, fn: () -> any): (string, boolean?, any)
	local box: { done: boolean, gaveUp: boolean, ok: boolean?, value: any } = { done = false, gaveUp = false }
	clothingLog(job, label .. ": início")
	task.spawn(function()
		local ok, value = pcall(fn)
		box.ok, box.value = ok, value
		if not box.gaveUp then
			box.done = true
		else
			-- já tinha desistido de esperar: registra a resposta tardia
			clothingLog(job, `{label}: respondeu DEPOIS do prazo -> {if ok then tostring(value) else "erro " .. tostring(value)}`)
		end
	end)
	local deadline = os.clock() + wait
	while not box.done and os.clock() < deadline do
		task.wait(0.1)
	end
	if not box.done then
		box.gaveUp = true
		clothingLog(job, `{label}: SEM RESPOSTA em {wait}s (a chamada continua pendente; a API não tem cancelamento)`)
		return "pending", nil, nil
	end
	clothingLog(job, `{label}: fim ({if box.ok then "ok" else "erro: " .. tostring(box.value)})`)
	return "done", box.ok, box.value
end

local function runClothingCheck(job: any)
	local Marketplace = game:GetService("MarketplaceService")
	local PlayersService = game:GetService("Players")
	local ContentProvider = game:GetService("ContentProvider")
	local wait = DevService.ClothingWait
	for _, entry in job.entries do
		clothingLog(job, `checando {entry.property} {entry.id} (usado por {table.concat(entry.users, ", ")})`)
		local numeric = tonumber(entry.id) :: number
		-- 1) Que tipo de asset é esse id?
		local status, ok, info = callWithWait(job, `{entry.id} GetProductInfo`, wait, function()
			return Marketplace:GetProductInfo(numeric, Enum.InfoType.Asset)
		end)
		local kind: string? = nil
		if status == "pending" then
			table.insert(entry.steps, "GetProductInfo sem resposta")
		elseif not ok then
			table.insert(entry.steps, "GetProductInfo erro: " .. tostring(info))
		else
			kind = ASSET_TYPES[info.AssetTypeId] or ("tipo " .. tostring(info.AssetTypeId))
			table.insert(entry.steps, `tipo {kind} ({tostring(info.Name)})`)
		end
		-- 2) A imagem carrega? (PreloadAsync só termina quando o asset carrega ou falha)
		local fetch = "?"
		local pStatus = callWithWait(job, `{entry.id} PreloadAsync`, wait, function()
			ContentProvider:PreloadAsync({ "rbxassetid://" .. entry.id }, function(_, result)
				fetch = tostring(result)
			end)
			return fetch
		end)
		table.insert(entry.steps, if pStatus == "pending" then "PreloadAsync sem resposta" else "carregamento: " .. fetch)
		-- 3) Item da loja: descobre a imagem pelo HumanoidDescription
		if kind == "Shirt" or kind == "Pants" then
			local hStatus, hOk, image = callWithWait(job, `{entry.id} CreateHumanoidModelFromDescription`, wait, function()
				local description = Instance.new("HumanoidDescription")
				if kind == "Shirt" then
					description.Shirt = numeric
				else
					description.Pants = numeric
				end
				local dummy = PlayersService:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R6)
				local found = dummy:FindFirstChildOfClass(kind :: string)
				local result = found and (found :: any)[if kind == "Shirt" then "ShirtTemplate" else "PantsTemplate"]
				dummy:Destroy()
				return result
			end)
			if hStatus == "done" and hOk and image then
				entry.image = image
				table.insert(entry.steps, "imagem do item: " .. tostring(image))
			else
				table.insert(entry.steps, if hStatus == "pending" then "HumanoidDescription sem resposta" else "HumanoidDescription sem imagem")
			end
		end
		-- Classificação
		if kind == "Image" and fetch == tostring(Enum.AssetFetchStatus.Success) then
			entry.class = "A (imagem utilizável)"
		elseif kind == "Shirt" or kind == "Pants" or kind == "TShirt" then
			entry.class = if entry.image then "B (item da loja -> imagem " .. entry.image .. ")" else "B (item da loja; imagem não descoberta)"
		elseif kind == "Image" then
			entry.class = "C? (é imagem, mas não carregou: " .. fetch .. " — removida/moderada?)"
		elseif kind == nil and status == "pending" then
			entry.class = "D (consulta sem resposta no Studio)"
		elseif kind == nil then
			entry.class = "C/D (consulta falhou: " .. table.concat(entry.steps, "; ") .. ")"
		else
			entry.class = "E (" .. kind .. ")"
		end
		clothingLog(job, `RESULTADO {entry.property} {entry.id}: {entry.class}`)
	end
	job.running = false
	job.finishedAt = os.clock()
	clothingLog(job, "terminado. Resumo: game.ServerStorage.RollLegendsDev:Invoke(\"ClothingCheckStatus\")")
end

DevService.Register("ClothingCheck", "(characterId? | ids...) diagnóstico das roupas em segundo plano (veja ClothingCheckStatus)", function(...)
	if clothingJob and clothingJob.running then
		return "ClothingCheck já está rodando; acompanhe o Output ou ClothingCheckStatus"
	end
	local args = { ... }
	local onlyIds: { [string]: boolean } = {}
	local filterIds = false
	local onlyModel: string? = nil
	for _, arg in args do
		if type(arg) == "string" and string.match(arg, "^%d+$") then
			filterIds = true
			onlyIds[arg] = true
		elseif type(arg) == "string" then
			onlyModel = arg
		end
	end
	local folder = game:GetService("ReplicatedStorage"):FindFirstChild(CharacterAssetConfig.StorageName)
	local entries: { ClothingEntry } = {}
	local byId: { [string]: ClothingEntry } = {}
	for _, model in (if folder then folder:GetChildren() else {}) do
		if onlyModel and model.Name ~= onlyModel then
			continue
		end
		for _, clothing in model:GetDescendants() do
			local property = if clothing:IsA("Shirt") then "ShirtTemplate" elseif clothing:IsA("Pants") then "PantsTemplate" else nil
			local id = property and CharacterAssetPipeline.assetIdOf((clothing :: any)[property])
			if property and id and (not filterIds or onlyIds[id]) then
				local entry: ClothingEntry? = byId[id]
				if not entry then
					local created: ClothingEntry = { id = id, property = property, users = {}, steps = {} }
					byId[id] = created
					table.insert(entries, created)
					entry = created
				end
				table.insert((entry :: ClothingEntry).users, model.Name)
			end
		end
	end
	-- ids pedidos que nenhum asset usa também são checados
	for id in onlyIds do
		if not byId[id] then
			table.insert(entries, { id = id, property = "?", users = { "(pedido direto)" }, steps = {} })
		end
	end
	if #entries == 0 then
		return "nenhuma roupa para checar"
	end
	local job = { running = true, startedAt = os.clock(), entries = entries, log = {} }
	clothingJob = job
	clothingLog(job, `start: {#entries} id(s) de roupa, até {DevService.ClothingWait}s por chamada`)
	task.spawn(runClothingCheck, job)
	return `ClothingCheck iniciado ({#entries} id(s)); acompanhe o Output "[ClothingCheck]" ou rode Invoke("ClothingCheckStatus")`
end)
-- Linhas do log do último diagnóstico (testes)
function DevService._clothingLog(): { string }
	return if clothingJob then clothingJob.log else {}
end
DevService.Register("ClothingCheckStatus", "() resultado/andamento do ClothingCheck", function()
	local job = clothingJob
	if not job then
		return "ClothingCheck ainda não foi iniciado"
	end
	local lines = { if job.running then "EM ANDAMENTO" else string.format("TERMINADO em %.1fs", (job.finishedAt or os.clock()) - job.startedAt) }
	local suggestions = {}
	for _, entry in job.entries do
		table.insert(lines, `{entry.property} {entry.id} ({table.concat(entry.users, ", ")}): {entry.class or "aguardando"} · registrado no config: {CharacterAssetConfig.clothingStatus(entry.id)}`)
		for _, step in entry.steps do
			table.insert(lines, "    · " .. step)
		end
		if entry.image then
			table.insert(suggestions, `\t["{entry.id}"] = "{entry.image}",`)
		end
	end
	if #suggestions > 0 then
		table.insert(lines, "")
		table.insert(lines, "Overrides SUGERIDOS (não aplicados; só entram em CharacterAssetConfig com aprovação):")
		for _, line in suggestions do
			table.insert(lines, line)
		end
	end
	return table.concat(lines, "\n")
end)

DevService.Register("SourcePackCheck", "() prova que o jogo não depende do Anime Pack em runtime", function()
	local pack = workspace:FindFirstChild(CharacterAssetConfig.SourcePackName)
	local previousParent = pack and pack.Parent
	if pack then
		pack.Parent = nil -- some temporariamente (volta no fim)
	end
	CharacterModelFactory.clearCache()
	local ok, fromAsset, problems = 0, 0, {}
	for _, character in CharacterConfig.Pilots do
		local built, model = pcall(CharacterModelFactory.build, character.Id, { vfx = "Full" })
		if built then
			ok += 1
			if model:GetAttribute("AssetRig") then
				fromAsset += 1
			end
			for _, obj in model:GetDescendants() do
				if obj:IsA("ObjectValue") or obj:IsA("LuaSourceContainer") then
					table.insert(problems, `{character.Id}: {obj.ClassName} {obj.Name}`)
				end
			end
			model:Destroy()
		else
			table.insert(problems, `{character.Id}: {model}`)
		end
	end
	if pack then
		pack.Parent = previousParent
	end
	return `Anime Pack no Workspace: {if pack then "sim (escondido durante o teste)" else "não"} · {ok}/{#CharacterConfig.Pilots} montados sem o pack · {fromAsset} do asset sanitizado · problemas: {if #problems == 0 then "nenhum" else table.concat(problems, "; ")}`
end)

DevService.Register("Analytics", "() contagem dos eventos de analytics", function()
	return game:GetService("HttpService"):JSONEncode(AnalyticsService.Counts())
end)

-- Executa um comando (mesma porta do BindableFunction; usado também pelos testes)
function DevService.Run(name: string, ...: any): any
	local command = commands[name]
	if not command then
		return `comando desconhecido: {tostring(name)} (use "Help")`
	end
	local ok, result = pcall(command.run, ...)
	if not ok then
		log:warn("comando", name, "falhou:", result)
		return "erro: " .. tostring(result)
	end
	return result
end

function DevService.Init()
	if not RunService:IsStudio() then
		return
	end
	local old = ServerStorage:FindFirstChild("RollLegendsDev")
	if old then
		old:Destroy()
	end
	local bindable = Instance.new("BindableFunction")
	bindable.Name = "RollLegendsDev"
	-- O resultado também vai para o Output (na Barra de comandos não precisa de print)
	bindable.OnInvoke = function(name: string, ...: any): any
		local result = DevService.Run(name, ...)
		print(`[RollLegendsDev] {tostring(name)} ->\n{tostring(result)}`)
		return result
	end
	bindable.Parent = ServerStorage
	log:info('comandos de teste prontos: game.ServerStorage.RollLegendsDev:Invoke("Help")')
end

return DevService
