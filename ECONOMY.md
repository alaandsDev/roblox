# ECONOMY — Roll Legends

Toda a economia é **configurável** e calculada no **servidor** (`src/shared/Modules/Formulas.luau`).
Os números abaixo são gerados pela simulação com as **mesmas configs e fórmulas** do jogo
(`tools/sim/EconomySim.luau`, rode `tools/bin/lune-0.10.4/lune run tools/sim/simulate_economy.luau`).
A regressão `tests/Economy.spec.luau` falha se a progressão "quebrar".

> **Balanceamento aplicado (depois de d9a8da2):** refund 75% por instância (fusão soma, troca
> carrega), MaxLevel 30, Forbidden 400M, rolls Flame 450 / Blade 650 + 60 rolls com o Dice anterior
> (sem compra em cascata), venda base 20–90 s, 1º Rebirth 15M, offline 25% do próximo Rebirth,
> conquista do Índice 14/28/56/112 (só F2P), Pacote de dinheiro 60 gemas. Prisma, pity, pesos e
> cadência intocados. Testes: `tests/EconomyApplied.spec.luau`.
>
> **Auditoria completa (por Dice, Monte Carlo, 4 perfis):** `ECONOMY_BALANCE_ANALYSIS.md`, gerado
> por `python3 tools/sim/run_economy_analysis.py` com o simulador NOVO `tools/sim/EconomyModel.luau`
> (roll idêntico ao DiceCore, pity 50/250). `EconomySim.luau`/`Odds.luau` são **LEGACY** (RollCore
> global, pity 50/800 fixado) e ficam só para as regressões antigas.

## Fontes de dinheiro

| Fonte | Fórmula | Config |
|---|---|---|
| Renda das estações | Σ (BaseIncome × (1 + (Level−1) × 0,25) × Variante) × (1 + nível Income × 10%) | CharacterConfig, CharacterLevelConfig, VariantConfig, UpgradeConfig |
| Coletor | renda acumula em `UncollectedMoney` (teto = 1 h de renda) e vai para Money ao pisar/usar | EconomyConfig |
| Venda | `SaleCore.quote`: BaseIncome × SellSeconds[raridade] × Variante.SellMultiplier + **75%** do investimento em níveis gravado na própria unidade (`UpgradeInvestment`). SellSeconds: C/U 20 · R 25 · E 30 · L 35 · M 45 · D 60 · S 90 s. Prévia autoritativa: remote `PreviewSale` (base, investido, %, recuperado, total) | EconomyConfig.SellSeconds / UpgradeRefundPercent |
| Offline | renda/s salva × min(tempo fora, 8 h) × 12% | OfflineIncomeConfig |
| Diário | tabela de 7 dias (dinheiro escala com a renda) | DailyConfig |

## Gastos

| Gasto | Fórmula | Config |
|---|---|---|
| Melhorias globais | BaseCost × Growth^nível, até MaxLevel | UpgradeConfig (Luck 2000×1,9ⁿ /20 · Income 1500×1,85ⁿ /25 · RollSpeed 5000×2ⁿ /11 · Inventory 1000×1,7ⁿ /20) |
| Nível da estação | BaseUpgradeCost × 1,2^(Level−1), BaseUpgradeCost = BaseIncome × 60 s | CharacterLevelConfig (**MaxLevel 30**; saves acima migrados com o investimento preservado) |
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
6. **Renascimento** (Fase 8, revisado na auditoria; balanceamento aplicado: 1º = **15M**): custo **15M × 2,2ⁿ** (antes 10M × 2,2ⁿ e, na Fase 8, 5M × 3ⁿ, que
   ficava atrás da renda). Cada renascimento: +25% renda, +2% sorte (teto +50%), +10% poder,
   +1 pedestal e fichas. Ativo renasce pela 1ª vez em ~1h40 e 6 vezes em 8 h.
7. **Offline** limitado também a **25%** do custo do próximo renascimento (era 50%: 68% da renda do Casual vinha do offline).
8. Critérios automatizados: em 5 min (Hardcore) nenhuma melhoria ≥ 10 e no máximo o dado
   Flame; em 2 h (Ativo) ainda sem Celestial e com melhorias por comprar; 1º renascimento do
   Ativo entre 1 h e 3 h; offline ≤ metade do próximo renascimento.

## Resultados da simulação


<!-- SIM:BEGIN (gerado por tools/sim/simulate_economy.luau — não editar à mão) -->

### Casual

Roll manual a cada 2.5 s, coleta a cada 120 s, decide a cada 60 s, gasta 30% em níveis de estação, renasce com 1.0x o custo, sobe torres a cada minuto.

