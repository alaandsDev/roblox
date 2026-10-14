# ROLL LEGENDS — Auditoria e balanceamento da economia

> Gerado por `python3 tools/sim/run_economy_analysis.py` (simulador `tools/sim/EconomyModel.luau`).
> **Tabelas e números = jogo ATUAL** (lidos dos configs/módulos reais na hora de gerar): economia
> aplicada (refund 75%, MaxLevel 30, Forbidden 400M, Rebirth 15M, offline 25%...) e **renda por Dice ×
> Raridade** (`CharacterConfig.IncomeCurve`, ver seção 0 e `DICE_INCOME_AUDIT.md`). As seções 13 e 14 guardam
> o diagnóstico HISTÓRICO (commit 07744e5) que motivou essas mudanças, com o status de cada item.

Amostra: 10000 jogadores/perfil até 1 h · 2000 jogadores/perfil até 20 h · 150 por variante de refund · 150 por variante de Prisma · 150 por política de Rebirth.

## Resumo executivo

- **Renda por Dice × Raridade (seção 0).** O BaseIncome dos 112 F2P vem de `CharacterConfig.IncomeCurve`: o mesmo Mítico rende 149/s no Spirit e 309/s no Forbidden; variante e nível multiplicam depois. Não há mais renda global por raridade.
- **Ritmo de Dice.** O Ativo F2P compra o Forbidden em ~4.0 h de jogo ativo (P50) e o Casual em ~4.8 h. Para o Casual o gargalo é o requisito de **rolls** (o offline paga os preços); para Ativo/Otimizador o requisito de rolls chega primeiro e o **dinheiro** atrasa os últimos Dice. Maior degrau de preço: Celestial → Forbidden (75.00M → 400.00M, 5.3×; ~40.2 min de espera por dinheiro no Ativo).
- **Os pools são pequenos (6–8 personagens por Dice) e completam em segundos/minutos**: depois disso o jogador rola o mesmo Dice sem nada novo até liberar o próximo (ex.: ~3858 rolls sem novidade no Celestial, P50 Ativo). A coleção não segura a sessão no meio do jogo — quem segura é a espera pelo próximo Dice.
- **Rebirth é obrigatório:** com 20 h, quem renasce tem renda/s ~37× maior que quem nunca renasce (Ativo, política medium × never); ao renascer, ~90% do dinheiro acumulado some no reset.
- **Offline é a maior fonte do Casual** (67% do dinheiro em 20 h ativas): 8 h offline a 12% ≈ 1 h de renda ativa (teto 25% do próximo Rebirth), e o Casual joga só 20 min/dia.
- **Venda reconhece o nível:** base + **75%** do investimento em níveis gravado na unidade (antes: 0%, a troca de estação destruía o investimento). Nunca dá lucro (seção 9).
- **Duplicatas:** venda = 20–90 s de renda da própria unidade (base), que acompanha o Dice de origem.
- **Prisma:** com 3 usos por recompensa e teto 21, o Casual (que mais depende dele) não perde cargas; o Ativo recebe 1 recompensa a cada 7 dias reais, o que limita o impacto.
- **Status:** as recomendações da auditoria histórica foram aplicadas (refund 75% por instância, Forbidden 400M, rolls, MaxLevel 30, Rebirth 15M, offline 25%...) e a renda passou a ser Dice × Raridade (seção 0). Status item a item na seção 14.


## 0. Fonte de verdade da renda: BaseIncome → Dice + Raridade

A renda de uma estação é calculada nesta ordem (`Formulas:unitIncome` / `stationIncome`):

1. **BaseIncome → Dice + Raridade** (personagens F2P): `CharacterConfig.IncomeCurve` é a fonte ÚNICA.
   BaseIncome = Anchor[raridade] × 1.11 ^ (ordem do Dice − pivô), pivô = 1ª ordem da raridade + 0.1 × (última − 1ª).
   Não existe mais renda global por raridade: o mesmo Mítico rende mais num Dice mais avançado.
2. **VariantMultiplier → aplicado depois:** × `VariantConfig.IncomeMultiplier` (Normal 1 … Celestial 10).
3. **LevelMultiplier → aplicado depois:** × (1 + 0.25 × (Nível − 1)), nível máximo 30.
4. Na estação, × multiplicadores globais (upgrade Renda, Rebirth, perk, VIP, amigos).

Derivados do BaseIncome (mesma proporção, sem arbitragem nova): custo de nível (BaseIncome × 60 s × 1.2^(Nível−1)), venda (BaseIncome × SellSeconds × variante + 75% do investimento), custo de fusão.

**Premium e Legacy continuam com renda própria:** os 9 personagens Premium (fora dos Dice F2P) e os 24 legados do protótipo
(fora do roll e do Índice) mantêm o `BaseIncome` definido no próprio cadastro; a curva só se aplica aos 112 F2P.

Anchor (renda aprovada da raridade): Common 1 · Uncommon 4 · Rare 9 · Epic 25 · Legendary 60 · Mythic 160 · Divine 425 · Secret 1200.

BaseIncome Nível 1, variante Normal ("-" = raridade inexistente no Dice):

| # | Dice | Common | Uncommon | Rare | Epic | Legendary | Mythic | Divine | Secret |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Starter | 1 | 3.8 | 8.2 | 22 | - | - | - | - |
| 2 | Lucky | 1.1 | 4.2 | 9.1 | 24 | - | - | - | - |
| 3 | Rampart | 1.2 | 4.6 | 10 | 27 | - | - | - | - |
| 4 | Shinobi | 1.3 | 5.1 | 11 | 30 | - | - | - | - |
| 5 | Flame | - | 5.7 | 12 | 33 | 54 | - | - | - |
| 6 | Blade | - | 6.3 | 14 | 37 | 60 | - | - | - |
| 7 | Fighter | - | 7 | 15 | 41 | 67 | - | - | - |
| 8 | Storm | - | - | 17 | 46 | 74 | - | - | - |
| 9 | Spirit | - | - | 19 | 51 | 82 | 149 | - | - |
| 10 | Arcane | - | - | 21 | 56 | 91 | 165 | - | - |
| 11 | Shadow | - | - | - | 63 | 101 | 183 | - | - |
| 12 | Void | - | - | - | 70 | 112 | 203 | 408 | - |
| 13 | Colossus | - | - | - | 77 | 125 | 226 | - | - |
| 14 | Awakened | - | - | - | - | 138 | 251 | - | - |
| 15 | Celestial | - | - | - | - | 153 | 278 | 557 | - |
| 16 | Forbidden | - | - | - | - | - | 309 | 619 | 1200 |

Antes desta curva o catálogo usava valores provisórios iguais em todo Dice (Lendário 60, Mítico 160, Divino 425...).
Comparação antes/depois, tempo por Dice e testes: `DICE_INCOME_AUDIT.md`; linha de base histórica "antes":
`tools/sim/dice_income_baseline.json` (não é sobrescrita). Testes: `tests/DiceIncome.spec.luau`.


## 1. Tabela principal por perfil (P50; entre colchetes P10–P90)

Perfis (agentes do simulador; tempo = jogo ATIVO; entre sessões corre o offline real):

| Perfil | Sessões/dia | AUTO-roll | Coleta | Decide a cada | Payback p/ nível | Fusão | Torres | Jackpot | Rebirth | Gamepasses |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Casual F2P | 20.0 min | 70% | 180s | 60s | 10.0 min | não | a cada 15.0 min | não | early | nenhum |
| Ativo F2P | 1.0 h + 1.0 h | 100% | 30s | 15s | 20.0 min | sim | a cada 5.0 min | sim | medium | nenhum |
| Otimizador F2P | 2.0 h + 2.0 h | 100% | 10s | 5s | 30.0 min | sim | a cada 2.0 min | sim | medium | nenhum |
| Pago Moderado | 1.0 h + 1.0 h | 100% | 30s | 15s | 20.0 min | sim | a cada 5.0 min | sim | medium | FastRoll, VIP, LuckX2, BigBackpack |

Hipóteses: sem amigos no servidor (Impulso de amigos +5%/amigo não entra); o jogador sempre rola o MELHOR Dice que tem (como o jogo seleciona ao comprar); estação trocada é vendida; gemas vão para o Jackpot; missões diárias completadas com a probabilidade do perfil; 20 h ativas = 60 dias (Casual), 10 dias (Ativo/Pago), 5 dias (Otimizador). Pago Moderado = Ativo + os 4 gamepasses existentes (Roll Rápido, VIP, Sorte x2, Mochila Gigante), sem comprar Robux de dinheiro.

### Casual F2P

| Tempo ativo | Dice | Money (saldo) | Ganho total | Renda/s | Index (/112) | Rebirth | Upgrade médio (nível) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 10 min | Shinobi (4) [4–4] | 68.69K | 89.65K / 153.06K / 232.24K | 222 | 29 / 30 / 30 | 0 / 0 / 0 | 3.8 |
| 30 min | Storm (8) [8–8] | 3.33M | 3.63M / 5.23M / 5.85M | 1.04K | 58 / 58 / 58 | 0 / 0 / 0 | 9.0 |
| 1 h | Shadow (11) [10–11] | 6.71M | 14.41M / 15.80M / 17.31M | 3.04K | 73 / 73 / 80 | 0 / 0 / 0 | 9.0 |
| 3 h | Awakened (14) [14–14] | 38.01M | 271.64M / 398.78M / 464.52M | 50.74K | 98 / 98 / 98 | 3 / 4 / 4 | 14.0 |
| 5 h | Forbidden (16) [15–16] | 300.37M | 1.82B / 2.21B / 2.74B | 150.57K | 105 / 109 / 111 | 5 / 6 / 6 | 17.0 |
| 10 h | Forbidden (16) [16–16] | 6.71B | 22.96B / 25.46B / 29.04B | 463.23K | 112 / 112 / 112 | 9 / 9 / 9 | 19.0 |
| 20 h | Forbidden (16) [16–16] | 44.01B | 110.23B / 124.00B / 142.43B | 818.43K | 112 / 112 / 112 | 11 / 11 / 11 | 20.0 |

