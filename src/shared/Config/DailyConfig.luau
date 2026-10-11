--!strict
--[[
	Recompensas diárias: ciclo de 7 dias, virada do dia em UTC (relógio do servidor).
	Regras (ver ECONOMY.md / DATA_SCHEMA.md):
	  - Pode resgatar 1 vez por dia UTC (não precisa esperar 24 h desde o último clique).
	  - Resgatou ontem -> avança um dia. Pulou ao menos um dia inteiro -> volta para o Dia 1.
	  - Depois do Dia 7 o ciclo recomeça no Dia 1 (a sequência/streak continua contando).

	Kind:
	  Money     -> max(Amount, renda/s * IncomeSeconds)
	  Gems      -> Amount
	  LuckBoost -> Multiplier por Duration segundos (o maior boost vence; mesmo valor soma tempo)
	  Dice      -> dado exclusivo DiceId; se já tiver, entrega Fallback
]]

return {
	DayLength = 24 * 60 * 60,
	Rewards = ({
		{ Day = 1, Kind = "Money", Amount = 1000, IncomeSeconds = 120, Icon = "💵" },
		{ Day = 2, Kind = "Gems", Amount = 25, Icon = "💎" },
		{ Day = 3, Kind = "LuckBoost", Multiplier = 1.5, Duration = 10 * 60, Icon = "🍀" },
		{ Day = 4, Kind = "Money", Amount = 10000, IncomeSeconds = 600, Icon = "💰" },
		{ Day = 5, Kind = "Gems", Amount = 100, Icon = "💎" },
		{ Day = 6, Kind = "LuckBoost", Multiplier = 2, Duration = 15 * 60, Icon = "🌟" },
		{ Day = 7, Kind = "Dice", DiceId = "Prism", Icon = "🌈", Fallback = { Kind = "Gems", Amount = 250 } },
	} :: { any }),
}
