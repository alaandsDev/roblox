--[[
	Auditoria 200 h: Player Auras (proposta R, Absoluta candidata 10T) + LifetimeMoneyGenerated
	(Ranking Magnata). HIPÓTESE — nada disso existe no jogo.
	    lune run tools/sim/analyze_magnate.luau <cenário> <perfil> <semente0> <n> <horas> <saida.json>
	Cenários:
	    base   jogo atual (ninguém compra aura; registra quando o saldo PODERIA pagar)
	    R10    proposta: 1B/25B/250B/2,5T/10T × 1,5/1,75/2/2,25/2,5 (saveRatio do perfil)
	    R5 R7 R20 sensibilidade do preço da Absoluta (5T / 7,5T / 20T)
	    A      compra assim que consegue (adia o Rebirth até 5× o custo dele para juntar)
	    B      prioriza Rebirth (nunca adia o Rebirth; só compra o que couber no ciclo)
	    C      acumula (Rebirth "late": só renasce com 4× o custo em caixa; compra aura se couber)
	    D      otimizada (aura × Rebirth: o que der mais renda extra por $)
	Lifetime = soma das fontes GENERATED do protótipo MoneyLedger (coletor, offline, torre,
	missões, diário); venda, reembolso, Jackpot e Robux não contam.
	Python junta: tools/sim/run_magnate_audit.py
]]
local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")

local EconomyModel = require("./EconomyModel")

local B, T = 1e9, 1e12
local function tiers(absoluta: number)
	return {
		{ name = "Aura Desperta", price = 1 * B, money = 1.5, walk = 28 },
		{ name = "Aura Imperial", price = 25 * B, money = 1.75, walk = 30 },
		{ name = "Aura Divina", price = 250 * B, money = 2, walk = 32 },
		{ name = "Aura Celestial", price = 2.5 * T, money = 2.25, walk = 34 },
		{ name = "Aura Absoluta", price = absoluta, money = 2.5, walk = 36 },
	}
end
local SAVE_RATIO = { Casual = 1, Ativo = 2, Otimizador = 3, Pago = 2 }

local scenario = process.args[1]
local profileName = process.args[2]
local seed0 = tonumber(process.args[3]) or 1
local n = tonumber(process.args[4]) or 10
local hours = tonumber(process.args[5]) or 200
local out = process.args[6]
local profile = EconomyModel.Profiles[profileName] or error("perfil desconhecido " .. tostring(profileName))

local auraOpts: any
local rebirthPolicy: string? = nil
if scenario == "base" then
	auraOpts = { tiers = tiers(10 * T), saveRatio = 0, buy = false }
elseif scenario == "R10" then
	auraOpts = { tiers = tiers(10 * T), saveRatio = SAVE_RATIO[profileName], buy = true }
elseif scenario == "R5" then
	auraOpts = { tiers = tiers(5 * T), saveRatio = SAVE_RATIO[profileName], buy = true }
elseif scenario == "R7" then
	auraOpts = { tiers = tiers(7.5 * T), saveRatio = SAVE_RATIO[profileName], buy = true }
elseif scenario == "R20" then
	auraOpts = { tiers = tiers(20 * T), saveRatio = SAVE_RATIO[profileName], buy = true }
elseif scenario == "A" then
	auraOpts = { tiers = tiers(10 * T), saveRatio = 5, buy = true }
elseif scenario == "B" then
	auraOpts = { tiers = tiers(10 * T), saveRatio = 0, buy = true }
elseif scenario == "C" then
	auraOpts = { tiers = tiers(10 * T), saveRatio = 0, buy = true }
	rebirthPolicy = "late"
elseif scenario == "D" then
	auraOpts = { tiers = tiers(10 * T), saveRatio = 0, buy = true, strategy = "efficiency" }
else
	error("cenário desconhecido " .. tostring(scenario))
end

local checkpoints = {}
for _, h in { 10, 20, 40, 80, 120, 200 } do
	if h <= hours then
		table.insert(checkpoints, h * 3600)
	end
end

local runs = {}
for i = 0, n - 1 do
	local seed = seed0 + i
	local r = EconomyModel.run(profile, hours * 3600, 9000 + seed, { checkpoints = checkpoints, playerAuras = auraOpts, rebirth = rebirthPolicy })
	local p = r.player
	local snaps = {}
	for _, s in r.snapshots do
		local earned = 0
		for _, v in s.earnedBy do
			earned += v
		end
		table.insert(snaps, {
			time = s.time,
			ips = s.ips,
			rebirths = s.rebirths,
			earned = earned,
			lifetime = s.lifetime,
			money = s.money,
			auraSpent = s.spentBy.PlayerAura or 0,
		})
	end
	table.insert(runs, {
		seed = seed,
		affordable = p.auraAffordableAt,
		bought = p.auraBoughtAt,
		buyState = p.auraBuyState,
		rebirthTimes = p.rebirthTimes,
		snaps = snaps,
		lifetime = p.lifetime,
	})
end
fs.writeFile(out, serde.encode("json", { scenario = scenario, profile = profileName, tiers = auraOpts.tiers, runs = runs }, false))
