--!strict
--[[
	Renascimento (Fase 8).
	    Custo do próximo = BaseCost * Growth ^ rebirthsFeitos
	    Reseta: Money, dinheiro no coletor e melhorias GLOBAIS (Luck/Renda/Velocidade). A Mochila fica.
	    Mantém: personagens (com níveis e variantes), Índice, dados, torres, diário, gemas.
	    Ganha (permanente): +IncomePerRebirth de renda, +LuckPerRebirth de sorte,
	                        +PowerPerRebirth de poder, +1 slot na base (BaseProgressionConfig)
	                        e fichas de renascimento (TokensBase + rebirth // TokensBonusEvery).
	Perks: comprados com fichas, permanentes (custo = BaseCost + nível * CostStep).
]]

export type Perk = { Id: string, Order: number, PerLevel: number, MaxLevel: number, BaseCost: number, CostStep: number }

local perks: { Perk } = {
	{ Id = "Luck", Order = 1, PerLevel = 0.05, MaxLevel = 10, BaseCost = 1, CostStep = 1 },
	{ Id = "Income", Order = 2, PerLevel = 0.15, MaxLevel = 10, BaseCost = 1, CostStep = 1 },
	{ Id = "Speed", Order = 3, PerLevel = 0.03, MaxLevel = 5, BaseCost = 2, CostStep = 2 },
	{ Id = "Capacity", Order = 4, PerLevel = 25, MaxLevel = 8, BaseCost = 1, CostStep = 1 },
	{ Id = "Power", Order = 5, PerLevel = 0.10, MaxLevel = 10, BaseCost = 1, CostStep = 1 },
}
local perksById: { [string]: Perk } = {}
for _, perk in perks do
	perksById[perk.Id] = perk
end

return {
	-- Auditoria: 1º renascimento por volta de 1,5–2 h (perfil Ativo); custo x2,2 por renascimento.
	-- Bônus são LINEARES (não explodem em 20/30/36 renascimentos); ver ECONOMY.md.
	-- 1º Rebirth 10M -> 15M (depois do Colossus de 12,5M); sequência = 15M * 2,2^n
	BaseCost = 15_000_000,
	Growth = 2.2,
	MaxRebirths = 36,
	IncomePerRebirth = 0.25,
	-- Sorte do renascimento tem TETO (auditoria): +2% por renascimento, no máximo +50%
	LuckPerRebirth = 0.02,
	LuckRebirthCap = 0.5,
	PowerPerRebirth = 0.10,
	TokensBase = 1,
	TokensBonusEvery = 5,
	Perks = perks,
	PerksById = perksById,
}
