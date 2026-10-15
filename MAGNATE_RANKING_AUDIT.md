# RANKING MAGNATA — auditoria (proposta, NÃO implementada)

> **Status:** auditoria/proposta. Nada foi ativado no jogo: nenhum campo novo no save, nenhum
> ranking novo, nenhuma mudança em `EconomyService`, economia, Rebirth ou RNG. O que existe é um
> **protótipo puro** (`tools/sim/MoneyLedger.luau`) usado pelo simulador e pelos testes
> (`tests/MoneyLedger.spec.luau`, `tests/money_sources_test.py`).

## Resumo (para decidir)

- **LifetimeMoneyGenerated** = riqueza PRODUZIDA pela conta: soma só as fontes **GENERATED**
  (coletor, offline, torre, missões, diário). Nunca diminui; gastar, Dice, Player Aura, níveis,
  fusão e Rebirth não mexem nele; vai no save.
- **Não contam:** venda (RECYCLED), reembolso de investimento (REFUND), trocas (TRANSFER — hoje
  elas nem movem dinheiro), Jackpot, pacotes em Robux e DEV/admin (OTHER). Na simulação as fontes
  que contam são **~97–99,9% de todo o dinheiro** que entra: excluir o resto quase não muda a
  ordem, mas fecha todos os loops (comprar → upar → vender, troca, gemas compradas).
- **Porta única no servidor:** hoje TODO dinheiro já entra por `EconomyService.AddMoney(player,
  valor, origem)` (10 origens; verificado por `tests/money_sources_test.py`). A proposta é tornar a
  origem obrigatória e registrada (origem desconhecida = erro) e somar o Lifetime ali dentro, no
  mesmo passo — nenhum sistema precisa "lembrar" de incrementar o ranking.
- **Migração:** o save atual **não tem** nenhum histórico de dinheiro gerado (só `Money`, que o
  Rebirth zera). Não dá para reconstruir sem inventar → **começa em 0 na atualização**
  (Temporada 1 do Magnata), sem estimar por Money/Rebirth/personagens.
- **Player Auras × ranking:** com a proposta R10 o Lifetime fica ~2–3× maior para todos os perfis,
  mas **não** cria "quem compra primeiro fica inalcançável": a estratégia que compra a aura o mais
  cedo possível (A) termina ATRÁS de quem prioriza Rebirth (B) e da otimizada (D); a vantagem da
  aura é uma escolha de ritmo, não uma bola de neve (seção de resultados).

## 1. Definição

| | Money | LifetimeMoneyGenerated |
|---|---|---|
| O que é | dinheiro disponível para gastar | dinheiro legitimamente PRODUZIDO pela conta, desde a atualização |
| Gastar (Dice, níveis, fusão, upgrades, Player Aura) | diminui | **não muda** |
| Rebirth | zera | **não muda** |
| Venda / reembolso / troca | aumenta | **não muda** |
| Renda (coletor, offline), torre, missões, diário | aumenta | **aumenta o mesmo valor** |
| Save/load | salvo | salvo |
| Quem altera | só o servidor | só o servidor (dentro da porta única) |

