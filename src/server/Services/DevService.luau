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
local DiceConfig = require(Shared.Config.DiceConfig)
local RarityConfig = require(Shared.Config.RarityConfig)
local DiceCore = require(Shared.Modules.DiceCore)
local HttpService = game:GetService("HttpService")
local Formulas = require(Shared.Modules.GameFormulas)
local Net = require(Shared.Modules.Net)
local InventoryService = require(script.Parent.InventoryService)
local RollService = require(script.Parent.RollService)
local DiceService = require(script.Parent.DiceService)
local IndexService = require(script.Parent.IndexService)
local EconomyService = require(script.Parent.EconomyService)
local StationService = require(script.Parent.StationService)
local AnalyticsService = require(script.Parent.AnalyticsService)
local AfkService = require(script.Parent.AfkService)
local PlayerAuraService = require(script.Parent.PlayerAuraService)
local LeaderboardService = require(script.Parent.LeaderboardService)
local FusionService = require(script.Parent.FusionService)
local PlayerAuraConfig = require(Shared.Config.PlayerAuraConfig)
local MagnateConfig = require(Shared.Config.MagnateConfig)
local NumberFormatterDev = require(Shared.Modules.NumberFormatter)
local FusionCoreDev = require(game:GetService("ServerScriptService").Server.Core.FusionCore)
local SaleCoreDev = require(Shared.Modules.SaleCore)
local AfkConfig = require(Shared.Config.AfkConfig)
local ReconnectPolicy = require(Shared.Modules.ReconnectPolicy)

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

local function splitPlayer(...: any): (Player?, ...any)
	local first = ...
	local isPlayer = (typeof(first) == "Instance" and first:IsA("Player")) or (type(first) == "table" and first.UserId ~= nil)
	if isPlayer then
		return ...
	end
	return game:GetService("Players"):GetPlayers()[1], ...
end

