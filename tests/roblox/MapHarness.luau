--[[
	Executa o código REAL do mapa (MapService/MapBuilder/BaseBuilder) fora do Roblox, com o
	runtime Lune (que simula Instances). Pega erros de execução, roda o MapValidator e testa
	estados da base (RB0, RB5, dono). Gera build/map_preview.json para a imagem do layout.

	Uso: python tools/run_tests.py   (roda junto com os testes puros)
]]

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local taskLib = require("@lune/task")

local Instance = roblox.Instance

-- DataModel com a mesma árvore que o Rojo monta (default.project.json)
local game = Instance.new("DataModel")
local realServices = {}
for _, name in { "Workspace", "Lighting", "ReplicatedStorage", "ServerScriptService" } do
	realServices[name] = game:GetService(name)
end

local pathOf = {} -- nome completo da Instance -> arquivo
local function mount(dir: string, parent: any)
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
shared.Parent = realServices.ReplicatedStorage
mount("src/shared", shared)
local server = Instance.new("Folder")
server.Name = "Server"
server.Parent = realServices.ServerScriptService
mount("src/server", server)

-- Serviços que dependem do Roblox real viram stubs
local function signal()
	return { Connect = function() return { Disconnect = function() end } end, Once = function() end }
end
local tags = {}
local stubs = {
	RunService = {
		IsStudio = function() return true end,
		IsServer = function() return true end,
		IsClient = function() return false end,
		RenderStepped = signal(),
		Heartbeat = signal(),
	},
	Players = { GetPlayers = function() return {} end, PlayerAdded = signal(), PlayerRemoving = signal() },
	ProximityPromptService = { PromptTriggered = signal() },
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
}
local gameProxy = {
	GetService = function(_, name)
		return stubs[name] or realServices[name] or error("serviço sem stub no harness: " .. name)
	end,
}

local RandomStub = {}
function RandomStub.new(seed)
	local state = (seed or 1) % 2147483647
	local obj = {}
	function obj:NextNumber(a, b)
		state = (state * 48271) % 2147483647
		local t = state / 2147483647
		return (a or 0) + ((b or 1) - (a or 0)) * t
	end
	return obj
end

local baseEnv = {
	math = math, string = string, table = table, os = os, coroutine = coroutine, utf8 = utf8,
	bit32 = bit32, buffer = buffer, debug = debug, print = print, warn = function(...) print("[warn]", ...) end,
	error = error, assert = assert, pcall = pcall, xpcall = xpcall, select = select, type = type,
	typeof = typeof, tostring = tostring, tonumber = tonumber, ipairs = ipairs, pairs = pairs, next = next,
	setmetatable = setmetatable, getmetatable = getmetatable, rawget = rawget, rawset = rawset,
	rawequal = rawequal, rawlen = rawlen, unpack = table.unpack,
	task = taskLib, game = gameProxy, workspace = realServices.Workspace, Random = RandomStub,
}
for name, value in roblox do
	if baseEnv[name] == nil then
		baseEnv[name] = value
	end
end

local cache = {}
local function requireModule(target)
	if type(target) == "string" then
		return require(target)
	end
	local key = target:GetFullName()
	if cache[key] ~= nil then
		return cache[key]
	end
	local path = pathOf[key] or error("módulo não encontrado: " .. key)
	-- O Lune copia as chaves do ambiente (não usa __index), então montamos a tabela completa
	local env = table.clone(baseEnv)
	env.script = target
	env.require = requireModule
	local chunk = luau.load(fs.readFile(path), { debugName = path, environment = env })
	local result = chunk()
	cache[key] = result
	return result
end

------------------------------------------------------------------------------------

local failures = 0
local function check(condition: boolean, message: string)
	if condition then
		print("  ✓ " .. message)
	else
		failures += 1
		print("  ✗ " .. message)
	end
end

print("\n[Harness] Construindo o mapa com o código real (Lune)...")
local MapService = requireModule(server.Services.MapService)
MapService.Init()
local problems = MapService.ValidateMap()
for _, problem in problems do
	print("    - " .. problem)
