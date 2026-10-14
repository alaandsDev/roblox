--!strict
--[[
	JackpotReveal: o "CARALHO, VEIO UM DIVINO" — cinemática própria de DIVINO e SECRETO.

	Por que não o HeroLanding (ViewportFrame): ViewportFrame não renderiza ParticleEmitter, Beam,
	Trail nem Highlight. A Aura Full (AuraBuilder) nunca aparecia e a câmera fixa não se adaptava
	ao tamanho do personagem. Aqui o palco é NO MUNDO, só no cliente (nada replica), bem acima do
	mapa (RevealConfig.JackpotStage), com a câmera REAL em modo Scriptable:

	    DIVINO  feixes de luz -> surge alto -> queda rápida com a câmera acompanhando de baixo ->
	            HERO LANDING (tremida, onda de choque, anel no chão, faíscas, poeira, flash curto)
	            -> Aura Divine Full inteira no impacto -> DIVINO + nome -> pose -> volta ao jogo
	    SECRETO silêncio + tela escurece/falha + fenda no céu -> surge MUITO alto, carrega energia
	            -> queda que começa lenta e ACELERA, câmera mergulhando junto -> CORTE para o chão
	            -> câmera lenta nos últimos instantes -> impacto forte (onda dupla, estilhaços
	            radiais, rajada da assinatura do estilo) -> Aura Secret Full entra em CAMADAS
	            (corpo -> fora -> coroa) -> SECRETO + nome -> pose -> volta ao jogo

	Só APRESENTAÇÃO: o resultado já veio do servidor (nenhum RNG aqui). Reaproveita
	CharacterModelFactory (modelo, poses Crouch/Confident, lerpPose), AuraBuilder (Aura Full) e o
	AuraController (animação central das auras). Limpeza robusta: Stop() (pular, morrer, erro,
	fechar) restaura câmera, controles e HUD e destrói tudo (handle.done).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.Shared
local RevealConfig = require(Shared.Config.RevealConfig)
local RarityConfig = require(Shared.Config.RarityConfig)
local CharacterConfig = require(Shared.Config.CharacterConfig)
local VariantConfig = require(Shared.Config.VariantConfig)
local CharacterModelFactory = require(Shared.Modules.CharacterModelFactory)
local CharacterAssetConfig = require(Shared.Config.CharacterAssetConfig)
local AuraBuilder = require(Shared.Modules.AuraBuilder)
local NumberFormatter = require(Shared.Modules.NumberFormatter)
local Localization = require(Shared.Localization.Localization)
local Signal = require(Shared.Modules.Signal)

local UI = script.Parent.Parent.UI
local UIKit = require(UI.UIKit)
local Theme = require(UI.UITheme)
local CameraShake = require(script.Parent.CameraShake)

local JackpotReveal = {}

-- ordem em que a Aura Secret Full entra (zonas do AuraBuilder: corpo -> fora -> coroa)
local LAYER_ORDER = { "AuraCore", "AuraChest", "AuraRing", "AuraGround", "AuraOuter", "AuraHalo", "AuraCrown" }

local function rgb(list: { number }): Color3
	return Color3.fromRGB(list[1], list[2], list[3])
end
local function clamp01(t: number): number
	return math.clamp(t, 0, 1)
end
local function phase(t: number, a: number, b: number): number
	return clamp01((t - a) / math.max(b - a, 1e-3))
end
local function easeOut(t: number): number
	return 1 - (1 - t) ^ 3
end
local function smooth(t: number): number
	return t * t * (3 - 2 * t)
end

local function newPart(parent: Instance, name: string): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function emit(emitter: ParticleEmitter, count: number)
	pcall(function()
		emitter:Emit(math.max(1, math.floor(count)))
	end)
end

export type Options = {
	characterId: string,
	rarity: string,
	variant: string?,
	cinematic: string,
	quality: string,
	shake: number,
	isNew: boolean,
	odds: number,
	luck: number?,
	canSkip: boolean,
	autoClose: number,
	mobile: boolean?,
}

export type Handle = { done: boolean, Finished: any, Stop: (self: Handle) -> (), Skip: (self: Handle) -> () }

-- Enquadramento: distância para caber o personagem INTEIRO + parte do efeito no chão
function JackpotReveal.frameDistance(height: number, fov: number): number
	local visible = height * 1.35 + 4 -- corpo + folga da aura/anel no chão
	return math.max(11, visible / 2 / math.tan(math.rad(fov) / 2))
end

function JackpotReveal.play(opts: Options): Handle
	local preset = RevealConfig.Cinematics[opts.cinematic]
	local stageCfg = RevealConfig.JackpotStage
	local quality = RevealConfig.Quality[opts.quality] or RevealConfig.Quality.High
	local character = CharacterConfig.ById[opts.characterId]
	local rarityColor = rgb(RarityConfig.ById[opts.rarity].Color)
	local accent = if preset.Lighting then rgb(preset.Lighting) else rarityColor
	local secret = preset.Camera == "DiveCut"

	local handle = { done = false, Finished = Signal.new() } :: any
	local connections: { RBXScriptConnection } = {}
	local shake = CameraShake.new(opts.shake > 0)
	local shakeScale = opts.shake * (if opts.mobile then stageCfg.MobileShakeScale else 1)

	------------------------------------------------------------------ palco (mundo, local)
	local origin = CFrame.new(stageCfg.Position[1], stageCfg.Position[2], stageCfg.Position[3])
	local stage = Instance.new("Folder")
	stage.Name = "JackpotStage"
	stage:SetAttribute("Cinematic", opts.cinematic)
	stage.Parent = Workspace

	local R = stageCfg.GroundRadius
	local ground = newPart(stage, "Ground")
	ground.Shape = Enum.PartType.Cylinder
	ground.Size = Vector3.new(1.2, R * 2, R * 2)
	ground.CFrame = origin * CFrame.new(0, -0.6, 0) * CFrame.Angles(0, 0, math.rad(90))
	ground.Color = if secret then Color3.fromRGB(28, 22, 40) else Color3.fromRGB(235, 228, 210)
	ground.Material = Enum.Material.Slate
	local rim = newPart(stage, "Rim")
	rim.Shape = Enum.PartType.Cylinder
	rim.Size = Vector3.new(1.3, R * 2 + 2, R * 2 + 2)
	rim.CFrame = origin * CFrame.new(0, -0.7, 0) * CFrame.Angles(0, 0, math.rad(90))
	rim.Color = accent
	rim.Material = Enum.Material.Neon
	-- círculo central (onde o herói pousa): lê o "alvo" antes da queda
	local mark = newPart(stage, "LandingMark")
	mark.Shape = Enum.PartType.Cylinder
	mark.Size = Vector3.new(0.08, 8, 8)
	mark.CFrame = origin * CFrame.new(0, 0.02, 0) * CFrame.Angles(0, 0, math.rad(90))
	mark.Color = accent
	mark.Material = Enum.Material.Neon
	mark.Transparency = 0.6

	-- céu do Divino: colunas de luz; do Secreto: fenda roxa
	local beams: { Part } = {}
	if preset.SkyEffect == "Heaven" then
		for i = 1, 6 do
			local beam = newPart(stage, "HeavenBeam")
			beam.Material = Enum.Material.Neon
			beam.Color = accent
			beam.Transparency = 1
			local angle = i / 6 * math.pi * 2
			beam.Size = Vector3.new(1.6, 160, 1.6)
			beam.CFrame = origin * CFrame.new(math.cos(angle) * 16, 78, math.sin(angle) * 16 - 4)
			table.insert(beams, beam)
		end
	end

	------------------------------------------------------------------ personagem
	local model = CharacterModelFactory.build(opts.characterId, { variant = opts.variant, aura = false, vfx = CharacterAssetConfig.VFXModes.HeroLanding })
	model.Parent = stage
	local height = CharacterModelFactory.height(opts.characterId)
	local drop = math.max(preset.MinDrop, preset.DropHeight * height)
	local facing = CFrame.Angles(0, math.pi, 0) -- de frente para a câmera (+Z)
	local feetAt = function(y: number): CFrame
		return origin * CFrame.new(0, y, 0) * facing
	end
	model:PivotTo(feetAt(drop + 40)) -- fora de quadro até surgir

	-- silhueta (Divino: luz; Secreto: sombra) até o impacto
	local originals: { any } = {}
	local hidden: { any } = {}
	local silhouette = if secret then Color3.fromRGB(12, 8, 20) else Color3.fromRGB(255, 250, 225)
	for _, obj in model:GetDescendants() do
		if obj:IsA("BasePart") and obj.Transparency < 1 then
			table.insert(originals, { obj :: any, obj.Color, obj.Material })
			obj.Color = silhouette
			obj.Material = if secret then Enum.Material.SmoothPlastic else Enum.Material.Neon
		elseif obj:IsA("SpecialMesh") and obj.TextureId ~= "" then
			table.insert(hidden, { obj :: any, "TextureId", obj.TextureId })
			obj.TextureId = ""
		elseif obj:IsA("Decal") then
			table.insert(hidden, { obj :: any, "Transparency", obj.Transparency })
			obj.Transparency = 1
		end
	end
	-- MeshPart também é BasePart: a textura sai num 2º passe
	for _, obj in model:GetDescendants() do
		if obj:IsA("MeshPart") and obj.TextureID ~= "" then
			table.insert(hidden, { obj :: any, "TextureID", obj.TextureID })
			obj.TextureID = ""
		end
	end
	local clothing: { Instance } = {}
	for _, obj in model:GetDescendants() do
		if obj:IsA("Clothing") or obj:IsA("ShirtGraphic") then
			table.insert(clothing, obj)
		end
	end
	for _, obj in clothing do
		obj.Parent = nil
	end
	local revealed = false
	local function revealColors()
		if revealed then
			return
		end
		revealed = true
		for _, saved in originals do
			saved[1].Color = saved[2]
			saved[1].Material = saved[3]
		end
		for _, saved in hidden do
			saved[1][saved[2]] = saved[3]
		end
		for _, obj in clothing do
			obj.Parent = model
		end
		table.clear(clothing)
	end

	-- energia que acompanha o corpo na queda (mundo: partículas e rastro FUNCIONAM aqui)
	local carrier = newPart(stage, "FallFx")
	carrier.Size = Vector3.new(0.2, 0.2, 0.2)
	carrier.Transparency = 1
	local glow = newPart(stage, "FallGlow")
	glow.Shape = Enum.PartType.Ball
	glow.Material = Enum.Material.Neon
	glow.Color = accent
	glow.Transparency = 1
	glow.Size = Vector3.new(1, 1, 1) * math.max(5, height * 1.1)
	local streak = Instance.new("ParticleEmitter")
	streak.Name = "FallStreak"
	streak.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	streak.Color = ColorSequence.new(accent, Color3.new(1, 1, 1))
	streak.LightEmission = if secret then 0.3 else 0.7
	streak.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 0) })
	streak.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
	streak.Lifetime = NumberRange.new(0.35, 0.6)
	streak.Speed = NumberRange.new(2, 6)
	streak.SpreadAngle = Vector2.new(25, 25)
	streak.EmissionDirection = Enum.NormalId.Top
	streak.Rate = 0
	streak.Parent = carrier
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(-height * 0.3, 0, 0)
	a0.Parent = carrier
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(height * 0.3, 0, 0)
	a1.Parent = carrier
	local trail = Instance.new("Trail")
	trail.Name = "FallTrail"
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Color = ColorSequence.new(accent, Color3.new(1, 1, 1))
	trail.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	trail.Lifetime = 0.35
	trail.LightEmission = 0.6
	trail.Enabled = quality.Trails
	trail.Parent = carrier

	-- fenda do Secreto (no céu, acima do ponto de queda)
	local rift: Part? = nil
	if preset.SkyEffect == "Rift" then
		local r = newPart(stage, "Rift")
		r.Shape = Enum.PartType.Ball
		r.Material = Enum.Material.Neon
		r.Color = Color3.fromRGB(150, 40, 255)
		r.Transparency = 1
		r.Size = Vector3.new(0.1, 0.1, 0.1)
		r.CFrame = origin * CFrame.new(0, drop + height * 0.6, -6)
		rift = r
	end

	------------------------------------------------------------------ pós-efeito (só nesta câmera)
	local camera = Workspace.CurrentCamera
	local grade = Instance.new("ColorCorrectionEffect")
	grade.Name = "JackpotGrade"
	grade.TintColor = Color3.new(1, 1, 1)
	if camera then
		grade.Parent = camera
	end
	local tint = rgb(preset.Tint)

	------------------------------------------------------------------ câmera real
	local saved: { [string]: any } = {}
	if camera then
		saved = { type = camera.CameraType, subject = camera.CameraSubject, fov = camera.FieldOfView, cframe = camera.CFrame }
		camera.CameraType = Enum.CameraType.Scriptable
		camera.FieldOfView = stageCfg.CameraFov
	end
	-- controles do jogador congelados durante a cinemática (o avatar não anda "às cegas")
	local controls: any = nil
	pcall(function()
		local scripts = Players.LocalPlayer:FindFirstChild("PlayerScripts")
		local module = scripts and scripts:FindFirstChild("PlayerModule")
		if module then
			controls = (require :: any)(module):GetControls()
			controls:Disable()
		end
	end)

	------------------------------------------------------------------ interface (safe area)
	local playerGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
	-- HUD some durante o momento (volta exatamente como estava)
	if playerGui then
		for _, other in playerGui:GetChildren() do
			if other:IsA("ScreenGui") and other.Enabled and other.DisplayOrder < 200 then
				other:SetAttribute("JackpotHidden", true)
				other.Enabled = false
			end
		end
	end
	local gui = UIKit.screen("HeroLanding", 200)
	gui.IgnoreGuiInset = true
	gui:SetAttribute("Stage", "World")
	pcall(function()
		(gui :: any).ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	end)
	local function bar(name: string, top: boolean): Frame
		return UIKit.new("Frame", {
			Name = name,
			BackgroundColor3 = Color3.new(0, 0, 0),
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 0),
			AnchorPoint = Vector2.new(0, if top then 0 else 1),
			Position = UDim2.fromScale(0, if top then 0 else 1),
			ZIndex = 2,
		}, gui)
	end
	local topBar, bottomBar = bar("LetterboxTop", true), bar("LetterboxBottom", false)
	for _, b in { topBar, bottomBar } do
		TweenService:Create(b, TweenInfo.new(0.35, Enum.EasingStyle.Quad), { Size = UDim2.fromScale(1, 0.085) }):Play()
	end
	local dim = UIKit.new("Frame", {
		Name = "Dim",
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 1,
	}, gui)
	local flash = UIKit.new("Frame", {
		Name = "Flash",
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 20,
	}, gui)
	-- textos em ESCALA da tela (não só UIScale): TextScaled + limites de tamanho
	local function bigText(name: string, y: number, h: number, color: Color3, maxSize: number): TextLabel
		local label = UIKit.new("TextLabel", {
			Name = name,
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(0.9, h),
			Position = UDim2.fromScale(0.5, y),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Font = Theme.Font,
			Text = "",
			TextColor3 = color,
			TextScaled = true,
			TextTransparency = 1,
			TextStrokeTransparency = 1,
			ZIndex = 10,
		}, gui) :: TextLabel
		UIKit.new("UITextSizeConstraint", { MaxTextSize = maxSize, MinTextSize = 14 }, label)
		UIKit.new("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0), Transparency = 1 }, label)
		UIKit.new("UIScale", { Scale = 1 }, label)
		return label
	end
	local intro = bigText("Intro", 0.3, 0.14, accent, 110)
	local rarityLabel = bigText("Rarity", 0.16, 0.12, rarityColor, 96)
	local newLabel = bigText("New", 0.255, 0.05, Theme.Colors.Warning, 44)
	local nameLabel = bigText("Name", 0.79, 0.08, Color3.new(1, 1, 1), 64)
	local oddsLabel = bigText("Odds", 0.855, 0.045, Theme.Colors.TextMuted, 36)
	local function pop(label: TextLabel, text: string, scale: number?)
		label.Text = text
		label.TextTransparency = 0
		local stroke = label:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Transparency = 0
		end
		local s = label:FindFirstChildOfClass("UIScale")
		if s then
			s.Scale = scale or 1.7
			TweenService:Create(s, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		end
	end
	local continueButton = UIKit.button(gui, {
		name = "Continue",
		text = Localization.t("reveal.continue"),
		color = Theme.Colors.Success,
		size = UDim2.fromOffset(220, 58),
		position = UDim2.new(0.5, 0, 0.965, 0),
		anchor = Vector2.new(0.5, 1),
	})
	continueButton.Visible = false
	continueButton.ZIndex = 12
	local skipButton = UIKit.button(gui, {
		name = "Skip",
		text = Localization.t("reveal.skip"),
		color = Color3.fromRGB(70, 70, 90),
		size = UDim2.fromOffset(140, 44),
		position = UDim2.new(1, -16, 0.1, 0),
		anchor = Vector2.new(1, 0),
	})
	skipButton.Visible = opts.canSkip
	skipButton.ZIndex = 12
	-- falhas de tela (suspense do Secreto)
	local glitches: { Frame } = {}
	if secret then
		for i = 1, 6 do
			table.insert(glitches, UIKit.new("Frame", {
				Name = "Glitch",
				BackgroundColor3 = if i % 2 == 0 then Color3.fromRGB(255, 40, 200) else Color3.fromRGB(40, 255, 255),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 6 + i * 4),
				ZIndex = 15,
			}, gui))
		end
	end

	------------------------------------------------------------------ impacto
	type Moving = { part: BasePart, kind: string, born: number, velocity: Vector3?, size: number, life: number }
	local moving: { Moving } = {}
	local sparks = Instance.new("ParticleEmitter")
	sparks.Name = "ImpactSparks"
	sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparks.Color = ColorSequence.new(Color3.new(1, 1, 1), accent)
	sparks.LightEmission = 0.8
	sparks.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, if secret then 1.4 else 1), NumberSequenceKeypoint.new(1, 0) })
	sparks.Lifetime = NumberRange.new(0.5, 1.1)
	sparks.Speed = NumberRange.new(if secret then 40 else 26, if secret then 70 else 44)
	sparks.SpreadAngle = Vector2.new(if secret then 88 else 70, if secret then 88 else 70)
	sparks.Drag = 4
	sparks.Acceleration = Vector3.new(0, -30, 0)
	sparks.EmissionDirection = Enum.NormalId.Top
	sparks.Rate = 0
	local impactPart = newPart(stage, "ImpactPoint")
	impactPart.Size = Vector3.new(1, 0.2, 1)
	impactPart.Transparency = 1
	impactPart.CFrame = origin * CFrame.new(0, 0.2, 0)
	sparks.Parent = impactPart

	local function ring(color: Color3, size: number, life: number, y: number, now: number)
		local r = newPart(stage, "Shockwave")
		r.Shape = Enum.PartType.Cylinder
		r.Material = Enum.Material.Neon
		r.Color = color
		r.Transparency = 0.05
		r.Size = Vector3.new(0.18, 1, 1)
		r.CFrame = origin * CFrame.new(0, y, 0) * CFrame.Angles(0, 0, math.rad(90))
		table.insert(moving, { part = r, kind = "ring", born = now, size = size, life = life } :: Moving)
	end

	local groundRing: Part? = nil
	local function spawnImpact(now: number)
		ring(accent, preset.RingSize, 0.5, 0.06, now)
		ring(Color3.new(1, 1, 1), preset.RingSize * 1.5, 0.75, 0.09, now)
		if secret then
			-- 2ª onda atrasada (o chão "responde" ao impacto)
			task.delay(0.18, function()
				if not handle.done then
					ring(Color3.fromRGB(190, 90, 255), preset.RingSize * 2.1, 1.0, 0.12, os.clock())
				end
			end)
		end
		-- anel no chão que FICA (ground effect)
		local g = newPart(stage, "GroundRing")
		g.Shape = Enum.PartType.Cylinder
		g.Material = Enum.Material.Neon
		g.Color = accent
		g.Transparency = 0.25
		g.Size = Vector3.new(0.1, height * 1.6 + 4, height * 1.6 + 4)
		g.CFrame = origin * CFrame.new(0, 0.04, 0) * CFrame.Angles(0, 0, math.rad(90))
		groundRing = g
		mark.Transparency = 1
		emit(sparks, preset.Sparks * quality.Particles)
		-- poeira
		local dust = math.max(4, math.floor((if secret then 14 else 10) * quality.Particles))
		for i = 1, dust do
			local d = newPart(stage, "Dust")
			d.Shape = Enum.PartType.Ball
			d.Color = (if secret then Color3.fromRGB(70, 50, 95) else Color3.fromRGB(230, 220, 200)):Lerp(accent, 0.2)
			d.Transparency = 0.3
			d.Size = Vector3.new(2, 2, 2)
			local angle = i / dust * math.pi * 2
			d.CFrame = origin * CFrame.new(math.cos(angle) * 2, 0.8, math.sin(angle) * 2)
			table.insert(moving, { part = d, kind = "dust", born = now, velocity = Vector3.new(math.cos(angle), 0.15, math.sin(angle)) * (if secret then 14 else 10), size = 5 + i % 3, life = 1.3 } :: Moving)
		end
		-- destroços (balísticos, sem física real)
		for _ = 1, math.max(3, math.floor(preset.Debris * quality.Debris)) do
			local rock = newPart(stage, "Debris")
			rock.Color = if secret then Color3.fromRGB(45, 35, 60) else Color3.fromRGB(150, 140, 125)
			rock.Material = Enum.Material.Slate
			local s = 0.4 + math.random() * 0.8
			rock.Size = Vector3.new(s, s, s)
			rock.CFrame = origin * CFrame.new(math.random() * 2 - 1, 0.5, math.random() * 2 - 1)
			local angle = math.random() * math.pi * 2
			local push = if secret then 12 else 8
			table.insert(moving, { part = rock, kind = "debris", born = now, velocity = Vector3.new(math.cos(angle) * (push + math.random() * 8), 14 + math.random() * 12, math.sin(angle) * (push + math.random() * 8)), size = s, life = 3 } :: Moving)
		end
		-- Secreto: estilhaços radiais rasgando o chão
		if secret then
			for i = 1, 10 do
				local shard = newPart(stage, "RiftShard")
				shard.Material = Enum.Material.Neon
				shard.Color = if i % 2 == 0 then accent else Color3.fromRGB(190, 90, 255)
				shard.Size = Vector3.new(0.35, 0.12, 1)
				local angle = i / 10 * math.pi * 2
				shard.CFrame = origin * CFrame.new(0, 0.05, 0) * CFrame.Angles(0, angle, 0)
				table.insert(moving, { part = shard, kind = "shard", born = now, size = preset.RingSize * 0.45, life = 0.6 } :: Moving)
			end
		end
		-- flash controlado + tremida + som
		flash.BackgroundTransparency = 1 - preset.Flash
		TweenService:Create(flash, TweenInfo.new(0.16 + (preset.WhiteOut or 0) * 2), { BackgroundTransparency = 1 }):Play()
		shake:Add(shakeScale, preset.ShakeTime + shakeScale * 0.2)
		UIKit.sound(preset.Sounds[3])
		UIKit.sound(preset.Sounds[4])
		grade.Brightness = if secret then 0.3 else 0.15
	end

	local function updateMoving(now: number, dt: number)
		for i = #moving, 1, -1 do
			local m = moving[i]
			local age = now - m.born
			local t = clamp01(age / m.life)
			local part = m.part
			if m.kind == "ring" then
				local d = 1 + easeOut(t) * m.size * 2
				part.Size = Vector3.new(0.18, d, d)
				part.Transparency = 0.05 + t * 0.95
			elseif m.kind == "dust" then
				local v = m.velocity :: Vector3
				part.CFrame += v * dt * (1 - t)
				local d = 2 + easeOut(t) * m.size
				part.Size = Vector3.new(d, d * 0.7, d)
				part.Transparency = 0.3 + t * 0.7
			elseif m.kind == "debris" then
				local v = m.velocity :: Vector3
				local p = part.CFrame.Position
				local floor = origin.Y + m.size / 2
				if p.Y > floor or v.Y > 0 then
					v = Vector3.new(v.X * 0.98, v.Y - 55 * dt, v.Z * 0.98)
					m.velocity = v
					local n = p + v * dt
					part.CFrame = CFrame.new(n.X, math.max(n.Y, floor), n.Z) * part.CFrame.Rotation * CFrame.Angles(dt * 6, dt * 4, 0)
				end
			elseif m.kind == "shard" then
				local length = 1 + easeOut(t) * m.size
				local rot = part.CFrame.Rotation
				part.Size = Vector3.new(0.35, 0.12, length)
				part.CFrame = CFrame.new((origin * CFrame.new(0, 0.05, 0)).Position) * rot * CFrame.new(0, 0, -length / 2 - 1)
				part.Transparency = phase(age, m.life * 0.6, m.life * 2)
			end
			if age > m.life * 2.2 and m.kind ~= "debris" then
				part:Destroy()
				table.remove(moving, i)
			end
		end
	end

	------------------------------------------------------------------ Aura Full
	local layers: { { Instance } } = {}
	local layerAt: number? = nil
	local function attachAura(now: number)
		local ok = pcall(function()
			AuraBuilder.attach(model, opts.characterId, opts.rarity, "Full", height)
		end)
		if not ok then
			return
		end
		if preset.AuraEntry == "Layers" then
			-- tudo apagado e reacende zona por zona (corpo -> fora -> coroa)
			local byZone: { [string]: { Instance } } = {}
			local rest: { Instance } = {}
			for _, obj in model:GetDescendants() do
				if obj:IsA("ParticleEmitter") or obj:IsA("Beam") or obj:IsA("Trail") or obj:IsA("Highlight") or obj:IsA("Light") then
					if string.sub(obj.Name, 1, 4) == "Aura" or (obj.Parent and string.sub(obj.Parent.Name, 1, 4) == "Aura") then
						local zone = nil
						local p: Instance? = obj.Parent
						while p and p ~= model do
							if table.find(LAYER_ORDER, p.Name) then
								zone = p.Name
								break
							end
							p = (p :: Instance).Parent
						end
						if zone then
							byZone[zone] = byZone[zone] or {}
							table.insert(byZone[zone], obj)
						else
							table.insert(rest, obj)
						end
						(obj :: any).Enabled = false
					end
				end
			end
			for _, zone in LAYER_ORDER do
				if byZone[zone] then
					table.insert(layers, byZone[zone])
				end
			end
			table.insert(layers, rest)
			layerAt = now
		end
		-- rajada da ASSINATURA do estilo no impacto (Burst do AuraBuilder)
		for _, obj in model:GetDescendants() do
			if obj:IsA("ParticleEmitter") and obj:GetAttribute("AuraRole") == "Burst" then
				emit(obj, ((obj:GetAttribute("AuraBurstCount") :: number?) or 10) * (if secret then 2 else 1))
			end
		end
	end
	local function updateLayers(now: number)
		if not layerAt or #layers == 0 then
			return
		end
		local index = math.floor((now - layerAt) / preset.LayerStep) + 1
		for i = 1, math.min(index, #layers) do
			local list = layers[i]
			if list then
				for _, obj in list do
					(obj :: any).Enabled = true
				end
				layers[i] = {}
			end
		end
	end

	------------------------------------------------------------------ limpeza
	local function cleanup()
		if handle.done then
			return
		end
		handle.done = true
		for _, c in connections do
			c:Disconnect()
		end
		if camera then
			-- cada propriedade isolada: uma falha (ex.: CameraSubject sumiu) não impede as outras
			-- (o enquadramento volta ao de antes; Custom recalcula no frame seguinte de qualquer jeito)
			local cam = camera :: Camera
			for _, restore in {
				function()
					cam.CFrame = saved.cframe
				end,
				function()
					cam.FieldOfView = saved.fov
				end,
				function()
					cam.CameraType = saved.type
				end,
				function()
					if saved.subject then -- nil = sem alvo (atribuir nil quebraria)
						cam.CameraSubject = saved.subject
					end
				end,
			} do
				local okRestore, why = (pcall :: any)(restore)
				if not okRestore then
					warn("[Roll Legends][JackpotReveal] restaurar câmera:", why)
				end
			end
		end
		pcall(function()
			if controls then
				controls:Enable()
			end
		end)
		if playerGui then
			for _, other in playerGui:GetChildren() do
				if other:GetAttribute("JackpotHidden") then
					other:SetAttribute("JackpotHidden", nil)
					;(other :: ScreenGui).Enabled = true
				end
			end
		end
		for _, obj in clothing do
			obj:Destroy()
		end
		grade:Destroy()
		stage:Destroy() -- personagem, aura, efeitos (o AuraController solta a aura pela tag)
		gui:Destroy()
		handle.Finished:Fire()
	end

	------------------------------------------------------------------ linha do tempo
	local clock = 0 -- tempo da cinemática (o Secreto desacelera perto do impacto)
	local last = os.clock()
	local impactDone, titleDone, continueShown = false, false, false
	local autoCloseAt: number? = nil
	local played: { [string]: boolean } = {}
	local function soundOnce(key: string, name: string)
		if not played[key] then
			played[key] = true
			UIKit.sound(name)
		end
	end
	local smoothLook: Vector3? = nil
	local smoothPos: Vector3? = nil
	local fov = stageCfg.CameraFov
	local frameDist = JackpotReveal.frameDistance(height, fov)
	local center = origin.Position + Vector3.new(0, height * 0.5, 0)
	-- enquadramento final: corpo inteiro + anel no chão, levemente de lado e de baixo (heroico)
	local finalPos = center + Vector3.new(frameDist * 0.22, height * 0.05, frameDist)

	local function title()
		if titleDone then
			return
		end
		titleDone = true
		pop(rarityLabel, Localization.t("rarity." .. opts.rarity), if secret then 2.2 else 1.7)
		if opts.isNew then
			pop(newLabel, Localization.t("reveal.new"))
		end
		pop(nameLabel, character.Name)
		local oddsText = if opts.odds > 0 then Localization.t("reveal.odds", { odds = NumberFormatter.thousands(opts.odds) }) else ""
		if opts.luck then
			oddsText ..= "   🍀 " .. string.format("%.2fx", opts.luck)
		end
		pop(oddsLabel, oddsText, 1.2)
		local variant = opts.variant and VariantConfig.ById[opts.variant]
		if variant and variant.Id ~= "Normal" and groundRing then
			groundRing.Color = rgb(variant.Color)
		end
		soundOnce("stinger", preset.Sounds[5])
	end

	local function impact(now: number)
		if impactDone then
			return
		end
		impactDone = true
		model:PivotTo(feetAt(0))
		CharacterModelFactory.pose(model, "Crouch")
		revealColors()
		glow.Transparency = 1
		streak.Rate = 0
		spawnImpact(now)
		attachAura(now)
	end

	function handle.Skip(_self: Handle)
		impact(os.clock())
		clock = math.max(clock, preset.Pose)
		skipButton.Visible = false
	end
	function handle.Stop(_self: Handle)
		cleanup()
	end
	table.insert(connections, skipButton.Activated:Connect(function()
		handle:Skip()
	end))
	table.insert(connections, continueButton.Activated:Connect(function()
		UIKit.sound("Click")
		cleanup()
	end))
	table.insert(connections, Players.LocalPlayer.CharacterRemoving:Connect(cleanup))

	task.delay(preset.Silence or 0, function()
		if not handle.done then
			soundOnce("trigger", preset.Sounds[1])
		end
	end)
	if preset.Intro then
		intro.Text = Localization.t(preset.Intro)
	end

	table.insert(connections, RunService.RenderStepped:Connect(function()
		if handle.done then
			return -- frame atrasado depois da limpeza: nunca mexe na câmera já devolvida
		end
		local ok, err = (pcall :: any)(function()
			local now = os.clock()
			local realDt = math.min(now - last, 0.05)
			last = now
			-- câmera lenta do Secreto: os últimos instantes antes do impacto
			local scale = 1
			if preset.SlowMo and clock >= preset.Impact - preset.SlowMo and clock < preset.Impact then
				scale = preset.SlowMoScale
			end
			clock += realDt * scale
			local t = clock
			local dt = realDt

			-- intro (DIVINO / ???) e escurecer
			if preset.Intro then
				local a = phase(t, 0.05, 0.3)
				local b = phase(t, preset.FallStart - 0.2, preset.FallStart + 0.05)
				intro.TextTransparency = 1 - a + b
				local stroke = intro:FindFirstChildOfClass("UIStroke")
				if stroke then
					stroke.Transparency = intro.TextTransparency
				end
				local s = intro:FindFirstChildOfClass("UIScale")
				if s then
					s.Scale = 1.4 - 0.4 * easeOut(a)
				end
			end
			local darkIn = phase(t, 0, if secret then preset.Suspense else 0.4)
			local darkOut = phase(t, preset.Impact, preset.Impact + 0.6)
			dim.BackgroundTransparency = 1 - preset.Darken * darkIn * (1 - darkOut)
			-- cor da cena: Secreto drena a cor no suspense e volta tingido; Divino aquece
			local strength = preset.TintStrength
			if secret then
				grade.Saturation = -0.8 * darkIn * (1 - darkOut) + 0.15 * darkOut
				grade.Contrast = 0.25 * darkIn
			else
				grade.Saturation = 0.1 * darkIn
			end
			grade.TintColor = Color3.new(1, 1, 1):Lerp(tint, strength * darkIn)
			grade.Brightness = grade.Brightness + (0 - grade.Brightness) * math.min(1, dt * 3)
			for _, g in glitches do
				local active = t > (preset.Silence or 0) and t < preset.FallStart and math.random() < 0.3
				g.BackgroundTransparency = if active then 0.3 else 1
				g.Position = UDim2.new(math.random() * 0.1 - 0.05, 0, math.random(), 0)
			end
			for _, beam in beams do
				beam.Transparency = 1 - 0.6 * phase(t, 0.05, preset.FallStart) * (1 - phase(t, preset.Pose, preset.Duration))
			end
			if rift then
				local open = phase(t, preset.Silence or 0, preset.Appear + 0.3)
				local close = phase(t, preset.Impact, preset.Impact + 0.4)
				rift.Transparency = 1 - 0.85 * open * (1 - close)
				rift.Size = Vector3.new(18 * open + 0.1, 30 * open + 0.1, 1)
			end

			-- posição do personagem: surge alto -> (Secreto: paira carregando) -> queda
			local y: number
			local fall = phase(t, preset.FallStart, preset.Impact)
			if t < preset.Appear then
				y = drop + 40 -- ainda fora de quadro
			elseif t < preset.FallStart then
				y = drop + math.sin(t * 5) * 0.4
			else
				y = drop * (1 - fall ^ preset.FallPower)
			end
			if t < preset.Impact then
				model:PivotTo(feetAt(y))
				CharacterModelFactory.lerpPose(model, "Idle", "Crouch", 0.55)
				carrier.CFrame = origin * CFrame.new(0, y + height * 0.5, 0)
				glow.CFrame = origin * CFrame.new(0, y + height * 0.55, -0.8)
				local appear = phase(t, preset.Appear, preset.Appear + 0.25)
				glow.Transparency = 1 - (if secret then 0.55 else 0.4) * appear
				if secret and t < preset.FallStart then
					-- carregando energia no alto: o brilho pulsa e cresce
					local charge = phase(t, preset.Appear, preset.FallStart)
					glow.Size = Vector3.new(1, 1, 1) * math.max(5, height * 1.1) * (1 + charge * 0.8 + math.sin(t * 18) * 0.08)
				end
				streak.Rate = if fall > 0 then 40 + 160 * fall * quality.Particles else 0
				if fall > 0 then
					soundOnce("fall", preset.Sounds[2])
				end
			else
				impact(now)
			end

			-- levanta e pose final (Crouch -> Confident) + leve giro
			if t >= preset.Rise then
				local rise = smooth(phase(t, preset.Rise, preset.Pose))
				CharacterModelFactory.lerpPose(model, "Crouch", "Confident", rise)
				model:PivotTo(feetAt(0) * CFrame.Angles(0, math.sin((t - preset.Rise) * 0.7) * 0.15 * rise, 0))
			end
			if t >= preset.Title then
				title()
			end
			if impactDone then
				updateMoving(now, dt)
				updateLayers(now)
				if groundRing then
					groundRing.Transparency = 0.25 + 0.35 * phase(t, preset.Impact + 0.3, preset.Pose)
				end
			end
			if t >= preset.Continue and not continueShown then
				continueShown = true
				continueButton.Visible = true
				skipButton.Visible = false
				if opts.autoClose > 0 then
					autoCloseAt = now + opts.autoClose
				end
			end
			if autoCloseAt and now >= autoCloseAt then
				cleanup()
				return
			end

			-- CÂMERA (real): ALTO -> QUEDA -> IMPACTO -> HERO LANDING enquadrado
			if not camera or handle.done then
				return
			end
			local body = origin.Position + Vector3.new(0, y + height * 0.5, 0)
			local pos: Vector3
			local look: Vector3
			if t < preset.Impact then
				if not secret then
					-- Divino: de baixo, acompanhando a queda (vê o céu e o herói vindo)
					pos = center + Vector3.new(frameDist * 0.35, -height * 0.2 + 1.5, frameDist * 1.25)
					look = if t < preset.Appear then center + Vector3.new(0, drop * 0.7, 0) else body
				else
					local cutAt = preset.Impact - (preset.SlowMo or 0) - 0.25
					if t < preset.FallStart then
						-- suspense: do chão olhando a fenda no céu
						pos = center + Vector3.new(0, 1, frameDist * 1.4)
						look = center + Vector3.new(0, drop * 0.85, 0)
					elseif t < cutAt then
						-- mergulho: câmera acima e atrás do herói, olhando para baixo (o chão cresce)
						pos = body + Vector3.new(2.5, height * 1.2 + 6, frameDist * 0.55)
						look = body + Vector3.new(0, -height * 2, 0)
						smoothPos, smoothLook = pos, look
					else
						-- CORTE para o chão: contra-plongée, o herói entra no quadro em câmera lenta
						pos = center + Vector3.new(-frameDist * 0.3, -height * 0.25 + 1.2, frameDist * 1.05)
						look = body:Lerp(center, 0.35)
						smoothPos, smoothLook = pos, look
					end
				end
			else
				-- impacto -> enquadra o corpo inteiro + chão; depois aproxima devagar (pose)
				local settle = easeOut(phase(t, preset.Impact, preset.Impact + 0.6))
				local push = smooth(phase(t, preset.Pose, preset.Continue + 1))
				local orbit = if secret then math.rad(-12) * push else math.rad(8) * push
				local offset = finalPos - center
				offset = CFrame.Angles(0, orbit, 0):VectorToWorldSpace(offset) * (1 - 0.08 * push)
				local target = center + offset
				local from = if smoothPos then smoothPos else target
				pos = from:Lerp(target, settle)
				look = center
			end
			-- suaviza (sem trancos), exceto no corte do Secreto
			local k = math.min(1, dt * 10)
			smoothPos = if smoothPos then smoothPos:Lerp(pos, k) else pos
			smoothLook = if smoothLook then smoothLook:Lerp(look, k) else look
			local fovNow = fov + (preset.FovFall - fov) * fall * (1 - phase(t, preset.Impact, preset.Impact + 0.5))
			local punch = if impactDone then -5 * (1 - phase(t, preset.Impact, preset.Impact + 0.3)) else 0
			if handle.done then
				return
			end
			camera.FieldOfView = fovNow + punch
			camera.CFrame = CFrame.lookAt(smoothPos :: Vector3, smoothLook :: Vector3) * shake:Sample()
		end)
		if not ok then
			warn("[Roll Legends][JackpotReveal] erro na cinemática:", err)
			cleanup()
		end
	end))

	return handle
end

return JackpotReveal
