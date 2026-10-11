--[[
	Simulação de economia (Lune): lune run tools/sim/simulate_economy.luau
	Perfis Casual / Ativo / Hardcore em 5 min, 10 min, 30 min, 1 h e 2 h, com as configs reais.
	Escreve a seção gerada de ECONOMY.md (entre os marcadores SIM:BEGIN / SIM:END).
]]

local fs = require("@lune/fs")
local EconomySim = require("./EconomySim")
local NumberFormatter = require("../../src/shared/Modules/NumberFormatter")
local CharacterConfig = require("../../src/shared/Config/CharacterConfig")
local DailyConfig = require("../../src/shared/Config/DailyConfig")
local OfflineIncomeConfig = require("../../src/shared/Config/OfflineIncomeConfig")

local CHECKPOINTS = { 300, 600, 1800, 3600, 7200, 14400, 28800 }
local LABELS = { [300] = "5 min", [600] = "10 min", [1800] = "30 min", [3600] = "1 h", [7200] = "2 h", [14400] = "4 h", [28800] = "8 h" }
local LevelConfig = require("../../src/shared/Config/CharacterLevelConfig")
local TowerConfig = require("../../src/shared/Config/TowerConfig")
local RarityConfig = require("../../src/shared/Config/RarityConfig")
local BattleCore = require("../../src/shared/Modules/BattleCore")
local money = NumberFormatter.money

local out = {}
local function line(text)
	table.insert(out, text)
end

