# DICE_PROGRESSION_PROPOSAL — PROPOSTA (não implementada)

> Muitos Dice com pools pequenos (5–10, ideal 7–8). Âncoras = Dice que já existem hoje
> (Normal→Starter, Lucky, Flame, Storm, Void, Celestial). O Prism continua exclusivo do Diário.
> **Chances globais de raridade, Luck, pity e economia NÃO mudam nesta etapa.**

## Ordem de desbloqueio

| # | Dice | Âncora atual | Tema | Qtde | Raridades (C/U/R/E/L/M/D/S) |
|---:|---|---|---|---:|---|
| 1 | **Starter Dice** | Normal | Recrutas e civis: primeiros personagens, silhuetas simples e limpas. | 8 | 4/2/1/1/0/0/0/0 |
| 2 | **Lucky Dice** | Lucky | Aventureiros e apostadores: sorte, viagem, cartas. | 7 | 2/2/2/1/0/0/0/0 |
| 3 | **Rampart Dice** | novo | Soldados das muralhas e os primeiros titãs: uniforme militar, capas, escala. | 7 | 1/2/2/2/0/0/0/0 |
| 4 | **Flame Dice** | Flame | Fogo, explosão e magma. | 6 | 0/2/2/1/1/0/0/0 |
| 5 | **Shinobi Dice** | novo | Ninjas: bandanas, máscaras, areia e espadas de ninja. | 8 | 2/2/2/2/0/0/0/0 |
| 6 | **Blade Dice** | novo | Espadachins: katanas, lâminas duplas e trilhas de corte. | 8 | 0/2/3/2/1/0/0/0 |
| 7 | **Fighter Dice** | novo | Lutadores de punho e heróis de força. | 7 | 0/3/2/1/1/0/0/0 |
| 8 | **Storm Dice** | Storm | Raio, velocidade e energia elétrica. | 7 | 0/0/3/2/2/0/0/0 |
| 9 | **Spirit Dice** | novo | Guerreiros espirituais: energia espiritual, gelo, flores, capas de capitão. | 7 | 0/0/1/3/2/1/0/0 |
| 10 | **Arcane Dice** | novo | Magia e heróis lendários: arcos, lanças, espadas mágicas. | 8 | 0/0/3/3/1/1/0/0 |
| 11 | **Shadow Dice** | novo | Formas sombrias, máscaras e vilões frios. | 7 | 0/0/0/3/2/2/0/0 |
| 12 | **Void Dice** | Void | Vazio e transformações sinistras. | 6 | 0/0/0/2/2/1/1/0 |
| 13 | **Awakened Dice** | novo | Formas DESPERTAS: o mesmo herói, agora com aura. | 6 | 0/0/0/0/3/3/0/0 |
| 14 | **Colossus Dice** | novo | Força bruta e gigantes: portões, berserkers, monstros. | 6 | 0/0/0/2/2/2/0/0 |
| 15 | **Celestial Dice** | Celestial | Lendas em forma máxima: Divinos da progressão principal. | 7 | 0/0/0/0/2/2/3/0 |
| 16 | **Forbidden Dice** | novo | Endgame: Secretos e as formas finais mais raras. | 7 | 0/0/0/0/0/1/3/3 |

**Total F2P: 112 personagens em 16 Dice.** + Premium Dice (ver PREMIUM_DICE_PROPOSAL.md).

## Progressão das faixas

- Iniciais (Starter → Shinobi): Comum, Incomum, Raro e alguns Épicos.
- Intermediários (Blade → Arcane): Raro, Épico, Lendário e os primeiros Míticos.
- Avançados (Shadow → Colossus): Épico, Lendário, Mítico e o primeiro Divino (Void).
- Endgame (Celestial, Forbidden): Lendário, Mítico, Divino e Secreto.

**Ponto a decidir na etapa de RNG:** hoje o sorteio escolhe a raridade com as chances globais e
depois um personagem daquela raridade. Com pools por Dice, uma raridade que o Dice não tem
(ex.: Secreto no Starter) precisa de regra (sugestão: cair para a maior raridade do Dice, ou
o pity respeitar a faixa do Dice). Fica para a nova simulação, depois de aprovar os pools.

## 1. Starter Dice (âncora: Normal)

Recrutas e civis: primeiros personagens, silhuetas simples e limpas.

| Raridade | DisplayName | CharacterId | SourceModelName | Família | Forma | Nota técnica | VFX próprios | Peças | Status |
|---|---|---|---|---|---:|---:|---|---:|---|
| Common | Sacha | `sacha` | AOT.Sasha | sacha | 1 | 24 | — | 8 | APPROVED |
| Common | Sacha (Terno) | `sacha_suit` | AOT.Sasha (Suit) | sacha | 1 | 24 | — | 8 | APPROVED |
| Common | Anny (Colegial) | `anny_school` | AOT.Annie (Junior High) | anny | 1 | 24 | — | 8 | APPROVED |
| Common | Mikaza (Formal) | `mikaza_formal` | AOT.Mikasa (Formal) | mikaza | 1 | 27 | — | 9 | APPROVED |
| Uncommon | Erwyn (Gala) | `erwyn_gala` | AOT.Erwin (Alt) | erwyn | 1 | 24 | — | 8 | APPROVED |
| Uncommon | Chiko | `chiko` | OTHER.MISC.Chika | chiko | 1 | 42 | — | 13 | APPROVED |
| Rare | Kurilo | `kurilo` | DBZ.Krillin | kurilo | 1 | 21 | — | 11 | APPROVED |
| Epic | Saitano | `saitano` | OTHER.MISC.Saitama | saitano | 1 | 27 | — | 13 | APPROVED |

