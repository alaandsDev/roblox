# Auditoria — Renda por Dice (Dice × Raridade)

> Gerado por `python3 tools/sim/run_dice_income_audit.py report`. Pesos, pity, Luck e a
> distribuição dos 112 personagens F2P NÃO foram alterados (só BaseIncome).
> Simulação: simulador oficial `tools/sim/EconomyModel.luau`, 24 jogadores por perfil, 40 h de jogo ATIVO cada (offline entre sessões incluído).

## 1. Problema encontrado

Antes: o catálogo de lançamento usava **stats provisórios por raridade** (`gen_launch_catalog.py`,
`STATS`): todo Mítico rendia $160/s (o piloto Barbalva $170/s) em qualquer Dice, todo Lendário $60/s etc.
Grupos de mesma raridade com renda IGUAL entre Dice diferentes: **antes 7**, **depois 0**.

- antes: Common $1/s em 4 Dice (Starter, Lucky, Rampart, Shinobi)
- antes: Uncommon $4/s em 7 Dice (Starter, Lucky, Rampart, Shinobi, Flame, Blade, Fighter)
- antes: Rare $9/s em 10 Dice (Starter, Lucky, Rampart, Shinobi, Flame, Blade, Fighter, Storm, Spirit, Arcane)
- antes: Epic $25/s em 13 Dice (Starter, Lucky, Rampart, Shinobi, Flame, Blade, Fighter, Storm, Spirit, Arcane, Shadow, Void, Colossus)
- antes: Legendary $60/s em 11 Dice (Flame, Blade, Fighter, Storm, Spirit, Arcane, Shadow, Void, Colossus, Awakened, Celestial)
- antes: Mythic $160/s em 7 Dice (Spirit, Arcane, Shadow, Void, Colossus, Awakened, Celestial)
- antes: Divine $425/s em 3 Dice (Void, Celestial, Forbidden)

## 2. Dice × Raridade — BaseIncome Nível 1 (ANTES)

| # | Dice | Common | Uncommon | Rare | Epic | Legendary | Mythic | Divine | Secret |
|---|---|---|---|---|---|---|---|---|---|
| 1 | Starter | 1 | 4 | 9 | 25 | - | - | - | - |
| 2 | Lucky | 1 | 4 | 9 | 25 | - | - | - | - |
| 3 | Rampart | 1 | 4 | 9 | 25 | - | - | - | - |
| 4 | Shinobi | 1 | 4 | 9 | 25 | - | - | - | - |
| 5 | Flame | - | 4 | 9 | 25 | 60 | - | - | - |
| 6 | Blade | - | 4 | 9 | 25 | 60 | - | - | - |
| 7 | Fighter | - | 4 | 9 | 25 | 60 | - | - | - |
| 8 | Storm | - | - | 9 | 25 | 60 | - | - | - |
| 9 | Spirit | - | - | 9 | 25 | 60 | 160 | - | - |
| 10 | Arcane | - | - | 9 | 25 | 60 | 160 | - | - |
| 11 | Shadow | - | - | - | 25 | 60 | 160 | - | - |
| 12 | Void | - | - | - | 25 | 60 | 160 | 425 | - |
| 13 | Colossus | - | - | - | 25 | 60 | 160 | - | - |
| 14 | Awakened | - | - | - | - | 60 | 160 | - | - |
| 15 | Celestial | - | - | - | - | 60 | 160 | 425 | - |
| 16 | Forbidden | - | - | - | - | - | 170 | 425 | 1.200 |

## 3. Dice × Raridade — BaseIncome Nível 1 (DEPOIS)

| # | Dice | Common | Uncommon | Rare | Epic | Legendary | Mythic | Divine | Secret |
|---|---|---|---|---|---|---|---|---|---|
| 1 | Starter | 1 | 3.8 | 8.2 | 22 | - | - | - | - |
| 2 | Lucky | 1.1 | 4.2 | 9.1 | 24 | - | - | - | - |
| 3 | Rampart | 1.2 | 4.6 | 10 | 27 | - | - | - | - |
| 4 | Shinobi | 1.3 | 5.1 | 11 | 30 | - | - | - | - |
| 5 | Flame | - | 5.7 | 12 | 33 | 54 | - | - | - |
| 6 | Blade | - | 6.3 | 14 | 37 | 60 | - | - | - |
| 7 | Fighter | - | 7 | 15 | 41 | 67 | - | - | - |
| 8 | Storm | - | - | 17 | 46 | 74 | - | - | - |
| 9 | Spirit | - | - | 19 | 51 | 82 | 149 | - | - |
| 10 | Arcane | - | - | 21 | 56 | 91 | 165 | - | - |
| 11 | Shadow | - | - | - | 63 | 101 | 183 | - | - |
| 12 | Void | - | - | - | 70 | 112 | 203 | 408 | - |
| 13 | Colossus | - | - | - | 77 | 125 | 226 | - | - |
| 14 | Awakened | - | - | - | - | 138 | 251 | - | - |
| 15 | Celestial | - | - | - | - | 153 | 278 | 557 | - |
| 16 | Forbidden | - | - | - | - | - | 309 | 619 | 1.200 |

