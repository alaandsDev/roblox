# Segurança — Roll Legends

## Server-authoritative

O cliente **nunca** decide: dinheiro, gems, resultado de roll, personagem recebido,
recompensas de torre, dano, entrega de compra, rebirth, valor de venda.
O cliente envia **intenções** (`RequestRoll()`, `RequestSellCharacter({uid})`…); o servidor
valida o estado e calcula tudo. Não existe remote do tipo `GiveMoney(amount)`.

## Toda entrada do cliente é validada (`Net` + `Validator`)

- Tipo de cada argumento, intervalos numéricos, inteiros, NaN/infinito rejeitados.
- Strings com tamanho máximo (padrão 64) e UTF-8 válido; `enum` quando há valores fixos.
- Listas sem buracos, com tamanho máximo e itens validados.
- Argumentos extras são rejeitados.
- O handler ainda deve checar **posse e estado** (ex.: o personagem é do jogador? está travado?).

## Rate limiting

Token bucket por jogador + remote (`Definitions.rate = { capacity, refill }`). Excesso
devolve `rate_limited` sem executar o handler. Os baldes são limpos quando o jogador sai.

## Erros

Handlers rodam em `pcall`: um erro vira `internal` para o cliente e log com stack trace no
servidor, sem derrubar o servidor nem vazar detalhes.

## Dados

Ver `DATA_SCHEMA.md` (UpdateAsync, session lock, backup de corrupção). Campos privados
(`ProcessedReceipts`) não são enviados ao cliente.

## Monetização

- IDs só em `MonetizationConfig.luau`.
- O cliente não informa compras: só pede para abrir a janela (`RequestPurchase(chave)`).
- `ProcessReceipt` idempotente: PurchaseId registrado no perfil e salvo antes de confirmar.
- Gamepass comprado é reconfirmado com `UserOwnsGamePassAsync`.

## Assets externos (Creator Store)

1. Buscar com `tools/FindAssets.lua` (remove scripts, filtra pelo nome).
2. Antes de usar: conferir o criador; abrir e procurar `require(<número>)`, `loadstring`,
   `getfenv`, código ofuscado, RemoteEvents estranhos.
3. Usar de preferência só MeshPart/Part/Texture/Decal/SurfaceAppearance/Sound/ParticleEmitter.
4. Em runtime, sempre carregar por `AssetLoader` (remove scripts de novo e desliga física).
5. Auditoria do `assets/Assets.rbxm`: converter para XML com o Rojo e contar classes
   (feito na FASE 1: 0 scripts).


## Auditoria dos remotes de gameplay

O cliente **nunca** envia raridade, luck, personagem, preço, nível, renda, custo ou valor.
Todos passam por rate limit + `Validator` (tipos, tamanhos, enums) antes do handler.

| Remote | Argumentos | Validação no servidor |
|---|---|---|
| RequestRoll | nenhum | dados carregados; cooldown por jogador (`Formulas:rollCooldown` − 0,06 s); inventário cheio antes de sortear; Random do servidor |
| EquipCharacter | uid, slot? (int 1–64) | dono do uid; slot liberado pela progressão (RB0 = 1–4); slot livre; não duplica |
| UnequipCharacter | uid | uid equipado do próprio jogador |
| EquipBest | — | só slots liberados; ordem por renda/power calculada no servidor |
| SetCharacterFlag | uid, enum Locked/Favorite, bool | dono do uid |
| UpgradeCharacter | uid, quantidade? (int 1–100) | dono; equipado; nível < máximo; custo calculado no servidor; saldo; sem yield (spam não duplica) |
| SellCharacter | lista de uids (≤ 500) | dono; nunca travado/favorito/equipado; preço do servidor |
| SellBatch | enum de modo, bool confirmar | seleção e preço no servidor; protegidos nunca entram |
| SetAutoSell | enum Common..Divine, bool | Secret nem existe no enum e é recusado de novo no handler |
| BuyDice | id | existe; não exclusivo; não possui; requisito (rolls + anterior); saldo |
| EquipDice | id | possui o dado |
| BuyUpgrade | enum | nível < máximo; custo do servidor; saldo |
| CollectMoney | — | perto do coletor da PRÓPRIA base (14 studs); cooldown |
| ClaimOfflineReward | — | valor calculado no servidor na entrada; zera antes de pagar (2º pedido = nada) |
| GetDailyStatus / ClaimDaily | — | relógio do servidor (UTC); estado gravado antes de entregar; spam = `already_claimed` |

Prompts do mapa (coletor, melhorias, pads de estação) conferem se o prompt pertence à base
do jogador. Dinheiro offline e diário validam timestamps (NaN, infinito, futuro, negativo).
DevService (Barra de comandos) só existe no Studio.
