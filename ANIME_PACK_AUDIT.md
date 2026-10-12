# ANIME_PACK_AUDIT — Anime Pack (asset 14679137059)

> Gerado por `tools/packaudit/audit_pack.luau` a partir de `third_party/AnimePack.rbxm`.
> O arquivo foi só **lido** (desserializado): nenhum script do pack foi executado.
> Notas de qualidade e raridades sugeridas são heurísticas — confirmar visualmente no Studio.

## Resumo

- Instâncias no pack: **33348**
- Personagens/modelos encontrados: **152**
- Rigs: R6: 150 · custom (RigType Enum.HumanoidRigType.R6): 2
- Scripts (Script/LocalScript/ModuleScript): **201**
- Classes: Accessory 2, Animation 1970, Animator 266, Attachment 4142, Beam 108, BillboardGui 131, BindableEvent 6, BlockMesh 46, BodyColors 9, BodyGyro 5, BodyPosition 5, BoolValue 397, Decal 417, EchoSoundEffect 1, Folder 616, Humanoid 282, ImageLabel 132, IntConstrainedValue 2, IntValue 134, LocalScript 142, ManualWeld 312, MeshPart 864, Model 689, ModuleScript 59, Motor6D 1187, NumberValue 320, ObjectValue 39, Pants 150, Part 2095, ParticleEmitter 1603, PointLight 5, RemoteEvent 94, RemoteFunction 589, Shirt 149, Snap 279, Sound 4669, SpecialMesh 770, StringValue 1068, SurfaceAppearance 1, SurfaceGui 1, Texture 191, Trail 574, TremoloSoundEffect 1, UnionOperation 256, Vector3Value 18, WedgePart 100, Weld 8452

## Categorias

| Categoria | Personagens |
|---|---:|
| AOT | 12 |
| Bleach Pack | 23 |
| DBZ | 15 |
| FATE | 10 |
| Fairy Tail | 4 |
| HXH | 8 |
| JJK | 4 |
| JOJO | 21 |
| My Hero Academia Pack | 11 |
| NARUTO | 19 |
| OTHER | 8 |
| One Piece Pack | 13 |
| YYH | 4 |

## Formas / transformações (mesmo personagem em versões diferentes — pistas, confirmar no Studio)

| Categoria | Personagem base | Versões | Pista |
|---|---|---|---|
| AOT | erwin | Erwin (Alt), Erwin | nome |
| Bleach Pack | aizen | Aizen, Final Aizen | nome |
| Bleach Pack | ichigo | Ichigo, Hollow Ichigo | nome |
| Bleach Pack | neko yoru | Neko Yoru, Shunko Yoruichi | mesma roupa/rosto |
| Bleach Pack | r | R1, R2 | nome |
| Bleach Pack | rukia | Ichigo, Rukia | mesma roupa/rosto |
| Bleach Pack | toshiro | Toshiro, Bankai Toshiro | nome |
| DBZ | broly | LSSJ BROLY, Broly | nome |
| DBZ | goku | Goku, Krillin | mesma roupa/rosto |
| DBZ | goku new | Goku Black [NEW], SSJR | mesma roupa/rosto |
| DBZ | vegito | VEGITO, VEGITO BLUE | nome |
| FATE | lancer | Lancer Mode, Lancer  | nome |
| Fairy Tail | natsu | Natsu, Natsu Awakened | nome |
| HXH | gon | Adult Gon, Gon | nome |
| HXH | hisoka | Hisoka, Hisoka | nome |
| HXH | illumi | Illumi Awakened, Illumi | nome |
| HXH | killua godspeed | Killua, Killua Godspeed | mesma roupa/rosto |
| JJK | gojo satoru blindfold off | Gojo Satoru, Gojo Satoru (Blindfold Off) | mesma roupa/rosto |
| JOJO | dio | DIO, DIO AWAKENED | nome |
| JOJO | giorno | Giorno, Giorno | nome |
| JOJO | jolyne | Jolyne, Awakened Jolyne | nome |
| JOJO | joseph | Old Joseph, Young Joseph | nome |
| JOJO | morph | Morph, Morph | nome |
| JOJO | stone free aura | STONE FREE, STONE FREE AURA | mesma roupa/rosto |
| My Hero Academia Pack | all might | All Might, All Might (MODE) | nome |
| My Hero Academia Pack | bakugo | Awakened Bakugo, Bakugo | nome |
| My Hero Academia Pack | deku | Deku Awakened, Deku | nome |
| NARUTO | rock lee gates | ROCK LEE GATES, Rock Lee | mesma roupa/rosto |
| NARUTO | th gate | 5TH GATE, Might Guy | mesma roupa/rosto |
| NARUTO | th gate | 5TH GATE, 8TH GATE | nome |
| OTHER | rikka | Rikka Awakened, Rikka | nome |
| YYH | hiei | Hiei, Hiei (Jagan Eye) | mesma roupa/rosto |
| YYH | yusuke | Yusuke, Yusuke Mode | nome |

## 1. Segurança — todos os scripts

