# MIGRATION_PLAN — Roll Legends

> **O jogo anterior ("Simulador de Escudo") era um protótipo e foi completamente descontinuado.
> Nenhuma compatibilidade ou migração de dados foi necessária.**
>
> Checkpoint do protótipo: tag Git `shield-prototype-final` (commit `f22dde8`).
> O DataStore `SimuladorEscudo_v1` não é lido; o Roll Legends usa `RollLegends_PlayerData_v1`.

## Status

| Fase | Status |
|---|---|
| 0 — Auditoria | ✅ concluída (seção "Histórico: auditoria do protótipo" abaixo) |
| 1 — Limpeza + arquitetura/fundação | ✅ concluída (commit 140794b) |
| 2 — Mapa completo + 10 bases + Hub + cabanas + esteira | ✅ concluída |
| 3 — Sistema de dados/RNG + primeira revelação | ⏳ próxima |

## Ordem oficial das fases (atualizada)

1. Limpeza + arquitetura (fundação, DataStore, rede segura, monetização mínima) ✅
2. Mapa completo + 10 bases + Hub + cabanas + esteira ✅
3. Sistema de dados/RNG + primeira revelação
4. Personagens 3D + inventário + personagens na base + geração de dinheiro
5. Luck + novos dados + upgrades + loja
6. Venda + auto-sell + índice
7. Torres + batalha de cards
8. Rebirth + progressão avançada
9. Missões + daily + offline
10. Monetização
11. Conteúdo, VFX, áudio e polish
12. Balanceamento, simulações e otimização

Cada fase termina com: `python tools\run_tests.py`, `luau-lsp analyze`, build, roteiro do
`TEST_PLAN.md` no Studio, documentação e commit.

## Decisões de design registradas

- **UI em PT-BR**, textos centralizados em `Shared/Localization` (EN-US depois).
- **Personagens: modelos 3D completos já na V1** (revelação, base, previews, batalhas);
  raridades altas com aura/partículas/idle/luz, respeitando mobile.
- **Base: cada andar = 2 lados × 4 slots = 8** (`SideA` Slot01–04, `SideB` Slot05–08;
  Floor02 = Slot09–16…). Rebirth 0 = 4 slots liberados **todos no SideA**; SideB bloqueado.
  Exposição em fileira com orientação consistente. Liberações configuráveis; só estão
  definidos Rebirth 0 = 4 slots, Floor01 = 8 físicos e Rebirth 5 = próximo andar.
  (Substitui qualquer menção anterior a "2 de cada lado".)
- **Publicação**: o Roll Legends usa o mesmo Place ID do protótipo (o protótipo foi abandonado).

## FASE 1 — o que foi feito

- **1A Limpeza**: removidos todo o gameplay, UI, configs, remotes e assets específicos do
  protótipo; `Modelos.rbxm` (672 KB, 1.024 poses, pets/escudos/ovos) substituído por
  `Assets.rbxm` (12,8 KB: Sounds, VFX, Icons, Sky; 0 scripts, 0 animações).
- **1B Fundação**: Bootstrap servidor/cliente, GameConfig, DataConfig, PlayerDataService
  (ProfileCore: UpdateAsync, session lock, autosave, retry/backoff, schema versionado,
  BindToClose, PlayerRemoving, backup de corrupção), Localization, NumberFormatter,
  AssetLoader, Logger, Signal, TableUtil.
- **1C Segurança**: Net com schema por remote, Validator, RateLimiter, requests futuros
  (`RequestRoll`, `RequestEquipCharacter`, `RequestSellCharacter`, `RequestEquipDice`,
  `RequestUpgrade`, `RequestEnterTower`) respondendo `not_implemented`.
- **1D Monetização mínima**: MonetizationConfig, MonetizationService, ReceiptCore idempotente.

---

# Histórico: auditoria do protótipo (FASE 0)

> O texto abaixo é o registro da auditoria feita antes da reconstrução. As classificações
> "ADAPTAR/REUTILIZAR" foram revistas na FASE 1: como o protótipo foi abandonado, quase tudo
> foi reescrito do zero; só ficaram as ferramentas, as técnicas e os assets genéricos.

## 1. Auditoria do projeto atual

