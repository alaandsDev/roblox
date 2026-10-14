# HUD — design system icon-first

Tokens em `src/client/UI/UITheme.luau` (`Hud`, `ButtonSizes`), componentes em `src/client/UI/UIKit.luau`.
Nenhuma tela desenha botão "na mão": tudo passa por estes componentes.

| Componente | API | Visual |
|---|---|---|
| HUDIconButton | `UIKit.iconButton(parent, opts)` | área de toque grande e INVISÍVEL; chip compacto (68% da largura) colorido com o ícone, brilho no topo; rótulo curto embaixo |
| HUDPrimaryButton | `iconButton` com `primary = true` | chip maior (84%), aro dourado — só o ROLAR |
| NotificationBadge | `UIKit.badge(botão)` → `set(texto?)` | bolinha 22 px no canto do CHIP; números alargam em pílula; o botão não cresce |
| CurrencyDisplay | `UIKit.currency(parent, opts)` | pílula escura translúcida + chip redondo do ícone + valor (dinheiro, gemas, sorte) |
| NavButton | `NavigationController` | pílula escura translúcida com chip colorido (CENTRO / CASA / LOJA) |
| Tooltip | — | não necessário: todo botão tem rótulo curto |

Estados: Default · Hover (escala 1,06) · Pressed (0,92) · Disabled (`UIKit.setDisabled`: chip cinza,
rótulo apagado, sem clique) · Notification (badge).

Hierarquia (mantida): **baixo centro** MOCHILA · **ROLAR** (primário) · MELHORIAS; **topo centro**
navegação; **esquerda** LOJA · RENASCIMENTO · ÍNDICE · MISSÕES; **direita** monetização (VIP, sorte,
Jackpot — 96 px, não cobre o centro); **topo direita** OFFLINE · DIÁRIO · ⚙️ (icon-first, 74 px);
**baixo esquerda** moedas em pílulas.

Responsivo: layout `wide` / `compact` / `portrait` (HudController.Layout) e `ScreenInsets =
DeviceSafeInsets`; toques ≥ 44 px (ClientHarness confere); o centro da tela fica livre.
