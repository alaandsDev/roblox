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
	Visual (PlayerAuraBuilder/PlayerAuraController no cliente) — ART PASS V2: identidade > quantidade.
	Composição em 3 alturas (pés / tronco / ombros-cabeça), círculos por arcos Bézier (2–4 beams),
	todo beam em movimento (endpoints/curvas animados ou textura correndo). Sem Highlight; outros
	jogadores com LOD por distância; mobile reduzido.
]]

export type Tier = {
	Tier: number,
	Id: string,
	Price: number,
	MoneyMultiplier: number,
	WalkSpeed: number,
	Color: { number },
	Accent: { number },
	Icon: string,
	-- visual (ART PASS V2): composição pés + tronco + ombros/cabeça, poucos elementos fortes
	Visual: Visual,
}

-- Cada número é a emissão (partículas/s) na qualidade cheia; 0 = sem o elemento.
-- Ring/Halo são CÍRCULOS de arcos Bézier (2 ou 4 beams, não 12 segmentos).
export type Visual = {
	Body: number, -- energia corporal (superfície do tronco)
	Rise: number, -- partículas ascendentes junto ao corpo
	Ground: number, -- brilho no chão
	Sides: number, -- energia subindo pelas laterais (2 pontos nos quadris), total
	Orbiters: number, -- orbitadores importantes (1 emissor cada)
	OrbitRate: number, -- por orbitador
	OrbitSize: number,
	Ring: { Arcs: number, Radius: number, Width: number }?, -- assinatura no chão
	Pulse: number?, -- intervalo (s) da onda no chão
	Flows: number, -- fluxos de energia animados (beams curvos) dos quadris aos ombros
	FlowWidth: number,
	Column: boolean, -- coluna vertical que respira
	Halo: { Arcs: number, Radius: number, Width: number }?, -- auréola acima da cabeça
	Crown: number, -- pontas de coroa sobre a auréola (beams)
	CrownSparks: number, -- faíscas saindo da coroa
	FootTrail: boolean,
	Light: number,
}

local tiers: { Tier } = {
	{
		Tier = 1, Id = "Desperta", Price = 1e9, MoneyMultiplier = 1.5, WalkSpeed = 28,
		Color = { 110, 215, 255 }, Accent = { 225, 250, 255 }, Icon = "✦",
		-- 1ª transformação: corpo leve + ascendentes + pulso suave + anel simples
		Visual = {
			Body = 7, Rise = 8, Ground = 3, Sides = 0, Orbiters = 0, OrbitRate = 0, OrbitSize = 0,
			Ring = { Arcs = 2, Radius = 2.3, Width = 0.22 }, Pulse = 3.2,
			Flows = 0, FlowWidth = 0, Column = false, Halo = nil, Crown = 0, CrownSparks = 0,
			FootTrail = false, Light = 0.8,
		},
	},
	{
		Tier = 2, Id = "Imperial", Price = 25e9, MoneyMultiplier = 1.75, WalkSpeed = 30,
		Color = { 255, 185, 45 }, Accent = { 255, 240, 170 }, Icon = "♛",
		-- assinatura Imperial: chamas DOURADAS subindo pelas laterais + 2 orbitadores grandes
		Visual = {
			Body = 8, Rise = 6, Ground = 3, Sides = 10, Orbiters = 2, OrbitRate = 3, OrbitSize = 0.75,
			Ring = { Arcs = 2, Radius = 2.6, Width = 0.26 }, Pulse = 2.8,
			Flows = 0, FlowWidth = 0, Column = false, Halo = nil, Crown = 0, CrownSparks = 0,
			FootTrail = true, Light = 1,
		},
	},
	{
		Tier = 3, Id = "Divina", Price = 250e9, MoneyMultiplier = 2.0, WalkSpeed = 32,
		Color = { 255, 235, 160 }, Accent = { 255, 255, 255 }, Icon = "✶",
		-- corpo inteiro envolvido: 2 fluxos subindo, 3 orbitadores, anel redondo, pulsos
		Visual = {
			Body = 10, Rise = 10, Ground = 4, Sides = 10, Orbiters = 3, OrbitRate = 3, OrbitSize = 0.65,
			Ring = { Arcs = 4, Radius = 2.8, Width = 0.32 }, Pulse = 2.4,
			Flows = 2, FlowWidth = 0.5, Column = false, Halo = nil, Crown = 0, CrownSparks = 0,
			FootTrail = true, Light = 1.1,
		},
	},
	{
		Tier = 4, Id = "Celestial", Price = 2.5e12, MoneyMultiplier = 2.25, WalkSpeed = 34,
		Color = { 140, 110, 255 }, Accent = { 210, 240, 255 }, Icon = "✧",
		-- SALTO: auréola celestial + coluna que respira + fluxos maiores + estrelas subindo
		Visual = {
			Body = 11, Rise = 14, Ground = 4, Sides = 10, Orbiters = 3, OrbitRate = 4, OrbitSize = 0.7,
			Ring = { Arcs = 2, Radius = 3, Width = 0.36 }, Pulse = 2.1,
			Flows = 2, FlowWidth = 0.7, Column = true,
			Halo = { Arcs = 4, Radius = 1.05, Width = 0.22 }, Crown = 0, CrownSparks = 4,
			FootTrail = true, Light = 1.3,
		},
	},
	{
		Tier = 5, Id = "Absoluta", Price = 5e12, MoneyMultiplier = 2.5, WalkSpeed = 36,
		Color = { 255, 45, 75 }, Accent = { 255, 210, 70 }, Icon = "👑",
		-- ÚLTIMA AURA: energia vertical carmesim, COROA dourada (auréola + 4 pontas), 3 grandes
		-- fluxos nos ombros, 3 orbitadores, 1 anel forte no chão, pulso rápido, coluna
		Visual = {
			Body = 13, Rise = 16, Ground = 5, Sides = 12, Orbiters = 3, OrbitRate = 4, OrbitSize = 0.85,
			Ring = { Arcs = 2, Radius = 3.3, Width = 0.55 }, Pulse = 1.6,
			Flows = 3, FlowWidth = 0.85, Column = true,
			Halo = { Arcs = 4, Radius = 1.1, Width = 0.26 }, Crown = 4, CrownSparks = 6,
			FootTrail = true, Light = 1.6,
		},
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
