--!strict
--[[
	PlayerAuraController: desenha as PLAYER AURAS de TODOS os avatares (inclusive o próprio),
	localmente em cada cliente, a partir dos atributos replicados pelo servidor
	(Player.PlayerAuraVisual). Nada de partícula replicada pelo servidor; nenhum script no efeito.

	Arquitetura central: UMA conexão (Heartbeat, ~30 Hz) anima todas as auras; uma varredura a cada
	0,5 s descobre quem tem aura / trocou de tier / renasceu (respawn: o efeito velho morre com o
	personagem e o novo é montado do zero — PlayerAuraBuilder.clear garante zero duplicata).
	LOD: a aura do DONO é sempre cheia; a dos outros fica cheia até FullDistance, reduzida até
	CullDistance e desligada além. Mobile: emissão × MobileRate.
	DEV: modelos com a tag "PlayerAuraHost" e atributo PlayerAuraVisual (vitrine/lineup/stress).
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage.Shared
local PlayerAuraConfig = require(Shared.Config.PlayerAuraConfig)
local PlayerAuraBuilder = require(Shared.Modules.PlayerAuraBuilder)

local PlayerAuraController = {}

PlayerAuraController.HostTag = "PlayerAuraHost"

type Entry = {
	key: string,
	root: BasePart,
	tier: number,
	own: boolean,
	fx: PlayerAuraBuilder.Built,
	lod: string,
	factor: number,
	nextPulse: number,
}

local entries: { [string]: Entry } = {}
local mobile = false
local clock = os.clock
local scanAccumulator = 0
local lastStep = 0
local lastWrites = 0 -- escritas de propriedade no último passo (todas as auras)

local function hostRoot(model: Instance?): BasePart?
	local root = model and model:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function desiredHosts(): { [string]: { root: BasePart, tier: number, own: boolean } }
	local out = {}
	local localPlayer = Players.LocalPlayer
	for _, player in Players:GetPlayers() do
		local tier = player:GetAttribute("PlayerAuraVisual")
		local root = hostRoot((player :: any).Character)
		if type(tier) == "number" and tier >= 1 and PlayerAuraConfig.List[tier] and root then
			out["P" .. tostring(player.UserId)] = { root = root, tier = tier, own = player == localPlayer }
		end
	end
	for _, model in CollectionService:GetTagged(PlayerAuraController.HostTag) do
		local tier = model:GetAttribute("PlayerAuraVisual")
		local root = hostRoot(model)
		if type(tier) == "number" and tier >= 1 and PlayerAuraConfig.List[tier] and root then
			out["H" .. model:GetFullName()] = { root = root, tier = tier, own = model:GetAttribute("PlayerAuraOwn") == true }
		end
	end
	return out
end

local function setFactor(entry: Entry, factor: number)
	if entry.factor == factor then
		return
	end
	entry.factor = factor
	local on = factor > 0
	for _, e in entry.fx.emitters do
		e.emitter.Rate = e.rate * factor
		e.emitter.Enabled = on
	end
	for _, b in entry.fx.beams do
		b.beam.Enabled = on
	end
	for _, trail in entry.fx.trails do
		trail.Enabled = on
	end
	if entry.fx.light then
		(entry.fx.light :: PointLight).Enabled = on
	end
	if entry.fx.pulse then
		(entry.fx.pulse :: ParticleEmitter).Enabled = on
	end
end

-- Varredura: monta/remonta/remove (barata, 2×/s)
function PlayerAuraController._scan()
	local desired = desiredHosts()
	for key, entry in entries do
		local want = desired[key]
		if not want or want.root ~= entry.root or want.tier ~= entry.tier or entry.root.Parent == nil then
			if entry.root.Parent ~= nil then
				PlayerAuraBuilder.clear(entry.root)
			end
			entries[key] = nil
		end
	end
	for key, want in desired do
		if not entries[key] then
			local ok, fx = pcall(PlayerAuraBuilder.build, want.root, PlayerAuraConfig.List[want.tier])
			if ok then
				entries[key] = { key = key, root = want.root, tier = want.tier, own = want.own, fx = fx, lod = "", factor = -1, nextPulse = 0 }
			end
		end
	end
end

local function cameraPosition(): Vector3?
	local camera = workspace.CurrentCamera
	return if camera then camera.CFrame.Position else nil
end

-- Distância (studs) -> fator de emissão. Dono: sempre cheia.
function PlayerAuraController.lodFor(own: boolean, distance: number): (string, number)
	local base = if mobile then PlayerAuraConfig.MobileRate else 1
	if own then
		return "Full", base
	end
	if distance <= PlayerAuraConfig.FullDistance then
		return "Full", base
	elseif distance <= PlayerAuraConfig.CullDistance then
		return "Reduced", base * PlayerAuraConfig.ReducedRate
	end
	return "Off", 0
end

-- Um passo do loop central (exposto para testes)
function PlayerAuraController._step(dt: number)
	scanAccumulator += dt
	if scanAccumulator >= 0.5 then
		scanAccumulator = 0
		PlayerAuraController._scan()
	end
	local t = clock()
	local cam = cameraPosition()
	local writes = 0
	for _, entry in entries do
		local distance = if cam then (entry.root.CFrame.Position - cam).Magnitude else 0
		local lod, factor = PlayerAuraController.lodFor(entry.own, distance)
		entry.lod = lod
		setFactor(entry, factor)
		if lod == "Off" then
			continue
		end
		local fx = entry.fx
		-- longe (Reduced): metade da frequência para fluxos/auréola
		local heavy = lod == "Full" or math.floor(t * 30) % 2 == 0
		-- órbitas: 2–3 elementos importantes, inclinados (não um disco plano)
		local n = #fx.orbit
		for i, a in fx.orbit do
			local ang = t * 1.7 + (i / n) * math.pi * 2
			local r = fx.orbitRadius * (1 + 0.1 * math.sin(t * 2.3 + i))
			a.Position = Vector3.new(math.cos(ang) * r, 0.6 + 1.1 * math.sin(ang + i), math.sin(ang) * r)
			writes += 1
		end
		if heavy then
			-- fluxos: pontas + curvas animadas (visível em 1–2 s), cada um com fase própria
			for _, flow in fx.flows do
				local cf0, cf1, c0, c1 = PlayerAuraBuilder.flowPose(flow, t)
				flow.a0.CFrame = cf0
				flow.a1.CFrame = cf1
				flow.beam.CurveSize0 = c0
				flow.beam.CurveSize1 = c1
				writes += 4
			end
			-- auréola/coroa girando devagar
			local halo = fx.halo
			if halo then
				PlayerAuraBuilder.placeCircle(halo.points, halo.radius, halo.y, t * 0.7, fx.crownTips, 0.9)
				writes += #halo.points + #fx.crownTips
			end
			-- coluna respirando
			if fx.column then
				(fx.column :: Beam).Width0 = fx.columnWidth * (1 + 0.22 * math.sin(t * 2.2))
				writes += 1
			end
		end
		-- onda periódica no chão
		if fx.pulse and fx.pulseEvery > 0 and t >= entry.nextPulse then
			entry.nextPulse = t + fx.pulseEvery
			pcall(function()
				(fx.pulse :: ParticleEmitter):Emit(1)
			end)
		end
	end
	lastWrites = writes
	lastStep = t
end

-- (testes/DEV/stress) números do que está vivo
function PlayerAuraController.Stats(): { [string]: number }
	local s = { auras = 0, emitters = 0, rate = 0, alive = 0, beams = 0, trails = 0, attachments = 0, lights = 0, highlights = 0, connections = 1, full = 0, reduced = 0, off = 0, writes = lastWrites }
	for _, entry in entries do
		s.auras += 1
		s.attachments += entry.fx.attachments
		for _, e in entry.fx.emitters do
			s.emitters += 1
			if e.emitter.Enabled then
				s.rate += e.emitter.Rate
				-- partículas vivas ~ emissão × vida média
				s.alive += e.emitter.Rate * e.life
			end
		end
		for _, b in entry.fx.beams do
			if b.beam.Enabled then
				s.beams += 1
			end
		end
		for _, tr in entry.fx.trails do
			if tr.Enabled then
				s.trails += 1
			end
		end
		if entry.fx.light and (entry.fx.light :: PointLight).Enabled then
			s.lights += 1
		end
		if entry.lod == "Full" then
			s.full += 1
		elseif entry.lod == "Reduced" then
			s.reduced += 1
		elseif entry.lod == "Off" then
			s.off += 1
		end
	end
	return s
end

function PlayerAuraController.EntryFor(key: string): Entry?
	return entries[key]
end

function PlayerAuraController._setClock(fn: () -> number)
	clock = fn
end

function PlayerAuraController._setMobile(on: boolean)
	mobile = on
	for _, entry in entries do
		entry.factor = -1
	end
end

function PlayerAuraController.Start()
	mobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	local accumulator = 0
	RunService.Heartbeat:Connect(function(dt)
		accumulator += dt
		if accumulator < 1 / 30 then
			return
		end
		PlayerAuraController._step(accumulator)
		accumulator = 0
	end)
	PlayerAuraController._scan()
	local _ = lastStep
end

return PlayerAuraController
