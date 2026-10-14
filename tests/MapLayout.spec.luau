local T = require("./TestLib")
local MapLayout = require("../src/shared/Modules/MapLayout")
local MapConfig = require("../src/shared/Config/MapConfig")
local BaseConfig = require("../src/shared/Config/BaseConfig")
local describe, it, expect = T.describe, T.it, T.expect

local map = MapLayout.new(MapConfig, BaseConfig)

local function rectsOverlap(a, b)
	return a.minX < b.maxX and a.maxX > b.minX and a.minZ < b.maxZ and a.maxZ > b.minZ
end

describe("MapLayout: dimensões", function()
	it("mapa ~500-550 x 330-380", function()
		expect(MapConfig.Island.SizeZ >= 500 and MapConfig.Island.SizeZ <= 550).toBeTruthy()
		expect(MapConfig.Island.SizeX >= 330 and MapConfig.Island.SizeX <= 380).toBeTruthy()
	end)

	it("base ~70-80 x 55-65", function()
		expect(BaseConfig.Width >= 70 and BaseConfig.Width <= 80).toBeTruthy()
		expect(BaseConfig.Depth >= 55 and BaseConfig.Depth <= 65).toBeTruthy()
	end)

	it("Hub com 90-110 de diâmetro", function()
		local d = MapConfig.Hub.Radius * 2
		expect(d >= 90 and d <= 110).toBeTruthy()
	end)
end)

describe("MapLayout: 10 bases", function()
	it("Base01-05 à esquerda, Base06-10 à direita", function()
		for id = 1, 10 do
			local b = map:base(id)
			if id <= 5 then
				expect(b.side).toBe("Left")
				expect(b.x < 0).toBeTruthy()
			else
				expect(b.side).toBe("Right")
				expect(b.x > 0).toBeTruthy()
			end
		end
	end)

	it("Base01/Base06 no fundo e Base05/Base10 na entrada", function()
		expect(map:base(1).z > map:base(2).z).toBeTruthy()
		expect(map:base(5).z < map:base(4).z).toBeTruthy()
		expect(map:base(1).z).toBe(map:base(6).z)
		expect(map:base(5).z).toBe(map:base(10).z)
	end)

	it("todas voltadas para o centro", function()
		for id = 1, 10 do
			local b = map:base(id)
			expect(b.faceX * b.x < 0).toBeTruthy()
		end
	end)

	it("nenhuma base sobrepõe outra e todas cabem na ilha", function()
		for a = 1, 10 do
			local ra = map:baseRect(a)
			expect(map:insideIsland(ra.minX, ra.minZ) and map:insideIsland(ra.maxX, ra.maxZ)).toBeTruthy()
			for b = a + 1, 10 do
				expect(rectsOverlap(ra, map:baseRect(b))).toBeFalsy()
			end
		end
	end)

	it("vão entre bases vizinhas e corredor central largo", function()
		local gap = MapConfig.Bases.RowSpacing - BaseConfig.Width
		expect(gap >= 4).toBeTruthy()
		local corridor = map:baseRect(6).minX - map:baseRect(1).maxX
		expect(corridor >= 150).toBeTruthy()
	end)

	it("entrada da base fica do lado do corredor; lado A é a esquerda de quem entra", function()
		-- Base01 (esquerda): frente = +X
		local ex, _ = map:baseToWorld(1, 0, -BaseConfig.Depth / 2)
		expect(ex > map:base(1).x).toBeTruthy()
		-- quem entra na Base01 anda para -X; a esquerda dele é +Z
		local _, az = map:baseToWorld(1, BaseConfig.SideOffsetX, 0)
		expect(az > map:base(1).z).toBeTruthy()
		-- Base06 (direita): frente = -X; quem entra anda para +X; esquerda dele é -Z
		local ex6, _ = map:baseToWorld(6, 0, -BaseConfig.Depth / 2)
		expect(ex6 < map:base(6).x).toBeTruthy()
		local _, az6 = map:baseToWorld(6, BaseConfig.SideOffsetX, 0)
		expect(az6 < map:base(6).z).toBeTruthy()
	end)
end)

