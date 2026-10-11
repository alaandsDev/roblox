--!strict
--[[
	Missões (puro).
	    MissionCore.day(now, config)                       -> número do dia UTC
	    MissionCore.dailyIds(userId, day, config)          -> ids sorteados (determinístico)
	    MissionCore.ensureDay(missions, userId, now, cfg)  -> (estado, mudou?) zera ao virar o dia
	    MissionCore.apply(missions, event, params, cfg)    -> lista de ids que avançaram
	    MissionCore.stat(data, statName)                   -> valor para conquistas
	Estado salvo: data.Missions = { Day, Daily = { [id] = { Progress, Claimed } }, Achievements = { [id] = nívelResgatado } }
]]

local MissionCore = {}

function MissionCore.day(now: number, config: any): number
	return math.floor(now / config.DayLength)
end

-- Embaralhamento determinístico (LCG) por jogador + dia
function MissionCore.dailyIds(userId: number, day: number, config: any): { string }
	local ids = {}
	for _, mission in config.Pool do
		table.insert(ids, mission.Id)
	end
	local state = (userId * 7919 + day * 104729) % 2147483647
	for i = #ids, 2, -1 do
		state = (state * 48271) % 2147483647
		local j = state % i + 1
		ids[i], ids[j] = ids[j], ids[i]
	end
	local out = {}
	for i = 1, math.min(config.DailyCount, #ids) do
		table.insert(out, ids[i])
	end
	table.sort(out)
	return out
end

function MissionCore.ensureDay(missions: any, userId: number, now: number, config: any): (any, boolean)
	local today = MissionCore.day(now, config)
	if type(missions) == "table" and missions.Day == today and type(missions.Daily) == "table" then
		return missions, false
	end
	local daily = {}
	for _, id in MissionCore.dailyIds(userId, today, config) do
		daily[id] = { Progress = 0, Claimed = false }
	end
	local achievements = if type(missions) == "table" and type(missions.Achievements) == "table" then missions.Achievements else {}
	return { Day = today, Daily = daily, Achievements = achievements }, true
end

local function byId(config: any, id: string): any
	for _, mission in config.Pool do
		if mission.Id == id then
			return mission
		end
	end
	return nil
end
MissionCore.byId = byId

function MissionCore.apply(missions: any, event: string, params: { [string]: any }?, config: any): { string }
	local changed = {}
	for id, entry in missions.Daily do
		local mission = byId(config, id)
		if mission and mission.Event == event and not entry.Claimed and entry.Progress < mission.Target then
			local amount = if mission.Amount == "events" then 1 else tonumber(params and params[mission.Amount]) or 0
			if amount > 0 then
				entry.Progress = math.min(mission.Target, entry.Progress + amount)
				table.insert(changed, id)
			end
		end
	end
	return changed
end

function MissionCore.stat(data: any, name: string): number
	if name == "Discovered" then
		local n = 0
		for _ in data.Index or {} do
			n += 1
		end
		return n
	elseif name == "TowerFloors" then
		local n = 0
		for _, floor in data.TowerProgress or {} do
			n += tonumber(floor) or 0
		end
		return n
	end
	return tonumber(data[name]) or 0
end

-- Próximo nível de conquista que dá para resgatar (ou nil)
function MissionCore.claimableTier(data: any, achievement: any): number?
	local claimed = (data.Missions and data.Missions.Achievements and data.Missions.Achievements[achievement.Id]) or 0
	local nextTier = claimed + 1
	local target = achievement.Tiers[nextTier]
	if target and MissionCore.stat(data, achievement.Stat) >= target then
		return nextTier
	end
	return nil
end

return MissionCore
