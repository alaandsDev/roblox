# PLAYER AURAS — auditoria econômica (proposta, NÃO implementada)

> **Status:** só simulação e proposta. Nada de Player Aura existe no jogo: nenhum save, serviço,
> remote, UI ou multiplicador foi adicionado. IncomeCurve, taxa 1,11, pivô 0,10, preços dos Dice,
> RNG, pesos, pity, Luck, Rebirth e a economia atual **não foram alterados** (o simulador ganhou
> uma opção desligada por padrão; com ela desligada o resultado é idêntico — `tests/EconomyModel.spec.luau`).
>
> Player Auras ≠ Character Auras: as auras dos personagens colecionáveis (AuraConfig/AuraBuilder)
> continuam só nos personagens; a Player Aura seria um sistema NOVO, no avatar do jogador.

## Resumo (para decidir)

| | Hipótese H (pedido) | Recomendação R |
|---|---|---|
| 1ª aura | 100M ×2 em **~1,9–3 h**, se paga em **0,2–0,6 h** → compra óbvia, sem decisão | 1B ×1,5 em **~3–5,5 h** (depois do Forbidden), se paga em **0,9–2,9 h** |
| Renda em 10 h (Ativo) | **×3,5** a do jogo atual (3,73M × 1,07M/s) | **×1,6** (1,70M/s) |
| Renda em 40 h (Ativo) | **×4,1** (14,3M/s) | **×2,4** (8,3M/s) |
| Topo | Celestial 5T: 0% dos F2P em 40 h, ~89–96 h para Ativo/Otimizador; **Absoluta 250T: 0% em 120 h** (inalcançável) | Divina 250B em ~15–31 h; Celestial 2,5T em ~49–93 h (Casual: não em 120 h); Absoluta = prestígio (ver §4) |
| Dice | Forbidden ~0,1–0,3 h mais cedo | Forbidden no MESMO tempo (a aura nunca compete com a trilha de Dice) |

**Recomendação:** Money côncavo ×1,5 / ×1,75 / ×2 / ×2,25 / ×2,5 com preços **1B / 25B / 250B / 2,5T / 10T**
(a Absoluta foi simulada a 25T e ninguém chega em 120 h: recomendo 10T e validar com uma rodada de
200 h antes de implementar). Speed NÃO deve ser 2x–4x: WalkSpeed 28 / 30 / 32 / 34 / 36 (base 22,
teto 40). O multiplicador vale sempre o da MAIOR aura comprada, calculado no servidor.


## 1. Método

- Simulador oficial `tools/sim/EconomyModel.luau` (o mesmo do `ECONOMY_BALANCE_ANALYSIS.md`: roll
  idêntico ao `DiceCore`, renda Dice × Raridade, níveis, venda, upgrades, Rebirth 15M × 2,2ⁿ,
  torres, diário, missões, Jackpot, offline, fusão, Prisma) com a opção **`playerAuras`**:
  - compra permanente (não reseta no Rebirth), em ordem; vale o multiplicador da MAIOR aura comprada
    (não empilha: ×2,5 depois de ×2 = ×2,5, não ×5);
  - o multiplicador entra como mais um fator da renda/s (como VIP e Rebirth hoje): coletor,
    offline (com o MESMO teto de 25% do próximo Rebirth) e os prêmios definidos em "segundos de
    renda" (torre, missões, diário, Jackpot). Venda, reembolso, Dice, Rebirth, fusão e trocas não;
  - prioridade do jogador: **Dice > aura > Rebirth**. Cada perfil aceita ADIAR o Rebirth para juntar
    a próxima aura se o preço ≤ `saveRatio` × custo do próximo Rebirth (Casual 1, Ativo 2,
    Otimizador 3, Pago 2); juntando (≥ 50% do preço) ele para de gastar em níveis/upgrades, como já
    faz quando junta para o Rebirth.
- Linha de base (`baseH`/`baseR`): o jogo atual, ninguém compra; registra só quando o **saldo**
  poderia pagar cada aura.
