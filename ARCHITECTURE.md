# Arquitetura — Roll Legends

## Visão geral

```
ReplicatedStorage
└── Shared
    ├── Config/          GameConfig, DataConfig, MonetizationConfig, MapConfig, BaseConfig,
    │                    BaseProgressionConfig, RarityConfig, RollConfig, CharacterConfig,
    │                    CharacterLevelConfig, VariantConfig, DiceConfig, UpgradeConfig,
    │                    EconomyConfig, OfflineIncomeConfig, DailyConfig, IndexConfig,
    │                    RevealConfig, FriendBoostConfig (dados, sem lógica)
    ├── Modules/         TableUtil, NumberFormatter, RateLimiter, Validator, Signal,
    │                    Logger, AssetLoader, Net, MapLayout, BaseLayout, BaseProgression,
    │                    RollCore, Formulas (+ GameFormulas), OfflineCore, DailyCore,
    │                    RevealPlanner (puros) e CharacterModelFactory (modelos 3D)
    ├── Localization/    Localization (t/format), PtBR (padrão), EnUS
    └── Remotes/         Definitions (lista de remotes + schema); as instâncias são
                         criadas aqui em runtime pelo Net
ReplicatedStorage.Assets (assets/Assets.rbxm: Sounds, VFX, Icons, Sky)

ServerScriptService
└── Server
    ├── Bootstrap.server.luau   cria remotes e inicia os Services (Init -> Start)
    ├── Services/               PlayerDataService, MonetizationService, MapService, BaseService,
    │                           AnalyticsService, EconomyService, InventoryService, IndexService,
    │                           SellService, RollService, DiceService, UpgradeService,
    │                           StationService, DailyService, DevService (Studio)
    ├── Map/                    construtores: Build, Decor, MapBuilder, BaseBuilder
    └── Core/                   lógica pura testável: ProfileCore, ReceiptCore, Migrations,
                                BaseAllocator, MapValidator, SpawnCoordinator, InventoryCore

StarterPlayer.StarterPlayerScripts
└── Client
    ├── Bootstrap.client.luau   inicia os Controllers
    ├── UI/                     UITheme (design system) + UIKit (botões, janelas, confirmação, sons)
    ├── Effects/                HeroLanding (cinemática), JackpotReveal (Divino/Secreto), CameraShake, Pool
    └── Controllers/            Notification, Data, Hud, Navigation, Ambient, Reveal, Roll,
                                Inventory, DiceShop, Upgrades, Sell, Index, Daily, Offline,
                                Settings, Feedback, Lod

Workspace (gerado pelo MapService ao iniciar o servidor)
├── Map        Environment, Paths, Conveyor, Hub, Shops, Towers, Social
├── Bases      Base01 … Base10
└── Runtime    Characters, Effects, Temporary
```

Regra: **não criar Services/Controllers vazios**. Cada um nasce na fase em que é usado.

## Ciclo de vida

- **Bootstrap** chama `Net.initServer()`, depois `Init()` de todos os Services na ordem de
  `ORDER` (registrar handlers, sem yield), depois `Start()` de cada um em sua thread.
  Erros em um Service são registrados e não derrubam os outros.
- O cliente faz o mesmo com os Controllers.

## Rede (`Shared/Modules/Net.luau`)

- **Requests** (RemoteFunction cliente→servidor): o cliente pede, o servidor responde
  `{ ok = true, data }` ou `{ ok = false, code }`. Códigos: `rate_limited`, `invalid_args`,
  `not_ready`, `not_implemented`, `internal` (o cliente mostra `error.<code>` da Localization).
- **Events** (RemoteEvent servidor→cliente): `Notify(chaveDeTexto, params)` e
  `DataChanged(chave, valor)`. Qualquer coisa enviada pelo cliente nesses eventos é ignorada.
- Pipeline de cada request: rate limit (token bucket por jogador+remote) → validação de
  argumentos (`Validator`, schema em `Remotes/Definitions`) → handler em `pcall`.
- Requests já preparados para as próximas fases (respondem `not_implemented`):
  `RequestRoll`, `RequestEquipCharacter`, `RequestSellCharacter`, `RequestEquipDice`,
  `RequestUpgrade`, `RequestEnterTower`.
- Nunca usar `InvokeClient` (o servidor ficaria preso esperando um cliente).

## Dados

`PlayerDataService` (+ `Core/ProfileCore`) é a única porta para os dados do jogador.
Outros Services usam `GetData`, `Set`, `Increment`, `SaveNow` e o sinal `Loaded`.
O cliente recebe um snapshot (`GetSnapshot`) e depois `DataChanged`; ele **nunca escreve**
dados, só pede intenções. Detalhes em `DATA_SCHEMA.md`.

