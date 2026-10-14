--[[
	Auditoria econômica das PLAYER AURAS (HIPÓTESE — nada disso existe no jogo).
	    lune run tools/sim/analyze_player_auras.luau <cenário> <perfil> <semente0> <n> <horas> <saida.json>
	Cenários (tabelas de preço/multiplicador): ver SCENARIOS abaixo. "baseH"/"baseR" = jogo atual
	(ninguém compra; só registra quando o saldo PODERIA pagar cada aura de H/R).
	Usa o simulador oficial (EconomyModel) com a opção playerAuras: a aura multiplica a renda das
	estações (e o que deriva dela: offline com o mesmo teto, prêmios em "segundos de renda");
	venda, reembolsos, Dice, Rebirth, fusão e trocas NÃO são multiplicados.
	Python junta: tools/sim/run_player_aura_audit.py -> PLAYER_AURA_ECONOMY_AUDIT.md
]]
local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")

local EconomyModel = require("./EconomyModel")

local K, M, B, T = 1e3, 1e6, 1e9, 1e12
local SCENARIOS = {
	-- hipótese do pedido (preço, Speed nominal, Money)
	H = {
		{ name = "Aura Desperta", price = 100 * M, money = 2 },
		{ name = "Aura Imperial", price = 5 * B, money = 2.5 },
		{ name = "Aura Divina", price = 100 * B, money = 3 },
		{ name = "Aura Celestial", price = 5 * T, money = 3.5 },
		{ name = "Aura Absoluta", price = 250 * T, money = 4 },
	},
	-- recomendação: 1ª aura só DEPOIS do Forbidden (400M: não compete com a trilha de Dice),
	-- preços ancorados no custo do Rebirth do momento (1B ≈ RB7 · 25B ≈ RB11 · 250B ≈ RB14 ·
	-- 2,5T ≈ RB17 · 25T ≈ RB19) — a economia atual achata depois de ~15 Rebirths, então os
	-- degraus finais ficam ×10 (não ×20–50) — e Money CÔNCAVO (+50% → ×2,5)
	R = {
		{ name = "Aura Desperta", price = 1 * B, money = 1.5 },
		{ name = "Aura Imperial", price = 25 * B, money = 1.75 },
		{ name = "Aura Divina", price = 250 * B, money = 2 },
		{ name = "Aura Celestial", price = 2.5 * T, money = 2.25 },
		{ name = "Aura Absoluta", price = 25 * T, money = 2.5 },
	},
}
-- linhas de base: jogo atual (ninguém compra), só registra quando o saldo PODERIA pagar
SCENARIOS.baseH = SCENARIOS.H
SCENARIOS.baseR = SCENARIOS.R
local _ = K

-- quanto cada perfil aceita adiar o Rebirth para juntar a próxima aura (preço <= ratio × Rebirth)
local SAVE_RATIO = { Casual = 1, Ativo = 2, Otimizador = 3, Pago = 2 }

local scenario = process.args[1]
local profileName = process.args[2]
local seed0 = tonumber(process.args[3]) or 1
local n = tonumber(process.args[4]) or 10
local hours = tonumber(process.args[5]) or 40
local out = process.args[6]
local tiers = SCENARIOS[scenario] or error("cenário desconhecido " .. tostring(scenario))
local profile = EconomyModel.Profiles[profileName] or error("perfil desconhecido " .. tostring(profileName))
local checkpoints = { 10 * 3600, 20 * 3600, 40 * 3600 }
if hours > 40 then
	table.insert(checkpoints, hours * 3600)
end

local runs = {}
for i = 0, n - 1 do
	local seed = seed0 + i
	local r = EconomyModel.run(profile, hours * 3600, 7000 + seed, {
		checkpoints = checkpoints,
		playerAuras = { tiers = tiers, saveRatio = SAVE_RATIO[profileName], buy = string.sub(scenario, 1, 4) ~= "base" },
	})
	local p = r.player
	local snaps = {}
	for _, s in r.snapshots do
		table.insert(snaps, { time = s.time, ips = s.ips, rebirths = s.rebirths, earned = s.earned, money = s.money, dice = s.dice, auraSpent = s.spentBy.PlayerAura or 0 })
	end
	table.insert(runs, {
		seed = seed,
		affordable = p.auraAffordableAt,
		bought = p.auraBoughtAt,
		buyState = p.auraBuyState,
		rebirthTimes = p.rebirthTimes,
		diceAt = p.ownedAt,
		snaps = snaps,
	})
end
fs.writeFile(out, serde.encode("json", { scenario = scenario, profile = profileName, tiers = tiers, saveRatio = SAVE_RATIO[profileName], runs = runs }, false))
