# PLAYER AURAS — auditoria econômica (proposta, NÃO implementada)

> **Status:** só simulação e proposta. Nada de Player Aura existe no jogo: nenhum save, serviço,
> remote, UI ou multiplicador foi adicionado. IncomeCurve, taxa 1,11, pivô 0,10, preços dos Dice,
> RNG, pesos, pity, Luck, Rebirth e a economia atual **não foram alterados** (o simulador ganhou
> uma opção desligada por padrão; com ela desligada o resultado é idêntico — `tests/EconomyModel.spec.luau`).
>
> Player Auras ≠ Character Auras: as auras dos personagens colecionáveis (AuraConfig/AuraBuilder)
> continuam só nos personagens; a Player Aura seria um sistema NOVO, no avatar do jogador.

<!-- RESUMO -->

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
| Aura Absoluta | 250T · 4x · 4x | 25T · ×2,5 |

## 2. Resultados

<!-- GERADO:INICIO -->
<!-- GERADO:FIM -->

<!-- ANALISE -->
