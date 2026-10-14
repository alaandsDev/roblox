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
	local state = math.floor(math.abs(seed or 1)) % 2147483647
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

-- O CFrame.lookAt do Lune 0.10.4 espelha o eixo Z (lookAt(0 -> (1,0,1)) dá LookVector (0.7,0,-0.7)).
-- No Roblox de verdade está certo; aqui trocamos por uma versão correta para os testes/prévia.
local function fixedLookAt(position, target, up)
	local look = (target - position).Unit
	local right = look:Cross(up or roblox.Vector3.new(0, 1, 0)).Unit
	return roblox.CFrame.fromMatrix(position, right, right:Cross(look), -look)
end
local FixedCFrame = setmetatable({ lookAt = fixedLookAt }, { __index = roblox.CFrame })

local baseEnv = {
	CFrame = FixedCFrame,
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

do
	-- ESTEIRA TERRESTRE: no chão, sem pilares, bordas baixas, abertas nos cruzamentos
	local MapCfg = requireModule(shared.Config.MapConfig)
	local Layout = requireModule(shared.Modules.MapLayout).new(MapCfg, requireModule(shared.Config.BaseConfig))
	local conveyor = map:FindFirstChild("Conveyor")
	local highest, pillars, railsOnPath, belts, rails = -math.huge, 0, 0, 0, 0
	for _, part in conveyor:GetDescendants() do
		if part:IsA("BasePart") then
			-- topo real da peça (cilindros deitados usam Size.X como altura)
			local height = if part.Shape == roblox.Enum.PartType.Cylinder then part.Size.X else part.Size.Y
			highest = math.max(highest, part.CFrame.Position.Y + height / 2)
			if part.Name == "Pillar" then
				pillars += 1
			elseif part.Name == "Belt" then
				belts += 1
			elseif part.Name == "Rail" then
				rails += 1
				local half = part.Size.Z / 2 - 0.5
				local look = part.CFrame.LookVector
				for _, t in { -half, 0, half } do
					local p = part.CFrame.Position + look * t
					if Layout:onPath(p.X, p.Z) then
						railsOnPath += 1
					end
				end
			end
		end
	end
	local top = Layout:conveyorTop()
	check(pillars == 0, "esteira: nenhum pilar (pista terrestre)")
	check(top >= 0.3 and top <= 0.8, string.format("esteira: superfície a %.2f stud do chão (0,3–0,8)", top))
	check(highest <= 1.5, string.format("esteira: nada passa de %.2f stud (personagem R6 ~5 studs fica bem mais alto; não bloqueia a visão)", highest))
	check(belts == #Layout:conveyorPath().points, "esteira: mesma rota fechada de antes (" .. belts .. " trechos)")
	check(rails > 0 and railsOnPath == 0, "esteira: bordas abertas onde cruza caminhos (nenhuma borda em cima de caminho)")
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

do
	-- VISUAL OVERHAUL: layout funcional preservado (posições, spawns, slots, prompts) e nada bloqueando caminhos
	local MapCfg = requireModule(shared.Config.MapConfig)
	local Layout = requireModule(shared.Modules.MapLayout).new(MapCfg, BaseConfig)
	local SlotLayout = requireModule(shared.Modules.BaseLayout).new(BaseConfig)
	local moved, slotsOff = 0, 0
	for i = 1, 10 do
		local base = bases:FindFirstChild(string.format("Base%02d", i))
		local p = Layout:base(i)
		local pivot = base.WorldPivot.Position
		if math.abs(pivot.X - p.x) > 0.01 or math.abs(pivot.Z - p.z) > 0.01 or math.abs(pivot.Y) > 0.01 then
			moved += 1
		end
		for slotId = 1, 8 do
			local slot = base.Floors.Floor01:FindFirstChild(string.format("Slot%02d", slotId), true)
			local expected = SlotLayout:slotPosition(slotId)
			local got = base.WorldPivot:PointToObjectSpace(slot.CharacterPoint.CFrame.Position)
			if (got - roblox.Vector3.new(expected.x, expected.y, expected.z)).Magnitude > 0.01 then
				slotsOff += 1
			end
			local pedestal = slot.Pedestal
			local top = pedestal.CFrame.Position.Y + pedestal.Size.Y / 2
			if math.abs(top - slot.CharacterPoint.CFrame.Position.Y) > 0.01 then
				slotsOff += 1
			end
		end
	end
	check(moved == 0, "bases: as 10 continuam exatamente na posição do layout")
	check(slotsOff == 0, "slots: CharacterPoint no lugar e no topo do pedestal blocky (80 slots)")

	local function near(part, spot, label)
		local pos = part and part.CFrame.Position
		check(pos ~= nil and math.abs(pos.X - spot.x) < 0.01 and math.abs(pos.Z - spot.z) < 0.01, label .. " na posição do MapConfig")
	end
	near(map.Hub:FindFirstChild("HubSpawn", true), MapCfg.Spawns.Hub, "HubSpawn")
	near(map.Shops:FindFirstChild("ShopSpawn", true), MapCfg.Spawns.Shop, "ShopSpawn")
	near(map.Towers:FindFirstChild("TowerEntrance", true), MapCfg.Spawns.TowerEntrance, "TowerEntrance")
	near(map.Hub:FindFirstChild("Plaza", true), { x = MapCfg.Hub.Center.x, z = MapCfg.Hub.Center.z }, "Praça do Hub")

	-- Prompts das áreas funcionais
	local prompts = {}
	for _, obj in map:GetDescendants() do
		if obj:IsA("ProximityPrompt") then
			prompts[obj:GetAttribute("InteractId")] = true
		end
	end
	for _, id in { "Market", "DiceShop", "Sell", "Towers", "Fusion", "Missions", "Trade" } do
		check(prompts[id] == true, "prompt de " .. id .. " presente")
	end

	-- Nada sólido na altura do personagem em cima dos caminhos (exceto o altar do Hub, que É o destino)
	local allowed = { AltarTier1 = true, AltarTier2 = true, AltarTier3 = true, DicePedestal = true, TowerTier1 = true }
	local blocking = {}
	for _, root in { map, bases } do
		for _, part in root:GetDescendants() do
			if part:IsA("BasePart") and part.CanCollide and not allowed[part.Name] then
				local pos = part.CFrame.Position
				local height = if part:IsA("Part") and part.Shape == roblox.Enum.PartType.Cylinder then part.Size.X else part.Size.Y
				local top, bottom = pos.Y + height / 2, pos.Y - height / 2
				if top > 1.6 and bottom < 5 then
					-- centro e cantos da projeção da peça no chão (pega paredes largas também)
					local hx, hz = part.Size.X / 2 - 0.3, part.Size.Z / 2 - 0.3
					for _, o in { { 0, 0 }, { hx, hz }, { -hx, hz }, { hx, -hz }, { -hx, -hz } } do
						local p = (part.CFrame * roblox.CFrame.new(o[1], 0, o[2])).Position
						if Layout:onPath(p.X, p.Z) then
							table.insert(blocking, part:GetFullName())
							break
						end
					end
				end
			end
		end
	end
	for i = 1, math.min(#blocking, 8) do
		print("    - bloqueia caminho: " .. blocking[i])
	end
	check(#blocking == 0, "caminhos livres: nenhuma peça sólida na altura do jogador sobre os caminhos")

	-- Decoração do ambiente fora das bases e longe dos spawns
	local decorBad = 0
	for _, part in map.Environment.Decor:GetDescendants() do
		if part:IsA("BasePart") then
			local pos = part.CFrame.Position
			if Layout:insideAnyBase(pos.X, pos.Z) then
				decorBad += 1
			end
			for _, spot in Layout:spawnPoints() do
				if math.sqrt((pos.X - spot.x) ^ 2 + (pos.Z - spot.z) ^ 2) < 6 then
					decorBad += 1
				end
			end
			if part.CanCollide and Layout:onPath(pos.X, pos.Z, 1) then
				decorBad += 1
			end
		end
	end
	check(decorBad == 0, "decoração: nada dentro das bases, perto de spawns ou com colisão encostada nos caminhos")
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
do
	-- Iluminação entre andares: cada andar N >= 2 traz luminárias sob o piso (ilumina o N-1);
	-- genérico de 2 a MaxFloors, sem caso especial do Floor02; o andar do topo não tem teto
	local BaseConfig = requireModule(shared.Config.BaseConfig)
	local L = BaseConfig.FloorLighting
	local function lightsOf(floorModel: any): { any }
		local out = {}
		local folder = floorModel and floorModel:FindFirstChild("UnderLights", true)
		if folder then
			for _, lamp in folder:GetChildren() do
				local light = lamp:FindFirstChildOfClass("PointLight")
				if light then
					table.insert(out, { lamp = lamp, light = light })
				end
			end
		end
		return out
	end
	check(#lightsOf(floor01) == 0, "luz entre andares: Floor01 (térreo) não tem luminárias sob o piso")
	local rb = progression:floorUnlockRebirth(BaseConfig.MaxFloors)
	BaseBuilder.applyState(base03, progression:state(rb), progression)
	local allOk = true
	for n = 2, BaseConfig.MaxFloors do
		local model = base03.Floors:FindFirstChild(string.format("Floor%02d", n))
		local below = base03.Floors:FindFirstChild(string.format("Floor%02d", n - 1))
		local lights = lightsOf(model)
		if #lights ~= L.Columns * L.Rows then
			allOk = false
		end
		for _, item in lights do
			local p = item.lamp.CFrame.Position.Y
			local platform = model:FindFirstChild("Platform")
			local floorBelowY = below:FindFirstChild("Platform").CFrame.Position.Y
			-- sob o piso de cima, acima do andar coberto; brilho baixo, sem sombra, alcance curto, sem colisão
			if not (p < platform.CFrame.Position.Y and p > floorBelowY + 10) then
				allOk = false
			end
			if item.light.Brightness > 1 or item.light.Shadows or item.light.Range > BaseConfig.FloorHeight + 2 or item.lamp.CanCollide then
				allOk = false
			end
		end
	end
	check(allOk, "luz entre andares: Floor02..Floor0" .. BaseConfig.MaxFloors .. " iluminam o andar de baixo (grade completa, brilho <= 1, sem sombra, sem colisão)")
	check(#MapService.ValidateMap() == 0, "MapValidator sem problemas com " .. BaseConfig.MaxFloors .. " andares iluminados")
end
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
			local right, up = cf.RightVector, cf.UpVector
			table.insert(preview, {
				g = label,
				n = obj.Name,
				x = cf.Position.X, y = cf.Position.Y, z = cf.Position.Z,
				sx = obj.Size.X, sy = obj.Size.Y, sz = obj.Size.Z,
				lx = look.X, lz = look.Z,
				-- orientação completa (render em perspectiva da câmera do jogador)
				r = { right.X, right.Y, right.Z }, u = { up.X, up.Y, up.Z }, l = { look.X, look.Y, look.Z },
				collide = obj.CanCollide, material = tostring(obj.Material),
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
-- ESTEIRA: transporte físico (AssemblyLinearVelocity nas partes Belt) = mesmo sentido e velocidade
-- da animação do cliente (MapConfig.Conveyor, ordem do caminho). A física do personagem em cima só
-- é confirmável no Studio (STUDIO_SMOKE_TEST.md, seção da esteira).
do
	local conveyorConfig = requireModule(shared.Config.MapConfig).Conveyor
	local conveyorFolder = map:FindFirstChild("Conveyor", true)
	local belts, aligned, joints, jointsInert = 0, 0, 0, 0
	-- Lune: propriedade nunca definida não tem valor padrão -> zero
	local function velocityOf(part)
		local ok, v = pcall(function()
			return part.AssemblyLinearVelocity
		end)
		return if ok then v else roblox.Vector3.new(0, 0, 0)
	end
	for _, obj in (conveyorFolder or map):GetDescendants() do
		if obj:IsA("BasePart") and obj.Name == "Belt" then
			belts += 1
			local v = velocityOf(obj)
			local forward = obj.CFrame.LookVector
			local expected = forward * conveyorConfig.Speed * conveyorConfig.Direction
			if (v - roblox.Vector3.new(expected.X, 0, expected.Z)).Magnitude < 1e-3 and math.abs(v.Y) < 1e-6 and obj.Anchored and obj.CanCollide then
				aligned += 1
			end
		elseif obj:IsA("BasePart") and obj.Name == "Joint" then
			joints += 1
			if not obj.CanCollide and velocityOf(obj).Magnitude < 1e-6 then
				jointsInert += 1
			end
		end
	end
	check(belts > 0 and aligned == belts, string.format("esteira: %d/%d trechos com velocidade física = %d studs/s no sentido visual (horizontal, ancorados, pisáveis)", aligned, belts, conveyorConfig.Speed))
	check(joints > 0 and jointsInert == joints, "esteira: emendas decorativas (sem colisão, sem velocidade)")
	-- Setas: a PONTA de cada chevron (encontro das 2 barras) aponta no sentido da velocidade do trecho
	-- mais próximo — com CFrame real e trechos em todas as orientações da pista oval
	local beltList, arrows = {}, {}
	for _, obj in (conveyorFolder or map):GetDescendants() do
		if obj:IsA("BasePart") and obj.Name == "Belt" then
			table.insert(beltList, obj)
		elseif obj:IsA("BasePart") and obj.Name == "Arrow" then
			table.insert(arrows, obj)
		end
	end
	local arrowsOk, pairsChecked = 0, 0
	for i, bar in arrows do
		-- a outra barra do mesmo chevron é a mais próxima
		local mate, best = nil, math.huge
		for j, other in arrows do
			local dist = (other.CFrame.Position - bar.CFrame.Position).Magnitude
			if j ~= i and dist < best then
				mate, best = other, dist
			end
		end
		if mate and best < 3 then
			pairsChecked += 1
			local center = (bar.CFrame.Position + mate.CFrame.Position) / 2
			local tip = nil
			local tipDist = math.huge
			for _, b in { bar, mate } do
				for _, sz in { -1.3, 1.3 } do
					local p = (b.CFrame * roblox.CFrame.new(0, 0, sz)).Position
					local dd = (p - center).Magnitude
					if dd < tipDist then
						tip, tipDist = p, dd
					end
				end
			end
			-- trecho mais próximo
			local nearest, nd = nil, math.huge
			for _, belt in beltList do
				local dd = (belt.CFrame.Position - center).Magnitude
				if dd < nd then
					nearest, nd = belt, dd
				end
			end
			local flow = velocityOf(nearest)
			local pointing = (tip - center) - roblox.Vector3.new(0, (tip - center).Y, 0)
			if pointing:Dot(flow) > 0 then
				arrowsOk += 1
			end
		end
	end
	check(pairsChecked > 0 and arrowsOk == pairsChecked, string.format("esteira: %d/%d barras de seta com a ponta no sentido da velocidade física (= animação)", arrowsOk, pairsChecked))
end

do -- World Art Pass: linguagem blocky aplicada por papel, sem tocar na esteira
	local E = roblox.Enum
	local studded, groundStudded, ground, conveyorTouched, styled, inlet, trees, species = 0, 0, 0, 0, 0, 0, 0, {}
	for _, d in workspace:GetDescendants() do
		if d:IsA("BasePart") then
			if d:GetAttribute("ArtStyled") == true then
				styled += 1
			end
			if d.TopSurface == E.SurfaceType.Studs then
				studded += 1
			end
			if d.BottomSurface == E.SurfaceType.Inlet then
				inlet += 1
			end
			if d:FindFirstAncestor("Conveyor") and d:GetAttribute("ArtStyled") == true and d.TopSurface == E.SurfaceType.Studs then
				conveyorTouched += 1
			end
			if d.Name == "Grass" or d.Name == "Platform" then
				ground += 1
				if d.TopSurface == E.SurfaceType.Studs then
					groundStudded += 1
				end
			end
		elseif d:IsA("Model") and d:GetAttribute("Species") then
			trees += 1
			species[d:GetAttribute("Species")] = true
		end
	end
	local nSpecies = 0
	for _ in species do
		nSpecies += 1
	end
	check(styled > 1000 and studded > 400 and inlet > 100, string.format("art pass: %d peças estilizadas, %d com studs, %d com inlet", styled, studded, inlet))
	check(ground > 0 and groundStudded == ground, string.format("art pass: grama/pisos com studs (%d/%d)", groundStudded, ground))
	check(conveyorTouched == 0, "art pass: esteira intocada (física/seta/animação preservadas)")
	check(trees >= 30 and nSpecies == 4, string.format("art pass: %d árvores, %d espécies", trees, nSpecies))
end

-- SKY: exatamente 1 Sky efetivo em Lighting (ClassicRobloxSky tem prioridade, nada é clonado)
do
	local MapBuilder = requireModule(server.Map.MapBuilder)
	local MapCfg = requireModule(shared.Config.MapConfig)
	local lighting = realServices.Lighting
	local function skies()
		local list = {}
		for _, c in lighting:GetChildren() do
			if c.ClassName == "Sky" then
				table.insert(list, c)
			end
		end
		return list
	end
	for _, c in skies() do
		c:Destroy()
	end
	local classic = Instance.new("Sky")
	classic.Name = MapCfg.Lighting.SkyName
	classic.Parent = lighting
	local old = Instance.new("Sky")
	old.Name = "Sky"
	old.Parent = lighting
	MapBuilder._chooseSky()
	local list = skies()
	check(#list == 1 and list[1] == classic, "Sky: com ClassicRobloxSky + Sky antigo sobra exatamente 1 (o ClassicRobloxSky, mesma instância)")
	MapBuilder._chooseSky()
	check(#skies() == 1 and skies()[1] == classic, "Sky: chamar de novo não duplica nem clona")
	-- contêiner (Model com o Sky dentro): o Sky é MOVIDO para Lighting, o contêiner sai
	classic:Destroy()
	local box = Instance.new("Model")
	box.Name = MapCfg.Lighting.SkyName
	local inner = Instance.new("Sky")
	inner.Parent = box
	box.Parent = lighting
	MapBuilder._chooseSky()
	list = skies()
	check(#list == 1 and list[1] == inner and inner.Name == MapCfg.Lighting.SkyName and box.Parent == nil, "Sky: ClassicRobloxSky salvo dentro de um contêiner vira o único Sky efetivo (movido, sem clonar)")
	check(MapCfg.Lighting.SkyAssetId == 339406852 and MapCfg.Lighting.SkyName == "ClassicRobloxSky", "Sky: céu oficial = Classic Roblox Sky (339406852)")
	inner:Destroy()
end

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
