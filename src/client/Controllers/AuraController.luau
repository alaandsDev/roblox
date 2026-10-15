--!strict
--[[
	AuraController (V2): o MOVIMENTO das auras de alta raridade (AuraBuilder) num ÚNICO loop central.
	    órbitas      raio/altura/velocidade/sentido próprios + oscilação vertical; Void/Gravity com
	                 órbita irregular (raio "respirando")
	    formas       fitas/rajadas/raios: PONTAS, curvatura e largura animadas pelo AuraMotion com a
	                 personalidade do estilo (AuraConfig.Motion); raios ainda piscam
	    rajadas      Pulse / Shockwave / Flash / anel de energia / erupção do Secreto: cada uma com
	                 intervalo próprio ±25% (nada sincronizado entre auras nem entre camadas)
	    contorno     Highlight (Mítico+) só nas MaxHighlights auras mais próximas
	Orçamento (AuraConfig.Budget):
	    - só anima as MaxAnimated auras mais próximas e dentro de CullDistance (ranking 2x/s);
	    - a taxa cai aos poucos com a distância (Budget.DistanceRates: 100% → 55% até o Cull);
	    - o PERSONAGEM nunca é escondido aqui: só partículas/beams/contorno da aura mudam;
	    - no máximo MaxFull auras "Full" com taxa cheia; as excedentes caem para a taxa Light;
	    - mobile/touch sem teclado: taxas × LowEndRateScale.
	Nenhum loop por personagem; nenhuma conexão por frame além desta.
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.Shared
local AuraConfig = require(Shared.Config.AuraConfig)
local AuraBuilder = require(Shared.Modules.AuraBuilder)
local AuraMotion = require(Shared.Modules.AuraMotion)

local AuraController = {}

type Burst = { emitter: ParticleEmitter, every: number, count: number, nextAt: number }
-- forma grande animada (fita/rajada/raio): pontas, curvatura e largura vêm do AuraMotion
type Shape = { beam: Beam, a0: Attachment, a1: Attachment, ribbon: AuraMotion.Ribbon, w0: number, w1: number }
type Entry = {
	model: Model,
	orbits: { Attachment },
	bolts: { Beam },
	wisps: { Beam },
	gusts: { Beam },
	bursts: { Burst },
	shapes: { Shape },
	motion: AuraMotion.Profile,
	amp: number,
	distance: number,
	frame: number,
	emitters: { ParticleEmitter },
	outline: Highlight?,
	rateScale: number,
	active: boolean,
}

local entries: { [string]: Entry } = {} -- chave = id estável gravado no modelo (não a Instance)
local B = AuraConfig.Budget
local lowEnd = false
local clock = 0
local rankAt = 0
local boltAt = 0
local random = Random.new()
local nextId = 0

local function setRates(entry: Entry, scale: number)
	if entry.rateScale == scale then
		return
	end
	entry.rateScale = scale
	for _, e in entry.emitters do
		local base = e:GetAttribute("BaseRate")
		if type(base) == "number" then
			e.Rate = base * scale
		end
	end
end

local function keyOf(model: Instance, create: boolean): string?
	local id = model:GetAttribute("AuraEntryId")
	if type(id) == "string" then
		return id
	end
	if not create then
		return nil
	end
	nextId += 1
	local newId = "aura" .. nextId
	model:SetAttribute("AuraEntryId", newId)
	return newId
end

local function register(model: Instance)
	if not model:IsA("Model") then
		return
	end
	local key = keyOf(model, true) :: string
	if entries[key] then
		return
	end
	local style = model:GetAttribute("AuraStyle")
	local entry: Entry = {
		model = model,
		orbits = {},
		bolts = {},
		wisps = {},
		gusts = {},
		bursts = {},
		shapes = {},
		motion = (if type(style) == "string" then AuraConfig.Motion[style] else nil) or AuraConfig.DefaultMotion,
		amp = (model:GetAttribute("AuraAmp") :: number?) or 1,
		distance = 0,
		frame = 0,
		emitters = {},
		outline = nil,
		rateScale = 1,
		active = false,
	}
	for _, obj in model:GetDescendants() do
		local role = obj:GetAttribute("AuraRole")
		if obj:IsA("Attachment") and role == "Orbit" then
			table.insert(entry.orbits, obj)
		elseif obj:IsA("Beam") then
			if role == "Bolt" then
				table.insert(entry.bolts, obj)
			elseif role == "Wisp" then
				table.insert(entry.wisps, obj)
			elseif role == "Gust" then
				table.insert(entry.gusts, obj)
			end
			-- forma grande com parâmetros de movimento (fita/rajada/raio): pontas animadas
			if obj:GetAttribute("MotionIndex") ~= nil and obj.Attachment0 and obj.Attachment1 then
				table.insert(entry.shapes, {
					beam = obj,
					a0 = obj.Attachment0 :: Attachment,
					a1 = obj.Attachment1 :: Attachment,
					ribbon = {
						index = obj:GetAttribute("MotionIndex") :: number,
						angle = (obj:GetAttribute("MotionAngle") :: number?) or 0,
						twist = (obj:GetAttribute("MotionTwist") :: number?) or 1,
						radius = (obj:GetAttribute("MotionRadius") :: number?) or 2,
						y0 = (obj:GetAttribute("MotionY0") :: number?) or 0,
						y1 = (obj:GetAttribute("MotionY1") :: number?) or 3,
						curve = (obj:GetAttribute("MotionCurve") :: number?) or 2,
						amp = (obj:GetAttribute("MotionAmp") :: number?) or 1,
					},
					w0 = (obj:GetAttribute("MotionWidth0") :: number?) or obj.Width0,
					w1 = (obj:GetAttribute("MotionWidth1") :: number?) or obj.Width1,
				})
			end
		elseif obj:IsA("Highlight") and role == "Outline" then
			entry.outline = obj
		elseif obj:IsA("ParticleEmitter") then
			if role == "Burst" then
				local every = (obj:GetAttribute("AuraBurstEvery") :: number?) or 3
				table.insert(entry.bursts, {
					emitter = obj,
					every = every,
					count = (obj:GetAttribute("AuraBurstCount") :: number?) or 10,
					nextAt = clock + random:NextNumber(0, every), -- fases diferentes desde o início
				})
			elseif obj:GetAttribute("BaseRate") ~= nil then
				table.insert(entry.emitters, obj)
			end
		end
	end
	entries[key] = entry
	if lowEnd then
		setRates(entry, B.LowEndRateScale)
	end
end

local function unregister(model: Instance)
	local key = keyOf(model, false)
	if key then
		local entry = entries[key]
		if entry and entry.outline then
			entry.outline.Enabled = false
		end
		entries[key] = nil
	end
end

-- fator de taxa pela distância da câmera (progressivo; além do Cull a aura nem anima)
function AuraController.distanceRate(distance: number): number
	for _, step in B.DistanceRates do
		if distance <= step[1] then
			return step[2]
		end
	end
	return B.DistanceRates[#B.DistanceRates][2]
end

-- Ranking (2x/s): quais auras animar, quais Full mantêm taxa cheia e quais ganham contorno
local function rank()
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local origin = camera.CFrame.Position
	local list = {}
	for key, entry in entries do
		if entry.model.Parent == nil then
			entries[key] = nil
		else
			local ok, pivot = pcall(entry.model.GetPivot, entry.model)
			local distance = if ok then (pivot.Position - origin).Magnitude else math.huge
			table.insert(list, { entry = entry, distance = distance })
		end
	end
	table.sort(list, function(a, b)
		return a.distance < b.distance
	end)
	local full, outlines = 0, 0
	for i, item in list do
		local entry = item.entry
		entry.distance = item.distance
		local active = i <= B.MaxAnimated and item.distance <= B.CullDistance
		if entry.active and not active then
			for _, beam in entry.bolts do
				beam.Enabled = false
			end
		end
		entry.active = active
		local scale = if lowEnd then B.LowEndRateScale else 1
		scale *= AuraController.distanceRate(item.distance)
		if entry.model:GetAttribute("AuraMode") == "Full" then
			full += 1
			if full > B.MaxFull then
				scale *= AuraConfig.LightScale.Rate
			end
		end
		setRates(entry, scale)
		if entry.outline then
			local on = active and outlines < B.MaxHighlights
			if on then
				outlines += 1
			end
			entry.outline.Enabled = on
		end
	end
end

local function animate(dt: number)
	clock += dt
	if clock >= rankAt then
		rankAt = clock + 0.5
		rank()
	end
	local flicker = clock >= boltAt
	if flicker then
		boltAt = clock + random:NextNumber(0.06, 0.14)
	end
	for _, entry in entries do
		if entry.active then
			-- longe ou no mobile: formas e órbitas a meia frequência (o movimento continua contínuo,
			-- é absoluto no tempo; só atualiza menos vezes)
			entry.frame += 1
			local reduced = (lowEnd or entry.distance > B.MidDistance) and entry.frame % 2 == 1
			local motion, amp = entry.motion, entry.amp
			for _, a in entry.orbits do
				if reduced then
					break
				end
				local index = (a:GetAttribute("AuraIndex") :: number?) or 1
				local count = (a:GetAttribute("AuraCount") :: number?) or 1
				local radius = (a:GetAttribute("AuraRadius") :: number?) or 2
				local height = (a:GetAttribute("AuraHeight") :: number?) or 0
				local speed = (a:GetAttribute("AuraSpeed") :: number?) or 3
				local bob = (a:GetAttribute("AuraBob") :: number?) or 0.4
				local wobble = (a:GetAttribute("AuraWobble") :: number?) or 0
				-- personalidade do estilo (saltos elétricos, respiração, chama subindo)
				local dAngle, rScale, dy = AuraMotion.orbitOffset(motion, index, clock, amp)
				local angle = (clock * speed) % (math.pi * 2) + index * (math.pi * 2 / count) + dAngle
				local r = radius * rScale * (1 + wobble * 0.35 * math.sin(clock * 1.7 + index * 2.1))
				a.Position = Vector3.new(math.cos(angle) * r, height + dy + math.sin(clock * (1.6 + index * 0.3) + index) * bob, math.sin(angle) * r)
			end
			if flicker then
				-- raios piscam (o formato vem do AuraMotion, com saltos bruscos do Electric)
				for _, beam in entry.bolts do
					beam.Enabled = random:NextNumber() < 0.75
				end
			end
			-- FORMAS GRANDES (fitas, rajadas, raios): pontas, curvatura e largura vivas — antes só a
			-- curvatura mudava e as pontas ficavam presas (a "fita parada nas costas")
			if not reduced then
				for _, shape in entry.shapes do
					local pose = AuraMotion.ribbon(motion, shape.ribbon, clock)
					shape.a0.Position = Vector3.new(pose.ax, pose.ay, pose.az)
					shape.a1.Position = Vector3.new(pose.bx, pose.by, pose.bz)
					shape.beam.CurveSize0 = pose.curve0
					shape.beam.CurveSize1 = pose.curve1
					shape.beam.Width0 = shape.w0 * pose.width
					shape.beam.Width1 = shape.w1 * pose.width
				end
			end
			for _, burst in entry.bursts do
				if clock >= burst.nextAt then
					burst.nextAt = clock + burst.every * random:NextNumber(0.75, 1.25)
					burst.emitter:Emit(math.max(1, math.floor(burst.count * entry.rateScale + 0.5)))
				end
			end
		end
	end
end

function AuraController.Count(): (number, number)
	local total, active = 0, 0
	for _, entry in entries do
		total += 1
		if entry.active then
			active += 1
		end
	end
	return total, active
end

-- custo do loop central: quantas formas e órbitas são atualizadas por quadro (auras ativas)
function AuraController.Stats(): { shapes: number, orbits: number, bursts: number }
	local out = { shapes = 0, orbits = 0, bursts = 0 }
	for _, entry in entries do
		if entry.active then
			out.shapes += #entry.shapes
			out.orbits += #entry.orbits
			out.bursts += #entry.bursts
		end
	end
	return out
end

-- quantos contornos (Highlight) estão ligados agora (orçamento MaxHighlights)
function AuraController.Outlines(): number
	local n = 0
	for _, entry in entries do
		if entry.outline and entry.outline.Enabled then
			n += 1
		end
	end
	return n
end

-- (testes/DEV) roda um passo do loop
AuraController._step = animate

function AuraController.Start()
	lowEnd = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	CollectionService:GetInstanceAddedSignal(AuraBuilder.Tag):Connect(register)
	CollectionService:GetInstanceRemovedSignal(AuraBuilder.Tag):Connect(unregister)
	for _, model in CollectionService:GetTagged(AuraBuilder.Tag) do
		register(model)
	end
	local accumulator = 0
	RunService.Heartbeat:Connect(function(dt)
		accumulator += dt
		local step = 1 / B.UpdateRate
		if accumulator < step then
			return
		end
		if next(entries) == nil then
			accumulator = 0
			return
		end
		animate(accumulator)
		accumulator = 0
	end)
end

return AuraController
