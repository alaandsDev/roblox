--!strict
--[[
	MapService: constrói o mundo (mapa + 10 bases) e expõe os pontos importantes.
	    MapService.GetHubSpawn() / GetShopSpawn() / GetTowerEntrance()  -> CFrame
	    MapService.GetBases() -> { [baseId]: Model }
	    MapService.ValidateMap() -> lista de problemas (vazia = ok)
	No Studio o mapa é validado automaticamente ao iniciar (avisos na Saída).
	Prompts "Abrir" de áreas ainda não implementadas respondem "em breve".
]]

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local MapConfig = require(Shared.Config.MapConfig)
local BaseConfig = require(Shared.Config.BaseConfig)
local BaseProgressionConfig = require(Shared.Config.BaseProgressionConfig)
local BaseProgression = require(Shared.Modules.BaseProgression)
local BaseLayout = require(Shared.Modules.BaseLayout)
local Logger = require(Shared.Modules.Logger)
local Net = require(Shared.Modules.Net)

local Server = script.Parent.Parent
local MapBuilder = require(Server.Map.MapBuilder)
local BaseBuilder = require(Server.Map.BaseBuilder)
local MapValidator = require(Server.Core.MapValidator)

local log = Logger.new("Map")

local MapService = {}

MapService.Progression = BaseProgression.new(BaseProgressionConfig, BaseConfig.SlotsPerSide * 2)

local refs: MapBuilder.Refs
local bases: { [number]: Model } = {}
local promptCooldown: { [Player]: number } = {}

function MapService.GetHubSpawn(): CFrame
	return refs.hubSpawn.CFrame
end

function MapService.GetShopSpawn(): CFrame
	return refs.shopSpawn.CFrame
end

function MapService.GetTowerEntrance(): CFrame
	return refs.towerEntrance.CFrame
end

function MapService.GetBases(): { [number]: Model }
	return bases
end

-- Busca no cache e, se não houver (ex.: módulo carregado em outro contexto, como a Barra de
-- comandos do Studio), direto em Workspace.Bases — o DataModel é a fonte da verdade.
function MapService.GetBase(baseId: number): Model?
	local cached = bases[baseId]
	if cached and cached.Parent then
		return cached
	end
	local folder = workspace:FindFirstChild("Bases")
	local found = folder and folder:FindFirstChild(BaseLayout.baseName(baseId))
	if found and found:IsA("Model") then
		bases[baseId] = found
		return found
	end
	return nil
end

-- Monta o "retrato" do mapa e roda o MapValidator
function MapService.ValidateMap(): { string }
	local snapshot = { points = {}, bases = {} }
	snapshot.points.HubSpawn = refs.map:FindFirstChild("HubSpawn", true) ~= nil
	snapshot.points.ShopSpawn = refs.map:FindFirstChild("ShopSpawn", true) ~= nil
	snapshot.points.TowerEntrance = refs.map:FindFirstChild("TowerEntrance", true) ~= nil

	local folder = workspace:FindFirstChild("Bases")
	for _, base in if folder then folder:GetChildren() else {} do
		if not base:IsA("Model") then
			continue
		end
		local entry = {
			name = base.Name,
			baseId = base:GetAttribute("BaseId"),
			hasPlayerSpawn = base:FindFirstChild("PlayerSpawn") ~= nil,
			hasOwnerSign = base:FindFirstChild("OwnerSign") ~= nil,
			hasMoneyCollector = base:FindFirstChild("MoneyCollector") ~= nil,
			hasUpgradeArea = base:FindFirstChild("UpgradeArea") ~= nil,
			hasRuntimeCharacters = base:FindFirstChild("RuntimeCharacters") ~= nil,
			floors = {},
		}
		local floors = base:FindFirstChild("Floors")
		for _, floor in if floors then floors:GetChildren() else {} do
			local floorEntry = { name = floor.Name, floorId = floor:GetAttribute("FloorId"), sides = {} }
			for _, side in { "A", "B" } do
				local sideFolder = floor:FindFirstChild("Side" .. side)
				if sideFolder then
					local slots = {}
					for _, slot in sideFolder:GetChildren() do
						table.insert(slots, {
							name = slot.Name,
							slotId = slot:GetAttribute("SlotId"),
							side = slot:GetAttribute("Side"),
							index = slot:GetAttribute("SlotIndexOnSide"),
							floorId = slot:GetAttribute("FloorId"),
						})
					end
					floorEntry.sides[side] = slots
				end
			end
			table.insert(entry.floors, floorEntry)
		end
		table.insert(snapshot.bases, entry)
	end
	return MapValidator.validate(snapshot, MapConfig.Bases.Count, BaseConfig.SlotsPerSide)
end

function MapService.Init()
	local started = os.clock()
	local problems = MapService.Progression:validate(BaseConfig.MaxFloors)
	for _, problem in problems do
		log:warn("BaseProgressionConfig:", problem)
	end

	refs = MapBuilder.build()

	local old = workspace:FindFirstChild("Bases")
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "Bases"
	local initial = MapService.Progression:state(0)
	for id = 1, MapConfig.Bases.Count do
		local base = BaseBuilder.build(id, folder, MapService.Progression)
		BaseBuilder.applyState(base, initial, MapService.Progression)
		bases[id] = base
	end
	folder.Parent = workspace

	local count = 0
	for _, obj in workspace:GetDescendants() do
		if obj:IsA("BasePart") then
			count += 1
		end
	end
	log:info(string.format("mapa construído em %.2fs (%d peças)", os.clock() - started, count))
end

function MapService.Start()
	if RunService:IsStudio() then
		local problems = MapService.ValidateMap()
		if #problems == 0 then
			log:info("mapa validado: OK (10 bases, 4 slots no lado A e 4 no lado B em cada andar)")
		else
			for _, problem in problems do
				log:warn("validação do mapa:", problem)
			end
		end
	end

	-- Áreas ainda não implementadas: avisam "em breve"
	ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
		local id = prompt:GetAttribute("InteractId")
		if not id then
			return
		end
		local now = os.clock()
		if now - (promptCooldown[player] or 0) < 1 then
			return
		end
		promptCooldown[player] = now
		Net.fire("Notify", player, "map.coming_soon", { name = prompt.ObjectText })
	end)
	Players.PlayerRemoving:Connect(function(player)
		promptCooldown[player] = nil
	end)
end

return MapService