## 2. Lucky Dice (âncora: Lucky)

Aventureiros e apostadores: sorte, viagem, cartas.

| Raridade | DisplayName | CharacterId | SourceModelName | Família | Forma | Nota técnica | VFX próprios | Peças | Status |
|---|---|---|---|---|---:|---:|---|---:|---|
| Common | Gom | `gom` | HXH.Gon | gom | 1 | 31 | — | 12 | APPROVED |
| Common | Sanjo (Jovem) | `sanjo_young` | One Piece Pack.ptsSanji | sanjo | 1 | 27 | — | 12 | APPROVED |
| Uncommon | Rinn | `rinn` | FATE.Rin | rinn | 1 | 35 | — | 13 | APPROVED |
| Uncommon | Kazumo | `kazumo` | OTHER.Kazuma | kazumo | 1 | 35 | Trail | 13 | APPROVED |
| Rare | Rukya | `rukya` | Bleach Pack.Rukia | rukya | 1 | 41 | Trail | 14 | APPROVED |
| Rare | Grei | `grei` | Fairy Tail.Gray | grei | 1 | 27 | — | 13 | APPROVED |
| Epic | Hizoka | `hizoka` | HXH.Hisoka (2ª ocorrência) | hizoka | 1 | 31 | Aura | 12 | APPROVED |

## 3. Rampart Dice

Soldados das muralhas e os primeiros titãs: uniforme militar, capas, escala.

| Raridade | DisplayName | CharacterId | SourceModelName | Família | Forma | Nota técnica | VFX próprios | Peças | Status |
|---|---|---|---|---|---:|---:|---|---:|---|
| Common | Erem | `erem` | AOT.Eren | erem | 1 | 24 | — | 8 | APPROVED |
| Uncommon | Mikaza | `mikaza` | AOT.Mikasa | mikaza | 1 | 27 | — | 9 | APPROVED |
| Uncommon | Anny | `anny` | AOT.Annie | anny | 1 | 24 | — | 8 | APPROVED |
| Rare | Erwyn | `erwyn` | AOT.Erwin | erwyn | 1 | 27 | — | 9 | APPROVED |
| Rare | Erem (Veterano) | `erem_veteran` | AOT.Eren Post-time skip | erem | 2 | 24 | — | 8 | APPROVED |
| Epic | Titã Feminina | `anny_titan` | AOT.Female Titan | anny | 2 | 24 | — | 8 | APPROVED |
| Epic | Titã de Ataque | `erem_titan` | AOT.Attack Titan | erem | 3 | 27 | — | 9 | APPROVED |

## 4. Flame Dice (âncora: Flame)

Fogo, explosão e magma.

| Raridade | DisplayName | CharacterId | SourceModelName | Família | Forma | Nota técnica | VFX próprios | Peças | Status |
|---|---|---|---|---|---:|---:|---|---:|---|
| Uncommon | Natzu | `natzu` | Fairy Tail.Natsu | natzu | 1 | 33 | — | 14 | APPROVED |
| Uncommon | Todoruki | `todoruki` | My Hero Academia Pack.Todoroki | todoruki | 1 | 27 | ChargeParticle2 | 14 | APPROVED |
| Rare | Bakugu | `bakugu` | My Hero Academia Pack.Bakugo | bakugu | 1 | 24 | — | 24 | APPROVED |
| Rare | Ase | `ase` | One Piece Pack.Ace | ase | 1 | 44 | — | 15 | APPROVED |
| Epic | Yamamotu | `yamamotu` | Bleach Pack.Yamamoto | yamamotu | 1 | 38 | Beam, Fire, PointLight | 15 | APPROVED |
| Legendary | Akaino | `akaino` | One Piece Pack.Akainu | akaino | 1 | 58 | — | 27 | APPROVED |

## 5. Shinobi Dice

Ninjas: bandanas, máscaras, areia e espadas de ninja.

| Raridade | DisplayName | CharacterId | SourceModelName | Família | Forma | Nota técnica | VFX próprios | Peças | Status |
|---|---|---|---|---|---:|---:|---|---:|---|
| Common | Narotu (Jovem) | `narotu_young` | NARUTO.ptsNaruto | narotu | 1 | 27 | — | 12 | APPROVED |
| Common | Sasuko (Jovem) | `sasuko_young` | NARUTO.ptsSasuke | sasuko | 1 | 33 | — | 13 | APPROVED |
| Uncommon | Nejo | `nejo` | NARUTO.Neji | nejo | 1 | 33 | — | 13 | APPROVED |
| Uncommon | Roque Li | `roqueli` | NARUTO.Rock Lee.Rock Lee | roqueli | 1 | 33 | — | 17 | APPROVED |
| Rare | Gaaro | `gaaro` | NARUTO.Gaara | gaaro | 1 | 30 | FeetParticle, Particle | 21 | APPROVED |
| Rare | Zabuzo | `zabuzo` | NARUTO.Zabuza | zabuzo | 1 | 50 | — | 16 | APPROVED |
| Epic | Narotu | `narotu` | NARUTO.tsNaruto | narotu | 2 | 27 | — | 12 | APPROVED |
| Epic | Kakaxi | `kakaxi` | NARUTO.Kakashi | kakaxi | 1 | 39 | — | 17 | APPROVED |

