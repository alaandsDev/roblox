--!strict
--[[
	Missões (Fase 9).
	DIÁRIAS: todo dia (UTC do servidor) cada jogador recebe DailyCount missões sorteadas do Pool
	(sorteio determinístico por jogador + dia: igual em qualquer servidor). O progresso vem dos
	eventos do jogo (AnalyticsService): Event = nome do evento; Amount = "events" soma 1 por
	evento, ou o nome de um parâmetro numérico do evento (ex.: "amount" do MoneyCollected).
	CONQUISTAS: permanentes, por nível; o progresso é lido dos dados (Stat).
	Recompensas: Money = max(Amount, renda/s * IncomeSeconds) | Gems = Amount.
]]

return {
	DailyCount = 3,
	DayLength = 24 * 60 * 60,
	Pool = ({
		{ Id = "roll_50", Event = "Roll", Amount = "events", Target = 50, Reward = { Kind = "Money", Amount = 2000, IncomeSeconds = 300 } },
		{ Id = "roll_200", Event = "Roll", Amount = "events", Target = 200, Reward = { Kind = "Gems", Amount = 15 } },
		{ Id = "rare_5", Event = "RareObtained", Amount = "events", Target = 5, Reward = { Kind = "Money", Amount = 3000, IncomeSeconds = 400 } },
		{ Id = "legendary_1", Event = "LegendaryObtained", Amount = "events", Target = 1, Reward = { Kind = "Gems", Amount = 20 } },
		{ Id = "collect_5", Event = "MoneyCollected", Amount = "events", Target = 5, Reward = { Kind = "Money", Amount = 1500, IncomeSeconds = 240 } },
		{ Id = "level_10", Event = "CharacterUpgraded", Amount = "events", Target = 10, Reward = { Kind = "Gems", Amount = 10 } },
		{ Id = "sell_20", Event = "CharacterSold", Amount = "count", Target = 20, Reward = { Kind = "Money", Amount = 2000, IncomeSeconds = 300 } },
		{ Id = "tower_3", Event = "TowerWin", Amount = "events", Target = 3, Reward = { Kind = "Gems", Amount = 15 } },
		{ Id = "upgrade_3", Event = "UpgradePurchased", Amount = "events", Target = 3, Reward = { Kind = "Money", Amount = 2500, IncomeSeconds = 300 } },
		{ Id = "fuse_1", Event = "Fusion", Amount = "events", Target = 1, Reward = { Kind = "Gems", Amount = 25 } },
	} :: { any }),
	Achievements = {
		{ Id = "rolls", Stat = "Rolls", Tiers = { 100, 1000, 5000, 20000 }, Reward = { Kind = "Gems", Amount = 25 } },
		{ Id = "index", Stat = "Discovered", Tiers = { 14, 28, 56, 112 }, Reward = { Kind = "Gems", Amount = 30 } },
		{ Id = "rebirths", Stat = "Rebirths", Tiers = { 1, 3, 10, 25 }, Reward = { Kind = "Gems", Amount = 50 } },
		{ Id = "towers", Stat = "TowerFloors", Tiers = { 10, 30, 70, 120 }, Reward = { Kind = "Gems", Amount = 40 } },
	},
}
