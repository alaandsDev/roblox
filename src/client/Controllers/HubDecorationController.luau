--!strict
--[[
	HubDecorationController: microanimações dos LANDMARKS do Hub, só no cliente, num ÚNICO loop.
	Nenhum Script nas estruturas: o MapBuilder/Landmarks marca as peças com a tag "HubDeco" e
	atributos (DecoMode, DecoSpeed, DecoAmp, DecoPhase, DecoAxis, DecoWave, DecoHz); efeitos
	(ParticleEmitter/Beam) levam a tag "HubDecoFx".

	    Spin    gira no eixo (Y padrão; X/Z) — Amp opcional = flutuar junto
	    Bob     sobe/desce
	    Pulse   transparência respirando (a partir da transparência original)
	    Slide   vai-e-volta (seno) ou esteira (Wave = "Saw") no eixo local
	    Tumble  gira em dois eixos (dados) — Amp opcional = flutuar

	LOD (distância da câmera ao landmark; geometria NUNCA some):
	    até FullDistance (50)     animação na frequência pedida (DecoHz) e efeitos cheios
	    até ReducedDistance (100) animação a 1/3 da frequência, efeitos a 50%
	    além                      animação parada, efeitos desligados
	Mobile: frequência e emissão pela metade.
]]

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local HubDecorationController = {}

HubDecorationController.Tag = "HubDeco"
HubDecorationController.FxTag = "HubDecoFx"
HubDecorationController.FullDistance = 50
HubDecorationController.ReducedDistance = 100

type Item = {
	inst: Instance,
	isModel: boolean,
	parts: { BasePart },
	base: CFrame,
	baseTransparency: { number },
	mode: string,
	speed: number,
	amp: number,
	phase: number,
	axis: string,
	saw: boolean,
	hz: number,
	nextAt: number,
	lod: string,
}
type Fx = { inst: Instance, rate: number, position: Vector3, lod: string }

local items: { Item } = {}
local effects: { Fx } = {}
local clock = os.clock
local mobile = false
local lastWrites = 0
local lodTimer = 0

local function pivotOf(inst: Instance): CFrame
	if inst:IsA("Model") then
		return inst:GetPivot()
	end
	return (inst :: BasePart).CFrame
end

local function register(inst: Instance)
	local mode = inst:GetAttribute("DecoMode")
	if type(mode) ~= "string" then
		return
	end
	local parts: { BasePart } = {}
	if inst:IsA("BasePart") then
		table.insert(parts, inst)
	else
		for _, d in inst:GetDescendants() do
			if d:IsA("BasePart") then
				table.insert(parts, d)
			end
		end
	end
	local transparency = {}
	for i, p in parts do
		transparency[i] = p.Transparency
	end
	table.insert(items, {
		inst = inst,
		isModel = inst:IsA("Model"),
		parts = parts,
		base = pivotOf(inst),
		baseTransparency = transparency,
		mode = mode,
		speed = tonumber(inst:GetAttribute("DecoSpeed")) or 1,
		amp = tonumber(inst:GetAttribute("DecoAmp")) or 0,
		phase = tonumber(inst:GetAttribute("DecoPhase")) or 0,
		axis = tostring(inst:GetAttribute("DecoAxis") or "Y"),
		saw = inst:GetAttribute("DecoWave") == "Saw",
		hz = tonumber(inst:GetAttribute("DecoHz")) or 15,
		nextAt = 0,
		lod = "Full",
	})
end

local function registerFx(inst: Instance)
	local parent = inst.Parent
	local position = if parent and parent:IsA("BasePart") then parent.CFrame.Position else Vector3.zero
	local rate = tonumber(inst:GetAttribute("BaseRate")) or (if inst:IsA("ParticleEmitter") then inst.Rate else 0)
	table.insert(effects, { inst = inst, rate = rate, position = position, lod = "" })
end

local function axisAngles(axis: string, angle: number): CFrame
	if axis == "X" then
		return CFrame.Angles(angle, 0, 0)
	elseif axis == "Z" then
		return CFrame.Angles(0, 0, angle)
	end
	return CFrame.Angles(0, angle, 0)
end

local function axisVector(axis: string): Vector3
	if axis == "X" then
		return Vector3.xAxis
	elseif axis == "Z" then
		return Vector3.zAxis
	end
	return Vector3.yAxis
end

-- Transformação do item no instante t (relativa à pose original). Puro (exposto para testes).
function HubDecorationController.pose(item: any, t: number): CFrame?
	local mode = item.mode
	local s = t * item.speed + item.phase
	if mode == "Spin" then
		local bob = if item.amp > 0 then math.sin(t * 1.6 + item.phase) * item.amp else 0
		return CFrame.new(0, bob, 0) * axisAngles(item.axis, math.rad(item.speed) * t)
	elseif mode == "Tumble" then
		local bob = if item.amp > 0 then math.sin(t * 1.3 + item.phase) * item.amp else 0
		local a = math.rad(item.speed) * t
		return CFrame.new(0, bob, 0) * CFrame.Angles(a * 0.7, a, a * 0.4)
	elseif mode == "Bob" then
		return CFrame.new(0, math.sin(s) * item.amp, 0)
	elseif mode == "Slide" then
		local k = if item.saw then (s % 1) else math.sin(s)
		return CFrame.new(axisVector(item.axis) * k * item.amp)
	end
	return nil
