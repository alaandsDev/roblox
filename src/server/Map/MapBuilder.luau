--!strict
--[[
	Constrói o mapa principal (sem as bases, que ficam com o BaseBuilder) a partir do
	MapConfig. Tudo é gerado por código para ficar consistente com os testes de layout.

	Workspace.Map
	├── Environment   (chão, areia, barreiras, entrada, palmeiras, pedras, ilhotas)
	├── Paths         (caminho central + ligações até cada base)
	├── Conveyor      (estrutura fixa da esteira; o movimento é feito no cliente)
	├── Hub           (praça + dado mágico + HubSpawn)
	├── Shops         (Mercado, Vender, Loja de Dados + ShopSpawn)
	├── Towers        (portal + torre + TowerEntrance)
	└── Social        (Fusão, Missões, Trocas, Rankings)
	Workspace.Runtime (Characters, Effects, Temporary)
]]

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local MapConfig = require(Shared.Config.MapConfig)
local BaseConfig = require(Shared.Config.BaseConfig)
local MapLayout = require(Shared.Modules.MapLayout)
local AssetLoader = require(Shared.Modules.AssetLoader)
local Localization = require(Shared.Localization.Localization)

local Build = require(script.Parent.Build)
local Decor = require(script.Parent.Decor)

local rgb = Build.rgb
local layout = MapLayout.new(MapConfig, BaseConfig)

local MapBuilder = {}

export type Refs = {
	map: Folder,
	hubSpawn: BasePart,
	shopSpawn: BasePart,
	towerEntrance: BasePart,
	dice: Model,
}

local function at(x: number, y: number, z: number): CFrame
	return CFrame.new(x, y, z)
end

-- Ponto de teleporte invisível; LookVector = (sin yaw, 0, cos yaw), ou seja 0 = +Z, 90 = +X
local function teleportPoint(name: string, spot: { x: number, z: number, yaw: number }, parent: Instance): Part
	local part = Build.part(
		Vector3.new(4, 1, 4),
		at(spot.x, 1, spot.z) * CFrame.Angles(0, math.rad(spot.yaw + 180), 0),
		{ Name = name, Transparency = 1, Parent = parent }
	)
	Build.decor(part)
	Build.tag(part, "TeleportPoint")
	return part
end

------------------------------------------------------------------------------------
-- Iluminação: dia claro, cores vivas, sombras suaves

local function applyLighting()
	Lighting.ClockTime = 13.5
	Lighting.Brightness = 2.4
	Lighting.Ambient = rgb(120, 118, 130)
	Lighting.OutdoorAmbient = rgb(160, 160, 170)
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 0.6
	Lighting.ShadowSoftness = 0.6
	Lighting.GlobalShadows = true

	local function effect(className: string, name: string): Instance
		local existing = Lighting:FindFirstChild(name)
		if existing then
			return existing
		end
		local created = Instance.new(className)
		created.Name = name
		created.Parent = Lighting
		return created
	end
	local color = effect("ColorCorrectionEffect", "RollLegendsColor") :: ColorCorrectionEffect
	color.Saturation = 0.22
	color.Contrast = 0.06
	color.Brightness = 0.02
	local bloom = effect("BloomEffect", "RollLegendsBloom") :: BloomEffect
	bloom.Intensity = 0.35
	bloom.Size = 22
	bloom.Threshold = 1.6
	local atmosphere = effect("Atmosphere", "RollLegendsAtmosphere") :: Atmosphere
	atmosphere.Density = 0.22
	atmosphere.Haze = 0.6
	atmosphere.Color = rgb(200, 228, 255)
	atmosphere.Decay = rgb(130, 180, 230)
	atmosphere.Glare = 0.15

	local sky = AssetLoader.clone("Sky", "Sky")
	if sky and sky:IsA("Sky") then
		local old = Lighting:FindFirstChildOfClass("Sky")
		if old then
			old:Destroy()
		end
		sky.Parent = Lighting
	end
end

------------------------------------------------------------------------------------
-- Ilha, água e bordas

