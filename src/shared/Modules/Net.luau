--!strict
-- Rede segura entre cliente e servidor, baseada em Remotes/Definitions.
--
-- SERVIDOR
--   Net.initServer()                         -- cria os remotes (uma vez, no Bootstrap)
--   Net.handle("SetSetting", function(player, key, value) return dados end)
--   Net.fire("Notify", player, "welcome", { game = "..." })
--   Net.fireAll("Notify", ...)
--   Um handler devolve dados (ok) ou chama Net.fail("CODIGO") para recusar.
--
-- CLIENTE
--   local result = Net.request("SetSetting", "HideRollAnimation", true)
--   if result.ok then ... else print(result.code) end
--   Net.on("Notify", function(key, params) ... end)
--
-- Antes de chegar no handler, todo pedido passa por: rate limit por jogador/remote,
-- validação de tipos/tamanhos (Validator) e pcall (erro vira "INTERNAL", sem derrubar nada).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Definitions = require(script.Parent.Parent.Remotes.Definitions)
local Validator = require(script.Parent.Validator)
local RateLimiter = require(script.Parent.RateLimiter)
local Logger = require(script.Parent.Logger)

local log = Logger.new("Net")
local folder: Instance = script.Parent.Parent.Remotes

export type Result = { ok: boolean, code: string?, data: any? }

local Net = {}

-- Códigos de erro padrão (o cliente mostra o texto "error.<codigo>" da Localization)
Net.Codes = {
	RateLimited = "rate_limited",
	InvalidArgs = "invalid_args",
	NotReady = "not_ready",
	NotImplemented = "not_implemented",
	Internal = "internal",
}

local FAIL_MARKER = {}

-- Usado dentro de um handler para recusar o pedido com um código
function Net.fail(code: string): never
	error({ [FAIL_MARKER] = true, code = code }, 0)
end

------------------------------------------------------------------------------------
-- Servidor

local handlers: { [string]: (Player, ...any) -> any } = {}
local limiters: { [string]: RateLimiter.RateLimiter } = {}
local serverReady = false

function Net.initServer()
	assert(RunService:IsServer(), "Net.initServer só no servidor")
	if serverReady then
		return
	end
	serverReady = true

	for name, def in Definitions.Requests do
		local remote = Instance.new("RemoteFunction")
		remote.Name = name
		limiters[name] = RateLimiter.new(def.rate.capacity, def.rate.refill)

		remote.OnServerInvoke = function(player: Player, ...: any): Result
			if not limiters[name]:allow(player) then
				log:debug("rate limit", name, player.Name)
				return { ok = false, code = Net.Codes.RateLimited }
			end
			local ok, err = Validator.validateArgs({ ... }, select("#", ...), def.args)
			if not ok then
				log:warn("argumentos inválidos em", name, "de", player.Name, "-", err)
				return { ok = false, code = Net.Codes.InvalidArgs }
			end
			local handler = handlers[name]
			if not handler then
				return { ok = false, code = Net.Codes.NotImplemented }
			end
			local success, result = pcall(handler, player, ...)
			if success then
				return { ok = true, data = result }
			end
			if type(result) == "table" and result[FAIL_MARKER] then
				return { ok = false, code = result.code }
			end
			log:error(`handler {name} falhou para {player.Name}:`, result)
			return { ok = false, code = Net.Codes.Internal }
		end
		remote.Parent = folder
	end

	for name in Definitions.Events do
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		-- Eventos são só servidor -> cliente: qualquer coisa vinda do cliente é ignorada
		remote.OnServerEvent:Connect(function(player)
			log:debug("evento ignorado vindo do cliente", name, player.Name)
		end)
		remote.Parent = folder
	end

	Players.PlayerRemoving:Connect(function(player)
		for _, limiter in limiters do
			limiter:remove(player)
		end
	end)
end

function Net.handle(name: string, handler: (Player, ...any) -> any)
	assert(Definitions.Requests[name], `Net.handle: request "{name}" não existe em Definitions`)
	assert(handlers[name] == nil, `Net.handle: "{name}" já tem handler`)
	handlers[name] = handler
end

local function event(name: string): RemoteEvent
	assert(Definitions.Events[name], `evento "{name}" não existe em Definitions`)
	return folder:WaitForChild(name) :: RemoteEvent
end

function Net.fire(name: string, player: Player, ...: any)
	event(name):FireClient(player, ...)
end

function Net.fireAll(name: string, ...: any)
	event(name):FireAllClients(...)
end

------------------------------------------------------------------------------------
-- Cliente

function Net.request(name: string, ...: any): Result
	assert(Definitions.Requests[name], `Net.request: request "{name}" não existe em Definitions`)
	local remote = folder:WaitForChild(name, 30) :: RemoteFunction?
	if not remote then
		return { ok = false, code = Net.Codes.Internal }
	end
	local ok, result = pcall(remote.InvokeServer, remote, ...)
	if not ok or type(result) ~= "table" then
		log:warn("falha no pedido", name, result)
		return { ok = false, code = Net.Codes.Internal }
	end
	return result
end

function Net.on(name: string, callback: (...any) -> ()): RBXScriptConnection
	return event(name).OnClientEvent:Connect(callback)
end

return Net
