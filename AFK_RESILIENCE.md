# AFK Resilience: resiliência de sessão

Isto **não** é um "anti-AFK". O jogo nunca gera input, nunca simula atividade, não usa VirtualUser nem input falso de mouse/teclado, não mexe na CoreGui e não tenta contornar o timeout de inatividade do Roblox. O objetivo é outro: quem fica parado com o AUTO ligado continua jogando como sempre, e, se a sessão cair, nada se perde nem duplica. Quando a plataforma permite, o jogador volta por APIs oficiais.

**AFK não é buff nem penalidade.** Ficar parado não dá Luck, multiplicador de dinheiro, velocidade de roll, pity nem recompensa extra. O teste estático do `AfkHarness` garante que nenhuma fórmula ou serviço de jogo lê o estado AFK.

## 1. Arquitetura

| Peça | Onde | O que faz |
|---|---|---|
| `AfkConfig` | `Shared/Config` | Limiares: Idle após 120 s; reporte de atividade a cada ≥ 15 s; timeout da plataforma (~20 min, só para documentação); reconexão (3 tentativas, espera 3/10/30 s, 3 cliques, cadeia máxima 2); janela de 10 min para o AUTO voltar. |
| `AfkCore` (puro) | `Shared/Modules` | Estado de **um** jogador: `Active` / `Idle` / `Reconnecting`. `simulateIdle` só altera o relógio interno. |
| `ReconnectPolicy` (puro) | `Shared/Modules` | Classifica a queda (`Auto` / `Manual` / `Never`) e define as tentativas com limite, espera e "mesmo servidor só na 1ª". Também guarda o encadeamento entre reconexões e a regra `resumeAuto`. |
| `AfkService` | servidor | Recebe `ReportActivity` (input real), publica o atributo `AfkState` no Player e registra na Analytics `AfkIdle`/`AfkActive`/`Reconnected`/`AutoResumed`. Mantém a sessão (é reconexão? de qual servidor?) e envia `ResumeAuto` **uma vez** quando tudo fica pronto. Comandos DEV. |
| `SessionController` | cliente | Envia `ReportActivity` em input real (com limite), mostra o indicador "💤 AFK" e liga o AUTO ao receber `ResumeAuto`. Detecta a queda (`GuiService.ErrorMessageChanged`) e tenta reconectar via `TeleportService` com limite, mostrando o botão RECONECTAR. |
| `PlayerDataService` | servidor | Saída idempotente. Espera a trava do servidor antigo na entrada. `OnBeforeSave`, `SessionInfo`, `SaveStats`. |
| `EconomyService` | servidor | `OnBeforeSave`: `LastLogout = agora` em todo save (protege contra pagar o offline duas vezes). |
| `RollController` | cliente | A escolha do jogador no AUTO vai para `Settings.AutoRoll`. `ResumeAuto()`, `IsAuto()`, `IsReady()`. |

## 2. O que acontece quando o jogador fica parado

- Depois de 120 s sem input real, o estado passa a `Idle`. Aparece o indicador "💤 AFK" ou "💤 AFK · AUTO ligado", e a Analytics registra `AfkIdle`. Os rolls do AUTO **não** contam como atividade.
- O AUTO continua se estava ligado. O mesmo vale para a renda da base (Tick central), os timers (boosts, diário, Prisma) e o autosave a cada 120 s. Tudo continua no servidor.
- A cadência não muda: **1 roll/s** normal e **0,5 s** com Roll Rápido, validada no servidor (`nextRollAt = último aceito + intervalo`). Não há crédito, rajada, catch-up nem rolls retroativos. Medido com tempo virtual:

  | Situação | Resultado |
  |---|---|
  | 20 min de AFK + AUTO | 1201 rolls em 1200 s, menor intervalo 1,000 s |
  | Roll Rápido | 121 rolls em 60 s, menor intervalo 0,500 s |
  | Pausa de 5 min e volta | 1 roll no 1º segundo |
  | 50 pedidos no mesmo instante | 1 roll |

