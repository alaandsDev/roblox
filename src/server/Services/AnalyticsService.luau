--!strict
--[[
	AnalyticsService: ganchos internos de analytics (sem serviço externo ainda).
	    AnalyticsService.Track(player, "Roll", { rarity = "Rare" })
	Conta eventos por nome (para o DevService "Analytics") e dispara AnalyticsService.Tracked,
	onde no futuro entra o AnalyticsService do Roblox / funil. Eventos válidos em EVENTS.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Logger = require(Shared.Modules.Logger)
local Signal = require(Shared.Modules.Signal)

local log = Logger.new("Analytics")

local AnalyticsService = {}

AnalyticsService.EVENTS = {
	"FirstRoll",
	"Roll",
	"RareObtained",
	"LegendaryObtained",
	"MythicObtained",
	"DicePurchased",
	"UpgradePurchased",
	"CharacterEquipped",
	"CharacterUpgraded",
	"MoneyCollected",
	"CharacterSold",
	"InventoryFull",
	"OfflineRewardClaimed",
	"DailyClaimed",
	"IndexMilestone",
}

-- (player, nome, params)
AnalyticsService.Tracked = Signal.new()

local counts: { [string]: number } = {}

function AnalyticsService.Track(player: Player, name: string, params: { [string]: any }?)
	if not table.find(AnalyticsService.EVENTS, name) then
		log:warn("evento de analytics desconhecido:", name)
		return
	end
	counts[name] = (counts[name] or 0) + 1
	log:debug(name, player.Name)
	AnalyticsService.Tracked:Fire(player, name, params or {})
end

function AnalyticsService.Counts(): { [string]: number }
	return table.clone(counts)
end

return AnalyticsService