### Ativo F2P

| Tempo ativo | Dice | Money (saldo) | Ganho total | Renda/s | Index (/112) | Rebirth | Upgrade médio (nível) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 10 min | Rampart (3) [3–4] | 265.79K | 371.62K / 510.69K / 701.79K | 562 | 22 / 22 / 22 | 0 / 0 / 0 | 9.5 |
| 30 min | Storm (8) [8–8] | 174.13K | 2.87M / 3.56M / 4.23M | 3.41K | 57 / 58 / 58 | 0 / 0 / 0 | 16.0 |
| 1 h | Shadow (11) [11–12] | 3.75M | 16.71M / 20.40M / 33.43M | 9.58K | 80 / 80 / 86 | 0 / 0 / 0 | 17.8 |
| 3 h | Celestial (15) [14–15] | 37.75M | 284.57M / 418.50M / 593.74M | 121.89K | 98 / 105 / 105 | 2 / 3 / 3 | 21.1 |
| 5 h | Forbidden (16) [16–16] | 373.06M | 1.97B / 2.52B / 3.37B | 357.75K | 109 / 109 / 110 | 5 / 5 / 6 | 23.8 |
| 10 h | Forbidden (16) [16–16] | 3.16B | 20.30B / 23.78B / 31.09B | 1.05M | 109 / 110 / 112 | 9 / 9 / 9 | 26.2 |
| 20 h | Forbidden (16) [16–16] | 58.58B | 127.65B / 141.62B / 165.29B | 2.03M | 112 / 112 / 112 | 11 / 11 / 11 | 27.3 |

### Otimizador F2P

| Tempo ativo | Dice | Money (saldo) | Ganho total | Renda/s | Index (/112) | Rebirth | Upgrade médio (nível) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 10 min | Rampart (3) [3–3] | 245.07K | 373.27K / 516.50K / 692.07K | 536 | 22 / 22 / 22 | 0 / 0 / 0 | 12.8 |
| 30 min | Fighter (7) [7–8] | 107.20K | 2.66M / 3.39M / 3.98M | 2.92K | 51 / 51 / 58 | 0 / 0 / 0 | 18.0 |
| 1 h | Shadow (11) [10–12] | 2.16M | 16.78M / 20.89M / 48.70M | 11.03K | 73 / 80 / 86 | 0 / 0 / 0 | 20.0 |
| 3 h | Celestial (15) [14–15] | 37.39M | 276.32M / 392.61M / 590.75M | 116.44K | 98 / 104 / 105 | 2 / 2 / 3 | 23.7 |
| 5 h | Forbidden (16) [16–16] | 348.13M | 2.10B / 2.71B / 3.79B | 442.73K | 109 / 109 / 110 | 5 / 6 / 6 | 26.2 |
| 10 h | Forbidden (16) [16–16] | 3.82B | 16.43B / 20.94B / 26.26B | 1.17M | 109 / 110 / 112 | 8 / 9 / 9 | 28.1 |
| 20 h | Forbidden (16) [16–16] | 30.84B | 97.55B / 112.46B / 131.56B | 2.24M | 111 / 112 / 112 | 11 / 11 / 11 | 29.1 |

### Pago Moderado

| Tempo ativo | Dice | Money (saldo) | Ganho total | Renda/s | Index (/112) | Rebirth | Upgrade médio (nível) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 10 min | Flame (5) [5–6] | 843.84K | 1.10M / 1.53M / 2.10M | 1.71K | 36 / 36 / 36 | 0 / 0 / 0 | 11.8 |
| 30 min | Arcane (10) [9–11] | 942.87K | 10.98M / 13.91M / 21.51M | 15.18K | 65 / 73 / 80 | 0 / 0 / 0 | 20.5 |
| 1 h | Colossus (13) [13–14] | 19.27M | 66.48M / 80.09M / 143.13M | 28.30K | 92 / 92 / 98 | 0 / 0 / 1 | 21.2 |
| 3 h | Forbidden (16) [16–16] | 309.23M | 1.81B / 2.61B / 4.19B | 672.65K | 109 / 109 / 110 | 5 / 5 / 6 | 26.2 |
| 5 h | Forbidden (16) [16–16] | 3.05B | 10.10B / 13.61B / 18.38B | 1.58M | 109 / 110 / 112 | 8 / 8 / 8 | 27.9 |
| 10 h | Forbidden (16) [16–16] | 15.15B | 79.60B / 97.49B / 119.81B | 3.53M | 111 / 112 / 112 | 10 / 11 / 11 | 29.0 |
| 20 h | Forbidden (16) [16–16] | 69.08B | 361.33B / 426.37B / 500.93B | 6.00M | 112 / 112 / 112 | 12 / 13 / 13 | 29.3 |


## 2. Tempo para comprar cada Dice (tempo ATIVO; P10 / P50 / P90)

`Liberado por rolls` = quando atingiu o requisito de rolls do Dice; `Espera por dinheiro` = quanto tempo depois disso ainda faltava dinheiro. Espera ~0 = o requisito de **rolls** é o gargalo; espera longa = o **preço** é o gargalo. `Completion antes do próximo?` = fração dos jogadores que já tinham 100% / ≥90% / <50% do pool quando compraram o próximo Dice (<50% quase sempre = Dice pulado: comprou dois de uma vez e nunca rolou o anterior).

Leitura (Ativo F2P):
- Rampart: gargalo misto (espera P50 1.4 min depois de liberar por rolls).
- Shinobi: gargalo **dinheiro** (espera P50 5.2 min depois de liberar por rolls).
- Flame: gargalo misto (espera P50 5.0 min depois de liberar por rolls).
- Blade: gargalo **dinheiro** (espera P50 5.7 min depois de liberar por rolls).
- Fighter: gargalo **dinheiro** (espera P50 8.1 min depois de liberar por rolls).
- Storm: gargalo **dinheiro** (espera P50 8.8 min depois de liberar por rolls).
- Spirit: gargalo **dinheiro** (espera P50 11.5 min depois de liberar por rolls).
- Arcane: gargalo **dinheiro** (espera P50 9.7 min depois de liberar por rolls).
- Shadow: gargalo **dinheiro** (espera P50 9.3 min depois de liberar por rolls).
- Void: gargalo **dinheiro** (espera P50 10.2 min depois de liberar por rolls).
- Awakened: gargalo **dinheiro** (espera P50 8.5 min depois de liberar por rolls).
- Celestial: gargalo **dinheiro** (espera P50 29.7 min depois de liberar por rolls).
- Forbidden: gargalo **dinheiro** (espera P50 40.2 min depois de liberar por rolls).
- Lucky: limitado pelos rolls. No Casual quase todos os Dice são limitados pelos rolls (espera por dinheiro < 1 min), porque o offline paga os preços entre as sessões.

### Casual F2P

| Dice | Unlock (rolls) | Price | P10 | P50 | P90 | Comprou em 20 h | Liberado por rolls (P50) | Espera por dinheiro (P50) | Completion antes do próximo? |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Starter | 0 | 0 | 0 | 0 | 0 | 100% | — | — | 100%: 98% · ≥90%: 98% · <50%: 0% |
| Lucky | 50 | 2.50K | 3.0 min | 3.0 min | 3.0 min | 100% | 1.2 min | 1.8 min | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Rampart | 125 | 10.00K | 5.0 min | 6.0 min | 6.0 min | 100% | 3.0 min | 3.0 min | 100%: 99% · ≥90%: 99% · <50%: 0% |
| Shinobi | 300 | 40.00K | 9.0 min | 9.0 min | 9.0 min | 100% | 7.1 min | 1.9 min | 100%: 99% · ≥90%: 99% · <50%: 0% |
| Flame | 450 | 75.00K | 11.0 min | 12.0 min | 15.0 min | 100% | 10.7 min | 48s | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Blade | 650 | 125.00K | 16.0 min | 16.0 min | 18.0 min | 100% | 15.4 min | 44s | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Fighter | 775 | 225.00K | 21.0 min | 21.0 min | 21.0 min | 100% | 18.4 min | 2.5 min | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Storm | 1000 | 400.00K | 24.0 min | 24.0 min | 25.0 min | 100% | 23.8 min | 29s | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Spirit | 1500 | 750.00K | 36.0 min | 36.0 min | 37.0 min | 100% | 35.7 min | 29s | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Arcane | 2000 | 1.40M | 47.0 min | 48.0 min | 49.0 min | 100% | 47.6 min | 30s | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Shadow | 2500 | 2.60M | 59.0 min | 1.0 h | 1.0 h | 100% | 59.5 min | 30s | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Void | 3000 | 5.00M | 1.2 h | 1.4 h | 1.4 h | 100% | 1.2 h | 8.1 min | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Colossus | 4500 | 12.50M | 1.8 h | 1.9 h | 1.9 h | 100% | 1.8 h | 3.6 min | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Awakened | 6000 | 30.00M | 2.4 h | 2.4 h | 2.6 h | 100% | 2.4 h | 44s | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Celestial | 8000 | 75.00M | 3.2 h | 3.2 h | 3.4 h | 100% | 3.2 h | 44s | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Forbidden | 12000 | 400.00M | 4.8 h | 4.8 h | 5.0 h | 100% | 4.8 h | 50s | último Dice |

