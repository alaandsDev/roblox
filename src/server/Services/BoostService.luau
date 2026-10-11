--!strict
--[[
	BoostService (Fase 10): multiplicadores da SESSÃO em data.Runtime (replicado).
	    Gamepasses (MonetizationConfig.GamePasses[*].Effects): Income/Luck/Cooldown multiplicam,
	    Capacity soma.
	    Impulso de amigos: +PerFriend de renda por amigo no mesmo servidor (até Max).
	Recalculado ao entrar, ao comprar um gamepass e quando alguém entra/sai. O valor salvo de
	Runtime nunca é confiado (sempre recalculado aqui).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local MonetizationConfig = require(Shared.Config.MonetizationConfig)
local FriendBoostConfig = require(Shared.Config.FriendBoostConfig)

local PlayerDataService = require(script.Parent.PlayerDataService)
local MonetizationService = require(script.Parent.MonetizationService)

local Signal = require(Shared.Modules.Signal)

local BoostService = {}

-- (player) depois que o Runtime mudou (estações atualizam a renda mostrada)
BoostService.Changed = Signal.new()

-- Amizades: cache por par (IsFriendsWith é lento)
local friendCache: { [Player]: { [number]: boolean } } = {}

local function isFriend(a: Player, b: Player): boolean
	local cache = friendCache[a]
	if not cache then
		cache = {}
		friendCache[a] = cache
	end
	if cache[b.UserId] == nil then
		local ok, result = pcall(function()
			return (a :: any):IsFriendsWith(b.UserId)
		end)
		cache[b.UserId] = ok and result == true
	end
	return cache[b.UserId]
end

-- Esquece as amizades conhecidas (ex.: amizade feita durante a sessão / testes)
function BoostService.ClearFriendCache(player: Player)
	friendCache[player] = nil
end

function BoostService.FriendCount(player: Player): number
	if not FriendBoostConfig.Enabled then
		return 0
	end
	local n = 0
	for _, other in Players:GetPlayers() do
		if other ~= player and isFriend(player, other) then
			n += 1
		end
	end
	return n
end

function BoostService.Compute(player: Player): { [string]: any }
	local runtime: { [string]: any } = { Income = 1, Luck = 1, Cooldown = 1, Capacity = 0, Friends = 0, FriendBonus = 0, Passes = {} }
	for key, pass in MonetizationConfig.GamePasses do
		if MonetizationService.OwnsPass(player, key) then
			runtime.Passes[key] = true
		end
		if MonetizationService.OwnsPass(player, key) and pass.Effects then
			for effect, value in pass.Effects do
				if effect == "Capacity" then
					runtime.Capacity += value
				else
					runtime[effect] = (runtime[effect] or 1) * value
				end
			end
		end
	end
	local friends = BoostService.FriendCount(player)
	local bonus = math.min(FriendBoostConfig.Max, friends * FriendBoostConfig.PerFriend)
	runtime.Friends = friends
	runtime.FriendBonus = bonus
	runtime.Income *= 1 + bonus
	return runtime
end

-- Etiqueta "👑 VIP" acima da cabeça de quem tem o gamepass VIP
local function vipTag(player: Player)
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	if not head then
		return
	end
	local existing = head:FindFirstChild("VipTag")
	local isVip = MonetizationService.OwnsPass(player, "VIP")
	if not isVip then
		if existing then
			existing:Destroy()
		end
		return
	end
	if existing then
		return
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "VipTag"
	gui.Size = UDim2.fromOffset(120, 34)
	gui.StudsOffset = Vector3.new(0, 2.6, 0)
	gui.MaxDistance = 80
	gui.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 205, 60)
	label.Text = "👑 VIP"
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Parent = label
	label.Parent = gui
	gui.Parent = head
end

function BoostService.Refresh(player: Player)
	if PlayerDataService.GetData(player) then
		PlayerDataService.Set(player, "Runtime", BoostService.Compute(player))
		BoostService.Changed:Fire(player)
		pcall(vipTag, player)
	end
end

local function refreshAll()
	for _, player in Players:GetPlayers() do
		task.spawn(BoostService.Refresh, player)
	end
end

function BoostService.Start()
	PlayerDataService.Loaded:Connect(function(player)
		-- nunca confia no Runtime salvo
		BoostService.Refresh(player)
		refreshAll()
	end)
	local function watch(player: Player)
		if typeof(player) == "Instance" then
			player.CharacterAdded:Connect(function(character)
				character:WaitForChild("Head", 10)
				pcall(vipTag, player)
			end)
		end
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	MonetizationService.PassesLoaded:Connect(BoostService.Refresh)
	MonetizationService.PassPurchased:Connect(BoostService.Refresh)
	Players.PlayerRemoving:Connect(function(player)
		friendCache[player] = nil
		task.defer(refreshAll)
	end)
	for _, player in Players:GetPlayers() do
		if PlayerDataService.IsLoaded(player) then
			BoostService.Refresh(player)
		end
	end
end

return BoostService
