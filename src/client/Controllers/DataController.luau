--!strict
--[[
	DataController: cópia (somente leitura) dos dados do jogador no cliente.
	O servidor é a fonte da verdade; aqui só espelhamos para a interface.
	    DataController.Get("Money")
	    DataController.Changed:Connect(function(key, value) end)
	    DataController.Ready:Wait()
	    DataController.InventoryChanged:Connect(function(set, removed) end)
	O inventário chega aos pedaços (evento InventoryDelta), sem reenviar tudo a cada roll.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Modules.Net)
local Signal = require(Shared.Modules.Signal)
local Logger = require(Shared.Modules.Logger)

local log = Logger.new("DataController")

local DataController = {}

DataController.Changed = Signal.new()
DataController.Ready = Signal.new()
-- ({ [uid] = item }, { uid })
DataController.InventoryChanged = Signal.new()

local data: { [string]: any }? = nil

function DataController.Get(key: string): any
	return if data then data[key] else nil
end

function DataController.IsReady(): boolean
	return data ~= nil
end

-- Pede uma configuração ao servidor (ele valida e salva)
function DataController.SetSetting(key: string, value: boolean): Net.Result
	return Net.request("SetSetting", key, value)
end

-- Espera os dados (para controllers que precisam deles ao iniciar)
function DataController.Wait(): { [string]: any }
	while not data do
		DataController.Ready:Wait()
	end
	return data :: { [string]: any }
end

function DataController.GetAll(): { [string]: any }?
	return data
end

function DataController.Start()
	Net.on("DataChanged", function(key: string, value: any)
		if data then
			data[key] = value
			DataController.Changed:Fire(key, value)
		end
	end)
	Net.on("InventoryDelta", function(delta: any)
		if not data or type(delta) ~= "table" then
			return
		end
		local inventory = data.Inventory
		for uid, item in delta.set or {} do
			inventory[uid] = item
		end
		for _, uid in delta.removed or {} do
			inventory[uid] = nil
		end
		DataController.InventoryChanged:Fire(delta.set or {}, delta.removed or {})
		DataController.Changed:Fire("Inventory", inventory)
	end)

	-- O perfil pode ainda estar carregando no servidor: tenta de novo por até ~30 s
	for _ = 1, 30 do
		local result = Net.request("GetSnapshot")
		if result.ok then
			data = result.data
			log:info("dados recebidos do servidor (Money:", result.data.Money, "Rolls:", result.data.Rolls, ")")
			DataController.Ready:Fire()
			return
		end
		task.wait(1)
	end
	log:warn("não foi possível obter os dados do servidor")
end

return DataController
