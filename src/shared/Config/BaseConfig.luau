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
