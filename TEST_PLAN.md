# Plano de testes — Roll Legends

> **Antes dos testes completos, rode o roteiro curto `STUDIO_SMOKE_TEST.md` (~30 testes).**

> ⚠️ **Nunca use `require(...)` na Barra de comandos para ler o estado do jogo.** Ela roda em
> outra máquina Luau e recebe uma cópia nova (vazia) dos módulos. Use
> `game.ServerStorage.RollLegendsDev:Invoke("Help")` (DevService, só no Studio).

## 1. Automáticos (fora do Roblox)

`python tools\run_tests.py` roda o binário `luau` sobre `tests/run.luau` + checagem de textos.

| Arquivo | O que cobre |
|---|---|
| `tests/TableUtil.spec.luau` | deepCopy, deepEqual, **deep merge/reconcile** (ausentes, tipo errado, chaves desconhecidas, mapas dinâmicos, template intacto) |
| `tests/NumberFormatter.spec.luau` | sufixos K…Dc, truncamento, negativos, NaN/inf, milhar pt-BR, duração |
| `tests/RateLimiter.spec.luau` | capacidade, recarga, chaves independentes, relógio voltando |
| `tests/Validator.spec.luau` | **payload validation** (números, strings, UTF-8, enum, listas, extras, opcionais) + todas as definições de remotes válidas |
| `tests/ProfileCore.spec.luau` | **schema default**, **save/load**, **session lock** (bloqueio, liberação, trava velha, lock perdido não sobrescreve, renovação), **migrations futuras**, versão do futuro, retry/backoff, corrupção com backup |
| `tests/ReceiptCore.spec.luau` | **receipt idempotency** (duplicata, produto desconhecido, erro na entrega, save falhando + repetição sem reentregar, histórico limitado) |
| `tests/Config.spec.luau` | schema completo, consistência DataConfig × Definitions, Localization (formato, fallback) |
| `tests/BaseAllocator.spec.luau` | **base assignment, uniqueness, release, reassignment**, 11º jogador sem base |
| `tests/BaseLayout.spec.luau` | **slot layout**: 4 slots no lado A + 4 no lado B, ids por andar (Floor02 = 09–16), posições, orientação, rampa sem invadir pedestais |
| `tests/BaseProgression.spec.luau` | **RB0 = 1-4 liberados, 5-8 bloqueados**, RB1-4 sem invenção, **RB5 = Floor02 + Slot09**, validação da config |
| `tests/MapLayout.spec.luau` | dimensões, 5+5 bases, sem sobreposição, Hub, lojas a 40-80, **teleport destinations**, esteira fechada |
| `tests/MapValidator.spec.luau` | **map validation**: detecta base faltando, ids repetidos, lado com 2 slots, peças faltando |
| `tests/SpawnCoordinator.spec.luau` | **spawn**: cada jogador nasce na própria base, respawn na mesma base, nunca na base de outro, 10 entradas simultâneas em ordens misturadas, base atrasada (nasce no Hub e vai para casa), 11º jogador |
| `tests/roblox/ServiceHarness.luau` (Lune) | **integração** PlayerDataService + MapService + BaseService reais com jogadores falsos: AssignBase → GetPlayerBase → GetBaseOwner → OwnerUserId → ReleaseBase → reatribuição; regressão da "cópia da Barra de comandos"; integridade |
| `tests/RollCore.spec.luau` | pesos (soma 10.000.000; Secreto 1 em 200.000), Luck com retornos decrescentes (satura em 11), expoentes crescentes, pity 50/800 com **piso exato** (maior vence, reset), **1.000.000 rolls** dentro de 5σ |
| `tests/Odds.spec.luau` | odds reais por cenário A–G (novo → monetizado): Secretos/h, Divinos/h, limite de pay-to-win, pity não cria Secreto |
| `tests/DataSize.spec.luau` | tamanho do save de fim de jogo (600 personagens) < 256 KB (≈ 79 KB) |
| `tests/Formulas.spec.luau` | Luck (dado × upgrades × boost), cooldown mínimo, capacidade, renda por estação (Level × Variante), custo de nível x1/x5/MAX, venda, custos globais |
| `tests/InventoryCore.spec.luau` | **uids únicos** (10.000), equipar (RB0 1–4, slot bloqueado/ocupado, dono, mover), EQUIPAR MELHORES, venda com proteções, duplicatas, comuns |
| `tests/Characters.spec.luau` | roster 5/4/4/3/3/2/2/1, campos, renda cresce por raridade, dados e upgrades |
| `tests/OfflineCore.spec.luau` | 0 s, 1 min, 1 h, 8 h, 24 h (limita), futuro, NaN/inf/texto, renda zero |
| `tests/DailyCore.spec.luau` | primeiro login, Dia 1, double claim/spam, mesmo dia, dia seguinte (<24 h), ciclo de 7, streak perdido, timestamp futuro/inválido |
| `tests/RevealPlanner.spec.luau` | Comum/Épico sem cinemática, Lendário/Mítico/Divino/Secreto com o preset certo, OCULTAR (Secreto força), AUTO pausa/continua, NOVO, PULAR, efeitos reduzidos, **odds = config** |
| `tests/Migrations.spec.luau` | v1 → v2 (Level/Variant, NextUid, slots inválidos) + Template |
| `tests/Economy.spec.luau` | simulação Casual/Ativo/Hardcore: progressão não quebra em 5 min/2 h, 8 h offline ≤ 1 h ativa |
| `tests/roblox/GameplayHarness.luau` (Lune) | **integração** de todos os Services de gameplay reais: roll/cooldown/pity/inventário cheio/auto-sell, equipar + estações (billboard/pad/placa, sem colisão), **nível individual** (custo exato, spam, não equipado, máximo, pisar no pad), renda/coletor (pisar, longe), dados, upgrades, venda (protegidos, prévia = confirmado), Index (marco único), offline (claim único, futuro, fechar sem resgatar), diário (spam, dia seguinte, reset, Dia 7), base demo, saída |
| `tests/BattleCore.spec.luau` | cartas, inimigos determinísticos por andar, chefe, vitória/derrota, log coerente, torres em sequência |
| `tests/FusionCore.spec.luau` | 3 iguais -> próxima variante, nível máximo, custo, protegidos, mistura, última variante, grupos |
| `tests/TradeCore.spec.luau` | troca atômica (nível/variante preservados), protegidos, repetidos, limite, vazia, inventário cheio (nada muda) |
| `tests/MissionCore.spec.luau` | diárias determinísticas por jogador/dia, virada do dia, progresso por evento, conquistas |
| `tests/JackpotCore.spec.luau` | chances (200.000 giros), extremos, regra dos boosts, IDs sem repetição |
| `tests/roblox/ClientHarness.luau` (Lune) | **ponta a ponta**: Services do servidor + Controllers REAIS do cliente, ligados por uma rede falsa que copia os dados. Clica nos botões de verdade: HUD completo, ROLAR, reveal normal e compacto, as 4 cinemáticas (palco, CONTINUAR, limpeza), morrer no meio, MOCHILA (selecionar/EQUIPAR), todas as janelas, DIÁRIO, OFFLINE, venda com confirmação, configurações, notificações agrupadas; falha com qualquer erro de execução |
| `tests/roblox/SessionHarness.luau` (Lune) | **smoke do ciclo completo** (novo → roll → equipar → coletar → melhorar → dado → 5 renascimentos → andar novo → torre → fusão → troca → diário → missão → sair/voltar com DataStore em memória JSON) + **sessão longa**: 10 jogadores, 4 h lógicas, ~14.400 ações, invariantes (NaN, negativo, UID, slot, base, troca, capacidade) |
| `tests/roblox/MapHarness.luau` (Lune) | executa o **MapService/MapBuilder/BaseBuilder reais**; **map references**; estados RB0/RB5/dono; gera a imagem `build/map_preview.png` |

