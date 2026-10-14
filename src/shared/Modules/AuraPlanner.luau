--!strict
--[[
	AuraPlanner (puro, configs injetadas): decide ESTILO e PLANO da aura V2 (camadas por zona).
	    local planner = AuraPlanner.new(AuraConfig, CharacterConfig, DiceConfig)
	    planner:styleOf(characterId)                         -> override do personagem > Dice > padrão
	    planner:resolve(characterId, rarity, mode, style?)   -> Plan? (nil = sem aura alta / None)
	O AuraBuilder transforma o plano em Instances; o AuraController anima (loop central).
	Testado em tests/Aura.spec.luau (camadas por raridade, silhueta, orçamento, Light = mesma
	identidade, mesmo espetáculo entre estilos na mesma raridade).
]]

local AuraPlanner = {}
AuraPlanner.__index = AuraPlanner

local RARITY_TIER = { Legendary = "Legendary", Mythic = "Mythic", Divine = "Divine", Secret = "Secret" }

--[[
	Camadas (kinds): taxa base (partículas/s antes de Tier.Rate e do Light), vida média (s) e zona.
	Burst = emitido em rajadas pelo cliente (taxa média = Burst / PulseEvery).
]]
AuraPlanner.Kinds = {
	Body = { rate = 18, life = 1.3, zone = "Inner" }, -- massa colorida colada no corpo (alfa)
	Contrast = { rate = 8, life = 1.4, zone = "Inner" }, -- fundo ESCURO atrás do corpo
	Depth = { rate = 14, life = 1.2, zone = "Mid" }, -- partículas na frente E atrás (profundidade)
	Rise = { rate = 12, life = 1.2, zone = "Mid" }, -- streaks subindo ao redor (sobe além da cabeça)
	Outer = { rate = 8, life = 2.2, zone = "Outer" }, -- coluna externa (alarga a silhueta)
	Orbit = { rate = 6, life = 0.6, zone = "Mid" }, -- por orbitador: cabeça + rastro (Trail)
	Ribbon = { rate = 0, life = 0, zone = "Mid" }, -- Beams animados (raios/fitas)
	Ground = { rate = 10, life = 1.4, zone = "Outer" }, -- anel/runas no chão
	Shockwave = { rate = 0, life = 0.7, zone = "Outer", burst = 2 }, -- anel que expande
	Pulse = { rate = 0, life = 0.6, zone = "Mid", burst = 18 }, -- explosão controlada
	Signature = { rate = 14, life = 1, zone = "Mid" }, -- elemento do ESTILO (por 3 assinaturas)
	Crown = { rate = 10, life = 1.2, zone = "Outer" }, -- Secreto: coroa/halo + erupção periódica
}

export type Component = { kind: string, count: number, rate: number, life: number, zone: string }
export type Plan = {
	style: string,
	tier: string,
	mode: string,
	components: { Component },
	layers: number,
	totalRate: number,
	alive: number,
	silhouette: number,
	orbiters: number,
	signature: string,
	signatureCount: number,
	glow: number,
	highlight: boolean,
	pulseEvery: number?,
}

function AuraPlanner.new(auraConfig: any, characterConfig: any, diceConfig: any): any
	return setmetatable({ aura = auraConfig, characters = characterConfig, dice = diceConfig }, AuraPlanner)
end

function AuraPlanner:styleOf(characterId: string): string
	for _, rule in self.aura.StyleByCharacterPrefix do
		if string.sub(characterId, 1, #rule.Prefix) == rule.Prefix then
			return rule.Style
		end
	end
	local character = self.characters.ById[characterId]
	local dice = character and character.DefaultDice and self.dice.ByCatalogKey[character.DefaultDice]
	return (dice and self.aura.StyleByDice[dice.Id]) or self.aura.DefaultStyle
end

function AuraPlanner:resolve(characterId: string, rarity: string, mode: string, styleOverride: string?): Plan?
	local tierName = RARITY_TIER[rarity]
	if not tierName or mode == "None" then
		return nil
	end
	local A = self.aura
	local tier = A.Tiers[tierName]
	local style = if styleOverride and A.Styles[styleOverride] then styleOverride else self:styleOf(characterId)
	local styleDef = A.Styles[style]
	local light = mode ~= "Full"
	local L = A.LightScale
	local scale = tier.Rate * (if light then L.Rate else 1)
	local orbiters = if light then math.max(1, math.floor(tier.Orbiters * L.Orbits + 0.5)) else tier.Orbiters
	local signatureCount = if light then math.max(1, math.floor(tier.SignatureCount * L.Signature + 0.5)) else tier.SignatureCount
	local components: { Component } = {}
	local total, alive = 0, 0
	for _, kind in tier.Layers do
		local spec = AuraPlanner.Kinds[kind]
		local count, rate = 1, spec.rate * scale
		if kind == "Orbit" then
			count = orbiters
		elseif kind == "Signature" then
			count = signatureCount
			rate = spec.rate * (signatureCount / 3) * tier.Rate * (if light then L.Rate / L.Signature else 1)
		elseif kind == "Ribbon" then
			count = math.max(2, math.floor(signatureCount / 2))
		elseif spec.burst then
			local every = tier.PulseEvery or 4
			rate = spec.burst * (if light then L.Rate else 1) / every
		end
		local perComponent = if kind == "Orbit" then rate * count else rate
		table.insert(components, { kind = kind, count = count, rate = rate, life = spec.life, zone = spec.zone })
		total += perComponent
		alive += perComponent * spec.life
	end
	return {
		style = style,
		tier = tierName,
		mode = mode,
		components = components,
		layers = #tier.Layers,
		totalRate = total,
		alive = alive,
		silhouette = tier.Silhouette,
		orbiters = orbiters,
		signature = styleDef.Signature,
		signatureCount = signatureCount,
		glow = tier.Glow,
		highlight = tier.Highlight,
		pulseEvery = tier.PulseEvery,
	}
end

return AuraPlanner
