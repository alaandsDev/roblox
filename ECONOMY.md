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
5. **Torres** (Fase 7, revisado na auditoria): Brasas (150 → ~122K), Tempestade (120K → ~10M),
   Vazio (10M → ~250M). Chefe = 0,7× em 1 inimigo (antes 1,25× criava uma parede no andar 20).
   Recompensa por andar = max(poder dos inimigos, 8 s de renda), só na 1ª vitória (sem farm).
6. **Renascimento** (Fase 8, revisado na auditoria): custo **10M × 2,2ⁿ** (antes 5M × 3ⁿ, que
   ficava atrás da renda). Cada renascimento: +25% renda, +2% sorte (teto +50%), +10% poder,
   +1 pedestal e fichas. Ativo renasce pela 1ª vez em ~1h40 e 6 vezes em 8 h.
7. **Offline** limitado também a 50% do custo do próximo renascimento.
8. Critérios automatizados: em 5 min (Hardcore) nenhuma melhoria ≥ 10 e no máximo o dado
   Flame; em 2 h (Ativo) ainda sem Celestial e com melhorias por comprar; 1º renascimento do
   Ativo entre 1 h e 3 h; offline ≤ metade do próximo renascimento.

## Resultados da simulação


<!-- SIM:BEGIN (gerado por tools/sim/simulate_economy.luau — não editar à mão) -->

### Casual

Roll manual a cada 2.5 s, coleta a cada 120 s, decide a cada 60 s, gasta 30% em níveis de estação, renasce com 1.0x o custo, sobe torres a cada minuto.

| Tempo | Rolls | Dado | Luck | Renda/s | Ganho total | Saldo | Upg L/I/S/C | Nível médio estação | Renasc. | Andares (torres) | Melhor | Index | 8 h offline |
|---|---:|---|---:|---:|---:|---:|---|---:|---:|---:|---|---:|---:|
| 5 min | 120 | Lucky | 1.55 | $247.1 | $64.18K | $4.59K | 3/4/1/5 | 1.2 | 0 | 18/120 | Solar Paladin (Legendary) | 16/24 | $853.97K |
| 10 min | 240 | Lucky | 1.75 | $405.37 | $206.32K | $10.83K | 5/5/3/7 | 1.2 | 0 | 20/120 | Solar Paladin (Legendary) | 19/24 | $1.4M |
| 30 min | 720 | Flame | 2.50 | $1.41K | $1.28M | $95.69K | 7/8/5/10 | 7.2 | 0 | 24/120 | Void Emperor (Mythic) | 20/24 | $4.88M |
| 1 h | 1440 | Storm | 3.44 | $3.3K | $5.83M | $468.36K | 9/10/7/13 | 13.0 | 0 | 27/120 | Void Emperor (Mythic) | 21/24 | $5M |
| 2 h | 2880 | Storm | 3.92 | $9.51K | $31.08M | $2.72M | 12/13/10/15 | 17.5 | 0 | 38/120 | Chrono Sage (Divine) | 22/24 | $5M |
| 4 h | 5760 | Void | 6.35 | $40.67K | $203.51M | $11.56M | 14/15/11/19 | 23.7 | 2 | 46/120 | Chrono Sage (Divine) | 23/24 | $24.2M |
| 8 h | 11520 | Celestial | 10.31 | $110.36K | $1.29B | $18.57M | 16/17/11/20 | 38.5 | 4 | 52/120 | Chrono Sage (Divine) | 23/24 | $117.12M |

Renascimentos em: 144 min, 178 min, 256 min, 438 min. Próximo custa $234.25M.

### Ativo

Roll AUTO (cooldown), coleta a cada 30 s, decide a cada 15 s, gasta 50% em níveis de estação, renasce com 1.0x o custo, sobe torres a cada minuto.

| Tempo | Rolls | Dado | Luck | Renda/s | Ganho total | Saldo | Upg L/I/S/C | Nível médio estação | Renasc. | Andares (torres) | Melhor | Index | 8 h offline |
|---|---:|---|---:|---:|---:|---:|---|---:|---:|---:|---|---:|---:|
| 5 min | 290 | Lucky | 1.75 | $612 | $268.39K | $18.87K | 5/6/3/7 | 2.5 | 0 | 23/120 | Void Emperor (Mythic) | 20/24 | $2.11M |
| 10 min | 616 | Flame | 2.24 | $1.05K | $552.3K | $27.65K | 5/6/4/8 | 5.5 | 0 | 23/120 | Void Emperor (Mythic) | 20/24 | $3.64M |
| 30 min | 2048 | Flame | 2.62 | $4.23K | $4.06M | $196.35K | 8/9/6/11 | 14.2 | 0 | 29/120 | Void Emperor (Mythic) | 21/24 | $5M |
| 1 h | 4528 | Storm | 3.76 | $6.46K | $14.79M | $792.31K | 11/11/9/14 | 12.2 | 0 | 34/120 | Astral Seraph (Divine) | 22/24 | $5M |
| 2 h | 9841 | Void | 5.27 | $12.23K | $45.13M | $2.27M | 11/11/9/14 | 12.8 | 1 | 40/120 | Astral Seraph (Divine) | 22/24 | $11M |
| 4 h | 21020 | Void | 5.98 | $59.19K | $250.82M | $43.35M | 12/13/10/16 | 22.4 | 3 | 51/120 | Astral Seraph (Divine) | 23/24 | $53.24M |
| 8 h | 46753 | Celestial | 10.35 | $318.76K | $2.55B | $8.23M | 14/15/11/19 | 34.2 | 6 | 63/120 | Eclipse Sovereign (Secret) | 24/24 | $566.89M |

