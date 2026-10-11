# ECONOMY — Roll Legends

Toda a economia é **configurável** e calculada no **servidor** (`src/shared/Modules/Formulas.luau`).
Os números abaixo são gerados pela simulação com as **mesmas configs e fórmulas** do jogo
(`tools/sim/EconomySim.luau`, rode `tools/bin/lune-0.10.4/lune run tools/sim/simulate_economy.luau`).
A regressão `tests/Economy.spec.luau` falha se a progressão "quebrar".

## Fontes de dinheiro

| Fonte | Fórmula | Config |
|---|---|---|
| Renda das estações | Σ (BaseIncome × (1 + (Level−1) × 0,25) × Variante) × (1 + nível Income × 10%) | CharacterConfig, CharacterLevelConfig, VariantConfig, UpgradeConfig |
| Coletor | renda acumula em `UncollectedMoney` (teto = 1 h de renda) e vai para Money ao pisar/usar | EconomyConfig |
| Venda | BaseIncome × SellSeconds[raridade] × Variante.SellMultiplier | EconomyConfig.SellSeconds |
| Offline | renda/s salva × min(tempo fora, 8 h) × 12% | OfflineIncomeConfig |
| Diário | tabela de 7 dias (dinheiro escala com a renda) | DailyConfig |

## Gastos

| Gasto | Fórmula | Config |
|---|---|---|
| Melhorias globais | BaseCost × Growth^nível, até MaxLevel | UpgradeConfig (Luck 2000×1,9ⁿ /20 · Income 1500×1,85ⁿ /25 · RollSpeed 5000×2ⁿ /11 · Inventory 1000×1,7ⁿ /20) |
| Nível da estação | BaseUpgradeCost × 1,2^(Level−1), BaseUpgradeCost = BaseIncome × 60 s | CharacterLevelConfig (MaxLevel 50) |
| Dados | preço fixo + requisito de rolls + dado anterior | DiceConfig (Lucky $2.5K/50 · Flame $40K/300 · Storm $400K/1000 · Void $5M/3000 · Celestial $75M/8000) |

`Formulas:characterUpgradeCost(id, nível, n)` soma n níveis (x1/x5/x10) e
`Formulas:affordableLevels` calcula o MAX — arquitetura pronta para multi-upgrade.

## Balanceamento (decisões)

1. **Primeira versão quebrava**: com a renda inicial (Lendário 320/s) e os custos baixos, a
   simulação mostrou TODAS as melhorias globais no máximo em 5 min e Divino para o casual.
   O pity Lendário em 50 rolls (pedido no design) garante um Lendário em ~1 min, então a renda
   das raridades altas foi reduzida (Lendário 55–70/s, Mítico 150–170, Divino 400–450,
   Secreto 1200) e os custos ficaram exponenciais mais íngremes.
2. **Rolls são o portão dos dados** (50/300/1000/3000/8000): dinheiro sozinho não pula dado.
3. **Offline**: a sugestão inicial (50%) fazia 8 h pagarem ~2,3× tudo que um jogador ativo
   ganha em 2 h. Com **12%**, 8 h offline ≈ **1 h de renda passiva** no mesmo ponto do jogo —
   recompensa por voltar, sem pular metade da progressão. `tests/Economy.spec.luau` garante isso.
4. Teto do coletor (1 h de renda) evita AFK infinito na própria sessão.
5. **Torres** (Fase 7): dificuldade calibrada pelo poder real dos personagens — Brasas
   (100 → ~40K) termina entre 5 e 30 min, Tempestade (50K → ~10M) leva horas, Vazio
   (10M → ~250M) é o objetivo de longo prazo (precisa de renascimentos, fusões e níveis).
   Recompensa por andar = max(poder dos inimigos, 8 s de renda) para não inflar o começo.
6. **Renascimento** (Fase 8): 5M × 3ⁿ; reseta dinheiro e melhorias globais e dá +25% de renda,
   +5% de sorte, +10% de poder, +1 pedestal e fichas. A simulação renasce 1 vez na 1ª hora e
   3 vezes em 4 h (perfil Ativo).
7. Critérios automatizados: em 5 min (Hardcore) nenhuma melhoria ≥ 10 e no máximo o dado
   Flame; em 2 h (Ativo) ainda sem Celestial e com melhorias por comprar.

## Resultados da simulação


<!-- SIM:BEGIN (gerado por tools/sim/simulate_economy.luau — não editar à mão) -->

### Casual

Roll manual a cada 2.5 s, coleta a cada 120 s, decide a cada 60 s, gasta 30% em níveis de estação, renasce com 2.0x o custo, sobe torres a cada minuto.

| Tempo | Rolls | Dado | Luck | Renda/s | Ganho total | Saldo | Upg L/I/S/C | Nível médio estação | Renasc. | Andares (torres) | Melhor | Index | 8 h offline |
|---|---:|---|---:|---:|---:|---:|---|---:|---:|---:|---|---:|---:|
| 5 min | 120 | Lucky | 1.65 | $350 | $127.41K | $10.34K | 4/5/2/6 | 1.2 | 0 | 24/120 | Dragon Knight (Legendary) | 17/24 | $1.2M |
| 10 min | 240 | Lucky | 2.05 | $2.4K | $1.53M | $69.03K | 8/8/6/11 | 2.0 | 0 | 39/120 | Chrono Sage (Divine) | 22/24 | $8.32M |
| 30 min | 720 | Flame | 3.01 | $9.92K | $10.97M | $404.3K | 11/11/9/14 | 7.8 | 0 | 48/120 | Chrono Sage (Divine) | 23/24 | $34.29M |
| 1 h | 1440 | Storm | 4.08 | $23.46K | $43.98M | $795.2K | 13/14/10/16 | 14.2 | 0 | 54/120 | Eclipse Sovereign (Secret) | 24/24 | $81.07M |
| 2 h | 2880 | Storm | 4.62 | $133.81K | $346.37M | $18.51M | 15/17/11/20 | 21.2 | 1 | 66/120 | Eclipse Sovereign (Secret) | 24/24 | $462.45M |
| 4 h | 5760 | Void | 8.39 | $433.08K | $2.46B | $112.73M | 18/19/11/20 | 34.6 | 3 | 69/120 | Eclipse Sovereign (Secret) | 24/24 | $1.49B |

