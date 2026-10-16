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

## PLAYER AURA ART PASS V2 + MAGNATA POLISH + MOBILE AURAS

Regra desta etapa: identidade vale mais que quantidade. Preços, multiplicadores, WalkSpeed, Lifetime, MoneySourceConfig, Fusion/FuseMax, RNG, AFK, Recent Rolls, Hero Landing e Character Aura **não mudaram**.

### Composição por tier (`PlayerAuraConfig.Visual`)

| Tier | Pés | Tronco | Ombros / cabeça | Assinatura |
|---|---|---|---|---|
| Desperta | anel simples (2 arcos), pulso suave a cada 3,2 s | energia leve + ascendentes junto ao corpo | — | primeira transformação, ciano |
| Imperial | anel dourado, pulso, rastro | 2 orbitadores grandes, chamas DOURADAS subindo pelas laterais | — | chamas laterais |
| Divina | anel redondo (4 arcos), pulso a cada 2,4 s | 3 orbitadores, ascendentes, laterais, 2 fluxos | os fluxos sobem até acima dos ombros | corpo inteiro envolvido |
| Celestial | anel, pulso a cada 2,1 s | coluna de luz que respira, estrelas subindo, 2 fluxos largos | **auréola celestial** girando + faíscas | salto visual: auréola + coluna |
| Absoluta | 1 anel forte e largo (0,55), pulso a cada 1,6 s | energia vertical carmesim, coluna, 3 orbitadores | **3 grandes fluxos nos ombros** + **coroa dourada** (auréola + 4 pontas) + faíscas | coroa = reconhecível sem ler o nome |

### Como os círculos foram barateados

- **Antes:** um círculo era um polígono de 12 beams + 12 attachments.
- **Agora:** é um conjunto de **arcos Bézier**: o eixo do attachment fica na tangente e o `CurveSize` vale k·r. Com 2 arcos o círculo inteiro usa 2 beams e 2 attachments; com 4 arcos, 4 e 4.
- **Precisão:** o teste confere que o meio de cada arco cai exatamente no raio, ou seja, o círculo é redondo e não um polígono.

### Movimento (todo beam se move)

- **Fluxos:** as pontas andam ~1,3 studs e a curva varia ~4,8 em 1,5 s, cada fluxo com fase própria. A textura de fogo também corre ao longo deles.
- **Auréola e coroa:** giram.
- **Anel e coluna:** a textura corre, e a coluna respira na largura.
- **Teste:** o ClientHarness reprova qualquer beam parado.

### Custo (medido no ClientHarness)

| | Antes (7e2c50b) | Agora |
|---|---|---|
| Absoluta: beams | 44 | **14** (−68%) |
| Absoluta: attachments | 57 | **26** (−54%) |
| Absoluta: partículas/s | 104 | **64** (~55 vivas) |
| 10 Absolutas perto | 1040/s · 440 beams · 570 att. | **640/s · 550 vivas · 140 beams · 260 att. · 240 escritas por quadro** |
| 10 a 40 studs | — | cheias (igual à linha acima) |
| 10 a 60 / 90 studs | 468/s | reduzidas: 288/s, 247 vivas, 30 escritas por quadro (metade da frequência) |
| 10 a 110 studs | — | desligadas: 0 partículas, 0 beams, 0 escritas |
| 10 perto no mobile | — | 320/s (×0,5) |

Em todos os casos: **1 conexão**, **0 Highlights**, 1 PointLight por aura.

### Escala por tier (1 aura perto)

| Tier | Partículas/s | Beams | Attachments | Elementos acima do tronco |
|---|---|---|---|---|
| Desperta | 18 | 2 | 3 | 0 |
| Imperial | 33 | 2 | 9 | 0 |
| Divina | 43 | 6 | 16 | 2 |
| Celestial | 55 | 9 | 20 | 6 |
| Absoluta | 64 | 14 | 26 | 11 |

### DEV

- **`PlayerAuraLineup`:**
  - 13 studs entre os bonecos (antes 7);
  - rótulo pequeno em studs (7 de largura) acima da coroa, só com o nome: DESPERTA … ABSOLUTA;
  - sem o "Player Aura" repetido; nenhum rótulo se sobrepõe.
- **`PlayerAuraStress`:**
  - formação 5 + 5, com 10 studs entre colunas e 11 entre fileiras;
  - a fileira de trás fica deslocada meio passo, para ninguém ficar escondido;
  - rótulos curtos: "Absoluta #n".

### Magnata (polish, sem redesenho)

- **Linhas:** as 10 têm a mesma altura (0,073), com espaçamento fino constante. O texto ficou com 23 px no painel.
- **Painel:** passou de 13 para 15 studs de altura.
- **Título:** "👑 MAGNATA / TEMPORADA 1" agora ocupa duas linhas e se ajusta à largura, sem "…".
- **Colunas:** a do valor ficou mais larga (0,33) e alinhada à direita, então "$12.4T" não é cortado. Nome longo trunca com "…".
- **Preservado:** moldura dourada, coroa, posição, elevação e Top 10. Os 3 painéis originais não mudaram.

### Mobile: botão AURAS

- **Retrato:** a coluna da direita some, então o atalho ✨ AURAS aparece na **coluna da esquerda** como 5º botão. O botão tem o atributo `PortraitOnly` e o `HudController.Layout` aumenta a altura da coluna para caber.
- **Paisagem e PC:** o botão da esquerda fica escondido e só o da direita aparece, sem duplicata.
- **Sem sobreposição:** testado em retrato estreito (360×740) e médio (390×844). A coluna termina antes dos controles de baixo (ROLAR, MOCHILA, MELHORIAS, AUTO, OCULTAR).
- **Loja no celular:** abre dentro da tela, rola as 5 auras, compra, equipa e mostra preço, renda, velocidade e 👑 Gerado em retrato e paisagem.