### 1.1 Visão geral

| Item | Valor |
|---|---|
| Ferramenta | Rojo 7.7.1 (baixado pelo `tools/build_place.py`), Luau |
| Linhas de código Luau | ~3.700 (15 arquivos em `src/`) |
| Publicação | `tools/build_place.py` (rbxlx) + `tools/publish_place.py` (Open Cloud, Universe 10770107678 / Place 86294164179735) |
| Conceito atual | Simulator "toque para ganhar armadura → quebre paredes → vitórias → escudos/pets/mundos" |
| Arquitetura atual | 1 script de servidor "god script" (`main.server.luau`, 608 linhas) + módulos; 1 LocalScript de HUD + janelas; UI 100% criada por código |
| Testes automatizados | Nenhum. Só checagem de tipos com `luau-lsp analyze` |

### 1.2 Inventário de arquivos e classificação

Legenda: **REUTILIZAR** (fica quase igual), **ADAPTAR** (a ideia/código serve, mas vai ser reescrito no novo formato), **REMOVER** (específico do jogo antigo), **SUBSTITUIR** (a função continua existindo, mas com sistema novo).

#### Infraestrutura / ferramentas

| Arquivo | O que faz | Classe | Motivo |
|---|---|---|---|
| `tools/build_place.py` | Gera `.rbxlx` com Rojo pinado + injeta `assets/*.rbxm` | **REUTILIZAR** | Genérico. Só trocar o nome do arquivo de saída (via config) |
| `tools/publish_place.py` | Publica via Open Cloud | **REUTILIZAR** | Genérico. Ver risco R1 (mesmo Place ID) |
| `tools/BuscarModelos.lua` | Busca pets/ovos/escudos na Store | **ADAPTAR** | O mecanismo (busca + filtro de nome + remoção de scripts) vira `tools/BuscarAssets.lua` com listas novas (palmeiras, dados, VFX…) |
| `tools/BuscarExtras.lua` | Busca sons/VFX/céu/ícones | **ADAPTAR** | Mesmo caso acima, unificar em um só script |
| `default.project.json` | Árvore Rojo | **ADAPTAR** | Nova árvore (Shared/Config, Shared/Modules, Services, Controllers) |
| `aftman.toml` | Versão do Rojo | **REUTILIZAR** | — |
| `.gitignore` | — | **REUTILIZAR** | — |
| `tools/__pycache__/*.pyc` | Lixo versionado por engano | **REMOVER** | Já está no `.gitignore`, mas foi commitado |
| `README.md` | Docs do jogo antigo | **SUBSTITUIR** | Reescrito para Roll Legends |

#### Shared (`ReplicatedStorage.Shared`)

| Arquivo | O que faz | Classe | Motivo |
|---|---|---|---|
| `Config.luau` | Toda a economia do simulator (escudos, pets, ovos, mundos, auras, paredes, tutorial, passes) + helpers | **SUBSTITUIR** | Vira vários configs (`CharacterConfig`, `DiceConfig`, …). Helpers genéricos (`copiar`) vão para `TableUtil` |
| `Modelos.luau` | Clona modelo de `ReplicatedStorage.Modelos`, **remove scripts**, ajusta tamanho, solda | **REUTILIZAR** (renomear `AssetLoader`) | Totalmente genérico e já protege contra backdoor. Usado para personagens, dados, VFX |

#### Servidor (`ServerScriptService.Server`)

