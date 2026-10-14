--!strict
--[[
	Constrói o mapa principal (sem as bases, que ficam com o BaseBuilder) a partir do
	MapConfig. Tudo é gerado por código para ficar consistente com os testes de layout.
	Direção de arte (MapConfig.Visual): BLOCKY SIMULATOR — poucos volumes grandes, silhuetas
	fortes, cores por área, Neon só como detalhe. Posições funcionais = MapConfig (iguais às de
	antes do overhaul visual).

	Workspace.Map
	├── Environment   (chão, recortes da borda, entrada, vegetação blocky, ilhotas)
	├── Paths         (caminho central + ligações até cada base, ladrilhos e meio-fios)
	├── Conveyor      (esteira TERRESTRE; o movimento é feito no cliente)
	├── Hub           (ALTAR DOS ROLLS: degraus + pedestal + dado mágico + HubSpawn)
	├── Shops         (Mercado, Vender, Loja de Dados + ShopSpawn)
	├── Towers        (portal + torre + espada/escudo + TowerEntrance)
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
local WorldStyle = require(script.Parent.WorldStyle)

local rgb = Build.rgb
local layout = MapLayout.new(MapConfig, BaseConfig)
local P = MapConfig.Visual.Palette
local color = Decor.color

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

-- Faixa reta de peças decorativas (ex.: meio-fio) quebrada onde `blocked(ponto)` é verdade
local function runs(parent: Instance, from: Vector3, to: Vector3, width: number, height: number, partColor: Color3, name: string, blocked: (Vector3) -> boolean, step: number?)
	local length = (to - from).Magnitude
	local dir = (to - from).Unit
	local stepSize = step or 2
	local runStart: number? = nil
	local function flush(runEnd: number)
		if runStart and runEnd - runStart >= 2 then
			local a = from + dir * runStart
			local b = from + dir * runEnd
			Build.decor(Build.part(Vector3.new(width, height, runEnd - runStart), CFrame.lookAt((a + b) / 2, b), {
				Name = name,
				Color = partColor,
				Parent = parent,
			}))
		end
		runStart = nil
	end
	local t = 0
	while t <= length do
		if blocked(from + dir * t) then
			flush(t)
		elseif runStart == nil then
			runStart = t
		end
		t += stepSize
	end
	flush(length)
end

------------------------------------------------------------------------------------
-- Iluminação: dia claro de anime, sombras suaves, cores vivas (sem pós-processamento pesado)

--[[
	Iluminação do World Art Pass: dia claro, cores vivas, contraste (anime simulator blocky).
	Bloom é só complemento (limiar alto: só Neon/VFX brilham, a imagem não estoura).
	SKY: o céu escolhido é o "Classic Roblox Sky" (asset 339406852, MapConfig.Lighting.SkyAssetId).
	  - se já existe um Sky em Lighting (inserido no Studio ou vindo de assets/ClassicRobloxSky.rbxm
	    pelo build), ele é REUTILIZADO; se houver mais de um, fica só um (o de nome
	    "ClassicRobloxSky" tem prioridade) — nunca dois céus conflitantes;
	  - sem nenhum Sky, usa o de ReplicatedStorage.Assets (AssetLoader) se existir; nada é baixado.
]]
local function chooseSky()
	local skies = {}
	for _, child in Lighting:GetChildren() do
		if child:IsA("Sky") then
			table.insert(skies, child)
		end
	end
	local keep: Instance? = nil
	for _, sky in skies do
		if sky.Name == MapConfig.Lighting.SkyName then
			keep = sky
		end
	end
	keep = keep or skies[1]
	for _, sky in skies do
		if sky ~= keep then
			sky:Destroy()
		end
	end
	if not keep then
		local fallback = AssetLoader.clone("Sky", "Sky")
		if fallback and fallback:IsA("Sky") then
			fallback.Parent = Lighting
		end
	end
end

local function applyLighting()
	local L = MapConfig.Lighting
	Lighting.ClockTime = L.ClockTime
	Lighting.GeographicLatitude = 25
	Lighting.Brightness = L.Brightness
	Lighting.Ambient = rgb(table.unpack(L.Ambient))
	Lighting.OutdoorAmbient = rgb(table.unpack(L.OutdoorAmbient))
	Lighting.ExposureCompensation = L.Exposure
	Lighting.ColorShift_Top = rgb(table.unpack(L.ColorShiftTop))
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 0.4
	Lighting.ShadowSoftness = 0.3
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
	local cc = effect("ColorCorrectionEffect", "RollLegendsColor") :: ColorCorrectionEffect
	cc.Saturation = L.Saturation
	cc.Contrast = L.Contrast
	cc.Brightness = 0.02
	cc.TintColor = rgb(255, 252, 246)
	local bloom = effect("BloomEffect", "RollLegendsBloom") :: BloomEffect
	bloom.Intensity = L.BloomIntensity
	bloom.Size = 20
	bloom.Threshold = L.BloomThreshold
	local rays = effect("SunRaysEffect", "RollLegendsSunRays") :: SunRaysEffect
	rays.Intensity = L.SunRays
	rays.Spread = 0.6
	local atmosphere = effect("Atmosphere", "RollLegendsAtmosphere") :: Atmosphere
	atmosphere.Density = L.AtmosphereDensity
	atmosphere.Offset = 0.04
	atmosphere.Haze = L.AtmosphereHaze
	atmosphere.Color = rgb(205, 230, 255)
	atmosphere.Decay = rgb(110, 165, 235)
	atmosphere.Glare = 0.15
	chooseSky()
end

------------------------------------------------------------------------------------
-- Ilha, borda, água e vegetação

local function buildEnvironment(parent: Folder)
	local island = MapConfig.Island
	local hx, hz = island.SizeX / 2, island.SizeZ / 2
	local beach = island.BeachWidth

	-- Água (Terrain) + plataforma rasa de areia em volta da ilha (água turquesa perto da praia).
	-- (No Roblox o Terrain sempre existe; a checagem é para o teste fora do Studio.)
	local terrain = workspace:FindFirstChildOfClass("Terrain")
	if terrain then
		terrain.WaterColor = rgb(35, 185, 215)
		terrain.WaterTransparency = 0.45
		terrain.WaterWaveSize = 0.15
		terrain.WaterWaveSpeed = 8
		terrain.WaterReflectance = 0.35
		local waterSize = Vector3.new(island.SizeX + island.WaterMargin * 2, 12, island.SizeZ + island.WaterMargin * 2)
		terrain:FillBlock(CFrame.new(0, island.WaterLevel - 6, 0), waterSize, Enum.Material.Water)
		terrain:FillBlock(CFrame.new(0, island.WaterLevel - 16, 0), waterSize + Vector3.new(0, -4, 0), Enum.Material.Sand)
		terrain:FillBlock(CFrame.new(0, island.WaterLevel - 4, 0), Vector3.new(island.SizeX + beach * 2 + 60, 2, island.SizeZ + beach * 2 + 60), Enum.Material.Sand)
	end

	Build.part(Vector3.new(island.SizeX + beach * 2, 4, island.SizeZ + beach * 2), at(0, -2.4, 0), {
		Name = "Beach",
		Color = color(P.Sand),
		Material = Enum.Material.Sand,
		Parent = parent,
	})
	Build.part(Vector3.new(island.SizeX, 4, island.SizeZ), at(0, -2, 0), {
		Name = "Ground",
		Color = color(P.Grass),
		Material = Enum.Material.Grass,
		Parent = parent,
	})

	-- Recortes da borda: areia entrando na grama e grama saindo para a praia (quebra o retângulo)
	local edges = Build.folder("Edge", parent)
	for _, bite in layout:edgeBites() do
		local inward = if bite.alongX then Vector3.new(0, 0, -math.sign(bite.z)) else Vector3.new(-math.sign(bite.x), 0, 0)
		local size = if bite.alongX then Vector3.new(bite.length, 0, bite.depth) else Vector3.new(bite.depth, 0, bite.length)
		if bite.sand then
			Build.decor(Build.part(size + Vector3.new(0, 0.08, 0), at(bite.x, 0.04, bite.z) + inward * (bite.depth / 2), {
				Name = "SandBite",
				Color = color(P.Sand),
				Material = Enum.Material.Sand,
				Parent = edges,
			}))
		else
			Build.part(size + Vector3.new(0, 0.4, 0), at(bite.x, -0.2, bite.z) - inward * (bite.depth / 2), {
				Name = "GrassTongue",
				Color = color(P.Grass),
				Material = Enum.Material.Grass,
				Parent = edges,
			})
		end
	end

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

	-- Portal de entrada (sul): pilares chunky + viga com o nome do jogo
	local entrance = Build.model("EntranceArch", parent)
	local e = MapConfig.Entrance
	for _, x in { -e.width / 2, e.width / 2 } do
		Decor.pillar(entrance, at(x, 0, e.z), 4, e.height, rgb(255, 245, 230), color(P.HubPurple), true)
	end
	local beam = Build.part(Vector3.new(e.width + 8, 5, 3), at(0, e.height + 2.5, e.z), {
		Color = color(P.HubPurple),
		Parent = entrance,
	})
	local title = Localization.t("map.game_title")
	Build.sign(beam, Enum.NormalId.Front, { { title, 0.9, rgb(255, 230, 90) } })
	Build.sign(beam, Enum.NormalId.Back, { { title, 0.9, rgb(255, 230, 90) } })
	Decor.smallDice(entrance, at(0, e.height + 8, e.z) * CFrame.Angles(0.5, 0.6, 0.2), 4)

	-- Vegetação blocky em pontos determinísticos (MapLayout:decorSpots respeita caminhos,
	-- bases, esteira, Hub, áreas funcionais e spawns)
	local decor = Build.folder("Decor", parent)
	local v = MapConfig.Visual
	for _, spot in layout:decorSpots() do
		local base = at(spot.x, 0, spot.z)
		if spot.kind == "Palm" then
			Decor.palm(decor, base, v.PalmHeight[1] + (v.PalmHeight[2] - v.PalmHeight[1]) * (spot.scale - 0.85) / 0.3, spot.seed)
		elseif spot.kind == "Tree" then
			-- altura pela escala (clusters menores, isoladas maiores)
			Decor.tree(decor, base, math.max(9, v.TreeHeight[1] + (v.TreeHeight[2] - v.TreeHeight[1]) * (spot.scale - 0.85) / 0.3), spot.seed, spot.species)
		elseif spot.kind == "Bush" then
			Decor.bush(decor, base, 3.2 * spot.scale, spot.seed)
		elseif spot.kind == "Rocks" then
			Decor.rockCluster(decor, base, 5 * spot.scale, spot.seed, true)
		else
			Decor.flowerPatch(decor, base, spot.seed)
		end
	end

	-- "Montanhas" e ilhotas no mar, dando limite visual ao mapa
	local backdrop = Build.folder("Backdrop", parent)
	for i, spot in { { -130, hz + 55, 26 }, { 0, hz + 75, 34 }, { 130, hz + 55, 28 }, { -hx - 60, 40, 20 }, { hx + 60, -60, 22 } } do
		Decor.rockCluster(backdrop, at(spot[1], -2, spot[2]), spot[3], 200 + i, false)
	end
	for i, spot in { { -hx - 70, 160 }, { hx + 75, -170 }, { -60, -hz - 70 } } do
		Build.decor(Build.part(Vector3.new(30, 3, 26), at(spot[1], island.WaterLevel - 0.8, spot[2]) * CFrame.Angles(0, i * 0.5, 0), {
			Name = "Islet",
			Color = color(P.Sand),
			Material = Enum.Material.Sand,
			Parent = backdrop,
		}))
		Decor.palm(backdrop, at(spot[1] + 3, island.WaterLevel + 0.7, spot[2]), 18, 300 + i)
		Decor.palm(backdrop, at(spot[1] - 5, island.WaterLevel + 0.7, spot[2] + 4), 14, 310 + i)
	end
end

------------------------------------------------------------------------------------
-- Caminhos: laje + ladrilhos grandes alternados + meio-fio baixo (só visual, sem degrau)

local function buildPaths(parent: Folder)
	local p = MapConfig.Paths
	local pathColor, altColor, curbColor = color(P.Path), color(P.PathAlt), color(P.Curb)
	local length = p.MainToZ - p.MainFromZ
	Build.part(Vector3.new(p.MainWidth, 0.4, length), at(0, 0.2, p.MainFromZ + length / 2), {
		Name = "MainPath",
		Color = pathColor,
		Material = Enum.Material.Pavement,
		Parent = parent,
	})
	-- Uma ligação por fileira de bases, cruzando o mapa (frente das bases da esquerda até as da direita)
	local reach = MapConfig.Bases.CenterX - BaseConfig.Depth / 2
	local rowZ = {}
	for row = 1, MapConfig.Bases.PerSide do
		local z = layout:base(row).z
		table.insert(rowZ, z)
		Build.part(Vector3.new(reach * 2, 0.4, p.BranchWidth), at(0, 0.2, z), {
			Name = `BranchRow{row}`,
			Color = pathColor,
			Material = Enum.Material.Pavement,
			Parent = parent,
		})
	end

	local hub = MapConfig.Hub
	local beltClear = MapConfig.Conveyor.BeltWidth / 2 + 1.5
	local function busy(point: Vector3): boolean
		return layout:distanceToHub(point.X, point.Z) < hub.Radius + 1 or layout:distanceToConveyor(point.X, point.Z) < beltClear
	end
	local details = Build.folder("Details", parent)
	local tileTop = 0.42

	-- Ladrilhos grandes (12 studs) alternando o tom, fora do Hub/esteira/cruzamentos
	local function tile(cx: number, cz: number, sx: number, sz: number)
		if not busy(Vector3.new(cx, 0, cz)) then
			Build.decor(Build.part(Vector3.new(sx, 0.04, sz), at(cx, tileTop, cz), { Name = "Tile", Color = altColor, Material = Enum.Material.Pavement, Parent = details }))
		end
	end
	for z = p.MainFromZ + 6, p.MainToZ - 6, 24 do
		local nearRow = false
		for _, rz in rowZ do
			nearRow = nearRow or math.abs(z - rz) < p.BranchWidth / 2 + 7
		end
		if not nearRow then
			tile(0, z, p.MainWidth - 1.6, 11.6)
		end
	end
	for _, rz in rowZ do
		for x = -reach + 6, reach - 6, 24 do
			if math.abs(x) > p.MainWidth / 2 + 7 then
				tile(x, rz, 11.6, p.BranchWidth - 1.6)
			end
		end
		-- Cruzamento bem marcado (caminho principal × fileira)
		if not busy(Vector3.new(0, 0, rz)) then
			Build.decor(Build.part(Vector3.new(p.MainWidth + 4, 0.05, p.BranchWidth + 4), at(0, tileTop + 0.01, rz), {
				Name = "Intersection",
				Color = altColor,
				Material = Enum.Material.Pavement,
				Parent = details,
			}))
		end
	end

	-- Meio-fio baixo nas bordas (decoração, sem colisão), aberto em cruzamentos e na esteira
	local curbY = 0.46
	local function curbBlocked(point: Vector3): boolean
		if busy(point) then
			return true
		end
		-- dentro de OUTRO caminho (cruzamento) -> abre
		local inside = 0
		for _, r in layout:pathRects() do
			if point.X > r.minX - 0.1 and point.X < r.maxX + 0.1 and point.Z > r.minZ - 0.1 and point.Z < r.maxZ + 0.1 then
				inside += 1
			end
		end
		return inside > 1
	end
	for _, side in { -1, 1 } do
		local x = side * (p.MainWidth / 2 + 0.45)
		runs(details, Vector3.new(x, curbY, p.MainFromZ), Vector3.new(x, curbY, p.MainToZ), 0.9, 0.12, curbColor, "Curb", curbBlocked)
		for _, rz in rowZ do
			local z = rz + side * (p.BranchWidth / 2 + 0.45)
			runs(details, Vector3.new(-reach, curbY, z), Vector3.new(reach, curbY, z), 0.9, 0.12, curbColor, "Curb", curbBlocked)
		end
	end
end

------------------------------------------------------------------------------------
-- Dado mágico

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
			-- pontos quadrados (blocky), levemente afundados na face
			local dot = Build.part(Vector3.new(size * 0.16, size * 0.16, size * 0.16), center * CFrame.new(position - normal * size * 0.04), {
				Name = "Pip",
				Color = if count == 1 then rgb(230, 50, 80) else rgb(70, 40, 140),
				Material = Enum.Material.Neon,
				Parent = dice,
			})
			Build.decor(dot)
		end
	end
	local light = Instance.new("PointLight")
	light.Color = rgb(190, 150, 255)
	light.Range = 40
	light.Brightness = 1.4
	light.Parent = body
	return dice
end

------------------------------------------------------------------------------------
-- Hub central: ALTAR DOS ROLLS

local function buildHub(parent: Folder): (BasePart, Model)
	local hub = MapConfig.Hub
	local altar = hub.Altar
	local c = hub.Center
	local center = at(c.x, 0, c.z)
	local plazaTop = 0.8

	Build.cylinder(hub.Radius * 2, plazaTop, center, {
		Name = "Plaza",
		Color = color(P.HubStone),
		Material = Enum.Material.Slate,
		Parent = parent,
	})
	-- Borda chunky da praça, aberta onde os caminhos entram (N/S/L/O)
	local decor = Build.folder("Decor", parent)
	local segments = 28
	for i = 0, segments - 1 do
		local angle = math.pi * 2 * (i + 0.5) / segments
		local deg = math.deg(angle) % 90
		if deg > 14 and deg < 76 then
			local r = hub.Radius - 1.2
			local length = 2 * math.pi * r / segments * 0.82
			Build.decor(Build.part(Vector3.new(2.4, 1.2, length), center * CFrame.Angles(0, -angle, 0) * CFrame.new(r, plazaTop + 0.6, 0), {
				Name = "PlazaRim",
				Color = color(P.HubPurple),
				Parent = decor,
			}))
		end
	end

	-- Degraus largos e baixos (sobe andando), cada um com friso escuro
	local y = plazaTop
	local tierColors = { color(P.HubStone), rgb(206, 196, 238), color(P.HubPurple) }
	for i, side in altar.Tiers do
		Build.decor(Build.part(Vector3.new(side + 1, 0.3, side + 1), center * CFrame.new(0, y + 0.15, 0), {
			Name = "TierTrim",
			Color = color(P.HubPurpleDark),
			Parent = decor,
		}))
		Build.part(Vector3.new(side, altar.StepHeight, side), center * CFrame.new(0, y + altar.StepHeight / 2, 0), {
			Name = `AltarTier{i}`,
			Color = tierColors[i],
			Material = Enum.Material.SmoothPlastic,
			Parent = parent,
		})
		y += altar.StepHeight
	end
	local tierTop = y

	-- Pedestal do dado (bloco grande) com faixa dourada e placas nas 4 faces
	local pedestal = Build.part(Vector3.new(altar.PedestalSize, altar.PedestalHeight, altar.PedestalSize), center * CFrame.new(0, tierTop + altar.PedestalHeight / 2, 0), {
		Name = "DicePedestal",
		Color = color(P.HubPurpleDark),
		Material = Enum.Material.SmoothPlastic,
		Parent = parent,
	})
	local pedTop = tierTop + altar.PedestalHeight
	Build.decor(Build.part(Vector3.new(altar.PedestalSize + 0.6, 0.7, altar.PedestalSize + 0.6), center * CFrame.new(0, pedTop - 0.35, 0), {
		Name = "PedestalBand",
		Color = color(P.Gold),
		Parent = decor,
	}))
	-- sombra do dado no pedestal
	Build.decor(Build.cylinder(altar.PedestalSize * 0.8, 0.05, center * CFrame.new(0, pedTop, 0), {
		Name = "DiceShadow",
		Color = rgb(20, 15, 40),
		Transparency = 0.5,
		Parent = decor,
	}))
	for i = 0, 3 do
		local plate = Build.decor(Build.part(Vector3.new(altar.PedestalSize - 1, altar.PedestalHeight - 1.2, 0.3), center * CFrame.Angles(0, math.rad(90 * i), 0) * CFrame.new(0, tierTop + (altar.PedestalHeight - 0.7) / 2, -altar.PedestalSize / 2 - 0.2), {
			Name = "PedestalPlate",
			Color = color(P.HubPurple),
			Parent = parent,
		}))
		Build.sign(plate, Enum.NormalId.Front, {
			{ Localization.t("map.hub_title"), 0.55, rgb(255, 230, 90) },
			{ Localization.t("map.hub_sub"), 0.35 },
		})
	end

	-- Anel de energia (octógono) em volta do último degrau
	local ringR = altar.Tiers[3] / 2 + 3
	for i = 0, 7 do
		local angle = math.pi / 4 * i
		Build.decor(Build.part(Vector3.new(2 * ringR * math.tan(math.pi / 8) + 0.3, 0.12, 0.9), center * CFrame.Angles(0, angle, 0) * CFrame.new(0, plazaTop + altar.StepHeight * 2 + 0.06, -ringR), {
			Name = "RuneRing",
			Color = rgb(190, 160, 255),
			Material = Enum.Material.Neon,
			Parent = decor,
		}))
	end

	-- Pilares nos cantos do 1º degrau com dados flutuando (RNG por todo lado)
	local corner = altar.Tiers[1] / 2 - 4
	for i, sx in { -1, 1, -1, 1 } do
		local sz = if i <= 2 then -1 else 1
		local base = center * CFrame.new(sx * corner, plazaTop + altar.StepHeight, sz * corner)
		Decor.pillar(decor, base, 3, altar.CornerPillarHeight, color(P.HubStone), color(P.Gold), true)
		Decor.smallDice(decor, base * CFrame.new(0, altar.CornerPillarHeight + 2.6, 0) * CFrame.Angles(0.6, 0.5 * i, 0.3), 3)
	end

	local dice = buildDice(parent, center * CFrame.new(0, hub.DiceHeight, 0) * CFrame.Angles(0.5, 0.6, 0.2), hub.DiceSize)
	Build.tag(dice, "HubDice")
	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Name = "Sparkles"
	sparkles.Color = ColorSequence.new(rgb(255, 240, 160), rgb(190, 150, 255))
	sparkles.LightEmission = 1
	sparkles.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) })
	sparkles.Lifetime = NumberRange.new(2, 3)
	sparkles.Rate = 8
	sparkles.Speed = NumberRange.new(3, 6)
	sparkles.SpreadAngle = Vector2.new(30, 30)
	sparkles.EmissionDirection = Enum.NormalId.Top
	sparkles.Parent = pedestal

	-- Cristais grandes nas diagonais e lanternas entre eles (fora dos caminhos)
	local colors = { rgb(140, 220, 255), rgb(255, 150, 220), rgb(180, 140, 255), rgb(255, 220, 120) }
	for i = 1, 8 do
		local angle = math.pi * 2 * (i - 0.5) / 8
		local r = hub.Radius - 9
		local spot = center * CFrame.new(math.cos(angle) * r, plazaTop, math.sin(angle) * r)
		if i % 2 == 0 then
			Decor.crystal(decor, spot, 8, colors[(i // 2) % 4 + 1])
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
-- Área comercial: três prédios com silhuetas DIFERENTES (mesmas posições de antes)

-- frente (local -Z) virada para o Hub (+Z)
local function shopOrigin(spot: any): CFrame
	return CFrame.lookAt(Vector3.new(spot.x, 0, spot.z), Vector3.new(spot.x, 0, spot.z + 1))
end

local function shopModel(parent: Instance, id: string): Model
	local model = Build.model(id, parent)
	model:SetAttribute("ShopId", id)
	Build.tag(model, "ShopStand", "Interactable")
	return model
end

local function signBoard(parent: Instance, cf: CFrame, width: number, height: number, boardColor: Color3, lines: { { any } }): Part
	local board = Build.part(Vector3.new(width, height, 0.8), cf, { Name = "SignBoard", Color = boardColor, Parent = parent })
	Build.decor(Build.part(Vector3.new(width + 0.8, height + 0.8, 0.5), cf * CFrame.new(0, 0, 0.4), { Name = "SignFrame", Color = rgb(40, 35, 55), Parent = parent }))
	Build.sign(board, Enum.NormalId.Front, lines)
	return board
end

-- MERCADO: barraca com toldo listrado, caixotes e bandeirinhas
local function buildMarket(parent: Instance, spot: any)
	local model = shopModel(parent, "Market")
	local origin = shopOrigin(spot)
	local w, d = spot.width, spot.depth
	local orange = rgb(255, 150, 60)
	Build.part(Vector3.new(w, 1, d), origin * CFrame.new(0, 0.5, 0), { Name = "Floor", Color = color(P.Wood), Material = Enum.Material.WoodPlanks, Parent = model })
	Build.part(Vector3.new(w, 8, 1.2), origin * CFrame.new(0, 5, d / 2 - 0.6), { Name = "BackWall", Color = color(P.WoodDark), Material = Enum.Material.WoodPlanks, Parent = model })
	for _, x in { -w / 2 + 0.9, w / 2 - 0.9 } do
		for _, z in { -d / 2 + 0.9, d / 2 - 0.9 } do
			Build.part(Vector3.new(1.8, 10, 1.8), origin * CFrame.new(x, 6, z), { Name = "Post", Color = color(P.WoodDark), Material = Enum.Material.Wood, Parent = model })
		end
	end
	-- toldo listrado inclinado para a frente
	local stripes = 6
	for i = 1, stripes do
		local x = -w / 2 + (i - 0.5) * w / stripes
		Build.decor(Build.part(Vector3.new(w / stripes + 0.05, 0.6, d + 3), origin * CFrame.new(x, 11.4, -1) * CFrame.Angles(math.rad(12), 0, 0), {
			Name = "Awning",
			Color = if i % 2 == 0 then rgb(255, 250, 240) else orange,
			Parent = model,
		}))
	end
	local counter = Build.part(Vector3.new(w - 4, 3.5, 2), origin * CFrame.new(0, 2.75, -d / 2 + 2), { Name = "Counter", Color = rgb(150, 100, 60), Material = Enum.Material.Wood, Parent = model })
	-- caixotes de frutas nas laterais
	for i, offset in { Vector3.new(-w / 2 - 2, 1.5, -d / 2 + 2), Vector3.new(w / 2 + 2, 1.5, -d / 2 + 3), Vector3.new(w / 2 + 2, 4.1, -d / 2 + 3) } do
		Build.decor(Build.part(Vector3.new(3, 2.6, 3), origin * CFrame.new(offset) * CFrame.Angles(0, i * 0.2, 0), { Name = "Crate", Color = color(P.Wood), Material = Enum.Material.WoodPlanks, Parent = model }))
		Build.decor(Build.part(Vector3.new(2.4, 0.6, 2.4), origin * CFrame.new(offset + Vector3.new(0, 1.5, 0)), { Name = "Fruit", Color = if i == 2 then rgb(255, 90, 80) else rgb(120, 220, 90), Parent = model }))
	end
	signBoard(model, origin * CFrame.new(0, 14.6, -d / 2 - 0.6), w - 2, 3.8, orange, { { "🛒 " .. Localization.t("map.market"), 0.85 } })
	Build.prompt(counter, "Market", Localization.t("map.market"), Localization.t("prompt.open"))
end

-- VENDER: cofre de pedra com moeda gigante no telhado
local function buildSell(parent: Instance, spot: any)
	local model = shopModel(parent, "Sell")
	local origin = shopOrigin(spot)
	local w, d = spot.width, spot.depth
	local green, gold = rgb(80, 200, 110), color(P.Gold)
	Build.part(Vector3.new(w, 1, d), origin * CFrame.new(0, 0.5, 0), { Name = "Floor", Color = color(P.StoneDark), Material = Enum.Material.Slate, Parent = model })
	Build.part(Vector3.new(w, 9, 1.4), origin * CFrame.new(0, 5.5, d / 2 - 0.7), { Name = "BackWall", Color = color(P.Stone), Material = Enum.Material.Slate, Parent = model })
	for _, x in { -w / 2 + 0.8, w / 2 - 0.8 } do
		Build.part(Vector3.new(1.6, 9, d), origin * CFrame.new(x, 5.5, 0), { Name = "SideWall", Color = color(P.Stone), Material = Enum.Material.Slate, Parent = model })
	end
	-- telhado plano com ameias e faixa verde
	Build.part(Vector3.new(w + 1.4, 1.2, d + 1.4), origin * CFrame.new(0, 10.6, 0), { Name = "Roof", Color = green, Parent = model })
	for _, x in { -w / 2, w / 2 } do
		for _, z in { -d / 2, d / 2 } do
			Build.decor(Build.part(Vector3.new(2.2, 1.8, 2.2), origin * CFrame.new(x, 12.1, z), { Name = "Crenel", Color = color(P.Stone), Parent = model }))
		end
	end
	-- moeda gigante em pé no telhado, virada para o Hub, com "$" nas duas faces
	local coin = Build.part(Vector3.new(1.4, 9, 9), origin * CFrame.new(0, 16.4, 0) * CFrame.Angles(0, math.rad(90), 0), { Name = "BigCoin", Color = gold, Parent = model })
	coin.Shape = Enum.PartType.Cylinder
	Build.decor(coin)
	Build.sign(coin, Enum.NormalId.Left, { { "$", 0.9, rgb(255, 250, 220) } })
	Build.sign(coin, Enum.NormalId.Right, { { "$", 0.9, rgb(255, 250, 220) } })
	local counter = Build.part(Vector3.new(w - 4, 3.5, 2), origin * CFrame.new(0, 2.75, -d / 2 + 2), { Name = "Counter", Color = green, Parent = model })
	-- pilhas de moedas e sacos de dinheiro na frente
	for i, x in { -w / 2 - 2, w / 2 + 2 } do
		for k = 0, 2 - i % 2 do
			Build.decor(Build.cylinder(2.6, 0.7, origin * CFrame.new(x, 0.75 * k, -d / 2 + 2), { Name = "CoinStack", Color = gold, Parent = model }))
		end
		Build.decor(Build.part(Vector3.new(2.4, 2.4, 2.4), origin * CFrame.new(x, 1.2, -d / 2 + 5) * CFrame.Angles(0, 0.4 * i, 0), { Name = "MoneyBag", Color = rgb(190, 150, 90), Parent = model }))
	end
	signBoard(model, origin * CFrame.new(0, 8.4, -d / 2 - 0.4), w - 3, 3.4, green, { { "💰 " .. Localization.t("map.sell"), 0.85 } })
	Build.prompt(counter, "Sell", Localization.t("map.sell"), Localization.t("prompt.open"))
end

-- LOJA DE DADOS: portal sobre o caminho principal (o caminho passa por baixo), torres de
-- dados nas laterais e um dado gigante em cima
local function buildDiceShop(parent: Instance, spot: any)
	local model = shopModel(parent, "DiceShop")
	local origin = shopOrigin(spot)
	local w, d = spot.width, spot.depth
	local purple, gold = rgb(150, 90, 240), color(P.Gold)
	local towerW = (w - MapConfig.Paths.MainWidth) / 2 - 0.5
	local towerX = w / 2 - towerW / 2
	local towerH = 13
	-- As torres terminam antes da fileira de caminhos que passa atrás da loja (z local +3 = caminho)
	local backZ = 2.5
	local towerFront = -d / 2 + 4
	local towerD = backZ - towerFront
	local towerZ = (backZ + towerFront) / 2
	local counter: Part? = nil
	for i, side in { -1, 1 } do
		local x = side * towerX
		Build.part(Vector3.new(towerW, 1, backZ + d / 2), origin * CFrame.new(x, 0.5, (backZ - d / 2) / 2), { Name = "Floor", Color = rgb(70, 50, 120), Parent = model })
		Build.part(Vector3.new(towerW, towerH, towerD), origin * CFrame.new(x, 1 + towerH / 2, towerZ), { Name = "Tower", Color = purple, Parent = model })
		-- "faces de dado" brancas nas torres
		Build.decor(Build.part(Vector3.new(towerW - 1.4, towerW - 1.4, 0.3), origin * CFrame.new(x, 8, -d / 2 + 3.9), { Name = "DiceFace", Color = rgb(250, 248, 255), Parent = model }))
		Build.decor(Build.part(Vector3.new(1.4, 1.4, 0.3), origin * CFrame.new(x, 8, -d / 2 + 3.7), { Name = "DicePip", Color = rgb(230, 50, 80), Material = Enum.Material.Neon, Parent = model }))
		Build.decor(Build.part(Vector3.new(towerW + 0.8, 1, towerD + 0.8), origin * CFrame.new(x, 1 + towerH + 0.5, towerZ), { Name = "TowerCap", Color = gold, Parent = model }))
		Decor.smallDice(model, origin * CFrame.new(x, 1 + towerH + 3.2, towerZ) * CFrame.Angles(0.5, 0.3 * i, 0.2), 3.4)
		local c = Build.part(Vector3.new(towerW - 0.6, 3.5, 2), origin * CFrame.new(x, 2.75, -d / 2 + 2), { Name = if i == 1 then "Counter" else "CounterB", Color = rgb(110, 70, 190), Parent = model })
		if i == 1 then
			counter = c
		end
	end
	-- ponte por cima do caminho (altura livre de ~12 studs)
	local bridge = Build.part(Vector3.new(w, 4, 6), origin * CFrame.new(0, 1 + towerH + 2, -d / 2 + 4), { Name = "Bridge", Color = rgb(110, 70, 190), Parent = model })
	Build.decor(bridge)
	Build.sign(bridge, Enum.NormalId.Front, { { "🎲 " .. Localization.t("map.dice_shop"), 0.85, rgb(255, 230, 90) } })
	Build.sign(bridge, Enum.NormalId.Back, { { "🎲 " .. Localization.t("map.dice_shop"), 0.85, rgb(255, 230, 90) } })
	buildDice(model, origin * CFrame.new(0, 1 + towerH + 10, -d / 2 + 4) * CFrame.Angles(0.4, 0.5, 0.2), 7)
	Decor.crystal(model, origin * CFrame.new(-w / 2 - 2.5, 0, -d / 2), 7, rgb(190, 140, 255))
	Decor.crystal(model, origin * CFrame.new(w / 2 + 2.5, 0, -d / 2), 7, rgb(140, 220, 255))
	if counter then
		Build.prompt(counter, "DiceShop", Localization.t("map.dice_shop"), Localization.t("prompt.open"))
	end
end

local function buildShops(parent: Folder): BasePart
	local s = MapConfig.Shops
	buildMarket(parent, s.Market)
	buildDiceShop(parent, s.DiceShop)
	buildSell(parent, s.Sell)
	return teleportPoint("ShopSpawn", MapConfig.Spawns.Shop, parent)
end

------------------------------------------------------------------------------------
-- Torres: portal de COMBATE + torre em degraus com ameias + espada e escudo gigantes

local function buildTowers(parent: Folder): BasePart
	local t = MapConfig.Towers
	local origin = CFrame.lookAt(Vector3.new(t.x, 0, t.z), Vector3.new(t.x, 0, t.z - 1)) -- frente para o Hub (-Z)
	local stone = rgb(90, 80, 120)
	local stoneLight = rgb(118, 104, 152)
	local accent = rgb(255, 90, 140)
	local half = t.portalWidth / 2

	for _, x in { -half, half } do
		Build.part(Vector3.new(5, t.portalHeight, 5), origin * CFrame.new(x, t.portalHeight / 2, 0), {
			Name = "PortalPillar",
			Color = stone,
			Material = Enum.Material.Slate,
			Parent = parent,
		})
		Build.decor(Build.part(Vector3.new(6.4, 2, 6.4), origin * CFrame.new(x, 1, 0), { Name = "PillarBase", Color = stoneLight, Parent = parent }))
		Build.decor(Build.part(Vector3.new(1.2, t.portalHeight - 6, 0.6), origin * CFrame.new(x, t.portalHeight / 2, -2.7), {
			Name = "PillarGlow",
			Color = accent,
			Material = Enum.Material.Neon,
			Parent = parent,
		}))
	end
	local beam = Build.part(Vector3.new(t.portalWidth + 10, 7, 5), origin * CFrame.new(0, t.portalHeight + 3.5, 0), {
		Name = "PortalBeam",
		Color = stone,
		Material = Enum.Material.Slate,
		Parent = parent,
	})
	Build.sign(beam, Enum.NormalId.Front, {
		{ "⚔️ " .. Localization.t("map.towers"), 0.6, rgb(255, 120, 150) },
		{ Localization.t("map.towers_sub"), 0.3 },
	})
	for _, x in { -t.portalWidth / 2 - 4, 0, t.portalWidth / 2 + 4 } do
		Build.decor(Build.part(Vector3.new(3, 2.4, 3), origin * CFrame.new(x, t.portalHeight + 8.2, 0), { Name = "Crenel", Color = stoneLight, Parent = parent }))
	end
	local portal = Build.part(Vector3.new(t.portalWidth - 5, t.portalHeight - 2, 0.6), origin * CFrame.new(0, (t.portalHeight - 2) / 2 + 0.5, 0), {
		Name = "PortalField",
		Color = rgb(200, 70, 160),
		Material = Enum.Material.Neon,
		Transparency = 0.45,
		Parent = parent,
	})
	portal.CanCollide = false
	Build.tag(portal, "Interactable")
	Build.prompt(portal, "Towers", Localization.t("map.towers"), Localization.t("prompt.open"))

	-- Torre atrás do portal: blocos em degraus com ameias nos cantos e faixa neon
	local body = origin * CFrame.new(0, 0, 18)
	local y = 0
	for i, info in { { 30, 22 }, { 24, 20 }, { 18, 18 }, { 12, 10 } } do
		local w, h = info[1], info[2]
		Build.part(Vector3.new(w, h, w), body * CFrame.new(0, y + h / 2, 0), {
			Name = `TowerTier{i}`,
			Color = if i % 2 == 0 then stoneLight else stone,
			Material = Enum.Material.Slate,
			Parent = parent,
		})
		Build.decor(Build.part(Vector3.new(w + 0.6, 0.8, w + 0.6), body * CFrame.new(0, y + h - 0.4, 0), {
			Name = "TierRing",
			Color = accent,
			Material = Enum.Material.Neon,
			Parent = parent,
		}))
		for _, sx in { -1, 1 } do
			for _, sz in { -1, 1 } do
				Build.decor(Build.part(Vector3.new(3, 2.4, 3), body * CFrame.new(sx * (w / 2 - 1.5), y + h + 1.2, sz * (w / 2 - 1.5)), {
					Name = "Crenel",
					Color = stoneLight,
					Parent = parent,
				}))
			end
		end
		y += h
	end
	Build.decor(Build.part(Vector3.new(6, 6, 6), body * CFrame.new(0, y + 4, 0) * CFrame.Angles(math.rad(45), 0, math.rad(45)), {
		Name = "TowerOrb",
		Color = rgb(255, 110, 170),
		Material = Enum.Material.Neon,
		Parent = parent,
	}))

	-- Espada gigante cravada no chão (esquerda) e escudo (direita): COMBATE
	local sword = Build.model("GiantSword", parent)
	local sb = origin * CFrame.new(-half - 10, 0, -2)
	Build.decor(Build.part(Vector3.new(2.4, 16, 0.8), sb * CFrame.new(0, 7, 0) * CFrame.Angles(0, 0, math.rad(8)), { Name = "Blade", Color = rgb(225, 230, 245), Material = Enum.Material.Metal, Parent = sword }))
	Build.decor(Build.part(Vector3.new(8, 1.4, 1.6), sb * CFrame.new(-2.2, 15.4, 0) * CFrame.Angles(0, 0, math.rad(8)), { Name = "Guard", Color = color(P.Gold), Parent = sword }))
	Build.decor(Build.part(Vector3.new(1.2, 4, 1.2), sb * CFrame.new(-2.6, 18, 0) * CFrame.Angles(0, 0, math.rad(8)), { Name = "Grip", Color = rgb(110, 60, 40), Parent = sword }))
	Build.decor(Build.part(Vector3.new(2, 2, 2), sb * CFrame.new(-2.9, 20.6, 0) * CFrame.Angles(0, 0, math.rad(8)), { Name = "Pommel", Color = color(P.Gold), Parent = sword }))
	local shield = Build.model("GiantShield", parent)
	local hb = origin * CFrame.new(half + 10, 0, -2)
	Build.decor(Build.part(Vector3.new(1.4, 3, 4), hb * CFrame.new(0, 1.5, 0), { Name = "Stand", Color = stone, Parent = shield }))
	local disk = Build.part(Vector3.new(1.2, 11, 11), hb * CFrame.new(0, 8.5, 0) * CFrame.Angles(0, math.rad(90), 0), { Name = "Shield", Color = rgb(210, 60, 90), Parent = shield })
	disk.Shape = Enum.PartType.Cylinder
	Build.decor(disk)
	Build.decor(Build.part(Vector3.new(3.2, 3.2, 1.6), hb * CFrame.new(0, 8.5, -0.6) * CFrame.Angles(0, 0, math.rad(45)), { Name = "Emblem", Color = color(P.Gold), Parent = shield }))

	local entrance = teleportPoint("TowerEntrance", MapConfig.Spawns.TowerEntrance, parent)
	Build.tag(entrance, "TowerEntrance")
	return entrance
end

------------------------------------------------------------------------------------
-- Área social: Fusão, Missões, Trocas, Rankings

-- origem com a frente (local -Z) virada para o centro do Hub
local function facingHub(spot: { x: number, z: number }): CFrame
	local c = MapConfig.Hub.Center
	return CFrame.lookAt(Vector3.new(spot.x, 0, spot.z), Vector3.new(c.x, 0, c.z))
end

local function buildSocial(parent: Folder)
	local s = MapConfig.Social

	-- Fusão: plataforma em 2 degraus, runa quadrada, altar com cristal grande, pilares de cristal
	local fusion = Build.model("Fusion", parent)
	Build.tag(fusion, "Interactable")
	local fo = facingHub(s.Fusion)
	Build.part(Vector3.new(18, 1, 18), fo * CFrame.new(0, 0.5, 0), { Name = "Platform", Color = rgb(70, 60, 110), Material = Enum.Material.Slate, Parent = fusion })
	Build.part(Vector3.new(12, 1, 12), fo * CFrame.new(0, 1.5, 0), { Name = "Platform2", Color = rgb(96, 82, 148), Material = Enum.Material.Slate, Parent = fusion })
	local rune = Decor.chunkyBorder(fusion, fo * CFrame.new(0, 2, 0), 9, 9, 0.5, 0.12, rgb(120, 255, 220))
	for _, part in rune:GetChildren() do
		(part :: BasePart).Material = Enum.Material.Neon
	end
	local altar = Build.part(Vector3.new(5, 3.5, 5), fo * CFrame.new(0, 3.75, 0), { Name = "Altar", Color = rgb(110, 90, 170), Material = Enum.Material.Slate, Parent = fusion })
	Decor.crystal(fusion, fo * CFrame.new(0, 5.5, 0), 9, rgb(120, 255, 220))
	for i, x in { -6.5, 6.5 } do
		local base = fo * CFrame.new(x, 1, 6.5)
		Build.decor(Build.part(Vector3.new(3.4, 3, 3.4), base * CFrame.new(0, 1.5, 0), { Name = "CrystalBase", Color = color(P.StoneDark), Parent = fusion }))
		Decor.crystal(fusion, base * CFrame.new(0, 3, 0), 7, if i == 1 then rgb(200, 120, 255) else rgb(255, 140, 210))
	end
	Decor.rockCluster(fusion, fo * CFrame.new(-10, 0, 8), 4, 901, false)
	Decor.rockCluster(fusion, fo * CFrame.new(10, 0, 8), 4, 902, false)
	Decor.sign(fusion, fo * CFrame.new(0, 0, 10.5), "✨ " .. Localization.t("map.fusion"), rgb(110, 70, 220), { width = 12, lift = 6 })
	Build.prompt(altar, "Fusion", Localization.t("map.fusion"), Localization.t("prompt.open"))

	-- Missões: quadro de avisos com telhadinho + NPC guia
	local missions = Build.model("Missions", parent)
	Build.tag(missions, "Interactable")
	local mo = facingHub(s.Missions)
	for _, x in { -5.6, 5.6 } do
		Build.part(Vector3.new(1.2, 10, 1.2), mo * CFrame.new(x, 5, 2.4), { Name = "Post", Color = color(P.WoodDark), Material = Enum.Material.Wood, Parent = missions })
	end
	local board = Build.part(Vector3.new(10, 7, 0.8), mo * CFrame.new(0, 5.5, 2), {
		Name = "Board",
		Color = rgb(150, 105, 65),
		Material = Enum.Material.Wood,
		Parent = missions,
	})
	Build.sign(board, Enum.NormalId.Front, {
		{ "📜 " .. Localization.t("map.missions"), 0.3, rgb(255, 230, 90) },
		{ "• • •", 0.25 },
	}, rgb(245, 235, 210))
	for _, side in { -1, 1 } do
		Build.decor(Build.wedge(Vector3.new(14, 2, 4), mo * CFrame.new(0, 11, 2.4 + side * 2) * CFrame.Angles(0, if side == 1 then math.pi else 0, 0), {
			Name = "Roof",
			Color = rgb(230, 150, 40),
			Parent = missions,
		}))
	end
	local npc = Build.model("GuideNPC", missions)
	local npcBase = mo * CFrame.new(-8, 0, 0)
	Build.part(Vector3.new(2, 2, 1), npcBase * CFrame.new(0, 3, 0), { Color = rgb(60, 120, 220), Parent = npc })
	Build.part(Vector3.new(2, 2, 1), npcBase * CFrame.new(0, 1, 0), { Color = rgb(50, 50, 70), Parent = npc })
	Build.part(Vector3.new(1.6, 1.6, 1.6), npcBase * CFrame.new(0, 4.8, 0), { Color = rgb(255, 210, 170), Parent = npc })
	Build.decor(Build.part(Vector3.new(2.4, 0.5, 2.4), npcBase * CFrame.new(0, 5.8, 0), { Color = rgb(255, 200, 60), Parent = npc }))
	Build.prompt(board, "Missions", Localization.t("map.missions"), Localization.t("prompt.open"))

	-- Trocas: tenda listrada sobre tapete, mesas e banquinhos
	local trade = Build.model("Trade", parent)
	Build.tag(trade, "Interactable")
	local to = facingHub(s.Trade)
	Build.part(Vector3.new(16, 0.2, 12), to * CFrame.new(0, 0.1, 0), {
		Name = "Rug",
		Color = rgb(230, 90, 90),
		Material = Enum.Material.Fabric,
		Parent = trade,
	})
	for _, x in { -7.4, 7.4 } do
		for _, z in { -5.4, 5.4 } do
			Build.decor(Build.part(Vector3.new(1, 8.5, 1), to * CFrame.new(x, 4.25, z), { Name = "TentPost", Color = color(P.WoodDark), Parent = trade }))
		end
	end
	for i = 1, 4 do
		Build.decor(Build.part(Vector3.new(16.6, 0.5, 3.3), to * CFrame.new(0, 8.8, -6.6 + (i - 0.5) * 3.3), {
			Name = "TentRoof",
			Color = if i % 2 == 0 then rgb(255, 250, 240) else rgb(230, 80, 80),
			Parent = trade,
		}))
	end
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
			Build.part(Vector3.new(1.6, 1.6, 1.6), to * CFrame.new(x, 0.8, z), { Name = "Stool", Color = rgb(255, 200, 80), Parent = trade })
		end
	end
	Decor.sign(trade, to * CFrame.new(0, 0, 8.5), "🤝 " .. Localization.t("map.trade"), rgb(230, 80, 80), { width = 12, lift = 6 })
	if tableTop then
		Build.prompt(tableTop, "Trade", Localization.t("map.trade"), Localization.t("prompt.open"))
	end

	-- Rankings: pódio (ouro/prata/bronze) na frente de 3 painéis
	local boards = Build.model("Leaderboards", parent)
	local lo = facingHub(s.Leaderboards)
	-- Arco côncavo virado para o Hub. ANTES: raio 4 com ±28° => centros a ~1,9 stud e painéis de
	-- 9 studs uns DENTRO dos outros (os textos das mesmas linhas apareciam lado a lado). Agora o
	-- pivô fica BOARD_RADIUS à frente e a corda entre painéis vizinhos = BOARD_SPACING (> largura).
	local BOARD_RADIUS = 24
	local BOARD_SPACING = 11 -- moldura 9,8 + folga
	local step = 2 * math.asin(BOARD_SPACING / (2 * BOARD_RADIUS))
	for i, key in { "map.lb_rebirths", "map.lb_tower", "map.lb_rolls" } do
		local panelCf = lo * CFrame.new(0, 0, 4 - BOARD_RADIUS) * CFrame.Angles(0, (i - 2) * step, 0) * CFrame.new(0, 0, BOARD_RADIUS)
		for _, x in { -3.5, 3.5 } do
			Build.decor(Build.part(Vector3.new(1, 3, 1), panelCf * CFrame.new(x, 1.5, 0), {
				Color = rgb(70, 65, 85),
				Parent = boards,
			}))
		end
		local panel = Build.part(Vector3.new(9, 11, 0.8), panelCf * CFrame.new(0, 8.5, 0), {
			Name = `Panel{i}`,
			Color = rgb(40, 35, 60),
			Parent = boards,
		})
		Build.rankingBoard(panel, Enum.NormalId.Front, Localization.t(key), rgb(255, 220, 80), 5)
		Build.decor(Build.part(Vector3.new(9.8, 11.8, 0.4), panelCf * CFrame.new(0, 8.5, 0.6), { Name = "PanelFrame", Color = rgb(60, 140, 230), Parent = boards }))
	end
	local podiums: { { x: number, h: number, color: Color3 } } = {
		{ x = 0, h = 3, color = rgb(255, 205, 70) },
		{ x = -4.2, h = 2, color = rgb(205, 210, 225) },
		{ x = 4.2, h = 1.3, color = rgb(205, 130, 70) },
	}
	for _, info in podiums do
		Build.part(Vector3.new(4, info.h, 3.6), lo * CFrame.new(info.x, info.h / 2, -2.6), { Name = "Podium", Color = info.color, Parent = boards })
	end
	-- Título acima do painel do meio
	local header = Build.part(Vector3.new(14, 3.4, 0.6), lo * CFrame.new(0, 16.5, 4), {
		Name = "Header",
		Color = rgb(60, 140, 230),
		Parent = boards,
	})
	Build.decor(header)
	Build.sign(header, Enum.NormalId.Front, { { "🏆 " .. Localization.t("map.rankings"), 0.85 } })
end

------------------------------------------------------------------------------------
-- Esteira TERRESTRE (estrutura fixa; ripas e objetos andando são criados no cliente).
-- Mesma rota oval de sempre (MapLayout:conveyorPath), no chão: topo da esteira a
-- MapLayout:conveyorTop() studs do chão, bordas baixas e SEM pilares. Onde a pista cruza um
-- caminho (MapLayout:onPath), as bordas abrem e viram faixa de travessia (listras + balizas).
-- Visual "tech/dice": setas emissivas no sentido do movimento.

local function buildConveyor(parent: Folder)
	local c = MapConfig.Conveyor
	local path = layout:conveyorPath()
	local beltColor = rgb(55, 55, 70)
	local railColor = rgb(255, 200, 60)
	local y = c.Height
	local top = layout:conveyorTop()
	local railY = top + c.RailHeight / 2
	local count = #path.points
	local railWidth = 1
	local railOffset = c.BeltWidth / 2 + railWidth / 2

	-- Borda de um lado de um trecho, quebrada onde passa um caminho
	local function rails(from: Vector3, to: Vector3, side: number)
		local length = (to - from).Magnitude
		local dir = (to - from).Unit
		local normal = Vector3.new(-dir.Z, 0, dir.X) * side * railOffset
		local runStart: number? = nil
		local function flush(runEnd: number)
			if runStart and runEnd - runStart >= 1 then
				local a = from + dir * runStart + normal
				local b = from + dir * runEnd + normal
				Build.decor(Build.part(Vector3.new(railWidth, c.RailHeight, runEnd - runStart), CFrame.lookAt((a + b) / 2, b) + Vector3.new(0, railY - (a.Y + b.Y) / 2, 0), {
					Name = "Rail",
					Color = railColor,
					Parent = parent,
				}))
			end
			runStart = nil
		end
		local t = 0
		while t <= length do
			local point = from + dir * t + normal
			if layout:onPath(point.X, point.Z, c.CrossingMargin) then
				flush(t)
			elseif runStart == nil then
				runStart = t
			end
			t += 1
		end
		flush(length)
	end

	-- TRANSPORTE: a parte ancorada com AssemblyLinearVelocity carrega pela física de contato quem
	-- está em cima (simulado no dono do personagem: o cliente). Sem script, sem loop, sem CFrame
	-- no personagem; ao sair da esteira não há mais contato, logo nenhuma força.
	for i, a in path.points do
		local b = path.points[i % count + 1]
		local from = Vector3.new(a.x, y, a.z)
		local to = Vector3.new(b.x, y, b.z)
		local length = (to - from).Magnitude
		local cf = CFrame.lookAt((from + to) / 2, to)
		local belt = Build.part(Vector3.new(c.BeltWidth, c.BeltThickness, length), cf, { Name = "Belt", Color = beltColor, Parent = parent })
		local vx, vz = MapLayout.beltVelocity(c, a.x, a.z, b.x, b.z)
		belt.AssemblyLinearVelocity = Vector3.new(vx, 0, vz)
		for _, side in { -1, 1 } do
			rails(from, to, side)
		end
		-- Disco na emenda das curvas (mesma altura da esteira: não vira degrau; decorativo)
		Build.decor(Build.cylinder(c.BeltWidth, c.BeltThickness, CFrame.new(a.x, y - c.BeltThickness / 2, a.z), {
			Name = "Joint",
			Color = beltColor,
			Parent = parent,
		}))
	end

	local details = Build.folder("Details", parent)
	-- Setas ">" emissivas a cada 22 studs (fora dos cruzamentos), no sentido do movimento
	local d = 6
	while d < path.length do
		local x, z, pdx, pdz = MapLayout.pointAt(path, d)
		local dx, dz = MapLayout.conveyorFlow(c, pdx, pdz) -- mesmo sentido da física e da animação
		if not layout:onPath(x, z, c.CrossingMargin + 2) then
			local forward = CFrame.lookAt(Vector3.new(x, top + 0.03, z), Vector3.new(x + dx, top + 0.03, z + dz))
			for _, sign in { -1, 1 } do
				local offsetX, yaw = MapLayout.conveyorChevron(sign)
				Build.decor(Build.part(Vector3.new(0.45, 0.06, 2.6), forward * CFrame.new(offsetX, 0, 0) * CFrame.Angles(0, yaw, 0), {
					Name = "Arrow",
					Color = rgb(255, 214, 90),
					Material = Enum.Material.Neon,
					Parent = details,
				}))
			end
		end
		d += 22
	end

	-- Cruzamentos: listras de faixa de pedestre sobre a esteira + balizas baixas nas pontas das bordas
	local wasOn = false
	local runStart = 0
	local d2 = 0
	while d2 <= path.length + 1 do
		local x, z = MapLayout.pointAt(path, d2)
		local on = layout:onPath(x, z) and d2 <= path.length
		if on and not wasOn then
			runStart = d2
		elseif wasOn and not on then
			for s = runStart + 0.8, d2 - 0.8, 2 do
				local sx, sz, sdx, sdz = MapLayout.pointAt(path, s)
				Build.decor(Build.part(Vector3.new(c.BeltWidth - 1, 0.05, 0.9), CFrame.lookAt(Vector3.new(sx, top + 0.025, sz), Vector3.new(sx + sdx, top + 0.025, sz + sdz)), {
					Name = "CrossingStripe",
					Color = rgb(250, 248, 240),
					Parent = details,
				}))
			end
			for _, edge in { runStart - c.CrossingMargin - 1.2, d2 + c.CrossingMargin + 0.4 } do
				local bx, bz, bdx, bdz = MapLayout.pointAt(path, edge)
				for _, side in { -1, 1 } do
					local nx, nz = -bdz * side * railOffset, bdx * side * railOffset
					Build.decor(Build.part(Vector3.new(1.2, 1.3, 1.2), CFrame.new(bx + nx, 0.65, bz + nz), {
						Name = "Bollard",
						Color = rgb(255, 180, 50),
						Parent = details,
					}))
				end
			end
		end
		wasOn = on
		d2 += 0.5
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
	-- World Art Pass: studs/inlet/saturação por papel (não move nem redimensiona nada)
	WorldStyle.apply(map)

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