| Caminho | Classe | Linhas | Risco | Função aparente | Só visual? | Remover? | Padrões encontrados |
|---|---|---:|---|---|---|---|---|
| `Anime Pack.Bleach Pack.Aizen.Aizen.Animate` | LocalScript | 2 | **NENHUM** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | — |
| `Anime Pack.Bleach Pack.Aizen.Final Aizen.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.Bleach Pack.Aizen.Final Aizen.BattleScript` | ModuleScript | 213 | **MÉDIO** | toca animação | sim | SIM | MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.Bleach Pack.Byakuya.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.Bleach Pack.Gin.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.Bleach Pack.Grimmjow.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.Bleach Pack.Hollow Ichigo.Hollow Ichigo.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.Bleach Pack.Hollow Ichigo.Hollow Ichigo.BattleScript` | ModuleScript | 233 | **MÉDIO** | toca animação | sim | SIM | MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.Bleach Pack.Hollow Ichigo.Mugetsu.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.Bleach Pack.Hollow Ichigo.Mugetsu.BattleScript` | ModuleScript | 233 | **MÉDIO** | toca animação | sim | SIM | MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.Bleach Pack.Hollow Ichigo.Vasto.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.Bleach Pack.Hollow Ichigo.Vasto.BattleScript` | ModuleScript | 233 | **MÉDIO** | toca animação | sim | SIM | MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.Bleach Pack.Ichigo.Animate` | LocalScript | 2 | **NENHUM** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | — |
| `Anime Pack.Bleach Pack.Kisuke.Animate` | LocalScript | 2 | **NENHUM** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | — |
| `Anime Pack.Bleach Pack.Rukia.Animate` | LocalScript | 2 | **NENHUM** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | — |
| `Anime Pack.Bleach Pack.Shinji.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.Bleach Pack.Shunsui.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.Bleach Pack.Starrk.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.Bleach Pack.Toshiro.Bankai Toshiro.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.Bleach Pack.Toshiro.Bankai Toshiro.BattleScript` | ModuleScript | 233 | **MÉDIO** | toca animação | sim | SIM | MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.Bleach Pack.Toshiro.Toshiro.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.Bleach Pack.Toshiro.Toshiro.BattleScript` | ModuleScript | 233 | **MÉDIO** | toca animação | sim | SIM | MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.Bleach Pack.Ulquiorra.R1.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.Bleach Pack.Ulquiorra.R1.BattleScript` | ModuleScript | 233 | **MÉDIO** | toca animação | sim | SIM | MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.Bleach Pack.Ulquiorra.R2.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.Bleach Pack.Ulquiorra.R2.BattleScript` | ModuleScript | 233 | **MÉDIO** | toca animação | sim | SIM | MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.Bleach Pack.Ulquiorra.Ulq.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.Bleach Pack.Ulquiorra.Ulq.BattleScript` | ModuleScript | 233 | **MÉDIO** | toca animação | sim | SIM | MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.Bleach Pack.Yamamoto.Animate` | LocalScript | 2 | **NENHUM** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | — |
| `Anime Pack.Bleach Pack.Yoruichi.Neko Yoru.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.Bleach Pack.Yoruichi.Neko Yoru.BattleScript` | ModuleScript | 235 | **MÉDIO** | toca animação | sim | SIM | MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.Bleach Pack.Yoruichi.Shunko Yoruichi.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.Bleach Pack.Yoruichi.Shunko Yoruichi.BattleScript` | ModuleScript | 235 | **MÉDIO** | toca animação | sim | SIM | MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.Bleach Pack.Yoruichi.Yoruichi.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.Bleach Pack.Yoruichi.Yoruichi.BattleScript` | ModuleScript | 235 | **MÉDIO** | toca animação | sim | SIM | MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.DBZ.Broly.Broly.Animate` | LocalScript | 2 | **NENHUM** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | — |
| `Anime Pack.DBZ.Broly.LSSJ BROLY.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.DBZ.Broly.LSSJ BROLY.BattleScript` | ModuleScript | 205 | **MÉDIO** | toca animação | sim | SIM | MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.DBZ.Buu Saga Goku.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.DBZ.Caulifa.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.DBZ.Gohan.Animate` | LocalScript | 2 | **NENHUM** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | — |
| `Anime Pack.DBZ.Goku Black.Goku Black [NEW].Animate` | LocalScript | 1 | **NENHUM** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | — |
| `Anime Pack.DBZ.Goku Black.Goku Black [NEW].BattleScript` | ModuleScript | 1 | **NENHUM** | não identificada (ler manualmente) | não | SIM | — |
| `Anime Pack.DBZ.Goku Black.SSJR.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.DBZ.Goku Black.SSJR.BattleScript` | ModuleScript | 273 | **MÉDIO** | toca animação | sim | SIM | MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações<br>BAIXO: TweenService: efeito visual/movimento |
| `Anime Pack.DBZ.Goku.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.DBZ.Krillin.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.DBZ.Krillin.BattleScript` | ModuleScript | 205 | **MÉDIO** | toca animação | sim | SIM | MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.DBZ.Majin Vegeta.Animate` | LocalScript | 2 | **NENHUM** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | — |
| `Anime Pack.DBZ.Piccolo.Animate` | LocalScript | 2 | **NENHUM** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | — |
| `Anime Pack.DBZ.Trunks.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.DBZ.Vegeta.Animate` | LocalScript | 2 | **NENHUM** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | — |
| `Anime Pack.DBZ.Vegito.VEGITO BLUE.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.DBZ.Vegito.VEGITO BLUE.BattleScript` | ModuleScript | 205 | **MÉDIO** | toca animação | sim | SIM | MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.DBZ.Vegito.VEGITO.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.DBZ.Vegito.VEGITO.BattleScript` | ModuleScript | 205 | **MÉDIO** | toca animação | sim | SIM | MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.FATE.Archer (EMIYA).Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.FATE.Archer (EMIYA).BattleScript` | ModuleScript | 311 | **MÉDIO** | toca animação | sim | SIM | MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações<br>BAIXO: TweenService: efeito visual/movimento |
| `Anime Pack.FATE.Fate Pack.Gilgamesh.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.FATE.Fate Pack.Saber.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.FATE.Fate Pack.Shirou.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.FATE.Iskandar.Animate` | LocalScript | 1 | **NENHUM** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | — |
| `Anime Pack.FATE.Iskandar.BattleScript` | ModuleScript | 1 | **NENHUM** | não identificada (ler manualmente) | não | SIM | — |
| `Anime Pack.FATE.Kiritsugu.Animate` | LocalScript | 1 | **NENHUM** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | — |
| `Anime Pack.FATE.Kiritsugu.BattleScript` | ModuleScript | 1 | **NENHUM** | não identificada (ler manualmente) | não | SIM | — |
| `Anime Pack.FATE.Lancer .Animate` | LocalScript | 1 | **NENHUM** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | — |
| `Anime Pack.FATE.Lancer .BattleScript` | ModuleScript | 1 | **NENHUM** | não identificada (ler manualmente) | não | SIM | — |
| `Anime Pack.FATE.Lancer Mode.Animate` | LocalScript | 1 | **NENHUM** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | — |
| `Anime Pack.FATE.Lancer Mode.BattleScript` | ModuleScript | 1 | **NENHUM** | não identificada (ler manualmente) | não | SIM | — |
| `Anime Pack.FATE.Rin.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.FATE.Rin.BattleScript` | ModuleScript | 205 | **MÉDIO** | toca animação | sim | SIM | MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.FATE.SALTER.Animate` | LocalScript | 1 | **NENHUM** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | — |
| `Anime Pack.FATE.SALTER.BattleScript` | ModuleScript | 1 | **NENHUM** | não identificada (ler manualmente) | não | SIM | — |
| `Anime Pack.Fairy Tail.Gray.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.Fairy Tail.Gray.BattleScript` | ModuleScript | 205 | **MÉDIO** | toca animação | sim | SIM | MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.Fairy Tail.Grey Awakening.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.Fairy Tail.Grey Awakening.BattleScript` | ModuleScript | 205 | **MÉDIO** | toca animação | sim | SIM | MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.Fairy Tail.Natsu Awakened.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.Fairy Tail.Natsu Awakened.BattleScript` | ModuleScript | 205 | **MÉDIO** | toca animação | sim | SIM | MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.Fairy Tail.Natsu.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.Fairy Tail.Natsu.BattleScript` | ModuleScript | 205 | **MÉDIO** | toca animação | sim | SIM | MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.HXH.Adult Gon.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.HXH.Adult Gon.BattleScript` | ModuleScript | 205 | **MÉDIO** | toca animação | sim | SIM | MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.HXH.Gon.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.HXH.Hisoka.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.HXH.Hisoka.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.HXH.Hisoka.BattleScript` | ModuleScript | 205 | **MÉDIO** | toca animação | sim | SIM | MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.HXH.Illumi Awakened.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.HXH.Illumi Awakened.BattleScript` | ModuleScript | 205 | **MÉDIO** | toca animação | sim | SIM | MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.HXH.Illumi.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.HXH.Killua Godspeed.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.HXH.Killua Godspeed.BattleScript` | ModuleScript | 205 | **MÉDIO** | toca animação | sim | SIM | MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.HXH.Killua.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.JJK.Gojo Satoru (Blindfold Off).Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.JJK.Gojo Satoru.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.JJK.Sukuna.Animate` | LocalScript | 1 | **NENHUM** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | — |
| `Anime Pack.JJK.Sukuna.BattleScript` | ModuleScript | 1 | **NENHUM** | não identificada (ler manualmente) | não | SIM | — |
| `Anime Pack.JJK.Yuji.Animate` | LocalScript | 1 | **NENHUM** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | — |
| `Anime Pack.JJK.Yuji.BattleScript` | ModuleScript | 1 | **NENHUM** | não identificada (ler manualmente) | não | SIM | — |
| `Anime Pack.JOJO.DIO.DIO AWAKENED.Animate` | LocalScript | 1 | **NENHUM** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | — |
| `Anime Pack.JOJO.DIO.DIO AWAKENED.BattleScript` | ModuleScript | 1 | **NENHUM** | não identificada (ler manualmente) | não | SIM | — |
| `Anime Pack.JOJO.DIO.DIO AWAKENED.LocalStand` | LocalScript | 1 | **NENHUM** | não identificada (ler manualmente) | não | SIM | — |
| `Anime Pack.JOJO.DIO.DIO.Animate` | LocalScript | 1 | **NENHUM** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | — |
| `Anime Pack.JOJO.DIO.DIO.LocalStand` | LocalScript | 1 | **NENHUM** | não identificada (ler manualmente) | não | SIM | — |
| `Anime Pack.JOJO.Doppio/Diavolo.Doppio.Animate` | LocalScript | 1 | **NENHUM** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | — |
| `Anime Pack.JOJO.Doppio/Diavolo.Doppio.LocalStand` | LocalScript | 1 | **NENHUM** | não identificada (ler manualmente) | não | SIM | — |
| `Anime Pack.JOJO.Giorno (BUT BOSS).Giorno.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.JOJO.Giorno (BUT BOSS).Giorno.LocalStand` | LocalScript | 35 | **MÉDIO** | não identificada (ler manualmente) | não | SIM | MÉDIO: acessa Players<br>MÉDIO: loop infinito (custo de desempenho) |
| `Anime Pack.JOJO.Giorno.Giorno.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.JOJO.Giorno.Giorno.LocalStand` | LocalScript | 35 | **MÉDIO** | não identificada (ler manualmente) | não | SIM | MÉDIO: acessa Players<br>MÉDIO: loop infinito (custo de desempenho) |
| `Anime Pack.JOJO.Jolyne.Awakened Jolyne.Animate` | LocalScript | 1 | **NENHUM** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | — |
| `Anime Pack.JOJO.Jolyne.Awakened Jolyne.BattleScript` | ModuleScript | 1 | **NENHUM** | não identificada (ler manualmente) | não | SIM | — |
| `Anime Pack.JOJO.Jolyne.Awakened Jolyne.LocalStand` | LocalScript | 1 | **NENHUM** | não identificada (ler manualmente) | não | SIM | — |
| `Anime Pack.JOJO.Jolyne.Jolyne.Jolyne.Animate` | LocalScript | 1 | **NENHUM** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | — |
| `Anime Pack.JOJO.Jolyne.Jolyne.Jolyne.BattleScript` | ModuleScript | 1 | **NENHUM** | não identificada (ler manualmente) | não | SIM | — |
| `Anime Pack.JOJO.Jolyne.Jolyne.Jolyne.LocalStand` | LocalScript | 1 | **NENHUM** | não identificada (ler manualmente) | não | SIM | — |
| `Anime Pack.JOJO.Jonathan.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.JOJO.Josuke.Josuke.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.JOJO.Josuke.Josuke.LocalStand` | LocalScript | 35 | **MÉDIO** | não identificada (ler manualmente) | não | SIM | MÉDIO: acessa Players<br>MÉDIO: loop infinito (custo de desempenho) |
| `Anime Pack.JOJO.Jotaro.Model.Jotaro.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.JOJO.Jotaro.Model.Jotaro.LocalStand` | LocalScript | 35 | **MÉDIO** | não identificada (ler manualmente) | não | SIM | MÉDIO: acessa Players<br>MÉDIO: loop infinito (custo de desempenho) |
| `Anime Pack.JOJO.Kira Yoshikage.Kira Yoshikage.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.JOJO.Kira Yoshikage.Kira Yoshikage.BattleScript` | ModuleScript | 255 | **MÉDIO** | toca animação | sim | SIM | MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações<br>BAIXO: TweenService: efeito visual/movimento |
| `Anime Pack.JOJO.Kira Yoshikage.Kira Yoshikage.LocalStand` | LocalScript | 35 | **MÉDIO** | não identificada (ler manualmente) | não | SIM | MÉDIO: acessa Players<br>MÉDIO: loop infinito (custo de desempenho) |
| `Anime Pack.JOJO.Old Joseph.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.JOJO.Young Joseph.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.My Hero Academia Pack.100% Deku.Animate` | LocalScript | 1 | **NENHUM** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | — |
| `Anime Pack.My Hero Academia Pack.100% Deku.BattleScript` | ModuleScript | 1 | **NENHUM** | não identificada (ler manualmente) | não | SIM | — |
| `Anime Pack.My Hero Academia Pack.All Might (MODE).Animate` | LocalScript | 1 | **NENHUM** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | — |
| `Anime Pack.My Hero Academia Pack.All Might (MODE).BattleScript` | ModuleScript | 1 | **NENHUM** | não identificada (ler manualmente) | não | SIM | — |
| `Anime Pack.My Hero Academia Pack.All Might.Animate` | LocalScript | 1 | **NENHUM** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | — |
| `Anime Pack.My Hero Academia Pack.All Might.BattleScript` | ModuleScript | 1 | **NENHUM** | não identificada (ler manualmente) | não | SIM | — |
| `Anime Pack.My Hero Academia Pack.Awakened Bakugo.Animate` | LocalScript | 1 | **NENHUM** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | — |
| `Anime Pack.My Hero Academia Pack.Awakened Bakugo.BattleScript` | ModuleScript | 1 | **NENHUM** | não identificada (ler manualmente) | não | SIM | — |
| `Anime Pack.My Hero Academia Pack.Bakugo.Animate` | LocalScript | 1 | **NENHUM** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | — |
| `Anime Pack.My Hero Academia Pack.Bakugo.BattleScript` | ModuleScript | 1 | **NENHUM** | não identificada (ler manualmente) | não | SIM | — |
| `Anime Pack.My Hero Academia Pack.Deku Awakened.Animate` | LocalScript | 1 | **NENHUM** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | — |
| `Anime Pack.My Hero Academia Pack.Deku Awakened.BattleScript` | ModuleScript | 1 | **NENHUM** | não identificada (ler manualmente) | não | SIM | — |
| `Anime Pack.My Hero Academia Pack.Deku.Animate` | LocalScript | 1 | **NENHUM** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | — |
| `Anime Pack.My Hero Academia Pack.Deku.BattleScript` | ModuleScript | 1 | **NENHUM** | não identificada (ler manualmente) | não | SIM | — |
| `Anime Pack.My Hero Academia Pack.Hellflame.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.My Hero Academia Pack.Lemillion.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.My Hero Academia Pack.Speed Guy.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.My Hero Academia Pack.Todoroki.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.NARUTO.Gaara.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.NARUTO.Itachi.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.NARUTO.Kakashi.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.NARUTO.Madara.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.NARUTO.Might Guy.5TH GATE.Animate` | LocalScript | 1 | **NENHUM** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | — |
| `Anime Pack.NARUTO.Might Guy.5TH GATE.BattleScript` | ModuleScript | 1 | **NENHUM** | não identificada (ler manualmente) | não | SIM | — |
| `Anime Pack.NARUTO.Might Guy.8TH GATE.Animate` | LocalScript | 1 | **NENHUM** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | — |
| `Anime Pack.NARUTO.Might Guy.8TH GATE.BattleScript` | ModuleScript | 1 | **NENHUM** | não identificada (ler manualmente) | não | SIM | — |
| `Anime Pack.NARUTO.Might Guy.Might Guy.Animate` | LocalScript | 1 | **NENHUM** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | — |
| `Anime Pack.NARUTO.Might Guy.Might Guy.BattleScript` | ModuleScript | 1 | **NENHUM** | não identificada (ler manualmente) | não | SIM | — |
| `Anime Pack.NARUTO.Minato.KCM MINATO.Animate` | LocalScript | 1 | **NENHUM** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | — |
| `Anime Pack.NARUTO.Minato.KCM MINATO.BattleScript` | ModuleScript | 1 | **NENHUM** | não identificada (ler manualmente) | não | SIM | — |
| `Anime Pack.NARUTO.Minato.Minato.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.NARUTO.Neji.Animate` | LocalScript | 2 | **NENHUM** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | — |
| `Anime Pack.NARUTO.Pain.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.NARUTO.Rock Lee.ROCK LEE GATES.Animate` | LocalScript | 1 | **NENHUM** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | — |
| `Anime Pack.NARUTO.Rock Lee.ROCK LEE GATES.BattleScript` | ModuleScript | 1 | **NENHUM** | não identificada (ler manualmente) | não | SIM | — |
| `Anime Pack.NARUTO.Rock Lee.Rock Lee.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.NARUTO.Sage Mode.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.NARUTO.Zabuza.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.NARUTO.ptsNaruto.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.NARUTO.ptsSasuke.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.NARUTO.tsNaruto.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.NARUTO.tsSasuke.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.OTHER.Accel.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.OTHER.Accel.BattleScript` | ModuleScript | 206 | **MÉDIO** | toca animação | sim | SIM | MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.OTHER.Kazuma.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.OTHER.MISC.Afro Samurai.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.OTHER.MISC.Chika.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.OTHER.MISC.Saitama.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.OTHER.MISC.Tanjiro.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.OTHER.Rikka Awakened.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.OTHER.Rikka Awakened.BattleScript` | ModuleScript | 378 | **MÉDIO** | toca animação | sim | SIM | MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.OTHER.Rikka.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.OTHER.Rikka.BattleScript` | ModuleScript | 378 | **MÉDIO** | toca animação | sim | SIM | MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.One Piece Pack.Ace.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.One Piece Pack.Akainu.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.One Piece Pack.Akainu.BattleScript` | ModuleScript | 205 | **MÉDIO** | toca animação | sim | SIM | MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.One Piece Pack.Kizaru.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.One Piece Pack.Kizaru.BattleScript` | ModuleScript | 205 | **MÉDIO** | toca animação | sim | SIM | MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.One Piece Pack.Shanks.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.One Piece Pack.TS Luffy.Snakeman.Animate` | LocalScript | 1 | **NENHUM** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | — |
| `Anime Pack.One Piece Pack.TS Luffy.Snakeman.BattleScript` | ModuleScript | 1 | **NENHUM** | não identificada (ler manualmente) | não | SIM | — |
| `Anime Pack.One Piece Pack.TS Luffy.tsLuffy.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.One Piece Pack.TS SANJI.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.One Piece Pack.TS SANJI.BattleScript` | ModuleScript | 205 | **MÉDIO** | toca animação | sim | SIM | MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.One Piece Pack.Whitebeard.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.One Piece Pack.ptsLaw.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.One Piece Pack.ptsLuffy.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.One Piece Pack.ptsSanji.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.One Piece Pack.ptsZoro.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.One Piece Pack.tsZoro.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.YYH.Hiei (Jagan Eye).Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.YYH.Hiei.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |
| `Anime Pack.YYH.Yusuke Mode.Animate` | LocalScript | 1 | **NENHUM** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | — |
| `Anime Pack.YYH.Yusuke Mode.BattleScript` | ModuleScript | 1 | **NENHUM** | não identificada (ler manualmente) | não | SIM | — |
| `Anime Pack.YYH.Yusuke.Animate` | LocalScript | 596 | **MÉDIO** | Animate padrão do Roblox (andar/pular/idle) | sim | SIM | MÉDIO: acessa Players<br>MÉDIO: acessa Chat/TextChat<br>MÉDIO: loop infinito (custo de desempenho)<br>BAIXO: toca animações |

Regra do Roll Legends: **nenhum script de terceiros entra no jogo**. O CharacterModelFactory
já anima/posiciona os modelos; os scripts do pack são removidos na importação.

## 2. Personagens