| Arquivo | O que faz | Classe | Motivo / destino |
|---|---|---|---|
| `Dados.luau` (335) | Load/save DataStore, merge com defaults, multiplicadores, sync via Attributes, tutorial, sorteio de ovo, recompensas | **ADAPTAR** (dividir) | Load/save/merge ➜ `PlayerDataService` (com versionamento, `UpdateAsync`, session lock). Sync via Attributes ➜ substituído por replicação de estado (ver 3.4). Sorteio ponderado ➜ `RNG` + `RollService`. `darRecompensa` ➜ `RewardService`. Multiplicadores ➜ `LuckService`/`EconomyService` |
| `main.server.luau` (608) | Dispatcher de ações (`Acao`), personagem, paredes, gamepasses, ProcessReceipt, loops | **ADAPTAR** (dividir) | Dispatcher com rate-limit ➜ `Net` (remotes tipados). Gamepasses + receipt ➜ `MonetizationService` (corrigir idempotência). Offline income ➜ `OfflineIncomeService`. Lógica de escudo/paredes/mundos/auras ➜ **REMOVER** |
| `Mundo.luau` (266) | Gera hub quadriculado com studs, ovos, pista, paredes, barreiras invisíveis | **SUBSTITUIR** | Vira `MapService`/`BaseService` (10 bases + HUB). Reaproveitar: helper de piso com studs, `barreira()` invisível, placa de texto |
| `Ranking.luau` (127) | 2 placares OrderedDataStore com cache de nomes | **ADAPTAR** | Vira `LeaderboardService` genérico (N placares: Money, Rolls, Rebirths, Floor, Collection%) |
| `Conquistas.luau` (41) | Badges por condição | **REUTILIZAR** (renomear `BadgeService`→`AchievementService`) | Genérico; só trocam as condições |
| `Visual.server.luau` (38) | Iluminação + ColorCorrection + Bloom + Sky do asset | **REUTILIZAR** | Vira `LightingService`; valores no `GameConfig` |

#### Cliente (`StarterPlayerScripts.Client`)

| Arquivo | O que faz | Classe | Motivo / destino |
|---|---|---|---|
| `UI.luau` (319) | Helpers: `create`, `texto`, `botao`, `janela`, `linha`, formatação de números/tempo, `notificar`, `icone`, registro de refresh | **ADAPTAR** | Base do `UIController` + `UIKit`. Formatação ➜ `NumberFormatter` (shared). Falta: `UIScale`, responsividade mobile, pooling |
| `Efeitos.luau` (156) | Sons de `Modelos/Sons` + partículas de `Modelos/Efeitos` com fallback | **ADAPTAR** | Separar em `AudioController` + `EffectsController` (com pooling) |
| `main.client.luau` (455) | HUD do simulator (TOQUE!, nível, tutorial, autoclick, passes, menu) | **SUBSTITUIR** | Novo HUD (ROLL central, Backpack, Upgrades, Money, Friend Boost) |
| `Janelas/Loja.luau` | Escudos/Auras/Melhorias/Rebirth | **SUBSTITUIR** | Dice Shop / Market / Upgrades / Rebirth |
| `Janelas/Pets.luau` | Inventário de pets, fusão, animação de ovo | **ADAPTAR** | Ideias (inventário com cards, fila de animação de reveal) ➜ `InventoryController` + `RollController` |
| `Janelas/Mundos.luau` | Teleporte entre mundos | **REMOVER** | Não existe no novo conceito (CENTER/HOME substituem) |
| `Janelas/Recompensas.luau` | Diária, presentes por tempo, poções, boosts Robux | **ADAPTAR** | Diária ➜ `DailyRewardService`; poções ➜ consumíveis do Market |
| `PetsVisual.client.luau` | Pets seguindo jogadores (arco, lerp, modelo ou fallback) | **ADAPTAR** | Técnica reaproveitada para personagens "andando" na base / showcase |
| `Paredes.client.luau` | Colisão local de paredes | **REMOVER** | Específico do jogo antigo |

### 1.3 Remotes

| Remote | Tipo | Direção | Uso | Classe |
|---|---|---|---|---|
| `Remotes.Acao` | RemoteEvent | C→S | Dispatcher de 19 ações (`Click`, `ComprarEscudo`, `AbrirOvo`, `FundirPet`…) com rate-limit global de 0.15 s | **SUBSTITUIR** por remotes por domínio com validação de tipos (ver 3.3) |
| `Remotes.Notificar` | RemoteEvent | S→C | Toast de texto | **REUTILIZAR** (vira `Notify`) |
| `Remotes.OvoAberto` | RemoteEvent | S→C | Resultado do ovo para animação | **SUBSTITUIR** por `RollResult` |
| `Remotes.Efeito` | RemoteEvent | S→C | Som/VFX por tipo + posição | **REUTILIZAR** (vira `PlayEffect`) |
| RemoteFunctions | — | — | Nenhuma | — |

### 1.4 DataStores