## 6. Blade Dice

Espadachins: katanas, lâminas duplas e trilhas de corte.

| Raridade | DisplayName | CharacterId | SourceModelName | Família | Forma | Nota técnica | VFX próprios | Peças | Status |
|---|---|---|---|---|---:|---:|---|---:|---|
| Uncommon | Ichiro | `ichiro` | Bleach Pack.Ichigo | ichiro | 1 | 41 | Trail | 14 | APPROVED |
| Uncommon | Zoru (Jovem) | `zoru_young` | One Piece Pack.ptsZoro | zoru | 1 | 66 | Trail | 22 | APPROVED |
| Rare | Kisuko | `kisuko` | Bleach Pack.Kisuke | kisuko | 1 | 41 | NoBlade2, Trail | 17 | APPROVED |
| Rare | Ginn | `ginn` | Bleach Pack.Gin | ginn | 1 | 38 | — | 15 | APPROVED |
| Rare | Trunkz | `trunkz` | DBZ.Trunks | trunkz | 1 | 38 | SaiyanAura | 19 | APPROVED |
| Epic | Tanjiru | `tanjiru` | OTHER.MISC.Tanjiro | tanjiru | 1 | 47 | FireTrail1, FireTrail2, Trail | 16 | APPROVED |
| Epic | Zoru | `zoru` | One Piece Pack.tsZoro | zoru | 2 | 66 | Trail | 22 | APPROVED |
| Legendary | Shankz | `shankz` | One Piece Pack.Shanks | shankz | 1 | 48 | — | 25 | APPROVED |

## 7. Fighter Dice

Lutadores de punho e heróis de força.

| Raridade | DisplayName | CharacterId | SourceModelName | Família | Forma | Nota técnica | VFX próprios | Peças | Status |
|---|---|---|---|---|---:|---:|---|---:|---|
| Uncommon | Goko | `goko` | DBZ.Goku | goko | 1 | 33 | — | 12 | APPROVED |
| Uncommon | Deko | `deko` | My Hero Academia Pack.Deku | deko | 1 | 30 | ChargeParticle2 | 15 | APPROVED |
| Uncommon | Yuzuke | `yuzuke` | YYH.Yusuke | yuzuke | 1 | 31 | — | 12 | APPROVED |
| Rare | Lemilio | `lemilio` | My Hero Academia Pack.Lemillion | lemilio | 1 | 42 | — | 15 | APPROVED |
| Rare | Lufy | `lufy` | One Piece Pack.TS Luffy.tsLuffy | lufy | 2 | 36 | — | 17 | APPROVED |
| Epic | Pikkolo | `pikkolo` | DBZ.Piccolo | pikkolo | 1 | 45 | — | 17 | APPROVED |
| Legendary | Ol Maito | `olmaito` | My Hero Academia Pack.All Might | olmaito | 1 | 34 | — | 12 | APPROVED |

## 8. Storm Dice (âncora: Storm)

Raio, velocidade e energia elétrica.

| Raridade | DisplayName | CharacterId | SourceModelName | Família | Forma | Nota técnica | VFX próprios | Peças | Status |
|---|---|---|---|---|---:|---:|---|---:|---|
| Rare | Lanseiro | `lanseiro` | FATE.Lancer  | lanseiro | 1 | 50 | ChargeParticle, ChargeParticle2, ShootParticle | 18 | APPROVED |
| Rare | Killuo | `killuo` | HXH.Killua | killuo | 1 | 27 | — | 12 | APPROVED |
| Rare | Minatu | `minatu` | NARUTO.Minato.Minato | minatu | 1 | 39 | — | 14 | APPROVED |
| Epic | Goko (Saga Majin) | `goko_majin_saga` | DBZ.Buu Saga Goku | goko | 2 | 37 | Lightning, SaiyanAura | 14 | APPROVED |
| Epic | Kaulifa | `kaulifa` | DBZ.Caulifa | kaulifa | 1 | 27 | Lightning, SaiyanAura, SaiyanAura2 | 13 | APPROVED |
| Legendary | Killuo Relâmpago | `killuo_godspeed` | HXH.Killua Godspeed | killuo | 2 | 33 | Lightning, Reiatsu | 13 | APPROVED |
| Legendary | Deko Desperto | `deko_awakened` | My Hero Academia Pack.Deku Awakened | deko | 2 | 30 | ChargeParticle2, ShootParticle | 15 | APPROVED |

## 9. Spirit Dice

Guerreiros espirituais: energia espiritual, gelo, flores, capas de capitão.