## 3. Perto do timeout real (~20 min sem input)

Quem decide é o **Roblox**: o cliente é desconectado com "Desconectado por inatividade". O jogo não evita isso, não envia input e não reconecta sozinho. A queda `DisconnectIdle` é classificada como `Never`. Se o cliente ainda conseguir desenhar algo, o jogo só mostra um aviso claro. O diálogo do próprio Roblox (Reconectar/Sair) fica por conta da plataforma.

Até o momento da desconexão, o AUTO seguiu rolando e o servidor salvou a cada 120 s. A saída dispara o save final (ver §6).

## 4. Quedas que o jogo consegue detectar

- **Servidor:** `PlayerRemoving` (saída, queda de conexão percebida pelo servidor, kick) dispara o save final e libera a trava. Em `BindToClose` (servidor desligando, atualização), todos são salvos em até 25 s.
- **Cliente:** `GuiService.ErrorMessageChanged` + `GetErrorCode()` (Enum.ConnectionError). Com isso classificamos:
  - **Auto:** quedas de rede, como `DisconnectConnectionLost`, `DisconnectTimeout` e erros de pacote/Raknet. Também o servidor sendo encerrado: `DisconnectEvicted`, `DisconnectDevMaintenance`.
  - **Never:**
    - inatividade da plataforma (`DisconnectIdle`);
    - o próprio jogo expulsou (`DisconnectLuaKick`: save travado/indisponível, versão de save nova);
    - conta duplicada;
    - saída voluntária;
    - segurança/versão;
    - manutenção do Roblox.
  - **Manual (só o botão):** qualquer código desconhecido.
- `TeleportService.TeleportInitFailed`: falha de cada tentativa.

## 5. Quedas que o jogo NÃO controla, em que nenhum código roda

- O app foi fechado, travou ou o sistema o encerrou (celular em segundo plano, falta de memória).
- O dispositivo perdeu a rede de vez, ou o cliente caiu antes de rodar o evento.
- O processo do servidor caiu (crash) sem `BindToClose`. Nesse caso vale o **último autosave**: até 120 s de progresso podem voltar atrás, mas **nunca duplicam** (ver §10).
- O diálogo de desconexão do Roblox e o botão "Reconectar" dele.
- O Teleport depois de uma queda é **best-effort**: em parte das quedas o cliente não consegue mais chamar o TeleportService. Nesse caso, o jogador volta pelo botão do Roblox ou entrando de novo.

## 6. Estratégia de save (auditoria B3)

| Momento | Antes | Agora |
|---|---|---|
| Autosave | a cada 120 s, espalhado | igual (independe de input; AFK continua salvando) |
| PlayerRemoving | save + libera trava | igual, agora **idempotente** |
| BindToClose | save de todos, 25 s | igual; sem save duplicado com o PlayerRemoving (antes os dois salvavam juntos e o segundo dava aviso de "falha") |
| Rebirth / Daily / Missão / Fusão / Jackpot / Dice / Torre | `SaveSoon` (≤ 1 save a cada 8 s) | igual |
| Compra Robux | `SaveNow` + recibo idempotente | igual |
| Drop Mítico+ | `SaveSoon` | igual |
| Roll comum, venda, melhoria | só no autosave (o estado é sempre salvo junto, por instantâneo: nunca há meio-estado) | igual |
| **LastLogout** | só na saída (e a cada 30 s em memória) | **em todo save** (`OnBeforeSave`) |
| **Entrada com o perfil travado** (reconexão rápida) | 1 tentativa no Studio / ~15 s no jogo e expulsava | espera até **60 s** (a cada 5 s, com aviso "Recuperando seus dados…") e nunca assume a trava antes do timeout de 30 min |

Não há save por roll. Em 20 min de AFK com AUTO foram feitas **10 gravações**, o mesmo número de rodadas de autosave.

