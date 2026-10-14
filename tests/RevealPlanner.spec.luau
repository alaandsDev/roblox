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
		-- Divino/Secreto viraram JACKPOT REVEAL (fase 15: queda visível + aura Full + leitura):
		-- faixas ampliadas pelo design aprovado (antes Divine 2,5–3,5 e Secret 3,5–4,5)
		local ranges = { Legendary = { 2.0, 2.8 }, Mythic = { 2.5, 3.2 }, Divine = { 4.0, 5.5 }, Secret = { 5.5, 7.0 } }
		local last = 0
		for _, id in { "Legendary", "Mythic", "Divine", "Secret" } do
			local c = RevealConfig.Cinematics[id]
			expect(c.Duration >= ranges[id][1] and c.Duration <= ranges[id][2]).toBeTruthy()
			expect(c.Shake > last).toBeTruthy()
			last = c.Shake
		end
	end)

	it("OCULTAR: tudo compacto (estilo por raridade), exceto Divino e Secreto", function()
		expect(planner:plan({ rarity = "Common", hide = true }).mode).toBe("Compact")
		local legendary = planner:plan({ rarity = "Legendary", hide = true })
		expect(legendary.mode).toBe("Compact")
		expect(legendary.compactStyle).toBe("Special")
		expect(planner:plan({ rarity = "Mythic", hide = true }).compactStyle).toBe("Highlight")
		expect(planner:plan({ rarity = "Divine", hide = true }).compactStyle).toBe("Premium")
		expect(planner:plan({ rarity = "Divine", hide = true }).mode).toBe("HeroLanding")
		expect(planner:plan({ rarity = "Secret", hide = true }).mode).toBe("HeroLanding")
	end)

	it("Divino respeita OCULTAR se ForceCinematicForDivine = false", function()
		RevealConfig.ForceCinematicForDivine = false
		expect(planner:plan({ rarity = "Divine", hide = true }).mode).toBe("Compact")
		RevealConfig.ForceCinematicForDivine = true
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
		-- Odds exibidas agora vêm do Dice do personagem (DiceCore:odds; RollService e reveal):
		-- Starter, Épico: 3% e 1 personagem = 1 em 33
		local DiceCore = require("../src/shared/Modules/DiceCore")
		local DiceConfig = require("../src/shared/Config/DiceConfig")
		local RollConfig = require("../src/shared/Config/RollConfig")
		local dice = DiceCore.new(DiceConfig, CharacterConfig, RarityConfig, RollConfig)
		local starterEpic = dice.pools.Starter.byRarity.Epic[1]
		expect(dice:odds(starterEpic)).toBe(33)
		-- Forbidden, Secreto: 0,0045% dividido por 3 personagens = 1 em ~66.667
		local forbiddenSecret = dice.pools.Forbidden.byRarity.Secret[1]
		expect(dice:odds(forbiddenSecret)).toBe(66667)
		-- Premium e legados: fora dos Dice, sem "1 em X"
		expect(dice:odds(CharacterConfig.Premium[1].Id)).toBe(0)
		expect(dice:odds("dragon_knight")).toBe(0)
		-- Odds GLOBAIS da raridade (tabela de referência do RarityConfig) continuam iguais
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

describe("Jackpot Reveal (Divino/Secreto): palco no mundo, timing próprio", function()
	it("Divino/Secreto vão para o palco no MUNDO (aura Full visível); Lendário/Mítico seguem no viewport", function()
		expect(planner:plan({ rarity = "Divine" }).stage).toBe("World")
		expect(planner:plan({ rarity = "Secret" }).stage).toBe("World")
		expect(planner:plan({ rarity = "Legendary" }).stage).toBe("Viewport")
		expect(planner:plan({ rarity = "Mythic" }).stage).toBe("Viewport")
		expect(planner:plan({ rarity = "Epic" }).stage).toBeNil()
	end)

	it("linha do tempo em ordem: surge ALTO -> queda -> impacto -> levanta -> pose -> CONTINUAR", function()
		for _, id in { "Divine", "Secret" } do
			local c = RevealConfig.Cinematics[id]
			expect(c.Appear < c.FallStart and c.FallStart < c.Impact and c.Impact < c.Rise and c.Rise < c.Pose).toBeTruthy()
			expect(c.Impact < c.Title and c.Title < c.Continue and c.Continue < c.Duration).toBeTruthy()
			-- queda perceptível: pelo menos 0,7 s no ar e dezenas de studs
			expect(c.Impact - c.FallStart >= 0.7 and c.MinDrop >= 40).toBeTruthy()
		end
	end)

	it("Secreto NÃO é o Divino com partículas maiores: suspense, câmera, aceleração e entrada da aura próprios", function()
		local d, s = RevealConfig.Cinematics.Divine, RevealConfig.Cinematics.Secret
		expect(s.Suspense ~= nil and d.Suspense == nil).toBeTruthy()
		expect(s.SlowMo ~= nil and d.SlowMo == nil).toBeTruthy()
		expect(s.Camera ~= d.Camera).toBeTruthy()
		expect(s.AuraEntry ~= d.AuraEntry).toBeTruthy()
		expect(s.FallPower > d.FallPower and s.MinDrop > d.MinDrop).toBeTruthy()
		expect(s.Shake > d.Shake and s.ShakeTime > d.ShakeTime and s.RingSize > d.RingSize).toBeTruthy()
	end)

	it("AUTO + OCULTAR: Divino/Secreto ainda pausam o AUTO (cinemática toca)", function()
		expect(planner:plan({ rarity = "Divine", autoRoll = true, hide = true }).pauseAutoRoll).toBe(true)
		expect(planner:plan({ rarity = "Secret", autoRoll = true, hide = true }).pauseAutoRoll).toBe(true)
	end)
end)

return true
