# STUDIO SMOKE TEST — Roll Legends (roteiro curto, ~40 min)

Objetivo: em **32 testes** confirmar que o jogo inteiro funciona no Studio antes de gastar
tempo com os 108 testes completos do `TEST_PLAN.md`. Se algum falhar, anote o número, o que
apareceu no **Output** e pare.

## Preparação (uma vez)

1. `python tools\build_place.py` e abra `build\RollLegends.rbxlx` no Studio (**não publique**).
2. Aperte **Play (F5)**. Na aba **TEST**, mude para **Current: Server** (a Barra de comandos
   precisa rodar no SERVIDOR).
3. Os comandos de teste ficam numa interface criada pelo próprio jogo no servidor:
   **`game.ServerStorage.RollLegendsDev`** (BindableFunction, só existe no Studio). Confirme que
   o Output mostrou `comandos de teste prontos` e teste:

```lua
game.ServerStorage.RollLegendsDev:Invoke("Help")
```

   O resultado de cada comando aparece no Output como `[RollLegendsDev] Comando -> ...`.
   Comandos que mexem num jogador recebem o jogador primeiro:
   `game.ServerStorage.RollLegendsDev:Invoke("Roll", game.Players:GetPlayers()[1], 50)`.
   Os comandos dos pilotos (CharacterGallery, ShowCharacterVariants, ...) não precisam dele.
   Volte para **Current: Client** para jogar/clicar e para **Server** para colar comandos.

> Nunca use `require(...)` na Barra de comandos (ela roda em outra máquina Luau).

---

## BOOT

| # | Ação | Esperado | OK |
|---|---|---|---|
| 1 | Play (F5) e olhe o Output | Sem erro vermelho. Aparece "comandos de teste prontos" e "mapa validado: OK" | [ ] |
| 2 | Olhe a tela ao nascer | Você nasce **na sua base**; HUD com ROLAR, MOCHILA, MELHORIAS, dinheiro e Sorte | [ ] |
| 3 | Banner do tutorial no topo | Mostra **PASSO 1/7 — Toque em ROLAR** e o botão PULAR; botões da esquerda/direita escondidos | [ ] |

## BASE

| # | Ação | Esperado | OK |
|---|---|---|---|
| 4 | `game.ServerStorage.RollLegendsDev:Invoke("GetPlayerBase", game.Players:GetPlayers()[1])` | Mostra a base, BaseId e OwnerUserId = seu UserId | [ ] |
| 5 | Ande pela base | 4 pedestais liberados (1–4) e 4 bloqueados (5–8) com cadeado/aviso | [ ] |

## ROLL + TUTORIAL

| # | Ação | Esperado | OK |
|---|---|---|---|
| 6 | Clique **ROLAR** | Dado gira, reveal mostra o personagem; banner passa para **PASSO 2/7 (MOCHILA)** | [ ] |
| 7 | Abra a **MOCHILA** | Personagem aparece no inventário; banner vai para **PASSO 3/7 (EQUIPAR)** | [ ] |
| 8 | Selecione e clique **EQUIPAR** | Personagem aparece num pedestal com nome/raridade/$/s; banner avança (4/7, ou direto 5/7 se você já está na base); botões laterais voltam | [ ] |
| 9 | Se aparecer **🏠 IR**, clique; depois pise no **coletor 💰** | Teleporta para a base; dinheiro sobe com moedas voando; banner vai para **6/7** | [ ] |
| 10 | Pise no pad verde da estação (ou compre uma MELHORIA) e depois **OK!** | Nível sobe; banner mostra o próximo objetivo; OK fecha o tutorial | [ ] |
| 11 | `game.ServerStorage.RollLegendsDev:Invoke("Roll", game.Players:GetPlayers()[1], 200)` e depois `game.ServerStorage.RollLegendsDev:Invoke("GetLuck", game.Players:GetPlayers()[1])` | Resumo dos 200 rolls sem erro (quase só Comum–Épico + alguns Lendários: pity a cada 50); mostra Luck e Luck efetiva entre 1 e 2 | [ ] |

## RARE CINEMATIC

| # | Ação | Esperado | OK |
|---|---|---|---|
| 12 | `game.ServerStorage.RollLegendsDev:Invoke("PlayReveal", game.Players:GetPlayers()[1], "Legendary")` | Cinemática Lendária: palco, personagem, "1 EM X", CONTINUAR fecha e limpa tudo | [ ] |
| 13 | `game.ServerStorage.RollLegendsDev:Invoke("PlayReveal", game.Players:GetPlayers()[1], "Secret")` | Cinemática Secreta (a mais forte), câmera volta ao normal depois | [ ] |

