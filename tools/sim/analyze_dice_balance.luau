--[[
	Análise de balanceamento dos 16 Dice (Lune): lune run tools/sim/analyze_dice_balance.luau
	Escreve DICE_BALANCE_ANALYSIS.md com os pesos FINAIS de produção (DiceConfig: Variante B +
	Divino reduzido, aprovados), comparados com a normalização antiga (commit 4a69c25).
	Simulação determinística (xorshift32, sementes fixas): 1.000.000 rolls por Dice + sessões
	de 100 / 1.000 / 10.000 rolls nos Dice endgame.
]]

local fs = require("@lune/fs")
local B = require("./DiceBalance")
local Rng = require("../../tests/Rng")
local RarityConfig = require("../../src/shared/Config/RarityConfig")
local RollConfig = require("../../src/shared/Config/RollConfig")
local DiceConfig = require("../../src/shared/Config/DiceConfig")
local CharacterConfig = require("../../src/shared/Config/CharacterConfig")

local P = B.Params
local current, proposed = B.baseline, B.final -- "current" = antes (normalização); "proposed" = FINAL
local diceList = proposed:diceList()
local N_SIM = 1000000
local SHORT = { Common = "C", Uncommon = "U", Rare = "R", Epic = "E", Legendary = "L", Mythic = "M", Divine = "D", Secret = "S" }
local PT = { Common = "Comum", Uncommon = "Incomum", Rare = "Raro", Epic = "Épico", Legendary = "Lendário", Mythic = "Mítico", Divine = "Divino", Secret = "Secreto" }
local ENDGAME = { "Awakened", "Colossus", "Celestial", "Forbidden" }

local out = {}
local function line(text: string?)
	table.insert(out, text or "")
end
local function pct(p: number): string
	if p >= 0.01 then
		return string.format("%.2f%%", p * 100)
	elseif p >= 0.0001 then
		return string.format("%.4f%%", p * 100)
	end
	return string.format("%.5f%%", p * 100)
end
local function oneIn(rolls: number): string
	if rolls == math.huge then
		return "—"
	end
	local n = math.floor(rolls + 0.5)
	local s = tostring(n)
	local formatted = s:reverse():gsub("(%d%d%d)", "%1."):reverse()
	return "1 em " .. formatted:gsub("^%.", "")
end
local function weightsText(core: any, diceId: string): string
	local parts = {}
	for _, row in B.rarityRows(core, diceId, 1) do
		table.insert(parts, string.format("%s %s", SHORT[row.rarity], pct(row.p)))
	end
	return table.concat(parts, " · ")
end
local function countsText(diceId: string): string
	local parts = {}
	for _, row in B.rarityRows(current, diceId, 1) do
		table.insert(parts, string.format("%s%d", SHORT[row.rarity], row.count))
	end
	return table.concat(parts, " ")
end
local function money(n: number): string
	if n >= 1e6 then
		return string.format("%gM", n / 1e6)
	elseif n >= 1e3 then
		return string.format("%gk", n / 1e3)
	end
	return tostring(n)
end

------------------------------------------------------------------------------------
line("# DICE BALANCE ANALYSIS — Roll Legends (FINAL, aplicado)")
line()
line("Gerado por `lune run tools/sim/analyze_dice_balance.luau` com o **mesmo `DiceCore` do servidor**.")
line("**Pesos FINAIS de produção** (`DiceConfig.RarityWeights`, explícitos): proposta de e4b73ac aprovada")
line("com a **Variante B** (Shinobi antes do Flame, Colossus antes do Awakened) e o **Divino reduzido**")
line("(Celestial 0,5% / Forbidden 0,75%). Pity: Lendário 50 (mantido) · Mítico **250**. Luck: inalterada.")
line("Preço e rolls de desbloqueio seguem a POSIÇÃO; o LuckMultiplier é de cada Dice. \"Antes\" = normalização")
line("da tabela global (commit 4a69c25).")
line()
line("- Pools (personagens por Dice) **não mudam**; só os `RarityWeights`.")
line(string.format("- Cadência: Normal = %g s/roll (1 roll/s) · Roll Rápido = %g s/roll (2 rolls/s). Tempos = expectativa matemática, não garantia.", RollConfig.RollSpeed.BaseInterval, RollConfig.RollSpeed.FastRollInterval))
line("- **Expected Rarity Value (ERV)** = Σ P(raridade) × Score — ferramenta de análise, não é gameplay. Score: " .. (function()
	local parts = {}
	for _, r in RarityConfig.Order do
		table.insert(parts, `{PT[r]} {P.Score[r]}`)
	end
	return table.concat(parts, " · ")
end)() .. ".")
line("- Luck nos cenários: 1,0x · Luck do próprio Dice (LuckMultiplier, sem upgrades) · máximo F2P (upgrades/renascimentos/perks no máximo + boost diário 2x) · máximo com monetização (+ VIP + Sorte x2). Fórmula atual: retornos decrescentes (LuckSoftCap 10) e `LuckExponent` por raridade.")
line()

