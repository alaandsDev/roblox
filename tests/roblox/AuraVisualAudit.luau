--[[
	Auditoria VISUAL das auras (Lune): mede, sem Studio, o que a câmera da Base veria.
	    lune run tests/roblox/AuraVisualAudit.luau [--report]

	Para cada raridade × estilo × modo (Light/Full) monta o personagem com o AuraBuilder real e
	projeta as partículas (forma do emissor, sentido, velocidade, drag, aceleração, tamanho e
	transparência ao longo da vida, ZOffset, rajadas, beams e trails) na visão FRONTAL da câmera
	(estação vista de frente). Mede:
	    OCLUSÃO  fração da silhueta do personagem coberta por aura NA FRENTE dele
	             (regra: a aura nunca pode "engolir" o personagem)
	    PRESENÇA área equivalente-opaca da aura FORA do corpo (studs²): o quanto a aura aparece
	    ORÇAMENTO partículas/s, vivas, beams, trails, highlights, attachments, instâncias
	Estimativa geométrica (não é o renderizador do Roblox): serve para comparar antes/depois e
	travar regressões; a aprovação final continua visual no Studio.
]]
local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local Env = require("./Env")

local REPORT = table.find(process.args, "--report") ~= nil
local T = Env.checker("Auditoria visual das auras (oclusão × presença × orçamento)")
local check = T.check
local env = Env.create()
if fs.isFile("assets/Characters.rbxm") then
	local folder = roblox.deserializeModel(fs.readFile("assets/Characters.rbxm"))[1]
	folder.Parent = env.real.ReplicatedStorage
end
local CFrame, Vector3, Enum = roblox.CFrame, roblox.Vector3, roblox.Enum

local function worldPos(a: any): any
	local parent = a.Parent
	if parent and parent:IsA("Attachment") then
		return worldPos(parent) + (parent.Parent.CFrame - parent.Parent.CFrame.Position):VectorToWorldSpace(a.Position)
	end
	return parent.CFrame:PointToWorldSpace(a.Position)
end

-- GetBoundingBox real (o AuraBuilder mede o corpo com ele no Roblox)
pcall(roblox.implementMethod, "Model", "GetBoundingBox", function(model)
	local pivot = model:GetPivot()
	local minV, maxV = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			local h = part.Size / 2
			for _, sx in { -1, 1 } do
				for _, sy in { -1, 1 } do
					for _, sz in { -1, 1 } do
						local p = pivot:PointToObjectSpace(part.CFrame:PointToWorldSpace(Vector3.new(h.X * sx, h.Y * sy, h.Z * sz)))
						minV = Vector3.new(math.min(minV.X, p.X), math.min(minV.Y, p.Y), math.min(minV.Z, p.Z))
						maxV = Vector3.new(math.max(maxV.X, p.X), math.max(maxV.Y, p.Y), math.max(maxV.Z, p.Z))
					end
				end
			end
		end
	end
	local center = (minV + maxV) / 2
	return pivot * CFrame.new(center), maxV - minV
end)

local req = env.newContext()
local Factory = req(env.shared.Modules.CharacterModelFactory)
local AuraBuilder = req(env.shared.Modules.AuraBuilder)
local AuraConfig = req(env.shared.Config.AuraConfig)
local CharacterConfig = req(env.shared.Config.CharacterConfig)

------------------------------------------------------------------------------------
-- Estimador

local CELL = 0.25 -- studs por célula da "tela"
local SOFT = { Spark = 0.35, Smoke = 0.6, Fire = 0.5, Ember = 0.35 }
local function textureKey(id: string): string
	for key, path in AuraConfig.Textures do
		if path == id then
			return key
		end
	end
	return "Spark"
end

