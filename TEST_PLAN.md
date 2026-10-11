# Plano de testes — Roll Legends

## 1. Automáticos (fora do Roblox)

`python tools\run_tests.py` roda o binário `luau` sobre `tests/run.luau` + checagem de textos.

| Arquivo | O que cobre |
|---|---|
| `tests/TableUtil.spec.luau` | deepCopy, deepEqual, **deep merge/reconcile** (ausentes, tipo errado, chaves desconhecidas, mapas dinâmicos, template intacto) |
| `tests/NumberFormatter.spec.luau` | sufixos K…Dc, truncamento, negativos, NaN/inf, milhar pt-BR, duração |
| `tests/RateLimiter.spec.luau` | capacidade, recarga, chaves independentes, relógio voltando |
| `tests/Validator.spec.luau` | **payload validation** (números, strings, UTF-8, enum, listas, extras, opcionais) + todas as definições de remotes válidas |
| `tests/ProfileCore.spec.luau` | **schema default**, **save/load**, **session lock** (bloqueio, liberação, trava velha, lock perdido não sobrescreve, renovação), **migrations futuras**, versão do futuro, retry/backoff, corrupção com backup |
| `tests/ReceiptCore.spec.luau` | **receipt idempotency** (duplicata, produto desconhecido, erro na entrega, save falhando + repetição sem reentregar, histórico limitado) |
| `tests/Config.spec.luau` | schema completo, consistência DataConfig × Definitions, Localization (formato, fallback) |

Também rodar antes de cada commit:
- `luau-lsp analyze` (checagem de tipos com definições do Roblox)
- `python tools\build_place.py` (build Rojo)

## 2. Manual no Roblox Studio — FASE 1 (fundação)

Preparação: `python tools\build_place.py` → abrir `build\RollLegends.rbxlx` →
Janela > Saída aberta.

| # | Teste | Como | Esperado |
|---|---|---|---|
| 1 | Boot | Play | Saída: `[Roll Legends][Bootstrap] Roll Legends v0.1.0 iniciado com 2 services` e `[ClientBootstrap] 2 controllers iniciados`. Nenhum erro vermelho |
| 2 | Perfil temporário (sem API) | Play sem acesso à API | Toasts "Bem-vindo ao Roll Legends!" e "Modo de teste: salvamento desativado…"; Saída: `perfil carregado: <nome> (novo: true, offline: true)` |
| 3 | Snapshot no cliente | Saída do cliente | `[DataController] dados recebidos do servidor (Money: 0 Rolls: 0 )` |
| 4 | Ler dados no servidor | Barra de comandos no contexto **Servidor**: `print(require(game.ServerScriptService.Server.Services.PlayerDataService).GetData(game.Players:GetPlayers()[1]).Money)` | `0` |
| 5 | Pedido válido | Barra de comandos no contexto **Cliente**: `print(require(game.ReplicatedStorage.Shared.Modules.Net).request("SetSetting","HideRollAnimation",true).ok)` | `true` |
| 6 | Payload inválido | Cliente: `print(require(game.ReplicatedStorage.Shared.Modules.Net).request("SetSetting","Money",true).code)` | `invalid_args` + aviso no servidor |
| 7 | Rate limit | Cliente: `local N=require(game.ReplicatedStorage.Shared.Modules.Net) for i=1,10 do print(i, N.request("SetSetting","AutoRoll",true).code) end` | primeiros `nil`, depois `rate_limited` |
| 8 | Request futuro | Cliente: `print(require(game.ReplicatedStorage.Shared.Modules.Net).request("RequestRoll").code)` | `not_implemented` |
| 9 | Compra sem ID | Cliente: `print(require(game.ReplicatedStorage.Shared.Modules.Net).request("RequestPurchase","LuckBoost").code)` | `not_configured` + toast "Este item ainda não está à venda." |
| 10 | Save/load real | Publicar, ativar API no Studio, Play, rodar #5, Stop, Play de novo, rodar #4 trocando `.Money` por `.Settings.HideRollAnimation` | `true` (persistiu); Saída: `perfil salvo e liberado` ao parar |
| 11 | Session lock real | No jogo publicado, entrar, sair e entrar de novo rápido em outro servidor | Entra normalmente (a trava é liberada ao sair); se o servidor antigo ainda estiver salvando, a mensagem `data.session_locked` aparece e na segunda tentativa funciona |
| 12 | BindToClose | Studio com API: Play e Stop | Saída mostra o save antes de fechar, sem aviso de timeout |

## 3. Futuras fases

Lista completa (bases, roll, auto roll, inventário cheio, venda, torres, rebirth, offline,
daily, gamepass, produto, falha de DataStore, reconexão, UI mobile…) será detalhada aqui
conforme cada fase entrar.
