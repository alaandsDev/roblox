--[[
	Auditoria: tamanho do save de um jogador no FIM DO JOGO (inventário cheio no máximo,
	Índice completo, 40 slots, 100 recibos, missões, torres...). Limite do DataStore: 4 MB por chave.
]]
local T = require("./TestLib")
local Odds = require("../tools/sim/Odds")
local DataConfig = require("../src/shared/Config/DataConfig")
local CharacterConfig = require("../src/shared/Config/CharacterConfig")
local UpgradeConfig = require("../src/shared/Config/UpgradeConfig")
local RebirthConfig = require("../src/shared/Config/RebirthConfig")
local TowerConfig = require("../src/shared/Config/TowerConfig")
local describe, it, expect = T.describe, T.it, T.expect

-- JSON simples (mesmo formato aproximado do JSONEncode do Roblox)
local function encode(value: any): string
	local t = type(value)
	if t == "table" then
		local parts = {}
		if #value > 0 then
			for _, v in value do
				table.insert(parts, encode(v))
			end
			return "[" .. table.concat(parts, ",") .. "]"
		end
		for k, v in value do
			table.insert(parts, string.format("%q:%s", tostring(k), encode(v)))
		end
		return "{" .. table.concat(parts, ",") .. "}"
	elseif t == "string" then
		return string.format("%q", value)
	elseif t == "number" then
		return if value == math.floor(value) then string.format("%d", value) else tostring(value)
	end
	return tostring(value)
end

local function deepCopy(v: any): any
	if type(v) ~= "table" then
		return v
	end
	local out = {}
	for k, x in v do
		out[k] = deepCopy(x)
	end
	return out
end

local function endgameProfile(): (any, number)
	local data = deepCopy(DataConfig.Template)
	data.Money = 9.99e15
	data.Gems = 999999
	data.Rolls = 9999999
	data.Rebirths = RebirthConfig.MaxRebirths
	for _, u in UpgradeConfig.List do
		data.Upgrades[u.Id] = u.MaxLevel
	end
	for _, perk in RebirthConfig.Perks do
		data.RebirthPerks[perk.Id] = perk.MaxLevel
	end
	data.Runtime = { Capacity = 100, Luck = 2.2, Income = 1.5, Cooldown = 0.85 }
	local capacity = Odds.formulas:capacity(data)
	local now = 1_800_000_000
	for i = 1, capacity do
		local character = CharacterConfig.List[(i % #CharacterConfig.List) + 1]
		data.Inventory["c" .. tostring(1_000_000 + i)] = { Id = character.Id, Level = 50, Variant = "Celestial", Locked = true, Favorite = true, ObtainedAt = now }
	end
	data.NextUid = 1_000_000 + capacity + 1
	for slot = 1, 40 do
		data.EquippedCharacters[tostring(slot)] = "c" .. tostring(1_000_000 + slot)
	end
	for _, character in CharacterConfig.List do
		data.Index[character.Id] = { Count = 99999, FirstAt = now }
		data.RevealViews[character.Id] = 999
	end
	for _, tower in TowerConfig.List do
		data.TowerProgress[tower.Id] = tower.Floors
	end
	data.TowerTeam = { "c1000001", "c1000002", "c1000003", "c1000004", "c1000005" }
	data.ProcessedReceipts = {}
	for i = 1, DataConfig.ReceiptHistorySize do
		table.insert(data.ProcessedReceipts, string.format("%08x-aaaa-bbbb-cccc-%012d", i, i))
	end
	data.Missions = { Day = 20000, Daily = {}, Achievements = {} }
	for i = 1, 6 do
		data.Missions.Daily["mission_" .. i] = { Progress = 999999, Claimed = true }
		data.Missions.Achievements["achievement_" .. i] = 10
	end
	data.Boosts = { Luck = { Multiplier = 2, ExpiresAt = now } }
	return data, capacity
end

describe("Tamanho do save (DataStore)", function()
	it("perfil de fim de jogo cabe com folga no limite de 4 MB", function()
		local data, capacity = endgameProfile()
		local bytes = #encode(data)
		print(string.format("    perfil fim de jogo: %d personagens, %.1f KB (limite 4096 KB)", capacity, bytes / 1024))
		expect(capacity >= 400).toBeTruthy()
		expect(bytes < 256 * 1024).toBeTruthy()
	end)
end)

return true