end

local function apply(item: Item, t: number): number
	if item.mode == "Pulse" then
		local k = 0.5 + 0.5 * math.sin(t * item.speed + item.phase)
		for i, p in item.parts do
			p.Transparency = math.clamp(item.baseTransparency[i] + item.amp * k, 0, 1)
		end
		return #item.parts
	end
	local pose = HubDecorationController.pose(item, t)
	if not pose then
		return 0
	end
	-- girar/mover em torno do próprio pivô (sem acumular erro: sempre a partir da pose original)
	local target = item.base * pose
	if item.isModel then
		(item.inst :: Model):PivotTo(target)
		return #item.parts
	end
	(item.inst :: BasePart).CFrame = target
	return 1
end

local function lodOf(distance: number): string
	if distance <= HubDecorationController.FullDistance then
		return "Full"
	elseif distance <= HubDecorationController.ReducedDistance then
		return "Reduced"
	end
	return "Off"
end

local function refreshLod()
	local camera = workspace.CurrentCamera
	local cam = if camera then camera.CFrame.Position else Vector3.zero
	for _, item in items do
		item.lod = lodOf((item.base.Position - cam).Magnitude)
	end
	for _, f in effects do
		local lod = lodOf((f.position - cam).Magnitude)
		if lod ~= f.lod then
			f.lod = lod
			local factor = (if lod == "Full" then 1 elseif lod == "Reduced" then 0.5 else 0) * (if mobile then 0.5 else 1)
			if f.inst:IsA("ParticleEmitter") then
				local e = f.inst :: ParticleEmitter
				e.Rate = f.rate * factor
				e.Enabled = factor > 0
			elseif f.inst:IsA("Beam") then
				(f.inst :: Beam).Enabled = lod ~= "Off"
			end
		end
	end
end

-- Um passo do loop central (exposto para testes)
function HubDecorationController._step(dt: number)
	lodTimer -= dt
	if lodTimer <= 0 then
		lodTimer = 0.5
		refreshLod()
	end
	local t = clock()
	local writes = 0
	for _, item in items do
		if item.lod ~= "Off" then
			local hz = item.hz * (if item.lod == "Reduced" then 1 / 3 else 1) * (if mobile then 0.5 else 1)
			if t >= item.nextAt then
				item.nextAt = t + 1 / math.max(1, hz)
				if item.inst.Parent ~= nil then
					writes += apply(item, t)
				end
			end
		end
	end
	lastWrites = writes
end

function HubDecorationController.Stats(): { [string]: number }
	local s = { items = #items, effects = #effects, full = 0, reduced = 0, off = 0, writes = lastWrites, rate = 0, beams = 0, connections = 1 }
	for _, item in items do
		if item.lod == "Full" then
			s.full += 1
		elseif item.lod == "Reduced" then
			s.reduced += 1
		else
			s.off += 1
		end
	end
	for _, f in effects do
		if f.inst:IsA("ParticleEmitter") and (f.inst :: ParticleEmitter).Enabled then
			s.rate += (f.inst :: ParticleEmitter).Rate
		elseif f.inst:IsA("Beam") and (f.inst :: Beam).Enabled then
			s.beams += 1
		end
	end
	return s
end

function HubDecorationController._setClock(fn: () -> number)
	clock = fn
end

function HubDecorationController._setMobile(on: boolean)
	mobile = on
	for _, f in effects do
		f.lod = ""
	end
	lodTimer = 0
end

function HubDecorationController._rescan()
	table.clear(items)
	table.clear(effects)
	for _, inst in CollectionService:GetTagged(HubDecorationController.Tag) do
		register(inst)
	end
	for _, inst in CollectionService:GetTagged(HubDecorationController.FxTag) do
		registerFx(inst)
	end
	lodTimer = 0
end

function HubDecorationController.Start()
	mobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	-- o mapa chega do servidor: espera os landmarks e registra (e quem aparecer depois)
	workspace:WaitForChild("Map", 30)
	HubDecorationController._rescan()
	CollectionService:GetInstanceAddedSignal(HubDecorationController.Tag):Connect(register)
	CollectionService:GetInstanceAddedSignal(HubDecorationController.FxTag):Connect(registerFx)
	local accumulator = 0
	RunService.Heartbeat:Connect(function(dt)
		accumulator += dt
		if accumulator < 1 / 30 then
			return
		end
		HubDecorationController._step(accumulator)
		accumulator = 0
	end)
end

return HubDecorationController