local function buildEnvironment(parent: Folder)
	local island = MapConfig.Island
	local hx, hz = island.SizeX / 2, island.SizeZ / 2
	local beach = island.BeachWidth

	-- Água (Terrain) em volta da ilha. (No Roblox o Terrain sempre existe; a checagem é
	-- para o teste fora do Studio, que não tem Terrain.)
	local terrain = workspace:FindFirstChildOfClass("Terrain")
	if terrain then
		terrain.WaterColor = rgb(40, 175, 210)
		terrain.WaterTransparency = 0.55
		terrain.WaterWaveSize = 0.12
		terrain.WaterWaveSpeed = 6
		terrain.WaterReflectance = 0.6
		local waterSize = Vector3.new(island.SizeX + island.WaterMargin * 2, 12, island.SizeZ + island.WaterMargin * 2)
		terrain:FillBlock(CFrame.new(0, island.WaterLevel - 6, 0), waterSize, Enum.Material.Water)
		terrain:FillBlock(CFrame.new(0, island.WaterLevel - 16, 0), waterSize + Vector3.new(0, -4, 0), Enum.Material.Sand)
	end

	Build.part(
		Vector3.new(island.SizeX + beach * 2, 4, island.SizeZ + beach * 2),
		at(0, -2.4, 0),
		{ Name = "Beach", Color = rgb(240, 220, 165), Material = Enum.Material.Sand, Parent = parent }
	)
	Build.part(
		Vector3.new(island.SizeX, 4, island.SizeZ),
		at(0, -2, 0),
		{ Name = "Ground", Color = rgb(105, 200, 85), Material = Enum.Material.Grass, Parent = parent }
	)

	-- Barreiras invisíveis na borda da areia (a água e as pedras dão o contexto visual)
	local barriers = Build.folder("Barriers", parent)
	local h = island.BarrierHeight
	local bx, bz = hx + beach, hz + beach
	local walls: { { any } } = {
		{ Vector3.new(2, h, bz * 2), at(-bx, h / 2, 0) },
		{ Vector3.new(2, h, bz * 2), at(bx, h / 2, 0) },
		{ Vector3.new(bx * 2, h, 2), at(0, h / 2, -bz) },
		{ Vector3.new(bx * 2, h, 2), at(0, h / 2, bz) },
	}
	for _, info in walls do
		local wall = Build.part(info[1], info[2], { Name = "Barrier", Transparency = 1, Parent = barriers })
		wall.CanQuery = false
		wall.CanTouch = false
	end

	-- Portal de entrada (sul)
	local entrance = Build.model("EntranceArch", parent)
	local e = MapConfig.Entrance
	for _, x in { -e.width / 2, e.width / 2 } do
		Build.part(Vector3.new(3, e.height, 3), at(x, e.height / 2, e.z), {
			Color = rgb(255, 245, 230),
			Material = Enum.Material.Sandstone,
			Parent = entrance,
		})
	end
	local beam = Build.part(Vector3.new(e.width + 6, 5, 2), at(0, e.height + 2.5, e.z), {
		Color = rgb(150, 90, 230),
		Parent = entrance,
	})
	local title = Localization.t("map.game_title")
	Build.sign(beam, Enum.NormalId.Front, { { title, 0.9, rgb(255, 230, 90) } })
	Build.sign(beam, Enum.NormalId.Back, { { title, 0.9, rgb(255, 230, 90) } })

	-- Decoração: palmeiras nos vãos entre bases e nas pontas; pedras nos cantos
	local decor = Build.folder("Decor", parent)
	local seed = 1
	local function palm(x: number, z: number)
		seed += 1
		Decor.palm(decor, at(x, 0, z), MapConfig.Decor.PalmHeight * (0.85 + (seed % 4) * 0.08), seed)
	end
	local gapZ = MapConfig.Bases.RowSpacing / 2
	for _, z in { gapZ * 5, gapZ * 3, gapZ, -gapZ, -gapZ * 3, -gapZ * 5 } do
		palm(-hx + 6, z)
		palm(hx - 6, z)
	end
	for _, x in { -150, -112, -74, 74, 112, 150 } do
		palm(x, -hz + 8)
		palm(x, hz - 8)
	end
	for i, corner in { { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } } do
		Decor.rock(decor, at(corner[1] * (hx - 10), 0, corner[2] * (hz - 12)), 7, 100 + i)
		Decor.bush(decor, at(corner[1] * (hx - 20), 0, corner[2] * (hz - 6)), 4)
	end

	-- "Montanhas" e ilhotas no mar, dando limite visual ao mapa
	local backdrop = Build.folder("Backdrop", parent)
	for i, spot in { { -130, hz + 55, 26 }, { 0, hz + 75, 34 }, { 130, hz + 55, 28 }, { -hx - 60, 40, 20 }, { hx + 60, -60, 22 } } do
		Decor.rock(backdrop, at(spot[1], -2, spot[2]), spot[3], 200 + i)
	end
	for i, spot in { { -hx - 70, 160 }, { hx + 75, -170 }, { -60, -hz - 70 } } do
		local islet = Build.cylinder(30, 3, at(spot[1], island.WaterLevel - 2.2, spot[2]), {
			Name = "Islet",
			Color = rgb(240, 220, 165),
			Material = Enum.Material.Sand,
			Parent = backdrop,
		})
		Build.decor(islet)
		Decor.palm(backdrop, at(spot[1] + 3, island.WaterLevel + 0.8, spot[2]), 16, 300 + i)
		Decor.palm(backdrop, at(spot[1] - 5, island.WaterLevel + 0.8, spot[2] + 4), 13, 310 + i)
	end
