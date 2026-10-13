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
	it("roster do roll e do Índice = 112 F2P (pilotos dentro; legados e Premium fora)", function()
		expect(CharacterConfig.Count).toBe(112)
		expect(#CharacterConfig.List).toBe(112)
		local inList = {}
		for _, c in CharacterConfig.List do
			expect(c.Legacy).toBeNil()
			expect(c.LaunchPool).toBe("F2P")
			inList[c.Id] = true
		end
		for _, pilot in CharacterConfig.Pilots do
			expect(inList[pilot.Id]).toBe(true)
		end
	end)

	it("sorteio nunca entrega legado nem Premium (milhares de rolls por Dice)", function()
		local DiceConfig = require("../src/shared/Config/DiceConfig")
		local DiceCore = require("../src/shared/Modules/DiceCore")
		local core = DiceCore.new(DiceConfig, CharacterConfig, RarityConfig, RollConfig)
		local seed = 7
		local function rand()
			seed = (seed * 48271) % 2147483647
			return seed / 2147483647
		end
		for _, dice in core:diceList() do
			for _ = 1, 300 do
				local id = core:roll(dice.Id, 1, {}, rand).characterId
				expect(CharacterConfig.ById[id].Legacy).toBeNil()
				expect(CharacterConfig.ById[id].LaunchPool).toBe("F2P")
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

describe("Catálogo de LANÇAMENTO (121 = 112 F2P + 9 Premium)", function()
	local F2P_DICE = { "starter", "lucky", "rampart", "flame", "shinobi", "blade", "fighter", "storm", "spirit", "arcane", "shadow", "void", "awakened", "colossus", "celestial", "forbidden" }
	local PREMIUM = { "Iskandar", "Hellflame", "Lancer Mode", "Afro Samurai", "Kizaru", "Shunko Yoruichi", "SSJR", "SALTER", "Bankai Toshiro" }

	it("exatamente 121 personagens: 112 F2P e 9 Premium, CharacterIds únicos", function()
		local launch = CharacterConfig.Launch
		expect(#launch).toBe(121)
		local seen, f2p, premium = {}, 0, 0
		for _, c in launch do
			expect(string.match(c.Id, "^char_[a-z0-9_]+$") ~= nil).toBeTruthy()
			expect(seen[c.Id]).toBeNil()
			seen[c.Id] = true
			expect(CharacterConfig.ById[c.Id]).toBe(c)
			expect(c.Launch).toBe(true)
			if c.LaunchPool == "F2P" then
				f2p += 1
			elseif c.LaunchPool == "Premium" then
				premium += 1
			end
		end
		expect(f2p).toBe(112)
		expect(premium).toBe(9)
	end)

	it("F2P distribuídos nos 16 Dice; Premium = os 9 do PREMIUM_DICE_PROPOSAL", function()
		local perDice, premiumSources = {}, {}
		for _, c in CharacterConfig.Launch do
			if c.LaunchPool == "F2P" then
				expect(table.find(F2P_DICE, c.DefaultDice) ~= nil).toBeTruthy()
				perDice[c.DefaultDice] = (perDice[c.DefaultDice] or 0) + 1
			else
				expect(c.DefaultDice).toBe("premium")
				premiumSources[c.SourceModelName] = true
			end
		end
		local total = 0
		for _, dice in F2P_DICE do
			expect((perDice[dice] or 0) >= 6).toBeTruthy()
			total += perDice[dice] or 0
		end
		expect(total).toBe(112)
		for _, source in PREMIUM do
			expect(premiumSources[source]).toBe(true)
		end
	end)

	it("metadados completos e mapeamento para o pack (SourcePath único por id)", function()
		local paths, names = {}, {}
		for _, c in CharacterConfig.Launch do
			expect(RarityConfig.ById[c.Rarity] ~= nil).toBeTruthy()
			expect(type(c.DisplayName) == "string" and #c.DisplayName > 0).toBeTruthy()
			expect(type(c.CharacterFamily) == "string" and #c.CharacterFamily > 0).toBeTruthy()
			expect(type(c.FormTier) == "number" and c.FormTier >= 1).toBeTruthy()
			local spec = CharacterAssetConfig.Assets[c.Id]
			expect(spec ~= nil).toBeTruthy()
			expect(spec.SourceModelName).toBe(c.SourceModelName)
			-- "Nome (2ª ocorrência)" = irmão repetido no pack (resolvido pelo Pipeline.findSource)
			-- espaço no fim é o nome EXATO no pack ("FATE.Lancer "); o nome exibido nas ferramentas não tem
			local leaf = string.gsub(string.gsub(spec.SourcePath, " %(%d+ª ocorrência%)$", ""), "%s+$", "")
			expect(string.sub(leaf, -#c.SourceModelName)).toBe(c.SourceModelName)
			expect(paths[spec.SourcePath]).toBeNil()
			paths[spec.SourcePath] = true
			expect(names[c.DisplayName]).toBeNil()
			names[c.DisplayName] = true
			local scale = CharacterAssetConfig.visualScale(c.Id)
			expect(scale >= CharacterAssetConfig.VisualScaleLimits.Min and scale <= CharacterAssetConfig.VisualScaleLimits.Max).toBeTruthy()
			expect(#CharacterAssetConfig.visualOffset(c.Id)).toBe(3)
		end
		-- nenhum asset fora do catálogo de lançamento
		local assets = 0
		for id in CharacterAssetConfig.Assets do
			expect(CharacterConfig.ById[id] ~= nil and CharacterConfig.ById[id].Launch == true).toBeTruthy()
			assets += 1
		end
		expect(assets).toBe(121)
	end)

	it("pilotos preservados (mesmos ids) dentro do lançamento; roster do roll = 112 F2P", function()
		local launchIds = {}
		for _, c in CharacterConfig.Launch do
			launchIds[c.Id] = true
		end
		for _, pilot in CharacterConfig.Pilots do
			expect(launchIds[pilot.Id]).toBe(true)
		end
		expect(#CharacterConfig.List).toBe(112)
		expect(CharacterConfig.Count).toBe(112)
		expect(#CharacterConfig.Premium).toBe(9)
		for _, c in CharacterConfig.List do
			expect(c.Launch).toBe(true)
			expect(c.LaunchPool).toBe("F2P")
		end
	end)

	it("formas são CharacterIds separados da mesma família (sem cópia por variante)", function()
		local families = {}
		for _, c in CharacterConfig.Launch do
			families[c.CharacterFamily] = families[c.CharacterFamily] or {}
			table.insert(families[c.CharacterFamily], c)
		end
		local multiForm = 0
		for _, members in families do
			if #members > 1 then
				multiForm += 1
				local ids = {}
				for _, c in members do
					expect(ids[c.Id]).toBeNil()
					ids[c.Id] = true
				end
			end
		end
		expect(multiForm > 0).toBeTruthy()
		-- variantes nunca viram ids/assets próprios
		for id in CharacterAssetConfig.Assets do
			for _, variant in VariantConfig.List do
				expect(string.find(id, "_" .. string.lower(variant.Id) .. "$") == nil or variant.Id == "Normal").toBeTruthy()
			end
		end
	end)

	it("VFX de combate (golpes/disparos) nunca entram na whitelist gerada", function()
		local combat = { "trail", "shoot", "beam", "slash", "blast", "projectile", "kame", "punch", "kick" }
		for _, c in CharacterConfig.Launch do
			local spec = CharacterAssetConfig.Assets[c.Id]
			if spec.VFX and spec.VFXExcluded then
				for _, name in spec.VFX.Full or {} do
					for _, word in combat do
						expect(string.find(string.lower(name), word, 1, true)).toBeNil()
					end
				end
			end
		end
	end)
end)

return true