## Monetização

`MonetizationService`: IDs só em `MonetizationConfig`; o cliente pede `RequestPurchase(chave)`
e o servidor abre a compra; `ProcessReceipt` idempotente (`Core/ReceiptCore`); gamepasses com
cache e reconfirmação via `UserOwnsGamePassAsync`. Produtos são entregues por funções
registradas com `MonetizationService.RegisterProduct`.

## Textos

Todo texto de interface fica em `Localization/PtBR.luau` (padrão) e é lido com
`Localization.t("chave", params)`. O servidor envia **chaves**, não frases.
`tools/run_tests.py` falha se alguma chave usada no código não existir no PtBR.

## Assets externos

Sempre por `AssetLoader` (remove scripts, desliga colisão/física). Busca na Store com
`tools/FindAssets.lua`. Regras em `SECURITY.md`.

## Mapa (FASE 2)

- Gerado 100% por código a partir de `MapConfig`/`BaseConfig` (nada de números mágicos nos
  construtores). Os cálculos de posição ficam em módulos puros (`MapLayout`, `BaseLayout`,
  `BaseProgression`) testados fora do Roblox; os construtores só transformam isso em peças.
- `MapService` constrói tudo no `Init` (mapa + 10 bases no estado RB0), expõe `GetHubSpawn`,
  `GetShopSpawn`, `GetTowerEntrance`, `GetBases`, `ValidateMap` e responde "em breve" nos
  prompts das áreas que ainda não funcionam. No Studio valida o mapa ao iniciar.
- `BaseService`: `BaseAllocator` (puro) garante uma base por jogador; aplica placa do dono,
  progressão visual (andares/slots) e teleporta. Também atende `RequestTeleport`
  (Center/Home/Shop, cooldown de 1 s no servidor). Sem base livre: jogador vai para o Hub
  (log "No free base available.").
- Spawn: `PlayerSpawn` de cada base é um `SpawnLocation` (Neutral = false) logo depois do arco
  da entrada, olhando para dentro. `CharacterAutoLoads = false`; o `Core/SpawnCoordinator`
  (puro, testado) só carrega o personagem depois da base atribuída, define
  `player.RespawnLocation` e posiciona o HumanoidRootPart na altura certa (respawn incluso).
  Sem base em 10 s (ou servidor cheio): nasce no Hub e vai para casa quando a base chegar.
- Esteira: estrutura fixa no servidor; as ripas e objetos que andam (72 + 16 peças) existem
  só no cliente e são movidos com um único `BulkMoveTo` por quadro.
- Tags (CollectionService): `PlayerBase`, `CharacterSlot`, `LockedCharacterSlot`,
  `TeleportPoint`, `ShopStand`, `Interactable`, `TowerEntrance`, `HubDice`.
- Teste headless: `tests/roblox/MapHarness.luau` roda o código real com o Lune.
- Visual BLOCKY SIMULATOR (sobre o layout existente, sem mover nada funcional):
  `MapConfig.Visual` centraliza paleta, folgas da decoração (`DecorClearance`), densidade e
  semente; `MapConfig.Landmarks` lista as áreas funcionais. `MapLayout.decorSpots()` /
  `edgeBites()` decidem ONDE plantar (determinístico, testado: nada em caminhos, bases,
  esteira, Hub, landmarks ou spawns; árvores só fora de `OpenCenterRadius`; entre a esteira e as
  bases só flores). `Decor` é a biblioteca de peças blocky (BlockyTree, BlockyPalm, BlockyBush,
  BlockyRockCluster, BlockyFlowerPatch, pilar, borda chunky, placa, dado pequeno). Decoração perto
  de caminho tem `CanCollide = false`; só troncos/rochas principais longe dos caminhos colidem.
- Hierarquia visual: Hub (altar de 3 degraus + pedestal + dado 18) > base do jogador > Dice Shop
  (portal sobre o caminho principal) / Torres (portal + espada + escudo) > Fusão / Mercado / Vender
  > Missões / Trocas / Rankings > decoração.
- Vistas da câmera do jogador fora do Studio: `python tools/render_views.py` (lê
  `build/map_preview.json` do MapHarness; gera `build/views/*.png`). Aproximação, não substitui
  o Studio. Tour no Studio: `game.ServerStorage.RollLegendsDev:Invoke("VisualCheck", game.Players:GetPlayers()[1], "Hub")` (Base, Conveyor, DiceShop, Market,
  Sell, Fusion, Towers, Missions, Trades, Rankings).