line("<!-- SIM:BEGIN (gerado por tools/sim/simulate_economy.luau — não editar à mão) -->")
line("")
for _, name in { "Casual", "Ativo", "Hardcore" } do
	local profile = EconomySim.Profiles[name]
	local snaps = EconomySim.run(profile, 28800, 42, CHECKPOINTS)
	line(string.format("### %s", name))
	line("")
	line(string.format("Roll %s, coleta a cada %d s, decide a cada %d s, gasta %d%% em níveis de estação, renasce com %.1fx o custo, sobe torres a cada minuto.",
		if profile.manualInterval then string.format("manual a cada %.1f s", profile.manualInterval) else "AUTO (cooldown)",
		profile.collectEvery, profile.thinkEvery, math.floor(profile.levelSpend * 100), profile.rebirthMargin or 0))
	line("")
	line("| Tempo | Rolls | Dado | Luck | Renda/s | Ganho total | Saldo | Upg L/I/S/C | Nível médio estação | Renasc. | Andares (torres) | Melhor | Index | 8 h offline |")
	line("|---|---:|---|---:|---:|---:|---:|---|---:|---:|---:|---|---:|---:|")
	for _, s in snaps do
		local best = CharacterConfig.ById[s.best]
		line(string.format("| %s | %d | %s | %.2f | %s | %s | %s | %d/%d/%d/%d | %.1f | %d | %d/120 | %s (%s) | %d/24 | %s |",
			LABELS[s.time], s.rolls, s.dice, s.luck, money(s.income), money(s.earned), money(s.money),
			s.upgrades.Luck, s.upgrades.Income, s.upgrades.RollSpeed, s.upgrades.Inventory,
			s.avgStationLevel, s.rebirths, s.towerFloors, best and best.Name or "-", best and best.Rarity or "-", s.discovered, money(EconomySim.offline(s.income, nil, s.nextRebirthCost))))
	end
	line("")
	local last = snaps[#snaps]
	local times = {}
	for _, t in last.rebirthTimes do
		table.insert(times, string.format("%d min", t // 60))
	end
	line(string.format("Renascimentos em: %s. Próximo custa %s.", if #times > 0 then table.concat(times, ", ") else "nenhum em 8 h", money(last.nextRebirthCost)))
	line("")
	print(name, "ok")
end

-- Nível de personagem 1 -> 50 (em unidades de BaseIncome; payback sem multiplicadores globais)
line("### Nível de personagem (1 → 50)")
line("")
line(string.format("Custo L→L+1 = BaseIncome × %d s × %.2f^(L−1); ganho por nível = +%d%% da renda base da unidade.",
	LevelConfig.BaseCostSeconds, LevelConfig.CostGrowth, math.floor(LevelConfig.IncomePerLevel * 100)))
line("Payback = custo do nível ÷ renda que ele adiciona (multiplicadores globais encurtam o payback na mesma proporção).")
line("")
line("| Nível | Custo do próximo (× BaseIncome) | Custo acumulado desde 1 | Renda da unidade | Payback do próximo nível |")
line("|---:|---:|---:|---:|---:|")
do
	local acc = 0
	for lvl = 1, LevelConfig.MaxLevel - 1 do
		local cost = LevelConfig.BaseCostSeconds * LevelConfig.CostGrowth ^ (lvl - 1)
		if lvl == 1 or lvl % 5 == 0 or lvl == LevelConfig.MaxLevel - 1 then
			local payback = cost / LevelConfig.IncomePerLevel
			local paybackText = if payback < 3600 then string.format("%d min", payback // 60) elseif payback < 86400 then string.format("%.1f h", payback / 3600) else string.format("%.1f dias", payback / 86400)
			line(string.format("| %d | %s | %s | %.2fx | %s |", lvl, NumberFormatter.abbreviate(cost), NumberFormatter.abbreviate(acc), 1 + (lvl - 1) * LevelConfig.IncomePerLevel, paybackText))
		end
		acc += cost
	end
	line("")
	line(string.format("Total 1→50 ≈ %s × BaseIncome para %.2fx de renda: os primeiros ~15 níveis se pagam em minutos/poucas horas; depois disso subir de raridade (roll/fusão) rende mais — a decisão \"melhorar ou rolar\" é real.", NumberFormatter.abbreviate(acc), 1 + (LevelConfig.MaxLevel - 1) * LevelConfig.IncomePerLevel))
	line("")
end

-- Curva das torres
line("### Curva das torres")
line("")
line(string.format("Poder dos inimigos = BasePower × Growth^(andar−1); chefe a cada %d andares (%gx em 1 inimigo). Recompensa só na 1ª vitória de cada andar (sem farm): max(poder × %g, renda/s × %d s).",
	TowerConfig.BossEvery, TowerConfig.BossMultiplier, TowerConfig.MoneyPerPower, TowerConfig.IncomeSeconds))
line("")
line("| Torre | Andar 1 | Andar 10 | Andar 20 | Último | Soma do dinheiro (piso) |")
line("|---|---:|---:|---:|---:|---:|")
do
	local battle = BattleCore.new(TowerConfig, CharacterConfig, RarityConfig)
	for _, tower in TowerConfig.List do
		local total = 0
		for f = 1, tower.Floors do
			total += battle:enemyPower(tower, f) * TowerConfig.MoneyPerPower
		end
		line(string.format("| %s | %s | %s | %s | %s (%d) | %s |", tower.Id,
			NumberFormatter.abbreviate(battle:enemyPower(tower, 1)), NumberFormatter.abbreviate(battle:enemyPower(tower, 10)),
			NumberFormatter.abbreviate(battle:enemyPower(tower, 20)), NumberFormatter.abbreviate(battle:enemyPower(tower, tower.Floors)), tower.Floors,
			money(total)))
	end
	line("")
	line("A soma de TODOS os andares de uma torre fica abaixo de 1 custo de renascimento da fase em que ela é jogada — torre é bônus, não substitui a renda da base.")
	line("")
end

line("### Dinheiro offline x jogo ativo")
line("")
line(string.format("Fórmula: renda/s salva × min(tempo fora, %d h) × %d%%. Com esses valores, **8 h offline ≈ %.2f h**",
	OfflineIncomeConfig.MaxSeconds // 3600, math.floor(OfflineIncomeConfig.Multiplier * 100), OfflineIncomeConfig.MaxSeconds * OfflineIncomeConfig.Multiplier / 3600))
line("de renda passiva jogando ativo no mesmo ponto do jogo (coluna \"8 h offline\" acima),\n" .. string.format("limitado a %d%% do custo do próximo renascimento (não dá para comprar renascimentos dormindo).", math.floor((OfflineIncomeConfig.MaxRebirthFraction or 1) * 100)))
line("")
line("### Recompensas diárias (valor por dia)")
line("")
line("| Dia | Recompensa |")
line("|---|---|")
for _, r in DailyConfig.Rewards do
	local text
	if r.Kind == "Money" then
		text = string.format("Dinheiro: max(%s, renda/s × %d s)", money(r.Amount), r.IncomeSeconds or 0)
	elseif r.Kind == "Gems" then
		text = string.format("%d gemas", r.Amount)
	elseif r.Kind == "LuckBoost" then
		text = string.format("Boost de Luck %gx por %d min", r.Multiplier, r.Duration // 60)
	else
		text = string.format("Dado exclusivo %s (se já tiver: %d gemas)", r.DiceId, r.Fallback.Amount)
	end
	line(string.format("| %d | %s |", r.Day, text))
end
line("")
line("<!-- SIM:END -->")

local generated = table.concat(out, "\n")
local path = "ECONOMY.md"
local existing = if fs.isFile(path) then fs.readFile(path) else ""
local before, after = string.match(existing, "^(.-)<!%-%- SIM:BEGIN.-SIM:END %-%->(.*)$")
if before then
	fs.writeFile(path, before .. generated .. after)
else
	fs.writeFile(path, existing .. "\n" .. generated .. "\n")
end
print("ECONOMY.md atualizado")
