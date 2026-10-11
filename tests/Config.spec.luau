local T = require("./TestLib")
local DataConfig = require("../src/shared/Config/DataConfig")
local GameConfig = require("../src/shared/Config/GameConfig")
local Definitions = require("../src/shared/Remotes/Definitions")
local Localization = require("../src/shared/Localization/Localization")
local PtBR = require("../src/shared/Localization/PtBR")
local EnUS = require("../src/shared/Localization/EnUS")
local describe, it, expect = T.describe, T.it, T.expect

describe("Configs", function()
	it("versão do template = SchemaVersion", function()
		expect(DataConfig.Template.Version).toBe(DataConfig.SchemaVersion)
	end)

	it("schema inicial tem todos os campos pedidos", function()
		for _, key in {
			"Version", "Money", "Gems", "RebirthTokens", "Rolls", "Rebirths", "EquippedDice",
			"Inventory", "EquippedCharacters", "Index", "Upgrades", "TowerProgress", "Pity",
			"Settings", "Daily", "LastLogout", "CreatedAt", "LastSave",
		} do
			if DataConfig.Template[key] == nil then
				error("faltando no Template: " .. key)
			end
		end
		expect(DataConfig.Template.Settings.AutoRoll).toBe(false)
		expect(DataConfig.Template.Settings.HideRollAnimation).toBe(false)
	end)

	it("chaves privadas e configurações do cliente existem no template", function()
		for _, key in DataConfig.PrivateKeys do
			expect(DataConfig.Template[key] ~= nil).toBeTruthy()
		end
		for _, key in DataConfig.ClientSettings do
			expect(type(DataConfig.Template.Settings[key])).toBe("boolean")
		end
	end)

	it("SetSetting aceita exatamente as configurações do cliente", function()
		local enum = Definitions.Requests.SetSetting.args[1].enum
		expect(#enum).toBe(#DataConfig.ClientSettings)
		for _, key in DataConfig.ClientSettings do
			expect(table.find(enum, key) ~= nil).toBeTruthy()
		end
	end)

	it("nome do jogo centralizado", function()
		expect(GameConfig.GameName).toBe("Roll Legends")
	end)
end)

describe("Localization", function()
	Localization.setDictionaries({ ["pt-BR"] = PtBR, ["en-US"] = EnUS })

	it("formata parâmetros", function()
		expect(Localization.format("Olá {nome}!", { nome = "Ana" })).toBe("Olá Ana!")
		expect(Localization.format("{a} e {b}", { a = 1 })).toBe("1 e {b}")
	end)

	it("traduz e usa pt-BR como reserva", function()
		Localization.setLocale("pt-BR")
		expect(Localization.t("welcome", { game = "X" })).toBe("Bem-vindo ao X!")
		Localization.setLocale("en-US")
		expect(Localization.t("welcome", { game = "X" })).toBe("Welcome to X!")
		expect(Localization.t("error.internal")).toBe(PtBR["error.internal"]) -- sem tradução EN ainda
		Localization.setLocale("pt-BR")
	end)

	it("chave inexistente aparece como a própria chave", function()
		expect(Localization.t("nao.existe")).toBe("nao.existe")
	end)

	it("famílias de chaves dinâmicas completas (raridade, variante, dado, upgrade, filtros, configs, anúncios)", function()
		local RarityConfig = require("../src/shared/Config/RarityConfig")
		local VariantConfig = require("../src/shared/Config/VariantConfig")
		local DiceConfig = require("../src/shared/Config/DiceConfig")
		local UpgradeConfig = require("../src/shared/Config/UpgradeConfig")
		local RevealConfig = require("../src/shared/Config/RevealConfig")
		local keys = {}
		for _, r in RarityConfig.List do
			table.insert(keys, "rarity." .. r.Id)
		end
		for _, v in VariantConfig.List do
			table.insert(keys, "variant." .. v.Id)
		end
		for _, d in DiceConfig.List do
			table.insert(keys, "dice." .. d.Id)
		end
		for _, u in UpgradeConfig.List do
			table.insert(keys, "upg." .. u.Id)
			table.insert(keys, "upg.benefit." .. u.Id)
		end
		for _, f in { "All", "Rarity", "Power", "Income", "Recent" } do
			table.insert(keys, "inv.filter." .. f)
		end
		for _, k in DataConfig.ClientSettings do
			if k ~= "AutoRoll" then
				table.insert(keys, "settings." .. k)
			end
		end
		for _, preset in RevealConfig.ByRarity do
			if preset.Social ~= "None" then
				table.insert(keys, "announce." .. preset.Social)
			end
		end
		for _, c in RevealConfig.Cinematics do
			if c.Intro then
				table.insert(keys, c.Intro)
			end
		end
		for _, key in keys do
			if PtBR[key] == nil then
				error("faltando no PtBR: " .. key)
			end
		end
	end)

	it("todo erro que o servidor pode devolver tem texto", function()
		local codes = {
			"cooldown", "inventory_full", "not_owned", "no_free_slot", "slot_locked", "slot_occupied", "not_equipped",
			"invalid_flag", "max_level", "not_enough_money", "locked", "favorite", "equipped", "nothing_to_sell",
			"protected", "invalid_dice", "exclusive", "already_owned", "requires_previous", "requires_rolls",
			"invalid_upgrade", "already_claimed", "invalid_time", "nothing_to_claim", "too_far", "no_base", "no_character",
		}
		for _, code in codes do
			if PtBR["error." .. code] == nil then
				error("faltando error." .. code)
			end
		end
	end)

	it("todo código de erro do Net tem texto", function()
		for _, code in { "rate_limited", "invalid_args", "not_ready", "not_implemented", "internal" } do
			expect(PtBR["error." .. code] ~= nil).toBeTruthy()
		end
	end)
end)

return true