## Pipeline de personagens (piloto)

- Visual de personagem tem UMA fonte: `CharacterModelFactory` (Base, Reveal, Mochila, Índice,
  Hero Landing, galeria DEV). Ele usa `ReplicatedStorage.CharacterAssets.<CharacterId>` (gerado
  por `tools/build_characters.py` a partir do Anime Pack, sanitizado e validado) ou o placeholder.
- Fusão, Torres, Trocas, Inventário e save só conhecem o `CharacterId`.
- Pilotos: `CharacterConfig.Pilots` (fora de `List`, logo fora do roll e do progresso do Índice).
- Detalhes, regras de normalização/pivô/VFX/variantes e decisão de armazenamento:
  `CHARACTER_PIPELINE.md`.

## Base do jogador

Cada andar tem **2 lados com 4 slots cada (4 + 4 = 8)**:

```
Floor01: SideA = Slot01..Slot04 | SideB = Slot05..Slot08
Floor02: SideA = Slot09..Slot12 | SideB = Slot13..Slot16
...
```

- Jogador novo (Rebirth 0): 4 slots liberados, **todos no SideA** do Floor01; SideB bloqueado.
- Personagens em fileira, todos com a mesma orientação (exposição de coleção).
- Liberação de slots/lados/andares 100% configurável (`BaseProgressionConfig`): lista
  explícita de slots por marco, sem fórmula. Definido: RB0 = Floor01 + slots 1-4;
  RB5 = Floor02 + slots 1-9. RB1-4 ainda não definidos (usam o marco RB0).
- Andar bloqueado não existe fisicamente; slot bloqueado existe com pedestal apagado,
  cadeado e requisito ("REBIRTH 5" ou "REBIRTH NECESSÁRIO" quando ainda não definido).
- Andares sobem de 20 em 20 studs; a rampa fica num "poço" lateral que alterna de lado a
  cada andar (Floor01→02 pelo lado B, Floor02→03 pelo lado A…). A moldura do telhado fica
  sempre no andar mais alto, então a base cresce visivelmente.


## Fases 7–12

| Service | Responsabilidade | Remotes |
|---|---|---|
| TowerService | 3 torres, batalha de cards simulada no servidor (BattleCore), time da torre, recompensas | RequestEnterTower, SetTowerTeam |
| RebirthService | renascimento (reset, bônus permanentes, +1 pedestal), loja de fichas | Rebirth, BuyRebirthPerk |
| FusionService | 3 iguais -> próxima variante (FusionCore) | Fuse |
| TradeService | trocas entre jogadores (convite, ofertas, pronto, confirmação, troca atômica — TradeCore) | RequestTrade, RespondTrade, SetTradeOffer, SetTradeReady, ConfirmTrade, CancelTrade |
| MissionService | 3 diárias por jogador/dia + conquistas (MissionCore), progresso pelos eventos de analytics | ClaimMission |
| BoostService | multiplicadores de sessão em data.Runtime (gamepasses, impulso de amigos), etiqueta VIP | — |
| JackpotService | Giro do Jackpot, loja de gemas, entrega dos produtos Robux | SpinJackpot, BuyGemItem |
| LeaderboardService | rankings dos painéis do Hub (OrderedDataStore) e leaderstats | — |

Cliente: TowerController (janela + tela de batalha animada), RebirthController, FusionController,
TradeController, MissionController, StoreController (loja + atalhos da direita + giro),
MusicController. Interações do mapa: Towers, Fusion, Trade, Missions, Market (loja).

## Gameplay (Fases 3–6 + estações, offline, diário, cinemática)

Ordem do servidor (`Bootstrap`): PlayerData → Monetization → Map → Base → Analytics → Economy →
Inventory → Index → Sell → Roll → Dice → Upgrade → Station → Daily → Dev.

