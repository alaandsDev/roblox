--!strict
--[[
	AuraPlanner (puro, configs injetadas): decide ESTILO e PLANO da aura (componentes e taxas).
	    local planner = AuraPlanner.new(AuraConfig, CharacterConfig, DiceConfig)
	    planner:styleOf(characterId)                -> override do personagem > Dice de origem > padrão
	    planner:resolve(characterId, rarity, mode)  -> Plan? (nil = sem aura alta / modo None)
	O AuraBuilder transforma o plano em Instances. Testado em tests/Aura.spec.luau.
]]

local AuraPlanner = {}
AuraPlanner.__index = AuraPlanner

local RARITY_TIER = { Legendary = "Legendary", Mythic = "Mythic", Divine = "Divine", Secret = "Secret" }

export type Component = { kind: string, count: number, rate: number }
export type Plan = { style: string, tier: string, mode: string, components: { Component }, totalRate: number, glow: number, pulseEvery: number? }

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

function AuraPlanner:resolve(characterId: string, rarity: string, mode: string): Plan?
	local tierName = RARITY_TIER[rarity]
	if not tierName or mode == "None" then
		return nil
	end
	local A = self.aura
	local tier = A.Tiers[tierName]
	local style = self:styleOf(characterId)
	local styleDef = A.Styles[style]
	local light = mode ~= "Full"
	local L = A.LightScale
	local rateScale = if light then L.Rate else 1
	local components: { Component } = {}
	local total = 0
	local function add(kind: string, count: number, rate: number)
		if count > 0 then
			table.insert(components, { kind = kind, count = count, rate = rate })
			total += count * rate
		end
	end
	add("Body", tier.Layers, tier.BodyRate * rateScale)
	if tier.Rise then
		add("Rise", 1, tier.RiseRate * rateScale)
	end
	if tier.Sparks > 0 then
		add("Sparks", 1, tier.Sparks * (if light then L.Sparks else 1))
	end
	add("Orbit", if light then math.floor(tier.Orbits * L.Orbits) else tier.Orbits, 0)
	-- assinatura do estilo (raio/fita) aparece também no Light (ex.: Killuo na base)
	local bolts = if light then math.ceil(tier.Bolts * L.Bolts) else tier.Bolts
	if styleDef.Bolts ~= "None" then
		add(if styleDef.Bolts == "Lightning" then "Bolt" else "Wisp", bolts, 0)
	end
	if tier.PulseEvery and (not light or L.Pulse) then
		add("Pulse", 1, 0)
	end
	if tier.Ground and (not light or L.Ground) then
		add("Ground", 1, 8 * rateScale)
	end
	return { style = style, tier = tierName, mode = mode, components = components, totalRate = total, glow = tier.Glow, pulseEvery = tier.PulseEvery }
end

return AuraPlanner
