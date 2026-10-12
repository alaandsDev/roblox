--!strict
--[[
	Constrói e atualiza as bases dos jogadores (geometria em BaseConfig/BaseLayout).

	Base01 (Model)                 atributos: BaseId, OwnerUserId   tag: PlayerBase
	├── OwnerSign                  placa na entrada (avatar + nome / "BASE LIVRE")
	├── Entrance                   arco da entrada
	├── PlayerSpawn                SpawnLocation na entrada (dono nasce aqui, olhando para dentro)
	├── Floors
	│   └── Floor01                atributos: FloorId, UnlockRebirth
	│       ├── Platform
	│       ├── SideA  -> Slot01..Slot04
	│       ├── SideB  -> Slot05..Slot08
	│       ├── Structure          paredes/grades/pilares deste andar
	│       └── Ramp               (só se existir o andar de cima)
	├── Roof                       moldura no topo do andar mais alto (mostra a altura)
	├── MoneyCollector             tag: Interactable
	├── UpgradeArea                tag: Interactable
	└── RuntimeCharacters          personagens do dono (fases futuras)

	Slot (Model): Pedestal, Rim, CharacterPoint (onde o personagem fica, já orientado)
	atributos: SlotId, FloorId, Side ("A"/"B"), SlotIndexOnSide, Unlocked
	tags: CharacterSlot (+ LockedCharacterSlot quando bloqueado)

	Andar BLOQUEADO = não existe fisicamente. Slot BLOQUEADO = existe, com visual de cadeado.
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local BaseConfig = require(Shared.Config.BaseConfig)
local MapConfig = require(Shared.Config.MapConfig)
local BaseLayout = require(Shared.Modules.BaseLayout)
local MapLayout = require(Shared.Modules.MapLayout)
local Localization = require(Shared.Localization.Localization)

local Build = require(script.Parent.Build)
local Decor = require(script.Parent.Decor)

local rgb = Build.rgb
local baseLayout = BaseLayout.new(BaseConfig)
local mapLayout = MapLayout.new(MapConfig, BaseConfig)

local BaseBuilder = {}

local W, D = BaseConfig.Width, BaseConfig.Depth
local LOCKED_COLOR = rgb(92, 92, 104)
local ROOF_HEIGHT = 12

export type OwnerInfo = { displayName: string, userName: string, thumbnail: string? }
export type State = { unlockedFloors: number, unlockedSlots: { [number]: boolean } }
-- Progressão usada para mostrar o requisito de cada slot/andar
export type ProgressionLike = {
	slotUnlockRebirth: (self: any, slotId: number) -> number?,
	floorUnlockRebirth: (self: any, floor: number) -> number?,
}

function BaseBuilder.baseCFrame(baseId: number): CFrame
	local p = mapLayout:base(baseId)
	return CFrame.lookAt(Vector3.new(p.x, 0, p.z), Vector3.new(p.x + p.faceX, 0, p.z + p.faceZ))
end

local function themeOf(base: Model): Color3
	local id = base:GetAttribute("BaseId") :: number
	return Build.theme(BaseConfig.Themes[id] or BaseConfig.Themes[1])
end

local function lighten(color: Color3, amount: number): Color3
	return color:Lerp(Color3.new(1, 1, 1), amount)
end

------------------------------------------------------------------------------------
-- Slots

local function lockBillboard(pedestal: BasePart): BillboardGui
	local gui = Instance.new("BillboardGui")
	gui.Name = "LockInfo"
	gui.Size = UDim2.fromOffset(120, 48)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 3.2, 0)
	gui.MaxDistance = 70
	gui.LightInfluence = 0
	gui.Parent = pedestal

	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.fromScale(1, 0.55)
	icon.BackgroundTransparency = 1
	icon.Text = "🔒"
	icon.TextScaled = true
	icon.Parent = gui

	local requirement = Instance.new("TextLabel")
	requirement.Name = "Requirement"
	requirement.Position = UDim2.fromScale(0, 0.58)
	requirement.Size = UDim2.fromScale(1, 0.4)
	requirement.BackgroundTransparency = 1
	requirement.Font = Enum.Font.FredokaOne
	requirement.TextScaled = true
	requirement.TextColor3 = Color3.new(1, 1, 1)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Parent = requirement
	requirement.Parent = gui
	return gui
end

local function buildSlot(parent: Instance, origin: CFrame, slotId: number): Model
	local info = baseLayout:slotInfo(slotId)
	local p = baseLayout:slotPosition(slotId)
	local slot = Build.model(baseLayout:slotName(slotId), parent)
	slot:SetAttribute("SlotId", slotId)
	slot:SetAttribute("FloorId", info.floor)
	slot:SetAttribute("Side", info.side)
	slot:SetAttribute("SlotIndexOnSide", info.index)
	slot:SetAttribute("Unlocked", false)
	Build.tag(slot, "CharacterSlot")

	local floorY = baseLayout:floorY(info.floor)
	local ground = origin * CFrame.new(p.x, floorY, p.z)
	-- Pedestal blocky (topo = floorY + PedestalHeight, onde o personagem R6 fica) + rodapé na cor do tema
	local size = BaseConfig.PedestalSize
	local pedestal = Build.part(Vector3.new(size, BaseConfig.PedestalHeight, size), ground * CFrame.new(0, BaseConfig.PedestalHeight / 2, 0), {
		Name = "Pedestal",
		Parent = slot,
	})
	local rim = Build.part(Vector3.new(size + 0.8, 0.35, size + 0.8), ground * CFrame.new(0, 0.175, 0), {
		Name = "Rim",
		Parent = slot,
	})
	Build.decor(rim)

	local localTop = Vector3.new(p.x, p.y, p.z)
	local point = Build.part(
		Vector3.new(1, 1, 1),
		origin * CFrame.lookAt(localTop, localTop + Vector3.new(p.lookX, 0, p.lookZ)),
		{ Name = "CharacterPoint", Transparency = 1, Parent = slot }
	)
	Build.decor(point)
	slot.PrimaryPart = pedestal
	lockBillboard(pedestal)
	return slot
end

local function styleSlot(slot: Model, unlocked: boolean, theme: Color3, progression: ProgressionLike)
	local pedestal = slot:FindFirstChild("Pedestal") :: BasePart
	local rim = slot:FindFirstChild("Rim") :: BasePart
	local gui = pedestal:FindFirstChild("LockInfo") :: BillboardGui
	slot:SetAttribute("Unlocked", unlocked)
	if unlocked then
		pedestal.Color = lighten(theme, 0.55)
		pedestal.Material = Enum.Material.SmoothPlastic
		rim.Color = theme
		rim.Transparency = 0
		gui.Enabled = false
		CollectionService:RemoveTag(slot, "LockedCharacterSlot")
	else
		pedestal.Color = LOCKED_COLOR
		pedestal.Material = Enum.Material.Slate
		rim.Transparency = 1
		gui.Enabled = true
		local rebirth = progression:slotUnlockRebirth(slot:GetAttribute("SlotId") :: number)
		local requirement = gui:FindFirstChild("Requirement") :: TextLabel
		requirement.Text = if rebirth
			then Localization.t("base.slot_requires_rebirth", { rebirth = rebirth })
			else Localization.t("base.slot_locked")
		CollectionService:AddTag(slot, "LockedCharacterSlot")
	end
end

------------------------------------------------------------------------------------
-- Andares

local function rail(parent: Instance, size: Vector3, cf: CFrame, color: Color3)
	Build.part(size, cf, { Name = "Rail", Color = color, Parent = parent })
	-- Tampo mais largo em cima da grade (leitura "chunky")
	local cap = Vector3.new(if size.X > size.Z then size.X else size.X + 0.5, 0.5, if size.Z > size.X then size.Z else size.Z + 0.5)
	Build.decor(Build.part(cap, cf * CFrame.new(0, size.Y / 2 + 0.25, 0), { Name = "RailCap", Color = color:Lerp(Color3.new(0, 0, 0), 0.2), Parent = parent }))
end

local function buildFloor(base: Model, origin: CFrame, floor: number, progression: ProgressionLike): Model
	local floors = base:FindFirstChild("Floors") :: Folder
	local theme = themeOf(base)
	local model = Build.model(baseLayout:floorName(floor), floors)
	model:SetAttribute("FloorId", floor)
	model:SetAttribute("UnlockRebirth", progression:floorUnlockRebirth(floor) or -1)

	local y = baseLayout:floorY(floor) -- topo do piso
	local structure = Build.folder("Structure", model)
	local platformColor = rgb(245, 240, 232)

	if floor == 1 then
		Build.part(Vector3.new(W, 1, D), origin * CFrame.new(0, y - 0.5, 0), {
			Name = "Platform",
			Color = platformColor,
			Material = Enum.Material.WoodPlanks,
			Parent = model,
		})
		-- Paredes: fundo mais alto, laterais baixas, frente aberta (entrada)
		Build.part(Vector3.new(W, BaseConfig.BackWallHeight, 1), origin * CFrame.new(0, y + BaseConfig.BackWallHeight / 2, D / 2 - 0.5), {
			Name = "BackWall",
			Color = lighten(theme, 0.25),
			Parent = structure,
		})
		Build.decor(Build.part(Vector3.new(W - 2, 0.8, 0.3), origin * CFrame.new(0, y + BaseConfig.BackWallHeight - 1, D / 2 - 1.15), {
			Name = "BackStripe",
			Color = theme,
			Material = Enum.Material.Neon,
			Parent = structure,
		}))
		for _, side in { -1, 1 } do
			Build.part(Vector3.new(1, BaseConfig.WallHeight, D), origin * CFrame.new(side * (W / 2 - 0.5), y + BaseConfig.WallHeight / 2, 0), {
				Name = "SideWall",
				Color = lighten(theme, 0.4),
				Parent = structure,
			})
			Decor.flag(structure, origin * CFrame.new(side * (W / 2 - 1.5), y + BaseConfig.BackWallHeight, D / 2 - 1), 8, theme)
			-- Tampo grosso da parede lateral
			Build.decor(Build.part(Vector3.new(1.8, 0.6, D), origin * CFrame.new(side * (W / 2 - 0.5), y + BaseConfig.WallHeight + 0.3, 0), {
				Name = "WallCap",
				Color = theme,
				Parent = structure,
			}))
			-- Pilastras chunky por fora da parede (frente, meio e fundo)
			for _, z in { -D / 2 + 1.2, 0, D / 2 - 1.2 } do
				Decor.pillar(structure, origin * CFrame.new(side * (W / 2 + 0.4), y - 1, z), 2, BaseConfig.WallHeight + 2.5, lighten(theme, 0.55), theme)
			end
			-- Mureta baixa na frente, dos lados da entrada (a entrada continua aberta, sem porta)
			local e = BaseConfig.Entrance
			local from, to = e.halfWidth + 2, W / 2 - 1
			Build.part(Vector3.new(to - from, BaseConfig.FrontWallHeight, 1.2), origin * CFrame.new(side * (from + to) / 2, y + BaseConfig.FrontWallHeight / 2, -D / 2 + 0.6), {
				Name = "FrontWall",
				Color = lighten(theme, 0.4),
				Parent = structure,
			})
			Build.decor(Build.part(Vector3.new(to - from + 0.6, 0.5, 1.8), origin * CFrame.new(side * (from + to) / 2, y + BaseConfig.FrontWallHeight + 0.25, -D / 2 + 0.6), {
				Name = "WallCap",
				Color = theme,
				Parent = structure,
			}))
		end
		Build.decor(Build.part(Vector3.new(W, 0.6, 1.8), origin * CFrame.new(0, y + BaseConfig.BackWallHeight + 0.3, D / 2 - 0.5), {
			Name = "WallCap",
			Color = theme,
			Parent = structure,
		}))
	else
		-- Piso superior com o "poço" por onde chega a rampa do andar de baixo
		local well = baseLayout:rampRect(floor - 1)
		local wellOnPlus = well.minX > 0
		local mainMinX = if wellOnPlus then -W / 2 else well.maxX
		local mainMaxX = if wellOnPlus then well.minX else W / 2
		Build.part(Vector3.new(mainMaxX - mainMinX, 1, D), origin * CFrame.new((mainMinX + mainMaxX) / 2, y - 0.5, 0), {
			Name = "Platform",
			Color = platformColor,
			Material = Enum.Material.WoodPlanks,
			Parent = model,
		})
		local landingDepth = D / 2 - well.maxZ
		Build.part(Vector3.new(well.maxX - well.minX, 1, landingDepth), origin * CFrame.new((well.minX + well.maxX) / 2, y - 0.5, well.maxZ + landingDepth / 2), {
			Name = "Landing",
			Color = platformColor,
			Material = Enum.Material.WoodPlanks,
			Parent = model,
		})
		-- Grades em volta e na borda do poço
		local railColor = lighten(theme, 0.3)
		rail(structure, Vector3.new(W, 2.5, 0.6), origin * CFrame.new(0, y + 1.25, -D / 2 + 0.3), railColor)
		rail(structure, Vector3.new(W, 2.5, 0.6), origin * CFrame.new(0, y + 1.25, D / 2 - 0.3), railColor)
		for _, side in { -1, 1 } do
			rail(structure, Vector3.new(0.6, 2.5, D), origin * CFrame.new(side * (W / 2 - 0.3), y + 1.25, 0), railColor)
		end
		local innerX = if wellOnPlus then well.minX else well.maxX
		local wellLength = well.maxZ + D / 2
		rail(structure, Vector3.new(0.6, 2.5, wellLength), origin * CFrame.new(innerX, y + 1.25, -D / 2 + wellLength / 2), railColor)
		-- Pilares de sustentação vindos do andar de baixo
		local below = baseLayout:floorY(floor - 1)
		for _, sx in { -1, 1 } do
			for _, sz in { -1, 1 } do
				Build.part(Vector3.new(2.4, y - 1 - below, 2.4), origin * CFrame.new(sx * (W / 2 - 1.5), (below + y - 1) / 2, sz * (D / 2 - 1.5)), {
					Name = "Pillar",
					Color = rgb(240, 238, 245),
					Parent = structure,
				})
				Build.decor(Build.part(Vector3.new(3.2, 0.8, 3.2), origin * CFrame.new(sx * (W / 2 - 1.5), y - 1.4, sz * (D / 2 - 1.5)), {
					Name = "PillarCap",
					Color = theme,
					Parent = structure,
				}))
			end
		end
	end

	-- Corredor (tapete) no meio
	Build.decor(Build.part(Vector3.new(BaseConfig.CorridorHalfWidth * 2 - 6, 0.1, D - 4), origin * CFrame.new(0, y + 0.05, 0), {
		Name = "Carpet",
		Color = lighten(theme, 0.15),
		Material = Enum.Material.Fabric,
		Parent = structure,
	}))

	local sideA = Build.folder("SideA", model)
	local sideB = Build.folder("SideB", model)
	for _, slotId in baseLayout:slotsForFloor(floor) do
		local info = baseLayout:slotInfo(slotId)
		buildSlot(if info.side == "A" then sideA else sideB, origin, slotId)
	end
	return model
end

local function buildRamp(floorModel: Model, origin: CFrame, floor: number, theme: Color3)
	local old = floorModel:FindFirstChild("Ramp")
	if old then
		old:Destroy()
	end
	local r = baseLayout:rampRect(floor)
	local rise = BaseConfig.FloorHeight
	local length = r.maxZ - r.minZ
	local y = baseLayout:floorY(floor)
	local ramp = Build.model("Ramp", floorModel)
	-- A parte alta da cunha (local +Z) fica no fundo: sobe da frente para o fundo
	Build.wedge(Vector3.new(r.maxX - r.minX, rise, length), origin * CFrame.new((r.minX + r.maxX) / 2, y + rise / 2, (r.minZ + r.maxZ) / 2), {
		Name = "Slope",
		Color = lighten(theme, 0.5),
		Material = Enum.Material.WoodPlanks,
		Parent = ramp,
	})
end

local function buildRoof(base: Model, origin: CFrame, topFloor: number)
	local old = base:FindFirstChild("Roof")
	if old then
		old:Destroy()
	end
	local theme = themeOf(base)
	local roof = Build.model("Roof", base)
	local y = baseLayout:floorY(topFloor)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			Build.decor(Build.part(Vector3.new(1.8, ROOF_HEIGHT, 1.8), origin * CFrame.new(sx * (W / 2 - 1.5), y + ROOF_HEIGHT / 2, sz * (D / 2 - 1.5)), {
				Name = "RoofPost",
				Color = rgb(240, 238, 245),
				Parent = roof,
			}))
		end
	end
	local top = y + ROOF_HEIGHT
	for _, sz in { -1, 1 } do
		Build.decor(Build.part(Vector3.new(W - 1, 1.6, 1.8), origin * CFrame.new(0, top, sz * (D / 2 - 1.5)), {
			Name = "RoofBeam",
			Color = theme,
			Parent = roof,
		}))
	end
	for _, sx in { -1, 1 } do
		Build.decor(Build.part(Vector3.new(1.8, 1.6, D - 1), origin * CFrame.new(sx * (W / 2 - 1.5), top, 0), {
			Name = "RoofBeam",
			Color = theme,
			Parent = roof,
		}))
	end
end

------------------------------------------------------------------------------------
-- Placa do dono

local function buildOwnerSign(base: Model, origin: CFrame)
	local e = BaseConfig.Entrance
	local sign = Build.model("OwnerSign", base)
	local board = Build.part(Vector3.new(e.halfWidth * 2 + 4, 6, 1), origin * CFrame.new(0, 1 + e.height + 3, -D / 2 + 0.5), {
		Name = "Board",
		Color = rgb(40, 35, 60),
		Parent = sign,
	})
	sign.PrimaryPart = board
	-- Moldura blocky atrás da placa (escura por dentro, dourada por fora) + ameias em cima
	local frameCf = origin * CFrame.new(0, 1 + e.height + 3, -D / 2 + 1.2)
	Build.decor(Build.part(Vector3.new(e.halfWidth * 2 + 6, 7.6, 0.6), frameCf, { Name = "SignFrame", Color = rgb(255, 200, 70), Parent = sign }))
	for i = -2, 2 do
		Build.decor(Build.part(Vector3.new(2, 1.2, 1.2), frameCf * CFrame.new(i * (e.halfWidth + 1) / 2, 4.4, 0), { Name = "SignCrenel", Color = rgb(255, 200, 70), Parent = sign }))
	end

	local gui = Instance.new("SurfaceGui")
	gui.Name = "OwnerDisplay"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.LightInfluence = 0
	gui.MaxDistance = 220
	gui.Parent = board

	local avatar = Instance.new("ImageLabel")
	avatar.Name = "Avatar"
	avatar.AnchorPoint = Vector2.new(0, 0.5)
	avatar.Position = UDim2.new(0, 12, 0.5, 0)
	avatar.Size = UDim2.new(0, 150, 0, 150)
	avatar.BackgroundColor3 = rgb(255, 255, 255)
	avatar.Visible = false
	avatar.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = avatar

	local function label(name: string, y: number, h: number, color: Color3): TextLabel
		local l = Instance.new("TextLabel")
		l.Name = name
		l.Position = UDim2.new(0, 175, y, 0)
		l.Size = UDim2.new(1, -190, h, 0)
		l.BackgroundTransparency = 1
		l.Font = Enum.Font.FredokaOne
		l.TextScaled = true
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.TextColor3 = color
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 3
		stroke.Color = rgb(20, 15, 30)
		stroke.Parent = l
		l.Parent = gui
		return l
	end
	label("Title", 0.08, 0.25, rgb(255, 220, 90))
	label("PlayerName", 0.33, 0.42, rgb(255, 255, 255))
	label("Handle", 0.76, 0.18, rgb(200, 200, 220))
end

function BaseBuilder.setOwner(base: Model, owner: OwnerInfo?)
	local sign = base:FindFirstChild("OwnerSign")
	local board = sign and sign:FindFirstChild("Board")
	local gui = board and board:FindFirstChild("OwnerDisplay") :: SurfaceGui?
	if not gui then
		return
	end
	local avatar = gui:FindFirstChild("Avatar") :: ImageLabel
	local title = gui:FindFirstChild("Title") :: TextLabel
	local name = gui:FindFirstChild("PlayerName") :: TextLabel
	local handle = gui:FindFirstChild("Handle") :: TextLabel
	if owner then
		title.Text = Localization.t("base.owner_title")
		name.Text = owner.displayName
		handle.Text = "@" .. owner.userName
		avatar.Image = owner.thumbnail or ""
		avatar.Visible = owner.thumbnail ~= nil
		name.Position = UDim2.new(0, 175, 0.33, 0)
	else
		title.Text = ""
		name.Text = Localization.t("base.free")
		handle.Text = ""
		avatar.Image = ""
		avatar.Visible = false
	end
end

------------------------------------------------------------------------------------

local function pad(base: Model, name: string, spot: any, color: Color3, labelKey: string): Part
	local origin = BaseBuilder.baseCFrame(base:GetAttribute("BaseId") :: number)
	local part = Build.part(Vector3.new(spot.width, 0.4, spot.depth), origin * CFrame.new(spot.x, 1.2, spot.z), {
		Name = name,
		Color = color,
		Parent = base,
	})
	part.CanCollide = false
	-- Moldura baixa em volta do pad (enfeite, sem colisão)
	Decor.chunkyBorder(base, origin * CFrame.new(spot.x, 1, spot.z), spot.width, spot.depth, 0.8, 0.6, color:Lerp(Color3.new(0, 0, 0), 0.35)).Name = name .. "Frame"
	part:SetAttribute("InteractId", name)
	Build.tag(part, "Interactable")

	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = UDim2.fromOffset(150, 50)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
	gui.MaxDistance = 80
	gui.LightInfluence = 0
	gui.Parent = part
	local text = Instance.new("TextLabel")
	text.Name = "Text"
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.FredokaOne
	text.TextScaled = true
	text.TextColor3 = Color3.new(1, 1, 1)
	text.Text = Localization.t(labelKey)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Parent = text
	text.Parent = gui
	Build.prompt(part, name, Localization.t(labelKey), Localization.t(if name == "MoneyCollector" then "prompt.collect" else "prompt.open"))
	return part
end

-- Constrói a base com o Floor01 (sem estado de progressão aplicado)
function BaseBuilder.build(baseId: number, parent: Instance, progression: ProgressionLike): Model
	local origin = BaseBuilder.baseCFrame(baseId)
	local base = Build.model(BaseLayout.baseName(baseId))
	base:SetAttribute("BaseId", baseId)
	base:SetAttribute("OwnerUserId", 0)
	base.WorldPivot = origin
	Build.tag(base, "PlayerBase")

	Build.folder("Floors", base)
	buildFloor(base, origin, 1, progression)

	-- Entrada: arco + placa do dono em cima
	local e = BaseConfig.Entrance
	local entrance = Build.model("Entrance", base)
	local theme = themeOf(base)
	local gold = rgb(255, 200, 70)
	for _, side in { -1, 1 } do
		local foot = origin * CFrame.new(side * e.halfWidth, 1, -D / 2 + 0.5)
		Build.part(Vector3.new(3.2, e.height, 3.2), foot * CFrame.new(0, e.height / 2, 0), {
			Name = "ArchPillar",
			Color = rgb(250, 248, 255),
			Parent = entrance,
		})
		-- Base, faixas na cor do tema e capitel dourado (enfeites)
		Build.decor(Build.part(Vector3.new(4.4, 1.4, 4.4), foot * CFrame.new(0, 0.7, 0), { Name = "ArchBase", Color = theme, Parent = entrance }))
		Build.decor(Build.part(Vector3.new(3.6, 0.6, 3.6), foot * CFrame.new(0, e.height * 0.55, 0), { Name = "ArchBand", Color = theme, Parent = entrance }))
		Build.decor(Build.part(Vector3.new(4.4, 1, 4.4), foot * CFrame.new(0, e.height - 0.5, 0), { Name = "ArchCap", Color = gold, Parent = entrance }))
		Decor.lamp(entrance, foot * CFrame.new(side * 3.4, -1, -2.6), lighten(theme, 0.3))
	end
	-- Degrau de fora (grama -> 0.5 -> piso) e tapete de boas-vindas com setas para dentro
	local stoneLight = rgb(205, 200, 215)
	Build.part(Vector3.new(e.halfWidth * 2 + 6, 0.6, 4), origin * CFrame.new(0, 0.3, -D / 2 - 2), {
		Name = "EntranceStep",
		Color = stoneLight,
		Parent = entrance,
	})
	local matCf = origin * CFrame.new(0, 1.12, -D / 2 + 3.5)
	Build.decor(Build.part(Vector3.new(e.halfWidth * 2 - 6, 0.12, 5), matCf, { Name = "EntranceMat", Color = theme:Lerp(Color3.new(0, 0, 0), 0.25), Parent = entrance }))
	for i = 0, 1 do
		for _, side in { -1, 1 } do
			-- ">" apontando para dentro (+Z local)
			Build.decor(Build.part(Vector3.new(0.6, 0.1, 2.6), matCf * CFrame.new(side * 6 + side * 0.8, 0.1, -1 + i * 2.2) * CFrame.Angles(0, side * math.rad(-40), 0), {
				Name = "MatArrow",
				Color = gold,
				Parent = entrance,
			}))
		end
	end

	-- Fundação: rodapé de pedra mais largo que o piso (a base parece "plantada" no chão)
	local foundation = Build.model("Foundation", base)
	Build.part(Vector3.new(W + 3, 0.5, D + 3), origin * CFrame.new(0, 0.25, 0), {
		Name = "Skirt",
		Color = rgb(150, 145, 165),
		Parent = foundation,
	})
	Build.decor(Build.part(Vector3.new(W + 0.6, 0.35, D + 0.6), origin * CFrame.new(0, 0.62, 0), {
		Name = "SkirtTrim",
		Color = theme:Lerp(Color3.new(0, 0, 0), 0.15),
		Parent = foundation,
	}))
	buildOwnerSign(base, origin)

	-- PlayerSpawn é um SpawnLocation: o Roblox já faz o dono nascer aqui (player.RespawnLocation).
	-- Neutral = false: jogadores sem RespawnLocation (os outros) nunca nascem aqui.
	-- O topo fica no nível do piso; virado (LookVector) para dentro da base (local +Z).
	local s = BaseConfig.Spawn
	local spawnLocation = Instance.new("SpawnLocation")
	spawnLocation.Name = "PlayerSpawn"
	spawnLocation.Anchored = true
	spawnLocation.Size = Vector3.new(s.size, 0.2, s.size)
	spawnLocation.CFrame = origin * CFrame.new(s.x, BaseConfig.PlatformThickness + 0.1, s.z) * CFrame.Angles(0, math.pi, 0)
	spawnLocation.Transparency = 1
	spawnLocation.CanCollide = false
	spawnLocation.CanQuery = false
	spawnLocation.CanTouch = false
	spawnLocation.Neutral = false
	spawnLocation.AllowTeamChangeOnTouch = false
	spawnLocation.Duration = 0
	local spawnDecal = spawnLocation:FindFirstChildOfClass("Decal")
	if spawnDecal then
		spawnDecal:Destroy()
	end
	spawnLocation.Parent = base
	Build.tag(spawnLocation, "TeleportPoint")

	pad(base, "MoneyCollector", BaseConfig.Collector, rgb(80, 230, 110), "base.collector")
	pad(base, "UpgradeArea", BaseConfig.UpgradeArea, rgb(80, 170, 255), "base.upgrades")
	Build.folder("RuntimeCharacters", base)

	BaseBuilder.setOwner(base, nil)
	base.Parent = parent
	return base
end

-- Aplica andares e slots liberados. Retorna (andares antes, andares depois).
function BaseBuilder.applyState(base: Model, state: State, progression: ProgressionLike): (number, number)
	local baseId = base:GetAttribute("BaseId") :: number
	local origin = BaseBuilder.baseCFrame(baseId)
	local floors = base:FindFirstChild("Floors") :: Folder
	local theme = themeOf(base)
	local target = math.clamp(state.unlockedFloors, 1, BaseConfig.MaxFloors)

	local before = 0
	for floor = 1, BaseConfig.MaxFloors do
		if floors:FindFirstChild(baseLayout:floorName(floor)) then
			before = floor
		end
	end

	for floor = 2, BaseConfig.MaxFloors do
		local existing = floors:FindFirstChild(baseLayout:floorName(floor))
		if floor <= target and not existing then
			buildFloor(base, origin, floor, progression)
		elseif floor > target and existing then
			existing:Destroy()
		end
	end

	for floor = 1, target do
		local model = floors:FindFirstChild(baseLayout:floorName(floor)) :: Model
		if floor < target then
			buildRamp(model, origin, floor, theme)
		else
			local ramp = model:FindFirstChild("Ramp")
			if ramp then
				ramp:Destroy()
			end
		end
		for _, sideName in { "SideA", "SideB" } do
			for _, slot in (model:FindFirstChild(sideName) :: Folder):GetChildren() do
				if slot:IsA("Model") then
					local slotId = slot:GetAttribute("SlotId") :: number
					styleSlot(slot, state.unlockedSlots[slotId] == true, theme, progression)
				end
			end
		end
	end
	buildRoof(base, origin, target)
	return before, target
end

function BaseBuilder.clearRuntime(base: Model)
	local runtime = base:FindFirstChild("RuntimeCharacters")
	if runtime then
		runtime:ClearAllChildren()
	end
end

-- CFrame do ponto de nascimento NO PISO (centro da entrada, olhando para dentro da base)
function BaseBuilder.spawnCFrame(base: Model): CFrame
	local spawn = base:FindFirstChild("PlayerSpawn") :: BasePart
	return spawn.CFrame * CFrame.new(0, spawn.Size.Y / 2, 0)
end

function BaseBuilder.spawnLocation(base: Model): SpawnLocation?
	local spawn = base:FindFirstChild("PlayerSpawn")
	return if spawn and spawn:IsA("SpawnLocation") then spawn else nil
end

-- Efeito simples quando um andar novo aparece (gancho para a fase de Rebirth)
function BaseBuilder.playFloorUnlockedEffect(base: Model, floor: number)
	local model = (base:FindFirstChild("Floors") :: Folder):FindFirstChild(baseLayout:floorName(floor))
	local platform = model and model:FindFirstChild("Platform") :: BasePart?
	if not platform then
		return
	end
	local burst = Instance.new("ParticleEmitter")
	burst.Color = ColorSequence.new(rgb(255, 230, 120), themeOf(base))
	burst.LightEmission = 1
	burst.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 0) })
	burst.Lifetime = NumberRange.new(1, 1.6)
	burst.Speed = NumberRange.new(8, 16)
	burst.SpreadAngle = Vector2.new(60, 60)
	burst.EmissionDirection = Enum.NormalId.Top
	burst.Enabled = false
	burst.Parent = platform
	-- Efeito é cosmético: uma falha aqui nunca pode interromper a progressão da base
	pcall(function()
		burst:Emit(80)
	end)
	task.delay(3, burst.Destroy, burst)