Também rodar antes de cada commit:
- `luau-lsp analyze` (checagem de tipos com definições do Roblox)
- `python tools\build_place.py` (build Rojo)

## 2. Manual no Roblox Studio — FASE 1 (fundação)

Preparação: `python tools\build_place.py` → abrir `build\RollLegends.rbxlx` →
Janela > Saída aberta.

| # | Teste | Como | Esperado |
|---|---|---|---|
| 1 | Boot | Play | Saída: `[Roll Legends][Bootstrap] Roll Legends v0.1.0 iniciado com 2 services` e `[ClientBootstrap] 2 controllers iniciados`. Nenhum erro vermelho |
| 2 | Perfil temporário (sem API) | Play sem acesso à API | Toasts "Bem-vindo ao Roll Legends!" e "Modo de teste: salvamento desativado…"; Saída: `perfil carregado: <nome> (novo: true, offline: true)` |
| 3 | Snapshot no cliente | Saída do cliente | `[DataController] dados recebidos do servidor (Money: 0 Rolls: 0 )` |
| 4 | Ler dados no servidor | Barra de comandos no contexto **Servidor**: `print(game.ServerStorage.RollLegendsDev:Invoke("GetData", game.Players:GetPlayers()[1], "Money"))` | `0` |
| 5 | Pedido válido | Barra de comandos no contexto **Cliente**: `print(require(game.ReplicatedStorage.Shared.Modules.Net).request("SetSetting","HideRollAnimation",true).ok)` | `true` |
| 6 | Payload inválido | Cliente: `print(require(game.ReplicatedStorage.Shared.Modules.Net).request("SetSetting","Money",true).code)` | `invalid_args` + aviso no servidor |
| 7 | Rate limit | Cliente: `local N=require(game.ReplicatedStorage.Shared.Modules.Net) for i=1,10 do print(i, N.request("SetSetting","AutoRoll",true).code) end` | primeiros `nil`, depois `rate_limited` |
| 8 | Request futuro | Cliente: `print(require(game.ReplicatedStorage.Shared.Modules.Net).request("RequestRoll").code)` | `not_implemented` |
| 9 | Compra sem ID | Cliente: `print(require(game.ReplicatedStorage.Shared.Modules.Net).request("RequestPurchase","LuckBoost").code)` | `not_configured` + toast "Este item ainda não está à venda." |
| 10 | Save/load real | Publicar, ativar API no Studio, Play, rodar #5, Stop, Play de novo, rodar #4 trocando `.Money` por `.Settings.HideRollAnimation` | `true` (persistiu); Saída: `perfil salvo e liberado` ao parar |
| 11 | Session lock real | No jogo publicado, entrar, sair e entrar de novo rápido em outro servidor | Entra normalmente (a trava é liberada ao sair); se o servidor antigo ainda estiver salvando, a mensagem `data.session_locked` aparece e na segunda tentativa funciona |
| 12 | BindToClose | Studio com API: Play e Stop | Saída mostra o save antes de fechar, sem aviso de timeout |

