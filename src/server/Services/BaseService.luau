--!strict
--[[
	BaseService: uma base por jogador.
	    BaseService.GetFreeBase()           -> baseId livre (sem ocupar) ou nil
	    BaseService.AssignBase(player)      -> baseId ou nil (sem base: vai para o Hub)
	    BaseService.ReleaseBase(player)
	    BaseService.GetPlayerBase(player)   -> Model?
	    BaseService.GetBaseOwner(base)      -> Player?
	    BaseService.TeleportPlayerHome(player)
	    BaseService.RefreshBase(player)     -> aplica andares/slots conforme o Rebirth
	    BaseService.FloorUnlocked           -> Signal(player, floor) (gancho para o Rebirth)

	Fluxo de entrada: dados carregados -> base livre -> placa do dono -> progressão visual
	-> teleporte para o PlayerSpawn. Na saída a base volta a "BASE LIVRE".
	Também responde ao HUD de navegação (RequestTeleport: Center / Home / Shop).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local MapConfig = require(Shared.Config.MapConfig)
local BaseConfig = require(Shared.Config.BaseConfig)
local Logger = require(Shared.Modules.Logger)
local Signal = require(Shared.Modules.Signal)
local Net = require(Shared.Modules.Net)

local Server = script.Parent.Parent
local BaseAllocator = require(Server.Core.BaseAllocator)
local BaseBuilder = require(Server.Map.BaseBuilder)
local MapService = require(script.Parent.MapService)
local PlayerDataService = require(script.Parent.PlayerDataService)

local log = Logger.new("Base")

local TELEPORT_COOLDOWN = 1

local BaseService = {}

BaseService.FloorUnlocked = Signal.new()

local allocator = BaseAllocator.new(MapConfig.Bases.AssignOrder)
local lastTeleport: { [Player]: number } = {}

local function teleport(player: Player, target: CFrame): boolean
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not character or not humanoid or humanoid.Health <= 0 then
		return false
	end
	character:PivotTo(target * CFrame.new(0, 3, 0))
	return true
end

function BaseService.GetFreeBase(): number?
	return allocator:peekFree()
end

function BaseService.GetPlayerBase(player: Player): Model?
	local id = allocator:baseOfUser(player.UserId)
	return if id then MapService.GetBase(id) else nil
end

function BaseService.GetBaseOwner(base: Model): Player?
	local userId = base:GetAttribute("OwnerUserId")
	if type(userId) ~= "number" or userId == 0 then
		return nil
	end
	return Players:GetPlayerByUserId(userId)
end

function BaseService.TeleportPlayerHome(player: Player): boolean
	local base = BaseService.GetPlayerBase(player)
	if not base then
		return teleport(player, MapService.GetHubSpawn())
	end
	return teleport(player, BaseBuilder.spawnCFrame(base))
end

-- Aplica andares/slots da progressão do dono. Dispara FloorUnlocked se apareceu andar novo.
function BaseService.RefreshBase(player: Player, isInitial: boolean?)
	local base = BaseService.GetPlayerBase(player)
	local data = PlayerDataService.GetData(player)
	if not base or not data then
		return
	end
	local state = MapService.Progression:state(data.Rebirths or 0)
	local before, after = BaseBuilder.applyState(base, state, MapService.Progression)
	if not isInitial and after > before then
		for floor = before + 1, after do
			BaseBuilder.playFloorUnlockedEffect(base, floor)
			BaseService.FloorUnlocked:Fire(player, floor)
			Net.fire("FloorUnlocked", player, floor)
			Net.fire("Notify", player, "base.floor_unlocked", { floor = floor })
		end
	end
end

function BaseService.AssignBase(player: Player): number?
	local baseId = allocator:assign(player.UserId)
	if not baseId then
		log:warn("No free base available.", player.Name, "vai para o Hub")
		return nil
	end
	local base = MapService.GetBase(baseId) :: Model
	base:SetAttribute("OwnerUserId", player.UserId)
	player:SetAttribute("BaseId", baseId)

	local thumbnail: string? = nil
	local ok, result = pcall(
		Players.GetUserThumbnailAsync,
		Players,
		player.UserId,
		Enum.ThumbnailType.HeadShot,
		Enum.ThumbnailSize.Size150x150
	)
	if ok then
		thumbnail = result
	end
	-- O jogador pode ter saído enquanto a foto carregava
	if allocator:baseOfUser(player.UserId) ~= baseId then
		return nil
	end
	BaseBuilder.setOwner(base, { displayName = player.DisplayName, userName = player.Name, thumbnail = thumbnail })
	BaseService.RefreshBase(player, true)
	log:info(`{player.Name} recebeu a {base.Name}`)
	return baseId
end

function BaseService.ReleaseBase(player: Player)
	local baseId = allocator:release(player.UserId)
	lastTeleport[player] = nil
	if not baseId then
		return
	end
	local base = MapService.GetBase(baseId)
	if not base then
		return
	end
	base:SetAttribute("OwnerUserId", 0)
	BaseBuilder.clearRuntime(base)
	BaseBuilder.setOwner(base, nil)
	BaseBuilder.applyState(base, MapService.Progression:state(0), MapService.Progression)
	log:info(`{base.Name} liberada ({player.Name} saiu)`)
end

local function onDataLoaded(player: Player)
	if player.Parent ~= Players then
		return
	end
	if not BaseService.AssignBase(player) then
		Net.fire("Notify", player, "nav.no_base")
	end
	BaseService.TeleportPlayerHome(player)
end

local function handleTeleport(player: Player, destination: string)
	local now = os.clock()
	if now - (lastTeleport[player] or 0) < TELEPORT_COOLDOWN then
		Net.fail("cooldown")
	end
	lastTeleport[player] = now

	local ok
	if destination == "Center" then
		ok = teleport(player, MapService.GetHubSpawn())
	elseif destination == "Shop" then
		ok = teleport(player, MapService.GetShopSpawn())
	else
		if not BaseService.GetPlayerBase(player) then
			Net.fire("Notify", player, "nav.no_base")
			Net.fail("no_base")
		end
		ok = BaseService.TeleportPlayerHome(player)
	end
	if not ok then
		Net.fail("no_character")
	end
	return destination
end

------------------------------------------------------------------------------------
-- Ferramentas de teste (só no Studio). Pela Barra de comandos, contexto Servidor:
--   local B = require(game.ServerScriptService.Server.Services.BaseService)
--   B.Dev.PreviewFloors(3, 2)   -- Base03 com 2 andares (sem dar Rebirth a ninguém)
--   B.Dev.ShowDummies(3, true)  -- bonecos de escala em todos os slots da Base03
--   B.Dev.Reset(3)              -- volta ao estado do dono (ou RB0 se livre)

BaseService.Dev = {}

local function requireStudio()
	assert(RunService:IsStudio(), "ferramenta de teste disponível só no Studio")
end

function BaseService.Dev.PreviewFloors(baseId: number, floors: number)
	requireStudio()
	local base = MapService.GetBase(baseId)
	assert(base, "base inválida")
	local rebirth = MapService.Progression:floorUnlockRebirth(floors)
	local state = if rebirth then MapService.Progression:state(rebirth) else MapService.Progression:state(0)
	-- Se o andar ainda não tem marco definido, só constrói a estrutura (slots seguem bloqueados)
	local preview = { unlockedFloors = floors, unlockedSlots = state.unlockedSlots }
	local before, after = BaseBuilder.applyState(base, preview, MapService.Progression)
	if after > before then
		BaseBuilder.playFloorUnlockedEffect(base, after)
	end
	log:info(`[DEV] {base.Name}: prévia com {after} andar(es)`)
end

function BaseService.Dev.ShowDummies(baseId: number, show: boolean)
	requireStudio()
	local base = MapService.GetBase(baseId)
	assert(base, "base inválida")
	local runtime = base:FindFirstChild("RuntimeCharacters") :: Folder
	for _, child in runtime:GetChildren() do
		if child.Name == "ScaleDummy" then
			child:Destroy()
		end
	end
	if not show then
		return
	end
	local count = 0
	for _, slot in base:GetDescendants() do
		if slot:IsA("Model") and slot:GetAttribute("SlotId") then
			local point = slot:FindFirstChild("CharacterPoint") :: BasePart
			local dummy = BaseBuilder.dummy(Color3.fromHSV((slot:GetAttribute("SlotId") :: number % 8) / 8, 0.6, 0.95))
			dummy:PivotTo(point.CFrame)
			dummy.Parent = runtime
			count += 1
		end
	end
	log:info(`[DEV] {count} bonecos de escala na {base.Name}`)
end

function BaseService.Dev.Reset(baseId: number)
	requireStudio()
	local base = MapService.GetBase(baseId)
	assert(base, "base inválida")
	BaseService.Dev.ShowDummies(baseId, false)
	local owner = BaseService.GetBaseOwner(base)
	if owner then
		BaseService.RefreshBase(owner, true)
	else
		BaseBuilder.applyState(base, MapService.Progression:state(0), MapService.Progression)
	end
end

------------------------------------------------------------------------------------

function BaseService.Init()
	Net.handle("RequestTeleport", handleTeleport)
end

function BaseService.Start()
	PlayerDataService.Loaded:Connect(onDataLoaded)
	for _, player in Players:GetPlayers() do
		if PlayerDataService.IsLoaded(player) and not allocator:baseOfUser(player.UserId) then
			task.spawn(onDataLoaded, player)
		end
	end

	local function watchCharacter(player: Player)
		player.CharacterAdded:Connect(function(character)
			character:WaitForChild("HumanoidRootPart", 10)
			task.wait() -- deixa o Roblox terminar de posicionar o personagem
			BaseService.TeleportPlayerHome(player)
		end)
	end
	Players.PlayerAdded:Connect(watchCharacter)
	for _, player in Players:GetPlayers() do
		watchCharacter(player)
	end
	Players.PlayerRemoving:Connect(BaseService.ReleaseBase)

	if BaseConfig.MaxFloors < 2 then
		log:warn("BaseConfig.MaxFloors < 2: o Floor02 nunca será construído")
	end
end

return BaseService