| Raridade | DisplayName | CharacterId | SourceModelName | Família | Forma | Nota técnica | VFX próprios | Peças | Status |
|---|---|---|---|---|---:|---:|---|---:|---|
| Rare | Toshiru | `toshiru` | Bleach Pack.Toshiro.Toshiro | toshiru | 1 | 63 | Trail | 17 | APPROVED |
| Epic | Byakuto | `byakuto` | Bleach Pack.Byakuya | byakuto | 1 | 44 | NoBlade, NoBlade2, Trail | 15 | APPROVED |
| Epic | Shunzo | `shunzo` | Bleach Pack.Shunsui | shunzo | 1 | 56 | — | 22 | APPROVED |
| Epic | Starko | `starko` | Bleach Pack.Starrk | starko | 1 | 44 | Trail | 16 | APPROVED |
| Legendary | Yoruka | `yoruka` | Bleach Pack.Yoruichi.Yoruichi | yoruka | 1 | 27 | — | 13 | APPROVED |
| Legendary | Hiey | `hiey` | YYH.Hiei | hiey | 1 | 62 | — | 21 | APPROVED |
| Mythic | Yuzuke Demônio | `yuzuke_demon` | YYH.Yusuke Mode | yuzuke | 2 | 37 | BigParticle, SmallParticle | 13 | APPROVED |

## 10. Arcane Dice

Magia e heróis lendários: arcos, lanças, espadas mágicas.

| Raridade | DisplayName | CharacterId | SourceModelName | Família | Forma | Nota técnica | VFX próprios | Peças | Status |
|---|---|---|---|---|---:|---:|---|---:|---|
| Rare | Shiro | `shiro` | FATE.Fate Pack.Shirou | shiro | 1 | 59 | — | 18 | APPROVED |
| Rare | Seiba | `seiba` | FATE.Fate Pack.Saber | seiba | 1 | 44 | Charge | 16 | APPROVED |
| Rare | Kiritsugo | `kiritsugo` | FATE.Kiritsugu | kiritsugo | 1 | 24 | — | 13 | APPROVED |
| Epic | Akcel | `akcel` | OTHER.Accel | akcel | 1 | 30 | — | 14 | APPROVED |
| Epic | Rika | `rika` | OTHER.Rikka | rika | 1 | 44 | ChargeParticle, ChargeParticle2, CircleParticle | 15 | APPROVED |
| Epic | Lau | `lau` | One Piece Pack.ptsLaw | lau | 1 | 44 | Trail | 15 | APPROVED |
| Legendary | Gilgamex | `gilgamex` | FATE.Fate Pack.Gilgamesh | gilgamex | 1 | 39 | — | 16 | APPROVED |
| Mythic | Emyia Arqueiro | `shiro_archer` | FATE.Archer (EMIYA) | shiro | 2 | 59 | PointLight, SmallShoot | 18 | APPROVED |

## 11. Shadow Dice

Formas sombrias, máscaras e vilões frios.

| Raridade | DisplayName | CharacterId | SourceModelName | Família | Forma | Nota técnica | VFX próprios | Peças | Status |
|---|---|---|---|---|---:|---:|---|---:|---|
| Epic | Shinjo | `shinjo` | Bleach Pack.Shinji | shinjo | 1 | 58 | Trail | 19 | APPROVED |
| Epic | Grimjau | `grimjau` | Bleach Pack.Grimmjow | grimjau | 1 | 59 | — | 21 | APPROVED |
| Epic | Ulkiorra | `ulkiorra` | Bleach Pack.Ulquiorra.Ulq | ulkiorra | 1 | 56 | Trail | 18 | APPROVED |
| Legendary | Itaxi | `itaxi` | NARUTO.Itachi | itaxi | 1 | 36 | — | 13 | APPROVED |
| Legendary | Peinn | `peinn` | NARUTO.Pain | peinn | 1 | 30 | — | 13 | APPROVED |
| Mythic | Ichiro Mascarado | `ichiro_hollow` | Bleach Pack.Hollow Ichigo.Hollow Ichigo | ichiro | 2 | 53 | Trail | 16 | APPROVED |
| Mythic | Goko Sombrio | `goko_dark` | DBZ.Goku Black.Goku Black [NEW] | goko_dark | 1 | 21 | — | 19 | APPROVED |

## 12. Void Dice (âncora: Void)

Vazio e transformações sinistras.

| Raridade | DisplayName | CharacterId | SourceModelName | Família | Forma | Nota técnica | VFX próprios | Peças | Status |
|---|---|---|---|---|---:|---:|---|---:|---|
| Epic | Vejita | `vejita` | DBZ.Vegeta | vejita | 1 | 21 | — | 43 | NEEDS_OPTIMIZATION |
| Epic | Ilumi | `ilumi` | HXH.Illumi | ilumi | 1 | 24 | — | 13 | APPROVED |
| Legendary | Vejita Majin | `vejita_majin` | DBZ.Majin Vegeta | vejita | 2 | 24 | SaiyanAura | 13 | APPROVED |
| Legendary | Ilumi Desperto | `ilumi_awakened` | HXH.Illumi Awakened | ilumi | 2 | 30 | Beam | 15 | APPROVED |
| Mythic | Ulkiorra Liberado | `ulkiorra_release` | Bleach Pack.Ulquiorra.R1 | ulkiorra | 2 | 53 | Trail | 18 | APPROVED |
| Divine | Ichiro Vasto | `ichiro_vasto` | Bleach Pack.Hollow Ichigo.Vasto | ichiro | 3 | 53 | — | 17 | APPROVED |