## 3. Manual no Roblox Studio — FASE 2 (mapa, bases, Hub)

Preparação: `git pull`, `python tools\run_tests.py` (gera também `build\map_preview.png`),
`python tools\build_place.py`, abrir `build\RollLegends.rbxlx`, Janela > Saída.

| # | O que verificar | Como | Esperado |
|---|---|---|---|
| 1 | Boot | Play | Saída: `mapa construído em …s (≈1200 peças)`, `mapa validado: OK (10 bases, 4 slots no lado A e 4 no lado B…)`, `<você> recebeu a Base03`. Sem erros vermelhos |
| 2 | Nascimento | Logo após o Play | Você aparece logo depois do arco da entrada da sua base, no meio do corredor, olhando para DENTRO da base (pedestais à frente); placa "BASE DE <seu nome>" atrás de você |
| 2b | Respawn | Barra de comandos, contexto **Servidor**: `game.Players:GetPlayers()[1].Character.Humanoid.Health = 0` | Depois do tempo de respawn você nasce de novo na entrada da SUA base, olhando para dentro, sem cair no chão nem prender em nada |
| 2c | Respawn com 2+ jogadores | Teste > Servidor local com 2 jogadores; matar cada um como no 2b | Cada um renasce na própria base; ninguém nasce na base do outro |
| 3 | Slots RB0 | Andar pela base | Lado esquerdo (de quem entra): 4 pedestais coloridos com aro brilhante. Lado direito: 4 pedestais cinza com 🔒 e "REBIRTH 5". Corredor livre no meio |
| 4 | Sem 2º andar | Olhar para cima | Só a moldura do telhado; nenhum Floor02 |
| 5 | HUD | Topo da tela | 3 botões [🎲 CENTRO] [🏠 CASA] [🛒 LOJA]; hover aumenta, clique "afunda", som de clique, barra escura de 1 s |
| 6 | Teleportes | Clicar CENTRO / LOJA / CASA | Hub (olhando o dado) / entre o Hub e as cabanas (olhando as lojas) / entrada da sua base. Clicar rápido não teleporta 2x |
| 7 | Hub | No centro | Praça circular clara, dado gigante branco com pontos girando e flutuando, brilhinhos, cristais e postes em volta |
| 8 | Esteira | Do Hub e da base | Pista oval elevada passando entre o Hub e as bases, com ripas e dados/cristais andando; dá para passar por baixo |
| 9 | Lojas | Perto das cabanas | MERCADO (laranja), LOJA DE DADOS (roxa, maior, com dado no telhado), VENDER (verde). Prompt "Abrir" → aviso "…: em breve!" |
| 10 | Torres / social | Norte do Hub | Portal TORRES "DESAFIE OS ANDARES" + torre em degraus; FUSÃO (oeste), TROCAS (leste), MISSÕES e RANKINGS (3 painéis) |
| 11 | Bordas | Correr até a areia | Parede invisível na borda da areia; água, ilhotas e pedras ao fundo |
| 12 | Escala com bonecos | Barra de comandos, contexto **Servidor**: `game.ServerStorage.RollLegendsDev:Invoke("ShowDummies", 3, true)` | 8 bonecos ~5,5 studs nos 8 pedestais da Base03, todos olhando para o corredor (nariz vermelho), sem encostar uns nos outros |
| 13 | Floor02 (prévia) | Servidor: `game.ServerStorage.RollLegendsDev:Invoke("PreviewFloors", 3, 2)` e depois `…:Invoke("ShowDummies", 3, true)` | Andar de cima construído com efeito de partículas, rampa lateral no lado B, grades, 8 pedestais (Slot09 colorido, 10–16 com cadeado). Subir a rampa a pé |
| 14 | Voltar | Servidor: `game.ServerStorage.RollLegendsDev:Invoke("ResetBase", 3)` | Base volta ao estado real (sem Floor02, sem bonecos) |
| 15 | Multiplayer | Teste > Servidor local com 2 a 4 jogadores (e 10 se a máquina aguentar) | Cada jogador recebe uma base diferente (ordem 3, 8, 2, 9…); placas certas; fechar um jogador → base volta a "BASE LIVRE" |
| 16 | Mobile | Teste > Dispositivo: iPhone (em pé e deitado), iPad, 1366×768 | Os 3 botões cabem no topo sem cobrir a tela |

## 4. Manual no Roblox Studio — FASES 3–6 + estações, offline, diário e cinemática