Renascimentos em: 102 min, 155 min, 212 min, 289 min, 382 min, 473 min. Próximo custa $1.13B.

### Hardcore

Roll AUTO (cooldown), coleta a cada 5 s, decide a cada 3 s, gasta 60% em níveis de estação, renasce com 1.0x o custo, sobe torres a cada minuto.

| Tempo | Rolls | Dado | Luck | Renda/s | Ganho total | Saldo | Upg L/I/S/C | Nível médio estação | Renasc. | Andares (torres) | Melhor | Index | 8 h offline |
|---|---:|---|---:|---:|---:|---:|---|---:|---:|---:|---|---:|---:|
| 5 min | 289 | Lucky | 1.75 | $830.25 | $301.98K | $16.42K | 5/5/3/7 | 4.5 | 0 | 23/120 | Void Emperor (Mythic) | 20/24 | $2.86M |
| 10 min | 605 | Flame | 2.24 | $1.51K | $694.08K | $15.3K | 5/6/3/7 | 8.5 | 0 | 24/120 | Void Emperor (Mythic) | 20/24 | $5M |
| 30 min | 2009 | Storm | 3.28 | $4.21K | $4.92M | $411.6K | 8/8/6/11 | 15.0 | 0 | 30/120 | Void Emperor (Mythic) | 21/24 | $5M |
| 1 h | 4459 | Storm | 3.60 | $5.26K | $13.79M | $3.06M | 10/11/8/14 | 11.8 | 0 | 32/120 | Void Emperor (Mythic) | 21/24 | $5M |
| 2 h | 9734 | Void | 4.60 | $9.19K | $38.78M | $6.86M | 8/9/7/11 | 6.8 | 1 | 46/120 | Eclipse Sovereign (Secret) | 23/24 | $11M |
| 4 h | 19724 | Celestial | 8.35 | $44.4K | $251.05M | $45.98M | 11/11/8/14 | 12.4 | 3 | 55/120 | Eclipse Sovereign (Secret) | 24/24 | $53.24M |
| 8 h | 44355 | Celestial | 11.91 | $508.21K | $3.93B | $569.14M | 18/19/11/20 | 35.3 | 6 | 70/120 | Eclipse Sovereign (Secret) | 24/24 | $566.89M |

Renascimentos em: 108 min, 145 min, 189 min, 272 min, 316 min, 398 min. Próximo custa $1.13B.

### Nível de personagem (1 → 50)

Custo L→L+1 = BaseIncome × 60 s × 1.20^(L−1); ganho por nível = +25% da renda base da unidade.
Payback = custo do nível ÷ renda que ele adiciona (multiplicadores globais encurtam o payback na mesma proporção).

| Nível | Custo do próximo (× BaseIncome) | Custo acumulado desde 1 | Renda da unidade | Payback do próximo nível |
|---:|---:|---:|---:|---:|
| 1 | 60 | 0 | 1.00x | 4 min |
| 5 | 124.41 | 322.08 | 2.00x | 8 min |
| 10 | 309.58 | 1.24K | 3.25x | 20 min |
| 15 | 770.35 | 3.55K | 4.50x | 51 min |
| 20 | 1.91K | 9.28K | 5.75x | 2.1 h |
| 25 | 4.76K | 23.54K | 7.00x | 5.3 h |
| 30 | 11.86K | 59.04K | 8.25x | 13.2 h |
| 35 | 29.53K | 147.36K | 9.50x | 1.4 dias |
| 40 | 73.48K | 367.14K | 10.75x | 3.4 dias |
| 45 | 182.86K | 914.01K | 12.00x | 8.5 dias |
| 49 | 379.18K | 1.89M | 13.00x | 17.6 dias |

Total 1→50 ≈ 2.27M × BaseIncome para 13.25x de renda: os primeiros ~15 níveis se pagam em minutos/poucas horas; depois disso subir de raridade (roll/fusão) rende mais — a decisão "melhorar ou rolar" é real.

### Curva das torres

Poder dos inimigos = BasePower × Growth^(andar−1); chefe a cada 10 andares (0.7x em 1 inimigo). Recompensa só na 1ª vitória de cada andar (sem farm): max(poder × 1, renda/s × 8 s).

| Torre | Andar 1 | Andar 10 | Andar 20 | Último | Soma do dinheiro (piso) |
|---|---:|---:|---:|---:|---:|
| Ember | 150 | 1.2K | 12.1K | 122.13K (30) | $591.3K |
| Storm | 120K | 332.76K | 1.03M | 9.96M (40) | $92.05M |
| Void | 10M | 18.07M | 34.9M | 251.18M (50) | $3.79B |

A soma de TODOS os andares de uma torre fica abaixo de 1 custo de renascimento da fase em que ela é jogada — torre é bônus, não substitui a renda da base.

### Dinheiro offline x jogo ativo

Fórmula: renda/s salva × min(tempo fora, 8 h) × 12%. Com esses valores, **8 h offline ≈ 0.96 h**
de renda passiva jogando ativo no mesmo ponto do jogo (coluna "8 h offline" acima),
limitado a 50% do custo do próximo renascimento (não dá para comprar renascimentos dormindo).

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
