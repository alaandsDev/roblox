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

DevService.Register("Analytics", "() contagem dos eventos de analytics", function()
	return game:GetService("HttpService"):JSONEncode(AnalyticsService.Counts())
end)

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
	bindable.OnInvoke = function(name: string, ...: any): any
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
	bindable.Parent = ServerStorage
	log:info('comandos de teste prontos: game.ServerStorage.RollLegendsDev:Invoke("Help")')
end

return DevService
