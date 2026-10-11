--[[
	Teste de INTEGRAÇÃO com os Services reais (Lune):
	PlayerDataService + MapService + BaseService + jogadores falsos.

	Inclui o teste de regressão do bug "GetPlayerBase = nil na Barra de comandos":
	a Barra de comandos do Studio carrega uma CÓPIA NOVA dos módulos; aqui isso é simulado
	com um segundo contexto de require.
]]

local process = require("@lune/process")
local task = require("@lune/task")
local Env = require("./Env")

local env = Env.create()
local T = Env.checker("Integração: Map -> BaseService -> jogador")
local check = T.check

-- Net falso: registra handlers e eventos enviados (sem RemoteEvents de verdade)
local sent = {}
local handlers = {}
local NetStub = {
	Codes = { RateLimited = "rate_limited", InvalidArgs = "invalid_args", NotReady = "not_ready", NotImplemented = "not_implemented", Internal = "internal" },
	handle = function(name, fn)
		handlers[name] = fn
	end,
	fire = function(name, player, ...)
		table.insert(sent, { name = name, player = player, args = { ... } })
	end,
	fireAll = function() end,
	fail = function(code)
		error({ code = code }, 0)
	end,
	initServer = function() end,
}
local overrides = { [env.shared.Modules.Net:GetFullName()] = NetStub }

local require1 = env.newContext(overrides)
local Services = env.server.Services
local PlayerDataService = require1(Services.PlayerDataService)
local MapService = require1(Services.MapService)
local BaseService = require1(Services.BaseService)

for _, service in { PlayerDataService, MapService, BaseService } do
	service.Init()
end
for _, service in { PlayerDataService, MapService, BaseService } do
	task.spawn(service.Start)
end

check(env.Players.CharacterAutoLoads == false, "CharacterAutoLoads desligado (personagem só depois da base)")

local p1 = env.newPlayer("alandias123")
local p2 = env.newPlayer("jogador2")
env.join(p1)
env.join(p2)
check(Env.waitFor(function()
	return p1:GetAttribute("BaseId") ~= nil and p2:GetAttribute("BaseId") ~= nil
end), "os dois jogadores receberam base")

local base1 = BaseService.GetPlayerBase(p1)
local base2 = BaseService.GetPlayerBase(p2)
check(base1 ~= nil and base2 ~= nil, "GetPlayerBase retorna a base")
check(base1 ~= base2, "bases diferentes")
check(base1 and base1:GetAttribute("BaseId") == p1:GetAttribute("BaseId"), "BaseId do jogador = BaseId da base")
check(base1 and base1:GetAttribute("OwnerUserId") == p1.UserId, "OwnerUserId da base = UserId do jogador")
check(base1 and BaseService.GetBaseOwner(base1) == p1, "GetBaseOwner(base) == jogador")
check(base2 and BaseService.GetBaseOwner(base2) == p2, "GetBaseOwner da segunda base == jogador2")
check(base1 and p1.RespawnLocation == base1:FindFirstChild("PlayerSpawn"), "RespawnLocation = PlayerSpawn da própria base")
check(Env.waitFor(function()
	return p1.loads == 1 and p2.loads == 1
end), "personagem carregado uma vez por jogador")

-- Regressão: contexto separado (Barra de comandos do Studio) com cópia NOVA dos módulos
local require2 = env.newContext(overrides)
local BaseServiceCopy = require2(Services.BaseService)
check(BaseServiceCopy ~= BaseService, "segundo contexto tem outra cópia do módulo (como a Barra de comandos)")
local fromCopy = BaseServiceCopy.GetPlayerBase(p1)
check(fromCopy == base1, "GetPlayerBase funciona na cópia (pelo atributo OwnerUserId)")
local MapCopy = require2(Services.MapService)
check(MapCopy.GetBase(3) ~= nil, "MapService.GetBase(3) funciona na cópia (busca em Workspace.Bases)")

-- Dev API aceitando o jogador
local ok, previewErr = pcall(BaseService.Dev.PreviewFloorsForPlayer, p1, 2)
if not ok then print("    erro:", previewErr) end
check(ok and base1.Floors:FindFirstChild("Floor02") ~= nil, "Dev.PreviewFloorsForPlayer(player, 2) constrói o Floor02")
ok = pcall(BaseService.Dev.ResetPlayerBase, p1)
check(ok and base1.Floors:FindFirstChild("Floor02") == nil, "Dev.ResetPlayerBase(player) volta ao estado real")

-- Release
env.leave(p1)
check(Env.waitFor(function()
	return base1:GetAttribute("OwnerUserId") == 0
end), "ao sair: OwnerUserId = 0")
check(BaseService.GetPlayerBase(p1) == nil, "ao sair: GetPlayerBase == nil")
check(BaseService.GetBaseOwner(base1) == nil, "ao sair: GetBaseOwner == nil")
check(p1:GetAttribute("BaseId") == nil and p1.RespawnLocation == nil, "ao sair: atributos do jogador limpos")
check(base1.OwnerSign.Board.OwnerDisplay.PlayerName.Text == "BASE LIVRE", "ao sair: placa BASE LIVRE")
check(#base1.RuntimeCharacters:GetChildren() == 0, "ao sair: RuntimeCharacters limpo")

-- Reatribuição
local p3 = env.newPlayer("jogador3")
env.join(p3)
check(Env.waitFor(function()
	return p3:GetAttribute("BaseId") ~= nil
end), "terceiro jogador recebeu base")
check(BaseService.GetPlayerBase(p3) == base1, "base liberada foi reaproveitada")
check(BaseService.GetPlayerBase(p2) == base2, "jogador2 continua com a base dele")

-- Integridade: duas bases com o mesmo dono -> nil + erro
local other = MapService.GetBase(10)
other:SetAttribute("OwnerUserId", p2.UserId)
local copy3 = env.newContext(overrides)(Services.BaseService)
check(copy3.GetPlayerBase(p2) == nil, "dono de duas bases (sem cache) = erro de integridade, nil")
other:SetAttribute("OwnerUserId", 0)

local failures = T.finish()
process.exit(if failures > 0 then 1 else 0)
