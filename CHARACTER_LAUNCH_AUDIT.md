# CHARACTER LAUNCH AUDIT — Roll Legends

Gerado por `python tools/build_characters.py` a partir de `AnimePack.rbxm` (nenhum script do pack é executado). Assets em `assets/Characters.rbxm` → `ReplicatedStorage.CharacterAssets`. Roster do roll/Índice oficial NÃO muda nesta fase.

## Resumo

```
Launch characters: 121/121
F2P: 112/112
Premium: 9/9

Sanitizer: PASS (0 falha(s))
CharacterIds únicos: 121/121
Source models encontrados: 121/121
Factory: 121/121

Clothing (por AssetId único, 209 ids):
  OK: 0
  UNCHECKED: 207
  REVIEW_REQUIRED: 2
  OVERRIDDEN: 0

Optimization (orçamento: 40 peças, 300 instâncias):
  OK: 121
  NEEDS_OPTIMIZATION: 0

VFX (limites: 6 guardados, 2 no modo Light, 1 luz):
  OK: 86
  REVIEW: 35

Possíveis duplicatas: 5

Remoções visuais (objeto a objeto):
  VISUAL_REMOVED_JUSTIFIED: 638 (InvisibleCombatHelper 16, InvisibleHitbox 287, NameTag 214, RootPart 121)
  VISUAL_REMOVED_UNJUSTIFIED: 0
```

## Personagens

| CharacterId | DisplayName | SourceModelName | Rarity | LaunchPool | Dice | Family | FormTier | SourceParts | FinalParts | ClothingStatus | OptimizationStatus | VFXStatus | Result |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `char_anny_school` | Anny (Colegial) | Annie (Junior High) | Common | F2P | starter | anny | 1 | 8 | 7 | UNCHECKED | OK | OK | **OK (avisos)** |
| `char_mikaza_formal` | Mikaza (Formal) | Mikasa (Formal) | Common | F2P | starter | mikaza | 1 | 9 | 8 | UNCHECKED | OK | OK | **OK (avisos)** |
| `char_sacha_base` | Sacha | Sasha | Common | F2P | starter | sacha | 1 | 8 | 7 | UNCHECKED | OK | OK | **OK (avisos)** |
| `char_sacha_suit` | Sacha (Terno) | Sasha (Suit) | Common | F2P | starter | sacha | 1 | 8 | 7 | UNCHECKED | OK | OK | **OK (avisos)** |
| `char_chiko_base` | Chiko | Chika | Uncommon | F2P | starter | chiko | 1 | 13 | 9 | UNCHECKED | OK | OK | **OK** |
| `char_erwyn_gala` | Erwyn (Gala) | Erwin (Alt) | Uncommon | F2P | starter | erwyn | 1 | 8 | 7 | UNCHECKED | OK | OK | **OK (avisos)** |
| `char_kurilo_base` | Kurilo | Krillin | Rare | F2P | starter | kurilo | 1 | 11 | 7 | UNCHECKED | OK | OK | **OK** |
| `char_saitano_base` | Saitano | Saitama | Epic | F2P | starter | saitano | 1 | 13 | 9 | UNCHECKED | OK | OK | **OK** |
| `char_gom_base` | Gom | Gon | Common | F2P | lucky | gom | 1 | 12 | 8 | UNCHECKED | OK | OK | **OK** |
| `char_sanjo_young` | Sanjo (Jovem) | ptsSanji | Common | F2P | lucky | sanjo | 1 | 12 | 8 | UNCHECKED | OK | OK | **OK** |
| `char_kazumo_base` | Kazumo | Kazuma | Uncommon | F2P | lucky | kazumo | 1 | 13 | 9 | UNCHECKED | OK | REVIEW | **OK** |
| `char_rinn_base` | Rinn | Rin | Uncommon | F2P | lucky | rinn | 1 | 13 | 9 | UNCHECKED | OK | OK | **OK** |
| `char_grei_base` | Grei | Gray | Rare | F2P | lucky | grei | 1 | 13 | 9 | UNCHECKED | OK | OK | **OK** |
| `char_rukya_base` | Rukya | Rukia | Rare | F2P | lucky | rukya | 1 | 14 | 9 | UNCHECKED | OK | REVIEW | **OK** |
| `char_hizoka_base` | Hizoka | Hisoka | Epic | F2P | lucky | hizoka | 1 | 12 | 8 | UNCHECKED | OK | OK | **OK** |
| `char_erem_base` | Erem | Eren | Common | F2P | rampart | erem | 1 | 8 | 7 | UNCHECKED | OK | OK | **OK (avisos)** |
| `char_anny_base` | Anny | Annie | Uncommon | F2P | rampart | anny | 1 | 8 | 7 | UNCHECKED | OK | OK | **OK (avisos)** |
| `char_mikaza_base` | Mikaza | Mikasa | Uncommon | F2P | rampart | mikaza | 1 | 9 | 8 | UNCHECKED | OK | OK | **OK (avisos)** |
| `char_erem_veteran` | Erem (Veterano) | Eren Post-time skip | Rare | F2P | rampart | erem | 2 | 8 | 7 | UNCHECKED | OK | OK | **OK (avisos)** |
| `char_erwyn_base` | Erwyn | Erwin | Rare | F2P | rampart | erwyn | 1 | 9 | 8 | UNCHECKED | OK | OK | **OK (avisos)** |
| `char_anny_titan` | Titã Feminina | Female Titan | Epic | F2P | rampart | anny | 2 | 8 | 7 | UNCHECKED | OK | OK | **OK (avisos)** |
| `char_erem_titan` | Titã de Ataque | Attack Titan | Epic | F2P | rampart | erem | 3 | 9 | 8 | UNCHECKED | OK | OK | **OK (avisos)** |
| `char_natzu_base` | Natzu | Natsu | Uncommon | F2P | flame | natzu | 1 | 14 | 10 | UNCHECKED | OK | OK | **OK** |
| `char_todoruki_base` | Todoruki | Todoroki | Uncommon | F2P | flame | todoruki | 1 | 14 | 10 | UNCHECKED | OK | REVIEW | **OK** |
| `char_ase_base` | Ase | Ace | Rare | F2P | flame | ase | 1 | 15 | 11 | UNCHECKED | OK | OK | **OK** |
| `char_bakugu_base` | Bakugu | Bakugo | Rare | F2P | flame | bakugu | 1 | 24 | 20 | UNCHECKED | OK | OK | **OK** |
| `char_yamamotu_base` | Yamamotu | Yamamoto | Epic | F2P | flame | yamamotu | 1 | 15 | 11 | UNCHECKED | OK | OK | **OK** |
| `char_akaino_base` | Akaino | Akainu | Legendary | F2P | flame | akaino | 1 | 27 | 23 | UNCHECKED | OK | OK | **OK** |
| `char_narotu_young` | Narotu (Jovem) | ptsNaruto | Common | F2P | shinobi | narotu | 1 | 12 | 8 | UNCHECKED | OK | OK | **OK** |
| `char_sasuko_young` | Sasuko (Jovem) | ptsSasuke | Common | F2P | shinobi | sasuko | 1 | 13 | 9 | UNCHECKED | OK | OK | **OK** |
| `char_nejo_base` | Nejo | Neji | Uncommon | F2P | shinobi | nejo | 1 | 13 | 9 | UNCHECKED | OK | OK | **OK** |
| `char_roqueli_base` | Roque Li | Rock Lee | Uncommon | F2P | shinobi | roqueli | 1 | 17 | 13 | UNCHECKED | OK | OK | **OK** |
| `char_gaaro_base` | Gaaro | Gaara | Rare | F2P | shinobi | gaaro | 1 | 21 | 17 | UNCHECKED | OK | OK | **OK** |
| `char_zabuzo_base` | Zabuzo | Zabuza | Rare | F2P | shinobi | zabuzo | 1 | 16 | 11 | UNCHECKED | OK | OK | **OK** |
| `char_kakaxi_base` | Kakaxi | Kakashi | Epic | F2P | shinobi | kakaxi | 1 | 17 | 10 | UNCHECKED | OK | OK | **OK** |
| `char_narotu_base` | Narotu | tsNaruto | Epic | F2P | shinobi | narotu | 2 | 12 | 8 | UNCHECKED | OK | OK | **OK** |
| `char_ichiro_base` | Ichiro | Ichigo | Uncommon | F2P | blade | ichiro | 1 | 14 | 9 | UNCHECKED | OK | OK | **OK** |
| `char_zoru_young` | Zoru (Jovem) | ptsZoro | Uncommon | F2P | blade | zoru | 1 | 22 | 15 | UNCHECKED | OK | REVIEW | **OK** |
| `char_ginn_base` | Ginn | Gin | Rare | F2P | blade | ginn | 1 | 15 | 11 | UNCHECKED | OK | OK | **OK** |
| `char_kisuko_base` | Kisuko | Kisuke | Rare | F2P | blade | kisuko | 1 | 17 | 12 | UNCHECKED | OK | REVIEW | **OK** |
| `char_trunkz_base` | Trunkz | Trunks | Rare | F2P | blade | trunkz | 1 | 19 | 14 | UNCHECKED | OK | OK | **OK** |
| `char_tanjiru_base` | Tanjiru | Tanjiro | Epic | F2P | blade | tanjiru | 1 | 16 | 12 | UNCHECKED | OK | REVIEW | **OK** |
| `char_zoru_base` | Zoru | tsZoro | Epic | F2P | blade | zoru | 2 | 22 | 15 | UNCHECKED | OK | REVIEW | **OK** |
| `char_shankz_base` | Shankz | Shanks | Legendary | F2P | blade | shankz | 1 | 25 | 15 | UNCHECKED | OK | OK | **OK** |
| `char_deko_base` | Deko | Deku | Uncommon | F2P | fighter | deko | 1 | 15 | 11 | UNCHECKED | OK | REVIEW | **OK** |
| `char_goko_base` | Goko | Goku | Uncommon | F2P | fighter | goko | 1 | 12 | 8 | UNCHECKED | OK | OK | **OK** |
| `char_yuzuke_base` | Yuzuke | Yusuke | Uncommon | F2P | fighter | yuzuke | 1 | 12 | 8 | UNCHECKED | OK | OK | **OK** |
| `char_lemilio_base` | Lemilio | Lemillion | Rare | F2P | fighter | lemilio | 1 | 15 | 11 | UNCHECKED | OK | OK | **OK** |
| `char_lufy_base` | Lufy | tsLuffy | Rare | F2P | fighter | lufy | 2 | 17 | 13 | UNCHECKED | OK | OK | **OK** |
| `char_pikkolo_base` | Pikkolo | Piccolo | Epic | F2P | fighter | pikkolo | 1 | 17 | 12 | UNCHECKED | OK | OK | **OK** |
| `char_olmaito_base` | Ol Maito | All Might | Legendary | F2P | fighter | olmaito | 1 | 12 | 8 | UNCHECKED | OK | OK | **OK** |
| `char_killuo_base` | Killuo | Killua | Rare | F2P | storm | killuo | 1 | 12 | 8 | REVIEW_REQUIRED | OK | OK | **OK (avisos)** |
| `char_lanseiro_base` | Lanseiro | Lancer | Rare | F2P | storm | lanseiro | 1 | 18 | 14 | UNCHECKED | OK | REVIEW | **OK** |
| `char_minatu_base` | Minatu | Minato | Rare | F2P | storm | minatu | 1 | 14 | 9 | UNCHECKED | OK | OK | **OK** |
| `char_goko_majin_saga` | Goko (Saga Majin) | Buu Saga Goku | Epic | F2P | storm | goko | 2 | 14 | 8 | UNCHECKED | OK | OK | **OK** |
| `char_kaulifa_base` | Kaulifa | Caulifa | Epic | F2P | storm | kaulifa | 1 | 13 | 8 | UNCHECKED | OK | OK | **OK** |
| `char_deko_awakened` | Deko Desperto | Deku Awakened | Legendary | F2P | storm | deko | 2 | 15 | 11 | UNCHECKED | OK | REVIEW | **OK** |
| `char_killuo_godspeed` | Killuo Relâmpago | Killua Godspeed | Legendary | F2P | storm | killuo | 2 | 13 | 8 | REVIEW_REQUIRED | OK | REVIEW | **OK (avisos)** |
| `char_toshiru_base` | Toshiru | Toshiro | Rare | F2P | spirit | toshiru | 1 | 17 | 13 | UNCHECKED | OK | REVIEW | **OK** |
| `char_byakuto_base` | Byakuto | Byakuya | Epic | F2P | spirit | byakuto | 1 | 15 | 11 | UNCHECKED | OK | REVIEW | **OK** |
| `char_shunzo_base` | Shunzo | Shunsui | Epic | F2P | spirit | shunzo | 1 | 22 | 18 | UNCHECKED | OK | OK | **OK** |
| `char_starko_base` | Starko | Starrk | Epic | F2P | spirit | starko | 1 | 16 | 10 | UNCHECKED | OK | REVIEW | **OK** |
| `char_hiey_base` | Hiey | Hiei | Legendary | F2P | spirit | hiey | 1 | 21 | 13 | UNCHECKED | OK | OK | **OK** |
| `char_yoruka_base` | Yoruka | Yoruichi | Legendary | F2P | spirit | yoruka | 1 | 13 | 9 | UNCHECKED | OK | OK | **OK** |
| `char_yuzuke_demon` | Yuzuke Demônio | Yusuke Mode | Mythic | F2P | spirit | yuzuke | 2 | 13 | 8 | UNCHECKED | OK | OK | **OK** |
| `char_kiritsugo_base` | Kiritsugo | Kiritsugu | Rare | F2P | arcane | kiritsugo | 1 | 13 | 9 | UNCHECKED | OK | OK | **OK** |
| `char_seiba_base` | Seiba | Saber | Rare | F2P | arcane | seiba | 1 | 16 | 11 | UNCHECKED | OK | REVIEW | **OK** |
| `char_shiro_base` | Shiro | Shirou | Rare | F2P | arcane | shiro | 1 | 18 | 12 | UNCHECKED | OK | OK | **OK** |
| `char_akcel_base` | Akcel | Accel | Epic | F2P | arcane | akcel | 1 | 14 | 10 | UNCHECKED | OK | OK | **OK** |
| `char_lau_base` | Lau | ptsLaw | Epic | F2P | arcane | lau | 1 | 15 | 10 | UNCHECKED | OK | REVIEW | **OK** |
| `char_rika_base` | Rika | Rikka | Epic | F2P | arcane | rika | 1 | 15 | 11 | UNCHECKED | OK | REVIEW | **OK** |
| `char_gilgamex_base` | Gilgamex | Gilgamesh | Legendary | F2P | arcane | gilgamex | 1 | 16 | 12 | UNCHECKED | OK | OK | **OK** |
| `char_shiro_archer` | Emyia Arqueiro | Archer (EMIYA) | Mythic | F2P | arcane | shiro | 2 | 18 | 12 | UNCHECKED | OK | REVIEW | **OK** |
| `char_grimjau_base` | Grimjau | Grimmjow | Epic | F2P | shadow | grimjau | 1 | 21 | 10 | UNCHECKED | OK | OK | **OK** |
| `char_shinjo_base` | Shinjo | Shinji | Epic | F2P | shadow | shinjo | 1 | 19 | 11 | UNCHECKED | OK | REVIEW | **OK** |
| `char_ulkiorra_base` | Ulkiorra | Ulq | Epic | F2P | shadow | ulkiorra | 1 | 18 | 14 | UNCHECKED | OK | REVIEW | **OK** |
| `char_itaxi_base` | Itaxi | Itachi | Legendary | F2P | shadow | itaxi | 1 | 13 | 9 | UNCHECKED | OK | OK | **OK** |
| `char_peinn_base` | Peinn | Pain | Legendary | F2P | shadow | peinn | 1 | 13 | 9 | UNCHECKED | OK | OK | **OK** |
| `char_goko_dark_base` | Goko Sombrio | Goku Black [NEW] | Mythic | F2P | shadow | goko_dark | 1 | 19 | 15 | UNCHECKED | OK | OK | **OK** |
| `char_ichiro_hollow` | Ichiro Mascarado | Hollow Ichigo | Mythic | F2P | shadow | ichiro | 2 | 16 | 11 | UNCHECKED | OK | OK | **OK** |
| `char_ilumi_base` | Ilumi | Illumi | Epic | F2P | void | ilumi | 1 | 13 | 9 | UNCHECKED | OK | OK | **OK** |
| `char_vejita_base` | Vejita | Vegeta | Epic | F2P | void | vejita | 1 | 43 | 39 | UNCHECKED | OK (catálogo: NEEDS_OPTIMIZATION) | OK | **OK** |
| `char_ilumi_awakened` | Ilumi Desperto | Illumi Awakened | Legendary | F2P | void | ilumi | 2 | 15 | 10 | UNCHECKED | OK | REVIEW | **OK** |
| `char_vejita_majin` | Vejita Majin | Majin Vegeta | Legendary | F2P | void | vejita | 2 | 13 | 9 | UNCHECKED | OK | OK | **OK** |
| `char_ulkiorra_release` | Ulkiorra Liberado | R1 | Mythic | F2P | void | ulkiorra | 2 | 18 | 14 | UNCHECKED | OK | REVIEW | **OK (avisos)** |
| `char_ichiro_vasto` | Ichiro Vasto | Vasto | Divine | F2P | void | ichiro | 3 | 17 | 12 | UNCHECKED | OK | OK | **OK** |
| `char_bakugu_awakened` | Bakugu Desperto | Awakened Bakugo | Legendary | F2P | awakened | bakugu | 2 | 24 | 20 | UNCHECKED | OK | OK | **OK** |
| `char_grei_awakened` | Grei Desperto | Grey Awakening | Legendary | F2P | awakened | grei | 2 | 13 | 9 | UNCHECKED | OK | REVIEW | **OK** |
| `char_rika_awakened` | Rika Desperta | Rikka Awakened | Legendary | F2P | awakened | rika | 2 | 20 | 15 | UNCHECKED | OK | REVIEW | **OK (avisos)** |
| `char_gom_adult` | Gom Adulto | Adult Gon | Mythic | F2P | awakened | gom | 2 | 12 | 8 | UNCHECKED | OK | OK | **OK (avisos)** |
| `char_natzu_awakened` | Natzu Desperto | Natsu Awakened | Mythic | F2P | awakened | natzu | 2 | 14 | 10 | UNCHECKED | OK | REVIEW | **OK** |
| `char_roqueli_gates` | Roque Li dos Portões | ROCK LEE GATES | Mythic | F2P | awakened | roqueli | 2 | 17 | 13 | UNCHECKED | OK | OK | **OK** |
| `char_gohin_base` | Gohin | Gohan | Epic | F2P | colossus | gohin | 1 | 13 | 8 | UNCHECKED | OK | OK | **OK** |
| `char_mighto_base` | Mighto | Might Guy | Epic | F2P | colossus | mighto | 1 | 13 | 9 | UNCHECKED | OK | OK | **OK** |
| `char_brolli_base` | Brolli | Broly | Legendary | F2P | colossus | brolli | 1 | 13 | 9 | UNCHECKED | OK | OK | **OK** |
| `char_sasuko_base` | Sasuko | tsSasuke | Legendary | F2P | colossus | sasuko | 2 | 25 | 16 | UNCHECKED | OK | REVIEW | **OK** |
| `char_lufy_snake` | Lufy Serpente | Snakeman | Mythic | F2P | colossus | lufy | 3 | 22 | 18 | UNCHECKED | OK | OK | **OK** |
| `char_mighto_gate5` | Mighto 5º Portão | 5TH GATE | Mythic | F2P | colossus | mighto | 2 | 16 | 11 | UNCHECKED | OK (catálogo: NEEDS_OPTIMIZATION) | REVIEW | **OK** |
| `char_sanjo_base` | Sanjo | TS SANJI | Legendary | F2P | celestial | sanjo | 2 | 12 | 8 | UNCHECKED | OK | OK | **OK** |
| `char_yujo_base` | Yujo | Yuji | Legendary | F2P | celestial | yujo | 1 | 15 | 11 | UNCHECKED | OK | OK | **OK** |
| `char_narotu_sage` | Narotu Sábio | Sage Mode | Mythic | F2P | celestial | narotu | 3 | 13 | 9 | UNCHECKED | OK | OK | **OK (avisos)** |
| `char_olmaito_mode` | Ol Maito Poder Total | All Might (MODE) | Mythic | F2P | celestial | olmaito | 2 | 13 | 8 | UNCHECKED | OK | OK | **OK** |
| `char_deko_full` | Deko 100% | 100% Deku | Divine | F2P | celestial | deko | 3 | 21 | 17 | UNCHECKED | OK | REVIEW | **OK** |
| `char_goju_base` | Goju | Gojo Satoru | Divine | F2P | celestial | goju | 1 | 17 | 12 | UNCHECKED | OK | OK | **OK** |
| `char_vegitto_base` | Vegitto | VEGITO | Divine | F2P | celestial | vegitto | 1 | 15 | 11 | UNCHECKED | OK | OK | **OK** |
| `char_barbalva_base` | Barbalva | Whitebeard | Mythic | F2P | forbidden | barbalva | 1 | 17 | 13 | UNCHECKED | OK | OK | **OK** |
| `char_aizo_base` | Aizo | Aizen | Divine | F2P | forbidden | aizo | 1 | 14 | 10 | UNCHECKED | OK | REVIEW | **OK** |
| `char_brolli_legend` | Brolli Lendário | LSSJ BROLY | Divine | F2P | forbidden | brolli | 2 | 14 | 8 | UNCHECKED | OK | OK | **OK** |
| `char_madaro_base` | Madaro | Madara | Divine | F2P | forbidden | madaro | 1 | 15 | 10 | UNCHECKED | OK | OK | **OK** |
| `char_ichiro_mugetsu` | Ichiro Mugetsu | Mugetsu | Secret | F2P | forbidden | ichiro | 4 | 17 | 10 | UNCHECKED | OK | OK | **OK** |
| `char_mighto_gate8` | Mighto 8º Portão | 8TH GATE | Secret | F2P | forbidden | mighto | 3 | 14 | 10 | UNCHECKED | OK (catálogo: NEEDS_OPTIMIZATION) | REVIEW | **OK** |
| `char_vegitto_blue` | Vegitto Azul | VEGITO BLUE | Secret | F2P | forbidden | vegitto | 2 | 15 | 11 | UNCHECKED | OK | OK | **OK** |
| `char_infernus_base` | Infernus | Hellflame | Epic | Premium | premium | infernus | 1 | 25 | 21 | UNCHECKED | OK | REVIEW | **OK** |
| `char_iskander_base` | Iskander | Iskandar | Epic | Premium | premium | iskander | 1 | 20 | 16 | UNCHECKED | OK | OK | **OK** |
| `char_kizaro_base` | Kizaro | Kizaru | Legendary | Premium | premium | kizaro | 1 | 21 | 17 | UNCHECKED | OK | OK | **OK** |
| `char_lanseiro_mode` | Lanseiro Ardente | Lancer Mode | Legendary | Premium | premium | lanseiro | 2 | 18 | 16 | UNCHECKED | OK | REVIEW | **OK** |
| `char_samurai_afro_base` | Samurai Afro | Afro Samurai | Legendary | Premium | premium | samurai_afro | 1 | 25 | 21 | UNCHECKED | OK | REVIEW | **OK** |
| `char_goko_dark_rose` | Goko Sombrio Rosé | SSJR | Mythic | Premium | premium | goko_dark | 2 | 21 | 16 | UNCHECKED | OK | OK | **OK** |
| `char_yoruka_shunko` | Yoruka Shunko | Shunko Yoruichi | Mythic | Premium | premium | yoruka | 2 | 13 | 9 | UNCHECKED | OK | OK | **OK** |
| `char_seiba_alter` | Seiba Sombria | SALTER | Divine | Premium | premium | seiba | 2 | 22 | 16 | UNCHECKED | OK | REVIEW | **OK** |
| `char_toshiru_bankai` | Toshiru Bankai | Bankai Toshiro | Secret | Premium | premium | toshiru | 2 | 24 | 20 | UNCHECKED | OK | REVIEW | **OK (avisos)** |

