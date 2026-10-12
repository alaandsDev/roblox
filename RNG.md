# RNG — Roll Legends

Todo sorteio acontece **no servidor** (`Server/Services/RollService.luau`) com `Random.new()`
do servidor e o módulo puro `Shared/Modules/RollCore.luau` (testado fora do Roblox).
O cliente só envia `RequestRoll()` **sem argumentos** — nunca raridade, luck, personagem ou valores.

## Raridades (`Shared/Config/RarityConfig.luau`)

| Raridade (PT) | Id | Tier | Peso base | % com Luck 1 | 1 em | LuckExponent |
|---|---|---:|---:|---:|---:|---:|
| Comum | Common | 1 | 5 613 450 | 56,1% | 2 | 0 |
| Incomum | Uncommon | 2 | 2 600 000 | 26% | 4 | 0,20 |
| Raro | Rare | 3 | 1 200 000 | 12% | 8 | 0,45 |
| Épico | Epic | 4 | 450 000 | 4,5% | 22 | 0,70 |
| Lendário | Legendary | 5 | 130 000 | 1,3% | 77 | 0,75 |
| Mítico | Mythic | 6 | 6 000 | 0,06% | 1 667 | 0,85 |
| Divino | Divine | 7 | 500 | 0,005% | 20 000 | 1,00 |
| Secreto | Secret | 8 | 50 | 0,0005% | 200 000 | 1,30 |

Os pesos somam 10 000 000. (Auditoria pré-Studio: antes Secreto era 1 em 2 000 e com Luck 174
saía ~740 Secretos por hora — ver tabela "antes/depois" no fim.)

## Fórmula da Luck (com retornos decrescentes)

```
Luck        = LuckDoDado × (1 + nívelLuck × 0,08) × boostAtivo × bônusRenascimento × passes
LuckEfetiva = 1 + (Luck − 1) / (1 + (Luck − 1) / LuckSoftCap)        LuckSoftCap = 10
pesoEfetivo(r) = Weight(r) × LuckEfetiva ^ LuckExponent(r)
chance(r)      = pesoEfetivo(r) / Σ pesoEfetivo
```

- `LuckEfetiva` nunca passa de 11 (Luck 2 → 1,91 · Luck 5 → 3,86 · Luck 10 → 5,74 ·
  Luck 40 → 8,8 · Luck 1000 → 10,9). Dobrar a Luck no fim do jogo rende pouco; no começo rende quase tudo.
- Comum tem expoente 0: a Luck **nunca aumenta** comuns, só os dilui. Expoentes crescem
  com o tier (teste `RollCore.spec`).
- Bônus de renascimento: +2% por renascimento, **teto +50%**; perk Sorte +5%/nível.
- Boosts temporários (Diário 1,5x/2x, produto Super Sorte 2x, Jackpot) não multiplicam entre si:
  vale o maior multiplicador ativo (o mesmo multiplicador soma tempo — `JackpotCore.mergeBoost`).
- Implementação: `RollCore:effectiveLuck` (servidor) e `Formulas:effectiveLuck` (HUD) — mesma fórmula.

Dados: Normal 1,0 · Lucky 1,25 · Flame 1,6 · Storm 2,0 · Void 2,75 · Celestial 4,0 ·
Prism 2,25 (exclusivo do Diário).

## Pity (`RollConfig.Pity`)

| Regra | Garante | Limite |
|---|---|---:|
| Legendary | Lendário ou melhor | 50 |
| Mythic | Mítico ou melhor | 800 |

- Contador = rolls seguidos **sem** tirar `MinRarity` ou melhor. No roll de número `limite`
  o servidor sorteia normalmente; se o resultado ficar abaixo do piso, entrega **exatamente
  o piso** (Lendário ou Mítico). O pity **nunca** gera Divino/Secreto — essas raridades só
  saem pela sorte natural (teste `Odds.spec`: 300 mil rolls com e sem pity têm o mesmo nº de Secretos).
- Mesma regra para presentes/grants (`RollService` → `core:pickWithFloor`).
- Se as duas regras disparam juntas, vence a de **maior** raridade.
- Tirar a raridade zera o contador dela (e de regras menores). Contadores salvos em `Pity`.

## Escolha do personagem

Depois da raridade, um personagem daquela raridade é sorteado com chance igual entre eles
(lista em ordem estável). **Odds exibidas no reveal ("1 EM X")**: chance BASE do personagem
(raridade com Luck 1 ÷ nº de personagens da raridade). Decisão: mostrar sempre a base, que é
consistente entre jogadores; a Luck usada aparece ao lado no Divino/Secreto.

## Fluxo do servidor (RequestRoll)

1. Jogador e dados carregados.
2. Intervalo: `RollConfig.RollSpeed` — **1 roll/s** (Roll Rápido: 2 rolls/s), validado no servidor sem folga e sem crédito (`nextRollAt` = último roll aceito + intervalo). Vale para manual, AUTO e OCULTAR.
3. Inventário cheio → recusa **antes** de sortear (`inventory_full`).
4. Luck → `RollCore:roll(luck, pity, Random)` → raridade, personagem, novo pity.
5. Rolls + 1, Index (NOVO?), contagem de reveals por raridade (libera PULAR).
6. Auto-sell (se ligado para a raridade e não for a primeira descoberta) ou inventário (uid).
7. Analytics, anúncio social (Mítico+), save em breve (Mítico+).
8. Resposta: `{ CharacterId, Rarity, Variant, Uid, IsNew, AutoSold, SoldFor, PityTriggered, Luck, TimesSeen, Odds }`.

## Simulação

`RNG_SIMULATION.md`: 1 000 000 rolls por cenário (sem Luck, Luck média, Luck alta, com pity),
gerado por `tools/sim/simulate_rng.luau`. O teste `RollCore.spec` também roda 1 000 000 rolls
e exige cada raridade dentro de 5 desvios-padrão do teórico.

## Velocidade do roll (cadência oficial)

| Situação | Intervalo mínimo | Rolls/min | Rolls/h (teórico, sem pausas) |
|---|---:|---:|---:|
| Normal (manual, AUTO, OCULTAR) | 1,0 s | 60 | 3.600 |
| Gamepass Roll Rápido | 0,5 s | 120 | 7.200 |

- Fonte única: `RollConfig.RollSpeed` (`BaseInterval`, `FastRollInterval`). Nada mais acelera:
  a melhoria "Velocidade de Roll" e o perk "Mãos Rápidas" ficam fora da loja enquanto
  `UpgradesAffectInterval = false` (níveis antigos no save são ignorados, sem migração).
- Servidor: `nextRollAt[jogador] = agora + intervalo` a cada roll ACEITO; pedido antes disso =
  `cooldown`. Sem folga de rede e sem crédito: ficar 5 s sem resposta e mandar 5 pedidos juntos
  rende 1 roll. Testes: `GameplayHarness` (relógio simulado: spam 100/s, 240 FPS, macro, latência,
  Roll Rápido) e `ClientHarness` (AUTO, OCULTAR, Roll Rápido e cinemática pausando o AUTO).
- Cinemáticas (Lendário+) continuam pausando o AUTO pelo tempo inteiro delas: 1 roll/s é a
  cadência MÁXIMA, sessões reais rendem menos.
- Prêmios (Jackpot/produtos) que entregam personagem não usam o intervalo do roll: têm custo e
  limite próprios.
