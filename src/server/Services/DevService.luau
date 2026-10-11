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