| Tempo | Rolls | Dado | Luck | Renda/s | Ganho total | Saldo | Upg L/I/S/C | Nível médio estação | Renasc. | Andares (torres) | Melhor | Index | 8 h offline |
|---|---:|---|---:|---:|---:|---:|---|---:|---:|---:|---|---:|---:|
| 5 min | 120 | Lucky | 1.55 | $255.85 | $64.18K | $6.5K | 3/4/0/5 | 1.8 | 0 | 18/120 | Solar Paladin (Legendary) | 16/24 | $884.21K |
| 10 min | 240 | Lucky | 1.75 | $361.5 | $205.43K | $10.34K | 5/6/0/7 | 1.2 | 0 | 20/120 | Solar Paladin (Legendary) | 19/24 | $1.24M |
| 30 min | 720 | Flame | 2.62 | $1.29K | $1.27M | $59.48K | 8/8/0/10 | 7.5 | 0 | 22/120 | Solar Paladin (Legendary) | 19/24 | $4.46M |
| 1 h | 1440 | Storm | 3.44 | $2.75K | $5.38M | $420.07K | 9/10/0/13 | 13.2 | 0 | 26/120 | Celestial Monk (Mythic) | 20/24 | $5M |
| 2 h | 2880 | Storm | 3.92 | $8.4K | $29.86M | $6.2M | 12/13/0/15 | 18.5 | 0 | 34/120 | Celestial Monk (Mythic) | 21/24 | $5M |
| 4 h | 5760 | Void | 6.11 | $31.55K | $162.44M | $5.18M | 13/15/0/17 | 27.2 | 2 | 40/120 | Celestial Monk (Mythic) | 21/24 | $24.2M |
| 8 h | 11520 | Celestial | 10.67 | $141.22K | $1.62B | $51.76M | 17/18/0/20 | 40.4 | 4 | 60/120 | Eclipse Sovereign (Secret) | 22/24 | $117.12M |

Renascimentos em: 138 min, 206 min, 254 min, 354 min. Próximo custa $234.25M.

### Ativo

Roll AUTO (cooldown), coleta a cada 30 s, decide a cada 15 s, gasta 50% em níveis de estação, renasce com 1.0x o custo, sobe torres a cada minuto.

| Tempo | Rolls | Dado | Luck | Renda/s | Ganho total | Saldo | Upg L/I/S/C | Nível médio estação | Renasc. | Andares (torres) | Melhor | Index | 8 h offline |
|---|---:|---|---:|---:|---:|---:|---|---:|---:|---:|---|---:|---:|
| 5 min | 300 | Flame | 2.24 | $708 | $280.06K | $12.51K | 5/6/0/7 | 3.2 | 0 | 23/120 | Void Emperor (Mythic) | 20/24 | $2.44M |
| 10 min | 600 | Flame | 2.37 | $1.14K | $583.07K | $35.8K | 6/6/0/8 | 6.0 | 0 | 23/120 | Void Emperor (Mythic) | 20/24 | $3.93M |
| 30 min | 1800 | Flame | 2.62 | $4.26K | $4.21M | $129.92K | 8/9/0/11 | 15.0 | 0 | 29/120 | Void Emperor (Mythic) | 20/24 | $5M |
| 1 h | 3600 | Storm | 3.76 | $5.59K | $14.32M | $2.35M | 11/11/0/14 | 13.2 | 0 | 32/120 | Void Emperor (Mythic) | 21/24 | $5M |
| 2 h | 7200 | Void | 5.27 | $13.48K | $43.73M | $5.37M | 11/12/0/15 | 17.6 | 1 | 35/120 | Void Emperor (Mythic) | 21/24 | $11M |
| 4 h | 14400 | Void | 6.59 | $30.94K | $225.34M | $28.93M | 15/16/0/19 | 21.2 | 2 | 42/120 | Chrono Sage (Divine) | 22/24 | $24.2M |
| 8 h | 28800 | Celestial | 10.12 | $200.45K | $1.52B | $7.16M | 15/17/0/20 | 37.7 | 5 | 60/120 | Eclipse Sovereign (Secret) | 23/24 | $257.68M |

Renascimentos em: 98 min, 140 min, 266 min, 341 min, 452 min. Próximo custa $515.36M.

### Hardcore

Roll AUTO (cooldown), coleta a cada 5 s, decide a cada 3 s, gasta 60% em níveis de estação, renasce com 1.0x o custo, sobe torres a cada minuto.

