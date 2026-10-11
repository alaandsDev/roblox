--!strict
--[[
	Giro do Jackpot (Fase 10). Um giro sorteia UM prêmio pelos pesos (Weight).
	Custa GemCost gemas (ou 1 produto "JackpotSpin" em Robux).
	Kinds: Money (renda/s * Seconds, mínimo Min) | Gems | LuckBoost | Roll (personagem garantido
	de MinRarity ou melhor).
	As chances aparecem na loja (transparência).
]]
return {
	GemCost = 150,
	Rewards = ({
		{ Id = "money_s", Kind = "Money", Seconds = 600, Min = 5000, Weight = 30, Icon = "💵" },
		{ Id = "money_l", Kind = "Money", Seconds = 3600, Min = 50000, Weight = 12, Icon = "💰" },
		{ Id = "gems", Kind = "Gems", Amount = 100, Weight = 18, Icon = "💎" },
		{ Id = "gems_big", Kind = "Gems", Amount = 400, Weight = 4, Icon = "💎" },
		{ Id = "luck", Kind = "LuckBoost", Multiplier = 2, Duration = 900, Weight = 18, Icon = "🍀" },
		{ Id = "epic", Kind = "Roll", MinRarity = "Epic", Weight = 12, Icon = "🟣" },
		{ Id = "legendary", Kind = "Roll", MinRarity = "Legendary", Weight = 5, Icon = "🟡" },
		{ Id = "mythic", Kind = "Roll", MinRarity = "Mythic", Weight = 1, Icon = "🔴" },
	} :: { any }),
	-- Loja de gemas (itens comprados só com gemas)
	GemShop = ({
		{ Id = "JackpotSpin", Cost = 150, Icon = "🎰" },
		{ Id = "LuckBoost", Cost = 60, Kind = "LuckBoost", Multiplier = 2, Duration = 600, Icon = "🍀" },
		{ Id = "MoneyPack", Cost = 40, Kind = "Money", Seconds = 900, Min = 5000, Icon = "💵" },
	} :: { any }),
}
