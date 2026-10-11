--!strict
--[[
	Variantes visuais/econômicas de uma unidade (CharacterInstance.Variant).
	Hoje só "Normal" sai no roll (Enabled = false nas outras). Arquitetura pronta para:
	Income, Power, cor/aura e valor de venda por variante.
]]

export type Variant = {
	Id: string,
	Order: number,
	Enabled: boolean,
	IncomeMultiplier: number,
	PowerMultiplier: number,
	SellMultiplier: number,
	Color: { number },
}

local list: { Variant } = {
	{ Id = "Normal", Order = 1, Enabled = true, IncomeMultiplier = 1, PowerMultiplier = 1, SellMultiplier = 1, Color = { 255, 255, 255 } },
	{ Id = "Silver", Order = 2, Enabled = false, IncomeMultiplier = 1.5, PowerMultiplier = 1.25, SellMultiplier = 1.5, Color = { 210, 220, 235 } },
	{ Id = "Gold", Order = 3, Enabled = false, IncomeMultiplier = 2, PowerMultiplier = 1.5, SellMultiplier = 2, Color = { 255, 205, 60 } },
	{ Id = "Diamond", Order = 4, Enabled = false, IncomeMultiplier = 3, PowerMultiplier = 2, SellMultiplier = 3, Color = { 120, 230, 255 } },
	{ Id = "Emerald", Order = 5, Enabled = false, IncomeMultiplier = 4, PowerMultiplier = 2.5, SellMultiplier = 4, Color = { 60, 230, 130 } },
	{ Id = "Void", Order = 6, Enabled = false, IncomeMultiplier = 6, PowerMultiplier = 3, SellMultiplier = 6, Color = { 150, 70, 255 } },
	{ Id = "Celestial", Order = 7, Enabled = false, IncomeMultiplier = 10, PowerMultiplier = 5, SellMultiplier = 10, Color = { 255, 245, 200 } },
}

local byId: { [string]: Variant } = {}
for _, v in list do
	byId[v.Id] = v
end

return { List = list, ById = byId, Default = "Normal" }
