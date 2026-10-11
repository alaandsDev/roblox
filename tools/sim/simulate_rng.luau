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
local Odds = require("./Odds")

local core = RollCore.new(RarityConfig, CharacterConfig, RollConfig)
local N = 1000000

local maxLuck = Odds.evaluate(Odds.Scenarios[7].data).luck

local scenarios = {
	{ name = "Sem Luck (dado Normal, Luck 1.00)", luck = 1, pity = false },
	{ name = "Luck média (dado Storm, Luck 2.00)", luck = 2, pity = false },
	{ name = string.format("Luck máxima com monetização (Luck %.2f, efetiva %.2f)", maxLuck, core:effectiveLuck(maxLuck)), luck = maxLuck, pity = false },
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
line("## Odds REAIS por cenário (todos os multiplicadores + velocidade do AUTO)")
line("")
line("Luck = dado × melhoria de Luck × renascimento (com teto) × perk × boost × gamepasses. Luck efetiva = com retornos")
line("decrescentes (LuckSoftCap). \"1 em X\" = essa raridade OU MELHOR (com pity no Lendário/Mítico). Tempo = média no AUTO.")
line("")
line("| Cenário | Luck | Luck efetiva | Rolls/min | Lendário+ | Mítico+ | Divino+ | Secreto | Secreto/hora |")
line("|---|---:|---:|---:|---|---|---|---|---:|")
local function fmtTime(minutes: number): string
	if minutes < 60 then
		return string.format("%.1f min", minutes)
	elseif minutes < 60 * 48 then
		return string.format("%.1f h", minutes / 60)
	end
	return string.format("%.1f dias", minutes / 1440)
end
for _, scenario in Odds.Scenarios do
	local r = Odds.evaluate(scenario.data)
	local cells = {}
	for _, id in { "Legendary", "Mythic", "Divine", "Secret" } do
		table.insert(cells, string.format("1 em %s (%s)", string.format("%.0f", r.rarity[id].oneIn), fmtTime(r.rarity[id].minutes)))
	end
	line(string.format("| %s) %s | %.2f | %.2f | %.0f | %s | %.2f |", scenario.id, scenario.name, r.luck, r.effectiveLuck, r.perMinute, table.concat(cells, " | "), r.rarity.Secret.perHour))
end
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
