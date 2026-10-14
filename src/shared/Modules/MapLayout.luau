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

export type Rect = { minX: number, maxX: number, minZ: number, maxZ: number }

-- Retângulos dos caminhos de chão (o MapBuilder desenha estes mesmos caminhos)
function MapLayout:pathRects(): { Rect }
	local p = self.map.Paths
	local rects: { Rect } = {
		{ minX = -p.MainWidth / 2, maxX = p.MainWidth / 2, minZ = p.MainFromZ, maxZ = p.MainToZ },
	}
	local reach = self.map.Bases.CenterX - self.baseConfig.Depth / 2
	for row = 1, self.map.Bases.PerSide do
		local z = self:base(row).z
		table.insert(rects, { minX = -reach, maxX = reach, minZ = z - p.BranchWidth / 2, maxZ = z + p.BranchWidth / 2 })
	end
	return rects
end

-- Algum caminho de chão cobre (x, z)? margin aumenta cada retângulo
function MapLayout:onPath(x: number, z: number, margin: number?): boolean
	local m = margin or 0
	for _, r in self:pathRects() do
		if x >= r.minX - m and x <= r.maxX + m and z >= r.minZ - m and z <= r.maxZ + m then
			return true
		end
	end
	return false
end

-- Altura do topo da esteira (as ripas e itens do cliente andam sobre ela)
function MapLayout:conveyorTop(): number
	local c = self.map.Conveyor
	return c.Height + c.BeltThickness / 2
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

--[[
	Velocidade FÍSICA de um trecho da esteira (de `fromX,fromZ` para `toX,toZ`, na ordem do
	caminho), em studs/s: AssemblyLinearVelocity da parte ancorada = o contato transporta o
	personagem (mesmo sentido e velocidade da animação do cliente). Devolve (vx, vz).
	CarryPlayers = false -> (0, 0). Config inválida -> erro (nada de esteira "meio configurada").
]]
function MapLayout.beltVelocity(conveyor: any, fromX: number, fromZ: number, toX: number, toZ: number): (number, number)
	assert(type(conveyor.Speed) == "number" and conveyor.Speed > 0 and conveyor.Speed < 100, "Conveyor.Speed inválida (0 < Speed < 100)")
	assert(conveyor.Direction == 1 or conveyor.Direction == -1, "Conveyor.Direction deve ser 1 ou -1")
	if not conveyor.CarryPlayers then
		return 0, 0
	end
	local dx, dz = toX - fromX, toZ - fromZ
	local length = math.sqrt(dx * dx + dz * dz)
	assert(length > 1e-6, "trecho de esteira com comprimento zero")
	local k = conveyor.Speed * conveyor.Direction / length
	return dx * k, dz * k
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

------------------------------------------------------------------------------------
-- Visual blocky: o que a decoração NÃO pode invadir e onde plantar (determinístico)

-- Menor distância de (x, z) até a linha central da esteira
function MapLayout:distanceToConveyor(x: number, z: number): number
	local path = self:conveyorPath()
	local best = math.huge
	local count = #path.points
	for i, a in path.points do
		local b = path.points[i % count + 1]
		local dx, dz = b.x - a.x, b.z - a.z
		local len2 = dx * dx + dz * dz
		local t = if len2 > 0 then math.clamp(((x - a.x) * dx + (z - a.z) * dz) / len2, 0, 1) else 0
		local px, pz = a.x + dx * t, a.z + dz * t
		best = math.min(best, math.sqrt((x - px) ^ 2 + (z - pz) ^ 2))
	end
	return best
end

-- Pontos de nascimento/teleporte do mapa (Hub/Lojas/Torres) + PlayerSpawn de cada base
function MapLayout:spawnPoints(): { { x: number, z: number } }
	local list = {}
	for _, spot in self.map.Spawns do
		table.insert(list, { x = spot.x, z = spot.z })
	end
	local s = self.baseConfig.Spawn
	for id = 1, self.map.Bases.Count do
		local x, z = self:baseToWorld(id, s.x, s.z)
		table.insert(list, { x = x, z = z })
	end
	return list
end

-- Área funcional (Fusão, Lojas, Torres...) que contém (x, z) com folga `margin`
function MapLayout:landmarkAt(x: number, z: number, margin: number?): string?
	for _, l in self.map.Landmarks or {} do
		if math.sqrt((x - l.x) ^ 2 + (z - l.z) ^ 2) <= l.radius + (margin or 0) then
			return l.id
		end
	end
	return nil
end

-- A base com folga `margin` cobre (x, z)?
function MapLayout:nearBase(x: number, z: number, margin: number): boolean
	for id = 1, self.map.Bases.Count do
		local r = self:baseRect(id)
		if x >= r.minX - margin and x <= r.maxX + margin and z >= r.minZ - margin and z <= r.maxZ + margin then
			return true
		end
	end
	return false
end

