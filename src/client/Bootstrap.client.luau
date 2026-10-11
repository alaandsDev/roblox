--!strict
-- Ponto de entrada do cliente: inicia os Controllers na ordem.
-- Init() de todos primeiro, depois Start() (cada um na sua thread).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Logger = require(ReplicatedStorage.Shared.Modules.Logger)

local log = Logger.new("ClientBootstrap")

local ORDER = {
	"NotificationController",
	"DataController",
}

local controllers = {}
for _, name in ORDER do
	local module = script.Parent.Controllers:FindFirstChild(name)
	assert(module, `Controller "{name}" não encontrado em Controllers/`)
	local ok, controller = pcall(require, module)
	if ok then
		table.insert(controllers, { name = name, controller = controller })
	else
		log:error(`erro ao carregar {name}:`, controller)
	end
end

for _, entry in controllers do
	if entry.controller.Init then
		local ok, err = pcall(entry.controller.Init)
		if not ok then
			log:error(`{entry.name}.Init falhou:`, err)
		end
	end
end

for _, entry in controllers do
	if entry.controller.Start then
		task.spawn(function()
			local ok, err = pcall(entry.controller.Start)
			if not ok then
				log:error(`{entry.name}.Start falhou:`, err)
			end
		end)
	end
end

log:info(`{#controllers} controllers iniciados`)