Exemplo do pedido: o jogador gerou $850B; gasta $500B, compra uma aura e renasce com quase nada
— o Lifetime continua **≥ $850B** (`tests/MoneyLedger.spec.luau`, "gastar, comprar Dice, comprar
Player Aura e Rebirth não reduzem o Lifetime").

## 2. Todas as fontes de Money (auditoria do código atual)

Toda entrada de dinheiro do servidor passa por `EconomyService.AddMoney(player, valor, origem)`;
`PlayerDataService.Increment(..., "Money")` só é chamado ali dentro. Única exceção: o comando DEV
`Rebirth` (só Studio) põe o saldo direto para renascer — fica fora do ranking por definição.

| Origem (código) | Onde | O que é | Classe | Conta? | Por quê |
|---|---|---|---|---|---|
| `Collector` | EconomyService (coletor) | renda das estações acumulada no coletor | GENERATED | **sim** | é a produção da base |
| `Offline` | EconomyService (ClaimOfflineReward) | % da renda enquanto offline (teto = 25% do próximo Rebirth) | GENERATED | **sim** | é renda; o servidor calcula pelo relógio dele |
| `Tower` | TowerService | 1ª vitória de cada andar: `max(poder × 1, renda × 8)` | GENERATED | **sim** | jogo; cada andar paga uma vez na vida |
| `Mission` | MissionService | missões diárias (dinheiro ou "segundos de renda") | GENERATED | **sim** | jogo; uma vez por missão por dia |
| `Daily` | DailyService | recompensa diária | GENERATED | **sim** | jogo; uma vez por dia |
| `Sell` | SellService (venda/venda em massa) | valor-base do personagem + reembolso de 75% do investimento em níveis | RECYCLED + REFUND | não | converte item em dinheiro e devolve o que o jogador já pagou: contar abriria o loop "upar → vender" |
| `AutoSell` | RollService (venda automática) | valor-base do personagem recém-rolado | RECYCLED | não | conversão de item; venda + Jackpot somam ~0,1–3% de todo o dinheiro em 200 h na simulação |
| `Jackpot` | JackpotService (giro com gemas) | prêmio em dinheiro | OTHER | não | as gemas também são vendidas em Robux (Gems500): não dá para separar a origem |
| `Product` | JackpotService (MoneySmall/MoneyLarge, Robux) | pacote de dinheiro pago | OTHER | não | Robux não é produção; evita "comprar o 1º lugar" |
| `Dev` | DevService (Studio) | comando DEV | OTHER | não | ferramenta de teste |
| (trocas) | TradeService | só personagens; **nenhum dinheiro** | TRANSFER (reservado) | não | se um dia houver dinheiro em troca, é TRANSFER: não cria riqueza |
| (fusão) | FusionService | só CUSTO (TrySpend) | — | — | não gera dinheiro |
| (códigos, compensação admin) | — | **não existem hoje** | OTHER | não | se forem criados: OTHER, salvo decisão explícita |

Gasto (`TrySpend`: Dice, níveis, upgrades, fusão, Rebirth zerando) nunca mexe no Lifetime.

## 3. Arquitetura proposta (server-authoritative)

```
EconomyService.Grant(player, amount, source, opId?)      -- ÚNICA porta de entrada de Money
    MoneySourceConfig[source] -> GENERATED | TRANSFER | REFUND | RECYCLED | OTHER
    origem desconhecida  -> erro (falha fechada)
    amount: finito, >= 0, <= MaxGrant; opId repetido -> ignorado (idempotente)
    Money += amount
    se GENERATED: LifetimeMoneyGenerated += amount        -- no MESMO passo, sem yield
EconomyService.GrantSale(player, base, refund)           -- RECYCLED(base) + REFUND(refund), SaleCore.quote já separa
EconomyService.TrySpend(player, amount)                  -- só Money
```

- `AddMoney(player, valor, origem)` vira um apelido de `Grant` (as 10 chamadas atuais já passam a
  origem). O protótipo é exatamente isso (`MoneyLedger.grant/grantSale/spend/rebirth`).
- **O cliente nunca envia valor.** Nenhum remote recebe "gerei X": coletor (o servidor soma o
  coletor), offline (servidor calcula pelo `os.time`), missão/diário/torre (flags de resgate no save)
  e Robux (`ProcessReceipt` idempotente) já são assim. O `opId` cobre o que não tiver idempotência
  natural (ex.: `mission:<dia>:<id>`); histórico limitado a 200 ids no save.
- **Ranking:** novo quadro no `LeaderboardService` (mesmo esquema dos 3 atuais: OrderedDataStore
  `RollLegends_LB_Magnate_v1`, escrita a cada 120 s por jogador, leitura a cada 60 s, top local
  como reserva no Studio). OrderedDataStore só guarda inteiros: pontuação = **milhares de $**
  (`floor(Lifetime / 1000)`, teto 2⁵³ ≈ $9 sextilhões — precisão de $1K, invisível no "$12.4T").
- **Exibição:** `👑 MAGNATA` · `#1 Nome — $12.4T` com `NumberFormatter.money` (já usa K, M, B, T,
  Qa, Qi, Sx, Sp, Oc, No, Dc). O Hub tem 3 painéis (Rebirths, Torre, Rolls): o Magnata pede um 4º
  painel ou substituir um deles — **decisão de mapa/UX pendente**, por isso não foi feito.

## 4. Migração dos saves

Auditado `DataConfig.Template` (schema 4) e todos os serviços: **não existe** campo de dinheiro
acumulado (nem total ganho, nem estatística de conquistas em dinheiro; as conquistas usam Rolls,
Index, Rebirths e Torre). O que existe:

| Dado do save | Serve para reconstruir? |
|---|---|
| `Money` | não — o Rebirth zera; é saldo, não produção |
| `Rebirths` (+ custo 15M × 2,2ⁿ) | não — dá um piso do que foi GASTO em Rebirth, mas esse dinheiro pode ter vindo de venda, Jackpot ou Robux |
| `Inventory` (níveis), Dice comprados | não — é o que foi gasto, não de onde veio |
| `ProcessedReceipts` | não — guarda só ids de compra |
| `LastKnownIncomePerSecond` | não — renda atual × tempo de jogo desconhecido |

**Política recomendada:** schema 5 com `LifetimeMoneyGenerated = 0` para todos na atualização
(Temporada 1 do Magnata, todo mundo larga igual; jogadores antigos têm renda maior e sobem rápido
de forma legítima). Se quiserem reconhecer veteranos, que seja com um selo separado (ex.: "Fundador",
por `CreatedAt`), nunca com dinheiro estimado no ranking. `MoneyLedger.migrate` já faz isso (campo
ausente, negativo, NaN ou texto → 0; valor válido é preservado).


## Resultados das simulações

Simulador oficial (`tools/sim/EconomyModel.luau`) até 200 h ativas, com o Lifetime calculado pelo
protótipo `MoneyLedger` em cada entrada de dinheiro e a proposta de Player Auras R10 (1B / 25B /
250B / 2,5T / 10T × 1,5 / 1,75 / 2 / 2,25 / 2,5 — ainda não aprovada). Estratégias, todas no perfil
Ativo e com as mesmas sementes:

- **A — compra assim que consegue:** junta para a próxima aura sempre que ela custa até 5× o
  próximo Rebirth (adia o Rebirth para comprar logo);
- **B — prioriza Rebirth:** nunca adia o Rebirth; compra a aura só quando o saldo cobre dentro do ciclo;
- **C — acumula:** Rebirth tardio (só com 4× o custo em caixa); compra a aura quando o saldo cobre;
- **D — otimizada:** a cada decisão compara renda extra por $ da próxima aura × do próximo
  Rebirth (+25% e slot novo) e junta para o que render mais.

Reproduzir: `python3 tools/sim/run_magnate_audit.py` (~25 min em 4 núcleos).

<!-- GERADO:INICIO -->

_Gerado por `python3 tools/sim/run_magnate_audit.py` — 48 jogadores por cenário, 200 h ativas, MESMAS sementes; Lifetime = protótipo `tools/sim/MoneyLedger.luau` (só GENERATED)._

### LifetimeMoneyGenerated por perfil (P50) — jogo atual × proposta R10

| Perfil | Cenário | 20 h | 40 h | 80 h | 120 h | 200 h | % do produzido que conta (200 h) |
|---|---|---|---|---|---|---|---|
| Casual | atual | $126.25B | $430.05B | $1.30T | $2.27T | $4.39T | 99.8% |
| Casual | R10 | $264.85B | $1.05T | $3.29T | $5.82T | $12.26T | 99.9% |
| Ativo | atual | $132.16B | $520.86B | $1.77T | $3.63T | $8.12T | 97.1% |
| Ativo | R10 | $248.85B | $1.11T | $4.06T | $8.52T | $20.16T | 97.3% |
| Otimizador | atual | $107.65B | $404.58B | $1.38T | $2.80T | $6.40T | 98.2% |
| Otimizador | R10 | $182.97B | $729.07B | $2.68T | $5.30T | $13.40T | 97.9% |
| Pago | atual | $401.31B | $1.45T | $4.41T | $7.87T | $15.82T | 97.2% |
| Pago | R10 | $816.63B | $3.14T | $10.56T | $19.93T | $42.58T | 97.3% |

### Estratégias (Ativo, mesmas sementes) — Lifetime P50 (P10–P90)

| Estratégia | 20 h | 40 h | 80 h | 120 h | 200 h | Rebirths 200 h | Auras em 200 h |
|---|---|---|---|---|---|---|---|
| sem Player Aura (jogo atual) | $132.16B ($119.21B–$147.60B) | $520.86B ($490.96B–$591.98B) | $1.77T ($1.67T–$1.92T) | $3.63T ($3.45T–$3.83T) | $8.12T ($7.42T–$8.72T) | 17 | 0 |
| padrão do perfil (proposta) | $248.85B ($236.99B–$279.74B) | $1.11T ($1.01T–$1.20T) | $4.06T ($3.74T–$4.30T) | $8.52T ($7.87T–$9.10T) | $20.16T ($18.11T–$22.63T) | 17 | 4 |
| A · compra assim que consegue | $218.70B ($197.16B–$243.34B) | $1.01T ($936.17B–$1.17T) | $3.44T ($3.26T–$4.06T) | $7.31T ($6.72T–$8.34T) | $15.87T ($14.26T–$18.06T) | 15 | 5 |
| B · prioriza Rebirth | $257.23B ($233.79B–$293.79B) | $1.11T ($1.01T–$1.22T) | $4.05T ($3.80T–$4.45T) | $8.60T ($8.09T–$9.40T) | $20.96T ($18.98T–$22.98T) | 18 | 4 |
| C · acumula dinheiro | $239.81B ($205.09B–$282.18B) | $1.06T ($976.26B–$1.27T) | $4.01T ($3.73T–$4.66T) | $8.53T ($7.60T–$9.42T) | $19.83T ($16.65T–$22.22T) | 17 | 4 |
| D · otimizada | $259.10B ($243.33B–$287.91B) | $1.11T ($1.03T–$1.20T) | $4.06T ($3.83T–$4.33T) | $8.51T ($8.02T–$9.25T) | $20.54T ($18.57T–$22.77T) | 17 | 5 |

### Bola de neve? Razão entre estratégias (P50) e quem passa quem (mesma semente)

| Comparação | 20 h | 40 h | 80 h | 120 h | 200 h |
|---|---|---|---|---|---|
| com aura (padrão) ÷ sem aura | ×1.88 | ×2.13 | ×2.30 | ×2.35 | ×2.48 |
| A ÷ B | ×0.85 | ×0.91 | ×0.85 | ×0.85 | ×0.76 |
| C ÷ B | ×0.93 | ×0.96 | ×0.99 | ×0.99 | ×0.95 |
| D ÷ B | ×1.01 | ×1.00 | ×1.00 | ×0.99 | ×0.98 |
| A à frente de B (% das sementes) | 2% | 17% | 8% | 6% | 2% |
| D à frente de B (% das sementes) | 54% | 58% | 50% | 33% | 35% |
| C à frente de B (% das sementes) | 21% | 31% | 42% | 35% | 21% |

### Entre perfis: a aura alarga a distância? (Lifetime P50)

| Razão | Cenário | 20 h | 40 h | 80 h | 120 h | 200 h |
|---|---|---|---|---|---|---|
| Pago ÷ Casual | atual | ×3.18 | ×3.37 | ×3.40 | ×3.46 | ×3.60 |
| Pago ÷ Casual | R10 | ×3.08 | ×3.01 | ×3.21 | ×3.42 | ×3.47 |
| Otimizador ÷ Ativo | atual | ×0.81 | ×0.78 | ×0.78 | ×0.77 | ×0.79 |
| Otimizador ÷ Ativo | R10 | ×0.74 | ×0.66 | ×0.66 | ×0.62 | ×0.66 |
| Ativo ÷ Casual | atual | ×1.05 | ×1.21 | ×1.36 | ×1.59 | ×1.85 |
| Ativo ÷ Casual | R10 | ×0.94 | ×1.06 | ×1.23 | ×1.46 | ×1.64 |

<!-- GERADO:FIM -->

## Leitura: Player Auras × Ranking Magnata

1. **A aura vale muito no ranking — de propósito.** Com a proposta, o Lifetime fica ×1,9 (20 h)
   a ×2,5 (200 h) o de quem não compra. Quem ignora as auras não compete no topo: é a vantagem
   estratégica pedida.
2. **Não há "quem compra primeiro fica inalcançável".** No mesmo perfil (Ativo) e mesmas
   sementes, a estratégia **A** (compra a aura o mais cedo possível, adiando o Rebirth até 5× o
   custo) fica **9–24% ATRÁS** de **B** (prioriza Rebirth) em 20–200 h, e só passa B em 2–17% das
   sementes. Comprar cedo demais atrasa Rebirths (15 × 18 em 200 h) e os níveis das estações.
3. **D (otimizada: aura × Rebirth pelo que der mais renda por $) ≈ B** (×0,98–×1,01; à frente em
   33–58% das sementes) e **C (acumula, Rebirth tardio) ≈ ×0,93–0,99**. As estratégias razoáveis
   terminam a menos de 5% umas das outras: a ordem entre bons jogadores continua decidida por
   tempo de jogo e decisões, não por quem clicou primeiro.
4. **A razão entre estratégias NÃO cresce com o tempo** (A ÷ B ×0,85 → ×0,76; D ÷ B ≈ 1): não é
   bola de neve. Cada aura é um multiplicador FIXO (o da maior comprada, sem empilhar) e a curva de
   Rebirth aprovada continua sendo o motor; o efeito composto existe, mas é limitado.
5. **Entre perfis a aura não alarga a distância**: Pago ÷ Casual ×3,6 → ×3,5 em 200 h com a
   proposta; Ativo ÷ Casual ×1,85 → ×1,64. Ela alarga Otimizador × Ativo (×0,79 → ×0,66) porque o
   perfil Otimizador simulado adia o Rebirth até 3× o custo para juntar — a decisão importa.
6. **Absoluta 10T:** na prática só o Pago a compra em 200 h (ver `PLAYER_AURA_ECONOMY_AUDIT.md`
   §10); no Magnata isso daria ao topo pago um ×2,25 → ×2,5 extra que o F2P quase nunca vê. A
   recomendação de **5T** deixa o último degrau acessível ao F2P dedicado.


## Riscos de exploit (e o teste que cobre cada um)

| Risco | Defesa | Teste |
|---|---|---|
| Rebirth reduzir o Lifetime | Rebirth só zera Money | `MoneyLedger.spec` "gastar, … Rebirth não reduzem" + simulador (Lifetime monotônico com Rebirths) |
| Gastar / Dice / Player Aura reduzir | `spend` só mexe em Money | `MoneyLedger.spec` |
| Save/load perder o valor | campo no save; migração preserva valor válido | `MoneyLedger.spec` "save/load" |
| Troca duplicar ranking | troca é TRANSFER (e hoje nem move dinheiro) | `MoneyLedger.spec` "troca não duplica" (ida e volta 50×) |
| Loop comprar → upar → vender | venda = RECYCLED, investimento = REFUND | `MoneyLedger.spec` (100 ciclos, Lifetime igual) |
| Fusão criar ranking | fusão só custa | `MoneyLedger.spec` |
| Replay de remote / grant duplicado | remotes não enviam valor; flags de resgate; `opId` idempotente | `MoneyLedger.spec` "mesmo opId só credita uma vez" |
| Valores negativos, NaN, ∞, texto | recusados sem efeito | `MoneyLedger.spec` |
| Overflow / valores enormes | teto por entrada (1e18), total satura (1e24), pontuação inteira ≤ 2⁵³ | `MoneyLedger.spec` "overflow" |
| Cliente forjando geração | nenhuma API do cliente; origem desconhecida → recusada | `MoneyLedger.spec` "cliente forjando" |
| Fonte nova esquecida | toda chamada `AddMoney(..., "Origem")` precisa estar classificada | `tests/money_sources_test.py` (lê o código do servidor) |
| Robux comprando posição | pacotes de dinheiro e Jackpot não contam | classificação OTHER |
| Gamepass VIP (×1,5 renda) | **conta** (é renda) — vantagem paga legítima, igual à renda | decisão de produto: documentar na loja |
| Contas alternativas / farm | fora do escopo do ledger (é o mesmo problema dos rankings atuais) | — |

## Recomendação final

1. **Definição aprovável:** LifetimeMoneyGenerated = soma das origens GENERATED (coletor,
   offline, torre, missões, diário). Venda, reembolso, trocas, Jackpot, Robux e DEV não contam.
2. **Implementação (quando autorizada):** porta única `EconomyService.Grant` com origem
   obrigatória e registrada em config (falha fechada), Lifetime somado no mesmo passo; venda via
   `GrantSale` (base RECYCLED + investimento REFUND); `opId` só onde não houver idempotência
   natural; schema 5 + migração para 0; quadro `👑 MAGNATA` no `LeaderboardService` com
   pontuação em milhares de $; levar o protótipo e os testes (`tests/MoneyLedger.spec.luau`,
   `tests/money_sources_test.py`) para o código real.
3. **Migração:** começar em 0 (Temporada 1). Não há dado confiável para reconstruir o histórico.
4. **Player Auras:** compatíveis com o Magnata — vantagem forte, mas sem bola de neve e sem
   recompensar "comprar primeiro". Recomendo Absoluta **5T** em vez de 10T.
5. **Decisões pendentes de vocês:** (a) preços finais das auras; (b) onde o painel MAGNATA entra
   no Hub (4º painel ou substituir um dos 3); (c) se o VIP (×1,5 renda, pago) deve ou não contar —
   hoje conta, como toda renda; (d) selo de "Fundador" para veteranos, se desejado.


