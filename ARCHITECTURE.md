# Arquitetura — Roll Legends

## Visão geral

```
ReplicatedStorage
└── Shared
    ├── Config/          GameConfig, DataConfig, MonetizationConfig, MapConfig, BaseConfig,
    │                    BaseProgressionConfig (dados, sem lógica)
    ├── Modules/         TableUtil, NumberFormatter, RateLimiter, Validator, Signal,
    │                    Logger, AssetLoader, Net, MapLayout, BaseLayout, BaseProgression
    ├── Localization/    Localization (t/format), PtBR (padrão), EnUS
    └── Remotes/         Definitions (lista de remotes + schema); as instâncias são
                         criadas aqui em runtime pelo Net
ReplicatedStorage.Assets (assets/Assets.rbxm: Sounds, VFX, Icons, Sky)

ServerScriptService
└── Server
    ├── Bootstrap.server.luau   cria remotes e inicia os Services (Init -> Start)
    ├── Services/               PlayerDataService, MonetizationService, MapService, BaseService
    ├── Map/                    construtores: Build, Decor, MapBuilder, BaseBuilder
    └── Core/                   lógica pura testável: ProfileCore, ReceiptCore, Migrations,
                                BaseAllocator, MapValidator

StarterPlayer.StarterPlayerScripts
└── Client
    ├── Bootstrap.client.luau   inicia os Controllers
    └── Controllers/            DataController, NotificationController,
                                NavigationController (HUD CENTRO/CASA/LOJA), AmbientController
                                (esteira + dado do Hub, só visual)

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
- Esteira: estrutura fixa no servidor; as ripas e objetos que andam (72 + 16 peças) existem
  só no cliente e são movidos com um único `BulkMoveTo` por quadro.
- Tags (CollectionService): `PlayerBase`, `CharacterSlot`, `LockedCharacterSlot`,
  `TeleportPoint`, `ShopStand`, `Interactable`, `TowerEntrance`, `HubDice`.
- Teste headless: `tests/roblox/MapHarness.luau` roda o código real com o Lune.

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
