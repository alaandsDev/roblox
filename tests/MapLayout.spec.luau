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

	it("esteira passa alto o suficiente para jogadores andarem por baixo", function()
		expect(MapConfig.Conveyor.Height >= 10).toBeTruthy()
	end)

	it("pointAt devolve direção unitária", function()
		local path = map:conveyorPath()
		for d = 0, path.length, 37 do
			local _, _, dx, dz = MapLayout.pointAt(path, d)
			expect(math.abs(math.sqrt(dx * dx + dz * dz) - 1) < 1e-6).toBeTruthy()
		end
	end)
end)

return true
