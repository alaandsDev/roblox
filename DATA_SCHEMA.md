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
| `Version` | number | Versão do schema (= `DataConfig.SchemaVersion` = 4) |
| `Money`, `Gems`, `RebirthTokens` | number | Moedas |
| `Rolls`, `Rebirths` | number | Contadores |
| `EquippedDice` | string | Dice SELECIONADO para rolar (SelectedDiceId; padrão `"Starter"`). O servidor valida a cada roll (existe, sorteável, desbloqueado); inválido → Starter |
| `OwnedDice` | map | `{ [diceId] = true }` — Dice desbloqueados (Starter sempre). Migração v3: `Normal` → `Starter` |
| `DiceRolls` | map | `{ [diceId] = n }` — rolls NATURAIS feitos com cada Dice (Prisma/prêmios não contam). Libera o próximo Dice (`UnlockRequirement.RollsOnPrevious` = 60). Perfis antigos começam vazio (Template) |
| `PrismCharges` | number | Usos guardados do Prisma da Coleção (padrão 0; vem do Diário, Dia 7). Campo novo sem migração: o Template completa perfis antigos |
| `PrismLastUsedAt` | number | `os.time` do último uso do prisma (intervalo `PrismConfig.CooldownSeconds`) |
| `Inventory` | map | `{ [uid] = CharacterInstance }` (abaixo) |
| `NextUid` | number | Próximo uid (`"c" .. NextUid`); nunca diminui, nunca repete |
| `EquippedCharacters` | map | `{ [tostring(slotId)] = uid }` (chave string: compatível com JSON) |
| `Index` | map | `{ [characterId] = { Count, FirstAt, Variants? } }` — `Variants = { [variantId] = true }` é opcional (saves antigos válidos sem migração) |
| `IndexRewards` | map | `{ ["25"] = true, ... }` marcos já pagos |
| `Upgrades` | map | `{ Luck, Income, RollSpeed, Inventory }` níveis das melhorias GLOBAIS |
| `TowerProgress` | map | Maior andar por torre (fase futura) |
| `Pity` | map | `{ Legendary, Mythic }` rolls desde a raridade |
| `UncollectedMoney` | number | Renda no coletor da base |
| `LastKnownIncomePerSecond` | number | Renda/s da base (base do dinheiro offline) |
| `PendingOfflineReward` | number | Dinheiro offline calculado e ainda não resgatado |
| `LastDailyClaim`, `DailyStreak`, `DailyCycleDay` | number | Diário (os.time do servidor, sequência, último dia do ciclo 0–7) |
| `Boosts` | map | `{ Luck = { Multiplier, ExpiresAt } }` |
| `Tutorial` | number | passos do tutorial concluídos (0..7; 7 = terminado). Só avança (`SetTutorialStep`); jogadores com 50+ rolls pulam |
| `RevealViews` | map | `{ [rarity] = vezes }` (libera PULAR na cinemática) |
| `Settings.AutoRoll`, `HideRollAnimation`, `CameraShake`, `ReducedEffects` | boolean | Configurações do cliente |
| `Settings.AutoSell` | map | `{ Common..Divine = boolean }` (Secreto nunca) |
| `TowerTeam` | lista | Até 5 uids do time da torre (vazio = automático) |
| `RebirthPerks` | map | `{ [perkId] = nível }` (loja de fichas) |
| `Missions` | map | `{ Day, Daily = { [id] = { Progress, Claimed } }, Achievements = { [id] = nível } }` |
| `Runtime` | map | Multiplicadores da sessão (gamepasses, amigos). **Zerado a cada entrada e recalculado pelo BoostService** — nunca confiável |
| `Settings.Music` | boolean | Música de fundo (padrão desligada) |
| `Daily` | map | Reservado (legado) |
| `ProcessedReceipts` | lista | Últimos PurchaseIds entregues (idempotência). **Privado**: nunca vai ao cliente |
| `LastLogout` | number | "Visto por último": saída do jogador e a cada 30 s (os.time do servidor) |
| `CreatedAt`, `LastSave` | number | `os.time()` do servidor |