### Ativo F2P

| Dice | Unlock (rolls) | Price | P10 | P50 | P90 | Comprou em 20 h | Liberado por rolls (P50) | Espera por dinheiro (P50) | Completion antes do próximo? |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Starter | 0 | 0 | 0 | 0 | 0 | 100% | — | — | 100%: 96% · ≥90%: 96% · <50%: 0% |
| Lucky | 50 | 2.50K | 1.0 min | 1.5 min | 1.8 min | 100% | 50s | 40s | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Rampart | 125 | 10.00K | 3.5 min | 3.5 min | 4.8 min | 100% | 2.1 min | 1.4 min | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Shinobi | 300 | 40.00K | 10.0 min | 10.2 min | 10.2 min | 100% | 5.0 min | 5.2 min | 100%: 99% · ≥90%: 99% · <50%: 0% |
| Flame | 450 | 75.00K | 11.2 min | 12.5 min | 15.0 min | 100% | 7.5 min | 5.0 min | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Blade | 650 | 125.00K | 12.5 min | 16.5 min | 20.5 min | 100% | 10.8 min | 5.7 min | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Fighter | 775 | 225.00K | 19.0 min | 21.0 min | 24.3 min | 100% | 12.9 min | 8.1 min | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Storm | 1000 | 400.00K | 23.0 min | 25.5 min | 29.0 min | 100% | 16.7 min | 8.8 min | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Spirit | 1500 | 750.00K | 32.0 min | 36.5 min | 40.2 min | 100% | 25.0 min | 11.5 min | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Arcane | 2000 | 1.40M | 39.5 min | 43.0 min | 47.5 min | 100% | 33.3 min | 9.7 min | 100%: 99% · ≥90%: 99% · <50%: 0% |
| Shadow | 2500 | 2.60M | 45.5 min | 51.0 min | 55.5 min | 100% | 41.7 min | 9.3 min | 100%: 98% · ≥90%: 98% · <50%: 0% |
| Void | 3000 | 5.00M | 51.5 min | 1.0 h | 1.0 h | 100% | 50.0 min | 10.2 min | 100%: 99% · ≥90%: 99% · <50%: 0% |
| Colossus | 4500 | 12.50M | 1.2 h | 1.2 h | 1.3 h | 100% | 1.2 h | 0s | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Awakened | 6000 | 30.00M | 1.7 h | 1.8 h | 2.0 h | 100% | 1.7 h | 8.5 min | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Celestial | 8000 | 75.00M | 2.4 h | 2.7 h | 3.0 h | 100% | 2.2 h | 29.7 min | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Forbidden | 12000 | 400.00M | 3.7 h | 4.0 h | 4.2 h | 100% | 3.3 h | 40.2 min | último Dice |

### Otimizador F2P

| Dice | Unlock (rolls) | Price | P10 | P50 | P90 | Comprou em 20 h | Liberado por rolls (P50) | Espera por dinheiro (P50) | Completion antes do próximo? |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Starter | 0 | 0 | 0 | 0 | 0 | 100% | — | — | 100%: 96% · ≥90%: 96% · <50%: 0% |
| Lucky | 50 | 2.50K | 1.3 min | 1.7 min | 1.8 min | 100% | 50s | 50s | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Rampart | 125 | 10.00K | 3.0 min | 4.3 min | 5.8 min | 100% | 2.1 min | 2.2 min | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Shinobi | 300 | 40.00K | 10.1 min | 10.1 min | 10.1 min | 100% | 5.0 min | 5.1 min | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Flame | 450 | 75.00K | 12.7 min | 14.6 min | 17.0 min | 100% | 7.5 min | 7.1 min | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Blade | 650 | 125.00K | 14.6 min | 18.3 min | 25.0 min | 100% | 10.8 min | 7.5 min | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Fighter | 775 | 225.00K | 22.2 min | 25.2 min | 28.0 min | 100% | 12.9 min | 12.2 min | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Storm | 1000 | 400.00K | 26.8 min | 31.0 min | 34.5 min | 100% | 16.7 min | 14.4 min | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Spirit | 1500 | 750.00K | 35.8 min | 40.7 min | 44.2 min | 100% | 25.0 min | 15.7 min | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Arcane | 2000 | 1.40M | 44.2 min | 48.2 min | 54.7 min | 100% | 33.3 min | 14.8 min | 100%: 98% · ≥90%: 98% · <50%: 0% |
| Shadow | 2500 | 2.60M | 48.2 min | 55.5 min | 1.0 h | 100% | 41.7 min | 13.8 min | 100%: 96% · ≥90%: 96% · <50%: 0% |
| Void | 3000 | 5.00M | 54.1 min | 1.1 h | 1.2 h | 100% | 50.0 min | 13.7 min | 100%: 99% · ≥90%: 99% · <50%: 0% |
| Colossus | 4500 | 12.50M | 1.2 h | 1.3 h | 1.4 h | 100% | 1.2 h | 4.5 min | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Awakened | 6000 | 30.00M | 1.7 h | 1.9 h | 2.0 h | 100% | 1.7 h | 11.1 min | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Celestial | 8000 | 75.00M | 2.5 h | 2.9 h | 3.1 h | 100% | 2.2 h | 37.7 min | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Forbidden | 12000 | 400.00M | 3.8 h | 4.0 h | 4.2 h | 100% | 3.3 h | 40.2 min | último Dice |

### Pago Moderado

| Dice | Unlock (rolls) | Price | P10 | P50 | P90 | Comprou em 20 h | Liberado por rolls (P50) | Espera por dinheiro (P50) | Completion antes do próximo? |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Starter | 0 | 0 | 0 | 0 | 0 | 100% | — | — | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Lucky | 50 | 2.50K | 30s | 1.0 min | 1.0 min | 100% | 25s | 35s | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Rampart | 125 | 10.00K | 1.8 min | 1.8 min | 1.8 min | 100% | 1.1 min | 42s | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Shinobi | 300 | 40.00K | 3.5 min | 5.0 min | 5.2 min | 100% | 2.5 min | 2.5 min | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Flame | 450 | 75.00K | 6.5 min | 8.0 min | 8.0 min | 100% | 3.8 min | 4.2 min | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Blade | 650 | 125.00K | 10.0 min | 10.2 min | 10.2 min | 100% | 5.4 min | 4.8 min | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Fighter | 775 | 225.00K | 10.5 min | 13.0 min | 14.5 min | 100% | 6.5 min | 6.5 min | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Storm | 1000 | 400.00K | 13.2 min | 15.5 min | 18.5 min | 100% | 8.3 min | 7.2 min | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Spirit | 1500 | 750.00K | 18.0 min | 21.5 min | 25.0 min | 100% | 12.5 min | 9.0 min | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Arcane | 2000 | 1.40M | 25.5 min | 29.5 min | 33.0 min | 100% | 16.7 min | 12.8 min | 100%: 97% · ≥90%: 97% · <50%: 0% |
| Shadow | 2500 | 2.60M | 27.0 min | 33.4 min | 37.5 min | 100% | 20.8 min | 12.5 min | 100%: 95% · ≥90%: 95% · <50%: 0% |
| Void | 3000 | 5.00M | 31.0 min | 37.5 min | 42.0 min | 100% | 25.0 min | 12.5 min | 100%: 95% · ≥90%: 95% · <50%: 0% |
| Colossus | 4500 | 12.50M | 37.5 min | 45.5 min | 52.0 min | 100% | 37.5 min | 8.0 min | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Awakened | 6000 | 30.00M | 50.0 min | 1.1 h | 1.2 h | 100% | 50.0 min | 14.0 min | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Celestial | 8000 | 75.00M | 1.4 h | 1.7 h | 1.9 h | 100% | 1.1 h | 36.8 min | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Forbidden | 12000 | 400.00M | 2.1 h | 2.4 h | 2.7 h | 100% | 1.7 h | 42.0 min | último Dice |


## 3. Completion de cada Dice × próximo desbloqueio (Ativo F2P)

Pools por Dice: 6–8 personagens. Até o Awakened o 100% sai em segundos ou poucos minutos depois da compra; só Celestial (3 Divinos) e Forbidden (3 Divinos + 3 Secretos) têm caça longa. **"Rolar sem nada novo" é a regra no meio do jogo**: o tempo entre completar o Dice e comprar o próximo (coluna `Próximo comprado`, 5–30 min no meio do jogo) é gasto inteiro em rolls repetidos — a recompensa desse tempo é só a venda de duplicata (centavos) e o progresso para o requisito de rolls.

| Dice | 50% | 75% | 90% | 100% | Próximo liberado por rolls | Próximo comprado | Rolls sem nada novo (P50) | Completou 100% (20 h) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Starter | 5s | 10s | 29s | 29s | 50s | 1.5 min | 47 | 100% |
| Lucky | 6s | 14s | 26s | 26s | 35s | 2.5 min | 129 | 100% |
| Rampart | 6s | 17s | 33s | 33s | 1.5 min | 6.0 min | 329 | 100% |
| Shinobi | 5s | 10s | 23s | 23s | 0s | 2.5 min | 120 | 100% |
| Flame | 4s | 11s | 50s | 50s | 0s | 4.0 min | 205 | 100% |
| Blade | 5s | 10s | 27s | 27s | 0s | 4.0 min | 220 | 100% |
| Fighter | 5s | 12s | 20s | 20s | 0s | 4.0 min | 221 | 100% |
| Storm | 5s | 13s | 26s | 26s | 0s | 11.0 min | 634 | 100% |
| Spirit | 6s | 18s | 54s | 54s | 0s | 6.5 min | 321 | 100% |
| Arcane | 5s | 10s | 30s | 30s | 0s | 7.5 min | 405 | 100% |
| Shadow | 6s | 16s | 43s | 43s | 0s | 7.0 min | 368 | 100% |
| Void | 4s | 11s | 2.6 min | 2.6 min | 14.8 min | 18.2 min | 889 | 100% |
| Colossus | 3s | 9s | 16s | 16s | 25.0 min | 31.8 min | 1884 | 100% |
| Awakened | 4s | 13s | 28s | 28s | 24.8 min | 54.0 min | 3210 | 100% |
| Celestial | 8s | 5.0 min | 11.0 min | 11.0 min | 37.0 min | 1.3 h | 3858 | 100% |
| Forbidden | 7.6 min | 5.7 h | 8.0 h | 8.0 h | — | — | 28785 | 100% |