## INVENTORY / EQUIP / INCOME / CHARACTER UPGRADE

| # | Ação | Esperado | OK |
|---|---|---|---|
| 14 | `game.ServerStorage.RollLegendsDev:Invoke("FillInventory", game.Players:GetPlayers()[1])` e clique ROLAR | Aviso "Inventário cheio" com botões VENDER/MOCHILA (sem empilhar mensagens) | [ ] |
| 15 | VENDER → **VENDER DUPLICATAS** → confirmar | Prévia com valor; ao confirmar o dinheiro sobe e os favoritos/equipados ficam | [ ] |
| 16 | MOCHILA → **EQUIPAR MELHORES** | Os 4 pedestais preenchidos com os melhores; `game.ServerStorage.RollLegendsDev:Invoke("Income", game.Players:GetPlayers()[1])` mostra renda/s > 0 | [ ] |
| 17 | `game.ServerStorage.RollLegendsDev:Invoke("GiveMoney", game.Players:GetPlayers()[1], 1e6)` e segure em cima do pad de uma estação | Sobe vários níveis seguidos; billboard e placa atualizam | [ ] |

## REBIRTH / NEW FLOOR

| # | Ação | Esperado | OK |
|---|---|---|---|
| 18 | `game.ServerStorage.RollLegendsDev:Invoke("Rebirth", game.Players:GetPlayers()[1])` | +1 renascimento; dinheiro e melhorias de Sorte/Renda/Velocidade zeram; **Mochila e personagens ficam**; slot 5 liberado | [ ] |
| 19 | `game.ServerStorage.RollLegendsDev:Invoke("Rebirth", game.Players:GetPlayers()[1])` mais 4 vezes | Com 5 renascimentos aparece o **2º andar** com o Slot09 liberado; dá para equipar nele | [ ] |

## TOWER

| # | Ação | Esperado | OK |
|---|---|---|---|
| 20 | Abra TORRES → **Torre das Brasas** e lute | Batalha animada; vitória dá dinheiro só na 1ª vez do andar; Torre do Vazio aparece bloqueada | [ ] |

## FUSION

| # | Ação | Esperado | OK |
|---|---|---|---|
| 21 | `game.ServerStorage.RollLegendsDev:Invoke("GiveCharacter", game.Players:GetPlayers()[1], "flame_rookie", 3)` e abra FUSÃO | Grupo pronto com botão FUNDIR; fundir cobra dinheiro e gera 1 **Prata** com o maior nível | [ ] |

## TRADE (2 PLAYERS)

| # | Ação | Esperado | OK |
|---|---|---|---|
| 22 | TEST → **Clients and Servers** com **2 jogadores** | Cada um nasce na **própria** base (bases diferentes) | [ ] |
| 23 | Jogador 1 convida o 2; os dois oferecem 1 personagem | As duas ofertas aparecem nas duas telas | [ ] |
| 24 | Jogador 1 tenta VENDER o item oferecido | Recusado: "Personagem está numa troca aberta" | [ ] |
| 25 | PRONTO nos dois → um muda a oferta → CONFIRMAR | PRONTO zera; só depois de PRONTO+CONFIRMAR dos dois a troca acontece | [ ] |

## DAILY / OFFLINE

| # | Ação | Esperado | OK |
|---|---|---|---|
| 26 | `game.ServerStorage.RollLegendsDev:Invoke("SetDaily", game.Players:GetPlayers()[1], 1, 0)` e abra o DIÁRIO | Dia 1 disponível; resgatar entrega e o botão some (não dá para resgatar 2×) | [ ] |
| 27 | `game.ServerStorage.RollLegendsDev:Invoke("SimulateOffline", game.Players:GetPlayers()[1], 3600)` | Janela OFFLINE abre **sozinha** (fila: nunca por cima de reveal/outra janela); resgatar soma o dinheiro | [ ] |

## SHOP / JACKPOT

| # | Ação | Esperado | OK |
|---|---|---|---|
| 28 | Abra a LOJA | Passes e produtos aparecem; comprar mostra "ainda não está à venda" (IDs = 0); chances do Jackpot listadas | [ ] |
| 29 | `game.ServerStorage.RollLegendsDev:Invoke("GiveGems", game.Players:GetPlayers()[1], 500)` e clique **GIRO DO JACKPOT** | Gasta 150 gemas; rolo gira e mostra o prêmio | [ ] |

