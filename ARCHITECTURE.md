# Arquitetura — Roll Legends

## Visão geral

```
ReplicatedStorage
└── Shared
    ├── Config/          GameConfig, DataConfig, MonetizationConfig (dados, sem lógica)
    ├── Modules/         TableUtil, NumberFormatter, RateLimiter, Validator, Signal,
    │                    Logger, AssetLoader, Net
    ├── Localization/    Localization (t/format), PtBR (padrão), EnUS
    └── Remotes/         Definitions (lista de remotes + schema); as instâncias são
                         criadas aqui em runtime pelo Net
ReplicatedStorage.Assets (assets/Assets.rbxm: Sounds, VFX, Icons, Sky)

ServerScriptService
└── Server
    ├── Bootstrap.server.luau   cria remotes e inicia os Services (Init -> Start)
    ├── Services/               PlayerDataService, MonetizationService
    └── Core/                   lógica pura testável: ProfileCore, ReceiptCore, Migrations

StarterPlayer.StarterPlayerScripts
└── Client
    ├── Bootstrap.client.luau   inicia os Controllers
    └── Controllers/            DataController, NotificationController
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

## Base do jogador (definido para a FASE 2)

Cada andar tem **2 lados com 4 slots cada (4 + 4 = 8)**:

```
Floor01: SideA = Slot01..Slot04 | SideB = Slot05..Slot08
Floor02: SideA = Slot09..Slot12 | SideB = Slot13..Slot16
...
```

- Jogador novo (Rebirth 0): 4 slots liberados, **todos no SideA** do Floor01; SideB bloqueado.
- Personagens em fileira, todos com a mesma orientação (exposição de coleção).
- Liberação de slots/lados/andares 100% configurável (`BaseProgressionConfig`, FASE 2).
  Já definido: Rebirth 0 = 4 slots; Floor01 = 8 slots físicos; Rebirth 5 = mecânica do
  próximo andar. Rebirths 1–4 ainda não definidos.