Tempos de completion contados a partir da compra do Dice (P50 de quem chegou ao marco).


## 4. Fontes de dinheiro

| Fonte | Valor | Frequência | Condição | Multiplicadores | F2P / Pago | Autoritativo no servidor? |
| --- | --- | --- | --- | --- | --- | --- |
| Coletor (renda das estações) | Σ BaseIncome(**Dice × Raridade**, seção 0) × variante (1/1,5/2/3/4/6/10) × (1 + 0,25·(nível−1)) | por segundo, acumula no coletor (teto 1 h de renda) | personagem equipado na base | Renda global +10%/nível (25), Rebirth +25%/rebirth, perk Renda +15%/nível, VIP ×1,5, amigos +5% (até 25%) | F2P (VIP pago) | sim (IncomeService/EconomyService) |
| Dinheiro offline | 12% × renda/s × min(offline, 8 h) | ao voltar (≥ 60 s fora) | relógio do servidor | teto = 25% do custo do próximo Rebirth | F2P | sim (OfflineCore, os.time) |
| Venda de personagem | BaseIncome(Dice × Raridade) × SellSeconds (C 20 · U 20 · R 25 · E 30 · L 35 · M 45 · D 60 · S 90 s) × variante + 75% do investimento em níveis | por venda / em massa / auto-sell | não travado/favorito/equipado/em troca (em massa: nem no time da Torre) | nível reembolsado em 75% | F2P | sim (SellService via SaleCore/BulkSaleCore) |
| Torres | max(poder inimigo × 1, renda/s × 8) | 1ª vitória de cada andar (120 andares) | time de 5 vence a batalha simulada | poder: Rebirth +10%/rb, perk Poder | F2P | sim (TowerService/BattleCore) |
| Missões diárias | dinheiro = max(1,5K–3K, renda × 240–400 s) | 3/dia (das 10 do pool, 5 dão dinheiro) | completar a meta | renda/s | F2P | sim (MissionService) |
| Recompensa diária | D1 max(1K, 120 s) · D4 max(10K, 600 s); D2/D5 gemas; D3/D6 sorte; D7 Prisma | 1/dia UTC, ciclo 7 | não pular dia | renda/s | F2P | sim (DailyService) |
| Jackpot (150 gemas) | dinheiro 600 s (mín 5K, peso 30) ou 3600 s (mín 50K, peso 12); gemas; sorte 2×; roll garantido Épico/Lendário/Mítico | por giro | gemas | renda/s | F2P (gemas) / Robux (giro) | sim (JackpotService) |
| Loja de gemas: Pacote de dinheiro | 40 gemas → max(5K, 900 s de renda) | à vontade | gemas | renda/s | F2P | sim |
| Produtos Robux | Pacote max(10K, 15 min) · Cofre max(150K, 2 h) | compra | Robux | renda/s | Pago | sim (ReceiptCore) |
| Gemas (não é dinheiro) | Diário 25/100, missões 10–25, torres 5 a cada 5 andares + 100/250/600, Índice 10/25/50/150, conquistas 25–50 | — | — | — | F2P | sim |

Observações: (1) o **Pacote de dinheiro da loja de gemas paga 22,5 s de renda por gema**, o Jackpot paga em média ~4 s de renda por gema em dinheiro (612 s / 150 gemas) — quem quer dinheiro nunca deveria girar o Jackpot; o simulador gasta as gemas no Jackpot (pior caso para dinheiro). (2) Conquista `index` ainda usa marcos {6, 12, 18, 24} de quando havia 24 personagens; hoje há 112.

Participação de cada fonte no dinheiro ganho (agregado de todos os jogadores do perfil):

| Perfil | Tempo | Coletor | Offline | Venda duplicatas | Venda c/ nível | Torres | Missões | Diário | Jackpot |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Casual F2P | 1.0 h | 31% | 42% | 14% | 1% | 4% | 7% | 0% | 0% |
| Casual F2P | 5.0 h | 40% | 44% | 3% | 0% | 1% | 9% | 3% | 0% |
| Casual F2P | 20.0 h | 24% | 67% | 0% | 0% | 0% | 6% | 2% | 0% |
| Ativo F2P | 1.0 h | 59% | 0% | 15% | 3% | 5% | 1% | 0% | 17% |
| Ativo F2P | 5.0 h | 81% | 5% | 5% | 0% | 1% | 5% | 0% | 3% |
| Ativo F2P | 20.0 h | 52% | 40% | 1% | 0% | 0% | 3% | 0% | 3% |
| Otimizador F2P | 1.0 h | 56% | 0% | 12% | 4% | 5% | 1% | 0% | 22% |
| Otimizador F2P | 5.0 h | 82% | 3% | 4% | 0% | 1% | 5% | 0% | 5% |
| Otimizador F2P | 20.0 h | 70% | 23% | 1% | 0% | 0% | 2% | 1% | 4% |
| Pago Moderado | 1.0 h | 59% | 0% | 18% | 1% | 4% | 1% | 0% | 17% |
| Pago Moderado | 5.0 h | 75% | 9% | 2% | 0% | 1% | 5% | 0% | 7% |
| Pago Moderado | 20.0 h | 52% | 41% | 0% | 0% | 0% | 3% | 0% | 3% |


## 5. Sinks (para onde o dinheiro vai)

| Sink | Custo inicial | Curva | Acumulado | Limite | Dependências / reset |
| --- | --- | --- | --- | --- | --- |
| Dice (16) | 2,5K | fixo por posição (até 400.00M) | 528.13M todos | 16 | rolls exigidos + Dice anterior; **não reseta** no Rebirth |
| Níveis de estação | BaseIncome(Dice × Raridade) × 60 | × 1,2 por nível | ver seção 6 | nível 30 | personagem equipado; 75% volta na venda; soma na fusão |
| Upgrade Luck | 2K | × 1,9 | 835.33M (20 níveis) | 20 | **reseta** no Rebirth |
| Upgrade Renda | 1,5K | × 1,85 | 8.43B (25 níveis) | 25 | **reseta** no Rebirth |
| Upgrade Inventário | 1K | × 1,7 | 58.06M (20 níveis) | 20 | mantido |
| Velocidade de Roll | — | desligado (cadência fixa por config) | — | — | — |
| Fusão | BaseIncome(Dice × Raridade) × 600 × ordem da variante + 2–3 cópias | por degrau | Normal→Celestial = 3·3·3·3·2·2·2 = 648 cópias | Celestial | resultado mantém o MAIOR nível e SOMA o investimento das cópias |
| Rebirth | 15.00M | × 2,2 | 33.19B até o 10º | 36 | zera dinheiro, coletor, Luck/Renda; mantém Dice, personagens, Índice, torres, gemas |
| Gemas | Jackpot 150 · sorte 60 · dinheiro 40 | — | — | — | — |

Destino do dinheiro (agregado; "Rebirth" = saldo zerado ao renascer):

| Perfil | Tempo | Dice | Níveis de estação | Upgrade Luck | Upgrade Renda | Upgrade Inventário | Fusão | Rebirth (saldo zerado) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Casual F2P | 1.0 h | 57% | 9% | 14% | 1% | 18% | 0% | 0% |
| Casual F2P | 5.0 h | 20% | 2% | 7% | 1% | 3% | 0% | 67% |
| Casual F2P | 20.0 h | 1% | 0% | 4% | 0% | 0% | 0% | 95% |
| Ativo F2P | 1.0 h | 42% | 20% | 10% | 7% | 10% | 11% | 0% |
| Ativo F2P | 5.0 h | 24% | 4% | 15% | 5% | 3% | 1% | 48% |
| Ativo F2P | 20.0 h | 1% | 0% | 5% | 1% | 0% | 0% | 93% |
| Otimizador F2P | 1.0 h | 32% | 29% | 7% | 14% | 8% | 10% | 0% |
| Otimizador F2P | 5.0 h | 21% | 6% | 11% | 11% | 2% | 1% | 47% |
| Otimizador F2P | 20.0 h | 1% | 1% | 5% | 2% | 0% | 0% | 91% |
| Pago Moderado | 1.0 h | 42% | 14% | 13% | 6% | 13% | 7% | 5% |
| Pago Moderado | 5.0 h | 5% | 3% | 15% | 5% | 1% | 1% | 71% |
| Pago Moderado | 20.0 h | 0% | 0% | 2% | 1% | 0% | 0% | 97% |


## 6. Curva de upgrade de personagem (estação)

Fórmula (CharacterLevelConfig): custo L→L+1 = floor(BaseIncome × 60 × 1,2^(L−1)); renda = BaseIncome × (1 + 0,25·(L−1)), com BaseIncome = Dice × Raridade (seção 0). O **payback de um nível não depende da raridade nem do Dice** (o custo é proporcional ao BaseIncome): 240 s × 1,2^(L−1) ÷ (variante × multiplicadores do jogador). Sem multiplicadores, o nível 10 se paga em ~21 min, o 20 em ~2 h e o 30 (máximo) em ~13 h. Com os multiplicadores de Rebirth/Renda (×10–15 no fim), os perfis param perto do máximo (Upgrade médio na tabela principal).

