--[[
	Ambiente simulado do Roblox para rodar os módulos REAIS fora do Studio (runtime Lune).
	- Monta um DataModel com a mesma árvore do Rojo (src/shared e src/server).
	- Serviços que dependem do Roblox real (Players, RunService, DataStore, rede...) viram stubs.
	- newContext() cria um "contexto Luau" com cache de require próprio. Dois contextos =
	  duas cópias dos módulos, exatamente como a Barra de comandos do Studio vs. os scripts.
]]

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local taskLib = require("@lune/task")

local Instance = roblox.Instance

local Env = {}

function Env.signal()
	local s = { listeners = {} }
	function s:Connect(fn)
		local entry = { fn = fn, connected = true }
		table.insert(self.listeners, entry)
		return {
			Connected = true,
			Disconnect = function()
				entry.connected = false
			end,
		}
	end
	function s:Once(fn)
		local connection
		connection = self:Connect(function(...)
			connection.Disconnect()
			fn(...)
		end)
		return connection
	end
	function s:Fire(...)
		for _, entry in self.listeners do
			if entry.connected then
				taskLib.spawn(entry.fn, ...)
			end
		end
	end
	return s
end

function Env.create()
	local game = Instance.new("DataModel")
	local real = {}
	for _, name in { "Workspace", "Lighting", "ReplicatedStorage", "ServerScriptService", "ServerStorage" } do
		real[name] = game:GetService(name)
	end

	local pathOf = {}
	local function mount(dir, parent)
		for _, entry in fs.readDir(dir) do
			local full = dir .. "/" .. entry
			if fs.isDir(full) then
				local folder = Instance.new("Folder")
				folder.Name = entry
				folder.Parent = parent
				mount(full, folder)
			elseif string.sub(entry, -5) == ".luau" then
				local className, name = "ModuleScript", string.sub(entry, 1, -6)
				if string.sub(name, -7) == ".server" then
					className, name = "Script", string.sub(name, 1, -8)
				elseif string.sub(name, -7) == ".client" then
					className, name = "LocalScript", string.sub(name, 1, -8)
				end
				local module = Instance.new(className)
				module.Name = name
				module.Parent = parent
				pathOf[module:GetFullName()] = full
			end
		end
	end
	local shared = Instance.new("Folder")
	shared.Name = "Shared"
	shared.Parent = real.ReplicatedStorage
	mount("src/shared", shared)
	local server = Instance.new("Folder")
	server.Name = "Server"
	server.Parent = real.ServerScriptService
	mount("src/server", server)

	-- Jogadores falsos
	local Players = {
		list = {},
		PlayerAdded = Env.signal(),
		PlayerRemoving = Env.signal(),
		CharacterAutoLoads = true,
		RespawnTime = 5,
	}
	function Players:GetPlayers()
		return table.clone(self.list)
	end
	function Players:GetPlayerByUserId(userId)
		for _, player in self.list do
			if player.UserId == userId then
				return player
			end
		end
		return nil
	end
	function Players:GetUserThumbnailAsync(userId)
		return "rbxthumb://type=AvatarHeadShot&id=" .. userId
	end
	function Players:GetNameFromUserIdAsync(userId)
		return "user" .. userId
	end

	local tags = {}
	local stubs = {
		Players = Players,
		RunService = {
			IsStudio = function()
				return true
			end,
			IsServer = function()
				return true
			end,
			IsClient = function()
				return false
			end,
			RenderStepped = Env.signal(),
			Heartbeat = Env.signal(),
		},
		ProximityPromptService = { PromptTriggered = Env.signal() },
		CollectionService = {
			AddTag = function(_, instance, tag)
				tags[tag] = tags[tag] or {}
				tags[tag][instance:GetFullName()] = true
			end,
			RemoveTag = function(_, instance, tag)
				if tags[tag] then
					tags[tag][instance:GetFullName()] = nil
				end
			end,
			HasTag = function(_, instance, tag)
				return tags[tag] ~= nil and tags[tag][instance:GetFullName()] == true
			end,
		},
		DataStoreService = {
			GetDataStore = function()
				return {
					UpdateAsync = function()
						error("DataStore indisponível (harness)")
					end,
				}
			end,
			GetOrderedDataStore = function()
				return {}
			end,
		},
		HttpService = {
			GenerateGUID = function()
				return "guid-" .. tostring(math.random(1, 1e9))
			end,
			JSONEncode = function(_, value)
				return serde.encode("json", value)
			end,
			JSONDecode = function(_, text)
				return serde.decode("json", text)
			end,
		},
		MarketplaceService = {
			PromptGamePassPurchaseFinished = Env.signal(),
			UserOwnsGamePassAsync = function()
				return false
			end,
		},
		BadgeService = {},
		SoundService = {},
		TweenService = {
			Create = function()
				return { Play = function() end, Cancel = function() end }
			end,
		},
	}
	local gameProxy = {
		GameId = 0,
		JobId = "",
		BindToClose = function() end,
		GetService = function(_, name)
			return stubs[name] or real[name] or error("serviço sem stub no harness: " .. name)
		end,
	}

	local RandomStub = {}
	function RandomStub.new(seed)
		local state = (seed or os.clock() * 1e6) % 2147483647
		if state <= 0 then
			state = 12345
		end
		local obj = {}
		function obj:NextNumber(a, b)
			state = (state * 48271) % 2147483647
			local t = state / 2147483647
			return (a or 0) + ((b or 1) - (a or 0)) * t
		end
		function obj:NextInteger(a, b)
			return math.floor(obj:NextNumber(a, b + 1 - 1e-9))
		end
		return obj
	end

	-- Métodos que o Lune não implementa
	local function descendantsParts(model)
		local parts = {}
		for _, d in model:GetDescendants() do
			if d:IsA("BasePart") then
				table.insert(parts, d)
			end
		end
		return parts
	end
	pcall(roblox.implementMethod, "Model", "GetPivot", function(model)
		return model.WorldPivot
	end)
	pcall(roblox.implementMethod, "Model", "PivotTo", function(model, target)
		local delta = target * model.WorldPivot:Inverse()
		for _, part in descendantsParts(model) do
			part.CFrame = delta * part.CFrame
		end
		model.WorldPivot = target
	end)
	pcall(roblox.implementMethod, "BasePart", "GetPivot", function(part)
		return part.CFrame
	end)
	pcall(roblox.implementMethod, "BasePart", "PivotTo", function(part, target)
		part.CFrame = target
	end)

	local baseEnv = {
		math = math, string = string, table = table, os = os, coroutine = coroutine, utf8 = utf8,
		bit32 = bit32, buffer = buffer, debug = debug, print = print,
		warn = function(...)
			print("[warn]", ...)
		end,
		error = error, assert = assert, pcall = pcall, xpcall = xpcall, select = select, type = type,
		typeof = typeof, tostring = tostring, tonumber = tonumber, ipairs = ipairs, pairs = pairs,
		next = next, setmetatable = setmetatable, getmetatable = getmetatable, rawget = rawget,
		rawset = rawset, rawequal = rawequal, rawlen = rawlen, unpack = table.unpack,
		task = taskLib, game = gameProxy, workspace = real.Workspace, Random = RandomStub,
	}
	for name, value in roblox do
		if baseEnv[name] == nil then
			baseEnv[name] = value
		end
	end

	local env = {
		game = game,
		real = real,
		stubs = stubs,
		Players = Players,
		shared = shared,
		server = server,
		tags = tags,
	}

	-- Um contexto = um cache de require. overrides[fullName] substitui módulos (ex.: Net).
	function env.newContext(overrides)
		local cache = {}
		local function requireModule(target)
			if type(target) == "string" then
				return require(target)
			end
			local key = target:GetFullName()
			if overrides and overrides[key] ~= nil then
				return overrides[key]
			end
			if cache[key] ~= nil then
				return cache[key]
			end
			local path = pathOf[key] or error("módulo não encontrado: " .. key)
			local moduleEnv = table.clone(baseEnv)
			moduleEnv.script = target
			moduleEnv.require = requireModule
			local chunk = luau.load(fs.readFile(path), { debugName = path, environment = moduleEnv })
			local result = chunk()
			cache[key] = result
			return result
		end
		return requireModule
	end

	-- Jogador falso com o mínimo usado pelos Services
	local nextId = 1000
	function env.newPlayer(name)
		nextId += 1
		local player = {
			UserId = nextId,
			Name = name,
			DisplayName = name,
			Parent = Players,
			Character = nil,
			RespawnLocation = nil,
			CharacterAdded = Env.signal(),
			loads = 0,
			kicked = nil,
			attributes = {},
		}
		function player:GetAttribute(key)
			return self.attributes[key]
		end
		function player:SetAttribute(key, value)
			self.attributes[key] = value
		end
		function player:Kick(message)
			self.kicked = message
		end
		function player:LoadCharacterAsync()
			self.loads += 1
		end
		return player
	end

	function env.join(player)
		table.insert(Players.list, player)
		Players.PlayerAdded:Fire(player)
	end

	function env.leave(player)
		local index = table.find(Players.list, player)
		if index then
			table.remove(Players.list, index)
		end
		player.Parent = nil
		Players.PlayerRemoving:Fire(player)
	end

	return env
end

-- Espera uma condição (com limite) dando tempo para as threads do jogo rodarem
function Env.waitFor(condition, timeout)
	local deadline = os.clock() + (timeout or 3)
	while os.clock() < deadline do
		if condition() then
			return true
		end
		taskLib.wait(0.02)
	end
	return condition()
end

function Env.checker(title)
	local failures = 0
	local count = 0
	print(`\n[{title}]`)
	return {
		check = function(condition, message)
			count += 1
			if condition then
				print("  ✓ " .. message)
			else
				failures += 1
				print("  ✗ " .. message)
			end
		end,
		finish = function()
			print(`[{title}] {count - failures}/{count} verificações OK`)
			return failures
		end,
	}
end

return Env
