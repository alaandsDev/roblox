--[[
	Auditoria econômica (Lune). Use o orquestrador (paralelo, 1 worker por núcleo):
	    python3 tools/sim/run_economy_analysis.py            -> ECONOMY_BALANCE_ANALYSIS.md
	Modos deste script:
	    lune run tools/sim/analyze_economy.luau worker <shard> <nShards> <saida.json> [escala]
	    lune run tools/sim/analyze_economy.luau report <pasta-dos-json> [escala]
	escala (padrão 1) multiplica o nº de jogadores (0.01 = teste rápido).
	Tudo determinístico: sementes fixas por grupo (mesmas sementes entre variantes = comparação
	com números aleatórios comuns).
]]

local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")
local M = require("./EconomyModel")
local CharacterConfig = require("../../src/shared/Config/CharacterConfig")
local LevelConfig = require("../../src/shared/Config/CharacterLevelConfig")
local EconomyConfig = require("../../src/shared/Config/EconomyConfig")
local VariantConfig = require("../../src/shared/Config/VariantConfig")
local RebirthConfig = require("../../src/shared/Config/RebirthConfig")
local UpgradeConfig = require("../../src/shared/Config/UpgradeConfig")
local PrismConfig = require("../../src/shared/Config/PrismConfig")
local RollConfig = require("../../src/shared/Config/RollConfig")

local DICE = M.DiceOrder
local PROFILES = { "Casual", "Ativo", "Otimizador", "Pago" }
local H = 3600
local CHECK_LONG = { 600, 1800, H, 3 * H, 5 * H, 10 * H, 20 * H }
local CHECK_SHORT = { 300, 600, 1200, 1800, H }
local REFUNDS = { 0, 0.5, 0.6, 0.7, 0.75, 0.8, 1 }
local PRISM_USES = { 1, 2, 3 }
local PRISM_CAPS = { 7, 14, 21 }
local REBIRTH_POLICIES = { "early", "medium", "late", "never" }

------------------------------------------------------------------------------------
-- TAREFAS

local function tasks(scale: number): { any }
	local list = {}
	local function n(base: number): number
		return math.max(4, math.floor(base * scale + 0.5))
	end
	for _, profile in PROFILES do
		for seed = 1, n(10000) do
			table.insert(list, { group = "short", profile = profile, seed = seed, horizon = H, checkpoints = CHECK_SHORT })
		end
		for seed = 1, n(2000) do
			table.insert(list, { group = "long", profile = profile, seed = 100000 + seed, horizon = 20 * H, checkpoints = CHECK_LONG })
		end
	end
	for _, profile in { "Casual", "Ativo", "Otimizador" } do
		for _, r in REFUNDS do
			for seed = 1, n(150) do
				table.insert(list, { group = "refund", variant = tostring(r), profile = profile, seed = 200000 + seed, horizon = 10 * H, checkpoints = { 3 * H, 10 * H }, refund = r })
			end
		end
		for _, policy in REBIRTH_POLICIES do
			for seed = 1, n(150) do
				table.insert(list, { group = "rebirth", variant = policy, profile = profile, seed = 300000 + seed, horizon = 20 * H, checkpoints = { 3 * H, 10 * H, 20 * H }, rebirth = policy })
			end
		end
	end
	for _, profile in { "Casual", "Ativo" } do
		for _, uses in PRISM_USES do
			for _, cap in PRISM_CAPS do
				for seed = 1, n(150) do
					table.insert(list, {
						group = "prism",
						variant = `{uses}x{cap}`,
						profile = profile,
						seed = 400000 + seed,
						horizon = 20 * H,
						checkpoints = { 10 * H, 20 * H },
						prism = { UsesPerReward = uses, MaxCharges = cap, CooldownSeconds = PrismConfig.CooldownSeconds },
					})
				end
			end
		end
	end
	return list
end

local function arrayOf(t: { [number]: number }, size: number): { number }
	local out = {}
	for i = 1, size do
		out[i] = t[i] or -1
	end
	return out
end

