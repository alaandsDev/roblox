--!strict
--[[
	AuraController (V2): o MOVIMENTO das auras de alta raridade (AuraBuilder) num ÚNICO loop central.
	    órbitas      raio/altura/velocidade/sentido próprios + oscilação vertical; Void/Gravity com
	                 órbita irregular (raio "respirando")
	    raios        arcos piscando e mudando de curva (Electric)
	    fitas        Ribbon/Gust ondulando (Gust mais rápido)
	    rajadas      Pulse / Shockwave / Flash / anel de energia / erupção do Secreto: cada uma com
	                 intervalo próprio ±25% (nada sincronizado entre auras nem entre camadas)
	    contorno     Highlight (Mítico+) só nas MaxHighlights auras mais próximas
	Orçamento (AuraConfig.Budget):
	    - só anima as MaxAnimated auras mais próximas e dentro de CullDistance (ranking 2x/s);
	    - além de MidDistance a taxa cai pela metade (mesma identidade);
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

local AuraController = {}

type Burst = { emitter: ParticleEmitter, every: number, count: number, nextAt: number }
type Entry = {
	model: Model,
	orbits: { Attachment },
	bolts: { Beam },
	wisps: { Beam },
	gusts: { Beam },
	bursts: { Burst },
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
	local entry: Entry = { model = model, orbits = {}, bolts = {}, wisps = {}, gusts = {}, bursts = {}, emitters = {}, outline = nil, rateScale = 1, active = false }
	for _, obj in model:GetDescendants() do
		local role = obj:GetAttribute("AuraRole")
		if obj:IsA("Attachment") and role == "Orbit" then
			table.insert(entry.orbits, obj)
		elseif obj:IsA("Beam") and role == "Bolt" then
			table.insert(entry.bolts, obj)
		elseif obj:IsA("Beam") and role == "Wisp" then
			table.insert(entry.wisps, obj)
		elseif obj:IsA("Beam") and role == "Gust" then
			table.insert(entry.gusts, obj)
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
		local active = i <= B.MaxAnimated and item.distance <= B.CullDistance
		if entry.active and not active then
			for _, beam in entry.bolts do
				beam.Enabled = false
			end
		end
		entry.active = active
		local scale = if lowEnd then B.LowEndRateScale else 1
		if item.distance > B.MidDistance then
			scale *= 0.5
		end
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
			for _, a in entry.orbits do
				local index = (a:GetAttribute("AuraIndex") :: number?) or 1
				local count = (a:GetAttribute("AuraCount") :: number?) or 1
				local radius = (a:GetAttribute("AuraRadius") :: number?) or 2
				local height = (a:GetAttribute("AuraHeight") :: number?) or 0
				local speed = (a:GetAttribute("AuraSpeed") :: number?) or 3
				local bob = (a:GetAttribute("AuraBob") :: number?) or 0.4
				local wobble = (a:GetAttribute("AuraWobble") :: number?) or 0
				local angle = clock * speed + index * (math.pi * 2 / count)
				local r = radius * (1 + wobble * 0.35 * math.sin(clock * 1.7 + index * 2.1))
				a.Position = Vector3.new(math.cos(angle) * r, height + math.sin(clock * (1.6 + index * 0.3) + index) * bob, math.sin(angle) * r)
			end
			if flicker then
				-- raios: arcos que mudam de forma e piscam (não um brilho parado)
				for _, beam in entry.bolts do
					beam.Enabled = random:NextNumber() < 0.75
					beam.CurveSize0 = random:NextNumber(-3, 3)
					beam.CurveSize1 = random:NextNumber(-3, 3)
				end
			end
			for i, beam in entry.wisps do
				beam.CurveSize0 = 3 + math.sin(clock * 1.3 + i) * 2.5
				beam.CurveSize1 = -3 + math.cos(clock * 1.1 + i * 1.7) * 2.5
			end
			for i, beam in entry.gusts do
				beam.CurveSize0 = math.sin(clock * 4 + i) * 4
				beam.CurveSize1 = math.cos(clock * 3.4 + i) * 4
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