| Nome | Tipo | Conteúdo | Classe |
|---|---|---|---|
| `SimuladorEscudo_v1` | GlobalDataStore | Perfil do simulator (chave = UserId) | **NÃO MIGRAR**: o conteúdo não tem equivalente no novo jogo. O novo store usa outro nome (`RollLegends_Profile_v1`), assim os saves antigos ficam intactos e recuperáveis |
| `RankingRebirths_v1` | OrderedDataStore | Top rebirths | **REMOVER** (substituído) |
| `RankingVitorias_v1` | OrderedDataStore | Top vitórias | **REMOVER** (substituído) |

Problemas encontrados no save atual (corrigidos na FASE 1):
- `SetAsync` sem `UpdateAsync`: um servidor antigo pode sobrescrever o save mais novo.
- **Não tem session lock**: entrar em outro servidor rápido pode duplicar ou perder dados.
- **Não tem campo `Version`** nem migrações.
- Salva de 60 em 60 s sem limitar requisições por minuto.
- O `ProcessReceipt` **não é idempotente** (não guarda o `PurchaseId`), então um produto pode ser entregue duas vezes se o Roblox reenviar a compra.

### 1.5 GUIs

Todas criadas por código (nenhuma ScreenGui em StarterGui):
- `SimuladorGui` (HUD + 9 janelas): **SUBSTITUIR**
- `BillboardGui` dos ovos, `SurfaceGui` das paredes e placares: **REMOVER/SUBSTITUIR**
- Os helpers de construção (`UI.create`, `UI.janela`, `UI.linha`) são **ADAPTADOS**

### 1.6 Mapa

Gerado 100% por código (`Mundo.luau`), sem nada salvo no Studio:
- 4 mundos × (hub 96×72 + pista 30×385 + 10 paredes + barreiras invisíveis): **REMOVER**
- Reaproveitar a técnica: piso com `SurfaceType.Studs`, barreiras invisíveis e placas `SurfaceGui`
- `assets/Mapa.rbxm` está previsto no build, mas **não existe ainda**

### 1.7 Assets (`assets/Modelos.rbxm`, 6.4k linhas binárias)

Auditado convertendo para XML: **0 scripts** (o filtro de backdoor funcionou).

| Pasta | Conteúdo | Classe |
|---|---|---|
| `Pets/` (16) | Modelos de pets da Store | **REMOVER** (não combinam com lutadores) |
| `Escudos/` (12) | Escudos | **REMOVER** |
| `Ovos/` (5) | Ovos | **REMOVER** |
| `Sons/` (7) | Clique, Compra, Nivel, Parede, Rebirth, Ovo, Musica | **REUTILIZAR** (Clique, Compra, Nivel, Rebirth, Musica) / **ADAPTAR** (Ovo ➜ reveal, Parede ➜ impacto de batalha) |
| `Efeitos/` (5) | Partículas | **REUTILIZAR** |
| `Ceu/Sky` | Céu cartoon | **REUTILIZAR** |
| `Icones/` (10) | Decals | **ADAPTAR** (manter Rebirth, Presente, Pocao, Melhoria; buscar Roll, Backpack, Index, Tower, Dice, Money, Gems) |

Observação: o asset tem **1.024 `Pose` + 64 `Keyframe`**, ou seja, animações embutidas nos pets, que ocupam espaço à toa. Elas saem junto com os pets.

### 1.8 Mapa de dependências (antes de excluir)

```
Config ◄── tudo (servidor e cliente)
Modelos ◄── main.server, Mundo, PetsVisual
Dados ◄── main.server          (Dados expõe remotes e o estado global dos jogadores)
Mundo, Ranking, Conquistas ◄── main.server
UI ◄── main.client, Janelas/*
Efeitos ◄── main.client
Janelas/* ◄── main.client
Atributos do Player (Armadura, Pets, Boosts, ...) ◄── Dados.sync ──► UI/Janelas/PetsVisual/Paredes
```

Consequência: o jogo antigo é um bloco só. **Não dá para remover partes isoladamente sem quebrá-lo.** Por isso a estratégia é construir a nova árvore ao lado e trocar de uma vez no fim da FASE 1 (ver 4.1).

---

## 2. O que será aproveitado e o que sai

