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

local CHECKPOINTS = { 300, 600, 1800, 3600, 7200, 14400 }
local LABELS = { [300] = "5 min", [600] = "10 min", [1800] = "30 min", [3600] = "1 h", [7200] = "2 h", [14400] = "4 h" }
local money = NumberFormatter.money

local out = {}
local function line(text)
	table.insert(out, text)
end

line("<!-- SIM:BEGIN (gerado por tools/sim/simulate_economy.luau — não editar à mão) -->")
line("")
for _, name in { "Casual", "Ativo", "Hardcore" } do
	local profile = EconomySim.Profiles[name]
	local snaps = EconomySim.run(profile, 14400, 42, CHECKPOINTS)
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
			s.avgStationLevel, s.rebirths, s.towerFloors, best and best.Name or "-", best and best.Rarity or "-", s.discovered, money(EconomySim.offline(s.income))))
	end
	line("")
	print(name, "ok")
end

line("### Dinheiro offline x jogo ativo")
line("")
line(string.format("Fórmula: renda/s salva × min(tempo fora, %d h) × %d%%. Com esses valores, **8 h offline ≈ %.2f h**",
	OfflineIncomeConfig.MaxSeconds // 3600, math.floor(OfflineIncomeConfig.Multiplier * 100), OfflineIncomeConfig.MaxSeconds * OfflineIncomeConfig.Multiplier / 3600))
line("de renda passiva jogando ativo no mesmo ponto do jogo (coluna \"8 h offline\" acima).")
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
