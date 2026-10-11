--!strict
-- Logs padronizados: [Roll Legends][Origem] mensagem
--   local log = Logger.new("PlayerData")
--   log:info("perfil carregado", player.Name)

local RunService = game:GetService("RunService")

local GameConfig = require(script.Parent.Parent.Config.GameConfig)

local LEVELS = { Debug = 1, Info = 2, Warn = 3, Error = 4 }
local configured = if RunService:IsStudio() then GameConfig.StudioLogLevel else GameConfig.LogLevel
local minimum = LEVELS[configured] or LEVELS.Info

local Logger = {}
Logger.__index = Logger

export type Logger = typeof(setmetatable({} :: { prefix: string }, Logger))

function Logger.new(origin: string): Logger
	return setmetatable({ prefix = `[{GameConfig.GameName}][{origin}]` }, Logger)
end

local function join(...: any): string
	local parts = table.pack(...)
	for i = 1, parts.n do
		parts[i] = tostring(parts[i])
	end
	return table.concat(parts, " ", 1, parts.n)
end

function Logger.debug(self: Logger, ...: any)
	if minimum <= LEVELS.Debug then
		print(self.prefix, join(...))
	end
end

function Logger.info(self: Logger, ...: any)
	if minimum <= LEVELS.Info then
		print(self.prefix, join(...))
	end
end

function Logger.warn(self: Logger, ...: any)
	if minimum <= LEVELS.Warn then
		warn(self.prefix, join(...))
	end
end

-- Erros não interrompem o jogo: só registram com o rastro da pilha
function Logger.error(self: Logger, ...: any)
	warn(self.prefix, "[ERRO]", join(...), "\n" .. debug.traceback(nil, 2))
end

return Logger
