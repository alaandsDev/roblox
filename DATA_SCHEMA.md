# Data Schema — Roll Legends

DataStore: **`RollLegends_PlayerData_v1`**, chave `Player_<UserId>`.
O `SimuladorEscudo_v1` do protótipo **não é lido nem migrado**.

## Registro gravado

```lua
{
	Data = { ...perfil (abaixo)... },
	Meta = {
		SessionLock = { JobId = "<servidor>", LockedAt = <os.time> } | nil,
		SavedAt = <os.time>,
		CorruptBackup = <valor ilegível encontrado, se houver>,
	},
}
```

## Perfil — versão 2 (`Shared/Config/DataConfig.luau`)

| Campo | Tipo | Descrição |
|---|---|---|
| `Version` | number | Versão do schema (= `DataConfig.SchemaVersion` = 2) |
| `Money`, `Gems`, `RebirthTokens` | number | Moedas |
| `Rolls`, `Rebirths` | number | Contadores |
| `EquippedDice` | string | Dado equipado (`"Normal"`) |
| `OwnedDice` | map | `{ [diceId] = true }` (Normal sempre) |
| `Inventory` | map | `{ [uid] = CharacterInstance }` (abaixo) |
| `NextUid` | number | Próximo uid (`"c" .. NextUid`); nunca diminui, nunca repete |
| `EquippedCharacters` | map | `{ [tostring(slotId)] = uid }` (chave string: compatível com JSON) |
| `Index` | map | `{ [characterId] = { Count, FirstAt } }` |
| `IndexRewards` | map | `{ ["25"] = true, ... }` marcos já pagos |
| `Upgrades` | map | `{ Luck, Income, RollSpeed, Inventory }` níveis das melhorias GLOBAIS |
| `TowerProgress` | map | Maior andar por torre (fase futura) |
| `Pity` | map | `{ Legendary, Mythic }` rolls desde a raridade |
| `UncollectedMoney` | number | Renda no coletor da base |
| `LastKnownIncomePerSecond` | number | Renda/s da base (base do dinheiro offline) |
| `PendingOfflineReward` | number | Dinheiro offline calculado e ainda não resgatado |
| `LastDailyClaim`, `DailyStreak`, `DailyCycleDay` | number | Diário (os.time do servidor, sequência, último dia do ciclo 0–7) |
| `Boosts` | map | `{ Luck = { Multiplier, ExpiresAt } }` |
| `RevealViews` | map | `{ [rarity] = vezes }` (libera PULAR na cinemática) |
| `Settings.AutoRoll`, `HideRollAnimation`, `CameraShake`, `ReducedEffects` | boolean | Configurações do cliente |
| `Settings.AutoSell` | map | `{ Common..Divine = boolean }` (Secreto nunca) |
| `Daily` | map | Reservado (legado) |
| `ProcessedReceipts` | lista | Últimos PurchaseIds entregues (idempotência). **Privado**: nunca vai ao cliente |
| `LastLogout` | number | "Visto por último": saída do jogador e a cada 30 s (os.time do servidor) |
| `CreatedAt`, `LastSave` | number | `os.time()` do servidor |

### CharacterInstance (`Inventory[uid]`)

| Campo | Tipo | Descrição |
|---|---|---|
| `Id` | string | `CharacterConfig` id |
| `Level` | number | Nível da estação (1..CharacterLevelConfig.MaxLevel) |
| `Variant` | string | `Normal` (Silver/Gold/Diamond/Emerald/Void/Celestial preparadas em VariantConfig) |
| `Locked`, `Favorite` | boolean | Proteções contra venda |
| `ObtainedAt` | number | os.time do servidor |

### Migração v1 → v2 (`Server/Core/Migrations.luau`)

Unidades antigas ganham `Level = 1`, `Variant = "Normal"`, flags booleanas; itens inválidos são
removidos; `NextUid` fica acima do maior uid existente; slots apontando para uids inexistentes
são limpos. Os campos novos vêm do Template (reconcile). Teste: `tests/Migrations.spec.luau`.

Tabelas vazias no Template são **mapas dinâmicos**: o carregamento só garante o tipo, não o conteúdo.

## Garantias do salvamento (`Server/Core/ProfileCore.luau`)

- **UpdateAsync** sempre (nunca SetAsync).
- **Session lock**: carregar grava `SessionLock` com o JobId; outro servidor espera e tenta
  de novo (backoff exponencial) e, se a trava continuar ativa, o jogador recebe a mensagem
  `data.session_locked`. Trava sem renovação há `SessionLockTimeout` (30 min) = servidor
  caído, pode ser assumida. O autosave renova a trava.
- **Lock perdido**: se outro servidor assumiu, o save é cancelado (não sobrescreve) e o
  jogador é desconectado com `data.lost_lock`.
- **Autosave** a cada `AutosaveInterval` (120 s), espalhado entre jogadores; save ao sair
  (libera a trava); **BindToClose** salva todos em paralelo (até 25 s).
- **Retry/backoff**: `MaxAttempts` tentativas com espera `RetryBaseDelay * 2^n`.
- **Corrupção**: valor ilegível vai para `Meta.CorruptBackup` (nunca descartado) + log de erro;
  campos com tipo errado voltam ao padrão (log); campos desconhecidos são mantidos.
- **Versão do futuro** (save mais novo que o servidor): não carrega e não grava.
- **Studio sem API**: perfil temporário, nada salvo, aviso na tela.
- **Falha no jogo publicado**: o jogador é desconectado com mensagem (melhor que jogar sem salvar).

## Como mudar o schema (futuro)

1. Aumente `DataConfig.SchemaVersion` e `Template.Version`.
2. Adicione os campos novos no `Template` (campos simples já são completados sozinhos).
3. Para transformações (renomear, converter), escreva `Migrations[N]` em
   `Server/Core/Migrations.luau`. Nunca apague migrações antigas.
4. Adicione um teste em `tests/ProfileCore.spec.luau`.