## 4. Tempo de jogo ATIVO para comprar cada Dice (mediana) — antes → depois

Entre parênteses: quando os rolls exigidos foram atingidos (se o Dice sai logo depois disso, o
gargalo é o número de rolls, não o dinheiro).

| # | Dice | Preço | Casual | Ativo | Otimizador | Pago |
|---|---|---|---|---|---|---|
| 1 | Starter | $0 | 0 min → **0 min** (0 min) | 0 min → **0 min** (0 min) | 0 min → **0 min** (0 min) | 0 min → **0 min** (0 min) |
| 2 | Lucky | $2.500 | 3 min → **3 min** (1 min) | 1 min → **1 min** (0 min) | 1 min → **1 min** (0 min) | 1 min → **1 min** (0 min) |
| 3 | Rampart | $10.000 | 6 min → **6 min** (2 min) | 4 min → **4 min** (2 min) | 4 min → **4 min** (2 min) | 1 min → **1 min** (1 min) |
| 4 | Shinobi | $40.000 | 9 min → **9 min** (7 min) | 10 min → **10 min** (5 min) | 10 min → **10 min** (5 min) | 5 min → **5 min** (2 min) |
| 5 | Flame | $75.000 | 12 min → **11 min** (10 min) | 13 min → **12 min** (7 min) | 14 min → **13 min** (7 min) | 8 min → **8 min** (3 min) |
| 6 | Blade | $125.000 | 16 min → **16 min** (15 min) | 15 min → **16 min** (10 min) | 17 min → **18 min** (10 min) | 10 min → **10 min** (5 min) |
| 7 | Fighter | $225.000 | 21 min → **21 min** (18 min) | 22 min → **21 min** (12 min) | 26 min → **24 min** (12 min) | 13 min → **12 min** (6 min) |
| 8 | Storm | $400.000 | 24 min → **24 min** (23 min) | 26 min → **25 min** (16 min) | 32 min → **30 min** (16 min) | 16 min → **15 min** (8 min) |
| 9 | Spirit | $750.000 | 36 min → **36 min** (35 min) | 33 min → **36 min** (25 min) | 37 min → **39 min** (25 min) | 20 min → **21 min** (12 min) |
| 10 | Arcane | $1.400.000 | 48 min → **48 min** (47 min) | 43 min → **43 min** (33 min) | 46 min → **46 min** (33 min) | 25 min → **29 min** (16 min) |
| 11 | Shadow | $2.600.000 | 1.0 h → **1.0 h** (59 min) | 50 min → **51 min** (41 min) | 52 min → **51 min** (41 min) | 28 min → **31 min** (20 min) |
| 12 | Void | $5.000.000 | 1.3 h → **1.3 h** (1.2 h) | 1.0 h → **58 min** (50 min) | 1.1 h → **1.0 h** (50 min) | 33 min → **36 min** (25 min) |
| 13 | Colossus | $12.500.000 | 1.9 h → **1.9 h** (1.8 h) | 1.4 h → **1.2 h** (1.2 h) | 1.4 h → **1.3 h** (1.2 h) | 45 min → **44 min** (37 min) |
| 14 | Awakened | $30.000.000 | 2.4 h → **2.4 h** (2.4 h) | 2.0 h → **1.8 h** (1.7 h) | 2.0 h → **1.8 h** (1.7 h) | 1.1 h → **1.1 h** (50 min) |
| 15 | Celestial | $75.000.000 | 3.2 h → **3.2 h** (3.2 h) | 3.0 h → **2.7 h** (2.2 h) | 3.1 h → **2.9 h** (2.2 h) | 1.8 h → **1.7 h** (1.1 h) |
| 16 | Forbidden | $400.000.000 | 4.8 h → **4.8 h** (4.8 h) | 4.7 h → **4.0 h** (3.3 h) | 4.9 h → **4.0 h** (3.3 h) | 2.8 h → **2.4 h** (1.7 h) |

