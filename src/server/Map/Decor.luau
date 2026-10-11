--!strict
-- Enfeites low-poly feitos com peças simples (sem assets externos):
-- palmeira, pedra, arbusto, cristal, bandeira, poste de luz.
-- Tudo ancorado e sem colisão (exceto onde indicado).

local Build = require(script.Parent.Build)

local Decor = {}

local rgb = Build.rgb

function Decor.palm(parent: Instance, base: CFrame, height: number, seed: number): Model
	local model = Build.model("Palm", parent)
	local random = Random.new(seed)
	local lean = math.rad(random:NextNumber(4, 12))
	local turn = random:NextNumber(0, math.pi * 2)
	local segments = 4
	local cf = base * CFrame.Angles(0, turn, 0)
	local segmentHeight = height / segments
	for i = 1, segments do
		local d = 1.8 - i * 0.18
		local trunk = Build.cylinder(d, segmentHeight + 0.4, cf, {
			Color = if i % 2 == 0 then rgb(150, 105, 65) else rgb(135, 92, 55),
			Material = Enum.Material.Wood,
			Parent = model,
		})
		Build.decor(trunk)
		cf = cf * CFrame.new(0, segmentHeight, 0) * CFrame.Angles(lean / segments, 0, 0)
	end
	local top = cf
	for i = 1, 6 do
		local angle = math.pi * 2 * i / 6 + random:NextNumber(-0.2, 0.2)
		local leaf = Build.part(
			Vector3.new(2.6, 0.35, 9),
			top * CFrame.Angles(0, angle, 0) * CFrame.Angles(math.rad(-22), 0, 0) * CFrame.new(0, 0, -4.2),
			{ Color = if i % 2 == 0 then rgb(70, 175, 70) else rgb(95, 200, 80), Material = Enum.Material.Grass, Parent = model }
		)
		Build.decor(leaf)
	end
	for i = 1, 2 do
		Build.decor(Build.ball(1, top * CFrame.new(i == 1 and 0.6 or -0.5, -0.7, 0.3), {
			Color = rgb(110, 75, 40),
			Parent = model,
		}))
	end
	return model
end

function Decor.rock(parent: Instance, base: CFrame, size: number, seed: number): Model
	local model = Build.model("Rock", parent)
	local random = Random.new(seed)
	for i = 1, 3 do
		local s = size * random:NextNumber(0.5, 1)
		local piece = Build.part(
			Vector3.new(s, s * random:NextNumber(0.6, 1.1), s * random:NextNumber(0.7, 1.2)),
			base
				* CFrame.new(random:NextNumber(-size, size) * 0.4, s * 0.3, random:NextNumber(-size, size) * 0.4)
				* CFrame.Angles(random:NextNumber(-0.4, 0.4), random:NextNumber(0, 6.28), random:NextNumber(-0.4, 0.4)),
			{
				Color = if i == 1 then rgb(150, 145, 140) else rgb(125, 122, 120),
				Material = Enum.Material.Rock,
				Parent = model,
			}
		)
		if size < 6 then
			Build.decor(piece)
		end
	end
	return model
end

function Decor.bush(parent: Instance, base: CFrame, size: number): Model
	local model = Build.model("Bush", parent)
	for i, offset in { Vector3.new(0, 0, 0), Vector3.new(size * 0.45, -0.2, 0.2), Vector3.new(-size * 0.4, -0.3, -0.2) } do
		Build.decor(Build.ball(size * (1 - (i - 1) * 0.2), base * CFrame.new(offset + Vector3.new(0, size * 0.35, 0)), {
			Color = if i == 1 then rgb(80, 180, 75) else rgb(100, 195, 85),
			Material = Enum.Material.Grass,
			Parent = model,
		}))
	end
	return model
end

function Decor.crystal(parent: Instance, base: CFrame, height: number, color: Color3): Model
	local model = Build.model("Crystal", parent)
	for i, info in { { 0, 1, 0 }, { 1.3, 0.65, 0.5 }, { -1.1, 0.55, -0.6 } } do
		local h = height * info[2]
		Build.decor(Build.part(
			Vector3.new(h * 0.3, h, h * 0.3),
			base * CFrame.new(info[1], h * 0.45, info[3]) * CFrame.Angles(0, math.rad(45), math.rad((i - 2) * 12)),
			{ Color = color, Material = Enum.Material.Neon, Transparency = 0.15, Parent = model }
		))
	end
	return model
end

function Decor.flag(parent: Instance, base: CFrame, height: number, color: Color3): Model
	local model = Build.model("Flag", parent)
	Build.decor(Build.cylinder(0.4, height, base, { Color = rgb(235, 235, 240), Material = Enum.Material.Metal, Parent = model }))
	Build.decor(Build.part(Vector3.new(0.15, 2.4, 3.6), base * CFrame.new(0, height - 1.5, 1.9), { Color = color, Parent = model }))
	return model
end

function Decor.lamp(parent: Instance, base: CFrame, color: Color3): Model
	local model = Build.model("Lamp", parent)
	Build.decor(Build.cylinder(0.6, 7, base, { Color = rgb(70, 65, 85), Material = Enum.Material.Metal, Parent = model }))
	Build.decor(Build.ball(1.6, base * CFrame.new(0, 7.6, 0), { Color = color, Material = Enum.Material.Neon, Parent = model }))
	return model
end

return Decor
