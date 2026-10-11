--!strict
-- Configuração do salvamento (DataStore) e o formato inicial dos dados do jogador.
-- Ao mudar o formato: aumente SchemaVersion e escreva uma migração em
-- ServerScriptService/Server/Core/Migrations.luau. Veja DATA_SCHEMA.md.

local DataConfig = {
	StoreName = "RollLegends_PlayerData_v1",
	KeyPrefix = "Player_",

	SchemaVersion = 1,

	-- Salvamento automático (segundos entre cada rodada)
	AutosaveInterval = 120,

	-- Trava de sessão: se outro servidor não renovar a trava por esse tempo,
	-- consideramos que ele caiu e podemos assumir os dados (segundos)
	SessionLockTimeout = 30 * 60,

	-- Tentativas ao carregar/salvar e espera inicial entre elas (dobra a cada tentativa)
	MaxAttempts = 5,
	RetryBaseDelay = 1,
	-- No Studio: 1 tentativa só (sem acesso à API o erro é imediato e repetir só atrasa o spawn)
	StudioMaxAttempts = 1,

	-- Quantos PurchaseIds guardamos para evitar entregar a mesma compra duas vezes
	ReceiptHistorySize = 100,

	-- Tempo máximo esperando os salvamentos quando o servidor desliga (o limite do Roblox é 30 s)
	ShutdownTimeout = 25,
}

-- Formato inicial do perfil. Tabelas vazias são "mapas dinâmicos": o conteúdo não é
-- comparado com o modelo, só o tipo.
DataConfig.Template = {
	Version = 1,

	Money = 0,
	Gems = 0,
	RebirthTokens = 0,

	Rolls = 0,
	Rebirths = 0,

	EquippedDice = "Normal",

	Inventory = {},
	EquippedCharacters = {},
	Index = {},
	Upgrades = {},
	TowerProgress = {},
	Pity = {},

	Settings = {
		AutoRoll = false,
		HideRollAnimation = false,
		AutoSell = {},
	},

	Daily = {},

	-- Compras já entregues (idempotência do ProcessReceipt)
	ProcessedReceipts = {},

	LastLogout = 0,
	CreatedAt = 0,
	LastSave = 0,
}

-- Chaves que nunca são enviadas ao cliente
DataConfig.PrivateKeys = { "ProcessedReceipts" }

-- Configurações que o cliente pode alterar (sempre booleanas)
DataConfig.ClientSettings = { "AutoRoll", "HideRollAnimation" }

return DataConfig
