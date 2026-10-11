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

	Spawn (Player -> Base -> Spawn):
	- CharacterAutoLoads = false: o personagem só é carregado DEPOIS da base atribuída.
	- player.RespawnLocation = PlayerSpawn da base do jogador (SpawnLocation na entrada,
	  Neutral = false: ninguém mais nasce ali). Vale para entrada e para todo respawn.
	- Quando o HumanoidRootPart existe, o personagem é colocado exatamente no PlayerSpawn,
	  na altura certa e olhando para dentro da base (só se a base for MESMO dele).
	- A ordem dos eventos é controlada pelo Core/SpawnCoordinator (sem corrida entre
	  CharacterAdded e atribuição). Se a base demorar (ou não houver base livre), o jogador
	  nasce no Hub e vai para casa assim que a base for atribuída.
	Na saída a base volta a "BASE LIVRE".
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
local SpawnCoordinator = require(Server.Core.SpawnCoordinator)
local BaseBuilder = require(Server.Map.BaseBuilder)
local MapService = require(script.Parent.MapService)
local PlayerDataService = require(script.Parent.PlayerDataService)

local log = Logger.new("Base")

local TELEPORT_COOLDOWN = 1
-- Sem base depois desse tempo (dados lentos / servidor cheio): nasce no Hub
local SPAWN_FALLBACK_SECONDS = 10

local BaseService = {}

BaseService.FloorUnlocked = Signal.new()

local allocator = BaseAllocator.new(MapConfig.Bases.AssignOrder)
local lastTeleport: { [Player]: number } = {}

-- Coloca o personagem em pé sobre `floorCFrame` (posição no piso + direção do olhar)
local function teleport(player: Player, floorCFrame: CFrame): boolean
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not character or not humanoid or not root or humanoid.Health <= 0 then
		return false
	end
	-- Altura do HumanoidRootPart acima do piso: pernas + metade do root (R6 tem HipHeight 0)
	local legs = if humanoid.RigType == Enum.HumanoidRigType.R15 then humanoid.HipHeight else 2
	character:PivotTo(floorCFrame * CFrame.new(0, legs + root.Size.Y / 2 + 0.05, 0))
	root.AssemblyLinearVelocity = Vector3.zero
	return true
end

local coordinator = SpawnCoordinator.new({
	loadCharacter = function(player: Player)
		task.spawn(function()
			if player.Parent == Players then
				local ok, err = pcall(player.LoadCharacterAsync, player)
				if not ok then
					log:warn("LoadCharacterAsync falhou para", player.Name, err)
				end
			end
		end)
	end,
	placeAtBase = function(player: Player, baseId: number)
		local base = MapService.GetBase(baseId)
		if base then
			teleport(player, BaseBuilder.spawnCFrame(base))
		end
	end,
	ownerOf = function(baseId: number): number?
		return allocator:owner(baseId)
	end,
})

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
	if not base or base:GetAttribute("OwnerUserId") ~= player.UserId then
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
	-- Todo nascimento/respawn do jogador passa a ser no PlayerSpawn desta base
	player.RespawnLocation = BaseBuilder.spawnLocation(base) :: any

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
	-- Carrega o personagem (ou leva para casa, se ele já nasceu no Hub)
	coordinator:baseAssigned(player, baseId)
	return baseId
end

function BaseService.ReleaseBase(player: Player)
	local baseId = allocator:release(player.UserId)
	lastTeleport[player] = nil
	coordinator:playerLeft(player)
	player.RespawnLocation = nil :: any
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
		coordinator:fallbackDue(player) -- sem base livre: nasce no Hub
	end
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
	-- O personagem só é carregado pelo SpawnCoordinator (depois da base atribuída)
	Players.CharacterAutoLoads = false
	Net.handle("RequestTeleport", handleTeleport)
end

local function watchPlayer(player: Player)
	coordinator:playerJoined(player)
	player.CharacterAdded:Connect(function(character)
		coordinator:characterAdded(player)
		local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
		local root = character:WaitForChild("HumanoidRootPart", 10)
		if not humanoid or not root or player.Character ~= character then
			return
		end
		humanoid.Died:Once(function()
			coordinator:died(player)
			task.delay(Players.RespawnTime, function()
				if player.Parent == Players then
					coordinator:respawnDue(player)
				end
			end)
		end)
		task.wait() -- deixa o Roblox terminar de posicionar no SpawnLocation
		if player.Character == character then
			coordinator:rootReady(player)
		end
	end)
	-- Rede de segurança: se a base não vier a tempo, nasce no Hub
	task.delay(SPAWN_FALLBACK_SECONDS, function()
		if player.Parent == Players then
			coordinator:fallbackDue(player)
		end
	end)
end

function BaseService.Start()
	Players.PlayerAdded:Connect(watchPlayer)
	for _, player in Players:GetPlayers() do
		watchPlayer(player)
		-- Já tinha personagem antes deste script (ex.: Play Solo): marca para ser levado para casa
		if player.Character then
			coordinator:characterAdded(player)
			coordinator:rootReady(player)
		end
	end
	Players.PlayerRemoving:Connect(BaseService.ReleaseBase)

	PlayerDataService.Loaded:Connect(onDataLoaded)
	for _, player in Players:GetPlayers() do
		if PlayerDataService.IsLoaded(player) and not allocator:baseOfUser(player.UserId) then
			task.spawn(onDataLoaded, player)
		end
	end

	if BaseConfig.MaxFloors < 2 then
		log:warn("BaseConfig.MaxFloors < 2: o Floor02 nunca será construído")
	end
end

return BaseService
