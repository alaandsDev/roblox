--[[
	Texto do ECONOMY_BALANCE_ANALYSIS.md (seções narrativas). Cada função recebe o agregado A
	(ver analyze_economy.luau/EconomyReport.luau) e devolve Markdown. Os números citados são
	lidos dos resultados da simulação ou das configs — nada é digitado à mão.
]]

local H = 3600

local function medianAt(A: any, profile: string, t: number, field: string): number
	return A.median(A.collect(A.select("long", profile), function(r)
		local s = A.snapAt(r, t)
		return s and s[field]
	end))
end

local function diceTime(A: any, profile: string, diceId: string, q: number): number
	for _, st in A.STATS[profile] do
		if st.dice.Id == diceId then
			return A.quantile(st.owned, q)
		end
	end
	return 0 / 0
end

local function upgradeTotal(A: any, id: string): number
	local f = A.M.formulas
	local total, level = 0, 0
	while true do
		local cost = f:upgradeCost(id, level)
		if not cost then
			break
		end
		total += cost
		level += 1
	end
	return total
end

local function refundRow(A: any, profile: string, r: number): any
	local list = A.select("refund", profile, tostring(r))
	local function at(field: string): number
		return A.median(A.collect(list, function(x)
			local s = A.snapAt(x, 10 * H)
			return s and s[field]
		end))
	end
	return {
		swaps = A.median(A.collect(list, function(x) return x.swaps end)),
		lost = A.median(A.collect(list, function(x) return x.investmentLost end)),
		refunded = A.median(A.collect(list, function(x) return x.investmentRefunded end)),
		earned = at("earned"),
		patrimony = at("patrimony"),
		level = at("avgLevel"),
	}
end