## FAIL / MISSING_SOURCE (0)

Nenhum.

## Roupa REVIEW_REQUIRED (2)

- `char_killuo_base` (Killuo): Pants 2065252088, Shirt 2065247269 (CLOTHING_AUDIT.md)
- `char_killuo_godspeed` (Killuo Relâmpago): Pants 2065252088, Shirt 2065247269 (CLOTHING_AUDIT.md)

## NEEDS_OPTIMIZATION (0)

Nenhum.

## VFX REVIEW (35)

- `char_kazumo_base` (Kazumo): fora da whitelist (golpe/rastro): Trail
- `char_rukya_base` (Rukya): fora da whitelist (golpe/rastro): Trail
- `char_todoruki_base` (Todoruki): fora da whitelist (golpe/rastro): ChargeParticle2
- `char_zoru_young` (Zoru (Jovem)): fora da whitelist (golpe/rastro): Trail
- `char_kisuko_base` (Kisuko): fora da whitelist (golpe/rastro): NoBlade2, Trail
- `char_tanjiru_base` (Tanjiru): fora da whitelist (golpe/rastro): FireTrail1, FireTrail2, Trail, WaterTrail1, WaterTrail2
- `char_zoru_base` (Zoru): fora da whitelist (golpe/rastro): Trail
- `char_deko_base` (Deko): fora da whitelist (golpe/rastro): ChargeParticle2
- `char_lanseiro_base` (Lanseiro): fora da whitelist (golpe/rastro): ChargeParticle, ChargeParticle2, ShootParticle, Trail, Trail1, Trail2
- `char_deko_awakened` (Deko Desperto): fora da whitelist (golpe/rastro): ChargeParticle2, ShootParticle
- `char_killuo_godspeed` (Killuo Relâmpago): 10 efeito(s) próprio(s) acima do limite
- `char_toshiru_base` (Toshiru): fora da whitelist (golpe/rastro): Trail
- `char_byakuto_base` (Byakuto): fora da whitelist (golpe/rastro): NoBlade, NoBlade2, Trail
- `char_starko_base` (Starko): fora da whitelist (golpe/rastro): Trail
- `char_seiba_base` (Seiba): fora da whitelist (golpe/rastro): Charge
- `char_lau_base` (Lau): fora da whitelist (golpe/rastro): Trail
- `char_rika_base` (Rika): fora da whitelist (golpe/rastro): ChargeParticle, ChargeParticle2, ShootParticle
- `char_shiro_archer` (Emyia Arqueiro): 1 efeito(s) próprio(s) acima do limite; fora da whitelist (golpe/rastro): SmallShoot
- `char_shinjo_base` (Shinjo): fora da whitelist (golpe/rastro): Trail
- `char_ulkiorra_base` (Ulkiorra): fora da whitelist (golpe/rastro): Trail
- `char_ilumi_awakened` (Ilumi Desperto): fora da whitelist (golpe/rastro): Beam
- `char_ulkiorra_release` (Ulkiorra Liberado): fora da whitelist (golpe/rastro): Trail
- `char_grei_awakened` (Grei Desperto): 8 efeito(s) próprio(s) acima do limite
- `char_rika_awakened` (Rika Desperta): fora da whitelist (golpe/rastro): ChargeParticle, ChargeParticle2, ShootParticle
- `char_natzu_awakened` (Natzu Desperto): 3 efeito(s) próprio(s) acima do limite; fora da whitelist (golpe/rastro): ShootParticle, SmallShoot
- `char_sasuko_base` (Sasuko): fora da whitelist (golpe/rastro): ChargeParticle2
- `char_mighto_gate5` (Mighto 5º Portão): fora da whitelist (golpe/rastro): Beam1, Beam10, Beam11, Beam12, Beam13, Beam14, Beam15, Beam16, Beam17, Beam18, Beam19, Beam2, Beam20, Beam21, Beam22, Beam23, Beam24, Beam25, Beam26, Beam27, Beam3, Beam4, Beam5, Beam6, Beam7, Beam8, Beam9, LeftEyeTrail, RightEyeTrail
- `char_deko_full` (Deko 100%): fora da whitelist (golpe/rastro): ShootParticle, SmallShoot
- `char_aizo_base` (Aizo): fora da whitelist (golpe/rastro): Trail
- `char_mighto_gate8` (Mighto 8º Portão): fora da whitelist (golpe/rastro): Beam1, Beam10, Beam11, Beam12, Beam13, Beam14, Beam15, Beam16, Beam17, Beam18, Beam19, Beam2, Beam20, Beam21, Beam22, Beam23, Beam24, Beam25, Beam26, Beam27, Beam28, Beam3, Beam4, Beam5, Beam6, Beam7, Beam8, Beam9, LeftEyeTrail, RightEyeTrail
- `char_infernus_base` (Infernus): 7 efeito(s) próprio(s) acima do limite
- `char_lanseiro_mode` (Lanseiro Ardente): 2 efeito(s) próprio(s) acima do limite; fora da whitelist (golpe/rastro): ChargeParticle, ChargeParticle2, ShootParticle, Trail, Trail1, Trail2
- `char_samurai_afro_base` (Samurai Afro): fora da whitelist (golpe/rastro): Beam
- `char_seiba_alter` (Seiba Sombria): fora da whitelist (golpe/rastro): Charge
- `char_toshiru_bankai` (Toshiru Bankai): fora da whitelist (golpe/rastro): Trail

## VISUAL_REMOVED_UNJUSTIFIED (0)

Nenhuma: todo objeto visual removido tem regra e motivo registrados.

## VISUAL_REMOVED_JUSTIFIED (638)

Regras: NameTag (placa de título), ForbiddenContainer (LocalStand/BattleScript/Animate), RootPart (raiz invisível), InvisibleHitbox (Transparency ≥ 0.99 sem nada visível), InvisibleCombatHelper (Transparency ≥ 0.99; só aparecia pelos VFX de combate removidos), ForbiddenClass (só quando invisível).

