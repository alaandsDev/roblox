# ROLL LEGENDS — Auditoria e balanceamento da economia

> Gerado por `python3 tools/sim/run_economy_analysis.py` (simulador `tools/sim/EconomyModel.luau`).
> **Somente análise e proposta. Nada desta proposta foi aplicado ao jogo.** Os números do jogo
> (preços, custos, renda, venda, Rebirth, Prisma) são os de produção do commit 07744e5.

Amostra: 10000 jogadores/perfil até 1 h · 2000 jogadores/perfil até 20 h · 150 por variante de refund · 150 por variante de Prisma · 150 por política de Rebirth.

## Resumo executivo

- **Ritmo de Dice regular, com um muro no fim.** O Ativo F2P compra o Forbidden em ~4.4 h de jogo ativo (P50) e o Casual em ~4.8 h. Para o Casual o gargalo é o requisito de **rolls** (o offline paga os preços); para Ativo/Otimizador o requisito de rolls chega primeiro e o **dinheiro** atrasa cada Dice em ~10–15 min. O único muro grande é Celestial → Forbidden (75M → 750M, 10×; ~1.0 h de espera por dinheiro no Ativo).
- **Os pools são pequenos (6–8 personagens por Dice) e completam em segundos/minutos**: depois disso o jogador rola o mesmo Dice sem nada novo até liberar o próximo (ex.: ~6228 rolls sem novidade no Celestial, P50 Ativo). A coleção não segura a sessão no meio do jogo — quem segura é a espera pelo próximo Dice.
- **Rebirth é obrigatório:** com 20 h, quem renasce tem renda/s ~41× maior que quem nunca renasce (Ativo, política medium × never); ao renascer, ~90% do dinheiro acumulado some no reset.
- **Offline é a maior fonte do Casual** (68% do dinheiro em 20 h ativas): 8 h offline a 12% ≈ 1 h de renda ativa, e o Casual joga só 20 min/dia.
- **Venda ignora o nível:** um Lendário nível 20 custou 557K em níveis e vende por 1,2K (0,2%). A troca de estação destrói o investimento — é o maior atrito de "liberdade de troca" da economia.
- **Duplicatas quase não pagam nada** fora dos primeiros minutos (venda = 12–40 s de renda da própria unidade).
- **Prisma:** com 3 usos por recompensa e teto 21, o Casual (que mais depende dele) não perde cargas; o Ativo recebe 1 recompensa a cada 7 dias reais, o que limita o impacto.
- **Recomendação central (não aplicada):** reembolso de **75%** do investimento em níveis na venda, com investimento gravado por instância no servidor (opção B), mais ajustes de pacing do meio do jogo e um degrau entre Celestial e Forbidden (seção 14).


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
| 10 min | Shinobi (4) [3–4] | 59.41K | 75.77K / 132.04K / 199.27K | 195 | 22 / 30 / 30 | 0 / 0 / 0 | 3.0 |
| 30 min | Storm (8) [8–8] | 2.46M | 3.41M / 4.10M / 5.34M | 1.15K | 50 / 51 / 58 | 0 / 0 / 0 | 9.0 |
| 1 h | Shadow (11) [10–11] | 6.26M | 12.16M / 13.86M / 16.30M | 2.21K | 65 / 70 / 73 | 0 / 0 / 1 | 7.0 |
| 3 h | Awakened (14) [14–14] | 82.68M | 381.51M / 547.13M / 816.96M | 55.45K | 93 / 94 / 98 | 4 / 4 / 5 | 15.0 |
| 5 h | Forbidden (16) [15–16] | 271.16M | 3.08B / 3.90B / 4.81B | 163.98K | 103 / 107 / 110 | 7 / 7 / 7 | 17.0 |
| 10 h | Forbidden (16) [16–16] | 2.28B | 25.17B / 27.13B / 31.06B | 491.53K | 112 / 112 / 112 | 9 / 10 / 10 | 19.0 |
| 20 h | Forbidden (16) [16–16] | 15.31B | 107.00B / 121.71B / 139.56B | 787.42K | 112 / 112 / 112 | 11 / 12 / 12 | 20.0 |

### Ativo F2P

| Tempo ativo | Dice | Money (saldo) | Ganho total | Renda/s | Index (/112) | Rebirth | Upgrade médio (nível) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 10 min | Rampart (3) [3–3] | 271.07K | 333.69K / 462.62K / 617.55K | 530 | 22 / 22 / 22 | 0 / 0 / 0 | 9.5 |
| 30 min | Fighter (7) [7–8] | 197.50K | 2.39M / 3.03M / 3.57M | 3.07K | 37 / 43 / 44 | 0 / 0 / 0 | 16.5 |
| 1 h | Shadow (11) [11–12] | 2.40M | 10.65M / 14.01M / 21.46M | 6.16K | 66 / 70 / 72 | 0 / 0 / 0 | 16.8 |
| 3 h | Celestial (15) [15–15] | 40.11M | 309.55M / 455.63M / 668.54M | 101.75K | 89 / 91 / 97 | 3 / 3 / 4 | 20.9 |
| 5 h | Forbidden (16) [15–16] | 333.11M | 1.77B / 2.39B / 3.12B | 261.18K | 91 / 95 / 102 | 5 / 6 / 6 | 23.2 |
| 10 h | Forbidden (16) [16–16] | 4.66B | 13.61B / 18.37B / 22.94B | 641.88K | 95 / 97 / 103 | 9 / 9 / 9 | 25.0 |
| 20 h | Forbidden (16) [16–16] | 36.34B | 76.57B / 95.34B / 112.57B | 1.38M | 98 / 101 / 107 | 11 / 11 / 11 | 26.3 |

### Otimizador F2P

| Tempo ativo | Dice | Money (saldo) | Ganho total | Renda/s | Index (/112) | Rebirth | Upgrade médio (nível) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 10 min | Rampart (3) [3–3] | 277.42K | 346.50K / 499.46K / 663.79K | 553 | 20 / 22 / 22 | 0 / 0 / 0 | 12.0 |
| 30 min | Blade (6) [5–7] | 88.20K | 2.18M / 2.73M / 3.29M | 3.14K | 28 / 35 / 37 | 0 / 0 / 0 | 18.0 |
| 1 h | Shadow (11) [10–11] | 1.45M | 11.04M / 12.88M / 16.98M | 5.80K | 59 / 65 / 71 | 0 / 0 / 0 | 19.5 |
| 3 h | Celestial (15) [14–15] | 25.38M | 267.70M / 370.31M / 517.10M | 98.09K | 87 / 91 / 97 | 2 / 3 / 3 | 22.7 |
| 5 h | Forbidden (16) [15–16] | 361.05M | 1.65B / 2.32B / 3.06B | 270.16K | 90 / 95 / 102 | 5 / 5 / 6 | 25.4 |
| 10 h | Forbidden (16) [16–16] | 2.97B | 11.15B / 13.87B / 18.90B | 655.98K | 94 / 97 / 104 | 8 / 9 / 9 | 27.1 |
| 20 h | Forbidden (16) [16–16] | 18.66B | 54.47B / 71.39B / 88.11B | 1.58M | 95 / 98 / 104 | 10 / 11 / 11 | 29.2 |

### Pago Moderado