local function seqAt(seq: any, t: number): number
	local keys = seq.Keypoints
	for i = 1, #keys - 1 do
		local a, b = keys[i], keys[i + 1]
		if t >= a.Time and t <= b.Time then
			local f = (t - a.Time) / math.max(b.Time - a.Time, 1e-6)
			return a.Value + (b.Value - a.Value) * f
		end
	end
	return keys[#keys].Value
end

local seed = 1
local function rand(): number
	seed = (seed * 1103515245 + 12345) % 2147483648
	return seed / 2147483648
end

local function randomUnit(): any
	local z = rand() * 2 - 1
	local a = rand() * math.pi * 2
	local r = math.sqrt(1 - z * z)
	return Vector3.new(r * math.cos(a), z, r * math.sin(a))
end

-- desvia d dentro de um cone (graus)
local function spread(d: any, deg: number): any
	if deg <= 0 then
		return d
	end
	if deg >= 180 then
		return randomUnit()
	end
	local t = math.rad(deg) * rand()
	local o = randomUnit()
	local side = d:Cross(o)
	if side.Magnitude < 1e-3 then
		return d
	end
	side = side.Unit
	return (d * math.cos(t) + side * math.sin(t)).Unit
end

-- ponto de nascimento e direção (aproximação das formas do ParticleEmitter)
local function spawn(e: any, part: any): (any, any)
	local cf, size = part.CFrame, part.Size
	local inward = e.ShapeInOut == Enum.ParticleEmitterShapeInOut.Inward
	local function dirOf(normal: any): any
		local d = if inward then -normal else normal
		if e.ShapeInOut == Enum.ParticleEmitterShapeInOut.InAndOut and rand() < 0.5 then
			d = -normal
		end
		return d
	end
	local volume = e.ShapeStyle == Enum.ParticleEmitterShapeStyle.Volume
	if e.Shape == Enum.ParticleEmitterShape.Cylinder or e.Shape == Enum.ParticleEmitterShape.Disc then
		local a = rand() * math.pi * 2
		local r = if volume then math.sqrt(rand()) else 1
		local local_ = Vector3.new(math.cos(a) * size.X / 2 * r, (rand() - 0.5) * size.Y, math.sin(a) * size.Z / 2 * r)
		local normal = cf:VectorToWorldSpace(Vector3.new(math.cos(a), 0, math.sin(a)))
		return cf:PointToWorldSpace(local_), spread(dirOf(normal), e.SpreadAngle.X)
	elseif e.Shape == Enum.ParticleEmitterShape.Sphere then
		local n = randomUnit()
		local r = if volume then rand() ^ (1 / 3) else 1
		return cf:PointToWorldSpace(Vector3.new(n.X * size.X / 2 * r, n.Y * size.Y / 2 * r, n.Z * size.Z / 2 * r)), spread(dirOf(n), e.SpreadAngle.X)
	end
	-- Box
	if volume then
		local p = Vector3.new((rand() - 0.5) * size.X, (rand() - 0.5) * size.Y, (rand() - 0.5) * size.Z)
		return cf:PointToWorldSpace(p), spread(cf.UpVector, e.SpreadAngle.X)
	end
	local areas = { size.Y * size.Z, size.Y * size.Z, size.X * size.Z, size.X * size.Z, size.X * size.Y, size.X * size.Y }
	local total = 0
	for _, a in areas do
		total += a
	end
	local pick, acc = 1, rand() * total
	for i, a in areas do
		acc -= a
		if acc <= 0 then
			pick = i
			break
		end
	end
	local axes = { Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0), Vector3.new(0, 1, 0), Vector3.new(0, -1, 0), Vector3.new(0, 0, 1), Vector3.new(0, 0, -1) }
	local n = axes[pick]
	local p = Vector3.new((rand() - 0.5) * size.X, (rand() - 0.5) * size.Y, (rand() - 0.5) * size.Z)
	p = Vector3.new(if n.X ~= 0 then n.X * size.X / 2 else p.X, if n.Y ~= 0 then n.Y * size.Y / 2 else p.Y, if n.Z ~= 0 then n.Z * size.Z / 2 else p.Z)
	return cf:PointToWorldSpace(p), spread(dirOf(cf:VectorToWorldSpace(n)), e.SpreadAngle.X)
