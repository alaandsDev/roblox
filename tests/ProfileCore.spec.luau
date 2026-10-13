local T = require("./TestLib")
local ProfileCore = require("../src/server/Core/ProfileCore")
local TableUtil = require("../src/shared/Modules/TableUtil")
local DataConfig = require("../src/shared/Config/DataConfig")
local Migrations = require("../src/server/Core/Migrations")
local describe, it, expect = T.describe, T.it, T.expect

-- DataStore falso em memória, com UpdateAsync igual ao do Roblox
-- (transform recebe cópia; nil cancela a escrita) e injeção de falhas.
local function fakeStore()
	local store = { data = {}, failNext = 0, calls = 0 }
	function store:UpdateAsync(key, transform)
		self.calls += 1
		if self.failNext > 0 then
			self.failNext -= 1
			error("DataStore indisponível (simulado)")
		end
		local result = transform(TableUtil.deepCopy(self.data[key]))
		if result ~= nil then
			self.data[key] = TableUtil.deepCopy(result)
		end
		return result
	end
	return store
end

local clock = 1000
local waits = 0

local function newCore(store, jobId, overrides)
	local options = {
		store = store,
		jobId = jobId,
		template = DataConfig.Template,
		version = DataConfig.SchemaVersion,
		migrations = Migrations,
		lockTimeout = 60,
		maxAttempts = 3,
		retryBaseDelay = 1,
		now = function()
			return clock
		end,
		wait = function()
			waits += 1
		end,
		deepCopy = TableUtil.deepCopy,
		reconcile = TableUtil.reconcile,
	}
	for k, v in overrides or {} do
		options[k] = v
	end
	return ProfileCore.new(options)
end

describe("ProfileCore: schema e save/load", function()
	it("perfil novo nasce com o schema padrão", function()
		clock = 1000
		local core = newCore(fakeStore(), "A")
		local profile = core:load("Player_1")
		expect(profile ~= nil).toBeTruthy()
		expect(profile.IsNew).toBe(true)
		expect(profile.Data.Version).toBe(DataConfig.SchemaVersion)
		expect(profile.Data.Money).toBe(0)
		expect(profile.Data.EquippedDice).toBe("Starter") -- SelectedDiceId padrão seguro (v3)
		expect(profile.Data.Settings.HideRollAnimation).toBe(false)
		expect(profile.Data.CreatedAt).toBe(1000)
	end)

	it("o template nunca é alterado pelo perfil", function()
		local core = newCore(fakeStore(), "A")
		local profile = core:load("Player_1")
		profile.Data.Money = 999
		profile.Data.Settings.AutoRoll = true
		expect(DataConfig.Template.Money).toBe(0)
		expect(DataConfig.Template.Settings.AutoRoll).toBe(false)
	end)

	it("salva e carrega de volta (round trip)", function()
		clock = 2000
		local store = fakeStore()
		local core = newCore(store, "A")
		local profile = core:load("Player_1")
		profile.Data.Money = 1234
		profile.Data.Inventory["u1"] = { Id = "FlameRookie" }
		expect(core:save(profile, true)).toBe(true)
		expect(store.data["Player_1"].Data.LastSave).toBe(2000)
		expect(store.data["Player_1"].Meta.SessionLock).toBeNil()

		local again = core:load("Player_1")
		expect(again.IsNew).toBe(false)
		expect(again.Data.Money).toBe(1234)
		expect(again.Data.Inventory["u1"].Id).toBe("FlameRookie")
	end)

	it("dados antigos sem campos novos são completados (deep merge)", function()
		local store = fakeStore()
		store.data["Player_1"] = { Data = { Version = 1, Money = 50, Settings = { AutoRoll = true } }, Meta = {} }
		local profile = newCore(store, "A"):load("Player_1")
		expect(profile.Data.Money).toBe(50)
		expect(profile.Data.Settings.AutoRoll).toBe(true)
		expect(profile.Data.Settings.HideRollAnimation).toBe(false)
		expect(type(profile.Data.Inventory)).toBe("table")
	end)
end)