- Mesmas sementes em todos os cenários; P50 (P10/P90 onde indicado). Horizonte 40 h ativas (10/20/40 h)
  e um horizonte longo para as últimas auras.
- Reproduzir: `python3 tools/sim/run_player_aura_audit.py` (≈ 25 min em 4 núcleos; `--players 20
  --long-players 8` ≈ 4 min). Reescreve só a parte entre os marcadores GERADO.

Cenários:

| Aura | H (hipótese do pedido) Preço · Speed · Money | R (recomendação) Preço · Money |
|---|---|---|
| Aura Desperta | 100M · 2x · 2x | 1B · ×1,5 |
| Aura Imperial | 5B · 2,5x · 2,5x | 25B · ×1,75 |
| Aura Divina | 100B · 3x · 3x | 250B · ×2 |
| Aura Celestial | 5T · 3,5x · 3,5x | 2,5T · ×2,25 |
| Aura Absoluta | 250T · 4x · 4x | 25T · ×2,5 (recomendação final: 10T, ver §4) |

## 2. Resultados

<!-- GERADO:INICIO -->

_Gerado por `python3 tools/sim/run_player_aura_audit.py --players 120 --hours 40` — 120 jogadores por perfil e cenário, MESMAS sementes entre cenários; P50 salvo indicação._

### Hipótese do pedido (H): compra de cada aura por perfil

| Perfil | Aura | Preço | Money | Pode pagar¹ (P50) | Comprou em 40 h | Compra P10 / P50 / P90 | Renda/s na compra | Rebirths na compra | Payback² | Ciclo de Rebirth com a compra³ |
|---|---|---|---|---|---|---|---|---|---|---|
| Casual | Aura Desperta | 100.00M | ×2 | 2.8 h (100%) | 100% | 2.7 h / 2.8 h / 3.2 h | 45.34K/s | 3 | 0.6 h | 0.8 h |
| Casual | Aura Imperial | 5.00B | ×2.5 | 8.0 h (100%) | 100% | 6.0 h / 6.3 h / 6.4 h | 728.55K/s | 8 | 7.6 h | 1.4 h |
| Casual | Aura Divina | 100.00B | ×3 | 30.0 h (100%) | 100% | 14.0 h / 14.7 h / 15.3 h | 2.82M/s | 12 | 49.3 h | 6.0 h |
| Casual | Aura Celestial | 5.00T | ×3.5 | — (0%) | 0% | — / — / — | —/s | — | — | — |
| Casual | Aura Absoluta | 250.00T | ×4 | — (0%) | 0% | — / — / — | —/s | — | — | — |
| Ativo | Aura Desperta | 100.00M | ×2 | 3.2 h (100%) | 100% | 2.6 h / 3.0 h / 3.2 h | 89.15K/s | 2 | 0.3 h | 0.9 h |
| Ativo | Aura Imperial | 5.00B | ×2.5 | 8.2 h (100%) | 100% | 5.3 h / 5.8 h / 6.0 h | 1.24M/s | 7 | 4.5 h | 1.4 h |
| Ativo | Aura Divina | 100.00B | ×3 | 27.0 h (100%) | 100% | 12.0 h / 13.0 h / 14.0 h | 4.65M/s | 11 | 29.9 h | 5.0 h |
| Ativo | Aura Celestial | 5.00T | ×3.5 | — (0%) | 0% | — / — / — | —/s | — | — | — |
| Ativo | Aura Absoluta | 250.00T | ×4 | — (0%) | 0% | — / — / — | —/s | — | — | — |
| Otimizador | Aura Desperta | 100.00M | ×2 | 3.4 h (100%) | 100% | 2.8 h / 3.1 h / 3.4 h | 102.90K/s | 2 | 0.3 h | 0.9 h |
| Otimizador | Aura Imperial | 5.00B | ×2.5 | 8.6 h (100%) | 100% | 5.3 h / 5.7 h / 6.0 h | 1.04M/s | 6 | 5.4 h | 1.7 h |
| Otimizador | Aura Divina | 100.00B | ×3 | 31.8 h (100%) | 100% | 13.0 h / 14.0 h / 14.8 h | 3.94M/s | 10 | 35.3 h | 6.5 h |
| Otimizador | Aura Celestial | 5.00T | ×3.5 | — (0%) | 0% | — / — / — | —/s | — | — | — |
| Otimizador | Aura Absoluta | 250.00T | ×4 | — (0%) | 0% | — / — / — | —/s | — | — | — |
| Pago | Aura Desperta | 100.00M | ×2 | 2.0 h (100%) | 100% | 1.5 h / 1.9 h / 2.1 h | 164.06K/s | 2 | 0.2 h | 0.6 h |
| Pago | Aura Imperial | 5.00B | ×2.5 | 5.0 h (100%) | 100% | 3.0 h / 3.5 h / 3.9 h | 2.31M/s | 7 | 2.4 h | 0.9 h |
| Pago | Aura Divina | 100.00B | ×3 | 15.6 h (100%) | 100% | 7.1 h / 8.0 h / 8.5 h | 8.34M/s | 11 | 16.7 h | 3.2 h |
| Pago | Aura Celestial | 5.00T | ×3.5 | — (0%) | 0% | — / — / — | —/s | — | — | — |
| Pago | Aura Absoluta | 250.00T | ×4 | — (0%) | 0% | — / — / — | —/s | — | — | — |