### CharacterInstance (`Inventory[uid]`)

| Campo | Tipo | Descrição |
|---|---|---|
| `Id` | string | `CharacterConfig` id |
| `Level` | number | Nível da estação (1..CharacterLevelConfig.MaxLevel = 30) |
| `UpgradeInvestment` | number? | Dinheiro efetivamente pago em níveis por ESTA instância. Só o servidor escreve: upgrade soma o custo cobrado; fusão grava na unidade nova a soma das consumidas; troca copia. Venda = base + 75% disso (SaleCore). Ausente = save antigo → soma da curva oficial do nível |
| `Variant` | string | `Normal` (Silver/Gold/Diamond/Emerald/Void/Celestial preparadas em VariantConfig) |
| `Locked`, `Favorite` | boolean | Proteções contra venda |
| `ObtainedAt` | number | os.time do servidor |

### Migração v1 → v2 (`Server/Core/Migrations.luau`)

Unidades antigas ganham `Level = 1`, `Variant = "Normal"`, flags booleanas; itens inválidos são
removidos; `NextUid` fica acima do maior uid existente; slots apontando para uids inexistentes
são limpos. Os campos novos vêm do Template (reconcile). Teste: `tests/Migrations.spec.luau`.

### Migração v3 → v4 (investimento por instância + cap de nível 30)

Para cada unidade com `Level > 1` e sem `UpgradeInvestment` válido: grava a soma EXATA da curva
oficial (`SaleCore.curveInvestment`) do nível 1 até o nível SALVO — o que o jogador pagou. Depois,
nível acima de 30 vira 30 (o investimento histórico continua gravado: venda e fusão o reconhecem).
Nenhum dinheiro é concedido na migração; rodar de novo não muda nada (valor já gravado é mantido).
A curva vem de `Migrations.Context` (injetado pelo PlayerDataService); sem contexto a migração não
corta nem grava, e o fallback do SaleCore recalcula pela curva no nível salvo.

Política de investimento:

| Fluxo | Instância que fica | Investimento | Nível |
|---|---|---|---|
| Upgrade | a mesma | + custo cobrado (`TrySpend`) | + níveis comprados |
| Fusão | nenhuma das consumidas: nasce UMA nova (uid novo, variante seguinte) | soma das consumidas, uma vez cada (uid repetido é recusado; custo da fusão NÃO entra) | maior entre as consumidas |
| Troca | a mesma unidade com uid novo no outro jogador | copiado | copiado |
| Venda | removida na mesma operação | `floor(75% × investido)` volta junto da base | — |

### Migração v2 → v3 (16 Dice por pool)

`OwnedDice`/`EquippedDice`: o id `Normal` vira `Starter` (o primeiro Dice, grátis); os outros
ids antigos continuam (Lucky, Flame, Storm, Void, Celestial = âncoras; Prism = exclusivo do
Diário). `Starter` sempre desbloqueado; `EquippedDice` inválido → `Starter`. Contadores de
`Pity` mantêm o formato (`Legendary`, `Mythic`). Personagens antigos (24 legados) no inventário
continuam válidos (ficam em `CharacterConfig.ById`), só não são mais sorteados nem contam no Índice.

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

## Tamanho do save (auditoria)

`tests/DataSize.spec.luau` monta um perfil de FIM DE JOGO (600 personagens nível 50
Celestiais, Índice completo, 40 slots, 3 torres completas, 100 recibos, missões) e mede o
JSON: **≈ 79 KB** (limite do DataStore: 4 MB por chave → ~2% do limite). O teste falha se
passar de 256 KB.

## Como mudar o schema (futuro)

1. Aumente `DataConfig.SchemaVersion` e `Template.Version`.
2. Adicione os campos novos no `Template` (campos simples já são completados sozinhos).
3. Para transformações (renomear, converter), escreva `Migrations[N]` em
   `Server/Core/Migrations.luau`. Nunca apague migrações antigas.
4. Adicione um teste em `tests/ProfileCore.spec.luau`.
