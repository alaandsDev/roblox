local T = require("./TestLib")
local Migrations = require("../src/server/Core/Migrations")
local TableUtil = require("../src/shared/Modules/TableUtil")
local DataConfig = require("../src/shared/Config/DataConfig")
local describe, it, expect = T.describe, T.it, T.expect

describe("Migração v1 -> v2", function()
	it("unidades antigas ganham Level 1 e Variant Normal; NextUid acima do maior uid", function()
		local data = {
			Version = 1,
			Inventory = { c7 = { Id = "flame_rookie" }, c3 = { Id = "dragon_knight", Level = 4 }, bad = 5 },
			EquippedCharacters = { ["1"] = "c7", ["2"] = "c404" },
		}
		local out = Migrations[2](data)
		expect(out.Inventory.c7.Level).toBe(1)
		expect(out.Inventory.c7.Variant).toBe("Normal")
		expect(out.Inventory.c7.Locked).toBe(false)
		expect(out.Inventory.c3.Level).toBe(4)
		expect(out.Inventory.bad).toBeNil()
		expect(out.NextUid).toBe(8)
		expect(out.EquippedCharacters["1"]).toBe("c7")
		expect(out.EquippedCharacters["2"]).toBeNil()
	end)

	it("perfil v1 vazio + Template v2 = todos os campos novos", function()
		local data = Migrations[2]({ Version = 1, Money = 10, Inventory = {}, Settings = { AutoRoll = true } })
		data.Version = 2
		TableUtil.reconcile(data, DataConfig.Template)
		expect(data.Money).toBe(10)
		expect(data.NextUid).toBe(1)
		expect(data.Pity.Legendary).toBe(0)
		expect(data.OwnedDice.Normal).toBe(true)
		expect(data.Upgrades.Luck).toBe(0)
		expect(data.Settings.AutoRoll).toBe(true)
		expect(data.Settings.AutoSell.Common).toBe(false)
		expect(data.Settings.CameraShake).toBe(true)
		expect(data.PendingOfflineReward).toBe(0)
		expect(data.DailyCycleDay).toBe(0)
	end)
end)

return true