## 7. Estratégia de reconexão

A política vive em `ReconnectPolicy`; o `SessionController` só executa.

1. Queda `Auto`: espera 3 s e tenta o **mesmo servidor** (`TeleportToPlaceInstance(PlaceId, JobId)`). Isso só acontece se a queda não indica que o servidor está fechando e se o JobId é conhecido.
2. Uma falha (`TeleportInitFailed` ou nenhuma resposta em 30 s) tira o mesmo servidor da lista. As próximas tentativas vão para **qualquer servidor** do place (`Teleport(PlaceId)`), após 10 s e depois 30 s.
3. Com 3 tentativas automáticas esgotadas, aparece o botão **RECONECTAR**. Cada clique é input real e vale uma tentativa, no máximo 3 cliques com 5 s de intervalo. Depois disso: "Não foi possível reconectar automaticamente. Entre no jogo de novo."
4. `Unauthorized` para tudo na hora.
5. A `TeleportData` leva `{ Reconnect, Chain, FromJobId, At }`. Se o jogador já chegou por **2 reconexões automáticas seguidas** em até 10 min, a próxima queda só oferece o botão. Isso evita pular de servidor em servidor em loop.
6. A `TeleportData` vem do cliente e é tratada só como **dica de preferência**: ela nunca vale dinheiro, roll ou item.

Limite absoluto: **3 + 3 = 6 teleportes** por queda, testado com o teleporte falhando para sempre.

## 8. O mesmo servidor é possível?

**Nunca é prometido.** Ele só existe se o processo do servidor antigo ainda estiver vivo, o que é comum numa queda de rede do jogador e impossível quando o servidor está fechando. Além disso, o servidor precisa ter vaga. Se ele acabou, encheu ou recusou, a política cai para "qualquer servidor do place". Nesse caso o jogador perde os vizinhos de base e os rankings locais, mas nenhum dado: o save é o mesmo.

Se o servidor antigo ainda está salvando a saída, a entrada espera a trava (§6). O jogo nunca carrega o mesmo save em dois servidores.

## 9. AUTO depois de reconectar

- **Preferências auditadas:**
  - **Auto Roll** é persistido em `Settings.AutoRoll`. Mudam o valor apenas o clique do jogador e o inventário cheio, que desliga o AUTO.
  - **Ocultar**, efeitos, música e tremida já eram persistidos e voltam em qualquer entrada.
  - **Roll Rápido** é gamepass: o BoostService recalcula a cada entrada, então não é uma preferência.
  - **Estado transitório** (janela aberta, reveal em andamento, Torre, histórico de rolls) **não** volta.
- **Entrada normal:** o AUTO começa **desligado**, e o servidor limpa `Settings.AutoRoll`.
- **Reconexão:** o AUTO só volta quando **todas** as condições abaixo valem, e então o servidor envia `ResumeAuto` **uma vez**:
  - chegou com `TeleportData` de reconexão;
  - o AUTO estava ligado no save;
  - a saída foi há ≤ 10 min;
  - o **save carregou**, a **base foi atribuída**, o **personagem existe** e os **serviços estão prontos** (o runtime de boosts foi calculado, então o Roll Rápido já vale);
  - se a sessão não ficar pronta em 60 s, o AUTO não volta.
- Nunca rola antes do PlayerData: o servidor responde `not_ready`.
- A cadência continua a mesma (1 roll/s ou 0,5 s), sem roll "devido".

## 10. Proteção contra pagar o offline duas vezes (B6)

- `offlineDuration` começa no **último LastLogout salvo**. Agora todo save grava `LastLogout = agora` junto com a renda já acumulada. Por isso, o período produzido online e salvo nunca é pago de novo como offline.
- **AFK conectado → queda → volta 10 min depois:** o offline paga **só os 600 s fora** (teste: 1411 = 19,6/s × 600 × 12%), e não os 20 min de AFK online.
- **Crash do servidor entre saves:** o jogador volta ao estado do último save. O offline conta a partir dele. O trecho online que não chegou ao save foi perdido **junto** (dinheiro e LastLogout), então não há pagamento duplo. Antes da mudança, o LastLogout salvo podia estar até 30 s atrás do save, e essa diferença pagava um pouco em dobro.
- Tetos inalterados: 8 h, 12%, ≤ 25% do próximo renascimento. A economia não mudou.

