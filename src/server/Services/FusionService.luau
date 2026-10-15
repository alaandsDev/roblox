--!strict
--[[
	FusionService (Fase 8): altar de FUSÃO.
	    Fuse({ uid, uid, uid }) -> 3 iguais viram 1 da próxima variante (regras em FusionCore)
	    FuseMax(characterId, confirmar, fusõesVistas?) -> FUNDIR MÁX.: a cadeia inteira da família
	        numa operação só (FusionCore.fuseMaxPlan). confirmar = false: só a prévia.
	O servidor confere dono, proteção, igualdade e dinheiro; o cliente só escolhe (no MÁX. o
	cliente manda só o personagem: o servidor lê o inventário, planeja, valida e aplica).
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

-- uma operação de fusão por jogador por vez (FUNDIR 1× e FUNDIR MÁX.)
local busy: { [Player]: boolean } = {}

local function investedOf(item: any): number
	return SaleCore.invested(Formulas, item)
end

FusionService.Configs = { Fusion = FusionConfig, Variants = VariantConfig, Characters = CharacterConfig, Inventory = InventoryCore }

function FusionService.Fuse(player: Player, uids: { string })
	local data = PlayerDataService.GetData(player)
	if not data then
		Net.fail(Net.Codes.NotReady)
	end
	assert(data)
	if busy[player] then
		Net.fail("fusion_busy")
	end
	local plan, err = FusionCore.plan(data, uids, FusionService.Configs)
	if not plan then
		Net.fail(err :: string)
	end
	assert(plan)
	-- investimento em níveis das consumidas (lido ANTES de removê-las; cada uma conta uma vez)
	local invested = FusionCore.investment(data, uids, investedOf)
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

local function summary(plan: FusionCore.MaxPlan): { [string]: any }
	return {
		characterId = plan.characterId,
		fusions = plan.fusions,
		cost = plan.cost,
		created = plan.created,
		remaining = plan.remaining,
		top = plan.top,
		limitedByMoney = plan.limitedByMoney,
		consumed = plan.consumed,
	}
end

-- Prévia (sem mudar nada)
function FusionService.PreviewMax(player: Player, characterId: string): { [string]: any }
	local data = PlayerDataService.GetData(player)
	if not data then
		Net.fail(Net.Codes.NotReady)
	end
	assert(data)
	local plan, err = FusionCore.fuseMaxPlan(data, characterId, FusionService.Configs, investedOf, data.Money)
	if not plan then
		Net.fail(err :: string)
	end
	return summary(plan :: FusionCore.MaxPlan)
end

--[[
	FUNDIR MÁX.: 1) lê o inventário 2) planeja a cadeia inteira 3) valida (dinheiro, a prévia que
	o jogador viu) 4) desconta o custo total 5) consome/cria em sequência sem yield 6) UM delta para
	o cliente 7) salva em breve. Sem yield entre planejar e aplicar: nada muda no meio (atômico).
	expectedFusions: as fusões que a prévia mostrou; se o inventário mudou, recusa ("fusion_changed").
]]
function FusionService.FuseMax(player: Player, characterId: string, confirm: boolean?, expectedFusions: number?)
	if not confirm then
		return FusionService.PreviewMax(player, characterId)
	end
	local data = PlayerDataService.GetData(player)
	if not data then
		Net.fail(Net.Codes.NotReady)
	end
	assert(data)
	if busy[player] then
		Net.fail("fusion_busy")
	end
	local plan, err = FusionCore.fuseMaxPlan(data, characterId, FusionService.Configs, investedOf, data.Money)
	if not plan then
		Net.fail(err :: string)
	end
	assert(plan)
	if expectedFusions ~= nil and expectedFusions ~= plan.fusions then
		Net.fail("fusion_changed")
	end
	busy[player] = true
	local ok, result = pcall(function()
		if not EconomyService.TrySpend(player, plan.cost) then
			Net.fail("not_enough_money")
		end
		local removedOriginal: { string } = {}
		local finalNew: { [string]: boolean } = {}
		local now = os.time()
		for _, step in plan.steps do
			for _, uid in step.uids do
				if finalNew[uid] then
					finalNew[uid] = nil -- intermediária: nasce e é consumida no próprio plano
				else
					table.insert(removedOriginal, uid)
				end
				InventoryCore.remove(data, uid)
			end
			local uid = InventoryCore.add(data, plan.characterId, now, step.toVariant)
			assert(uid == step.uid, "FuseMax: uid fora da sequência do plano")
			data.Inventory[uid].Level = step.level
			data.Inventory[uid].UpgradeInvestment = step.investment
			finalNew[uid] = true
			AnalyticsService.Track(player, "Fusion", { id = plan.characterId, variant = step.toVariant })
		end
		local created = {}
		for uid in finalNew do
			table.insert(created, uid)
		end
		table.sort(created, FusionCore.uidLess)
		PlayerDataService.Replicate(player, "NextUid")
		InventoryService.SendDelta(player, created, removedOriginal)
		local variants = {}
		for _, step in plan.steps do
			if not variants[step.toVariant] then
				variants[step.toVariant] = true
				IndexService.RegisterVariant(player, plan.characterId, step.toVariant)
			end
		end
		PlayerDataService.SaveSoon(player)
		local out = summary(plan)
		out.uids = created
		return out
	end)
	busy[player] = nil
	if not ok then
		error(result, 0)
	end
	return result
end

function FusionService.Init()
	Net.handle("Fuse", FusionService.Fuse)
	Net.handle("FuseMax", FusionService.FuseMax)
	MapService.RegisterInteraction("Fusion", function(player)
		Net.fire("OpenMenu", player, "Fusion")
	end)
end

return FusionService