| Tempo ativo | Dice | Money (saldo) | Ganho total | Renda/s | Index (/112) | Rebirth | Upgrade médio (nível) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 10 min | Shinobi (4) [4–5] | 580.40K | 771.14K / 1.07M / 1.40M | 1.08K | 30 / 30 / 36 | 0 / 0 / 0 | 13.5 |
| 30 min | Spirit (9) [9–9] | 655.59K | 6.72M / 8.37M / 9.65M | 10.21K | 44 / 51 / 59 | 0 / 0 / 0 | 19.8 |
| 1 h | Colossus (13) [12–14] | 6.47M | 42.87M / 59.13M / 126.60M | 38.86K | 70 / 78 / 86 | 0 / 0 / 1 | 19.4 |
| 3 h | Forbidden (16) [15–16] | 316.79M | 1.46B / 2.11B / 2.99B | 438.51K | 84 / 95 / 103 | 5 / 5 / 6 | 25.7 |
| 5 h | Forbidden (16) [16–16] | 1.93B | 6.55B / 9.46B / 12.54B | 975.80K | 88 / 97 / 105 | 7 / 8 / 8 | 27.3 |
| 10 h | Forbidden (16) [16–16] | 17.63B | 52.01B / 69.53B / 83.17B | 2.42M | 89 / 98 / 106 | 10 / 11 / 11 | 29.3 |
| 20 h | Forbidden (16) [16–16] | 60.76B | 262.06B / 306.66B / 342.55B | 4.43M | 92 / 101 / 109 | 13 / 13 / 13 | 30.6 |


## 2. Tempo para comprar cada Dice (tempo ATIVO; P10 / P50 / P90)

`Liberado por rolls` = quando atingiu o requisito de rolls do Dice; `Espera por dinheiro` = quanto tempo depois disso ainda faltava dinheiro. Espera ~0 = o requisito de **rolls** é o gargalo; espera longa = o **preço** é o gargalo. `Completion antes do próximo?` = fração dos jogadores que já tinham 100% / ≥90% / <50% do pool quando compraram o próximo Dice (<50% quase sempre = Dice pulado: comprou dois de uma vez e nunca rolou o anterior).

Leitura (Ativo F2P):
- Rampart: gargalo misto (espera P50 2.4 min depois de liberar por rolls).
- Shinobi: gargalo **dinheiro** (espera P50 5.2 min depois de liberar por rolls).
- Flame: gargalo misto (espera P50 3.2 min depois de liberar por rolls).
- Blade: gargalo misto (espera P50 1.1 min depois de liberar por rolls).
- Fighter: gargalo **dinheiro** (espera P50 11.6 min depois de liberar por rolls).
- Storm: gargalo **dinheiro** (espera P50 14.3 min depois de liberar por rolls).
- Spirit: gargalo **dinheiro** (espera P50 11.0 min depois de liberar por rolls).
- Arcane: gargalo **dinheiro** (espera P50 12.2 min depois de liberar por rolls).
- Shadow: gargalo **dinheiro** (espera P50 12.3 min depois de liberar por rolls).
- Void: gargalo **dinheiro** (espera P50 10.2 min depois de liberar por rolls).
- Colossus: gargalo **dinheiro** (espera P50 7.2 min depois de liberar por rolls).
- Awakened: gargalo **dinheiro** (espera P50 17.0 min depois de liberar por rolls).
- Celestial: gargalo **dinheiro** (espera P50 11.2 min depois de liberar por rolls).
- Forbidden: gargalo **dinheiro** (espera P50 1.0 h depois de liberar por rolls).
- Lucky: limitado pelos rolls. No Casual quase todos os Dice são limitados pelos rolls (espera por dinheiro < 1 min), porque o offline paga os preços entre as sessões.

### Casual F2P

| Dice | Unlock (rolls) | Price | P10 | P50 | P90 | Comprou em 20 h | Liberado por rolls (P50) | Espera por dinheiro (P50) | Completion antes do próximo? |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Starter | 0 | 0 | 0 | 0 | 0 | 100% | — | — | 100%: 98% · ≥90%: 98% · <50%: 0% |
| Lucky | 50 | 2.50K | 3.0 min | 3.0 min | 3.0 min | 100% | 1.2 min | 1.8 min | 100%: 78% · ≥90%: 78% · <50%: 22% |
| Rampart | 125 | 10.00K | 3.0 min | 6.0 min | 6.0 min | 100% | 3.0 min | 3.0 min | 100%: 99% · ≥90%: 99% · <50%: 0% |
| Shinobi | 300 | 40.00K | 9.0 min | 9.0 min | 11.0 min | 100% | 7.1 min | 1.9 min | 100%: 97% · ≥90%: 97% · <50%: 3% |
| Flame | 425 | 75.00K | 11.0 min | 12.0 min | 16.0 min | 100% | 10.1 min | 2.0 min | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Blade | 550 | 125.00K | 16.0 min | 18.0 min | 21.0 min | 100% | 13.1 min | 4.4 min | 100%: 59% · ≥90%: 59% · <50%: 41% |
| Fighter | 775 | 225.00K | 21.0 min | 21.0 min | 21.0 min | 100% | 18.4 min | 2.5 min | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Storm | 1000 | 400.00K | 24.0 min | 24.0 min | 25.0 min | 100% | 23.8 min | 29s | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Spirit | 1500 | 750.00K | 36.0 min | 36.0 min | 37.0 min | 100% | 35.7 min | 30s | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Arcane | 2000 | 1.40M | 47.0 min | 48.0 min | 49.0 min | 100% | 47.6 min | 31s | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Shadow | 2500 | 2.60M | 59.0 min | 1.0 h | 1.2 h | 100% | 59.5 min | 48s | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Void | 3000 | 5.00M | 1.2 h | 1.3 h | 1.4 h | 100% | 1.2 h | 6.1 min | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Colossus | 4500 | 12.50M | 1.8 h | 1.8 h | 1.9 h | 100% | 1.8 h | 48s | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Awakened | 6000 | 30.00M | 2.4 h | 2.4 h | 2.5 h | 100% | 2.4 h | 37s | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Celestial | 8000 | 75.00M | 3.2 h | 3.2 h | 3.4 h | 100% | 3.2 h | 46s | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Forbidden | 12000 | 750.00M | 4.8 h | 4.8 h | 5.0 h | 100% | 4.8 h | 53s | último Dice |

### Ativo F2P

| Dice | Unlock (rolls) | Price | P10 | P50 | P90 | Comprou em 20 h | Liberado por rolls (P50) | Espera por dinheiro (P50) | Completion antes do próximo? |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Starter | 0 | 0 | 0 | 0 | 0 | 100% | — | — | 100%: 97% · ≥90%: 97% · <50%: 0% |
| Lucky | 50 | 2.50K | 1.0 min | 1.5 min | 1.8 min | 100% | 50s | 40s | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Rampart | 125 | 10.00K | 3.5 min | 4.5 min | 5.0 min | 100% | 2.1 min | 2.4 min | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Shinobi | 300 | 40.00K | 10.2 min | 10.2 min | 10.2 min | 100% | 5.0 min | 5.2 min | 100%: 8% · ≥90%: 8% · <50%: 92% |
| Flame | 425 | 75.00K | 10.2 min | 10.2 min | 10.2 min | 100% | 7.1 min | 3.2 min | 100%: 49% · ≥90%: 49% · <50%: 51% |
| Blade | 550 | 125.00K | 10.2 min | 10.2 min | 24.5 min | 100% | 9.2 min | 1.1 min | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Fighter | 775 | 225.00K | 22.0 min | 24.5 min | 28.0 min | 100% | 12.9 min | 11.6 min | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Storm | 1000 | 400.00K | 29.0 min | 31.0 min | 33.5 min | 100% | 16.7 min | 14.3 min | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Spirit | 1500 | 750.00K | 34.0 min | 36.0 min | 38.0 min | 100% | 25.0 min | 11.0 min | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Arcane | 2000 | 1.40M | 42.5 min | 45.5 min | 50.0 min | 100% | 33.3 min | 12.2 min | 100%: 85% · ≥90%: 85% · <50%: 13% |
| Shadow | 2500 | 2.60M | 45.5 min | 54.0 min | 57.5 min | 100% | 41.7 min | 12.3 min | 100%: 96% · ≥90%: 96% · <50%: 2% |
| Void | 3000 | 5.00M | 55.5 min | 1.0 h | 1.0 h | 100% | 50.0 min | 10.2 min | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Colossus | 4500 | 12.50M | 1.2 h | 1.4 h | 1.5 h | 100% | 1.2 h | 7.2 min | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Awakened | 6000 | 30.00M | 1.7 h | 1.9 h | 2.0 h | 100% | 1.7 h | 17.0 min | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Celestial | 8000 | 75.00M | 2.2 h | 2.4 h | 2.7 h | 100% | 2.2 h | 11.2 min | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Forbidden | 12000 | 750.00M | 4.0 h | 4.4 h | 5.0 h | 100% | 3.3 h | 1.0 h | último Dice |