| Tempo | Rolls | Dado | Luck | Renda/s | Ganho total | Saldo | Upg L/I/S/C | Nível médio estação | Renasc. | Andares (torres) | Melhor | Index | 8 h offline |
|---|---:|---|---:|---:|---:|---:|---|---:|---:|---:|---|---:|---:|
| 5 min | 300 | Flame | 2.24 | $879.75 | $313.51K | $4.85K | 5/5/0/7 | 4.8 | 0 | 23/120 | Void Emperor (Mythic) | 20/24 | $3.04M |
| 10 min | 600 | Flame | 2.24 | $1.57K | $734.44K | $13.74K | 5/6/0/8 | 9.0 | 0 | 24/120 | Void Emperor (Mythic) | 20/24 | $5M |
| 30 min | 1800 | Storm | 3.28 | $4.29K | $4.89M | $182.07K | 8/9/0/11 | 14.8 | 0 | 30/120 | Void Emperor (Mythic) | 21/24 | $5M |
| 1 h | 3600 | Storm | 3.76 | $4.81K | $13.3M | $2.58M | 11/11/0/14 | 10.5 | 0 | 31/120 | Void Emperor (Mythic) | 21/24 | $5M |
| 2 h | 7200 | Void | 5.39 | $4.83K | $32.54M | $8.17M | 12/13/0/15 | 8.0 | 0 | 32/120 | Astral Seraph (Divine) | 22/24 | $5M |
| 4 h | 14400 | Void | 5.74 | $44.47K | $187.38M | $42.66M | 11/12/0/15 | 23.1 | 3 | 47/120 | Astral Seraph (Divine) | 23/24 | $53.24M |
| 8 h | 28800 | Celestial | 10.49 | $192.95K | $1.9B | $25.01M | 16/17/0/20 | 41.4 | 5 | 57/120 | Astral Seraph (Divine) | 23/24 | $257.68M |

Renascimentos em: 126 min, 165 min, 211 min, 300 min, 362 min. Próximo custa $515.36M.

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
limitado a 25% do custo do próximo renascimento (não dá para comprar renascimentos dormindo).

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

## Compra em cascata e a "missão dos 10 minutos" (auditoria aplicada)

O simulador (`EconomyModel`) entrega as 3 missões diárias aos 10 min de jogo; no jogo real elas
pagam ao completar (roll_50, collect_5, rare_5... nos primeiros minutos), cada uma
`max(Amount, renda/s × 240–400 s)`. Em ambos os casos o dinheiro chega EM BLOCO e, como o
requisito era só de rolls TOTAIS, o jogador comprava Shinobi + Flame + Blade de uma vez (92% dos
Ativos nunca rolavam o Shinobi). A recompensa em si é proporcional e foi mantida.

Menor correção: cada Dice exige **60 rolls feitos com o Dice anterior** (`DiceConfig.RollsOnPrevious`,
`data.DiceRolls`, regra única em `DiceCore.unlockBlocker` para servidor e loja). Resultado no
simulador (400 Ativos, 6 h): Shinobi nunca rolado 92% → **0%**; Forbidden P50 ≈ 4,6 h.

## Torre contínua (AUTO / OCULTAR) — auditoria de throughput

A sessão contínua (`TowerService.StartSession`, `TowerSessionCore`) **não cria recompensa nova**:
cada andar paga `max(poder dos inimigos × 1, renda/s × 8)` **só na 1ª vitória** (o andar lutado é
sempre `TowerProgress + 1`, lido do save; o mesmo andar nunca paga duas vezes). O AUTO apenas
encadeia os andares que o jogador já poderia lutar manualmente.

| Torre | Andares | Dinheiro total (parte fixa, Σ poder) | Gemas totais |
|---|---|---|---|
| Brasas | 30 | ~591K | 205 |
| Tempestade | 40 | ~92M | 430 |
| Vazio | 50 | ~3,8B | 875 |

Teto absoluto por torre = parte fixa + `andares × 8 s` de renda (Brasas: 240 s; Tempestade:
320 s; Vazio: 400 s de renda) — **uma vez na vida do save**, igual ao fluxo manual. Ritmo: AUTO
luta um estágio a cada `Session.StageInterval = 3 s`; o manual já permitia 1 a cada 1,5 s
(`BattleCooldown`), então o AUTO é até MAIS LENTO por estágio. Sessão termina em derrota (não
recomeça do andar 1), PARAR, torre completa, 50 estágios, desconexão ou morte do personagem.
Conclusão: throughput econômico inalterado (o limite é o poder do time, não o tempo); nenhuma
proteção extra (cap/rendimento decrescente) foi necessária. Testes: `tests/TowerSession.spec.luau`
(+ GameplayHarness: idempotência, PARAR, derrota, desconexão, sessão duplicada).