### Recomendação (R): compra de cada aura por perfil

| Perfil | Aura | Preço | Money | Pode pagar¹ (P50) | Comprou em 40 h | Compra P10 / P50 / P90 | Renda/s na compra | Rebirths na compra | Payback² | Ciclo de Rebirth com a compra³ |
|---|---|---|---|---|---|---|---|---|---|---|
| Casual | Aura Desperta | 1.00B | ×1.5 | 5.5 h (100%) | 100% | 5.2 h / 5.5 h / 5.8 h | 188.73K/s | 6 | 2.9 h | 1.3 h |
| Casual | Aura Imperial | 25.00B | ×1.75 | 14.3 h (100%) | 100% | 11.0 h / 11.5 h / 12.0 h | 987.65K/s | 10 | 42.2 h | 4.0 h |
| Casual | Aura Divina | 250.00B | ×2 | — (0%) | 100% | 29.4 h / 31.4 h / 33.7 h | 2.45M/s | 13 | 198.7 h | 15.3 h |
| Casual | Aura Celestial | 2.50T | ×2.25 | — (0%) | 0% | — / — / — | —/s | — | — | — |
| Casual | Aura Absoluta | 25.00T | ×2.5 | — (0%) | 0% | — / — / — | —/s | — | — | — |
| Ativo | Aura Desperta | 1.00B | ×1.5 | 5.7 h (100%) | 100% | 4.7 h / 5.0 h / 5.4 h | 333.14K/s | 5 | 1.7 h | 1.2 h |
| Ativo | Aura Imperial | 25.00B | ×1.75 | 14.0 h (100%) | 100% | 10.0 h / 10.6 h / 11.0 h | 1.69M/s | 9 | 24.6 h | 3.7 h |
| Ativo | Aura Divina | 250.00B | ×2 | 38.3 h (22%) | 100% | 23.3 h / 25.3 h / 26.2 h | 4.49M/s | 12 | 108.3 h | 12.2 h |
| Ativo | Aura Celestial | 2.50T | ×2.25 | — (0%) | 0% | — / — / — | —/s | — | — | — |
| Ativo | Aura Absoluta | 25.00T | ×2.5 | — (0%) | 0% | — / — / — | —/s | — | — | — |
| Otimizador | Aura Desperta | 1.00B | ×1.5 | 5.7 h (100%) | 100% | 4.4 h / 4.9 h / 5.4 h | 252.74K/s | 4 | 2.2 h | 1.7 h |
| Otimizador | Aura Imperial | 25.00B | ×1.75 | 15.5 h (100%) | 100% | 10.7 h / 11.8 h / 12.0 h | 1.83M/s | 9 | 22.7 h | 4.4 h |
| Otimizador | Aura Divina | 250.00B | ×2 | — (0%) | 100% | 26.0 h / 28.0 h / 29.0 h | 3.91M/s | 11 | 124.4 h | 15.1 h |
| Otimizador | Aura Celestial | 2.50T | ×2.25 | — (0%) | 0% | — / — / — | —/s | — | — | — |
| Otimizador | Aura Absoluta | 25.00T | ×2.5 | — (0%) | 0% | — / — / — | —/s | — | — | — |
| Pago | Aura Desperta | 1.00B | ×1.5 | 3.4 h (100%) | 100% | 2.6 h / 3.0 h / 3.4 h | 616.94K/s | 5 | 0.9 h | 0.7 h |
| Pago | Aura Imperial | 25.00B | ×1.75 | 8.0 h (100%) | 100% | 6.0 h / 6.4 h / 7.0 h | 3.10M/s | 9 | 13.5 h | 2.4 h |
| Pago | Aura Divina | 250.00B | ×2 | 24.0 h (100%) | 100% | 14.0 h / 15.0 h / 16.0 h | 8.03M/s | 12 | 60.5 h | 7.0 h |
| Pago | Aura Celestial | 2.50T | ×2.25 | — (0%) | 0% | — / — / — | —/s | — | — | — |
| Pago | Aura Absoluta | 25.00T | ×2.5 | — (0%) | 0% | — / — / — | —/s | — | — | — |

