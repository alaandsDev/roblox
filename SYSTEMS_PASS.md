# Systems pass: FUNDIR MÁX. + Player Auras + LifetimeMoneyGenerated + Ranking Magnata

Esta etapa implementa quatro sistemas que já tinham sido auditados ou definidos antes. As bases econômicas são `PLAYER_AURA_ECONOMY_AUDIT.md` e `MAGNATE_RANKING_AUDIT.md`.

**Não foi alterado:** RNG/Dice/pesos/pity/Luck, DiceIncome, preços dos Dice, fórmula do Rebirth, Character Aura/Aura Motion, Hero Landing, Torre, AFK Resilience, Recent Rolls, World Art Pass, Sky e catálogo.

**Nada foi publicado.**

## A) FUNDIR MÁX.

### Arquitetura

- **Cálculo, sem efeitos colaterais:** `FusionCore.fuseMaxPlan(data, characterId, configs, investedOf, budget)` monta o plano inteiro e não mexe em `data`.
- **Aplicação:** `FusionService.FuseMax(player, characterId, confirmar, fusõesDaPrévia)`.
  - `confirmar = false` devolve só a prévia.
  - `confirmar = true` aplica o plano.
- **O que o cliente envia:** só o personagem (`FuseMax` em `Definitions`).
- **O que o servidor faz:** lê o inventário, planeja, valida, desconta o custo total, consome e cria tudo sem yield, envia **um** `InventoryDelta` e agenda `SaveSoon`.

### Regras da cadeia

- **Seleção:** só a família pedida, ou seja, o mesmo `CharacterId`. Mesma raridade não basta. A compatibilidade é a do Fuse normal: mesmo Id e mesma variante, unidades livres.
- **Ordem canônica:** variante mais baixa primeiro, uids em ordem numérica (`FusionCore.uidLess`), unidades novas no fim da fila.
- **Variantes:** a escada vem de `VariantConfig` (Normal → Prata → Ouro → Diamante → Esmeralda → Vazio → Celestial). As quantidades vêm de `FusionConfig.RequiredByTarget`. A cadeia para na variante máxima real.
- **Variantes já existentes:** unidades livres de **todas** as variantes da família entram na cadeia. Exemplo: 300 Normal + 2 Prata dão 102 Prata, que viram 34 Ouro, e assim por diante.
- **Protegidas, nunca consumidas:** equipado, travado, favorito e em troca (`InventoryCore.protection`, a mesma regra do Fuse).

### Economia e segurança

- **Investimento:** igual ao Fuse.
  - Nível = maior entre as consumidas.
  - `UpgradeInvestment` = soma do investimento das consumidas.
  - Custo de cada fusão = BaseIncome × 600 × ordem da variante de destino.
  - Nenhum investimento é criado nem destruído.
- **Dinheiro limitado:** a cadeia para na primeira fusão que não cabe no saldo, como aconteceria clicando FUNDIR 1× repetidamente.
- **Atomicidade:** o plano completo é calculado antes de tudo. A aplicação não tem yield. Uma operação de fusão por jogador por vez (`busy`).
- **Spam e replay:**
  - Um replay recalcula o plano a partir do inventário atual: não há nada a fundir, ou a prévia mudou (`fusion_changed`).
  - Dois cliques simultâneos resultam em uma única aplicação.

### Desempenho

| Unidades | Fusões | Só o plano | Servidor (plano + aplicação) |
|---|---|---|---|
| 300 | 152 | 1,2 ms | 4,2 ms |
| 1.000 | 512 | 5,1 ms | 15,7 ms |
| 5.000 | 2.567 | 38,9 ms | 89,7 ms |

### Equivalência com FUNDIR 1× repetido

Comparamos FUNDIR MÁX. com o FUNDIR 1× repetido nas mesmas condições. Os dois caminhos resultam idênticos em uid, Id, variante, nível, investimento, NextUid e dinheiro.

- **Testes puros:** 3, 9, 27, 30 e 300 unidades, mais 40 inventários aleatórios mistos (variantes existentes, protegidos, outra família, dinheiro limitado).
- **Serviço real:** `Fuse` × `FuseMax` em `SystemsHarness`.

### UI

- **Botões:** cada linha tem [✨ FUNDIR 1×] e [⚡ FUNDIR MÁX.].
- **Prévia:** mostra fusões, maior resultado, o que sobra e o custo, sem ViewportFrame.
- **Resultado:** uma animação e um texto: "⚡ N FUSÕES REALIZADAS! CRIADO: 1× Celestial · …".

## B) PLAYER AURAS (avatar; não é a Character Aura)