Venda base = 20–90 × BaseIncome; o investimento em níveis volta em 75% na venda (antes da economia aplicada voltava 0%).

| Nível | Custo L→L+1 (× BaseIncome) | Acumulado até L (× BaseIncome) | Renda no nível (× BaseIncome) | Payback do nível (Normal) | Venda base Comum/Mítico (× BaseIncome) |
| --- | --- | --- | --- | --- | --- |
| 1 | 60 | 0 | 1.00 | 4.0 min | 20 / 45 |
| 2 | 72 | 60 | 1.25 | 4.8 min | 20 / 45 |
| 5 | 124 | 322 | 2.00 | 8.3 min | 20 / 45 |
| 10 | 310 | 1.25K | 3.25 | 20.6 min | 20 / 45 |
| 15 | 770 | 3.55K | 4.50 | 51.4 min | 20 / 45 |
| 20 | 1.92K | 9.28K | 5.75 | 2.1 h | 20 / 45 |
| 25 | 4.77K | 23.55K | 7.00 | 5.3 h | 20 / 45 |
| 30 | máx | 59.04K | 8.25 | — | 20 / 45 |

Investimento acumulado em níveis por Dice × Raridade (o custo acompanha o BaseIncome da curva; 1º e último Dice de cada raridade):

| Raridade · Dice (BaseIncome) | Nível 2 | Nível 10 | Nível 20 | Nível 30 (máx) | Venda base Nv1 |
| --- | --- | --- | --- | --- | --- |
| Common · starter (1) | 60 | 1.24K | 9.28K | 59.03K | 20 |
| Common · shinobi (1.3) | 78 | 1.62K | 12.06K | 76.74K | 26 |
| Uncommon · starter (3.8) | 228 | 4.74K | 35.27K | 224.35K | 76 |
| Uncommon · fighter (7) | 420 | 8.73K | 64.98K | 413.29K | 140 |
| Rare · starter (8.2) | 491 | 10.23K | 76.12K | 484.15K | 204 |
| Rare · arcane (21) | 1.26K | 26.20K | 194.96K | 1.24M | 525 |
| Epic · starter (22) | 1.32K | 27.45K | 204.25K | 1.30M | 660 |
| Epic · colossus (77) | 4.62K | 96.09K | 714.89K | 4.55M | 2.31K |
| Legendary · flame (54) | 3.24K | 67.39K | 501.35K | 3.19M | 1.89K |
| Legendary · celestial (153) | 9.18K | 190.93K | 1.42M | 9.03M | 5.36K |
| Mythic · spirit (149) | 8.94K | 185.94K | 1.38M | 8.80M | 6.71K |
| Mythic · forbidden (309) | 18.54K | 385.61K | 2.87M | 18.24M | 13.90K |
| Divine · void (408) | 24.48K | 509.15K | 3.79M | 24.09M | 24.48K |
| Divine · forbidden (619) | 37.14K | 772.47K | 5.75M | 36.55M | 37.14K |
| Secret · forbidden (1200) | 72.00K | 1.50M | 11.14M | 70.85M | 108.00K |

Minutos de renda (P50 do Ativo F2P no momento em que compra o Dice) para levar UMA unidade da raridade mais comum do Dice entre níveis:

| Dice | Renda/s na compra (P50) | Raridade típica (BaseIncome deste Dice) | 1→10 | 10→20 | 20→30 |
| --- | --- | --- | --- | --- | --- |
| Starter | 562 | Common (1) | 2s | 14s | 1.5 min |
| Lucky | 76 | Common (1.1) | 18s | 1.9 min | 12.0 min |
| Rampart | 183 | Common (1.2) | 8s | 53s | 5.4 min |
| Shinobi | 563 | Common (1.3) | 3s | 19s | 1.9 min |
| Flame | 850 | Uncommon (5.7) | 8s | 54s | 5.6 min |
| Blade | 1.48K | Uncommon (6.3) | 5s | 34s | 3.5 min |
| Fighter | 1.87K | Uncommon (7) | 5s | 30s | 3.1 min |
| Storm | 2.00K | Rare (17) | 11s | 1.1 min | 7.0 min |
| Spirit | 4.65K | Rare (19) | 5s | 33s | 3.4 min |
| Arcane | 5.79K | Rare (21) | 5s | 29s | 3.0 min |
| Shadow | 8.53K | Epic (63) | 9s | 59s | 6.1 min |
| Void | 8.57K | Epic (70) | 10s | 1.1 min | 6.8 min |
| Colossus | 14.96K | Legendary (125) | 10s | 1.1 min | 6.9 min |
| Awakened | 15.07K | Legendary (138) | 11s | 1.2 min | 7.6 min |
| Celestial | 85.47K | Legendary (153) | 2s | 14s | 1.5 min |
| Forbidden | 227.58K | Mythic (309) | 2s | 11s | 1.1 min |


## 7. Duplicatas

Regra atual: cada roll vira uma unidade no inventário (capacidade 100 + Mochila/upgrade); duplicata = mais uma cópia (serve para Fusão, troca ou venda). Venda = BaseIncome(Dice × Raridade) × SellSeconds × variante, ou seja **20–90 segundos da renda que a própria unidade daria equipada**. Venda em massa na Mochila (SELECIONAR DUPLICATAS) e auto-sell por raridade (desligado por padrão; Secreto protegido).

Valor vendido em duplicatas de cada Dice em 20 h (P50) e quanto isso paga do próximo Dice:

| Dice | Raridades | Valor vendido (Ativo, P50) | ÷ preço do próximo Dice | Casual P50 | Otimizador P50 | Rolls no Dice (Ativo P50) | Dice nunca rolado (Ativo) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Starter | Common/Uncommon/Rare/Epic | 3.49K | 140% | 5.53K | 3.73K | 90 | 0% |
| Lucky | Common/Uncommon/Rare/Epic | 10.09K | 101% | 8.91K | 13.27K | 150 | 0% |
| Rampart | Common/Uncommon/Rare/Epic | 54.54K | 136% | 16.98K | 50.70K | 360 | 0% |
| Shinobi | Common/Uncommon/Rare/Epic | 32.14K | 43% | 21.73K | 55.83K | 150 | 0% |
| Flame | Uncommon/Rare/Epic/Legendary | 69.23K | 55% | 51.38K | 63.38K | 240 | 0% |
| Blade | Uncommon/Rare/Epic/Legendary | 111.26K | 49% | 86.15K | 158.14K | 240 | 0% |
| Fighter | Uncommon/Rare/Epic/Legendary | 136.72K | 34% | 76.34K | 196.65K | 240 | 0% |
| Storm | Rare/Epic/Legendary | 566.84K | 76% | 486.24K | 507.66K | 660 | 0% |
| Spirit | Rare/Epic/Legendary/Mythic | 513.94K | 37% | 652.04K | 555.84K | 390 | 0% |
| Arcane | Rare/Epic/Legendary/Mythic | 713.07K | 27% | 831.96K | 541.20K | 450 | 0% |
| Shadow | Epic/Legendary/Mythic | 1.14M | 23% | 2.14M | 1.24M | 420 | 0% |
| Void | Epic/Legendary/Mythic/Divine | 3.83M | 31% | 4.96M | 3.60M | 1095 | 0% |
| Colossus | Epic/Legendary/Mythic | 8.81M | 29% | 6.60M | 8.34M | 1905 | 0% |
| Awakened | Legendary/Mythic | 17.87M | 24% | 11.83M | 19.95M | 3240 | 0% |
| Celestial | Legendary/Mythic/Divine | 37.37M | 9% | 33.54M | 35.10M | 4560 | 0% |
| Forbidden | Mythic/Divine/Secret | 805.63M | — | 539.24M | 800.57M | 57585 | 0% |

Participação total da venda de duplicatas: Casual F2P: 14% do dinheiro até 1 h, 0% até 20 h; Ativo F2P: 15% do dinheiro até 1 h, 1% até 20 h; Otimizador F2P: 12% do dinheiro até 1 h, 1% até 20 h; Pago Moderado: 18% do dinheiro até 1 h, 0% até 20 h.


## 8. UPGRADE REFUND ANALYSIS

### Desenho

`SaleValue = BaseSaleValue + RefundPercent × EligibleUpgradeInvestment` — cotação pura em `src/shared/Modules/SaleCore.luau`, usada pela venda real (individual e em massa) com **`EconomyConfig.UpgradeRefundPercent = 0.75`** (aplicado). As tabelas desta seção comparam percentuais no simulador.

**Investimento elegível — recálculo (A) × gravado por instância (B):**

| Critério | (A) recalcular pela curva do nível | (B) `UpgradeInvestment` gravado por instância |
| --- | --- | --- |
| Mudança futura na curva de custo | **reembolsa pela curva NOVA** (pode dar mais do que foi pago se a curva subir) | reembolsa o que foi pago de fato |
| Fusão (resultado fica com o maior nível) | ignora as cópias consumidas (ok) | pode SOMAR o investimento das cópias consumidas (mais justo) — mas exige regra explícita |
| Item recebido por troca | reembolsa níveis que o receptor não pagou | idem (o valor viaja com o item, como o próprio nível já viaja) |
| Duplicação / rollback | o nível já é a verdade; nada novo a corromper | +1 campo por item no save; protegido pelo mesmo ProfileCore/sessão |
| Valor negativo / NaN / adulterado | impossível (derivado do nível) | SaleCore descarta inválido e cai em (A) |
| Venda repetida | o item sai do inventário na mesma operação (SellService) | idem |
| Custo de save | 0 | ~8 bytes por item |