### Otimizador F2P

| Dice | Unlock (rolls) | Price | P10 | P50 | P90 | Comprou em 20 h | Liberado por rolls (P50) | Espera por dinheiro (P50) | Completion antes do próximo? |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Starter | 0 | 0 | 0 | 0 | 0 | 100% | — | — | 100%: 96% · ≥90%: 96% · <50%: 0% |
| Lucky | 50 | 2.50K | 1.2 min | 1.7 min | 1.8 min | 100% | 50s | 50s | 100%: 62% · ≥90%: 62% · <50%: 1% |
| Rampart | 125 | 10.00K | 2.1 min | 2.1 min | 4.1 min | 100% | 2.1 min | 0s | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Shinobi | 300 | 40.00K | 10.1 min | 10.1 min | 10.1 min | 100% | 5.0 min | 5.1 min | 100%: 9% · ≥90%: 9% · <50%: 91% |
| Flame | 425 | 75.00K | 10.1 min | 10.1 min | 10.1 min | 100% | 7.1 min | 3.0 min | 100%: 49% · ≥90%: 49% · <50%: 51% |
| Blade | 550 | 125.00K | 10.1 min | 10.1 min | 31.5 min | 100% | 9.2 min | 55s | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Fighter | 775 | 225.00K | 28.0 min | 30.7 min | 33.7 min | 100% | 12.9 min | 17.8 min | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Storm | 1000 | 400.00K | 35.5 min | 38.0 min | 40.5 min | 100% | 16.7 min | 21.3 min | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Spirit | 1500 | 750.00K | 41.5 min | 43.8 min | 46.3 min | 100% | 25.0 min | 18.8 min | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Arcane | 2000 | 1.40M | 48.2 min | 51.0 min | 56.5 min | 100% | 33.3 min | 17.7 min | 100%: 91% · ≥90%: 91% · <50%: 8% |
| Shadow | 2500 | 2.60M | 56.0 min | 59.7 min | 1.1 h | 100% | 41.7 min | 18.0 min | 100%: 97% · ≥90%: 97% · <50%: 3% |
| Void | 3000 | 5.00M | 1.1 h | 1.2 h | 1.3 h | 100% | 50.0 min | 24.3 min | 100%: 99% · ≥90%: 99% · <50%: 0% |
| Colossus | 4500 | 12.50M | 1.3 h | 1.6 h | 1.8 h | 100% | 1.2 h | 21.2 min | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Awakened | 6000 | 30.00M | 1.9 h | 2.1 h | 2.3 h | 100% | 1.7 h | 25.5 min | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Celestial | 8000 | 75.00M | 2.5 h | 2.7 h | 3.0 h | 100% | 2.2 h | 31.2 min | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Forbidden | 12000 | 750.00M | 4.2 h | 4.6 h | 5.3 h | 100% | 3.3 h | 1.3 h | último Dice |

### Pago Moderado

| Dice | Unlock (rolls) | Price | P10 | P50 | P90 | Comprou em 20 h | Liberado por rolls (P50) | Espera por dinheiro (P50) | Completion antes do próximo? |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Starter | 0 | 0 | 0 | 0 | 0 | 100% | — | — | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Lucky | 50 | 2.50K | 30s | 1.0 min | 1.0 min | 100% | 25s | 35s | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Rampart | 125 | 10.00K | 1.8 min | 1.8 min | 3.0 min | 100% | 1.1 min | 42s | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Shinobi | 300 | 40.00K | 5.2 min | 5.2 min | 5.2 min | 100% | 2.5 min | 2.8 min | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Flame | 425 | 75.00K | 9.5 min | 10.2 min | 10.2 min | 100% | 3.5 min | 6.7 min | 100%: 28% · ≥90%: 28% · <50%: 67% |
| Blade | 550 | 125.00K | 10.2 min | 10.2 min | 10.2 min | 100% | 4.6 min | 5.7 min | 100%: 34% · ≥90%: 34% · <50%: 66% |
| Fighter | 775 | 225.00K | 10.2 min | 10.2 min | 20.0 min | 100% | 6.5 min | 3.8 min | 100%: 82% · ≥90%: 82% · <50%: 18% |
| Storm | 1000 | 400.00K | 10.2 min | 23.0 min | 25.5 min | 100% | 8.3 min | 14.7 min | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Spirit | 1500 | 750.00K | 24.0 min | 26.0 min | 28.5 min | 100% | 12.5 min | 13.5 min | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Arcane | 2000 | 1.40M | 30.5 min | 33.5 min | 35.5 min | 100% | 16.7 min | 16.8 min | 100%: 83% · ≥90%: 83% · <50%: 17% |
| Shadow | 2500 | 2.60M | 30.5 min | 37.5 min | 40.0 min | 100% | 20.8 min | 16.7 min | 100%: 83% · ≥90%: 83% · <50%: 17% |
| Void | 3000 | 5.00M | 35.5 min | 45.0 min | 48.5 min | 100% | 25.0 min | 20.0 min | 100%: 97% · ≥90%: 97% · <50%: 1% |
| Colossus | 4500 | 12.50M | 47.0 min | 56.5 min | 1.0 h | 100% | 37.5 min | 19.0 min | 100%: 94% · ≥90%: 94% · <50%: 6% |
| Awakened | 6000 | 30.00M | 57.0 min | 1.2 h | 1.4 h | 100% | 50.0 min | 25.0 min | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Celestial | 8000 | 75.00M | 1.5 h | 1.6 h | 1.9 h | 100% | 1.1 h | 32.3 min | 100%: 100% · ≥90%: 100% · <50%: 0% |
| Forbidden | 12000 | 750.00M | 2.5 h | 2.9 h | 3.2 h | 100% | 1.7 h | 1.2 h | último Dice |


## 3. Completion de cada Dice × próximo desbloqueio (Ativo F2P)

Pools por Dice: 6–8 personagens. Até o Awakened o 100% sai em segundos ou poucos minutos depois da compra; só Celestial (3 Divinos) e Forbidden (3 Divinos + 3 Secretos) têm caça longa. **"Rolar sem nada novo" é a regra no meio do jogo**: o tempo entre completar o Dice e comprar o próximo (coluna `Próximo comprado`, 5–30 min no meio do jogo) é gasto inteiro em rolls repetidos — a recompensa desse tempo é só a venda de duplicata (centavos) e o progresso para o requisito de rolls.

