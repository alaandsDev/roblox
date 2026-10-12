--!strict
--[[
	HeroLanding: cinemática ORIGINAL de drop raro (Lendário, Mítico, Divino, Secreto).

	    silhueta no céu -> queda em alta velocidade (rastros, speed lines, FOV abre) ->
	    IMPACTO (flash, tremida, anel, onda de choque, poeira, destroços, rachaduras, grave) ->
	    poeira baixa, herói ajoelhado -> levanta -> pose confiante -> RARIDADE / NOME / NOVO! / 1 EM X

	Tudo acontece num PALCO LOCAL: um ViewportFrame em tela cheia com câmera própria.
	Nada é criado no Workspace e a câmera/controles do jogador NUNCA são tocados — por isso
	não há como a câmera "ficar presa". Mesmo assim existe limpeza robusta: Stop() (pular,
	morrer, fechar, erro) destrói a interface, devolve peças ao pool e desliga as conexões.

	Parâmetros por raridade em RevealConfig.Cinematics (tempos, tremida, FOV, anel, destroços,
	efeito de céu, sons). Qualidade (High/Medium/Low) reduz partículas/destroços/rastros.
	Variantes (Gold, Diamond...) somam um efeito de cor por cima (composição, não uma
	cinemática por combinação).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage.Shared
local RevealConfig = require(Shared.Config.RevealConfig)
local RarityConfig = require(Shared.Config.RarityConfig)
local CharacterConfig = require(Shared.Config.CharacterConfig)
local VariantConfig = require(Shared.Config.VariantConfig)
local CharacterModelFactory = require(Shared.Modules.CharacterModelFactory)
local CharacterAssetConfig = require(Shared.Config.CharacterAssetConfig)
local NumberFormatter = require(Shared.Modules.NumberFormatter)
local Localization = require(Shared.Localization.Localization)
local Signal = require(Shared.Modules.Signal)

local UI = script.Parent.Parent.UI
local UIKit = require(UI.UIKit)
local Theme = require(UI.UITheme)
local CameraShake = require(script.Parent.CameraShake)
local Pool = require(script.Parent.Pool)

local HeroLanding = {}

local SKY_HEIGHT = 70
local CAMERA_POS = Vector3.new(0, 4.5, 19)
local LOOK_GROUND = Vector3.new(0, 3.2, 0)

local function rgb(list: { number }): Color3
	return Color3.fromRGB(list[1], list[2], list[3])
end

local function newPart(): Part
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	return part
end

-- Pools compartilhados entre cinemáticas (nada se acumula depois de 100 rolls)
local debrisPool = Pool.new(newPart, 40)
local ringPool = Pool.new(function()
	local part = newPart()
	part.Shape = Enum.PartType.Cylinder
	part.Material = Enum.Material.Neon
	return part
end, 8)
local dustPool = Pool.new(function()
	local part = newPart()
	part.Shape = Enum.PartType.Ball
	part.Material = Enum.Material.SmoothPlastic
	return part
end, 16)

local function easeIn(t: number): number
	return t * t * t
end
local function easeOut(t: number): number
	return 1 - (1 - t) ^ 3
end
local function clamp01(t: number): number
	return math.clamp(t, 0, 1)
end
local function phase(t: number, a: number, b: number): number
	return clamp01((t - a) / math.max(b - a, 1e-3))
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
}

export type Handle = { done: boolean, Finished: any, Stop: (self: Handle) -> (), Skip: (self: Handle) -> () }

function HeroLanding.play(opts: Options): Handle
	local preset = RevealConfig.Cinematics[opts.cinematic]
	local quality = RevealConfig.Quality[opts.quality] or RevealConfig.Quality.High
	local character = CharacterConfig.ById[opts.characterId]
	local rarityColor = rgb(RarityConfig.ById[opts.rarity].Color)
	local accent = if preset.Lighting then rgb(preset.Lighting) else rarityColor

	local handle = { done = false, Finished = Signal.new() } :: any
	local connections: { RBXScriptConnection } = {}
	local pooled: { { pool: any, item: Instance } } = {}
	local shake = CameraShake.new(opts.shake > 0)

	------------------------------------------------------------------ interface + palco
	local gui = UIKit.screen("HeroLanding", 200)
	gui.IgnoreGuiInset = true
	local dim = UIKit.new("Frame", {
		Name = "Dim",
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, gui)
	TweenService:Create(dim, TweenInfo.new(0.2), { BackgroundTransparency = 1 - preset.Darken }):Play()

	local viewport = UIKit.new("ViewportFrame", {
		Name = "Stage",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Ambient = Color3.fromRGB(140, 140, 160),
		LightColor = Color3.fromRGB(255, 250, 240),
		LightDirection = Vector3.new(-0.4, -1, -0.6),
	}, gui)
	local camera = Instance.new("Camera")
	camera.FieldOfView = RevealConfig.BaseFov
	camera.Parent = viewport
	viewport.CurrentCamera = camera
	local world = Instance.new("WorldModel")
	world.Parent = viewport

	local overlay = UIKit.scaledRoot(gui, "Overlay")
	local flash = UIKit.new("Frame", {
		Name = "Flash",
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 20,
	}, gui)

	-- Chão do palco (disco) + rachaduras (só visual, somem no fim)
	local ground = newPart()
	ground.Shape = Enum.PartType.Cylinder
	ground.Size = Vector3.new(1, 70, 70)
	ground.CFrame = CFrame.new(0, -0.5, 0) * CFrame.Angles(0, 0, math.rad(90))
	ground.Color = Color3.fromRGB(70, 75, 95)
	ground.Material = Enum.Material.Slate
	ground.Parent = world

	------------------------------------------------------------------ personagem
	local model = CharacterModelFactory.build(opts.characterId, { variant = opts.variant, aura = false, vfx = CharacterAssetConfig.VFXModes.HeroLanding })
	model.Parent = world
	local facing = CFrame.Angles(0, math.pi, 0) -- de frente para a câmera
	-- Silhueta: cores originais guardadas e trocadas por sombra (ou luz, no Divino)
	local originals: { [BasePart]: { Color3 | Enum.Material } } = {}
	local silhouetteColor = if preset.SkyEffect == "Heaven" then Color3.fromRGB(255, 250, 225) else Color3.fromRGB(12, 10, 18)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part.Transparency < 1 then
			originals[part] = { part.Color, part.Material }
			part.Color = silhouetteColor
			part.Material = if preset.SkyEffect == "Heaven" then Enum.Material.Neon else Enum.Material.SmoothPlastic
		end
	end
	-- Asset do pipeline: texturas, rosto e roupas também somem na silhueta (voltam no reveal)
	local hiddenTextures: { { any } } = {}
	local hiddenDecals: { [Decal]: number } = {}
	local hiddenClothing: { Instance } = {}
	for _, obj in model:GetDescendants() do
		if obj:IsA("MeshPart") and obj.TextureID ~= "" then
			table.insert(hiddenTextures, { obj :: any, "TextureID", obj.TextureID })
			obj.TextureID = ""
		elseif obj:IsA("SpecialMesh") and obj.TextureId ~= "" then
			table.insert(hiddenTextures, { obj :: any, "TextureId", obj.TextureId })
			obj.TextureId = ""
		elseif obj:IsA("Decal") then
			hiddenDecals[obj] = obj.Transparency
			obj.Transparency = 1
		elseif obj:IsA("Clothing") or obj:IsA("ShirtGraphic") then
			local clothing = obj :: Instance
			table.insert(hiddenClothing, clothing)
			clothing.Parent = nil
		end
	end
	local revealed = false
	local function revealColors()
		if revealed then
			return
		end
		revealed = true
		for part, saved in originals do
			part.Color = saved[1] :: Color3
			part.Material = saved[2] :: Enum.Material
		end
		for _, saved in hiddenTextures do
			saved[1][saved[2]] = saved[3]
		end
		for decal, transparency in hiddenDecals do
			decal.Transparency = transparency
		end
		for _, clothing in hiddenClothing do
			clothing.Parent = model
		end
		table.clear(hiddenClothing)
	end

	-- Brilho atrás da silhueta
	local glow = newPart()
	glow.Shape = Enum.PartType.Ball
	glow.Material = Enum.Material.Neon
	glow.Color = accent
	glow.Transparency = 0.55
	glow.Size = Vector3.new(7, 7, 7)
	glow.Parent = world

	-- Rastros da queda
	local trails: { Part } = {}
	if quality.Trails then
		local count = if preset.Trail == "Wind" then 3 else 5
		for i = 1, count do
			local trail = newPart()
			trail.Material = Enum.Material.Neon
			trail.Color = if preset.Trail == "Wind" then Color3.fromRGB(230, 240, 255) else accent
			trail.Transparency = 0.35
			trail.Size = Vector3.new(0.25, 1, 0.25)
			trail:SetAttribute("Offset", Vector3.new(math.cos(i * 2.1) * 1.6, 0, math.sin(i * 2.1) * 1.2))
			trail.Parent = world
			table.insert(trails, trail)
		end
	end

	------------------------------------------------------------------ efeitos de céu
	local beams: { Part } = {}
	if preset.SkyEffect == "Heaven" or preset.SkyEffect == "Aura" then
		local count = if preset.SkyEffect == "Heaven" then 6 else 3
		for i = 1, count do
			local beam = newPart()
			beam.Material = Enum.Material.Neon
			beam.Color = accent
			beam.Transparency = 1
			local angle = i / count * math.pi * 2
			beam.Size = Vector3.new(1.2, 120, 1.2)
			beam.CFrame = CFrame.new(math.cos(angle) * 14, 55, math.sin(angle) * 14 - 6)
			beam.Parent = world
			table.insert(beams, beam)
		end
	end
	local rift: Part? = nil
	if preset.SkyEffect == "Rift" then
		local r = newPart()
		r.Shape = Enum.PartType.Ball
		r.Material = Enum.Material.Neon
		r.Color = Color3.fromRGB(150, 40, 255)
		r.Transparency = 1
		r.Size = Vector3.new(14, 26, 1)
		r.CFrame = CFrame.new(0, SKY_HEIGHT, -4)
		r.Parent = world
		rift = r
	end

	------------------------------------------------------------------ UI de texto
	local function bigText(name: string, y: number, h: number, color: Color3): TextLabel
		local label = UIKit.text(overlay, {
			name = name,
			size = UDim2.new(0.9, 0, 0, h),
			position = UDim2.new(0.5, 0, y, 0),
			anchor = Vector2.new(0.5, 0.5),
			color = color,
			stroke = 4,
			z = 10,
		})
		label.TextTransparency = 1
		UIKit.new("UIScale", { Scale = 1 }, label)
		return label
	end
	local intro = bigText("Intro", 0.32, 120, accent)
	local rarityLabel = bigText("Rarity", 0.14, 92, rarityColor)
	local newLabel = bigText("New", 0.245, 52, Theme.Colors.Warning)
	local nameLabel = bigText("Name", 0.8, 70, Color3.new(1, 1, 1))
	local oddsLabel = bigText("Odds", 0.875, 40, Theme.Colors.TextMuted)
	local function pop(label: TextLabel, text: string)
		label.Text = text
		label.TextTransparency = 0
		local s = label:FindFirstChildOfClass("UIScale")
		if s then
			s.Scale = 1.6
			TweenService:Create(s, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		end
	end

	-- Speed lines (UI)
	local speedLines: { Frame } = {}
	for i = 1, quality.SpeedLines do
		local angle = (i / quality.SpeedLines) * 360 + math.random(-8, 8)
		local line = UIKit.new("Frame", {
			Name = "SpeedLine",
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(6, 260),
			Rotation = angle,
			ZIndex = 5,
		}, overlay)
		line:SetAttribute("Angle", math.rad(angle))
		table.insert(speedLines, line)
	end
	-- Barras de glitch (Secreto)
	local glitches: { Frame } = {}
	if preset.SkyEffect == "Rift" then
		for _ = 1, 6 do
			table.insert(glitches, UIKit.new("Frame", {
				BackgroundColor3 = if math.random() < 0.5 then Color3.fromRGB(255, 40, 200) else Color3.fromRGB(40, 255, 255),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, math.random(6, 30)),
				ZIndex = 15,
			}, gui))
		end
	end

	-- Botões
	local continueButton = UIKit.button(overlay, {
		name = "Continue",
		text = Localization.t("reveal.continue"),
		color = Theme.Colors.Success,
		size = UDim2.fromOffset(240, 64),
		position = UDim2.new(0.5, 0, 0.955, 0),
		anchor = Vector2.new(0.5, 1),
	})
	continueButton.Visible = false
	continueButton.ZIndex = 12
	local skipButton = UIKit.button(overlay, {
		name = "Skip",
		text = Localization.t("reveal.skip"),
		color = Color3.fromRGB(70, 70, 90),
		size = UDim2.fromOffset(150, 48),
		position = UDim2.new(1, -20, 0, 20),
		anchor = Vector2.new(1, 0),
	})
	skipButton.Visible = opts.canSkip
	skipButton.ZIndex = 12

	------------------------------------------------------------------ impacto
	local impactParts: { { part: BasePart, kind: string, born: number, velocity: Vector3?, size: number } } = {}
	local function borrow(pool: any): any
		local item = pool:Get()
		table.insert(pooled, { pool = pool, item = item })
		return item
	end

	local function spawnImpact(now: number)
		-- Anel no chão + onda de choque
		for i, size in { preset.RingSize, preset.RingSize * 1.6 } do
			local ring = borrow(ringPool)
			ring.Color = if i == 1 then accent else Color3.new(1, 1, 1)
			ring.Transparency = 0.1
			ring.Size = Vector3.new(0.15, 1, 1)
			ring.CFrame = CFrame.new(0, 0.05 + i * 0.02, 0) * CFrame.Angles(0, 0, math.rad(90))
			ring.Parent = world
			table.insert(impactParts, { part = ring, kind = "ring", born = now, size = size })
		end
		-- Poeira
		local dustCount = math.max(3, math.floor(10 * quality.Particles))
		for i = 1, dustCount do
			local dust = borrow(dustPool)
			dust.Color = Color3.fromRGB(190, 180, 165):Lerp(accent, 0.2)
			dust.Transparency = 0.3
			dust.Size = Vector3.new(2, 2, 2)
			local angle = i / dustCount * math.pi * 2
			dust.CFrame = CFrame.new(math.cos(angle) * 2, 0.8, math.sin(angle) * 2)
			dust.Parent = world
			table.insert(impactParts, {
				part = dust,
				kind = "dust",
				born = now,
				velocity = Vector3.new(math.cos(angle) * 9, 1.5, math.sin(angle) * 9),
				size = 5 + math.random() * 3,
			})
		end
		-- Destroços (visuais, sem física real)
		local debrisCount = math.max(3, math.floor(preset.Debris * quality.Debris))
		for _ = 1, debrisCount do
			local rock = borrow(debrisPool)
			rock.Color = Color3.fromRGB(95, 90, 105)
			rock.Material = Enum.Material.Slate
			rock.Transparency = 0
			local s = 0.4 + math.random() * 0.7
			rock.Size = Vector3.new(s, s, s)
			rock.CFrame = CFrame.new(math.random() * 2 - 1, 0.5, math.random() * 2 - 1)
			rock.Parent = world
			local angle = math.random() * math.pi * 2
			table.insert(impactParts, {
				part = rock,
				kind = "debris",
				born = now,
				velocity = Vector3.new(math.cos(angle) * (6 + math.random() * 8), 12 + math.random() * 10, math.sin(angle) * (6 + math.random() * 8)),
				size = s,
			})
		end
		-- Rachaduras no chão (efeito plano, não mexe em terreno)
		if quality.Cracks then
			for i = 1, 7 do
				local crack = borrow(debrisPool)
				crack.Color = Color3.fromRGB(20, 18, 28)
				crack.Material = Enum.Material.SmoothPlastic
				crack.Transparency = 0
				local angle = i / 7 * math.pi * 2 + math.random() * 0.4
				local length = 3 + math.random() * (preset.RingSize * 0.25)
				crack.Size = Vector3.new(0.25, 0.06, length)
				crack.CFrame = CFrame.new(0, 0.03, 0) * CFrame.Angles(0, angle, 0) * CFrame.new(0, 0, -length / 2 - 0.8)
				crack.Parent = world
			end
		end
		-- Flash, tremida, som
		flash.BackgroundTransparency = if preset.WhiteOut then 0 else 0.25
		TweenService:Create(flash, TweenInfo.new(0.18 + (preset.WhiteOut or 0) * 2), { BackgroundTransparency = 1 }):Play()
		shake:Add(opts.shake, 0.6 + opts.shake * 0.4)
		UIKit.sound(preset.Sounds[3])
		UIKit.sound(preset.Sounds[4])
		-- Luz da cena muda (Mítico+)
		if preset.Lighting then
			viewport.LightColor = accent
			viewport.Ambient = accent:Lerp(Color3.new(0.5, 0.5, 0.55), 0.5)
		end
	end

	local function updateImpact(now: number, dt: number)
		for _, entry in impactParts do
			local age = now - entry.born
			local part = entry.part
			if entry.kind == "ring" then
				local t = clamp01(age / 0.55)
				local d = 1 + easeOut(t) * entry.size
				part.Size = Vector3.new(0.15, d, d)
				part.Transparency = 0.1 + t * 0.9
			elseif entry.kind == "dust" then
				local t = clamp01(age / 1.2)
				local v = entry.velocity :: Vector3
				part.CFrame = part.CFrame + v * dt * (1 - t)
				local d = 2 + easeOut(t) * entry.size
				part.Size = Vector3.new(d, d * 0.7, d)
				part.Transparency = 0.3 + t * 0.7
			elseif entry.kind == "debris" then
				local v = entry.velocity :: Vector3
				local p = part.CFrame.Position
				if p.Y > entry.size / 2 or v.Y > 0 then
					v = Vector3.new(v.X * 0.98, v.Y - 50 * dt, v.Z * 0.98)
					entry.velocity = v
					local nextPos = p + v * dt
					part.CFrame = CFrame.new(Vector3.new(nextPos.X, math.max(nextPos.Y, entry.size / 2), nextPos.Z)) * part.CFrame.Rotation * CFrame.Angles(dt * 6, dt * 4, 0)
				end
			end
		end
	end

	------------------------------------------------------------------ limpeza
	local function cleanup()
		if handle.done then
			return
		end
		handle.done = true
		for _, connection in connections do
			connection:Disconnect()
		end
		for _, entry in pooled do
			entry.pool:Release(entry.item)
		end
		table.clear(pooled)
		-- Roupas tiradas para a silhueta (se a cinemática acabou antes do reveal)
		for _, clothing in hiddenClothing do
			clothing:Destroy()
		end
		table.clear(hiddenClothing)
		gui:Destroy() -- palco, modelo, rastros, UI, câmera do viewport
		handle.Finished:Fire()
	end

	------------------------------------------------------------------ linha do tempo
	local start = os.clock()
	local last = start
	local impactDone = false
	local revealDone = false
	local continueShown = false
	local autoCloseAt: number? = nil
	local soundsPlayed: { [string]: boolean } = {}
	local function soundOnce(key: string, name: string)
		if not soundsPlayed[key] then
			soundsPlayed[key] = true
			UIKit.sound(name)
		end
	end

	local function finishReveal()
		if revealDone then
			return
		end
		revealDone = true
		revealColors()
		pop(rarityLabel, Localization.t("rarity." .. opts.rarity))
		if opts.isNew then
			pop(newLabel, Localization.t("reveal.new"))
		end
		pop(nameLabel, character.Name)
		local oddsText = Localization.t("reveal.odds", { odds = NumberFormatter.thousands(opts.odds) })
		if opts.luck and RarityConfig.ById[opts.rarity].Tier >= RarityConfig.ById.Divine.Tier then
			oddsText ..= "   🍀 " .. string.format("%.2fx", opts.luck)
		end
		pop(oddsLabel, oddsText)
		-- Variante: efeito somado por cima (composição)
		local variant = opts.variant and VariantConfig.ById[opts.variant]
		if variant and variant.Id ~= "Normal" then
			local ring = borrow(ringPool)
			ring.Color = rgb(variant.Color)
			ring.Transparency = 0.2
			ring.Size = Vector3.new(0.15, 9, 9)
			ring.CFrame = CFrame.new(0, 0.12, 0) * CFrame.Angles(0, 0, math.rad(90))
			ring.Parent = world
		end
		soundOnce("stinger", preset.Sounds[5])
	end

	function handle.Skip(_self: Handle)
		-- Pula direto para a pose final (impacto já resolvido)
		if not impactDone then
			impactDone = true
			spawnImpact(os.clock())
		end
		start = os.clock() - preset.Pose
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
	-- Personagem do jogador morreu/sumiu: fecha (nunca deixa nada preso)
	local player = Players.LocalPlayer
	table.insert(connections, player.CharacterRemoving:Connect(cleanup))

	-- Secreto: silêncio curto antes do primeiro som
	task.delay(preset.Silence or 0, function()
		if not handle.done then
			soundOnce("trigger", preset.Sounds[1])
		end
	end)
	if preset.Intro then
		intro.Text = Localization.t(preset.Intro)
	end

	table.insert(connections, RunService.RenderStepped:Connect(function()
		local ok, err = (pcall :: any)(function()
			local now = os.clock()
			local dt = math.min(now - last, 0.05)
			last = now
			local t = now - start

			-- Intro (MÍTICO / DIVINO / ???)
			if preset.Intro then
				local a = phase(t, 0.08, 0.3)
				local b = phase(t, preset.FallStart - 0.15, preset.FallStart + 0.1)
				intro.TextTransparency = 1 - a + b
				local s = intro:FindFirstChildOfClass("UIScale")
				if s then
					s.Scale = 1.4 - 0.4 * easeOut(a)
				end
			end
			-- Glitch (Secreto)
			for _, bar in glitches do
				local active = t < preset.FallStart and t > (preset.Silence or 0) and math.random() < 0.35
				bar.BackgroundTransparency = if active then 0.25 else 1
				bar.Position = UDim2.new(math.random() * 0.1 - 0.05, 0, math.random(), 0)
			end
			-- Céu
			local skyIn = phase(t, 0.1, preset.FallStart)
			for _, beam in beams do
				beam.Transparency = 1 - 0.65 * skyIn * (1 - phase(t, preset.Pose, preset.Duration))
			end
			if rift then
				rift.Transparency = 1 - 0.8 * skyIn * (1 - phase(t, preset.Impact, preset.Impact + 0.3))
				rift.Size = Vector3.new(14 * skyIn + 0.1, 26 * skyIn + 0.1, 1)
			end

			-- Queda
			local fall = phase(t, preset.FallStart, preset.Impact)
			local height = SKY_HEIGHT * (1 - easeIn(fall))
			if t < preset.Impact then
				model:PivotTo(CFrame.new(0, height, 0) * facing)
				CharacterModelFactory.lerpPose(model, "Idle", "Crouch", 0.55)
				glow.CFrame = CFrame.new(0, height + 3, -1)
				glow.Transparency = 0.55 + 0.35 * fall
				if fall > 0 then
					soundOnce("fall", preset.Sounds[2])
				end
				local speed = if fall > 0 and fall < 1 then 3 * fall * fall else 0
				for _, trail in trails do
					local offset = trail:GetAttribute("Offset") :: Vector3
					local length = 2 + speed * 14
					trail.Size = Vector3.new(0.25, length, 0.25)
					trail.CFrame = CFrame.new(offset.X, height + 4 + length / 2, offset.Z)
					trail.Transparency = if speed > 0 then 0.3 else 1
				end
				for _, line in speedLines do
					local active = fall > 0.15
					line.BackgroundTransparency = if active then 0.25 + math.random() * 0.4 else 1
					local angle = line:GetAttribute("Angle") :: number
					local radius = 0.35 + math.random() * 0.15
					line.Position = UDim2.fromScale(0.5 + math.sin(angle) * radius, 0.5 - math.cos(angle) * radius * 1.4)
				end
			elseif not impactDone then
				impactDone = true
				model:PivotTo(CFrame.new(0, 0, 0) * facing)
				CharacterModelFactory.pose(model, "Crouch")
				revealColors()
				glow.Transparency = 1
				for _, trail in trails do
					trail.Transparency = 1
				end
				for _, line in speedLines do
					line.BackgroundTransparency = 1
				end
				spawnImpact(now)
			end

			-- Levanta e pose final
			if t >= preset.Rise then
				local rise = easeOut(phase(t, preset.Rise, preset.Pose))
				CharacterModelFactory.lerpPose(model, "Crouch", "Confident", rise)
				model:PivotTo(CFrame.new(0, 0, 0) * facing * CFrame.Angles(0, math.sin(t * 0.8) * 0.12 * rise, 0))
			end
			if t >= preset.Pose then
				finishReveal()
				-- luz volta ao normal
				viewport.LightColor = viewport.LightColor:Lerp(Color3.fromRGB(255, 250, 240), dt * 2)
			end
			if impactDone then
				updateImpact(now, dt)
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

			-- Câmera do palco: olha para o céu, acompanha a queda, volta ao chão
			local lookY
			if t < preset.FallStart then
				lookY = LOOK_GROUND.Y + (SKY_HEIGHT * 0.75 - LOOK_GROUND.Y) * easeOut(phase(t, 0.15, preset.FallStart))
			elseif t < preset.Impact then
				lookY = math.max(LOOK_GROUND.Y, height * 0.75 + 2)
			else
				lookY = LOOK_GROUND.Y
			end
			local fovFall = RevealConfig.BaseFov + (preset.FovFall - RevealConfig.BaseFov) * fall
			local punch = if impactDone then -6 * (1 - phase(t, preset.Impact, preset.Impact + 0.35)) else 0
			local settle = if t > preset.Impact then phase(t, preset.Impact + 0.2, preset.Pose) else 0
			camera.FieldOfView = fovFall + (RevealConfig.BaseFov - fovFall) * settle + punch
			local camPos = if t > preset.Rise then CAMERA_POS:Lerp(Vector3.new(2.5, 3.6, 15), easeOut(phase(t, preset.Rise, preset.Continue))) else CAMERA_POS
			camera.CFrame = CFrame.lookAt(camPos, Vector3.new(0, lookY, 0)) * shake:Sample()
		end)
		if not ok then
			warn("[Roll Legends][HeroLanding] erro na cinemática:", err)
			cleanup()
		end
	end))

	return handle
end

return HeroLanding
