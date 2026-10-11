--!strict
--[[
	EconomyService: dinheiro do jogador (autoritativo).
	    EconomyService.AddMoney(player, valor, origem)
	    EconomyService.TrySpend(player, valor) -> boolean
	    EconomyService.IncomePerSecond(player)
	    EconomyService.Collect(player) -> valor coletado

	Renda passiva: a cada EconomyConfig.IncomeTick, a renda das estações vai para
	data.UncollectedMoney (só memória: NÃO grava no DataStore a cada tick; o autosave salva).
	O coletor da base mostra o valor ($125 / $1.2K). Pisar no coletor ou usar o prompt COLETAR
	transfere para Money (efeito de moedas no cliente via evento MoneyCollected).

	Dinheiro offline: ao carregar o perfil, calcula com OfflineCore (relógio do servidor) e
	guarda em PendingOfflineReward. O cliente só pede ClaimOfflineReward; o servidor zera o
	pendente ANTES de entregar (pedidos repetidos não pagam duas vezes).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local EconomyConfig = require(Shared.Config.EconomyConfig)
local OfflineIncomeConfig = require(Shared.Config.OfflineIncomeConfig)
local Formulas = require(Shared.Modules.GameFormulas)
local OfflineCore = require(Shared.Modules.OfflineCore)
local NumberFormatter = require(Shared.Modules.NumberFormatter)
local Logger = require(Shared.Modules.Logger)
local Signal = require(Shared.Modules.Signal)
local Net = require(Shared.Modules.Net)

local PlayerDataService = require(script.Parent.PlayerDataService)
local BaseService = require(script.Parent.BaseService)
local MapService = require(script.Parent.MapService)
local AnalyticsService = require(script.Parent.AnalyticsService)

local log = Logger.new("Economy")

local EconomyService = {}

-- (player, valor, origem)
EconomyService.MoneyAdded = Signal.new()
-- Relógio (substituível nos testes)
EconomyService._now = function(): number
	return os.time()
end

local COLLECT_RADIUS = 14
local LAST_SEEN_INTERVAL = 30

local lastCollect: { [Player]: number } = {}
local offlineChecked: { [Player]: boolean } = {}
local collectorText: { [Model]: string } = {}

local function finite(n: any): boolean
	return type(n) == "number" and n == n and n ~= math.huge and n ~= -math.huge
end

function EconomyService.AddMoney(player: Player, amount: number, source: string): number
	local data = PlayerDataService.GetData(player)
	assert(data, "dados não carregados")
	assert(finite(amount) and amount >= 0, "valor inválido")
	local value = math.floor(amount)
	local money = PlayerDataService.Increment(player, "Money", value)
	EconomyService.MoneyAdded:Fire(player, value, source)
	return money
end

-- Desconta se tiver saldo. Sem yield entre checar e descontar (dois pedidos não gastam o mesmo dinheiro)
function EconomyService.TrySpend(player: Player, amount: number): boolean
	local data = PlayerDataService.GetData(player)
	if not data or not finite(amount) or amount < 0 then
		return false
	end
	if data.Money < amount then
		return false
	end
	PlayerDataService.Set(player, "Money", data.Money - math.floor(amount))
	return true
end

function EconomyService.IncomePerSecond(player: Player): number
	local data = PlayerDataService.GetData(player)
	return if data then Formulas:incomePerSecond(data) else 0
end

------------------------------------------------------------------------------------
-- Coletor da base

local function collectorOf(base: Model): BasePart?
	local pad = base:FindFirstChild("MoneyCollector")
	return if pad and pad:IsA("BasePart") then pad else nil
end

local function amountLabel(pad: BasePart): TextLabel?
	local gui = pad:FindFirstChild("Label")
	if not gui or not gui:IsA("BillboardGui") then
		return nil
	end
	local label = gui:FindFirstChild("Amount")
	if label and label:IsA("TextLabel") then
		return label
	end
	gui.Size = UDim2.fromOffset(170, 84)
	local title = gui:FindFirstChild("Text")
	if title and title:IsA("TextLabel") then
		title.Size = UDim2.fromScale(1, 0.45)
	end
	local amount = Instance.new("TextLabel")
	amount.Name = "Amount"
	amount.Position = UDim2.fromScale(0, 0.45)
	amount.Size = UDim2.fromScale(1, 0.55)
	amount.BackgroundTransparency = 1
	amount.Font = Enum.Font.FredokaOne
	amount.TextScaled = true
	amount.TextColor3 = Color3.fromRGB(120, 255, 120)
	amount.Text = "$0"
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2.5
	stroke.Parent = amount
	amount.Parent = gui
	return amount
end

local function refreshCollector(player: Player)
	local base = BaseService.GetPlayerBase(player)
	local data = PlayerDataService.GetData(player)
	local pad = base and collectorOf(base)
	if not base or not data or not pad then
		return
	end
	local text = NumberFormatter.money(math.floor(data.UncollectedMoney))
	if collectorText[base] ~= text then
		collectorText[base] = text
		local label = amountLabel(pad)
		if label then
			label.Text = text
		end
	end
end

local function clearCollector(base: Model)
	collectorText[base] = nil
	local pad = collectorOf(base)
	local label = pad and amountLabel(pad)
	if label then
		label.Text = ""
	end
end

function EconomyService.Collect(player: Player): number
	local data = PlayerDataService.GetData(player)
	if not data then
		return 0
	end
	local now = os.clock()
	if now - (lastCollect[player] or 0) < EconomyConfig.CollectCooldown then
		return 0
	end
	local amount = math.floor(data.UncollectedMoney)
	if amount < 1 then
		return 0
	end
	lastCollect[player] = now
	data.UncollectedMoney -= amount
	EconomyService.AddMoney(player, amount, "Collector")
	refreshCollector(player)
	Net.fire("MoneyCollected", player, amount)
	AnalyticsService.Track(player, "MoneyCollected", { amount = amount })
	return amount
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function isNearCollector(player: Player, radius: number): boolean
	local base = BaseService.GetPlayerBase(player)
	local pad = base and collectorOf(base)
	local root = rootOf(player)
	if not pad or not root then
		return false
	end
	return (root.CFrame.Position - pad.CFrame.Position).Magnitude <= radius
end

-- Pisou no coletor (checagem por posição no servidor: não depende de Touched do cliente)
local function isStandingOnCollector(player: Player): boolean
	local base = BaseService.GetPlayerBase(player)
	local pad = base and collectorOf(base)
	local root = rootOf(player)
	if not pad or not root then
		return false
	end
	local localPos = pad.CFrame:PointToObjectSpace(root.CFrame.Position)
	return math.abs(localPos.X) <= pad.Size.X / 2 + 0.5
		and math.abs(localPos.Z) <= pad.Size.Z / 2 + 0.5
		and localPos.Y > -1
		and localPos.Y < 6
end

------------------------------------------------------------------------------------
-- Renda passiva

function EconomyService.Tick(dt: number)
	for _, player in Players:GetPlayers() do
		local data = PlayerDataService.GetData(player)
		if not data then
			continue
		end
		local ips = Formulas:incomePerSecond(data)
		data.LastKnownIncomePerSecond = ips
		if ips > 0 and BaseService.GetPlayerBase(player) then
			local cap = ips * EconomyConfig.MaxUncollectedSeconds
			if data.UncollectedMoney < cap then
				data.UncollectedMoney = math.min(cap, data.UncollectedMoney + ips * dt)
			end
		end
		refreshCollector(player)
	end
end

------------------------------------------------------------------------------------
-- Dinheiro offline

function EconomyService.CheckOffline(player: Player)
	if offlineChecked[player] then
		return
	end
	local data = PlayerDataService.GetData(player)
	if not data then
		return
	end
	offlineChecked[player] = true
	local now = EconomyService._now()
	local amount, seconds, reason =
		OfflineCore.compute(data.LastLogout, now, data.LastKnownIncomePerSecond, OfflineIncomeConfig)
	-- Daqui em diante o "visto por último" é agora (uma queda do servidor não recalcula o mesmo período)
	data.LastLogout = now
	if amount > 0 then
		local pending = if finite(data.PendingOfflineReward) and data.PendingOfflineReward > 0 then data.PendingOfflineReward else 0
		-- Pendente não resgatado de sessões anteriores soma, mas nunca passa do teto de uma sessão
		local cap = math.floor(data.LastKnownIncomePerSecond * OfflineIncomeConfig.MaxSeconds * OfflineIncomeConfig.Multiplier)
		PlayerDataService.Set(player, "PendingOfflineReward", math.min(pending + amount, math.max(cap, amount)))
		log:info(`{player.Name}: dinheiro offline {amount} ({math.floor(seconds)} s)`)
	elseif reason == "future" or reason == "invalid" then
		log:warn(`{player.Name}: LastLogout inválido ({reason}); sem dinheiro offline`)
	end
end

-- Só DEV/testes: permite recalcular o offline na mesma sessão
function EconomyService._resetOffline(player: Player)
	offlineChecked[player] = nil
end

function EconomyService.ClaimOffline(player: Player): number
	local data = PlayerDataService.GetData(player)
	if not data then
		Net.fail(Net.Codes.NotReady)
	end
	assert(data)
	local amount = data.PendingOfflineReward
	if not finite(amount) or amount < 1 then
		Net.fail("nothing_to_claim")
	end
	-- Zera ANTES de entregar: um segundo pedido (spam) não encontra nada
	PlayerDataService.Set(player, "PendingOfflineReward", 0)
	EconomyService.AddMoney(player, amount, "Offline")
	AnalyticsService.Track(player, "OfflineRewardClaimed", { amount = amount })
	PlayerDataService.SaveSoon(player)
	return amount
end

------------------------------------------------------------------------------------

local function handleCollect(player: Player)
	if not PlayerDataService.GetData(player) then
		Net.fail(Net.Codes.NotReady)
	end
	if not isNearCollector(player, COLLECT_RADIUS) then
		Net.fail("too_far")
	end
	return EconomyService.Collect(player)
end

function EconomyService.Init()
	Net.handle("CollectMoney", handleCollect)
	Net.handle("ClaimOfflineReward", function(player)
		return EconomyService.ClaimOffline(player)
	end)
	MapService.RegisterInteraction("MoneyCollector", function(player, prompt)
		local base = BaseService.GetPlayerBase(player)
		if not base or not prompt:IsDescendantOf(base) then
			Net.fire("Notify", player, "base.not_yours")
			return
		end
		if EconomyService.Collect(player) == 0 then
			Net.fire("Notify", player, "economy.nothing_to_collect")
		end
	end)
end

function EconomyService.Start()
	PlayerDataService.Loaded:Connect(function(player)
		EconomyService.CheckOffline(player)
	end)
	for _, player in Players:GetPlayers() do
		if PlayerDataService.IsLoaded(player) then
			EconomyService.CheckOffline(player)
		end
	end
	BaseService.BaseReleased:Connect(function(_, base)
		clearCollector(base)
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastCollect[player] = nil
		offlineChecked[player] = nil
	end)

	-- Renda (1 loop central para todos os jogadores)
	task.spawn(function()
		local lastSeen = 0
		while true do
			local dt = task.wait(EconomyConfig.IncomeTick)
			EconomyService.Tick(dt)
			lastSeen += dt
			if lastSeen >= LAST_SEEN_INTERVAL then
				lastSeen = 0
				local now = EconomyService._now()
				for _, player in Players:GetPlayers() do
					local data = PlayerDataService.GetData(player)
					if data and offlineChecked[player] then
						data.LastLogout = now
					end
				end
			end
		end
	end)
	-- Coletor por "pisar" (checagem leve de posição, 4x por segundo)
	task.spawn(function()
		while true do
			task.wait(0.25)
			for _, player in Players:GetPlayers() do
				if isStandingOnCollector(player) then
					EconomyService.Collect(player)
				end
			end
		end
	end)
end

return EconomyService