**Antes**: feche o Studio, `git pull`, `python tools\run_tests.py`, `python tools\build_place.py`,
abra `build\RollLegends.rbxlx` e clique em **Play**. Contexto **Servidor** = Barra de comandos
com a visão "Server" (Test > Current: Server); **Cliente** = visão "Client" ou só olhando a tela.

**Preparação (Servidor, rode uma vez por Play):**
`_G.D = game.ServerStorage.RollLegendsDev _G.P = game.Players:GetPlayers()[1] print(_G.D:Invoke("Help"))`

(Nunca use `require()` na Barra de comandos: ela recebe uma cópia vazia dos módulos.)

| # | Seção | Ação | Resultado esperado | Contexto | Comando |
|---|---|---|---|---|---|
| 1 | A BOOT | Play; olhar a Saída | Sem erros vermelhos; "Roll Legends v… iniciado com 15 services"; "15+ controllers iniciados" | Servidor/Cliente | — |
| 2 | A BOOT | Ver HUD | Topo: CENTRO/CASA/LOJA; esquerda: LOJA/RENASCER/ÍNDICE; baixo: MOCHILA/ROLAR/MELHORIAS + AUTO/OCULTAR; topo direito: DIÁRIO e ⚙️; baixo esquerda: $0, 🍀 1x, 💎 0, Impulso de Amigos +0% | Cliente | — |
| 3 | B BASE | Conferir base do jogador | "alandias123: Base03 (BaseId 3, OwnerUserId …)" | Servidor | `print(_G.D:Invoke("GetPlayerBase", _G.P))` |
| 4 | B BASE | Andar até o coletor (pad verde da frente, lado B) | Billboard "COLETAR" com "$0" embaixo | Cliente | — |
| 5 | C MULTIPLAYER | Teste > Servidor local, 2 jogadores; rolar nos dois | Cada um com base própria; estações e coletor de um não aparecem/coletam na base do outro | Servidor | `for _,p in game.Players:GetPlayers() do print(_G.D:Invoke("GetPlayerBase", p)) end` |
| 6 | D ROLL | Clicar ROLAR (ou tecla R) | Reveal toca; personagem novo na MOCHILA; histórico (chip) acima do botão | Cliente | — |
| 7 | D ROLL | Clicar ROLAR várias vezes rápido | Só 1 roll por cooldown (barra escura no botão); nenhuma mensagem de erro em spam | Cliente | — |
| 8 | D ROLL | Ver Rolls/Pity no servidor | Rolls subiu; Pity conta rolls sem Lendário | Servidor | `print(_G.D:Invoke("GetData", _G.P, "Rolls"), _G.D:Invoke("GetData", _G.P, "Pity"))` |
| 9 | E RNG/REVEAL | 200 rolls instantâneos | Distribuição parecida com 55/25/12/5/2… (JSON) | Servidor | `print(_G.D:Invoke("Roll", _G.P, 200))` |
| 10 | E RNG/REVEAL | Forçar pity Lendário e rolar 1 | Resultado Lendário+ (`{"Legendary":1}` ou maior) | Servidor | `_G.D:Invoke("SetPity", _G.P, 49, 0) print(_G.D:Invoke("Roll", _G.P, 1))` |
| 11 | E RNG/REVEAL | Rolar Comum/Raro/Épico pelo botão | Comum/Incomum: dado gira, flash, nome (~1,2–1,3 s); Raro: raios pequenos; Épico: raios maiores e flash mais forte (~1,8 s) | Cliente | — |
| 12 | F AUTO ROLL | Ligar AUTO | Rola sozinho no ritmo do cooldown; botão AUTO verde ✓ | Cliente | — |
| 13 | F AUTO ROLL | Desligar AUTO | Para imediatamente | Cliente | — |
| 14 | G HIDE ROLL | Ligar OCULTAR e rolar | Sem reveal grande: cartão compacto no topo (ícone, nome, raridade, NOVO) | Cliente | — |
| 15 | G HIDE ROLL | Reabrir o Play (Studio sem API não salva; com API salva) | OCULTAR mantém o estado salvo | Cliente | — |
| 16 | H INVENTÁRIO | Abrir MOCHILA | Grade com retrato, nome, raridade, renda/s; capacidade "N / 100" | Cliente | — |
| 17 | H INVENTÁRIO | Filtros TODOS/RARIDADE/PODER/RENDA/RECENTES e busca "dragon" | Ordem muda; busca filtra por nome | Cliente | — |
| 18 | H INVENTÁRIO | Encher inventário e tentar rolar | "SEU INVENTÁRIO ESTÁ CHEIO!" com [VENDER] [MOCHILA]; repetidas viram "[x2]"; AUTO desliga | Servidor + Cliente | `print(_G.D:Invoke("FillInventory", _G.P))` |
| 19 | H INVENTÁRIO | Limpar inventário | Mochila vazia | Servidor | `print(_G.D:Invoke("ClearInventory", _G.P))` |
| 20 | I EQUIP | Dar personagens e EQUIPAR um na MOCHILA | Vai para o 1º pedestal livre (Slot01, lado A) | Servidor + Cliente | `print(_G.D:Invoke("GiveCharacter", _G.P, "dragon_knight", 3))` |
| 21 | I EQUIP | EQUIPAR MELHORES | Até 4 personagens (RB0) por maior renda; lado B (05–08) continua bloqueado | Cliente | — |
| 22 | I EQUIP | DESEQUIPAR | Estação some do pedestal | Cliente | — |
| 23 | J PERSONAGENS NA BASE | Olhar os pedestais | Modelo 3D placeholder (cores/arma/acessório do personagem), virado para o corredor, sem andar, sem colisão (dá para atravessar) | Cliente | — |
| 24 | J PERSONAGENS NA BASE | Ver atributo TODO_ASSET | `true` nos placeholders | Servidor | `print(workspace.Bases.Base03.RuntimeCharacters:FindFirstChild("Station_1"):FindFirstChildWhichIsA("Model"):GetAttribute("TODO_ASSET"))` |
| 25 | K RENDA | Ver renda | "renda X/s, não coletado Y" crescendo | Servidor | `print(_G.D:Invoke("Income", _G.P))` |
| 26 | L COLETAR | Pisar no coletor | Moedas voam até o dinheiro, "+$X", som; coletor volta a $0 | Cliente | — |
| 27 | L COLETAR | Usar o prompt "Coletar" no coletor de OUTRA base | "Essa não é a sua base." | Cliente | — |
| 28 | M DICE SHOP | Ir à LOJA DE DADOS (Hub) e usar o prompt / botão LOJA | Janela com 6 dados: Luck, preço, requisito, COMPRAR/BLOQUEADO/EQUIPAR/EQUIPADO | Cliente | — |
| 29 | M DICE SHOP | Comprar Sortudo | Precisa de 50 rolls e $2.5K; ao comprar fica EQUIPADO | Servidor + Cliente | `_G.D:Invoke("SetRolls", _G.P, 50) print(_G.D:Invoke("GiveMoney", _G.P, 3000))` |
| 30 | N LUCK | Ver Luck | HUD "🍀 1.25x"; servidor 1.25 | Servidor | `print(_G.D:Invoke("GetLuck", _G.P))` |
| 31 | O UPGRADES | Abrir MELHORIAS (botão ou área MELHORIAS da base) | 4 linhas, "NÍVEL 0/20", próximo benefício, custo; badge com quantos dá para comprar | Cliente | `print(_G.D:Invoke("GiveMoney", _G.P, 1e6))` |
| 32 | O UPGRADES | Comprar Sorte 1x | NÍVEL 1/20; Luck do HUD sobe 8% | Cliente | — |
| 33 | O UPGRADES | Abrir MELHORIAS | "Velocidade de Roll" não aparece (velocidade fixa: 1 roll/s; Roll Rápido 2/s); botão "MÁX" nas outras | Cliente | `print(_G.D:Invoke("GiveMoney", _G.P, 1e9))` |
| 34 | P SELL | No stand VENDER (Hub) → janela VENDER | Botões Vender selecionado / duplicatas / comuns + AUTO-SELL | Cliente | — |
| 35 | P SELL | Vender duplicatas | Confirmação "Vender N personagens por $X?" [CANCELAR] [VENDER]; travados/favoritos/equipados nunca saem | Cliente | `print(_G.D:Invoke("GiveCharacter", _G.P, "flame_rookie", 10))` |
| 36 | P SELL | Travar um personagem e tentar vendê-lo na MOCHILA | "Personagem travado." | Cliente | — |
| 37 | Q AUTO SELL | Ligar COMUM no AUTO-SELL e rolar 30 vezes | Comuns repetidos não entram na mochila; reveal mostra "VENDIDO"; primeira descoberta nunca é vendida | Servidor | `print(_G.D:Invoke("Roll", _G.P, 30))` |
| 38 | Q AUTO SELL | Clicar SECRETO no AUTO-SELL | Fica bloqueado: "Secretos nunca são vendidos automaticamente." | Cliente | — |
| 39 | R INDEX | Abrir ÍNDICE | 24 cards; não descobertos = silhueta preta + "???"; "N / 24 DESCOBERTOS (P%)"; marcos 25/50/75/100 | Cliente | — |
| 40 | R INDEX | Rolar até 6 descobertas | Aviso "Index 25% completo! +10 gemas" uma única vez | Servidor | `print(_G.D:Invoke("Roll", _G.P, 40))` |
| 41 | S SAVE/LOAD | (Place publicado + API ligada) jogar, sair, voltar | Inventário, nível das estações, dados, upgrades, Index, diário mantidos | Servidor | `print(_G.D:Invoke("GetData", _G.P, "Inventory"))` |
| 42 | S SAVE/LOAD | Studio sem API | Aviso "Modo de teste: salvamento desativado" | Cliente | — |
| 43 | T MOBILE | Test > Device: iPhone (em pé e deitado), iPad | HUD cabe sem sobrepor; botões ≥ 44 px; janelas centralizadas e escaladas | Cliente | — |
| 44 | U PERFORMANCE | Base demo nos 10 jogadores (ou várias vezes) e Ctrl+Shift+F5 | FPS estável; estações não têm física; partículas somem de longe | Servidor | `print(_G.D:Invoke("PopulateDemoBase", _G.P, true))` |
| 45 | V SEGURANÇA | Chamar remote com argumento inválido | `{ok=false, code="invalid_args"}` | Cliente | `print(game.ReplicatedStorage.Shared.Remotes.RequestRoll:InvokeServer("Secret"))` |
| 46 | V SEGURANÇA | Equipar uid que não é seu | `not_owned` | Cliente | `print(game.ReplicatedStorage.Shared.Remotes.EquipCharacter:InvokeServer("c999999").code)` |
| 47 | V SEGURANÇA | Ativar AUTO-SELL de Secreto pelo remote | `invalid_args` | Cliente | `print(game.ReplicatedStorage.Shared.Remotes.SetAutoSell:InvokeServer("Secret", true).code)` |
| 48 | V SEGURANÇA | Spam de RequestRoll | Só rolls no ritmo do cooldown; resto `cooldown`/`rate_limited` | Cliente | `for i=1,30 do task.spawn(function() print(game.ReplicatedStorage.Shared.Remotes.RequestRoll:InvokeServer().code) end) end` |
| 49 | W CHARACTER LEVEL | Equipar e ver nível | Novo personagem = Nível 1 no billboard | Cliente | `print(_G.D:Invoke("GiveCharacter", _G.P, "cyber_ronin", 1))` |
| 50 | W CHARACTER LEVEL | Melhorar sem dinheiro | "Dinheiro insuficiente para melhorar." (uma vez a cada 3 s, sem spam) | Cliente | — |
| 51 | W CHARACTER LEVEL | Melhorar personagem NÃO equipado pelo remote: dar um (anote o uid, ex. `c42`) e pedir no Cliente | `not_equipped` | Servidor → Cliente | Servidor: `print(_G.D:Invoke("GiveCharacter", _G.P, "leaf_ranger", 1))` · Cliente: `print(game.ReplicatedStorage.Shared.Remotes.UpgradeCharacter:InvokeServer("c42").code)` |
| 52 | W CHARACTER LEVEL | Levar ao máximo | Nível 50; pad fica dourado "MÁX"; placa "NÍVEL MÁX" | Servidor | `print(_G.D:Invoke("GiveMoney", _G.P, 1e15))` e pisar no pad |
| 53 | X PEDESTAL UPGRADE | Pisar no pad verde em frente ao pedestal | Sobe 1 nível a cada 0,4 s enquanto estiver em cima; pad pisca branco, faíscas, som subindo de tom, "NÍVEL N!" | Cliente | `print(_G.D:Invoke("GiveMoney", _G.P, 1e6))` |
| 54 | X PEDESTAL UPGRADE | Prompt "Melhorar" no pad | +1 nível; custo novo no pad; renda nova no billboard | Cliente | — |
| 55 | X PEDESTAL UPGRADE | Prompt no pad de OUTRO jogador | "Essa não é a sua base." | Cliente | — |
| 56 | Y OFFLINE MONEY | Simular 1 h fora com renda 100/s | Pendente = 100 × 3600 × 12% = 43.200 | Servidor | `print(_G.D:Invoke("SimulateOffline", _G.P, 3600, 100))` |
| 57 | Y OFFLINE MONEY | Ver popup | Botão 🎁 OFFLINE aparece no topo direito; clicar abre "BEM-VINDO DE VOLTA!" com $43.2K e RESGATAR | Cliente | — |
| 58 | Y OFFLINE MONEY | Fechar no X | Valor continua; 🎁 OFFLINE reabre | Cliente | — |
| 59 | Y OFFLINE MONEY | RESGATAR duas vezes rápido | Paga uma vez; 2ª: "Nada para resgatar." | Cliente | — |
| 60 | Y OFFLINE MONEY | 24 h fora | Limita a 8 h (100 × 28800 × 12% = 345.600) | Servidor | `print(_G.D:Invoke("SimulateOffline", _G.P, 86400, 100))` |
| 61 | Y OFFLINE MONEY | Timestamp no futuro | Pendente não muda (aviso "LastLogout inválido") | Servidor | `print(_G.D:Invoke("SimulateOffline", _G.P, -99999, 100))` |
| 62 | Z DAILY | Abrir DIÁRIO (badge "1") | Grade Dia 1–6 + Dia 7 grande; Dia 1 com borda brilhando e "RESGATAR!" | Cliente | `_G.D:Invoke("SetDaily", _G.P, nil, 0)` |
| 63 | Z DAILY | Clicar Dia 1 | Dinheiro entregue; ✔ verde no Dia 1; badge some; "Próxima recompensa em HH:MM:SS" | Cliente | — |
| 64 | Z DAILY | Clicar de novo / spam | Nada é entregue ("Já resgatado hoje.") | Cliente | — |
| 65 | Z DAILY | Simular "resgatou ontem, dia 3" | Dia 4 disponível; 1–3 com ✔ | Servidor | `print(_G.D:Invoke("SetDaily", _G.P, 1, 3))` |
| 66 | Z DAILY | Simular "resgatou há 3 dias" | Volta ao Dia 1 (sequência perdida) | Servidor | `print(_G.D:Invoke("SetDaily", _G.P, 3, 5))` |
| 67 | Z DAILY | Simular Dia 7 | Recebe o Dado Prisma (exclusivo); na LOJA aparece como EQUIPAR | Servidor | `print(_G.D:Invoke("SetDaily", _G.P, 1, 6))` |
| 68 | AA BILLBOARDS | Olhar uma estação de perto | VARIANTE (se não Normal) / NOME / RARIDADE (cor) / Nível N / $X/s; placa "$produzido" + "Nível N > N+1"; pad "$custo" — renda e custo separados | Cliente | — |
| 69 | AA BILLBOARDS | Afastar ~50 studs e ~100 studs | Médio: só a renda; longe: billboard some e auras param | Cliente | — |
| 70 | AB BASE DEMO | Base demo (4 slots) | 4 estações com raridades/níveis diferentes | Servidor | `print(_G.D:Invoke("PopulateDemoBase", _G.P))` |
| 71 | AB BASE DEMO | Base demo (8 slots, ignora bloqueio) | 8 estações: Comum, Raro (Prata), Épico, Lendário (Ouro), Mítico (Diamante), Divino (Esmeralda), Incomum, Secreto (Celestial) | Servidor | `print(_G.D:Invoke("PopulateDemoBase", _G.P, true))` |
| 72 | AC RARE CINEMATIC | Lendário | Tela escurece, câmera olha o céu, silhueta, queda com rastros/speed lines, IMPACTO (flash, tremida, anel, poeira, destroços, rachaduras, som grave), ajoelhado → levanta → pose; LENDÁRIO / ✨ NOVO! ✨ / nome / "1 EM 150"; CONTINUAR (~2,3 s) | Servidor | `print(_G.D:Invoke("PlayReveal", _G.P, "Legendary"))` |
| 73 | AC RARE CINEMATIC | Mítico | Texto "MÍTICO" antes da queda, luz vermelha na cena, anel maior, tremida maior (~3 s) | Servidor | `print(_G.D:Invoke("PlayReveal", _G.P, "Mythic", "void_emperor"))` |
| 74 | AC RARE CINEMATIC | Divino | "DIVINO", feixes de luz no céu, silhueta brilhante, onda maior; odds + 🍀 Luck | Servidor | `print(_G.D:Invoke("PlayReveal", _G.P, "Divine", "celestial_monk"))` |
| 75 | AC RARE CINEMATIC | Secreto | Tela quase preta, silêncio curto, glitch + "???", fenda, queda muito rápida, tela branca no impacto (~4,2 s) | Servidor | `print(_G.D:Invoke("PlayReveal", _G.P, "Secret"))` |
| 76 | AC RARE CINEMATIC | Todas em sequência | Lendário → Mítico → Divino → Secreto, cada uma esperando CONTINUAR | Servidor | `print(_G.D:Invoke("PlayAllReveals", _G.P))` |
| 77 | AC RARE CINEMATIC | Limpeza | Depois de fechar: câmera/movimento normais; nada sobra em PlayerGui | Cliente | `print(game.Players.LocalPlayer.PlayerGui:FindFirstChild("HeroLanding"))` → `nil` |
| 78 | AC RARE CINEMATIC | Morrer durante a cinemática | Cinemática fecha sozinha, nada preso | Servidor | `_G.P.Character.Humanoid.Health = 0` (logo após o PlayReveal) |
| 79 | AD HIDE ROLL + RARE | OCULTAR ligado e PlayReveal de cada raridade | Comum–Épico compacto; Lendário compacto especial; Mítico destacado; Divino premium (borda arco-íris); **Secreto toca a cinemática completa** | Servidor | `print(_G.D:Invoke("PlayReveal", _G.P, "Divine"))` |
| 80 | AE AUTO ROLL + RARE | AUTO ligado; forçar pity e esperar | No Lendário o AUTO pausa durante a cinemática, que fecha sozinha ~1,2 s após CONTINUAR, e o AUTO continua | Servidor | `_G.D:Invoke("SetPity", _G.P, 49, 0)` |
| 81 | AF MOBILE CINEMATIC | Device iPhone em pé/deitado + PlayReveal | Palco ocupa a tela; textos e botões visíveis; qualidade Medium (menos destroços) | Servidor | `print(_G.D:Invoke("PlayReveal", _G.P, "Mythic"))` |
| 82 | AG REDUCED EFFECTS | ⚙️ → Efeitos reduzidos LIGADO e "Tremer a câmera" DESLIGADO; PlayReveal | Poucos destroços, sem rastros/rachaduras, sem tremida; impacto ainda tem flash/anel/som; auras das estações desligadas | Servidor | `print(_G.D:Invoke("PlayReveal", _G.P, "Divine"))` |