## 13. Awakened Dice

Formas DESPERTAS: o mesmo herói, agora com aura.

| Raridade | DisplayName | CharacterId | SourceModelName | Família | Forma | Nota técnica | VFX próprios | Peças | Status |
|---|---|---|---|---|---:|---:|---|---:|---|
| Legendary | Grei Desperto | `grei_awakened` | Fairy Tail.Grey Awakening | grei | 2 | 30 | SaiyanAura, SaiyanAura2, dust | 13 | APPROVED |
| Legendary | Bakugu Desperto | `bakugu_awakened` | My Hero Academia Pack.Awakened Bakugo | bakugu | 2 | 24 | Sparky | 24 | APPROVED |
| Legendary | Rika Desperta | `rika_awakened` | OTHER.Rikka Awakened | rika | 2 | 53 | Blood, ChargeParticle, ChargeParticle2 | 20 | APPROVED |
| Mythic | Natzu Desperto | `natzu_awakened` | Fairy Tail.Natsu Awakened | natzu | 2 | 33 | CircleParticle, Fire, Particle | 14 | APPROVED |
| Mythic | Gom Adulto | `gom_adult` | HXH.Adult Gon | gom | 2 | 24 | SaiyanAura, SaiyanAura2, SaiyanAura3 | 12 | APPROVED |
| Mythic | Roque Li dos Portões | `roqueli_gates` | NARUTO.Rock Lee.ROCK LEE GATES | roqueli | 2 | 33 | Aura, ParticleEmitter | 17 | APPROVED |

## 14. Colossus Dice

Força bruta e gigantes: portões, berserkers, monstros.

| Raridade | DisplayName | CharacterId | SourceModelName | Família | Forma | Nota técnica | VFX próprios | Peças | Status |
|---|---|---|---|---|---:|---:|---|---:|---|
| Epic | Gohin | `gohin` | DBZ.Gohan | gohin | 1 | 27 | — | 13 | APPROVED |
| Epic | Mighto | `mighto` | NARUTO.Might Guy.Might Guy | mighto | 1 | 27 | — | 13 | APPROVED |
| Legendary | Brolli | `brolli` | DBZ.Broly.Broly | brolli | 1 | 30 | — | 13 | APPROVED |
| Legendary | Sasuko | `sasuko` | NARUTO.tsSasuke | sasuko | 2 | 35 | ChargeParticle2, ParticleEmitter | 25 | APPROVED |
| Mythic | Mighto 5º Portão | `mighto_gate5` | NARUTO.Might Guy.5TH GATE | mighto | 2 | 39 | Aura, Beam1, Beam10 | 16 | NEEDS_OPTIMIZATION |
| Mythic | Lufy Serpente | `lufy_snake` | One Piece Pack.TS Luffy.Snakeman | lufy | 3 | 27 | — | 22 | APPROVED |

## 15. Celestial Dice (âncora: Celestial)

Lendas em forma máxima: Divinos da progressão principal.

| Raridade | DisplayName | CharacterId | SourceModelName | Família | Forma | Nota técnica | VFX próprios | Peças | Status |
|---|---|---|---|---|---:|---:|---|---:|---|
| Legendary | Yujo | `yujo` | JJK.Yuji | yujo | 1 | 46 | — | 15 | APPROVED |
| Legendary | Sanjo | `sanjo` | One Piece Pack.TS SANJI | sanjo | 2 | 27 | — | 12 | APPROVED |
| Mythic | Ol Maito Poder Total | `olmaito_mode` | My Hero Academia Pack.All Might (MODE) | olmaito | 2 | 37 | — | 13 | APPROVED |
| Mythic | Narotu Sábio | `narotu_sage` | NARUTO.Sage Mode | narotu | 3 | 33 | — | 13 | APPROVED |
| Divine | Vegitto | `vegitto` | DBZ.Vegito.VEGITO | vegitto | 1 | 42 | — | 15 | APPROVED |
| Divine | Goju | `goju` | JJK.Gojo Satoru | goju | 1 | 51 | — | 17 | APPROVED |
| Divine | Deko 100% | `deko_full` | My Hero Academia Pack.100% Deku | deko | 3 | 36 | SaiyanAura, ShootParticle, SmallShoot | 21 | APPROVED |

## 16. Forbidden Dice

Endgame: Secretos e as formas finais mais raras.