## 11. Proteção contra roll e prêmio duplicados (B8)

- O roll é decidido e **gravado no servidor** antes da resposta (Rolls, Pity, Index, inventário com uid novo, auto-sell).
- A apresentação (reveal, Hero Landing, Jackpot Reveal) **não faz nenhum pedido ao servidor**, o que é verificado no código. Perder a apresentação numa queda não perde o prêmio, e repeti-la não dá outro.
- Uma reconexão não reenvia pedidos e o servidor novo não tem fila. Depois de sair e voltar (duas vezes), Money, Rolls, inventário, Index, Rebirth e NextUid estão idênticos ao save.
- O uid nunca volta (`NextUid` só cresce). Compras seguem idempotentes pelo `ProcessedReceipts`.
- Torre: não há retomada automática no meio de uma batalha. A sessão da torre é de memória e termina na saída, como antes.

## 12. Comandos DEV (Studio, contexto Servidor)

```lua
local Dev = game.ServerStorage.RollLegendsDev
local p = game.Players:GetPlayers()[1]
print(Dev:Invoke("AFKStatus", p))           -- estado, inatividade, Auto/Roll Rápido/Ocultar, último save, JobId, sessão
print(Dev:Invoke("SimulateIdle", p, 1200))   -- SÓ o estado interno (nenhum input gerado)
print(Dev:Invoke("SimulateActive", p))       -- volta para Active
print(Dev:Invoke("SimulateReconnect", p))    -- trata a sessão como reconexão: AUTO volta pelo caminho real
print(Dev:Invoke("ReconnectPlan", "DisconnectConnectionLost"))  -- o que o cliente faria (não teleporta)
print(Dev:Invoke("ReconnectPlan", "DisconnectIdle"))            -- Never
```

## 13. Teste manual de 20+ min

O roteiro está em `STUDIO_SMOKE_TEST.md`, seção **AFK RESILIENCE**.

## 14. Arquivos

- **Novos:**
  - `Shared/Config/AfkConfig.luau`
  - `Shared/Modules/AfkCore.luau`
  - `Shared/Modules/ReconnectPolicy.luau`
  - `Server/Services/AfkService.luau`
  - `Client/Controllers/SessionController.luau`
  - `tests/Afk.spec.luau`
  - `tests/roblox/AfkHarness.luau`
  - este documento
- **Alterados:**
  - `PlayerDataService`
  - `EconomyService`
  - `DevService`
  - `AnalyticsService` (eventos)
  - `Definitions` (`ReportActivity`, `ResumeAuto`)
  - `DataConfig` (`LockedJoinWait` / `LockedRetryDelay`)
  - `PtBR`
  - `RollController`
  - os dois Bootstraps
  - `ClientHarness` / `SessionHarness` (ORDER)
  - `tools/run_tests.py`
  - `STUDIO_SMOKE_TEST.md`
  - `ARCHITECTURE.md`
  - `DATA_SCHEMA.md`
- **Schema:** sem mudança de schema. `Settings.AutoRoll` já existia.

## 15. Desempenho

- **Servidor:** um loop de 1/s em O(jogadores) que só escreve o atributo quando o estado muda. `ReportActivity` chega no máximo a cada 15 s por jogador (rate limit de 0,2/s). Cada save ganha um hook O(1).
- **Cliente:** um loop de 1/s para o indicador e o envio de atividade com limite. Nada roda por frame.
- **DataStore:** nenhuma gravação extra. A entrada travada faz ≤ 12 leituras e só existe na reconexão.
