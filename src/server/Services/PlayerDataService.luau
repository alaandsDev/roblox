--!strict
--[[
	PlayerDataService: carrega, guarda e salva o perfil de cada jogador.

	- Carrega ao entrar (com trava de sessão), salva a cada DataConfig.AutosaveInterval,
	  ao sair (liberando a trava) e quando o servidor desliga (BindToClose).
	- Outros Services leem/alteram dados SÓ por aqui:
	    PlayerDataService.GetData(player)            -> tabela do perfil (ou nil se não carregou)
	    PlayerDataService.WaitForData(player, 10)
	    PlayerDataService.Set(player, "Money", 100)  -> altera e avisa o cliente
	    PlayerDataService.Increment(player, "Rolls", 1)
	    PlayerDataService.Loaded:Connect(function(player, data) end)
	- No Studio sem acesso à API, o jogador joga com um perfil temporário (não salva) e é avisado.
	- No jogo publicado, se não der para carregar, o jogador é desconectado com uma mensagem
	  (melhor do que jogar e perder o progresso).
]]

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local DataConfig = require(Shared.Config.DataConfig)
local GameConfig = require(Shared.Config.GameConfig)
local TableUtil = require(Shared.Modules.TableUtil)
local Signal = require(Shared.Modules.Signal)
local Logger = require(Shared.Modules.Logger)
local Localization = require(Shared.Localization.Localization)
local Net = require(Shared.Modules.Net)

local Core = script.Parent.Parent.Core
local ProfileCore = require(Core.ProfileCore)
local Migrations = require(Core.Migrations)

local log = Logger.new("PlayerData")

local PlayerDataService = {}

PlayerDataService.Loaded = Signal.new()

type Entry = {
	profile: ProfileCore.Profile,
	-- true = perfil temporário (Studio sem API): nunca salva
	offline: boolean,
}

local entries: { [Player]: Entry } = {}
-- Studio com place local/não publicado (ou DataStore indisponível): perfis temporários direto
local offlineOnly = false
local loading: { [Player]: boolean } = {}
local core: any = nil
-- Usado na idempotência de compras (ver MonetizationService)
local saving: { [Player]: boolean } = {}

local function keyFor(player: Player): string
	return DataConfig.KeyPrefix .. player.UserId
end

local function coreLog(level: string, message: string)
	if level == "error" then
		log:error(message)
	elseif level == "warn" then
		log:warn(message)
	elseif level == "info" then
		log:info(message)
	else
		log:debug(message)
	end
end

local function clientView(data: { [string]: any }): { [string]: any }
	local copy = TableUtil.deepCopy(data)
	for _, key in DataConfig.PrivateKeys do
		copy[key] = nil
	end
	return copy
end

local function kick(player: Player, textKey: string)
	if player.Parent == Players then
		player:Kick(Localization.t(textKey))
	end
end

------------------------------------------------------------------------------------
-- API pública

function PlayerDataService.GetData(player: Player): { [string]: any }?
	local entry = entries[player]
	return if entry then entry.profile.Data else nil
end

function PlayerDataService.GetProfile(player: Player): ProfileCore.Profile?
	local entry = entries[player]
	return if entry then entry.profile else nil
end

function PlayerDataService.IsLoaded(player: Player): boolean
	return entries[player] ~= nil
end

function PlayerDataService.WaitForData(player: Player, timeout: number?): { [string]: any }?
	local deadline = os.clock() + (timeout or 15)
	while not entries[player] and player.Parent == Players and os.clock() < deadline do
		task.wait(0.1)
	end
	return PlayerDataService.GetData(player)
end

-- Altera uma chave de primeiro nível e avisa o cliente (se não for privada)
function PlayerDataService.Set(player: Player, key: string, value: any)
	local data = PlayerDataService.GetData(player)
	assert(data, "PlayerDataService.Set: dados não carregados")
	assert(DataConfig.Template[key] ~= nil, `PlayerDataService.Set: chave "{key}" não existe no Template`)
	data[key] = value
	if not table.find(DataConfig.PrivateKeys, key) then
		Net.fire("DataChanged", player, key, TableUtil.deepCopy(value))
	end
