# RNG — Roll Legends

Todo sorteio acontece **no servidor** (`Server/Services/RollService.luau`) com `Random.new()`
do servidor e o módulo puro `Shared/Modules/RollCore.luau` (testado fora do Roblox).
O cliente só envia `RequestRoll()` **sem argumentos** — nunca raridade, luck, personagem ou valores.

## Raridades (`Shared/Config/RarityConfig.luau`)

| Raridade (PT) | Id | Tier | Peso base | % com Luck 1 | 1 em | LuckExponent |
|---|---|---:|---:|---:|---:|---:|
| Comum | Common | 1 | 55 000 | 55% | 2 | 0 |
| Incomum | Uncommon | 2 | 25 000 | 25% | 4 | 0,35 |
| Raro | Rare | 3 | 12 000 | 12% | 8 | 0,70 |
| Épico | Epic | 4 | 5 000 | 5% | 20 | 1,00 |
| Lendário | Legendary | 5 | 2 000 | 2% | 50 | 1,30 |
| Mítico | Mythic | 6 | 750 | 0,75% | 133 | 1,55 |
| Divino | Divine | 7 | 200 | 0,2% | 500 | 1,75 |
| Secreto | Secret | 8 | 50 | 0,05% | 2 000 | 1,90 |

Os pesos somam 100 000 (peso ÷ 1000 = % com Luck 1).

## Fórmula da Luck

```
pesoEfetivo(r) = Weight(r) × Luck ^ LuckExponent(r)          (Luck < 1 é tratada como 1)
chance(r)      = pesoEfetivo(r) / Σ pesoEfetivo
```

- Comum tem expoente 0: a Luck **nunca aumenta** comuns, só os dilui.
- Expoentes crescem com o tier ⇒ quanto mais rara, mais a Luck ajuda (ganho relativo
  cresce com o tier — teste `RollCore.spec`).
- Exemplos (teórico): Luck 2,0 → Lendário 3,96%, Secreto 0,15%; Luck 10,4 (máximo:
  Celestial 4,0 × (1 + 20 × 8%)) → Lendário 13,5%, Secreto 1,37%.

**Luck efetiva** (`Formulas:luck`): `LuckDoDado × (1 + nívelLuck × 0,08) × boostAtivo`.
Dados: Normal 1,0 · Lucky 1,25 · Flame 1,6 · Storm 2,0 · Void 2,75 · Celestial 4,0 ·
Prism 2,25 (exclusivo do Diário). Boost do Diário: 1,5x (10 min) e 2x (15 min).

## Pity (`RollConfig.Pity`)

| Regra | Garante | Limite |
|---|---|---:|
| Legendary | Lendário ou melhor | 50 |
| Mythic | Mítico ou melhor | 250 |

- Contador = rolls seguidos **sem** tirar `MinRarity` ou melhor. Ao chegar em `limite − 1`,
  o próximo roll sorteia **só entre as raridades ≥ MinRarity** (mantendo as proporções entre elas).
- Se as duas regras disparam juntas, vence a de **maior** raridade.
- Tirar a raridade zera o contador dela (e de regras menores). Contadores salvos em `Pity`.

## Escolha do personagem

Depois da raridade, um personagem daquela raridade é sorteado com chance igual entre eles
(lista em ordem estável). **Odds exibidas no reveal ("1 EM X")**: chance BASE do personagem
(raridade com Luck 1 ÷ nº de personagens da raridade). Decisão: mostrar sempre a base, que é
consistente entre jogadores; a Luck usada aparece ao lado no Divino/Secreto.

## Fluxo do servidor (RequestRoll)

1. Jogador e dados carregados.
2. Cooldown: `Formulas:rollCooldown` (1,0 s → mínimo 0,45 s pelo upgrade) com folga de 0,06 s.
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