### Ativo

Roll AUTO (cooldown), coleta a cada 30 s, decide a cada 15 s, gasta 50% em níveis de estação, renasce com 1.2x o custo, sobe torres a cada minuto.

| Tempo | Rolls | Dado | Luck | Renda/s | Ganho total | Saldo | Upg L/I/S/C | Nível médio estação | Renasc. | Andares (torres) | Melhor | Index | 8 h offline |
|---|---:|---|---:|---:|---:|---:|---|---:|---:|---:|---|---:|---:|
| 5 min | 321 | Flame | 2.62 | $4.99K | $1.57M | $94.34K | 8/8/6/10 | 2.0 | 0 | 25/120 | Eclipse Sovereign (Secret) | 24/24 | $17.26M |
| 10 min | 728 | Flame | 2.88 | $12.28K | $8.72M | $289.49K | 10/11/8/14 | 8.0 | 0 | 49/120 | Eclipse Sovereign (Secret) | 24/24 | $42.45M |
| 30 min | 2639 | Storm | 4.08 | $59.76K | $77.6M | $1.99M | 13/14/10/17 | 18.0 | 0 | 63/120 | Eclipse Sovereign (Secret) | 24/24 | $206.53M |
| 1 h | 5764 | Void | 6.12 | $148.05K | $301.71M | $5.83M | 14/15/11/19 | 25.4 | 1 | 67/120 | Eclipse Sovereign (Secret) | 24/24 | $511.66M |
| 2 h | 12228 | Void | 7.52 | $245.91K | $1.13B | $8.67M | 16/17/11/20 | 27.8 | 2 | 69/120 | Eclipse Sovereign (Secret) | 24/24 | $849.88M |
| 4 h | 25253 | Celestial | 12.20 | $479.37K | $3.91B | $112.66M | 18/19/11/20 | 38.4 | 3 | 69/120 | Eclipse Sovereign (Secret) | 24/24 | $1.65B |

### Hardcore

Roll AUTO (cooldown), coleta a cada 5 s, decide a cada 3 s, gasta 60% em níveis de estação, renasce com 1.0x o custo, sobe torres a cada minuto.

| Tempo | Rolls | Dado | Luck | Renda/s | Ganho total | Saldo | Upg L/I/S/C | Nível médio estação | Renasc. | Andares (torres) | Melhor | Index | 8 h offline |
|---|---:|---|---:|---:|---:|---:|---|---:|---:|---:|---|---:|---:|
| 5 min | 321 | Flame | 2.50 | $7.22K | $1.97M | $72.73K | 7/8/6/10 | 4.5 | 0 | 25/120 | Eclipse Sovereign (Secret) | 24/24 | $24.96M |
| 10 min | 717 | Flame | 3.01 | $21.89K | $16.61M | $485K | 11/12/9/14 | 11.2 | 0 | 55/120 | Eclipse Sovereign (Secret) | 24/24 | $75.66M |
| 30 min | 2671 | Storm | 4.08 | $43.92K | $101.45M | $375.69K | 13/14/10/16 | 12.5 | 0 | 64/120 | Eclipse Sovereign (Secret) | 24/24 | $151.78M |
| 1 h | 5676 | Void | 5.89 | $136.08K | $272.32M | $150.51K | 13/15/11/17 | 24.0 | 1 | 66/120 | Eclipse Sovereign (Secret) | 24/24 | $470.29M |
| 2 h | 12141 | Void | 7.52 | $284.67K | $1.09B | $26.81M | 16/17/11/20 | 32.5 | 2 | 69/120 | Eclipse Sovereign (Secret) | 24/24 | $983.83M |
| 4 h | 25182 | Void | 8.11 | $432.51K | $3.84B | $32.26M | 17/18/11/20 | 35.7 | 3 | 69/120 | Eclipse Sovereign (Secret) | 24/24 | $1.49B |

### Dinheiro offline x jogo ativo

Fórmula: renda/s salva × min(tempo fora, 8 h) × 12%. Com esses valores, **8 h offline ≈ 0.96 h**
de renda passiva jogando ativo no mesmo ponto do jogo (coluna "8 h offline" acima).

### Recompensas diárias (valor por dia)

| Dia | Recompensa |
|---|---|
| 1 | Dinheiro: max($1K, renda/s × 120 s) |
| 2 | 25 gemas |
| 3 | Boost de Luck 1.5x por 10 min |
| 4 | Dinheiro: max($10K, renda/s × 600 s) |
| 5 | 100 gemas |
| 6 | Boost de Luck 2x por 15 min |
| 7 | Dado exclusivo Prism (se já tiver: 250 gemas) |

<!-- SIM:END -->
