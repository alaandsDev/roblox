--!strict
--[[
	MissionService (Fase 9): missões diárias + conquistas.
	Progresso pelos eventos do jogo (AnalyticsService.Tracked), sempre no servidor.
	    ClaimMission("Daily", id) / ClaimMission("Achievement", id)
	Estado em data.Missions (replicado). Vira o dia UTC -> novas diárias.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local MissionConfig = require(Shared.Config.MissionConfig)
local MissionCore = require(Shared.Modules.MissionCore)
local Formulas = require(Shared.Modules.GameFormulas)
local TableUtil = require(Shared.Modules.TableUtil)
local Net = require(Shared.Modules.Net)

local PlayerDataService = require(script.Parent.PlayerDataService)
local EconomyService = require(script.Parent.EconomyService)
local MapService = require(script.Parent.MapService)
local AnalyticsService = require(script.Parent.AnalyticsService)

local MissionService = {}

MissionService._now = function(): number
	return os.time()
end

local function ensure(player: Player): any
	local data = PlayerDataService.GetData(player)
	if not data then
		return nil
	end
	local missions, changed = MissionCore.ensureDay(data.Missions, player.UserId, MissionService._now(), MissionConfig)
	if changed then
		PlayerDataService.Set(player, "Missions", missions)
	end
	return data
end

local function reward(player: Player, data: any, r: any): { [string]: any }
	if r.Kind == "Money" then
		local amount = math.max(r.Amount, math.floor(Formulas:incomePerSecond(data) * (r.IncomeSeconds or 0)))
		EconomyService.AddMoney(player, amount, "Mission")
		return { kind = "Money", amount = amount }
	end
	PlayerDataService.Increment(player, "Gems", r.Amount)
	return { kind = "Gems", amount = r.Amount }
end

function MissionService.Claim(player: Player, kind: string, id: string)
	local data = ensure(player)
	if not data then
		Net.fail(Net.Codes.NotReady)
	end
	if kind == "Daily" then
		local entry = data.Missions.Daily[id]
		local mission = MissionCore.byId(MissionConfig, id)
		if not entry or not mission then
			Net.fail("mission_invalid")
		end
		if entry.Claimed then
			Net.fail("already_claimed")
		end
		if entry.Progress < mission.Target then
			Net.fail("mission_incomplete")
		end
		-- marca ANTES de entregar (spam não duplica)
		entry.Claimed = true
		PlayerDataService.Replicate(player, "Missions")
		local given = reward(player, data, mission.Reward)
		AnalyticsService.Track(player, "MissionClaimed", { id = id })
		PlayerDataService.SaveSoon(player)
		return given
	end
	local achievement
	for _, a in MissionConfig.Achievements do
		if a.Id == id then
			achievement = a
		end
	end
	if not achievement then
		Net.fail("mission_invalid")
	end
	local tier = MissionCore.claimableTier(data, achievement)
	if not tier then
		Net.fail("mission_incomplete")
	end
	local missions = TableUtil.deepCopy(data.Missions)
	missions.Achievements[id] = tier
	PlayerDataService.Set(player, "Missions", missions)
	local given = reward(player, data, { Kind = achievement.Reward.Kind, Amount = achievement.Reward.Amount * (tier :: number) })
	AnalyticsService.Track(player, "MissionClaimed", { id = id, tier = tier })
	PlayerDataService.SaveSoon(player)
	return given
end

function MissionService.Init()
	Net.handle("ClaimMission", MissionService.Claim)
	MapService.RegisterInteraction("Missions", function(player)
		ensure(player)
		Net.fire("OpenMenu", player, "Missions")
	end)
end

function MissionService.Start()
	AnalyticsService.Tracked:Connect(function(player: Player, name: string, params: any)
		local data = ensure(player)
		if not data then
			return
		end
		local changed = MissionCore.apply(data.Missions, name, params, MissionConfig)
		if #changed > 0 then
			PlayerDataService.Replicate(player, "Missions")
		end
	end)
	local function onLoaded(player: Player)
		ensure(player)
	end
	PlayerDataService.Loaded:Connect(onLoaded)
	for _, player in Players:GetPlayers() do
		if PlayerDataService.IsLoaded(player) then
			onLoaded(player)
		end
	end
	-- Virada do dia com o jogo aberto
	task.spawn(function()
		while true do
			task.wait(60)
			for _, player in Players:GetPlayers() do
				ensure(player)
			end
		end
	end)
end

return MissionService
