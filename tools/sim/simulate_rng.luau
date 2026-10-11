--[[
	Simulação do RNG (Lune): lune run tools/sim/simulate_rng.luau
	1.000.000 rolls por cenário com gerador determinístico (xorshift32, semente fixa) e o
	MESMO RollCore do servidor. Escreve RNG_SIMULATION.md na raiz.
]]

local fs = require("@lune/fs")
local RollCore = require("../../src/shared/Modules/RollCore")
local RarityConfig = require("../../src/shared/Config/RarityConfig")
local CharacterConfig = require("../../src/shared/Config/CharacterConfig")
local RollConfig = require("../../src/shared/Config/RollConfig")
local DiceConfig = require("../../src/shared/Config/DiceConfig")
local UpgradeConfig = require("../../src/shared/Config/UpgradeConfig")
local Rng = require("../../tests/Rng")

local core = RollCore.new(RarityConfig, CharacterConfig, RollConfig)
local N = 1000000

local maxLuck = DiceConfig.ById.Celestial.LuckMultiplier * (1 + UpgradeConfig.ById.Luck.MaxLevel * UpgradeConfig.ById.Luck.PerLevel)

local scenarios = {
	{ name = "Sem Luck (dado Normal, Luck 1.00)", luck = 1, pity = false },
	{ name = "Luck média (dado Storm, Luck 2.00)", luck = 2, pity = false },
	{ name = string.format("Luck alta (Celestial + Luck nível máx, Luck %.2f)", maxLuck), luck = maxLuck, pity = false },
	{ name = "Luck 1.00 COM pity (Lendário 50 / Mítico 250)", luck = 1, pity = true },
}

local out = {}
local function line(text)
	table.insert(out, text)
end

line("# RNG_SIMULATION — Roll Legends")
line("")
line("Gerado por `tools/sim/simulate_rng.luau` (Lune) com o **mesmo `RollCore` do servidor**,")
line(string.format("gerador determinístico xorshift32 (semente fixa), **%s rolls por cenário**.", "1.000.000"))
line("Teórico = `RollCore:chances(luck)` (fórmula em RNG.md). Desvio = observado − teórico (pontos percentuais).")
line("")

for index, scenario in scenarios do
	local rand = Rng.new(1000 + index * 7919)
	local counts = {}
	local pity = {}
	local streak, worstLegendary, triggered = 0, 0, 0
	for _ = 1, N do
		local rarity
		if scenario.pity then
			local result = core:roll(scenario.luck, pity, rand)
			pity = result.pity
			rarity = result.rarity
			if result.pityTriggered then
				triggered += 1
			end
		else
			rarity = core:pickRarity(scenario.luck, rand)
		end
		counts[rarity] = (counts[rarity] or 0) + 1
		if core:tierOf(rarity) >= core:tierOf("Legendary") then
			streak = 0
		else
			streak += 1
			worstLegendary = math.max(worstLegendary, streak)
		end
	end
	local chances = core:chances(scenario.luck)
	line("## " .. scenario.name)
	line("")
	line("| Raridade | Teórico % | Observado % | Desvio (p.p.) | Ocorrências | 1 em |")
	line("|---|---:|---:|---:|---:|---:|")
	for _, rarity in RarityConfig.List do
		local theoretical = chances[rarity.Id] * 100
		local observed = (counts[rarity.Id] or 0) / N * 100
		local oneIn = if (counts[rarity.Id] or 0) > 0 then math.floor(N / counts[rarity.Id] + 0.5) else 0
		line(string.format("| %s | %.4f | %.4f | %+.4f | %d | %d |", rarity.Id, theoretical, observed, observed - theoretical, counts[rarity.Id] or 0, oneIn))
	end
	line("")
	line(string.format("Maior sequência sem Lendário+: **%d** rolls.%s", worstLegendary,
		if scenario.pity then string.format(" Pity disparou **%d** vezes.", triggered) else ""))
	if scenario.pity then
		line("Com pity o teórico acima é o SEM pity; a diferença nas raridades Lendário/Mítico é o efeito esperado do pity.")
	end
	line("")
	print(scenario.name, "ok")
end

fs.writeFile("RNG_SIMULATION.md", table.concat(out, "\n"))
print("RNG_SIMULATION.md escrito")
