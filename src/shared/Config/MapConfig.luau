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
	-- Velocidade (studs/s) e sentido ÚNICOS da esteira: a animação do cliente (ripas/objetos) e o
	-- transporte FÍSICO (AssemblyLinearVelocity das partes Belt/Joint) usam os mesmos valores.
	Speed = 12,
	Direction = 1, -- 1 = ordem do caminho (MapLayout:conveyorPath); -1 = sentido contrário
	CarryPlayers = true, -- a esteira transporta quem está em cima (false = só visual)
	SlatCount = 72, -- ripas que andam sobre a esteira (efeito de movimento)
	ItemCount = 16, -- dados/cristais transportados
}

--[[
	Visual BLOCKY (direção de arte: Blocky Simulator + Anime + Toy World).
	Poucos objetos grandes > muitos pequenos. Cores por família de área; Neon só como detalhe.
]]
MapConfig.Visual = {
	-- Paleta SATURADA (World Art Pass): verde vivo, azul forte, contraste entre áreas
	Palette = {
		Grass = { 88, 206, 64 },
		GrassDark = { 64, 182, 52 },
		Sand = { 248, 222, 150 },
		Path = { 242, 226, 186 },
		PathAlt = { 228, 206, 160 },
		Curb = { 206, 176, 120 },
		Stone = { 160, 158, 178 },
		StoneDark = { 116, 112, 138 },
		Wood = { 186, 124, 70 },
		WoodDark = { 128, 82, 46 },
		Trunk = { 140, 92, 52 },
		Leaves = { { 64, 196, 72 }, { 40, 172, 64 }, { 110, 222, 80 } },
		PineLeaves = { { 30, 150, 90 }, { 22, 128, 80 }, { 50, 170, 100 } },
		Blossom = { { 255, 160, 200 }, { 255, 128, 182 }, { 255, 196, 222 } },
		Flowers = { { 255, 110, 160 }, { 255, 220, 70 }, { 150, 110, 255 }, { 255, 255, 255 } },
		Gold = { 255, 205, 60 },
		HubStone = { 238, 232, 252 },
		HubPurple = { 124, 86, 218 },
		HubPurpleDark = { 84, 58, 170 },
		Accent = { 255, 212, 70 },
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

-- Iluminação (World Art Pass). Sky escolhido: Classic Roblox Sky (Creator Store 339406852):
-- reutilizado se já estiver em Lighting (nome SkyName tem prioridade); ver MapBuilder.chooseSky.
MapConfig.Lighting = {
	SkyAssetId = 339406852,
	SkyName = "ClassicRobloxSky",
	ClockTime = 13.6,
	Brightness = 3,
	Exposure = 0.05,
	Ambient = { 128, 124, 144 },
	OutdoorAmbient = { 150, 152, 172 },
	ColorShiftTop = { 255, 244, 225 },
	Saturation = 0.26,
	Contrast = 0.12,
	-- Bloom só complementa (limiar alto: Neon/VFX brilham, o resto não estoura)
	BloomIntensity = 0.22,
	BloomThreshold = 2.1,
	SunRays = 0.05,
	-- menos névoa = cores mais vivas e leitura de longe
	AtmosphereDensity = 0.16,
	AtmosphereHaze = 0.55,
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