| # | Categoria | Nome atual | Rig | Nota | Peças (Mesh) | Cabelo | Roupa | Rosto | Arma | Acessórios | VFX | Animações | Scripts | Compatibilidade |
|---:|---|---|---:|---|---|---|---|---|---|---:|---:|---:|---|
| 1 | FATE | Shirou | R6 | 59 | 18 (10) | — | Shirt 1146886989, Pants 1146886584 | — | RightSword (pelo nome), RightSwordEX (pelo nome), LeftSword (pelo nome), LeftSwordEX (pelo nome) | 0 | 14 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 2 | FATE | Saber | R6 | 44 | 16 (8) | — | Shirt 3145139681, Pants 3145142260 | — | SpecialBlade (pelo nome) | 0 | 15 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 3 | FATE | Gilgamesh | R6 | 39 | 16 (8) | — | Shirt 5737904033, Pants 5737913186 | — | — | 0 | 14 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 4 | FATE | Iskandar | R6 | 65 | 20 (12) | — | Shirt 7048976455, Pants 7048693612 | — | MySword (pelo nome) | 0 | 14 | 21 | 2 | MÉDIA (corrigir: ver problemas) |
| 5 | FATE | Lancer Mode | R6 | 50 | 18 (10) | — | Shirt 4712211329, Pants 4712207631 | — | Spear (pelo nome), SwordDrawn1 (pelo nome) | 0 | 30 | 21 | 2 | MÉDIA (corrigir: ver problemas) |
| 6 | FATE | SALTER | R6 | 65 | 22 (14) | — | Shirt 6318331684, Pants 6318334129 | — | Blade (pelo nome), SpecialBlade (pelo nome) | 0 | 15 | 21 | 2 | MÉDIA (corrigir: ver problemas) |
| 7 | FATE | Lancer  | R6 | 50 | 18 (10) | — | Shirt 4712211329, Pants 4712207631 | — | Spear (pelo nome), SwordDrawn1 (pelo nome) | 0 | 21 | 21 | 2 | MÉDIA (corrigir: ver problemas) |
| 8 | FATE | Kiritsugu | R6 | 24 | 13 (5) | — | Shirt 4839032606, Pants 4839033124 | — | — | 0 | 14 | 21 | 2 | MÉDIA (corrigir: ver problemas) |
| 9 | FATE | Rin | R6 | 35 | 13 (5) | — | Shirt 4631417727, Pants 2133003392 | — | Bow (pelo nome) | 0 | 14 | 21 | 2 | MÉDIA (corrigir: ver problemas) |
| 10 | FATE | Archer (EMIYA) | R6 | 59 | 18 (10) | — | Shirt 246903243, Pants 246903175 | — | RightSword (pelo nome), RightSwordEX (pelo nome), LeftSword (pelo nome), LeftSwordEX (pelo nome) | 0 | 18 | 43 | 2 | MÉDIA (corrigir: ver problemas) |
| 11 | NARUTO | tsSasuke | R6 | 35 | 25 (5) | — | Shirt 170827870, Pants 170827994 | — | Blade1 (pelo nome), Blade2 (pelo nome) | 0 | 18 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 12 | NARUTO | Pain | R6 | 30 | 13 (5) | — | Shirt 1163738004, Pants 1163737487 | — | — | 0 | 14 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 13 | NARUTO | tsNaruto | R6 | 27 | 12 (4) | — | Shirt 1149318124, Pants 1149318906 | — | — | 0 | 14 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 14 | NARUTO | Kakashi | R6 | 39 | 17 (9) | — | Shirt 2219413408, Pants 2219439857 | — | — | 0 | 14 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 15 | NARUTO | Gaara | R6 | 30 | 21 (12) | — | Shirt 767679257, Pants 702520223 | — | — | 0 | 17 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 16 | NARUTO | ptsNaruto | R6 | 27 | 12 (4) | — | Shirt 365307181, Pants 365308863 | — | — | 0 | 14 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 17 | NARUTO | ptsSasuke | R6 | 33 | 13 (5) | — | Shirt 491812706, Pants 491812658 | — | — | 0 | 14 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 18 | NARUTO | Neji | R6 | 33 | 13 (5) | — | Shirt 750982686, Pants 278654273 | — | — | 0 | 14 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 19 | NARUTO | Itachi | R6 | 36 | 13 (5) | — | Shirt 401316063, Pants 401316106 | — | — | 0 | 14 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 20 | NARUTO | Madara | R6 | 30 | 15 (7) | — | Shirt 1581337627, Pants 1891149621 | — | — | 0 | 14 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 21 | NARUTO | Zabuza | R6 | 50 | 16 (8) | — | Shirt 755366217, Pants 814177258 | — | BackSword (pelo nome) | 0 | 14 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 22 | NARUTO | Sage Mode | R6 | 33 | 13 (5) | — | Shirt 2194165465, Pants 2194384062 | — | — | 0 | 14 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 23 | NARUTO | 5TH GATE | R6 | 39 | 16 (8) | — | Shirt 433171231, Pants 433171481 | — | — | 0 | 45 | 21 | 2 | MÉDIA (corrigir: ver problemas) |
| 24 | NARUTO | Might Guy | R6 | 27 | 13 (5) | — | Shirt 433171231, Pants 433171481 | — | — | 0 | 14 | 21 | 2 | MÉDIA (corrigir: ver problemas) |
| 25 | NARUTO | 8TH GATE | R6 | 36 | 14 (6) | — | Shirt 7166020562, Pants 433171481 | — | — | 0 | 46 | 21 | 2 | MÉDIA (corrigir: ver problemas) |
| 26 | NARUTO | ROCK LEE GATES | R6 | 33 | 17 (4) | — | Shirt 748606701, Pants 1173837938 | — | — | 0 | 16 | 21 | 2 | MÉDIA (corrigir: ver problemas) |
| 27 | NARUTO | Rock Lee | R6 | 33 | 17 (4) | — | Shirt 748606701, Pants 1173837938 | — | — | 0 | 14 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 28 | NARUTO | KCM MINATO | R6 | 54 | 145 (27) | — | Shirt 339391590, Pants 339401998 | — | — | 0 | 14 | 21 | 2 | MÉDIA (corrigir: ver problemas) |
| 29 | NARUTO | Minato | R6 | 39 | 14 (6) | — | Shirt 2878419840, Pants 2890807343 | — | — | 0 | 14 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 30 | OTHER | Tanjiro | R6 | 47 | 16 (8) | — | Shirt 4153556958, Pants 4153572196 | — | Sword (pelo nome), Blade (pelo nome) | 0 | 19 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 31 | OTHER | Chika | R6 | 42 | 13 (5) | — | Shirt 5616878364, Pants 5616885541 | 5762484813 | Bow (pelo nome) | 0 | 14 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 32 | OTHER | Saitama | R6 | 27 | 13 (5) | — | Shirt 438640554, Pants 438640628 | — | — | 0 | 14 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 33 | OTHER | Afro Samurai | R6 | 73 | 25 (17) | — | Shirt 519869765, Pants 519869895 | — | Blade (pelo nome) | 0 | 18 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 34 | OTHER | Kazuma | R6 | 35 | 13 (5) | — | Shirt 4778785731, Pants 4778725438 | — | Sword (pelo nome) | 0 | 15 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 35 | OTHER | Rikka Awakened | R6 | 53 | 20 (11) | — | Shirt 5467480270, Pants 5467476326 | — | Bow (pelo nome) | 0 | 24 | 32 | 2 | MÉDIA (corrigir: ver problemas) |
| 36 | OTHER | Rikka | R6 | 44 | 15 (7) | — | Shirt 5467480270, Pants 5467476326 | — | Bow (pelo nome) | 0 | 22 | 32 | 2 | MÉDIA (corrigir: ver problemas) |
| 37 | OTHER | Accel | R6 | 30 | 14 (6) | — | Shirt 285788508, Pants 285788475 | — | — | 0 | 14 | 21 | 2 | MÉDIA (corrigir: ver problemas) |
| 38 | DBZ | Majin Vegeta | R6 | 24 | 13 (3) | — | Shirt 670881834, Pants 187766138 | — | — | 0 | 15 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 39 | DBZ | Goku | R6 | 33 | 12 (4) | GokuHair | Shirt 541432531, Pants 541432684 | — | — | 1 | 14 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 40 | DBZ | Piccolo | R6 | 45 | 17 (9) | — | Shirt 877663892, Pants 768830398 | — | — | 0 | 14 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 41 | DBZ | Caulifa | R6 | 27 | 13 (5) | — | Shirt 1175554941, Pants 1175553242 | — | — | 0 | 17 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 42 | DBZ | Trunks | R6 | 38 | 19 (5) | TrunksHairF | Shirt 89362662, Pants 156051951 | — | SwordPack (pelo nome), Swordy (pelo nome), Swordy (pelo nome), Swordy (pelo nome) | 1 | 15 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 43 | DBZ | Vegeta | R6 | 21 | 43 (3) | — | Shirt 880856934, Pants 880857066 | — | — | 0 | 14 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 44 | DBZ | Buu Saga Goku | R6 | 37 | 14 (6) | — | Shirt 541432531, Pants 541432684 | 1138377952 | — | 0 | 16 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 45 | DBZ | Gohan | R6 | 27 | 13 (5) | — | Shirt 1252700273, Pants 2693861316 | — | — | 0 | 14 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 46 | DBZ | Goku Black [NEW] | R6 | 21 | 19 (8) | — | Shirt 4821551938, Pants 4821552177 | — | — | 0 | 14 | 32 | 2 | MÉDIA (corrigir: ver problemas) |
| 47 | DBZ | SSJR | R6 | 24 | 21 (9) | — | Shirt 4821551938, Pants 4821552177 | — | — | 0 | 16 | 32 | 2 | MÉDIA (corrigir: ver problemas) |
| 48 | DBZ | VEGITO | R6 | 42 | 15 (7) | — | Shirt 385574437, Pants 385574689 | — | — | 0 | 14 | 21 | 2 | MÉDIA (corrigir: ver problemas) |
| 49 | DBZ | VEGITO BLUE | R6 | 42 | 15 (7) | — | Shirt 385574437, Pants 385574689 | — | — | 0 | 15 | 21 | 2 | MÉDIA (corrigir: ver problemas) |
| 50 | DBZ | LSSJ BROLY | R6 | 33 | 14 (6) | — | Shirt 2313604978, Pants 2313575049 | — | — | 0 | 16 | 21 | 2 | MÉDIA (corrigir: ver problemas) |
| 51 | DBZ | Broly | R6 | 30 | 13 (5) | — | Shirt 3092007477, Pants 3009760273 | — | — | 0 | 14 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 52 | DBZ | Krillin | R6 | 21 | 11 (3) | — | Shirt 541432531, Pants 541432684 | — | — | 0 | 14 | 21 | 2 | MÉDIA (corrigir: ver problemas) |
| 53 | Bleach Pack | Grimmjow | R6 | 59 | 21 (13) | — | Shirt 1437431145, Pants 1437436295 | — | Sword (pelo nome), FakeSword (pelo nome) | 0 | 14 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 54 | Bleach Pack | Kisuke | R6 | 41 | 17 (7) | — | Shirt 165567911, Pants 165567952 | — | Blade (pelo nome) | 0 | 16 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 55 | Bleach Pack | Shunsui | R6 | 56 | 22 (14) | — | Shirt 2441529930, Pants 2441532543 | — | LBlade (pelo nome), RBlade (pelo nome) | 0 | 14 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 56 | Bleach Pack | Byakuya | R6 | 44 | 15 (7) | — | Shirt 124509917, Pants 124500388 | — | Blade (pelo nome), Sword (pelo nome) | 0 | 17 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 57 | Bleach Pack | Shinji | R6 | 58 | 19 (10) | — | Shirt 1195155236, Pants 1476033362 | — | Sword (pelo nome) | 0 | 16 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 58 | Bleach Pack | Gin | R6 | 38 | 15 (7) | — | Shirt 124509759, Pants 124500388 | — | Blade (pelo nome), ExtendingBlade (pelo nome) | 0 | 14 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 59 | Bleach Pack | Yamamoto | R6 | 38 | 15 (5) | — | Shirt 2432831544, Pants 2432809576 | — | Sword (pelo nome) | 0 | 19 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 60 | Bleach Pack | Rukia | R6 | 41 | 14 (6) | — | Shirt 168080073, Pants 224504565 | — | Sword (pelo nome) | 0 | 15 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 61 | Bleach Pack | Starrk | R6 | 44 | 16 (8) | — | Shirt 429526385, Pants 429550268 | — | Sword (pelo nome), EnergySwordR (pelo nome), EnergySwordL (pelo nome) | 0 | 17 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 62 | Bleach Pack | Ichigo | R6 | 41 | 14 (6) | — | Shirt 168080073, Pants 224504565 | — | Sword (pelo nome) | 0 | 15 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 63 | Bleach Pack | Aizen | R6 | 38 | 14 (6) | — | Shirt 2951463323, Pants 201100741 | — | Sword (pelo nome) | 0 | 15 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 64 | Bleach Pack | Final Aizen | R6 | 38 | 26 (6) | — | Shirt 5145757702, Pants 5145758300 | — | Sword (pelo nome) | 0 | 15 | 21 | 2 | MÉDIA (corrigir: ver problemas) |
| 65 | Bleach Pack | Mugetsu | R6 | 63 | 17 (9) | — | Shirt 6360803241, Pants 6526202614 | 1486850218 | Sword (pelo nome) | 0 | 16 | 21 | 2 | MÉDIA (corrigir: ver problemas) |
| 66 | Bleach Pack | Hollow Ichigo | R6 | 53 | 16 (8) | — | Shirt 169930804, Pants 177383854 | — | Sword (pelo nome) | 0 | 15 | 21 | 2 | MÉDIA (corrigir: ver problemas) |
| 67 | Bleach Pack | Vasto | R6 | 53 | 17 (9) | — | Shirt 6408862988, Pants 6408863474 | — | Sword (pelo nome) | 0 | 14 | 21 | 2 | MÉDIA (corrigir: ver problemas) |
| 68 | Bleach Pack | Neko Yoru | R6 | 27 | 26 (5) | — | Shirt 1635575936, Pants 399343072 | — | — | 0 | 27 | 21 | 2 | MÉDIA (corrigir: ver problemas) |
| 69 | Bleach Pack | Shunko Yoruichi | R6 | 27 | 13 (5) | — | Shirt 1635575936, Pants 399343072 | — | — | 0 | 18 | 21 | 2 | MÉDIA (corrigir: ver problemas) |
| 70 | Bleach Pack | Yoruichi | R6 | 27 | 13 (5) | — | Shirt 2850202076, Pants 399343072 | — | — | 0 | 14 | 21 | 2 | MÉDIA (corrigir: ver problemas) |
| 71 | Bleach Pack | R1 | R6 | 53 | 18 (10) | — | Shirt 6704386382, Pants 6700814487 | — | Sword (pelo nome) | 0 | 15 | 21 | 2 | MÉDIA (corrigir: ver problemas) |
| 72 | Bleach Pack | R2 | R6 | 59 | 19 (11) | — | Shirt 5608818156, Pants 5608818782 | — | Sword (pelo nome) | 0 | 15 | 21 | 2 | MÉDIA (corrigir: ver problemas) |
| 73 | Bleach Pack | Ulq | R6 | 56 | 18 (10) | — | Shirt 4776261782, Pants 4776262663 | — | Swords (pelo nome), Swords (pelo nome), Swords (pelo nome), Sword (pelo nome) | 0 | 15 | 21 | 2 | MÉDIA (corrigir: ver problemas) |
| 74 | Bleach Pack | Toshiro | R6 | 63 | 17 (9) | — | Shirt 124497496, Pants 124500388 | 6499094138 | Sword (pelo nome) | 0 | 15 | 21 | 2 | MÉDIA (corrigir: ver problemas) |
| 75 | Bleach Pack | Bankai Toshiro | R6 | 80 | 24 (16) | — | Shirt 124497496, Pants 124500388 | 6499094138 | Sword (pelo nome) | 0 | 17 | 21 | 2 | MÉDIA (corrigir: ver problemas) |
| 76 | Fairy Tail | Gray | R6 | 27 | 13 (5) | — | Shirt 238424897, Pants 4807856387 | — | — | 0 | 14 | 21 | 2 | MÉDIA (corrigir: ver problemas) |
| 77 | Fairy Tail | Grey Awakening | R6 | 30 | 13 (5) | — | Shirt 7033733206, Pants 4807856387 | — | — | 0 | 28 | 21 | 2 | MÉDIA (corrigir: ver problemas) |
| 78 | Fairy Tail | Natsu | R6 | 33 | 14 (6) | — | Shirt 238423172, Pants 238423246 | — | — | 0 | 14 | 21 | 2 | MÉDIA (corrigir: ver problemas) |
| 79 | Fairy Tail | Natsu Awakened | R6 | 33 | 14 (6) | — | Shirt 238423172, Pants 238423246 | — | — | 0 | 31 | 21 | 2 | MÉDIA (corrigir: ver problemas) |
| 80 | JJK | Sukuna | R6 | 52 | 16 (8) | — | Shirt 7019407948, Pants 6893665160 | 7578962194 | — | 0 | 14 | 21 | 2 | MÉDIA (corrigir: ver problemas) |
| 81 | JJK | Yuji | R6 | 46 | 15 (7) | — | Shirt 6102256552, Pants 6102258786 | 6752935483 | — | 0 | 14 | 21 | 2 | MÉDIA (corrigir: ver problemas) |
| 82 | JJK | Gojo Satoru (Blindfold Off) | R6 | 51 | 17 (9) | — | Shirt 6041845046, Pants 6041840643 | — | — | 0 | 14 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 83 | JJK | Gojo Satoru | R6 | 51 | 17 (9) | — | Shirt 6041845046, Pants 6041840643 | — | — | 0 | 14 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 84 | One Piece Pack | Shanks | R6 | 48 | 25 (13) | — | Shirt 513011433, Pants 513013377 | 916695561 | SheathedBlade (pelo nome), BladeUnion (pelo nome), Blade (pelo nome), BladeUnion (pelo nome) | 0 | 14 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 85 | One Piece Pack | TS SANJI | R6 | 27 | 12 (4) | — | Shirt 1173599426, Pants 1173599919 | — | — | 0 | 14 | 21 | 2 | MÉDIA (corrigir: ver problemas) |
| 86 | One Piece Pack | Whitebeard | R6 | 58 | 17 (9) | — | Shirt 5089959071, Pants 2843082152 | 1162044724 | — | 0 | 15 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 87 | One Piece Pack | ptsLaw | R6 | 44 | 15 (7) | — | Shirt 409688020, Pants 303139899 | — | SwordDrawn1 (pelo nome), SwordHilt (pelo nome) | 0 | 15 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 88 | One Piece Pack | ptsSanji | R6 | 27 | 12 (4) | — | Shirt 416334998, Pants 261456708 | — | — | 0 | 14 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 89 | One Piece Pack | ptsZoro | R6 | 66 | 22 (13) | — | Shirt 408413703, Pants 408413722 | 1057719043 | — | 0 | 17 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 90 | One Piece Pack | Ace | R6 | 44 | 15 (7) | — | Shirt 231542845, Pants 227118801 | — | Pistol (pelo nome) | 0 | 14 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 91 | One Piece Pack | Akainu | R6 | 58 | 27 (19) | — | Shirt 5490519807, Pants 640333276 | 6478986845 | — | 0 | 14 | 21 | 2 | MÉDIA (corrigir: ver problemas) |
| 92 | One Piece Pack | Kizaru | R6 | 64 | 21 (13) | — | Shirt 670782694, Pants 687442019 | 6476237983 | — | 0 | 14 | 21 | 2 | MÉDIA (corrigir: ver problemas) |
| 93 | One Piece Pack | tsZoro | R6 | 66 | 22 (13) | — | Shirt 6789178999, Pants 6789176148 | 631666499 | — | 0 | 17 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 94 | One Piece Pack | ptsLuffy | R6 | 33 | 16 (4) | — | Pants 815464868 | — | — | 0 | 14 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 95 | One Piece Pack | Snakeman | R6 | 27 | 22 (4) | — | Shirt 3361690688, Pants 3361324877 | — | — | 0 | 14 | 21 | 2 | MÉDIA (corrigir: ver problemas) |
| 96 | One Piece Pack | tsLuffy | R6 | 36 | 17 (5) | — | Shirt 187585383, Pants 242533144 | — | — | 0 | 14 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 97 | JOJO | Jonathan | R6 | 32 | 13 (5) | — | Shirt 3274358737, Pants 3312877965 | — | Sword (pelo nome) | 0 | 19 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 98 | JOJO | Josuke | R6 | 54 | 27 (17) | — | Shirt 4758068378, Pants 4758069229 | — | — | 0 | 14 | 9 | 2 | MÉDIA (corrigir: ver problemas) |
| 99 | JOJO | Giorno | R6 | 67 | 31 (21) | — | Shirt 5293737444, Pants 5293741706 | 4861665654 | — | 0 | 14 | 9 | 2 | MÉDIA (corrigir: ver problemas) |
| 100 | JOJO | GER | R6 | 50 | 85 (45) | — | — | 3423965424 | — | 0 | 8 | 1 | 0 | MÉDIA (corrigir: ver problemas) |
| 101 | JOJO | Giorno | R6 | 67 | 31 (21) | — | Shirt 3569533581, Pants 3569541097 | 4861665654 | — | 0 | 14 | 9 | 2 | MÉDIA (corrigir: ver problemas) |
| 102 | JOJO | Jotaro | R6 | 54 | 32 (22) | — | Shirt 3271436702, Pants 3270719883 | — | — | 0 | 14 | 9 | 2 | MÉDIA (corrigir: ver problemas) |
| 103 | JOJO | Old Joseph | R6 | 33 | 16 (6) | — | Shirt 1069863440, Pants 1069863927 | — | — | 0 | 24 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 104 | JOJO | Young Joseph | R6 | 33 | 17 (6) | — | Shirt 2203306011, Pants 2937056830 | — | — | 0 | 14 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 105 | JOJO | Kira Yoshikage | R6 | 51 | 22 (12) | — | Shirt 4828313734, Pants 4828324070 | — | — | 0 | 14 | 22 | 3 | MÉDIA (corrigir: ver problemas) |
| 106 | JOJO | Killer Queen | R6 | 54 | 38 (25) | — | Shirt 0, Pants Pants | — | — | 0 | 9 | 1 | 0 | MÉDIA (corrigir: ver problemas) |
| 107 | JOJO | Morph | custom (RigType Enum.HumanoidRigType.R6) | 12 | 4 (4) | — | — | — | — | 0 | 0 | 0 | 0 | MÉDIA (corrigir: ver problemas) |
| 108 | JOJO | DIO | R6 | 33 | 37 (13) | — | Shirt 981445141, Pants 981445283 | — | — | 0 | 14 | 9 | 2 | MÉDIA (corrigir: ver problemas) |
| 109 | JOJO | DIO AWAKENED | R6 | 27 | 11 (3) | — | Shirt 5739507839, Pants 981445283 | — | — | 0 | 22 | 22 | 3 | MÉDIA (corrigir: ver problemas) |
| 110 | JOJO | Morph | custom (RigType Enum.HumanoidRigType.R6) | 14 | 4 (4) | — | — | — | — | 0 | 1 | 0 | 0 | MÉDIA (corrigir: ver problemas) |
| 111 | JOJO | Doppio | R6 | 43 | 35 (17) | — | Shirt 1062590648, Pants 1062727307 | 5834444583 | — | 0 | 16 | 9 | 2 | MÉDIA (corrigir: ver problemas) |
| 112 | JOJO | KC AURA | R6 | 53 | 57 (28) | — | — | 4728555890 | — | 0 | 9 | 0 | 0 | MÉDIA (corrigir: ver problemas) |
| 113 | JOJO | STONE FREE AURA | R6 | 57 | 34 (26) | — | Shirt Shirt, Pants Pants | — | — | 0 | 9 | 1 | 0 | MÉDIA (corrigir: ver problemas) |
| 114 | JOJO | Jolyne | R6 | 54 | 27 (17) | — | Shirt 6858394476, Pants 6858395702 | — | — | 0 | 14 | 22 | 3 | MÉDIA (corrigir: ver problemas) |
| 115 | JOJO | STONE FREE | R6 | 47 | 34 (26) | — | Shirt Shirt, Pants Pants | — | — | 0 | 0 | 1 | 0 | ALTA |
| 116 | JOJO | Awakened Jolyne | R6 | 54 | 27 (17) | — | Shirt 6858394476, Pants 6858395702 | — | — | 0 | 22 | 22 | 3 | MÉDIA (corrigir: ver problemas) |
| 117 | JOJO | Enrico | R6 | 78 | 37 (25) | — | Shirt 8146722402, Pants 8146434822 | 8625002232 | — | 0 | 7 | 0 | 0 | MÉDIA (corrigir: ver problemas) |
| 118 | My Hero Academia Pack | Lemillion | R6 | 42 | 15 (7) | — | Shirt 4806108407, Pants 3459508053 | — | — | 0 | 15 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 119 | My Hero Academia Pack | Speed Guy | R6 | 30 | 220 (180) | — | Shirt 2107230452, Pants 2142309816 | — | — | 0 | 51 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 120 | My Hero Academia Pack | Hellflame | R6 | 67 | 25 (14) | — | Shirt 2094256527, Pants 2094586396 | 5202199639 | — | 0 | 28 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 121 | My Hero Academia Pack | Todoroki | R6 | 27 | 14 (4) | — | Shirt 1044512674, Pants 1069574772 | — | — | 0 | 18 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 122 | My Hero Academia Pack | Deku Awakened | R6 | 30 | 15 (5) | — | Shirt 1925822323, Pants 1584618190 | — | — | 0 | 23 | 21 | 2 | MÉDIA (corrigir: ver problemas) |
| 123 | My Hero Academia Pack | All Might | R6 | 34 | 12 (4) | — | Shirt 1946244545, Pants 1694412886 | 6765348477 | — | 0 | 14 | 21 | 2 | MÉDIA (corrigir: ver problemas) |
| 124 | My Hero Academia Pack | All Might (MODE) | R6 | 37 | 13 (5) | — | Shirt 445670583, Pants 433406732 | 1880669867 | — | 0 | 14 | 21 | 2 | MÉDIA (corrigir: ver problemas) |
| 125 | My Hero Academia Pack | Awakened Bakugo | R6 | 24 | 24 (4) | — | Shirt 860232820, Pants 454918764 | — | — | 0 | 16 | 21 | 2 | MÉDIA (corrigir: ver problemas) |
| 126 | My Hero Academia Pack | Bakugo | R6 | 24 | 24 (4) | — | Shirt 860232820, Pants 454918764 | — | — | 0 | 14 | 21 | 2 | MÉDIA (corrigir: ver problemas) |
| 127 | My Hero Academia Pack | Deku | R6 | 30 | 15 (5) | — | Shirt 1925822323, Pants 1584618190 | — | — | 0 | 17 | 21 | 2 | MÉDIA (corrigir: ver problemas) |
| 128 | My Hero Academia Pack | 100% Deku | R6 | 36 | 21 (8) | — | Shirt 5141913448, Pants 4992277720 | — | — | 0 | 23 | 21 | 2 | MÉDIA (corrigir: ver problemas) |
| 129 | HXH | Adult Gon | R6 | 24 | 12 (4) | — | Shirt 634456744, Pants 1388491228 | — | — | 0 | 17 | 21 | 2 | MÉDIA (corrigir: ver problemas) |
| 130 | HXH | Killua Godspeed | R6 | 33 | 13 (5) | — | Shirt 2065247269, Pants 2065252088 | — | — | 0 | 30 | 21 | 2 | MÉDIA (corrigir: ver problemas) |
| 131 | HXH | Hisoka | R6 | 31 | 12 (4) | — | Shirt 684655756, Pants 684639323 | 5203810349 | — | 0 | 14 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 132 | HXH | Illumi Awakened | R6 | 30 | 15 (7) | — | Shirt 5542638365, Pants 4880509381 | — | — | 0 | 31 | 21 | 2 | MÉDIA (corrigir: ver problemas) |
| 133 | HXH | Illumi | R6 | 24 | 13 (5) | — | Shirt 5104513434, Pants 5104511174 | — | — | 0 | 14 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 134 | HXH | Killua | R6 | 27 | 12 (4) | — | Shirt 2065247269, Pants 2065252088 | — | — | 0 | 14 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 135 | HXH | Gon | R6 | 31 | 12 (4) | — | Shirt 159011359, Pants 159011374 | 5203287838 | — | 0 | 14 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 136 | HXH | Hisoka | R6 | 31 | 12 (4) | — | Shirt 684655756, Pants 684639323 | 5584533426 | — | 0 | 15 | 21 | 2 | MÉDIA (corrigir: ver problemas) |
| 137 | YYH | Hiei | R6 | 62 | 21 (13) | — | Shirt 6532351263, Pants 6532359099 | — | Blade (pelo nome), Blade2 (pelo nome) | 0 | 14 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 138 | YYH | Yusuke | R6 | 31 | 12 (4) | — | Shirt 5127567401, Pants 5127569364 | 2549113296 | — | 0 | 14 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 139 | YYH | Yusuke Mode | R6 | 37 | 13 (5) | — | Shirt 4610857104, Pants 4610863084 | 2953840006 | — | 0 | 16 | 21 | 2 | MÉDIA (corrigir: ver problemas) |
| 140 | YYH | Hiei (Jagan Eye) | R6 | 62 | 21 (13) | — | Shirt 6532351263, Pants 6532359099 | — | Blade (pelo nome), Blade2 (pelo nome) | 0 | 14 | 9 | 1 | MÉDIA (corrigir: ver problemas) |
| 141 | AOT | Eren | R6 | 24 | 8 (2) | — | Shirt 764288993, Pants 2422053275 | 491062990 | — | 0 | 0 | 0 | 0 | ALTA |
| 142 | AOT | Attack Titan | R6 | 27 | 9 (3) | — | Shirt 6331913214, Pants 6770170859 | 141107361 | — | 0 | 0 | 0 | 0 | ALTA |
| 143 | AOT | Eren Post-time skip | R6 | 24 | 8 (2) | — | Shirt 6365243700, Pants 6365397892 | 6490568071 | — | 0 | 0 | 0 | 0 | ALTA |
| 144 | AOT | Mikasa (Formal) | R6 | 27 | 9 (3) | — | Shirt 6531123096, Pants 6428697541 | 6944709040 | — | 0 | 0 | 0 | 0 | ALTA |
| 145 | AOT | Mikasa | R6 | 27 | 9 (3) | — | Shirt 404851338, Pants 427960517 | 6944709040 | — | 0 | 0 | 0 | 0 | ALTA |
| 146 | AOT | Female Titan | R6 | 24 | 8 (2) | — | Shirt 6383651600, Pants 6383653512 | 6399702661 | — | 0 | 0 | 0 | 0 | ALTA |
| 147 | AOT | Annie (Junior High) | R6 | 24 | 8 (2) | — | Shirt 6631212586, Pants 6645662576 | 6332463530 | — | 0 | 0 | 0 | 0 | ALTA |
| 148 | AOT | Annie | R6 | 24 | 8 (2) | — | Shirt 177783521, Pants 177783110 | 6332463530 | — | 0 | 0 | 0 | 0 | ALTA |
| 149 | AOT | Erwin (Alt) | R6 | 24 | 8 (2) | — | Shirt 6555644139, Pants 6555645158 | 6944478188 | — | 0 | 0 | 0 | 0 | ALTA |
| 150 | AOT | Erwin | R6 | 27 | 9 (3) | — | Shirt 157615090, Pants 2273144386 | 6944478188 | — | 0 | 0 | 0 | 0 | ALTA |
| 151 | AOT | Sasha (Suit) | R6 | 24 | 8 (2) | — | Shirt 6301459760, Pants 6272063125 | 6944812855 | — | 0 | 0 | 0 | 0 | ALTA |
| 152 | AOT | Sasha | R6 | 24 | 8 (2) | — | Shirt 157615090, Pants 2273144386 | 6944812855 | — | 0 | 0 | 0 | 0 | ALTA |