end

type Screen = { body: { [number]: number }, front: { [number]: number }, around: { [number]: number } }
local W, H0, H1 = 14, -3, 24 -- janela da "tela" em studs (x ±W, y H0..H1) no espaço do pivô
local NX = math.floor(2 * W / CELL)
local function cellIndex(x: number, y: number): number?
	local ix = math.floor((x + W) / CELL)
	local iy = math.floor((y - H0) / CELL)
	if ix < 0 or ix >= NX or iy < 0 or iy >= math.floor((H1 - H0) / CELL) then
		return nil
	end
	return iy * NX + ix
end

-- silhueta do corpo: profundidade da superfície da frente por célula (frente = -Z local)
local function bodySilhouette(model: any, pivot: any): { [number]: number }
	local depth = {}
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part.Transparency < 1 and string.sub(part.Name, 1, 4) ~= "Aura" then
			local h = part.Size / 2
			local minX, maxX, minY, maxY, minZ = math.huge, -math.huge, math.huge, -math.huge, math.huge
			for _, sx in { -1, 1 } do
				for _, sy in { -1, 1 } do
					for _, sz in { -1, 1 } do
						local p = pivot:PointToObjectSpace(part.CFrame:PointToWorldSpace(Vector3.new(h.X * sx, h.Y * sy, h.Z * sz)))
						minX, maxX = math.min(minX, p.X), math.max(maxX, p.X)
						minY, maxY = math.min(minY, p.Y), math.max(maxY, p.Y)
						minZ = math.min(minZ, p.Z)
					end
				end
			end
			-- caixa projetada encolhida 15% (MeshPart/acessório raramente preenche a caixa toda)
			local sx, sy = (maxX - minX) * 0.075, (maxY - minY) * 0.075
			local x = minX + sx
			while x <= maxX - sx do
				local y = minY + sy
				while y <= maxY - sy do
					local i = cellIndex(x, y)
					if i then
						depth[i] = math.min(depth[i] or math.huge, minZ)
					end
					y += CELL
				end
				x += CELL
			end
		end
	end
	return depth
end

export type Measure = {
	rate: number,
	alive: number,
	beams: number,
	trails: number,
	highlights: number,
	attachments: number,
	instances: number,
	presence: number,
	occlusion: number,
}

