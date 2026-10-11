--!strict
--[[
	DataController: cópia (somente leitura) dos dados do jogador no cliente.
	O servidor é a fonte da verdade; aqui só espelhamos para a interface.
	    DataController.Get("Money")
	    DataController.Changed:Connect(function(key, value) end)
	    DataController.Ready:Wait()
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

function DataController.Start()
	Net.on("DataChanged", function(key: string, value: any)
		if data then
			data[key] = value
			DataController.Changed:Fire(key, value)
		end
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