### 1. Shirou

- Caminho: `Anime Pack.FATE.Fate Pack.Shirou` · Categoria: FATE
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 6 MeshPart, 4 SpecialMesh, 6 MeshIds únicos · Texturas únicas: 6 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: RightSword (pelo nome), RightSwordEX (pelo nome), LeftSword (pelo nome), LeftSwordEX (pelo nome)
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 2. Saber

- Caminho: `Anime Pack.FATE.Fate Pack.Saber` · Categoria: FATE
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 4 MeshPart, 4 SpecialMesh, 3 MeshIds únicos · Texturas únicas: 4 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: SpecialBlade (pelo nome)
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+9)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO]
- Problemas: 15 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 3. Gilgamesh

- Caminho: `Anime Pack.FATE.Fate Pack.Gilgamesh` · Categoria: FATE
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 4 MeshPart, 4 SpecialMesh, 4 MeshIds únicos · Texturas únicas: 3 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 4. Iskandar

- Caminho: `Anime Pack.FATE.Iskandar` · Categoria: FATE
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 8 MeshPart, 4 SpecialMesh, 8 MeshIds únicos · Texturas únicas: 6 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: MySword (pelo nome)
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+15)
- Scripts: Animate [NENHUM], BattleScript [NENHUM]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 5. Lancer Mode

