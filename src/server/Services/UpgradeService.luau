--!strict
--[[
	UpgradeService: melhorias GLOBAIS (Luck, Income, RollSpeed, Inventory).
	(As melhorias individuais de personagem ficam no InventoryService.UpgradeCharacter.)
	Custo do próximo nível = BaseCost * Growth ^ nível (Formulas:upgradeCost), até MaxLevel.
	A área MELHORIAS da base (só do dono) abre a janela.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local UpgradeConfig = require(Shared.Config.UpgradeConfig)
local Formulas = require(Shared.Modules.GameFormulas)
local TableUtil = require(Shared.Modules.TableUtil)
local Signal = require(Shared.Modules.Signal)
local Net = require(Shared.Modules.Net)

local PlayerDataService = require(script.Parent.PlayerDataService)
local EconomyService = require(script.Parent.EconomyService)
local MapService = require(script.Parent.MapService)
local AnalyticsService = require(script.Parent.AnalyticsService)

local UpgradeService = {}

-- (player, upgradeId, nivel)
UpgradeService.Purchased = Signal.new()

function UpgradeService.Buy(player: Player, upgradeId: string)
	local data = PlayerDataService.GetData(player)
	if not data then
		Net.fail(Net.Codes.NotReady)
	end
	assert(data)
	if not UpgradeConfig.ById[upgradeId] then
		Net.fail("invalid_upgrade")
	end
	-- Velocidade do roll é fixa por config (RollConfig.RollSpeed): melhoria de velocidade fora da loja
	if not Formulas:upgradeEnabled(upgradeId) then
		Net.fail("upgrade_disabled")
	end
	local level = Formulas:upgradeLevel(data, upgradeId)
	local cost = Formulas:upgradeCost(upgradeId, level)
	if not cost then
		Net.fail("max_level")
	end
	assert(cost)
	if not EconomyService.TrySpend(player, cost) then
		Net.fail("not_enough_money")
	end
	local upgrades = TableUtil.deepCopy(data.Upgrades)
	upgrades[upgradeId] = level + 1
	PlayerDataService.Set(player, "Upgrades", upgrades)
	AnalyticsService.Track(player, "UpgradePurchased", { id = upgradeId, level = level + 1 })
	UpgradeService.Purchased:Fire(player, upgradeId, level + 1)
	return { id = upgradeId, level = level + 1 }
end

function UpgradeService.Init()
	Net.handle("BuyUpgrade", UpgradeService.Buy)
	-- Acesso físico ÚNICO: landmark MELHORIAS do Hub. Abre a MESMA janela do botão do HUD.
	-- (o antigo pad "UpgradeArea" dentro das bases foi removido — não é mais construído)
	MapService.RegisterInteraction("HubUpgrades", function(player)
		Net.fire("OpenMenu", player, "Upgrades")
	end)
end

return UpgradeService