**Escolha: (B) com fallback (A).** O servidor grava em `InventoryService.Upgrade` exatamente o que cobrou (`TrySpend`), a fusão soma o investimento das unidades consumidas e itens antigos sem o campo usam a curva (A). Só o servidor escreve; o cliente nunca manda valor. Assim uma mudança futura de curva nunca cria dinheiro, e a fusão deixa de destruir investimento.

**API de prévia (pronta, autoritativa):** remote `PreviewSale({uid})` → por unidade `{ Base, Invested, Percent, Refund, Total }` + somas, calculada pelo servidor sobre o inventário do servidor (uid repetido conta uma vez; travado/favorito/equipado/em troca/inexistente fica de fora — mesma regra da venda). `SellCharacter` usa a mesma cotação, então **venda = prévia** (GameplayHarness). Sem UI definitiva nesta fase.

**Prova de que não existe loop de lucro.** Para qualquer unidade: o jogador paga `C` em níveis e recebe `Base + floor(r·C)` na venda. Lucro do ciclo = `Base + floor(r·C) − C ≤ Base − (1−r)·C ≤ Base` para `0 ≤ r ≤ 1` — nunca mais do que vender a unidade sem nível. O SaleCore limita `r` a [0, 1] (NaN/texto/±∞ → 0), nunca devolve negativo e nunca usa investimento de outra instância (cada item carrega o seu). Testado em `tests/SaleCore.spec.luau` e `tests/EconomyModel.spec.luau` para todos os 112+ personagens, 7 variantes, níveis 1/2/10/20/50 e r = 0/50/60/70/75/80/100%. A venda só aceita uid que existe no inventário do servidor e o remove na mesma operação (sem venda repetida). Com r = 100% o ciclo é neutro (lucro = só a Base, que já existia); por isso o teto recomendado é < 100%.

### Simulação

### Casual F2P (10 h ativas, 150 jogadores por %)

| Refund | Trocas de estação | Investimento perdido | Reembolsado | Ganho total 10 h | Dice 10 h | Index 10 h | Nível médio 10 h | Patrimônio 10 h |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 0% | 24 | 10.02M | 0 | 25.49B | 16.0 | 112 | 19.0 | 6.85B |
| 50% | 24 | 5.22M | 5.22M | 25.26B | 16.0 | 112 | 19.0 | 6.61B |
| 60% | 24 | 4.15M | 6.23M | 25.18B | 16.0 | 112 | 19.0 | 6.54B |
| 70% | 24 | 3.15M | 7.34M | 25.28B | 16.0 | 112 | 19.0 | 6.66B |
| 75% | 24 | 2.64M | 7.93M | 25.47B | 16.0 | 112 | 19.0 | 6.76B |
| 80% | 24 | 2.09M | 8.37M | 25.39B | 16.0 | 112 | 19.0 | 6.74B |
| 100% | 24 | 0 | 10.38M | 25.40B | 16.0 | 112 | 19.0 | 6.77B |

### Ativo F2P (10 h ativas, 150 jogadores por %)

| Refund | Trocas de estação | Investimento perdido | Reembolsado | Ganho total 10 h | Dice 10 h | Index 10 h | Nível médio 10 h | Patrimônio 10 h |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 0% | 17 | 10.71M | 0 | 23.28B | 16.0 | 111 | 26.2 | 2.99B |
| 50% | 17 | 5.16M | 5.16M | 23.47B | 16.0 | 110 | 26.2 | 3.22B |
| 60% | 17 | 4.28M | 6.42M | 23.66B | 16.0 | 111 | 26.1 | 3.21B |
| 70% | 17 | 2.77M | 6.45M | 24.25B | 16.0 | 110 | 26.2 | 5.96B |
| 75% | 17 | 2.73M | 8.20M | 23.65B | 16.0 | 111 | 26.2 | 3.08B |
| 80% | 17 | 1.95M | 7.79M | 25.43B | 16.0 | 110 | 26.2 | 6.54B |
| 100% | 17 | 0 | 11.01M | 24.74B | 16.0 | 110 | 26.2 | 5.70B |

### Otimizador F2P (10 h ativas, 150 jogadores por %)

| Refund | Trocas de estação | Investimento perdido | Reembolsado | Ganho total 10 h | Dice 10 h | Index 10 h | Nível médio 10 h | Patrimônio 10 h |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 0% | 19 | 18.07M | 0 | 19.10B | 16.0 | 110 | 27.8 | 4.83B |
| 50% | 19 | 8.44M | 8.44M | 20.90B | 16.0 | 110 | 28.0 | 4.75B |
| 60% | 18 | 7.12M | 10.68M | 20.55B | 16.0 | 110 | 28.1 | 3.80B |
| 70% | 18 | 4.74M | 11.06M | 21.31B | 16.0 | 110 | 28.1 | 4.02B |
| 75% | 19 | 4.31M | 12.94M | 20.15B | 16.0 | 110 | 28.1 | 4.14B |
| 80% | 19 | 3.48M | 13.91M | 21.24B | 16.0 | 110 | 28.1 | 4.40B |
| 100% | 19 | 0 | 17.81M | 20.56B | 16.0 | 110 | 28.1 | 3.89B |

### Impacto por percentual

| Refund | Liberdade de troca | Sink de dinheiro | Progressão | Exploit | Patrimônio |
| --- | --- | --- | --- | --- | --- |
| 0% (antes) | baixa: trocar a estação joga fora 100% dos níveis | máximo (todo nível é sink definitivo) | base | impossível | só saldo + venda base |
| 50% | média | metade do gasto em níveis volta ao trocar | ≈ base | impossível | + metade do investido |
| 60% | média | 40% fica no sistema | ≈ base | impossível | — |
| 70% | boa | 30% fica | ≈ base | impossível | — |
| **75%** | **boa** | **25% fica (sink real preservado)** | ≈ base (diferença dentro do ruído) | **impossível** | o jogador "vê" 3/4 do que investiu |
| 80% | boa | 20% fica | ≈ base | impossível | — |
| 100% | total | nível vira depósito sem custo: trocar é grátis, subir nível deixa de ser decisão | ≈ base | neutro (sem lucro) | inflaciona o patrimônio |

Números (P50, 10 h ativas): Ativo perde 10.71M em níveis ao trocar estações com 0% e 2.73M com 75% (recebe 8.20M de volta); Otimizador 18.07M → 4.31M. Isso é pequeno perto do ganho total (23.28B Ativo): **o refund não acelera a progressão de forma relevante** — o ganho é de liberdade (trocar para o personagem novo sem punição) e de percepção de valor. Diferenças de "Ganho total" entre as linhas são ruído de amostra (mesmas sementes, mas o caminho diverge cedo).

**Recomendação: 75%** (APLICADA) com investimento gravado por instância (B). Abaixo de 60% a troca ainda dói; 100% elimina o sink e transforma nível em poupança. 75% mantém 1/4 de cada troca como sink e deixa a decisão "subir nível agora × esperar o personagem melhor" com peso, sem nunca permitir lucro.


## 9. Prisma da Coleção (UsesPerReward × MaxCharges)

O Prisma vem no Dia 7 do ciclo diário (1 recompensa a cada 7 dias reais). Tempo ativo de 20 h = 60 dias para o Casual (8–9 recompensas), 10 dias para o Ativo (1 recompensa). No simulador o jogador usa a carga no Dice selecionado; se ele já está completo, seleciona o maior Dice que ainda tem personagem a descobrir (o servidor recusa sem gastar quando não há nada a descobrir).

### Casual F2P (20 h ativas)

| Usos/recompensa | Teto | Usos (P50) | Cargas perdidas no teto (P50) | Index 20 h (P50) | Forbidden 100% (jogadores) | Celestial 100% |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 7 | 4 | 0 | 112 | 100% | 100% |
| 1 | 14 | 4 | 0 | 112 | 100% | 100% |
| 1 | 21 | 4 | 0 | 112 | 100% | 100% |
| 2 | 7 | 6 | 3 | 112 | 100% | 100% |
| 2 | 14 | 6 | 0 | 112 | 100% | 100% |
| 2 | 21 | 6 | 0 | 112 | 100% | 100% |
| 3 | 7 | 8 | 9 | 112 | 100% | 100% |
| 3 | 14 | 8 | 2 | 112 | 100% | 100% |
| 3 (atual) | 21 | 8 | 0 | 112 | 100% | 100% |

### Ativo F2P (20 h ativas)

| Usos/recompensa | Teto | Usos (P50) | Cargas perdidas no teto (P50) | Index 20 h (P50) | Forbidden 100% (jogadores) | Celestial 100% |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 7 | 1 | 0 | 112 | 88% | 100% |
| 1 | 14 | 1 | 0 | 112 | 88% | 100% |
| 1 | 21 | 1 | 0 | 112 | 88% | 100% |
| 2 | 7 | 1 | 0 | 112 | 100% | 100% |
| 2 | 14 | 1 | 0 | 112 | 100% | 100% |
| 2 | 21 | 1 | 0 | 112 | 100% | 100% |
| 3 | 7 | 1 | 0 | 112 | 100% | 100% |
| 3 | 14 | 1 | 0 | 112 | 100% | 100% |
| 3 (atual) | 21 | 1 | 0 | 112 | 100% | 100% |

Leitura: o teto só importa para quem acumula; com 3 usos e teto 7 o Casual perde ~8 cargas em 60 dias, com teto 21 nenhuma. O Prisma decide principalmente os **Secretos do Forbidden** (0,0045%): no Ativo (1 recompensa em 20 h) 1 uso deixa ~14% dos jogadores sem o Forbidden completo em 20 h, 2 usos ~1%, 3 usos 0%. O Casual, com 8–9 recompensas, completa com qualquer combinação. **Recomendação: manter 3 usos / teto 21** (atual).


