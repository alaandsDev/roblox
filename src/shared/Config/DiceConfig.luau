--!strict
--[[
	Dados. O jogador começa com o Normal. Comprar exige dinheiro + requisito (rolls feitos e o
	dado anterior). Luck do dado multiplica a Luck dos upgrades (ver RNG.md e ECONOMY.md).
	VisualModel: modelo em Assets.Dice (TODO_ASSET); sem ele o dado é desenhado com ColorTheme.
]]

export type Dice = {
	Id: string,
	Order: number,
	LuckMultiplier: number,
	Price: number,
	Currency: string,
	-- Exclusivo: não aparece à venda (vem de recompensa, ex.: Dia 7 do Diário)
	Exclusive: boolean?,
	UnlockRequirement: { Rolls: number?, Dice: string? },
	VisualModel: string,
	ColorTheme: { Body: { number }, Pips: { number } },
}

local list: { Dice } = {
	{ Id = "Normal", Order = 1, LuckMultiplier = 1.0, Price = 0, Currency = "Money", UnlockRequirement = {}, VisualModel = "NormalDice", ColorTheme = { Body = { 250, 250, 255 }, Pips = { 40, 40, 60 } } },
	{ Id = "Lucky", Order = 2, LuckMultiplier = 1.25, Price = 2500, Currency = "Money", UnlockRequirement = { Rolls = 50, Dice = "Normal" }, VisualModel = "LuckyDice", ColorTheme = { Body = { 120, 230, 120 }, Pips = { 255, 255, 255 } } },
	{ Id = "Flame", Order = 3, LuckMultiplier = 1.6, Price = 40000, Currency = "Money", UnlockRequirement = { Rolls = 300, Dice = "Lucky" }, VisualModel = "FlameDice", ColorTheme = { Body = { 255, 110, 40 }, Pips = { 255, 240, 120 } } },
	{ Id = "Storm", Order = 4, LuckMultiplier = 2.0, Price = 400000, Currency = "Money", UnlockRequirement = { Rolls = 1000, Dice = "Flame" }, VisualModel = "StormDice", ColorTheme = { Body = { 70, 110, 220 }, Pips = { 255, 240, 100 } } },
	{ Id = "Void", Order = 5, LuckMultiplier = 2.75, Price = 5000000, Currency = "Money", UnlockRequirement = { Rolls = 3000, Dice = "Storm" }, VisualModel = "VoidDice", ColorTheme = { Body = { 35, 20, 55 }, Pips = { 190, 110, 255 } } },
	{ Id = "Celestial", Order = 6, LuckMultiplier = 4.0, Price = 75000000, Currency = "Money", UnlockRequirement = { Rolls = 8000, Dice = "Void" }, VisualModel = "CelestialDice", ColorTheme = { Body = { 255, 245, 210 }, Pips = { 255, 190, 60 } } },
	-- Exclusivo da recompensa diária (Dia 7)
	{ Id = "Prism", Order = 7, LuckMultiplier = 2.25, Price = 0, Currency = "Money", Exclusive = true, UnlockRequirement = {}, VisualModel = "PrismDice", ColorTheme = { Body = { 255, 140, 220 }, Pips = { 120, 240, 255 } } },
}

local byId: { [string]: Dice } = {}
for _, dice in list do
	byId[dice.Id] = dice
end

return { List = list, ById = byId, Default = "Normal" }