### Aproveitado (genérico, já testado em produção)
1. **Pipeline** de build/publish (Rojo pinado, assets `.rbxm`, Open Cloud).
2. `Modelos.luau` ➜ `AssetLoader` (clonagem segura que remove scripts).
3. Padrão de **load/merge de dados com defaults** (`mesclar`) ➜ base da migração.
4. **Dispatcher com rate-limit** ➜ evolui para `Net` com schema por remote.
5. Conquistas/badges, Ranking (OrderedDataStore + cache de nomes), Lighting/Sky.
6. Helpers de UI, formatação de números (`K/M/B/T/Qa/Qi`) e tempo, toasts.
7. Áudio/VFX com fallback e assets de som/efeito/céu.
8. Técnicas de mapa: piso com studs, barreiras invisíveis, placas SurfaceGui, respawn por queda.
9. Scripts de busca na Store (com filtro de nome + remoção de scripts).

### Removido
Toque/armadura, paredes/pista, escudos, pets/ovos/fusão de pets, auras, mundos, poções antigas, presentes por tempo, tutorial antigo, HUD antigo, rankings antigos e os assets de pets/escudos/ovos.

---

## 3. Arquitetura proposta

### 3.1 Árvore (Rojo)

```
ReplicatedStorage
  Shared
    Config/
      GameConfig.luau           -- nome do jogo, nº de bases, cores, iluminação, flags
      CharacterConfig.luau      -- lutadores (id, nome, raridade, power, income, peso, sell, index)
      RarityConfig.luau         -- raridades, cores, pity
      DiceConfig.luau           -- dados (luck, speed, preço, requisito)
      EconomyConfig.luau        -- moedas, custo de roll, offline, friend boost
      UpgradeConfig.luau
      RebirthConfig.luau
      TowerConfig.luau
      TowerDropConfig.luau
      MissionConfig.luau / DailyConfig.luau / IndexConfig.luau
      MonetizationConfig.luau   -- TODOS os IDs de gamepass/produto
      Strings.luau              -- textos da UI (PT-BR), para trocar idioma depois
    Modules/
      NumberFormatter.luau
      RNG.luau                  -- sorteio ponderado (puro, testável fora do Roblox)
      Signal.luau
      TableUtil.luau
      Net.luau                  -- define remotes + validação de tipos (compartilhado)
      AssetLoader.luau          -- ex-Modelos.luau
      Formulas.luau             -- luck/income/custos (puro, usado pelo servidor e pela simulação)
  Remotes/                      -- criados pelo Net em runtime

ServerScriptService
  Server/
    init.server.luau            -- bootstrap: carrega services na ordem e chama :Start()
    Services/
      PlayerDataService   BaseService     MapService       RollService
      LuckService         DiceService     CharacterService InventoryService
      EconomyService      UpgradeService  TowerService     BattleService
      RebirthService      OfflineIncomeService MissionService DailyRewardService
      MonetizationService LeaderboardService AchievementService AnalyticsService
      FriendBoostService  LightingService

StarterPlayer.StarterPlayerScripts
  Client/
    init.client.luau            -- bootstrap dos controllers
    Controllers/
      UIController  RollController  BaseController  InventoryController
      TowerController  BattleController  EffectsController  AudioController
      TeleportController  TutorialController
    UI/                          -- UIKit + telas (Hud, Backpack, DiceShop, Market, Sell, Tower, Index, Rebirth…)

assets/  Mapa.rbxm (decoração do Studio)  Modelos.rbxm (personagens, dados, VFX, sons)
tests/   specs puros (RNG, Formulas, migração) rodados com o binário `luau` fora do Roblox
tools/   build/publish/busca de assets + simulate_economy (simulação)
```

### 3.2 Padrão de serviços
- Cada Service é um ModuleScript com `Init()` (registra dependências) e `Start()` (conecta eventos). Um bootstrap único chama na ordem. Nada de vários `.server.luau` soltos.
- Services se comunicam por chamadas diretas e `Signal`s. O cliente **nunca** chama Service diretamente, só pelo `Net`.

