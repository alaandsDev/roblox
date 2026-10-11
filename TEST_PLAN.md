# Plano de testes — Roll Legends

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

## 4. Futuras fases

Lista completa (bases, roll, auto roll, inventário cheio, venda, torres, rebirth, offline,
daily, gamepass, produto, falha de DataStore, reconexão, UI mobile…) será detalhada aqui
conforme cada fase entrar.