| Dice | 50% | 75% | 90% | 100% | Próximo liberado por rolls | Próximo comprado | Rolls sem nada novo (P50) | Completou 100% (20 h) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Starter | 5s | 10s | 29s | 29s | 50s | 1.5 min | 46 | 99% |
| Lucky | 6s | 14s | 27s | 27s | 35s | 3.0 min | 150 | 100% |
| Rampart | 6s | 17s | 33s | 33s | 30s | 5.8 min | 314 | 100% |
| Shinobi | 5s | 10s | 23s | 23s | 0s | 0s | 0 | 8% |
| Flame | 4s | 11s | 50s | 50s | 0s | 0s | 0 | 49% |
| Blade | 5s | 10s | 29s | 29s | 2.7 min | 10.2 min | 571 | 100% |
| Fighter | 5s | 12s | 20s | 20s | 0s | 6.5 min | 370 | 100% |
| Storm | 5s | 13s | 27s | 27s | 0s | 4.5 min | 251 | 100% |
| Spirit | 6s | 18s | 55s | 55s | 0s | 9.5 min | 488 | 100% |
| Arcane | 5s | 10s | 30s | 30s | 0s | 8.0 min | 454 | 87% |
| Shadow | 6s | 16s | 42s | 42s | 0s | 5.8 min | 302 | 98% |
| Void | 4s | 11s | 2.7 min | 2.7 min | 14.8 min | 22.8 min | 1157 | 100% |
| Colossus | 3s | 9s | 16s | 16s | 17.8 min | 33.0 min | 1964 | 100% |
| Awakened | 4s | 13s | 29s | 29s | 16.3 min | 31.2 min | 1838 | 100% |
| Celestial | 7s | 4.7 min | 11.2 min | 11.2 min | 55.5 min | 1.9 h | 6228 | 100% |
| Forbidden | 8.0 min | 5.5 h | 7.4 h | 7.4 h | — | — | 28785 | 100% |

Tempos de completion contados a partir da compra do Dice (P50 de quem chegou ao marco).


## 4. Fontes de dinheiro

| Fonte | Valor | Frequência | Condição | Multiplicadores | F2P / Pago | Autoritativo no servidor? |
| --- | --- | --- | --- | --- | --- | --- |
| Coletor (renda das estações) | Σ BaseIncome × (1 + 0,25·(nível−1)) × variante (1/1,5/2/3/4/6/10) | por segundo, acumula no coletor (teto 1 h de renda) | personagem equipado na base | Renda global +10%/nível (25), Rebirth +25%/rebirth, perk Renda +15%/nível, VIP ×1,5, amigos +5% (até 25%) | F2P (VIP pago) | sim (IncomeService/EconomyService) |
| Dinheiro offline | 12% × renda/s × min(offline, 8 h) | ao voltar (≥ 60 s fora) | relógio do servidor | teto = 50% do custo do próximo Rebirth | F2P | sim (OfflineCore, os.time) |
| Venda de personagem | BaseIncome × SellSeconds (C/U 12 · R 15 · E 18 · L 20 · M 25 · D 30 · S 40 s) × variante | por venda / auto-sell | não travado/favorito/equipado/em troca | **nível ignorado** | F2P | sim (SellService, agora via SaleCore) |
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
| Casual F2P | 1.0 h | 31% | 53% | 5% | 0% | 3% | 7% | 0% | 0% |
| Casual F2P | 5.0 h | 28% | 63% | 0% | 0% | 0% | 7% | 2% | 0% |
| Casual F2P | 20.0 h | 24% | 68% | 0% | 0% | 0% | 6% | 2% | 0% |
| Ativo F2P | 1.0 h | 70% | 0% | 7% | 0% | 5% | 1% | 0% | 16% |
| Ativo F2P | 5.0 h | 75% | 14% | 1% | 0% | 1% | 5% | 0% | 3% |
| Ativo F2P | 20.0 h | 52% | 42% | 0% | 0% | 0% | 3% | 0% | 3% |
| Otimizador F2P | 1.0 h | 79% | 0% | 6% | 0% | 4% | 2% | 0% | 10% |
| Otimizador F2P | 5.0 h | 78% | 9% | 1% | 0% | 1% | 5% | 0% | 5% |
| Otimizador F2P | 20.0 h | 70% | 24% | 0% | 0% | 0% | 2% | 1% | 3% |
| Pago Moderado | 1.0 h | 66% | 0% | 6% | 0% | 9% | 1% | 0% | 18% |
| Pago Moderado | 5.0 h | 72% | 16% | 1% | 0% | 1% | 5% | 0% | 5% |
| Pago Moderado | 20.0 h | 52% | 42% | 0% | 0% | 0% | 3% | 0% | 2% |


## 5. Sinks (para onde o dinheiro vai)

| Sink | Custo inicial | Curva | Acumulado | Limite | Dependências / reset |
| --- | --- | --- | --- | --- | --- |
| Dice (16) | 2,5K | fixo por posição (até 750M) | 878.13M todos | 16 | rolls exigidos + Dice anterior; **não reseta** no Rebirth |
| Níveis de estação | BaseIncome × 60 | × 1,2 por nível | BaseIncome × 2,27M até o 50 (ver seção 6) | nível 50 | personagem equipado; **perdido na venda/fusão** |
| Upgrade Luck | 2K | × 1,9 | 835.33M (20 níveis) | 20 | **reseta** no Rebirth |
| Upgrade Renda | 1,5K | × 1,85 | 8.43B (25 níveis) | 25 | **reseta** no Rebirth |
| Upgrade Inventário | 1K | × 1,7 | 58.06M (20 níveis) | 20 | mantido |
| Velocidade de Roll | — | desligado (cadência fixa por config) | — | — | — |
| Fusão | BaseIncome × 600 × ordem da variante + 2–3 cópias | por degrau | Normal→Celestial = 3·3·3·3·2·2·2 = 648 cópias | Celestial | resultado mantém o MAIOR nível; o investimento das outras cópias é perdido |
| Rebirth | 10M | × 2,2 | 22.12B até o 10º | 36 | zera dinheiro, coletor, Luck/Renda; mantém Dice, personagens, Índice, torres, gemas |
| Gemas | Jackpot 150 · sorte 60 · dinheiro 40 | — | — | — | — |

Destino do dinheiro (agregado; "Rebirth" = saldo zerado ao renascer):

| Perfil | Tempo | Dice | Níveis de estação | Upgrade Luck | Upgrade Renda | Upgrade Inventário | Fusão | Rebirth (saldo zerado) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Casual F2P | 1.0 h | 50% | 8% | 6% | 2% | 4% | 0% | 31% |
| Casual F2P | 5.0 h | 22% | 1% | 5% | 1% | 2% | 0% | 70% |
| Casual F2P | 20.0 h | 1% | 0% | 4% | 0% | 0% | 0% | 95% |
| Ativo F2P | 1.0 h | 49% | 18% | 9% | 7% | 10% | 7% | 0% |
| Ativo F2P | 5.0 h | 38% | 3% | 17% | 4% | 3% | 1% | 35% |
| Ativo F2P | 20.0 h | 1% | 1% | 7% | 1% | 0% | 0% | 90% |
| Otimizador F2P | 1.0 h | 38% | 26% | 6% | 14% | 8% | 8% | 0% |
| Otimizador F2P | 5.0 h | 34% | 5% | 14% | 9% | 3% | 1% | 34% |
| Otimizador F2P | 20.0 h | 2% | 1% | 7% | 2% | 0% | 0% | 88% |
| Pago Moderado | 1.0 h | 36% | 21% | 8% | 10% | 6% | 6% | 12% |
| Pago Moderado | 5.0 h | 12% | 3% | 17% | 5% | 1% | 0% | 63% |
| Pago Moderado | 20.0 h | 0% | 0% | 2% | 1% | 0% | 0% | 96% |


## 6. Curva de upgrade de personagem (estação)

Fórmula (CharacterLevelConfig): custo L→L+1 = floor(BaseIncome × 60 × 1,2^(L−1)); renda = BaseIncome × (1 + 0,25·(L−1)). O **payback de um nível não depende da raridade**: 240 s × 1,2^(L−1) ÷ (variante × multiplicadores do jogador). Sem multiplicadores, o nível 10 se paga em ~21 min, o 20 em ~2 h, o 30 em ~13 h e o 40 em ~82 h — o nível 50 é inalcançável na prática (acumulado = 2,27 milhões × BaseIncome). Com os multiplicadores de Rebirth/Renda (×10–15 no fim), o "muro" efetivo fica entre os níveis 25 e 30, que é onde os perfis param (Upgrade médio na tabela principal).

Venda base = 12–40 × BaseIncome. **No nível 10 o jogador já pôs 104× o valor de venda em níveis (Comum) e no nível 20, 773×** — é isso que a troca de estação joga fora hoje.

