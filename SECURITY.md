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

| RequestEnterTower | id da torre | torre existe e liberada; luta só o próximo andar; cooldown; time só com uids do jogador; batalha e semente no servidor |
| SetTowerTeam | lista de uids (≤ 5) | dono de cada uid; sem repetidos |
| Rebirth | — | custo do servidor; saldo; tudo sem yield (dois pedidos não renascem duas vezes) |
| BuyRebirthPerk | enum | nível < máximo; fichas suficientes |
| Fuse | 3 uids | dono, não protegidos, iguais (personagem + variante), variante não máxima, dinheiro |
| RequestTrade / RespondTrade | userId (+ bool) | jogador no servidor, não é você, ninguém já em troca, convite válido por 30 s |
| SetTradeOffer | uids (≤ 8) | dono, não protegidos, sem repetidos; muda a versão e tira o PRONTO dos dois |
| ConfirmTrade | — | os dois PRONTOS e confirmando a MESMA versão; revalida tudo e troca de forma atômica (capacidade dos dois lados) |
| ClaimMission | enum, id | missão do jogador no dia; completa; marcada antes de pagar |
| SpinJackpot / BuyGemItem | — / id | gemas descontadas antes do prêmio; prêmio sorteado no servidor |
| RequestPurchase | chave | só chaves da MonetizationConfig; ID 0 = recusado; entrega pelo ProcessReceipt idempotente |

Trocas: os dois perfis estão sob trava de sessão neste servidor, então mover itens na memória e
salvar os dois em seguida não permite duplicação entre servidores.

Prompts do mapa (coletor, melhorias, pads de estação) conferem se o prompt pertence à base
do jogador. Dinheiro offline e diário validam timestamps (NaN, infinito, futuro, negativo).
DevService (Barra de comandos) só existe no Studio.

## Auditoria pré-Studio — casos de borda (testados no `GameplayHarness`)

| Sistema | Caso | Resultado |
|---|---|---|
| Troca | item oferecido vendido / vendido em lote / equipado / EQUIPAR MELHORES / fundido | recusado (`in_trade`); trava só em memória, some ao fechar a troca |
| Troca | oferecer item do outro jogador, item repetido, acima de 8 | `not_owned` / `trade_duplicate` / `trade_too_many` |
| Troca | mudar a oferta depois de confirmar | os dois perdem PRONTO; confirmação antiga não vale (versão) |
| Troca | confirmar 2× sozinho (spam) | só "aguardando"; nada se move |
| Troca | item some antes do commit | troca recusada, nada muda, PRONTO zerado |
| Troca | 2ª troca com quem já está trocando | `trade_busy` |
| Troca | jogador sai no meio | sessão fecha ("left"), o outro fica com os itens livres; convite de quem saiu é inválido |
| Troca | destinatário sem espaço | `trade_full_a/b` (TradeCore.spec) |
| Troca | confirmação simultânea | o commit não tem `yield`: valida tudo dos dois lados e move de uma vez (atômico) |
| Fusão | uid repetido, inexistente, personagens diferentes, favorito, equipado, em troca, tipos inválidos | recusado |
| Fusão | spam do mesmo pedido | só o 1º vale (`not_owned` depois) |
| Renascimento | 2 pedidos seguidos com dinheiro para 1 | só 1 vale (`not_enough_money`) |
| Torre | torre inexistente / bloqueada / completa / spam | `invalid_tower` / `tower_locked` / `tower_complete` / `cooldown`; recompensa só no 1º clear de cada andar |
| Compras | mesmo recibo repetido, falha no save, erro na entrega | idempotente (`ReceiptCore.spec`): nunca entrega 2× |

Risco residual conhecido: se o servidor cair entre o commit da troca e o save dos dois
perfis (`SaveNow` é disparado logo depois), um dos lados pode voltar ao estado anterior.
O DataStore não tem transação entre duas chaves; a janela é de poucos segundos.
