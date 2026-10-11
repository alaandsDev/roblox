local T = require("./TestLib")
local RevealPlanner = require("../src/shared/Modules/RevealPlanner")
local RevealConfig = require("../src/shared/Config/RevealConfig")
local RarityConfig = require("../src/shared/Config/RarityConfig")
local CharacterConfig = require("../src/shared/Config/CharacterConfig")
local describe, it, expect = T.describe, T.it, T.expect

local planner = RevealPlanner.new(RevealConfig, RarityConfig, CharacterConfig)

describe("Reveal: qual apresentação tocar", function()
	it("Comum/Incomum/Raro: reveal normal, sem cinemática", function()
		for _, id in { "Common", "Uncommon", "Rare" } do
			local plan = planner:plan({ rarity = id })
			expect(plan.mode).toBe("Normal")
			expect(plan.cinematic).toBeNil()
		end
	end)

	it("Épico: reveal melhorado, sem Hero Landing", function()
		local plan = planner:plan({ rarity = "Epic" })
		expect(plan.mode).toBe("Enhanced")
		expect(plan.cinematic).toBeNil()
	end)

	it("Lendário/Mítico/Divino/Secreto: Hero Landing com o preset certo", function()
		for _, id in { "Legendary", "Mythic", "Divine", "Secret" } do
			local plan = planner:plan({ rarity = id })
			expect(plan.mode).toBe("HeroLanding")
			expect(plan.cinematic).toBe(id)
		end
	end)

	it("durações nas faixas pedidas e cada raridade supera a anterior", function()
		local ranges = { Legendary = { 2.0, 2.8 }, Mythic = { 2.5, 3.2 }, Divine = { 2.5, 3.5 }, Secret = { 3.5, 4.5 } }
		local last = 0
		for _, id in { "Legendary", "Mythic", "Divine", "Secret" } do
			local c = RevealConfig.Cinematics[id]
			expect(c.Duration >= ranges[id][1] and c.Duration <= ranges[id][2]).toBeTruthy()
			expect(c.Shake > last).toBeTruthy()
			last = c.Shake
		end
	end)

	it("OCULTAR: tudo compacto (estilo por raridade), exceto Secreto", function()
		expect(planner:plan({ rarity = "Common", hide = true }).mode).toBe("Compact")
		local legendary = planner:plan({ rarity = "Legendary", hide = true })
		expect(legendary.mode).toBe("Compact")
		expect(legendary.compactStyle).toBe("Special")
		expect(planner:plan({ rarity = "Mythic", hide = true }).compactStyle).toBe("Highlight")
		expect(planner:plan({ rarity = "Divine", hide = true }).compactStyle).toBe("Premium")
		expect(planner:plan({ rarity = "Secret", hide = true }).mode).toBe("HeroLanding")
	end)

	it("Secreto respeita OCULTAR se ForceCinematicForSecret = false", function()
		RevealConfig.ForceCinematicForSecret = false
		expect(planner:plan({ rarity = "Secret", hide = true }).mode).toBe("Compact")
		RevealConfig.ForceCinematicForSecret = true
	end)

	it("AUTO: comuns continuam, Lendário+ pausa (e não pausa se estiver compacto)", function()
		expect(planner:plan({ rarity = "Epic", autoRoll = true }).pauseAutoRoll).toBe(false)
		expect(planner:plan({ rarity = "Legendary", autoRoll = true }).pauseAutoRoll).toBe(true)
		expect(planner:plan({ rarity = "Mythic", autoRoll = true }).pauseAutoRoll).toBe(true)
		expect(planner:plan({ rarity = "Mythic", autoRoll = true, hide = true }).pauseAutoRoll).toBe(false)
		expect(planner:plan({ rarity = "Legendary" }).pauseAutoRoll).toBe(false)
	end)

	it("AUTO fecha o reveal sozinho", function()
		expect(planner:plan({ rarity = "Legendary", autoRoll = true }).autoClose > 0).toBeTruthy()
	end)

	it("NOVO aparece na primeira descoberta", function()
		expect(planner:plan({ rarity = "Common", isNew = true }).showNew).toBe(true)
		expect(planner:plan({ rarity = "Common", isNew = false }).showNew).toBe(false)
	end)

	it("PULAR: só depois de ver X vezes; primeira descoberta Mítico+ nunca pula", function()
		expect(planner:plan({ rarity = "Legendary", timesSeen = 0 }).canSkip).toBe(false)
		expect(planner:plan({ rarity = "Legendary", timesSeen = 5 }).canSkip).toBe(true)
		expect(planner:plan({ rarity = "Legendary", timesSeen = 5, isNew = true }).canSkip).toBe(true)
		expect(planner:plan({ rarity = "Mythic", timesSeen = 5, isNew = true }).canSkip).toBe(false)
		expect(planner:plan({ rarity = "Secret", timesSeen = 9, isNew = true }).canSkip).toBe(false)
	end)

	it("Efeitos reduzidos -> qualidade Low e tremida menor; tremida desligável", function()
		local plan = planner:plan({ rarity = "Divine", reducedEffects = true })
		expect(plan.quality).toBe("Low")
		expect(plan.shake < RevealConfig.Cinematics.Divine.Shake).toBeTruthy()
		expect(planner:plan({ rarity = "Divine", cameraShake = false }).shake).toBe(0)
		expect(planner:plan({ rarity = "Divine", mobile = true }).quality).toBe("Medium")
		expect(planner:plan({ rarity = "Divine" }).quality).toBe("High")
	end)

	it("odds exibidas batem com a config (chance base por personagem)", function()
		-- Lendário: 1,3% dividido por 3 personagens = 1 em ~231
		expect(planner:odds("dragon_knight")).toBe(231)
		-- Secreto: 0,0005% e 1 personagem = 1 em 200.000
		expect(planner:odds("eclipse_sovereign")).toBe(200000)
		expect(planner:rarityOdds("Mythic")).toBe(1667)
		expect(planner:odds("nao_existe")).toBe(0)
	end)

	it("social: Mítico discreto, Divino global, Secreto destaque", function()
		expect(planner:plan({ rarity = "Legendary" }).social).toBe("None")
		expect(planner:plan({ rarity = "Mythic" }).social).toBe("Discreet")
		expect(planner:plan({ rarity = "Divine" }).social).toBe("Global")
		expect(planner:plan({ rarity = "Secret" }).social).toBe("Highlight")
	end)
end)

return true
