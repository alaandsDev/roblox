--!strict
--[[
	DailyService: recompensas diárias (ciclo de 7 dias, relógio do SERVIDOR, virada em UTC).
	Regras em DailyConfig/DailyCore. O estado (LastDailyClaim/DailyStreak/DailyCycleDay) é
	atualizado ANTES de entregar o prêmio e tudo roda sem yield: spam do remote não duplica.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local DailyConfig = require(Shared.Config.DailyConfig)
local DailyCore = require(Shared.Modules.DailyCore)
local Formulas = require(Shared.Modules.GameFormulas)
local TableUtil = require(Shared.Modules.TableUtil)
local Net = require(Shared.Modules.Net)

local PlayerDataService = require(script.Parent.PlayerDataService)
local EconomyService = require(script.Parent.EconomyService)
local DiceService = require(script.Parent.DiceService)
local AnalyticsService = require(script.Parent.AnalyticsService)

local DailyService = {}

DailyService._now = function(): number
	return os.time()
end

local function state(data: any): any
	return { LastDailyClaim = data.LastDailyClaim, DailyStreak = data.DailyStreak, DailyCycleDay = data.DailyCycleDay }
end

function DailyService.Status(player: Player)
	local data = PlayerDataService.GetData(player)
	if not data then
		Net.fail(Net.Codes.NotReady)
	end
	local now = DailyService._now()
	local status = DailyCore.status(state(data), now, DailyConfig)
	return {
		canClaim = status.canClaim,
		day = status.day,
		claimedThrough = if status.reset then 0 else (data :: any).DailyCycleDay,
		secondsLeft = math.max(0, status.nextClaimAt - now),
		streak = (data :: any).DailyStreak,
	}
end

-- Entrega o prêmio (resolvido no servidor). Devolve uma descrição para o cliente
local function deliver(player: Player, data: any, reward: any, now: number): { [string]: any }
	if reward.Kind == "Money" then
		local amount = math.max(reward.Amount, math.floor(Formulas:incomePerSecond(data) * (reward.IncomeSeconds or 0)))
		EconomyService.AddMoney(player, amount, "Daily")
		return { kind = "Money", amount = amount }
	elseif reward.Kind == "Gems" then
		PlayerDataService.Increment(player, "Gems", reward.Amount)
		return { kind = "Gems", amount = reward.Amount }
	elseif reward.Kind == "LuckBoost" then
		local boosts = TableUtil.deepCopy(data.Boosts)
		local current = boosts.Luck
		local active = type(current) == "table" and type(current.ExpiresAt) == "number" and current.ExpiresAt > now
		if active and current.Multiplier == reward.Multiplier then
			current.ExpiresAt += reward.Duration
		elseif active and current.Multiplier > reward.Multiplier then
			-- Já tem um boost maior: mantém o maior
			current.ExpiresAt = math.max(current.ExpiresAt, now + reward.Duration)
		else
			boosts.Luck = { Multiplier = reward.Multiplier, ExpiresAt = now + reward.Duration }
		end
		PlayerDataService.Set(player, "Boosts", boosts)
		return { kind = "LuckBoost", multiplier = reward.Multiplier, duration = reward.Duration }
	elseif reward.Kind == "Dice" then
		-- Prisma da Coleção: a cada entrega do Prism (1ª vez ou fallback) os usos são creditados
		if data.OwnedDice[reward.DiceId] then
			local result = deliver(player, data, reward.Fallback, now)
			result.prismUses = DiceService.RewardDelivered(player, reward.DiceId)
			return result
		end
		DiceService.Grant(player, reward.DiceId)
		return { kind = "Dice", id = reward.DiceId, prismUses = DiceService.RewardDelivered(player, reward.DiceId) }
	end
	return { kind = "None" }
end

function DailyService.Claim(player: Player)
	local data = PlayerDataService.GetData(player)
	if not data then
		Net.fail(Net.Codes.NotReady)
	end
	assert(data)
	local now = DailyService._now()
	local newState, day, err = DailyCore.claim(state(data), now, DailyConfig)
	if not newState then
		Net.fail(err :: string)
	end
	assert(day)
	-- Marca como resgatado ANTES de entregar
	PlayerDataService.Set(player, "LastDailyClaim", newState.LastDailyClaim)
	PlayerDataService.Set(player, "DailyStreak", newState.DailyStreak)
	PlayerDataService.Set(player, "DailyCycleDay", newState.DailyCycleDay)
	local result = deliver(player, data, DailyConfig.Rewards[day], now)
	result.day = day
	AnalyticsService.Track(player, "DailyClaimed", { day = day })
	PlayerDataService.SaveSoon(player)
	return result
end

function DailyService.Init()
	Net.handle("GetDailyStatus", DailyService.Status)
	Net.handle("ClaimDaily", DailyService.Claim)
end

return DailyService