## 10. Rebirth: cedo × médio × tarde

Políticas: **early** = renasce assim que pode pagar; **medium** = renasce quando o próximo Dice custa mais que 2× o Rebirth; **late** = só com 15 Dice ou 4× o custo em caixa; **never** = nunca. O Rebirth mantém Dice, personagens, níveis, Índice e torres; zera dinheiro e as melhorias de Luck/Renda; dá +25% de renda, +2% de Luck (teto +50%), +10% de poder, +1 slot e fichas.

### Casual F2P

| Política | 1º Rebirth (P50) | Rebirths 3 h | Rebirths 10 h | Rebirths 20 h | Renda/s 20 h | Dice 20 h | Index 20 h | Ganho total 20 h |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| early | 1.2 h | 4 | 9 | 11 | 840.48K | 16.0 | 112 | 123.57B |
| medium | 2.4 h | 2 | 9 | 11 | 856.22K | 16.0 | 112 | 118.31B |
| late | 3.0 h | 0 | 8 | 11 | 854.20K | 16.0 | 112 | 110.88B |
| never | não renasce (P50) | 0 | 0 | 0 | 35.28K | 16.0 | 112 | 2.86B |

### Ativo F2P

| Política | 1º Rebirth (P50) | Rebirths 3 h | Rebirths 10 h | Rebirths 20 h | Renda/s 20 h | Dice 20 h | Index 20 h | Ganho total 20 h |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| early | 1.2 h | 4 | 9 | 11 | 1.94M | 16.0 | 112 | 138.90B |
| medium | 2.0 h | 3 | 9 | 11 | 2.03M | 16.0 | 112 | 140.48B |
| late | 2.6 h | 1 | 8 | 11 | 2.00M | 16.0 | 112 | 125.94B |
| never | não renasce (P50) | 0 | 0 | 0 | 54.94K | 16.0 | 112 | 4.34B |

### Otimizador F2P

| Política | 1º Rebirth (P50) | Rebirths 3 h | Rebirths 10 h | Rebirths 20 h | Renda/s 20 h | Dice 20 h | Index 20 h | Ganho total 20 h |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| early | 1.5 h | 3 | 9 | 11 | 2.19M | 16.0 | 112 | 113.94B |
| medium | 2.0 h | 2 | 9 | 11 | 2.25M | 16.0 | 112 | 112.53B |
| late | 2.7 h | 1 | 8 | 11 | 2.18M | 16.0 | 112 | 99.44B |
| never | não renasce (P50) | 0 | 0 | 0 | 66.51K | 16.0 | 112 | 4.68B |

Leitura (diagnóstico histórico, com Rebirth 1 = 10M; hoje é 15M): (1) o primeiro Rebirth (10M) chegava **antes** do Colossus (12,5M) — como o Rebirth não tira Dice, renascer cedo é quase grátis e o jogador médio renasce enquanto ainda compra Dice; (2) em 20 h todas as políticas convergem para ~10–12 rebirths, porque o custo × 2,2 cresce mais devagar que a renda multiplicada (+25%/rebirth, +1 slot); (3) **never** ganha ~50× menos dinheiro em 20 h — o Rebirth é obrigatório, não opcional; (4) para Ativo/Otimizador, medium ganha um pouco mais que early (renascer cedo zera Luck/Renda compradas várias vezes); para o Casual, early ganha mais (o teto do offline sobe com o custo do próximo Rebirth).


## 11. Retenção: primeiros 5 / 10 / 20 / 30 / 60 minutos

Momentos de retenção medidos em 10.000 jogadores por perfil (primeira hora). Leitura: Raro e Épico chegam em segundos, o 1º Dice novo em 1–3 min e o 1º Dice 100% em < 2 min — os primeiros 5 min estão cheios. O **buraco** fica entre ~2 e ~10 min (nenhum marco novo até o 1º Lendário, que só existe a partir do Flame, ~11–13 min) e entre ~15 e ~35 min (até o 1º Mítico, no Spirit). Missões/Diário ajudam, mas não há recompensa de coleção nesse intervalo.

### Casual F2P (10000 jogadores)

| Evento | P10 / P50 / P90 | ≤5 min | ≤10 min | ≤20 min | ≤30 min | ≤60 min |
| --- | --- | --- | --- | --- | --- | --- |
| 1º Raro | 2s / 11s / 36s | 100% | 100% | 100% | 100% | 100% |
| 1º Épico | 5s / 33s / 1.8 min | 100% | 100% | 100% | 100% | 100% |
| 1º Lendário | 11.4 min / 12.3 min / 16.2 min | 0% | 0% | 100% | 100% | 100% |
| 1º Mítico | 36.2 min / 37.5 min / 40.3 min | 0% | 0% | 0% | 0% | 100% |
| 1º Dice novo | 3.0 min / 3.0 min / 3.0 min | 100% | 100% | 100% | 100% | 100% |
| 1º upgrade de estação | 3.0 min / 3.0 min / 3.0 min | 99% | 100% | 100% | 100% | 100% |
| 1º Dice 100% (coleção) | 21s / 41s / 1.8 min | 100% | 100% | 100% | 100% | 100% |

### Ativo F2P (10000 jogadores)

| Evento | P10 / P50 / P90 | ≤5 min | ≤10 min | ≤20 min | ≤30 min | ≤60 min |
| --- | --- | --- | --- | --- | --- | --- |
| 1º Raro | 2s / 8s / 26s | 100% | 100% | 100% | 100% | 100% |
| 1º Épico | 4s / 23s / 1.2 min | 100% | 100% | 100% | 100% | 100% |
| 1º Lendário | 11.6 min / 13.3 min / 15.8 min | 0% | 0% | 100% | 100% | 100% |
| 1º Mítico | 33.1 min / 37.5 min / 41.7 min | 0% | 0% | 0% | 1% | 100% |
| 1º Dice novo | 1.0 min / 1.5 min / 1.8 min | 100% | 100% | 100% | 100% | 100% |
| 1º upgrade de estação | 15s / 15s / 15s | 100% | 100% | 100% | 100% | 100% |
| 1º Dice 100% (coleção) | 15s / 29s / 1.2 min | 100% | 100% | 100% | 100% | 100% |

### Otimizador F2P (10000 jogadores)

| Evento | P10 / P50 / P90 | ≤5 min | ≤10 min | ≤20 min | ≤30 min | ≤60 min |
| --- | --- | --- | --- | --- | --- | --- |
| 1º Raro | 2s / 8s / 26s | 100% | 100% | 100% | 100% | 100% |
| 1º Épico | 4s / 23s / 1.2 min | 100% | 100% | 100% | 100% | 100% |
| 1º Lendário | 13.2 min / 15.2 min / 17.7 min | 0% | 0% | 97% | 100% | 100% |
| 1º Mítico | 37.1 min / 41.8 min / 45.8 min | 0% | 0% | 0% | 0% | 100% |
| 1º Dice novo | 1.3 min / 1.7 min / 1.8 min | 100% | 100% | 100% | 100% | 100% |
| 1º upgrade de estação | 5s / 5s / 5s | 100% | 100% | 100% | 100% | 100% |
| 1º Dice 100% (coleção) | 15s / 29s / 1.2 min | 100% | 100% | 100% | 100% | 100% |

### Pago Moderado (10000 jogadores)

| Evento | P10 / P50 / P90 | ≤5 min | ≤10 min | ≤20 min | ≤30 min | ≤60 min |
| --- | --- | --- | --- | --- | --- | --- |
| 1º Raro | 1s / 3s / 10s | 100% | 100% | 100% | 100% | 100% |
| 1º Épico | 2s / 8s / 25s | 100% | 100% | 100% | 100% | 100% |
| 1º Lendário | 6.6 min / 8.0 min / 8.4 min | 0% | 99% | 100% | 100% | 100% |
| 1º Mítico | 18.4 min / 22.1 min / 25.6 min | 0% | 0% | 22% | 100% | 100% |
| 1º Dice novo | 30s / 1.0 min / 1.0 min | 100% | 100% | 100% | 100% | 100% |
| 1º upgrade de estação | 15s / 15s / 15s | 100% | 100% | 100% | 100% | 100% |
| 1º Dice 100% (coleção) | 7s / 12s / 26s | 100% | 100% | 100% | 100% | 100% |


## 12. Longo prazo: 3 / 5 / 10 / 20 h

Forbidden: compra em ~3–5 h ativas para todos os perfis F2P; o 100% (3 Secretos) depende do Prisma e de horas de roll. **Não é rápido demais para comprar** (é o maior muro de dinheiro do jogo), mas depois de comprar não há mais nenhum Dice: o objetivo vira Rebirth + Secretos + torres.