## SAVE / LOAD

| # | Ação | Esperado | OK |
|---|---|---|---|
| 30 | Anote dinheiro/renascimentos, pare (Stop) e dê Play de novo | Com "Enable Studio Access to API Services" ligado: tudo volta igual. Sem ele: aviso "perfil temporário" (normal no Studio) | [ ] |

## MOBILE

| # | Ação | Esperado | OK |
|---|---|---|---|
| 31 | Device Emulator (aba TEST) → iPhone deitado e depois em pé | Deitado: HUD inteiro sem sobrepor. Em pé: dinheiro/sorte no topo, coluna da direita e histórico somem, botões tocáveis | [ ] |

## PERFORMANCE

| # | Ação | Esperado | OK |
|---|---|---|---|
| 32 | `game.ServerStorage.RollLegendsDev:Invoke("PopulateDemoBase", game.Players:GetPlayers()[1], true)` e abra **View → Script Performance / MicroProfiler** (Ctrl+F6) | Base demo com 8 estações; FPS estável; nenhum script do jogo acima de ~3% de atividade parado | [ ] |

## MAPA BLOCKY (extra, não conta nos 32)

| # | Ação | Esperado | OK |
|---|---|---|---|
| M1 | `game.ServerStorage.RollLegendsDev:Invoke("VisualCheck", game.Players:GetPlayers()[1], "Hub")` | Altar do Hub imponente na câmera normal, dado grande girando, nada tapando metade da tela | [ ] |
| M2 | `game.ServerStorage.RollLegendsDev:Invoke("VisualCheck", game.Players:GetPlayers()[1], "Base")` | Base com fundação, pilastras, arco com lanternas e placa emoldurada; pedestais quadrados; entrada aberta | [ ] |
| M3 | `game.ServerStorage.RollLegendsDev:Invoke("VisualCheck", game.Players:GetPlayers()[1], "Conveyor")` | Esteira no chão, setas, faixa de pedestre nos cruzamentos, atravessa a pé | [ ] |
| M4 | `VisualCheck` com DiceShop, Market, Sell, Fusion, Towers, Missions, Trades, Rankings | Cada landmark distinto e legível; prompts funcionando; caminho principal passa por baixo do portal da Dice Shop | [ ] |
| M5 | Andar do Hub até a base e até a borda da ilha | Nenhuma árvore/pedra prende o personagem nos caminhos; borda com recortes de areia e palmeiras | [ ] |

## PILOTOS DO PIPELINE DE PERSONAGENS (extra, não conta nos 32)

Antes: `python tools/build_characters.py` (gera `assets/Characters.rbxm`) e `python tools/build_place.py`.
Abra o place gerado (SEM o Anime Pack no Workspace).

| # | Ação | Esperado | OK |
|---|---|---|---|
| P1 | `game.ServerStorage.RollLegendsDev:Invoke("CharacterAssetReport")` | `ReplicatedStorage.CharacterAssets: 10 assets` e os 10 pilotos OK/AVISO | [ ] |
| P2 | `game.ServerStorage.RollLegendsDev:Invoke("SourcePackCheck")` | `10/10 montados sem o pack · 10 do asset sanitizado · problemas: nenhum` | [ ] |
| P3 | `game.ServerStorage.RollLegendsDev:Invoke("CharacterGallery")` | 10 pilotos lado a lado, mesma escala de corpo (maiores por raridade), etiqueta "asset" | [ ] |
| P4 | `game.ServerStorage.RollLegendsDev:Invoke("ShowCharacterVariants", "char_ichiro_base")` | 7 variantes; rosto/roupa iguais; anel e acentos mudam | [ ] |
| P5 | `game.ServerStorage.RollLegendsDev:Invoke("GivePilots")` e equipar pela MOCHILA | Piloto em pé no pedestal, nome/raridade/renda/nível certos | [ ] |
| P6 | `game.ServerStorage.RollLegendsDev:Invoke("PlayReveal", game.Players:GetPlayers()[1], "Divine", "char_goju_base")` | Hero Landing com o Goju, limpa no fim | [ ] |

---

**Passou tudo?** Então vale rodar os 108 testes do `TEST_PLAN.md`. **Falhou algo?** Mande o
número do teste + a mensagem do Output.
