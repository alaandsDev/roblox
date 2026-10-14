-- 16 Dice + RNG por Dice (DiceCore): pools, pesos, Luck, pity, probabilidade e simulação
local T = require("./TestLib")
local Rng = require("./Rng")
local DiceCore = require("../src/shared/Modules/DiceCore")
local DiceConfig = require("../src/shared/Config/DiceConfig")
local CharacterConfig = require("../src/shared/Config/CharacterConfig")
local RarityConfig = require("../src/shared/Config/RarityConfig")
local RollConfig = require("../src/shared/Config/RollConfig")
local DataConfig = require("../src/shared/Config/DataConfig")
local Migrations = require("../src/server/Core/Migrations")
local Formulas = require("../src/shared/Modules/Formulas")
local TableUtil = require("../src/shared/Modules/TableUtil")
local describe, it, expect = T.describe, T.it, T.expect

local core = DiceCore.new(DiceConfig, CharacterConfig, RarityConfig, RollConfig)
local APPROVED = {
	Starter = 8, Lucky = 7, Rampart = 7, Flame = 6, Shinobi = 8, Blade = 8, Fighter = 7, Storm = 7,
	Spirit = 7, Arcane = 8, Shadow = 7, Void = 6, Awakened = 6, Colossus = 6, Celestial = 7, Forbidden = 7,
}
local PREMIUM_SOURCES = { "Iskandar", "Hellflame", "Lancer Mode", "Afro Samurai", "Kizaru", "Shunko Yoruichi", "SSJR", "SALTER", "Bankai Toshiro" }

local function near(a: number, b: number, eps: number?): boolean
	return math.abs(a - b) <= (eps or 1e-9)
end

local function deepCopy(t: any): any
	return TableUtil.deepCopy(t)
end