¹ Na linha de base (jogo atual, ninguém compra): 1º momento em que o SALDO ≥ preço, e % dos jogadores que chegam lá em 40 h. Com o Rebirth zerando o saldo, isso só acontece quando o Rebirth seguinte custa ≈ o preço (ou o jogador adia o Rebirth).
² Tempo ATIVO para o ganho extra de renda (× novo ÷ × anterior − 1) pagar o preço, com a renda do momento da compra (sem contar o crescimento depois — limite superior).
³ Tempo entre o Rebirth anterior e o seguinte quando a compra cai no meio (inclui o tempo poupando para a aura).

### Impacto em 10 h / 20 h / 40 h ativas (P50)

| Perfil | Cenário | Renda/s 10 h | Renda/s 20 h | Renda/s 40 h | Rebirths 10/20/40 h | Ganho total 40 h | Gasto em auras 40 h | Forbidden comprado (P50) |
|---|---|---|---|---|---|---|---|---|
| Casual | atual (sem auras) | 469.89K | 814.40K | 1.33M | 9 / 11 / 13 | 432.92B | 0 | 4.9 h |
| Casual | H | 2.22M | 4.19M | 6.55M | 11 / 13 / 15 | 2.17T | 105.10B | 4.8 h |
| Casual | R | 973.31K | 1.88M | 3.22M | 10 / 12 / 13 | 1.04T | 276.00B | 4.9 h |
| Ativo | atual (sem auras) | 1.07M | 2.04M | 3.52M | 9 / 11 / 13 | 555.36B | 0 | 4.0 h |
| Ativo | H | 3.73M | 9.00M | 14.28M | 10 / 13 / 15 | 2.20T | 105.10B | 3.7 h |
| Ativo | R | 1.70M | 4.43M | 8.30M | 9 / 12 / 14 | 1.16T | 276.00B | 4.0 h |
| Otimizador | atual (sem auras) | 1.17M | 2.23M | 3.74M | 9 / 11 / 13 | 413.27B | 0 | 4.0 h |
| Otimizador | H | 3.91M | 8.40M | 13.62M | 10 / 12 / 14 | 1.61T | 105.10B | 3.9 h |
| Otimizador | R | 1.82M | 3.91M | 7.75M | 9 / 11 / 13 | 764.88B | 276.00B | 4.0 h |
| Pago | atual (sem auras) | 3.57M | 6.06M | 8.69M | 11 / 13 / 14 | 1.54T | 0 | 2.4 h |
| Pago | H | 13.22M | 21.65M | 35.17M | 12 / 14 / 16 | 5.88T | 105.10B | 2.2 h |
| Pago | R | 6.43M | 12.59M | 20.00M | 11 / 13 / 15 | 3.29T | 276.00B | 2.4 h |