### 3.3 Rede e segurança (server authoritative)
- `Net.luau` declara cada remote com **schema de argumentos** (tipos, ranges, tamanho máximo de string, enums) e **rate limit por remote/jogador** (token bucket).
- O cliente só envia intenções: `RequestRoll`, `EquipCharacter(uid)`, `SellCharacters({uid…})`, `BuyDice(id)`, `EnterTower(id)`, `SetSetting(key, bool)`…
- O servidor calcula tudo: roll, valores, dano, drops, preços, rebirth, offline.
- `RemoteFunction` só para leituras idempotentes (ex.: snapshot inicial). Elas têm timeout no cliente.

### 3.4 Replicação de estado
Hoje o servidor replica o estado via Attributes + JSON a cada sync, e a cada clique ele reserializa o perfil inteiro. Nova abordagem:
- O servidor envia o **snapshot** inicial uma vez e depois **deltas por chave** (`StateChanged(path, value)`), com agrupamento por frame.
- O cliente mantém um `ClientState` com `Signal` por chave. A UI só atualiza o que mudou.
- Valores de leaderboard continuam em `leaderstats`.

### 3.5 DataStore (FASE 1)

```lua
PlayerData = {
  Version = 1,
  Money = 0, Gems = 0, RebirthTokens = 0,
  Rolls = 0, Rebirths = 0,
  EquippedDice = "Normal", OwnedDice = { Normal = true },
  Inventory = {},             -- [uid] = { Id, Locked, Favorite, Level, ObtainedAt }
  NextUid = 1,
  BaseSlots = {},             -- uids colocados na base (gera income)
  TowerTeam = {},             -- até 4 uids
  Index = {},                 -- [CharacterId] = true (descoberto)
  Upgrades = {}, PermanentUpgrades = {},
  TowerProgress = {},         -- [TowerId] = maior andar
  Pity = {},                  -- [Rarity] = rolls desde o último
  Consumables = {}, ActiveBoosts = {},
  Settings = { AutoRoll = false, HideRollAnimation = false, AutoSell = {} },
  Daily = { Streak = 0, LastClaim = 0 }, Missions = {},
  Stats = {},                 -- contadores para missões/analytics
  ProcessedPurchases = {},    -- PurchaseIds recentes (idempotência)
  LastLogout = 0,
}
```
- `UpdateAsync` + **session lock** (campo com JobId e timestamp; espera e tenta de novo se outro servidor estiver segurando).
- `Migrations[n] = function(data) ... end` aplicadas em sequência até `CURRENT_VERSION`. Save com versão desconhecida (mais nova) = **não carrega e não sobrescreve** (o jogador entra em modo seguro, sem salvar).
- Falha de load = **modo sem salvar** com aviso, igual ao comportamento atual (que é correto).
- Save: autosave a cada 2–3 min + ao sair + `BindToClose`, respeitando o orçamento de requisições.

### 3.6 Árvore de sistemas (gameplay)

```
ROLL ─┬─ DiceService (dado equipado: luck, speed)
      ├─ LuckService (dado × upgrades × rebirth × boosts × VIP × index × friend × evento)
      ├─ RollService (cooldown, pity, RNG ponderado, auto-roll, auto-delete)
      └─► CharacterService/InventoryService (cria o lutador, index, lock/favorite)
              ├─► BaseService (slots na base ➜ income/s ➜ EconomyService)
              ├─► SellService (venda unitária / duplicatas / tudo, com proteção)
              └─► Tower team (4) ➜ TowerService ➜ BattleService (simulação no servidor)
                                                  └─► TowerDropConfig ➜ RewardService
EconomyService (Money, Gems, RebirthTokens) ◄── base income, sell, drops, daily, missions
UpgradeService / DiceShop / Market  ◄── gastam Money/Gems
RebirthService ➜ reseta economia, dá RebirthTokens ➜ PermanentUpgrades
OfflineIncomeService (timestamp do servidor, teto 8 h)
Missions / Daily / Index bonuses / Achievements / Leaderboards / Analytics
MonetizationService (passes, produtos, receipts idempotentes)
```