end

------------------------------------------------------------------------------------
-- Caminhos

local function buildPaths(parent: Folder)
	local p = MapConfig.Paths
	local color = rgb(232, 220, 190)
	local length = p.MainToZ - p.MainFromZ
	Build.part(Vector3.new(p.MainWidth, 0.4, length), at(0, 0.2, p.MainFromZ + length / 2), {
		Name = "MainPath",
		Color = color,
		Material = Enum.Material.Pavement,
		Parent = parent,
	})
	-- Uma ligação por fileira de bases, cruzando o mapa (frente das bases da esquerda até as da direita)
	local reach = MapConfig.Bases.CenterX - BaseConfig.Depth / 2
	for row = 1, MapConfig.Bases.PerSide do
		local z = layout:base(row).z
		Build.part(Vector3.new(reach * 2, 0.4, p.BranchWidth), at(0, 0.2, z), {
			Name = `BranchRow{row}`,
			Color = color,
			Material = Enum.Material.Pavement,
			Parent = parent,
		})
	end
end

------------------------------------------------------------------------------------
-- Hub central com o dado mágico

local PIPS: { [number]: { { number } } } = {
	-- face (normal) -> posições dos pontos (u, v) em -1..1
	[1] = { { 0, 0 } },
	[2] = { { -0.5, -0.5 }, { 0.5, 0.5 } },
	[3] = { { -0.5, -0.5 }, { 0, 0 }, { 0.5, 0.5 } },
	[4] = { { -0.5, -0.5 }, { 0.5, -0.5 }, { -0.5, 0.5 }, { 0.5, 0.5 } },
	[5] = { { -0.5, -0.5 }, { 0.5, -0.5 }, { 0, 0 }, { -0.5, 0.5 }, { 0.5, 0.5 } },
	[6] = { { -0.5, -0.55 }, { 0.5, -0.55 }, { -0.5, 0 }, { 0.5, 0 }, { -0.5, 0.55 }, { 0.5, 0.55 } },
}
-- Lado oposto soma 7, como num dado de verdade
local FACES: { { any } } = {
	{ 1, CFrame.new(0, 0, -1) }, -- frente
	{ 6, CFrame.new(0, 0, 1) },
	{ 2, CFrame.new(0, 1, 0) },
	{ 5, CFrame.new(0, -1, 0) },
	{ 3, CFrame.new(1, 0, 0) },
	{ 4, CFrame.new(-1, 0, 0) },
}

local function buildDice(parent: Instance, center: CFrame, size: number): Model
	local dice = Build.model("MagicDice", parent)
	local body = Build.part(Vector3.one * size, center, {
		Name = "Body",
		Color = rgb(250, 248, 255),
		Material = Enum.Material.SmoothPlastic,
		Parent = dice,
	})
	Build.decor(body)
	dice.PrimaryPart = body
	for _, face in FACES do
		local count, normal = face[1], face[2].Position
		-- eixos u/v perpendiculares à normal
		local u = if math.abs(normal.Y) > 0.5 then Vector3.xAxis else Vector3.yAxis
		local v = normal:Cross(u)
		for _, pip in PIPS[count] do
			local position = normal * (size / 2) + u * pip[1] * size * 0.32 + v * pip[2] * size * 0.32
			local dot = Build.part(Vector3.new(size * 0.14, size * 0.14, size * 0.14), center * CFrame.new(position), {
				Name = "Pip",
				Color = if count == 1 then rgb(230, 50, 80) else rgb(70, 40, 140),
				Material = Enum.Material.Neon,
				Parent = dice,
			})
			dot.Shape = Enum.PartType.Ball
			Build.decor(dot)
		end
	end
	local light = Instance.new("PointLight")
	light.Color = rgb(190, 150, 255)
	light.Range = 26
	light.Brightness = 1.2
	light.Parent = body
	return dice
