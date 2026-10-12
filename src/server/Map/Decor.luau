--!strict
--[[
	Biblioteca BLOCKY do mapa (sem assets externos): poucos volumes grandes, cores por família
	(MapConfig.Visual.Palette), Neon só como detalhe. Tudo ancorado.
	Colisão: troncos e pedras grandes colidem (ficam longe dos caminhos pelas regras do
	MapLayout); folhas, flores, arbustos, cristais e enfeites NÃO colidem.

	    Decor.tree(parent, base, altura, seed)       tronco + 2–4 blocos de copa
	    Decor.palm(parent, base, altura, seed)       tronco grosso + 5 folhas grandes
	    Decor.bush / Decor.rockCluster / Decor.flowerPatch
	    Decor.crystal(parent, base, altura, cor)     cristal chunky (3 blocos)
	    Decor.lamp / Decor.flag
	    Decor.sign(parent, origem, título, cor, opts) placa blocky com 2 pilares
	    Decor.chunkyBorder(parent, cf, x, z, espessura, altura, cor)  moldura de 4 barras
	    Decor.pillar(parent, base, largura, altura, cor, capCor)      pilar com base e capitel
	    Decor.smallDice(parent, cf, tamanho)          dado decorativo simples
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MapConfig = require(ReplicatedStorage.Shared.Config.MapConfig)
local Build = require(script.Parent.Build)

local Decor = {}

local rgb = Build.rgb
local P = MapConfig.Visual.Palette

local function color(list: { number }): Color3
	return Color3.fromRGB(list[1], list[2], list[3])
end
Decor.color = color

local function pick(list: { { number } }, n: number): Color3
	return color(list[(n % #list) + 1])
end

------------------------------------------------------------------------------------
-- Vegetação

function Decor.tree(parent: Instance, base: CFrame, height: number, seed: number): Model
	local model = Build.model("BlockyTree", parent)
	local random = Random.new(seed)
	local cf = base * CFrame.Angles(0, random:NextNumber(0, math.pi / 2), 0)
	local trunkH = height * 0.45
	local trunkW = 1.8 + height * 0.03
	Build.part(Vector3.new(trunkW, trunkH, trunkW), cf * CFrame.new(0, trunkH / 2, 0), {
		Name = "Trunk",
		Color = color(P.Trunk),
		Material = Enum.Material.Wood,
		Parent = model,
	})
	-- copa: 1 bloco grande + 1–3 menores em cima/ao lado
	local crown = height * 0.42
	local blocks = 2 + random:NextInteger(0, 2)
	for i = 1, blocks do
		local s = crown * (if i == 1 then 1 else random:NextNumber(0.55, 0.75))
		local offset = if i == 1
			then Vector3.new(0, trunkH + s * 0.4, 0)
			else Vector3.new(random:NextNumber(-0.35, 0.35) * crown, trunkH + crown * random:NextNumber(0.55, 0.95), random:NextNumber(-0.35, 0.35) * crown)
		Build.decor(Build.part(Vector3.new(s, s * 0.85, s), cf * CFrame.new(offset) * CFrame.Angles(0, random:NextNumber(-0.4, 0.4), 0), {
			Name = "Leaves",
			Color = pick(P.Leaves, seed + i),
			Material = Enum.Material.SmoothPlastic,
			Parent = model,
		}))
	end
	return model
end

function Decor.palm(parent: Instance, base: CFrame, height: number, seed: number): Model
	local model = Build.model("BlockyPalm", parent)
	local random = Random.new(seed)
	local lean = math.rad(random:NextNumber(5, 12))
	local cf = base * CFrame.Angles(0, random:NextNumber(0, math.pi * 2), 0)
	local segments = 3
	local segmentH = height / segments
	for i = 1, segments do
		local w = 2.2 - i * 0.3
		local trunk = Build.part(Vector3.new(w, segmentH + 0.3, w), cf * CFrame.new(0, segmentH / 2, 0), {
			Name = "Trunk",
			Color = if i % 2 == 0 then color(P.Trunk) else color(P.WoodDark),
			Material = Enum.Material.Wood,
			Parent = model,
		})
		if i > 1 then
			Build.decor(trunk)
		end
		cf = cf * CFrame.new(0, segmentH, 0) * CFrame.Angles(lean / segments, 0, 0)
	end
	-- folhas grandes caídas (5) + cachos de coco (1 bloco)
	for i = 1, 5 do
		local angle = math.pi * 2 * i / 5 + random:NextNumber(-0.15, 0.15)
		Build.decor(Build.part(Vector3.new(3.2, 0.6, height * 0.5), cf * CFrame.Angles(0, angle, 0) * CFrame.Angles(math.rad(-24), 0, 0) * CFrame.new(0, 0, -height * 0.22), {
			Name = "Leaf",
			Color = pick(P.Leaves, seed + i),
			Parent = model,
		}))
	end
	Build.decor(Build.part(Vector3.new(1.8, 1.4, 1.8), cf * CFrame.new(0, -0.9, 0), {
		Name = "Coconuts",
		Color = rgb(110, 75, 40),
		Parent = model,
	}))
	return model
end

function Decor.bush(parent: Instance, base: CFrame, size: number, seed: number?): Model
	local model = Build.model("BlockyBush", parent)
	local n = seed or 1
	Build.decor(Build.part(Vector3.new(size * 1.3, size * 0.8, size), base * CFrame.new(0, size * 0.4, 0) * CFrame.Angles(0, (n % 7) * 0.3, 0), {
		Color = pick(P.Leaves, n),
		Parent = model,
	}))
	Build.decor(Build.part(Vector3.new(size * 0.8, size * 0.6, size * 0.8), base * CFrame.new(size * 0.45, size * 0.75, size * 0.1) * CFrame.Angles(0, (n % 5) * 0.4, 0), {
		Color = pick(P.Leaves, n + 1),
		Parent = model,
	}))
	return model
end

-- Grupo de 3–5 pedras grandes (low-poly). collide = as maiores colidem
function Decor.rockCluster(parent: Instance, base: CFrame, size: number, seed: number, collide: boolean?): Model
	local model = Build.model("BlockyRocks", parent)
	local random = Random.new(seed)
	local count = 3 + random:NextInteger(0, 2)
	for i = 1, count do
		local s = size * (if i == 1 then 1 else random:NextNumber(0.4, 0.7))
		local offset = if i == 1 then Vector3.zero else Vector3.new(random:NextNumber(-1, 1) * size * 0.7, 0, random:NextNumber(-1, 1) * size * 0.7)
		local rock = Build.part(
			Vector3.new(s, s * random:NextNumber(0.6, 0.95), s * random:NextNumber(0.8, 1.2)),
			base * CFrame.new(offset + Vector3.new(0, s * 0.28, 0)) * CFrame.Angles(random:NextNumber(-0.25, 0.25), random:NextNumber(0, 6.28), random:NextNumber(-0.25, 0.25)),
			{
				Name = "Rock",
				Color = if i == 1 then color(P.Stone) else color(P.StoneDark),
				Material = Enum.Material.Slate,
				Parent = model,
			}
		)
		if not (collide and i == 1) then
			Build.decor(rock)
		end
	end
	return model
end

-- Compatível com o uso antigo (pedra única grande)
function Decor.rock(parent: Instance, base: CFrame, size: number, seed: number): Model
	return Decor.rockCluster(parent, base, size, seed, size >= 6)
end

function Decor.flowerPatch(parent: Instance, base: CFrame, seed: number): Model
	local model = Build.model("BlockyFlowers", parent)
	local random = Random.new(seed)
	Build.decor(Build.part(Vector3.new(4.2, 0.5, 3.4), base * CFrame.new(0, 0.25, 0) * CFrame.Angles(0, random:NextNumber(0, 1.5), 0), {
		Color = color(P.GrassDark),
		Parent = model,
	}))
	for i = 1, 3 do
		Build.decor(Build.part(Vector3.one * 0.9, base * CFrame.new(random:NextNumber(-1.4, 1.4), 1.0, random:NextNumber(-1.1, 1.1)) * CFrame.Angles(0, random:NextNumber(0, 1.5), 0), {
			Color = pick(P.Flowers, seed + i),
			Parent = model,
		}))
	end
	return model
end

------------------------------------------------------------------------------------
-- Enfeites

function Decor.crystal(parent: Instance, base: CFrame, height: number, crystalColor: Color3): Model
	local model = Build.model("Crystal", parent)
	for i, info in { { 0, 1, 0, 0 }, { 0.42, 0.6, 0.15, 18 }, { -0.38, 0.5, -0.2, -16 } } do
		local h = height * info[2]
		local w = height * 0.32 * info[2]
		Build.decor(Build.part(Vector3.new(w, h, w), base * CFrame.new(info[1] * height, h * 0.45, info[3] * height) * CFrame.Angles(0, math.rad(45), math.rad(info[4])), {
			Color = crystalColor,
			Material = Enum.Material.Neon,
			Transparency = 0.1,
			Parent = model,
		}))
	end
	return model
end

function Decor.lamp(parent: Instance, base: CFrame, lightColor: Color3): Model
	local model = Build.model("Lamp", parent)
	Build.decor(Build.part(Vector3.new(1.6, 0.6, 1.6), base * CFrame.new(0, 0.3, 0), { Color = color(P.StoneDark), Parent = model }))
	Build.decor(Build.part(Vector3.new(0.8, 6.5, 0.8), base * CFrame.new(0, 3.5, 0), { Color = rgb(70, 65, 85), Parent = model }))
	Build.decor(Build.part(Vector3.new(1.8, 1.8, 1.8), base * CFrame.new(0, 7.4, 0), { Color = lightColor, Material = Enum.Material.Neon, Parent = model }))
	Build.decor(Build.part(Vector3.new(2.4, 0.5, 2.4), base * CFrame.new(0, 8.5, 0), { Color = rgb(70, 65, 85), Parent = model }))
	return model
end

function Decor.flag(parent: Instance, base: CFrame, height: number, flagColor: Color3): Model
	local model = Build.model("Flag", parent)
	Build.decor(Build.part(Vector3.new(0.6, height, 0.6), base * CFrame.new(0, height / 2, 0), { Color = rgb(235, 235, 240), Parent = model }))
	Build.decor(Build.part(Vector3.new(0.3, 2.6, 3.8), base * CFrame.new(0, height - 1.5, 2), { Color = flagColor, Parent = model }))
	return model
end

-- Pilar chunky: base + fuste + capitel (opcionalmente com colisão no fuste)
function Decor.pillar(parent: Instance, base: CFrame, width: number, height: number, bodyColor: Color3, capColor: Color3?, collide: boolean?): Model
	local model = Build.model("Pillar", parent)
	Build.part(Vector3.new(width + 1, 1, width + 1), base * CFrame.new(0, 0.5, 0), { Name = "PillarBase", Color = capColor or color(P.StoneDark), Parent = model })
	Build.part(Vector3.new(width, height - 2, width), base * CFrame.new(0, height / 2, 0), { Name = "PillarBody", Color = bodyColor, Parent = model })
	local cap = Build.part(Vector3.new(width + 1, 1, width + 1), base * CFrame.new(0, height - 0.5, 0), { Name = "PillarCap", Color = capColor or color(P.StoneDark), Parent = model })
	-- Com colisão: só base e fuste colidem (o capitel é enfeite)
	Build.decor(cap)
	if not collide then
		for _, part in model:GetChildren() do
			Build.decor(part)
		end
	end
	return model
end

-- Moldura de 4 barras em volta de um retângulo (bordas grossas)
function Decor.chunkyBorder(parent: Instance, center: CFrame, sizeX: number, sizeZ: number, thickness: number, height: number, borderColor: Color3, collide: boolean?): Model
	local model = Build.model("ChunkyBorder", parent)
	local bars: { { size: Vector3, offset: CFrame } } = {
		{ size = Vector3.new(sizeX + thickness * 2, height, thickness), offset = CFrame.new(0, 0, -(sizeZ + thickness) / 2) },
		{ size = Vector3.new(sizeX + thickness * 2, height, thickness), offset = CFrame.new(0, 0, (sizeZ + thickness) / 2) },
		{ size = Vector3.new(thickness, height, sizeZ), offset = CFrame.new(-(sizeX + thickness) / 2, 0, 0) },
		{ size = Vector3.new(thickness, height, sizeZ), offset = CFrame.new((sizeX + thickness) / 2, 0, 0) },
	}
	for _, bar in bars do
		local part = Build.part(bar.size, center * bar.offset * CFrame.new(0, height / 2, 0), { Name = "Border", Color = borderColor, Parent = model })
		if not collide then
			Build.decor(part)
		end
	end
	return model
end

-- Placa blocky sustentada por 2 pilares baixos. Devolve (model, board)
export type SignOptions = { width: number?, height: number?, lift: number?, sub: string? }
function Decor.sign(parent: Instance, origin: CFrame, title: string, boardColor: Color3, opts: SignOptions?): (Model, Part)
	local o: SignOptions = opts or {}
	local width = o.width or 12
	local boardH = o.height or 3.4
	local lift = o.lift or 5
	local model = Build.model("BlockySign", parent)
	for _, x in { -width / 2 + 0.8, width / 2 - 0.8 } do
		Build.decor(Build.part(Vector3.new(1.2, lift, 1.2), origin * CFrame.new(x, lift / 2, 0), { Color = color(P.WoodDark), Material = Enum.Material.Wood, Parent = model }))
	end
	local board = Build.part(Vector3.new(width, boardH, 0.8), origin * CFrame.new(0, lift + boardH / 2, 0), { Name = "SignBoard", Color = boardColor, Parent = model })
	Build.decor(board)
	-- moldura escura (bordas grossas)
	Build.decor(Build.part(Vector3.new(width + 0.8, boardH + 0.8, 0.5), origin * CFrame.new(0, lift + boardH / 2, 0.35), { Name = "SignFrame", Color = rgb(40, 35, 55), Parent = model }))
	local titleLine: { any } = { title, if o.sub then 0.6 else 0.85 }
	local lines: { { any } } = { titleLine }
	local sub = o.sub
	if sub then
		local subLine: { any } = { sub, 0.3 }
		table.insert(lines, subLine)
	end
	Build.sign(board, Enum.NormalId.Front, lines)
	return model, board
end

-- Dado decorativo simples (cubo + 1 ponto em cada face)
function Decor.smallDice(parent: Instance, cf: CFrame, size: number): Model
	local model = Build.model("SmallDice", parent)
	Build.decor(Build.part(Vector3.one * size, cf, { Name = "Body", Color = rgb(250, 248, 255), Parent = model }))
	for _, normal in { Vector3.xAxis, -Vector3.xAxis, Vector3.yAxis, -Vector3.yAxis, Vector3.zAxis, -Vector3.zAxis } do
		Build.decor(Build.part(Vector3.one * size * 0.24, cf * CFrame.new(normal * size * 0.46), {
			Name = "Pip",
			Color = rgb(150, 90, 240),
			Material = Enum.Material.Neon,
			Parent = model,
		}))
	end
	return model
end

return Decor
