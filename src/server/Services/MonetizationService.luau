--!strict
--[[
	MonetizationService: gamepasses e produtos (MarketplaceService).

	- IDs só em Shared/Config/MonetizationConfig.luau.
	- O cliente pede a compra pela CHAVE (RequestPurchase("LuckBoost")); quem abre a janela
	  de compra é o servidor. O cliente nunca diz "eu comprei".
	- ProcessReceipt idempotente (Core/ReceiptCore.luau): a mesma compra nunca é entregue duas vezes.
	- Outros Services registram quem entrega cada produto:
	    MonetizationService.RegisterProduct("LuckBoost", function(player, data) ... return true end)
	- Gamepasses: MonetizationService.OwnsPass(player, "VIP"), com cache por sessão.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local MonetizationConfig = require(Shared.Config.MonetizationConfig)
local DataConfig = require(Shared.Config.DataConfig)
local Logger = require(Shared.Modules.Logger)
local Signal = require(Shared.Modules.Signal)
local Net = require(Shared.Modules.Net)

local ReceiptCore = require(script.Parent.Parent.Core.ReceiptCore)
local PlayerDataService = require(script.Parent.PlayerDataService)

local log = Logger.new("Monetization")

local MonetizationService = {}

-- (player, passKey) quando um gamepass é comprado durante a sessão
MonetizationService.PassPurchased = Signal.new()

type Deliver = (player: Player, data: { [string]: any }) -> boolean

local deliverers: { [string]: Deliver } = {}
local productKeyById: { [number]: string } = {}
local passKeyById: { [number]: string } = {}
local ownedPasses: { [Player]: { [string]: boolean } } = {}
local pendingReceipts: { [string]: boolean } = {}

function MonetizationService.RegisterProduct(key: string, deliver: Deliver)
	assert(MonetizationConfig.Products[key], `produto "{key}" não existe em MonetizationConfig`)
	assert(not deliverers[key], `produto "{key}" já tem entregador`)
	deliverers[key] = deliver
end

function MonetizationService.OwnsPass(player: Player, key: string): boolean
	local owned = ownedPasses[player]
	return owned ~= nil and owned[key] == true
end

local function loadPasses(player: Player)
	local owned = {}
	ownedPasses[player] = owned
	for key, pass in MonetizationConfig.GamePasses do
		if pass.Id ~= 0 then
			local ok, result = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, pass.Id)
			if ok then
				owned[key] = result
			else
				log:warn("falha ao verificar gamepass", key, "de", player.Name, result)
			end
		end
	end
end

local function processReceipt(info: any): Enum.ProductPurchaseDecision
	local result = ReceiptCore.process(info, {
		getProfile = function(playerId: number)
			local player = Players:GetPlayerByUserId(playerId)
			return player and PlayerDataService.GetProfile(player)
		end,
		getHandler = function(productId: number)
			local key = productKeyById[productId]
			local deliver = key and deliverers[key]
			if not deliver then
				return nil
			end
			return function(_profile: any, receipt: ReceiptCore.ReceiptInfo): boolean
				local player = Players:GetPlayerByUserId(receipt.PlayerId)
				local data = player and PlayerDataService.GetData(player)
				if not player or not data then
					return false
				end
				return deliver(player, data)
			end
		end,
		save = function(_profile: any, receipt: ReceiptCore.ReceiptInfo): boolean
			local player = Players:GetPlayerByUserId(receipt.PlayerId)
			return player ~= nil and PlayerDataService.SaveNow(player)
		end,
		pending = pendingReceipts,
		historySize = DataConfig.ReceiptHistorySize,
		log = function(level, message)
			if level == "error" then
				log:error(message)
			else
				log:warn(message)
			end
		end,
	})

	if result == ReceiptCore.Granted then
		local player = Players:GetPlayerByUserId(info.PlayerId)
		if player then
			Net.fire("Notify", player, "purchase.thanks")
		end
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

local function handleRequestPurchase(player: Player, key: string)
	local product = MonetizationConfig.Products[key]
	local pass = MonetizationConfig.GamePasses[key]
	local item = product or pass
	if not item or item.Id == 0 then
		Net.fire("Notify", player, "purchase.not_configured")
		Net.fail("not_configured")
	end
	assert(item)
	if product then
		MarketplaceService:PromptProductPurchase(player, item.Id)
	else
		if MonetizationService.OwnsPass(player, key) then
			return "owned"
		end
		MarketplaceService:PromptGamePassPurchase(player, item.Id)
	end
	return "prompted"
end

function MonetizationService.Init()
	for key, product in MonetizationConfig.Products do
		if product.Id ~= 0 then
			assert(not productKeyById[product.Id], `ID de produto repetido: {product.Id}`)
			productKeyById[product.Id] = key
		end
	end
	for key, pass in MonetizationConfig.GamePasses do
		if pass.Id ~= 0 then
			passKeyById[pass.Id] = key
		end
	end
	Net.handle("RequestPurchase", handleRequestPurchase)
end

function MonetizationService.Start()
	MarketplaceService.ProcessReceipt = processReceipt

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		local key = passKeyById[passId]
		if not purchased or not key then
			return
		end
		-- Confirma com o Roblox antes de liberar (não confia só no evento)
		local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, passId)
		if ok and owns then
			local owned = ownedPasses[player] or {}
			ownedPasses[player] = owned
			owned[key] = true
			MonetizationService.PassPurchased:Fire(player, key)
			Net.fire("Notify", player, "purchase.thanks")
		end
	end)

	Players.PlayerAdded:Connect(loadPasses)
	Players.PlayerRemoving:Connect(function(player)
		ownedPasses[player] = nil
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(loadPasses, player)
	end
end

return MonetizationService