describe("MapLayout: Hub, lojas, torres e esteira", function()
	it("lojas a 40-80 studs do centro e próximas entre si", function()
		for name, shop in MapConfig.Shops do
			local d = map:distanceToHub(shop.x, shop.z)
			if d < 40 or d > 80 then
				error(`{name} a {d} do centro`)
			end
		end
		local m, s = MapConfig.Shops.Market, MapConfig.Shops.Sell
		expect(math.abs(m.x - s.x) <= 100).toBeTruthy()
	end)

	it("lojas, torres e áreas sociais fora do Hub, das bases e dentro da ilha", function()
		local spots = {}
		for name, v in MapConfig.Shops do
			spots[name] = v
		end
		for name, v in MapConfig.Social do
			spots[name] = v
		end
		spots.Towers = MapConfig.Towers
		for name, v in spots do
			if map:distanceToHub(v.x, v.z) < MapConfig.Hub.Radius then
				error(`{name} dentro do Hub`)
			end
			if map:insideAnyBase(v.x, v.z) then
				error(`{name} dentro de uma base`)
			end
			expect(map:insideIsland(v.x, v.z, 20)).toBeTruthy()
		end
	end)

	it("destinos de teleporte válidos (dentro da ilha, fora das bases, livres do dado)", function()
		for name, spawn in MapConfig.Spawns do
			expect(map:insideIsland(spawn.x, spawn.z, 10)).toBeTruthy()
			expect(map:insideAnyBase(spawn.x, spawn.z)).toBeNil()
			if map:distanceToHub(spawn.x, spawn.z) < MapConfig.Hub.DiceSize then
				error(`{name} embaixo do dado`)
			end
		end
	end)

	it("esteira: circuito fechado entre o Hub e as bases", function()
		local path = map:conveyorPath()
		expect(path.length > 500).toBeTruthy()
		local x, z = MapLayout.pointAt(path, 0)
		local x2, z2 = MapLayout.pointAt(path, path.length)
		expect(math.abs(x - x2) < 1e-6 and math.abs(z - z2) < 1e-6).toBeTruthy()
		for _, p in path.points do
			expect(map:insideIsland(p.x, p.z, 10)).toBeTruthy()
			expect(map:insideAnyBase(p.x, p.z)).toBeNil()
			expect(map:distanceToHub(p.x, p.z) > MapConfig.Hub.Radius).toBeTruthy()
		end
	end)

	it("esteira é TERRESTRE: topo 0,3–0,8 stud acima do chão e bordas abaixo da cintura do personagem", function()
		local top = map:conveyorTop()
		expect(top >= 0.3 and top <= 0.8).toBeTruthy()
		-- personagem R6 tem ~5 studs; as bordas ficam abaixo de 1,5 (bem mais baixas que ele)
		expect(top + MapConfig.Conveyor.RailHeight <= 1.5).toBeTruthy()
		expect(MapConfig.Conveyor.PillarSpacing).toBeNil()
	end)

	it("esteira no chão não atravessa nenhuma base nem sai da ilha (largura inteira, a cada 2 studs)", function()
		local path = map:conveyorPath()
		local half = MapConfig.Conveyor.BeltWidth / 2 + 0.6
		for d = 0, path.length, 2 do
			local x, z, dx, dz = MapLayout.pointAt(path, d)
			for _, side in { -1, 0, 1 } do
				local px, pz = x - dz * half * side, z + dx * half * side
				expect(map:insideAnyBase(px, pz)).toBeNil()
				expect(map:insideIsland(px, pz, 5)).toBeTruthy()
				expect(map:distanceToHub(px, pz) > MapConfig.Hub.Radius).toBeTruthy()
			end
		end
	end)

	it("cruzamentos com caminhos: pista rente ao caminho (dá para atravessar a pé)", function()
		local path = map:conveyorPath()
		local crossings = 0
		local wasOn = false
		for d = 0, path.length, 1 do
			local x, z = MapLayout.pointAt(path, d)
			local on = map:onPath(x, z)
			if on and not wasOn then
				crossings += 1
			end
			wasOn = on
		end
		-- caminho principal (curva sul) + ligações das 5 fileiras dos dois lados
		expect(crossings).toBe(1 + 2 * MapConfig.Bases.PerSide)
		-- degrau entre o caminho (topo 0,4) e a esteira: pequeno o bastante para andar por cima
		expect(map:conveyorTop() - 0.4 <= 0.5).toBeTruthy()
	end)

	it("pointAt devolve direção unitária", function()
		local path = map:conveyorPath()
		for d = 0, path.length, 37 do
			local _, _, dx, dz = MapLayout.pointAt(path, d)
			expect(math.abs(math.sqrt(dx * dx + dz * dz) - 1) < 1e-6).toBeTruthy()
		end
	end)
end)