- Caminho: `Anime Pack.FATE.Lancer Mode` · Categoria: FATE · Forma de: **lancer**
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 6 MeshPart, 4 SpecialMesh, 5 MeshIds únicos · Texturas únicas: 4 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: Spear (pelo nome), SwordDrawn1 (pelo nome)
- VFX: ParticleEmitter Reiatsu, ParticleEmitter Reiatsu, ParticleEmitter ShootParticle, Trail MoveT, ParticleEmitter Reiatsu, Trail MoveT (+24)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+15)
- Scripts: Animate [NENHUM], BattleScript [NENHUM]
- Problemas: 30 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 6. SALTER

- Caminho: `Anime Pack.FATE.SALTER` · Categoria: FATE
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 10 MeshPart, 4 SpecialMesh, 8 MeshIds únicos · Texturas únicas: 6 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: Blade (pelo nome), SpecialBlade (pelo nome)
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+9)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+15)
- Scripts: Animate [NENHUM], BattleScript [NENHUM]
- Problemas: 15 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 7. Lancer 

- Caminho: `Anime Pack.FATE.Lancer ` · Categoria: FATE · Forma de: **lancer**
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 6 MeshPart, 4 SpecialMesh, 5 MeshIds únicos · Texturas únicas: 4 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: Spear (pelo nome), SwordDrawn1 (pelo nome)
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+15)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+15)
- Scripts: Animate [NENHUM], BattleScript [NENHUM]
- Problemas: 21 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 8. Kiritsugu

- Caminho: `Anime Pack.FATE.Kiritsugu` · Categoria: FATE
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 1 MeshPart, 4 SpecialMesh, 1 MeshIds únicos · Texturas únicas: 1 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+15)
- Scripts: Animate [NENHUM], BattleScript [NENHUM]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 9. Rin

- Caminho: `Anime Pack.FATE.Rin` · Categoria: FATE
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 2 MeshPart, 3 SpecialMesh, 2 MeshIds únicos · Texturas únicas: 2 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: Bow (pelo nome)
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+15)
- Scripts: Animate [MÉDIO], BattleScript [MÉDIO]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 10. Archer (EMIYA)

- Caminho: `Anime Pack.FATE.Archer (EMIYA)` · Categoria: FATE
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 6 MeshPart, 4 SpecialMesh, 6 MeshIds únicos · Texturas únicas: 6 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: RightSword (pelo nome), RightSwordEX (pelo nome), LeftSword (pelo nome), LeftSwordEX (pelo nome)
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+12)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+37)
- Scripts: Animate [MÉDIO], BattleScript [MÉDIO]
- Problemas: 18 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 11. tsSasuke

- Caminho: `Anime Pack.NARUTO.tsSasuke` · Categoria: NARUTO
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 2 MeshPart, 3 SpecialMesh, 2 MeshIds únicos · Texturas únicas: 2 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: Blade1 (pelo nome), Blade2 (pelo nome)
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+12)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO]
- Problemas: 18 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 12. Pain

- Caminho: `Anime Pack.NARUTO.Pain` · Categoria: NARUTO
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 2 MeshPart, 3 SpecialMesh, 2 MeshIds únicos · Texturas únicas: 2 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 13. tsNaruto

- Caminho: `Anime Pack.NARUTO.tsNaruto` · Categoria: NARUTO
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 1 MeshPart, 3 SpecialMesh, 1 MeshIds únicos · Texturas únicas: 2 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 14. Kakashi

- Caminho: `Anime Pack.NARUTO.Kakashi` · Categoria: NARUTO
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 2 MeshPart, 7 SpecialMesh, 3 MeshIds únicos · Texturas únicas: 4 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 15. Gaara

- Caminho: `Anime Pack.NARUTO.Gaara` · Categoria: NARUTO
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 1 MeshPart, 11 SpecialMesh, 1 MeshIds únicos · Texturas únicas: 3 · Decals: 11 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter FeetParticle, ParticleEmitter Break (+11)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO]
- Problemas: 17 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 16. ptsNaruto

- Caminho: `Anime Pack.NARUTO.ptsNaruto` · Categoria: NARUTO
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 1 MeshPart, 3 SpecialMesh, 1 MeshIds únicos · Texturas únicas: 2 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 17. ptsSasuke

- Caminho: `Anime Pack.NARUTO.ptsSasuke` · Categoria: NARUTO
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 1 MeshPart, 4 SpecialMesh, 2 MeshIds únicos · Texturas únicas: 3 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 18. Neji

- Caminho: `Anime Pack.NARUTO.Neji` · Categoria: NARUTO
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 2 MeshPart, 3 SpecialMesh, 2 MeshIds únicos · Texturas únicas: 3 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [NENHUM]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 19. Itachi

- Caminho: `Anime Pack.NARUTO.Itachi` · Categoria: NARUTO
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 1 MeshPart, 4 SpecialMesh, 2 MeshIds únicos · Texturas únicas: 4 · Decals: 3 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 20. Madara

- Caminho: `Anime Pack.NARUTO.Madara` · Categoria: NARUTO
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 3 MeshPart, 4 SpecialMesh, 2 MeshIds únicos · Texturas únicas: 2 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 21. Zabuza

- Caminho: `Anime Pack.NARUTO.Zabuza` · Categoria: NARUTO
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 5 MeshPart, 3 SpecialMesh, 4 MeshIds únicos · Texturas únicas: 5 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: BackSword (pelo nome)
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 22. Sage Mode

- Caminho: `Anime Pack.NARUTO.Sage Mode` · Categoria: NARUTO
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 2 MeshPart, 3 SpecialMesh, 2 MeshIds únicos · Texturas únicas: 3 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1 (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 23. 5TH GATE

- Caminho: `Anime Pack.NARUTO.Might Guy.5TH GATE` · Categoria: NARUTO · Forma de: **th gate**
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 3 MeshPart, 5 SpecialMesh, 3 MeshIds únicos · Texturas únicas: 4 · Decals: 3 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: ParticleEmitter Aura, ParticleEmitter ParticleEmitter, Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT (+39)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+15)
- Scripts: Animate [NENHUM], BattleScript [NENHUM]
- Problemas: 45 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 24. Might Guy

- Caminho: `Anime Pack.NARUTO.Might Guy.Might Guy` · Categoria: NARUTO
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 1 MeshPart, 4 SpecialMesh, 1 MeshIds únicos · Texturas únicas: 2 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+15)
- Scripts: Animate [NENHUM], BattleScript [NENHUM]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 25. 8TH GATE

- Caminho: `Anime Pack.NARUTO.Might Guy.8TH GATE` · Categoria: NARUTO · Forma de: **th gate**
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 2 MeshPart, 4 SpecialMesh, 2 MeshIds únicos · Texturas únicas: 4 · Decals: 9 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: ParticleEmitter Aura, ParticleEmitter ParticleEmitter, Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT (+40)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+15)
- Scripts: Animate [NENHUM], BattleScript [NENHUM]
- Problemas: 46 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 26. ROCK LEE GATES

- Caminho: `Anime Pack.NARUTO.Rock Lee.ROCK LEE GATES` · Categoria: NARUTO
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 1 MeshPart, 3 SpecialMesh, 1 MeshIds únicos · Texturas únicas: 4 · Decals: 11 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+10)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+15)
- Scripts: Animate [NENHUM], BattleScript [NENHUM]
- Problemas: 16 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 27. Rock Lee

- Caminho: `Anime Pack.NARUTO.Rock Lee.Rock Lee` · Categoria: NARUTO
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 1 MeshPart, 3 SpecialMesh, 1 MeshIds únicos · Texturas únicas: 4 · Decals: 11 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 28. KCM MINATO

- Caminho: `Anime Pack.NARUTO.Minato.KCM MINATO` · Categoria: NARUTO
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 20 MeshPart, 7 SpecialMesh, 6 MeshIds únicos · Texturas únicas: 6 · Decals: 4 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+15)
- Scripts: Animate [NENHUM], BattleScript [NENHUM]
- Problemas: 145 peças: pesado para 400 personagens na tela, 14 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 29. Minato

- Caminho: `Anime Pack.NARUTO.Minato.Minato` · Categoria: NARUTO
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 2 MeshPart, 4 SpecialMesh, 3 MeshIds únicos · Texturas únicas: 4 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 30. Tanjiro

- Caminho: `Anime Pack.OTHER.MISC.Tanjiro` · Categoria: OTHER
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 5 MeshPart, 3 SpecialMesh, 5 MeshIds únicos · Texturas únicas: 3 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: Sword (pelo nome), Blade (pelo nome)
- VFX: ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1 (+13)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO]
- Problemas: 19 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 31. Chika

- Caminho: `Anime Pack.OTHER.MISC.Chika` · Categoria: OTHER
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 2 MeshPart, 3 SpecialMesh, 2 MeshIds únicos · Texturas únicas: 2 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: Bow (pelo nome)
- VFX: ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1 (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 32. Saitama

- Caminho: `Anime Pack.OTHER.MISC.Saitama` · Categoria: OTHER
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 1 MeshPart, 4 SpecialMesh, 1 MeshIds únicos · Texturas únicas: 2 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1 (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 33. Afro Samurai

- Caminho: `Anime Pack.OTHER.MISC.Afro Samurai` · Categoria: OTHER
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 11 MeshPart, 6 SpecialMesh, 10 MeshIds únicos · Texturas únicas: 7 · Decals: 5 · SurfaceAppearance: 0
- Acessórios: —
- Armas: Blade (pelo nome)
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+12)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO]
- Problemas: 18 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 34. Kazuma

- Caminho: `Anime Pack.OTHER.Kazuma` · Categoria: OTHER
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 2 MeshPart, 3 SpecialMesh, 2 MeshIds únicos · Texturas únicas: 2 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: Sword (pelo nome)
- VFX: ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1 (+9)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO]
- Problemas: 15 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 35. Rikka Awakened

- Caminho: `Anime Pack.OTHER.Rikka Awakened` · Categoria: OTHER · Forma de: **rikka**
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 2
- Malhas: 6 MeshPart, 5 SpecialMesh, 6 MeshIds únicos · Texturas únicas: 4 · Decals: 3 · SurfaceAppearance: 0
- Acessórios: —
- Armas: Bow (pelo nome)
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+18)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+26)
- Scripts: Animate [MÉDIO], BattleScript [MÉDIO]
- Problemas: 24 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 36. Rikka

- Caminho: `Anime Pack.OTHER.Rikka` · Categoria: OTHER · Forma de: **rikka**
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 3 MeshPart, 4 SpecialMesh, 3 MeshIds únicos · Texturas únicas: 4 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: Bow (pelo nome)
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+16)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+26)
- Scripts: Animate [MÉDIO], BattleScript [MÉDIO]
- Problemas: 22 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 37. Accel

- Caminho: `Anime Pack.OTHER.Accel` · Categoria: OTHER
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 2 MeshPart, 4 SpecialMesh, 2 MeshIds únicos · Texturas únicas: 2 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+15)
- Scripts: Animate [MÉDIO], BattleScript [MÉDIO]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 38. Majin Vegeta

- Caminho: `Anime Pack.DBZ.Majin Vegeta` · Categoria: DBZ
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 0 MeshPart, 3 SpecialMesh, 0 MeshIds únicos · Texturas únicas: 2 · Decals: 3 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+9)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [NENHUM]
- Problemas: 15 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 39. Goku

- Caminho: `Anime Pack.DBZ.Goku` · Categoria: DBZ
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 0 MeshPart, 4 SpecialMesh, 1 MeshIds únicos · Texturas únicas: 3 · Decals: 3 · SurfaceAppearance: 0
- Acessórios: GokuHair
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 40. Piccolo

- Caminho: `Anime Pack.DBZ.Piccolo` · Categoria: DBZ
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 3 MeshPart, 6 SpecialMesh, 5 MeshIds únicos · Texturas únicas: 4 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [NENHUM]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 41. Caulifa

- Caminho: `Anime Pack.DBZ.Caulifa` · Categoria: DBZ
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 2 MeshPart, 3 SpecialMesh, 2 MeshIds únicos · Texturas únicas: 1 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+11)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO]
- Problemas: 17 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 42. Trunks

- Caminho: `Anime Pack.DBZ.Trunks` · Categoria: DBZ
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 0 MeshPart, 5 SpecialMesh, 2 MeshIds únicos · Texturas únicas: 2 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: TrunksHairF
- Armas: SwordPack (pelo nome), Swordy (pelo nome), Swordy (pelo nome), Swordy (pelo nome)
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+9)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO]
- Problemas: 15 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 43. Vegeta

- Caminho: `Anime Pack.DBZ.Vegeta` · Categoria: DBZ
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 0 MeshPart, 3 SpecialMesh, 0 MeshIds únicos · Texturas únicas: 1 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [NENHUM]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 44. Buu Saga Goku

- Caminho: `Anime Pack.DBZ.Buu Saga Goku` · Categoria: DBZ
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 1 MeshPart, 5 SpecialMesh, 3 MeshIds únicos · Texturas únicas: 1 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+10)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO]
- Problemas: 16 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 45. Gohan

- Caminho: `Anime Pack.DBZ.Gohan` · Categoria: DBZ
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 2 MeshPart, 3 SpecialMesh, 2 MeshIds únicos · Texturas únicas: 1 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [NENHUM]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 46. Goku Black [NEW]

- Caminho: `Anime Pack.DBZ.Goku Black.Goku Black [NEW]` · Categoria: DBZ
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 0 MeshPart, 8 SpecialMesh, 0 MeshIds únicos · Texturas únicas: 1 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+26)
- Scripts: Animate [NENHUM], BattleScript [NENHUM]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 47. SSJR

- Caminho: `Anime Pack.DBZ.Goku Black.SSJR` · Categoria: DBZ
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 0 MeshPart, 9 SpecialMesh, 1 MeshIds únicos · Texturas únicas: 1 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: ParticleEmitter FinAura2, Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break (+10)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+26)
- Scripts: Animate [MÉDIO], BattleScript [MÉDIO]
- Problemas: 16 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 48. VEGITO

