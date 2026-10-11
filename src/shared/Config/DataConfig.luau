--!strict
-- Configuração do salvamento (DataStore) e o formato inicial dos dados do jogador.
-- Ao mudar o formato: aumente SchemaVersion e escreva uma migração em
-- ServerScriptService/Server/Core/Migrations.luau. Veja DATA_SCHEMA.md.

local DataConfig = {
	StoreName = "RollLegends_PlayerData_v1",
	KeyPrefix = "Player_",

	SchemaVersion = 2,

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
	Version = 2,

	Money = 0,
	Gems = 0,
	RebirthTokens = 0,

	Rolls = 0,
	Rebirths = 0,

	EquippedDice = "Normal",
	-- Dados comprados ({ [diceId] = true })
	OwnedDice = { Normal = true },

	-- Inventário: { [uid] = { Id, Level, Variant, Locked, Favorite, ObtainedAt } } (ver DATA_SCHEMA.md)
	Inventory = {},
	-- Próximo número de uid ("c1", "c2", ...). Nunca diminui.
	NextUid = 1,
	-- { [tostring(slotId)] = uid }
	EquippedCharacters = {},
	-- Personagens já descobertos: { [characterId] = { Count, FirstAt } }
	Index = {},
	-- Marcos do Index já recebidos: { [tostring(percentual)] = true }
	IndexRewards = {},
	Upgrades = { Luck = 0, Income = 0, RollSpeed = 0, Inventory = 0 },
	-- Torres: { [towerId] = maior andar vencido }; time escolhido (até 5 uids; vazio = automático)
	TowerProgress = {},
	TowerTeam = {},
	-- Missões: { Day, Daily = { [id] = { Progress, Claimed } }, Achievements = { [id] = nível } }
	Missions = {},

	-- Perks comprados com fichas de renascimento: { [perkId] = nível }
	RebirthPerks = {},

	-- Contadores de pity (rolls seguidos sem a raridade)
	Pity = { Legendary = 0, Mythic = 0 },

	-- Renda acumulada no coletor da base, ainda não coletada
	UncollectedMoney = 0,
	-- Renda/s da base no último momento conhecido (base do dinheiro offline)
	LastKnownIncomePerSecond = 0,
	-- Dinheiro offline calculado na entrada e ainda não resgatado
	PendingOfflineReward = 0,

	-- Recompensas diárias (ver DailyConfig)
	LastDailyClaim = 0,
	DailyStreak = 0,
	DailyCycleDay = 0,

	-- Boosts temporários: { Luck = { Multiplier, ExpiresAt } }
	Boosts = {},
	-- Quantas vezes cada raridade alta já saiu (libera PULAR na cinemática)
	RevealViews = {},

	Settings = {
		AutoRoll = false,
		HideRollAnimation = false,
		CameraShake = true,
		ReducedEffects = false,
		-- Venda automática por raridade (Secret é sempre protegido, ver RollConfig)
		AutoSell = {
			Common = false,
			Uncommon = false,
			Rare = false,
			Epic = false,
			Legendary = false,
			Mythic = false,
			Divine = false,
		},
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
DataConfig.ClientSettings = { "AutoRoll", "HideRollAnimation", "CameraShake", "ReducedEffects" }

return DataConfig
