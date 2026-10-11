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
5. Critérios automatizados: em 5 min (Hardcore) nenhuma melhoria ≥ 10 e no máximo o dado
   Flame; em 2 h (Ativo) ainda sem Celestial e com melhorias por comprar.

## Resultados da simulação


<!-- SIM:BEGIN (gerado por tools/sim/simulate_economy.luau — não editar à mão) -->

### Casual

Roll manual a cada 2.5 s, coleta a cada 120 s, decide a cada 60 s, gasta 30% em níveis de estação.

| Tempo | Rolls | Dado | Luck | Renda/s | Ganho total | Saldo | Upg L/I/S/C | Nível médio estação | Melhor | Index | 8 h offline |
|---|---:|---|---:|---:|---:|---:|---|---:|---|---:|---:|
| 5 min | 120 | Lucky | 1.55 | $882 | $73.68K | $5.4K | 3/4/2/5 | 1.0 | Chrono Sage (Divine) | 18/24 | $3.04M |
| 10 min | 240 | Lucky | 1.85 | $1.85K | $614.99K | $26.82K | 6/7/5/9 | 2.2 | Chrono Sage (Divine) | 22/24 | $6.41M |
| 30 min | 720 | Flame | 2.88 | $8.77K | $6.74M | $62.32K | 10/11/8/13 | 6.8 | Chrono Sage (Divine) | 23/24 | $30.32M |
| 1 h | 1440 | Storm | 3.92 | $16.3K | $31.83M | $1.94M | 12/13/10/16 | 14.2 | Chrono Sage (Divine) | 23/24 | $56.33M |
| 2 h | 2880 | Storm | 4.40 | $76.44K | $205.36M | $15.37M | 15/16/11/19 | 22.0 | Eclipse Sovereign (Secret) | 24/24 | $264.17M |

### Ativo

Roll AUTO (cooldown), coleta a cada 30 s, decide a cada 15 s, gasta 50% em níveis de estação.

| Tempo | Rolls | Dado | Luck | Renda/s | Ganho total | Saldo | Upg L/I/S/C | Nível médio estação | Melhor | Index | 8 h offline |
|---|---:|---|---:|---:|---:|---:|---|---:|---|---:|---:|
| 5 min | 295 | Lucky | 1.75 | $2.42K | $368.18K | $32.95K | 5/6/4/8 | 1.5 | Chrono Sage (Divine) | 22/24 | $8.36M |
| 10 min | 645 | Flame | 2.62 | $4.25K | $1.46M | $9.22K | 8/8/6/10 | 2.2 | Chrono Sage (Divine) | 23/24 | $14.69M |
| 30 min | 2267 | Storm | 3.76 | $27.72K | $17.12M | $64.73K | 11/11/9/14 | 8.0 | Eclipse Sovereign (Secret) | 24/24 | $95.8M |
| 1 h | 5231 | Void | 5.61 | $70.56K | $116.89M | $4.49M | 13/14/11/17 | 21.8 | Eclipse Sovereign (Secret) | 24/24 | $243.85M |
| 2 h | 11777 | Void | 6.05 | $82.68K | $430.17M | $6.61M | 15/16/11/19 | 23.5 | Eclipse Sovereign (Secret) | 24/24 | $285.74M |

### Hardcore

Roll AUTO (cooldown), coleta a cada 5 s, decide a cada 3 s, gasta 60% em níveis de estação.

| Tempo | Rolls | Dado | Luck | Renda/s | Ganho total | Saldo | Upg L/I/S/C | Nível médio estação | Melhor | Index | 8 h offline |
|---|---:|---|---:|---:|---:|---:|---|---:|---|---:|---:|
| 5 min | 293 | Lucky | 1.75 | $2.69K | $391.7K | $30.8K | 5/6/3/7 | 2.2 | Chrono Sage (Divine) | 22/24 | $9.3M |
| 10 min | 634 | Flame | 2.50 | $6.48K | $1.71M | $41.91K | 7/8/5/9 | 5.0 | Chrono Sage (Divine) | 23/24 | $22.39M |
| 30 min | 2227 | Storm | 3.60 | $34.65K | $22.48M | $458.09K | 10/11/8/13 | 10.8 | Eclipse Sovereign (Secret) | 24/24 | $119.75M |
| 1 h | 5050 | Storm | 4.08 | $70.56K | $120.89M | $4.37M | 13/14/10/16 | 21.5 | Eclipse Sovereign (Secret) | 24/24 | $243.85M |
| 2 h | 11561 | Void | 6.05 | $102.96K | $446.37M | $20.5M | 15/16/11/19 | 30.0 | Eclipse Sovereign (Secret) | 24/24 | $355.82M |

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