## 5. Rebirth, renda final e fontes de dinheiro (mediana)

| Perfil | 1º Rebirth antes → depois | Rebirths em 40 h | Renda/s final antes → depois | Offline % | Torre % | Venda % |
|---|---|---|---|---|---|---|
| Casual | 1.1 h → **1.2 h** | 13 → **13** | $1.141.993 → **$1.203.081** | 68% | 0.0% | 0.3% |
| Ativo | 2.1 h → **2.0 h** | 13 → **13** | $2.533.722 → **$3.472.172** | 43% | 0.1% | 0.3% |
| Otimizador | 2.1 h → **2.0 h** | 12 → **13** | $2.452.432 → **$3.669.405** | 26% | 0.1% | 0.4% |
| Pago | 1.2 h → **1.2 h** | 14 → **14** | $6.897.730 → **$8.421.727** | 43% | 0.0% | 0.3% |

## 6. Upgrades, venda/refund, fusão, troca, offline, torre e exploits

- **Fonte da verdade da renda:** `CharacterConfig.IncomeCurve` (Dice × Raridade) define o `BaseIncome` dos 112 F2P;
  `Formulas:unitIncome` = BaseIncome × (1 + 0,25 × (Nível − 1)) × Variante.IncomeMultiplier; estação = × multiplicadores globais.
  Antes: `BaseIncome` literal por raridade no catálogo gerado (`gen_launch_catalog.py` STATS) e nos pilotos.
- **Upgrades:** custo do nível = BaseIncome × 60 s × 1,2^(Nível−1) — proporcional ao BaseIncome, então o tempo para um nível
  se pagar é o mesmo em todo Dice (sem Dice "barato de upar"). Teste: `tests/DiceIncome.spec.luau`.
- **Venda/refund:** base = BaseIncome × SellSeconds[raridade] × variante + 75% do investimento gravado na unidade;
  venda − investimento ≤ base para todo personagem/nível (comprar níveis e vender nunca dá lucro). Venda em massa = Σ individual.
- **Fusão:** a unidade nova soma o investimento das consumidas (independe da renda). **Troca:** copia Id/Nível/Variante/investimento,
  então a renda não muda. **Save/load:** a renda não é gravada no save; é recalculada de Id/Nível/Variante (saves antigos
  passam a render pela curva nova automaticamente; o investimento já gravado continua valendo na venda).
- **Offline:** limitado a 25% do custo do próximo Rebirth (não infla com a renda maior); fatia do dinheiro igual à de antes.
- **Torre:** recompensa = max(poder do inimigo × MoneyPerPower, renda/s × IncomeSeconds) — acompanha a renda; < 0,2% do dinheiro.
- **Inflação:** a renda/s final sobe (+5% Casual a +50% Otimizador em 40 h) porque o fim do jogo tem personagens melhores,
  mas o nº de Rebirths fica igual (custo 15M × 2,2ⁿ absorve) e nenhum Dice fica mais de 15% mais rápido.
- **Exploits procurados:** arbitragem upar→vender (impossível, refund 75%), comprar Dice só para vender (venda ∝ renda,
  não ao preço do Dice), duplicatas de Dice tardio (vender rende mais, mas é o mesmo personagem que já renderia mais na
  base), troca entre contas (não cria renda). Nenhum encontrado.

## 7. Conclusão

- Curva aplicada: Growth **1,11** por passo de Dice, Pivot **0,10** (âncora perto do 1º Dice de cada raridade).
- Míticos de Dice diferentes não rendem mais igual (Spirit 149 → Forbidden 309); Lendário Celestial (153) passa o Mítico Spirit (149).
- Pacing: Casual idêntico (±3%); Dice até o Shadow e 1º Rebirth dentro de ±15% (a maioria ±5%); jogadores ativos chegam ao Celestial/Forbidden
  ~8–15% antes (o Dice posterior passou a ter valor econômico real). Pesos, pity, Luck e distribuição intocados.

## 8. Os 112 personagens F2P (depois)

