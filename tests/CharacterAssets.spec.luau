local T = require("./TestLib")
local CharacterConfig = require("../src/shared/Config/CharacterConfig")
local CharacterAssetConfig = require("../src/shared/Config/CharacterAssetConfig")
local RarityConfig = require("../src/shared/Config/RarityConfig")
local RollConfig = require("../src/shared/Config/RollConfig")
local VariantConfig = require("../src/shared/Config/VariantConfig")
local RollCore = require("../src/shared/Modules/RollCore")
local describe, it, expect = T.describe, T.it, T.expect

describe("Pipeline de personagens: pilotos (metadados)", function()
	it("8–10 pilotos, ids próprios e estáveis (char_*), sem repetir", function()
		local pilots = CharacterConfig.Pilots
		expect(#pilots >= 8 and #pilots <= 10).toBeTruthy()
		local seen = {}
		for _, c in pilots do
			expect(string.match(c.Id, "^char_[a-z0-9_]+$") ~= nil).toBeTruthy()
			expect(seen[c.Id]).toBeNil()
			seen[c.Id] = true
			expect(CharacterConfig.ById[c.Id]).toBe(c)
		end
	end)

	it("CharacterId, DisplayName e SourceModelName separados", function()
		for _, c in CharacterConfig.Pilots do
			expect(type(c.DisplayName) == "string" and #c.DisplayName > 0).toBeTruthy()
			expect(c.DisplayName ~= c.Id).toBeTruthy()
			expect(c.Name).toBe(c.DisplayName)
			expect(type(c.SourceModelName) == "string" and #c.SourceModelName > 0).toBeTruthy()
			expect(c.SourceModelName ~= c.Id).toBeTruthy()
			local spec = CharacterAssetConfig.Assets[c.Id]
			expect(spec ~= nil).toBeTruthy()
			expect(spec.SourceModelName).toBe(c.SourceModelName)
			-- O caminho no pack termina no nome do modelo de origem
			expect(string.sub(spec.SourcePath, -#c.SourceModelName)).toBe(c.SourceModelName)
		end
	end)

	it("metadados exigidos: raridade, família, forma, categoria, dado e status", function()
		for _, c in CharacterConfig.Pilots do
			expect(RarityConfig.ById[c.Rarity] ~= nil).toBeTruthy()
			expect(type(c.CharacterFamily) == "string" and #c.CharacterFamily > 0).toBeTruthy()
			expect(type(c.FormTier) == "number" and c.FormTier >= 1).toBeTruthy()
			expect(type(c.SourceCategory) == "string" and #c.SourceCategory > 0).toBeTruthy()
			expect(type(c.DefaultDice) == "string" and #c.DefaultDice > 0).toBeTruthy()
			expect(c.TechnicalStatus).toBe("APPROVED")
			expect(c.BasePower > 0 and c.BaseIncome > 0).toBeTruthy()
			expect(c.Pilot).toBe(true)
		end
	end)

	it("transformações: toda forma 2+ tem a forma base da família no piloto", function()
		local families = {}
		for _, c in CharacterConfig.Pilots do
			families[c.CharacterFamily] = families[c.CharacterFamily] or {}
			families[c.CharacterFamily][c.FormTier] = true
		end
		local transformations = 0
		for _, tiers in families do
			for tier in tiers do
				if tier > 1 then
					transformations += 1
					expect(tiers[1]).toBe(true)
				end
			end
		end
		expect(transformations >= 1).toBeTruthy()
	end)

	it("diversidade: comum simples, Lendário/Mítico e Divino/Secreto", function()
		local rarities = {}
		for _, c in CharacterConfig.Pilots do
			rarities[c.Rarity] = true
		end
		expect(rarities.Common).toBe(true)
		expect(rarities.Legendary == true or rarities.Mythic == true).toBeTruthy()
		expect(rarities.Divine == true or rarities.Secret == true).toBeTruthy()
	end)

	it("nenhum piloto evitado (Speed Guy, KCM Minato, GER, stands)", function()
		for _, spec in CharacterAssetConfig.Assets do
			for _, avoided in { "Speed Guy", "KCM", "GER", "Stand" } do
				expect(string.find(spec.SourcePath, avoided, 1, true)).toBeNil()
			end
		end
	end)
end)

describe("Pipeline de personagens: RNG e roster intocados", function()
	it("pilotos fora do roll e do progresso do Índice (List = 24)", function()
		expect(CharacterConfig.Count).toBe(24)
		expect(#CharacterConfig.List).toBe(24)
		for _, c in CharacterConfig.List do
			expect(c.Pilot).toBeNil()
		end
	end)

	it("RollCore nunca sorteia piloto (milhares de sorteios por raridade)", function()
		local core = RollCore.new(RarityConfig, CharacterConfig, RollConfig)
		local seed = 7
		local function rand()
			seed = (seed * 48271) % 2147483647
			return seed / 2147483647
		end
		for _, rarity in RarityConfig.List do
			for _ = 1, 300 do
				local id = core:pickCharacter(rarity.Id, rand)
				expect(CharacterConfig.ById[id].Pilot).toBeNil()
			end
		end
	end)

	it("velocidade do roll continua 1/s (Fast Roll 2/s)", function()
		expect(RollConfig.RollSpeed.BaseInterval).toBe(1)
		expect(RollConfig.RollSpeed.FastRollInterval).toBe(0.5)
	end)
end)

describe("Pipeline de personagens: regras de segurança e VFX", function()
	local function has(list, value)
		return table.find(list, value) ~= nil
	end

	it("classes proibidas cobrem scripts, remotes, bindables, sons e animações", function()
		for _, className in { "Script", "LocalScript", "ModuleScript", "RemoteEvent", "RemoteFunction", "BindableEvent", "BindableFunction", "Sound", "Animation", "Animator" } do
			expect(has(CharacterAssetConfig.ForbiddenClasses, className)).toBe(true)
			expect(has(CharacterAssetConfig.AllowedClasses, className)).toBe(false)
		end
	end)

	it("visual permitido: peças, malhas, roupas, rosto, attachments", function()
		for _, className in { "Part", "MeshPart", "SpecialMesh", "Decal", "Texture", "Shirt", "Pants", "BodyColors", "Attachment" } do
			expect(has(CharacterAssetConfig.AllowedClasses, className)).toBe(true)
		end
	end)

	it("VFX genéricos do jogo de origem nunca estão na whitelist de um piloto", function()
		for _, name in { "MoveT", "Break", "Bubbles", "Slider", "Hit1", "Hit2", "Block", "SoruP", "LevelParticle", "SenzuEat" } do
			expect(has(CharacterAssetConfig.GenericVFXNames, name)).toBe(true)
		end
		for _, spec in CharacterAssetConfig.Assets do
			for _, list in { spec.VFX and spec.VFX.Light or {}, spec.VFX and spec.VFX.Full or {} } do
				for _, name in list do
					expect(has(CharacterAssetConfig.GenericVFXNames, name)).toBe(false)
				end
			end
			-- Light é subconjunto de Full
			for _, name in spec.VFX and spec.VFX.Light or {} do
				expect(has(spec.VFX.Full, name)).toBe(true)
			end
		end
	end)

	it("modos de VFX por contexto e limites para mobile", function()
		local modes = CharacterAssetConfig.VFXModes
		expect(modes.Base).toBe("Light")
		expect(modes.Reveal).toBe("Full")
		expect(modes.Inventory).toBe("None")
		expect(modes.Index).toBe("None")
		expect(CharacterAssetConfig.VFXLimits.MaxLight <= CharacterAssetConfig.VFXLimits.MaxFull).toBeTruthy()
		expect(CharacterAssetConfig.VFXLimits.MaxFull <= 8).toBeTruthy()
	end)

	it("normalização: corpo R6 padrão e ajustes visuais limitados e centralizados", function()
		expect(CharacterAssetConfig.BodyHeight).toBe(5)
		for id in CharacterAssetConfig.Assets do
			local scale = CharacterAssetConfig.visualScale(id)
			expect(scale >= CharacterAssetConfig.VisualScaleLimits.Min and scale <= CharacterAssetConfig.VisualScaleLimits.Max).toBeTruthy()
			expect(#CharacterAssetConfig.visualOffset(id)).toBe(3)
		end
	end)

	it("7 variantes existem para o modificador visual", function()
		expect(#VariantConfig.List).toBe(7)
	end)
end)

return true