| Perfil | Tempo | Dice (P50) | Tem Forbidden | Forbidden 100% | Index (P50) | Rebirths (P50) | Renda/s (P50) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Casual F2P | 3.0 h | 14 | 0% | 0% | 98 | 4 | 50.74K |
| Casual F2P | 5.0 h | 16 | 65% | 4% | 109 | 6 | 150.57K |
| Casual F2P | 10.0 h | 16 | 100% | 100% | 112 | 9 | 463.23K |
| Casual F2P | 20.0 h | 16 | 100% | 100% | 112 | 11 | 818.43K |
| Ativo F2P | 3.0 h | 15 | 0% | 0% | 105 | 3 | 121.89K |
| Ativo F2P | 5.0 h | 16 | 100% | 0% | 109 | 5 | 357.75K |
| Ativo F2P | 10.0 h | 16 | 100% | 14% | 110 | 9 | 1.05M |
| Ativo F2P | 20.0 h | 16 | 100% | 100% | 112 | 11 | 2.03M |
| Otimizador F2P | 3.0 h | 15 | 0% | 0% | 104 | 2 | 116.44K |
| Otimizador F2P | 5.0 h | 16 | 100% | 0% | 109 | 6 | 442.73K |
| Otimizador F2P | 10.0 h | 16 | 100% | 15% | 110 | 9 | 1.17M |
| Otimizador F2P | 20.0 h | 16 | 100% | 65% | 112 | 11 | 2.24M |
| Pago Moderado | 3.0 h | 16 | 100% | 0% | 109 | 5 | 672.65K |
| Pago Moderado | 5.0 h | 16 | 100% | 14% | 110 | 8 | 1.58M |
| Pago Moderado | 10.0 h | 16 | 100% | 68% | 112 | 11 | 3.53M |
| Pago Moderado | 20.0 h | 16 | 100% | 100% | 112 | 13 | 6.00M |

## 13. Problemas encontrados (diagnóstico histórico do commit 07744e5, com status)

Itens 1, 2, 4, 5, 6, 7, 8, 9, 10 e 11 foram corrigidos pela economia aplicada (refund 75%, fusão soma investimento, rolls por Dice, Forbidden 400M, Rebirth 15M, offline 25%, venda maior, loja de gemas, Índice 14/28/56/112, MaxLevel 30). Item novo 13: renda global por raridade (corrigido: Dice × Raridade, seção 0).

1. **Venda ignora o nível** — o investimento em níveis (até 773× o valor de venda no nível 20) é destruído na troca/venda. Pior atrito de liberdade de troca.
2. **Fusão destrói o investimento** das cópias consumidas (o resultado fica só com o maior nível).
3. **Pools de 6–8 personagens completam em segundos**; no meio do jogo a sessão é "rolar sem nada novo" esperando o próximo Dice (rolls para o Casual, dinheiro para Ativo/Otimizador).
4. **Compra em cascata pula Dice:** quando o requisito de rolls de vários Dice é atingido junto e o dinheiro sobra, o jogador compra 2–3 Dice de uma vez e nunca rola os intermediários (Shinobi/Flame no Ativo) — esses personagens só entram no Índice se o jogador voltar ao Dice antigo.
5. **Muro único Celestial → Forbidden** (75M → 750M = 10×; os outros degraus são de 1,7× a 4×).
6. **Rebirth 1 (10M) antes do Colossus (12,5M)** e Rebirth sem perda de Dice: renascer cedo não custa progresso, só dinheiro em caixa.
7. **Offline > ativo para o Casual** (até ~2/3 do dinheiro). Coerente com a regra "8 h ≈ 1 h ativa", mas o teto de 50% do próximo Rebirth fica alto no fim.
8. **Duplicatas não pagam nada** depois dos primeiros minutos (12–40 s de renda).
9. **Loja de gemas × Jackpot:** o Pacote de dinheiro (40 gemas) paga ~5× mais dinheiro por gema que o Jackpot.
10. **Conquista `index` desatualizada** ({6,12,18,24} para 112 personagens).
11. **Nível 50 inalcançável** (payback de 82 h no nível 40 sem multiplicadores); a curva serve até ~25–30.
12. Ferramentas antigas (`tools/sim/EconomySim.luau`, `Odds.luau`) usam o RollCore global com pity 50/800 — marcadas como LEGACY; este relatório usa só o simulador novo por Dice.
13. **Renda global por raridade** (achado depois, no Studio): todo Mítico rendia $160/s, todo Lendário $60/s, todo Divino $425/s em qualquer Dice — o Dice mais avançado não tinha valor econômico. **Corrigido:** BaseIncome = Dice × Raridade (`CharacterConfig.IncomeCurve`, seção 0; `DICE_INCOME_AUDIT.md`).

## 14. Proposta de economia (histórica) e STATUS

Proposta feita sobre o commit 07744e5. Coluna ATUAL = valor daquela época. **Status: todos os itens abaixo foram APLICADOS** (fase de economia, 473a292) — exceto a linha "Renda", substituída depois pela curva Dice × Raridade (6b4528e).

| Item | ATUAL (07744e5) | PROPOSTO | JUSTIFICATIVA | EFEITO ESPERADO |
| --- | --- | --- | --- | --- |
| Reembolso na venda | 0% | **75%** do investimento em níveis, gravado por instância (B) | troca de estação sem destruir o investimento; 25% continua sink; prova de não-lucro | liberdade de troca; impacto de progressão ≈ 0 |
| Fusão | resultado = maior nível | resultado soma `UpgradeInvestment` das cópias (refund futuro) — nível continua o maior | fusão deixa de punir quem upou a cópia errada | mais fusões; nenhum dinheiro novo |
| Preço Forbidden | 750M (10× Celestial) | 750M → **400M** (≈5× Celestial), requisito 12.000 rolls mantido | único degrau de 10×; o requisito de rolls (3,3 h) chega ~1 h antes do dinheiro no Ativo | Forbidden ~30–40 min mais cedo para Ativo/Otimizador; Casual inalterado (já limitado por rolls) |
| Requisito de rolls Shinobi→Blade | 300 / 425 / 550 | 300 / 450 / 650 | no Ativo a missão dos 10 min paga Shinobi+Flame+Blade de uma vez (92% nunca rolam o Shinobi) | cada Dice rolado ≥ 2 min; Índice completo sem voltar |
| Preços de Dice (exceto Forbidden) | 2,5K…75M | **manter** | espera de 10–15 min por dinheiro por Dice (Ativo) é um ritmo saudável | — |
| Requisito de rolls Celestial | 8.000 | manter | — | — |
| Renda | BaseIncome provisório por raridade (L 60 · M 160 · D 425 em todo Dice) | **SUBSTITUÍDO:** Dice × Raridade (`CharacterConfig.IncomeCurve`, 1,11 por Dice, pivô 0,10) | o Dice mais avançado precisa ter valor econômico | ver seção 0 e `DICE_INCOME_AUDIT.md` |
| Duplicatas | 12–40 s de renda | C/U 20 · R 25 · E 30 · L 35 · M 45 · D 60 · S 90 s | dar valor ao "rolar sem nada novo" do meio do jogo | duplicatas ≈ 3–5% do dinheiro em 5 h (hoje ~1%) |
| Custo de nível | 60 s × 1,2^(L−1) | manter a curva; **MaxLevel 50 → 30** (ou crescimento 1,2 → 1,15 depois do 20) | o 31–50 nunca é comprado | teto alcançável e visível |
| Rebirth | 10M × 2,2^n | 1º Rebirth 10M → **15M** (crescimento igual) | primeiro Rebirth depois do Colossus, não antes | 1º Rebirth ~15–20 min mais tarde para o Ativo |
| Prisma | 3 usos, teto 21 | **manter** | Casual não perde carga; 3 usos fecham os Secretos | — |
| Offline | 12%, 8 h, teto 50% do próximo Rebirth | teto 50% → **25%** do próximo Rebirth | o Casual ganha mais offline que jogando | Casual com ~50% offline em vez de ~2/3 |
| Conquista `index` | 6/12/18/24 | 14/28/56/112 (12,5/25/50/100%) | roster 112 | conquista volta a funcionar como meta |
| Loja de gemas | Pacote 40 gemas = 900 s | 60 gemas = 900 s, ou Jackpot dinheiro 600 → 1.200 s | equilibrar gema → dinheiro | Jackpot volta a ser opção |

Aplicado: as tabelas das seções 1–12 deste documento já são do jogo atual (economia aplicada + renda Dice × Raridade).

## Método e limites

- Renda: BaseIncome de cada personagem lido de `CharacterConfig` (F2P = `IncomeCurve` Dice × Raridade; Premium/Legacy = renda própria). A linha de base histórica da renda por raridade fica em `tools/sim/dice_income_baseline.json` (não é sobrescrita).
- Simulador: `tools/sim/EconomyModel.luau` (puro). Roll **idêntico** ao `DiceCore.roll` (provado roll a roll em `tests/EconomyModel.spec.luau`): pesos de produção, Luck real (Dice × upgrade × boosts × Rebirth × gamepass, softcap 10), pity Lendário 50 / Mítico 250, Dice selecionado = o melhor comprado. Renda, níveis, venda (SaleCore), upgrades, Rebirth, torres (BattleCore), Jackpot, Diário, Missões, Offline, Fusão e Prisma (DiceCore:prismPick) vêm dos módulos e configs reais.
- Monte Carlo: 10000 jogadores por perfil até 1 h (retenção) e 2000 por perfil até 20 h. Menos de 10.000 no horizonte de 20 h porque cada jogador de 20 h custa 0,2–0,7 s (≈ 25 min para tudo em 4 núcleos). Convergência medida: diferença entre as duas metades da amostra (sementes pares × ímpares) no ganho total de 20 h — Casual F2P ≤ 1.1%, Ativo F2P ≤ 0.4%, Otimizador F2P ≤ 1.8%, Pago Moderado ≤ 0.8%. Sensibilidades (refund, Prisma, Rebirth) com 150 jogadores por variante e as MESMAS sementes entre variantes.
- Tempo = jogo ATIVO. O offline é aplicado entre as sessões do perfil (relógio real).
- Limites: agente simples (não troca Dice para caçar personagem fora do Prisma, não usa a loja de gemas, não negocia); torres só pela 1ª vitória; sem amigos no servidor.
- Reproduzir: `python3 tools/sim/run_economy_analysis.py` (≈ 25 min em 4 núcleos; `--scale 0.01` ≈ 30 s).