- Caminho: `Anime Pack.DBZ.Vegito.VEGITO` · Categoria: DBZ · Forma de: **vegito**
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 4 MeshPart, 3 SpecialMesh, 4 MeshIds únicos · Texturas únicas: 4 · Decals: 3 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+15)
- Scripts: Animate [MÉDIO], BattleScript [MÉDIO]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 49. VEGITO BLUE

- Caminho: `Anime Pack.DBZ.Vegito.VEGITO BLUE` · Categoria: DBZ · Forma de: **vegito**
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 4 MeshPart, 3 SpecialMesh, 4 MeshIds únicos · Texturas únicas: 4 · Decals: 3 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: ParticleEmitter SaiyanAura, Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break (+9)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+15)
- Scripts: Animate [MÉDIO], BattleScript [MÉDIO]
- Problemas: 15 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 50. LSSJ BROLY

- Caminho: `Anime Pack.DBZ.Broly.LSSJ BROLY` · Categoria: DBZ · Forma de: **broly**
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 0 MeshPart, 6 SpecialMesh, 3 MeshIds únicos · Texturas únicas: 2 · Decals: 3 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: ParticleEmitter SaiyanAura, ParticleEmitter SaiyanAura2, Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT (+10)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+15)
- Scripts: Animate [MÉDIO], BattleScript [MÉDIO]
- Problemas: 16 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 51. Broly

- Caminho: `Anime Pack.DBZ.Broly.Broly` · Categoria: DBZ · Forma de: **broly**
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 0 MeshPart, 5 SpecialMesh, 2 MeshIds únicos · Texturas únicas: 2 · Decals: 3 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [NENHUM]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 52. Krillin

- Caminho: `Anime Pack.DBZ.Krillin` · Categoria: DBZ
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 0 MeshPart, 3 SpecialMesh, 0 MeshIds únicos · Texturas únicas: 1 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+15)
- Scripts: Animate [MÉDIO], BattleScript [MÉDIO]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 53. Grimmjow

- Caminho: `Anime Pack.Bleach Pack.Grimmjow` · Categoria: Bleach Pack
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 10 MeshPart, 3 SpecialMesh, 8 MeshIds únicos · Texturas únicas: 4 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: Sword (pelo nome), FakeSword (pelo nome)
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 54. Kisuke

- Caminho: `Anime Pack.Bleach Pack.Kisuke` · Categoria: Bleach Pack
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 3 MeshPart, 4 SpecialMesh, 3 MeshIds únicos · Texturas únicas: 3 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: Blade (pelo nome)
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+10)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [NENHUM]
- Problemas: 16 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 55. Shunsui

- Caminho: `Anime Pack.Bleach Pack.Shunsui` · Categoria: Bleach Pack
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 11 MeshPart, 3 SpecialMesh, 7 MeshIds únicos · Texturas únicas: 4 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: LBlade (pelo nome), RBlade (pelo nome)
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 56. Byakuya

- Caminho: `Anime Pack.Bleach Pack.Byakuya` · Categoria: Bleach Pack
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 4 MeshPart, 3 SpecialMesh, 4 MeshIds únicos · Texturas únicas: 3 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: Blade (pelo nome), Sword (pelo nome)
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+11)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO]
- Problemas: 17 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 57. Shinji

- Caminho: `Anime Pack.Bleach Pack.Shinji` · Categoria: Bleach Pack
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 3 MeshPart, 7 SpecialMesh, 5 MeshIds únicos · Texturas únicas: 7 · Decals: 8 · SurfaceAppearance: 0
- Acessórios: —
- Armas: Sword (pelo nome)
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+10)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO]
- Problemas: 16 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 58. Gin

- Caminho: `Anime Pack.Bleach Pack.Gin` · Categoria: Bleach Pack
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 3 MeshPart, 4 SpecialMesh, 3 MeshIds únicos · Texturas únicas: 2 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: Blade (pelo nome), ExtendingBlade (pelo nome)
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 59. Yamamoto

- Caminho: `Anime Pack.Bleach Pack.Yamamoto` · Categoria: Bleach Pack
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 2 MeshPart, 3 SpecialMesh, 2 MeshIds únicos · Texturas únicas: 3 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: Sword (pelo nome)
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+13)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [NENHUM]
- Problemas: 19 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 60. Rukia

- Caminho: `Anime Pack.Bleach Pack.Rukia` · Categoria: Bleach Pack
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 3 MeshPart, 3 SpecialMesh, 3 MeshIds únicos · Texturas únicas: 3 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: Sword (pelo nome)
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+9)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [NENHUM]
- Problemas: 15 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 61. Starrk

- Caminho: `Anime Pack.Bleach Pack.Starrk` · Categoria: Bleach Pack
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 5 MeshPart, 3 SpecialMesh, 3 MeshIds únicos · Texturas únicas: 4 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: Sword (pelo nome), EnergySwordR (pelo nome), EnergySwordL (pelo nome)
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+11)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO]
- Problemas: 17 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 62. Ichigo

- Caminho: `Anime Pack.Bleach Pack.Ichigo` · Categoria: Bleach Pack · Forma de: **ichigo**
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 3 MeshPart, 3 SpecialMesh, 3 MeshIds únicos · Texturas únicas: 3 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: Sword (pelo nome)
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+9)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [NENHUM]
- Problemas: 15 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 63. Aizen

- Caminho: `Anime Pack.Bleach Pack.Aizen.Aizen` · Categoria: Bleach Pack · Forma de: **aizen**
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 2 MeshPart, 4 SpecialMesh, 2 MeshIds únicos · Texturas únicas: 3 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: Sword (pelo nome)
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+9)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [NENHUM]
- Problemas: 15 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 64. Final Aizen

- Caminho: `Anime Pack.Bleach Pack.Aizen.Final Aizen` · Categoria: Bleach Pack · Forma de: **aizen**
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 2 MeshPart, 4 SpecialMesh, 2 MeshIds únicos · Texturas únicas: 3 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: Sword (pelo nome)
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+9)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+15)
- Scripts: Animate [MÉDIO], BattleScript [MÉDIO]
- Problemas: 15 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 65. Mugetsu

- Caminho: `Anime Pack.Bleach Pack.Hollow Ichigo.Mugetsu` · Categoria: Bleach Pack
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 5 MeshPart, 4 SpecialMesh, 5 MeshIds únicos · Texturas únicas: 6 · Decals: 7 · SurfaceAppearance: 0
- Acessórios: —
- Armas: Sword (pelo nome)
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+10)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+15)
- Scripts: Animate [MÉDIO], BattleScript [MÉDIO]
- Problemas: 16 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 66. Hollow Ichigo

- Caminho: `Anime Pack.Bleach Pack.Hollow Ichigo.Hollow Ichigo` · Categoria: Bleach Pack · Forma de: **ichigo**
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 4 MeshPart, 4 SpecialMesh, 4 MeshIds únicos · Texturas únicas: 6 · Decals: 3 · SurfaceAppearance: 0
- Acessórios: —
- Armas: Sword (pelo nome)
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+9)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+15)
- Scripts: Animate [MÉDIO], BattleScript [MÉDIO]
- Problemas: 15 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 67. Vasto

- Caminho: `Anime Pack.Bleach Pack.Hollow Ichigo.Vasto` · Categoria: Bleach Pack
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 5 MeshPart, 4 SpecialMesh, 5 MeshIds únicos · Texturas únicas: 5 · Decals: 1 · SurfaceAppearance: 0
- Acessórios: —
- Armas: Sword (pelo nome)
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+15)
- Scripts: Animate [MÉDIO], BattleScript [MÉDIO]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 68. Neko Yoru

- Caminho: `Anime Pack.Bleach Pack.Yoruichi.Neko Yoru` · Categoria: Bleach Pack
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 1 MeshPart, 4 SpecialMesh, 1 MeshIds únicos · Texturas únicas: 2 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Beam Beam, Beam Beam, Beam Beam, Beam Beam, Beam Beam, Beam Beam (+21)
- Animações: Animation1 = 6734171516, Animation2 = 6734171516, WalkAnim = 6734147823, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+15)
- Scripts: Animate [MÉDIO], BattleScript [MÉDIO]
- Problemas: 27 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 69. Shunko Yoruichi

- Caminho: `Anime Pack.Bleach Pack.Yoruichi.Shunko Yoruichi` · Categoria: Bleach Pack
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 1 MeshPart, 4 SpecialMesh, 1 MeshIds únicos · Texturas únicas: 2 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+12)
- Animações: Animation1 = 6734171516, Animation2 = 6734171516, WalkAnim = 6734147823, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+15)
- Scripts: Animate [MÉDIO], BattleScript [MÉDIO]
- Problemas: 18 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 70. Yoruichi

- Caminho: `Anime Pack.Bleach Pack.Yoruichi.Yoruichi` · Categoria: Bleach Pack
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 1 MeshPart, 4 SpecialMesh, 1 MeshIds únicos · Texturas únicas: 2 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+15)
- Scripts: Animate [MÉDIO], BattleScript [MÉDIO]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 71. R1

- Caminho: `Anime Pack.Bleach Pack.Ulquiorra.R1` · Categoria: Bleach Pack · Forma de: **r**
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 5 MeshPart, 5 SpecialMesh, 5 MeshIds únicos · Texturas únicas: 5 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: Sword (pelo nome)
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+9)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+15)
- Scripts: Animate [MÉDIO], BattleScript [MÉDIO]
- Problemas: 15 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 72. R2

- Caminho: `Anime Pack.Bleach Pack.Ulquiorra.R2` · Categoria: Bleach Pack · Forma de: **r**
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 5 MeshPart, 6 SpecialMesh, 6 MeshIds únicos · Texturas únicas: 6 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: Sword (pelo nome)
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+9)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+15)
- Scripts: Animate [MÉDIO], BattleScript [MÉDIO]
- Problemas: 15 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 73. Ulq

- Caminho: `Anime Pack.Bleach Pack.Ulquiorra.Ulq` · Categoria: Bleach Pack
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 6 MeshPart, 4 SpecialMesh, 5 MeshIds únicos · Texturas únicas: 6 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: Swords (pelo nome), Swords (pelo nome), Swords (pelo nome), Sword (pelo nome)
- VFX: ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1 (+9)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+15)
- Scripts: Animate [MÉDIO], BattleScript [MÉDIO]
- Problemas: 15 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 74. Toshiro

- Caminho: `Anime Pack.Bleach Pack.Toshiro.Toshiro` · Categoria: Bleach Pack · Forma de: **toshiro**
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 5 MeshPart, 4 SpecialMesh, 5 MeshIds únicos · Texturas únicas: 6 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: Sword (pelo nome)
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+9)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+15)
- Scripts: Animate [MÉDIO], BattleScript [MÉDIO]
- Problemas: 15 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 75. Bankai Toshiro

- Caminho: `Anime Pack.Bleach Pack.Toshiro.Bankai Toshiro` · Categoria: Bleach Pack · Forma de: **toshiro**
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 10 · peças ancoradas: 0
- Malhas: 12 MeshPart, 4 SpecialMesh, 10 MeshIds únicos · Texturas únicas: 8 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: Sword (pelo nome)
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+11)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+15)
- Scripts: Animate [MÉDIO], BattleScript [MÉDIO]
- Problemas: 17 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 76. Gray

- Caminho: `Anime Pack.Fairy Tail.Gray` · Categoria: Fairy Tail
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 1 MeshPart, 4 SpecialMesh, 1 MeshIds únicos · Texturas únicas: 2 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+15)
- Scripts: Animate [MÉDIO], BattleScript [MÉDIO]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 77. Grey Awakening

- Caminho: `Anime Pack.Fairy Tail.Grey Awakening` · Categoria: Fairy Tail
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 1 MeshPart, 4 SpecialMesh, 1 MeshIds únicos · Texturas únicas: 3 · Decals: 8 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: ParticleEmitter dust, ParticleEmitter dust2, ParticleEmitter dust, ParticleEmitter dust2, Trail MoveT, ParticleEmitter dust (+22)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+15)
- Scripts: Animate [MÉDIO], BattleScript [MÉDIO]
- Problemas: 28 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 78. Natsu

- Caminho: `Anime Pack.Fairy Tail.Natsu` · Categoria: Fairy Tail · Forma de: **natsu**
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 2 MeshPart, 4 SpecialMesh, 2 MeshIds únicos · Texturas únicas: 3 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+15)
- Scripts: Animate [MÉDIO], BattleScript [MÉDIO]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 79. Natsu Awakened

- Caminho: `Anime Pack.Fairy Tail.Natsu Awakened` · Categoria: Fairy Tail · Forma de: **natsu**
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 2 MeshPart, 4 SpecialMesh, 2 MeshIds únicos · Texturas únicas: 3 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: ParticleEmitter SmallShoot, PointLight RyujinLight, ParticleEmitter Smoke, ParticleEmitter SmallShoot, ParticleEmitter Fire, ParticleEmitter ShootParticle (+25)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+15)
- Scripts: Animate [MÉDIO], BattleScript [MÉDIO]
- Problemas: 31 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 80. Sukuna

- Caminho: `Anime Pack.JJK.Sukuna` · Categoria: JJK
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 4 MeshPart, 4 SpecialMesh, 4 MeshIds únicos · Texturas únicas: 5 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+15)
- Scripts: Animate [NENHUM], BattleScript [NENHUM]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 81. Yuji

- Caminho: `Anime Pack.JJK.Yuji` · Categoria: JJK
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 3 MeshPart, 4 SpecialMesh, 3 MeshIds únicos · Texturas únicas: 4 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+15)
- Scripts: Animate [NENHUM], BattleScript [NENHUM]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 82. Gojo Satoru (Blindfold Off)

- Caminho: `Anime Pack.JJK.Gojo Satoru (Blindfold Off)` · Categoria: JJK
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 5 MeshPart, 4 SpecialMesh, 5 MeshIds únicos · Texturas únicas: 6 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1 (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 83. Gojo Satoru

- Caminho: `Anime Pack.JJK.Gojo Satoru` · Categoria: JJK
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 5 MeshPart, 4 SpecialMesh, 5 MeshIds únicos · Texturas únicas: 6 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: ParticleEmitter Break, ParticleEmitter Bubbles, ParticleEmitter Slider, ParticleEmitter Smoke, ParticleEmitter Hit2, ParticleEmitter Hit1 (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 84. Shanks

- Caminho: `Anime Pack.One Piece Pack.Shanks` · Categoria: One Piece Pack
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 10 MeshPart, 3 SpecialMesh, 3 MeshIds únicos · Texturas únicas: 3 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: SheathedBlade (pelo nome), BladeUnion (pelo nome), Blade (pelo nome), BladeUnion (pelo nome)
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 85. TS SANJI

- Caminho: `Anime Pack.One Piece Pack.TS SANJI` · Categoria: One Piece Pack
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 1 MeshPart, 3 SpecialMesh, 1 MeshIds únicos · Texturas únicas: 2 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+15)
- Scripts: Animate [MÉDIO], BattleScript [MÉDIO]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 86. Whitebeard

- Caminho: `Anime Pack.One Piece Pack.Whitebeard` · Categoria: One Piece Pack
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 5 MeshPart, 4 SpecialMesh, 5 MeshIds únicos · Texturas únicas: 6 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+9)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO]
- Problemas: 15 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 87. ptsLaw