describe("Dice: roster por Dice (fonte = catálogo de lançamento)", function()
	it("exatamente 16 Dice sorteáveis, na ordem aprovada, com a quantidade aprovada", function()
		local list = core:diceList()
		expect(#list).toBe(16)
		-- Ordem oficial (Variante B): Shinobi antes do Flame, Colossus antes do Awakened
		local order = { "Starter", "Lucky", "Rampart", "Shinobi", "Flame", "Blade", "Fighter", "Storm", "Spirit", "Arcane", "Shadow", "Void", "Colossus", "Awakened", "Celestial", "Forbidden" }
		for i, dice in list do
			expect(dice.Id).toBe(order[i])
			expect(dice.Order).toBe(i)
			expect(#core:charactersFor(dice.Id)).toBe(APPROVED[dice.Id])
		end
	end)

	it("sum(Dice roster) == 112 e cada F2P em EXATAMENTE um Dice", function()
		local seen, total = {}, 0
		for _, dice in core:diceList() do
			for _, id in core:charactersFor(dice.Id) do
				total += 1
				expect(seen[id]).toBeNil()
				seen[id] = dice.Id
			end
		end
		expect(total).toBe(112)
		for _, character in CharacterConfig.List do
			expect(seen[character.Id] ~= nil).toBeTruthy()
			expect(core:diceOfCharacter(character.Id)).toBe(seen[character.Id])
		end
	end)

	it("9 Premium fora de qualquer Dice (e são os do PREMIUM_DICE_PROPOSAL)", function()
		expect(#CharacterConfig.Premium).toBe(9)
		local sources = {}
		for _, character in CharacterConfig.Premium do
			expect(character.LaunchPool).toBe("Premium")
			expect(core:diceOfCharacter(character.Id)).toBeNil()
			for _, dice in core:diceList() do
				expect(core:characterProbability(dice.Id, character.Id)).toBe(0)
			end
			sources[character.SourceModelName] = true
		end
		for _, source in PREMIUM_SOURCES do
			expect(sources[source]).toBe(true)
		end
	end)

	it("nenhuma reserva/evento/limited/legado nos Dice F2P (só catálogo de lançamento F2P)", function()
		for _, dice in core:diceList() do
			for _, id in core:charactersFor(dice.Id) do
				local character = CharacterConfig.ById[id]
				expect(character.Launch).toBe(true)
				expect(character.LaunchPool).toBe("F2P")
				expect(character.Legacy).toBeNil()
				expect(DiceConfig.ByCatalogKey[character.DefaultDice].Id).toBe(dice.Id)
			end
		end
		for _, legacy in CharacterConfig.Legacy do
			expect(core:diceOfCharacter(legacy.Id)).toBeNil()
		end
	end)

	it("Prism (exclusivo do Diário) existe mas não é sorteável", function()
		expect(DiceConfig.ById.Prism.Exclusive).toBe(true)
		expect(core:isRollable("Prism")).toBe(false)
		expect(#core:charactersFor("Prism")).toBe(0)
	end)

	it("configuração aprovada passa na auditoria (DiceProbabilityReport sem problemas)", function()
		expect(#DiceCore.validate(DiceConfig, CharacterConfig, RarityConfig)).toBe(0)
		for _, dice in core:diceList() do
			local _, problems = core:probabilityReport(dice.Id)
			expect(#problems).toBe(0)
		end
	end)
end)

describe("Dice: pesos de raridade (base normalizada por Dice)", function()
	it("normalize: só raridades suportadas, soma 100 (55/25/12/5 sobre 97)", function()
		local out = DiceCore.normalize(DiceConfig.BaseRarityPercent, { Common = true, Uncommon = true, Rare = true, Epic = true })
		expect(near(out.Common, 55 / 97 * 100)).toBeTruthy()
		expect(near(out.Epic, 5 / 97 * 100)).toBeTruthy()
		expect(out.Legendary).toBeNil()
		local sum = 0
		for _, v in out do
			sum += v
		end
		expect(near(sum, 100)).toBeTruthy()
	end)

	it("base da distribuição soma 100% (55/25/12/5/2/0,75/0,20/0,05)", function()
		local sum = 0
		for _, v in DiceConfig.BaseRarityPercent do
			sum += v
		end
		expect(near(sum, 100)).toBeTruthy()
	end)

	it("pesos de cada Dice somam 100% e raridade ausente = 0%", function()
		for _, dice in core:diceList() do
			local weights = core:rarityWeights(dice.Id)
			local sum = 0
			for rarity, w in weights do
				sum += w
				expect(core:supports(dice.Id, rarity)).toBe(true)
			end
			expect(near(sum, 100, 1e-6)).toBeTruthy()
			for _, rarity in RarityConfig.Order do
				if not core:supports(dice.Id, rarity) then
					expect(weights[rarity]).toBeNil()
					expect(core:rarityChances(dice.Id)[rarity] or 0).toBe(0)
				end
			end
		end
	end)

	it("pesos APROVADOS (Variante B + Divino reduzido): explícitos, sem normalização", function()
		local expected = {
			Shinobi = { Common = 35, Uncommon = 33, Rare = 22, Epic = 10 },
			Flame = { Uncommon = 60, Rare = 28, Epic = 11, Legendary = 1 },
			Colossus = { Epic = 40, Legendary = 45, Mythic = 15 },
			Awakened = { Legendary = 85, Mythic = 15 },
			Celestial = { Legendary = 64, Mythic = 35.5, Divine = 0.5 },
			Forbidden = { Mythic = 99.2455, Divine = 0.75, Secret = 0.0045 },
		}
		for id, weights in expected do
			local w = core:rarityWeights(id)
			for rarity, value in weights do
				expect(near(w[rarity], value, 1e-9)).toBeTruthy()
			end
		end
		for _, dice in core:diceList() do
			expect(dice.RarityWeights ~= nil).toBeTruthy()
		end
	end)

	it("sem fallback: Dice sorteável sem RarityWeights é erro (construção) e problema (auditoria)", function()
		local DiceBalance = require("../tools/sim/DiceBalance")
		local broken = DiceBalance.withWeights({})
		expect((pcall(DiceCore.new, broken, CharacterConfig, RarityConfig, RollConfig))).toBe(false)
		local problems = DiceCore.validate(broken, CharacterConfig, RarityConfig)
		local found = false
		for _, p in problems do
			found = found or string.find(p, "sem RarityWeights explícitos", 1, true) ~= nil
		end
		expect(found).toBe(true)
	end)
end)

describe("Dice: probabilidade por personagem (GetCharacterProbability)", function()
	it("soma dos personagens de cada Dice = 100%", function()
		for _, dice in core:diceList() do
			local sum = 0
			for _, id in core:charactersFor(dice.Id) do
				sum += core:characterProbability(dice.Id, id)
			end
			expect(near(sum, 1, 1e-9)).toBeTruthy()
		end
	end)

	it("P(personagem) = P(raridade no Dice) × 1 / quantidade da raridade", function()
		for _, dice in core:diceList() do
			local pool = core:pool(dice.Id)
			for rarity, ids in pool.byRarity do
				for _, id in ids do
					expect(near(core:characterProbability(dice.Id, id), pool.percent[rarity] / 100 / #ids, 1e-12)).toBeTruthy()
				end
			end
		end
		-- Starter Épico (1 personagem): 3%
		local epic = core:pool("Starter").byRarity.Epic[1]
		expect(near(core:characterProbability("Starter", epic), 0.03, 1e-12)).toBeTruthy()
	end)

	it("personagem fora do Dice / inexistente = 0%", function()
		local blade = core:charactersFor("Blade")[1]
		expect(core:characterProbability("Starter", blade)).toBe(0)
		expect(core:characterProbability("Starter", "nao_existe")).toBe(0)
		expect(core:characterProbability("NaoExiste", blade)).toBe(0)
		expect(core:characterProbability("Starter", "flame_rookie")).toBe(0) -- legado
	end)
end)

describe("Dice: Luck (só sobre as raridades do Dice)", function()
	it("Luck mantém soma 100%, não cria raridade ausente, sobe as altas e dilui a mais baixa", function()
		for _, dice in core:diceList() do
			local base = core:rarityWeights(dice.Id, 1)
			for _, luck in { 1.5, 2, 5, 20, 1000 } do
				local w = core:rarityWeights(dice.Id, luck)
				local sum = 0
				for rarity, value in w do
					sum += value
					expect(base[rarity] ~= nil).toBeTruthy()
				end
				expect(near(sum, 100, 1e-6)).toBeTruthy()
				local pool = core:pool(dice.Id)
				local lowest, highest = pool.rarities[1], pool.rarities[#pool.rarities]
				if lowest ~= highest then
					expect(w[lowest] < base[lowest]).toBeTruthy()
					expect(w[highest] > base[highest]).toBeTruthy()
				end
			end
		end
	end)

	it("mesma fórmula de Luck efetiva do jogo (retornos decrescentes)", function()
		expect(core:effectiveLuck(1)).toBe(1)
		expect(near(core:effectiveLuck(10), 1 + 9 / (1 + 9 / RollConfig.LuckSoftCap))).toBeTruthy()
		expect(core:effectiveLuck(0.5)).toBe(1)
	end)

	it("AUTO / OCULTAR / Roll Rápido não mudam a Luck (nem as chances)", function()
		local f = Formulas.new({
			Dice = DiceConfig,
			Upgrades = require("../src/shared/Config/UpgradeConfig"),
			Roll = RollConfig,
			Economy = require("../src/shared/Config/EconomyConfig"),
			Characters = CharacterConfig,
			Levels = require("../src/shared/Config/CharacterLevelConfig"),
			Variants = require("../src/shared/Config/VariantConfig"),
			Rebirth = require("../src/shared/Config/RebirthConfig"),
		})
		local data: any = deepCopy(DataConfig.Template)
		local a = f:luck(data, 0)
		data.Settings.AutoRoll = true
		data.Settings.HideRollAnimation = true
		data.Runtime = { FastRoll = true }
		expect(f:luck(data, 0)).toBe(a)
		expect(RollConfig.RollSpeed.BaseInterval).toBe(1.0)
		expect(RollConfig.RollSpeed.FastRollInterval).toBe(0.5)
		expect(RollConfig.RollSpeed.UpgradesAffectInterval).toBe(false)
	end)
end)

describe("Dice: pity (só em Dice compatível)", function()
	local function fixedRand(value: number): () -> number
		return function()
			return value
		end
	end

	it("pity Lendário NÃO dispara em Dice sem Lendário (Starter) e NÃO é consumido", function()
		local r = core:roll("Starter", 1, { Legendary = 49, Mythic = 799 }, fixedRand(0))
		expect(r.pityTriggered).toBeNil()
		expect(r.rarity).toBe("Common")
		expect(r.pity.Legendary).toBe(49) -- congelado
		expect(r.pity.Mythic).toBe(799)
		expect(core:pityFor("Starter", { Legendary = 1000, Mythic = 1000 })).toBeNil()
	end)

	it("o mesmo contador dispara num Dice compatível (Flame) e zera", function()
		local r = core:roll("Flame", 1, { Legendary = 49, Mythic = 3 }, fixedRand(0))
		expect(r.pityTriggered).toBe("Legendary")
		expect(r.rarity).toBe("Legendary")
		expect(r.pity.Legendary).toBe(0)
		expect(r.pity.Mythic).toBe(3) -- Flame não tem Mítico: congelado
	end)

	it("pity Mítico só dispara em Dice com Mítico; vence o Lendário quando ambos disparam", function()
		local storm = core:roll("Storm", 1, { Legendary = 10, Mythic = RollConfig.Pity[2].Threshold - 1 }, fixedRand(0))
		expect(storm.pityTriggered).toBeNil() -- Storm não tem Mítico
		local spirit = core:roll("Spirit", 1, { Legendary = 49, Mythic = RollConfig.Pity[2].Threshold - 1 }, fixedRand(0))
		expect(spirit.pityTriggered).toBe("Mythic")
		expect(spirit.rarity).toBe("Mythic")
		expect(spirit.pity.Mythic).toBe(0)
		expect(spirit.pity.Legendary).toBe(0)
	end)

	it("contador incrementa só em Dice compatível; zera ao tirar a raridade ou melhor (qualquer Dice)", function()
		expect(core:nextPity("Flame", { Legendary = 5, Mythic = 5 }, "Rare").Legendary).toBe(6)
		expect(core:nextPity("Starter", { Legendary = 5, Mythic = 5 }, "Rare").Legendary).toBe(5)
		-- Forbidden não tem Lendário, mas tudo nele é Mítico+: o pity Lendário zera
		expect(core:nextPity("Forbidden", { Legendary = 30, Mythic = 30 }, "Divine").Legendary).toBe(0)
		expect(core:nextPity("Forbidden", { Legendary = 30, Mythic = 30 }, "Divine").Mythic).toBe(0)
	end)

	it("pity não aumenta raridades acima do piso (sorteio natural mantido)", function()
		local withPity = core:rarityChances("Void", 1, { Legendary = 49 })
		local without = core:rarityChances("Void", 1, {})
		expect(withPity.Epic).toBe(0)
		expect(near(withPity.Legendary, without.Legendary + without.Epic, 1e-12)).toBeTruthy()
		expect(near(withPity.Mythic, without.Mythic, 1e-12) and near(withPity.Divine, without.Divine, 1e-12)).toBeTruthy()
	end)

	it("prêmio (Jackpot): Dice selecionado se tem a raridade; senão o primeiro que tem", function()
		expect(core:grantDice("Void", "Mythic")).toBe("Void")
		expect(core:grantDice("Starter", "Legendary")).toBe("Flame")
		expect(core:grantDice("Starter", "Mythic")).toBe("Spirit")
		expect(core:grantDice("Starter", "Epic")).toBe("Starter")
	end)
end)

describe("Dice: simulação (100.000 rolls por Dice, determinística)", function()
	it("frequência observada de cada personagem dentro de 5 desvios-padrão; nunca fora do Dice", function()
		local N = 100000
		for i, dice in core:diceList() do
			local rand = Rng.new(1000 + i * 7919)
			local counts = {}
			for _ = 1, N do
				local id = core:pickCharacter(dice.Id, core:pickRarity(dice.Id, 1, rand), rand)
				counts[id] = (counts[id] or 0) + 1
			end
			local inDice = {}
			for _, id in core:charactersFor(dice.Id) do
				inDice[id] = true
				local p = core:characterProbability(dice.Id, id)
				local expected = N * p
				local sigma = math.sqrt(N * p * (1 - p))
				local observed = counts[id] or 0
				if math.abs(observed - expected) > 5 * sigma + 1 then
					error(string.format("%s %s: observado %d, esperado %.1f (5σ = %.1f)", dice.Id, id, observed, expected, 5 * sigma))
				end
			end
			for id in counts do
				expect(inDice[id]).toBe(true)
			end
		end
	end)
end)

describe("Dice: auditoria detecta configuração inválida", function()
	local function pools(): any
		return DiceCore.buildPools(DiceConfig, CharacterConfig)
	end
	local function has(problems: { string }, text: string): boolean
		for _, p in problems do
			if string.find(p, text, 1, true) then
				return true
			end
		end
		return false
	end

	it("total != 100%", function()
		local problems = DiceCore.validate(DiceConfig, CharacterConfig, RarityConfig, nil, { Starter = { Common = 50, Uncommon = 25, Rare = 12, Epic = 5 } })
		expect(has(problems, "Starter: pesos somam")).toBe(true)
	end)

	it("raridade com peso e sem personagem", function()
		local problems = DiceCore.validate(DiceConfig, CharacterConfig, RarityConfig, nil, { Starter = { Common = 50, Uncommon = 25, Rare = 12, Epic = 5, Legendary = 8 } })
		expect(has(problems, "Starter: raridade Legendary com 8% e nenhum personagem")).toBe(true)
	end)

	it("personagem duplicado em dois Dice", function()
		local p = pools()
		table.insert(p.Lucky.Common, p.Starter.Common[1])
		expect(has(DiceCore.validate(DiceConfig, CharacterConfig, RarityConfig, p), "duplicado")).toBe(true)
	end)

	it("F2P ausente (sem Dice)", function()
		local p = pools()
		local removed = table.remove(p.Starter.Common, 1)
		expect(has(DiceCore.validate(DiceConfig, CharacterConfig, RarityConfig, p), removed .. ": F2P sem Dice")).toBe(true)
	end)

	it("raridade do personagem diferente do catálogo", function()
		local p = pools()
		local moved = table.remove(p.Starter.Epic, 1)
		table.insert(p.Starter.Common, moved)
		expect(has(DiceCore.validate(DiceConfig, CharacterConfig, RarityConfig, p), "mas o catálogo diz Epic")).toBe(true)
	end)

	it("Premium dentro de Dice F2P", function()
		local p = pools()
		local premium = CharacterConfig.Premium[1]
		p.Forbidden[premium.Rarity] = p.Forbidden[premium.Rarity] or {}
		table.insert(p.Forbidden[premium.Rarity], premium.Id)
		expect(has(DiceCore.validate(DiceConfig, CharacterConfig, RarityConfig, p), "Premium/fora do F2P")).toBe(true)
	end)

	it("contagem por raridade diferente da aprovada", function()
		local p = pools()
		table.remove(p.Starter.Common, 1)
		expect(has(DiceCore.validate(DiceConfig, CharacterConfig, RarityConfig, p), "Starter: Common tem 3 personagem(ns), aprovado 4")).toBe(true)
	end)
end)

describe("Dice: save (SelectedDiceId)", function()
	it("perfil novo: Starter selecionado e desbloqueado", function()
		expect(DataConfig.Template.EquippedDice).toBe(DiceConfig.Default)
		expect(DataConfig.Template.OwnedDice.Starter).toBe(true)
		expect(DataConfig.SchemaVersion).toBe(4) -- v4: investimento por instância + cap 30
		expect(next(DataConfig.Template.DiceRolls)).toBeNil()
	end)

	it("migração v3: Normal -> Starter (âncoras mantidas), equipado inválido -> Starter", function()
		local out = Migrations[3]({ EquippedDice = "Normal", OwnedDice = { Normal = true, Lucky = true, Prism = true } })
		expect(out.EquippedDice).toBe("Starter")
		expect(out.OwnedDice.Starter and out.OwnedDice.Lucky and out.OwnedDice.Prism).toBe(true)
		expect(out.OwnedDice.Normal).toBeNil()
		local broken = Migrations[3]({ EquippedDice = 42 })
		expect(broken.EquippedDice).toBe("Starter")
		expect(broken.OwnedDice.Starter).toBe(true)
		local kept = Migrations[3]({ EquippedDice = "Void", OwnedDice = { Normal = true, Void = true } })
		expect(kept.EquippedDice).toBe("Void")
	end)
end)

return true