| Service | Responsabilidade | Remotes |
|---|---|---|
| RollService | roll autoritativo (cooldown, inventário cheio antes do sorteio, Luck, pity, Index, auto-sell, histórico de sessão, anúncio) | RequestRoll |
| InventoryService | unidades (uid), equipar/desequipar/melhores, travar/favoritar, **nível individual** | EquipCharacter, UnequipCharacter, EquipBest, SetCharacterFlag, UpgradeCharacter |
| StationService | cada slot equipado vira **estação**: personagem 3D, billboard (variante/nome/raridade/nível/renda), placa (produzido + Nível N > N+1), pad de upgrade (pisar/prompt) | — |
| EconomyService | dinheiro, renda passiva → coletor, coletar (pisar/prompt/remote perto), **dinheiro offline** | CollectMoney, ClaimOfflineReward |
| DiceService | comprar/equipar dados, abre a LOJA DE DADOS | BuyDice, EquipDice |
| UpgradeService | melhorias globais, abre MELHORIAS na base | BuyUpgrade |
| SellService | vender, vender em massa (prévia + confirmação), auto-sell | SellCharacter, SellBatch, SetAutoSell |
| IndexService | descobertas e marcos (25/50/75/100%) | — |
| DailyService | recompensas diárias (7 dias, UTC do servidor) | GetDailyStatus, ClaimDaily |
| AnalyticsService | ganchos internos (FirstRoll, Roll, RareObtained, …) | — |

Interações do mapa: `MapService.RegisterInteraction(id, fn)` (DiceShop, Sell, UpgradeArea,
MoneyCollector, StationUpgrade); o servidor responde com `OpenMenu` quando é uma janela.

**Cliente**: `UITheme` + `UIKit` (um design system para toda janela). HUD segue a hierarquia
da referência: topo centro CENTRO/CASA/LOJA, esquerda LOJA/RENASCER/ÍNDICE, baixo centro
MOCHILA/ROLAR/MELHORIAS (+ AUTO/OCULTAR e histórico), topo direito OFFLINE/DIÁRIO/⚙️,
baixo esquerda dinheiro/Luck/impulso de amigos, direita reservada (monetização futura).

**Reveal**: `RevealPlanner` (puro) decide Normal / Enhanced / Compact / HeroLanding a partir
do `RevealConfig`. A cinemática roda num **ViewportFrame local** com câmera própria: a câmera
e os controles do jogador nunca são tocados; tudo é limpo em `Stop()` (pular, continuar,
morrer, erro). Peças de impacto vêm de `Pool`.
**Jackpot Reveal (Divino/Secreto)**: `Effects/JackpotReveal` (presets com `Stage = "World"`). O
ViewportFrame não renderiza partículas/Beams/Highlight, então Divino e Secreto usam um palco NO
MUNDO, só no cliente, bem acima do mapa (`RevealConfig.JackpotStage`), com a câmera real em
Scriptable: queda visível → hero landing → Aura Full (AuraBuilder + AuraController) → nome e
raridade. Câmera, controles e HUD são guardados e restaurados exatamente em `Stop()`; o
resultado já veio do servidor (nenhum RNG na apresentação). OCULTAR não esconde Divino/Secreto;
o AUTO (normal ou Roll Rápido) fica parado enquanto a apresentação toca e retoma na cadência do
servidor. DEV: `DivineLanding` / `SecretLanding`.

**Desempenho**: estações sem colisão/toque/consulta; um loop central por serviço (renda 1 s,
placas 2 s, pads 0,4 s, coletor 0,25 s); textos só mudam quando o valor muda; billboards com
`MaxDistance`; `LodController` (cliente, 0,5 s) esconde detalhe e partículas de longe.

## Auditoria pré-Studio — desempenho, mobile, fila de avisos e tutorial

- **400 personagens (10 bases × 40 slots)**: nenhum loop por personagem. Servidor: 1 loop
  central atualiza o "$ produzido" a cada 3 s (só se o texto mudou) e 1 loop checa pads.
  Modelos procedurais: peças `Anchored`, sem `CanTouch/CanQuery/CastShadow`. Billboard some
  a 90 studs, placa/pad a 55; LodController (cliente, a cada 0,5 s): < 40 studs completo,
  < 75 sem detalhe, longe sem partículas/luz. Na prática o jogador vê ~1–2 bases com UI ativa.
- **HUD responsivo** (`HudController.Layout`): escala única pela tela + 3 modos — largo,
  compacto (< 1200 unidades: status sobem) e retrato (status no topo; somem atalhos da
  direita e o histórico). HUD usa `ScreenInsets = DeviceSafeInsets` (notch).
- **Prioridade de avisos** (`NotificationController`): CRITICAL > RARE_DROP > REWARD >
  WARNING > INFO; REWARD/INFO esperam a cinemática. Janelas automáticas entram em
  `QueueModal` (uma por vez, por prioridade, nunca sobre reveal/janela/tutorial).
- **Tutorial** (`TutorialController` + `TutorialConfig`): 7 passos detectados pelos dados,
  banner "PASSO X/7" com PULAR; HUD progressivo nos 3 primeiros passos.
