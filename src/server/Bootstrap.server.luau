--!strict
-- Ponto de entrada do servidor: cria os remotes, inicia os Services na ordem certa.
-- Init() de todos primeiro (registrar handlers, sem esperar nada), depois Start().
-- Para adicionar um Service: crie em Services/ e coloque o nome em ORDER.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Modules.Net)
local Logger = require(ReplicatedStorage.Shared.Modules.Logger)
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local log = Logger.new("Bootstrap")

local ORDER = {
	"PlayerDataService",
	"MonetizationService",
	"MapService",
	"BaseService",
	"AnalyticsService",
	"EconomyService",
	"InventoryService",
	"IndexService",
	"SellService",
	"RollService",
	"DiceService",
	"UpgradeService",
	"StationService",
	"DailyService",
	"TowerService",
	"DevService", -- só ativo no Studio
}

Net.initServer()

local services = {}
for _, name in ORDER do
	local module = script.Parent.Services:FindFirstChild(name)
	assert(module, `Service "{name}" não encontrado em Services/`)
	local ok, service = pcall(require, module)
	if not ok then
		log:error(`erro ao carregar {name}:`, service)
		continue
	end
	table.insert(services, { name = name, service = service })
end

for _, entry in services do
	if entry.service.Init then
		local ok, err = pcall(entry.service.Init)
		if not ok then
			log:error(`{entry.name}.Init falhou:`, err)
		end
	end
end

for _, entry in services do
	if entry.service.Start then
		task.spawn(function()
			local ok, err = pcall(entry.service.Start)
			if not ok then
				log:error(`{entry.name}.Start falhou:`, err)
			end
		end)
	end
end

log:info(`{GameConfig.GameName} v{GameConfig.Version} iniciado com {#services} services`)