-- Motivo pelo qual não dá para decorar um círculo (x, z, radius); nil = livre
function MapLayout:decorBlocked(x: number, z: number, radius: number): string?
	local c = self.map.Visual.DecorClearance
	if not self:insideIsland(x, z, c.IslandEdge + radius) then
		return "ilha"
	elseif self:onPath(x, z, c.Path + radius) then
		return "caminho"
	elseif self:nearBase(x, z, c.Base + radius) then
		return "base"
	elseif self:distanceToConveyor(x, z) < self.map.Conveyor.BeltWidth / 2 + c.Conveyor + radius then
		return "esteira"
	elseif self:distanceToHub(x, z) < self.map.Hub.Radius + c.Hub + radius then
		return "hub"
	elseif self:landmarkAt(x, z, c.Landmark + radius) then
		return "landmark"
	end
	for _, spot in self:spawnPoints() do
		if math.sqrt((x - spot.x) ^ 2 + (z - spot.z) ^ 2) < c.Spawn + radius then
			return "spawn"
		end
	end
	return nil
end

-- Hash determinístico 0..1 (mesmo mapa em todo servidor e nos testes)
local function hash01(a: number, b: number, seed: number): number
	local n = math.sin(a * 12.9898 + b * 78.233 + seed * 37.719) * 43758.5453
	return n - math.floor(n)
end
MapLayout.hash01 = hash01

export type DecorSpot = { kind: string, x: number, z: number, radius: number, scale: number, seed: number }

--[[
	Onde plantar a vegetação blocky. Grade regular com deslocamento determinístico; cada ponto
	vira (ou não) um tipo conforme a zona:
	  faixa da borda (EdgeBand)      -> palmeiras (e algumas pedras)
	  entre a esteira e as bases     -> só canteiros de flores (não tapa a visão das bases)
	  miolo                          -> árvores, arbustos, pedras e flores
	Tudo passa por decorBlocked (caminhos, bases, esteira, Hub, áreas funcionais, spawns).
]]
local RADIUS = { Palm = 3, Tree = 4.5, Bush = 2.2, Rocks = 4, Flowers = 2.5 }
function MapLayout:decorSpots(): { DecorSpot }
	local v = self.map.Visual
	local grid = v.DecorGrid
	local hx, hz = self:islandHalf()
	local spots: { DecorSpot } = {}
	local corridorMin = self.map.Conveyor.HalfX + self.map.Conveyor.BeltWidth / 2
	local corridorMax = self.map.Bases.CenterX - self.baseConfig.Depth / 2
	for gx = -hx, hx, grid do
		for gz = -hz, hz, grid do
			local r1, r2, r3 = hash01(gx, gz, v.DecorSeed), hash01(gz, gx, v.DecorSeed + 1), hash01(gx + gz, gx - gz, v.DecorSeed + 2)
			local x = gx + (r1 - 0.5) * grid * 0.7
			local z = gz + (r2 - 0.5) * grid * 0.7
			local edgeDistance = math.min(hx - math.abs(x), hz - math.abs(z))
			local inCorridor = math.abs(x) > corridorMin and math.abs(x) < corridorMax and math.abs(z) < self.map.Conveyor.StraightHalfZ
			local kind: string? = nil
			if inCorridor then
				kind = if v.BaseCorridorFlowersOnly and r3 < 0.35 then "Flowers" else nil
			elseif edgeDistance < v.EdgeBand then
				kind = if r3 < 0.5 then "Palm" elseif r3 < 0.64 then "Rocks" elseif r3 < 0.7 then "Bush" else nil
			else
				-- Perto do Hub só decoração baixa: as árvores não tampam os landmarks vistos do centro
				local open = math.sqrt(x * x + z * z) < v.OpenCenterRadius
				kind = if r3 < 0.3 then (if open then "Bush" else "Tree") elseif r3 < 0.38 then "Bush" elseif r3 < 0.47 then "Rocks" elseif r3 < 0.6 then "Flowers" else nil
			end
			if kind then
				local radius = RADIUS[kind]
				if not self:decorBlocked(x, z, radius) then
					table.insert(spots, { kind = kind, x = x, z = z, radius = radius, scale = 0.85 + r1 * 0.3, seed = math.floor(r2 * 1e6) })
				end
			end
		end
	end
	return spots
end

-- Recortes decorativos na borda da grama (areia entrando / grama saindo), longe de bases e caminhos
export type EdgeBite = { x: number, z: number, alongX: boolean, length: number, depth: number, sand: boolean }
function MapLayout:edgeBites(): { EdgeBite }
	local v = self.map.Visual
	local hx, hz = self:islandHalf()
	local bites: { EdgeBite } = {}
	local function try(x: number, z: number, alongX: boolean, i: number)
		local r = hash01(x, z, v.DecorSeed + 5)
		local length = 8 + r * 8
		local depth = 2 + hash01(z, x, v.DecorSeed + 6) * 3
		if self:nearBase(x, z, 2 + length / 2) or self:onPath(x, z, length / 2 + 2) or self:landmarkAt(x, z, 4) then
			return
		end
		table.insert(bites, { x = x, z = z, alongX = alongX, length = length, depth = depth, sand = i % 2 == 0 })
	end
	local i = 0
	for x = -hx + 10, hx - 10, v.EdgeBiteSpacing do
		i += 1
		try(x, hz, true, i)
		try(x, -hz, true, i + 1)
	end
	for z = -hz + 10, hz - 10, v.EdgeBiteSpacing do
		i += 1
		try(hx, z, false, i)
		try(-hx, z, false, i + 1)
	end
	return bites
end

return MapLayout