local SNAPSHOTS = 4
local only: string? = nil -- (detalhe) mede só o emissor com esse nome
local function measure(model: any, opts: { orbit: number? }?): Measure
	local pivot = model:GetPivot()
	local body = bodySilhouette(model, pivot)
	local bodyCells = 0
	for _ in body do
		bodyCells += 1
	end
	local m: Measure = { rate = 0, alive = 0, beams = 0, trails = 0, highlights = 0, attachments = 0, instances = 0, presence = 0, occlusion = 0 }
	for _, d in AuraBuilder.instances(model) do
		m.instances += 1
		if d:IsA("Beam") then
			m.beams += 1
		elseif d:IsA("Trail") then
			m.trails += 1
		elseif d:IsA("Highlight") then
			m.highlights += 1
		elseif d:IsA("Attachment") then
			m.attachments += 1
		end
	end
	local presenceSum, occlusionSum = 0, 0
	for snap = 1, SNAPSHOTS do
		seed = snap * 7919
		local transmit: { [number]: number } = {} -- fração que PASSA (1 = nada cobre)
		local transmitFront: { [number]: number } = {}
		-- flat = sprite deitado no chão (VelocityPerpendicular): visto de frente, ~40% da altura
		local function paint(x: number, y: number, z: number, radius: number, alpha: number, flat: boolean?)
			if alpha <= 0.01 then
				return
			end
			local r = math.max(radius, CELL / 2)
			local ry = if flat then math.max(r * 0.4, CELL / 2) else r
			local x0, x1 = x - r, x + r
			local y0, y1 = y - ry, y + ry
			local cx = x0
			while cx <= x1 do
				local cy = y0
				while cy <= y1 do
					local dx, dy = (cx - x) / r, (cy - y) / ry
					if dx * dx + dy * dy <= 1 then
						local i = cellIndex(cx, cy)
						if i then
							transmit[i] = (transmit[i] or 1) * (1 - alpha)
							local bodyZ = body[i]
							if bodyZ and z < bodyZ then
								transmitFront[i] = (transmitFront[i] or 1) * (1 - alpha)
							end
						end
					end
					cy += CELL
				end
				cx += CELL
			end
		end
		for _, e in model:GetDescendants() do
			if e:IsA("ParticleEmitter") and string.sub(e.Name, 1, 4) == "Aura" and e.Parent and (e.Parent:IsA("BasePart") or e.Parent:IsA("Attachment")) and (only == nil or e.Name == only) then
				local burst = e:GetAttribute("AuraRole") == "Burst"
				local rate = if burst then ((e:GetAttribute("AuraBurstCount") or 10) / (e:GetAttribute("AuraBurstEvery") or 3)) elseif e.Enabled then e.Rate else 0
				local life = (e.Lifetime.Min + e.Lifetime.Max) / 2
				if snap == 1 then
					m.rate += rate
					m.alive += rate * life
				end
				local n = rate * life
				local count = math.floor(n) + (if rand() < n % 1 then 1 else 0)
				local soft = SOFT[textureKey(e.Texture)] or 0.4
				local parent = e.Parent
				local orbitPart = parent:IsA("Attachment") and parent.Parent
				for _ = 1, count do
					local age = rand() * life
					local t = age / math.max(life, 1e-6)
					local p0, dir
					if orbitPart then
						-- emissor num attachment de órbita: posição da órbita num instante qualquer
						local ang = rand() * math.pi * 2
						local radius = parent:GetAttribute("AuraRadius") or parent.Position.Magnitude
						local hgt = parent:GetAttribute("AuraHeight") or parent.Position.Y
						p0 = orbitPart.CFrame:PointToWorldSpace(Vector3.new(math.cos(ang) * radius, hgt, math.sin(ang) * radius))
						dir = randomUnit()
					else
						p0, dir = spawn(e, parent)
					end
					local speed = e.Speed.Min + rand() * (e.Speed.Max - e.Speed.Min)
					local drag = e.Drag
					local travel = if drag > 0 then (1 - 2 ^ (-drag * age)) / (drag * math.log(2)) else age
					local pos = p0 + dir * speed * travel + e.Acceleration * (0.5 * age * age)
					local lp = pivot:PointToObjectSpace(pos)
					-- ZOffset: positivo = para a câmera (câmera em -Z local)
					local z = lp.Z - e.ZOffset
					local size = seqAt(e.Size, t)
					local alpha = (1 - seqAt(e.Transparency, t)) * soft
					paint(lp.X, lp.Y, z, size / 2, alpha, e.Orientation == Enum.ParticleOrientation.VelocityPerpendicular)
				end
			end
		end
		-- beams (largura média × comprimento) e trails das órbitas
		for _, b in model:GetDescendants() do
			if only ~= nil and b.Name ~= only then
				continue
			end
			if b:IsA("Beam") and b.Attachment0 and b.Attachment1 and string.sub(b.Name, 1, 4) == "Aura" then
				local on = if b:GetAttribute("AuraRole") == "Bolt" then 0.75 else (if b.Enabled then 1 else 0)
				local a = pivot:PointToObjectSpace(worldPos(b.Attachment0))
				local c = pivot:PointToObjectSpace(worldPos(b.Attachment1))
				local width = (b.Width0 + b.Width1) / 2
				local alpha = (1 - seqAt(b.Transparency, 0.5)) * 0.8 * on
				local steps = math.max(2, math.floor((c - a).Magnitude / CELL))
				for s = 0, steps do
					local p = a:Lerp(c, s / steps)
					paint(p.X, p.Y, p.Z - b.ZOffset, width / 2, alpha / math.max(1, width / CELL / 2))
				end
			elseif b:IsA("Trail") and b.Attachment0 and string.sub(b.Name, 1, 4) == "Aura" then
				local orbit = b.Attachment0
				local orbitPart = orbit.Parent
				local radius = orbit:GetAttribute("AuraRadius") or 2
				local hgt = orbit:GetAttribute("AuraHeight") or 0
				local speed = math.abs(orbit:GetAttribute("AuraSpeed") or 3)
				local arc = speed * b.Lifetime -- radianos cobertos pelo rastro
				local start = rand() * math.pi * 2
				for s = 0, 12 do
					local ang = start - arc * s / 12
					local p = pivot:PointToObjectSpace(orbitPart.CFrame:PointToWorldSpace(Vector3.new(math.cos(ang) * radius, hgt, math.sin(ang) * radius)))
					paint(p.X, p.Y, p.Z, 0.45, (1 - s / 12) * 0.6)
				end
			end
		end
		local presence, covered = 0, 0
		for i, pass in transmit do
			if not body[i] then
				presence += (1 - pass) * CELL * CELL
			end
		end
		for i in body do
			covered += 1 - (transmitFront[i] or 1)
		end
		presenceSum += presence
		occlusionSum += if bodyCells > 0 then covered / bodyCells else 0
	end
	m.presence = presenceSum / SNAPSHOTS
	m.occlusion = occlusionSum / SNAPSHOTS
	return m