### Longo prazo: 120 h ativas (24 jogadores por perfil e cenário) — quando chegam as últimas auras

| Perfil | Cenário | Aura | Preço | Comprou em 120 h | Compra P50 | Renda/s na compra | Rebirths na compra | Renda/s 120 h | Rebirths 120 h |
|---|---|---|---|---|---|---|---|---|---|
| Casual | H | Aura Divina | 100.00B | 100% | 14.4 h | 2.88M/s | 12 | 8.55M | 17 |
| Casual | H | Aura Celestial | 5.00T | 0% | — | —/s | — | 8.55M | 17 |
| Casual | H | Aura Absoluta | 250.00T | 0% | — | —/s | — | 8.55M | 17 |
| Casual | R | Aura Divina | 250.00B | 100% | 31.0 h | 2.45M/s | 13 | 4.44M | 16 |
| Casual | R | Aura Celestial | 2.50T | 0% | — | —/s | — | 4.44M | 16 |
| Casual | R | Aura Absoluta | 25.00T | 0% | — | —/s | — | 4.44M | 16 |
| Ativo | H | Aura Divina | 100.00B | 100% | 13.0 h | 4.79M/s | 11 | 35.35M | 17 |
| Ativo | H | Aura Celestial | 5.00T | 100% | 89.1 h | 21.22M/s | 16 | 35.35M | 17 |
| Ativo | H | Aura Absoluta | 250.00T | 0% | — | —/s | — | 35.35M | 17 |
| Ativo | R | Aura Divina | 250.00B | 100% | 25.6 h | 4.46M/s | 12 | 18.95M | 16 |
| Ativo | R | Aura Celestial | 2.50T | 100% | 83.6 h | 11.81M/s | 15 | 18.95M | 16 |
| Ativo | R | Aura Absoluta | 25.00T | 0% | — | —/s | — | 18.95M | 16 |
| Otimizador | H | Aura Divina | 100.00B | 100% | 14.0 h | 4.05M/s | 10 | 29.28M | 16 |
| Otimizador | H | Aura Celestial | 5.00T | 100% | 95.7 h | 17.64M/s | 15 | 29.28M | 16 |
| Otimizador | H | Aura Absoluta | 250.00T | 0% | — | —/s | — | 29.28M | 16 |
| Otimizador | R | Aura Divina | 250.00B | 100% | 28.0 h | 3.92M/s | 11 | 16.33M | 15 |
| Otimizador | R | Aura Celestial | 2.50T | 100% | 93.1 h | 9.90M/s | 14 | 16.33M | 15 |
| Otimizador | R | Aura Absoluta | 25.00T | 0% | — | —/s | — | 16.33M | 15 |
| Pago | H | Aura Divina | 100.00B | 100% | 7.9 h | 8.09M/s | 11 | 59.31M | 18 |
| Pago | H | Aura Celestial | 5.00T | 100% | 54.0 h | 34.98M/s | 16 | 59.31M | 18 |
| Pago | H | Aura Absoluta | 250.00T | 0% | — | —/s | — | 59.31M | 18 |
| Pago | R | Aura Divina | 250.00B | 100% | 15.1 h | 7.62M/s | 12 | 31.81M | 17 |
| Pago | R | Aura Celestial | 2.50T | 100% | 49.0 h | 19.97M/s | 15 | 31.81M | 17 |
| Pago | R | Aura Absoluta | 25.00T | 0% | — | —/s | — | 31.81M | 17 |

Custo do Rebirth n (15M × 2,2ⁿ) para comparar com os preços: RB1 15.00M, RB3 72.60M, RB5 351.38M, RB7 1.70B, RB9 8.23B, RB11 39.84B, RB13 192.83B, RB15 933.27B, RB17 4.52T, RB19 21.86T, RB21 105.81T, RB23 512.14T.

<!-- GERADO:FIM -->

## 3. Leitura da hipótese H

