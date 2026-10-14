-- Auras V2 (AuraPlanner/AuraConfig): raridade = composição/alcance, estilo = identidade/assinatura
local T = require("./TestLib")
local AuraPlanner = require("../src/shared/Modules/AuraPlanner")
local AuraConfig = require("../src/shared/Config/AuraConfig")
local CharacterConfig = require("../src/shared/Config/CharacterConfig")
local DiceConfig = require("../src/shared/Config/DiceConfig")
local describe, it, expect = T.describe, T.it, T.expect

local planner = AuraPlanner.new(AuraConfig, CharacterConfig, DiceConfig)
local ORDER = { "Legendary", "Mythic", "Divine", "Secret" }
-- assinaturas implementadas pelo AuraBuilder (uma por estilo)
local SIGNATURES = { Lightning = true, Flames = true, Fragments = true, Shadows = true, Stars = true, Gusts = true, Shards = true, Rings = true, Wisps = true, Pull = true }

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

describe("Auras V2: estilos (identidade)", function()
	it("cada estilo: 2–3 cores + tom ESCURO de contraste, textura nativa e UMA assinatura própria", function()
		local used = {}
		for name, style in AuraConfig.Styles do
			expect(#style.Colors >= 2 and #style.Colors <= 3).toBeTruthy()
			expect(type(style.Dark) == "table" and #style.Dark == 3).toBeTruthy()
			-- o tom escuro é de fato mais escuro que a cor principal (contraste sobre fundo claro)
			local lum = function(c)
				return c[1] * 0.3 + c[2] * 0.59 + c[3] * 0.11
			end
			expect(lum(style.Dark) < lum(style.Colors[1])).toBeTruthy()
			expect(string.sub(AuraConfig.Textures[style.Texture], 1, 9)).toBe("rbxasset:")
			expect(SIGNATURES[style.Signature]).toBeTruthy()
			expect(used[style.Signature]).toBeNil()
			used[style.Signature] = name
		end
		for _, dice in DiceConfig.List do
			if dice.Pool == "F2P" then
				expect(AuraConfig.Styles[AuraConfig.StyleByDice[dice.Id]] ~= nil).toBeTruthy()
			end
		end
	end)

	it("Killuo (referência elétrica) usa Electric com raios (assinatura Lightning)", function()
		expect(planner:styleOf("char_killuo_godspeed")).toBe("Electric")
		local plan = planner:resolve("char_killuo_godspeed", "Legendary", "Light")
		assert(plan)
		expect(plan.signature).toBe("Lightning")
		expect(kinds(plan).Signature >= 1).toBeTruthy()
	end)
end)

describe("Auras V2: hierarquia por raridade (camadas e silhueta)", function()
	it("camadas coordenadas: Lendário 2–3 · Mítico 4–5 · Divino 6–8 · Secreto 8–12", function()
		local ranges = { Legendary = { 2, 3 }, Mythic = { 4, 5 }, Divine = { 6, 8 }, Secret = { 8, 12 } }
		for _, rarity in ORDER do
			local plan = planner:resolve(anyOf(rarity), rarity, "Full")
			assert(plan)
			local r = ranges[rarity]
			expect(plan.layers >= r[1] and plan.layers <= r[2]).toBeTruthy()
		end
	end)

	it("silhueta: Lendário ~1,2 · Mítico ~1,5 · Divino ~2,0 · Secreto ~2,5 (× personagem)", function()
		local ranges = { Legendary = { 1.15, 1.25 }, Mythic = { 1.4, 1.6 }, Divine = { 1.8, 2.2 }, Secret = { 2.2, 2.8 } }
		for _, rarity in ORDER do
			local plan = planner:resolve(anyOf(rarity), rarity, "Light")
			assert(plan)
			expect(plan.silhouette >= ranges[rarity][1] and plan.silhouette <= ranges[rarity][2]).toBeTruthy()
		end
	end)

	it("escalada estrita (camadas, densidade, silhueta) e Divino = composição completa", function()
		local last = { layers = 0, rate = -1, silhouette = 0 }
		for _, rarity in ORDER do
			local plan = planner:resolve(anyOf(rarity), rarity, "Full")
			assert(plan)
			expect(plan.layers > last.layers and plan.totalRate > last.rate and plan.silhouette > last.silhouette).toBeTruthy()
			last = { layers = plan.layers, rate = plan.totalRate, silhouette = plan.silhouette }
		end
		local divine = planner:resolve(anyOf("Divine"), "Divine", "Full")
		assert(divine)
		local k = kinds(divine)
		-- corpo, externas subindo, frente/trás, 2–3 órbitas, fita, anel no chão, shockwave, assinatura
		for _, kind in { "Body", "Rise", "Depth", "Ribbon", "Ground", "Shockwave", "Signature" } do
			expect(k[kind] ~= nil).toBeTruthy()
		end
		expect(k.Orbit >= 2 and k.Orbit <= 3).toBeTruthy()
		local secret = planner:resolve(anyOf("Secret"), "Secret", "Full")
		assert(secret)
		local s = kinds(secret)
		expect(s.Orbit >= 3 and s.Orbit <= 4 and s.Crown == 1 and s.Contrast == 1 and s.Outer == 1).toBeTruthy()
		-- Lendário: corpo + subida + assinatura (sem órbitas)
		local legendary = kinds(planner:resolve(anyOf("Legendary"), "Legendary", "Full"))
		expect(legendary.Body == 1 and legendary.Rise == 1 and legendary.Signature ~= nil and legendary.Orbit == nil).toBeTruthy()
	end)

	it("contorno de silhueta (Highlight) a partir do Mítico", function()
		expect((planner:resolve(anyOf("Legendary"), "Legendary", "Light") :: any).highlight).toBe(false)
		for _, rarity in { "Mythic", "Divine", "Secret" } do
			expect((planner:resolve(anyOf(rarity), rarity, "Light") :: any).highlight).toBe(true)
		end
	end)

	it("mesmo espetáculo para estilos diferentes na mesma raridade (Mythic Electric × Mythic Flame)", function()
		local a = planner:resolve("char_killuo_godspeed", "Mythic", "Full", "Electric")
		local b = planner:resolve("char_killuo_godspeed", "Mythic", "Full", "Flame")
		assert(a and b)
		expect(a.style).toBe("Electric")
		expect(b.style).toBe("Flame")
		expect(a.totalRate).toBe(b.totalRate)
		expect(a.layers).toBe(b.layers)
		expect(a.signature ~= b.signature).toBeTruthy()
	end)
end)

describe("Auras V2: Light × Full e orçamento", function()
	it("Light = MESMA identidade (mesmas camadas e assinatura) com menos partículas; None/Épico sem aura", function()
		expect(planner:resolve(anyOf("Divine"), "Divine", "None")).toBeNil()
		expect(planner:resolve(anyOf("Epic"), "Epic", "Full")).toBeNil()
		for _, rarity in ORDER do
			local full = planner:resolve(anyOf(rarity), rarity, "Full")
			local light = planner:resolve(anyOf(rarity), rarity, "Light")
			assert(full and light)
			expect(light.layers).toBe(full.layers)
			expect(light.signature).toBe(full.signature)
			expect(light.silhouette).toBe(full.silhouette)
			for kind in kinds(full) do
				expect(kinds(light)[kind] ~= nil).toBeTruthy()
			end
			expect(light.totalRate > 0 and light.totalRate <= full.totalRate * 0.6).toBeTruthy()
		end
	end)

	it("orçamento: nenhuma aura Full passa de MaxRatePerAura partículas/s nem de MaxAlivePerAura vivas", function()
		for _, rarity in ORDER do
			for _, c in CharacterConfig.List do
				if c.Rarity == rarity then
					local plan = planner:resolve(c.Id, rarity, "Full")
					assert(plan)
					expect(plan.totalRate <= AuraConfig.Budget.MaxRatePerAura).toBeTruthy()
					expect(plan.alive <= AuraConfig.Budget.MaxAlivePerAura).toBeTruthy()
				end
			end
		end
		local B = AuraConfig.Budget
		expect(B.MaxFull >= 1 and B.MaxAnimated >= B.MaxFull and B.MaxHighlights <= 31).toBeTruthy()
		expect(B.CullDistance > B.MidDistance).toBeTruthy()
	end)
end)

return true
