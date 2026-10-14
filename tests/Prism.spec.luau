-- Prisma da Coleção (DiceCore:prismEligible / prismChances / prismPick)
local T = require("./TestLib")
local Rng = require("./Rng")
local DiceCore = require("../src/shared/Modules/DiceCore")
local DiceConfig = require("../src/shared/Config/DiceConfig")
local CharacterConfig = require("../src/shared/Config/CharacterConfig")
local RarityConfig = require("../src/shared/Config/RarityConfig")
local RollConfig = require("../src/shared/Config/RollConfig")
local PrismConfig = require("../src/shared/Config/PrismConfig")
local describe, it, expect = T.describe, T.it, T.expect

local core = DiceCore.new(DiceConfig, CharacterConfig, RarityConfig, RollConfig)

local function sum(map: { [string]: number }): number
	local total = 0
	for _, p in map do
		total += p
	end
	return total
end

local function discoveredExcept(diceId: string, keep: { string }): { [string]: any }
	local index = {}
	for _, id in core:charactersFor(diceId) do
		if not table.find(keep, id) then
			index[id] = { Count = 1 }
		end
	end
	return index
end

describe("Prisma da Coleção", function()
	it("config central: ligado, usos por recompensa, teto, intervalo, não mexe no pity nem conta roll", function()
		expect(PrismConfig.Enabled).toBe(true)
		expect(PrismConfig.DiceId).toBe("Prism")
		expect(PrismConfig.UsesPerReward > 0 and PrismConfig.MaxCharges >= PrismConfig.UsesPerReward).toBeTruthy()
		expect(PrismConfig.CooldownSeconds >= 0).toBeTruthy()
		expect(PrismConfig.AffectsPity).toBe(false)
		expect(PrismConfig.CountsAsRoll).toBe(false)
		expect(DiceConfig.ById.Prism.Exclusive).toBe(true)
	end)

	it("jogador sem nada descoberto: todos do Dice elegíveis, com as MESMAS chances do Dice", function()
		for _, dice in core:diceList() do
			local chances = core:prismChances(dice.Id, {}, 1)
			expect(#core:prismEligible(dice.Id, {})).toBe(#core:charactersFor(dice.Id))
			for _, id in core:charactersFor(dice.Id) do
				expect(math.abs(chances[id] - core:characterProbability(dice.Id, id, 1)) < 1e-12).toBeTruthy()
			end
			expect(math.abs(sum(chances) - 1) < 1e-9).toBeTruthy()
		end
	end)

	it("alguns descobertos: só os não descobertos, proporções relativas preservadas, soma 100%", function()
		local ids = core:charactersFor("Void")
		local index = { [ids[1]] = { Count = 1 }, [ids[2]] = { Count = 3 } }
		local chances = core:prismChances("Void", index, 1)
		expect(chances[ids[1]]).toBeNil()
		expect(chances[ids[2]]).toBeNil()
		expect(math.abs(sum(chances) - 1) < 1e-9).toBeTruthy()
		local a, b = ids[3], ids[#ids]
		local ratio = core:characterProbability("Void", a, 1) / core:characterProbability("Void", b, 1)
		expect(math.abs(chances[a] / chances[b] - ratio) < 1e-9).toBeTruthy()
	end)

	it("faltando exatamente 1: sempre esse personagem (100%)", function()
		local secret = core:pool("Forbidden").byRarity.Secret[2]
		local index = discoveredExcept("Forbidden", { secret })
		local chances = core:prismChances("Forbidden", index, 1)
		expect(chances[secret]).toBe(1)
		local rand = Rng.new(99)
		for _ = 1, 50 do
			expect(core:prismPick("Forbidden", index, 1, rand)).toBe(secret)
		end
	end)

	it("Dice completo: nada elegível (nil) — o servidor recusa sem gastar o uso", function()
		local index = discoveredExcept("Starter", {})
		expect(#core:prismEligible("Starter", index)).toBe(0)
		expect(next(core:prismChances("Starter", index, 1))).toBeNil()
		expect(core:prismPick("Starter", index, 1, Rng.new(1))).toBeNil()
	end)

	it("Dice inválido / não sorteável: nada elegível", function()
		expect(#core:prismEligible("NaoExiste", {})).toBe(0)
		expect(core:prismPick("NaoExiste", {}, 1, Rng.new(1))).toBeNil()
		expect(core:prismPick("Prism", {}, 1, Rng.new(1))).toBeNil()
	end)

	it("Premium e personagens de outro Dice nunca elegíveis; nunca sai fora do pool (10.000 usos)", function()
		local premium = {}
		for _, c in CharacterConfig.Premium do
			premium[c.Id] = true
		end
		for _, dice in core:diceList() do
			local pool = {}
			for _, id in core:charactersFor(dice.Id) do
				pool[id] = true
			end
			for id in core:prismChances(dice.Id, {}, 1) do
				expect(pool[id]).toBe(true)
				expect(premium[id]).toBeNil()
			end
		end
		local rand = Rng.new(2024)
		local index = { [core:charactersFor("Celestial")[1]] = { Count = 1 } }
		local pool = {}
		for _, id in core:charactersFor("Celestial") do
			pool[id] = true
		end
		for _ = 1, 10000 do
			local id = core:prismPick("Celestial", index, 1, rand)
			expect(pool[id] == true and index[id] == nil and not premium[id]).toBeTruthy()
		end
	end)

	it("frequência observada bate com as chances elegíveis (±5σ, 100.000 usos)", function()
		local ids = core:charactersFor("Spirit")
		local index = { [ids[1]] = { Count = 1 }, [ids[2]] = { Count = 1 } }
		local chances = core:prismChances("Spirit", index, 1)
		local counts = {}
		local rand = Rng.new(31337)
		local N = 100000
		for _ = 1, N do
			local id = core:prismPick("Spirit", index, 1, rand) :: string
			counts[id] = (counts[id] or 0) + 1
		end
		for id, p in chances do
			local sigma = math.sqrt(N * p * (1 - p))
			if math.abs((counts[id] or 0) - N * p) > 5 * sigma + 1 then
				error(`{id}: observado {counts[id]}, esperado {N * p}`)
			end
		end
	end)
end)

return true
