--!strict
--[[
	Torres (Fase 7). Cada torre tem andares com inimigos cada vez mais fortes.
	    Poder total dos inimigos no andar f = BasePower * Growth ^ (f - 1)
	    Andar múltiplo de BossEvery = chefe (1 inimigo forte, BossMultiplier)
	Recompensa da 1ª vitória em cada andar:
	    Dinheiro = max(poder dos inimigos * MoneyPerPower, renda/s * IncomeSeconds)
	    Gemas a cada GemsEvery andares; bônus ao completar a torre.
	Liberação: a torre anterior precisa estar completa (Unlock.Tower).
]]

export type Tower = {
	Id: string,
	Order: number,
	Floors: number,
	BasePower: number,
	Growth: number,
	Theme: { number },
	Unlock: { Tower: string? },
	CompletionGems: number,
}

local list: { Tower } = {
	{ Id = "Ember", Order = 1, Floors = 30, BasePower = 100, Growth = 1.229, Theme = { 255, 120, 50 }, Unlock = {}, CompletionGems = 100 },
	{ Id = "Storm", Order = 2, Floors = 40, BasePower = 50000, Growth = 1.146, Theme = { 90, 140, 255 }, Unlock = { Tower = "Ember" }, CompletionGems = 250 },
	{ Id = "Void", Order = 3, Floors = 50, BasePower = 10000000, Growth = 1.068, Theme = { 150, 70, 255 }, Unlock = { Tower = "Storm" }, CompletionGems = 600 },
}

local byId: { [string]: Tower } = {}
for _, tower in list do
	byId[tower.Id] = tower
end

return {
	List = list,
	ById = byId,
	TeamSize = 5,
	MaxEnemies = 5,
	BossEvery = 10,
	BossMultiplier = 1.25,
	-- Cartas: vida = poder * HpPerPower; ataque = poder * AtkPerPower
	HpPerPower = 5,
	AtkPerPower = 1,
	MaxRounds = 40,
	-- Chance de crítico e velocidade por raridade (tier 1..8)
	CritByTier = { 0.03, 0.04, 0.05, 0.06, 0.08, 0.10, 0.12, 0.15 },
	CritMultiplier = 1.75,
	SpeedByTier = { 10, 11, 12, 13, 14, 15, 16, 18 },
	MoneyPerPower = 1,
	IncomeSeconds = 8,
	GemsEvery = 5,
	GemsPerMilestone = 5,
	BattleCooldown = 1.5,
}