end
check(#problems == 0, "MapValidator sem problemas")

local workspace = realServices.Workspace
local map = workspace:FindFirstChild("Map")
check(map ~= nil, "Workspace.Map existe")
for _, name in { "Environment", "Paths", "Conveyor", "Hub", "Shops", "Towers", "Social" } do
	check(map and map:FindFirstChild(name) ~= nil, "Map/" .. name)
end
local runtime = workspace:FindFirstChild("Runtime")
for _, name in { "Characters", "Effects", "Temporary" } do
	check(runtime and runtime:FindFirstChild(name) ~= nil, "Runtime/" .. name)
end

local bases = workspace:FindFirstChild("Bases")
check(bases and #bases:GetChildren() == 10, "10 bases em Workspace.Bases")
local base03 = bases:FindFirstChild("Base03")
local floor01 = base03.Floors.Floor01
check(#floor01.SideA:GetChildren() == 4 and #floor01.SideB:GetChildren() == 4, "Floor01: SideA = 4 e SideB = 4")
check(base03.Floors:FindFirstChild("Floor02") == nil, "RB0: Floor02 não existe")
for i = 1, 8 do
	local slot = floor01:FindFirstChild(string.format("Slot%02d", i), true)
	local unlocked = slot:GetAttribute("Unlocked")
	check(unlocked == (i <= 4), string.format("RB0: Slot%02d %s", i, if i <= 4 then "liberado" else "bloqueado"))
end

-- PlayerSpawn: SpawnLocation na entrada, no piso, olhando para dentro da base
local BaseConfig = requireModule(shared.Config.BaseConfig)
for i = 1, 10 do
	local base = bases:FindFirstChild(string.format("Base%02d", i))
	local spawn = base.PlayerSpawn
	local origin = base.WorldPivot -- LookVector = frente da base (para o corredor)
	local localPos = origin:PointToObjectSpace(spawn.CFrame.Position)
	local inward = -origin.LookVector
	local ok = spawn.ClassName == "SpawnLocation"
		and spawn.Neutral == false
		and spawn.CanCollide == false
		and math.abs(localPos.X) < 0.01
		and math.abs(localPos.Z - BaseConfig.Spawn.z) < 0.01
		and math.abs((spawn.CFrame.Position.Y + spawn.Size.Y / 2) - (BaseConfig.PlatformThickness + 0.2)) < 0.01
		and spawn.CFrame.LookVector:Dot(inward) > 0.999
	check(ok, string.format("Base%02d: PlayerSpawn na entrada, no piso, olhando para dentro", i))
end

-- RB5: Floor02 aparece, Slot09 liberado, Slot10 bloqueado
local BaseBuilder = requireModule(server.Map.BaseBuilder)
local progression = MapService.Progression
local before, after = BaseBuilder.applyState(base03, progression:state(5), progression)
check(before == 1 and after == 2, "RB5: de 1 para 2 andares")
local floor02 = base03.Floors:FindFirstChild("Floor02")
check(floor02 ~= nil, "RB5: Floor02 construído")
check(#floor02.SideA:GetChildren() == 4 and #floor02.SideB:GetChildren() == 4, "Floor02: SideA = 4 e SideB = 4")
check(floor02:FindFirstChild("Slot09", true):GetAttribute("Unlocked") == true, "RB5: Slot09 liberado")
check(floor02:FindFirstChild("Slot10", true):GetAttribute("Unlocked") == false, "RB5: Slot10 bloqueado")
check(floor01:FindFirstChild("Ramp") ~= nil, "RB5: rampa do Floor01 para o Floor02")
check(#MapService.ValidateMap() == 0, "MapValidator sem problemas com Floor02")
BaseBuilder.applyState(base03, progression:state(0), progression)
check(base03.Floors:FindFirstChild("Floor02") == nil and floor01:FindFirstChild("Ramp") == nil, "volta ao RB0 remove Floor02 e rampa")

-- Dono na placa e base livre
BaseBuilder.setOwner(base03, { displayName = "Lindson", userName = "alandias123" })
local display = base03.OwnerSign.Board.OwnerDisplay
check(display.PlayerName.Text == "Lindson" and display.Title.Text == "BASE DE", "placa mostra o dono")
BaseBuilder.setOwner(base03, nil)
check(display.PlayerName.Text == "BASE LIVRE", "placa volta para BASE LIVRE")

-- Estatísticas e dados para a imagem do layout
local partCount, byFolder = 0, {}
local preview = {}
local function collect(root, label)
	for _, obj in root:GetDescendants() do
		if obj:IsA("BasePart") then
			partCount += 1
			byFolder[label] = (byFolder[label] or 0) + 1
			local cf = obj.CFrame
			local look = cf.LookVector
			table.insert(preview, {
				g = label,
				n = obj.Name,
				x = cf.Position.X, y = cf.Position.Y, z = cf.Position.Z,
				sx = obj.Size.X, sy = obj.Size.Y, sz = obj.Size.Z,
				lx = look.X, lz = look.Z,
				c = { math.floor(obj.Color.R * 255), math.floor(obj.Color.G * 255), math.floor(obj.Color.B * 255) },
				t = obj.Transparency,
				shape = if obj:IsA("Part") then tostring(obj.Shape) else obj.ClassName,
			})
		end
	end
end
for _, child in map:GetChildren() do
	collect(child, "Map/" .. child.Name)
end
collect(bases, "Bases")
print(string.format("\n[Harness] %d peças no total", partCount))
for label, count in byFolder do
	print(string.format("    %-18s %d", label, count))
end
fs.writeDir("build")
fs.writeFile("build/map_preview.json", serde.encode("json", preview))

if failures > 0 then
	error(string.format("[Harness] %d verificação(ões) falharam", failures), 0)
end
print("[Harness] OK")
