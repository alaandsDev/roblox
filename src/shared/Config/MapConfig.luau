--!strict
--[[
	Dimensões e posições do mapa principal. Unidade: studs. Nenhum número mágico do mapa
	deve ficar fora deste arquivo (ou de BaseConfig).

	Eixos: X = largura (bases da esquerda em X < 0, direita em X > 0)
	       Z = comprimento (FUNDO em Z > 0, ENTRADA em Z < 0)
	       Y = altura (topo da grama em Y = 0)
	Posições são tabelas { x, z } simples para os módulos de layout poderem ser testados
	fora do Roblox.
]]

local MapConfig = {}

MapConfig.Island = {
	SizeX = 360, -- largura (área de grama)
	SizeZ = 520, -- comprimento
	BeachWidth = 12, -- faixa de areia em volta da grama
	WaterLevel = -1, -- superfície da água (Terrain)
	WaterMargin = 260, -- quanto de água em volta da ilha
	BarrierHeight = 60, -- parede invisível na borda da areia
}

MapConfig.Bases = {
	Count = 10,
	PerSide = 5,
	-- distância do centro do mapa até o centro de cada base (em X)
	CenterX = 136,
	-- distância entre os centros de duas bases vizinhas (em Z); BaseConfig.Width = 76 => 8 de vão
	RowSpacing = 84,
	-- Ordem em que as bases livres são entregues: as mais perto do Hub primeiro,
	-- alternando lados (o servidor parece cheio mesmo com poucos jogadores)
	AssignOrder = { 3, 8, 2, 9, 4, 7, 1, 10, 5, 6 },
}

MapConfig.Hub = {
	Center = { x = 0, z = 0 },
	Radius = 52, -- diâmetro 104
	DiceSize = 14,
	DiceHeight = 24, -- altura do centro do dado flutuante
	DiceSpinSpeed = 20, -- graus por segundo
	DiceBobAmplitude = 1.5,
}

-- Pontos de teleporte. yaw = para onde o jogador olha (graus; 0 = +Z/fundo, 180 = -Z/entrada)
MapConfig.Spawns = {
	Hub = { x = 0, z = -36, yaw = 0 }, -- borda sul do Hub, olhando o dado
	Shop = { x = 0, z = -54, yaw = 180 }, -- entre o Hub e as cabanas, olhando as lojas
	TowerEntrance = { x = 0, z = 96, yaw = 0 },
}

-- Área comercial (ao sul do Hub)
MapConfig.Shops = {
	Market = { x = -38, z = -68, width = 18, depth = 14, yaw = 0 }, -- ~78 do centro
	DiceShop = { x = 0, z = -76, width = 26, depth = 18, yaw = 0 }, -- 76 do centro (maior e no meio)
	Sell = { x = 38, z = -68, width = 18, depth = 14, yaw = 0 }, -- ~78 do centro
}

MapConfig.Towers = { x = 0, z = 118, portalWidth = 26, portalHeight = 30, towerHeight = 70 }

MapConfig.Social = {
	Fusion = { x = -68, z = 12 },
	Trade = { x = 68, z = 12 },
	Missions = { x = -50, z = 98 },
	Leaderboards = { x = 50, z = 98 },
}

MapConfig.Entrance = { z = -248, width = 34, height = 16 }

MapConfig.Paths = {
	MainWidth = 14, -- caminho norte-sul pelo centro
	BranchWidth = 10, -- caminhos do centro até cada base
	MainFromZ = -252,
	MainToZ = 132,
}

-- Esteira elevada em forma de pista oval passando entre o Hub e as bases
MapConfig.Conveyor = {
	HalfX = 88, -- distância do centro até as retas da esteira
	StraightHalfZ = 140, -- as retas vão de -140 a 140 em Z; depois, semicírculos
	ArcSegments = 14, -- segmentos de cada semicírculo
	Height = 12, -- altura da esteira (jogadores passam por baixo)
	BeltWidth = 8,
	Speed = 12, -- studs por segundo (animação no cliente)
	SlatCount = 72, -- ripas que andam sobre a esteira (efeito de movimento)
	ItemCount = 16, -- dados/cristais transportados
	PillarSpacing = 40,
}

MapConfig.Decor = {
	PalmHeight = 18,
}

return MapConfig