| Nível | Custo L→L+1 (× BaseIncome) | Acumulado até L (× BaseIncome) | Renda no nível (× BaseIncome) | Payback do nível (Normal) | Venda base Comum/Mítico (× BaseIncome) |
| --- | --- | --- | --- | --- | --- |
| 1 | 60 | 0 | 1.00 | 4.0 min | 12 / 25 |
| 2 | 72 | 60 | 1.25 | 4.8 min | 12 / 25 |
| 5 | 124 | 322 | 2.00 | 8.3 min | 12 / 25 |
| 10 | 310 | 1.25K | 3.25 | 20.6 min | 12 / 25 |
| 15 | 770 | 3.55K | 4.50 | 51.4 min | 12 / 25 |
| 20 | 1.92K | 9.28K | 5.75 | 2.1 h | 12 / 25 |
| 25 | 4.77K | 23.55K | 7.00 | 5.3 h | 12 / 25 |
| 30 | 11.87K | 59.04K | 8.25 | 13.2 h | 12 / 25 |
| 40 | 73.49K | 367.14K | 10.75 | 81.7 h | 12 / 25 |
| 50 | máx | 2.27M | 13.25 | — | 12 / 25 |

Investimento acumulado por raridade (BaseIncome provisório de lançamento):

| Raridade (BaseIncome) | Nível 2 | Nível 10 | Nível 20 | Nível 30 | Nível 50 | Venda base |
| --- | --- | --- | --- | --- | --- | --- |
| Common (1) | 60 | 1.24K | 9.28K | 59.03K | 2.27M | 12 |
| Uncommon (4) | 240 | 4.99K | 37.13K | 236.16K | 9.10M | 48 |
| Rare (9) | 540 | 11.23K | 83.55K | 531.38K | 20.47M | 135 |
| Epic (25) | 1.50K | 31.19K | 232.10K | 1.48M | 56.87M | 450 |
| Legendary (60) | 3.60K | 74.87K | 557.05K | 3.54M | 136.49M | 1.20K |
| Mythic (160) | 9.60K | 199.67K | 1.49M | 9.45M | 363.97M | 4.00K |
| Divine (425) | 25.50K | 530.37K | 3.95M | 25.09M | 966.79M | 12.75K |
| Secret (1200) | 72.00K | 1.50M | 11.14M | 70.85M | 2.73B | 48.00K |

Minutos de renda (P50 do Ativo F2P no momento em que compra o Dice) para levar UMA unidade da raridade mais comum do Dice entre níveis:

| Dice | Renda/s na compra (P50) | Raridade típica | 1→10 | 10→20 | 20→30 | 30→50 |
| --- | --- | --- | --- | --- | --- | --- |
| Starter | 530 | Common (1) | 2s | 15s | 1.6 min | 1.2 h |
| Lucky | 86 | Common (1) | 14s | 1.6 min | 9.6 min | 7.1 h |
| Rampart | 203 | Common (1) | 6s | 40s | 4.1 min | 3.0 h |
| Shinobi | 534 | Common (1) | 2s | 15s | 1.6 min | 1.2 h |
| Flame | 534 | Uncommon (4) | 9s | 1.0 min | 6.2 min | 4.6 h |
| Blade | 577 | Uncommon (4) | 9s | 56s | 5.8 min | 4.3 h |
| Fighter | 2.63K | Uncommon (4) | 2s | 12s | 1.3 min | 56.2 min |
| Storm | 3.16K | Rare (9) | 4s | 23s | 2.4 min | 1.8 h |
| Spirit | 3.16K | Rare (9) | 4s | 23s | 2.4 min | 1.8 h |
| Arcane | 6.06K | Rare (9) | 2s | 12s | 1.2 min | 54.8 min |
| Shadow | 6.06K | Epic (25) | 5s | 33s | 3.4 min | 2.5 h |
| Void | 6.16K | Epic (25) | 5s | 33s | 3.4 min | 2.5 h |
| Colossus | 18.07K | Legendary (60) | 4s | 27s | 2.8 min | 2.0 h |
| Awakened | 41.51K | Legendary (60) | 2s | 12s | 1.2 min | 53.4 min |
| Celestial | 55.40K | Legendary (60) | 1s | 9s | 54s | 40.0 min |
| Forbidden | 230.47K | Mythic (170) | 1s | 6s | 37s | 27.2 min |


## 7. Duplicatas

Regra atual: cada roll vira uma unidade no inventário (capacidade 100 + Mochila/upgrade); duplicata = mais uma cópia (serve para Fusão, troca ou venda). Venda = BaseIncome × SellSeconds × variante, ou seja **12–40 segundos da renda que a própria unidade daria equipada**. Auto-sell existe por raridade (desligado por padrão; Secreto protegido).

Valor vendido em duplicatas de cada Dice em 20 h (P50) e quanto isso paga do próximo Dice:

| Dice | Raridades | Valor vendido (Ativo, P50) | ÷ preço do próximo Dice | Casual P50 | Otimizador P50 | Rolls no Dice (Ativo P50) | Dice nunca rolado (Ativo) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Starter | Common/Uncommon/Rare/Epic | 2.09K | 84% | 3.50K | 2.31K | 90 | 0% |
| Lucky | Common/Uncommon/Rare/Epic | 8.31K | 83% | 5.96K | 882 | 180 | 0% |
| Rampart | Common/Uncommon/Rare/Epic | 27.84K | 70% | 10.07K | 37.51K | 345 | 0% |
| Shinobi | Common/Uncommon/Rare/Epic | 0 | 0% | 13.31K | 0 | 0 | 92% |
| Flame | Uncommon/Rare/Epic/Legendary | 600 | 0% | 26.49K | 0 | 0 | 51% |
| Blade | Uncommon/Rare/Epic/Legendary | 102.39K | 46% | 27.00K | 163.53K | 615 | 0% |
| Fighter | Uncommon/Rare/Epic/Legendary | 87.17K | 22% | 29.25K | 98.77K | 390 | 0% |
| Storm | Rare/Epic/Legendary | 95.76K | 13% | 173.96K | 120.61K | 270 | 0% |
| Spirit | Rare/Epic/Legendary/Mythic | 241.96K | 17% | 226.49K | 176.85K | 570 | 0% |
| Arcane | Rare/Epic/Legendary/Mythic | 273.83K | 11% | 288.32K | 281.80K | 480 | 13% |
| Shadow | Epic/Legendary/Mythic | 302.73K | 6% | 498.30K | 829.20K | 345 | 2% |
| Void | Epic/Legendary/Mythic/Divine | 1.50M | 12% | 1.44M | 1.47M | 1365 | 0% |
| Colossus | Epic/Legendary/Mythic | 2.54M | 8% | 2.09M | 2.31M | 1980 | 0% |
| Awakened | Legendary/Mythic | 3.12M | 4% | 3.36M | 3.78M | 1875 | 0% |
| Celestial | Legendary/Mythic/Divine | 16.30M | 2% | 9.44M | 15.93M | 7005 | 0% |
| Forbidden | Mythic/Divine/Secret | 242.14M | — | 165.44M | 238.47M | 56280 | 0% |

Participação total da venda de duplicatas: Casual F2P: 5% do dinheiro até 1 h, 0% até 20 h; Ativo F2P: 7% do dinheiro até 1 h, 0% até 20 h; Otimizador F2P: 6% do dinheiro até 1 h, 0% até 20 h; Pago Moderado: 6% do dinheiro até 1 h, 0% até 20 h.


## 8. UPGRADE REFUND ANALYSIS

### Desenho