| Raridade | DisplayName | CharacterId | SourceModelName | Família | Forma | Nota técnica | VFX próprios | Peças | Status |
|---|---|---|---|---|---:|---:|---|---:|---|
| Mythic | Barbalva | `barbalva` | One Piece Pack.Whitebeard | barbalva | 1 | 58 | FX | 17 | APPROVED |
| Divine | Aizo | `aizo` | Bleach Pack.Aizen.Aizen | aizo | 1 | 38 | Trail | 14 | APPROVED |
| Divine | Brolli Lendário | `brolli_legend` | DBZ.Broly.LSSJ BROLY | brolli | 2 | 33 | SaiyanAura, SaiyanAura2 | 14 | APPROVED |
| Divine | Madaro | `madaro` | NARUTO.Madara | madaro | 1 | 30 | — | 15 | APPROVED |
| Secret | Ichiro Mugetsu | `ichiro_mugetsu` | Bleach Pack.Hollow Ichigo.Mugetsu | ichiro | 4 | 63 | BlackFlame | 17 | APPROVED |
| Secret | Vegitto Azul | `vegitto_blue` | DBZ.Vegito.VEGITO BLUE | vegitto | 2 | 42 | SaiyanAura | 15 | APPROVED |
| Secret | Mighto 8º Portão | `mighto_gate8` | NARUTO.Might Guy.8TH GATE | mighto | 3 | 36 | Aura, Beam1, Beam10 | 14 | NEEDS_OPTIMIZATION |

## Personagem → Dice

