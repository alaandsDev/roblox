# MONETIZATION — Roll Legends

Todos os IDs ficam em `src/shared/Config/MonetizationConfig.luau`. **Id = 0 = ainda não criado**:
a compra é recusada com o aviso "Este item ainda não está à venda" (nada quebra).

## Como ativar (Creator Hub)

1. Publique o jogo. Em *Creator Hub > Monetização*:
   - **Passes**: crie VIP, Sorte x2, Mochila Gigante, Roll Rápido.
   - **Produtos de desenvolvedor**: Pacote de Dinheiro, Cofre de Dinheiro, Super Sorte 2x,
     Giro do Jackpot, 500 Gemas.
2. Copie cada ID para o campo `Id` correspondente e confira se `PriceRobux` é igual ao preço
   definido lá (o valor só é usado para MOSTRAR na loja).
3. Rode `python tools\run_tests.py` (o teste recusa IDs repetidos) e faça o build.

## O que cada item faz (servidor)

| Chave | Tipo | Efeito |
|---|---|---|
| VIP | Gamepass | Renda x1.5, sorte x1.1 |
| LuckX2 | Gamepass | Sorte x2 |
| BigBackpack | Gamepass | +100 espaços na mochila |
| FastRoll | Gamepass | Cooldown do roll x0.85 (o mínimo seguro continua valendo) |
| MoneySmall | Produto | max($10K, 15 min de renda) |
| MoneyLarge | Produto | max($150K, 2 h de renda) |
| LuckBoost | Produto | Sorte 2x por 30 min (soma tempo se repetido; auditoria: era 3x) |
| JackpotSpin | Produto | 1 giro do Jackpot |
| Gems500 | Produto | 500 gemas |

Gamepasses viram multiplicadores de sessão em `data.Runtime` (BoostService), recalculados a
cada entrada (o valor salvo nunca é confiado). O **Impulso de Amigos** (+5% de renda por amigo
no mesmo servidor, até +25%) também entra aí.

## Limite de pay-to-win (auditoria)

Com a Luck saturando (ver RNG.md), pagar **não multiplica Secretos**: jogador F2P no máximo
(cenário F) ≈ **0,36 Secreto/h**; o mesmo jogador com VIP + Sorte x2 + Roll Rápido + Super
Sorte 2x (cenário G) ≈ **0,40 Secreto/h** (+11%). Os passes valem pela velocidade no começo
(Luck 1→2 quase dobra as chances) e pela renda, não por Secretos infinitos.
`tests/Odds.spec.luau` falha se G passar de 1,25× F ou de 1 Secreto/h.

## Gemas

Fontes: Diário, Índice, Torres, Missões, produto Gems500. Uso: **Loja de gemas** — Giro do
Jackpot (150), Sorte 2x por 10 min (60), dinheiro rápido (40).

## Giro do Jackpot (`JackpotConfig.luau`)

Chances mostradas na própria loja (transparência): dinheiro (10 min / 1 h de renda), 100 / 400
gemas, sorte 2x 15 min, personagem garantido Épico+ (12%), Lendário+ (5%), Mítico+ (1%).

## Segurança

- O cliente só pede `RequestPurchase(chave)`; o servidor abre a janela do Roblox.
- Produtos entregues no `ProcessReceipt` com idempotência (`ReceiptCore`): a mesma compra nunca
  é entregue duas vezes, e o perfil é salvo antes de confirmar ao Roblox.
- Gamepass comprado durante a sessão é confirmado com `UserOwnsGamePassAsync` antes de liberar.
- Gemas: gasto conferido e descontado no servidor antes do prêmio.

## Testar no Studio sem IDs

```
_G.D:Invoke("GrantPass", _G.P, "VIP")
_G.D:Invoke("DeliverProduct", _G.P, "JackpotSpin")
_G.D:Invoke("GiveGems", _G.P, 1000)
```