- Caminho: `Anime Pack.One Piece Pack.ptsLaw` · Categoria: One Piece Pack
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 4 MeshPart, 3 SpecialMesh, 3 MeshIds únicos · Texturas únicas: 4 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: SwordDrawn1 (pelo nome), SwordHilt (pelo nome)
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+9)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO]
- Problemas: 15 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 88. ptsSanji

- Caminho: `Anime Pack.One Piece Pack.ptsSanji` · Categoria: One Piece Pack
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 1 MeshPart, 3 SpecialMesh, 1 MeshIds únicos · Texturas únicas: 2 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 89. ptsZoro

- Caminho: `Anime Pack.One Piece Pack.ptsZoro` · Categoria: One Piece Pack
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 10 MeshPart, 3 SpecialMesh, 7 MeshIds únicos · Texturas únicas: 8 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+11)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO]
- Problemas: 17 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 90. Ace

- Caminho: `Anime Pack.One Piece Pack.Ace` · Categoria: One Piece Pack
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 4 MeshPart, 3 SpecialMesh, 4 MeshIds únicos · Texturas únicas: 3 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: Pistol (pelo nome)
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 91. Akainu

- Caminho: `Anime Pack.One Piece Pack.Akainu` · Categoria: One Piece Pack
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 16 MeshPart, 3 SpecialMesh, 7 MeshIds únicos · Texturas únicas: 4 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+15)
- Scripts: Animate [MÉDIO], BattleScript [MÉDIO]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 92. Kizaru

- Caminho: `Anime Pack.One Piece Pack.Kizaru` · Categoria: One Piece Pack
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 10 MeshPart, 3 SpecialMesh, 7 MeshIds únicos · Texturas únicas: 6 · Decals: 10 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+15)
- Scripts: Animate [MÉDIO], BattleScript [MÉDIO]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 93. tsZoro

- Caminho: `Anime Pack.One Piece Pack.tsZoro` · Categoria: One Piece Pack
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 10 MeshPart, 3 SpecialMesh, 7 MeshIds únicos · Texturas únicas: 7 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+11)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO]
- Problemas: 17 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 94. ptsLuffy

- Caminho: `Anime Pack.One Piece Pack.ptsLuffy` · Categoria: One Piece Pack
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 1 MeshPart, 3 SpecialMesh, 1 MeshIds únicos · Texturas únicas: 4 · Decals: 12 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 95. Snakeman

- Caminho: `Anime Pack.One Piece Pack.TS Luffy.Snakeman` · Categoria: One Piece Pack
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 1 MeshPart, 3 SpecialMesh, 1 MeshIds únicos · Texturas únicas: 2 · Decals: 8 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+15)
- Scripts: Animate [NENHUM], BattleScript [NENHUM]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 96. tsLuffy

- Caminho: `Anime Pack.One Piece Pack.TS Luffy.tsLuffy` · Categoria: One Piece Pack
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 2 MeshPart, 3 SpecialMesh, 2 MeshIds únicos · Texturas únicas: 4 · Decals: 12 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 97. Jonathan

- Caminho: `Anime Pack.JOJO.Jonathan` · Categoria: JOJO
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 2 MeshPart, 3 SpecialMesh, 2 MeshIds únicos · Texturas únicas: 1 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: Sword (pelo nome)
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+13)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO]
- Problemas: 19 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 98. Josuke

- Caminho: `Anime Pack.JOJO.Josuke.Josuke` · Categoria: JOJO
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 14 MeshPart, 3 SpecialMesh, 14 MeshIds únicos · Texturas únicas: 2 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO], LocalStand [MÉDIO]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 99. Giorno

- Caminho: `Anime Pack.JOJO.Giorno.Giorno` · Categoria: JOJO · Forma de: **giorno**
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 18 MeshPart, 3 SpecialMesh, 18 MeshIds únicos · Texturas únicas: 4 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO], LocalStand [MÉDIO]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 100. GER

- Caminho: `Anime Pack.JOJO.Giorno (BUT BOSS).GER` · Categoria: JOJO
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 28 MeshPart, 17 SpecialMesh, 18 MeshIds únicos · Texturas únicas: 1 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: ParticleEmitter Giorno Giovanna, ParticleEmitter Giorno Giovanna, ParticleEmitter Giorno Giovanna, ParticleEmitter Giorno Giovanna, ParticleEmitter Giorno Giovanna, ParticleEmitter Giorno Giovanna (+2)
- Animações: Idle = 180435571
- Scripts: —
- Problemas: 8 efeitos de VFX: precisa de LOD/ReducedEffects
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 101. Giorno

- Caminho: `Anime Pack.JOJO.Giorno (BUT BOSS).Giorno` · Categoria: JOJO · Forma de: **giorno**
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 18 MeshPart, 3 SpecialMesh, 18 MeshIds únicos · Texturas únicas: 4 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO], LocalStand [MÉDIO]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 102. Jotaro

- Caminho: `Anime Pack.JOJO.Jotaro.Model.Jotaro` · Categoria: JOJO
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 19 MeshPart, 3 SpecialMesh, 19 MeshIds únicos · Texturas únicas: 2 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO], LocalStand [MÉDIO]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 103. Old Joseph

- Caminho: `Anime Pack.JOJO.Old Joseph` · Categoria: JOJO · Forma de: **joseph**
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 0 MeshPart, 6 SpecialMesh, 3 MeshIds únicos · Texturas únicas: 2 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+18)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO]
- Problemas: 24 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 104. Young Joseph

- Caminho: `Anime Pack.JOJO.Young Joseph` · Categoria: JOJO · Forma de: **joseph**
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 3 MeshPart, 3 SpecialMesh, 3 MeshIds únicos · Texturas únicas: 2 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 105. Kira Yoshikage

- Caminho: `Anime Pack.JOJO.Kira Yoshikage.Kira Yoshikage` · Categoria: JOJO
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 9 MeshPart, 3 SpecialMesh, 9 MeshIds únicos · Texturas únicas: 2 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+16)
- Scripts: Animate [MÉDIO], BattleScript [MÉDIO], LocalStand [MÉDIO]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 3 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 106. Killer Queen

- Caminho: `Anime Pack.JOJO.Kira Yoshikage.Killer Queen` · Categoria: JOJO
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 1
- Malhas: 22 MeshPart, 3 SpecialMesh, 22 MeshIds únicos · Texturas únicas: 2 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: ParticleEmitter Kira Yoshikage, ParticleEmitter Kira Yoshikage, ParticleEmitter Kira Yoshikage, ParticleEmitter Kira Yoshikage, ParticleEmitter Kira Yoshikage, ParticleEmitter Kira Yoshikage (+3)
- Animações: Idle = 180435571
- Scripts: —
- Problemas: 9 efeitos de VFX: precisa de LOD/ReducedEffects
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 107. Morph

- Caminho: `Anime Pack.JOJO.DIO.TW.Morph` · Categoria: JOJO · Forma de: **morph**
- Rig: custom (RigType Enum.HumanoidRigType.R6) · Humanoid: sim · AnimationController: não · Motor6D: 0 · peças ancoradas: 0
- Malhas: 3 MeshPart, 1 SpecialMesh, 3 MeshIds únicos · Texturas únicas: 1 · Decals: 1 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: —
- Animações: —
- Scripts: —
- Problemas: sem HumanoidRootPart (precisa de âncora para posicionar no pedestal), rig sem Motor6D (estático; não anima)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 108. DIO

- Caminho: `Anime Pack.JOJO.DIO.DIO` · Categoria: JOJO · Forma de: **dio**
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 2 MeshPart, 11 SpecialMesh, 2 MeshIds únicos · Texturas únicas: 3 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [NENHUM], LocalStand [NENHUM]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 109. DIO AWAKENED

- Caminho: `Anime Pack.JOJO.DIO.DIO AWAKENED` · Categoria: JOJO · Forma de: **dio**
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 1
- Malhas: 1 MeshPart, 2 SpecialMesh, 1 MeshIds únicos · Texturas únicas: 2 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: ParticleEmitter Aura, ParticleEmitter Aura, Trail MoveT, ParticleEmitter Aura, Trail MoveT, ParticleEmitter Aura (+16)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+16)
- Scripts: Animate [NENHUM], BattleScript [NENHUM], LocalStand [NENHUM]
- Problemas: 22 efeitos de VFX: precisa de LOD/ReducedEffects, 3 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 110. Morph

- Caminho: `Anime Pack.JOJO.DIO.TW AURA.Morph` · Categoria: JOJO · Forma de: **morph**
- Rig: custom (RigType Enum.HumanoidRigType.R6) · Humanoid: sim · AnimationController: não · Motor6D: 0 · peças ancoradas: 0
- Malhas: 3 MeshPart, 1 SpecialMesh, 3 MeshIds únicos · Texturas únicas: 1 · Decals: 1 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: ParticleEmitter Stand Aura
- Animações: —
- Scripts: —
- Problemas: sem HumanoidRootPart (precisa de âncora para posicionar no pedestal), rig sem Motor6D (estático; não anima)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 111. Doppio

- Caminho: `Anime Pack.JOJO.Doppio/Diavolo.Doppio` · Categoria: JOJO
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 14 MeshPart, 3 SpecialMesh, 4 MeshIds únicos · Texturas únicas: 2 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+10)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [NENHUM], LocalStand [NENHUM]
- Problemas: 16 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 112. KC AURA

- Caminho: `Anime Pack.JOJO.Doppio/Diavolo.KC AURA` · Categoria: JOJO
- Rig: R6 · Humanoid: não · AnimationController: não · Motor6D: 8 · peças ancoradas: 1
- Malhas: 26 MeshPart, 2 SpecialMesh, 11 MeshIds únicos · Texturas únicas: 2 · Decals: 3 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail Trail, Trail Trail, ParticleEmitter Stand Aura, ParticleEmitter Stand Aura, ParticleEmitter Stand Aura, ParticleEmitter Stand Aura (+3)
- Animações: —
- Scripts: —
- Problemas: 9 efeitos de VFX: precisa de LOD/ReducedEffects
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 113. STONE FREE AURA

- Caminho: `Anime Pack.JOJO.Jolyne.STONE FREE AURA` · Categoria: JOJO
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 1
- Malhas: 24 MeshPart, 2 SpecialMesh, 24 MeshIds únicos · Texturas únicas: 3 · Decals: 3 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: ParticleEmitter JOLYNE KUJO, ParticleEmitter JOLYNE KUJO, ParticleEmitter JOLYNE KUJO, ParticleEmitter JOLYNE KUJO, ParticleEmitter JOLYNE KUJO, ParticleEmitter JOLYNE KUJO (+3)
- Animações: Idle = 180435571
- Scripts: —
- Problemas: 9 efeitos de VFX: precisa de LOD/ReducedEffects
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 114. Jolyne

- Caminho: `Anime Pack.JOJO.Jolyne.Jolyne.Jolyne` · Categoria: JOJO · Forma de: **jolyne**
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 13 MeshPart, 4 SpecialMesh, 13 MeshIds únicos · Texturas únicas: 2 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+16)
- Scripts: Animate [NENHUM], BattleScript [NENHUM], LocalStand [NENHUM]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 3 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 115. STONE FREE

- Caminho: `Anime Pack.JOJO.Jolyne.STONE FREE` · Categoria: JOJO
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 1
- Malhas: 24 MeshPart, 2 SpecialMesh, 24 MeshIds únicos · Texturas únicas: 3 · Decals: 3 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: —
- Animações: Idle = 180435571
- Scripts: —
- Problemas: nenhum
- Compatibilidade com Roll Legends: **ALTA**

### 116. Awakened Jolyne

- Caminho: `Anime Pack.JOJO.Jolyne.Awakened Jolyne` · Categoria: JOJO · Forma de: **jolyne**
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 13 MeshPart, 4 SpecialMesh, 13 MeshIds únicos · Texturas únicas: 2 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: ParticleEmitter Aura, ParticleEmitter Aura, Trail MoveT, ParticleEmitter Aura, Trail MoveT, ParticleEmitter Aura (+16)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+16)
- Scripts: Animate [NENHUM], BattleScript [NENHUM], LocalStand [NENHUM]
- Problemas: 22 efeitos de VFX: precisa de LOD/ReducedEffects, 3 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 117. Enrico

- Caminho: `Anime Pack.JOJO.Enrico` · Categoria: JOJO
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 12 · peças ancoradas: 2
- Malhas: 22 MeshPart, 3 SpecialMesh, 13 MeshIds únicos · Texturas únicas: 6 · Decals: 15 · SurfaceAppearance: 1
- Acessórios: —
- Armas: —
- VFX: ParticleEmitter ParticleEmitter, ParticleEmitter ParticleEmitter, ParticleEmitter ParticleEmitter, ParticleEmitter ParticleEmitter, ParticleEmitter ParticleEmitter, ParticleEmitter ParticleEmitter (+1)
- Animações: —
- Scripts: —
- Problemas: 7 efeitos de VFX: precisa de LOD/ReducedEffects
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 118. Lemillion

- Caminho: `Anime Pack.My Hero Academia Pack.Lemillion` · Categoria: My Hero Academia Pack
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 4 MeshPart, 3 SpecialMesh, 4 MeshIds únicos · Texturas únicas: 4 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: ParticleEmitter SweatParticle, Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break (+9)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO]
- Problemas: 15 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 119. Speed Guy

- Caminho: `Anime Pack.My Hero Academia Pack.Speed Guy` · Categoria: My Hero Academia Pack
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 2 MeshPart, 178 SpecialMesh, 2 MeshIds únicos · Texturas únicas: 2 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: ParticleEmitter SweatParticle, Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break (+45)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO]
- Problemas: 220 peças: pesado para 400 personagens na tela, 51 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 120. Hellflame

- Caminho: `Anime Pack.My Hero Academia Pack.Hellflame` · Categoria: My Hero Academia Pack
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 10 MeshPart, 4 SpecialMesh, 10 MeshIds únicos · Texturas únicas: 4 · Decals: 3 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: ParticleEmitter SweatParticle, Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break (+22)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO]
- Problemas: 28 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 121. Todoroki