| DisplayName | CharacterId | Raridade | Dice |
|---|---|---|---|
| Aizo | `aizo` | Divine | Forbidden Dice |
| Akaino | `akaino` | Legendary | Flame Dice |
| Akcel | `akcel` | Epic | Arcane Dice |
| Anny | `anny` | Uncommon | Rampart Dice |
| Anny (Colegial) | `anny_school` | Common | Starter Dice |
| Ase | `ase` | Rare | Flame Dice |
| Bakugu | `bakugu` | Rare | Flame Dice |
| Bakugu Desperto | `bakugu_awakened` | Legendary | Awakened Dice |
| Barbalva | `barbalva` | Mythic | Forbidden Dice |
| Brolli | `brolli` | Legendary | Colossus Dice |
| Brolli Lendário | `brolli_legend` | Divine | Forbidden Dice |
| Byakuto | `byakuto` | Epic | Spirit Dice |
| Chiko | `chiko` | Uncommon | Starter Dice |
| Deko | `deko` | Uncommon | Fighter Dice |
| Deko 100% | `deko_full` | Divine | Celestial Dice |
| Deko Desperto | `deko_awakened` | Legendary | Storm Dice |
| Emyia Arqueiro | `shiro_archer` | Mythic | Arcane Dice |
| Erem | `erem` | Common | Rampart Dice |
| Erem (Veterano) | `erem_veteran` | Rare | Rampart Dice |
| Erwyn | `erwyn` | Rare | Rampart Dice |
| Erwyn (Gala) | `erwyn_gala` | Uncommon | Starter Dice |
| Gaaro | `gaaro` | Rare | Shinobi Dice |
| Gilgamex | `gilgamex` | Legendary | Arcane Dice |
| Ginn | `ginn` | Rare | Blade Dice |
| Gohin | `gohin` | Epic | Colossus Dice |
| Goju | `goju` | Divine | Celestial Dice |
| Goko | `goko` | Uncommon | Fighter Dice |
| Goko (Saga Majin) | `goko_majin_saga` | Epic | Storm Dice |
| Goko Sombrio | `goko_dark` | Mythic | Shadow Dice |
| Goko Sombrio Rosé | `goko_dark_rose` | Mythic | Premium Dice |
| Gom | `gom` | Common | Lucky Dice |
| Gom Adulto | `gom_adult` | Mythic | Awakened Dice |
| Grei | `grei` | Rare | Lucky Dice |
| Grei Desperto | `grei_awakened` | Legendary | Awakened Dice |
| Grimjau | `grimjau` | Epic | Shadow Dice |
| Hiey | `hiey` | Legendary | Spirit Dice |
| Hizoka | `hizoka` | Epic | Lucky Dice |
| Ichiro | `ichiro` | Uncommon | Blade Dice |
| Ichiro Mascarado | `ichiro_hollow` | Mythic | Shadow Dice |
| Ichiro Mugetsu | `ichiro_mugetsu` | Secret | Forbidden Dice |
| Ichiro Vasto | `ichiro_vasto` | Divine | Void Dice |
| Ilumi | `ilumi` | Epic | Void Dice |
| Ilumi Desperto | `ilumi_awakened` | Legendary | Void Dice |
| Infernus | `infernus` | Epic | Premium Dice |
| Iskander | `iskander` | Epic | Premium Dice |
| Itaxi | `itaxi` | Legendary | Shadow Dice |
| Kakaxi | `kakaxi` | Epic | Shinobi Dice |
| Kaulifa | `kaulifa` | Epic | Storm Dice |
| Kazumo | `kazumo` | Uncommon | Lucky Dice |
| Killuo | `killuo` | Rare | Storm Dice |
| Killuo Relâmpago | `killuo_godspeed` | Legendary | Storm Dice |
| Kiritsugo | `kiritsugo` | Rare | Arcane Dice |
| Kisuko | `kisuko` | Rare | Blade Dice |
| Kizaro | `kizaro` | Legendary | Premium Dice |
| Kurilo | `kurilo` | Rare | Starter Dice |
| Lanseiro | `lanseiro` | Rare | Storm Dice |
| Lanseiro Ardente | `lanseiro_mode` | Legendary | Premium Dice |
| Lau | `lau` | Epic | Arcane Dice |
| Lemilio | `lemilio` | Rare | Fighter Dice |
| Lufy | `lufy` | Rare | Fighter Dice |
| Lufy Serpente | `lufy_snake` | Mythic | Colossus Dice |
| Madaro | `madaro` | Divine | Forbidden Dice |
| Mighto | `mighto` | Epic | Colossus Dice |
| Mighto 5º Portão | `mighto_gate5` | Mythic | Colossus Dice |
| Mighto 8º Portão | `mighto_gate8` | Secret | Forbidden Dice |
| Mikaza | `mikaza` | Uncommon | Rampart Dice |
| Mikaza (Formal) | `mikaza_formal` | Common | Starter Dice |
| Minatu | `minatu` | Rare | Storm Dice |
| Narotu | `narotu` | Epic | Shinobi Dice |
| Narotu (Jovem) | `narotu_young` | Common | Shinobi Dice |
| Narotu Sábio | `narotu_sage` | Mythic | Celestial Dice |
| Natzu | `natzu` | Uncommon | Flame Dice |
| Natzu Desperto | `natzu_awakened` | Mythic | Awakened Dice |
| Nejo | `nejo` | Uncommon | Shinobi Dice |
| Ol Maito | `olmaito` | Legendary | Fighter Dice |
| Ol Maito Poder Total | `olmaito_mode` | Mythic | Celestial Dice |
| Peinn | `peinn` | Legendary | Shadow Dice |
| Pikkolo | `pikkolo` | Epic | Fighter Dice |
| Rika | `rika` | Epic | Arcane Dice |
| Rika Desperta | `rika_awakened` | Legendary | Awakened Dice |
| Rinn | `rinn` | Uncommon | Lucky Dice |
| Roque Li | `roqueli` | Uncommon | Shinobi Dice |
| Roque Li dos Portões | `roqueli_gates` | Mythic | Awakened Dice |
| Rukya | `rukya` | Rare | Lucky Dice |
| Sacha | `sacha` | Common | Starter Dice |
| Sacha (Terno) | `sacha_suit` | Common | Starter Dice |
| Saitano | `saitano` | Epic | Starter Dice |
| Samurai Afro | `samurai_afro` | Legendary | Premium Dice |
| Sanjo | `sanjo` | Legendary | Celestial Dice |
| Sanjo (Jovem) | `sanjo_young` | Common | Lucky Dice |
| Sasuko | `sasuko` | Legendary | Colossus Dice |
| Sasuko (Jovem) | `sasuko_young` | Common | Shinobi Dice |
| Seiba | `seiba` | Rare | Arcane Dice |
| Seiba Sombria | `seiba_alter` | Divine | Premium Dice |
| Shankz | `shankz` | Legendary | Blade Dice |
| Shinjo | `shinjo` | Epic | Shadow Dice |
| Shiro | `shiro` | Rare | Arcane Dice |
| Shunzo | `shunzo` | Epic | Spirit Dice |
| Starko | `starko` | Epic | Spirit Dice |
| Tanjiru | `tanjiru` | Epic | Blade Dice |
| Titã Feminina | `anny_titan` | Epic | Rampart Dice |
| Titã de Ataque | `erem_titan` | Epic | Rampart Dice |
| Todoruki | `todoruki` | Uncommon | Flame Dice |
| Toshiru | `toshiru` | Rare | Spirit Dice |
| Toshiru Bankai | `toshiru_bankai` | Secret | Premium Dice |
| Trunkz | `trunkz` | Rare | Blade Dice |
| Ulkiorra | `ulkiorra` | Epic | Shadow Dice |
| Ulkiorra Liberado | `ulkiorra_release` | Mythic | Void Dice |
| Vegitto | `vegitto` | Divine | Celestial Dice |
| Vegitto Azul | `vegitto_blue` | Secret | Forbidden Dice |
| Vejita | `vejita` | Epic | Void Dice |
| Vejita Majin | `vejita_majin` | Legendary | Void Dice |
| Yamamotu | `yamamotu` | Epic | Flame Dice |
| Yoruka | `yoruka` | Legendary | Spirit Dice |
| Yoruka Shunko | `yoruka_shunko` | Mythic | Premium Dice |
| Yujo | `yujo` | Legendary | Celestial Dice |
| Yuzuke | `yuzuke` | Uncommon | Fighter Dice |
| Yuzuke Demônio | `yuzuke_demon` | Mythic | Spirit Dice |
| Zabuzo | `zabuzo` | Rare | Shinobi Dice |
| Zoru | `zoru` | Epic | Blade Dice |
| Zoru (Jovem) | `zoru_young` | Uncommon | Blade Dice |

## Formas espalhadas pela progressão (exemplos)

