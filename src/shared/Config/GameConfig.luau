--!strict
-- Configurações gerais do jogo. Troque o nome do jogo aqui.

local GameConfig = {
	GameName = "Roll Legends",
	Version = "0.1.0",

	-- Configurado no Creator Hub (Configurações > Lugares). Aqui é só referência.
	MaxPlayers = 10,

	DefaultLocale = "pt-BR",

	-- "Debug" | "Info" | "Warn" | "Error"
	LogLevel = "Info",
	-- No Studio os logs ficam mais detalhados
	StudioLogLevel = "Debug",
}

return GameConfig
