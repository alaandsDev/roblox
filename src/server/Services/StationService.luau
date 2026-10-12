--!strict
--[[
	StationService: cada CharacterSlot equipado vira uma ESTAÇÃO de produção.

	    [VARIANTE]  NOME  RARIDADE  Nível N  $X/s     <- BillboardGui acima do personagem
	              personagem 3D + aura
	    ┌ placa ┐  $produzido (desde que foi colocado) / "Nível N > N+1"
	    ┌ pad ┐    $CUSTO do próximo nível (pisar/prompt = melhora; segurar em cima = vários)

	Renda/s (produção) e custo de upgrade ficam SEPARADOS visualmente (billboard x pad).
	Desempenho: nada de loop por personagem. Um loop central:
	  - a cada DISPLAY_INTERVAL atualiza o "$ produzido" das placas (só se o texto mudou);
	  - a cada PAD_INTERVAL checa quem está pisando em algum pad.
	Billboard/placa só mudam quando nível, renda ou equipamento mudam. MaxDistance limita
	o custo de UI a distância; o cliente (LodController) desliga partículas de longe.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage.Shared
local CharacterConfig = require(Shared.Config.CharacterConfig)
local CharacterLevelConfig = require(Shared.Config.CharacterLevelConfig)
local RarityConfig = require(Shared.Config.RarityConfig)
local VariantConfig = require(Shared.Config.VariantConfig)
local BaseConfig = require(Shared.Config.BaseConfig)
local Formulas = require(Shared.Modules.GameFormulas)
local CharacterModelFactory = require(Shared.Modules.CharacterModelFactory)
local CharacterAssetConfig = require(Shared.Config.CharacterAssetConfig)
local NumberFormatter = require(Shared.Modules.NumberFormatter)
local Localization = require(Shared.Localization.Localization)
local Logger = require(Shared.Modules.Logger)
local Net = require(Shared.Modules.Net)

local PlayerDataService = require(script.Parent.PlayerDataService)
local BaseService = require(script.Parent.BaseService)
local MapService = require(script.Parent.MapService)
local InventoryService = require(script.Parent.InventoryService)
local UpgradeService = require(script.Parent.UpgradeService)
local BoostService = require(script.Parent.BoostService)

local log = Logger.new("Station")

local StationService = {}

local DISPLAY_INTERVAL = 3
local BILLBOARD_DISTANCE = 90
local PLATE_DISTANCE = 55
local PAD_COLOR = Color3.fromRGB(60, 230, 90)
local PAD_FRAME_COLOR = Color3.fromRGB(30, 120, 55)
local PAD_MAX_COLOR = Color3.fromRGB(255, 200, 60)

type Station = {
	uid: string,
	slotId: number,
	model: Model,
	pad: BasePart,
	labels: { [string]: TextLabel },
	produced: number,
	texts: { [string]: string },
}

local stations: { [Player]: { [number]: Station } } = {}
local lastPoorWarning: { [Player]: number } = {}

local function rgb(list: { number }): Color3
	return Color3.fromRGB(list[1], list[2], list[3])
end

local function findSlot(base: Model, slotId: number): Model?
	local floors = base:FindFirstChild("Floors")
	if not floors then
		return nil
	end
	for _, slot in floors:GetDescendants() do
		if slot:IsA("Model") and slot:GetAttribute("SlotId") == slotId then
			return slot
		end
	end
	return nil
end

local function decorPart(name: string, size: Vector3, cf: CFrame, color: Color3, parent: Instance): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cf
	part.Color = color
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function textLabel(parent: Instance, name: string, y: number, h: number, color: Color3, stroke: number?): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromScale(0, y)
	label.Size = UDim2.fromScale(1, h)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = color
	label.Text = ""
	local s = Instance.new("UIStroke")
	s.Thickness = stroke or 2
	s.Color = Color3.fromRGB(20, 15, 30)
	s.Parent = label
	label.Parent = parent
	return label
end

-- Atualiza um texto só se mudou (evita replicar propriedade à toa)
local function setText(station: Station, key: string, text: string)
	if station.texts[key] ~= text then
		station.texts[key] = text
		station.labels[key].Text = text
	end
end

local function build(player: Player, base: Model, slotId: number, uid: string): Station?
	local data = PlayerDataService.GetData(player)
	local item = data and data.Inventory[uid]
	local slot = findSlot(base, slotId)
	local point = slot and slot:FindFirstChild("CharacterPoint")
	if not item or not point or not point:IsA("BasePart") then
		return nil
	end
	local character = CharacterConfig.ById[item.Id]
	local rarity = RarityConfig.ById[character.Rarity]
	local runtime = base:FindFirstChild("RuntimeCharacters") :: Folder

	local model = Instance.new("Model")
	model.Name = "Station_" .. slotId
	model:SetAttribute("SlotId", slotId)
	model:SetAttribute("Uid", uid)
	model:SetAttribute("Station", true)

	local figure = CharacterModelFactory.build(item.Id, { variant = item.Variant, vfx = CharacterAssetConfig.VFXModes.Base })
	figure:PivotTo(point.CFrame)
	figure.Parent = model

	-- Billboard acima do personagem (Variante / Nome / Raridade / Nível / Renda)
	local height = CharacterModelFactory.height(item.Id)
	local anchor = decorPart("InfoAnchor", Vector3.new(0.2, 0.2, 0.2), point.CFrame * CFrame.new(0, height + 1.2, 0), Color3.new(), model)
	anchor.Transparency = 1
	local gui = Instance.new("BillboardGui")
	gui.Name = "Info"
	gui.Size = UDim2.fromOffset(200, 120)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 2.2, 0)
	gui.MaxDistance = BILLBOARD_DISTANCE
	gui.LightInfluence = 0
	gui.Parent = anchor
	local detail = Instance.new("Frame")
	detail.Name = "Detail"
	detail.BackgroundTransparency = 1
	detail.Size = UDim2.fromScale(1, 1)
	detail.Parent = gui
	local labels = {
		Variant = textLabel(detail, "Variant", 0, 0.16, Color3.new(1, 1, 1)),
		Title = textLabel(detail, "Title", 0.16, 0.22, Color3.new(1, 1, 1), 2.5),
		Rarity = textLabel(detail, "Rarity", 0.38, 0.18, rgb(rarity.Color)),
		Level = textLabel(detail, "Level", 0.56, 0.18, Color3.fromRGB(150, 230, 255)),
		-- Renda fica fora do "Detail": continua visível no LOD médio
		Income = textLabel(gui, "Income", 0.74, 0.26, Color3.fromRGB(110, 255, 110), 2.5),
	}

	-- Placa na frente do pedestal: produzido + nível atual > próximo
	local front = point.CFrame * CFrame.new(0, -BaseConfig.PedestalHeight / 2 + 0.2, -(BaseConfig.PedestalSize / 2 + 0.15))
	local plate = decorPart("Plate", Vector3.new(BaseConfig.PedestalSize * 0.7, 1.8, 0.25), front * CFrame.Angles(math.rad(-12), 0, 0), Color3.fromRGB(35, 40, 70), model)
	local surface = Instance.new("SurfaceGui")
	surface.Name = "PlateGui"
	surface.Face = Enum.NormalId.Front
	surface.CanvasSize = Vector2.new(280, 90)
	surface.LightInfluence = 0
	surface.MaxDistance = PLATE_DISTANCE
	surface.Parent = plate
	labels.Produced = textLabel(surface, "Produced", 0.02, 0.5, Color3.fromRGB(255, 225, 90))
	labels.LevelNext = textLabel(surface, "LevelNext", 0.52, 0.46, Color3.new(1, 1, 1))

	-- Pad de upgrade no chão, à frente
	local padCf = point.CFrame * CFrame.new(0, -BaseConfig.PedestalHeight + 0.18, -(BaseConfig.PedestalSize / 2 + 2.6))
	local pad = decorPart("UpgradePad", Vector3.new(5, 0.3, 3), padCf, PAD_COLOR, model)
	-- Moldura blocky mais escura por baixo (sem Neon: o verde já chama atenção sem estourar no Bloom)
	decorPart("PadFrame", Vector3.new(5.8, 0.24, 3.8), padCf * CFrame.new(0, -0.05, 0), PAD_FRAME_COLOR, model)
	pad:SetAttribute("Uid", uid)
	local padGui = Instance.new("BillboardGui")
	padGui.Name = "Cost"
	padGui.Size = UDim2.new(5, 0, 1.4, 0)
	padGui.StudsOffsetWorldSpace = Vector3.new(0, 1, 0)
	padGui.MaxDistance = PLATE_DISTANCE
	padGui.LightInfluence = 0
	padGui.Parent = pad
	labels.Cost = textLabel(padGui, "Cost", 0, 1, Color3.new(1, 1, 1), 3)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "Upgrade"
	prompt.ActionText = Localization.t("station.upgrade")
	prompt.ObjectText = character.Name
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("InteractId", "StationUpgrade")
	prompt:SetAttribute("Uid", uid)
	prompt.Parent = pad
	local sparkle = Instance.new("ParticleEmitter")
	sparkle.Name = "LevelUp"
	sparkle.Enabled = false
	sparkle.Color = ColorSequence.new(Color3.fromRGB(140, 255, 140), Color3.fromRGB(255, 240, 120))
	sparkle.LightEmission = 1
	sparkle.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
	sparkle.Lifetime = NumberRange.new(0.5, 0.9)
	sparkle.Speed = NumberRange.new(6, 10)
	sparkle.SpreadAngle = Vector2.new(35, 35)
	sparkle.EmissionDirection = Enum.NormalId.Top
	sparkle.Parent = pad

	model.Parent = runtime
	return ({
		uid = uid,
		slotId = slotId,
		model = model,
		pad = pad,
		labels = labels,
		produced = 0,
		texts = {},
	} :: any)
end

local function refresh(player: Player, station: Station)
	local data = PlayerDataService.GetData(player)
	local item = data and data.Inventory[station.uid]
	if not item then
		return
	end
	local character = CharacterConfig.ById[item.Id]
	local variant = VariantConfig.ById[item.Variant] or VariantConfig.ById.Normal
	local level = item.Level or 1
	setText(station, "Variant", if variant.Id == "Normal" then "" else Localization.t("variant." .. variant.Id))
	station.labels.Variant.TextColor3 = rgb(variant.Color)
	setText(station, "Title", character.Name)
	setText(station, "Rarity", Localization.t("rarity." .. character.Rarity))
	setText(station, "Level", Localization.t("station.level", { level = level }))
	setText(station, "Income", NumberFormatter.money(Formulas:stationIncome(data, item)) .. "/s")
	setText(station, "Produced", NumberFormatter.money(station.produced))
	local cost, levels = Formulas:characterUpgradeCost(item.Id, level, 1)
	if levels > 0 then
		setText(station, "LevelNext", Localization.t("station.level_next", { level = level, next = level + 1 }))
		setText(station, "Cost", NumberFormatter.money(cost))
		station.pad.Color = PAD_COLOR
	else
		setText(station, "LevelNext", Localization.t("station.level_max"))
		setText(station, "Cost", Localization.t("station.max"))
		station.pad.Color = PAD_MAX_COLOR
	end
	station.model:SetAttribute("Level", level)
end

local function clear(player: Player)
	local list = stations[player]
	if list then
		for _, station in list do
			station.model:Destroy()
		end
	end
	stations[player] = nil
end

-- Deixa as estações iguais a data.EquippedCharacters (só cria/destrói o que mudou)
function StationService.Sync(player: Player)
	local data = PlayerDataService.GetData(player)
	local base = BaseService.GetPlayerBase(player)
	if not data or not base then
		clear(player)
		return
	end
	local list: { [number]: Station } = stations[player] or {}
	stations[player] = list
	local desired: { [number]: string } = {}
	for slotKey, uid in data.EquippedCharacters do
		local slotId = tonumber(slotKey)
		if slotId and data.Inventory[uid] then
			desired[slotId] = uid
		end
	end
	for slotId, station in list do
		if desired[slotId] ~= station.uid or not station.model.Parent then
			station.model:Destroy()
			list[slotId] = nil
		end
	end
	for slotId, uid in desired do
		if not list[slotId] then
			local ok, station = pcall(build, player, base, slotId, uid)
			if ok and station then
				list[slotId] = station
			elseif not ok then
				log:warn("falha ao montar estação", slotId, station)
			end
		end
	end
	for _, station in list do
		refresh(player, station)
	end
end

function StationService.RefreshAll(player: Player)
	for _, station in (stations[player] or {}) :: { [number]: Station } do
		refresh(player, station)
	end
end

function StationService.Get(player: Player): { [number]: Station }
	return stations[player] or {}
end

local function stationByUid(player: Player, uid: string): Station?
	for _, station in (stations[player] or {}) :: { [number]: Station } do
		if station.uid == uid then
			return station
		end
	end
	return nil
end

local function playUpgradeEffect(station: Station)
	local pad = station.pad
	pad.Color = Color3.new(1, 1, 1)
	TweenService:Create(pad, TweenInfo.new(0.25), { Color = PAD_COLOR }):Play()
	local sparkle = pad:FindFirstChild("LevelUp")
	if sparkle and sparkle:IsA("ParticleEmitter") then
		pcall(function()
			sparkle:Emit(18)
		end)
	end
end

-- Melhora pela estação (pad/prompt). Falhas viram aviso discreto, sem erro
local function upgradeFromStation(player: Player, uid: string)
	local ok, err = pcall(InventoryService.UpgradeCharacter, player, uid, 1)
	if ok then
		return
	end
	local code = if type(err) == "table" then (err :: any).code else nil
	if code == "not_enough_money" then
		local now = os.clock()
		if now - (lastPoorWarning[player] or -math.huge) > 3 then
			lastPoorWarning[player] = now
			Net.fire("Notify", player, "station.not_enough_money")
		end
	elseif code ~= "max_level" then
		log:debug("upgrade pela estação falhou", player.Name, err)
	end
end

local function standingPad(player: Player): Station?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return nil
	end
	for _, station in (stations[player] or {}) :: { [number]: Station } do
		local localPos = station.pad.CFrame:PointToObjectSpace(root.CFrame.Position)
		if math.abs(localPos.X) <= station.pad.Size.X / 2 + 0.3 and math.abs(localPos.Z) <= station.pad.Size.Z / 2 + 0.3 and localPos.Y > -1 and localPos.Y < 6 then
			return station
		end
	end
	return nil
end

------------------------------------------------------------------------------------
-- DEV: base demo para avaliar billboards, auras, pedestais e pads

function StationService.PopulateDemo(player: Player, all: boolean?): number
	local data = PlayerDataService.GetData(player)
	assert(data, "dados não carregados")
	local demo: { { any } } = {
		{ "flame_rookie", 1, "Normal" },
		{ "frost_assassin", 7, "Silver" },
		{ "cyber_ronin", 12, "Normal" },
		{ "dragon_knight", 23, "Gold" },
		{ "void_emperor", 26, "Diamond" },
		{ "astral_seraph", 35, "Emerald" },
		{ "shadow_scout", 4, "Normal" },
		{ "eclipse_sovereign", 50, "Celestial" },
	}
	local unlocked = InventoryService.UnlockedSlots(player)
	local slots = {}
	if all then
		for id = 1, BaseConfig.SlotsPerSide * 2 do
			slots[id] = true
		end
	else
		slots = unlocked
	end
	local order = {}
	for id in slots do
		table.insert(order, id)
	end
	table.sort(order)
	table.clear(data.EquippedCharacters)
	local placed = 0
	for i, slotId in order do
		local entry = demo[i]
		if not entry then
			break
		end
		local uid = InventoryService.Add(player, entry[1], entry[3])
		data.Inventory[uid].Level = entry[2]
		data.EquippedCharacters[tostring(slotId)] = uid
		placed += 1
	end
	PlayerDataService.Replicate(player, "EquippedCharacters")
	StationService.Sync(player)
	return placed
end

------------------------------------------------------------------------------------

function StationService.Init()
	-- Atalho pedido: BaseService.Dev.PopulateDemoBase(player)
	(BaseService.Dev :: any).PopulateDemoBase = StationService.PopulateDemo
	MapService.RegisterInteraction("StationUpgrade", function(player, prompt)
		local uid = prompt:GetAttribute("Uid")
		local base = BaseService.GetPlayerBase(player)
		if type(uid) ~= "string" or not base or not prompt:IsDescendantOf(base) then
			Net.fire("Notify", player, "base.not_yours")
			return
		end
		upgradeFromStation(player, uid)
	end)
end

function StationService.Start()
	InventoryService.EquipChanged:Connect(StationService.Sync)
	InventoryService.ItemChanged:Connect(function(player, uid)
		local station = stationByUid(player, uid)
		if station then
			refresh(player, station)
		end
	end)
	InventoryService.CharacterUpgraded:Connect(function(player, uid)
		local station = stationByUid(player, uid)
		if station then
			playUpgradeEffect(station)
		end
	end)
	UpgradeService.Purchased:Connect(StationService.RefreshAll)
	BoostService.Changed:Connect(StationService.RefreshAll)
	BaseService.BaseAssigned:Connect(function(player)
		task.defer(StationService.Sync, player)
	end)
	BaseService.BaseReleased:Connect(function(player)
		clear(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		clear(player)
		lastPoorWarning[player] = nil
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(StationService.Sync, player)
	end

	-- Loop central: "$ produzido" das placas
	task.spawn(function()
		while true do
			local dt = task.wait(DISPLAY_INTERVAL)
			for player, list in stations do
				local data = PlayerDataService.GetData(player)
				if data then
					for _, station in list do
						local item = data.Inventory[station.uid]
						if item then
							station.produced += Formulas:stationIncome(data, item) * dt
							setText(station, "Produced", NumberFormatter.money(math.floor(station.produced)))
						end
					end
				end
			end
		end
	end)
	-- Loop central: pisar no pad (segurar em cima = vários níveis, no ritmo do config)
	task.spawn(function()
		while true do
			task.wait(CharacterLevelConfig.PadRepeatInterval)
			for player in stations do
				local station = standingPad(player)
				if station then
					upgradeFromStation(player, station.uid)
				end
			end
		end
	end)
end

return StationService