1. **Forte demais no começo.** A Desperta (100M) cabe no saldo do 2º–3º Rebirth (~2–3 h) e dobra
   a renda: payback de 0,2–0,6 h ativas — não existe decisão, é compra obrigatória. Como a renda
   alimenta tudo (níveis mais baratos em payback, Rebirth mais cedo, prêmios em segundos de renda),
   o ×2 COMPÕE: em 10 h a renda fica 3,3–4,7× a atual e o jogador ganha 1–2 Rebirths a mais em 40 h.
2. **Inalcançável no fim.** A economia atual achata depois de ~13–15 Rebirths: o Rebirth dá +25%
   LINEAR enquanto o custo cresce ×2,2. Em 120 h ativas o F2P tem 4–35M/s; 5T exige adiar o Rebirth
   e juntar dezenas de horas; 250T (≈ RB22) não chega para nenhum perfil, nem o Pago.
3. **Rebirth × aura.** Como o Rebirth ZERA o saldo, "poder pagar" só acontece quando o preço ≈
   custo do próximo Rebirth — ou se o jogador adiar o Rebirth para juntar (coluna "Ciclo de Rebirth":
   o ciclo em que a compra cai fica 1,5–3× mais longo). Isso é BOM para um money sink: a aura
   compete com o Rebirth, vira uma decisão real.

## 4. Recomendação de preço e multiplicador

| Aura | Preço | Money | ≈ custo do Rebirth | Quando (P50, simulado) | Payback na compra |
|---|---|---|---|---|---|
| Aura Desperta | **1B** | ×1,5 | RB7 (1,7B) | 3,0 h (Pago) · 4,9–5,5 h (F2P) | 0,9–2,9 h |
| Aura Imperial | **25B** | ×1,75 | RB11 (40B) | 6,4 h (Pago) · 10,6–11,8 h (F2P) | 13–42 h |
| Aura Divina | **250B** | ×2 | RB14 (424B) | 15 h (Pago) · 25–31 h (F2P) | 60–200 h |
| Aura Celestial | **2,5T** | ×2,25 | RB16–17 | 49 h (Pago) · 84–93 h (Ativo/Otim.) · Casual > 120 h | — |
| Aura Absoluta | **10T** (simulado: 25T) | ×2,5 | RB18 (9,9T) | prestígio: > 120 h (25T: 0% em 120 h) | — |

Por quê:
- **1ª aura depois do Forbidden (400M):** a trilha de Dice continua sendo o objetivo das primeiras
  horas; a aura começa como meta do mid-game (Forbidden comprado no mesmo tempo em R e no atual).
- **Côncavo e não multiplicativo:** cada degrau soa forte (+50%, depois +16%, +14%, +12%, +11%
  relativos) mas não compõe como ×2/×2,5/×3. A renda em 40 h fica ~2,4× a atual (H: ~4×).
- **Paybacks crescentes:** a 1ª se paga em poucas horas (desejável), as do meio em dezenas de horas
  (decisão: aura ou Rebirth?), as do topo são prestígio/sink de late game.
- **Não usar 250T:** com a curva de Rebirth atual (que NÃO deve mudar) ninguém chega; preço que
  ninguém alcança não drena dinheiro nenhum.

## 5. Quais fontes de Money o PlayerMoneyMultiplier afeta

Regra: o multiplicador entra como MAIS UM fator de `GameFormulas:incomeMultiplier` (como VIP, Rebirth
e perk de Renda já entram). Assim tudo que é "renda/s" ou "N segundos de renda" acompanha sozinho, e
nada que cria dinheiro do nada é multiplicado.

| Fonte | Multiplica? | Motivo |
|---|---|---|
| Renda das estações (coletor) | **Sim** | é o objetivo da aura |
| Offline | **Sim** (pela renda) | o TETO de 25% do custo do próximo Rebirth continua igual |
| Torre (`max(poder × 1, renda × 8)`) | **Só a parte "renda × 8"** | automático; o mínimo por poder não muda |
| Missões / Diário / Jackpot em "segundos de renda" | **Sim** (pela renda) | automático; os mínimos fixos não mudam |
| Venda de personagens / venda em massa | **Não** | multiplicar venda abre arbitragem (rolar → vender) |
| Reembolso de investimento (refund 75%) | **Não** | é devolução do que foi pago |
| Rebirth (fichas, bônus) | **Não** | Rebirth não dá dinheiro; a curva aprovada não muda |
| Trocas | **Não** | P2P: nenhum dinheiro é criado |
| Fusão | **Não** | é custo (sink), não fonte |
| Preços (Dice, upgrades, níveis, Rebirth) | **Não** | a aura não barateia nada |