describe("ProfileCore: session lock", function()
	it("outro servidor não carrega enquanto a trava está ativa", function()
		clock = 1000
		waits = 0
		local store = fakeStore()
		local profileA = newCore(store, "A"):load("Player_1")
		expect(profileA ~= nil).toBeTruthy()
		local profileB, reason = newCore(store, "B"):load("Player_1")
		expect(profileB).toBeNil()
		expect(reason).toBe(ProfileCore.Reasons.Locked)
		expect(waits > 0).toBeTruthy() -- esperou e tentou de novo
		expect(store.data["Player_1"].Meta.SessionLock.JobId).toBe("A")
	end)

	it("depois que o servidor A libera, o B carrega", function()
		clock = 1000
		local store = fakeStore()
		local coreA = newCore(store, "A")
		local profileA = coreA:load("Player_1")
		profileA.Data.Money = 77
		coreA:save(profileA, true)
		local profileB = newCore(store, "B"):load("Player_1")
		expect(profileB.Data.Money).toBe(77)
		expect(store.data["Player_1"].Meta.SessionLock.JobId).toBe("B")
	end)

	it("trava velha (servidor caído) é assumida", function()
		clock = 1000
		local store = fakeStore()
		newCore(store, "A"):load("Player_1")
		clock = 1000 + 61
		local profileB = newCore(store, "B"):load("Player_1")
		expect(profileB ~= nil).toBeTruthy()
	end)

	it("servidor que perdeu a trava NÃO sobrescreve o save do novo dono", function()
		clock = 1000
		local store = fakeStore()
		local coreA = newCore(store, "A")
		local profileA = coreA:load("Player_1")
		clock = 2000 -- A ficou travado/sem salvar além do timeout
		local coreB = newCore(store, "B")
		local profileB = coreB:load("Player_1")
		profileB.Data.Money = 500
		coreB:save(profileB)

		profileA.Data.Money = 1 -- dado velho
		local ok, reason = coreA:save(profileA)
		expect(ok).toBe(false)
		expect(reason).toBe(ProfileCore.Reasons.LockLost)
		expect(profileA.LockLost).toBe(true)
		expect(store.data["Player_1"].Data.Money).toBe(500)
		-- e não tenta mais salvar
		expect((coreA:save(profileA))).toBe(false)
	end)

	it("autosave renova a trava", function()
		clock = 1000
		local store = fakeStore()
		local core = newCore(store, "A")
		local profile = core:load("Player_1")
		clock = 1050
		core:save(profile)
		expect(store.data["Player_1"].Meta.SessionLock.LockedAt).toBe(1050)
	end)

	it("perfil liberado não salva de novo", function()
		local core = newCore(fakeStore(), "A")
		local profile = core:load("Player_1")
		core:save(profile, true)
		local ok, reason = core:save(profile)
		expect(ok).toBe(false)
		expect(reason).toBe(ProfileCore.Reasons.Released)
	end)
end)

describe("ProfileCore: versões e migrações", function()
	it("versão mais nova que o servidor não é carregada nem sobrescrita", function()
		local store = fakeStore()
		store.data["Player_1"] = { Data = { Version = 99, Money = 5 }, Meta = {} }
		local profile, reason = newCore(store, "A"):load("Player_1")
		expect(profile).toBeNil()
		expect(reason).toBe(ProfileCore.Reasons.FutureVersion)
		expect(store.data["Player_1"].Data.Version).toBe(99)
		expect(store.data["Player_1"].Meta.SessionLock).toBeNil()
	end)

	it("aplica migrações futuras em sequência", function()
		local store = fakeStore()
		store.data["Player_1"] = { Data = { Version = 1, Money = 10 }, Meta = {} }
		local template = TableUtil.deepCopy(DataConfig.Template)
		template.Version = 3
		template.Coins = 0
		local migrations = {
			[2] = function(data)
				data.Coins = data.Money * 2
				return data
			end,
			[3] = function(data)
				data.Money = 0
				return data
			end,
		}
		local profile = newCore(store, "A", { version = 3, template = template, migrations = migrations })
			:load("Player_1")
		expect(profile.Data.Version).toBe(3)
		expect(profile.Data.Coins).toBe(20)
		expect(profile.Data.Money).toBe(0)
	end)

	it("perfil sem Version é tratado como versão 1", function()
		local store = fakeStore()
		store.data["Player_1"] = { Data = { Money = 3 }, Meta = {} }
		local profile = newCore(store, "A"):load("Player_1")
		expect(profile.Data.Version).toBe(DataConfig.SchemaVersion)
		expect(profile.Data.Money).toBe(3)
	end)
end)

describe("ProfileCore: falhas e corrupção", function()
	it("repete com espera quando o DataStore falha e depois funciona", function()
		waits = 0
		local store = fakeStore()
		store.failNext = 2
		local profile = newCore(store, "A"):load("Player_1")
		expect(profile ~= nil).toBeTruthy()
		expect(waits).toBe(2)
	end)

	it("desiste com ERROR se o DataStore nunca responde", function()
		local store = fakeStore()
		store.failNext = 100
		local profile, reason = newCore(store, "A"):load("Player_1")
		expect(profile).toBeNil()
		expect(reason).toBe(ProfileCore.Reasons.Error)
	end)

	it("save com falha temporária ainda grava", function()
		local store = fakeStore()
		local core = newCore(store, "A")
		local profile = core:load("Player_1")
		profile.Data.Money = 42
		store.failNext = 1
		expect(core:save(profile)).toBe(true)
		expect(store.data["Player_1"].Data.Money).toBe(42)
	end)

	it("valor ilegível vira backup em vez de ser descartado", function()
		local store = fakeStore()
		store.data["Player_1"] = "lixo"
		local logs = {}
		local profile = newCore(store, "A", {
			log = function(level, message)
				table.insert(logs, level)
			end,
		}):load("Player_1")
		expect(profile.IsNew).toBe(true)
		expect(store.data["Player_1"].Meta.CorruptBackup).toBe("lixo")
		expect(table.find(logs, "error") ~= nil).toBeTruthy()
	end)

	it("Data ilegível dentro do registro também vira backup", function()
		local store = fakeStore()
		store.data["Player_1"] = { Data = 12345, Meta = {} }
		local profile = newCore(store, "A"):load("Player_1")
		expect(profile.Data.Money).toBe(0)
		expect(store.data["Player_1"].Meta.CorruptBackup).toBe(12345)
	end)

	it("save grava uma cópia (mudanças depois do save não vazam)", function()
		local store = fakeStore()
		local core = newCore(store, "A")
		local profile = core:load("Player_1")
		core:save(profile)
		profile.Data.Money = 999
		expect(store.data["Player_1"].Data.Money).toBe(0)
	end)
end)

return true
