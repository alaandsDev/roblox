# RNG_SIMULATION — Roll Legends

Gerado por `tools/sim/simulate_rng.luau` (Lune) com o **mesmo `RollCore` do servidor**,
gerador determinístico xorshift32 (semente fixa), **1.000.000 rolls por cenário**.
Teórico = `RollCore:chances(luck)` (fórmula em RNG.md). Desvio = observado − teórico (pontos percentuais).

## Odds REAIS por cenário (todos os multiplicadores + velocidade do AUTO)

Luck = dado × melhoria de Luck × renascimento (com teto) × perk × boost × gamepasses. Luck efetiva = com retornos
decrescentes (LuckSoftCap). "1 em X" = essa raridade OU MELHOR (com pity no Lendário/Mítico). Tempo = média no AUTO.

| Cenário | Luck | Luck efetiva | Rolls/min | Lendário+ | Mítico+ | Divino+ | Secreto | Secreto/hora |
|---|---:|---:|---:|---|---|---|---|---:|
| A) Jogador novo | 1.00 | 1.00 | 55 | 1 em 36 (0.7 min) | 1 em 623 (11.4 min) | 1 em 18182 (5.6 h) | 1 em 200000 (2.5 dias) | 0.02 |
| B) 30 minutos | 3.60 | 3.06 | 80 | 1 em 28 (0.4 min) | 1 em 478 (6.0 min) | 1 em 6962 (1.5 h) | 1 em 56718 (11.8 h) | 0.08 |
| C) 1 hora | 5.77 | 4.23 | 92 | 1 em 25 (0.3 min) | 1 em 430 (4.7 min) | 1 em 5336 (57.8 min) | 1 em 39958 (7.2 h) | 0.14 |
| D) Midgame (~4 h) | 11.22 | 6.05 | 109 | 1 em 23 (0.2 min) | 1 em 376 (3.4 min) | 1 em 3993 (36.6 min) | 1 em 27254 (4.2 h) | 0.24 |
| E) Late game (~RB 15) | 17.68 | 7.25 | 109 | 1 em 21 (0.2 min) | 1 em 349 (3.2 min) | 1 em 3459 (31.7 min) | 1 em 22552 (3.4 h) | 0.29 |
| F) Máximo F2P (RB máx + boost diário 2x) | 41.60 | 9.02 | 109 | 1 em 20 (0.2 min) | 1 em 317 (2.9 min) | 1 em 2916 (26.7 min) | 1 em 17985 (2.7 h) | 0.36 |
| G) Máximo com monetização (F + VIP + Sorte x2 + Roll Rápido) | 91.52 | 10.01 | 109 | 1 em 19 (0.2 min) | 1 em 303 (2.8 min) | 1 em 2692 (24.7 min) | 1 em 16181 (2.5 h) | 0.40 |

## Sem Luck (dado Normal, Luck 1.00)

| Raridade | Teórico % | Observado % | Desvio (p.p.) | Ocorrências | 1 em |
|---|---:|---:|---:|---:|---:|
| Common | 56.1345 | 56.1397 | +0.0052 | 561397 | 2 |
| Uncommon | 26.0000 | 25.9654 | -0.0346 | 259654 | 4 |
| Rare | 12.0000 | 11.9966 | -0.0034 | 119966 | 8 |
| Epic | 4.5000 | 4.5337 | +0.0337 | 45337 | 22 |
| Legendary | 1.3000 | 1.2999 | -0.0001 | 12999 | 77 |
| Mythic | 0.0600 | 0.0596 | -0.0004 | 596 | 1678 |
| Divine | 0.0050 | 0.0047 | -0.0003 | 47 | 21277 |
| Secret | 0.0005 | 0.0004 | -0.0001 | 4 | 250000 |

Maior sequência sem Lendário+: **715** rolls.

## Luck média (dado Storm, Luck 2.00)

| Raridade | Teórico % | Observado % | Desvio (p.p.) | Ocorrências | 1 em |
|---|---:|---:|---:|---:|---:|
| Common | 50.5356 | 50.5856 | +0.0500 | 505856 | 2 |
| Uncommon | 26.6383 | 26.5968 | -0.0415 | 265968 | 4 |
| Rare | 14.4518 | 14.4905 | +0.0387 | 144905 | 7 |
| Epic | 6.3703 | 6.3205 | -0.0498 | 63205 | 16 |
| Legendary | 1.9008 | 1.9027 | +0.0019 | 19027 | 53 |
| Mythic | 0.0936 | 0.0940 | +0.0004 | 940 | 1064 |
| Divine | 0.0086 | 0.0088 | +0.0002 | 88 | 11364 |
| Secret | 0.0010 | 0.0011 | +0.0001 | 11 | 90909 |

Maior sequência sem Lendário+: **649** rolls.

## Luck máxima com monetização (Luck 91.52, efetiva 10.01)

| Raridade | Teórico % | Observado % | Desvio (p.p.) | Ocorrências | 1 em |
|---|---:|---:|---:|---:|---:|
| Common | 34.7508 | 34.7877 | +0.0369 | 347877 | 3 |
| Uncommon | 25.5125 | 25.5240 | +0.0115 | 255240 | 4 |
| Rare | 20.9420 | 20.9145 | -0.0275 | 209145 | 5 |
| Epic | 13.9671 | 13.9339 | -0.0332 | 139339 | 7 |
| Legendary | 4.5274 | 4.5368 | +0.0094 | 45368 | 22 |
| Mythic | 0.2631 | 0.2622 | -0.0009 | 2622 | 381 |
| Divine | 0.0310 | 0.0340 | +0.0030 | 340 | 2941 |
| Secret | 0.0062 | 0.0069 | +0.0007 | 69 | 14493 |

Maior sequência sem Lendário+: **233** rolls.

## Luck 1.00 COM pity (Lendário 50 / Mítico 250)

| Raridade | Teórico % | Observado % | Desvio (p.p.) | Ocorrências | 1 em |
|---|---:|---:|---:|---:|---:|
| Common | 56.1345 | 55.3146 | -0.8199 | 553146 | 2 |
| Uncommon | 26.0000 | 25.5710 | -0.4290 | 255710 | 4 |
| Rare | 12.0000 | 11.8758 | -0.1242 | 118758 | 8 |
| Epic | 4.5000 | 4.4235 | -0.0765 | 44235 | 23 |
| Legendary | 1.3000 | 2.6542 | +1.3542 | 26542 | 38 |
| Mythic | 0.0600 | 0.1551 | +0.0951 | 1551 | 645 |
| Divine | 0.0050 | 0.0058 | +0.0008 | 58 | 17241 |
| Secret | 0.0005 | 0.0000 | -0.0005 | 0 | 0 |

Maior sequência sem Lendário+: **49** rolls. Pity disparou **14559** vezes.
Com pity o teórico acima é o SEM pity; a diferença nas raridades Lendário/Mítico é o efeito esperado do pity.