### Arquitetura

| Peça | Papel |
|---|---|
| `PlayerAuraConfig` | escada |
| `Formulas:playerAuraTier/playerAuraMultiplier/walkSpeed` | regras |
| `PlayerAuraService` | `BuyPlayerAura(tier)` / `EquipPlayerAura(tier)` |
| `BaseService.WalkSpeedFor/ApplyWalkSpeed` | velocidade |
| `PlayerAuraBuilder` + `PlayerAuraController` | visual no cliente |
| `PlayerAuraShopController` | janela |
| `PlayerAura = { Owned, Equipped }` | save, schema v5 |

### Escada final

| Aura | Preço | Renda | WalkSpeed |
|---|---|---|---|
| Desperta | $1B | ×1,50 | 28 |
| Imperial | $25B | ×1,75 | 30 |
| Divina | $250B | ×2,00 | 32 |
| Celestial | $2,5T | ×2,25 | 34 |
| **Absoluta** | **$5T** | ×2,50 | 36 |

### Regras

- **Compra sequencial:** tier N exige N−1. Cada etapa cobra só o seu preço. Permanente: Rebirth, morte e reconexão não removem.
- **Bônus × visual equipado:** renda e velocidade vêm sempre do **maior tier comprado**. O visual equipado (0..Owned) é só cosmético.
- **Onde o multiplicador entra:** só em `Formulas:incomeMultiplier`, o fator único. Por isso afeta a renda da base, o offline (o teto de 25% do próximo Rebirth não muda) e as recompensas em "segundos de renda" (Torre, Missão, Diário, Jackpot).
- **Onde não entra:** venda, refund, troca, fusão, custos e preço do Rebirth.
- **Servidor decide tudo:**
  - O remote recebe só o tier.
  - Preço e ordem vêm da config.
  - Débito e gravação acontecem no mesmo passo, sem yield.
  - Replay recebe `aura_owned`. Duas compras simultâneas resultam em uma só.
  - `SaveNow` logo após a compra.
- **Replicação:** atributos `PlayerAuraTier` e `PlayerAuraVisual` no Player. Cada cliente desenha localmente as auras de todos.
- **Respawn:** o `BaseService` reaplica o WalkSpeed a cada spawn. O controlador remonta o visual, e `PlayerAuraBuilder.clear` evita duplicar.

### Visual: identidade própria (sem Auras Pack, sem Highlight, texturas nativas)

| Aura | Elementos |
|---|---|
| Desperta | energia corporal + brilho no chão + luz suave (20/s) |
| Imperial | + 2 órbitas + rastro nos pés (30/s) |
| Divina | + 3 órbitas + anel no chão + pulsos + 2 fitas (45/s) |
| Celestial | + 4 órbitas + 3 fitas + partículas ascendentes + coluna de luz (60/s) |
| **Absoluta** | 6 órbitas, 4 fitas, anel DUPLO no chão, pulsos rápidos, coluna, ascendentes e **auréola/coroa** exclusiva acima da cabeça, sem cobrir o rosto |

### LOD, mobile e loop central

- **Auras de outros jogadores:**
  - cheia até 40 studs;
  - reduzida a ×0,45 até 90 studs;
  - desligada além disso.
- **Aura do dono:** sempre cheia.
- **Mobile:** emissão ×0,5.
- **Custo de execução:** uma conexão (Heartbeat a 30 Hz) para todas as auras, mais uma varredura a cada 0,5 s.

### Stress medido (ClientHarness)

| Cenário | Emissores | Partículas/s | Beams | Trails | Attachments | Luzes | Highlights | Conexões |
|---|---|---|---|---|---|---|---|---|
| 1 Absoluta perto | 9 | 104 | 44 | 1 | 57 | 1 | 0 | 1 |
| 5 Absolutas perto | 45 | 520 | 220 | 5 | 285 | 5 | 0 | 1 |
| 10 Absolutas perto | 90 | 1040 | 440 | 10 | 570 | 10 | 0 | 1 |
| 10 Absolutas a 60 studs | — | 468 | — | — | — | — | — | 1 |
| 10 Absolutas a 200 studs | — | 0 | 0 | — | — | — | — | 1 |

A aprovação visual é no Studio: `PlayerAuraLineup`, `PlayerAuraStress`.

## C) LifetimeMoneyGenerated

### Schema e migração

- **Schema v5:** `LifetimeMoneyGenerated = 0`, `MagnateSeason = 1`, `LedgerOps = {}` (privado) e `PlayerAura`.
- **Temporada 1:** o save antigo começa em **0**. O valor nunca é estimado a partir de Money, Rebirth ou inventário.
- **Robustez da migração:** um valor válido existente é mantido. NaN, infinito, negativo ou texto viram 0.