end

------------------------------------------------------------------------------------
-- Casos

-- personagem representativo: asset de altura normal (os gigantes têm caso próprio no relatório)
local function firstOf(rarity: string): string
	for _, c in CharacterConfig.List do
		if c.Rarity == rarity and Factory.hasAsset(c.Id) then
			local h = Factory.height(c.Id)
			if h >= 5 and h <= 11 then
				return c.Id
			end
		end
	end
	for _, c in CharacterConfig.List do
		if c.Rarity == rarity then
			return c.Id
		end
	end
	error("sem " .. rarity)
end

local ORDER = { "Legendary", "Mythic", "Divine", "Secret" }
local styles = {}
for name in AuraConfig.Styles do
	table.insert(styles, name)
end
table.sort(styles)

local function auraOn(id: string, rarity: string, mode: string, style: string?): (any, Measure)
	local model = Factory.build(id, { aura = false, vfx = "Light" })
	model:PivotTo(CFrame.new(0, 10, 0))
	model.Parent = env.real.Workspace
	AuraBuilder.attach(model, id, rarity, mode, Factory.height(id), style)
	local m = measure(model)
	model:Destroy()
	return model, m
end

-- (detalhe) lune run tests/roblox/AuraVisualAudit.luau --detail Secret Dark Light
local detailAt = table.find(process.args, "--detail")
if detailAt then
	local rarity, style, mode = process.args[detailAt + 1], process.args[detailAt + 2], process.args[detailAt + 3]
	local id
	id = firstOf(rarity)
	local model = Factory.build(id, { aura = false, vfx = "Light" })
	model:PivotTo(CFrame.new(0, 10, 0))
	model.Parent = env.real.Workspace
	AuraBuilder.attach(model, id, rarity, mode, Factory.height(id), style)
	local names = {}
	for _, d in model:GetDescendants() do
		if (d:IsA("ParticleEmitter") or d:IsA("Beam") or d:IsA("Trail")) and string.sub(d.Name, 1, 4) == "Aura" and not table.find(names, d.Name) then
			table.insert(names, d.Name)
		end
	end
	for _, name in names do
		only = name
		local m = measure(model)
		print(string.format("%-22s oclusão %3.0f%%  presença %6.1f", name, m.occlusion * 100, m.presence))
	end
	process.exit(0)
end