### 3.7 Mapa
- Oval com 10 bases (5 de cada lado) em volta do HUB central, a ~60–80 studs do centro. Assim todo mundo vê as bases dos outros.
- HUB: Towers (centro), Market / Sell / Dice Shop (as 3 cabanas), Fusion, Missions, Trade (placeholder), Leaderboards. Tudo a no máximo ~15 s de caminhada.
- **Esteira**: o trilho é uma única peça com `Texture` cuja `OffsetStudsV` anima no cliente (custo quase zero). Os objetos em cima vêm de um **pool pequeno** (~20) de caixas/dados movidos no cliente por um único loop `RenderStepped` com `BulkMoveTo`. O servidor não move nada.
- A geometria das bases e slots é gerada por código, para ficar consistente com o `BaseService`. A decoração (palmeiras, água, pontes) é feita no Studio e salva em `assets/Mapa.rbxm`.
- Máximo de 10 jogadores: isso é configuração da experiência (*Configurações > Lugares*). Não dá para mudar por script.

---

## 4. Plano de implementação (versão original da FASE 0, substituído pela "Ordem oficial" acima)

### 4.1 Estratégia de troca
1. A FASE 1 cria a nova árvore (`Shared/Config`, `Shared/Modules`, `Services`, `Controllers`) e o novo `PlayerDataService` **no lugar** do jogo antigo, em um único commit de troca. O código antigo sai junto. Ele fica preservado no histórico do Git; há uma tag `legacy-shield-sim` para voltar se precisar.
2. Cada fase termina com: `luau-lsp analyze` sem erros, testes puros (`tests/`) passando, build gerando o `.rbxlx`, teste manual no Studio (roteiro no `TEST_PLAN.md`) e commit/push.

### 4.2 Fases

| Fase | Entrega | Critério de pronto |
|---|---|---|
| **0** | Auditoria + este plano | ✅ |
| **1** | Nova árvore Rojo, bootstrap de Services/Controllers, `Net` com validação + rate limit, `PlayerDataService` (UpdateAsync, session lock, versão, migrações), `NumberFormatter`, `RNG`, `Signal`, `TableUtil`, `ClientState`, `GameConfig`, remoção do jogo antigo, `tests/` com runner `luau` | Entrar/sair salva e carrega; save com falha não sobrescreve; testes de RNG/migração passam |
| **2** | `MapService`: oval + 10 bases + HUB (cabanas, torre, placares placeholder) + esteira otimizada; `BaseService` (atribuir/liberar base, placa com nome/avatar); teleporte CENTER/HOME com cooldown | 10 jogadores recebem bases diferentes; sair libera a base |
| **3** | `DiceService` + `RollService` + `LuckService` (só o Normal Dice), pity, roll com animação completa e modo "ocultar rolagem" (persistido), botão ROLL | Roll calculado 100% no servidor; animação nos dois modos |
| **4** | `CharacterConfig` (~30 lutadores originais na primeira leva), inventário (cards, filtros, lock/favorite), equipar na base, income passivo + coleta, Index básico | Lutador na base gera dinheiro visível; inventário persiste |
| **5** | Dice Shop (6–7 dados), Upgrades (Luck, Money, Roll Speed, Inventory, Base Slots, Tower Damage) | Preços vêm do config; o efeito do luck aparece no roll |
| **6** | Sell (selecionados / duplicatas / tudo, com confirmação e proteções), Market (consumíveis/boosts), auto-roll + auto-delete | Locked/Favorite/Equipped nunca são vendidos |
| **7** | Torres + card battle (simulação no servidor, animação no cliente, AUTO, EXIT), drops | O resultado é igual com ou sem animação; drops vêm do config |
| **8** | Rebirth + Rebirth Tokens + upgrades permanentes; Offline income (WELCOME BACK) | Reset correto; offline calculado com relógio do servidor |
| **9** | Missões diárias, Daily calendar, bônus do Index, Achievements, Leaderboards (5) | — |
| **10** | Monetização (`MonetizationConfig`, passes, produtos, receipts idempotentes, VIP, Friend Boost) | Produto reenviado não é entregue duas vezes |
| **11** | VFX/áudio/polish, pooling, onboarding (6 passos) | Tutorial < 2 min |
| **12** | `ECONOMY.md` + simulação (casual/ativo/hardcore/AFK × 15 min a 5 h), balanceamento, `TEST_PLAN.md` completo, otimização mobile | Metas dos primeiros 10 min batem na simulação |

