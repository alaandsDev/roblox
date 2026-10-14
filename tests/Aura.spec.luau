-- Auras de alta raridade (AuraPlanner/AuraConfig): raridade = intensidade, estilo = comportamento
local T = require("./TestLib")
local AuraPlanner = require("../src/shared/Modules/AuraPlanner")
local AuraConfig = require("../src/shared/Config/AuraConfig")
local CharacterConfig = require("../src/shared/Config/CharacterConfig")
local DiceConfig = require("../src/shared/Config/DiceConfig")
local describe, it, expect = T.describe, T.it, T.expect

local planner = AuraPlanner.new(AuraConfig, CharacterConfig, DiceConfig)
local ORDER = { "Legendary", "Mythic", "Divine", "Secret" }

local function anyOf(rarity: string): string
	for _, c in CharacterConfig.List do
		if c.Rarity == rarity then
			return c.Id
		end
	end
	error("sem personagem " .. rarity)
end

local function kinds(plan: any): { [string]: number }
	local out = {}
	for _, c in plan.components do
		out[c.kind] = c.count
	end
	return out
end

local function countKinds(plan: any): number
	local n = 0
	for _ in kinds(plan) do
		n += 1
	end
	return n
end

describe("Auras: arquitetura raridade × estilo", function()
	it("estilos completos: 2–3 cores, textura nativa, comportamento definido", function()
		for name, style in AuraConfig.Styles do
			expect(#style.Colors >= 2 and #style.Colors <= 3).toBeTruthy()
			expect(AuraConfig.Textures[style.Texture] ~= nil).toBeTruthy()
			expect(string.sub(AuraConfig.Textures[style.Texture], 1, 9)).toBe("rbxasset:")
			expect(style.Direction ~= nil and style.Bolts ~= nil).toBeTruthy()
			local _ = name
		end
		for _, dice in DiceConfig.List do
			if dice.Pool == "F2P" then
				expect(AuraConfig.Styles[AuraConfig.StyleByDice[dice.Id]] ~= nil).toBeTruthy()
			end
		end
	end)

	it("escalada clara: Lendário < Mítico < Divino < Secreto (densidade e nº de componentes)", function()
		local lastRate, lastKinds = -1, 0
		for _, rarity in ORDER do
			local plan = planner:resolve(anyOf(rarity), rarity, "Full")
			assert(plan)
			expect(plan.totalRate > lastRate).toBeTruthy()
			expect(countKinds(plan) >= lastKinds).toBeTruthy()
			lastRate, lastKinds = plan.totalRate, countKinds(plan)
		end
		local secret = planner:resolve(anyOf("Secret"), "Secret", "Full")
		assert(secret)
		local k = kinds(secret)
		-- Secreto: 3–4+ componentes coordenados além do corpo
		expect((k.Orbit or 0) >= 4 and (k.Pulse or 0) == 1 and (k.Ground or 0) == 1 and ((k.Bolt or 0) + (k.Wisp or 0)) >= 4).toBeTruthy()
		local legendary = planner:resolve(anyOf("Legendary"), "Legendary", "Full")
		assert(legendary)
		expect(kinds(legendary).Body).toBe(1)
		expect(kinds(legendary).Rise).toBe(1)
	end)

	it("mesmo espetáculo para estilos diferentes na mesma raridade (Mythic Electric × Mythic Flame)", function()
		local electric, flame = "char_killuo_godspeed", nil
		for _, c in CharacterConfig.List do
			if planner:styleOf(c.Id) == "Flame" then
				flame = c.Id
				break
			end
		end
		assert(flame)
		local a = planner:resolve(electric, "Mythic", "Full")
		local b = planner:resolve(flame, "Mythic", "Full")
		assert(a and b)
		expect(a.style).toBe("Electric")
		expect(b.style).toBe("Flame")
		expect(a.totalRate).toBe(b.totalRate)
		expect(countKinds(a)).toBe(countKinds(b))
		expect(kinds(a).Bolt ~= nil).toBeTruthy() -- elétrico: raios de verdade
		expect(kinds(b).Wisp ~= nil).toBeTruthy() -- fogo: fitas/chamas
	end)

	it("Killuo (referência elétrica) usa Electric com raios", function()
		expect(planner:styleOf("char_killuo_godspeed")).toBe("Electric")
		expect(AuraConfig.Styles.Electric.Bolts).toBe("Lightning")
	end)

	it("modos: None/Inventário sem aura; Light <= Full; Épico fora do sistema", function()
		local id = anyOf("Divine")
		expect(planner:resolve(id, "Divine", "None")).toBeNil()
		expect(planner:resolve(anyOf("Epic"), "Epic", "Full")).toBeNil()
		for _, rarity in ORDER do
			local full = planner:resolve(anyOf(rarity), rarity, "Full")
			local light = planner:resolve(anyOf(rarity), rarity, "Light")
			assert(full and light)
			expect(light.totalRate <= full.totalRate).toBeTruthy()
			expect(light.totalRate > 0).toBeTruthy() -- Light ainda tem presença
		end
	end)

	it("orçamento: nenhuma aura Full passa de MaxRatePerAura partículas/s", function()
		for _, rarity in ORDER do
			for _, c in CharacterConfig.List do
				if c.Rarity == rarity then
					local plan = planner:resolve(c.Id, rarity, "Full")
					assert(plan)
					expect(plan.totalRate <= AuraConfig.Budget.MaxRatePerAura).toBeTruthy()
				end
			end
		end
		expect(AuraConfig.Budget.MaxFull >= 1 and AuraConfig.Budget.MaxAnimated >= AuraConfig.Budget.MaxFull).toBeTruthy()
	end)
end)

return true