------------------------------------------------------------------------------------
line("## 1. Tabela final dos 16 Dice (ordem oficial)")
line()
line("| # | Dice | Unlock (rolls · Dice anterior) | Preço | Pool | Pesos finais (Luck 1) | Luck do Dice | ERV antes | ERV final |")
line("|---:|---|---|---:|---|---|---:|---:|---:|")
local prevProposed, prevCurrent = 0, 0
local regressions = { current = {}, proposed = {} }
for _, dice in diceList do
	local req = dice.UnlockRequirement
	local ervC, ervP = B.erv(current, dice.Id, 1), B.erv(proposed, dice.Id, 1)
	if ervC <= prevCurrent then
		table.insert(regressions.current, string.format("%s (#%d): ERV %.1f ≤ anterior %.1f", dice.Id, dice.Order, ervC, prevCurrent))
	end
	if ervP <= prevProposed then
		table.insert(regressions.proposed, string.format("%s (#%d): ERV %.1f ≤ anterior %.1f", dice.Id, dice.Order, ervP, prevProposed))
	end
	prevCurrent, prevProposed = ervC, ervP
	line(string.format("| %d | **%s** | %s · %s | %s | %s | %s | %.2fx | %.1f | **%.1f** |", dice.Order, dice.Id, tostring(req.Rolls or 0), req.Dice or "—", money(dice.Price), countsText(dice.Id), weightsText(proposed, dice.Id), dice.LuckMultiplier, ervC, ervP))
end
line()
line("Pool: quantidade de personagens por raridade (C/U/R/E/L/M/D/S). ERV com Luck 1.")
line()

------------------------------------------------------------------------------------
line("## 2. Comparação antes × final (Luck 1)")
line()
line("| Dice | Antes (normalização da tabela global) | Final |")
line("|---|---|---|")
for _, dice in diceList do
	line(string.format("| %s | %s | %s |", dice.Id, weightsText(current, dice.Id), weightsText(proposed, dice.Id)))
end
line()

------------------------------------------------------------------------------------
line("## 3. Regressões")
line()
line("**Antes (normalização, ordem atual):**")
line()
for _, r in regressions.current do
	line("- " .. r)