Observação: o `ECONOMY.md` começa na FASE 4 (os primeiros números já são simulados) e é refinado na 12. A simulação usa o mesmo `Formulas.luau` do jogo, rodado com o binário `luau`, então ela não diverge do jogo.

---

## 5. Riscos técnicos

| # | Risco | Impacto | Mitigação |
|---|---|---|---|
| R1 | **Publicar o Roll Legends no Place ID atual substitui o Simulador de Escudo que está no ar** | Alto | Decidir antes da FASE 2: criar uma experiência nova (recomendado) ou aceitar a troca. O ID fica em `publish_place.py`/config |
| R2 | Não tenho como rodar o Roblox aqui: o teste real depende do Studio | Alto | Lógica pura (RNG, fórmulas, migração, batalha) com testes fora do Roblox; checagem de tipos; roteiro de teste manual por fase; logs claros no Output |
| R3 | DataStore: perda/duplicação de dados entre servidores | Alto | UpdateAsync + session lock + versão + modo sem salvar em falha |
| R4 | Receipts duplicados | Médio | `ProcessedPurchases` salvo antes de retornar `PurchaseGranted` |
| R5 | Exploits (spam de roll, venda forjada, dano no cliente) | Alto | Validação no `Net`, rate limit, servidor autoritativo em tudo |
| R6 | Performance mobile (esteira, VFX, 10 bases com modelos) | Médio | Esteira com textura + pool; LOD/streaming das bases distantes; pooling de VFX/números; limite de partículas |
| R7 | Lag com muitos personagens na base (até 20 × 10 bases = 200 modelos) | Médio | Modelos low-poly, `StreamingEnabled`, animação idle só por perto, sem física (Anchored) |
| R8 | Assets da Store com scripts ou de baixa qualidade | Médio | `AssetLoader` remove scripts; script de busca com filtro de nome; auditoria do rbxm convertendo para XML (como feito aqui) |
| R9 | Copyright: personagens parecidos demais com animes | Médio | Arquétipos originais com nomes próprios; revisar nomes e visuais |
| R10 | Economia sem testar (inflação, paredão de progresso) | Médio | Simulação antes de fixar números; tudo nos configs |
| R11 | Loot "pago" e regras de odds | Médio | Odds visíveis na UI de roll/dados; nenhuma lootbox comprada diretamente com Robux sem mostrar as chances |
| R12 | Escopo grande | Alto | Fases curtas e entregáveis; cada uma jogável |

---

## 6. Creator Store — o que procurar

**Sempre só a geometria** (MeshPart/Part/Texture/Decal/SurfaceAppearance), passando pelo `AssetLoader` e pela auditoria em XML. Nada de usar scripts de terceiros.

| Categoria | Buscas sugeridas | Uso |
|---|---|---|
| Natureza tropical | "low poly palm tree", "low poly bush", "tropical island", "low poly rock" | Decoração do oval |
| Água / pontes | "low poly bridge", "wooden bridge", "water" (preferir Terrain water) | Ligar bases ao HUB |
| Construções | "low poly hut", "market stall", "shop stand", "small house" | Cabanas Market/Sell/Dice Shop |
| Torre | "fantasy tower", "low poly tower", "magic tower" | Entrada das Towers no HUB |
| Dados | "dice model", "d6 dice", "low poly dice" | Modelo do dado (variações de cor/material por config) |
| Esteira | "conveyor belt", "crate", "wooden box" | Trilho + caixas do pool |
| Personagens | "R15 rig", "anime character model", "warrior npc" (só a geometria) | Base dos lutadores; variar com acessórios/cores para ter identidade |
| VFX | "slash effect", "impact vfx", "aura particle", "magic circle", "level up effect" | Batalha, reveal, raridades altas |
| Sons | "dice roll sound", "dice shake", "card flip", "sword slash", "hit sound", "victory fanfare", "cash register" | Roll, batalha, venda |
| Ícones | "money icon", "gem icon", "dice icon", "backpack icon", "tower icon", "index book icon" (mesmo estilo) | HUD |
| Cards/molduras | "card frame ui", "rarity frame" | Cards do inventário e da batalha |

---