end

local function buildHub(parent: Folder): (BasePart, Model)
	local hub = MapConfig.Hub
	local c = hub.Center
	local center = at(c.x, 0, c.z)

	Build.cylinder(hub.Radius * 2, 0.8, center, {
		Name = "Plaza",
		Color = rgb(236, 230, 248),
		Material = Enum.Material.Slate,
		Parent = parent,
	})
	Build.decor(Build.cylinder(hub.Radius * 1.3, 0.15, center * CFrame.new(0, 0.8, 0), {
		Name = "RuneRing",
		Color = rgb(170, 130, 255),
		Material = Enum.Material.Neon,
		Transparency = 0.45,
		Parent = parent,
	}))
	Build.decor(Build.cylinder(hub.Radius * 1.24, 0.17, center * CFrame.new(0, 0.8, 0), {
		Name = "RuneRingInner",
		Color = rgb(236, 230, 248),
		Material = Enum.Material.Slate,
		Parent = parent,
	}))
	local pedestal = Build.cylinder(16, 3, center * CFrame.new(0, 0.8, 0), {
		Name = "DicePedestal",
		Color = rgb(120, 90, 200),
		Material = Enum.Material.Slate,
		Parent = parent,
	})
	Build.sign(
		Build.decor(Build.part(Vector3.new(14, 2.4, 0.4), center * CFrame.new(0, 2.6, -8.1), {
			Name = "PedestalPlate",
			Transparency = 1,
			Parent = parent,
		})),
		Enum.NormalId.Front,
		{ { Localization.t("map.hub_title"), 0.9, rgb(255, 230, 90) } }
	)

	local dice = buildDice(parent, center * CFrame.new(0, hub.DiceHeight, 0) * CFrame.Angles(0.5, 0.6, 0.2), hub.DiceSize)
	Build.tag(dice, "HubDice")
	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Name = "Sparkles"
	sparkles.Color = ColorSequence.new(rgb(255, 240, 160), rgb(190, 150, 255))
	sparkles.LightEmission = 1
	sparkles.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
	sparkles.Lifetime = NumberRange.new(2, 3)
	sparkles.Rate = 8
	sparkles.Speed = NumberRange.new(3, 6)
	sparkles.SpreadAngle = Vector2.new(30, 30)
	sparkles.EmissionDirection = Enum.NormalId.Top
	sparkles.Parent = pedestal

	-- Cristais e postes de luz em volta da praça
	local decor = Build.folder("Decor", parent)
	local colors = { rgb(140, 220, 255), rgb(255, 150, 220), rgb(180, 140, 255) }
	for i = 1, 8 do
		local angle = math.pi * 2 * (i - 0.5) / 8
		local r = hub.Radius - 4
		local spot = center * CFrame.new(math.cos(angle) * r, 0.8, math.sin(angle) * r)
		if i % 2 == 0 then
			Decor.crystal(decor, spot, 6, colors[(i // 2) % 3 + 1])
		else
			Decor.lamp(decor, spot, rgb(255, 235, 170))
		end
	end

	-- Ponto de nascimento padrão (antes da base ser atribuída) e HubSpawn
	local spawnSpot = MapConfig.Spawns.Hub
	local spawnLocation = Instance.new("SpawnLocation")
	spawnLocation.Name = "DefaultSpawn"
	spawnLocation.Anchored = true
	spawnLocation.Size = Vector3.new(6, 1, 6)
	spawnLocation.CFrame = at(spawnSpot.x, 0.8, spawnSpot.z)
	spawnLocation.Transparency = 1
	spawnLocation.CanCollide = false
	spawnLocation.Neutral = true
	spawnLocation.Duration = 0
	local decal = spawnLocation:FindFirstChildOfClass("Decal")
	if decal then
		decal:Destroy()
	end
	spawnLocation.Parent = parent

	return teleportPoint("HubSpawn", spawnSpot, parent), dice
end

------------------------------------------------------------------------------------
-- Cabanas da área comercial

local function buildCabin(parent: Instance, id: string, spot: any, title: string, color: Color3, big: boolean): Model
	local cabin = Build.model(id, parent)
	cabin:SetAttribute("ShopId", id)
	Build.tag(cabin, "ShopStand", "Interactable")
	-- frente da cabana (local -Z) virada para o Hub (+Z)
	local origin = CFrame.lookAt(Vector3.new(spot.x, 0, spot.z), Vector3.new(spot.x, 0, spot.z + 1))
	local w, d = spot.width, spot.depth
	local wallH = if big then 11 else 9
	local wood = rgb(170, 120, 75)

	Build.part(Vector3.new(w, 1, d), origin * CFrame.new(0, 0.5, 0), {
		Name = "Floor",
		Color = rgb(200, 160, 110),
		Material = Enum.Material.WoodPlanks,
		Parent = cabin,
	})
	Build.part(Vector3.new(w, wallH, 1), origin * CFrame.new(0, wallH / 2 + 1, d / 2 - 0.5), {
		Name = "BackWall",
		Color = wood,
		Material = Enum.Material.WoodPlanks,
		Parent = cabin,
	})
	for _, x in { -w / 2 + 0.5, w / 2 - 0.5 } do
		Build.part(Vector3.new(1, wallH, d), origin * CFrame.new(x, wallH / 2 + 1, 0), {
			Name = "SideWall",
			Color = wood,
			Material = Enum.Material.WoodPlanks,
			Parent = cabin,
		})
	end
	-- Telhado em duas águas (cor da loja)
	local roofW = w / 2 + 1.5
	for _, sideSign in { -1, 1 } do
		Build.decor(Build.wedge(
			Vector3.new(d + 3, 4, roofW),
			-- parte alta da cunha (local +Z) virada para o centro da cabana
			origin * CFrame.new(sideSign * roofW / 2, wallH + 3, 0) * CFrame.Angles(0, math.rad(-90 * sideSign), 0),
			{ Name = "Roof", Color = color, Parent = cabin }
		))
	end
	-- Balcão na frente
	local counter = Build.part(Vector3.new(w - 4, 3.5, 2), origin * CFrame.new(0, 2.75, -d / 2 + 2), {
		Name = "Counter",
		Color = rgb(150, 100, 60),
		Material = Enum.Material.Wood,
		Parent = cabin,
	})
	-- Placa
	local board = Build.part(Vector3.new(w - 2, if big then 4.5 else 3.5, 0.6), origin * CFrame.new(0, wallH + 0.5, -d / 2 - 0.2), {
		Name = "SignBoard",
		Color = color,
		Parent = cabin,
	})
	Build.sign(board, Enum.NormalId.Front, { { title, 0.85 } })
	Build.prompt(counter, id, title, Localization.t("prompt.open"))

	if big then
		buildDice(cabin, origin * CFrame.new(0, wallH + 9, 0) * CFrame.Angles(0.4, 0.5, 0.2), 5)
		Decor.crystal(cabin, origin * CFrame.new(-w / 2 - 2, 0, -d / 2), 5, rgb(190, 140, 255))
		Decor.crystal(cabin, origin * CFrame.new(w / 2 + 2, 0, -d / 2), 5, rgb(140, 220, 255))
	end
	return cabin
end

local function buildShops(parent: Folder): BasePart
	local s = MapConfig.Shops
	buildCabin(parent, "Market", s.Market, Localization.t("map.market"), rgb(255, 150, 60), false)
	buildCabin(parent, "DiceShop", s.DiceShop, Localization.t("map.dice_shop"), rgb(150, 90, 240), true)
	buildCabin(parent, "Sell", s.Sell, Localization.t("map.sell"), rgb(80, 200, 110), false)
	return teleportPoint("ShopSpawn", MapConfig.Spawns.Shop, parent)
end

------------------------------------------------------------------------------------
-- Torres

local function buildTowers(parent: Folder): BasePart
	local t = MapConfig.Towers
	local origin = CFrame.lookAt(Vector3.new(t.x, 0, t.z), Vector3.new(t.x, 0, t.z - 1)) -- frente para o Hub (-Z)
	local stone = rgb(90, 80, 120)
	local half = t.portalWidth / 2

	for _, x in { -half, half } do
		Build.part(Vector3.new(4, t.portalHeight, 4), origin * CFrame.new(x, t.portalHeight / 2, 0), {
			Name = "PortalPillar",
			Color = stone,
			Material = Enum.Material.Slate,
			Parent = parent,
		})
		Build.decor(Build.part(Vector3.new(1, t.portalHeight - 4, 1), origin * CFrame.new(x, t.portalHeight / 2, -2.2), {
			Name = "PillarGlow",
			Color = rgb(255, 90, 140),
			Material = Enum.Material.Neon,
			Parent = parent,
		}))
	end
	local beam = Build.part(Vector3.new(t.portalWidth + 8, 6, 4), origin * CFrame.new(0, t.portalHeight + 3, 0), {
		Name = "PortalBeam",
		Color = stone,
		Material = Enum.Material.Slate,
		Parent = parent,
	})
	Build.sign(beam, Enum.NormalId.Front, {
		{ Localization.t("map.towers"), 0.6, rgb(255, 120, 150) },
		{ Localization.t("map.towers_sub"), 0.3 },
	})
	local portal = Build.part(Vector3.new(t.portalWidth - 4, t.portalHeight - 2, 0.6), origin * CFrame.new(0, (t.portalHeight - 2) / 2 + 0.5, 0), {
		Name = "PortalField",
		Color = rgb(200, 70, 160),
		Material = Enum.Material.Neon,
		Transparency = 0.45,
		Parent = parent,
	})
	portal.CanCollide = false
	Build.tag(portal, "Interactable")
	Build.prompt(portal, "Towers", Localization.t("map.towers"), Localization.t("prompt.open"))

	-- Torre atrás do portal, em degraus (segundo maior marco visual do mapa)
	local body = origin * CFrame.new(0, 0, 18)
	local y = 0
	for i, info in { { 30, 22 }, { 24, 20 }, { 18, 18 }, { 12, 10 } } do
		Build.cylinder(info[1], info[2], body * CFrame.new(0, y, 0), {
			Name = `TowerTier{i}`,
			Color = if i % 2 == 0 then rgb(110, 95, 150) else stone,
			Material = Enum.Material.Slate,
			Parent = parent,
		})
		Build.decor(Build.cylinder(info[1] + 0.6, 0.8, body * CFrame.new(0, y + info[2] - 0.8, 0), {
			Name = "TierRing",
			Color = rgb(255, 90, 140),
			Material = Enum.Material.Neon,
			Parent = parent,
		}))
		y += info[2]
	end
	Build.decor(Build.ball(6, body * CFrame.new(0, y + 3, 0), {
		Name = "TowerOrb",
		Color = rgb(255, 110, 170),
		Material = Enum.Material.Neon,
		Parent = parent,
	}))

	local entrance = teleportPoint("TowerEntrance", MapConfig.Spawns.TowerEntrance, parent)
	Build.tag(entrance, "TowerEntrance")
	return entrance
end

------------------------------------------------------------------------------------
-- Área social: Fusão, Missões, Trocas, Rankings

local function standSign(parent: Instance, origin: CFrame, title: string, color: Color3, height: number)
	for _, x in { -5, 5 } do
		Build.decor(Build.part(Vector3.new(0.8, height, 0.8), origin * CFrame.new(x, height / 2, 0), {
			Color = rgb(120, 85, 55),
			Material = Enum.Material.Wood,
			Parent = parent,
		}))
	end
	local board = Build.part(Vector3.new(12, 3.2, 0.6), origin * CFrame.new(0, height + 1, 0), {
		Name = "SignBoard",
		Color = color,
		Parent = parent,
	})
	Build.decor(board)
	Build.sign(board, Enum.NormalId.Front, { { title, 0.85 } })
end

-- origem com a frente (local -Z) virada para o centro do Hub
local function facingHub(spot: { x: number, z: number }): CFrame
	local c = MapConfig.Hub.Center
	return CFrame.lookAt(Vector3.new(spot.x, 0, spot.z), Vector3.new(c.x, 0, c.z))
end

local function buildSocial(parent: Folder)
	local s = MapConfig.Social

	-- Fusão: altar com cristais
	local fusion = Build.model("Fusion", parent)
	Build.tag(fusion, "Interactable")
	local fo = facingHub(s.Fusion)
	Build.cylinder(14, 1, fo, { Name = "Platform", Color = rgb(70, 60, 110), Material = Enum.Material.Slate, Parent = fusion })
	local altar = Build.cylinder(5, 3.5, fo * CFrame.new(0, 1, 0), {
		Name = "Altar",
		Color = rgb(110, 90, 170),
		Material = Enum.Material.Slate,
		Parent = fusion,
	})
	Decor.crystal(fusion, fo * CFrame.new(0, 4.5, 0), 6, rgb(120, 255, 220))
	Decor.crystal(fusion, fo * CFrame.new(-5, 1, 3), 4, rgb(200, 120, 255))
	Decor.crystal(fusion, fo * CFrame.new(5, 1, 3), 4, rgb(255, 140, 210))
	standSign(fusion, fo * CFrame.new(0, 0, 7.5), Localization.t("map.fusion"), rgb(110, 70, 220), 6)
	Build.prompt(altar, "Fusion", Localization.t("map.fusion"), Localization.t("prompt.open"))

	-- Missões: quadro de avisos + NPC placeholder
	local missions = Build.model("Missions", parent)
	Build.tag(missions, "Interactable")
	local mo = facingHub(s.Missions)
	local board = Build.part(Vector3.new(10, 7, 0.8), mo * CFrame.new(0, 5.5, 2), {
		Name = "Board",
		Color = rgb(150, 105, 65),
		Material = Enum.Material.Wood,
		Parent = missions,
	})
	Build.sign(board, Enum.NormalId.Front, {
		{ Localization.t("map.missions"), 0.3, rgb(255, 230, 90) },
		{ "• • •", 0.25 },
	}, rgb(245, 235, 210))
	local npc = Build.model("GuideNPC", missions)
	local npcBase = mo * CFrame.new(-7, 0, 0)
	Build.part(Vector3.new(2, 2, 1), npcBase * CFrame.new(0, 3, 0), { Color = rgb(60, 120, 220), Parent = npc })
	Build.part(Vector3.new(2, 2, 1), npcBase * CFrame.new(0, 1, 0), { Color = rgb(50, 50, 70), Parent = npc })
	Build.ball(1.6, npcBase * CFrame.new(0, 4.8, 0), { Color = rgb(255, 210, 170), Parent = npc })
	Build.decor(Build.part(Vector3.new(2.4, 0.5, 2.4), npcBase * CFrame.new(0, 5.8, 0), { Color = rgb(255, 200, 60), Parent = npc }))
	Build.prompt(board, "Missions", Localization.t("map.missions"), Localization.t("prompt.open"))

	-- Trocas: tapete, mesas e banquinhos
	local trade = Build.model("Trade", parent)
	Build.tag(trade, "Interactable")
	local to = facingHub(s.Trade)
	Build.part(Vector3.new(16, 0.2, 12), to * CFrame.new(0, 0.1, 0), {
		Name = "Rug",
		Color = rgb(230, 90, 90),
		Material = Enum.Material.Fabric,
		Parent = trade,
	})
	local tableTop: BasePart? = nil
	for _, x in { -4, 4 } do
		tableTop = Build.part(Vector3.new(4, 0.5, 3), to * CFrame.new(x, 3, 0), {
			Name = "Table",
			Color = rgb(170, 120, 75),
			Material = Enum.Material.Wood,
			Parent = trade,
		})
		Build.part(Vector3.new(1, 2.7, 1), to * CFrame.new(x, 1.35, 0), { Color = rgb(140, 95, 60), Parent = trade })
		for _, z in { -2.6, 2.6 } do
			Build.cylinder(1.6, 1.6, to * CFrame.new(x, 0, z), { Name = "Stool", Color = rgb(255, 200, 80), Parent = trade })
		end
	end
	standSign(trade, to * CFrame.new(0, 0, 7.5), Localization.t("map.trade"), rgb(230, 80, 80), 6)
	if tableTop then
		Build.prompt(tableTop, "Trade", Localization.t("map.trade"), Localization.t("prompt.open"))
	end

	-- Rankings: 3 painéis
	local boards = Build.model("Leaderboards", parent)
	local lo = facingHub(s.Leaderboards)
	for i, key in { "map.lb_rebirths", "map.lb_tower", "map.lb_rolls" } do
		local angle = math.rad((i - 2) * 28)
		local panelCf = lo * CFrame.Angles(0, angle, 0) * CFrame.new(0, 0, 4)
		for _, x in { -3.5, 3.5 } do
			Build.decor(Build.part(Vector3.new(0.8, 3, 0.8), panelCf * CFrame.new(x, 1.5, 0), {
				Color = rgb(70, 65, 85),
				Parent = boards,
			}))
		end
		local panel = Build.part(Vector3.new(9, 11, 0.8), panelCf * CFrame.new(0, 8.5, 0), {
			Name = `Panel{i}`,
			Color = rgb(40, 35, 60),
			Parent = boards,
		})
		Build.sign(panel, Enum.NormalId.Front, {
			{ Localization.t(key), 0.14, rgb(255, 220, 80) },
			{ "1. —", 0.1 },
			{ "2. —", 0.1 },
			{ "3. —", 0.1 },
			{ "4. —", 0.1 },
			{ "5. —", 0.1 },
		})
	end
	-- Título acima do painel do meio
	local header = Build.part(Vector3.new(14, 3.4, 0.6), lo * CFrame.new(0, 16.5, 4), {
		Name = "Header",
		Color = rgb(60, 140, 230),
		Parent = boards,
	})
	Build.decor(header)
	Build.sign(header, Enum.NormalId.Front, { { Localization.t("map.rankings"), 0.85 } })
end

------------------------------------------------------------------------------------
-- Esteira (estrutura fixa; ripas e objetos andando são criados no cliente)

local function buildConveyor(parent: Folder)
	local c = MapConfig.Conveyor
	local path = layout:conveyorPath()
	local beltColor = rgb(55, 55, 70)
	local railColor = rgb(255, 200, 60)
	local y = c.Height
	local count = #path.points

	for i, a in path.points do
		local b = path.points[i % count + 1]
		local from = Vector3.new(a.x, y, a.z)
		local to = Vector3.new(b.x, y, b.z)
		local length = (to - from).Magnitude
		local cf = CFrame.lookAt((from + to) / 2, to)
		Build.part(Vector3.new(c.BeltWidth, 1, length), cf, { Name = "Belt", Color = beltColor, Parent = parent })
		for _, side in { -1, 1 } do
			Build.decor(Build.part(Vector3.new(0.6, 1.4, length), cf * CFrame.new(side * (c.BeltWidth / 2 + 0.3), 0.6, 0), {
				Name = "Rail",
				Color = railColor,
				Parent = parent,
			}))
		end
		-- Junta redonda para fechar as emendas das curvas
		Build.decor(Build.cylinder(c.BeltWidth + 1.2, 1.4, CFrame.new(a.x, y - 0.5, a.z), {
			Name = "Joint",
			Color = railColor,
			Parent = parent,
		}))
	end

	-- Pilares a cada PillarSpacing ao longo da pista
	local d = 0
	while d < path.length do
		local x, z = MapLayout.pointAt(path, d)
		Build.cylinder(2.4, y - 0.5, CFrame.new(x, 0, z), {
			Name = "Pillar",
			Color = rgb(230, 228, 240),
			Material = Enum.Material.Metal,
			Parent = parent,
		})
		d += c.PillarSpacing
	end
end

------------------------------------------------------------------------------------

function MapBuilder.build(): Refs
	local old = workspace:FindFirstChild("Map")
	if old then
		old:Destroy()
	end
	local map = Instance.new("Folder")
	map.Name = "Map"

	applyLighting()
	buildEnvironment(Build.folder("Environment", map))
	buildPaths(Build.folder("Paths", map))
	buildConveyor(Build.folder("Conveyor", map))
	local hubSpawn, dice = buildHub(Build.folder("Hub", map))
	local shopSpawn = buildShops(Build.folder("Shops", map))
	local towerEntrance = buildTowers(Build.folder("Towers", map))
	buildSocial(Build.folder("Social", map))

	map.Parent = workspace

	local runtime = workspace:FindFirstChild("Runtime") or Build.folder("Runtime", workspace)
	for _, name in { "Characters", "Effects", "Temporary" } do
		if not runtime:FindFirstChild(name) then
			Build.folder(name, runtime)
		end
	end

	return { map = map, hubSpawn = hubSpawn, shopSpawn = shopSpawn, towerEntrance = towerEntrance, dice = dice }
end

return MapBuilder
