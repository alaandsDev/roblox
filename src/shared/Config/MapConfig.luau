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
	DiceSize = 18,
	DiceHeight = 27, -- altura do centro do dado flutuante (acima do pedestal do altar)
	DiceSpinSpeed = 20, -- graus por segundo
	DiceBobAmplitude = 1.5,
	-- ALTAR DOS ROLLS (visual): degraus quadrados largos e baixos (dá para subir andando)
	Altar = {
		Tiers = { 56, 38, 22 }, -- lado de cada degrau (studs)
		StepHeight = 1, -- altura de cada degrau
		PedestalSize = 12, -- bloco do dado em cima do último degrau
		PedestalHeight = 4,
		CornerPillarHeight = 10, -- pilares nos cantos do 1º degrau, com dados em cima
	},
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

-- Esteira TERRESTRE em forma de pista oval passando entre o Hub e as bases (no chão, sem
-- pilares). Onde ela cruza um caminho, as bordas abrem e a esteira fica quase rente ao caminho.
MapConfig.Conveyor = {
	HalfX = 88, -- distância do centro até as retas da esteira
	StraightHalfZ = 140, -- as retas vão de -140 a 140 em Z; depois, semicírculos
	ArcSegments = 14, -- segmentos de cada semicírculo
	Height = 0.3, -- centro da esteira; topo = Height + BeltThickness/2 = 0.55 stud acima do chão
	BeltThickness = 0.5,
	RailHeight = 0.5, -- bordas laterais baixas (acima do topo da esteira)
	CrossingMargin = 1.5, -- folga das bordas em volta de cada caminho cruzado
	BeltWidth = 8,
	Speed = 12, -- studs por segundo (animação no cliente)
	SlatCount = 72, -- ripas que andam sobre a esteira (efeito de movimento)
	ItemCount = 16, -- dados/cristais transportados
}

--[[
	Visual BLOCKY (direção de arte: Blocky Simulator + Anime + Toy World).
	Poucos objetos grandes > muitos pequenos. Cores por família de área; Neon só como detalhe.
]]
MapConfig.Visual = {
	Palette = {
		Grass = { 105, 200, 85 },
		GrassDark = { 82, 176, 72 },
		Sand = { 240, 220, 165 },
		Path = { 236, 224, 196 },
		PathAlt = { 224, 208, 176 },
		Curb = { 196, 178, 140 },
		Stone = { 150, 148, 160 },
		StoneDark = { 112, 110, 126 },
		Wood = { 170, 120, 75 },
		WoodDark = { 120, 82, 52 },
		Trunk = { 128, 88, 56 },
		Leaves = { { 76, 186, 80 }, { 60, 162, 72 }, { 104, 206, 92 } },
		Flowers = { { 255, 120, 160 }, { 255, 215, 80 }, { 150, 120, 255 }, { 255, 255, 255 } },
		Gold = { 255, 205, 70 },
		HubStone = { 236, 230, 248 },
		HubPurple = { 120, 90, 200 },
		HubPurpleDark = { 86, 62, 160 },
		Accent = { 255, 210, 80 },
	},
	-- Margens livres para decoração (studs)
	DecorClearance = {
		Path = 3, -- fora dos caminhos
		Base = 4, -- fora das bases
		Conveyor = 5, -- fora da esteira
		Hub = 6, -- fora do Hub
		Landmark = 6, -- fora das áreas de Fusão/Lojas/Torres/Missões/Trocas/Rankings
		Spawn = 10, -- nunca perto de pontos de nascimento/teleporte
		IslandEdge = 4, -- dentro da grama
	},
	-- Grade usada para escolher onde plantar (determinística)
	DecorGrid = 13,
	DecorSeed = 7,
	-- Faixa perto da borda da ilha: palmeiras; miolo: árvores; entre esteira e bases: só flores
	EdgeBand = 26,
	-- Raio em volta do Hub sem árvores (só arbusto/flor/pedra): os landmarks ficam visíveis do centro
	OpenCenterRadius = 115,
	BaseCorridorFlowersOnly = true,
	TreeHeight = { 14, 20 },
	PalmHeight = { 18, 26 },
	-- Recortes de areia/grama na borda da ilha (irregularidade só visual)
	EdgeBiteSpacing = 18,
}

MapConfig.Decor = {
	PalmHeight = 22,
}

-- Áreas funcionais (raio em studs) que a decoração não pode invadir
MapConfig.Landmarks = {
	{ id = "Market", x = -38, z = -68, radius = 14 },
	{ id = "DiceShop", x = 0, z = -76, radius = 18 },
	{ id = "Sell", x = 38, z = -68, radius = 14 },
	{ id = "Towers", x = 0, z = 130, radius = 30 },
	{ id = "Fusion", x = -68, z = 12, radius = 13 },
	{ id = "Trade", x = 68, z = 12, radius = 13 },
	{ id = "Missions", x = -50, z = 98, radius = 13 },
	{ id = "Leaderboards", x = 50, z = 98, radius = 15 },
	{ id = "Entrance", x = 0, z = -248, radius = 22 },
}

return MapConfig