end
line()
line("**Final:** " .. (if #regressions.proposed == 0 then "nenhuma — ERV estritamente crescente do #1 ao #16." else table.concat(regressions.proposed, "; ")))
line()
line("**Ordem (Variante B aplicada):** Shinobi (#4, sem Lendário) agora vem ANTES do Flame (#5, primeiro")
line("Lendário) e Colossus (#13, E/L/M) antes do Awakened (#14, L/M): o jogador nunca \"perde\" uma raridade")
line("ao avançar. Pools inalterados. O LuckMultiplier é do Dice, então Shinobi (1,7x) > Flame (1,6x) e")
line("Colossus (3,5x) > Awakened (3,1x) — veja a coluna ERV com Luck do Dice abaixo.")
line()
line("| # | Dice | ERV Luck 1 | ERV Luck do Dice |")
line("|---:|---|---:|---:|")
for _, dice in diceList do
	line(string.format("| %d | %s | %.1f | %.1f |", dice.Order, dice.Id, B.erv(proposed, dice.Id, 1), B.erv(proposed, dice.Id, dice.LuckMultiplier)))
end
line()
line("Limitação do pool (sinalizada): o Forbidden tem 1 único Mítico, que sai em ~99% dos rolls do")
line("Forbidden (é o \"comum\" do endgame); o valor do Dice são os 3 Divinos e os 3 Secretos.")
line()

------------------------------------------------------------------------------------
line("## 4. Impacto da Luck (final)")
line()
line("Chance da raridade MAIS ALTA de cada Dice nos 4 cenários de Luck (e 1 em X).")
line()
line("| Dice | Raridade topo | Luck 1,0x | Luck do Dice | Máx. F2P | Máx. monetização |")
line("|---|---|---|---|---|---|")
for _, dice in diceList do
	local pool = proposed:pool(dice.Id)
	local top = pool.rarities[#pool.rarities]
	local cells = {}
	for _, s in B.luckScenarios(dice.Id) do
		local p = proposed:rarityChances(dice.Id, s.luck)[top]
		table.insert(cells, string.format("%s (%s) @%.2fx", pct(p), oneIn(1 / p), s.luck))
	end
	line(string.format("| %s | %s | %s |", dice.Id, PT[top], table.concat(cells, " | ")))
end
line()
line("Leitura: a Luck atual tem retornos decrescentes (Luck efetiva nunca passa de ~11) e, nos Dice")
line("endgame, o denominador é dominado por Lendário/Mítico (que também sobem com a Luck). Por isso a")
line("Luck máxima multiplica o Secreto do Forbidden por ~2,8x (não por 20–90x). **Não é preciso mudar")
line("a estrutura da Luck** com os pesos finais; ver §6 e §11 para o efeito por hora e por prêmio.")
line()

------------------------------------------------------------------------------------
line("## 5. Detalhe por Dice (final)")
for _, dice in diceList do
	local scenarios = B.luckScenarios(dice.Id)
	local own = scenarios[2].luck
	line()
	line(string.format("### %d. %s — unlock %s rolls + %s · preço %s · Luck do Dice %.2fx", dice.Order, dice.Id, tostring(dice.UnlockRequirement.Rolls or 0), dice.UnlockRequirement.Dice or "—", money(dice.Price), dice.LuckMultiplier))
	line()
	line("| Raridade | Pers. | P (Luck 1) | Rolls esperados | Normal | Rápido | P (Luck do Dice) | Rolls | Normal |")
	line("|---|---:|---:|---:|---:|---:|---:|---:|---:|")
	local ownRows = {}
	for _, row in B.rarityRows(proposed, dice.Id, own) do
		ownRows[row.rarity] = row
	end
	for _, row in B.rarityRows(proposed, dice.Id, 1) do
		local normal, fast = B.timing(row.rolls)
		local o = ownRows[row.rarity]
		line(string.format("| %s | %d | %s | %s | %s | %s | %s | %s | %s |", PT[row.rarity], row.count, pct(row.p), oneIn(row.rolls), normal, fast, pct(o.p), oneIn(o.rolls), (B.timing(o.rolls))))
	end
	line()
	line("| Personagem | Raridade | P (Luck 1) | Rolls esperados | Normal | Rápido |")
	line("|---|---|---:|---:|---:|---:|")
	for _, row in B.characterRows(proposed, dice.Id, 1) do
		local normal, fast = B.timing(row.rolls)
		line(string.format("| %s (`%s`) | %s | %s | %s | %s | %s |", row.name, row.id, PT[row.rarity], pct(row.p), oneIn(row.rolls), normal, fast))
	end
	local completion = B.completionRolls(proposed, dice.Id, own)
	local cNormal, cFast = B.timing(completion)
	line()
	line(string.format("Completar o pool (todos ao menos 1x, Luck do Dice): ~%s rolls (Normal %s · Rápido %s).", oneIn(completion):gsub("1 em ", ""), cNormal, cFast))
end
line()

------------------------------------------------------------------------------------
line("## 6. Celestial e Forbidden (endgame) — análise detalhada")
for _, id in { "Celestial", "Forbidden" } do
	line()
	line(string.format("### %s", id))
	line()
	line("| Cenário | " .. (function()
		local parts = {}
		for _, row in B.rarityRows(proposed, id, 1) do
			table.insert(parts, PT[row.rarity])
		end
		return table.concat(parts, " | ")
	end)() .. " | ERV |")
	line("|---|" .. string.rep("---|", #proposed:pool(id).rarities) .. "---:|")
	for _, s in B.luckScenarios(id) do
		local cells = {}
		for _, row in B.rarityRows(proposed, id, s.luck) do
			table.insert(cells, string.format("%s (%s)", pct(row.p), oneIn(row.rolls)))
		end
		line(string.format("| %s | %s | %.1f |", s.name, table.concat(cells, " | "), B.erv(proposed, id, s.luck)))
	end
	line()
	line("Por hora (expectativa), raridades top:")
	line()
	line("| Cenário | Cadência | " .. (if id == "Forbidden" then "Divino/h | Secreto/h | 1 Secreto a cada" else "Mítico/h | Divino/h | 1 Divino a cada") .. " |")
	line("|---|---|---:|---:|---:|")
	for _, s in B.luckScenarios(id) do
		local chances = proposed:rarityChances(id, s.luck)
		for _, cadence in { { "Normal", 3600 / RollConfig.RollSpeed.BaseInterval }, { "Rápido", 3600 / RollConfig.RollSpeed.FastRollInterval } } do
			local a, b = if id == "Forbidden" then chances.Divine else chances.Mythic, if id == "Forbidden" then chances.Secret else chances.Divine
			line(string.format("| %s | %s | %.1f | %.2f | %s |", s.name, cadence[1], a * cadence[2], b * cadence[2], B.duration(3600 / (b * cadence[2]))))
		end
	end
end
line()
line("**Forbidden (final):** Mítico 99,2455% · Divino 0,75% · Secreto 0,0045%. Secreto 1 em ~22.200 com")
line("Luck 1 (cada um dos 3: 1 em ~66.700), **abaixo de 1 por hora mesmo no máximo absoluto** (Luck máxima com")
line("monetização + Roll Rápido) — meta da auditoria de RNG. Antes (75/20/5) era 1 Secreto a cada 20 rolls.")
line()
line("**Celestial (final):** Lendário 64% · Mítico 35,5% · Divino 0,5% (cada um dos 3 Divinos: 1 em 600).")
line()

------------------------------------------------------------------------------------
line("## 7. Pity com os pesos finais")
line()
local thresholds = {}
for _, rule in RollConfig.Pity do
	thresholds[rule.Id] = rule.Threshold
end
line(string.format("Final: Lendário %d (mantido) · Mítico %d (era 800). Um pity só vale em Dice que tem a raridade do piso.", thresholds.Legendary, thresholds.Mythic))
line(string.format("Tempo para %d rolls: Normal %s · Rápido %s. Para %d rolls: Normal %s · Rápido %s.", thresholds.Legendary, (B.timing(thresholds.Legendary)), select(2, B.timing(thresholds.Legendary)), thresholds.Mythic, (B.timing(thresholds.Mythic)), select(2, B.timing(thresholds.Mythic))))
line()
for _, rule in RollConfig.Pity do
	line(string.format("### Pity %s (piso: %s ou melhor)", rule.Id, PT[rule.MinRarity]))
	line()
	local header = "| Dice | P natural (Luck 1) | 1 em |"
	local sep = "|---|---:|---:|"
	for _, n in P.PityCandidates[rule.Id] do
		header ..= string.format(" chega ao pity %d | rolls efetivos %d |", n, n)
		sep ..= "---:|---:|"
	end
	line(header)
	line(sep)
	for _, dice in diceList do
		if proposed:supports(dice.Id, rule.MinRarity) then
			local p = B.atLeast(proposed, dice.Id, rule.MinRarity, 1)
			local row = string.format("| %s | %s | %s |", dice.Id, pct(p), oneIn(1 / p))
			for _, n in P.PityCandidates[rule.Id] do
				local s = B.pity(p, n)
				row ..= string.format(" %s | %.1f |", pct(s.reach), s.effectiveRolls)
			end
			line(row)
		end
	end
	local unsupported = {}
	for _, dice in diceList do
		if not proposed:supports(dice.Id, rule.MinRarity) then
			table.insert(unsupported, dice.Id)
		end
	end
	line()
	line("Dice SEM a raridade (pity congelado): " .. table.concat(unsupported, ", ") .. ".")
	line()
end
line("\"Chega ao pity\" = fração dos ciclos que só terminam pelo pity ((1−p)^(N−1)); \"rolls efetivos\" =")
line("rolls médios entre acertos COM pity ((1−(1−p)^N)/p). Sem pity seria 1/p.")
line()
line("**Lendário 50 (mantido por decisão de design):** no Flame (Lendário 1%) ~61% dos Lendários vêm do")
line("pity (1 Lendário a cada ~40 rolls em vez de 100), no Blade ~37%, no Fighter ~22%; do Storm em diante o")
line("pity quase não age. Intencional: início/meio de jogo mais generoso, com momentos fortes para iniciantes.")
line()
line("**Mítico 250 (aplicado):** só onde o Mítico é raro — Spirit ~8% dos Míticos pelo pity (~92 rolls entre")
line("Míticos em vez de 100), Arcane ~0,6%, Shadow em diante ~0. Com 800 era decorativo (~0,03% no Spirit).")
line()

------------------------------------------------------------------------------------
line("## 8. Preços e unlocks (por posição; economia ainda pendente)")
line()
line("| # | Dice | Preço | × anterior | Rolls p/ desbloquear | Δ rolls | ~tempo de roll (Normal) | Completar pool anterior (Luck do Dice) |")
line("|---:|---|---:|---:|---:|---:|---:|---:|")
local prev = nil
for _, dice in diceList do
	local rolls = dice.UnlockRequirement.Rolls or 0
	local completionPrev = if prev then B.completionRolls(proposed, prev.Id, prev.LuckMultiplier) else 0
	line(string.format("| %d | %s | %s | %s | %s | %s | %s | %s |", dice.Order, dice.Id, money(dice.Price), if prev and prev.Price > 0 then string.format("%.1fx", dice.Price / prev.Price) else "—", tostring(rolls), if prev then tostring(rolls - (prev.UnlockRequirement.Rolls or 0)) else "—", (B.timing(rolls)), if prev then oneIn(completionPrev):gsub("1 em ", "") .. " rolls" else "—"))
	prev = dice
end
line()
line("Preço e rolls pertencem à POSIÇÃO (#4 = 40k / 300 rolls, #5 = 75k / 425, #13 = 12,5M / 4.500,")
line("#14 = 30M / 6.000): com a Variante B, Shinobi e Colossus ficaram mais baratos e Flame e Awakened mais caros.")
line("Completar cada pool custa dezenas de rolls (Void/Celestial: centenas; Forbidden: dezenas de milhares por")
line("causa dos Secretos): o freio da progressão é o PREÇO. Validar com a renda real na fase de economia.")
line()

------------------------------------------------------------------------------------
line("## 9. Simulação: 1.000.000 rolls por Dice (Luck 1, sem pity)")
line()
line("| Dice | Raridade | Teórico | Observado | Desvio (z) | Maior |z| entre personagens |")
line("|---|---|---:|---:|---:|---:|")
local worstZ = 0
for i, dice in diceList do
	local rand = Rng.new(424242 + i * 104729)
	local rarityCount, charCount = {}, {}
	for _ = 1, N_SIM do
		local rarity = proposed:pickRarity(dice.Id, 1, rand)
		local id = proposed:pickCharacter(dice.Id, rarity, rand)
		rarityCount[rarity] = (rarityCount[rarity] or 0) + 1
		charCount[id] = (charCount[id] or 0) + 1
	end
	local maxCharZ = 0
	for _, id in proposed:charactersFor(dice.Id) do
		local p = proposed:characterProbability(dice.Id, id, 1)
		local z = ((charCount[id] or 0) - N_SIM * p) / math.sqrt(N_SIM * p * (1 - p))
		maxCharZ = math.max(maxCharZ, math.abs(z))
	end
	worstZ = math.max(worstZ, maxCharZ)
	for j, row in B.rarityRows(proposed, dice.Id, 1) do
		local observed = (rarityCount[row.rarity] or 0) / N_SIM
		local z = ((rarityCount[row.rarity] or 0) - N_SIM * row.p) / math.sqrt(N_SIM * row.p * (1 - row.p))
		line(string.format("| %s | %s | %s | %s | %+.2f | %s |", if j == 1 then dice.Id else "", PT[row.rarity], pct(row.p), pct(observed), z, if j == 1 then string.format("%.2f", maxCharZ) else ""))
	end
end
line()
line(string.format("Maior desvio entre TODOS os personagens dos 16 Dice: |z| = %.2f (esperado < ~4 com 112 comparações).", worstZ))
line()

------------------------------------------------------------------------------------
line(string.format("## 10. Sessões endgame (Luck do Dice, pity %d/%d, sementes fixas)", thresholds.Legendary, thresholds.Mythic))
line()
line("| Dice | Sessão | Sessões simuladas | Míticos (média) | Divinos (média) | Secretos (média) | P(≥1 Divino) | P(≥1 Secreto) |")
line("|---|---:|---:|---:|---:|---:|---:|---:|")
local sessionPlan = { { 100, 5000 }, { 1000, 1000 }, { 10000, 200 } }
for gi, id in ENDGAME do
	local luck = DiceConfig.ById[id].LuckMultiplier
	for si, plan in sessionPlan do
		local length, sessions = plan[1], plan[2]
		local rand = Rng.new(777 + gi * 31 + si * 1009)
		local sumM, sumD, sumS, anyD, anyS = 0, 0, 0, 0, 0
		for _ = 1, sessions do
			local pity = { Legendary = 0, Mythic = 0 }
			local m, d, s = 0, 0, 0
			for _ = 1, length do
				local r = proposed:roll(id, luck, pity, rand)
				pity = r.pity
				if r.rarity == "Mythic" then
					m += 1
				elseif r.rarity == "Divine" then
					d += 1
				elseif r.rarity == "Secret" then
					s += 1
				end
			end
			sumM += m
			sumD += d
			sumS += s
			anyD += if d > 0 then 1 else 0
			anyS += if s > 0 then 1 else 0
		end
		line(string.format("| %s | %s rolls | %d | %.2f | %.3f | %.4f | %.1f%% | %.2f%% |", if si == 1 then id else "", tostring(length), sessions, sumM / sessions, sumD / sessions, sumS / sessions, anyD / sessions * 100, anyS / sessions * 100))
	end
end
line()
line("Sessão de 100 rolls ≈ 1m40s (Normal); 1.000 ≈ 16m40s; 10.000 ≈ 2h47m.")
line()

------------------------------------------------------------------------------------
line("## 11. Endgame: rolls e tempo esperados (final)")
line()
line("| Prêmio | Cenário | Chance | Rolls esperados | Normal (1/s) | Roll Rápido (2/s) |")
line("|---|---|---:|---:|---:|---:|")
local function prize(label: string, diceId: string, filter: (string) -> boolean, perCharacter: string?)
	for _, s in B.luckScenarios(diceId) do
		local p = 0
		if perCharacter then
			p = proposed:characterProbability(diceId, perCharacter, s.luck)
		else
			for rarity, chance in proposed:rarityChances(diceId, s.luck) do
				if filter(rarity) then
					p += chance
				end
			end
		end
		local normal, fast = B.timing(1 / p)
		line(string.format("| %s | %s | %s | %s | %s | %s |", label, s.name, pct(p), oneIn(1 / p), normal, fast))
	end
end
prize("Divino (Celestial)", "Celestial", function(r)
	return r == "Divine"
end)
prize("Divino (Forbidden)", "Forbidden", function(r)
	return r == "Divine"
end)
prize("Secreto (Forbidden, qualquer)", "Forbidden", function(r)
	return r == "Secret"
end)
for _, id in proposed:pool("Forbidden").byRarity.Secret do
	prize(string.format("Secreto %s (`%s`)", CharacterConfig.ById[id].Name, id), "Forbidden", function()
		return false
	end, id)
end
line()

line("## 12. Prisma da Coleção (implementado)")
line()
line("Prism (Dia 7 do Diário) = **Prisma da Coleção**: cada uso sorteia no Dice SELECIONADO, mas só entre os")
line("personagens ainda NÃO descobertos, com as probabilidades relativas do Dice (P(c)/Σ elegíveis). Não muda")
line("pesos, Luck, pity (`PrismConfig.AffectsPity = false`) nem a contagem de rolls; Dice completo = recusado")
line("sem gastar o uso; não é vendido. Usos: `PrismConfig.UsesPerReward` por entrega do Diário (teto")
line("`MaxCharges`), intervalo mínimo `CooldownSeconds`.")
line()
line("Exemplo (Forbidden, só faltando os 3 Secretos): o prisma entrega um Secreto com 100% de chance — é o")
line("efeito desejado de \"completar a coleção\", limitado pelos usos que só o Diário dá.")
line()

fs.writeFile("DICE_BALANCE_ANALYSIS.md", table.concat(out, "\n") .. "\n")
print("DICE_BALANCE_ANALYSIS.md escrito (" .. #out .. " linhas)")