### Fases 7–11

| # | Seção | Ação | Resultado esperado | Contexto | Comando |
|---|---|---|---|---|---|
| 83 | AH TORRES | Portal TORRES no Hub (prompt) | Janela TORRES: 3 torres, "ANDAR 0/30", poder dos inimigos, time automático (5 mais fortes) | Cliente | — |
| 84 | AH TORRES | LUTAR na Torre das Brasas com personagens fortes | Tela de batalha: cartas dos dois lados, ataques com dano/críticos, VITÓRIA + dinheiro; ANDAR 1/30 | Servidor + Cliente | `print(_G.D:Invoke("GiveCharacter", _G.P, "eclipse_sovereign", 1))` |
| 85 | AH TORRES | Lutar com time fraco num andar alto | DERROTA, andar não avança | Servidor | `_G.D:Invoke("SetTowerFloor", _G.P, "Ember", 25)` |
| 86 | AH TORRES | Tempestade antes de completar Brasas | "Complete a torre anterior primeiro." | Cliente | — |
| 87 | AH TORRES | MOCHILA → "TIME DA TORRE" em até 5 personagens; TIME AUTO volta ao automático | Janela mostra "Seu time"/"Time automático" com o poder | Cliente | — |
| 88 | AI RENASCIMENTO | Botão RENASCER (esquerda) | Janela com custo, ganhos permanentes, o que reseta e loja de fichas; badge "!" quando dá para renascer | Cliente | — |
| 89 | AI RENASCIMENTO | Renascer | Confirmação; dinheiro e melhorias globais zeram; Slot05 liberado na base; "+X fichas" | Servidor | `print(_G.D:Invoke("Rebirth", _G.P))` |
| 90 | AI RENASCIMENTO | 5 renascimentos | Floor02 construído com efeito; Slot09 liberado | Servidor | rodar o comando acima 5 vezes |
| 91 | AI RENASCIMENTO | Comprar perk com fichas | Nível sobe; sorte/renda do HUD aumentam | Cliente | — |
| 92 | AJ FUSÃO | Altar FUSÃO com 3 iguais livres | Lista "3x Nome (NORMAL) → PRATA" + custo; FUNDIR cria a Prata com o maior nível | Servidor + Cliente | `print(_G.D:Invoke("GiveCharacter", _G.P, "dragon_knight", 3))` |
| 93 | AJ FUSÃO | Travar 1 dos 3 | Grupo some da lista (protegidos não entram) | Cliente | — |
| 94 | AK TROCAS | 2 jogadores (Servidor local) → mesa TROCAS → CONVIDAR | O outro recebe "Pedido de troca!" com ACEITAR/RECUSAR | Cliente (2 janelas) | — |
| 95 | AK TROCAS | Cada um põe personagens, PRONTO, CONFIRMAR | Troca concluída; itens trocam de mochila; quem recebeu ganha no Índice | Cliente (2 janelas) | — |
| 96 | AK TROCAS | Mudar a oferta depois do PRONTO | PRONTO dos dois some; precisa confirmar de novo | Cliente | — |
| 97 | AK TROCAS | Sair do jogo durante a troca | O outro vê "O outro jogador saiu."; nada é trocado | Cliente | — |
| 98 | AL MISSÕES | Botão MISSÕES / quadro no Hub | 3 diárias com barra de progresso + 4 conquistas | Cliente | — |
| 99 | AL MISSÕES | Rolar até completar "Role 50 vezes" e RESGATAR | Recompensa; botão vira ✔; badge some | Servidor | `print(_G.D:Invoke("Roll", _G.P, 60))` |
| 100 | AM LOJA | MERCADO no Hub (prompt) ou atalhos VIP/SORTE x2 à direita | LOJA: gamepasses, pacotes, loja de gemas e chances do Jackpot | Cliente | — |
| 101 | AM LOJA | Comprar com Robux (IDs ainda 0) | "Este item ainda não está à venda." | Cliente | — |
| 102 | AM LOJA | Giro do Jackpot com gemas (atalho JACKPOT) | Rolo gira e para no prêmio; −150 gemas; se for personagem, o reveal/cinemática toca | Servidor | `print(_G.D:Invoke("GiveGems", _G.P, 1000))` |
| 103 | AM LOJA | Simular VIP | Etiqueta 👑 VIP na cabeça; renda x1.5 nas estações; loja mostra COMPRADO | Servidor | `_G.D:Invoke("GrantPass", _G.P, "VIP")` |
| 104 | AM LOJA | Simular produto | Popup do prêmio (dinheiro/boost/gemas) | Servidor | `print(_G.D:Invoke("DeliverProduct", _G.P, "LuckBoost"))` |
| 105 | AN AMIGOS | 2 contas amigas no mesmo servidor (jogo publicado) | "Impulso de Amigos +5%" no canto inferior esquerdo | Cliente | — |
| 106 | AO RANKINGS | Olhar os 3 painéis do Hub | MAIS REBIRTHS / MAIOR TORRE / MAIS ROLLS preenchidos (no Studio: jogadores do servidor) | Cliente | — |
| 107 | AO RANKINGS | Lista de jogadores (Tab) | Colunas Rebirths e Rolls | Cliente | — |
| 108 | AP MÚSICA | ⚙️ → Música de fundo LIGADO | Música toca em loop baixo; DESLIGADO para | Cliente | — |

### Diagnóstico rápido

- `print(_G.D:Invoke("Analytics"))` — contagem dos eventos internos.
- `print(_G.D:Invoke("RollHistory", _G.P))` — últimos 10 rolls da sessão.
- Erros de handler aparecem como `[Roll Legends][Net] handler X falhou`.
