--!strict
--[[
	Raridades. Os IDs internos (Common, Rare...) nunca aparecem na tela: o texto vem da
	Localization ("rarity.<Id>").

	Weight: peso base (soma = 100.000, então peso / 1000 = % com Luck 1).
	LuckExponent: quanto a Luck favorece a raridade. Peso efetivo = Weight * Luck ^ LuckExponent
	(ver RNG.md). Comum tem expoente 0: a Luck nunca aumenta comuns, só dilui.
]]

export type Rarity = {
	Id: string,
	Tier: number,
	Weight: number,
	LuckExponent: number,
	Color: { number },
	-- Escala do modelo 3D (raridade maior = personagem maior) e aura
	ModelScale: number,
	Aura: string?, -- nil | "Soft" | "Strong" | "Divine" | "Secret"
}

local list: { Rarity } = {
	{ Id = "Common", Tier = 1, Weight = 55000, LuckExponent = 0, Color = { 190, 195, 205 }, ModelScale = 1.0 },
	{ Id = "Uncommon", Tier = 2, Weight = 25000, LuckExponent = 0.35, Color = { 110, 220, 110 }, ModelScale = 1.03 },
	{ Id = "Rare", Tier = 3, Weight = 12000, LuckExponent = 0.7, Color = { 70, 160, 255 }, ModelScale = 1.07 },
	{ Id = "Epic", Tier = 4, Weight = 5000, LuckExponent = 1.0, Color = { 175, 90, 255 }, ModelScale = 1.12, Aura = "Soft" },
	{ Id = "Legendary", Tier = 5, Weight = 2000, LuckExponent = 1.3, Color = { 255, 190, 40 }, ModelScale = 1.18, Aura = "Strong" },
	{ Id = "Mythic", Tier = 6, Weight = 750, LuckExponent = 1.55, Color = { 255, 70, 110 }, ModelScale = 1.24, Aura = "Strong" },
	{ Id = "Divine", Tier = 7, Weight = 200, LuckExponent = 1.75, Color = { 255, 250, 180 }, ModelScale = 1.3, Aura = "Divine" },
	{ Id = "Secret", Tier = 8, Weight = 50, LuckExponent = 1.9, Color = { 30, 30, 40 }, ModelScale = 1.36, Aura = "Secret" },
}

local byId: { [string]: Rarity } = {}
local order: { string } = {}
for _, rarity in list do
	byId[rarity.Id] = rarity
	table.insert(order, rarity.Id)
end

return {
	List = list,
	ById = byId,
	Order = order,
}