end

function PlayerDataService.Increment(player: Player, key: string, delta: number): number
	local data = PlayerDataService.GetData(player)
	assert(data and type(data[key]) == "number", `PlayerDataService.Increment: "{key}" não é número`)
	local value = data[key] + delta
	PlayerDataService.Set(player, key, value)
	return value
end

-- Salva agora (usado depois de compras). Retorna true se gravou.
function PlayerDataService.SaveNow(player: Player): boolean
	local entry = entries[player]
	if not entry then
		return false
	end
	if entry.offline then
		return true
	end
	while saving[player] do
		task.wait(0.1)
	end
	saving[player] = true
	local ok, reason = core:save(entry.profile, false)
	saving[player] = nil
	if not ok then
		log:warn("save falhou para", player.Name, reason)
		if reason == ProfileCore.Reasons.LockLost then
			kick(player, "data.lost_lock")
		end
	end
	return ok
end

-- Agenda um salvamento em até SAVE_SOON_DELAY segundos (vários pedidos viram um só).
-- Usado depois de eventos importantes (drop raro, compra, recompensa) sem gravar a cada roll.
local SAVE_SOON_DELAY = 8
local saveSoon: { [Player]: boolean } = {}
function PlayerDataService.SaveSoon(player: Player)
	if saveSoon[player] or not entries[player] then
		return
	end
	saveSoon[player] = true
	task.delay(SAVE_SOON_DELAY, function()
		saveSoon[player] = nil
		if entries[player] then
			PlayerDataService.SaveNow(player)
		end
	end)
end

-- Avisa o cliente que uma chave mudou (para quem altera a tabela direto, sem Set)
function PlayerDataService.Replicate(player: Player, key: string)
	local data = PlayerDataService.GetData(player)
	if data and not table.find(DataConfig.PrivateKeys, key) then
		Net.fire("DataChanged", player, key, TableUtil.deepCopy(data[key]))
	end
end

------------------------------------------------------------------------------------
-- Ciclo de vida

local function warnIfLarge(player: Player, data: { [string]: any })
	local ok, encoded = pcall(HttpService.JSONEncode, HttpService, data)
	-- Limite do Roblox é 4 MB por chave; avisamos bem antes
	if ok and #encoded > 1_000_000 then
		log:warn(`perfil de {player.Name} está grande: {#encoded} bytes`)
	end
end

local function release(player: Player)
	local entry = entries[player]
	if not entry then
		return
	end
	entry.profile.Data.LastLogout = os.time()
	if not entry.offline then
		while saving[player] do
			task.wait(0.1)
		end
		saving[player] = true
		warnIfLarge(player, entry.profile.Data)
		local ok, reason = core:save(entry.profile, true)
		saving[player] = nil
		if ok then
			log:info("perfil salvo e liberado:", player.Name)
		else
			log:warn("falha ao salvar saída de", player.Name, reason)
		end
	end
	entries[player] = nil
end

local function onPlayerAdded(player: Player)
	if entries[player] or loading[player] then
		return
	end
	loading[player] = true
	local profile, reason
	if offlineOnly then
		reason = ProfileCore.Reasons.Error
	else
		profile, reason = core:load(keyFor(player))
	end
	loading[player] = nil

	local offline = false
	if not profile then
		if reason == ProfileCore.Reasons.Error and RunService:IsStudio() then
			-- Studio sem "Enable Studio Access to API Services": perfil temporário
			log:warn("DataStore indisponível no Studio; usando perfil temporário (sem salvar)")
			local data = TableUtil.deepCopy(DataConfig.Template)
			data.CreatedAt = os.time()
			profile = {
				Key = keyFor(player),
				Data = data,
				Meta = {},
				IsNew = true,
				LockLost = false,
				Released = false,
			}
			offline = true
		else
			log:warn("não foi possível carregar", player.Name, reason)
			kick(
				player,
				if reason == ProfileCore.Reasons.Locked
					then "data.session_locked"
					elseif reason == ProfileCore.Reasons.FutureVersion then "data.future_version"
					else "data.load_failed"
			)
			return
		end
	end
	assert(profile)

	-- Saiu enquanto carregava: devolve a trava sem demora
	if player.Parent ~= Players then
		if not offline then
			core:save(profile, true)
		end
		return
	end

	entries[player] = { profile = profile, offline = offline }
	log:info(`perfil carregado: {player.Name} (novo: {profile.IsNew}, offline: {offline})`)
	PlayerDataService.Loaded:Fire(player, profile.Data)

	Net.fire("Notify", player, "welcome", { game = GameConfig.GameName })
	if offline then
		Net.fire("Notify", player, "data.studio_offline")
	end