| CharacterId | Regra | Classe | Nome | Caminho | Transparency | Size | MeshId | TextureId | Decals | Weld/Motor6D | Parte do corpo | VFX dentro | Motivo |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `char_aizo_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_aizo_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; SwordWeld (Weld) -> Sword; EnergySwordRWeld (Weld) -> nil; SwordWeldOld (Weld) -> nil; ExtendingBladeWeld (Weld) -> nil; RealHiltWeld (Weld) -> nil; BladeWeld (Weld) -> nil; ExtendingBladeWeldOld (Weld) -> nil; RealHiltWeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil; ExtendingBladeWeldOld (Weld) -> nil; RealHiltWeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil; ExtendingBladeWeldOld (Weld) -> nil; RealHiltWeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil; ExtendingBladeWeldOld (Weld) -> nil; RealHiltWeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil; ExtendingBladeWeldOld (Weld) -> nil; RealHiltWeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil; ExtendingBladeWeldOld (Weld) -> nil; RealHiltWeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil; ExtendingBladeWeldOld (Weld) -> nil; RealHiltWeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil; ExtendingBladeWeldOld (Weld) -> nil; RealHiltWeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil; FakeSwordWeld (Weld) -> nil; SwordWeldOld (Weld) -> nil; RFurWeld (Weld) -> nil; RBladeWeld (Weld) -> nil; RGuardWeld (Weld) -> nil; RGoldWeld (Weld) -> nil; SwordWeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil; ShikaiWeld (Weld) -> nil; SwordWeldOld (Weld) -> nil; ShikaiWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil; ShikaiWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_aizo_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm; EnergySwordLWeld (Weld) -> nil; LFurWeld (Weld) -> nil; LBladeWeld (Weld) -> nil; LGuardWeld (Weld) -> nil; LGoldWeld (Weld) -> nil | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_aizo_base` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_aizo_base` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_akaino_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_akaino_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_akaino_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_akaino_base` | NameTag | Part | Head | [ X ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_akaino_base` | NameTag | SpecialMesh | Mesh | [ X ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_akcel_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_akcel_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_akcel_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_akcel_base` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_akcel_base` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_anny_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | — | Torso | — | HumanoidRootPart: peça raiz do rig |
| `char_anny_school` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | — | Torso | — | HumanoidRootPart: peça raiz do rig |
| `char_anny_titan` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 4.71 × 4.71 × 2.35 | — | — | — | — | Torso | — | HumanoidRootPart: peça raiz do rig |
| `char_ase_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_ase_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; SwordDrawn1Weld (Weld) -> nil; KitetsuWeld (Weld) -> nil; HiltWeld (Weld) -> nil; Blade2Weld (Weld) -> nil; BladeWeld (Weld) -> nil; HiltWeldOld (Weld) -> nil; Blade2WeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_ase_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm; SwordHiltWeld (Weld) -> nil; SheathWeld (Weld) -> nil; ShisuiWeld (Weld) -> nil | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_ase_base` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_ase_base` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_bakugu_awakened` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_bakugu_awakened` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_bakugu_awakened` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_bakugu_awakened` | NameTag | Part | Head | [ X ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_bakugu_awakened` | NameTag | SpecialMesh | Mesh | [ X ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_bakugu_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_bakugu_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_bakugu_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_bakugu_base` | NameTag | Part | Head | [ X ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_bakugu_base` | NameTag | SpecialMesh | Mesh | [ X ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_barbalva_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 5.13 × 5.13 × 2.56 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_barbalva_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 2.56 × 0.13 × 2.56 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; QuakebubbleWeld (Weld) -> Quakebubble; BisentoWeld (Weld) -> Bisento; BladeUnionWeld (Weld) -> nil; HiltWeld (Weld) -> nil; Blade2Weld (Weld) -> nil; BladeWeld (Weld) -> nil; KitetsuWeld (Weld) -> nil; KitetsuWeldOld (Weld) -> nil; HiltWeldOld (Weld) -> nil; Blade2WeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil; SwordDrawn1Weld (Weld) -> nil; KitetsuWeldOld (Weld) -> nil; HiltWeldOld (Weld) -> nil; Blade2WeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil; HiltWeldOld (Weld) -> nil; Blade2WeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_barbalva_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 2.56 × 0.13 × 2.56 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm; ShisuiWeld (Weld) -> nil; ShisuiWeldOld (Weld) -> nil; SwordHiltWeld (Weld) -> nil; SheathWeld (Weld) -> nil; ShisuiWeldOld (Weld) -> nil | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_barbalva_base` | InvisibleCombatHelper | Part | Quakebubble | Morph.Quakebubble | 1.00 | 4.44 × 4.44 × 4.44 | — | — | — | QuakebubbleWeld (Weld) -> RightHilt | RightArm | ParticleEmitter FX | Transparency=1.00; o único conteúdo visível eram VFX removidos pela política de VFX (ParticleEmitter FX) |
| `char_barbalva_base` | InvisibleCombatHelper | SpecialMesh | Mesh | Morph.Quakebubble.Mesh | 1.00 | — | — | — | — | — | — | — | Transparency=1.00; o único conteúdo visível eram VFX removidos pela política de VFX (ParticleEmitter FX) (removido junto com Part "Quakebubble") |
| `char_brolli_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_brolli_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; HiltWeld (Weld) -> nil; Blade2Weld (Weld) -> nil; BladeWeld (Weld) -> nil; HiltWeldOld (Weld) -> nil; Blade2WeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_brolli_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm; MinatoKunaiWeld (Weld) -> nil | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_brolli_base` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_brolli_base` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_brolli_legend` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_brolli_legend` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_brolli_legend` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_brolli_legend` | NameTag | Part | Head | [ X ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_brolli_legend` | InvisibleHitbox | Part | Start2 | Morph.Start2 | 1.00 | 2.00 × 2.00 × 2.00 | — | — | — | Start2Weld (Weld) -> Head; Weld (ManualWeld) -> Start | Head | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_brolli_legend` | InvisibleHitbox | Part | Start | Morph.Start | 1.00 | 1.00 × 0.80 × 1.00 | — | — | — | StartWeld (Weld) -> Head; Weld (ManualWeld) -> Start2; AccessoryWeld (Weld) -> nil | Head | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_brolli_legend` | NameTag | SpecialMesh | Mesh | [ X ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_brolli_legend` | InvisibleHitbox | SpecialMesh | Mesh | Morph.Start2.Mesh | 1.00 | — | http://www.roblox.com/asset/?id=16627529 | rbxassetid://652531618 | — | — | — | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) (removido junto com Part "Start2") |
| `char_brolli_legend` | InvisibleHitbox | SpecialMesh | Mesh | Morph.Start.Mesh | 1.00 | — | rbxassetid://459797800 | rbxassetid://652531618 | — | — | — | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) (removido junto com Part "Start") |
| `char_byakuto_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_byakuto_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; BladeWeld (Weld) -> Blade; SwordWeld (Weld) -> Sword; ShikaiWeld (Weld) -> nil; SwordWeldOld (Weld) -> nil; ShikaiWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil; ShikaiWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_byakuto_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_byakuto_base` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_byakuto_base` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_chiko_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | SheathWeld (Weld) -> nil; Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_chiko_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | SharpWeld (Weld) -> nil; BladeWeld (Weld) -> nil; HandleWeld (Weld) -> nil; SwordWeld (Weld) -> nil; KazumaBowWeld (Weld) -> nil; SwordWeldOld (Weld) -> nil; Right Arm 🡪 RightHilt (Motor6D) -> Right Arm | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_chiko_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_chiko_base` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_chiko_base` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_deko_awakened` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_deko_awakened` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_deko_awakened` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_deko_awakened` | NameTag | Part | Head | [ X ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_deko_awakened` | NameTag | SpecialMesh | Mesh | [ X ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_deko_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_deko_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_deko_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_deko_base` | NameTag | Part | Head | [ X ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_deko_base` | NameTag | SpecialMesh | Mesh | [ X ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_deko_full` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_deko_full` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_deko_full` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_deko_full` | NameTag | Part | Head | [ X ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_deko_full` | NameTag | SpecialMesh | Mesh | [ X ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_erem_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | — | Torso | — | HumanoidRootPart: peça raiz do rig |
| `char_erem_titan` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 4.32 × 4.32 × 2.16 | — | — | — | — | Torso | — | HumanoidRootPart: peça raiz do rig |
| `char_erem_veteran` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | — | Torso | — | HumanoidRootPart: peça raiz do rig |
| `char_erwyn_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | — | Torso | — | HumanoidRootPart: peça raiz do rig |
| `char_erwyn_gala` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | — | Torso | — | HumanoidRootPart: peça raiz do rig |
| `char_gaaro_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat, ParticleEmitter SandBlock, ParticleEmitter FeetParticle | HumanoidRootPart: peça raiz do rig |
| `char_gaaro_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; ExecutionersWeld (Weld) -> nil; ExecutionersWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_gaaro_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_gaaro_base` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_gaaro_base` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_gilgamex_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_gilgamex_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; SpecialBladeWeld (Weld) -> nil; ExcaliburWeld (Weld) -> nil; RightSwordEXWeld (Weld) -> nil; RightSwordWeld (Weld) -> nil; ShirouPipeWeld (Weld) -> nil; RightSwordEXWeldOld (Weld) -> nil; RightSwordWeldOld (Weld) -> nil; ShirouPipeWeldOld (Weld) -> nil; HiltWeld (Weld) -> nil; Blade2Weld (Weld) -> nil; BladeWeld (Weld) -> nil; SharpWeld (Weld) -> nil; BladeWeldOld (Weld) -> nil; HandleWeld (Weld) -> nil; SwordWeld (Weld) -> nil; KazumaBowWeld (Weld) -> nil; SwordWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_gilgamex_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm; LeftSwordEXWeld (Weld) -> nil; LeftSwordWeld (Weld) -> nil; LeftSwordEXWeldOld (Weld) -> nil; LeftSwordWeldOld (Weld) -> nil; SheathWeld (Weld) -> nil | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_gilgamex_base` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_gilgamex_base` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_ginn_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_ginn_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; BladeWeld (Weld) -> Blade; RealHiltWeld (Weld) -> RealHilt; ExtendingBladeWeld (Weld) -> ExtendingBlade; ExtendingBladeWeldOld (Weld) -> nil; RealHiltWeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil; ExtendingBladeWeldOld (Weld) -> nil; RealHiltWeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil; ExtendingBladeWeldOld (Weld) -> nil; RealHiltWeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil; ExtendingBladeWeldOld (Weld) -> nil; RealHiltWeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil; ExtendingBladeWeldOld (Weld) -> nil; RealHiltWeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil; ExtendingBladeWeldOld (Weld) -> nil; RealHiltWeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil; ExtendingBladeWeldOld (Weld) -> nil; RealHiltWeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil; ExtendingBladeWeldOld (Weld) -> nil; RealHiltWeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil; FakeSwordWeld (Weld) -> nil; SwordWeld (Weld) -> nil; RFurWeld (Weld) -> nil; RBladeWeld (Weld) -> nil; RGuardWeld (Weld) -> nil; RGoldWeld (Weld) -> nil; SwordWeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil; ShikaiWeld (Weld) -> nil; SwordWeldOld (Weld) -> nil; ShikaiWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil; ShikaiWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_ginn_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm; LFurWeld (Weld) -> nil; LBladeWeld (Weld) -> nil; LGuardWeld (Weld) -> nil; LGoldWeld (Weld) -> nil | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_ginn_base` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_ginn_base` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_gohin_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_gohin_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; HiltWeld (Weld) -> nil; Blade2Weld (Weld) -> nil; BladeWeld (Weld) -> nil; HiltWeldOld (Weld) -> nil; Blade2WeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_gohin_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_gohin_base` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_gohin_base` | InvisibleHitbox | MeshPart | SSJ2 | Morph.SSJ2 | 1.00 | 2.36 × 2.35 × 2.40 | rbxassetid://560186510 | — | — | SSJ2Weld (Weld) -> Head | Head | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_gohin_base` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_goju_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | SheathWeld (Weld) -> nil; Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_goju_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | SharpWeld (Weld) -> nil; BladeWeld (Weld) -> nil; HandleWeld (Weld) -> nil; SwordWeld (Weld) -> nil; KazumaBowWeld (Weld) -> nil; SwordWeldOld (Weld) -> nil; Right Arm 🡪 RightHilt (Motor6D) -> Right Arm | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_goju_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_goju_base` | NameTag | Part | Head | [ CHAMPION ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ CHAMPION ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ CHAMPION ]") |
| `char_goju_base` | InvisibleHitbox | MeshPart | AwakeningHair | Morph.AwakeningHair | 1.00 | 2.13 × 2.08 × 2.04 | rbxassetid://6473331733 | http://www.roblox.com/asset/?id=6475784220 | — | AwakeningHairWeld (Weld) -> Head | Head | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_goju_base` | NameTag | SpecialMesh | Mesh | [ CHAMPION ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ CHAMPION ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ CHAMPION ]") |
| `char_goko_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_goko_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; HiltWeld (Weld) -> nil; Blade2Weld (Weld) -> nil; BladeWeld (Weld) -> nil; HiltWeldOld (Weld) -> nil; Blade2WeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_goko_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_goko_base` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_goko_base` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_goko_dark_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_goko_dark_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_goko_dark_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_goko_dark_base` | NameTag | Part | Head | [ X ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_goko_dark_base` | NameTag | SpecialMesh | Mesh | [ X ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_goko_dark_rose` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_goko_dark_rose` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; Weld (Weld) -> GodSlicer | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_goko_dark_rose` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_goko_dark_rose` | NameTag | Part | Head | [ X ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_goko_dark_rose` | InvisibleHitbox | UnionOperation | GokuHair | Morph.GokuHair | 1.00 | 3.14 × 1.83 × 3.02 | — | — | — | GokuHairWeld (Weld) -> Head | Head | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_goko_dark_rose` | NameTag | SpecialMesh | Mesh | [ X ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_goko_majin_saga` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_goko_majin_saga` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; HiltWeld (Weld) -> nil; Blade2Weld (Weld) -> nil; BladeWeld (Weld) -> nil; HiltWeldOld (Weld) -> nil; Blade2WeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_goko_majin_saga` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_goko_majin_saga` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_goko_majin_saga` | InvisibleHitbox | MeshPart | SSJ3 | Morph.SSJ3 | 1.00 | 2.36 × 2.03 × 2.40 | rbxassetid://560186510 | — | — | SSJ3Weld (Weld) -> Head | Head | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_goko_majin_saga` | InvisibleHitbox | Part | SaiyanHair3 | Morph.SaiyanHair3 | 1.00 | 0.20 × 0.20 × 0.20 | — | — | — | SaiyanHair3Weld (Weld) -> Head; Weld (ManualWeld) -> nil | Head | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_goko_majin_saga` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_goko_majin_saga` | InvisibleHitbox | SpecialMesh | Mesh | Morph.SaiyanHair3.Mesh | 1.00 | — | rbxassetid://560193297 | — | — | — | — | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) (removido junto com Part "SaiyanHair3") |
| `char_gom_adult` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat, ParticleEmitter SaiyanAura2, ParticleEmitter SaiyanAura3, ParticleEmitter SaiyanAura | HumanoidRootPart: peça raiz do rig |
| `char_gom_adult` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_gom_adult` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_gom_adult` | NameTag | Part | Head | [ X ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_gom_adult` | NameTag | SpecialMesh | Mesh | [ X ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_gom_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_gom_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; SwordWeld (Weld) -> nil; HermitWeld (Weld) -> nil; Hermit2Weld (Weld) -> nil; SwordWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_gom_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_gom_base` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_gom_base` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_grei_awakened` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_grei_awakened` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_grei_awakened` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_grei_awakened` | NameTag | Part | Head | [ CHAMPION  ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ CHAMPION  ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ CHAMPION  ]") |
| `char_grei_awakened` | NameTag | SpecialMesh | Mesh | [ CHAMPION  ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ CHAMPION  ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ CHAMPION  ]") |
| `char_grei_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_grei_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_grei_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_grei_base` | NameTag | Part | Head | [ CHAMPION  ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ CHAMPION  ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ CHAMPION  ]") |
| `char_grei_base` | NameTag | SpecialMesh | Mesh | [ CHAMPION  ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ CHAMPION  ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ CHAMPION  ]") |
| `char_grimjau_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_grimjau_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; FakeSwordWeld (Weld) -> FakeSword; SwordWeld (Weld) -> Sword; RFurWeld (Weld) -> nil; RBladeWeld (Weld) -> nil; RGuardWeld (Weld) -> nil; RGoldWeld (Weld) -> nil; SwordWeldOld (Weld) -> nil; BladeWeld (Weld) -> nil; ShikaiWeld (Weld) -> nil; SwordWeldOld (Weld) -> nil; ShikaiWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil; ShikaiWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_grimjau_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm; LFurWeld (Weld) -> nil; LBladeWeld (Weld) -> nil; LGuardWeld (Weld) -> nil; LGoldWeld (Weld) -> nil | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_grimjau_base` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_grimjau_base` | InvisibleHitbox | MeshPart | FakeSword | Morph.FakeSword | 1.00 | 1.28 × 5.75 × 0.73 | rbxassetid://670099981 | — | — | FakeSwordWeld (Weld) -> RightHilt | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_grimjau_base` | InvisibleHitbox | MeshPart | ResEars | Morph.ResEars | 1.00 | 2.82 × 0.67 × 0.77 | rbxassetid://741257738 | rbxassetid://741264863 | — | ResEarsWeld (Weld) -> Head | Head | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_grimjau_base` | InvisibleHitbox | MeshPart | ResCrown | Morph.ResCrown | 1.00 | 1.73 × 0.83 × 0.48 | rbxassetid://741257048 | rbxassetid://741264863 | — | ResCrownWeld (Weld) -> Head | Head | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_grimjau_base` | InvisibleHitbox | MeshPart | ResHair | Morph.ResHair | 1.00 | 2.61 × 6.83 × 2.34 | rbxassetid://741255505 | rbxassetid://741264863 | — | ResHairWeld (Weld) -> Head | Head | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_grimjau_base` | InvisibleHitbox | MeshPart | Tail | Morph.Tail | 1.00 | 0.38 × 4.38 × 0.44 | rbxassetid://741256168 | rbxassetid://741264863 | — | TailWeld (Weld) -> Torso | Torso | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_grimjau_base` | InvisibleHitbox | MeshPart | ResSpikeL | Morph.ResSpikeL | 1.00 | 2.38 × 0.90 × 0.75 | rbxassetid://741259587 | rbxassetid://741264863 | — | ResSpikeLWeld (Weld) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_grimjau_base` | InvisibleHitbox | MeshPart | ResSpikeR | Morph.ResSpikeR | 1.00 | 2.38 × 0.90 × 0.75 | rbxassetid://741259587 | rbxassetid://741264863 | — | ResSpikeRWeld (Weld) -> Right Arm | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_grimjau_base` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_hiey_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_hiey_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; Blade2Weld (Weld) -> Blade2; HiltWeld (Weld) -> Hilt; BladeWeld (Weld) -> Blade; SharpWeld (Weld) -> nil; BladeWeldOld (Weld) -> nil; HandleWeld (Weld) -> nil; SwordWeld (Weld) -> nil; KazumaBowWeld (Weld) -> nil; SwordWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_hiey_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm; SheathWeld (Weld) -> nil | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_hiey_base` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_hiey_base` | InvisibleHitbox | MeshPart | HairAwakened | Morph.HairAwakened | 1.00 | 2.03 × 2.47 × 2.35 | rbxassetid://6527933282 | rbxassetid://6527933324 | — | HairAwakenedWeld (Weld) -> Head | Head | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_hiey_base` | InvisibleHitbox | MeshPart | Hilt | Morph.Hilt | 1.00 | 0.45 × 0.92 × 1.50 | rbxassetid://6485752063 | rbxassetid://6485752085 | — | HiltWeld (Weld) -> RightHilt | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_hiey_base` | InvisibleHitbox | MeshPart | Blade2 | Morph.Blade2 | 1.00 | 0.10 × 0.31 × 3.95 | rbxassetid://6485753369 | — | — | Blade2Weld (Weld) -> RightHilt | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_hiey_base` | InvisibleHitbox | MeshPart | Blade | Morph.Blade | 1.00 | 0.10 × 0.43 × 3.95 | rbxassetid://6485752909 | — | — | BladeWeld (Weld) -> RightHilt | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_hiey_base` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_hizoka_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_hizoka_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_hizoka_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_hizoka_base` | NameTag | Part | Head | [ X ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_hizoka_base` | NameTag | SpecialMesh | Mesh | [ X ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_ichiro_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_ichiro_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; ShikaiWeld (Weld) -> Shikai; SwordWeld (Weld) -> Sword | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_ichiro_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_ichiro_base` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_ichiro_base` | InvisibleHitbox | MeshPart | Shikai | Morph.Shikai | 1.00 | 0.72 × 5.74 × 0.50 | rbxassetid://1469410538 | rbxassetid://666106331 | — | ShikaiWeld (Weld) -> RightHilt | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_ichiro_base` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_ichiro_hollow` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_ichiro_hollow` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; SwordWeld (Weld) -> Sword; SwordWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil; SwordsWeld (Weld) -> nil; SwordsWeldOld (Weld) -> nil; SwordsWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil; SwordsWeldOld (Weld) -> nil; SwordsWeldOld (Weld) -> nil; SwordsWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_ichiro_hollow` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_ichiro_hollow` | NameTag | Part | Head | [ X ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_ichiro_hollow` | InvisibleHitbox | MeshPart | HalfMask | Morph.HalfMask | 1.00 | 0.62 × 1.12 × 0.51 | rbxassetid://6373430812 | rbxassetid://6373430842 | — | HalfMaskWeld (Weld) -> Head | Head | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_ichiro_hollow` | NameTag | SpecialMesh | Mesh | [ X ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_ichiro_mugetsu` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat, ParticleEmitter BlackFlame | HumanoidRootPart: peça raiz do rig |
| `char_ichiro_mugetsu` | InvisibleHitbox | Part | FakeHead | FakeHead | 1.00 | 2.00 × 1.00 × 1.00 | — | — | — | Snap (Snap) -> Torso; Weld (ManualWeld) -> Head | Head | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_ichiro_mugetsu` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; SwordWeld (Weld) -> Sword; SwordWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil; SwordsWeld (Weld) -> nil; SwordsWeldOld (Weld) -> nil; SwordsWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil; SwordsWeldOld (Weld) -> nil; SwordsWeldOld (Weld) -> nil; SwordsWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_ichiro_mugetsu` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_ichiro_mugetsu` | InvisibleHitbox | SpecialMesh | Mesh | FakeHead.Mesh | 1.00 | — | — | — | — | — | — | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) (removido junto com Part "FakeHead") |
| `char_ichiro_mugetsu` | NameTag | Part | Head | [ X ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_ichiro_mugetsu` | InvisibleHitbox | MeshPart | FullMask | Morph.FullMask | 1.00 | 1.09 × 1.29 × 0.26 | rbxassetid://718894407 | rbxassetid://718894422 | — | FullMaskWeld (Weld) -> Head | Head | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_ichiro_mugetsu` | InvisibleHitbox | MeshPart | HalfMask | Morph.HalfMask | 1.00 | 0.62 × 1.12 × 0.51 | rbxassetid://6373430812 | rbxassetid://6373430842 | — | HalfMaskWeld (Weld) -> Head | Head | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_ichiro_mugetsu` | NameTag | SpecialMesh | Mesh | [ X ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_ichiro_vasto` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_ichiro_vasto` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; SwordWeld (Weld) -> Sword; SwordWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil; SwordsWeld (Weld) -> nil; SwordsWeldOld (Weld) -> nil; SwordsWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil; SwordsWeldOld (Weld) -> nil; SwordsWeldOld (Weld) -> nil; SwordsWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_ichiro_vasto` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_ichiro_vasto` | NameTag | Part | Head | [ X ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_ichiro_vasto` | InvisibleHitbox | Part | Face | Morph.Face | 1.00 | 2.00 × 1.00 × 1.00 | — | — | — | FaceWeld (Weld) -> Head; Snap (Snap) -> Torso | Head | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_ichiro_vasto` | NameTag | SpecialMesh | Mesh | [ X ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_ichiro_vasto` | InvisibleHitbox | SpecialMesh | Mesh | Morph.Face.Mesh | 1.00 | — | — | — | — | — | — | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) (removido junto com Part "Face") |
| `char_ilumi_awakened` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_ilumi_awakened` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_ilumi_awakened` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_ilumi_awakened` | NameTag | Part | Head | [ X ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_ilumi_awakened` | InvisibleHitbox | MeshPart | Hair | Morph.Hair | 1.00 | 1.98 × 4.92 × 2.81 | rbxassetid://6115436732 | — | — | HairWeld (Weld) -> Head | Head | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_ilumi_awakened` | NameTag | SpecialMesh | Mesh | [ X ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_ilumi_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_ilumi_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; SwordWeld (Weld) -> nil; HermitWeld (Weld) -> nil; Hermit2Weld (Weld) -> nil; SwordWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_ilumi_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_ilumi_base` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_ilumi_base` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_infernus_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_infernus_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; ExecutionersWeld (Weld) -> nil; ExecutionersWeldOld (Weld) -> nil; ExecutionersWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_infernus_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_infernus_base` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_infernus_base` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_iskander_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_iskander_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; MySwordWeld (Weld) -> MySword; MySwordWeldOld (Weld) -> nil; SwordDrawn1Weld (Weld) -> nil; SpearWeld (Weld) -> nil; MySwordWeldOld (Weld) -> nil; SwordDrawn1WeldOld (Weld) -> nil; SpearWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_iskander_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_iskander_base` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_iskander_base` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_itaxi_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_itaxi_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; Blade2Weld (Weld) -> nil; Handle3Weld (Weld) -> nil; Handle3WeldOld (Weld) -> nil; Handle2Weld (Weld) -> nil; Handle1Weld (Weld) -> nil; Blade1Weld (Weld) -> nil; Blade2WeldOld (Weld) -> nil; Handle3WeldOld (Weld) -> nil; Handle3WeldOld (Weld) -> nil; Handle2WeldOld (Weld) -> nil; Handle1WeldOld (Weld) -> nil; Blade1WeldOld (Weld) -> nil; ExecutionersWeld (Weld) -> nil; ExecutionersWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_itaxi_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_itaxi_base` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_itaxi_base` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_kakaxi_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_kakaxi_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; ExecutionersWeld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_kakaxi_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_kakaxi_base` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_kakaxi_base` | InvisibleHitbox | MeshPart | HairUp2 | Morph.HairUp2 | 1.00 | 2.46 × 2.31 × 2.21 | rbxassetid://522121299 | rbxassetid://522121303 | — | HairUp2Weld (Weld) -> Head | Head | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_kakaxi_base` | InvisibleHitbox | Part | HairUp1 | Morph.HairUp1 | 1.00 | 1.24 × 1.60 × 1.25 | — | — | — | HairUp1Weld (Weld) -> Head | Head | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_kakaxi_base` | InvisibleHitbox | Part | HairUp3 | Morph.HairUp3 | 1.00 | 0.45 × 0.78 × 0.96 | — | — | — | HairUp3Weld (Weld) -> Head | Head | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_kakaxi_base` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_kakaxi_base` | InvisibleHitbox | SpecialMesh | Mesh | Morph.HairUp1.Mesh | 1.00 | — | http://www.roblox.com/asset/?id=1286425 | rbxassetid://489237055 | — | — | — | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) (removido junto com Part "HairUp1") |
| `char_kakaxi_base` | InvisibleHitbox | SpecialMesh | Mesh | Morph.HairUp3.Mesh | 1.00 | — | — | — | — | — | — | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) (removido junto com Part "HairUp3") |
| `char_kaulifa_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_kaulifa_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; HiltWeld (Weld) -> nil; Blade2Weld (Weld) -> nil; BladeWeld (Weld) -> nil; HiltWeldOld (Weld) -> nil; Blade2WeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_kaulifa_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_kaulifa_base` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_kaulifa_base` | InvisibleHitbox | MeshPart | SSJ2 | Morph.SSJ2 | 1.00 | 2.67 × 2.59 × 2.36 | rbxassetid://5123230444 | — | — | SSJ2Weld (Weld) -> Head | Head | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_kaulifa_base` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_kazumo_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_kazumo_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | SwordWeld (Weld) -> Sword; SwordWeldOld (Weld) -> nil; Right Arm 🡪 RightHilt (Motor6D) -> Right Arm | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_kazumo_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_kazumo_base` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_kazumo_base` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_killuo_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_killuo_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; SwordWeld (Weld) -> nil; HermitWeld (Weld) -> nil; Hermit2Weld (Weld) -> nil; SwordWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_killuo_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_killuo_base` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_killuo_base` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_killuo_godspeed` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_killuo_godspeed` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_killuo_godspeed` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_killuo_godspeed` | NameTag | Part | Head | [ X ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_killuo_godspeed` | InvisibleHitbox | MeshPart | Hair | Morph.Hair | 1.00 | 2.43 × 2.00 × 2.09 | rbxassetid://5203350488 | http://www.roblox.com/asset/?id=5203445554 | — | HairWeld (Weld) -> Head | Head | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_killuo_godspeed` | NameTag | SpecialMesh | Mesh | [ X ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_kiritsugo_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_kiritsugo_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; SpecialBladeWeld (Weld) -> nil; ExcaliburWeld (Weld) -> nil; SwordDrawn1Weld (Weld) -> nil; SpearWeld (Weld) -> nil; SwordDrawn1WeldOld (Weld) -> nil; SpearWeldOld (Weld) -> nil; SpecialBladeWeldOld (Weld) -> nil; ExcaliburWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_kiritsugo_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_kiritsugo_base` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_kiritsugo_base` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_kisuko_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_kisuko_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; ShikaiWeld (Weld) -> Shikai; BladeWeld (Weld) -> Blade; SwordWeld (Weld) -> nil; EnergySwordRWeld (Weld) -> nil; SwordWeldOld (Weld) -> nil; ExtendingBladeWeld (Weld) -> nil; RealHiltWeld (Weld) -> nil; BladeWeldOld (Weld) -> nil; ExtendingBladeWeldOld (Weld) -> nil; RealHiltWeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil; ExtendingBladeWeldOld (Weld) -> nil; RealHiltWeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil; ExtendingBladeWeldOld (Weld) -> nil; RealHiltWeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil; ExtendingBladeWeldOld (Weld) -> nil; RealHiltWeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil; ExtendingBladeWeldOld (Weld) -> nil; RealHiltWeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil; ExtendingBladeWeldOld (Weld) -> nil; RealHiltWeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil; ExtendingBladeWeldOld (Weld) -> nil; RealHiltWeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil; ExtendingBladeWeldOld (Weld) -> nil; RealHiltWeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil; FakeSwordWeld (Weld) -> nil; SwordWeldOld (Weld) -> nil; RFurWeld (Weld) -> nil; RBladeWeld (Weld) -> nil; RGuardWeld (Weld) -> nil; RGoldWeld (Weld) -> nil; SwordWeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil; ShikaiWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil; ShikaiWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil; ShikaiWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_kisuko_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm; EnergySwordLWeld (Weld) -> nil; LFurWeld (Weld) -> nil; LBladeWeld (Weld) -> nil; LGuardWeld (Weld) -> nil; LGoldWeld (Weld) -> nil | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_kisuko_base` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_kisuko_base` | InvisibleHitbox | MeshPart | Shikai | Morph.Shikai | 1.00 | 1.82 × 0.23 × 5.41 | rbxassetid://1329987514 | rbxassetid://1036963965 | — | ShikaiWeld (Weld) -> RightHilt | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_kisuko_base` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_kizaro_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_kizaro_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_kizaro_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_kizaro_base` | NameTag | Part | Head | [ X ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_kizaro_base` | NameTag | SpecialMesh | Mesh | [ X ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_kurilo_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_kurilo_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_kurilo_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_kurilo_base` | NameTag | Part | Head | [ X ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_kurilo_base` | NameTag | SpecialMesh | Mesh | [ X ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_lanseiro_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_lanseiro_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; SwordDrawn1Weld (Weld) -> SwordDrawn1; SpearWeld (Weld) -> Spear; SwordDrawn1WeldOld (Weld) -> nil; SpearWeldOld (Weld) -> nil; SwordDrawn1WeldOld (Weld) -> nil; SpearWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_lanseiro_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_lanseiro_base` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_lanseiro_base` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_lanseiro_mode` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_lanseiro_mode` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_lanseiro_mode` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_lau_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_lau_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; SwordDrawn1Weld (Weld) -> SwordDrawn1; KitetsuWeld (Weld) -> nil; HiltWeld (Weld) -> nil; Blade2Weld (Weld) -> nil; BladeWeld (Weld) -> nil; HiltWeldOld (Weld) -> nil; Blade2WeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_lau_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm; SwordHiltWeld (Weld) -> SwordHilt; SheathWeld (Weld) -> Sheath; ShisuiWeld (Weld) -> nil | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_lau_base` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_lau_base` | InvisibleCombatHelper | MeshPart | SwordDrawn1 | Morph.SwordDrawn1 | 1.00 | 0.60 × 0.60 × 5.94 | rbxassetid://1567251909 | rbxassetid://1567251935 | — | SwordDrawn1Weld (Weld) -> RightHilt | RightArm | Trail Trail | Transparency=1.00; o único conteúdo visível eram VFX removidos pela política de VFX (Trail Trail) |
| `char_lau_base` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_lemilio_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_lemilio_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; ExecutionersWeld (Weld) -> nil; ExecutionersWeldOld (Weld) -> nil; ExecutionersWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_lemilio_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_lemilio_base` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_lemilio_base` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_lufy_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_lufy_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; KitetsuWeld (Weld) -> nil; HiltWeld (Weld) -> nil; Blade2Weld (Weld) -> nil; BladeWeld (Weld) -> nil; SwordDrawn1Weld (Weld) -> nil; KitetsuWeldOld (Weld) -> nil; HiltWeldOld (Weld) -> nil; Blade2WeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil; HiltWeldOld (Weld) -> nil; Blade2WeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_lufy_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm; ShisuiWeld (Weld) -> nil; SwordHiltWeld (Weld) -> nil; SheathWeld (Weld) -> nil; ShisuiWeldOld (Weld) -> nil | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_lufy_base` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_lufy_base` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_lufy_snake` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_lufy_snake` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_lufy_snake` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_lufy_snake` | NameTag | Part | Head | [ X ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_lufy_snake` | NameTag | SpecialMesh | Mesh | [ X ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_madaro_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_madaro_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; RealFanWeld (Weld) -> RealFan; Blade2Weld (Weld) -> nil; Handle3Weld (Weld) -> nil; Handle3WeldOld (Weld) -> nil; Handle2Weld (Weld) -> nil; Handle1Weld (Weld) -> nil; Blade1Weld (Weld) -> nil; Blade2WeldOld (Weld) -> nil; Handle3WeldOld (Weld) -> nil; Handle3WeldOld (Weld) -> nil; Handle2WeldOld (Weld) -> nil; Handle1WeldOld (Weld) -> nil; Blade1WeldOld (Weld) -> nil; ExecutionersWeld (Weld) -> nil; ExecutionersWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_madaro_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm; MinatoKunaiWeld (Weld) -> nil | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_madaro_base` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_madaro_base` | InvisibleHitbox | MeshPart | RealFan | Morph.RealFan | 1.00 | 2.93 × 6.45 × 0.16 | rbxassetid://450273384 | rbxassetid://450273389 | — | RealFanWeld (Weld) -> RightHilt | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_madaro_base` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_mighto_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_mighto_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; SwordWeld (Weld) -> nil; SwordWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_mighto_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_mighto_base` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_mighto_base` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_mighto_gate5` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_mighto_gate5` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; SwordWeld (Weld) -> nil; SwordWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_mighto_gate5` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_mighto_gate5` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_mighto_gate5` | InvisibleHitbox | MeshPart | Header | Morph.Header | 1.00 | 1.59 × 1.64 × 1.62 | rbxassetid://7038165415 | rbxassetid://7038165504 | — | HeaderWeld (Weld) -> Head | Head | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_mighto_gate5` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_mighto_gate8` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_mighto_gate8` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; SwordWeld (Weld) -> nil; SwordWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_mighto_gate8` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_mighto_gate8` | InvisibleHitbox | MeshPart | Header | Morph.Header | 1.00 | 1.59 × 1.64 × 1.62 | rbxassetid://7038165415 | rbxassetid://7038165504 | — | HeaderWeld (Weld) -> Head | Head | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_mikaza_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | — | Torso | — | HumanoidRootPart: peça raiz do rig |
| `char_mikaza_formal` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | — | Torso | — | HumanoidRootPart: peça raiz do rig |
| `char_minatu_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_minatu_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; Blade2Weld (Weld) -> nil; Handle3Weld (Weld) -> nil; Handle3WeldOld (Weld) -> nil; Handle2Weld (Weld) -> nil; Handle1Weld (Weld) -> nil; Blade1Weld (Weld) -> nil; Blade2WeldOld (Weld) -> nil; Handle3WeldOld (Weld) -> nil; Handle3WeldOld (Weld) -> nil; Handle2WeldOld (Weld) -> nil; Handle1WeldOld (Weld) -> nil; Blade1WeldOld (Weld) -> nil; ExecutionersWeld (Weld) -> nil; ExecutionersWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_minatu_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm; MinatoKunaiWeld (Weld) -> MinatoKunai | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_minatu_base` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_minatu_base` | InvisibleHitbox | MeshPart | MinatoKunai | Morph.MinatoKunai | 1.00 | 0.30 × 1.60 × 0.15 | rbxassetid://530339062 | rbxassetid://530339069 | — | MinatoKunaiWeld (Weld) -> LeftHilt | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_minatu_base` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_narotu_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_narotu_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; Blade2Weld (Weld) -> nil; Handle3Weld (Weld) -> nil; Handle3WeldOld (Weld) -> nil; Handle2Weld (Weld) -> nil; Handle1Weld (Weld) -> nil; Blade1Weld (Weld) -> nil; Blade2WeldOld (Weld) -> nil; Handle3WeldOld (Weld) -> nil; Handle3WeldOld (Weld) -> nil; Handle2WeldOld (Weld) -> nil; Handle1WeldOld (Weld) -> nil; Blade1WeldOld (Weld) -> nil; ExecutionersWeld (Weld) -> nil; ExecutionersWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_narotu_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_narotu_base` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_narotu_base` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_narotu_sage` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_narotu_sage` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_narotu_sage` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; Blade2Weld (Weld) -> nil; Handle3Weld (Weld) -> nil; Handle3WeldOld (Weld) -> nil; Handle2Weld (Weld) -> nil; Handle1Weld (Weld) -> nil; Blade1Weld (Weld) -> nil; Blade2WeldOld (Weld) -> nil; Handle3WeldOld (Weld) -> nil; Handle3WeldOld (Weld) -> nil; Handle2WeldOld (Weld) -> nil; Handle1WeldOld (Weld) -> nil; Blade1WeldOld (Weld) -> nil; ExecutionersWeld (Weld) -> nil; ExecutionersWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_narotu_sage` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_narotu_sage` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_narotu_young` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_narotu_young` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; ExecutionersWeld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_narotu_young` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_narotu_young` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_narotu_young` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_natzu_awakened` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_natzu_awakened` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; FakeSwordWeld (Weld) -> nil; SwordWeld (Weld) -> nil; RightSwordEXWeld (Weld) -> nil; RightSwordWeld (Weld) -> nil; ShirouPipeWeld (Weld) -> nil; RightSwordEXWeldOld (Weld) -> nil; RightSwordWeldOld (Weld) -> nil; ShirouPipeWeldOld (Weld) -> nil; RightSwordEXWeldOld (Weld) -> nil; RightSwordWeldOld (Weld) -> nil; ShirouPipeWeldOld (Weld) -> nil; RightSwordEXWeldOld (Weld) -> nil; RightSwordWeldOld (Weld) -> nil; ShirouPipeWeldOld (Weld) -> nil; RightSwordEXWeldOld (Weld) -> nil; RightSwordWeldOld (Weld) -> nil; ShirouPipeWeldOld (Weld) -> nil; RightSwordEXWeldOld (Weld) -> nil; RightSwordWeldOld (Weld) -> nil; ShirouPipeWeldOld (Weld) -> nil; SpecialBladeWeld (Weld) -> nil; ExcaliburWeld (Weld) -> nil; HiltWeld (Weld) -> nil; Blade2Weld (Weld) -> nil; BladeWeld (Weld) -> nil; ShikaiWeld (Weld) -> nil; SwordWeldOld (Weld) -> nil; FakeSwordWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_natzu_awakened` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm; LeftSwordEXWeld (Weld) -> nil; LeftSwordWeld (Weld) -> nil; LeftSwordEXWeldOld (Weld) -> nil; LeftSwordWeldOld (Weld) -> nil; LeftSwordEXWeldOld (Weld) -> nil; LeftSwordWeldOld (Weld) -> nil; LeftSwordEXWeldOld (Weld) -> nil; LeftSwordWeldOld (Weld) -> nil; LeftSwordEXWeldOld (Weld) -> nil; LeftSwordWeldOld (Weld) -> nil; LeftSwordEXWeldOld (Weld) -> nil; LeftSwordWeldOld (Weld) -> nil | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_natzu_awakened` | NameTag | Part | Head | [ CHAMPION  ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ CHAMPION  ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ CHAMPION  ]") |
| `char_natzu_awakened` | NameTag | SpecialMesh | Mesh | [ CHAMPION  ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ CHAMPION  ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ CHAMPION  ]") |
| `char_natzu_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_natzu_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; FakeSwordWeld (Weld) -> nil; SwordWeld (Weld) -> nil; RightSwordEXWeld (Weld) -> nil; RightSwordWeld (Weld) -> nil; ShirouPipeWeld (Weld) -> nil; RightSwordEXWeldOld (Weld) -> nil; RightSwordWeldOld (Weld) -> nil; ShirouPipeWeldOld (Weld) -> nil; RightSwordEXWeldOld (Weld) -> nil; RightSwordWeldOld (Weld) -> nil; ShirouPipeWeldOld (Weld) -> nil; RightSwordEXWeldOld (Weld) -> nil; RightSwordWeldOld (Weld) -> nil; ShirouPipeWeldOld (Weld) -> nil; RightSwordEXWeldOld (Weld) -> nil; RightSwordWeldOld (Weld) -> nil; ShirouPipeWeldOld (Weld) -> nil; RightSwordEXWeldOld (Weld) -> nil; RightSwordWeldOld (Weld) -> nil; ShirouPipeWeldOld (Weld) -> nil; SpecialBladeWeld (Weld) -> nil; ExcaliburWeld (Weld) -> nil; HiltWeld (Weld) -> nil; Blade2Weld (Weld) -> nil; BladeWeld (Weld) -> nil; ShikaiWeld (Weld) -> nil; SwordWeldOld (Weld) -> nil; FakeSwordWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_natzu_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm; LeftSwordEXWeld (Weld) -> nil; LeftSwordWeld (Weld) -> nil; LeftSwordEXWeldOld (Weld) -> nil; LeftSwordWeldOld (Weld) -> nil; LeftSwordEXWeldOld (Weld) -> nil; LeftSwordWeldOld (Weld) -> nil; LeftSwordEXWeldOld (Weld) -> nil; LeftSwordWeldOld (Weld) -> nil; LeftSwordEXWeldOld (Weld) -> nil; LeftSwordWeldOld (Weld) -> nil; LeftSwordEXWeldOld (Weld) -> nil; LeftSwordWeldOld (Weld) -> nil | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_natzu_base` | NameTag | Part | Head | [ CHAMPION  ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ CHAMPION  ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ CHAMPION  ]") |
| `char_natzu_base` | NameTag | SpecialMesh | Mesh | [ CHAMPION  ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ CHAMPION  ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ CHAMPION  ]") |
| `char_nejo_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_nejo_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; ExecutionersWeld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_nejo_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_nejo_base` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_nejo_base` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_olmaito_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_olmaito_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_olmaito_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_olmaito_base` | NameTag | Part | Head | [ X ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_olmaito_base` | NameTag | SpecialMesh | Mesh | [ X ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_olmaito_mode` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_olmaito_mode` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_olmaito_mode` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_olmaito_mode` | NameTag | Part | Head | [ X ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_olmaito_mode` | InvisibleHitbox | MeshPart | BaseHair | Morph.BaseHair | 1.00 | 3.42 × 3.48 × 3.50 | rbxassetid://1659352637 | rbxassetid://1659352648 | — | BaseHairWeld (Weld) -> Head | Head | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_olmaito_mode` | NameTag | SpecialMesh | Mesh | [ X ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_peinn_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_peinn_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; Blade2Weld (Weld) -> nil; Handle3Weld (Weld) -> nil; Handle3WeldOld (Weld) -> nil; Handle2Weld (Weld) -> nil; Handle1Weld (Weld) -> nil; Blade1Weld (Weld) -> nil; Blade2WeldOld (Weld) -> nil; Handle3WeldOld (Weld) -> nil; Handle3WeldOld (Weld) -> nil; Handle2WeldOld (Weld) -> nil; Handle1WeldOld (Weld) -> nil; Blade1WeldOld (Weld) -> nil; ExecutionersWeld (Weld) -> nil; ExecutionersWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_peinn_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_peinn_base` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_peinn_base` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_pikkolo_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_pikkolo_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; HiltWeld (Weld) -> nil; Blade2Weld (Weld) -> nil; BladeWeld (Weld) -> nil; HiltWeldOld (Weld) -> nil; Blade2WeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_pikkolo_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_pikkolo_base` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_pikkolo_base` | InvisibleHitbox | Part | Aten | Morph.Aten | 1.00 | 1.00 × 1.00 × 1.00 | — | — | — | AtenWeld (Weld) -> Head; Weld (ManualWeld) -> nil | Head | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_pikkolo_base` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_pikkolo_base` | InvisibleHitbox | SpecialMesh | Mesh | Morph.Aten.Mesh | 1.00 | — | http://www.roblox.com/asset/?id=1374149 | — | — | — | — | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) (removido junto com Part "Aten") |
| `char_rika_awakened` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat, ParticleEmitter Blood | HumanoidRootPart: peça raiz do rig |
| `char_rika_awakened` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_rika_awakened` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_rika_awakened` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_rika_awakened` | InvisibleCombatHelper | Part | Tweener | RikkaWep.Tweener | 1.00 | 17.23 × 6.71 × 2.47 | — | — | — | Tweener (Weld) -> Handle | Head | ParticleEmitter ShootParticle | Transparency=1.00; o único conteúdo visível eram VFX removidos pela política de VFX (ParticleEmitter ShootParticle) |
| `char_rika_awakened` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_rika_awakened` | InvisibleCombatHelper | SpecialMesh | Mesh | RikkaWep.Tweener.Mesh | 1.00 | — | rbxassetid://7333129922 | — | — | — | — | — | Transparency=1.00; o único conteúdo visível eram VFX removidos pela política de VFX (ParticleEmitter ShootParticle) (removido junto com Part "Tweener") |
| `char_rika_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_rika_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_rika_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_rika_base` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_rika_base` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_rinn_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_rinn_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; RightSwordEXWeld (Weld) -> nil; RightSwordWeld (Weld) -> nil; ShirouPipeWeld (Weld) -> nil; RightSwordEXWeldOld (Weld) -> nil; RightSwordWeldOld (Weld) -> nil; ShirouPipeWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_rinn_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm; LeftSwordEXWeld (Weld) -> nil; LeftSwordWeld (Weld) -> nil; LeftSwordEXWeldOld (Weld) -> nil; LeftSwordWeldOld (Weld) -> nil | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_rinn_base` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_rinn_base` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_roqueli_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_roqueli_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; ExecutionersWeld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_roqueli_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_roqueli_base` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_roqueli_base` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_roqueli_gates` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat, ParticleEmitter Aura, ParticleEmitter ParticleEmitter | HumanoidRootPart: peça raiz do rig |
| `char_roqueli_gates` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_roqueli_gates` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_roqueli_gates` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_roqueli_gates` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_rukya_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_rukya_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; SwordWeld (Weld) -> Sword; ShikaiWeld (Weld) -> Shikai; ShikaiWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_rukya_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_rukya_base` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_rukya_base` | InvisibleHitbox | MeshPart | Shikai | Morph.Shikai | 1.00 | 0.92 × 0.64 × 5.84 | rbxassetid://1563796257 | rbxassetid://1728023719 | — | ShikaiWeld (Weld) -> RightHilt | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_rukya_base` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_sacha_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | — | Torso | — | HumanoidRootPart: peça raiz do rig |
| `char_sacha_suit` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | — | Torso | — | HumanoidRootPart: peça raiz do rig |
| `char_saitano_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | SheathWeld (Weld) -> nil; Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_saitano_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | SharpWeld (Weld) -> nil; BladeWeld (Weld) -> nil; HandleWeld (Weld) -> nil; SwordWeld (Weld) -> nil; KazumaBowWeld (Weld) -> nil; SwordWeldOld (Weld) -> nil; Right Arm 🡪 RightHilt (Motor6D) -> Right Arm | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_saitano_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_saitano_base` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_saitano_base` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_samurai_afro_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_samurai_afro_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; HandleWeld (Weld) -> Handle; BladeWeld (Weld) -> Blade; SharpWeld (Weld) -> Sharp; SwordWeld (Weld) -> nil; KazumaBowWeld (Weld) -> nil; SwordWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_samurai_afro_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm; SheathWeld (Weld) -> Sheath | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_samurai_afro_base` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_samurai_afro_base` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_sanjo_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_sanjo_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_sanjo_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_sanjo_base` | NameTag | Part | Head | [ X ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_sanjo_base` | NameTag | SpecialMesh | Mesh | [ X ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_sanjo_young` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_sanjo_young` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; KitetsuWeld (Weld) -> nil; HiltWeld (Weld) -> nil; Blade2Weld (Weld) -> nil; BladeWeld (Weld) -> nil; HiltWeldOld (Weld) -> nil; Blade2WeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_sanjo_young` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm; ShisuiWeld (Weld) -> nil | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_sanjo_young` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_sanjo_young` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_sasuko_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_sasuko_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; Blade1Weld (Weld) -> Blade1; Handle3Weld (Weld) -> Handle3; Handle2Weld (Weld) -> Handle2; Handle3WeldOld (Weld) -> Handle3; Blade2Weld (Weld) -> Blade2; Handle1Weld (Weld) -> Handle1; ExecutionersWeld (Weld) -> nil; ExecutionersWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_sasuko_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_sasuko_base` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_sasuko_base` | InvisibleHitbox | MeshPart | cursemarkhair2 | Morph.cursemarkhair2 | 1.00 | 1.92 × 3.42 × 2.47 | rbxassetid://4534740771 | — | — | cursemarkhair2Weld (Weld) -> Head | Head | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_sasuko_base` | InvisibleHitbox | UnionOperation | Handle3 | Morph.Handle3 | 1.00 | 0.11 × 0.15 × 0.09 | — | — | — | Handle3Weld (Weld) -> Torso | Torso | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_sasuko_base` | InvisibleHitbox | UnionOperation | Handle3 | Morph.Handle3 | 1.00 | 0.11 × 0.15 × 0.09 | — | — | — | Handle3WeldOld (Weld) -> Torso | Torso | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_sasuko_base` | InvisibleHitbox | UnionOperation | Handle2 | Morph.Handle2 | 1.00 | 0.73 × 0.15 × 0.09 | — | — | — | Handle2Weld (Weld) -> Torso | Torso | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_sasuko_base` | InvisibleHitbox | UnionOperation | Handle1 | Morph.Handle1 | 1.00 | 0.73 × 0.15 × 0.09 | — | — | — | Handle1Weld (Weld) -> Torso | Torso | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_sasuko_base` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_sasuko_young` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_sasuko_young` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; ExecutionersWeld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_sasuko_young` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_sasuko_young` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_sasuko_young` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_seiba_alter` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_seiba_alter` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; SpecialBladeWeld (Weld) -> SpecialBlade; BladeWeld (Weld) -> Blade; ExcaliburWeld (Weld) -> Excalibur; SpecialBladeWeldOld (Weld) -> nil; ExcaliburWeldOld (Weld) -> nil; SpecialBladeWeldOld (Weld) -> nil; ExcaliburWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_seiba_alter` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_seiba_alter` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_seiba_alter` | InvisibleHitbox | MeshPart | Crown | Morph.Crown | 1.00 | 1.97 × 2.17 × 0.93 | rbxassetid://6208888383 | rbxassetid://6208888431 | — | CrownWeld (Weld) -> Head | Head | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_seiba_alter` | InvisibleCombatHelper | MeshPart | SpecialBlade | Morph.SpecialBlade | 1.00 | 0.20 × 1.35 × 6.28 | rbxassetid://6208910941 | — | — | SpecialBladeWeld (Weld) -> RightHilt | RightArm | ParticleEmitter Charge | Transparency=1.00; o único conteúdo visível eram VFX removidos pela política de VFX (ParticleEmitter Charge) |
| `char_seiba_alter` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_seiba_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_seiba_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; SpecialBladeWeld (Weld) -> SpecialBlade; ExcaliburWeld (Weld) -> Excalibur; RightSwordEXWeld (Weld) -> nil; RightSwordWeld (Weld) -> nil; ShirouPipeWeld (Weld) -> nil; RightSwordEXWeldOld (Weld) -> nil; RightSwordWeldOld (Weld) -> nil; ShirouPipeWeldOld (Weld) -> nil; HiltWeld (Weld) -> nil; Blade2Weld (Weld) -> nil; BladeWeld (Weld) -> nil; SharpWeld (Weld) -> nil; BladeWeldOld (Weld) -> nil; HandleWeld (Weld) -> nil; SwordWeld (Weld) -> nil; KazumaBowWeld (Weld) -> nil; SwordWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_seiba_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm; LeftSwordEXWeld (Weld) -> nil; LeftSwordWeld (Weld) -> nil; LeftSwordEXWeldOld (Weld) -> nil; LeftSwordWeldOld (Weld) -> nil; SheathWeld (Weld) -> nil | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_seiba_base` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_seiba_base` | InvisibleCombatHelper | MeshPart | SpecialBlade | Morph.SpecialBlade | 1.00 | 0.18 × 1.01 × 6.28 | rbxassetid://6208589741 | — | — | SpecialBladeWeld (Weld) -> RightHilt | RightArm | ParticleEmitter Charge | Transparency=1.00; o único conteúdo visível eram VFX removidos pela política de VFX (ParticleEmitter Charge) |
| `char_seiba_base` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_shankz_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_shankz_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; BladeUnionWeld (Weld) -> BladeUnion; HiltWeld (Weld) -> nil; Blade2Weld (Weld) -> nil; BladeWeld (Weld) -> nil; KitetsuWeld (Weld) -> nil; KitetsuWeldOld (Weld) -> nil; HiltWeldOld (Weld) -> nil; Blade2WeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil; SwordDrawn1Weld (Weld) -> nil; KitetsuWeldOld (Weld) -> nil; HiltWeldOld (Weld) -> nil; Blade2WeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil; HiltWeldOld (Weld) -> nil; Blade2WeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_shankz_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm; ShisuiWeld (Weld) -> nil; ShisuiWeldOld (Weld) -> nil; SwordHiltWeld (Weld) -> nil; SheathWeld (Weld) -> nil; ShisuiWeldOld (Weld) -> nil | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_shankz_base` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_shankz_base` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_shankz_base` | InvisibleHitbox | UnionOperation | BladeUnion | Morph.Blade.BladeUnion | 1.00 | 0.26 × 0.06 × 3.72 | — | — | — | BladeUnionWeld (Weld) -> RightHilt; Union 🡪 BladeUnion (Weld) -> Union | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_shankz_base` | InvisibleHitbox | MeshPart | cylinder | Morph.Blade.HiltModel.cylinder | 1.00 | 0.09 × 0.11 × 0.17 | rbxassetid://495043301 | — | — | Union 🡪 cylinder (Weld) -> Union | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_shankz_base` | InvisibleHitbox | MeshPart | cylinder | Morph.Blade.HiltModel.cylinder | 1.00 | 0.07 × 1.05 × 0.15 | rbxassetid://495043301 | — | — | Union 🡪 cylinder (Weld) -> Union | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_shankz_base` | InvisibleHitbox | MeshPart | cylinder | Morph.Blade.HiltModel.cylinder | 1.00 | 0.09 × 0.08 × 0.17 | rbxassetid://495043301 | — | — | Union 🡪 cylinder (Weld) -> Union | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_shankz_base` | InvisibleHitbox | UnionOperation | Union | Morph.Blade.HiltModel.Union | 1.00 | 1.14 × 0.73 × 0.42 | — | — | — | Union 🡪 BladeUnion (Weld) -> BladeUnion; Union 🡪 cylinder (Weld) -> cylinder; Union 🡪 cylinder (Weld) -> cylinder; Union 🡪 cylinder (Weld) -> cylinder; Union 🡪 cylinder (Weld) -> cylinder | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_shankz_base` | InvisibleHitbox | MeshPart | cylinder | Morph.Blade.HiltModel.cylinder | 1.00 | 0.10 × 0.11 × 0.19 | rbxassetid://495043301 | — | — | Union 🡪 cylinder (Weld) -> Union | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_shinjo_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_shinjo_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; SwordWeld (Weld) -> Sword; ShikaiWeld (Weld) -> Shikai; ShikaiWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil; ShikaiWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_shinjo_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_shinjo_base` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_shinjo_base` | InvisibleCombatHelper | UnionOperation | Shikai | Morph.Shikai | 1.00 | 0.24 × 1.33 × 6.10 | — | — | — | ShikaiWeld (Weld) -> RightHilt | RightArm | ParticleEmitter Smokey | Transparency=1.00; o único conteúdo visível eram VFX removidos pela política de VFX (ParticleEmitter Smokey) |
| `char_shinjo_base` | InvisibleHitbox | Part | Mask3 | Morph.Mask3 | 1.00 | 0.31 × 0.22 × 0.55 | — | — | — | Mask3Weld (Weld) -> Head | Head | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_shinjo_base` | InvisibleHitbox | Part | Mask2 | Morph.Mask2 | 1.00 | 0.31 × 0.22 × 0.55 | — | — | — | Mask2Weld (Weld) -> Head | Head | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_shinjo_base` | InvisibleHitbox | MeshPart | Mask | Morph.Mask | 1.00 | 2.50 × 2.88 × 1.89 | rbxassetid://1544575858 | rbxassetid://1544578603 | — | MaskWeld (Weld) -> Head | Head | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_shinjo_base` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_shinjo_base` | InvisibleHitbox | SpecialMesh | Mesh | Morph.Mask3.Mesh | 1.00 | — | — | — | — | — | — | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) (removido junto com Part "Mask3") |
| `char_shinjo_base` | InvisibleHitbox | SpecialMesh | Mesh | Morph.Mask2.Mesh | 1.00 | — | — | — | — | — | — | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) (removido junto com Part "Mask2") |
| `char_shiro_archer` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_shiro_archer` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; RightSwordEXWeld (Weld) -> RightSwordEX; RightSwordWeld (Weld) -> RightSword; ShirouPipeWeld (Weld) -> ShirouPipe; RightSwordEXWeldOld (Weld) -> nil; RightSwordWeldOld (Weld) -> nil; ShirouPipeWeldOld (Weld) -> nil; RightSwordEXWeldOld (Weld) -> nil; RightSwordWeldOld (Weld) -> nil; ShirouPipeWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_shiro_archer` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm; LeftSwordEXWeld (Weld) -> LeftSwordEX; LeftSwordWeld (Weld) -> LeftSword; LeftSwordEXWeldOld (Weld) -> nil; LeftSwordWeldOld (Weld) -> nil; LeftSwordEXWeldOld (Weld) -> nil; LeftSwordWeldOld (Weld) -> nil | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_shiro_archer` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_shiro_archer` | InvisibleHitbox | MeshPart | RightSword | Morph.RightSword | 1.00 | 0.17 × 0.56 × 3.34 | rbxassetid://6196177056 | http://www.roblox.com/asset/?id=6196177924 | — | RightSwordWeld (Weld) -> RightHilt | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_shiro_archer` | InvisibleHitbox | MeshPart | LeftSword | Morph.LeftSword | 1.00 | 0.17 × 0.56 × 3.34 | rbxassetid://6196166660 | http://www.roblox.com/asset/?id=6196167284 | — | LeftSwordWeld (Weld) -> LeftHilt | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_shiro_archer` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_shiro_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_shiro_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; ShirouPipeWeld (Weld) -> ShirouPipe; RightSwordWeld (Weld) -> RightSword; RightSwordEXWeld (Weld) -> RightSwordEX; RightSwordEXWeldOld (Weld) -> nil; RightSwordWeldOld (Weld) -> nil; ShirouPipeWeldOld (Weld) -> nil; HiltWeld (Weld) -> nil; Blade2Weld (Weld) -> nil; BladeWeld (Weld) -> nil; SharpWeld (Weld) -> nil; BladeWeldOld (Weld) -> nil; HandleWeld (Weld) -> nil; SwordWeld (Weld) -> nil; KazumaBowWeld (Weld) -> nil; SwordWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_shiro_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm; LeftSwordEXWeld (Weld) -> LeftSwordEX; LeftSwordWeld (Weld) -> LeftSword; LeftSwordEXWeldOld (Weld) -> nil; LeftSwordWeldOld (Weld) -> nil; SheathWeld (Weld) -> nil | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_shiro_base` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_shiro_base` | InvisibleHitbox | MeshPart | RightSwordEX | Morph.RightSwordEX | 1.00 | 0.57 × 1.06 × 6.48 | rbxassetid://6196151543 | http://www.roblox.com/asset/?id=6196152899 | — | RightSwordEXWeld (Weld) -> RightHilt | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_shiro_base` | InvisibleHitbox | MeshPart | LeftSwordEX | Morph.LeftSwordEX | 1.00 | 0.57 × 1.06 × 6.48 | rbxassetid://6196158643 | http://www.roblox.com/asset/?id=6196160848 | — | LeftSwordEXWeld (Weld) -> LeftHilt | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_shiro_base` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_shunzo_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_shunzo_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; RBladeWeld (Weld) -> RBlade; RFurWeld (Weld) -> RFur; RGuardWeld (Weld) -> RGuard; RGoldWeld (Weld) -> RGold; SwordWeld (Weld) -> nil; BladeWeld (Weld) -> nil; ShikaiWeld (Weld) -> nil; SwordWeldOld (Weld) -> nil; ShikaiWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil; ShikaiWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_shunzo_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm; LFurWeld (Weld) -> LFur; LBladeWeld (Weld) -> LBlade; LGoldWeld (Weld) -> LGold; LGuardWeld (Weld) -> LGuard | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_shunzo_base` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_shunzo_base` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_starko_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_starko_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; EnergySwordRWeld (Weld) -> EnergySwordR; SwordWeld (Weld) -> Sword; ExtendingBladeWeld (Weld) -> nil; RealHiltWeld (Weld) -> nil; BladeWeld (Weld) -> nil; ExtendingBladeWeldOld (Weld) -> nil; RealHiltWeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil; ExtendingBladeWeldOld (Weld) -> nil; RealHiltWeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil; ExtendingBladeWeldOld (Weld) -> nil; RealHiltWeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil; ExtendingBladeWeldOld (Weld) -> nil; RealHiltWeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil; ExtendingBladeWeldOld (Weld) -> nil; RealHiltWeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil; ExtendingBladeWeldOld (Weld) -> nil; RealHiltWeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil; ExtendingBladeWeldOld (Weld) -> nil; RealHiltWeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil; ExtendingBladeWeldOld (Weld) -> nil; RealHiltWeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil; FakeSwordWeld (Weld) -> nil; SwordWeldOld (Weld) -> nil; RFurWeld (Weld) -> nil; RBladeWeld (Weld) -> nil; RGuardWeld (Weld) -> nil; RGoldWeld (Weld) -> nil; SwordWeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil; ShikaiWeld (Weld) -> nil; SwordWeldOld (Weld) -> nil; ShikaiWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil; ShikaiWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_starko_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm; EnergySwordLWeld (Weld) -> EnergySwordL; LFurWeld (Weld) -> nil; LBladeWeld (Weld) -> nil; LGuardWeld (Weld) -> nil; LGoldWeld (Weld) -> nil | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_starko_base` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_starko_base` | InvisibleCombatHelper | MeshPart | EnergySwordR | Morph.EnergySwordR | 1.00 | 0.43 × 0.67 × 4.99 | rbxassetid://5692046401 | — | — | EnergySwordRWeld (Weld) -> RightHilt | RightArm | Trail Trail | Transparency=1.00; o único conteúdo visível eram VFX removidos pela política de VFX (Trail Trail) |
| `char_starko_base` | InvisibleCombatHelper | MeshPart | EnergySwordL | Morph.EnergySwordL | 1.00 | 0.43 × 0.67 × 4.99 | rbxassetid://5692046401 | — | — | EnergySwordLWeld (Weld) -> LeftHilt | LeftArm | Trail Trail | Transparency=1.00; o único conteúdo visível eram VFX removidos pela política de VFX (Trail Trail) |
| `char_starko_base` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_tanjiru_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_tanjiru_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | SwordWeld (Weld) -> Sword; Right Arm 🡪 RightHilt (Motor6D) -> Right Arm | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_tanjiru_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_tanjiru_base` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_tanjiru_base` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_todoruki_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_todoruki_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; ExecutionersWeld (Weld) -> nil; ExecutionersWeldOld (Weld) -> nil; ExecutionersWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_todoruki_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_todoruki_base` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_todoruki_base` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_toshiru_bankai` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat, ParticleEmitter Twirl1, ParticleEmitter Twirl2 | HumanoidRootPart: peça raiz do rig |
| `char_toshiru_bankai` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; SwordWeld (Weld) -> Sword; SwordWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_toshiru_bankai` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_toshiru_bankai` | NameTag | Part | Head | [ X ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_toshiru_bankai` | NameTag | SpecialMesh | Mesh | [ X ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_toshiru_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_toshiru_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; SwordWeld (Weld) -> Sword; SwordWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_toshiru_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_toshiru_base` | NameTag | Part | Head | [ X ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_toshiru_base` | NameTag | SpecialMesh | Mesh | [ X ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_trunkz_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_trunkz_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; HiltWeld (Weld) -> nil; Blade2Weld (Weld) -> nil; BladeWeld (Weld) -> nil; HiltWeldOld (Weld) -> nil; Blade2WeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_trunkz_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_trunkz_base` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_trunkz_base` | InvisibleHitbox | Part | SSJ | Morph.SSJ | 1.00 | 1.05 × 0.89 × 1.56 | — | — | — | SSJWeld (Weld) -> Head | Head | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_trunkz_base` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_trunkz_base` | InvisibleHitbox | SpecialMesh | Mesh | Morph.SSJ.Mesh | 1.00 | — | rbxassetid://459797551 | — | — | — | — | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) (removido junto com Part "SSJ") |
| `char_ulkiorra_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_ulkiorra_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | SwordWeld (Weld) -> Sword; SwordsWeld (Weld) -> Swords; SwordsWeldOld (Weld) -> Swords; SwordsWeldOld (Weld) -> Swords; SwordWeldOld (Weld) -> nil; SwordsWeldOld (Weld) -> nil; SwordsWeldOld (Weld) -> nil; SwordsWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil; SwordsWeldOld (Weld) -> nil; SwordsWeldOld (Weld) -> nil; SwordsWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil; Right Arm 🡪 RightHilt (Motor6D) -> Right Arm | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_ulkiorra_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_ulkiorra_base` | NameTag | Part | Head | [ X ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_ulkiorra_base` | NameTag | SpecialMesh | Mesh | [ X ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_ulkiorra_release` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_ulkiorra_release` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; SwordWeld (Weld) -> Sword; SwordWeldOld (Weld) -> nil; SwordsWeld (Weld) -> nil; SwordsWeldOld (Weld) -> nil; SwordsWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil; SwordsWeldOld (Weld) -> nil; SwordsWeldOld (Weld) -> nil; SwordsWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil; SwordsWeldOld (Weld) -> nil; SwordsWeldOld (Weld) -> nil; SwordsWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil; SwordsWeldOld (Weld) -> nil; SwordsWeldOld (Weld) -> nil; SwordsWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_ulkiorra_release` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_ulkiorra_release` | NameTag | Part | Head | [ X ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_ulkiorra_release` | NameTag | SpecialMesh | Mesh | [ X ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_vegitto_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_vegitto_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_vegitto_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_vegitto_base` | NameTag | Part | Head | [ X ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_vegitto_base` | NameTag | SpecialMesh | Mesh | [ X ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_vegitto_blue` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_vegitto_blue` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_vegitto_blue` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_vegitto_blue` | NameTag | Part | Head | [ X ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_vegitto_blue` | NameTag | SpecialMesh | Mesh | [ X ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_vejita_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_vejita_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; HiltWeld (Weld) -> nil; Blade2Weld (Weld) -> nil; BladeWeld (Weld) -> nil; HiltWeldOld (Weld) -> nil; Blade2WeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_vejita_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_vejita_base` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_vejita_base` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_vejita_majin` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_vejita_majin` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; HiltWeld (Weld) -> nil; Blade2Weld (Weld) -> nil; BladeWeld (Weld) -> nil; HiltWeldOld (Weld) -> nil; Blade2WeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_vejita_majin` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_vejita_majin` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_vejita_majin` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_yamamotu_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_yamamotu_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; CaneWeld (Weld) -> Cane; SwordWeld (Weld) -> Sword; BladeWeld (Weld) -> nil; ShikaiWeld (Weld) -> nil; SwordWeldOld (Weld) -> nil; EnergySwordRWeld (Weld) -> nil; SwordWeldOld (Weld) -> nil; ExtendingBladeWeld (Weld) -> nil; RealHiltWeld (Weld) -> nil; BladeWeldOld (Weld) -> nil; ExtendingBladeWeldOld (Weld) -> nil; RealHiltWeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil; ExtendingBladeWeldOld (Weld) -> nil; RealHiltWeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil; ExtendingBladeWeldOld (Weld) -> nil; RealHiltWeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil; ExtendingBladeWeldOld (Weld) -> nil; RealHiltWeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil; ExtendingBladeWeldOld (Weld) -> nil; RealHiltWeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil; ExtendingBladeWeldOld (Weld) -> nil; RealHiltWeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil; ExtendingBladeWeldOld (Weld) -> nil; RealHiltWeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil; ExtendingBladeWeldOld (Weld) -> nil; RealHiltWeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil; FakeSwordWeld (Weld) -> nil; SwordWeldOld (Weld) -> nil; RFurWeld (Weld) -> nil; RBladeWeld (Weld) -> nil; RGuardWeld (Weld) -> nil; RGoldWeld (Weld) -> nil; SwordWeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil; ShikaiWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil; ShikaiWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil; ShikaiWeldOld (Weld) -> nil; SwordWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_yamamotu_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm; EnergySwordLWeld (Weld) -> nil; LFurWeld (Weld) -> nil; LBladeWeld (Weld) -> nil; LGuardWeld (Weld) -> nil; LGoldWeld (Weld) -> nil | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_yamamotu_base` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_yamamotu_base` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_yoruka_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_yoruka_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; SwordWeld (Weld) -> nil; SwordWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_yoruka_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_yoruka_base` | NameTag | Part | Head | [ X ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_yoruka_base` | NameTag | SpecialMesh | Mesh | [ X ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_yoruka_shunko` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat, ParticleEmitter Shunko3, ParticleEmitter Shunko4, ParticleEmitter Shunko1, ParticleEmitter Shunko2 | HumanoidRootPart: peça raiz do rig |
| `char_yoruka_shunko` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; SwordWeld (Weld) -> nil; SwordWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_yoruka_shunko` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_yoruka_shunko` | NameTag | Part | Head | [ X ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_yoruka_shunko` | NameTag | SpecialMesh | Mesh | [ X ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_yujo_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_yujo_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; MySwordWeld (Weld) -> nil; MySwordWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_yujo_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_yujo_base` | NameTag | Part | Head | [ CHAMPION ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ CHAMPION ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ CHAMPION ]") |
| `char_yujo_base` | NameTag | SpecialMesh | Mesh | [ CHAMPION ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ CHAMPION ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ CHAMPION ]") |
| `char_yuzuke_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_yuzuke_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; SharpWeld (Weld) -> nil; BladeWeld (Weld) -> nil; HandleWeld (Weld) -> nil; SwordWeld (Weld) -> nil; KazumaBowWeld (Weld) -> nil; SwordWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_yuzuke_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm; SheathWeld (Weld) -> nil | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_yuzuke_base` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_yuzuke_base` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_yuzuke_demon` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat, ParticleEmitter BigParticle, ParticleEmitter SmallParticle | HumanoidRootPart: peça raiz do rig |
| `char_yuzuke_demon` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_yuzuke_demon` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_yuzuke_demon` | NameTag | Part | Head | [ X ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_yuzuke_demon` | InvisibleHitbox | MeshPart | YusukeHair | Morph.YusukeHair | 1.00 | 1.82 × 2.07 × 2.00 | rbxassetid://5621180708 | — | — | YusukeHairWeld (Weld) -> Head | Head | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_yuzuke_demon` | NameTag | SpecialMesh | Mesh | [ X ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]") |
| `char_zabuzo_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_zabuzo_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; ExecutionersWeld (Weld) -> Executioners; ExecutionersWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_zabuzo_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_zabuzo_base` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_zabuzo_base` | InvisibleHitbox | MeshPart | BackSword | Morph.BackSword | 1.00 | 1.35 × 8.42 × 0.31 | rbxassetid://521580928 | rbxassetid://521580933 | — | BackSwordWeld (Weld) -> Torso | Torso | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_zabuzo_base` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_zoru_base` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_zoru_base` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; KitetsuWeld (Weld) -> Kitetsu; KitetsuWeldOld (Weld) -> nil; HiltWeld (Weld) -> nil; Blade2Weld (Weld) -> nil; BladeWeld (Weld) -> nil; SwordDrawn1Weld (Weld) -> nil; KitetsuWeldOld (Weld) -> nil; HiltWeldOld (Weld) -> nil; Blade2WeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil; HiltWeldOld (Weld) -> nil; Blade2WeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_zoru_base` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm; ShisuiWeld (Weld) -> Shisui; ShisuiWeldOld (Weld) -> nil; SwordHiltWeld (Weld) -> nil; SheathWeld (Weld) -> nil; ShisuiWeldOld (Weld) -> nil | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_zoru_base` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_zoru_base` | InvisibleCombatHelper | MeshPart | Wado | Morph.Wado | 1.00 | 0.65 × 5.37 × 0.33 | rbxassetid://711813382 | rbxassetid://711813387 | — | WadoWeld (Weld) -> Head | Head | Trail Trail | Transparency=1.00; o único conteúdo visível eram VFX removidos pela política de VFX (Trail Trail) |
| `char_zoru_base` | InvisibleCombatHelper | MeshPart | Kitetsu | Morph.Kitetsu | 1.00 | 0.55 × 4.54 × 0.28 | rbxassetid://711811842 | rbxassetid://711811850 | — | KitetsuWeld (Weld) -> RightHilt | RightArm | Trail Trail | Transparency=1.00; o único conteúdo visível eram VFX removidos pela política de VFX (Trail Trail) |
| `char_zoru_base` | InvisibleCombatHelper | MeshPart | Shisui | Morph.Shisui | 1.00 | 0.57 × 4.71 × 0.29 | rbxassetid://711812754 | rbxassetid://711812760 | — | ShisuiWeld (Weld) -> LeftHilt | LeftArm | Trail Trail | Transparency=1.00; o único conteúdo visível eram VFX removidos pela política de VFX (Trail Trail) |
| `char_zoru_base` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_zoru_young` | RootPart | Part | HumanoidRootPart | HumanoidRootPart | 1.00 | 2.00 × 2.00 × 1.00 | — | — | — | RootJoint (Motor6D) -> Torso | Torso | ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1, ParticleEmitter Block, ParticleEmitter SoruP, ParticleEmitter LevelParticle, ParticleEmitter SenzuEat | HumanoidRootPart: peça raiz do rig |
| `char_zoru_young` | InvisibleHitbox | Part | RightHilt | RightHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Right Arm 🡪 RightHilt (Motor6D) -> Right Arm; KitetsuWeld (Weld) -> Kitetsu; HiltWeld (Weld) -> nil; Blade2Weld (Weld) -> nil; BladeWeld (Weld) -> nil; HiltWeldOld (Weld) -> nil; Blade2WeldOld (Weld) -> nil; BladeWeldOld (Weld) -> nil | RightArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_zoru_young` | InvisibleHitbox | Part | LeftHilt | LeftHilt | 1.00 | 1.00 × 0.05 × 1.00 | — | — | — | Left Arm 🡪 LeftHilt (Motor6D) -> Left Arm; ShisuiWeld (Weld) -> Shisui | LeftArm | — | Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) |
| `char_zoru_young` | NameTag | Part | Head | [ SEMI-PRO ].Head | 0.00 | 0.05 × 0.28 × 0.05 | — | — | — | Weld (ManualWeld) -> Head | Head | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |
| `char_zoru_young` | InvisibleCombatHelper | MeshPart | Kitetsu | Morph.Kitetsu | 1.00 | 0.55 × 4.54 × 0.28 | rbxassetid://711811842 | rbxassetid://711811850 | — | KitetsuWeld (Weld) -> RightHilt | RightArm | Trail Trail | Transparency=1.00; o único conteúdo visível eram VFX removidos pela política de VFX (Trail Trail) |
| `char_zoru_young` | InvisibleCombatHelper | MeshPart | Wado | Morph.Wado | 1.00 | 0.65 × 5.37 × 0.33 | rbxassetid://711813382 | rbxassetid://711813387 | — | WadoWeld (Weld) -> Head | Head | Trail Trail | Transparency=1.00; o único conteúdo visível eram VFX removidos pela política de VFX (Trail Trail) |
| `char_zoru_young` | InvisibleCombatHelper | MeshPart | Shisui | Morph.Shisui | 1.00 | 0.57 × 4.71 × 0.29 | rbxassetid://711812754 | rbxassetid://711812760 | — | ShisuiWeld (Weld) -> LeftHilt | LeftArm | Trail Trail | Transparency=1.00; o único conteúdo visível eram VFX removidos pela política de VFX (Trail Trail) |
| `char_zoru_young` | NameTag | SpecialMesh | Mesh | [ SEMI-PRO ].Head.Mesh | 0.00 | — | — | — | — | — | — | — | placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]") |

## POSSIBLE_DUPLICATE (5)

- char_bakugu_awakened = char_bakugu_base
- char_vegitto_base = char_vegitto_blue
- char_natzu_awakened = char_natzu_base
- char_roqueli_base = char_roqueli_gates
- char_lanseiro_base = char_lanseiro_mode

## Maiores personagens (instâncias no asset final)

- `char_mighto_gate8`: 117 instâncias, 10 peças, 1 MeshParts
- `char_mighto_gate5`: 110 instâncias, 11 peças, 2 MeshParts
- `char_deko_awakened`: 96 instâncias, 11 peças, 2 MeshParts
- `char_infernus_base`: 91 instâncias, 21 peças, 10 MeshParts
- `char_ilumi_awakened`: 88 instâncias, 10 peças, 0 MeshParts
- `char_vejita_base`: 75 instâncias, 39 peças, 0 MeshParts
- `char_akaino_base`: 73 instâncias, 23 peças, 16 MeshParts
- `char_samurai_afro_base`: 73 instâncias, 21 peças, 11 MeshParts
- `char_gaaro_base`: 72 instâncias, 17 peças, 1 MeshParts
- `char_lanseiro_mode`: 67 instâncias, 16 peças, 6 MeshParts

## Detalhes por personagem

### Anny (Colegial) (`char_anny_school`) — WARN
- Origem: `Anime Pack.AOT.Annie (Junior High)` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 0, remotes 0, sons 0, animações 0, bindables 0, estado 0, GUIs 0, peças invisíveis 0, placas de título 0, VFX 0, outros: —
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 1→1, SpecialMesh 2→2, Part 8→7 · objetos visuais: preservados 12, removidos com justificativa 1, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
- VFX mantidos: —
- Avisos: 1 peça(s) sem junta (presas pelo osso mais próximo): Handle

### Mikaza (Formal) (`char_mikaza_formal`) — WARN
- Origem: `Anime Pack.AOT.Mikasa (Formal)` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 0, remotes 0, sons 0, animações 0, bindables 0, estado 0, GUIs 0, peças invisíveis 0, placas de título 0, VFX 0, outros: —
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 1→1, SpecialMesh 3→3, Part 9→8 · objetos visuais: preservados 14, removidos com justificativa 1, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
- VFX mantidos: —
- Avisos: 2 peça(s) sem junta (presas pelo osso mais próximo): Handle, Handle

### Sacha (`char_sacha_base`) — WARN
- Origem: `Anime Pack.AOT.Sasha` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 0, remotes 0, sons 0, animações 0, bindables 0, estado 0, GUIs 0, peças invisíveis 0, placas de título 0, VFX 0, outros: —
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 1→1, SpecialMesh 2→2, Part 8→7 · objetos visuais: preservados 12, removidos com justificativa 1, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
- VFX mantidos: —
- Avisos: 1 peça(s) sem junta (presas pelo osso mais próximo): Handle

### Sacha (Terno) (`char_sacha_suit`) — WARN
- Origem: `Anime Pack.AOT.Sasha (Suit)` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 0, remotes 0, sons 0, animações 0, bindables 0, estado 0, GUIs 0, peças invisíveis 0, placas de título 0, VFX 0, outros: —
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 1→1, SpecialMesh 2→2, Part 8→7 · objetos visuais: preservados 12, removidos com justificativa 1, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
- VFX mantidos: —
- Avisos: 1 peça(s) sem junta (presas pelo osso mais próximo): Handle

### Chiko (`char_chiko_base`) — OK
- Origem: `Anime Pack.OTHER.MISC.Chika` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 1, remotes 4, sons 34, animações 10, bindables 0, estado 14, GUIs 2, peças invisíveis 2, placas de título 1, VFX 14, outros: Attachment 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 2→2, SpecialMesh 3→2, Part 11→7 · objetos visuais: preservados 15, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: —

### Erwyn (Gala) (`char_erwyn_gala`) — WARN
- Origem: `Anime Pack.AOT.Erwin (Alt)` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 0, remotes 0, sons 0, animações 0, bindables 0, estado 0, GUIs 0, peças invisíveis 0, placas de título 0, VFX 0, outros: —
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 1→1, SpecialMesh 2→2, Part 8→7 · objetos visuais: preservados 12, removidos com justificativa 1, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
- VFX mantidos: —
- Avisos: 1 peça(s) sem junta (presas pelo osso mais próximo): Hair

### Kurilo (`char_kurilo_base`) — OK
- Origem: `Anime Pack.DBZ.Krillin` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 2, remotes 5, sons 34, animações 22, bindables 0, estado 14, GUIs 2, peças invisíveis 2, placas de título 1, VFX 14, outros: Attachment 1, Folder 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, SpecialMesh 3→2, Part 11→7 · objetos visuais: preservados 13, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ X ].Head): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ X ].Head.Mesh): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
- VFX mantidos: —

### Saitano (`char_saitano_base`) — OK
- Origem: `Anime Pack.OTHER.MISC.Saitama` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 1, remotes 4, sons 34, animações 10, bindables 0, estado 14, GUIs 2, peças invisíveis 2, placas de título 1, VFX 14, outros: Attachment 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 1→1, SpecialMesh 4→3, Part 12→8 · objetos visuais: preservados 16, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: —

### Gom (`char_gom_base`) — OK
- Origem: `Anime Pack.HXH.Gon` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 1, remotes 4, sons 34, animações 10, bindables 0, estado 14, GUIs 2, peças invisíveis 2, placas de título 1, VFX 14, outros: Attachment 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 1→1, SpecialMesh 3→2, Part 11→7 · objetos visuais: preservados 14, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: —

### Sanjo (Jovem) (`char_sanjo_young`) — OK
- Origem: `Anime Pack.One Piece Pack.ptsSanji` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 1, remotes 4, sons 34, animações 10, bindables 0, estado 14, GUIs 2, peças invisíveis 2, placas de título 1, VFX 14, outros: Attachment 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 1→1, SpecialMesh 3→2, Part 11→7 · objetos visuais: preservados 14, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: —

### Kazumo (`char_kazumo_base`) — OK
- Origem: `Anime Pack.OTHER.Kazuma` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 1, remotes 4, sons 34, animações 10, bindables 0, estado 14, GUIs 2, peças invisíveis 2, placas de título 1, VFX 15, outros: Attachment 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 2→2, SpecialMesh 3→2, Part 11→7 · objetos visuais: preservados 15, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: —

### Rinn (`char_rinn_base`) — OK
- Origem: `Anime Pack.FATE.Rin` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 2, remotes 5, sons 34, animações 22, bindables 0, estado 14, GUIs 2, peças invisíveis 2, placas de título 1, VFX 14, outros: Attachment 1, Folder 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 2→2, SpecialMesh 3→2, Part 11→7 · objetos visuais: preservados 15, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: —

### Grei (`char_grei_base`) — OK
- Origem: `Anime Pack.Fairy Tail.Gray` · escala 0.988 · Humanoid (roupa): sim
- Removidos: scripts 2, remotes 5, sons 34, animações 22, bindables 0, estado 14, GUIs 2, peças invisíveis 2, placas de título 1, VFX 14, outros: Attachment 1, Folder 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 1→1, SpecialMesh 4→3, Part 12→8 · objetos visuais: preservados 16, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ CHAMPION  ].Head): placa de título do jogo de origem: Model "[ CHAMPION  ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ CHAMPION  ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ CHAMPION  ].Head.Mesh): placa de título do jogo de origem: Model "[ CHAMPION  ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ CHAMPION  ]")
- VFX mantidos: —

### Rukya (`char_rukya_base`) — OK
- Origem: `Anime Pack.Bleach Pack.Rukia` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 1, remotes 4, sons 34, animações 10, bindables 0, estado 14, GUIs 2, peças invisíveis 3, placas de título 1, VFX 15, outros: Attachment 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 3→2, SpecialMesh 3→2, Part 11→7 · objetos visuais: preservados 15, removidos com justificativa 6, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · InvisibleHitbox · MeshPart "Shikai" (Morph.Shikai): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: —

### Hizoka (`char_hizoka_base`) — OK
- Origem: `Anime Pack.HXH.Hisoka (2ª ocorrência)` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 2, remotes 5, sons 36, animações 22, bindables 0, estado 15, GUIs 2, peças invisíveis 2, placas de título 1, VFX 14, outros: Attachment 1, Folder 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 1→1, SpecialMesh 3→2, Part 11→7 · objetos visuais: preservados 14, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ X ].Head): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ X ].Head.Mesh): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
- VFX mantidos: ParticleEmitter Aura (Light)

### Erem (`char_erem_base`) — WARN
- Origem: `Anime Pack.AOT.Eren` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 0, remotes 0, sons 0, animações 0, bindables 0, estado 0, GUIs 0, peças invisíveis 0, placas de título 0, VFX 0, outros: —
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 1→1, SpecialMesh 2→2, Part 8→7 · objetos visuais: preservados 12, removidos com justificativa 1, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
- VFX mantidos: —
- Avisos: 1 peça(s) sem junta (presas pelo osso mais próximo): Handle

### Anny (`char_anny_base`) — WARN
- Origem: `Anime Pack.AOT.Annie` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 0, remotes 0, sons 0, animações 0, bindables 0, estado 0, GUIs 0, peças invisíveis 0, placas de título 0, VFX 0, outros: —
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 1→1, SpecialMesh 2→2, Part 8→7 · objetos visuais: preservados 12, removidos com justificativa 1, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
- VFX mantidos: —
- Avisos: 1 peça(s) sem junta (presas pelo osso mais próximo): Handle

### Mikaza (`char_mikaza_base`) — WARN
- Origem: `Anime Pack.AOT.Mikasa` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 0, remotes 0, sons 0, animações 0, bindables 0, estado 0, GUIs 0, peças invisíveis 0, placas de título 0, VFX 0, outros: —
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 1→1, SpecialMesh 3→3, Part 9→8 · objetos visuais: preservados 14, removidos com justificativa 1, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
- VFX mantidos: —
- Avisos: 2 peça(s) sem junta (presas pelo osso mais próximo): Handle, Handle

### Erem (Veterano) (`char_erem_veteran`) — WARN
- Origem: `Anime Pack.AOT.Eren Post-time skip` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 0, remotes 0, sons 0, animações 0, bindables 0, estado 0, GUIs 0, peças invisíveis 0, placas de título 0, VFX 0, outros: —
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 1→1, SpecialMesh 2→2, Part 8→7 · objetos visuais: preservados 12, removidos com justificativa 1, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
- VFX mantidos: —
- Avisos: 1 peça(s) sem junta (presas pelo osso mais próximo): Handle

### Erwyn (`char_erwyn_base`) — WARN
- Origem: `Anime Pack.AOT.Erwin` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 0, remotes 0, sons 0, animações 0, bindables 0, estado 0, GUIs 0, peças invisíveis 0, placas de título 0, VFX 0, outros: —
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 1→1, SpecialMesh 3→3, Part 9→8 · objetos visuais: preservados 14, removidos com justificativa 1, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
- VFX mantidos: —
- Avisos: 2 peça(s) sem junta (presas pelo osso mais próximo): Cape, Hair

### Titã Feminina (`char_anny_titan`) — WARN
- Origem: `Anime Pack.AOT.Female Titan` · escala 0.425 · Humanoid (roupa): sim
- Removidos: scripts 0, remotes 0, sons 0, animações 0, bindables 0, estado 0, GUIs 0, peças invisíveis 0, placas de título 0, VFX 0, outros: —
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 1→1, SpecialMesh 2→2, Part 8→7 · objetos visuais: preservados 12, removidos com justificativa 1, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
- VFX mantidos: —
- Avisos: 1 peça(s) sem junta (presas pelo osso mais próximo): Handle

### Titã de Ataque (`char_erem_titan`) — WARN
- Origem: `Anime Pack.AOT.Attack Titan` · escala 0.463 · Humanoid (roupa): sim
- Removidos: scripts 0, remotes 0, sons 0, animações 0, bindables 0, estado 0, GUIs 0, peças invisíveis 0, placas de título 0, VFX 0, outros: —
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 1→1, SpecialMesh 3→3, Part 9→8 · objetos visuais: preservados 14, removidos com justificativa 1, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
- VFX mantidos: —
- Avisos: 2 peça(s) sem junta (presas pelo osso mais próximo): Handle, Handle

### Natzu (`char_natzu_base`) — OK
- Origem: `Anime Pack.Fairy Tail.Natsu` · escala 0.988 · Humanoid (roupa): sim
- Removidos: scripts 2, remotes 5, sons 34, animações 22, bindables 0, estado 14, GUIs 2, peças invisíveis 2, placas de título 1, VFX 14, outros: Attachment 1, Folder 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 2→2, SpecialMesh 4→3, Part 12→8 · objetos visuais: preservados 17, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ CHAMPION  ].Head): placa de título do jogo de origem: Model "[ CHAMPION  ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ CHAMPION  ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ CHAMPION  ].Head.Mesh): placa de título do jogo de origem: Model "[ CHAMPION  ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ CHAMPION  ]")
- VFX mantidos: —
- Avisos: POSSIBLE_DUPLICATE: mesmo visual que char_natzu_awakened, char_natzu_base

### Todoruki (`char_todoruki_base`) — OK
- Origem: `Anime Pack.My Hero Academia Pack.Todoroki` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 1, remotes 4, sons 34, animações 10, bindables 0, estado 18, GUIs 2, peças invisíveis 2, placas de título 1, VFX 18, outros: Attachment 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, Texture 12→12, MeshPart 1→1, SpecialMesh 3→2, Part 13→9 · objetos visuais: preservados 28, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: —

### Ase (`char_ase_base`) — OK
- Origem: `Anime Pack.One Piece Pack.Ace` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 1, remotes 4, sons 34, animações 10, bindables 0, estado 14, GUIs 2, peças invisíveis 2, placas de título 1, VFX 14, outros: Attachment 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 4→4, SpecialMesh 3→2, Part 11→7 · objetos visuais: preservados 17, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: —

### Bakugu (`char_bakugu_base`) — OK
- Origem: `Anime Pack.My Hero Academia Pack.Bakugo` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 2, remotes 5, sons 34, animações 22, bindables 0, estado 14, GUIs 2, peças invisíveis 2, placas de título 1, VFX 14, outros: Attachment 1, Folder 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 1→1, SpecialMesh 3→2, Part 13→9, UnionOperation 10→10 · objetos visuais: preservados 26, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ X ].Head): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ X ].Head.Mesh): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
- VFX mantidos: —
- Avisos: POSSIBLE_DUPLICATE: mesmo visual que char_bakugu_awakened, char_bakugu_base

### Yamamotu (`char_yamamotu_base`) — OK
- Origem: `Anime Pack.Bleach Pack.Yamamoto` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 1, remotes 4, sons 34, animações 10, bindables 0, estado 14, GUIs 2, peças invisíveis 2, placas de título 1, VFX 16, outros: Attachment 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 2→2, SpecialMesh 3→2, Part 11→7, UnionOperation 2→2 · objetos visuais: preservados 17, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: ParticleEmitter Fire (Light), ParticleEmitter Fire (Light), PointLight PointLight (Full)

### Akaino (`char_akaino_base`) — OK
- Origem: `Anime Pack.One Piece Pack.Akainu` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 2, remotes 5, sons 34, animações 22, bindables 0, estado 14, GUIs 2, peças invisíveis 2, placas de título 1, VFX 14, outros: Attachment 1, Folder 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, Texture 12→12, MeshPart 16→16, SpecialMesh 3→2, Part 11→7 · objetos visuais: preservados 41, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ X ].Head): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ X ].Head.Mesh): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
- VFX mantidos: —

### Narotu (Jovem) (`char_narotu_young`) — OK
- Origem: `Anime Pack.NARUTO.ptsNaruto` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 1, remotes 4, sons 34, animações 10, bindables 0, estado 14, GUIs 2, peças invisíveis 2, placas de título 1, VFX 14, outros: Attachment 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 1→1, SpecialMesh 3→2, Part 11→7 · objetos visuais: preservados 14, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: —

### Sasuko (Jovem) (`char_sasuko_young`) — OK
- Origem: `Anime Pack.NARUTO.ptsSasuke` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 1, remotes 4, sons 34, animações 10, bindables 0, estado 14, GUIs 2, peças invisíveis 2, placas de título 1, VFX 14, outros: Attachment 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 1→1, SpecialMesh 4→3, Part 12→8 · objetos visuais: preservados 16, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: —

### Nejo (`char_nejo_base`) — OK
- Origem: `Anime Pack.NARUTO.Neji` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 1, remotes 4, sons 34, animações 10, bindables 0, estado 14, GUIs 2, peças invisíveis 2, placas de título 1, VFX 14, outros: Attachment 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 2→2, SpecialMesh 3→2, Part 11→7 · objetos visuais: preservados 15, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: —

### Roque Li (`char_roqueli_base`) — OK
- Origem: `Anime Pack.NARUTO.Rock Lee.Rock Lee` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 1, remotes 4, sons 34, animações 10, bindables 0, estado 14, GUIs 2, peças invisíveis 2, placas de título 1, VFX 14, outros: Attachment 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 11→11, MeshPart 1→1, SpecialMesh 3→2, Part 13→9, UnionOperation 3→3 · objetos visuais: preservados 28, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: —
- Avisos: POSSIBLE_DUPLICATE: mesmo visual que char_roqueli_base, char_roqueli_gates

### Gaaro (`char_gaaro_base`) — OK
- Origem: `Anime Pack.NARUTO.Gaara` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 1, remotes 4, sons 34, animações 10, bindables 0, estado 14, GUIs 2, peças invisíveis 2, placas de título 1, VFX 16, outros: Attachment 2
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 11→11, MeshPart 1→1, SpecialMesh 11→10, Part 19→15, UnionOperation 1→1 · objetos visuais: preservados 40, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: ParticleEmitter Particle (Full)

### Zabuzo (`char_zabuzo_base`) — OK
- Origem: `Anime Pack.NARUTO.Zabuza` · escala 0.985 · Humanoid (roupa): sim
- Removidos: scripts 1, remotes 4, sons 34, animações 10, bindables 0, estado 14, GUIs 2, peças invisíveis 3, placas de título 1, VFX 14, outros: Attachment 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 5→4, SpecialMesh 3→2, Part 11→7 · objetos visuais: preservados 17, removidos com justificativa 6, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · InvisibleHitbox · MeshPart "BackSword" (Morph.BackSword): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: —

### Kakaxi (`char_kakaxi_base`) — OK
- Origem: `Anime Pack.NARUTO.Kakashi` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 1, remotes 4, sons 34, animações 10, bindables 0, estado 14, GUIs 2, peças invisíveis 5, placas de título 1, VFX 14, outros: Attachment 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 2→1, SpecialMesh 7→4, Part 15→9 · objetos visuais: preservados 18, removidos com justificativa 10, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · InvisibleHitbox · MeshPart "HairUp2" (Morph.HairUp2): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "HairUp1" (Morph.HairUp1): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "HairUp3" (Morph.HairUp3): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · InvisibleHitbox · SpecialMesh "Mesh" (Morph.HairUp1.Mesh): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) (removido junto com Part "HairUp1")
  - JUSTIFIED · InvisibleHitbox · SpecialMesh "Mesh" (Morph.HairUp3.Mesh): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) (removido junto com Part "HairUp3")
- VFX mantidos: —

### Narotu (`char_narotu_base`) — OK
- Origem: `Anime Pack.NARUTO.tsNaruto` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 1, remotes 4, sons 34, animações 10, bindables 0, estado 14, GUIs 2, peças invisíveis 2, placas de título 1, VFX 14, outros: Attachment 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 1→1, SpecialMesh 3→2, Part 11→7 · objetos visuais: preservados 14, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: —

### Ichiro (`char_ichiro_base`) — OK
- Origem: `Anime Pack.Bleach Pack.Ichigo` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 1, remotes 4, sons 34, animações 10, bindables 0, estado 14, GUIs 2, peças invisíveis 3, placas de título 1, VFX 15, outros: Attachment 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 3→2, SpecialMesh 3→2, Part 11→7 · objetos visuais: preservados 15, removidos com justificativa 6, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · InvisibleHitbox · MeshPart "Shikai" (Morph.Shikai): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: —

### Zoru (Jovem) (`char_zoru_young`) — OK
- Origem: `Anime Pack.One Piece Pack.ptsZoro` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 1, remotes 4, sons 34, animações 10, bindables 0, estado 14, GUIs 2, peças invisíveis 5, placas de título 1, VFX 17, outros: Attachment 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 10→7, SpecialMesh 3→2, Part 11→7, UnionOperation 1→1 · objetos visuais: preservados 21, removidos com justificativa 8, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · InvisibleCombatHelper · MeshPart "Kitetsu" (Morph.Kitetsu): Transparency=1.00; o único conteúdo visível eram VFX removidos pela política de VFX (Trail Trail)
  - JUSTIFIED · InvisibleCombatHelper · MeshPart "Wado" (Morph.Wado): Transparency=1.00; o único conteúdo visível eram VFX removidos pela política de VFX (Trail Trail)
  - JUSTIFIED · InvisibleCombatHelper · MeshPart "Shisui" (Morph.Shisui): Transparency=1.00; o único conteúdo visível eram VFX removidos pela política de VFX (Trail Trail)
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: —

### Ginn (`char_ginn_base`) — OK
- Origem: `Anime Pack.Bleach Pack.Gin` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 1, remotes 4, sons 34, animações 10, bindables 0, estado 14, GUIs 2, peças invisíveis 2, placas de título 1, VFX 14, outros: Attachment 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 3→3, SpecialMesh 4→3, Part 12→8 · objetos visuais: preservados 18, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: —

### Kisuko (`char_kisuko_base`) — OK
- Origem: `Anime Pack.Bleach Pack.Kisuke` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 1, remotes 4, sons 34, animações 10, bindables 0, estado 14, GUIs 2, peças invisíveis 3, placas de título 1, VFX 16, outros: Attachment 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 3→2, SpecialMesh 4→3, Part 12→8, UnionOperation 2→2 · objetos visuais: preservados 19, removidos com justificativa 6, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · InvisibleHitbox · MeshPart "Shikai" (Morph.Shikai): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: —

### Trunkz (`char_trunkz_base`) — OK
- Origem: `Anime Pack.DBZ.Trunks` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 1, remotes 4, sons 34, animações 10, bindables 0, estado 14, GUIs 2, peças invisíveis 3, placas de título 1, VFX 14, outros: Attachment 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, SpecialMesh 5→3, Part 13→8, UnionOperation 6→6 · objetos visuais: preservados 21, removidos com justificativa 7, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · InvisibleHitbox · Part "SSJ" (Morph.SSJ): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · InvisibleHitbox · SpecialMesh "Mesh" (Morph.SSJ.Mesh): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) (removido junto com Part "SSJ")
- VFX mantidos: ParticleEmitter SaiyanAura (Light)

### Tanjiru (`char_tanjiru_base`) — OK
- Origem: `Anime Pack.OTHER.MISC.Tanjiro` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 1, remotes 4, sons 34, animações 10, bindables 0, estado 14, GUIs 2, peças invisíveis 2, placas de título 1, VFX 19, outros: Attachment 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 5→5, SpecialMesh 3→2, Part 11→7 · objetos visuais: preservados 18, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: —

### Zoru (`char_zoru_base`) — OK
- Origem: `Anime Pack.One Piece Pack.tsZoro` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 1, remotes 4, sons 34, animações 10, bindables 0, estado 14, GUIs 2, peças invisíveis 5, placas de título 1, VFX 17, outros: Attachment 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 10→7, SpecialMesh 3→2, Part 11→7, UnionOperation 1→1 · objetos visuais: preservados 21, removidos com justificativa 8, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · InvisibleCombatHelper · MeshPart "Wado" (Morph.Wado): Transparency=1.00; o único conteúdo visível eram VFX removidos pela política de VFX (Trail Trail)
  - JUSTIFIED · InvisibleCombatHelper · MeshPart "Kitetsu" (Morph.Kitetsu): Transparency=1.00; o único conteúdo visível eram VFX removidos pela política de VFX (Trail Trail)
  - JUSTIFIED · InvisibleCombatHelper · MeshPart "Shisui" (Morph.Shisui): Transparency=1.00; o único conteúdo visível eram VFX removidos pela política de VFX (Trail Trail)
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: —

### Shankz (`char_shankz_base`) — OK
- Origem: `Anime Pack.One Piece Pack.Shanks` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 1, remotes 4, sons 34, animações 10, bindables 0, estado 14, GUIs 2, peças invisíveis 8, placas de título 1, VFX 14, outros: Attachment 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 10→6, SpecialMesh 3→2, Part 11→7, UnionOperation 4→2 · objetos visuais: preservados 21, removidos com justificativa 11, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · InvisibleHitbox · UnionOperation "BladeUnion" (Morph.Blade.BladeUnion): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · MeshPart "cylinder" (Morph.Blade.HiltModel.cylinder): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · MeshPart "cylinder" (Morph.Blade.HiltModel.cylinder): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · MeshPart "cylinder" (Morph.Blade.HiltModel.cylinder): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · UnionOperation "Union" (Morph.Blade.HiltModel.Union): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · MeshPart "cylinder" (Morph.Blade.HiltModel.cylinder): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
- VFX mantidos: —

### Deko (`char_deko_base`) — OK
- Origem: `Anime Pack.My Hero Academia Pack.Deku` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 2, remotes 5, sons 34, animações 22, bindables 0, estado 16, GUIs 2, peças invisíveis 2, placas de título 1, VFX 17, outros: Attachment 1, Folder 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, Texture 12→12, MeshPart 2→2, SpecialMesh 3→2, Part 13→9 · objetos visuais: preservados 29, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ X ].Head): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ X ].Head.Mesh): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
- VFX mantidos: —

### Goko (`char_goko_base`) — OK
- Origem: `Anime Pack.DBZ.Goku` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 1, remotes 4, sons 34, animações 10, bindables 0, estado 16, GUIs 2, peças invisíveis 2, placas de título 1, VFX 14, outros: Attachment 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 3→3, SpecialMesh 4→3, Part 12→8 · objetos visuais: preservados 16, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: —

### Yuzuke (`char_yuzuke_base`) — OK
- Origem: `Anime Pack.YYH.Yusuke` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 1, remotes 4, sons 34, animações 10, bindables 0, estado 14, GUIs 2, peças invisíveis 2, placas de título 1, VFX 14, outros: Attachment 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 1→1, SpecialMesh 3→2, Part 11→7 · objetos visuais: preservados 14, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: —

### Lemilio (`char_lemilio_base`) — OK
- Origem: `Anime Pack.My Hero Academia Pack.Lemillion` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 1, remotes 4, sons 34, animações 10, bindables 0, estado 15, GUIs 2, peças invisíveis 2, placas de título 1, VFX 15, outros: Attachment 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 4→4, SpecialMesh 3→2, Part 11→7 · objetos visuais: preservados 17, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: —

### Lufy (`char_lufy_base`) — OK
- Origem: `Anime Pack.One Piece Pack.TS Luffy.tsLuffy` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 1, remotes 4, sons 34, animações 10, bindables 0, estado 14, GUIs 2, peças invisíveis 2, placas de título 1, VFX 14, outros: Attachment 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 12→12, MeshPart 2→2, SpecialMesh 3→2, Part 11→7, UnionOperation 4→4 · objetos visuais: preservados 29, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: —

### Pikkolo (`char_pikkolo_base`) — OK
- Origem: `Anime Pack.DBZ.Piccolo` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 1, remotes 4, sons 34, animações 10, bindables 0, estado 15, GUIs 2, peças invisíveis 3, placas de título 1, VFX 14, outros: Attachment 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 3→3, SpecialMesh 6→4, Part 14→9 · objetos visuais: preservados 20, removidos com justificativa 7, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · InvisibleHitbox · Part "Aten" (Morph.Aten): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · InvisibleHitbox · SpecialMesh "Mesh" (Morph.Aten.Mesh): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) (removido junto com Part "Aten")
- VFX mantidos: —

### Ol Maito (`char_olmaito_base`) — OK
- Origem: `Anime Pack.My Hero Academia Pack.All Might` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 2, remotes 5, sons 34, animações 22, bindables 0, estado 18, GUIs 2, peças invisíveis 2, placas de título 1, VFX 14, outros: Attachment 1, Folder 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 1→1, SpecialMesh 3→2, Part 11→7 · objetos visuais: preservados 14, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ X ].Head): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ X ].Head.Mesh): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
- VFX mantidos: —

### Killuo (`char_killuo_base`) — WARN
- Origem: `Anime Pack.HXH.Killua` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 1, remotes 4, sons 34, animações 10, bindables 0, estado 14, GUIs 2, peças invisíveis 2, placas de título 1, VFX 14, outros: Attachment 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 1→1, SpecialMesh 3→2, Part 11→7 · objetos visuais: preservados 14, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: —
- Avisos: roupa REVIEW_REQUIRED: Pants 2065252088 (veja CLOTHING_AUDIT.md); roupa REVIEW_REQUIRED: Shirt 2065247269 (veja CLOTHING_AUDIT.md)

### Lanseiro (`char_lanseiro_base`) — OK
- Origem: `Anime Pack.FATE.Lancer ` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 2, remotes 5, sons 34, animações 22, bindables 1, estado 16, GUIs 2, peças invisíveis 2, placas de título 1, VFX 21, outros: Attachment 1, Folder 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 6→6, SpecialMesh 4→3, Part 12→8 · objetos visuais: preservados 21, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: —
- Avisos: POSSIBLE_DUPLICATE: mesmo visual que char_lanseiro_base, char_lanseiro_mode

### Minatu (`char_minatu_base`) — OK
- Origem: `Anime Pack.NARUTO.Minato.Minato` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 1, remotes 4, sons 34, animações 10, bindables 0, estado 14, GUIs 2, peças invisíveis 3, placas de título 1, VFX 14, outros: Attachment 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 2→1, SpecialMesh 4→3, Part 12→8 · objetos visuais: preservados 16, removidos com justificativa 6, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · InvisibleHitbox · MeshPart "MinatoKunai" (Morph.MinatoKunai): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: —

### Goko (Saga Majin) (`char_goko_majin_saga`) — OK
- Origem: `Anime Pack.DBZ.Buu Saga Goku` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 1, remotes 4, sons 34, animações 10, bindables 0, estado 14, GUIs 2, peças invisíveis 4, placas de título 1, VFX 14, outros: Attachment 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 1→0, SpecialMesh 5→3, Part 13→8 · objetos visuais: preservados 15, removidos com justificativa 8, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · InvisibleHitbox · MeshPart "SSJ3" (Morph.SSJ3): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "SaiyanHair3" (Morph.SaiyanHair3): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · InvisibleHitbox · SpecialMesh "Mesh" (Morph.SaiyanHair3.Mesh): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) (removido junto com Part "SaiyanHair3")
- VFX mantidos: ParticleEmitter SaiyanAura (Light), ParticleEmitter Lightning (Full)

### Kaulifa (`char_kaulifa_base`) — OK
- Origem: `Anime Pack.DBZ.Caulifa` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 1, remotes 4, sons 34, animações 10, bindables 0, estado 14, GUIs 2, peças invisíveis 3, placas de título 1, VFX 14, outros: Attachment 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 2→1, SpecialMesh 3→2, Part 11→7 · objetos visuais: preservados 14, removidos com justificativa 6, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · InvisibleHitbox · MeshPart "SSJ2" (Morph.SSJ2): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: ParticleEmitter SaiyanAura (Light), ParticleEmitter SaiyanAura2 (Full), ParticleEmitter Lightning (Full)

### Deko Desperto (`char_deko_awakened`) — OK
- Origem: `Anime Pack.My Hero Academia Pack.Deku Awakened` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 2, remotes 5, sons 35, animações 22, bindables 0, estado 17, GUIs 2, peças invisíveis 2, placas de título 1, VFX 23, outros: Attachment 1, Folder 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, Texture 48→48, MeshPart 2→2, SpecialMesh 3→2, Part 13→9 · objetos visuais: preservados 65, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ X ].Head): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ X ].Head.Mesh): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
- VFX mantidos: —

### Killuo Relâmpago (`char_killuo_godspeed`) — WARN
- Origem: `Anime Pack.HXH.Killua Godspeed` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 2, remotes 5, sons 35, animações 22, bindables 0, estado 15, GUIs 2, peças invisíveis 3, placas de título 1, VFX 24, outros: Attachment 1, Folder 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 2→1, SpecialMesh 3→2, Part 11→7 · objetos visuais: preservados 14, removidos com justificativa 6, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ X ].Head): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
  - JUSTIFIED · InvisibleHitbox · MeshPart "Hair" (Morph.Hair): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ X ].Head.Mesh): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
- VFX mantidos: ParticleEmitter Lightning (Light), ParticleEmitter Lightning (Light), ParticleEmitter Lightning (Full), ParticleEmitter Lightning (Full), ParticleEmitter Lightning (Full), ParticleEmitter Lightning (Full)
- Avisos: roupa REVIEW_REQUIRED: Pants 2065252088 (veja CLOTHING_AUDIT.md); roupa REVIEW_REQUIRED: Shirt 2065247269 (veja CLOTHING_AUDIT.md)

### Toshiru (`char_toshiru_base`) — OK
- Origem: `Anime Pack.Bleach Pack.Toshiro.Toshiro` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 2, remotes 5, sons 34, animações 22, bindables 0, estado 14, GUIs 2, peças invisíveis 2, placas de título 1, VFX 15, outros: Attachment 1, Folder 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 5→5, SpecialMesh 4→3, Part 12→8 · objetos visuais: preservados 20, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ X ].Head): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ X ].Head.Mesh): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
- VFX mantidos: —

### Byakuto (`char_byakuto_base`) — OK
- Origem: `Anime Pack.Bleach Pack.Byakuya` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 1, remotes 4, sons 34, animações 10, bindables 0, estado 14, GUIs 2, peças invisíveis 2, placas de título 1, VFX 17, outros: Attachment 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 4→4, SpecialMesh 3→2, Part 11→7 · objetos visuais: preservados 17, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: —

### Shunzo (`char_shunzo_base`) — OK
- Origem: `Anime Pack.Bleach Pack.Shunsui` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 1, remotes 4, sons 34, animações 10, bindables 0, estado 14, GUIs 2, peças invisíveis 2, placas de título 1, VFX 14, outros: Attachment 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 11→11, SpecialMesh 3→2, Part 11→7 · objetos visuais: preservados 24, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: —

### Starko (`char_starko_base`) — OK
- Origem: `Anime Pack.Bleach Pack.Starrk` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 1, remotes 4, sons 34, animações 10, bindables 0, estado 14, GUIs 2, peças invisíveis 4, placas de título 1, VFX 17, outros: Attachment 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 5→3, SpecialMesh 3→2, Part 11→7 · objetos visuais: preservados 16, removidos com justificativa 7, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · InvisibleCombatHelper · MeshPart "EnergySwordR" (Morph.EnergySwordR): Transparency=1.00; o único conteúdo visível eram VFX removidos pela política de VFX (Trail Trail)
  - JUSTIFIED · InvisibleCombatHelper · MeshPart "EnergySwordL" (Morph.EnergySwordL): Transparency=1.00; o único conteúdo visível eram VFX removidos pela política de VFX (Trail Trail)
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: —

### Hiey (`char_hiey_base`) — OK
- Origem: `Anime Pack.YYH.Hiei` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 1, remotes 4, sons 34, animações 10, bindables 0, estado 14, GUIs 2, peças invisíveis 6, placas de título 1, VFX 14, outros: Attachment 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 9→5, SpecialMesh 4→3, Part 12→8 · objetos visuais: preservados 20, removidos com justificativa 9, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · InvisibleHitbox · MeshPart "HairAwakened" (Morph.HairAwakened): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · MeshPart "Hilt" (Morph.Hilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · MeshPart "Blade2" (Morph.Blade2): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · MeshPart "Blade" (Morph.Blade): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: —

### Yoruka (`char_yoruka_base`) — OK
- Origem: `Anime Pack.Bleach Pack.Yoruichi.Yoruichi` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 2, remotes 5, sons 34, animações 22, bindables 0, estado 14, GUIs 2, peças invisíveis 2, placas de título 1, VFX 14, outros: Attachment 1, Folder 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 1→1, SpecialMesh 4→3, Part 12→8 · objetos visuais: preservados 16, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ X ].Head): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ X ].Head.Mesh): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
- VFX mantidos: —

### Yuzuke Demônio (`char_yuzuke_demon`) — OK
- Origem: `Anime Pack.YYH.Yusuke Mode` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 2, remotes 5, sons 35, animações 22, bindables 0, estado 15, GUIs 2, peças invisíveis 3, placas de título 1, VFX 16, outros: Attachment 1, Folder 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 1→0, SpecialMesh 4→3, Part 12→8 · objetos visuais: preservados 15, removidos com justificativa 6, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ X ].Head): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
  - JUSTIFIED · InvisibleHitbox · MeshPart "YusukeHair" (Morph.YusukeHair): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ X ].Head.Mesh): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
- VFX mantidos: —

### Kiritsugo (`char_kiritsugo_base`) — OK
- Origem: `Anime Pack.FATE.Kiritsugu` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 2, remotes 5, sons 35, animações 22, bindables 0, estado 15, GUIs 2, peças invisíveis 2, placas de título 1, VFX 14, outros: Attachment 1, Folder 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 1→1, SpecialMesh 4→3, Part 12→8 · objetos visuais: preservados 16, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: —

### Seiba (`char_seiba_base`) — OK
- Origem: `Anime Pack.FATE.Fate Pack.Saber` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 1, remotes 4, sons 34, animações 10, bindables 0, estado 14, GUIs 2, peças invisíveis 3, placas de título 1, VFX 15, outros: Attachment 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 4→3, SpecialMesh 4→3, Part 12→8 · objetos visuais: preservados 18, removidos com justificativa 6, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · InvisibleCombatHelper · MeshPart "SpecialBlade" (Morph.SpecialBlade): Transparency=1.00; o único conteúdo visível eram VFX removidos pela política de VFX (ParticleEmitter Charge)
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: —

### Shiro (`char_shiro_base`) — OK
- Origem: `Anime Pack.FATE.Fate Pack.Shirou` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 1, remotes 4, sons 34, animações 10, bindables 0, estado 14, GUIs 2, peças invisíveis 4, placas de título 1, VFX 14, outros: Attachment 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, Texture 4→4, MeshPart 6→4, SpecialMesh 4→3, Part 12→8 · objetos visuais: preservados 23, removidos com justificativa 7, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · InvisibleHitbox · MeshPart "RightSwordEX" (Morph.RightSwordEX): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · MeshPart "LeftSwordEX" (Morph.LeftSwordEX): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: —

### Akcel (`char_akcel_base`) — OK
- Origem: `Anime Pack.OTHER.Accel` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 2, remotes 5, sons 34, animações 22, bindables 0, estado 14, GUIs 2, peças invisíveis 2, placas de título 1, VFX 14, outros: Attachment 1, Folder 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 2→2, SpecialMesh 4→3, Part 12→8 · objetos visuais: preservados 17, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: —

### Lau (`char_lau_base`) — OK
- Origem: `Anime Pack.One Piece Pack.ptsLaw` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 1, remotes 4, sons 34, animações 10, bindables 0, estado 14, GUIs 2, peças invisíveis 3, placas de título 1, VFX 15, outros: Attachment 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 4→3, SpecialMesh 3→2, Part 11→7 · objetos visuais: preservados 16, removidos com justificativa 6, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · InvisibleCombatHelper · MeshPart "SwordDrawn1" (Morph.SwordDrawn1): Transparency=1.00; o único conteúdo visível eram VFX removidos pela política de VFX (Trail Trail)
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: —

### Rika (`char_rika_base`) — OK
- Origem: `Anime Pack.OTHER.Rikka` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 2, remotes 5, sons 34, animações 33, bindables 0, estado 14, GUIs 2, peças invisíveis 2, placas de título 1, VFX 20, outros: Attachment 1, Folder 2
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 3→3, SpecialMesh 4→3, Part 12→8 · objetos visuais: preservados 18, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: ParticleEmitter CircleParticle (Light), ParticleEmitter FireOutParticle (Full)

### Gilgamex (`char_gilgamex_base`) — OK
- Origem: `Anime Pack.FATE.Fate Pack.Gilgamesh` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 1, remotes 4, sons 34, animações 10, bindables 0, estado 14, GUIs 2, peças invisíveis 2, placas de título 1, VFX 14, outros: Attachment 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 4→4, SpecialMesh 4→3, Part 12→8 · objetos visuais: preservados 19, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: —

### Emyia Arqueiro (`char_shiro_archer`) — OK
- Origem: `Anime Pack.FATE.Archer (EMIYA)` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 2, remotes 5, sons 34, animações 44, bindables 0, estado 14, GUIs 2, peças invisíveis 4, placas de título 1, VFX 17, outros: Attachment 1, Folder 3
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, Texture 4→4, MeshPart 6→4, SpecialMesh 4→3, Part 12→8 · objetos visuais: preservados 23, removidos com justificativa 7, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · InvisibleHitbox · MeshPart "RightSword" (Morph.RightSword): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · MeshPart "LeftSword" (Morph.LeftSword): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: PointLight PointLight (Light)

### Grimjau (`char_grimjau_base`) — OK
- Origem: `Anime Pack.Bleach Pack.Grimmjow` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 1, remotes 4, sons 34, animações 10, bindables 0, estado 14, GUIs 2, peças invisíveis 9, placas de título 1, VFX 14, outros: Attachment 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 10→3, SpecialMesh 3→2, Part 11→7 · objetos visuais: preservados 16, removidos com justificativa 12, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · InvisibleHitbox · MeshPart "FakeSword" (Morph.FakeSword): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · MeshPart "ResEars" (Morph.ResEars): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · MeshPart "ResCrown" (Morph.ResCrown): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · MeshPart "ResHair" (Morph.ResHair): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · MeshPart "Tail" (Morph.Tail): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · MeshPart "ResSpikeL" (Morph.ResSpikeL): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · MeshPart "ResSpikeR" (Morph.ResSpikeR): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: —

### Shinjo (`char_shinjo_base`) — OK
- Origem: `Anime Pack.Bleach Pack.Shinji` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 1, remotes 4, sons 34, animações 10, bindables 0, estado 14, GUIs 2, peças invisíveis 6, placas de título 1, VFX 16, outros: Attachment 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 8→8, MeshPart 3→2, SpecialMesh 7→4, Part 15→9, UnionOperation 1→0 · objetos visuais: preservados 25, removidos com justificativa 11, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · InvisibleCombatHelper · UnionOperation "Shikai" (Morph.Shikai): Transparency=1.00; o único conteúdo visível eram VFX removidos pela política de VFX (ParticleEmitter Smokey)
  - JUSTIFIED · InvisibleHitbox · Part "Mask3" (Morph.Mask3): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "Mask2" (Morph.Mask2): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · MeshPart "Mask" (Morph.Mask): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · InvisibleHitbox · SpecialMesh "Mesh" (Morph.Mask3.Mesh): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) (removido junto com Part "Mask3")
  - JUSTIFIED · InvisibleHitbox · SpecialMesh "Mesh" (Morph.Mask2.Mesh): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) (removido junto com Part "Mask2")
- VFX mantidos: —

### Ulkiorra (`char_ulkiorra_base`) — OK
- Origem: `Anime Pack.Bleach Pack.Ulquiorra.Ulq` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 2, remotes 5, sons 34, animações 22, bindables 0, estado 14, GUIs 2, peças invisíveis 2, placas de título 1, VFX 15, outros: Attachment 1, Folder 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 6→6, SpecialMesh 4→3, Part 12→8 · objetos visuais: preservados 21, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · NameTag · Part "Head" ([ X ].Head): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ X ].Head.Mesh): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
- VFX mantidos: —

### Itaxi (`char_itaxi_base`) — OK
- Origem: `Anime Pack.NARUTO.Itachi` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 1, remotes 4, sons 34, animações 10, bindables 0, estado 15, GUIs 2, peças invisíveis 2, placas de título 1, VFX 14, outros: Attachment 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 3→3, MeshPart 1→1, SpecialMesh 4→3, Part 12→8 · objetos visuais: preservados 17, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: —

### Peinn (`char_peinn_base`) — OK
- Origem: `Anime Pack.NARUTO.Pain` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 1, remotes 4, sons 34, animações 10, bindables 0, estado 16, GUIs 2, peças invisíveis 2, placas de título 1, VFX 14, outros: Attachment 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 2→2, SpecialMesh 3→2, Part 11→7 · objetos visuais: preservados 15, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: —

### Goko Sombrio (`char_goko_dark_base`) — OK
- Origem: `Anime Pack.DBZ.Goku Black.Goku Black [NEW]` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 2, remotes 5, sons 34, animações 33, bindables 0, estado 14, GUIs 2, peças invisíveis 2, placas de título 1, VFX 14, outros: Attachment 1, Folder 2
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, SpecialMesh 8→7, Part 16→12, UnionOperation 3→3 · objetos visuais: preservados 26, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ X ].Head): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ X ].Head.Mesh): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
- VFX mantidos: —

### Ichiro Mascarado (`char_ichiro_hollow`) — OK
- Origem: `Anime Pack.Bleach Pack.Hollow Ichigo.Hollow Ichigo` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 2, remotes 5, sons 35, animações 22, bindables 0, estado 14, GUIs 2, peças invisíveis 3, placas de título 1, VFX 15, outros: Attachment 1, Folder 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 3→3, MeshPart 4→3, SpecialMesh 4→3, Part 12→8 · objetos visuais: preservados 19, removidos com justificativa 6, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ X ].Head): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
  - JUSTIFIED · InvisibleHitbox · MeshPart "HalfMask" (Morph.HalfMask): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ X ].Head.Mesh): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
- VFX mantidos: —

### Ilumi (`char_ilumi_base`) — OK
- Origem: `Anime Pack.HXH.Illumi` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 1, remotes 4, sons 34, animações 10, bindables 0, estado 14, GUIs 2, peças invisíveis 2, placas de título 1, VFX 14, outros: Attachment 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 1→1, SpecialMesh 4→3, Part 12→8 · objetos visuais: preservados 16, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: —

### Vejita (`char_vejita_base`) — OK
- Origem: `Anime Pack.DBZ.Vegeta` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 1, remotes 4, sons 34, animações 10, bindables 0, estado 14, GUIs 2, peças invisíveis 2, placas de título 1, VFX 14, outros: Attachment 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, SpecialMesh 3→2, Part 35→31, UnionOperation 8→8 · objetos visuais: preservados 45, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: —

### Ilumi Desperto (`char_ilumi_awakened`) — OK
- Origem: `Anime Pack.HXH.Illumi Awakened` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 2, remotes 5, sons 35, animações 22, bindables 0, estado 15, GUIs 2, peças invisíveis 3, placas de título 1, VFX 31, outros: Attachment 1, Folder 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 4→4, MeshPart 1→0, SpecialMesh 6→5, Part 14→10 · objetos visuais: preservados 21, removidos com justificativa 6, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ X ].Head): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
  - JUSTIFIED · InvisibleHitbox · MeshPart "Hair" (Morph.Hair): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ X ].Head.Mesh): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
- VFX mantidos: —

### Vejita Majin (`char_vejita_majin`) — OK
- Origem: `Anime Pack.DBZ.Majin Vegeta` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 1, remotes 4, sons 34, animações 10, bindables 0, estado 14, GUIs 2, peças invisíveis 2, placas de título 1, VFX 14, outros: Attachment 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 3→3, SpecialMesh 3→2, Part 12→8, UnionOperation 1→1 · objetos visuais: preservados 16, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: ParticleEmitter SaiyanAura (Light)

### Ulkiorra Liberado (`char_ulkiorra_release`) — WARN
- Origem: `Anime Pack.Bleach Pack.Ulquiorra.R1` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 2, remotes 5, sons 34, animações 22, bindables 0, estado 15, GUIs 2, peças invisíveis 2, placas de título 1, VFX 15, outros: Attachment 1, Folder 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 5→5, SpecialMesh 5→4, Part 13→9 · objetos visuais: preservados 22, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ X ].Head): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ X ].Head.Mesh): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
- VFX mantidos: —
- Avisos: caixa total grande: 13.5 x 6.6 x 13.4 (corpo = 5)

### Ichiro Vasto (`char_ichiro_vasto`) — OK
- Origem: `Anime Pack.Bleach Pack.Hollow Ichigo.Vasto` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 2, remotes 5, sons 38, animações 22, bindables 0, estado 15, GUIs 2, peças invisíveis 3, placas de título 1, VFX 14, outros: Attachment 1, Folder 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 1→1, MeshPart 5→5, SpecialMesh 4→2, Part 12→7 · objetos visuais: preservados 17, removidos com justificativa 7, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ X ].Head): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
  - JUSTIFIED · InvisibleHitbox · Part "Face" (Morph.Face): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ X ].Head.Mesh): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
  - JUSTIFIED · InvisibleHitbox · SpecialMesh "Mesh" (Morph.Face.Mesh): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) (removido junto com Part "Face")
- VFX mantidos: —

### Bakugu Desperto (`char_bakugu_awakened`) — OK
- Origem: `Anime Pack.My Hero Academia Pack.Awakened Bakugo` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 2, remotes 5, sons 35, animações 22, bindables 0, estado 15, GUIs 2, peças invisíveis 2, placas de título 1, VFX 14, outros: Attachment 1, Folder 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 1→1, SpecialMesh 3→2, Part 13→9, UnionOperation 10→10 · objetos visuais: preservados 26, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ X ].Head): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ X ].Head.Mesh): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
- VFX mantidos: ParticleEmitter Sparky (Light), ParticleEmitter Sparky (Light)
- Avisos: POSSIBLE_DUPLICATE: mesmo visual que char_bakugu_awakened, char_bakugu_base

### Grei Desperto (`char_grei_awakened`) — OK
- Origem: `Anime Pack.Fairy Tail.Grey Awakening` · escala 0.988 · Humanoid (roupa): sim
- Removidos: scripts 2, remotes 5, sons 36, animações 22, bindables 0, estado 15, GUIs 2, peças invisíveis 2, placas de título 1, VFX 22, outros: Attachment 1, Folder 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 8→8, MeshPart 1→1, SpecialMesh 4→3, Part 12→8 · objetos visuais: preservados 22, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ CHAMPION  ].Head): placa de título do jogo de origem: Model "[ CHAMPION  ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ CHAMPION  ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ CHAMPION  ].Head.Mesh): placa de título do jogo de origem: Model "[ CHAMPION  ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ CHAMPION  ]")
- VFX mantidos: ParticleEmitter SaiyanAura (Light), ParticleEmitter dust (Full), ParticleEmitter dust2 (Full), ParticleEmitter dust (Full), ParticleEmitter dust2 (Full), ParticleEmitter dust (Full)

### Rika Desperta (`char_rika_awakened`) — WARN
- Origem: `Anime Pack.OTHER.Rikka Awakened` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 2, remotes 5, sons 38, animações 33, bindables 0, estado 15, GUIs 2, peças invisíveis 3, placas de título 1, VFX 22, outros: Attachment 2, Folder 2
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 3→3, MeshPart 6→6, SpecialMesh 5→3, Part 14→9 · objetos visuais: preservados 23, removidos com justificativa 7, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · InvisibleCombatHelper · Part "Tweener" (RikkaWep.Tweener): Transparency=1.00; o único conteúdo visível eram VFX removidos pela política de VFX (ParticleEmitter ShootParticle)
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · InvisibleCombatHelper · SpecialMesh "Mesh" (RikkaWep.Tweener.Mesh): Transparency=1.00; o único conteúdo visível eram VFX removidos pela política de VFX (ParticleEmitter ShootParticle) (removido junto com Part "Tweener")
- VFX mantidos: ParticleEmitter FireOutParticle (Full), ParticleEmitter CircleParticle (Full)
- Avisos: caixa total grande: 9.8 x 18.1 x 2.8 (corpo = 5); 4 peça(s) sem junta (presas pelo osso mais próximo): Handle, 2, 1, 3

### Gom Adulto (`char_gom_adult`) — WARN
- Origem: `Anime Pack.HXH.Adult Gon` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 2, remotes 5, sons 37, animações 22, bindables 0, estado 15, GUIs 2, peças invisíveis 2, placas de título 1, VFX 17, outros: Attachment 1, Folder 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 1→1, SpecialMesh 3→2, Part 11→7 · objetos visuais: preservados 14, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ X ].Head): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ X ].Head.Mesh): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
- VFX mantidos: —
- Avisos: caixa total grande: 4.0 x 12.9 x 2.2 (corpo = 5)

### Natzu Desperto (`char_natzu_awakened`) — OK
- Origem: `Anime Pack.Fairy Tail.Natsu Awakened` · escala 0.988 · Humanoid (roupa): sim
- Removidos: scripts 2, remotes 5, sons 38, animações 22, bindables 0, estado 15, GUIs 2, peças invisíveis 2, placas de título 1, VFX 25, outros: Attachment 1, Folder 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 2→2, SpecialMesh 4→3, Part 12→8 · objetos visuais: preservados 17, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ CHAMPION  ].Head): placa de título do jogo de origem: Model "[ CHAMPION  ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ CHAMPION  ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ CHAMPION  ].Head.Mesh): placa de título do jogo de origem: Model "[ CHAMPION  ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ CHAMPION  ]")
- VFX mantidos: ParticleEmitter SaiyanAura (Light), ParticleEmitter CircleParticle (Full), ParticleEmitter CircleParticle (Full), ParticleEmitter Fire (Full), ParticleEmitter Fire (Full), ParticleEmitter Particle (Full)
- Avisos: POSSIBLE_DUPLICATE: mesmo visual que char_natzu_awakened, char_natzu_base

### Roque Li dos Portões (`char_roqueli_gates`) — OK
- Origem: `Anime Pack.NARUTO.Rock Lee.ROCK LEE GATES` · escala 0.985 · Humanoid (roupa): sim
- Removidos: scripts 2, remotes 5, sons 35, animações 22, bindables 0, estado 15, GUIs 2, peças invisíveis 2, placas de título 1, VFX 16, outros: Attachment 1, Folder 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, BodyColors 1→1, Decal 11→11, MeshPart 1→1, SpecialMesh 3→2, Part 13→9, UnionOperation 3→3 · objetos visuais: preservados 29, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: —
- Avisos: POSSIBLE_DUPLICATE: mesmo visual que char_roqueli_base, char_roqueli_gates

### Gohin (`char_gohin_base`) — OK
- Origem: `Anime Pack.DBZ.Gohan` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 1, remotes 4, sons 34, animações 10, bindables 0, estado 14, GUIs 2, peças invisíveis 3, placas de título 1, VFX 14, outros: Attachment 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 2→1, SpecialMesh 3→2, Part 11→7 · objetos visuais: preservados 14, removidos com justificativa 6, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · InvisibleHitbox · MeshPart "SSJ2" (Morph.SSJ2): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: —

### Mighto (`char_mighto_base`) — OK
- Origem: `Anime Pack.NARUTO.Might Guy.Might Guy` · escala 0.985 · Humanoid (roupa): sim
- Removidos: scripts 2, remotes 5, sons 34, animações 22, bindables 0, estado 14, GUIs 2, peças invisíveis 2, placas de título 1, VFX 14, outros: Attachment 1, Folder 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 1→1, SpecialMesh 4→3, Part 12→8 · objetos visuais: preservados 16, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: —

### Brolli (`char_brolli_base`) — OK
- Origem: `Anime Pack.DBZ.Broly.Broly` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 1, remotes 4, sons 34, animações 10, bindables 0, estado 16, GUIs 2, peças invisíveis 2, placas de título 1, VFX 14, outros: Attachment 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 3→3, SpecialMesh 5→4, Part 13→9 · objetos visuais: preservados 18, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: —

### Sasuko (`char_sasuko_base`) — OK
- Origem: `Anime Pack.NARUTO.tsSasuke` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 1, remotes 4, sons 34, animações 10, bindables 0, estado 14, GUIs 2, peças invisíveis 7, placas de título 1, VFX 16, outros: Attachment 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 2→1, SpecialMesh 3→2, Part 11→7, UnionOperation 12→8 · objetos visuais: preservados 22, removidos com justificativa 10, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · InvisibleHitbox · MeshPart "cursemarkhair2" (Morph.cursemarkhair2): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · UnionOperation "Handle3" (Morph.Handle3): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · UnionOperation "Handle3" (Morph.Handle3): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · UnionOperation "Handle2" (Morph.Handle2): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · UnionOperation "Handle1" (Morph.Handle1): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: ParticleEmitter ParticleEmitter (Light), ParticleEmitter ParticleEmitter (Light)

### Lufy Serpente (`char_lufy_snake`) — OK
- Origem: `Anime Pack.One Piece Pack.TS Luffy.Snakeman` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 2, remotes 5, sons 36, animações 22, bindables 0, estado 15, GUIs 2, peças invisíveis 2, placas de título 1, VFX 14, outros: Attachment 1, Folder 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 8→8, MeshPart 1→1, SpecialMesh 3→2, Part 15→11, UnionOperation 6→6 · objetos visuais: preservados 30, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ X ].Head): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ X ].Head.Mesh): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
- VFX mantidos: —

### Mighto 5º Portão (`char_mighto_gate5`) — OK
- Origem: `Anime Pack.NARUTO.Might Guy.5TH GATE` · escala 0.985 · Humanoid (roupa): sim
- Removidos: scripts 2, remotes 5, sons 35, animações 22, bindables 0, estado 19, GUIs 2, peças invisíveis 3, placas de título 1, VFX 43, outros: Attachment 1, Folder 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, BodyColors 1→1, Decal 3→3, MeshPart 3→2, SpecialMesh 5→4, Part 13→9 · objetos visuais: preservados 21, removidos com justificativa 6, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · InvisibleHitbox · MeshPart "Header" (Morph.Header): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: ParticleEmitter Aura (Light), ParticleEmitter ParticleEmitter (Full)

### Sanjo (`char_sanjo_base`) — OK
- Origem: `Anime Pack.One Piece Pack.TS SANJI` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 2, remotes 5, sons 34, animações 22, bindables 0, estado 14, GUIs 2, peças invisíveis 2, placas de título 1, VFX 14, outros: Attachment 1, Folder 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 1→1, SpecialMesh 3→2, Part 11→7 · objetos visuais: preservados 14, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ X ].Head): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ X ].Head.Mesh): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
- VFX mantidos: —

### Yujo (`char_yujo_base`) — OK
- Origem: `Anime Pack.JJK.Yuji` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 2, remotes 5, sons 34, animações 22, bindables 0, estado 17, GUIs 2, peças invisíveis 2, placas de título 1, VFX 14, outros: Attachment 1, Folder 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 3→3, SpecialMesh 4→3, Part 12→8 · objetos visuais: preservados 18, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ CHAMPION ].Head): placa de título do jogo de origem: Model "[ CHAMPION ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ CHAMPION ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ CHAMPION ].Head.Mesh): placa de título do jogo de origem: Model "[ CHAMPION ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ CHAMPION ]")
- VFX mantidos: —

### Narotu Sábio (`char_narotu_sage`) — WARN
- Origem: `Anime Pack.NARUTO.Sage Mode` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 1, remotes 4, sons 34, animações 10, bindables 0, estado 14, GUIs 0, peças invisíveis 2, placas de título 1, VFX 14, outros: Attachment 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 2→2, SpecialMesh 3→2, Part 11→7 · objetos visuais: preservados 15, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: —
- Avisos: 2 peça(s) sem junta (presas pelo osso mais próximo): MeshPart, Meshes/NARUTOHAIR+BAND

### Ol Maito Poder Total (`char_olmaito_mode`) — OK
- Origem: `Anime Pack.My Hero Academia Pack.All Might (MODE)` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 2, remotes 5, sons 34, animações 22, bindables 0, estado 19, GUIs 2, peças invisíveis 3, placas de título 1, VFX 14, outros: Attachment 1, Folder 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 2→1, SpecialMesh 3→2, Part 11→7 · objetos visuais: preservados 14, removidos com justificativa 6, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ X ].Head): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
  - JUSTIFIED · InvisibleHitbox · MeshPart "BaseHair" (Morph.BaseHair): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ X ].Head.Mesh): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
- VFX mantidos: —

### Deko 100% (`char_deko_full`) — OK
- Origem: `Anime Pack.My Hero Academia Pack.100% Deku` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 2, remotes 5, sons 36, animações 22, bindables 0, estado 15, GUIs 2, peças invisíveis 2, placas de título 1, VFX 22, outros: Attachment 1, Folder 1, Humanoid 1
- Visual (origem → asset): Shirt 2→2, Pants 2→2, BodyColors 1→1, Decal 3→3, MeshPart 3→3, SpecialMesh 5→4, Part 18→14 · objetos visuais: preservados 29, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ X ].Head): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ X ].Head.Mesh): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
- VFX mantidos: ParticleEmitter SaiyanAura (Light)

### Goju (`char_goju_base`) — OK
- Origem: `Anime Pack.JJK.Gojo Satoru` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 1, remotes 4, sons 34, animações 10, bindables 0, estado 14, GUIs 2, peças invisíveis 3, placas de título 1, VFX 14, outros: Attachment 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 5→4, SpecialMesh 4→3, Part 12→8 · objetos visuais: preservados 19, removidos com justificativa 6, SEM justificativa 0
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · NameTag · Part "Head" ([ CHAMPION ].Head): placa de título do jogo de origem: Model "[ CHAMPION ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ CHAMPION ]")
  - JUSTIFIED · InvisibleHitbox · MeshPart "AwakeningHair" (Morph.AwakeningHair): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ CHAMPION ].Head.Mesh): placa de título do jogo de origem: Model "[ CHAMPION ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ CHAMPION ]")
- VFX mantidos: —

### Vegitto (`char_vegitto_base`) — OK
- Origem: `Anime Pack.DBZ.Vegito.VEGITO` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 2, remotes 5, sons 34, animações 22, bindables 0, estado 14, GUIs 2, peças invisíveis 2, placas de título 1, VFX 14, outros: Attachment 1, Folder 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 3→3, MeshPart 4→4, SpecialMesh 3→2, Part 11→7 · objetos visuais: preservados 18, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ X ].Head): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ X ].Head.Mesh): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
- VFX mantidos: —
- Avisos: POSSIBLE_DUPLICATE: mesmo visual que char_vegitto_base, char_vegitto_blue

### Barbalva (`char_barbalva_base`) — OK
- Origem: `Anime Pack.One Piece Pack.Whitebeard` · escala 0.390 · Humanoid (roupa): sim
- Removidos: scripts 1, remotes 4, sons 34, animações 11, bindables 0, estado 15, GUIs 2, peças invisíveis 3, placas de título 0, VFX 15, outros: Attachment 1, Humanoid 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 5→5, SpecialMesh 4→3, Part 12→8 · objetos visuais: preservados 20, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleCombatHelper · Part "Quakebubble" (Morph.Quakebubble): Transparency=1.00; o único conteúdo visível eram VFX removidos pela política de VFX (ParticleEmitter FX)
  - JUSTIFIED · InvisibleCombatHelper · SpecialMesh "Mesh" (Morph.Quakebubble.Mesh): Transparency=1.00; o único conteúdo visível eram VFX removidos pela política de VFX (ParticleEmitter FX) (removido junto com Part "Quakebubble")
- VFX mantidos: —

### Aizo (`char_aizo_base`) — OK
- Origem: `Anime Pack.Bleach Pack.Aizen.Aizen` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 1, remotes 4, sons 34, animações 10, bindables 0, estado 14, GUIs 2, peças invisíveis 2, placas de título 1, VFX 15, outros: Attachment 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 2→2, SpecialMesh 4→3, Part 12→8 · objetos visuais: preservados 17, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: —

### Brolli Lendário (`char_brolli_legend`) — OK
- Origem: `Anime Pack.DBZ.Broly.LSSJ BROLY` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 2, remotes 5, sons 35, animações 22, bindables 0, estado 17, GUIs 2, peças invisíveis 4, placas de título 1, VFX 14, outros: Attachment 1, Folder 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 3→3, SpecialMesh 6→3, Part 14→8 · objetos visuais: preservados 16, removidos com justificativa 9, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ X ].Head): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
  - JUSTIFIED · InvisibleHitbox · Part "Start2" (Morph.Start2): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "Start" (Morph.Start): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ X ].Head.Mesh): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
  - JUSTIFIED · InvisibleHitbox · SpecialMesh "Mesh" (Morph.Start2.Mesh): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) (removido junto com Part "Start2")
  - JUSTIFIED · InvisibleHitbox · SpecialMesh "Mesh" (Morph.Start.Mesh): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) (removido junto com Part "Start")
- VFX mantidos: ParticleEmitter SaiyanAura (Light), ParticleEmitter SaiyanAura2 (Full)

### Madaro (`char_madaro_base`) — OK
- Origem: `Anime Pack.NARUTO.Madara` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 1, remotes 4, sons 44, animações 10, bindables 0, estado 14, GUIs 2, peças invisíveis 3, placas de título 1, VFX 14, outros: Attachment 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 3→2, SpecialMesh 4→3, Part 12→8 · objetos visuais: preservados 17, removidos com justificativa 6, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · InvisibleHitbox · MeshPart "RealFan" (Morph.RealFan): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: —

### Ichiro Mugetsu (`char_ichiro_mugetsu`) — OK
- Origem: `Anime Pack.Bleach Pack.Hollow Ichigo.Mugetsu` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 2, remotes 5, sons 36, animações 22, bindables 0, estado 15, GUIs 2, peças invisíveis 5, placas de título 1, VFX 15, outros: Attachment 1, Folder 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 7→7, MeshPart 5→3, SpecialMesh 4→2, Part 12→7 · objetos visuais: preservados 21, removidos com justificativa 9, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "FakeHead" (FakeHead): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · SpecialMesh "Mesh" (FakeHead.Mesh): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador) (removido junto com Part "FakeHead")
  - JUSTIFIED · NameTag · Part "Head" ([ X ].Head): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
  - JUSTIFIED · InvisibleHitbox · MeshPart "FullMask" (Morph.FullMask): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · MeshPart "HalfMask" (Morph.HalfMask): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ X ].Head.Mesh): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
- VFX mantidos: ParticleEmitter BlackFlame (Light)

### Mighto 8º Portão (`char_mighto_gate8`) — OK
- Origem: `Anime Pack.NARUTO.Might Guy.8TH GATE` · escala 0.985 · Humanoid (roupa): sim
- Removidos: scripts 2, remotes 5, sons 38, animações 22, bindables 0, estado 21, GUIs 2, peças invisíveis 3, placas de título 0, VFX 44, outros: Attachment 1, Folder 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, BodyColors 1→1, Decal 9→9, MeshPart 2→1, SpecialMesh 4→4, Part 12→9 · objetos visuais: preservados 26, removidos com justificativa 4, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · MeshPart "Header" (Morph.Header): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
- VFX mantidos: ParticleEmitter Aura (Light), ParticleEmitter ParticleEmitter (Full)

### Vegitto Azul (`char_vegitto_blue`) — OK
- Origem: `Anime Pack.DBZ.Vegito.VEGITO BLUE` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 2, remotes 5, sons 36, animações 22, bindables 0, estado 15, GUIs 2, peças invisíveis 2, placas de título 1, VFX 14, outros: Attachment 1, Folder 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 3→3, MeshPart 4→4, SpecialMesh 3→2, Part 11→7 · objetos visuais: preservados 18, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ X ].Head): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ X ].Head.Mesh): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
- VFX mantidos: ParticleEmitter SaiyanAura (Light)
- Avisos: POSSIBLE_DUPLICATE: mesmo visual que char_vegitto_base, char_vegitto_blue

### Infernus (`char_infernus_base`) — OK
- Origem: `Anime Pack.My Hero Academia Pack.Hellflame` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 1, remotes 4, sons 34, animações 10, bindables 0, estado 15, GUIs 2, peças invisíveis 2, placas de título 1, VFX 22, outros: Attachment 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 3→3, MeshPart 10→10, SpecialMesh 4→3, Part 15→11 · objetos visuais: preservados 29, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: ParticleEmitter Particle1 (Light), ParticleEmitter Particle1 (Light), ParticleEmitter Particle1 (Full), ParticleEmitter Particle1 (Full), ParticleEmitter Particle1 (Full), ParticleEmitter Particle1 (Full)

### Iskander (`char_iskander_base`) — OK
- Origem: `Anime Pack.FATE.Iskandar` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 2, remotes 5, sons 34, animações 22, bindables 0, estado 14, GUIs 2, peças invisíveis 2, placas de título 1, VFX 14, outros: Attachment 1, Folder 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 8→8, SpecialMesh 4→3, Part 12→8 · objetos visuais: preservados 23, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: —

### Kizaro (`char_kizaro_base`) — OK
- Origem: `Anime Pack.One Piece Pack.Kizaru` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 2, remotes 5, sons 34, animações 22, bindables 0, estado 14, GUIs 2, peças invisíveis 2, placas de título 1, VFX 14, outros: Attachment 1, Folder 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 10→10, MeshPart 10→10, SpecialMesh 3→2, Part 11→7 · objetos visuais: preservados 31, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ X ].Head): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ X ].Head.Mesh): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
- VFX mantidos: —

### Lanseiro Ardente (`char_lanseiro_mode`) — OK
- Origem: `Anime Pack.FATE.Lancer Mode` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 2, remotes 5, sons 34, animações 22, bindables 1, estado 16, GUIs 2, peças invisíveis 0, placas de título 1, VFX 24, outros: Attachment 1, Folder 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 6→6, SpecialMesh 4→3, Part 12→10 · objetos visuais: preservados 23, removidos com justificativa 3, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: ParticleEmitter Reiatsu (Light), ParticleEmitter Reiatsu (Light), ParticleEmitter Reiatsu (Full), ParticleEmitter Reiatsu (Full), ParticleEmitter Reiatsu (Full), ParticleEmitter Reiatsu (Full)
- Avisos: POSSIBLE_DUPLICATE: mesmo visual que char_lanseiro_base, char_lanseiro_mode

### Samurai Afro (`char_samurai_afro_base`) — OK
- Origem: `Anime Pack.OTHER.MISC.Afro Samurai` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 1, remotes 4, sons 34, animações 10, bindables 0, estado 15, GUIs 2, peças invisíveis 2, placas de título 1, VFX 16, outros: Attachment 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 5→5, MeshPart 11→11, SpecialMesh 6→5, Part 14→10 · objetos visuais: preservados 33, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: ParticleEmitter ParticleEmitter (Light), ParticleEmitter ParticleEmitter (Light)

### Goko Sombrio Rosé (`char_goko_dark_rose`) — OK
- Origem: `Anime Pack.DBZ.Goku Black.SSJR` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 2, remotes 5, sons 38, animações 33, bindables 0, estado 15, GUIs 2, peças invisíveis 3, placas de título 1, VFX 14, outros: Attachment 1, Folder 2
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, SpecialMesh 9→8, Part 17→13, UnionOperation 4→3 · objetos visuais: preservados 28, removidos com justificativa 6, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ X ].Head): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
  - JUSTIFIED · InvisibleHitbox · UnionOperation "GokuHair" (Morph.GokuHair): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ X ].Head.Mesh): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
- VFX mantidos: ParticleEmitter FinAura2 (Light), ParticleEmitter Particle (Full)

### Yoruka Shunko (`char_yoruka_shunko`) — OK
- Origem: `Anime Pack.Bleach Pack.Yoruichi.Shunko Yoruichi` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 2, remotes 5, sons 36, animações 22, bindables 0, estado 15, GUIs 2, peças invisíveis 2, placas de título 1, VFX 18, outros: Attachment 1, Folder 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 1→1, SpecialMesh 4→3, Part 12→8 · objetos visuais: preservados 16, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ X ].Head): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ X ].Head.Mesh): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
- VFX mantidos: —

### Seiba Sombria (`char_seiba_alter`) — OK
- Origem: `Anime Pack.FATE.SALTER` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 2, remotes 5, sons 34, animações 22, bindables 0, estado 14, GUIs 2, peças invisíveis 4, placas de título 1, VFX 15, outros: Attachment 1, Folder 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 10→8, SpecialMesh 4→3, Part 12→8 · objetos visuais: preservados 23, removidos com justificativa 7, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ SEMI-PRO ].Head): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
  - JUSTIFIED · InvisibleHitbox · MeshPart "Crown" (Morph.Crown): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleCombatHelper · MeshPart "SpecialBlade" (Morph.SpecialBlade): Transparency=1.00; o único conteúdo visível eram VFX removidos pela política de VFX (ParticleEmitter Charge)
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ SEMI-PRO ].Head.Mesh): placa de título do jogo de origem: Model "[ SEMI-PRO ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ SEMI-PRO ]")
- VFX mantidos: —

### Toshiru Bankai (`char_toshiru_bankai`) — WARN
- Origem: `Anime Pack.Bleach Pack.Toshiro.Bankai Toshiro` · escala 1.000 · Humanoid (roupa): sim
- Removidos: scripts 2, remotes 5, sons 34, animações 22, bindables 0, estado 15, GUIs 2, peças invisíveis 2, placas de título 1, VFX 17, outros: Attachment 1, Folder 1
- Visual (origem → asset): Shirt 1→1, Pants 1→1, Decal 2→2, MeshPart 12→12, SpecialMesh 4→3, Part 12→8 · objetos visuais: preservados 27, removidos com justificativa 5, SEM justificativa 0
  - JUSTIFIED · RootPart · Part "HumanoidRootPart" (HumanoidRootPart): HumanoidRootPart: peça raiz do rig
  - JUSTIFIED · InvisibleHitbox · Part "RightHilt" (RightHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · InvisibleHitbox · Part "LeftHilt" (LeftHilt): Transparency=1.00, sem Decal/Texture/VFX dentro (hitbox/colisor/marcador)
  - JUSTIFIED · NameTag · Part "Head" ([ X ].Head): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
  - JUSTIFIED · NameTag · SpecialMesh "Mesh" ([ X ].Head.Mesh): placa de título do jogo de origem: Model "[ X ]" com Humanoid próprio e peças < 0.5 (removido junto com Model "[ X ]")
- VFX mantidos: —
- Avisos: caixa total grande: 18.6 x 7.5 x 11.3 (corpo = 5)
