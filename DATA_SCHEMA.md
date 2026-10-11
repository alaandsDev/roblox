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

## Perfil — versão 1 (`Shared/Config/DataConfig.luau`)

| Campo | Tipo | Descrição |
|---|---|---|
| `Version` | number | Versão do schema (= `DataConfig.SchemaVersion`) |
| `Money`, `Gems`, `RebirthTokens` | number | Moedas |
| `Rolls`, `Rebirths` | number | Contadores |
| `EquippedDice` | string | Dado equipado (`"Normal"`) |
| `Inventory` | map | Lutadores (formato definido na FASE 4) |
| `EquippedCharacters` | map/lista | Lutadores na base |
| `Index` | map | Lutadores descobertos |
| `Upgrades` | map | Níveis de melhoria |
| `TowerProgress` | map | Maior andar por torre |
| `Pity` | map | Rolls desde a última raridade |
| `Settings.AutoRoll` | boolean | |
| `Settings.HideRollAnimation` | boolean | |
| `Settings.AutoSell` | map | Raridades vendidas automaticamente |
| `Daily` | map | Recompensa diária |
| `ProcessedReceipts` | lista | Últimos PurchaseIds entregues (idempotência). **Privado**: nunca vai ao cliente |
| `LastLogout`, `CreatedAt`, `LastSave` | number | `os.time()` do servidor |

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
