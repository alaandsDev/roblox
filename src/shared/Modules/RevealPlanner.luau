--!strict
--[[
	Decide COMO apresentar um resultado de roll (puro, testado fora do Roblox).
	    local planner = RevealPlanner.new(RevealConfig, RarityConfig, CharacterConfig)
	    planner:plan({ rarity, isNew, hide, reducedEffects, cameraShake, autoRoll, timesSeen, mobile })
	    planner:odds(characterId) -> X de "1 EM X" (chance BASE, sem Luck; ver RNG.md)
]]

local RevealPlanner = {}
RevealPlanner.__index = RevealPlanner

export type Input = {
	rarity: string,
	isNew: boolean?,
	hide: boolean?,
	reducedEffects: boolean?,
	cameraShake: boolean?,
	autoRoll: boolean?,
	timesSeen: number?,
	mobile: boolean?,
}

export type Plan = {
	mode: string, -- "Compact" | "Normal" | "Enhanced" | "HeroLanding"
	cinematic: string?,
	compactStyle: string,
	pauseAutoRoll: boolean,
	canSkip: boolean,
	showNew: boolean,
	quality: string,
	shake: number,
	duration: number,
	autoClose: number,
	social: string,
}

function RevealPlanner.new(revealConfig: any, rarityConfig: any, characterConfig: any): any
	local perRarity: { [string]: number } = {}
	for _, character in characterConfig.List do
		perRarity[character.Rarity] = (perRarity[character.Rarity] or 0) + 1
	end
	return setmetatable({ c = revealConfig, rarities = rarityConfig, characters = characterConfig, perRarity = perRarity }, RevealPlanner)
end

function RevealPlanner:quality(reducedEffects: boolean?, mobile: boolean?): string
	if reducedEffects then
		return "Low"
	end
	return if mobile then "Medium" else "High"
end

function RevealPlanner:plan(input: Input): Plan
	local preset = self.c.ByRarity[input.rarity] or self.c.ByRarity.Common
	local tier = self.rarities.ById[input.rarity] and self.rarities.ById[input.rarity].Tier or 1
	local mode = preset.Mode
	if input.hide then
		local force = preset.Mode == "HeroLanding" and input.rarity == "Secret" and self.c.ForceCinematicForSecret
		if not force then
			mode = "Compact"
		end
	end
	local cinematic = if mode == "HeroLanding" then preset.Cinematic else nil
	local cinematicPreset = cinematic and self.c.Cinematics[cinematic]

	local seen = input.timesSeen or 0
	local canSkip = cinematic ~= nil and seen >= self.c.SkipAfterViews
	if canSkip and input.isNew and tier >= self.c.MinTierNoSkipOnFirst then
		canSkip = false
	end

	local shake = 0
	if cinematicPreset and input.cameraShake ~= false then
		shake = cinematicPreset.Shake * (if input.reducedEffects then 0.5 else 1)
	end

	local duration = if cinematicPreset then cinematicPreset.Duration elseif mode == "Compact" then 0 else preset.Duration
	return {
		mode = mode,
		cinematic = cinematic,
		compactStyle = preset.CompactStyle,
		-- Só pausa o AUTO se de fato tocar algo demorado
		pauseAutoRoll = input.autoRoll == true and preset.AutoRoll == "Pause" and mode ~= "Compact",
		canSkip = canSkip,
		showNew = input.isNew == true,
		quality = self:quality(input.reducedEffects, input.mobile),
		shake = shake,
		duration = duration,
		autoClose = if input.autoRoll then self.c.AutoCloseDelayAuto else self.c.AutoCloseDelay,
		social = preset.Social,
	}
end

-- "1 em X" da chance BASE do personagem (raridade / nº de personagens da raridade, Luck 1)
function RevealPlanner:odds(characterId: string): number
	local character = self.characters.ById[characterId]
	if not character then
		return 0
	end
	local total = 0
	for _, rarity in self.rarities.List do
		if self.perRarity[rarity.Id] then
			total += rarity.Weight
		end
	end
	local chance = self.rarities.ById[character.Rarity].Weight / total / self.perRarity[character.Rarity]
	return math.floor(1 / chance + 0.5)
end

-- Odds da raridade inteira (1 em X)
function RevealPlanner:rarityOdds(rarityId: string): number
	local total = 0
	for _, rarity in self.rarities.List do
		total += rarity.Weight
	end
	local rarity = self.rarities.ById[rarityId]
	return if rarity then math.floor(total / rarity.Weight + 0.5) else 0
end

return RevealPlanner
