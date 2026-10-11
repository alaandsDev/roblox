--!strict
--[[
	Posições do mapa em coordenadas do MUNDO, calculadas a partir do MapConfig/BaseConfig.
	Módulo puro (testável fora do Roblox): devolve tabelas { x, z } e números.

	    local map = MapLayout.new(MapConfig, BaseConfig)
	    map:base(1)       --> { id, side = "Left", row = 1, x, z, faceX, faceZ }
	    map:conveyorPath() --> { points = {...}, cumulative = {...}, length = n }
	    map:pointAt(path, distancia) --> x, z, dirX, dirZ
]]

local MapLayout = {}
MapLayout.__index = MapLayout

export type BasePlacement = {
	id: number,
	side: string, -- "Left" (Base01-05) | "Right" (Base06-10)
	row: number, -- 1 = fundo ... 5 = entrada
	x: number,
	z: number,
	faceX: number, -- direção da frente da base (para o corredor central)
	faceZ: number,
}

export type Path = { points: { { x: number, z: number } }, cumulative: { number }, length: number }

function MapLayout.new(mapConfig: any, baseConfig: any): any
	return setmetatable({ map = mapConfig, baseConfig = baseConfig }, MapLayout)
end

function MapLayout:base(id: number): BasePlacement
	local b = self.map.Bases
	assert(id >= 1 and id <= b.Count, "base inválida: " .. tostring(id))
	local left = id <= b.PerSide
	local row = if left then id else id - b.PerSide
	local middle = (b.PerSide + 1) / 2
	return {
		id = id,
		side = if left then "Left" else "Right",
		row = row,
		x = if left then -b.CenterX else b.CenterX,
		z = (middle - row) * b.RowSpacing, -- row 1 no fundo (+Z)
		faceX = if left then 1 else -1,
		faceZ = 0,
	}
end

function MapLayout:bases(): { BasePlacement }
	local list = {}
	for id = 1, self.map.Bases.Count do
		table.insert(list, self:base(id))
	end
	return list
end

-- Retângulo ocupado pela base no mundo { minX, maxX, minZ, maxZ }
function MapLayout:baseRect(id: number): { minX: number, maxX: number, minZ: number, maxZ: number }
	local p = self:base(id)
	local halfDepth = self.baseConfig.Depth / 2
	local halfWidth = self.baseConfig.Width / 2
	return { minX = p.x - halfDepth, maxX = p.x + halfDepth, minZ = p.z - halfWidth, maxZ = p.z + halfWidth }
end

-- Converte posição local da base (BaseConfig) para o mundo.
-- Igual ao CFrame.lookAt(centro, centro + frente) do Roblox: local -Z = frente (face),
-- local +X = RightVector = (-faceZ, faceX) = esquerda de quem entra na base.
function MapLayout:baseToWorld(id: number, lx: number, lz: number): (number, number)
	local p = self:base(id)
	local fx, fz = p.faceX, p.faceZ
	return p.x - fz * lx - fx * lz, p.z + fx * lx - fz * lz
end

function MapLayout:islandHalf(): (number, number)
	return self.map.Island.SizeX / 2, self.map.Island.SizeZ / 2
end

function MapLayout:insideIsland(x: number, z: number, margin: number?): boolean
	local hx, hz = self:islandHalf()
	local m = margin or 0
	return math.abs(x) <= hx - m and math.abs(z) <= hz - m
end

function MapLayout:insideAnyBase(x: number, z: number): number?
	for id = 1, self.map.Bases.Count do
		local r = self:baseRect(id)
		if x >= r.minX and x <= r.maxX and z >= r.minZ and z <= r.maxZ then
			return id
		end
	end
	return nil
end

function MapLayout:distanceToHub(x: number, z: number): number
	local c = self.map.Hub.Center
	return math.sqrt((x - c.x) ^ 2 + (z - c.z) ^ 2)
end

-- Pista oval: duas retas em X = ±HalfX ligadas por semicírculos nas pontas
function MapLayout:conveyorPath(): Path
	local c = self.map.Conveyor
	local points = {}
	local r = c.HalfX
	local zs = c.StraightHalfZ
	-- reta direita subindo (sul -> norte)
	table.insert(points, { x = r, z = -zs })
	table.insert(points, { x = r, z = zs })
	-- semicírculo norte (direita -> esquerda)
	for i = 1, c.ArcSegments - 1 do
		local a = math.pi * i / c.ArcSegments
		table.insert(points, { x = r * math.cos(a), z = zs + r * math.sin(a) })
	end
	-- reta esquerda descendo
	table.insert(points, { x = -r, z = zs })
	table.insert(points, { x = -r, z = -zs })
	-- semicírculo sul (esquerda -> direita), fecha no primeiro ponto
	for i = 1, c.ArcSegments - 1 do
		local a = math.pi + math.pi * i / c.ArcSegments
		table.insert(points, { x = r * math.cos(a), z = -zs + r * math.sin(a) })
	end

	local cumulative = { 0 }
	local total = 0
	for i = 1, #points do
		local a, b = points[i], points[i % #points + 1]
		total += math.sqrt((b.x - a.x) ^ 2 + (b.z - a.z) ^ 2)
		cumulative[i + 1] = total
	end
	return { points = points, cumulative = cumulative, length = total }
end

-- Posição e direção a uma distância ao longo da pista (com volta)
function MapLayout.pointAt(path: Path, distance: number): (number, number, number, number)
	local d = distance % path.length
	local lo, hi = 1, #path.points
	while lo < hi do
		local mid = (lo + hi + 1) // 2
		if path.cumulative[mid] <= d then
			lo = mid
		else
			hi = mid - 1
		end
	end
	local a = path.points[lo]
	local b = path.points[lo % #path.points + 1]
	local segLength = path.cumulative[lo + 1] - path.cumulative[lo]
	local t = if segLength > 0 then (d - path.cumulative[lo]) / segLength else 0
	local dx, dz = b.x - a.x, b.z - a.z
	local len = math.sqrt(dx * dx + dz * dz)
	return a.x + dx * t, a.z + dz * t, if len > 0 then dx / len else 0, if len > 0 then dz / len else 1
end

return MapLayout