`SaleValue = BaseSaleValue + RefundPercent × EligibleUpgradeInvestment` — implementado como cotação pura em `src/shared/Modules/SaleCore.luau` e usado pela venda real com **`EconomyConfig.UpgradeRefundPercent = 0`** (venda idêntica à de hoje; teste prova `Total == sellValue` para todos os personagens/variantes/níveis).

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
| 0% | 22 | 12.60M | 0 | 27.16B | 16.0 | 112 | 19.0 | 2.40B |
| 50% | 22 | 6.31M | 6.31M | 28.05B | 16.0 | 112 | 19.0 | 2.54B |
| 60% | 22 | 5.01M | 7.51M | 28.21B | 16.0 | 112 | 19.0 | 2.49B |
| 70% | 22 | 3.77M | 8.79M | 28.23B | 16.0 | 112 | 19.0 | 2.53B |
| 75% | 22 | 3.14M | 9.41M | 28.26B | 16.0 | 112 | 19.0 | 2.55B |
| 80% | 22 | 2.51M | 10.04M | 28.24B | 16.0 | 112 | 19.0 | 2.67B |
| 100% | 22 | 0 | 12.37M | 28.15B | 16.0 | 112 | 19.0 | 2.58B |

### Ativo F2P (10 h ativas, 150 jogadores por %)

| Refund | Trocas de estação | Investimento perdido | Reembolsado | Ganho total 10 h | Dice 10 h | Index 10 h | Nível médio 10 h | Patrimônio 10 h |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 0% | 14 | 9.91M | 0 | 18.63B | 16.0 | 98 | 25.2 | 4.87B |
| 50% | 14 | 4.39M | 4.39M | 19.02B | 16.0 | 97 | 25.0 | 4.95B |
| 60% | 14 | 3.13M | 4.69M | 18.07B | 16.0 | 97 | 25.0 | 4.53B |
| 70% | 14 | 2.89M | 6.75M | 19.22B | 16.0 | 97 | 25.0 | 5.10B |
| 75% | 14 | 2.19M | 6.58M | 18.03B | 16.0 | 97 | 25.0 | 4.35B |
| 80% | 14 | 1.83M | 7.30M | 18.31B | 16.0 | 98 | 25.0 | 4.72B |
| 100% | 14 | 0 | 8.42M | 17.93B | 16.0 | 99 | 25.0 | 4.63B |

### Otimizador F2P (10 h ativas, 150 jogadores por %)

| Refund | Trocas de estação | Investimento perdido | Reembolsado | Ganho total 10 h | Dice 10 h | Index 10 h | Nível médio 10 h | Patrimônio 10 h |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 0% | 17 | 16.49M | 0 | 14.42B | 16.0 | 97 | 27.2 | 2.88B |
| 50% | 18 | 7.62M | 7.62M | 13.86B | 16.0 | 97 | 27.0 | 2.94B |
| 60% | 18 | 6.72M | 10.08M | 14.60B | 16.0 | 97 | 27.0 | 3.09B |
| 70% | 17 | 4.26M | 9.95M | 13.52B | 16.0 | 96 | 27.0 | 2.97B |
| 75% | 17 | 3.39M | 10.17M | 14.13B | 16.0 | 96 | 27.2 | 3.05B |
| 80% | 18 | 3.18M | 12.71M | 14.44B | 16.0 | 97 | 27.2 | 3.24B |
| 100% | 18 | 0 | 16.54M | 14.24B | 16.0 | 97 | 27.0 | 3.11B |

### Impacto por percentual

| Refund | Liberdade de troca | Sink de dinheiro | Progressão | Exploit | Patrimônio |
| --- | --- | --- | --- | --- | --- |
| 0% (hoje) | baixa: trocar a estação joga fora 100% dos níveis | máximo (todo nível é sink definitivo) | base | impossível | só saldo + venda base |
| 50% | média | metade do gasto em níveis volta ao trocar | ≈ base | impossível | + metade do investido |
| 60% | média | 40% fica no sistema | ≈ base | impossível | — |
| 70% | boa | 30% fica | ≈ base | impossível | — |
| **75%** | **boa** | **25% fica (sink real preservado)** | ≈ base (diferença dentro do ruído) | **impossível** | o jogador "vê" 3/4 do que investiu |
| 80% | boa | 20% fica | ≈ base | impossível | — |
| 100% | total | nível vira depósito sem custo: trocar é grátis, subir nível deixa de ser decisão | ≈ base | neutro (sem lucro) | inflaciona o patrimônio |

Números (P50, 10 h ativas): Ativo perde 9.91M em níveis ao trocar estações com 0% e 2.19M com 75% (recebe 6.58M de volta); Otimizador 16.49M → 3.39M. Isso é pequeno perto do ganho total (18.63B Ativo): **o refund não acelera a progressão de forma relevante** — o ganho é de liberdade (trocar para o personagem novo sem punição) e de percepção de valor. Diferenças de "Ganho total" entre as linhas são ruído de amostra (mesmas sementes, mas o caminho diverge cedo).

**Recomendação: 75%** com investimento gravado por instância (B). Abaixo de 60% a troca ainda dói; 100% elimina o sink e transforma nível em poupança. 75% mantém 1/4 de cada troca como sink e deixa a decisão "subir nível agora × esperar o personagem melhor" com peso, sem nunca permitir lucro.


## 9. Prisma da Coleção (UsesPerReward × MaxCharges)

O Prisma vem no Dia 7 do ciclo diário (1 recompensa a cada 7 dias reais). Tempo ativo de 20 h = 60 dias para o Casual (8–9 recompensas), 10 dias para o Ativo (1 recompensa). No simulador o jogador usa a carga no Dice selecionado; se ele já está completo, seleciona o maior Dice que ainda tem personagem a descobrir (o servidor recusa sem gastar quando não há nada a descobrir).

### Casual F2P (20 h ativas)

| Usos/recompensa | Teto | Usos (P50) | Cargas perdidas no teto (P50) | Index 20 h (P50) | Forbidden 100% (jogadores) | Celestial 100% |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 7 | 8 | 0 | 111 | 100% | 100% |
| 1 | 14 | 8 | 0 | 111 | 100% | 100% |
| 1 | 21 | 8 | 0 | 111 | 100% | 100% |
| 2 | 7 | 10 | 0 | 112 | 100% | 100% |
| 2 | 14 | 10 | 0 | 112 | 100% | 100% |
| 2 | 21 | 10 | 0 | 112 | 100% | 100% |
| 3 | 7 | 10 | 8 | 112 | 100% | 100% |
| 3 | 14 | 10 | 0 | 112 | 100% | 100% |
| 3 (atual) | 21 | 10 | 0 | 112 | 100% | 100% |

### Ativo F2P (20 h ativas)

| Usos/recompensa | Teto | Usos (P50) | Cargas perdidas no teto (P50) | Index 20 h (P50) | Forbidden 100% (jogadores) | Celestial 100% |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 7 | 1 | 0 | 99 | 86% | 100% |
| 1 | 14 | 1 | 0 | 99 | 86% | 100% |
| 1 | 21 | 1 | 0 | 99 | 86% | 100% |
| 2 | 7 | 2 | 0 | 100 | 99% | 100% |
| 2 | 14 | 2 | 0 | 100 | 99% | 100% |
| 2 | 21 | 2 | 0 | 100 | 99% | 100% |
| 3 | 7 | 3 | 0 | 101 | 100% | 100% |
| 3 | 14 | 3 | 0 | 101 | 100% | 100% |
| 3 (atual) | 21 | 3 | 0 | 101 | 100% | 100% |

Leitura: o teto só importa para quem acumula; com 3 usos e teto 7 o Casual perde ~8 cargas em 60 dias, com teto 21 nenhuma. O Prisma decide principalmente os **Secretos do Forbidden** (0,0045%): no Ativo (1 recompensa em 20 h) 1 uso deixa ~14% dos jogadores sem o Forbidden completo em 20 h, 2 usos ~1%, 3 usos 0%. O Casual, com 8–9 recompensas, completa com qualquer combinação. **Recomendação: manter 3 usos / teto 21** (atual).