local function summarize(task: any, res: any): any
	local p = res.player
	local snaps = {}
	for _, s in res.snapshots do
		table.insert(snaps, {
			t = s.time, money = s.money, earned = s.earned, dice = s.dice, discovered = s.discovered,
			rebirths = s.rebirths, avgLevel = s.avgLevel, ips = s.ips, rolls = s.rolls, prismUsed = s.prismUsed,
			towerFloors = s.towerFloors, patrimony = s.patrimony, earnedBy = s.earnedBy, spentBy = s.spentBy,
		})
	end
	local completion = {}
	for diceId, marks in p.completion do
		completion[diceId] = { marks[50] or -1, marks[75] or -1, marks[90] or -1, marks[100] or -1 }
	end
	local slotsInvested = 0
	for _, slot in p.slots do
		slotsInvested += slot.invested
	end
	return {
		group = task.group, variant = task.variant, profile = task.profile, seed = task.seed,
		snaps = snaps,
		ownedAt = arrayOf(p.ownedAt, #DICE),
		rollUnlockAt = arrayOf(p.rollUnlockAt, #DICE),
		ipsAtPurchase = arrayOf(p.ipsAtPurchase, #DICE),
		completion = completion,
		firsts = p.firsts,
		dupByDice = p.dupIncomeByDice,
		rollsByDice = p.rollsByDice,
		deadRolls = p.deadRolls,
		duplicatesSold = p.duplicatesSold,
		investmentLost = p.investmentLost,
		investmentRefunded = p.investmentRefunded,
		slotsInvested = slotsInvested,
		swaps = p.swaps,
		prismWasted = p.prismWasted,
		prismUsed = p.prismUsed,
		rebirthTimes = p.rebirthTimes,
		pityL = p.pityTriggers.Legendary,
		pityM = p.pityTriggers.Mythic,
		discovered = p.discovered,
		days = res.days,
	}
end

local mode = process.args[1]
local scale = tonumber(process.args[(if mode == "worker" then 5 else 3)] or "1") or 1

if mode == "worker" then
	local shard, nShards, outFile = tonumber(process.args[2]) :: number, tonumber(process.args[3]) :: number, process.args[4]
	local results = {}
	for i, task in tasks(scale) do
		if (i - 1) % nShards == shard then
			local res = M.run(M.Profiles[task.profile], task.horizon, task.seed, {
				refundPercent = task.refund,
				prism = task.prism,
				rebirth = task.rebirth,
				checkpoints = task.checkpoints,
			})
			table.insert(results, summarize(task, res))
		end
	end
	fs.writeFile(outFile, serde.encode("json", results))
	return
end

assert(mode == "report", "uso: worker <shard> <n> <saida> [escala] | report <pasta> [escala]")

------------------------------------------------------------------------------------
-- AGREGAÇÃO

local dir = process.args[2]
local all: { any } = {}
for _, name in fs.readDir(dir) do
	if string.sub(name, -5) == ".json" then
		for _, r in serde.decode("json", fs.readFile(dir .. "/" .. name)) do
			table.insert(all, r)
		end
	end
end
table.sort(all, function(a, b)
	if a.group ~= b.group then
		return a.group < b.group
	end
	if a.profile ~= b.profile then
		return a.profile < b.profile
	end
	if (a.variant or "") ~= (b.variant or "") then
		return (a.variant or "") < (b.variant or "")
	end
	return a.seed < b.seed
end)

local function select(group: string, profile: string?, variant: string?): { any }
	local out = {}
	for _, r in all do
		if r.group == group and (profile == nil or r.profile == profile) and (variant == nil or r.variant == variant) then
			table.insert(out, r)
		end
	end
	return out
end

local function quantile(values: { number }, q: number): number
	if #values == 0 then
		return 0 / 0
	end
	local sorted = table.clone(values)
	table.sort(sorted)
	local pos = (#sorted - 1) * q + 1
	local lo = math.floor(pos)
	local hi = math.min(lo + 1, #sorted)
	return sorted[lo] + (sorted[hi] - sorted[lo]) * (pos - lo)
end

local function collect(list: { any }, fn: (any) -> number?): { number }
	local out = {}
	for _, r in list do
		local v = fn(r)
		if v ~= nil and v == v then
			table.insert(out, v)
		end
	end
	return out
end

local function snapAt(r: any, t: number): any
	for _, s in r.snaps do
		if s.t == t then
			return s
		end
	end
	return nil
end

local function money(x: number): string
	if x ~= x then
		return "—"
	end
	local abs = math.abs(x)
	local units = { { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } }
	for _, u in units do
		if abs >= u[1] then
			return string.format("%.2f%s", x / u[1], u[2])
		end
	end
	return string.format("%d", math.floor(x + 0.5))
end

local function dur(seconds: number): string
	if seconds ~= seconds or seconds < 0 then
		return "—"
	end
	if seconds < 60 then
		return string.format("%ds", math.floor(seconds + 0.5))
	elseif seconds < H then
		return string.format("%.1f min", seconds / 60)
	end
	return string.format("%.1f h", seconds / H)
end

local function pct(x: number): string
	if x ~= x then
		return "—"
	end
	return string.format("%.0f%%", x * 100)
end

local out = {}
local function line(text: string?)
	table.insert(out, text or "")
end
local function row(cells: { any })
	local parts = {}
	for _, c in cells do
		table.insert(parts, tostring(c))
	end
	line("| " .. table.concat(parts, " | ") .. " |")
end
local function header(cells: { string })
	row(cells)
	local sep = {}
	for _ in cells do
		table.insert(sep, "---")
	end
	row(sep)
end

local function p3(values: { number }, fmt: (number) -> string): string
	if #values == 0 then
		return "—"
	end
	return `{fmt(quantile(values, 0.1))} / {fmt(quantile(values, 0.5))} / {fmt(quantile(values, 0.9))}`
end

-- fração de jogadores com valor >= 0 (evento aconteceu)
local function reached(values: { number }, total: number): number
	return if total > 0 then #values / total else 0
end

local function nonNeg(v: number?): number?
	return if v and v >= 0 then v else nil
end

local PT_PROFILE = { Casual = "Casual F2P", Ativo = "Ativo F2P", Otimizador = "Otimizador F2P", Pago = "Pago Moderado" }

-- EXPORT do agregado para o texto (narrativa) abaixo
local A = {
	all = all,
	select = select,
	quantile = quantile,
	collect = collect,
	snapAt = snapAt,
	money = money,
	dur = dur,
	pct = pct,
	p3 = p3,
	reached = reached,
	nonNeg = nonNeg,
	line = line,
	row = row,
	header = header,
	DICE = DICE,
	PROFILES = PROFILES,
	PT_PROFILE = PT_PROFILE,
	REFUNDS = REFUNDS,
	PRISM_USES = PRISM_USES,
	PRISM_CAPS = PRISM_CAPS,
	REBIRTH_POLICIES = REBIRTH_POLICIES,
	CHECK_LONG = CHECK_LONG,
	CHECK_SHORT = CHECK_SHORT,
	M = M,
	CharacterConfig = CharacterConfig,
	LevelConfig = LevelConfig,
	EconomyConfig = EconomyConfig,
	VariantConfig = VariantConfig,
	RebirthConfig = RebirthConfig,
	UpgradeConfig = UpgradeConfig,
	PrismConfig = PrismConfig,
	RollConfig = RollConfig,
	scale = scale,
	counts = {
		short = #select("short", "Ativo"),
		long = #select("long", "Ativo"),
		refund = #select("refund", "Ativo", "0"),
		prism = #select("prism", "Ativo", "3x21"),
		rebirth = #select("rebirth", "Ativo", "medium"),
	},
}

-- convergência: P10/P50/P90 do ganho de 20 h, metade par × metade ímpar das sementes
A.halves = function(): string
	local parts = {}
	for _, profile in PROFILES do
		local halves = { {}, {} }
		for _, r in select("long", profile) do
			local s = snapAt(r, 20 * 3600)
			if s then
				table.insert(halves[(r.seed % 2) + 1], s.earned)
			end
		end
		local worst = 0
		for _, q in { 0.1, 0.5, 0.9 } do
			local a, b = quantile(halves[1], q), quantile(halves[2], q)
			worst = math.max(worst, math.abs(a - b) / ((a + b) / 2))
		end
		table.insert(parts, `{PT_PROFILE[profile]} ≤ {string.format("%.1f", worst * 100)}%`)
	end
	return table.concat(parts, ", ")
end
A.narrative = require("./EconomyNarrative")
require("./EconomyReport")(A)
fs.writeFile("ECONOMY_BALANCE_ANALYSIS.md", table.concat(out, "\n") .. "\n")
print(`ECONOMY_BALANCE_ANALYSIS.md: {#out} linhas, {#all} jogadores simulados`)