-- 1) Personagens do relato: Barbalva e Ulkiorra Liberado (Mítico, Void) na estação (Light)
local results: { [string]: Measure } = {}
local worst = { occlusion = 0, key = "" }
local byRarity: { [string]: { light: { number }, full: { number }, occl: { number } } } = {}
for _, rarity in ORDER do
	byRarity[rarity] = { light = {}, full = {}, occl = {} }
	local id = firstOf(rarity)
	for _, style in styles do
		for _, mode in { "Light", "Full" } do
			local _, m = auraOn(id, rarity, mode, style)
			local key = `{rarity}|{style}|{mode}`
			results[key] = m
			table.insert(byRarity[rarity].occl, m.occlusion)
			table.insert(if mode == "Light" then byRarity[rarity].light else byRarity[rarity].full, m.presence)
			if m.occlusion > worst.occlusion then
				worst = { occlusion = m.occlusion, key = key }
			end
		end
	end
end

local function median(list: { number }): number
	local c = table.clone(list)
	table.sort(c)
	return c[math.floor((#c + 1) / 2)] or 0
end

if REPORT then
	print("\nraridade | estilo | modo | part/s | vivas | beams | trails | highl | attach | inst | presença(st²) | oclusão")
	for _, rarity in ORDER do
		for _, style in styles do
			for _, mode in { "Light", "Full" } do
				local m = results[`{rarity}|{style}|{mode}`]
				print(string.format("%s | %s | %s | %.0f | %.0f | %d | %d | %d | %d | %d | %.1f | %.0f%%", rarity, style, mode, m.rate, m.alive, m.beams, m.trails, m.highlights, m.attachments, m.instances, m.presence, m.occlusion * 100))
			end
		end
	end
	print("\nP50 por raridade: presença Light | Full | Light÷Full | oclusão máx")
	for _, rarity in ORDER do
		local b = byRarity[rarity]
		local maxOcc = 0
		for _, o in b.occl do
			maxOcc = math.max(maxOcc, o)
		end
		print(string.format("%s | %.1f | %.1f | %.0f%% | %.0f%%", rarity, median(b.light), median(b.full), median(b.light) / math.max(median(b.full), 1e-6) * 100, maxOcc * 100))
	end
end

-- 2) Pior caso dos personagens do relato
for _, id in { "char_barbalva_base", "char_ulkiorra_release" } do
	if CharacterConfig.ById[id] then
		local _, m = auraOn(id, CharacterConfig.ById[id].Rarity, "Light")
		if REPORT then
			print(string.format("%s (Light, %s): oclusão %.0f%% · presença %.1f", id, AuraBuilder.styleOf(id), m.occlusion * 100, m.presence))
		end
		check(m.occlusion <= 0.3, string.format("%s: a aura cobre no máximo 30%% do personagem (%.0f%%)", id, m.occlusion * 100))
	end
end

-- 3) STRESS na Base (regras do AuraController: MaxAnimated, MaxFull, MaxHighlights, taxa por
--    distância, mobile ×LowEndRateScale). "antes" = mesmo script rodando no commit anterior.
local B = AuraConfig.Budget
local function rateAt(distance: number): number
	if B.DistanceRates then
		for _, step in B.DistanceRates do
			if distance <= step[1] then
				return step[2]
			end
		end
		return B.DistanceRates[#B.DistanceRates][2]
	end
	return if distance > B.MidDistance then 0.5 else 1 -- regra antiga (V2)
end
local STYLE_CYCLE = { "Electric", "Flame", "Void", "Celestial", "Dark", "Wind", "Ice", "Energy", "Spirit", "Gravity" }
local function stress(label: string, list: { { any } })
	for _, mobile in { false, true } do
		local tot = { rate = 0, alive = 0, beams = 0, trails = 0, highlights = 0, attachments = 0, instances = 0, animated = 0 }
		for i, item in list do
			local rarity, distance = item[1], item[2]
			local id = firstOf(rarity)
			local model = Factory.build(id, { aura = false, vfx = "Light" })
			model:PivotTo(CFrame.new(0, 10, 0))
			model.Parent = env.real.Workspace
			AuraBuilder.attach(model, id, rarity, "Light", Factory.height(id), STYLE_CYCLE[(i - 1) % #STYLE_CYCLE + 1])
			local active = i <= B.MaxAnimated and distance <= B.CullDistance
			local f = if active then rateAt(distance) * (if mobile then B.LowEndRateScale else 1) else 0
			for _, d in AuraBuilder.instances(model) do
				tot.instances += 1
				if d:IsA("ParticleEmitter") then
					local life = (d.Lifetime.Min + d.Lifetime.Max) / 2
					local r = if d:GetAttribute("AuraRole") == "Burst" then ((d:GetAttribute("AuraBurstCount") or 10) / (d:GetAttribute("AuraBurstEvery") or 3)) elseif d.Enabled then d.Rate else 0
					tot.rate += r * f
					tot.alive += r * f * life
				elseif d:IsA("Beam") then
					tot.beams += 1
					if active and d:GetAttribute("AuraRole") then
						tot.animated += 1
					end
				elseif d:IsA("Trail") then
					tot.trails += 1
				elseif d:IsA("Highlight") then
					if active and tot.highlights < B.MaxHighlights then
						tot.highlights += 1
					end
				elseif d:IsA("Attachment") then
					tot.attachments += 1
					if active and d:GetAttribute("AuraRole") == "Orbit" then
						tot.animated += 1
					end
				end
			end
			model:Destroy()
		end
		if REPORT then
			print(string.format("STRESS %s%s | part/s %.0f | vivas %.0f | beams %d | trails %d | highlights ligados %d | attachments %d | instâncias VFX %d | objetos animados/frame %d", label, if mobile then " (mobile)" else "", tot.rate, tot.alive, tot.beams, tot.trails, tot.highlights, tot.attachments, tot.instances, tot.animated))
		end
		if not mobile then
			check(tot.rate <= 2600 and tot.alive <= 3200, string.format("stress %s: %.0f partículas/s e %.0f vivas (teto da cena: 2600/s, 3200 vivas)", label, tot.rate, tot.alive))
		end
	end
end
stress("4 Divine (15–45 studs)", { { "Divine", 15 }, { "Divine", 25 }, { "Divine", 35 }, { "Divine", 45 } })
stress("8 alta raridade (10–80 studs)", { { "Legendary", 10 }, { "Mythic", 20 }, { "Divine", 30 }, { "Secret", 40 }, { "Legendary", 50 }, { "Mythic", 60 }, { "Divine", 70 }, { "Secret", 80 } })
stress("10 no LOD (10–100 studs)", { { "Secret", 10 }, { "Divine", 20 }, { "Mythic", 30 }, { "Legendary", 40 }, { "Divine", 50 }, { "Secret", 60 }, { "Mythic", 70 }, { "Divine", 80 }, { "Legendary", 90 }, { "Secret", 100 } })

check(worst.occlusion <= 0.3, string.format("nenhuma aura (raridade × estilo × modo) cobre mais de 30%% do personagem (pior: %s = %.0f%%)", worst.key, worst.occlusion * 100))
for _, rarity in ORDER do
	local b = byRarity[rarity]
	local ratio = median(b.light) / math.max(median(b.full), 1e-6)
	check(ratio >= 0.4, string.format("%s: Light com pelo menos ~40%% da presença do Full (%.0f%%)", rarity, ratio * 100))
end
for i = 2, #ORDER do
	local a, b = median(byRarity[ORDER[i - 1]].light), median(byRarity[ORDER[i]].light)
	check(b > a, string.format("Light: %s (%.1f) aparece mais que %s (%.1f)", ORDER[i], b, ORDER[i - 1], a))
end

local failures = T.finish()
process.exit(if failures > 0 then 1 else 0)