DevService.Register("GiveMoney", "(player, valor) adiciona dinheiro", function(player, amount)
	return EconomyService.AddMoney(player, amount, "Dev")
end)
DevService.Register("SetRolls", "(player, n) define o total de rolls (requisito dos dados)", function(player, n)
	PlayerDataService.Set(player, "Rolls", n)
	return n
end)
DevService.Register("GiveCharacter", "([player], characterId, quantidade?, nivel?) dá personagens (inventário + Índice, pelo servidor)", function(...)
	local player, id, count, level = splitPlayer(...)
	assert(player, "nenhum jogador no servidor (entre em Play)")
	assert(CharacterConfig.ById[id], "personagem inválido: " .. tostring(id))
	local uids = {}
	for _ = 1, count or 1 do
		local uid = InventoryService.Add(player, id)
		data(player).Inventory[uid].Level = level or 1
		table.insert(uids, uid)
	end
	IndexService.Register(player, id, "Normal")
	InventoryService.SendDelta(player, uids, nil)
	return `{#uids}x {id} ({CharacterConfig.ById[id].Name}, {CharacterConfig.ById[id].Rarity}): {table.concat(uids, ",")}`
end)
-- Dice: seleção e auditoria matemática (DiceCore)
DevService.Register("SelectDice", "([player], diceId) DESBLOQUEIA (DEV) e seleciona o Dice usado no roll", function(...)
	local player, diceId = splitPlayer(...)
	assert(player, "nenhum jogador no servidor (entre em Play)")
	local dice = DiceConfig.ById[diceId]
	assert(dice and dice.Rollable, "Dice inválido ou não sorteável: " .. tostring(diceId))
	DiceService.Grant(player, diceId)
	DiceService.Equip(player, diceId)
	return `Dice selecionado: {diceId} ({#DiceService.Core:charactersFor(diceId)} personagens)`
end)
DevService.Register("DiceReport", "([player]) os 16 Dice: personagens, raridades, unlock e progresso do jogador", function(...)
	local player = splitPlayer(...)
	local d = player and PlayerDataService.GetData(player)
	local core = DiceService.Core
	local lines = {}
	local total = 0
	for _, dice in core:diceList() do
		local ids = core:charactersFor(dice.Id)
		total += #ids
		local weights = core:rarityWeights(dice.Id)
		local parts = {}
		for _, rarity in RarityConfig.Order do
			if weights[rarity] then
				table.insert(parts, string.format("%s %.2f%%", rarity, weights[rarity]))
			end
		end
		local found = 0
		for _, id in ids do
			if d and d.Index[id] then
				found += 1
			end
		end
		local req = dice.UnlockRequirement
		local state = if not d then "" elseif d.EquippedDice == dice.Id then " · EM USO" elseif d.OwnedDice[dice.Id] then " · desbloqueado" else " · bloqueado"
		table.insert(lines, string.format("%2d. %-10s %d personagens · %s · preço %d · req %s rolls + %s · %s%s%s", dice.Order, dice.Id, #ids, table.concat(parts, ", "), dice.Price, tostring(req.Rolls or 0), tostring(req.Dice or "—"), dice.Balance, if d then ` · Índice {found}/{#ids}` else "", state))
	end
	table.insert(lines, `TOTAL F2P nos Dice: {total} · Premium (fora dos Dice): {CharacterConfig.PremiumCount}`)
	if d then
		table.insert(lines, `Índice: {IndexService.Discovered(player :: Player)}/{CharacterConfig.Count} F2P · Premium {IndexService.DiscoveredPremium(player :: Player)}/{CharacterConfig.PremiumCount} · pity {HttpService:JSONEncode(d.Pity)}`)
	end
	return table.concat(lines, "\n")
end)
DevService.Register("DiceProbabilityReport", "(diceId?) prova matemática: % por raridade e por personagem de cada Dice + validação", function(diceId)
	local core = DiceService.Core
	local lines = {}
	local problems = DiceCore.validate(DiceConfig, CharacterConfig, RarityConfig)
	for _, dice in core:diceList() do
		if diceId == nil or dice.Id == diceId then
			local report, issues = core:probabilityReport(dice.Id)
			for _, line in report do
				table.insert(lines, line)
			end
			table.insert(lines, "")
			for _, issue in issues do
				table.insert(problems, issue)
			end
		end
	end
	table.insert(lines, if #problems == 0 then "VALIDAÇÃO: OK (16 Dice, 112 F2P uma vez cada, 9 Premium fora, totais = 100%)" else "VALIDAÇÃO: " .. #problems .. " PROBLEMA(S)\n  " .. table.concat(problems, "\n  "))
	return table.concat(lines, "\n")
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
		InventoryService.Add(player, CharacterConfig.List[1].Id) -- um Comum do Starter
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
-- Jackpot Reveal (Divino/Secreto): SÓ a apresentação — não mexe em inventário, economia nem RNG
local function jackpot(rarity: string)
	return function(player, id, times, variant)
		local chosen = id
		if not chosen then
			for _, c in CharacterConfig.List do
				if c.Rarity == rarity then
					chosen = c.Id
					break
				end
			end
		end
		assert(chosen and CharacterConfig.ById[chosen] and CharacterConfig.ById[chosen].Rarity == rarity, "personagem " .. rarity .. " inválido")
		Net.fire("DevReveal", player, { CharacterId = chosen, Rarity = rarity, IsNew = true, Repeat = times or 1, Variant = variant })
		return chosen
	end
end
DevService.Register("DivineLanding", "(player, personagemId?, vezes?, variante?) Hero Landing do Divino (só apresentação)", jackpot("Divine"))
DevService.Register("SecretLanding", "(player, personagemId?, vezes?, variante?) Jackpot Reveal do Secreto (só apresentação)", jackpot("Secret"))
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

-- HUB ART PASS: tour pelos landmarks (ponto seguro de observação, olhando para a estrutura).
-- distância opcional (10/30/60/100 para o teste de leitura). Câmera não é controlada.
local function hubArtTargets(): { [string]: { x: number, z: number } }
	local s, sh, t = MapConfig.Social, MapConfig.Shops, MapConfig.Towers
	return {
		Market = sh.Market, DiceShop = sh.DiceShop, Sell = sh.Sell,
		Trade = s.Trade, Missions = s.Missions, Fusion = s.Fusion,
		Tower = { x = t.x, z = t.z }, Upgrades = s.Upgrades, Rebirth = s.Rebirth, Rankings = s.Leaderboards,
	}
end
DevService.HubArtTargets = hubArtTargets
-- altura segura para ficar em pé em (x, z): topo da peça sólida mais alta embaixo + corpo
local function standY(x: number, z: number): number
	local top = 0
	local map = game:GetService("Workspace"):FindFirstChild("Map")
	for _, part in (map and map:GetDescendants() or {}) do
		if part:IsA("BasePart") and part.CanCollide then
			local lp = part.CFrame:PointToObjectSpace(Vector3.new(x, part.CFrame.Position.Y, z))
			local half = part.Size / 2
			local height = part.Size.Y
			if part.Shape == Enum.PartType.Cylinder then
				half = Vector3.new(part.Size.X / 2, part.Size.Y / 2, part.Size.Z / 2)
				height = part.Size.X
			end
			if math.abs(lp.X) <= half.X and math.abs(lp.Z) <= half.Z and part.CFrame.Position.Y + height / 2 < 12 then
				top = math.max(top, part.CFrame.Position.Y + height / 2)
			end
		end
	end
	return top + 3.2
end

-- Ponto de observação: na direção do Hub (as estruturas olham para ele), a `distance` studs,
-- em pé em cima do que houver no chão ali (degraus do altar, plataformas)
function DevService.HubArtViewpoint(name: string, distance: number?): (Vector3?, Vector3?)
	if name == "Overview" then
		return Vector3.new(0, standY(0, -50), -50), Vector3.new(0, 4, 40)
	end
	local target = hubArtTargets()[name]
	if not target then
		return nil, nil
	end
	local to = Vector3.new(target.x, 4, target.z)
	local toHub = Vector3.new(MapConfig.Hub.Center.x - target.x, 0, MapConfig.Hub.Center.z - target.z)
	local dir = if toHub.Magnitude > 1 then toHub.Unit else Vector3.new(0, 0, -1)
	local from = to + dir * (distance or 26)
	return Vector3.new(from.X, standY(from.X, from.Z), from.Z), to
end
DevService.Register("HubArtTour", "([player], Overview|Market|DiceShop|Sell|Trade|Missions|Fusion|Tower|Upgrades|Rebirth|Rankings, distância=26) teleporta para um ponto seguro olhando o landmark (teste de leitura: 10/30/60/100)", function(...)
	local player, name, distance = splitPlayer(...)
	local names = { "Overview" }
	for key in hubArtTargets() do
		table.insert(names, key)
	end
	table.sort(names)
	local from, to = DevService.HubArtViewpoint(tostring(name), tonumber(distance))
	if not from or not to then
		return "landmark desconhecido; use: " .. table.concat(names, ", ")
	end
	local character = player and player.Character
	if not character then
		return "sem personagem (entre em Play)"
	end
	character:PivotTo(CFrame.lookAt(from, Vector3.new(to.X, from.Y, to.Z)))
	return string.format("%s a %.0f studs", tostring(name), (from - to).Magnitude)
end)

------------------------------------------------------------------------------------
-- Pipeline de personagens (PILOTO): galeria, variantes, poses e checagens

local CharacterAssetConfig = require(Shared.Config.CharacterAssetConfig)
local CharacterModelFactory = require(Shared.Modules.CharacterModelFactory)
local CharacterAssetPipeline = require(Shared.Modules.CharacterAssetPipeline)
local VariantConfigDev = require(Shared.Config.VariantConfig)

-- O jogador é OPCIONAL nos comandos dos pilotos: na Barra de comandos basta
--   game.ServerStorage.RollLegendsDev:Invoke("ShowCharacterVariants", "char_ichiro_base")
-- Se o 1º argumento for um jogador, ele é usado; senão, o primeiro jogador do servidor.

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
-- AURAS V2: comparação lado a lado NO CENÁRIO REAL (à frente do jogador, na base/mapa claro)
local AuraBuilder = require(Shared.Modules.AuraBuilder)
local AuraConfig = require(Shared.Config.AuraConfig)
local AURA_RARITIES = { "Legendary", "Mythic", "Divine", "Secret" }

-- distância padrão = a da câmera de jogo olhando um pedestal da Base (~24 studs)
local BASE_VIEW_DISTANCE = 24

local function auraRow(player: Player?, specs: { { rarity: string, style: string?, label: string, mode: string?, gap: number? } }, characterId: string, mode: string, spacing: number, distance: number?): string
	local workspaceService = game:GetService("Workspace")
	local old = workspaceService:FindFirstChild("DevAuraLineup")
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "DevAuraLineup"
	folder.Parent = workspaceService
	-- à frente do jogador (no chão onde ele está), virados para ele
	local root = player and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local origin = if root and root:IsA("BasePart") then root.CFrame else CFrame.new(0, 3, 0)
	local look = Vector3.new(origin.LookVector.X, 0, origin.LookVector.Z)
	look = if look.Magnitude > 0.01 then look.Unit else Vector3.new(0, 0, -1)
	local right = look:Cross(Vector3.new(0, 1, 0))
	local center = origin.Position + look * (distance or BASE_VIEW_DISTANCE) - Vector3.new(0, 3, 0)
	-- "gap" = espaço extra ANTES desse modelo (separa LIGHT | FULL no AuraCompare)
	local offsets, x = {}, 0
	for i, spec in specs do
		x += (if i > 1 then spacing else 0) + (spec.gap or 0)
		offsets[i] = x
	end
	local width = x
	for i, spec in specs do
		local pos = center + right * (-width / 2 + offsets[i])
		local cf = CFrame.lookAt(pos, pos - look)
		local model = CharacterModelFactory.spawn(characterId, cf, { vfx = "None" })
		local m = spec.mode or mode
		AuraBuilder.attach(model, characterId, spec.rarity, m, CharacterModelFactory.height(characterId), spec.style)
		galleryLabel(model, spec.label, `{model:GetAttribute("AuraStyle")} · {m} · {model:GetAttribute("AuraLayers")} camadas`)
		model.Parent = folder
	end
	return `{#specs} auras em Workspace.DevAuraLineup ({mode}); apague com Invoke("AuraClear")`
end

DevService.Register("AuraLineup", "([player], estilo?, modo?, characterId?, distância?) Lendário/Mítico/Divino/Secreto lado a lado, MESMO personagem e estilo, à frente do jogador na distância da Base (padrão 24 studs). estilo: Electric|Flame|Void|Dark|Celestial|Wind|Ice|Energy|Spirit|Gravity (padrão Celestial); modo: Light (base) | Full (reveal)", function(...)
	local player, style, mode, characterId, distance = splitPlayer(...)
	style = style or "Celestial"
	assert(AuraConfig.Styles[style], "estilo inválido: " .. tostring(style))
	mode = mode or "Light"
	assert(mode == "Light" or mode == "Full", "modo: Light ou Full")
	characterId = characterId or "char_killuo_godspeed"
	assert(CharacterConfig.ById[characterId], "personagem inválido: " .. tostring(characterId))
	local specs = {}
	for _, rarity in AURA_RARITIES do
		table.insert(specs, { rarity = rarity, style = style, label = rarity })
	end
	return auraRow(player, specs, characterId, mode, 9, tonumber(distance))
end)

DevService.Register("AuraCompare", "([player], estilo?, characterId?, distância?) LIGHT (esquerda) × FULL (direita): Lendário/Mítico/Divino/Secreto nos dois modos, lado a lado, na distância da Base", function(...)
	local player, style, characterId, distance = splitPlayer(...)
	style = style or "Celestial"
	assert(AuraConfig.Styles[style], "estilo inválido: " .. tostring(style))
	characterId = characterId or "char_killuo_godspeed"
	assert(CharacterConfig.ById[characterId], "personagem inválido: " .. tostring(characterId))
	local specs = {}
	for _, mode in { "Light", "Full" } do
		for i, rarity in AURA_RARITIES do
			table.insert(specs, { rarity = rarity, style = style, label = `{string.upper(mode)} · {rarity}`, mode = mode, gap = if mode == "Full" and i == 1 then 8 else nil })
		end
	end
	return auraRow(player, specs, characterId, "Light", 8, tonumber(distance))
end)

-- MOVIMENTO (AuraMotion): Mítico/Divino/Secreto com estilos de personalidades bem diferentes
local MOTION_SET = {
	{ rarity = "Mythic", style = "Electric" },
	{ rarity = "Mythic", style = "Ice" },
	{ rarity = "Divine", style = "Flame" },
	{ rarity = "Divine", style = "Celestial" },
	{ rarity = "Secret", style = "Void" },
	{ rarity = "Secret", style = "Wind" },
}
DevService.Register("AuraMotion", "([player], modo?, characterId?, distância?) Mítico Electric/Ice, Divino Flame/Celestial, Secreto Void/Wind lado a lado para inspecionar o MOVIMENTO das fitas/órbitas (modo Light | Full)", function(...)
	local player, mode, characterId, distance = splitPlayer(...)
	mode = mode or "Light"
	assert(mode == "Light" or mode == "Full", "modo: Light ou Full")
	characterId = characterId or "char_killuo_godspeed"
	assert(CharacterConfig.ById[characterId], "personagem inválido: " .. tostring(characterId))
	local specs = {}
	for _, item in MOTION_SET do
		table.insert(specs, { rarity = item.rarity, style = item.style, label = `{item.rarity} · {item.style}` })
	end
	return auraRow(player, specs, characterId, mode, 9, tonumber(distance))
end)

DevService.Register("AuraStress", "([player], quantidade 4|8|10, raridade? (Divine | mixed), modo?) N auras lado a lado à frente do jogador (teste de legibilidade/FPS)", function(...)
	local player, count, rarity, mode = splitPlayer(...)
	count = math.clamp(tonumber(count) or 4, 1, 12)
	rarity = rarity or "Divine"
	mode = mode or "Light"
	local specs = {}
	for i = 1, count do
		local r = if rarity == "mixed" then AURA_RARITIES[(i - 1) % 4 + 1] else rarity
		table.insert(specs, { rarity = r, style = nil, label = `{r} #{i}` })
	end
	return auraRow(player, specs, "char_killuo_godspeed", mode, 6)
end)

DevService.Register("AuraClear", "() remove Workspace.DevAuraLineup", function()
	local old = game:GetService("Workspace"):FindFirstChild("DevAuraLineup")
	if old then
		old:Destroy()
	end
	return "ok"
end)

-- Galeria PAGINADA do catálogo de lançamento (no máximo GALLERY_PAGE por vez)
local GALLERY_PAGE = 12
local FILTER_KEYS = { dice = "DefaultDice", rarity = "Rarity", pool = "LaunchPool", launchpool = "LaunchPool", family = "CharacterFamily" }
local function matchesFilter(character: any, filter: string?): boolean
	if not filter or filter == "" then
		return true
	end
	for clause in string.gmatch(filter, "[^,;]+") do
		local key, value = string.match(clause, "^%s*([%w_]+)%s*=%s*(.-)%s*$")
		if not key or not value then
			return false
		end
		key, value = string.lower(key), string.lower(value)
		if key == "status" then
			-- status de roupa/otimização/VFX gravado no asset pelo pipeline (ou "placeholder")
			local folder = game:GetService("ReplicatedStorage"):FindFirstChild(CharacterAssetConfig.StorageName)
			local template = folder and folder:FindFirstChild(character.Id)
			local found = false
			if not template then
				found = value == "placeholder" or value == "missing"
			else
				for _, attribute in { "ClothingStatus", "OptimizationStatus", "VFXStatus" } do
					found = found or string.lower(tostring(template:GetAttribute(attribute))) == value
				end
			end
			if not found then
				return false
			end
		else
			local field = FILTER_KEYS[key]
			if not field or string.lower(tostring(character[field])) ~= value then
				return false
			end
		end
	end
	return true
end

DevService.Register("CharacterGalleryPage", "([player], página, filtro?) catálogo de lançamento paginado (12 por página); filtro: Dice=blade, Rarity=Mythic, Pool=Premium, Family=ichiro, Status=REVIEW_REQUIRED (combine com vírgula)", function(...)
	local player, page, filter, vfx = splitPlayer(...)
	local list = {}
	for _, character in CharacterConfig.Launch do
		if matchesFilter(character, filter) then
			table.insert(list, character)
		end
	end
	local pages = math.max(1, math.ceil(#list / GALLERY_PAGE))
	local current = math.clamp(math.floor(tonumber(page) or 1), 1, pages)
	if #list == 0 then
		return `nenhum personagem com o filtro "{tostring(filter)}"`
	end
	local entries = {}
	for i = (current - 1) * GALLERY_PAGE + 1, math.min(current * GALLERY_PAGE, #list) do
		local character = list[i]
		table.insert(entries, {
			id = character.Id,
			title = character.Name,
			subtitle = `{character.Rarity} · {character.DefaultDice or "?"} · {character.LaunchPool or "?"} · {assetStatus(character.Id)}`,
			opts = { vfx = vfx or CharacterAssetConfig.VFXModes.Gallery },
		})
	end
	local shown = showRow(player, entries)
	return `Página {current}/{pages} · {#list} personagem(ns){if filter then ` com "{filter}"` else ""} · {shown}`
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
DevService.Register("CharacterAssetReport", "() status dos assets de lançamento (validação do runtime): resumo + só o que não está OK", function()
	CharacterModelFactory.clearCache()
	local folder = game:GetService("ReplicatedStorage"):FindFirstChild(CharacterAssetConfig.StorageName)
	local lines = { `ReplicatedStorage.{CharacterAssetConfig.StorageName}: {if folder then #folder:GetChildren() .. " assets" else "AUSENTE (rode python tools/build_characters.py)"}` }
	local counts = { ok = 0, missing = 0, invalid = 0, warn = 0 }
	local details = {}
	for _, character in CharacterConfig.Launch do
		local template = folder and folder:FindFirstChild(character.Id)
		local problems, warnings = {}, {}
		if template then
			problems, warnings = CharacterAssetPipeline.validate(template)
		end
		local status
		if not template then
			counts.missing += 1
			status = "sem asset (placeholder)"
		elseif #problems > 0 then
			counts.invalid += 1
			status = "INVÁLIDO: " .. problems[1]
		else
			local flags = {}
			for _, attribute in { "ClothingStatus", "OptimizationStatus", "VFXStatus" } do
				local value = template:GetAttribute(attribute)
				if value and value ~= "OK" and value ~= "NONE" and value ~= "UNCHECKED" then
					table.insert(flags, `{attribute}={value}`)
				end
			end
			if #warnings > 0 or #flags > 0 then
				counts.warn += 1
				status = "AVISO: " .. table.concat(flags, " ") .. (if #warnings > 0 then " " .. warnings[1] else "")
			else
				counts.ok += 1
			end
		end
		if status then
			table.insert(details, `{character.Id} ({character.Name}, {character.Rarity}): {status} · peças {template and template:GetAttribute("PartCount") or "-"}`)
		end
	end
	table.insert(lines, `Lançamento {#CharacterConfig.Launch}: OK {counts.ok} · com aviso {counts.warn} · inválidos {counts.invalid} · sem asset {counts.missing}`)
	for i, line in details do
		if i > 40 then
			table.insert(lines, `... e mais {#details - 40} (veja CHARACTER_LAUNCH_AUDIT.md)`)
			break
		end
		table.insert(lines, line)
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
	for _, character in CharacterConfig.Launch do
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
	return `Anime Pack no Workspace: {if pack then "sim (escondido durante o teste)" else "não"} · {ok}/{#CharacterConfig.Launch} montados sem o pack · {fromAsset} do asset sanitizado · problemas: {if #problems == 0 then "nenhum" else table.concat(problems, "; ")}`
end)

DevService.Register("Analytics", "() contagem dos eventos de analytics", function()
	return game:GetService("HttpService"):JSONEncode(AnalyticsService.Counts())
end)

-- Executa um comando (mesma porta do BindableFunction; usado também pelos testes)
------------------------------------------------------------------------------------
-- AFK Resilience (só estado/telemetria: nenhum comando gera input)

local function afkStatusText(player: Player): string
	local st = AfkService.Status(player)
	local saves = st.saves or {}
	local lines = {
		`AFKStatus {player.Name}`,
		`  estado: {st.state} · inativo há {st.idleSeconds} s (Idle a partir de {AfkConfig.IdleAfter} s; o Roblox desconecta ~{AfkConfig.PlatformIdleKick // 60} min sem input)`,
		`  Auto Roll: {if st.autoRoll then "LIGADO" else "desligado"} · Roll Rápido: {if st.fastRoll then "sim" else "não"} (intervalo {tostring(st.rollInterval)} s) · Ocultar: {if st.hide then "sim" else "não"}`,
		`  último save: {if st.lastSave > 0 then os.date("!%H:%M:%S UTC", st.lastSave) .. ` (há {tostring(st.secondsSinceSave)} s)` else "nenhum ainda"} · saves nesta sessão: {tostring(saves.count or 0)} (falhas {tostring(saves.failures or 0)})`
			.. (if st.offlineProfile then " · PERFIL TEMPORÁRIO (Studio sem API: nada é salvo)" else ""),
		`  JobId: {st.jobId}`,
		`  sessão: reconexão={tostring(st.session.reconnect)} cadeia={st.session.chain} de="{st.session.fromJobId}" AUTO-retomada={st.session.resume} ({st.session.resumeReason}){if st.session.simulated then " [simulada]" else ""}`,
	}
	return table.concat(lines, "\n")
end

DevService.Register("AFKStatus", "([player]) estado AFK (Active/Idle/Reconnecting), inatividade, Auto/Roll Rápido/Ocultar, último save, JobId e sessão", function(...)
	local player = splitPlayer(...)
	assert(player, "sem jogador")
	return afkStatusText(player)
end)
DevService.Register("SimulateIdle", "([player], segundos=1200) simula SÓ o estado interno de inatividade (nenhum input é gerado)", function(...)
	local player, seconds = splitPlayer(...)
	assert(player, "sem jogador")
	AfkService.SimulateIdle(player, tonumber(seconds) or 1200)
	return afkStatusText(player)
end)
DevService.Register("SimulateActive", "([player]) volta o estado interno para Active (como um input real)", function(...)
	local player = splitPlayer(...)
	assert(player, "sem jogador")
	AfkService.ReportActivity(player)
	return afkStatusText(player)
end)
DevService.Register("SimulateReconnect", "([player], auto=true) trata a sessão como reconexão (Studio não teleporta): AUTO volta só com save+base+personagem+serviços prontos", function(...)
	local player, autoRoll = splitPlayer(...)
	assert(player, "sem jogador")
	AfkService.SimulateReconnect(player, autoRoll ~= false)
	AfkService._tick()
	return afkStatusText(player)
end)
DevService.Register("ReconnectPlan", "(código Enum.ConnectionError, ex. DisconnectConnectionLost | DisconnectIdle) mostra o que o cliente faria (sem teleportar)", function(code)
	local kind, reason = ReconnectPolicy.classify(code)
	local plan = ReconnectPolicy.new(AfkConfig.Reconnect, { kind = kind, code = code, jobId = "job-atual", chain = 0 })
	local steps, now = {}, 0
	for _ = 1, AfkConfig.Reconnect.MaxAttempts + 1 do
		local step = plan:next(now)
		table.insert(steps, `{step.action}@{step.at}s{if step.reason then " (" .. step.reason .. ")" else ""}`)
		if step.action ~= "SameServer" and step.action ~= "AnyServer" then
			break
		end
		now = step.at
		plan:failed("Failure")
	end
	return `{tostring(code)}: {kind} ({reason}) -> {table.concat(steps, " -> ")}`
end)

------------------------------------------------------------------------------------
-- PLAYER AURAS / MAGNATA / FUNDIR MÁX. (Studio)

local function auraTierOf(value: any): number?
	if type(value) == "number" then
		return if PlayerAuraConfig.List[value] then value else nil
	end
	local tier = PlayerAuraConfig.ById[tostring(value)]
	return if tier then tier.Tier else nil
end

-- Boneco simples de avatar (R6 em blocos, ancorado) que recebe a Player Aura pelo cliente
local function auraDummy(parent: Instance, cf: CFrame, tier: number, label: string, labelWidth: number): Model
	local model = Instance.new("Model")
	model.Name = "AuraDummy_" .. label
	local function part(name: string, size: Vector3, offset: Vector3, color: Color3): Part
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Anchored = true
		p.CanCollide = false
		p.Color = color
		p.CFrame = cf * CFrame.new(offset)
		p.Parent = model
		return p
	end
	local root = part("HumanoidRootPart", Vector3.new(2, 2, 1), Vector3.new(0, 3, 0), Color3.new(1, 1, 1))
	root.Transparency = 1
	part("Torso", Vector3.new(2, 2, 1), Vector3.new(0, 3, 0), Color3.fromRGB(60, 120, 220))
	part("Head", Vector3.new(1.2, 1.2, 1.2), Vector3.new(0, 4.6, 0), Color3.fromRGB(255, 205, 150))
	part("LeftArm", Vector3.new(1, 2, 1), Vector3.new(-1.5, 3, 0), Color3.fromRGB(255, 205, 150))
	part("RightArm", Vector3.new(1, 2, 1), Vector3.new(1.5, 3, 0), Color3.fromRGB(255, 205, 150))
	part("LeftLeg", Vector3.new(1, 2, 1), Vector3.new(-0.5, 1, 0), Color3.fromRGB(40, 40, 60))
	part("RightLeg", Vector3.new(1, 2, 1), Vector3.new(0.5, 1, 0), Color3.fromRGB(40, 40, 60))
	model.PrimaryPart = root
	model:SetAttribute("PlayerAuraVisual", tier)
	-- rótulo pequeno, em STUDS (não cresce com a distância nem se sobrepõe aos vizinhos),
	-- acima da coroa; sem "Player Aura" repetido
	local gui = Instance.new("BillboardGui")
	gui.Name = "AuraLabel"
	gui.Size = UDim2.new(labelWidth, 0, 0.9, 0)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 5.6, 0)
	gui.LightInfluence = 0
	gui.MaxDistance = 140
	gui.Parent = root
	local text = Instance.new("TextLabel")
	text.Name = "Text"
	text.BackgroundTransparency = 1
	text.Size = UDim2.fromScale(1, 1)
	text.Font = Enum.Font.FredokaOne
	text.TextScaled = true
	text.TextColor3 = Color3.new(1, 1, 1)
	text.TextStrokeTransparency = 0.2
	text.Text = label
	text.Parent = gui
	model.Parent = parent
	game:GetService("CollectionService"):AddTag(model, "PlayerAuraHost")
	return model
end

-- espaçamentos dos comandos de vitrine (studs; testados contra a largura dos rótulos)
DevService.LineupSpacing = 13
DevService.LineupLabelWidth = 7
DevService.StressSpacing = 10
DevService.StressRowGap = 11
DevService.StressLabelWidth = 6

local function auraFolder(): Folder
	local ws = game:GetService("Workspace")
	local old = ws:FindFirstChild("DevPlayerAuras")
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "DevPlayerAuras"
	folder.Parent = ws
	return folder
end

local function frontOf(player: Player?, distance: number): (Vector3, Vector3, Vector3)
	local root = player and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local origin = if root and root:IsA("BasePart") then root.CFrame else CFrame.new(0, 3, 0)
	local look = Vector3.new(origin.LookVector.X, 0, origin.LookVector.Z)
	look = if look.Magnitude > 0.01 then look.Unit else Vector3.new(0, 0, -1)
	return origin.Position + look * distance - Vector3.new(0, 3, 0), look, look:Cross(Vector3.new(0, 1, 0))
end

DevService.Register("PlayerAuraStatus", "([player]) Player Aura: comprada, visual, renda ×, WalkSpeed, próxima/preço, Money e Lifetime", function(...)
	local player = splitPlayer(...)
	assert(player, "sem jogador")
	local st = PlayerAuraService.Status(player)
	return string.format(
		"PlayerAura %s: comprada %s (tier %d) · visual %s · renda ×%.2f · WalkSpeed %d · próxima %s %s · Money %s · 👑 Lifetime %s",
		player.Name, tostring(st.ownedId or "nenhuma"), st.owned or 0, tostring(st.equippedId or "nenhum"), st.multiplier or 1, st.walkSpeed or 0,
		tostring(st.nextId or "—"), if st.nextPrice then NumberFormatterDev.money(st.nextPrice) else "", NumberFormatterDev.money(st.money or 0), NumberFormatterDev.money(st.lifetime or 0)
	)
end)
DevService.Register("SetPlayerAura", "([player], tier 0..5 ou nome) Studio: define a maior aura comprada (sem dinheiro) para testar bônus/velocidade/visual", function(...)
	local player, value = splitPlayer(...)
	assert(player, "sem jogador")
	local tier = if value == 0 or value == "0" then 0 else auraTierOf(value)
	assert(tier, "tier inválido")
	PlayerDataService.Set(player, "PlayerAura", { Owned = tier, Equipped = tier })
	PlayerAuraService.Apply(player)
	return "ok: " .. tostring(tier)
end)
DevService.Register("PlayerAuraPreview", "([player], Desperta|Imperial|Divina|Celestial|Absoluta|nenhuma) SÓ o visual no próprio avatar (sem bônus; volta com SetPlayerAura/EQUIPAR)", function(...)
	local player, value = splitPlayer(...)
	assert(player, "sem jogador")
	local tier = auraTierOf(value) or 0
	player:SetAttribute("PlayerAuraVisual", tier)
	return "visual: " .. (if tier > 0 then PlayerAuraConfig.List[tier].Id else "nenhum")
end)
DevService.Register("PlayerAuraLineup", "([player], distância=26) as 5 Player Auras lado a lado à frente do jogador (bonecos); apague com PlayerAuraClear", function(...)
	local player, distance = splitPlayer(...)
	local folder = auraFolder()
	-- 13 studs entre bonecos: a maior aura (anel 3,3 + fluxos/orbitadores) cabe sem invadir a vizinha
	local center, look, right = frontOf(player, tonumber(distance) or 26)
	for i, tier in PlayerAuraConfig.List do
		local pos = center + right * ((i - 3) * DevService.LineupSpacing)
		auraDummy(folder, CFrame.lookAt(pos, pos - look), tier.Tier, string.upper(tier.Id), DevService.LineupLabelWidth)
	end
	return "5 Player Auras em Workspace.DevPlayerAuras"
end)
DevService.Register("PlayerAuraStress", "([player], quantidade=10, tier=Absoluta) N bonecos com a MESMA Player Aura juntos (stress/LOD)", function(...)
	local player, count, value = splitPlayer(...)
	local n = math.clamp(tonumber(count) or 10, 1, 20)
	local tier = auraTierOf(value or "Absoluta") or 5
	local folder = auraFolder()
	-- formação 5 + 5 (fileira de trás deslocada meio passo: ninguém fica escondido atrás)
	local center, look, right = frontOf(player, 24)
	for i = 1, n do
		local row, col = (i - 1) // 5, (i - 1) % 5
		local x = (col - 2) * DevService.StressSpacing + (if row % 2 == 1 then DevService.StressSpacing / 2 else 0)
		local pos = center + right * x + look * (row * DevService.StressRowGap)
		auraDummy(folder, CFrame.lookAt(pos, pos - look), tier, `{PlayerAuraConfig.List[tier].Id} #{i}`, DevService.StressLabelWidth)
	end
	return `{n} × {PlayerAuraConfig.List[tier].Id} em Workspace.DevPlayerAuras`
end)
DevService.Register("PlayerAuraClear", "() remove Workspace.DevPlayerAuras", function()
	local old = game:GetService("Workspace"):FindFirstChild("DevPlayerAuras")
	if old then
		old:Destroy()
	end
	return "ok"
end)

DevService.Register("MagnateStatus", "([player]) 👑 Lifetime gerado, Money atual, temporada, pontuação gravada e posição local", function(...)
	local player = splitPlayer(...)
	assert(player, "sem jogador")
	local d = data(player)
	local board = LeaderboardService.Boards[4]
	local top = LeaderboardService.LocalTop("Magnate", MagnateConfig.Top)
	local rank = "—"
	for i, entry in top do
		if entry.name == player.DisplayName then
			rank = tostring(i)
		end
	end
	return string.format("Magnata T%d %s: Lifetime %s · Money %s · pontuação %d (×%d) · posição local #%s · gravações de ranking %d",
		MagnateConfig.Season, player.Name, NumberFormatterDev.money(d.LifetimeMoneyGenerated or 0), NumberFormatterDev.money(d.Money),
		LeaderboardService.Score(board, d), MagnateConfig.ScoreUnit, rank, LeaderboardService.Writes)
end)
DevService.Register("MagnateBoardPreview", "() preenche o painel 👑 MAGNATA com 10 nomes/valores de exemplo (só visual; o próximo refresh volta ao real)", function()
	local sample = {}
	local values = { 12.4e12, 9.8e12, 7.1e12, 3.3e12, 980e9, 450e9, 120e9, 33e9, 4.2e9, 750e6 }
	for i, v in values do
		sample[i] = { name = (if i == 2 then "NomeMuitoLongoDeJogador_" else "Jogador") .. i, value = v }
	end
	LeaderboardService.Render("Panel4", sample, MagnateConfig.Top, true)
	return "painel Panel4 com 10 linhas de exemplo"
end)
DevService.Register("MagnateSimulateIncome", "([player], segundos=600) Studio: credita N segundos da renda/s ATUAL como coleta legítima (Collector) — sobe Money e Lifetime", function(...)
	local player, seconds = splitPlayer(...)
	assert(player, "sem jogador")
	local d = data(player)
	local amount = math.floor(Formulas:incomePerSecond(d) * (tonumber(seconds) or 600))
	EconomyService.AddMoney(player, amount, "Collector")
	return "gerado " .. NumberFormatterDev.money(amount) .. " · Lifetime " .. NumberFormatterDev.money(d.LifetimeMoneyGenerated)
end)

DevService.Register("FuseMaxPreview", "([player], characterId?) prévia do FUNDIR MÁX. (sem mudar nada); sem id = a família com mais fusões", function(...)
	local player, characterId = splitPlayer(...)
	assert(player, "sem jogador")
	local d = data(player)
	local function investedOf(item)
		return SaleCoreDev.invested(Formulas, item)
	end
	local ids = {}
	if characterId then
		ids = { characterId }
	else
		local seen = {}
		for _, item in d.Inventory do
			if not seen[item.Id] then
				seen[item.Id] = true
				table.insert(ids, item.Id)
			end
		end
	end
	local best, bestId = nil, nil
	local t0 = os.clock()
	for _, id in ids do
		local plan = FusionCoreDev.fuseMaxPlan(d, id, FusionService.Configs, investedOf, d.Money)
		if plan and (not best or plan.fusions > best.fusions) then
			best, bestId = plan, id
		end
	end
	if not best then
		return "nada para fundir"
	end
	local parts = {}
	for variant, n in best.created do
		table.insert(parts, `{n}× {variant}`)
	end
	return string.format("FUNDIR MÁX. %s: %d fusões, maior %s, cria [%s], custo %s%s (%.1f ms)", tostring(bestId), best.fusions, tostring(best.top), table.concat(parts, ", "),
		NumberFormatterDev.money(best.cost), if best.limitedByMoney then " (limitado pelo dinheiro)" else "", (os.clock() - t0) * 1000)
end)

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