## 10. Rebirth: cedo × médio × tarde

Políticas: **early** = renasce assim que pode pagar; **medium** = renasce quando o próximo Dice custa mais que 2× o Rebirth; **late** = só com 15 Dice ou 4× o custo em caixa; **never** = nunca. O Rebirth mantém Dice, personagens, níveis, Índice e torres; zera dinheiro e as melhorias de Luck/Renda; dá +25% de renda, +2% de Luck (teto +50%), +10% de poder, +1 slot e fichas.

### Casual F2P

| Política | 1º Rebirth (P50) | Rebirths 3 h | Rebirths 10 h | Rebirths 20 h | Renda/s 20 h | Dice 20 h | Index 20 h | Ganho total 20 h |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| early | 1.0 h | 5 | 10 | 12 | 787.42K | 16.0 | 112 | 121.26B |
| medium | 1.8 h | 2 | 9 | 12 | 725.55K | 16.0 | 112 | 113.69B |
| late | 2.1 h | 1 | 9 | 11 | 767.38K | 16.0 | 112 | 111.29B |
| never | não renasce (P50) | 0 | 0 | 0 | 35.28K | 16.0 | 112 | 1.77B |

### Ativo F2P

| Política | 1º Rebirth (P50) | Rebirths 3 h | Rebirths 10 h | Rebirths 20 h | Renda/s 20 h | Dice 20 h | Index 20 h | Ganho total 20 h |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| early | 1.2 h | 4 | 9 | 11 | 1.25M | 16.0 | 104 | 92.70B |
| medium | 1.5 h | 4 | 9 | 11 | 1.40M | 16.0 | 102 | 96.03B |
| late | 2.3 h | 1 | 8 | 11 | 1.25M | 16.0 | 101 | 83.60B |
| never | não renasce (P50) | 0 | 0 | 0 | 34.41K | 16.0 | 101 | 1.88B |

### Otimizador F2P

| Política | 1º Rebirth (P50) | Rebirths 3 h | Rebirths 10 h | Rebirths 20 h | Renda/s 20 h | Dice 20 h | Index 20 h | Ganho total 20 h |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| early | 1.5 h | 4 | 9 | 11 | 1.41M | 16.0 | 98 | 69.43B |
| medium | 1.7 h | 3 | 9 | 11 | 1.60M | 16.0 | 98 | 72.02B |
| late | 2.5 h | 1 | 8 | 11 | 1.34M | 16.0 | 98 | 62.60B |
| never | não renasce (P50) | 0 | 0 | 0 | 42.70K | 16.0 | 98 | 2.22B |

Leitura: (1) o primeiro Rebirth (10M) chega **antes** do Colossus (12,5M) — como o Rebirth não tira Dice, renascer cedo é quase grátis e o jogador médio renasce enquanto ainda compra Dice; (2) em 20 h todas as políticas convergem para ~10–12 rebirths, porque o custo × 2,2 cresce mais devagar que a renda multiplicada (+25%/rebirth, +1 slot); (3) **never** ganha ~50× menos dinheiro em 20 h — o Rebirth é obrigatório, não opcional; (4) para Ativo/Otimizador, medium ganha um pouco mais que early (renascer cedo zera Luck/Renda compradas várias vezes); para o Casual, early ganha mais (o teto do offline sobe com o custo do próximo Rebirth).


## 11. Retenção: primeiros 5 / 10 / 20 / 30 / 60 minutos

Momentos de retenção medidos em 10.000 jogadores por perfil (primeira hora). Leitura: Raro e Épico chegam em segundos, o 1º Dice novo em 1–3 min e o 1º Dice 100% em < 2 min — os primeiros 5 min estão cheios. O **buraco** fica entre ~2 e ~10 min (nenhum marco novo até o 1º Lendário, que só existe a partir do Flame, ~11–13 min) e entre ~15 e ~35 min (até o 1º Mítico, no Spirit). Missões/Diário ajudam, mas não há recompensa de coleção nesse intervalo.

### Casual F2P (10000 jogadores)

| Evento | P10 / P50 / P90 | ≤5 min | ≤10 min | ≤20 min | ≤30 min | ≤60 min |
| --- | --- | --- | --- | --- | --- | --- |
| 1º Raro | 2s / 11s / 36s | 100% | 100% | 100% | 100% | 100% |
| 1º Épico | 5s / 33s / 1.8 min | 100% | 100% | 100% | 100% | 100% |
| 1º Lendário | 11.7 min / 13.2 min / 17.1 min | 0% | 0% | 100% | 100% | 100% |
| 1º Mítico | 36.2 min / 37.5 min / 40.3 min | 0% | 0% | 0% | 0% | 100% |
| 1º Dice novo | 3.0 min / 3.0 min / 3.0 min | 100% | 100% | 100% | 100% | 100% |
| 1º upgrade de estação | 3.0 min / 6.0 min / 6.0 min | 31% | 100% | 100% | 100% | 100% |
| 1º Dice 100% (coleção) | 21s / 41s / 1.8 min | 100% | 100% | 100% | 100% | 100% |

### Ativo F2P (10000 jogadores)

| Evento | P10 / P50 / P90 | ≤5 min | ≤10 min | ≤20 min | ≤30 min | ≤60 min |
| --- | --- | --- | --- | --- | --- | --- |
| 1º Raro | 2s / 8s / 26s | 100% | 100% | 100% | 100% | 100% |
| 1º Épico | 4s / 23s / 1.2 min | 100% | 100% | 100% | 100% | 100% |
| 1º Lendário | 10.3 min / 10.9 min / 11.1 min | 0% | 0% | 99% | 100% | 100% |
| 1º Mítico | 34.9 min / 37.0 min / 40.5 min | 0% | 0% | 0% | 0% | 100% |
| 1º Dice novo | 1.0 min / 1.5 min / 1.8 min | 100% | 100% | 100% | 100% | 100% |
| 1º upgrade de estação | 15s / 15s / 2.0 min | 100% | 100% | 100% | 100% | 100% |
| 1º Dice 100% (coleção) | 15s / 29s / 1.2 min | 100% | 100% | 100% | 100% | 100% |

### Otimizador F2P (10000 jogadores)

| Evento | P10 / P50 / P90 | ≤5 min | ≤10 min | ≤20 min | ≤30 min | ≤60 min |
| --- | --- | --- | --- | --- | --- | --- |
| 1º Raro | 2s / 8s / 26s | 100% | 100% | 100% | 100% | 100% |
| 1º Épico | 4s / 23s / 1.2 min | 100% | 100% | 100% | 100% | 100% |
| 1º Lendário | 10.2 min / 10.8 min / 10.9 min | 0% | 0% | 96% | 100% | 100% |
| 1º Mítico | 42.4 min / 45.0 min / 48.3 min | 0% | 0% | 0% | 0% | 100% |
| 1º Dice novo | 1.2 min / 1.7 min / 1.8 min | 100% | 100% | 100% | 100% | 100% |
| 1º upgrade de estação | 5s / 5s / 50s | 100% | 100% | 100% | 100% | 100% |
| 1º Dice 100% (coleção) | 15s / 29s / 1.2 min | 100% | 100% | 100% | 100% | 100% |

### Pago Moderado (10000 jogadores)

| Evento | P10 / P50 / P90 | ≤5 min | ≤10 min | ≤20 min | ≤30 min | ≤60 min |
| --- | --- | --- | --- | --- | --- | --- |
| 1º Raro | 1s / 3s / 10s | 100% | 100% | 100% | 100% | 100% |
| 1º Épico | 2s / 8s / 25s | 100% | 100% | 100% | 100% | 100% |
| 1º Lendário | 9.9 min / 10.3 min / 10.7 min | 0% | 19% | 100% | 100% | 100% |
| 1º Mítico | 24.4 min / 26.8 min / 29.2 min | 0% | 0% | 0% | 96% | 100% |
| 1º Dice novo | 30s / 1.0 min / 1.0 min | 100% | 100% | 100% | 100% | 100% |
| 1º upgrade de estação | 15s / 1.0 min / 2.0 min | 100% | 100% | 100% | 100% | 100% |
| 1º Dice 100% (coleção) | 7s / 12s / 26s | 100% | 100% | 100% | 100% | 100% |