- **aizo**: Aizo (Divino, Forbidden Dice) → Aizo Transcendido (Secreto, Reserva: Event Dice)
- **anny**: Anny (Colegial) (Comum, Starter Dice) → Anny (Incomum, Rampart Dice) → Titã Feminina (Épico, Rampart Dice)
- **bakugu**: Bakugu (Raro, Flame Dice) → Bakugu Desperto (Lendário, Awakened Dice)
- **brolli**: Brolli (Lendário, Colossus Dice) → Brolli Lendário (Divino, Forbidden Dice)
- **deko**: Deko (Incomum, Fighter Dice) → Deko Desperto (Lendário, Storm Dice) → Deko 100% (Divino, Celestial Dice)
- **dyo**: Dyo (Mítico, Reserva: Future Update) → Dyo Desperto (Divino, Reserva: Event Dice)
- **erem**: Erem (Comum, Rampart Dice) → Erem (Veterano) (Raro, Rampart Dice) → Titã de Ataque (Épico, Rampart Dice)
- **erwyn**: Erwyn (Gala) (Incomum, Starter Dice) → Erwyn (Raro, Rampart Dice)
- **goko**: Goko (Incomum, Fighter Dice) → Goko (Saga Majin) (Épico, Storm Dice)
- **goko_dark**: Goko Sombrio (Mítico, Shadow Dice) → Goko Sombrio Rosé (Mítico, Premium Dice)
- **gom**: Gom (Comum, Lucky Dice) → Gom Adulto (Mítico, Awakened Dice)
- **grei**: Grei (Raro, Lucky Dice) → Grei Desperto (Lendário, Awakened Dice)
- **ichiro**: Ichiro (Incomum, Blade Dice) → Ichiro Mascarado (Mítico, Shadow Dice) → Ichiro Vasto (Divino, Void Dice) → Ichiro Mugetsu (Secreto, Forbidden Dice)
- **ilumi**: Ilumi (Épico, Void Dice) → Ilumi Desperto (Lendário, Void Dice)
- **jolene**: Jolene (Lendário, Reserva: Future Update) → Jolene Desperta (Mítico, Reserva: Future Update)
- **jorno**: Jorno (Mítico, Reserva: Special Banner) → Jorno Chefe (Divino, Reserva: Limited Dice)
- **josef**: Josef (Raro, Reserva: Future Update) → Josef Veterano (Lendário, Reserva: Future Update)
- **killuo**: Killuo (Raro, Storm Dice) → Killuo Relâmpago (Lendário, Storm Dice)
- **lanseiro**: Lanseiro (Raro, Storm Dice) → Lanseiro Ardente (Lendário, Premium Dice)
- **lufy**: Lufy (Raro, Fighter Dice) → Lufy Serpente (Mítico, Colossus Dice)
- **mighto**: Mighto (Épico, Colossus Dice) → Mighto 5º Portão (Mítico, Colossus Dice) → Mighto 8º Portão (Secreto, Forbidden Dice)
- **mikaza**: Mikaza (Formal) (Comum, Starter Dice) → Mikaza (Incomum, Rampart Dice)
- **minatu**: Minatu (Raro, Storm Dice) → Minatu Manto de Chakra (Divino, Reserva: Future Update)
- **narotu**: Narotu (Jovem) (Comum, Shinobi Dice) → Narotu (Épico, Shinobi Dice) → Narotu Sábio (Mítico, Celestial Dice)
- **natzu**: Natzu (Incomum, Flame Dice) → Natzu Desperto (Mítico, Awakened Dice)
- **olmaito**: Ol Maito (Lendário, Fighter Dice) → Ol Maito Poder Total (Mítico, Celestial Dice)
- **rika**: Rika (Épico, Arcane Dice) → Rika Desperta (Lendário, Awakened Dice)
- **roqueli**: Roque Li (Incomum, Shinobi Dice) → Roque Li dos Portões (Mítico, Awakened Dice)
- **sacha**: Sacha (Comum, Starter Dice) → Sacha (Terno) (Comum, Starter Dice)
- **sanjo**: Sanjo (Jovem) (Comum, Lucky Dice) → Sanjo (Lendário, Celestial Dice)
- **sasuko**: Sasuko (Jovem) (Comum, Shinobi Dice) → Sasuko (Lendário, Colossus Dice)
- **seiba**: Seiba (Raro, Arcane Dice) → Seiba Sombria (Divino, Premium Dice)
- **shiro**: Shiro (Raro, Arcane Dice) → Emyia Arqueiro (Mítico, Arcane Dice)
- **toshiru**: Toshiru (Raro, Spirit Dice) → Toshiru Bankai (Secreto, Premium Dice)
- **ulkiorra**: Ulkiorra (Épico, Shadow Dice) → Ulkiorra Liberado (Mítico, Void Dice) → Ulkiorra Segunda Forma (Divino, Reserva: Event Dice)
- **vegitto**: Vegitto (Divino, Celestial Dice) → Vegitto Azul (Secreto, Forbidden Dice)
- **vejita**: Vejita (Épico, Void Dice) → Vejita Majin (Lendário, Void Dice)
- **yoruka**: Yoruka (Lendário, Spirit Dice) → Yoruka Shunko (Mítico, Premium Dice) → Yoruka Felina (Mítico, Reserva: Limited Dice)
- **yuzuke**: Yuzuke (Incomum, Fighter Dice) → Yuzuke Demônio (Mítico, Spirit Dice)
- **zoru**: Zoru (Jovem) (Incomum, Blade Dice) → Zoru (Épico, Blade Dice)