Segurança: o multiplicador é DERIVADO no servidor do save (`PlayerAura.Owned` = maior tier comprado);
o cliente nunca envia nem define multiplicador, preço ou tier. Compra: um remote `BuyPlayerAura(tier,
requestId)` que só aceita o PRÓXIMO tier, cobra o preço da config (nunca do cliente), é idempotente
pelo requestId e grava no mesmo passo do débito.

## 6. Velocidade (WalkSpeed derivada no servidor)

2x–4x literal (44–88 de WalkSpeed) quebra rampas de 20 studs, grades dos andares, esteira, colisão
com pedestais e o controle no mobile. Proposta: curva côncava sobre a base 22 (MovementConfig),
sempre abaixo do teto `MovementConfig.MaxWalkSpeed = 40`:

| Aura | Speed exibido | WalkSpeed | vs. base 22 |
|---|---|---|---|
| (nenhuma) | — | 22 | — |
| Desperta | +25% | 28 | +27% |
| Imperial | +35% | 30 | +36% |
| Divina | +45% | 32 | +45% |
| Celestial | +55% | 34 | +55% |
| Absoluta | +65% | 36 | +64% |

Aplicada pelo servidor no spawn (já é assim com a base) e na compra; pulo não muda. A velocidade
quase não mexe na economia (a coleta não depende de andar), então é só conforto/status.

## 7. Visual das Player Auras (proposta)

- Uma por tier, **mais leve que a Character Aura Divine/Secret Full** (o avatar anda, as do
  personagem ficam paradas): orçamento ~20 / 30 / 45 / 60 / 80 partículas/s, 1 rastro nos pés a
  partir da Imperial, anel no chão a partir da Divina, **sem Highlight** (o orçamento de contornos
  fica com os personagens), PointLight só complemento.
- Segue o jogador (presa ao HumanoidRootPart), nenhum script dentro do efeito; LOD: auras de OUTROS
  jogadores ficam Light além de ~40 studs e somem além de ~90; mobile × 0,5.
- Construída pelo mesmo pipeline do AuraBuilder (texturas nativas rbxasset://). **Auras Pack: não
  usado** — a auditoria do pack real continua pendente; nada sem proveniência/segurança confirmada.

## 8. UX: estação AURAS

Painel na estação do Hub: aura atual, próxima, preço, Speed, Money, preview, **COMPRAR** e
**EQUIPAR**. O preview não pode ser ViewportFrame (não renderiza partículas — o mesmo motivo do
Jackpot Reveal): usar um pedestal de vitrine no mundo, local do cliente.

Equipar uma aura ANTERIOR: **pode** (é só visual, inclusive "nenhuma"). A regra no servidor é
inequívoca: `MoneyMultiplier` e `WalkSpeed` = da MAIOR aura comprada (`Owned`), independentemente
do visual equipado (`EquippedVisual`, validado ≤ `Owned`).

## 9. Próximos passos (quando aprovado)

1. Confirmar preços/multiplicadores (e a Absoluta com uma rodada de 200 h).
2. Implementar: `PlayerAuraConfig`, save `PlayerAura = { Owned, EquippedVisual }` + migração,
   fator em `incomeMultiplier`, `PlayerAuraService` (compra idempotente), WalkSpeed por tier,
   visual, estação/painel, testes (servidor nunca aceita multiplicador do cliente; ordem dos tiers;
   offline mantém o teto; venda não multiplica).
3. Regenerar `ECONOMY_BALANCE_ANALYSIS.md` com a aura aprovada.

