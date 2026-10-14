--[[
	Texto + tabelas de ECONOMY_BALANCE_ANALYSIS.md (chamado por analyze_economy.luau report).
	Recebe o agregado `A` (resultados por jogador + utilitários). Não simula nada.
]]

return function(A: any)
	local line, row, header = A.line, A.row, A.header
	local select, quantile, collect, snapAt = A.select, A.quantile, A.collect, A.snapAt
	local money, dur, pct, p3 = A.money, A.dur, A.pct, A.p3
	local DICE, PT_PROFILE = A.DICE, A.PT_PROFILE
	local M = A.M
	local H = 3600

	local function median(values: { number }): number
		return quantile(values, 0.5)
	end

	-- Dados por Dice (perfil, grupo long)
	local function diceStats(profile: string): { any }
		local list = select("long", profile)
		local stats = {}
		for i, dice in DICE do
			local owned = collect(list, function(r)
				return A.nonNeg(r.ownedAt[i])
			end)
			local unlock = collect(list, function(r)
				return A.nonNeg(r.rollUnlockAt[i])
			end)
			-- espera por dinheiro depois de liberar por rolls
			local moneyWait = collect(list, function(r)
				if r.ownedAt[i] >= 0 and r.rollUnlockAt[i] >= 0 then
					return math.max(0, r.ownedAt[i] - r.rollUnlockAt[i])
				end
				return nil
			end)
			-- maior marco de completion antes de comprar o próximo (ou até o fim)
			local marks = { 50, 75, 90, 100 }
			local before = { [0] = 0, [50] = 0, [75] = 0, [90] = 0, [100] = 0 }
			local ownedCount = 0
			local toMark = { {}, {}, {}, {} }
			local dead = {}
			for _, r in list do
				if r.ownedAt[i] >= 0 then
					ownedCount += 1
					local limit = if DICE[i + 1] and r.ownedAt[i + 1] >= 0 then r.ownedAt[i + 1] else math.huge
					local comp = r.completion[dice.Id]
					local best = 0
					for k, mark in marks do
						local t = comp and comp[k] or -1
						if t >= 0 then
							table.insert(toMark[k], t - r.ownedAt[i])
							if t <= limit then
								best = mark
							end
						end
					end
					before[best] += 1
					table.insert(dead, r.deadRolls[dice.Id] or 0)
				end
			end
			stats[i] = {
				dice = dice,
				owned = owned,
				unlock = unlock,
				moneyWait = moneyWait,
				ownedShare = #owned / math.max(1, #list),
				before = before,
				ownedCount = ownedCount,
				toMark = toMark,
				dead = dead,
				ipsAtPurchase = collect(list, function(r)
					return if r.ownedAt[i] >= 0 then r.ipsAtPurchase[i] else nil
				end),
			}
		end
		return stats
	end

	local STATS = {}
	for _, profile in A.PROFILES do
		STATS[profile] = diceStats(profile)
	end

	-- participação agregada por fonte de dinheiro num checkpoint
	local function sourceShares(profile: string, t: number): ({ [string]: number }, number)
		local by, total = {}, 0
		for _, r in select("long", profile) do
			local s = snapAt(r, t)
			if s then
				for k, v in s.earnedBy do
					by[k] = (by[k] or 0) + v
					total += v
				end
			end
		end
		for k, v in by do
			by[k] = v / math.max(1, total)
		end
		return by, total
	end

	A.STATS = STATS
	A.sourceShares = sourceShares
	A.median = median

	------------------------------------------------------------------------------------
	line("# ROLL LEGENDS — Auditoria e balanceamento da economia")
	line()
	line("> Gerado por `python3 tools/sim/run_economy_analysis.py` (simulador `tools/sim/EconomyModel.luau`).")
	line("> **Somente análise e proposta. Nada desta proposta foi aplicado ao jogo.** Os números do jogo")
	line("> (preços, custos, renda, venda, Rebirth, Prisma) são os de produção do commit 07744e5.")
	line()
	line(`Amostra: {A.counts.short} jogadores/perfil até 1 h · {A.counts.long} jogadores/perfil até 20 h · {A.counts.refund} por variante de refund · {A.counts.prism} por variante de Prisma · {A.counts.rebirth} por política de Rebirth.`)
	line()

	A.section = function(title: string)
		line()
		line("## " .. title)
		line()
	end

	local section = A.section
	local NARR = A.narrative or {}
	local function say(key: string)
		local text = NARR[key]
		if text then
			for _, l in string.split(text(A), "\n") do
				line(l)
			end
			line()
		end
	end

	say("summary")

	------------------------------------------------------------------------------------
	section("1. Tabela principal por perfil (P50; entre colchetes P10–P90)")
	say("profiles")
	local LABEL = { [600] = "10 min", [1800] = "30 min", [H] = "1 h", [3 * H] = "3 h", [5 * H] = "5 h", [10 * H] = "10 h", [20 * H] = "20 h" }
	for _, profile in A.PROFILES do
		local list = select("long", profile)
		line(`### {PT_PROFILE[profile]}`)
		line()
		header({ "Tempo ativo", "Dice", "Money (saldo)", "Ganho total", "Renda/s", "Index (/" .. A.CharacterConfig.Count .. ")", "Rebirth", "Upgrade médio (nível)" })
		for _, t in A.CHECK_LONG do
			local function v(fn: (any) -> number): { number }
				return collect(list, function(r)
					local s = snapAt(r, t)
					return if s then fn(s) else nil
				end)
			end
			local dice = v(function(s)
				return s.dice
			end)
			local d50 = math.floor(median(dice) + 0.5)
			row({
				LABEL[t],
				`{DICE[d50].Id} ({d50}) [{math.floor(quantile(dice, 0.1) + 0.5)}–{math.floor(quantile(dice, 0.9) + 0.5)}]`,
				money(median(v(function(s) return s.money end))),
				p3(v(function(s) return s.earned end), money),
				money(median(v(function(s) return s.ips end))),
				p3(v(function(s) return s.discovered end), function(x) return string.format("%d", math.floor(x + 0.5)) end),
				p3(v(function(s) return s.rebirths end), function(x) return string.format("%d", math.floor(x + 0.5)) end),
				string.format("%.1f", median(v(function(s) return s.avgLevel end))),
			})
		end
		line()
	end

	------------------------------------------------------------------------------------
	section("2. Tempo para comprar cada Dice (tempo ATIVO; P10 / P50 / P90)")
	say("dice")
	for _, profile in A.PROFILES do
		line(`### {PT_PROFILE[profile]}`)
		line()
		header({ "Dice", "Unlock (rolls)", "Price", "P10", "P50", "P90", "Comprou em 20 h", "Liberado por rolls (P50)", "Espera por dinheiro (P50)", "Completion antes do próximo?" })
		for i, st in STATS[profile] do
			local dice = st.dice
			local b = st.before
			local n = math.max(1, st.ownedCount)
			local completion = if i == #DICE
				then "último Dice"
				else string.format("100%%: %s · ≥90%%: %s · <50%%: %s", pct(b[100] / n), pct((b[90] + b[100]) / n), pct(b[0] / n))
			row({
				dice.Id,
				tostring(dice.UnlockRequirement.Rolls or 0),
				money(dice.Price),
				if i == 1 then "0" else dur(quantile(st.owned, 0.1)),
				if i == 1 then "0" else dur(quantile(st.owned, 0.5)),
				if i == 1 then "0" else dur(quantile(st.owned, 0.9)),
				pct(st.ownedShare),
				if i == 1 then "—" else dur(median(st.unlock)),
				if i == 1 then "—" else dur(median(st.moneyWait)),
				completion,
			})
		end
		line()
	end

	------------------------------------------------------------------------------------
	section("3. Completion de cada Dice × próximo desbloqueio (Ativo F2P)")
	say("completion")
	header({ "Dice", "50%", "75%", "90%", "100%", "Próximo liberado por rolls", "Próximo comprado", "Rolls sem nada novo (P50)", "Completou 100% (20 h)" })
	for i, st in STATS.Ativo do
		local nextSt = STATS.Ativo[i + 1]
		local nextUnlock, nextOwned = "—", "—"
		if nextSt then
			local list = select("long", "Ativo")
			nextUnlock = dur(median(collect(list, function(r)
				return if r.ownedAt[i] >= 0 and r.rollUnlockAt[i + 1] >= 0 then math.max(0, r.rollUnlockAt[i + 1] - r.ownedAt[i]) else nil
			end)))
			nextOwned = dur(median(collect(list, function(r)
				return if r.ownedAt[i] >= 0 and r.ownedAt[i + 1] >= 0 then r.ownedAt[i + 1] - r.ownedAt[i] else nil
			end)))
		end
		row({
			st.dice.Id,
			dur(median(st.toMark[1])),
			dur(median(st.toMark[2])),
			dur(median(st.toMark[3])),
			dur(median(st.toMark[4])),
			nextUnlock,
			nextOwned,
			string.format("%d", math.floor(median(st.dead) + 0.5)),
			pct(#st.toMark[4] / math.max(1, st.ownedCount)),
		})
	end
	line()
	line("Tempos de completion contados a partir da compra do Dice (P50 de quem chegou ao marco).")
	line()

	------------------------------------------------------------------------------------
	section("4. Fontes de dinheiro")
	say("sources")
	header({ "Perfil", "Tempo", "Coletor", "Offline", "Venda duplicatas", "Venda c/ nível", "Torres", "Missões", "Diário", "Jackpot" })
	for _, profile in A.PROFILES do
		for _, t in { H, 5 * H, 20 * H } do
			local by = sourceShares(profile, t)
			row({
				PT_PROFILE[profile],
				dur(t),
				pct(by.Collector or 0),
				pct(by.Offline or 0),
				pct(by.Sell or 0),
				pct(by.SellUpgraded or 0),
				pct(by.Tower or 0),
				pct(by.Mission or 0),
				pct(by.Daily or 0),
				pct(by.Jackpot or 0),
			})
		end
	end
	line()

	section("5. Sinks (para onde o dinheiro vai)")
	say("sinks")
	header({ "Perfil", "Tempo", "Dice", "Níveis de estação", "Upgrade Luck", "Upgrade Renda", "Upgrade Inventário", "Fusão", "Rebirth (saldo zerado)" })
	for _, profile in A.PROFILES do
		for _, t in { H, 5 * H, 20 * H } do
			local by, total = {}, 0
			for _, r in select("long", profile) do
				local s = snapAt(r, t)
				if s then
					for k, v in s.spentBy do
						by[k] = (by[k] or 0) + v
						total += v
					end
				end
			end
			local function share(k: string): string
				return pct((by[k] or 0) / math.max(1, total))
			end
			row({ PT_PROFILE[profile], dur(t), share("Dice"), share("StationLevels"), share("UpgradeLuck"), share("UpgradeIncome"), share("UpgradeInventory"), share("Fusion"), share("Rebirth") })
		end
	end
	line()

	------------------------------------------------------------------------------------
	section("6. Curva de upgrade de personagem (estação)")
	say("curve")
	header({ "Nível", "Custo L→L+1 (× BaseIncome)", "Acumulado até L (× BaseIncome)", "Renda no nível (× BaseIncome)", "Payback do nível (Normal)", "Venda base Comum/Mítico (× BaseIncome)" })
	local probe = { Id = "__probe", BaseIncome = 1 }
	local _ = probe
	local Lv = A.LevelConfig
	local function costUnit(level: number): number
		return Lv.BaseCostSeconds * Lv.CostGrowth ^ (level - 1)
	end
	local function accUnit(level: number): number
		local total = 0
		for k = 1, level - 1 do
			total += costUnit(k)
		end
		return total
	end
	for _, level in { 1, 2, 5, 10, 15, 20, 25, 30, 40, Lv.MaxLevel } do
		row({
			tostring(level),
			if level < Lv.MaxLevel then money(costUnit(level)) else "máx",
			money(accUnit(level)),
			string.format("%.2f", 1 + (level - 1) * Lv.IncomePerLevel),
			if level < Lv.MaxLevel then dur(costUnit(level) / Lv.IncomePerLevel) else "—",
			`{A.EconomyConfig.SellSeconds.Common} / {A.EconomyConfig.SellSeconds.Mythic}`,
		})
	end
	line()
	line("Investimento acumulado por raridade (BaseIncome provisório de lançamento):")
	line()
	header({ "Raridade (BaseIncome)", "Nível 2", "Nível 10", "Nível 20", "Nível 30", "Nível 50", "Venda base" })
	local seen = {}
	for _, c in A.CharacterConfig.List do
		if not seen[c.Rarity] and not c.BaseUpgradeCost then
			seen[c.Rarity] = true
			row({
				`{c.Rarity} ({c.BaseIncome})`,
				money(M.investedForLevel(c.Id, 2)),
				money(M.investedForLevel(c.Id, 10)),
				money(M.investedForLevel(c.Id, 20)),
				money(M.investedForLevel(c.Id, 30)),
				money(M.investedForLevel(c.Id, Lv.MaxLevel)),
				money(A.M.formulas:sellValue(c.Id, "Normal")),
			})
		end
	end
	line()
	line("Minutos de renda (P50 do Ativo F2P no momento em que compra o Dice) para levar UMA unidade da raridade mais comum do Dice entre níveis:")
	line()
	header({ "Dice", "Renda/s na compra (P50)", "Raridade típica", "1→10", "10→20", "20→30", "30→50" })
	for i, st in STATS.Ativo do
		local dice = st.dice
		local pool = M.core:pool(dice.Id)
		local bestR, bestW = nil, -1
		for _, r in pool.rarities do
			local w = M.core:rarityWeights(dice.Id, 1)[r]
			if w > bestW then
				bestR, bestW = r, w
			end
		end
		local id = pool.byRarity[bestR][1]
		local ips = if i == 1 then median(collect(select("long", "Ativo"), function(r)
			local s = snapAt(r, 600)
			return s and s.ips
		end)) else median(st.ipsAtPurchase)
		local function mins(a: number, b: number): string
			local cost = M.investedForLevel(id, b) - M.investedForLevel(id, a)
			if ips ~= ips or ips <= 0 then
				return "—"
			end
			return dur(cost / ips)
		end
		row({ dice.Id, money(ips), `{bestR} ({A.CharacterConfig.ById[id].BaseIncome})`, mins(1, 10), mins(10, 20), mins(20, 30), mins(30, Lv.MaxLevel) })
	end
	line()

	------------------------------------------------------------------------------------
	section("7. Duplicatas")
	say("duplicates")
	header({ "Dice", "Raridades", "Valor vendido (Ativo, P50)", "÷ preço do próximo Dice", "Casual P50", "Otimizador P50", "Rolls no Dice (Ativo P50)", "Dice nunca rolado (Ativo)" })
	local function dupStats(profile: string, diceId: string): (number, number, number)
		local list = select("long", profile)
		local sold = collect(list, function(r)
			return r.dupByDice[diceId] or 0
		end)
		local rolls = collect(list, function(r)
			return r.rollsByDice[diceId] or 0
		end)
		local never = 0
		for _, r in list do
			if (r.rollsByDice[diceId] or 0) == 0 then
				never += 1
			end
		end
		return median(sold), median(rolls), never / math.max(1, #list)
	end
	for i, dice in DICE do
		local soldA, rollsA, neverA = dupStats("Ativo", dice.Id)
		local soldC = dupStats("Casual", dice.Id)
		local soldO = dupStats("Otimizador", dice.Id)
		local nextDice = DICE[i + 1]
		row({
			dice.Id,
			table.concat(M.core:pool(dice.Id).rarities, "/"),
			money(soldA),
			if nextDice then pct(soldA / nextDice.Price) else "—",
			money(soldC),
			money(soldO),
			string.format("%.0f", rollsA),
			pct(neverA),
		})
	end
	line()
	local totalDup = {}
	for _, profile in A.PROFILES do
		local by1 = sourceShares(profile, H)
		local by20 = sourceShares(profile, 20 * H)
		table.insert(totalDup, `{PT_PROFILE[profile]}: {pct(by1.Sell or 0)} do dinheiro até 1 h, {pct(by20.Sell or 0)} até 20 h`)
	end
	line("Participação total da venda de duplicatas: " .. table.concat(totalDup, "; ") .. ".")
	line()

	------------------------------------------------------------------------------------
	section("8. UPGRADE REFUND ANALYSIS")
	say("refund")
	for _, profile in { "Casual", "Ativo", "Otimizador" } do
		line(`### {PT_PROFILE[profile]} (10 h ativas, {A.counts.refund} jogadores por %)`)
		line()
		header({ "Refund", "Trocas de estação", "Investimento perdido", "Reembolsado", "Ganho total 10 h", "Dice 10 h", "Index 10 h", "Nível médio 10 h", "Patrimônio 10 h" })
		for _, r in A.REFUNDS do
			local list = select("refund", profile, tostring(r))
			local function at(fn: (any) -> number): number
				return median(collect(list, function(x)
					local s = snapAt(x, 10 * H)
					return s and fn(s)
				end))
			end
			row({
				pct(r),
				string.format("%.0f", median(collect(list, function(x) return x.swaps end))),
				money(median(collect(list, function(x) return x.investmentLost end))),
				money(median(collect(list, function(x) return x.investmentRefunded end))),
				money(at(function(s) return s.earned end)),
				string.format("%.1f", at(function(s) return s.dice end)),
				string.format("%.0f", at(function(s) return s.discovered end)),
				string.format("%.1f", at(function(s) return s.avgLevel end)),
				money(at(function(s) return s.patrimony end)),
			})
		end
		line()
	end
	say("refundEnd")

	------------------------------------------------------------------------------------
	section("9. Prisma da Coleção (UsesPerReward × MaxCharges)")
	say("prism")
	for _, profile in { "Casual", "Ativo" } do
		line(`### {PT_PROFILE[profile]} (20 h ativas)`)
		line()
		header({ "Usos/recompensa", "Teto", "Usos (P50)", "Cargas perdidas no teto (P50)", "Index 20 h (P50)", "Forbidden 100% (jogadores)", "Celestial 100%" })
		for _, uses in A.PRISM_USES do
			for _, cap in A.PRISM_CAPS do
				local list = select("prism", profile, `{uses}x{cap}`)
				local function full(diceId: string): string
					local n = 0
					for _, r in list do
						local c = r.completion[diceId]
						if c and c[4] >= 0 then
							n += 1
						end
					end
					return pct(n / math.max(1, #list))
				end
				row({
					tostring(uses) .. (if uses == A.PrismConfig.UsesPerReward and cap == A.PrismConfig.MaxCharges then " (atual)" else ""),
					tostring(cap),
					string.format("%.0f", median(collect(list, function(r) return r.prismUsed end))),
					string.format("%.0f", median(collect(list, function(r) return r.prismWasted end))),
					string.format("%.0f", median(collect(list, function(r) return r.discovered end))),
					full("Forbidden"),
					full("Celestial"),
				})
			end
		end
		line()
	end
	say("prismEnd")

	------------------------------------------------------------------------------------
	section("10. Rebirth: cedo × médio × tarde")
	say("rebirth")
	for _, profile in { "Casual", "Ativo", "Otimizador" } do
		line(`### {PT_PROFILE[profile]}`)
		line()
		header({ "Política", "1º Rebirth (P50)", "Rebirths 3 h", "Rebirths 10 h", "Rebirths 20 h", "Renda/s 20 h", "Dice 20 h", "Index 20 h", "Ganho total 20 h" })
		for _, policy in A.REBIRTH_POLICIES do
			local list = select("rebirth", profile, policy)
			local function at(t: number, fn: (any) -> number): number
				return median(collect(list, function(x)
					local s = snapAt(x, t)
					return s and fn(s)
				end))
			end
			local first = collect(list, function(r)
				return r.rebirthTimes[1]
			end)
			row({
				policy,
				if #first > #list / 2 then dur(median(first)) else "não renasce (P50)",
				string.format("%.0f", at(3 * H, function(s) return s.rebirths end)),
				string.format("%.0f", at(10 * H, function(s) return s.rebirths end)),
				string.format("%.0f", at(20 * H, function(s) return s.rebirths end)),
				money(at(20 * H, function(s) return s.ips end)),
				string.format("%.1f", at(20 * H, function(s) return s.dice end)),
				string.format("%.0f", at(20 * H, function(s) return s.discovered end)),
				money(at(20 * H, function(s) return s.earned end)),
			})
		end
		line()
	end
	say("rebirthEnd")

	------------------------------------------------------------------------------------
	section("11. Retenção: primeiros 5 / 10 / 20 / 30 / 60 minutos")
	say("retention")
	local EVENTS = {
		{ "1º Raro", function(r) return r.firsts.firstRare end },
		{ "1º Épico", function(r) return r.firsts.firstEpic end },
		{ "1º Lendário", function(r) return r.firsts.firstLegendary end },
		{ "1º Mítico", function(r) return r.firsts.firstMythic end },
		{ "1º Dice novo", function(r) return A.nonNeg(r.ownedAt[2]) end },
		{ "1º upgrade de estação", function(r) return r.firsts.firstStationUpgrade end },
		{ "1º Dice 100% (coleção)", function(r)
			local best = nil
			for _, marks in r.completion do
				if marks[4] >= 0 and (best == nil or marks[4] < best) then
					best = marks[4]
				end
			end
			return best
		end },
	}
	for _, profile in A.PROFILES do
		line(`### {PT_PROFILE[profile]} ({A.counts.short} jogadores)`)
		line()
		header({ "Evento", "P10 / P50 / P90", "≤5 min", "≤10 min", "≤20 min", "≤30 min", "≤60 min" })
		local list = select("short", profile)
		for _, ev in EVENTS do
			local values = collect(list, ev[2])
			local cells = { ev[1], p3(values, dur) }
			for _, limit in { 300, 600, 1200, 1800, H } do
				local n = 0
				for _, v in values do
					if v <= limit then
						n += 1
					end
				end
				table.insert(cells, pct(n / math.max(1, #list)))
			end
			row(cells)
		end
		line()
	end

	------------------------------------------------------------------------------------
	section("12. Longo prazo: 3 / 5 / 10 / 20 h")
	say("longterm")
	header({ "Perfil", "Tempo", "Dice (P50)", "Tem Forbidden", "Forbidden 100%", "Index (P50)", "Rebirths (P50)", "Renda/s (P50)" })
	local forbiddenIndex = #DICE
	for _, profile in A.PROFILES do
		local list = select("long", profile)
		for _, t in { 3 * H, 5 * H, 10 * H, 20 * H } do
			local has, full = 0, 0
			for _, r in list do
				if r.ownedAt[forbiddenIndex] >= 0 and r.ownedAt[forbiddenIndex] <= t then
					has += 1
				end
				local c = r.completion.Forbidden
				if c and c[4] >= 0 and c[4] <= t then
					full += 1
				end
			end
			local function v(fn: (any) -> number): number
				return median(collect(list, function(r)
					local s = snapAt(r, t)
					return s and fn(s)
				end))
			end
			row({
				PT_PROFILE[profile], dur(t),
				string.format("%.0f", v(function(s) return s.dice end)),
				pct(has / #list), pct(full / #list),
				string.format("%.0f", v(function(s) return s.discovered end)),
				string.format("%.0f", v(function(s) return s.rebirths end)),
				money(v(function(s) return s.ips end)),
			})
		end
	end
	line()

	say("problems")
	say("recommendations")
	say("method")
end
