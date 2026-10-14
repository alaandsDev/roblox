--[[
	Análise de balanceamento dos 16 Dice (Lune): lune run tools/sim/analyze_dice_balance.luau
	Escreve DICE_BALANCE_ANALYSIS.md. Usa o MESMO DiceCore do servidor com os pesos PROPOSTOS
	(tools/sim/DiceBalanceProposal.luau); a produção (DiceConfig) não é alterada.
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

local P = B.Proposal
local current, proposed = B.current, B.proposed
local diceList = current:diceList()
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
line("# DICE BALANCE ANALYSIS — Roll Legends (PROPOSTA, não aplicada)")
line()
line("Gerado por `lune run tools/sim/analyze_dice_balance.luau` com o **mesmo `DiceCore` do servidor**.")
line("Pesos propostos em `tools/sim/DiceBalanceProposal.luau`. **Produção inalterada**: `DiceConfig`,")
line("Luck, pity, preços e unlocks continuam como no commit 4a69c25 até a aprovação.")
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
line("## 1. Tabela proposta dos 16 Dice")
line()
line("| # | Dice | Unlock (rolls · Dice anterior) | Preço | Pool | Pesos propostos (Luck 1) | Luck do Dice | ERV atual | ERV proposto |")
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
line("## 2. Comparação atual × proposta (Luck 1)")
line()
line("| Dice | Atual (normalização da tabela global) | Proposta |")
line("|---|---|---|")
for _, dice in diceList do
	line(string.format("| %s | %s | %s |", dice.Id, weightsText(current, dice.Id), weightsText(proposed, dice.Id)))
end
line()

------------------------------------------------------------------------------------
line("## 3. Regressões")
line()
line("**Atual (produção):**")
line()
for _, r in regressions.current do
	line("- " .. r)
end
line()
line("**Proposta:** " .. (if #regressions.proposed == 0 then "nenhuma — ERV estritamente crescente do #1 ao #16." else table.concat(regressions.proposed, "; ")))
line()
line("**Limitações estruturais dos pools (sinalizadas, NÃO corrigidas — nenhum personagem foi movido):**")
line()
line("- **Shinobi (#5) não tem Lendário**, e vem depois do Flame (#4), que tem. Pesos não resolvem a")
line("  métrica \"chance de Lendário\" (0% no Shinobi). A proposta mantém o ERV crescente via Épico 18%,")
line("  mas o jogador perde o Lendário ao avançar. Sugestão (não aplicada): trocar a ordem Shinobi ↔ Flame.")
line("- **Colossus (#14) tem Épico e o Awakened (#13) não.** A proposta compensa com Mítico 27% no")
line("  Colossus (ERV 163,5 > 145). Sugestão (não aplicada): trocar a ordem Colossus ↔ Awakened.")
line("- **Forbidden tem 1 único Mítico**: com Mítico ~98,5%, esse personagem sai em quase todo roll do")
line("  Forbidden (vira o \"comum\" do endgame). Inevitável com esse pool; o valor do Dice são os 3 Divinos")
line("  e os 3 Secretos.")
line()
line("### Variante B (alternativa recomendada para a fase de unlocks — NÃO aplicada)")
line()
line("Mesmos pools; troca Shinobi ↔ Flame e Colossus ↔ Awakened. Nessa ordem o Shinobi e o Colossus")
line("podem ser mais modestos (Épico 10% e Mítico 15%, em vez de 18% e 27%), e o jogador não \"perde\" o")
line("Lendário (Shinobi) nem ganha Épico de volta no endgame (Colossus). Os outros 14 Dice iguais à proposta.")
line()
line("| # | Dice | Pesos (Luck 1) | ERV |")
line("|---:|---|---|---:|")
local prevB = 0
local regressionsB = {}
for i, id in P.VariantB.Order do
	local erv = B.erv(B.variantB, id, 1)
	if erv <= prevB then
		table.insert(regressionsB, id)
	end
	prevB = erv
	line(string.format("| %d | %s | %s | %.1f |", i, id, weightsText(B.variantB, id), erv))
end
line()
line("Regressões na Variante B: " .. (if #regressionsB == 0 then "nenhuma (ERV estritamente crescente)." else table.concat(regressionsB, ", ")))
line("A ordem de desbloqueio (Order/UnlockRequirement/preço por posição) só muda se você aprovar.")
line()

------------------------------------------------------------------------------------
line("## 4. Impacto da Luck (proposta)")
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
line("a estrutura da Luck** com a proposta; ver §9 para o efeito por hora.")
line()

------------------------------------------------------------------------------------
line("## 5. Detalhe por Dice (proposta)")
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
line("**Forbidden:** com a proposta (Mítico 98,4955% · Divino 1,5% · Secreto 0,0045%), o Secreto é 1 em")
line("~22.200 com Luck 1 (cada um dos 3 Secretos: 1 em ~66.700) e fica **abaixo de 1 por hora mesmo no")
line("máximo absoluto** (Luck máxima com monetização + Roll Rápido) — a mesma meta da auditoria de RNG")
line("anterior (com 0,005% dava 1,01/h). A normalização atual (75/20/5) dava 1 Secreto a cada 20 rolls.")
line()
line("**Tensão a decidir — Divino no endgame:** a meta da auditoria antiga (\"Divino < 3/h\") era para o")
line("sorteio GLOBAL. Nos Dice endgame, que existem para entregar Divinos, a proposta dá ~36–150")
line("Divinos/h no Celestial/Forbidden (1 Divino a cada 30 s–1m40s), mas cada Divino específico continua")
line("1 em 200–300 rolls. Se você quiser o Divino mais raro mesmo no endgame, a alternativa é metade:")
line("Celestial L 64 / M 35,5 / D 0,5 e Forbidden M 99,2455 / D 0,75 / S 0,0045 (ERV continua crescente: 216,0 e 412,7).")
line()
line("**Celestial:** Divino 1% (cada um dos 3: 1 em 300). Mítico 35,5% continua frequente, mas é o")
line("Dice que antecede o Forbidden e tem 2 Míticos e 2 Lendários: o valor está nos Divinos.")
line()

------------------------------------------------------------------------------------
line("## 7. Pity com os pesos propostos")
line()
local thresholds = {}
for _, rule in RollConfig.Pity do
	thresholds[rule.Id] = rule.Threshold
end
line(string.format("Atual: Lendário %d · Mítico %d. Um pity só vale em Dice que tem a raridade do piso.", thresholds.Legendary, thresholds.Mythic))
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
line("**Leitura — Lendário 50:** no Flame (Lendário 1%) 61% dos Lendários viriam do pity e o Lendário")
line("sairia a cada ~40 rolls (não 100): o pity, e não o RNG, passa a definir a raridade da primeira")
line("vitrine. No Blade (2%) 37%; no Fighter (3%) 22%; do Storm em diante (≥8%) o pity quase não age.")
line("**Recomendação:** subir para **150** (Flame: 22% pelo pity, Lendário a cada ~78 rolls; ≥ Blade quase")
line("irrelevante) — continua sendo uma rede de segurança, sem esvaziar a raridade. Manter 50 só se a")
line("intenção for um Lendário bem mais frequente no início.")
line()
line("**Leitura — Mítico 800:** o Mítico só existe do Spirit em diante; no Spirit (1%) a chance de")
line("chegar a 800 rolls sem Mítico é ~0,03%, e do Arcane em diante é ~0. **O pity Mítico 800 é")
line("praticamente decorativo.** Com **250**: Spirit ~8% dos Míticos pelo pity (Mítico a cada ~92 rolls")
line("em vez de 100), Arcane ~0,6%, Shadow+ ~0 — uma rede de segurança real só onde o Mítico é raro.")
line("**Recomendação: voltar o Mítico para 250.** (400 fica no meio: Spirit ~1,8%.)")
line()

------------------------------------------------------------------------------------
line("## 8. Preços e unlocks (avaliação; nada alterado)")
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
line("Leitura:")
line()
line("- Preço: ~×2–4 por Dice até o Celestial e **×10 no Forbidden (750M)** — o salto final é o maior")
line("  da curva. Faz sentido como endgame, mas precisa ser validado com a renda real (fase de economia).")
line("- **Completar cada pool é rápido** com os pesos propostos (Luck do próprio Dice): dezenas de rolls")
line("  do Starter ao Shadow, ~260 no Void, ~430 no Celestial; só o **Forbidden é longo (~71.600 rolls,")
line("  ~20 h em Normal / ~10 h com Roll Rápido)** por causa dos 3 Secretos. Os rolls exigidos entre Dice")
line("  (+50 a +4.000) são MAIORES que isso: o requisito de rolls e, principalmente, o **preço** é que")
line("  seguram a progressão, não o RNG. Consequência: o Índice F2P (exceto Forbidden) pode ser completado")
line("  rápido quando o dinheiro chega — a longevidade vem da economia, dos níveis/variantes e do Forbidden.")
line("  Sugestão separada (fase de economia): validar o tempo até cada preço com a renda real e decidir")
line("  se algum pool deve ficar mais longo (ex.: Divino/Mítico um pouco mais raros nos Dice 9–15).")
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
line("## 10. Sessões endgame (Luck do Dice, pity atual 50/800, sementes fixas)")
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
line("## 11. Prism (Dia 7 do Diário) — 3 propostas (nada implementado)")
line()
line("1. **Prisma da Coleção** (recomendada): 1 \"roll de prisma\" por dia, gasto na Loja de Dados. Sorteia")
line("   com as chances normais do Dice selecionado, mas **só entre os personagens que o jogador ainda")
line("   NÃO descobriu** naquele Dice (se já descobriu todos, vira um roll normal). Não aumenta raridade,")
line("   não acelera rolls e não se compra: ajuda a completar o Índice e dá um motivo para trocar de Dice.")
line("2. **Prisma de Variante**: os próximos 25 rolls com o Prism equipado (1x por dia) têm chance de")
line("   sair como variante visual (Silver/Gold) — mesmo personagem, mesmo RNG de raridade. Aproveita a")
line("   Fusão/variantes, mas mexe na economia das variantes (renda maior) e exige balanceamento próprio.")
line("3. **Prisma Espelho**: o Prism \"copia\" o Dice desbloqueado mais alto e dá um bônus de Luck pequeno")
line("   (+10%) por 10 minutos 1x/dia. Simples, mas é mais Luck (pouco interessante e encosta em P2W de tempo).")
line()
line("**Recomendação: Prisma da Coleção** — usa a mecânica de coleção/RNG, é limitado por dia, é F2P")
line("(vem do Diário) e não substitui nenhum dos 16 Dice; a probabilidade exibida continua sendo a do")
line("Dice (filtrada), então a API de probabilidade atual serve com um filtro de \"não descobertos\".")
line()

------------------------------------------------------------------------------------
line("## 12. Recomendações (para aprovação; nada aplicado)")
line()
line("1. Aplicar os `RarityWeights` propostos (§1) como `RarityWeights` explícitos no `DiceConfig`.")
line("2. Pity Mítico **800 → 250**; pity Lendário **50 → 150** (ou manter 50 se o início deve ser generoso).")
line("3. Luck: **sem mudança estrutural** — com os pesos propostos o Secreto fica < 1/h no máximo absoluto.")
line("4. Ordem dos Dice: preferir a **Variante B** (Shinobi ↔ Flame e Colossus ↔ Awakened, com Épico 10% no")
line("   Shinobi e Mítico 15% no Colossus) — mesmos pools, curva mais natural; exige mudar a ordem de unlock.")
line("5. Preços/unlocks: manter por ora; validar com a renda real na fase de economia (o preço é o freio")
line("   real da progressão; ×10 no Forbidden).")
line("6. Divino no endgame: manter (1% Celestial / 1,5% Forbidden) ou usar a alternativa com metade (§6).")
line("7. Prism: Prisma da Coleção.")

fs.writeFile("DICE_BALANCE_ANALYSIS.md", table.concat(out, "\n") .. "\n")
print("DICE_BALANCE_ANALYSIS.md escrito (" .. #out .. " linhas)")
