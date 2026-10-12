--!strict
--[[
	Melhorias compradas com dinheiro. Custo do próximo nível = BaseCost * Growth ^ nívelAtual
	(arredondado). PerLevel = efeito por nível (ver Formulas.luau).
]]

export type Upgrade = { Id: string, Order: number, BaseCost: number, Growth: number, MaxLevel: number, PerLevel: number }

local list: { Upgrade } = {
	-- +8% de Luck por nível
	{ Id = "Luck", Order = 1, BaseCost = 2000, Growth = 1.9, MaxLevel = 20, PerLevel = 0.08 },
	-- +10% de renda por nível
	{ Id = "Income", Order = 2, BaseCost = 1500, Growth = 1.85, MaxLevel = 25, PerLevel = 0.10 },
	-- -5% no tempo entre rolls por nível — DESLIGADO enquanto RollConfig.RollSpeed.UpgradesAffectInterval = false
	{ Id = "RollSpeed", Order = 3, BaseCost = 5000, Growth = 2.0, MaxLevel = 11, PerLevel = 0.05 },
	-- +10 de espaço no inventário por nível
	{ Id = "Inventory", Order = 4, BaseCost = 1000, Growth = 1.7, MaxLevel = 20, PerLevel = 10 },
}

local byId: { [string]: Upgrade } = {}
for _, upgrade in list do
	byId[upgrade.Id] = upgrade
end

return { List = list, ById = byId }