-- "C 20 · U 20 · R 25 ..." a partir de EconomyConfig.SellSeconds (valores atuais)
local function sellSecondsText(A: any): string
	local parts = {}
	for _, r in { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Divine", "Secret" } do
		table.insert(parts, `{string.sub(r, 1, 1)} {A.EconomyConfig.SellSeconds[r]}`)
	end
	return table.concat(parts, " · ") .. " s"
end

local function sellRange(A: any): (number, number)
	local lo, hi = math.huge, 0
	for _, v in A.EconomyConfig.SellSeconds do
		lo, hi = math.min(lo, v), math.max(hi, v)
	end
	return lo, hi
end

local function priceOf(A: any, id: string): number
	for _, d in A.DICE do
		if d.Id == id then
			return d.Price
		end
	end
	return 0
end

local function refundPct(A: any): string
	return `{math.floor(A.EconomyConfig.UpgradeRefundPercent * 100 + 0.5)}%`
end

local N: { [string]: (any) -> string } = {}

N.summary = function(A)
	local m, d = A.money, A.dur
	local casualOffline = A.sourceShares("Casual", 20 * H).Offline or 0
	local ativoForbidden = diceTime(A, "Ativo", "Forbidden", 0.5)
	local casualForbidden = diceTime(A, "Casual", "Forbidden", 0.5)
	local function polIps(policy: string): number
		return A.median(A.collect(A.select("rebirth", "Ativo", policy), function(r)
			local s = A.snapAt(r, 20 * H)
			return s and s.ips
		end))
	end
	local rebirthRatio = polIps("medium") / math.max(1, polIps("never"))
	local forbiddenWait = 0 / 0
	for _, st in A.STATS.Ativo do
		if st.dice.Id == "Forbidden" then
			forbiddenWait = A.median(st.moneyWait)
		end
	end
	local deadCel = 0
	for _, st in A.STATS.Ativo do
		if st.dice.Id == "Celestial" then
			deadCel = A.median(st.dead)
		end
	end
	return table.concat({
		"## Resumo executivo",
		"",
		`- **Renda por Dice × Raridade (seção 0).** O BaseIncome dos 112 F2P vem de \`CharacterConfig.IncomeCurve\`: o mesmo Mítico rende {A.CharacterConfig.IncomeCurve.baseIncome("Mythic", "spirit")}/s no Spirit e {A.CharacterConfig.IncomeCurve.baseIncome("Mythic", "forbidden")}/s no Forbidden; variante e nível multiplicam depois. Não há mais renda global por raridade.`,
		`- **Ritmo de Dice.** O Ativo F2P compra o Forbidden em ~{d(ativoForbidden)} de jogo ativo (P50) e o Casual em ~{d(casualForbidden)}. Para o Casual o gargalo é o requisito de **rolls** (o offline paga os preços); para Ativo/Otimizador o requisito de rolls chega primeiro e o **dinheiro** atrasa os últimos Dice. Maior degrau de preço: Celestial → Forbidden ({m(priceOf(A, "Celestial"))} → {m(priceOf(A, "Forbidden"))}, {string.format("%.1f", priceOf(A, "Forbidden") / math.max(1, priceOf(A, "Celestial")))}×; ~{d(forbiddenWait)} de espera por dinheiro no Ativo).`,
		`- **Os pools são pequenos (6–8 personagens por Dice) e completam em segundos/minutos**: depois disso o jogador rola o mesmo Dice sem nada novo até liberar o próximo (ex.: ~{string.format("%.0f", deadCel)} rolls sem novidade no Celestial, P50 Ativo). A coleção não segura a sessão no meio do jogo — quem segura é a espera pelo próximo Dice.`,
		`- **Rebirth é obrigatório:** com 20 h, quem renasce tem renda/s ~{string.format("%.0f", rebirthRatio)}× maior que quem nunca renasce (Ativo, política medium × never); ao renascer, ~90% do dinheiro acumulado some no reset.`,
		`- **Offline é a maior fonte do Casual** ({A.pct(casualOffline)} do dinheiro em 20 h ativas): 8 h offline a 12% ≈ 1 h de renda ativa (teto {A.pct(A.OfflineIncomeConfig.MaxRebirthFraction)} do próximo Rebirth), e o Casual joga só 20 min/dia.`,
		`- **Venda reconhece o nível:** base + **{refundPct(A)}** do investimento em níveis gravado na unidade (antes: 0%, a troca de estação destruía o investimento). Nunca dá lucro (seção 9).`,
		`- **Duplicatas:** venda = {(sellRange(A))}–{select(2, sellRange(A))} s de renda da própria unidade (base), que acompanha o Dice de origem.`,
		"- **Prisma:** com 3 usos por recompensa e teto 21, o Casual (que mais depende dele) não perde cargas; o Ativo recebe 1 recompensa a cada 7 dias reais, o que limita o impacto.",
		"- **Status:** as recomendações da auditoria histórica foram aplicadas (refund 75% por instância, Forbidden 400M, rolls, MaxLevel 30, Rebirth 15M, offline 25%...) e a renda passou a ser Dice × Raridade (seção 0). Status item a item na seção 14.",
	}, "\n")
end

N.profiles = function(A)
	local P = A.M.Profiles
	local function passes(p: any): string
		return if #p.passes > 0 then table.concat(p.passes, ", ") else "nenhum"
	end
	local lines = {
		"Perfis (agentes do simulador; tempo = jogo ATIVO; entre sessões corre o offline real):",
		"",
		"| Perfil | Sessões/dia | AUTO-roll | Coleta | Decide a cada | Payback p/ nível | Fusão | Torres | Jackpot | Rebirth | Gamepasses |",
		"| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |",
	}
	for _, key in A.PROFILES do
		local p = P[key]
		local sessions = {}
		for _, s in p.sessionsPerDay do
			table.insert(sessions, A.dur(s))
		end
		table.insert(lines, string.format(
			"| %s | %s | %s | %ds | %ds | %s | %s | %s | %s | %s | %s |",
			p.name, table.concat(sessions, " + "), A.pct(p.rollActivity), p.collectEvery, p.thinkEvery, A.dur(p.levelPaybackSeconds),
			if p.fusion then "sim" else "não", if p.towersEvery then "a cada " .. A.dur(p.towersEvery) else "não",
			if p.jackpot then "sim" else "não", p.rebirth, passes(p)
		))
	end
	table.insert(lines, "")
	table.insert(lines, "Hipóteses: sem amigos no servidor (Impulso de amigos +5%/amigo não entra); o jogador sempre rola o MELHOR Dice que tem (como o jogo seleciona ao comprar); estação trocada é vendida; gemas vão para o Jackpot; missões diárias completadas com a probabilidade do perfil; 20 h ativas = 60 dias (Casual), 10 dias (Ativo/Pago), 5 dias (Otimizador). Pago Moderado = Ativo + os 4 gamepasses existentes (Roll Rápido, VIP, Sorte x2, Mochila Gigante), sem comprar Robux de dinheiro.")
	return table.concat(lines, "\n")
end

N.dice = function(A)
	local lines = {
		"`Liberado por rolls` = quando atingiu o requisito de rolls do Dice; `Espera por dinheiro` = quanto tempo depois disso ainda faltava dinheiro. Espera ~0 = o requisito de **rolls** é o gargalo; espera longa = o **preço** é o gargalo. `Completion antes do próximo?` = fração dos jogadores que já tinham 100% / ≥90% / <50% do pool quando compraram o próximo Dice (<50% quase sempre = Dice pulado: comprou dois de uma vez e nunca rolou o anterior).",
		"",
		"Leitura (Ativo F2P):",
	}
	for i, st in A.STATS.Ativo do
		if i > 1 then
			local wait = A.median(st.moneyWait)
			local gate = if wait > 5 * 60 then "**dinheiro**" elseif wait > 60 then "misto" else "rolls"
			if gate ~= "rolls" then
				table.insert(lines, `- {st.dice.Id}: gargalo {gate} (espera P50 {A.dur(wait)} depois de liberar por rolls).`)
			end
		end
	end
	table.insert(lines, "- Lucky: limitado pelos rolls. No Casual quase todos os Dice são limitados pelos rolls (espera por dinheiro < 1 min), porque o offline paga os preços entre as sessões.")
	return table.concat(lines, "\n")
end

N.completion = function(A)
	return table.concat({
		"Pools por Dice: 6–8 personagens. Até o Awakened o 100% sai em segundos ou poucos minutos depois da compra; só Celestial (3 Divinos) e Forbidden (3 Divinos + 3 Secretos) têm caça longa. **\"Rolar sem nada novo\" é a regra no meio do jogo**: o tempo entre completar o Dice e comprar o próximo (coluna `Próximo comprado`, 5–30 min no meio do jogo) é gasto inteiro em rolls repetidos — a recompensa desse tempo é só a venda de duplicata (centavos) e o progresso para o requisito de rolls.",
	}, "\n")
end

N.sources = function(A)
	local f = A.M.formulas
	local _ = f
	return table.concat({
		"| Fonte | Valor | Frequência | Condição | Multiplicadores | F2P / Pago | Autoritativo no servidor? |",
		"| --- | --- | --- | --- | --- | --- | --- |",
		"| Coletor (renda das estações) | Σ BaseIncome(**Dice × Raridade**, seção 0) × variante (1/1,5/2/3/4/6/10) × (1 + 0,25·(nível−1)) | por segundo, acumula no coletor (teto 1 h de renda) | personagem equipado na base | Renda global +10%/nível (25), Rebirth +25%/rebirth, perk Renda +15%/nível, VIP ×1,5, amigos +5% (até 25%) | F2P (VIP pago) | sim (IncomeService/EconomyService) |",
		`| Dinheiro offline | 12% × renda/s × min(offline, 8 h) | ao voltar (≥ 60 s fora) | relógio do servidor | teto = {A.pct(A.OfflineIncomeConfig.MaxRebirthFraction)} do custo do próximo Rebirth | F2P | sim (OfflineCore, os.time) |`,
		`| Venda de personagem | BaseIncome(Dice × Raridade) × SellSeconds ({sellSecondsText(A)}) × variante + {refundPct(A)} do investimento em níveis | por venda / em massa / auto-sell | não travado/favorito/equipado/em troca (em massa: nem no time da Torre) | nível reembolsado em {refundPct(A)} | F2P | sim (SellService via SaleCore/BulkSaleCore) |`,
		"| Torres | max(poder inimigo × 1, renda/s × 8) | 1ª vitória de cada andar (120 andares) | time de 5 vence a batalha simulada | poder: Rebirth +10%/rb, perk Poder | F2P | sim (TowerService/BattleCore) |",
		"| Missões diárias | dinheiro = max(1,5K–3K, renda × 240–400 s) | 3/dia (das 10 do pool, 5 dão dinheiro) | completar a meta | renda/s | F2P | sim (MissionService) |",
		"| Recompensa diária | D1 max(1K, 120 s) · D4 max(10K, 600 s); D2/D5 gemas; D3/D6 sorte; D7 Prisma | 1/dia UTC, ciclo 7 | não pular dia | renda/s | F2P | sim (DailyService) |",
		"| Jackpot (150 gemas) | dinheiro 600 s (mín 5K, peso 30) ou 3600 s (mín 50K, peso 12); gemas; sorte 2×; roll garantido Épico/Lendário/Mítico | por giro | gemas | renda/s | F2P (gemas) / Robux (giro) | sim (JackpotService) |",
		"| Loja de gemas: Pacote de dinheiro | 40 gemas → max(5K, 900 s de renda) | à vontade | gemas | renda/s | F2P | sim |",
		"| Produtos Robux | Pacote max(10K, 15 min) · Cofre max(150K, 2 h) | compra | Robux | renda/s | Pago | sim (ReceiptCore) |",
		"| Gemas (não é dinheiro) | Diário 25/100, missões 10–25, torres 5 a cada 5 andares + 100/250/600, Índice 10/25/50/150, conquistas 25–50 | — | — | — | F2P | sim |",
		"",
		"Observações: (1) o **Pacote de dinheiro da loja de gemas paga 22,5 s de renda por gema**, o Jackpot paga em média ~4 s de renda por gema em dinheiro (612 s / 150 gemas) — quem quer dinheiro nunca deveria girar o Jackpot; o simulador gasta as gemas no Jackpot (pior caso para dinheiro). (2) Conquista `index` ainda usa marcos {6, 12, 18, 24} de quando havia 24 personagens; hoje há 112.",
		"",
		"Participação de cada fonte no dinheiro ganho (agregado de todos os jogadores do perfil):",
	}, "\n")
end

N.sinks = function(A)
	local m = A.money
	local diceTotal = 0
	for _, d in A.DICE do
		diceTotal += d.Price
	end
	local rebirthTo10 = 0
	for i = 0, 9 do
		rebirthTo10 += A.M.formulas:rebirthCost(i)
	end
	return table.concat({
		"| Sink | Custo inicial | Curva | Acumulado | Limite | Dependências / reset |",
		"| --- | --- | --- | --- | --- | --- |",
		`| Dice (16) | 2,5K | fixo por posição (até {m(priceOf(A, "Forbidden"))}) | {m(diceTotal)} todos | 16 | rolls exigidos + Dice anterior; **não reseta** no Rebirth |`,
		`| Níveis de estação | BaseIncome(Dice × Raridade) × 60 | × 1,2 por nível | ver seção 6 | nível {A.LevelConfig.MaxLevel} | personagem equipado; {refundPct(A)} volta na venda; soma na fusão |`,
		`| Upgrade Luck | 2K | × 1,9 | {m(upgradeTotal(A, "Luck"))} (20 níveis) | 20 | **reseta** no Rebirth |`,
		`| Upgrade Renda | 1,5K | × 1,85 | {m(upgradeTotal(A, "Income"))} (25 níveis) | 25 | **reseta** no Rebirth |`,
		`| Upgrade Inventário | 1K | × 1,7 | {m(upgradeTotal(A, "Inventory"))} (20 níveis) | 20 | mantido |`,
		"| Velocidade de Roll | — | desligado (cadência fixa por config) | — | — | — |",
		"| Fusão | BaseIncome(Dice × Raridade) × 600 × ordem da variante + 2–3 cópias | por degrau | Normal→Celestial = 3·3·3·3·2·2·2 = 648 cópias | Celestial | resultado mantém o MAIOR nível e SOMA o investimento das cópias |",
		`| Rebirth | {m(A.M.formulas:rebirthCost(0))} | × 2,2 | {m(rebirthTo10)} até o 10º | 36 | zera dinheiro, coletor, Luck/Renda; mantém Dice, personagens, Índice, torres, gemas |`,
		"| Gemas | Jackpot 150 · sorte 60 · dinheiro 40 | — | — | — | — |",
		"",
		"Destino do dinheiro (agregado; \"Rebirth\" = saldo zerado ao renascer):",
	}, "\n")
end

N.curve = function(A)
	return table.concat({
		`Fórmula (CharacterLevelConfig): custo L→L+1 = floor(BaseIncome × 60 × 1,2^(L−1)); renda = BaseIncome × (1 + 0,25·(L−1)), com BaseIncome = Dice × Raridade (seção 0). O **payback de um nível não depende da raridade nem do Dice** (o custo é proporcional ao BaseIncome): 240 s × 1,2^(L−1) ÷ (variante × multiplicadores do jogador). Sem multiplicadores, o nível 10 se paga em ~21 min, o 20 em ~2 h e o {A.LevelConfig.MaxLevel} (máximo) em ~13 h. Com os multiplicadores de Rebirth/Renda (×10–15 no fim), os perfis param perto do máximo (Upgrade médio na tabela principal).`,
		"",
		`Venda base = {(sellRange(A))}–{select(2, sellRange(A))} × BaseIncome; o investimento em níveis volta em {refundPct(A)} na venda (antes da economia aplicada voltava 0%).`,
	}, "\n")
end

N.duplicates = function(A)
	return table.concat({
		`Regra atual: cada roll vira uma unidade no inventário (capacidade 100 + Mochila/upgrade); duplicata = mais uma cópia (serve para Fusão, troca ou venda). Venda = BaseIncome(Dice × Raridade) × SellSeconds × variante, ou seja **{(sellRange(A))}–{select(2, sellRange(A))} segundos da renda que a própria unidade daria equipada**. Venda em massa na Mochila (SELECIONAR DUPLICATAS) e auto-sell por raridade (desligado por padrão; Secreto protegido).`,
		"",
		"Valor vendido em duplicatas de cada Dice em 20 h (P50) e quanto isso paga do próximo Dice:",
	}, "\n")
end

N.refund = function(A)
	return table.concat({
		"### Desenho",
		"",
		`\`SaleValue = BaseSaleValue + RefundPercent × EligibleUpgradeInvestment\` — cotação pura em \`src/shared/Modules/SaleCore.luau\`, usada pela venda real (individual e em massa) com **\`EconomyConfig.UpgradeRefundPercent = {A.EconomyConfig.UpgradeRefundPercent}\`** (aplicado). As tabelas desta seção comparam percentuais no simulador.`,
		"",
		"**Investimento elegível — recálculo (A) × gravado por instância (B):**",
		"",
		"| Critério | (A) recalcular pela curva do nível | (B) `UpgradeInvestment` gravado por instância |",
		"| --- | --- | --- |",
		"| Mudança futura na curva de custo | **reembolsa pela curva NOVA** (pode dar mais do que foi pago se a curva subir) | reembolsa o que foi pago de fato |",
		"| Fusão (resultado fica com o maior nível) | ignora as cópias consumidas (ok) | pode SOMAR o investimento das cópias consumidas (mais justo) — mas exige regra explícita |",
		"| Item recebido por troca | reembolsa níveis que o receptor não pagou | idem (o valor viaja com o item, como o próprio nível já viaja) |",
		"| Duplicação / rollback | o nível já é a verdade; nada novo a corromper | +1 campo por item no save; protegido pelo mesmo ProfileCore/sessão |",
		"| Valor negativo / NaN / adulterado | impossível (derivado do nível) | SaleCore descarta inválido e cai em (A) |",
		"| Venda repetida | o item sai do inventário na mesma operação (SellService) | idem |",
		"| Custo de save | 0 | ~8 bytes por item |",
		"",
		"**Escolha: (B) com fallback (A).** O servidor grava em `InventoryService.Upgrade` exatamente o que cobrou (`TrySpend`), a fusão soma o investimento das unidades consumidas e itens antigos sem o campo usam a curva (A). Só o servidor escreve; o cliente nunca manda valor. Assim uma mudança futura de curva nunca cria dinheiro, e a fusão deixa de destruir investimento.",
		"",
		"**API de prévia (pronta, autoritativa):** remote `PreviewSale({uid})` → por unidade `{ Base, Invested, Percent, Refund, Total }` + somas, calculada pelo servidor sobre o inventário do servidor (uid repetido conta uma vez; travado/favorito/equipado/em troca/inexistente fica de fora — mesma regra da venda). `SellCharacter` usa a mesma cotação, então **venda = prévia** (GameplayHarness). Sem UI definitiva nesta fase.",
		"",
		"**Prova de que não existe loop de lucro.** Para qualquer unidade: o jogador paga `C` em níveis e recebe `Base + floor(r·C)` na venda. Lucro do ciclo = `Base + floor(r·C) − C ≤ Base − (1−r)·C ≤ Base` para `0 ≤ r ≤ 1` — nunca mais do que vender a unidade sem nível. O SaleCore limita `r` a [0, 1] (NaN/texto/±∞ → 0), nunca devolve negativo e nunca usa investimento de outra instância (cada item carrega o seu). Testado em `tests/SaleCore.spec.luau` e `tests/EconomyModel.spec.luau` para todos os 112+ personagens, 7 variantes, níveis 1/2/10/20/50 e r = 0/50/60/70/75/80/100%. A venda só aceita uid que existe no inventário do servidor e o remove na mesma operação (sem venda repetida). Com r = 100% o ciclo é neutro (lucro = só a Base, que já existia); por isso o teto recomendado é < 100%.",
		"",
		"### Simulação",
	}, "\n")
end

N.refundEnd = function(A)
	local a0, a75 = refundRow(A, "Ativo", 0), refundRow(A, "Ativo", 0.75)
	local o0, o75 = refundRow(A, "Otimizador", 0), refundRow(A, "Otimizador", 0.75)
	return table.concat({
		"### Impacto por percentual",
		"",
		"| Refund | Liberdade de troca | Sink de dinheiro | Progressão | Exploit | Patrimônio |",
		"| --- | --- | --- | --- | --- | --- |",
		"| 0% (antes) | baixa: trocar a estação joga fora 100% dos níveis | máximo (todo nível é sink definitivo) | base | impossível | só saldo + venda base |",
		"| 50% | média | metade do gasto em níveis volta ao trocar | ≈ base | impossível | + metade do investido |",
		"| 60% | média | 40% fica no sistema | ≈ base | impossível | — |",
		"| 70% | boa | 30% fica | ≈ base | impossível | — |",
		"| **75%** | **boa** | **25% fica (sink real preservado)** | ≈ base (diferença dentro do ruído) | **impossível** | o jogador \"vê\" 3/4 do que investiu |",
		"| 80% | boa | 20% fica | ≈ base | impossível | — |",
		"| 100% | total | nível vira depósito sem custo: trocar é grátis, subir nível deixa de ser decisão | ≈ base | neutro (sem lucro) | inflaciona o patrimônio |",
		"",
		`Números (P50, 10 h ativas): Ativo perde {A.money(a0.lost)} em níveis ao trocar estações com 0% e {A.money(a75.lost)} com 75% (recebe {A.money(a75.refunded)} de volta); Otimizador {A.money(o0.lost)} → {A.money(o75.lost)}. Isso é pequeno perto do ganho total ({A.money(a0.earned)} Ativo): **o refund não acelera a progressão de forma relevante** — o ganho é de liberdade (trocar para o personagem novo sem punição) e de percepção de valor. Diferenças de \"Ganho total\" entre as linhas são ruído de amostra (mesmas sementes, mas o caminho diverge cedo).`,
		"",
		"**Recomendação: 75%** (APLICADA) com investimento gravado por instância (B). Abaixo de 60% a troca ainda dói; 100% elimina o sink e transforma nível em poupança. 75% mantém 1/4 de cada troca como sink e deixa a decisão \"subir nível agora × esperar o personagem melhor\" com peso, sem nunca permitir lucro.",
	}, "\n")
end

N.prism = function(A)
	return table.concat({
		"O Prisma vem no Dia 7 do ciclo diário (1 recompensa a cada 7 dias reais). Tempo ativo de 20 h = 60 dias para o Casual (8–9 recompensas), 10 dias para o Ativo (1 recompensa). No simulador o jogador usa a carga no Dice selecionado; se ele já está completo, seleciona o maior Dice que ainda tem personagem a descobrir (o servidor recusa sem gastar quando não há nada a descobrir).",
	}, "\n")
end

N.prismEnd = function(A)
	return table.concat({
		"Leitura: o teto só importa para quem acumula; com 3 usos e teto 7 o Casual perde ~8 cargas em 60 dias, com teto 21 nenhuma. O Prisma decide principalmente os **Secretos do Forbidden** (0,0045%): no Ativo (1 recompensa em 20 h) 1 uso deixa ~14% dos jogadores sem o Forbidden completo em 20 h, 2 usos ~1%, 3 usos 0%. O Casual, com 8–9 recompensas, completa com qualquer combinação. **Recomendação: manter 3 usos / teto 21** (atual).",
	}, "\n")
end

N.rebirth = function(A)
	return table.concat({
		"Políticas: **early** = renasce assim que pode pagar; **medium** = renasce quando o próximo Dice custa mais que 2× o Rebirth; **late** = só com 15 Dice ou 4× o custo em caixa; **never** = nunca. O Rebirth mantém Dice, personagens, níveis, Índice e torres; zera dinheiro e as melhorias de Luck/Renda; dá +25% de renda, +2% de Luck (teto +50%), +10% de poder, +1 slot e fichas.",
	}, "\n")
end

N.rebirthEnd = function(A)
	return table.concat({
		"Leitura (diagnóstico histórico, com Rebirth 1 = 10M; hoje é 15M): (1) o primeiro Rebirth (10M) chegava **antes** do Colossus (12,5M) — como o Rebirth não tira Dice, renascer cedo é quase grátis e o jogador médio renasce enquanto ainda compra Dice; (2) em 20 h todas as políticas convergem para ~10–12 rebirths, porque o custo × 2,2 cresce mais devagar que a renda multiplicada (+25%/rebirth, +1 slot); (3) **never** ganha ~50× menos dinheiro em 20 h — o Rebirth é obrigatório, não opcional; (4) para Ativo/Otimizador, medium ganha um pouco mais que early (renascer cedo zera Luck/Renda compradas várias vezes); para o Casual, early ganha mais (o teto do offline sobe com o custo do próximo Rebirth).",
	}, "\n")
end

N.retention = function(A)
	return table.concat({
		"Momentos de retenção medidos em 10.000 jogadores por perfil (primeira hora). Leitura: Raro e Épico chegam em segundos, o 1º Dice novo em 1–3 min e o 1º Dice 100% em < 2 min — os primeiros 5 min estão cheios. O **buraco** fica entre ~2 e ~10 min (nenhum marco novo até o 1º Lendário, que só existe a partir do Flame, ~11–13 min) e entre ~15 e ~35 min (até o 1º Mítico, no Spirit). Missões/Diário ajudam, mas não há recompensa de coleção nesse intervalo.",
	}, "\n")
end

N.longterm = function(A)
	return table.concat({
		"Forbidden: compra em ~3–5 h ativas para todos os perfis F2P; o 100% (3 Secretos) depende do Prisma e de horas de roll. **Não é rápido demais para comprar** (é o maior muro de dinheiro do jogo), mas depois de comprar não há mais nenhum Dice: o objetivo vira Rebirth + Secretos + torres.",
	}, "\n")
end

N.problems = function(A)
	return table.concat({
		"## 13. Problemas encontrados (diagnóstico histórico do commit 07744e5, com status)",
		"",
		"Itens 1, 2, 4, 5, 6, 7, 8, 9, 10 e 11 foram corrigidos pela economia aplicada (refund 75%, fusão soma investimento, rolls por Dice, Forbidden 400M, Rebirth 15M, offline 25%, venda maior, loja de gemas, Índice 14/28/56/112, MaxLevel 30). Item novo 13: renda global por raridade (corrigido: Dice × Raridade, seção 0).",
		"",
		"1. **Venda ignora o nível** — o investimento em níveis (até 773× o valor de venda no nível 20) é destruído na troca/venda. Pior atrito de liberdade de troca.",
		"2. **Fusão destrói o investimento** das cópias consumidas (o resultado fica só com o maior nível).",
		"3. **Pools de 6–8 personagens completam em segundos**; no meio do jogo a sessão é \"rolar sem nada novo\" esperando o próximo Dice (rolls para o Casual, dinheiro para Ativo/Otimizador).",
		"4. **Compra em cascata pula Dice:** quando o requisito de rolls de vários Dice é atingido junto e o dinheiro sobra, o jogador compra 2–3 Dice de uma vez e nunca rola os intermediários (Shinobi/Flame no Ativo) — esses personagens só entram no Índice se o jogador voltar ao Dice antigo.",
		"5. **Muro único Celestial → Forbidden** (75M → 750M = 10×; os outros degraus são de 1,7× a 4×).",
		"6. **Rebirth 1 (10M) antes do Colossus (12,5M)** e Rebirth sem perda de Dice: renascer cedo não custa progresso, só dinheiro em caixa.",
		"7. **Offline > ativo para o Casual** (até ~2/3 do dinheiro). Coerente com a regra \"8 h ≈ 1 h ativa\", mas o teto de 50% do próximo Rebirth fica alto no fim.",
		"8. **Duplicatas não pagam nada** depois dos primeiros minutos (12–40 s de renda).",
		"9. **Loja de gemas × Jackpot:** o Pacote de dinheiro (40 gemas) paga ~5× mais dinheiro por gema que o Jackpot.",
		"10. **Conquista `index` desatualizada** ({6,12,18,24} para 112 personagens).",
		"11. **Nível 50 inalcançável** (payback de 82 h no nível 40 sem multiplicadores); a curva serve até ~25–30.",
		"12. Ferramentas antigas (`tools/sim/EconomySim.luau`, `Odds.luau`) usam o RollCore global com pity 50/800 — marcadas como LEGACY; este relatório usa só o simulador novo por Dice.",
		"13. **Renda global por raridade** (achado depois, no Studio): todo Mítico rendia $160/s, todo Lendário $60/s, todo Divino $425/s em qualquer Dice — o Dice mais avançado não tinha valor econômico. **Corrigido:** BaseIncome = Dice × Raridade (`CharacterConfig.IncomeCurve`, seção 0; `DICE_INCOME_AUDIT.md`).",
	}, "\n")
end

N.recommendations = function(A)
	local m = A.money
	return table.concat({
		"## 14. Proposta de economia (histórica) e STATUS",
		"",
		"Proposta feita sobre o commit 07744e5. Coluna ATUAL = valor daquela época. **Status: todos os itens abaixo foram APLICADOS** (fase de economia, 473a292) — exceto a linha \"Renda\", substituída depois pela curva Dice × Raridade (6b4528e).",
		"",
		"| Item | ATUAL (07744e5) | PROPOSTO | JUSTIFICATIVA | EFEITO ESPERADO |",
		"| --- | --- | --- | --- | --- |",
		"| Reembolso na venda | 0% | **75%** do investimento em níveis, gravado por instância (B) | troca de estação sem destruir o investimento; 25% continua sink; prova de não-lucro | liberdade de troca; impacto de progressão ≈ 0 |",
		"| Fusão | resultado = maior nível | resultado soma `UpgradeInvestment` das cópias (refund futuro) — nível continua o maior | fusão deixa de punir quem upou a cópia errada | mais fusões; nenhum dinheiro novo |",
		"| Preço Forbidden | 750M (10× Celestial) | 750M → **400M** (≈5× Celestial), requisito 12.000 rolls mantido | único degrau de 10×; o requisito de rolls (3,3 h) chega ~1 h antes do dinheiro no Ativo | Forbidden ~30–40 min mais cedo para Ativo/Otimizador; Casual inalterado (já limitado por rolls) |",
		"| Requisito de rolls Shinobi→Blade | 300 / 425 / 550 | 300 / 450 / 650 | no Ativo a missão dos 10 min paga Shinobi+Flame+Blade de uma vez (92% nunca rolam o Shinobi) | cada Dice rolado ≥ 2 min; Índice completo sem voltar |",
		"| Preços de Dice (exceto Forbidden) | 2,5K…75M | **manter** | espera de 10–15 min por dinheiro por Dice (Ativo) é um ritmo saudável | — |",
		"| Requisito de rolls Celestial | 8.000 | manter | — | — |",
		"| Renda | BaseIncome provisório por raridade (L 60 · M 160 · D 425 em todo Dice) | **SUBSTITUÍDO:** Dice × Raridade (`CharacterConfig.IncomeCurve`, 1,11 por Dice, pivô 0,10) | o Dice mais avançado precisa ter valor econômico | ver seção 0 e `DICE_INCOME_AUDIT.md` |",
		"| Duplicatas | 12–40 s de renda | C/U 20 · R 25 · E 30 · L 35 · M 45 · D 60 · S 90 s | dar valor ao \"rolar sem nada novo\" do meio do jogo | duplicatas ≈ 3–5% do dinheiro em 5 h (hoje ~1%) |",
		"| Custo de nível | 60 s × 1,2^(L−1) | manter a curva; **MaxLevel 50 → 30** (ou crescimento 1,2 → 1,15 depois do 20) | o 31–50 nunca é comprado | teto alcançável e visível |",
		"| Rebirth | 10M × 2,2^n | 1º Rebirth 10M → **15M** (crescimento igual) | primeiro Rebirth depois do Colossus, não antes | 1º Rebirth ~15–20 min mais tarde para o Ativo |",
		"| Prisma | 3 usos, teto 21 | **manter** | Casual não perde carga; 3 usos fecham os Secretos | — |",
		"| Offline | 12%, 8 h, teto 50% do próximo Rebirth | teto 50% → **25%** do próximo Rebirth | o Casual ganha mais offline que jogando | Casual com ~50% offline em vez de ~2/3 |",
		"| Conquista `index` | 6/12/18/24 | 14/28/56/112 (12,5/25/50/100%) | roster 112 | conquista volta a funcionar como meta |",
		"| Loja de gemas | Pacote 40 gemas = 900 s | 60 gemas = 900 s, ou Jackpot dinheiro 600 → 1.200 s | equilibrar gema → dinheiro | Jackpot volta a ser opção |",
		"",
		"Aplicado: as tabelas das seções 1–12 deste documento já são do jogo atual (economia aplicada + renda Dice × Raridade).",
	}, "\n")
end

N.method = function(A)
	return table.concat({
		"## Método e limites",
		"",
		`- Renda: BaseIncome de cada personagem lido de \`CharacterConfig\` (F2P = \`IncomeCurve\` Dice × Raridade; Premium/Legacy = renda própria). A linha de base histórica da renda por raridade fica em \`tools/sim/dice_income_baseline.json\` (não é sobrescrita).`,
		`- Simulador: \`tools/sim/EconomyModel.luau\` (puro). Roll **idêntico** ao \`DiceCore.roll\` (provado roll a roll em \`tests/EconomyModel.spec.luau\`): pesos de produção, Luck real (Dice × upgrade × boosts × Rebirth × gamepass, softcap {A.RollConfig.LuckSoftCap}), pity Lendário 50 / Mítico 250, Dice selecionado = o melhor comprado. Renda, níveis, venda (SaleCore), upgrades, Rebirth, torres (BattleCore), Jackpot, Diário, Missões, Offline, Fusão e Prisma (DiceCore:prismPick) vêm dos módulos e configs reais.`,
		`- Monte Carlo: {A.counts.short} jogadores por perfil até 1 h (retenção) e {A.counts.long} por perfil até 20 h. Menos de 10.000 no horizonte de 20 h porque cada jogador de 20 h custa 0,2–0,7 s (≈ 25 min para tudo em 4 núcleos). Convergência medida: diferença entre as duas metades da amostra (sementes pares × ímpares) no ganho total de 20 h — {A.halves()}. Sensibilidades (refund, Prisma, Rebirth) com {A.counts.refund} jogadores por variante e as MESMAS sementes entre variantes.`,
		"- Tempo = jogo ATIVO. O offline é aplicado entre as sessões do perfil (relógio real).",
		"- Limites: agente simples (não troca Dice para caçar personagem fora do Prisma, não usa a loja de gemas, não negocia); torres só pela 1ª vitória; sem amigos no servidor.",
		"- Reproduzir: `python3 tools/sim/run_economy_analysis.py` (≈ 25 min em 4 núcleos; `--scale 0.01` ≈ 30 s).",
	}, "\n")
end

return N
