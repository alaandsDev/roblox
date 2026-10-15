--!strict
--[[
	PLAYER AURAS (progressão permanente do AVATAR do jogador). NÃO é a Character Aura
	(AuraConfig/AuraBuilder, efeito dos personagens colecionáveis): são sistemas separados.

	Escada aprovada (PLAYER_AURA_ECONOMY_AUDIT.md §4/§10; Absoluta FINAL = $5T):
	    Tier  Aura       Preço   Renda   WalkSpeed
	    1     Desperta   $1B     ×1,50   28
	    2     Imperial   $25B    ×1,75   30
	    3     Divina     $250B   ×2,00   32
	    4     Celestial  $2,5T   ×2,25   34
	    5     Absoluta   $5T     ×2,50   36
	Regras (servidor):
	  - compra SEQUENCIAL (para o tier N precisa do N-1); cada etapa cobra só o preço dela;
	  - permanente: Rebirth, morte e reconexão não removem;
	  - multiplicador e WalkSpeed = da MAIOR aura comprada (Owned), NÃO do visual equipado;
	  - multiplicador NÃO empilha entre auras (×2,5 depois de ×2 = ×2,5) e entra como mais um fator
	    de Formulas:incomeMultiplier (renda da base, offline e recompensas em "segundos de renda");
	    nunca em venda, refund, troca, fusão, custos ou preço do Rebirth.
	Visual (PlayerAuraBuilder/PlayerAuraController no cliente): orçamento de partículas/s por tier,
	sem Highlight; outros jogadores com LOD por distância; mobile reduzido.
]]

export type Tier = {
	Tier: number,
	Id: string,
	Price: number,
	MoneyMultiplier: number,
	WalkSpeed: number,
	Color: { number },
	Accent: { number },
	-- visual
	Rate: number, -- partículas/s no total (qualidade cheia, dono)
	Orbiters: number,
	GroundRing: boolean,
	FootTrail: boolean,
	Ribbons: number,
	Halo: boolean,
	Pillar: boolean,
	Light: number, -- brilho da PointLight (0 = sem)
	Icon: string,
}

local tiers: { Tier } = {
	{
		Tier = 1, Id = "Desperta", Price = 1e9, MoneyMultiplier = 1.5, WalkSpeed = 28,
		Color = { 120, 220, 255 }, Accent = { 230, 250, 255 },
		Rate = 20, Orbiters = 0, GroundRing = false, FootTrail = false, Ribbons = 0, Halo = false, Pillar = false, Light = 0.6,
		Icon = "✦",
	},
	{
		Tier = 2, Id = "Imperial", Price = 25e9, MoneyMultiplier = 1.75, WalkSpeed = 30,
		Color = { 255, 190, 60 }, Accent = { 255, 240, 170 },
		Rate = 30, Orbiters = 2, GroundRing = false, FootTrail = true, Ribbons = 0, Halo = false, Pillar = false, Light = 0.8,
		Icon = "♛",
	},
	{
		Tier = 3, Id = "Divina", Price = 250e9, MoneyMultiplier = 2.0, WalkSpeed = 32,
		Color = { 255, 240, 180 }, Accent = { 255, 255, 255 },
		Rate = 45, Orbiters = 3, GroundRing = true, FootTrail = true, Ribbons = 2, Halo = false, Pillar = false, Light = 1,
		Icon = "✶",
	},
	{
		Tier = 4, Id = "Celestial", Price = 2.5e12, MoneyMultiplier = 2.25, WalkSpeed = 34,
		Color = { 150, 120, 255 }, Accent = { 200, 240, 255 },
		Rate = 60, Orbiters = 4, GroundRing = true, FootTrail = true, Ribbons = 3, Halo = false, Pillar = true, Light = 1.2,
		Icon = "✧",
	},
	{
		Tier = 5, Id = "Absoluta", Price = 5e12, MoneyMultiplier = 2.5, WalkSpeed = 36,
		Color = { 255, 60, 90 }, Accent = { 255, 215, 90 },
		Rate = 80, Orbiters = 6, GroundRing = true, FootTrail = true, Ribbons = 4, Halo = true, Pillar = true, Light = 1.5,
		Icon = "👑",
	},
}

local byId: { [string]: Tier } = {}
for _, t in tiers do
	byId[t.Id] = t
end

return {
	List = tiers,
	ById = byId,
	MaxTier = #tiers,
	-- LOD (auras de OUTROS jogadores; a do dono é sempre cheia): cheia até FullDistance,
	-- reduzida até CullDistance, invisível além. Mobile: emissão × MobileRate.
	FullDistance = 40,
	CullDistance = 90,
	ReducedRate = 0.45,
	MobileRate = 0.5,
}
