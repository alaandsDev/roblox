--!strict
--[[
	Geometria da base do jogador (coordenadas LOCAIS da base).

	Eixos locais: -Z = frente (entrada, virada para o corredor central)
	              +Z = fundo
	              +X = LADO A  (à ESQUERDA de quem entra na base)
	              -X = LADO B  (à direita de quem entra)

	Cada andar: 2 lados × 4 slots = 8 slots.
	    LADO A          LADO B
	    Slot01          Slot05      <- fundo
	    Slot02          Slot06
	    Slot03          Slot07
	    Slot04          Slot08      <- perto da entrada
	Andar N usa os slots (N-1)*8+1 .. N*8 (Floor02 = 09..16).
]]

local BaseConfig = {
	Width = 76, -- ao longo da fileira de bases (X local)
	Depth = 60, -- da entrada até o fundo (Z local)
	PlatformThickness = 1,
	FloorHeight = 20, -- distância entre pisos (personagens altos + auras + nomes)
	-- Quantos andares a arquitetura suporta (quais desbloqueiam: BaseProgressionConfig)
	MaxFloors = 5,

	--[[
		Iluminação INTERNA entre andares: o piso do andar N (N >= 2) cobre o andar N-1 e o
		escurecia (sombra do sol + Ambient do World Art Pass). Cada andar superior traz luminárias
		na face de BAIXO do seu piso, iluminando o andar que ele cobre — genérico de 1 a MaxFloors
		(nada fixo no Floor02); o andar do topo continua sob o céu (telhado aberto), sem luminárias.
		Barato e local: grade Columns × Rows de PointLights (Shadows = false), alcance curto e
		brilho baixo (luz quente neutra, não estoura para branco; o exterior não muda).
	]]
	FloorLighting = {
		Enabled = true,
		Columns = 3, -- ao longo de X (largura)
		Rows = 2, -- ao longo de Z (profundidade)
		Color = { 255, 238, 214 },
		Brightness = 0.75, -- teto: 1 (acima disso o piso claro lava para branco)
		Range = 20, -- só alcança o andar coberto (FloorHeight = 20), não vaza para fora
		Shadows = false,
		LampSize = { 3, 0.4, 3 },
	},

	-- Letreiros entre andares (FloorLegibility/LodController): de outro andar só a renda
	-- (andar vizinho) ou nada (2+ andares); Tolerance = studs abaixo do piso ainda "neste andar"
	FloorLegibility = { IncomeMaxGap = 1, Tolerance = 2 },

	SlotsPerSide = 4,
	SideOffsetX = 22, -- centro dos pedestais em relação ao corredor
	SlotFirstZ = 21, -- primeiro slot (fundo)
	SlotSpacing = 12, -- distância entre slots do mesmo lado
	PedestalSize = 8,
	PedestalHeight = 1.2,
	-- Personagens olham para o corredor, girados levemente para a entrada (exposição)
	CharacterTurnToEntrance = 25, -- graus

	WallHeight = 5,
	BackWallHeight = 8,
	FrontWallHeight = 1.6, -- mureta baixa dos lados da entrada (a entrada fica aberta)
	CorridorHalfWidth = 14,

	-- Rampa entre andares: fica no "poço" lateral, alternando de lado a cada andar
	-- (andar ímpar sobe pelo lado B, andar par pelo lado A)
	Ramp = { InnerX = 28, OuterX = 38, StartZ = -26, EndZ = 18 },

	-- PlayerSpawn: logo depois do arco da entrada (frente em Z = -30), no centro do corredor,
	-- olhando para dentro da base. Livre de pilares do arco, pads e rampa.
	Spawn = { x = 0, z = -25, size = 4 },
	Collector = { x = -24, z = -25, width = 8, depth = 6 }, -- frente, lado B
	UpgradeArea = { x = 24, z = -25, width = 8, depth = 6 }, -- frente, lado A
	Entrance = { halfWidth = 13, height = 13 },

	-- Cores de cada base (Base01..Base10)
	Themes = {
		{ 255, 99, 99 },
		{ 255, 170, 60 },
		{ 255, 220, 70 },
		{ 120, 220, 90 },
		{ 70, 200, 170 },
		{ 80, 170, 255 },
		{ 110, 120, 255 },
		{ 175, 105, 255 },
		{ 255, 110, 200 },
		{ 160, 160, 175 },
	},
}

return BaseConfig