### Porta única

`EconomyService.AddMoney(player, valor, origem, opId?)`:

1. Valida a origem em `MoneySourceConfig`. Origem desconhecida gera erro (falha fechada).
2. Valida o valor: finito, ≥ 0, ≤ 1e18.
3. Se houver `opId` repetido, a operação não credita nada.
4. Soma em Money.
5. Se a origem for GENERATED, soma também no Lifetime, no mesmo passo e sem yield (teto 1e24).

O teste `money_sources_test.py` confere toda chamada de `AddMoney` no servidor contra `MoneySourceConfig` e contra o protótipo da auditoria.

### Classificação das origens

| Classe | Origens | Conta no Lifetime? |
|---|---|---|
| GENERATED | Collector, Offline, Tower, Mission, Daily | sim |
| RECYCLED | Sell, AutoSell | não |
| REFUND | Refund | não |
| TRANSFER | Trade | não |
| OTHER | Jackpot, Product (Robux direto), Admin, Dev | não |

- **VIP e Player Aura:** multiplicam a produção. O valor **final** coletado conta **uma vez**. O teste confirma: Collector com VIP ×1,5 e Absoluta ×2,5 dá Lifetime += exatamente o coletado.
- **Offline:** conta. O valor já inclui a aura, porque `LastKnownIncomePerSecond` é calculado por `incomeMultiplier`.
- **Nunca diminui:** gasto, Dice, Player Aura, Rebirth e Fusão não tiram nada do Lifetime.

### Exploits testados, nenhum fabrica Lifetime

- melhorar → vender → refund;
- fusão;
- troca;
- replay ou opId repetido;
- NaN, infinito, negativo, overflow;
- origem desconhecida;
- remote com valor (não existe nenhum).

## D) RANKING MAGNATA (Temporada 1)

- **Arquitetura:** um 4º quadro no `LeaderboardService` (`Boards[4]`, stat "Magnate").
  - OrderedDataStore `RollLegends_LB_Magnate_S1`.
  - Pontuação = `floor(Lifetime / 1000)`, com teto 2^53.
  - A tela mostra o valor em $ via `NumberFormatter.money` (K, M, B, T…), o mesmo formatter do jogo.
- **Painel no Hub:** `Panel4` na ponta do mesmo arco côncavo dos 3 rankings, que continuam iguais.
  - Moldura dourada neon e coroa.
  - Título "👑 MAGNATA · TEMPORADA 1", **top 10** (os outros três continuam top 5).
  - O painel é elevado (base a 5,4 studs, pilares sem colisão) para não bloquear o caminho ao lado, confirmado pelo `MapHarness`.
- **Frequência de gravação:** igual à dos rankings atuais.
  - Escrita no máximo a cada 120 s por jogador, mais uma na saída.
  - Leitura a cada 60 s.
  - Agora todos os quadros só gravam quando o valor **mudou** (dirty). Nenhuma escrita por $ ganho.
- **Temporadas:** `MagnateConfig` (Season / Store / Top). Uma temporada futura troca o `Store` e zera o contador da temporada. Nesta etapa, `LifetimeMoneyGenerated` é o valor da Temporada 1.
- **Após Rebirth ou gasto:** o ranking não cai. O teste confirma que A (saldo $1B, Lifetime $20T) fica acima de B (saldo $5T, Lifetime $10T).
- **"👑 Gerado: $X":** aparece no topo da janela PLAYER AURAS, sem poluir o HUD.

## Comandos DEV (Studio)

| Comando | Para que serve |
|---|---|
| `PlayerAuraStatus` | estado da Player Aura do jogador |
| `SetPlayerAura(tier)` | define a maior aura comprada, sem dinheiro |
| `PlayerAuraPreview(nome)` | mostra só o visual no próprio avatar |
| `PlayerAuraLineup` | as 5 auras lado a lado |
| `PlayerAuraStress(n, tier)` | N bonecos com a mesma aura juntos |
| `PlayerAuraClear` | remove os bonecos |
| `MagnateStatus` | Lifetime, Money, temporada, pontuação e posição |
| `MagnateBoardPreview` | preenche o painel com 10 linhas de exemplo |
| `MagnateSimulateIncome(segundos)` | credita N segundos de renda como coleta legítima |
| `FuseMaxPreview(id?)` | prévia do FUNDIR MÁX. sem mudar nada |

O roteiro manual está em `STUDIO_SMOKE_TEST.md` (PA1–PA6, MG1–MG5, FM1–FM5).