end

local function autosaveLoop()
	while true do
		task.wait(DataConfig.AutosaveInterval)
		local players = {}
		for player in entries do
			table.insert(players, player)
		end
		-- Espalha os saves no intervalo para não estourar o limite de requisições
		local spacing = math.min(2, DataConfig.AutosaveInterval / math.max(1, #players) / 2)
		for _, player in players do
			if entries[player] then
				task.spawn(PlayerDataService.SaveNow, player)
				task.wait(spacing)
			end
		end
	end
end

------------------------------------------------------------------------------------
-- Handlers de rede

local function handleGetSnapshot(player: Player)
	local data = PlayerDataService.GetData(player)
	if not data then
		Net.fail(Net.Codes.NotReady)
	end
	return clientView(data :: any)
end

local function handleSetSetting(player: Player, key: string, value: boolean)
	local data = PlayerDataService.GetData(player)
	if not data then
		Net.fail(Net.Codes.NotReady)
	end
	assert(data)
	-- Dupla checagem além do Validator: só configurações permitidas
	if not table.find(DataConfig.ClientSettings, key) then
		Net.fail(Net.Codes.InvalidArgs)
	end
	local settings = TableUtil.deepCopy(data.Settings)
	settings[key] = value
	PlayerDataService.Set(player, "Settings", settings)
	return settings
end

------------------------------------------------------------------------------------

function PlayerDataService.Init()
	local isStudio = RunService:IsStudio()
	if isStudio and game.GameId == 0 then
		offlineOnly = true
		log:warn("place não publicado: DataStore desativado, perfis temporários (nada é salvo)")
	end
	local ok, store = pcall(DataStoreService.GetDataStore, DataStoreService, DataConfig.StoreName)
	if not ok then
		log:warn("DataStore indisponível:", store)
		if isStudio then
			offlineOnly = true
		end
		-- No jogo publicado o load vai falhar e o jogador recebe a mensagem de erro (nada é perdido)
		store = {
			UpdateAsync = function()
				error("DataStore indisponível")
			end,
		}
	end
	core = ProfileCore.new({
		store = store :: any,
		jobId = if game.JobId ~= "" then game.JobId else "studio-" .. HttpService:GenerateGUID(false),
		template = DataConfig.Template,
		version = DataConfig.SchemaVersion,
		migrations = Migrations,
		lockTimeout = DataConfig.SessionLockTimeout,
		maxAttempts = if isStudio then DataConfig.StudioMaxAttempts else DataConfig.MaxAttempts,
		retryBaseDelay = DataConfig.RetryBaseDelay,
		now = os.time,
		wait = function(seconds)
			task.wait(seconds)
		end,
		log = coreLog,
		deepCopy = TableUtil.deepCopy,
		reconcile = TableUtil.reconcile,
	})

	Net.handle("GetSnapshot", handleGetSnapshot)
	Net.handle("SetSetting", handleSetSetting)
end

function PlayerDataService.Start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(release)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
	task.spawn(autosaveLoop)

	game:BindToClose(function()
		local pending = 0
		for player in entries do
			pending += 1
			task.spawn(function()
				release(player)
				pending -= 1
			end)
		end
		local deadline = os.clock() + DataConfig.ShutdownTimeout
		while pending > 0 and os.clock() < deadline do
			task.wait(0.1)
		end
		if pending > 0 then
			log:warn(`desligamento: {pending} perfis não terminaram de salvar a tempo`)
		end
	end)
end

return PlayerDataService