end

-- Boneco do tamanho aproximado de um personagem (só para testes de escala no Studio)
function BaseBuilder.dummy(color: Color3): Model
	local dummy = Build.model("ScaleDummy")
	local function piece(size: Vector3, offset: Vector3, c: Color3)
		Build.decor(Build.part(size, CFrame.new(offset), { Color = c, Parent = dummy }))
	end
	piece(Vector3.new(0.9, 2.4, 0.9), Vector3.new(-0.5, 1.2, 0), rgb(50, 50, 70))
	piece(Vector3.new(0.9, 2.4, 0.9), Vector3.new(0.5, 1.2, 0), rgb(50, 50, 70))
	piece(Vector3.new(2.2, 2.4, 1.1), Vector3.new(0, 3.6, 0), color)
	piece(Vector3.new(0.8, 2.3, 0.8), Vector3.new(-1.55, 3.6, 0), color)
	piece(Vector3.new(0.8, 2.3, 0.8), Vector3.new(1.55, 3.6, 0), color)
	local head = Build.ball(1.6, CFrame.new(0, 5.6, 0), { Color = rgb(255, 210, 170), Parent = dummy })
	Build.decor(head)
	-- "nariz" mostra para onde o boneco olha
	piece(Vector3.new(0.3, 0.3, 0.6), Vector3.new(0, 5.6, -0.9), rgb(230, 80, 80))
	dummy.WorldPivot = CFrame.new()
	return dummy
end

return BaseBuilder
