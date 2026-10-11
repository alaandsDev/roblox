# RNG_SIMULATION — Roll Legends

Gerado por `tools/sim/simulate_rng.luau` (Lune) com o **mesmo `RollCore` do servidor**,
gerador determinístico xorshift32 (semente fixa), **1.000.000 rolls por cenário**.
Teórico = `RollCore:chances(luck)` (fórmula em RNG.md). Desvio = observado − teórico (pontos percentuais).

## Sem Luck (dado Normal, Luck 1.00)

| Raridade | Teórico % | Observado % | Desvio (p.p.) | Ocorrências | 1 em |
|---|---:|---:|---:|---:|---:|
| Common | 55.0000 | 54.9888 | -0.0112 | 549888 | 2 |
| Uncommon | 25.0000 | 24.9755 | -0.0245 | 249755 | 4 |
| Rare | 12.0000 | 11.9898 | -0.0102 | 119898 | 8 |
| Epic | 5.0000 | 5.0335 | +0.0335 | 50335 | 20 |
| Legendary | 2.0000 | 2.0091 | +0.0091 | 20091 | 50 |
| Mythic | 0.7500 | 0.7547 | +0.0047 | 7547 | 133 |
| Divine | 0.2000 | 0.1999 | -0.0001 | 1999 | 500 |
| Secret | 0.0500 | 0.0487 | -0.0013 | 487 | 2053 |

Maior sequência sem Lendário+: **326** rolls.

## Luck média (dado Storm, Luck 2.00)

| Raridade | Teórico % | Observado % | Desvio (p.p.) | Ocorrências | 1 em |
|---|---:|---:|---:|---:|---:|
| Common | 44.2342 | 44.2893 | +0.0551 | 442893 | 2 |
| Uncommon | 25.6269 | 25.6405 | +0.0136 | 256405 | 4 |
| Rare | 15.6783 | 15.6270 | -0.0513 | 156270 | 6 |
| Epic | 8.0426 | 8.0705 | +0.0279 | 80705 | 12 |
| Legendary | 3.9606 | 3.9189 | -0.0417 | 39189 | 26 |
| Mythic | 1.7663 | 1.7553 | -0.0110 | 17553 | 57 |
| Divine | 0.5410 | 0.5463 | +0.0053 | 5463 | 183 |
| Secret | 0.1501 | 0.1522 | +0.0021 | 1522 | 657 |

Maior sequência sem Lendário+: **161** rolls.

## Luck alta (Celestial + Luck nível máx, Luck 10.40)

| Raridade | Teórico % | Observado % | Desvio (p.p.) | Ocorrências | 1 em |
|---|---:|---:|---:|---:|---:|
| Common | 17.6195 | 17.6430 | +0.0235 | 176430 | 6 |
| Uncommon | 18.1774 | 18.1816 | +0.0042 | 181816 | 6 |
| Rare | 19.8032 | 19.7969 | -0.0063 | 197969 | 5 |
| Epic | 16.6584 | 16.7191 | +0.0607 | 167191 | 6 |
| Legendary | 13.4525 | 13.3662 | -0.0863 | 133662 | 7 |
| Mythic | 9.0593 | 9.0563 | -0.0030 | 90563 | 11 |
| Divine | 3.8589 | 3.8595 | +0.0006 | 38595 | 26 |
| Secret | 1.3708 | 1.3774 | +0.0066 | 13774 | 73 |

Maior sequência sem Lendário+: **43** rolls.

## Luck 1.00 COM pity (Lendário 50 / Mítico 250)

| Raridade | Teórico % | Observado % | Desvio (p.p.) | Ocorrências | 1 em |
|---|---:|---:|---:|---:|---:|
| Common | 55.0000 | 54.5008 | -0.4992 | 545008 | 2 |
| Uncommon | 25.0000 | 24.7534 | -0.2466 | 247534 | 4 |
| Rare | 12.0000 | 11.9215 | -0.0785 | 119215 | 8 |
| Epic | 5.0000 | 4.9495 | -0.0505 | 49495 | 20 |
| Legendary | 2.0000 | 2.5543 | +0.5543 | 25543 | 39 |
| Mythic | 0.7500 | 0.9950 | +0.2450 | 9950 | 101 |
| Divine | 0.2000 | 0.2569 | +0.0569 | 2569 | 389 |
| Secret | 0.0500 | 0.0686 | +0.0186 | 686 | 1458 |

Maior sequência sem Lendário+: **49** rolls. Pity disparou **8822** vezes.
Com pity o teórico acima é o SEM pity; a diferença nas raridades Lendário/Mítico é o efeito esperado do pity.