## 12. Longo prazo: 3 / 5 / 10 / 20 h

Forbidden: compra em ~3–5 h ativas para todos os perfis F2P; o 100% (3 Secretos) depende do Prisma e de horas de roll. **Não é rápido demais para comprar** (é o maior muro de dinheiro do jogo), mas depois de comprar não há mais nenhum Dice: o objetivo vira Rebirth + Secretos + torres.

| Perfil | Tempo | Dice (P50) | Tem Forbidden | Forbidden 100% | Index (P50) | Rebirths (P50) | Renda/s (P50) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Casual F2P | 3.0 h | 14 | 0% | 0% | 94 | 4 | 55.45K |
| Casual F2P | 5.0 h | 16 | 82% | 2% | 107 | 7 | 163.98K |
| Casual F2P | 10.0 h | 16 | 100% | 100% | 112 | 10 | 491.53K |
| Casual F2P | 20.0 h | 16 | 100% | 100% | 112 | 12 | 787.42K |
| Ativo F2P | 3.0 h | 15 | 0% | 0% | 91 | 3 | 101.75K |
| Ativo F2P | 5.0 h | 16 | 90% | 0% | 95 | 6 | 261.18K |
| Ativo F2P | 10.0 h | 16 | 100% | 13% | 97 | 9 | 641.88K |
| Ativo F2P | 20.0 h | 16 | 100% | 100% | 101 | 11 | 1.38M |
| Otimizador F2P | 3.0 h | 15 | 0% | 0% | 91 | 3 | 98.09K |
| Otimizador F2P | 5.0 h | 16 | 72% | 0% | 95 | 5 | 270.16K |
| Otimizador F2P | 10.0 h | 16 | 100% | 12% | 97 | 9 | 655.98K |
| Otimizador F2P | 20.0 h | 16 | 100% | 62% | 98 | 11 | 1.58M |
| Pago Moderado | 3.0 h | 16 | 61% | 0% | 95 | 5 | 438.51K |
| Pago Moderado | 5.0 h | 16 | 100% | 9% | 97 | 8 | 975.80K |
| Pago Moderado | 10.0 h | 16 | 100% | 65% | 98 | 11 | 2.42M |
| Pago Moderado | 20.0 h | 16 | 100% | 100% | 101 | 13 | 4.43M |

## 13. Problemas encontrados

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

## 14. Proposta de economia (NÃO aplicada)

| Item | ATUAL | PROPOSTO | JUSTIFICATIVA | EFEITO ESPERADO |
| --- | --- | --- | --- | --- |
| Reembolso na venda | 0% | **75%** do investimento em níveis, gravado por instância (B) | troca de estação sem destruir o investimento; 25% continua sink; prova de não-lucro | liberdade de troca; impacto de progressão ≈ 0 |
| Fusão | resultado = maior nível | resultado soma `UpgradeInvestment` das cópias (refund futuro) — nível continua o maior | fusão deixa de punir quem upou a cópia errada | mais fusões; nenhum dinheiro novo |
| Preço Forbidden | 750M (10× Celestial) | 750M → **400M** (≈5× Celestial), requisito 12.000 rolls mantido | único degrau de 10×; o requisito de rolls (3,3 h) chega ~1 h antes do dinheiro no Ativo | Forbidden ~30–40 min mais cedo para Ativo/Otimizador; Casual inalterado (já limitado por rolls) |
| Requisito de rolls Shinobi→Blade | 300 / 425 / 550 | 300 / 450 / 650 | no Ativo a missão dos 10 min paga Shinobi+Flame+Blade de uma vez (92% nunca rolam o Shinobi) | cada Dice rolado ≥ 2 min; Índice completo sem voltar |
| Preços de Dice (exceto Forbidden) | 2,5K…75M | **manter** | espera de 10–15 min por dinheiro por Dice (Ativo) é um ritmo saudável | — |
| Requisito de rolls Celestial | 8.000 | manter | — | — |
| Renda | BaseIncome provisório por raridade | manter | progressão em horas está no alvo | — |
| Duplicatas | 12–40 s de renda | C/U 20 · R 25 · E 30 · L 35 · M 45 · D 60 · S 90 s | dar valor ao "rolar sem nada novo" do meio do jogo | duplicatas ≈ 3–5% do dinheiro em 5 h (hoje ~1%) |
| Custo de nível | 60 s × 1,2^(L−1) | manter a curva; **MaxLevel 50 → 30** (ou crescimento 1,2 → 1,15 depois do 20) | o 31–50 nunca é comprado | teto alcançável e visível |
| Rebirth | 10M × 2,2^n | 1º Rebirth 10M → **15M** (crescimento igual) | primeiro Rebirth depois do Colossus, não antes | 1º Rebirth ~15–20 min mais tarde para o Ativo |
| Prisma | 3 usos, teto 21 | **manter** | Casual não perde carga; 3 usos fecham os Secretos | — |
| Offline | 12%, 8 h, teto 50% do próximo Rebirth | teto 50% → **25%** do próximo Rebirth | o Casual ganha mais offline que jogando | Casual com ~50% offline em vez de ~2/3 |
| Conquista `index` | 6/12/18/24 | 14/28/56/112 (12,5/25/50/100%) | roster 112 | conquista volta a funcionar como meta |
| Loja de gemas | Pacote 40 gemas = 900 s | 60 gemas = 900 s, ou Jackpot dinheiro 600 → 1.200 s | equilibrar gema → dinheiro | Jackpot volta a ser opção |

Nada acima foi aplicado: preços de Dice, custos de upgrade, renda, valores de duplicata, custos de Rebirth, reembolso de produção (0%), cargas do Prisma e o restante da economia continuam iguais ao commit 07744e5.

## Método e limites

- Simulador: `tools/sim/EconomyModel.luau` (puro). Roll **idêntico** ao `DiceCore.roll` (provado roll a roll em `tests/EconomyModel.spec.luau`): pesos de produção, Luck real (Dice × upgrade × boosts × Rebirth × gamepass, softcap 10), pity Lendário 50 / Mítico 250, Dice selecionado = o melhor comprado. Renda, níveis, venda (SaleCore), upgrades, Rebirth, torres (BattleCore), Jackpot, Diário, Missões, Offline, Fusão e Prisma (DiceCore:prismPick) vêm dos módulos e configs reais.
- Monte Carlo: 10000 jogadores por perfil até 1 h (retenção) e 2000 por perfil até 20 h. Menos de 10.000 no horizonte de 20 h porque cada jogador de 20 h custa 0,2–0,7 s (≈ 25 min para tudo em 4 núcleos). Convergência medida: diferença entre as duas metades da amostra (sementes pares × ímpares) no ganho total de 20 h — Casual F2P ≤ 1.2%, Ativo F2P ≤ 1.8%, Otimizador F2P ≤ 2.8%, Pago Moderado ≤ 0.5%. Sensibilidades (refund, Prisma, Rebirth) com 150 jogadores por variante e as MESMAS sementes entre variantes.
- Tempo = jogo ATIVO. O offline é aplicado entre as sessões do perfil (relógio real).
- Limites: agente simples (não troca Dice para caçar personagem fora do Prisma, não usa a loja de gemas, não negocia); torres só pela 1ª vitória; sem amigos no servidor.
- Reproduzir: `python3 tools/sim/run_economy_analysis.py` (≈ 25 min em 4 núcleos; `--scale 0.01` ≈ 30 s).