- Caminho: `Anime Pack.My Hero Academia Pack.Todoroki` · Categoria: My Hero Academia Pack
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 1 MeshPart, 3 SpecialMesh, 1 MeshIds únicos · Texturas únicas: 2 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: ParticleEmitter SweatParticle, Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break (+12)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO]
- Problemas: 18 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 122. Deku Awakened

- Caminho: `Anime Pack.My Hero Academia Pack.Deku Awakened` · Categoria: My Hero Academia Pack · Forma de: **deku**
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 2 MeshPart, 3 SpecialMesh, 2 MeshIds únicos · Texturas únicas: 2 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: ParticleEmitter ShootParticle, ParticleEmitter ShootParticle, Trail MoveT, ParticleEmitter ShootParticle, Trail MoveT, ParticleEmitter ShootParticle (+17)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+15)
- Scripts: Animate [NENHUM], BattleScript [NENHUM]
- Problemas: 23 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 123. All Might

- Caminho: `Anime Pack.My Hero Academia Pack.All Might` · Categoria: My Hero Academia Pack · Forma de: **all might**
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 1 MeshPart, 3 SpecialMesh, 1 MeshIds únicos · Texturas únicas: 2 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+15)
- Scripts: Animate [NENHUM], BattleScript [NENHUM]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 124. All Might (MODE)

- Caminho: `Anime Pack.My Hero Academia Pack.All Might (MODE)` · Categoria: My Hero Academia Pack · Forma de: **all might**
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 2 MeshPart, 3 SpecialMesh, 2 MeshIds únicos · Texturas únicas: 2 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+15)
- Scripts: Animate [NENHUM], BattleScript [NENHUM]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 125. Awakened Bakugo

- Caminho: `Anime Pack.My Hero Academia Pack.Awakened Bakugo` · Categoria: My Hero Academia Pack · Forma de: **bakugo**
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 1 MeshPart, 3 SpecialMesh, 1 MeshIds únicos · Texturas únicas: 1 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, ParticleEmitter Sparky, Trail MoveT, ParticleEmitter Sparky, Trail MoveT, Trail MoveT (+10)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+15)
- Scripts: Animate [NENHUM], BattleScript [NENHUM]
- Problemas: 16 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 126. Bakugo

- Caminho: `Anime Pack.My Hero Academia Pack.Bakugo` · Categoria: My Hero Academia Pack · Forma de: **bakugo**
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 1 MeshPart, 3 SpecialMesh, 1 MeshIds únicos · Texturas únicas: 1 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+15)
- Scripts: Animate [NENHUM], BattleScript [NENHUM]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 127. Deku

- Caminho: `Anime Pack.My Hero Academia Pack.Deku` · Categoria: My Hero Academia Pack · Forma de: **deku**
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 2 MeshPart, 3 SpecialMesh, 2 MeshIds únicos · Texturas únicas: 2 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+11)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+15)
- Scripts: Animate [NENHUM], BattleScript [NENHUM]
- Problemas: 17 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 128. 100% Deku

- Caminho: `Anime Pack.My Hero Academia Pack.100% Deku` · Categoria: My Hero Academia Pack
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 3 MeshPart, 5 SpecialMesh, 3 MeshIds únicos · Texturas únicas: 3 · Decals: 3 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: ParticleEmitter SmallShoot, ParticleEmitter ShootParticle, ParticleEmitter SmallShoot, Trail MoveT, ParticleEmitter SmallShoot, Trail MoveT (+17)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+15)
- Scripts: Animate [NENHUM], BattleScript [NENHUM]
- Problemas: 23 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 129. Adult Gon

- Caminho: `Anime Pack.HXH.Adult Gon` · Categoria: HXH · Forma de: **gon**
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 1 MeshPart, 3 SpecialMesh, 1 MeshIds únicos · Texturas únicas: 1 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+11)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+15)
- Scripts: Animate [MÉDIO], BattleScript [MÉDIO]
- Problemas: 17 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 130. Killua Godspeed

- Caminho: `Anime Pack.HXH.Killua Godspeed` · Categoria: HXH
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 2 MeshPart, 3 SpecialMesh, 2 MeshIds únicos · Texturas únicas: 3 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: ParticleEmitter Lightning, ParticleEmitter Reiatsu, ParticleEmitter Lightning, ParticleEmitter Reiatsu, Trail MoveT, ParticleEmitter Lightning (+24)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+15)
- Scripts: Animate [MÉDIO], BattleScript [MÉDIO]
- Problemas: 30 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 131. Hisoka

- Caminho: `Anime Pack.HXH.Hisoka` · Categoria: HXH · Forma de: **hisoka**
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 1 MeshPart, 3 SpecialMesh, 1 MeshIds únicos · Texturas únicas: 1 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 132. Illumi Awakened

- Caminho: `Anime Pack.HXH.Illumi Awakened` · Categoria: HXH · Forma de: **illumi**
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 1
- Malhas: 1 MeshPart, 6 SpecialMesh, 2 MeshIds únicos · Texturas únicas: 2 · Decals: 4 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Beam Beam, Beam Beam, Beam Beam, Beam Beam, Beam Beam, Beam Beam (+25)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+15)
- Scripts: Animate [MÉDIO], BattleScript [MÉDIO]
- Problemas: 31 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 133. Illumi

- Caminho: `Anime Pack.HXH.Illumi` · Categoria: HXH · Forma de: **illumi**
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 1 MeshPart, 4 SpecialMesh, 1 MeshIds únicos · Texturas únicas: 1 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 134. Killua

- Caminho: `Anime Pack.HXH.Killua` · Categoria: HXH
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 1 MeshPart, 3 SpecialMesh, 1 MeshIds únicos · Texturas únicas: 2 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 135. Gon

- Caminho: `Anime Pack.HXH.Gon` · Categoria: HXH · Forma de: **gon**
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 1 MeshPart, 3 SpecialMesh, 1 MeshIds únicos · Texturas únicas: 1 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 136. Hisoka

- Caminho: `Anime Pack.HXH.Hisoka` · Categoria: HXH · Forma de: **hisoka**
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 1 MeshPart, 3 SpecialMesh, 1 MeshIds únicos · Texturas únicas: 1 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: ParticleEmitter Aura, Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break (+9)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+15)
- Scripts: Animate [MÉDIO], BattleScript [MÉDIO]
- Problemas: 15 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 137. Hiei

- Caminho: `Anime Pack.YYH.Hiei` · Categoria: YYH
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 9 MeshPart, 4 SpecialMesh, 8 MeshIds únicos · Texturas únicas: 5 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: Blade (pelo nome), Blade2 (pelo nome)
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 138. Yusuke

- Caminho: `Anime Pack.YYH.Yusuke` · Categoria: YYH · Forma de: **yusuke**
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 1 MeshPart, 3 SpecialMesh, 1 MeshIds únicos · Texturas únicas: 1 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 139. Yusuke Mode

- Caminho: `Anime Pack.YYH.Yusuke Mode` · Categoria: YYH · Forma de: **yusuke**
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 1 MeshPart, 4 SpecialMesh, 2 MeshIds únicos · Texturas únicas: 2 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+10)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+15)
- Scripts: Animate [NENHUM], BattleScript [NENHUM]
- Problemas: 16 efeitos de VFX: precisa de LOD/ReducedEffects, 2 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 140. Hiei (Jagan Eye)

- Caminho: `Anime Pack.YYH.Hiei (Jagan Eye)` · Categoria: YYH
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 8 · peças ancoradas: 0
- Malhas: 9 MeshPart, 4 SpecialMesh, 8 MeshIds únicos · Texturas únicas: 5 · Decals: 2 · SurfaceAppearance: 0
- Acessórios: —
- Armas: Blade (pelo nome), Blade2 (pelo nome)
- VFX: Trail MoveT, Trail MoveT, Trail MoveT, Trail MoveT, ParticleEmitter Break, ParticleEmitter Bubbles (+8)
- Animações: Animation1 = 180435571, Animation2 = 180435792, WalkAnim = 180426354, RunAnim = 180426354, JumpAnim = 125750702, ClimbAnim = 180436334 (+3)
- Scripts: Animate [MÉDIO]
- Problemas: 14 efeitos de VFX: precisa de LOD/ReducedEffects, 1 script(s) de terceiros (remover)
- Compatibilidade com Roll Legends: **MÉDIA (corrigir: ver problemas)**

### 141. Eren

- Caminho: `Anime Pack.AOT.Eren` · Categoria: AOT
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 6 · peças ancoradas: 1
- Malhas: 0 MeshPart, 2 SpecialMesh, 1 MeshIds únicos · Texturas únicas: 2 · Decals: 1 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: —
- Animações: —
- Scripts: —
- Problemas: nenhum
- Compatibilidade com Roll Legends: **ALTA**

### 142. Attack Titan

- Caminho: `Anime Pack.AOT.Attack Titan` · Categoria: AOT
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 6 · peças ancoradas: 1
- Malhas: 0 MeshPart, 3 SpecialMesh, 2 MeshIds únicos · Texturas únicas: 2 · Decals: 1 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: —
- Animações: —
- Scripts: —
- Problemas: nenhum
- Compatibilidade com Roll Legends: **ALTA**

### 143. Eren Post-time skip

- Caminho: `Anime Pack.AOT.Eren Post-time skip` · Categoria: AOT
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 6 · peças ancoradas: 1
- Malhas: 0 MeshPart, 2 SpecialMesh, 1 MeshIds únicos · Texturas únicas: 2 · Decals: 1 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: —
- Animações: —
- Scripts: —
- Problemas: nenhum
- Compatibilidade com Roll Legends: **ALTA**

### 144. Mikasa (Formal)

- Caminho: `Anime Pack.AOT.Mikasa (Formal)` · Categoria: AOT
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 6 · peças ancoradas: 1
- Malhas: 0 MeshPart, 3 SpecialMesh, 2 MeshIds únicos · Texturas únicas: 2 · Decals: 1 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: —
- Animações: —
- Scripts: —
- Problemas: nenhum
- Compatibilidade com Roll Legends: **ALTA**

### 145. Mikasa

- Caminho: `Anime Pack.AOT.Mikasa` · Categoria: AOT
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 6 · peças ancoradas: 1
- Malhas: 0 MeshPart, 3 SpecialMesh, 2 MeshIds únicos · Texturas únicas: 2 · Decals: 1 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: —
- Animações: —
- Scripts: —
- Problemas: nenhum
- Compatibilidade com Roll Legends: **ALTA**

### 146. Female Titan

- Caminho: `Anime Pack.AOT.Female Titan` · Categoria: AOT
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 6 · peças ancoradas: 1
- Malhas: 0 MeshPart, 2 SpecialMesh, 1 MeshIds únicos · Texturas únicas: 2 · Decals: 1 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: —
- Animações: —
- Scripts: —
- Problemas: nenhum
- Compatibilidade com Roll Legends: **ALTA**

### 147. Annie (Junior High)

- Caminho: `Anime Pack.AOT.Annie (Junior High)` · Categoria: AOT
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 6 · peças ancoradas: 1
- Malhas: 0 MeshPart, 2 SpecialMesh, 1 MeshIds únicos · Texturas únicas: 2 · Decals: 1 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: —
- Animações: —
- Scripts: —
- Problemas: nenhum
- Compatibilidade com Roll Legends: **ALTA**

### 148. Annie

- Caminho: `Anime Pack.AOT.Annie` · Categoria: AOT
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 6 · peças ancoradas: 1
- Malhas: 0 MeshPart, 2 SpecialMesh, 1 MeshIds únicos · Texturas únicas: 2 · Decals: 1 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: —
- Animações: —
- Scripts: —
- Problemas: nenhum
- Compatibilidade com Roll Legends: **ALTA**

### 149. Erwin (Alt)

- Caminho: `Anime Pack.AOT.Erwin (Alt)` · Categoria: AOT · Forma de: **erwin**
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 6 · peças ancoradas: 1
- Malhas: 0 MeshPart, 2 SpecialMesh, 1 MeshIds únicos · Texturas únicas: 2 · Decals: 1 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: —
- Animações: —
- Scripts: —
- Problemas: nenhum
- Compatibilidade com Roll Legends: **ALTA**

### 150. Erwin

- Caminho: `Anime Pack.AOT.Erwin` · Categoria: AOT · Forma de: **erwin**
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 6 · peças ancoradas: 1
- Malhas: 0 MeshPart, 3 SpecialMesh, 2 MeshIds únicos · Texturas únicas: 2 · Decals: 1 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: —
- Animações: —
- Scripts: —
- Problemas: nenhum
- Compatibilidade com Roll Legends: **ALTA**

### 151. Sasha (Suit)

- Caminho: `Anime Pack.AOT.Sasha (Suit)` · Categoria: AOT
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 6 · peças ancoradas: 1
- Malhas: 0 MeshPart, 2 SpecialMesh, 1 MeshIds únicos · Texturas únicas: 2 · Decals: 1 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: —
- Animações: —
- Scripts: —
- Problemas: nenhum
- Compatibilidade com Roll Legends: **ALTA**

### 152. Sasha

- Caminho: `Anime Pack.AOT.Sasha` · Categoria: AOT
- Rig: R6 · Humanoid: sim · AnimationController: não · Motor6D: 6 · peças ancoradas: 1
- Malhas: 0 MeshPart, 2 SpecialMesh, 1 MeshIds únicos · Texturas únicas: 2 · Decals: 1 · SurfaceAppearance: 0
- Acessórios: —
- Armas: —
- VFX: —
- Animações: —
- Scripts: —
- Problemas: nenhum
- Compatibilidade com Roll Legends: **ALTA**

## 3. Sugestão visual de raridade (heurística — NÃO altera o balanceamento)

Ordenado pela nota de qualidade; as cotas repetem o roster atual (5/4/4/3/3/2/2/1 = 24).

| Raridade sugerida | Modelo | Nota |
|---|---|---:|
| Secret | Bankai Toshiro | 80 |
| Divine | Enrico | 78 |
| Divine | Afro Samurai | 73 |
| Mythic | Giorno | 67 |
| Mythic | Giorno | 67 |
| Legendary | Hellflame | 67 |
| Legendary | ptsZoro | 66 |
| Legendary | tsZoro | 66 |
| Epic | Iskandar | 65 |
| Epic | SALTER | 65 |
| Epic | Kizaru | 64 |
| Rare | Mugetsu | 63 |
| Rare | Toshiro | 63 |
| Rare | Hiei | 62 |
| Rare | Hiei (Jagan Eye) | 62 |
| Uncommon | Archer (EMIYA) | 59 |
| Uncommon | Grimmjow | 59 |
| Uncommon | R2 | 59 |
| Uncommon | Shirou | 59 |
| Common | Akainu | 58 |
| Common | Shinji | 58 |
| Common | Whitebeard | 58 |
| Common | STONE FREE AURA | 57 |
| Common | Shunsui | 56 |
