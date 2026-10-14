--!strict
--[[
	RevealController: apresenta o resultado do roll (só visual; o servidor já decidiu tudo).
	O TIPO de apresentação vem do RevealPlanner (RevealConfig), nunca de ifs por raridade:
	  Normal/Enhanced -> dado gira e quica, flash, personagem, raridade, nome, NOVO (1.2–1.8 s)
	  Compact         -> nada na tela (OCULTAR/AUTO): só a faixa de rolls recentes
	  HeroLanding     -> cinemática (Effects/HeroLanding, palco no viewport: Lendário/Mítico)
	                     Divino/Secreto (stage "World") -> Effects/JackpotReveal: palco no MUNDO,
	                     câmera real, Aura Full no impacto. OCULTAR não esconde Divino/Secreto.
	    RevealController.Play(resultado, { autoRoll = true }) -> plano (bloqueia até terminar,
	                                                              exceto o compacto)
	    RevealController.Busy()
	DEV (Studio): DevService "PlayReveal"/"PlayAllReveals"/"DivineLanding"/"SecretLanding" ->
	evento DevReveal -> toca SÓ a apresentação (sem RNG, inventário ou economia).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage.Shared
local RevealConfig = require(Shared.Config.RevealConfig)
local RarityConfig = require(Shared.Config.RarityConfig)
local CharacterConfig = require(Shared.Config.CharacterConfig)
local DiceConfig = require(Shared.Config.DiceConfig)
local RevealPlanner = require(Shared.Modules.RevealPlanner)
local DiceCore = require(Shared.Modules.DiceCore)
local CharacterModelFactory = require(Shared.Modules.CharacterModelFactory)
local CharacterAssetConfig = require(Shared.Config.CharacterAssetConfig)
local Localization = require(Shared.Localization.Localization)
local NumberFormatter = require(Shared.Modules.NumberFormatter)
local Net = require(Shared.Modules.Net)

local UI = script.Parent.Parent.UI
local UIKit = require(UI.UIKit)
local Theme = require(UI.UITheme)
local HeroLanding = require(script.Parent.Parent.Effects.HeroLanding)
local JackpotReveal = require(script.Parent.Parent.Effects.JackpotReveal)
local DataController = require(script.Parent.DataController)

local RevealController = {}

local planner = RevealPlanner.new(RevealConfig, RarityConfig, CharacterConfig)
-- "1 EM X" = chance BASE do personagem no Dice dele (DiceCore); Premium/legados: 0 (sem odds)
local diceCore = DiceCore.new(DiceConfig, CharacterConfig, RarityConfig, require(Shared.Config.RollConfig))
local busy = false
local current: any = nil

local cardGui: ScreenGui

function RevealController.Busy(): boolean
	return busy
end

local function settings(): any
	return DataController.Get("Settings") or {}
end

function RevealController.PlanFor(result: any, autoRoll: boolean?): RevealPlanner.Plan
	local s = settings()
	return planner:plan({
		rarity = result.Rarity,
		isNew = result.IsNew,
		hide = s.HideRollAnimation,
		reducedEffects = s.ReducedEffects,
		cameraShake = s.CameraShake,
		autoRoll = autoRoll,
		timesSeen = result.TimesSeen,
		mobile = UIKit.isMobile(),
	})
end

------------------------------------------------------------------------------------
-- Compacto (OCULTAR / AUTO): SEM texto na tela. O resultado já aparece na faixa de rolls
-- recentes (retrato real, CharacterPreview) e no inventário; um "Nome • RARIDADE" flutuante era
-- redundante e cobria a Mochila/filtros (com AUTO virava spam). Nada é desenhado aqui.

------------------------------------------------------------------------------------
-- Normal / Enhanced (1.2–1.8 s)

local function diceModel(): Model
	local dice = DiceConfig.ById[DataController.Get("EquippedDice") or DiceConfig.Default] or DiceConfig.ById[DiceConfig.Default]
	local model = Instance.new("Model")
	local cube = Instance.new("Part")
	cube.Size = Vector3.new(4, 4, 4)
	cube.Color = Color3.fromRGB(dice.ColorTheme.Body[1], dice.ColorTheme.Body[2], dice.ColorTheme.Body[3])
	cube.Material = Enum.Material.SmoothPlastic
	cube.Anchored = true
	cube.Parent = model
	-- Pontos (pips) nas faces
	local pipColor = Color3.fromRGB(dice.ColorTheme.Pips[1], dice.ColorTheme.Pips[2], dice.ColorTheme.Pips[3])
	for _, face in { Vector3.new(0, 0, -1), Vector3.new(0, 0, 1), Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0), Vector3.new(0, 1, 0), Vector3.new(0, -1, 0) } do
		local pip = Instance.new("Part")
		pip.Shape = Enum.PartType.Ball
		pip.Size = Vector3.new(0.9, 0.9, 0.9)
		pip.Color = pipColor
		pip.Anchored = true
		pip.CFrame = CFrame.new(face * 1.85)
		pip.Parent = model
	end
	model.PrimaryPart = cube
	return model
end

local function playCard(result: any, plan: RevealPlanner.Plan)
	local preset = RevealConfig.ByRarity[result.Rarity]
	local duration = plan.duration
	local color = UIKit.rarityColor(result.Rarity)
	local character = CharacterConfig.ById[result.CharacterId]
	local enhanced = plan.mode == "Enhanced"

	local root = UIKit.scaledRoot(cardGui, "Card")
	cardGui.Enabled = true
	local viewport = UIKit.new("ViewportFrame", {
		Size = UDim2.fromOffset(420, 420),
		Position = UDim2.fromScale(0.5, 0.45),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(170, 170, 185),
		LightDirection = Vector3.new(-0.3, -1, -0.5),
	}, root)
	local camera = Instance.new("Camera")
	camera.FieldOfView = 40
	camera.CFrame = CFrame.lookAt(Vector3.new(0, 4, 16), Vector3.new(0, 3.4, 0))
	camera.Parent = viewport
	viewport.CurrentCamera = camera
	-- Raios girando atrás (Enhanced / Rare)
	local rays: Frame? = nil
	if enhanced or preset.SmallEffect then
		local r = UIKit.new("Frame", {
			Size = UDim2.fromOffset(520, 520),
			Position = UDim2.fromScale(0.5, 0.45),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			ZIndex = 0,
		}, root)
		for i = 1, if enhanced then 12 else 6 do
			UIKit.new("Frame", {
				Size = UDim2.new(0, 22, 0.5, 0),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 1),
				Rotation = i * (360 / (if enhanced then 12 else 6)),
				BackgroundColor3 = color,
				BackgroundTransparency = 0.6,
				BorderSizePixel = 0,
				ZIndex = 0,
			}, r)
		end
		rays = r
	end
	local flash = UIKit.new("Frame", { Size = UDim2.fromScale(2, 2), Position = UDim2.fromScale(-0.5, -0.5), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, ZIndex = 8 }, root)
	local rarityLabel = UIKit.text(root, { text = Localization.t("rarity." .. result.Rarity), size = UDim2.fromOffset(600, 64), position = UDim2.fromScale(0.5, 0.15), anchor = Vector2.new(0.5, 0.5), color = color, stroke = 4, z = 9 })
	local nameLabel = UIKit.text(root, { text = character.Name, size = UDim2.fromOffset(600, 56), position = UDim2.fromScale(0.5, 0.75), anchor = Vector2.new(0.5, 0.5), stroke = 4, z = 9 })
	local newLabel = UIKit.text(root, { text = Localization.t("reveal.new"), size = UDim2.fromOffset(300, 40), position = UDim2.fromScale(0.5, 0.22), anchor = Vector2.new(0.5, 0.5), color = Theme.Colors.Warning, z = 9 })
	local soldLabel = UIKit.text(root, { text = Localization.t("reveal.autosold_for", { amount = NumberFormatter.money(result.SoldFor or 0) }), size = UDim2.fromOffset(420, 34), position = UDim2.fromScale(0.5, 0.82), anchor = Vector2.new(0.5, 0.5), color = Theme.Colors.Money, z = 9 })
	for _, label in { rarityLabel, nameLabel, newLabel, soldLabel } do
		label.TextTransparency = 1
	end

	local dice = diceModel()
	dice.Parent = viewport
	local figure = CharacterModelFactory.build(result.CharacterId, { variant = result.Variant, aura = false, vfx = CharacterAssetConfig.VFXModes.Reveal, pose = "Reveal" })
	figure:PivotTo(CFrame.new(0, -60, 0))
	figure.Parent = viewport

	local revealAt = duration * 0.42
	local revealed = false
	local start = os.clock()
	local done = false
	local connection
	connection = RunService.RenderStepped:Connect(function()
		local t = os.clock() - start
		if t < revealAt then
			-- dado gira e quica
			local bounce = math.abs(math.sin(t / revealAt * math.pi * 2)) * 2.2 * (1 - t / revealAt)
			dice:PivotTo(CFrame.new(0, 3.4 + bounce, 0) * CFrame.Angles(t * 9, t * 11, t * 5))
		elseif not revealed then
			revealed = true
			dice:PivotTo(CFrame.new(0, -60, 0))
			figure:PivotTo(CFrame.new(0, 0, 0) * CFrame.Angles(0, math.pi, 0))
			flash.BackgroundTransparency = 1 - preset.Flash
			TweenService:Create(flash, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
			rarityLabel.TextTransparency = 0
			nameLabel.TextTransparency = 0
			newLabel.TextTransparency = if result.IsNew then 0 else 1
			soldLabel.TextTransparency = if result.AutoSold then 0 else 1
			UIKit.sound(if enhanced then "RevealStinger" else "Reward", nil, 1 + RarityConfig.ById[result.Rarity].Tier * 0.04)
		else
			figure:PivotTo(CFrame.new(0, 0, 0) * CFrame.Angles(0, math.pi + (t - revealAt) * 1.2, 0))
		end
		if rays then
			rays.Rotation = t * 40
		end
		if t >= duration and not done then
			done = true
		end
	end)
	while not done do
		task.wait()
	end
	connection:Disconnect()
	root:Destroy()
	cardGui.Enabled = false
end

------------------------------------------------------------------------------------

function RevealController.Play(result: any, context: { autoRoll: boolean? }?): RevealPlanner.Plan
	local plan = RevealController.PlanFor(result, context and context.autoRoll)
	if plan.mode == "Compact" then
		return plan -- só a faixa de rolls recentes (sem toast de nome/raridade)
	end
	busy = true
	local ok, err = pcall(function()
		if plan.mode == "HeroLanding" and plan.cinematic then
			local playFn = if plan.stage == "World" then JackpotReveal.play else HeroLanding.play
			local handle = (playFn :: any)({
				characterId = result.CharacterId,
				rarity = result.Rarity,
				variant = result.Variant,
				cinematic = plan.cinematic,
				quality = plan.quality,
				shake = plan.shake,
				isNew = result.IsNew == true,
				odds = result.Odds or diceCore:odds(result.CharacterId),
				luck = result.Luck,
				canSkip = plan.canSkip,
				autoClose = plan.autoClose,
				mobile = UIKit.isMobile(),
			})
			current = handle
			-- Segurança: nunca espera mais que o dobro da duração + tempo do botão
			local deadline = os.clock() + RevealConfig.Cinematics[plan.cinematic].Duration * 2 + 30
			while not handle.done and os.clock() < deadline do
				task.wait(0.05)
			end
			if not handle.done then
				handle:Stop()
			end
			current = nil
		else
			playCard(result, plan)
		end
	end)
	busy = false
	if not ok then
		warn("[Roll Legends][Reveal] erro:", err)
		if current then
			current:Stop()
			current = nil
		end
	end
	return plan
end

-- Fecha o que estiver tocando (teleporte/janela/morte)
function RevealController.Cancel()
	if current then
		current:Stop()
	end
end

local function devPlay(payload: any)
	if not RunService:IsStudio() then
		return
	end
	local function one(id: string, isNew: boolean)
		local character = CharacterConfig.ById[id]
		RevealController.Play({
			CharacterId = id,
			Rarity = character.Rarity,
			Variant = payload.Variant or "Normal",
			IsNew = isNew,
			TimesSeen = 0,
			Odds = diceCore:odds(id),
			Luck = 1,
		})
	end
	if payload.All then
		for _, rarity in { "Legendary", "Mythic", "Divine", "Secret" } do
			for _, character in CharacterConfig.List do
				if character.Rarity == rarity then
					one(character.Id, true)
					break
				end
			end
		end
	elseif payload.CharacterId and CharacterConfig.ById[payload.CharacterId] then
		-- Repeat: toca N vezes seguidas (testar timing/câmera no Studio)
		for _ = 1, math.clamp(tonumber(payload.Repeat) or 1, 1, 10) do
			one(payload.CharacterId, payload.IsNew ~= false)
		end
	end
end

function RevealController.Start()
	cardGui = UIKit.screen("Reveal", 150)
	cardGui.IgnoreGuiInset = true
	cardGui.Enabled = false
	Net.on("DevReveal", function(payload)
		task.spawn(devPlay, payload)
	end)
end

return RevealController