| Dice | # | CharacterId | Raridade | BaseIncome antes | BaseIncome | Renda Nv1 Normal | Renda Nv30 Normal | Venda Nv1 |
|---|---|---|---|---|---|---|---|---|
| Starter | 1 | char_anny_school | Common | 1 | 1 | 1 | 8.25 | 20 |
| Starter | 1 | char_mikaza_formal | Common | 1 | 1 | 1 | 8.25 | 20 |
| Starter | 1 | char_sacha_base | Common | 1 | 1 | 1 | 8.25 | 20 |
| Starter | 1 | char_sacha_suit | Common | 1 | 1 | 1 | 8.25 | 20 |
| Starter | 1 | char_chiko_base | Uncommon | 4 | 3.8 | 3.8 | 31.35 | 76 |
| Starter | 1 | char_erwyn_gala | Uncommon | 4 | 3.8 | 3.8 | 31.35 | 76 |
| Starter | 1 | char_kurilo_base | Rare | 9 | 8.2 | 8.2 | 67.65 | 204 |
| Starter | 1 | char_saitano_base | Epic | 25 | 22 | 22 | 181.5 | 660 |
| Lucky | 2 | char_gom_base | Common | 1 | 1.1 | 1.1 | 9.075 | 22 |
| Lucky | 2 | char_sanjo_young | Common | 1 | 1.1 | 1.1 | 9.075 | 22 |
| Lucky | 2 | char_kazumo_base | Uncommon | 4 | 4.2 | 4.2 | 34.65 | 84 |
| Lucky | 2 | char_rinn_base | Uncommon | 4 | 4.2 | 4.2 | 34.65 | 84 |
| Lucky | 2 | char_grei_base | Rare | 9 | 9.1 | 9.1 | 75.075 | 227 |
| Lucky | 2 | char_rukya_base | Rare | 9 | 9.1 | 9.1 | 75.075 | 227 |
| Lucky | 2 | char_hizoka_base | Epic | 25 | 24 | 24 | 198 | 720 |
| Rampart | 3 | char_erem_base | Common | 1 | 1.2 | 1.2 | 9.9 | 24 |
| Rampart | 3 | char_anny_base | Uncommon | 4 | 4.6 | 4.6 | 37.95 | 92 |
| Rampart | 3 | char_mikaza_base | Uncommon | 4 | 4.6 | 4.6 | 37.95 | 92 |
| Rampart | 3 | char_erem_veteran | Rare | 9 | 10 | 10 | 82.5 | 250 |
| Rampart | 3 | char_erwyn_base | Rare | 9 | 10 | 10 | 82.5 | 250 |
| Rampart | 3 | char_anny_titan | Epic | 25 | 27 | 27 | 222.75 | 810 |
| Rampart | 3 | char_erem_titan | Epic | 25 | 27 | 27 | 222.75 | 810 |
| Shinobi | 4 | char_narotu_young | Common | 1 | 1.3 | 1.3 | 10.725 | 26 |
| Shinobi | 4 | char_sasuko_young | Common | 1 | 1.3 | 1.3 | 10.725 | 26 |
| Shinobi | 4 | char_nejo_base | Uncommon | 4 | 5.1 | 5.1 | 42.075 | 102 |
| Shinobi | 4 | char_roqueli_base | Uncommon | 4 | 5.1 | 5.1 | 42.075 | 102 |
| Shinobi | 4 | char_gaaro_base | Rare | 9 | 11 | 11 | 90.75 | 275 |
| Shinobi | 4 | char_zabuzo_base | Rare | 9 | 11 | 11 | 90.75 | 275 |
| Shinobi | 4 | char_kakaxi_base | Epic | 25 | 30 | 30 | 247.5 | 900 |
| Shinobi | 4 | char_narotu_base | Epic | 25 | 30 | 30 | 247.5 | 900 |
| Flame | 5 | char_natzu_base | Uncommon | 4 | 5.7 | 5.7 | 47.025 | 114 |
| Flame | 5 | char_todoruki_base | Uncommon | 4 | 5.7 | 5.7 | 47.025 | 114 |
| Flame | 5 | char_ase_base | Rare | 9 | 12 | 12 | 99 | 300 |
| Flame | 5 | char_bakugu_base | Rare | 9 | 12 | 12 | 99 | 300 |
| Flame | 5 | char_yamamotu_base | Epic | 25 | 33 | 33 | 272.25 | 990 |
| Flame | 5 | char_akaino_base | Legendary | 60 | 54 | 54 | 445.5 | 1.890 |
| Blade | 6 | char_ichiro_base | Uncommon | 4 | 6.3 | 6.3 | 51.975 | 126 |
| Blade | 6 | char_zoru_young | Uncommon | 4 | 6.3 | 6.3 | 51.975 | 126 |
| Blade | 6 | char_ginn_base | Rare | 9 | 14 | 14 | 115.5 | 350 |
| Blade | 6 | char_kisuko_base | Rare | 9 | 14 | 14 | 115.5 | 350 |
| Blade | 6 | char_trunkz_base | Rare | 9 | 14 | 14 | 115.5 | 350 |
| Blade | 6 | char_tanjiru_base | Epic | 25 | 37 | 37 | 305.25 | 1.110 |
| Blade | 6 | char_zoru_base | Epic | 25 | 37 | 37 | 305.25 | 1.110 |
| Blade | 6 | char_shankz_base | Legendary | 60 | 60 | 60 | 495 | 2.100 |
| Fighter | 7 | char_deko_base | Uncommon | 4 | 7 | 7 | 57.75 | 140 |
| Fighter | 7 | char_goko_base | Uncommon | 4 | 7 | 7 | 57.75 | 140 |
| Fighter | 7 | char_yuzuke_base | Uncommon | 4 | 7 | 7 | 57.75 | 140 |
| Fighter | 7 | char_lemilio_base | Rare | 9 | 15 | 15 | 123.75 | 375 |
| Fighter | 7 | char_lufy_base | Rare | 9 | 15 | 15 | 123.75 | 375 |
| Fighter | 7 | char_pikkolo_base | Epic | 25 | 41 | 41 | 338.25 | 1.230 |
| Fighter | 7 | char_olmaito_base | Legendary | 60 | 67 | 67 | 552.75 | 2.345 |
| Storm | 8 | char_killuo_base | Rare | 9 | 17 | 17 | 140.25 | 425 |
| Storm | 8 | char_lanseiro_base | Rare | 9 | 17 | 17 | 140.25 | 425 |
| Storm | 8 | char_minatu_base | Rare | 9 | 17 | 17 | 140.25 | 425 |
| Storm | 8 | char_goko_majin_saga | Epic | 25 | 46 | 46 | 379.5 | 1.380 |
| Storm | 8 | char_kaulifa_base | Epic | 25 | 46 | 46 | 379.5 | 1.380 |
| Storm | 8 | char_deko_awakened | Legendary | 60 | 74 | 74 | 610.5 | 2.590 |
| Storm | 8 | char_killuo_godspeed | Legendary | 60 | 74 | 74 | 610.5 | 2.590 |
| Spirit | 9 | char_toshiru_base | Rare | 9 | 19 | 19 | 156.75 | 475 |
| Spirit | 9 | char_byakuto_base | Epic | 25 | 51 | 51 | 420.75 | 1.530 |
| Spirit | 9 | char_shunzo_base | Epic | 25 | 51 | 51 | 420.75 | 1.530 |
| Spirit | 9 | char_starko_base | Epic | 25 | 51 | 51 | 420.75 | 1.530 |
| Spirit | 9 | char_hiey_base | Legendary | 60 | 82 | 82 | 676.5 | 2.870 |
| Spirit | 9 | char_yoruka_base | Legendary | 60 | 82 | 82 | 676.5 | 2.870 |
| Spirit | 9 | char_yuzuke_demon | Mythic | 160 | 149 | 149 | 1.229 | 6.705 |
| Arcane | 10 | char_kiritsugo_base | Rare | 9 | 21 | 21 | 173.25 | 525 |
| Arcane | 10 | char_seiba_base | Rare | 9 | 21 | 21 | 173.25 | 525 |
| Arcane | 10 | char_shiro_base | Rare | 9 | 21 | 21 | 173.25 | 525 |
| Arcane | 10 | char_akcel_base | Epic | 25 | 56 | 56 | 462 | 1.680 |
| Arcane | 10 | char_lau_base | Epic | 25 | 56 | 56 | 462 | 1.680 |
| Arcane | 10 | char_rika_base | Epic | 25 | 56 | 56 | 462 | 1.680 |
| Arcane | 10 | char_gilgamex_base | Legendary | 60 | 91 | 91 | 750.75 | 3.185 |
| Arcane | 10 | char_shiro_archer | Mythic | 160 | 165 | 165 | 1.361 | 7.425 |
| Shadow | 11 | char_grimjau_base | Epic | 25 | 63 | 63 | 519.75 | 1.890 |
| Shadow | 11 | char_shinjo_base | Epic | 25 | 63 | 63 | 519.75 | 1.890 |
| Shadow | 11 | char_ulkiorra_base | Epic | 25 | 63 | 63 | 519.75 | 1.890 |
| Shadow | 11 | char_itaxi_base | Legendary | 60 | 101 | 101 | 833.25 | 3.535 |
| Shadow | 11 | char_peinn_base | Legendary | 60 | 101 | 101 | 833.25 | 3.535 |
| Shadow | 11 | char_goko_dark_base | Mythic | 160 | 183 | 183 | 1.510 | 8.235 |
| Shadow | 11 | char_ichiro_hollow | Mythic | 160 | 183 | 183 | 1.510 | 8.235 |
| Void | 12 | char_ilumi_base | Epic | 25 | 70 | 70 | 577.5 | 2.100 |
| Void | 12 | char_vejita_base | Epic | 25 | 70 | 70 | 577.5 | 2.100 |
| Void | 12 | char_ilumi_awakened | Legendary | 60 | 112 | 112 | 924 | 3.920 |
| Void | 12 | char_vejita_majin | Legendary | 60 | 112 | 112 | 924 | 3.920 |
| Void | 12 | char_ulkiorra_release | Mythic | 160 | 203 | 203 | 1.675 | 9.135 |
| Void | 12 | char_ichiro_vasto | Divine | 425 | 408 | 408 | 3.366 | 24.480 |
| Colossus | 13 | char_gohin_base | Epic | 25 | 77 | 77 | 635.25 | 2.310 |
| Colossus | 13 | char_mighto_base | Epic | 25 | 77 | 77 | 635.25 | 2.310 |
| Colossus | 13 | char_brolli_base | Legendary | 60 | 125 | 125 | 1.031 | 4.375 |
| Colossus | 13 | char_sasuko_base | Legendary | 60 | 125 | 125 | 1.031 | 4.375 |
| Colossus | 13 | char_lufy_snake | Mythic | 160 | 226 | 226 | 1.864 | 10.170 |
| Colossus | 13 | char_mighto_gate5 | Mythic | 160 | 226 | 226 | 1.864 | 10.170 |
| Awakened | 14 | char_bakugu_awakened | Legendary | 60 | 138 | 138 | 1.138 | 4.830 |
| Awakened | 14 | char_grei_awakened | Legendary | 60 | 138 | 138 | 1.138 | 4.830 |
| Awakened | 14 | char_rika_awakened | Legendary | 60 | 138 | 138 | 1.138 | 4.830 |
| Awakened | 14 | char_gom_adult | Mythic | 160 | 251 | 251 | 2.071 | 11.295 |
| Awakened | 14 | char_natzu_awakened | Mythic | 160 | 251 | 251 | 2.071 | 11.295 |
| Awakened | 14 | char_roqueli_gates | Mythic | 160 | 251 | 251 | 2.071 | 11.295 |
| Celestial | 15 | char_sanjo_base | Legendary | 60 | 153 | 153 | 1.262 | 5.355 |
| Celestial | 15 | char_yujo_base | Legendary | 60 | 153 | 153 | 1.262 | 5.355 |
| Celestial | 15 | char_narotu_sage | Mythic | 160 | 278 | 278 | 2.294 | 12.510 |
| Celestial | 15 | char_olmaito_mode | Mythic | 160 | 278 | 278 | 2.294 | 12.510 |
| Celestial | 15 | char_deko_full | Divine | 425 | 557 | 557 | 4.595 | 33.420 |
| Celestial | 15 | char_goju_base | Divine | 425 | 557 | 557 | 4.595 | 33.420 |
| Celestial | 15 | char_vegitto_base | Divine | 425 | 557 | 557 | 4.595 | 33.420 |
| Forbidden | 16 | char_barbalva_base | Mythic | 170 | 309 | 309 | 2.549 | 13.905 |
| Forbidden | 16 | char_aizo_base | Divine | 425 | 619 | 619 | 5.107 | 37.140 |
| Forbidden | 16 | char_brolli_legend | Divine | 425 | 619 | 619 | 5.107 | 37.140 |
| Forbidden | 16 | char_madaro_base | Divine | 425 | 619 | 619 | 5.107 | 37.140 |
| Forbidden | 16 | char_ichiro_mugetsu | Secret | 1.200 | 1.200 | 1.200 | 9.900 | 108.000 |
| Forbidden | 16 | char_mighto_gate8 | Secret | 1.200 | 1.200 | 1.200 | 9.900 | 108.000 |
| Forbidden | 16 | char_vegitto_blue | Secret | 1.200 | 1.200 | 1.200 | 9.900 | 108.000 |

