--!strict
--[[
	FusionService (Fase 8): altar de FUSÃO.
	    Fuse({ uid, uid, uid }) -> 3 iguais viram 1 da próxima variante (regras em FusionCore)
	O servidor confere dono, proteção, igualdade e dinheiro; o cliente só escolhe.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local FusionConfig = require(Shared.Config.FusionConfig)
local VariantConfig = require(Shared.Config.VariantConfig)
local CharacterConfig = require(Shared.Config.CharacterConfig)
local Net = require(Shared.Modules.Net)
local SaleCore = require(Shared.Modules.SaleCore)
local Formulas = require(Shared.Modules.GameFormulas)

local Core = script.Parent.Parent.Core
local FusionCore = require(Core.FusionCore)
local InventoryCore = require(Core.InventoryCore)
local PlayerDataService = require(script.Parent.PlayerDataService)
local InventoryService = require(script.Parent.InventoryService)
local EconomyService = require(script.Parent.EconomyService)
local MapService = require(script.Parent.MapService)
local AnalyticsService = require(script.Parent.AnalyticsService)
local IndexService = require(script.Parent.IndexService)

local FusionService = {}

FusionService.Configs = { Fusion = FusionConfig, Variants = VariantConfig, Characters = CharacterConfig, Inventory = InventoryCore }

function FusionService.Fuse(player: Player, uids: { string })
	local data = PlayerDataService.GetData(player)
	if not data then
		Net.fail(Net.Codes.NotReady)
	end
	assert(data)
	local plan, err = FusionCore.plan(data, uids, FusionService.Configs)
	if not plan then
		Net.fail(err :: string)
	end
	assert(plan)
	-- investimento em níveis das consumidas (lido ANTES de removê-las; cada uma conta uma vez)
	local invested = FusionCore.investment(data, uids, function(item)
		return SaleCore.invested(Formulas, item)
	end)
	if not EconomyService.TrySpend(player, plan.cost) then
		Net.fail("not_enough_money")
	end
	InventoryService.Remove(player, uids)
	local uid = InventoryService.Add(player, plan.characterId, plan.toVariant)
	data.Inventory[uid].Level = plan.level
	data.Inventory[uid].UpgradeInvestment = invested
	InventoryService.SendDelta(player, { uid }, nil)
	-- Índice: variante nova descoberta (não conta como novo personagem nem mexe nos marcos)
	IndexService.RegisterVariant(player, plan.characterId, plan.toVariant)
	AnalyticsService.Track(player, "Fusion", { id = plan.characterId, variant = plan.toVariant })
	PlayerDataService.SaveSoon(player)
	return { uid = uid, characterId = plan.characterId, variant = plan.toVariant, level = plan.level, cost = plan.cost }
end

function FusionService.Init()
	Net.handle("Fuse", FusionService.Fuse)
	MapService.RegisterInteraction("Fusion", function(player)
		Net.fire("OpenMenu", player, "Fusion")
	end)
end

return FusionService
