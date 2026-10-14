--!strict
--[[
	AuraController: o MOVIMENTO das auras de alta raridade (AuraBuilder) num ÚNICO loop central.
	    órbitas (Attachment + Trail girando), raios elétricos piscando/recurvando, fitas (wisps)
	    ondulando, pulsos periódicos (Emit).
	Orçamento (AuraConfig.Budget):
	    - só anima as MaxAnimated auras mais próximas da câmera e dentro de CullDistance
	      (o ranking é refeito 2x/s, não a cada frame);
	    - no máximo MaxFull auras "Full" com taxa cheia; as excedentes caem para a taxa Light;
	    - longe/fora do ranking: raios desligados, nada é animado (o LodController ainda desliga as
	      partículas das estações distantes);
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

type Entry = {
	model: Model,
	orbits: { Attachment },
	bolts: { Beam },
	wisps: { Beam },
	pulses: { { emitter: ParticleEmitter, every: number, count: number, nextAt: number } },
	emitters: { ParticleEmitter },
	rateScale: number,
	active: boolean,
}

local entries: { [Model]: Entry } = {}
local B = AuraConfig.Budget
local lowEnd = false
local clock = 0
local rankAt = 0
local boltAt = 0
local random = Random.new()

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

local function register(model: Instance)
	if not model:IsA("Model") or entries[model] then
		return
	end
	local entry: Entry = { model = model, orbits = {}, bolts = {}, wisps = {}, pulses = {}, emitters = {}, rateScale = 1, active = false }
	for _, obj in model:GetDescendants() do
		local role = obj:GetAttribute("AuraRole")
		if obj:IsA("Attachment") and role == "Orbit" then
			table.insert(entry.orbits, obj)
		elseif obj:IsA("Beam") and role == "Bolt" then
			table.insert(entry.bolts, obj)
		elseif obj:IsA("Beam") and role == "Wisp" then
			table.insert(entry.wisps, obj)
		elseif obj:IsA("ParticleEmitter") then
			if role == "Pulse" then
				table.insert(entry.pulses, {
					emitter = obj,
					every = (obj:GetAttribute("AuraPulseEvery") :: number?) or 3,
					count = (obj:GetAttribute("AuraPulseCount") :: number?) or 20,
					nextAt = clock + random:NextNumber(0, 2),
				})
			elseif obj:GetAttribute("BaseRate") ~= nil then
				table.insert(entry.emitters, obj)
			end
		end
	end
	entries[model] = entry
	if lowEnd then
		setRates(entry, B.LowEndRateScale)
	end
end

local function unregister(model: Instance)
	entries[model :: Model] = nil
end

-- Ranking (2x/s): quais auras animar e quais Full mantêm taxa cheia
local function rank()
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local origin = camera.CFrame.Position
	local list = {}
	for model, entry in entries do
		if model.Parent == nil then
			entries[model] = nil
		else
			local ok, pivot = pcall(model.GetPivot, model)
			local distance = if ok then (pivot.Position - origin).Magnitude else math.huge
			table.insert(list, { entry = entry, distance = distance })
		end
	end
	table.sort(list, function(a, b)
		return a.distance < b.distance
	end)
	local full = 0
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
		if entry.model:GetAttribute("AuraMode") == "Full" then
			full += 1
			if full > B.MaxFull then
				scale *= AuraConfig.LightScale.Rate
			end
		end
		setRates(entry, scale)
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
				local angle = clock * speed + index * (math.pi * 2 / count)
				a.Position = Vector3.new(math.cos(angle) * radius, height + math.sin(clock * 2 + index) * 0.4, math.sin(angle) * radius)
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
				beam.CurveSize0 = math.sin(clock * 1.7 + i) * 2.5
				beam.CurveSize1 = math.cos(clock * 1.3 + i) * 2.5
			end
			for _, pulse in entry.pulses do
				if clock >= pulse.nextAt then
					pulse.nextAt = clock + pulse.every
					pulse.emitter:Emit(math.max(1, math.floor(pulse.count * entry.rateScale)))
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