describe("MapLayout: decoração blocky (vegetação e borda)", function()
	local spots = map:decorSpots()

	it("quantidade razoável e determinística (mobile: poucas peças)", function()
		expect(#spots >= 60).toBeTruthy()
		expect(#spots <= 260).toBeTruthy()
		local again = map:decorSpots()
		expect(#again).toBe(#spots)
		expect(again[1].x).toBe(spots[1].x)
		local kinds = {}
		for _, s in spots do
			kinds[s.kind] = (kinds[s.kind] or 0) + 1
		end
		for _, kind in { "Palm", "Tree", "Bush", "Rocks", "Flowers" } do
			expect((kinds[kind] or 0) > 0).toBeTruthy()
		end
	end)

	it("nenhuma decoração em caminho, base, esteira, Hub, landmark ou spawn", function()
		for _, s in spots do
			expect(map:decorBlocked(s.x, s.z, s.radius)).toBeNil()
			expect(map:onPath(s.x, s.z, s.radius)).toBeFalsy()
			expect(map:insideAnyBase(s.x, s.z)).toBeNil()
			for _, spawn in map:spawnPoints() do
				expect(math.sqrt((s.x - spawn.x) ^ 2 + (s.z - spawn.z) ^ 2) >= MapConfig.Visual.DecorClearance.Spawn).toBeTruthy()
			end
		end
	end)

	it("spawns incluem Hub/Shop/TowerEntrance e o PlayerSpawn das 10 bases", function()
		expect(#map:spawnPoints() >= 3 + 2 * MapConfig.Bases.PerSide).toBeTruthy()
	end)

	it("árvores ficam longe do centro (landmarks visíveis a partir do Hub)", function()
		for _, s in spots do
			if s.kind == "Tree" then
				expect(math.sqrt(s.x * s.x + s.z * s.z) >= MapConfig.Visual.OpenCenterRadius).toBeTruthy()
			end
		end
	end)

	it("entre a esteira e as bases só canteiros de flores (não tapa a visão das bases)", function()
		local minX = MapConfig.Conveyor.HalfX + MapConfig.Conveyor.BeltWidth / 2
		local maxX = MapConfig.Bases.CenterX - BaseConfig.Depth / 2
		for _, s in spots do
			if math.abs(s.x) > minX and math.abs(s.x) < maxX and math.abs(s.z) < MapConfig.Conveyor.StraightHalfZ then
				expect(s.kind).toBe("Flowers")
			end
		end
	end)

	it("recortes da borda não encostam em bases nem caminhos", function()
		local bites = map:edgeBites()
		expect(#bites > 10).toBeTruthy()
		for _, b in bites do
			expect(map:nearBase(b.x, b.z, 2 + b.length / 2)).toBeFalsy()
			expect(map:onPath(b.x, b.z, b.length / 2 + 2)).toBeFalsy()
		end
	end)

	it("landmarks não ficam em cima do caminho principal (exceto o portal da Dice Shop)", function()
		for _, l in MapConfig.Landmarks do
			if l.id ~= "DiceShop" and l.id ~= "Entrance" and l.id ~= "Towers" then
				expect(map:onPath(l.x, l.z)).toBeFalsy()
			end
		end
	end)
end)

describe("Esteira: velocidade física (MapLayout.beltVelocity)", function()
	local base = { Speed = 12, Direction = 1, CarryPlayers = true }
	local function near(a: number, b: number): boolean
		return math.abs(a - b) < 1e-9
	end

	it("sentido do trecho (ordem do caminho) e velocidade = Speed", function()
		local vx, vz = MapLayout.beltVelocity(base, 0, 0, 10, 0)
		expect(near(vx, 12) and near(vz, 0)).toBeTruthy()
		vx, vz = MapLayout.beltVelocity(base, 5, 5, 5, -15)
		expect(near(vx, 0) and near(vz, -12)).toBeTruthy()
		vx, vz = MapLayout.beltVelocity(base, 0, 0, 3, 4)
		expect(near(math.sqrt(vx * vx + vz * vz), 12)).toBeTruthy()
	end)

	it("Direction = -1 inverte (visual usa o mesmo sinal)", function()
		local vx = MapLayout.beltVelocity({ Speed = 12, Direction = -1, CarryPlayers = true }, 0, 0, 10, 0)
		expect(near(vx, -12)).toBeTruthy()
	end)

	it("desativado (CarryPlayers = false) -> velocidade zero", function()
		local vx, vz = MapLayout.beltVelocity({ Speed = 12, Direction = 1, CarryPlayers = false }, 0, 0, 10, 0)
		expect(vx == 0 and vz == 0).toBeTruthy()
	end)

	it("config inválida -> erro (Speed <= 0, Speed absurda, Direction fora de ±1, trecho de comprimento zero)", function()
		expect((pcall(MapLayout.beltVelocity, { Speed = 0, Direction = 1, CarryPlayers = true }, 0, 0, 1, 0))).toBe(false)
		expect((pcall(MapLayout.beltVelocity, { Speed = 500, Direction = 1, CarryPlayers = true }, 0, 0, 1, 0))).toBe(false)
		expect((pcall(MapLayout.beltVelocity, { Speed = 12, Direction = 2, CarryPlayers = true }, 0, 0, 1, 0))).toBe(false)
		expect((pcall(MapLayout.beltVelocity, base, 3, 3, 3, 3))).toBe(false)
	end)

	it("config real: velocidade e sentido válidos; a pista inteira tem velocidade em cada trecho", function()
		local c = MapConfig.Conveyor
		local path = MapLayout.new(MapConfig, BaseConfig):conveyorPath()
		for i, a in path.points do
			local b = path.points[i % #path.points + 1]
			local vx, vz = MapLayout.beltVelocity(c, a.x, a.z, b.x, b.z)
			expect(near(math.sqrt(vx * vx + vz * vz), c.Speed)).toBeTruthy()
			-- mesmo sentido da animação (pointAt avança na ordem do caminho)
			local dx, dz = b.x - a.x, b.z - a.z
			expect((vx * dx + vz * dz) * c.Direction > 0).toBeTruthy()
		end
	end)
end)

return true
