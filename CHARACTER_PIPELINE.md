# CHARACTER PIPELINE — Roll Legends (fase PILOTO)

Como um modelo visual do **Anime Pack** vira um personagem seguro e independente do Roll Legends.
Nesta fase só **10 pilotos** passam pelo pipeline. A integração em lote (121) só depois da
validação visual no Studio.

```
SOURCE MODEL   Workspace.Anime Pack / third_party/AnimePack.rbxm   (só desenvolvimento)
     │  python tools/build_characters.py   (Lune, nada do pack é executado)
     ▼
SANITIZATION   CharacterAssetPipeline.sanitize  (clone → remove tudo que não é visual)
     ▼
VALIDATION     CharacterAssetPipeline.validate  (ferramenta E runtime)
     ▼
CHARACTER ASSET  assets/Characters.rbxm → ReplicatedStorage.CharacterAssets.<CharacterId>
     ▼
CharacterModelFactory.build / spawn / pose   ← ÚNICA fonte do visual
     ▼
Base (estações) · Roll Reveal · Mochila · Índice · Hero Landing · Galeria DEV
(Fusão, Torres, Trocas e o save só usam o CharacterId)
```

## Arquivos

| Arquivo | Papel |
|---|---|
| `src/shared/Config/CharacterConfig.luau` | Metadados de jogo. `List` = roster do roll/Índice (24, intocado). `Pilots` + `ById` = pilotos com `DisplayName`, `SourceModelName`, `CharacterFamily`, `FormTier`, `SourceCategory`, `DefaultDice`, `TechnicalStatus`, stats. |
| `src/shared/Config/CharacterAssetConfig.luau` | Regras do pipeline (classes proibidas/permitidas, VFX genéricos, limites, normalização, modos de VFX) e `Assets[CharacterId]` = `SourcePath`, whitelist de VFX, `VisualScale`/`VisualOffset` (ajustes centralizados). |
| `src/shared/Modules/CharacterAssetPipeline.luau` | `sanitize`, `validate`, `scale`, `buildAll`, `buildInStudio`. |
| `src/shared/Modules/CharacterModelFactory.luau` | `build`, `spawn`, `pose`, `lerpPose`, `template`, `hasAsset`, `height`. Asset → senão placeholder. |
| `src/shared/Modules/VariantVisualModifier.luau` | Variantes sobre o mesmo modelo base. |
| `tools/build_characters.py` + `tools/characters/build_characters.luau` | Gera `assets/Characters.rbxm` + `CHARACTER_PILOT_AUDIT.md` + `third_party/character_pilot_report.json`. |
| `tools/packaudit/rbxm_reader.py` | `strip_properties`: cópia binária sem a propriedade que o Lune recusa (ex.: `Accessory.Tags`). |

## Chaves (sem rename destrutivo)

- **CharacterId** (`char_<família>_<forma>`): chave estável do save, configs e referências. Nunca muda.
- **DisplayName**: nome exibido (`CharacterConfig.Name` = `DisplayName`). Pode mudar sem migração.
- **SourceModelName**: nome no pack; só ferramentas/relatórios. O jogo nunca usa.
- O inventário guarda só `{ Id = CharacterId, Variant, Level, ... }` — nenhuma Instance vai para o save.
- Os 24 originais continuam com os mesmos ids (nada foi renomeado).

## Sanitização (o que entra e o que sai)

Tudo acontece num **clone**; o pack original nunca é alterado.

- **Sai sempre:** Script, LocalScript, ModuleScript, RemoteEvent/RemoteFunction, BindableEvent/
  BindableFunction, Sound, Animation, Animator, AnimationController, KeyframeSequence, Tool,
  BillboardGui/SurfaceGui, ProximityPrompt, ClickDetector, BodyMover, Constraint, valores de
  estado (ValueBase), Configuration, ForceField, e qualquer instância chamada `LocalStand`,
  `BattleScript` ou `Animate`. Também a `HumanoidRootPart`, hitboxes invisíveis e pastas vazias.
- **Fica (só o visual):** Part, MeshPart, WedgePart, UnionOperation, SpecialMesh/BlockMesh/
  CylinderMesh, Decal, Texture, SurfaceAppearance, Shirt, Pants, ShirtGraphic, BodyColors,
  Attachment. `Accessory` vira `Model` (o Humanoid não tenta soldar nada de novo).
- **Humanoid:** só fica se houver roupa (Shirt/Pants só aparecem com Humanoid). Fica inerte:
  sem filhos (sem Animator), `EvaluateStateMachine = false`, sem nome/vida, `RequiresNeck = false`.
- **Soldas assadas:** Motor6D/Weld/ManualWeld/Snap/WeldConstraint são lidos para descobrir em
  qual **osso** R6 cada peça está (cabelo → Head, espada → RightArm, espada das costas/capa →
  Torso...) e depois removidos. O atributo `Bone` guarda o osso. Peça sem junta: osso mais
  próximo + AVISO no relatório.
- **Física:** tudo `Anchored`, `CanCollide/CanTouch/CanQuery = false`, `Massless`. Arma não tem hitbox.

## VFX (controlado pelo Roll Legends)

- Os efeitos genéricos do jogo de origem (`MoveT`, `Break`, `Bubbles`, `Slider`, `Smoke`,
  `Hit1/2`, `Block`, `SoruP`, `LevelParticle`, `SenzuEat`) **nunca** entram.
- Só ficam efeitos PRÓPRIOS listados em `Assets[id].VFX.Full`; `VFX.Light` marca os leves.
  Limites: 6 efeitos guardados, 2 ativos no modo Light, 1 luz, taxa máxima 12/s por emissor.
- `VFXMode`: **None** (Mochila, Índice) · **Light** (Base, Torres) · **Full** (Reveal, Hero
  Landing, Galeria). "Efeitos reduzidos"/distância (LodController) desligam os efeitos marcados
  com `VFXTier` na base, como já fazia com a aura.
- ViewportFrames (Reveal/Mochila/Índice/Hero Landing) não renderizam partículas: a cinemática
  continua com os efeitos próprios dela.

## Normalização de tamanho (regra única)

1. Mede o **corpo**: do fundo das pernas ao topo da peça `Head` (sem cabelo, chapéu, arma, capa).
2. O pipeline escala o modelo para corpo = **5 studs** (R6 padrão). Assim um rig 1,4× maior
   e um 0,9× menor chegam ao mesmo corpo; cabelo grande continua grande (silhueta preservada).
3. Em jogo: `1,25 × ModelScale da raridade × VisualScale` — igual ao placeholder (corpo de
   ~6,25 no Comum a ~8,5 no Secreto).
4. Caixa total acima de 10 × 9 × 10 (unidades com corpo = 5) → AVISO no relatório (nada é
   cortado). Ajuste fino só em `CharacterAssetConfig.Assets[id].VisualScale` (0,85–1,2).

## Pivô

- `PivotRoot` (peça invisível de 0,2) = `PrimaryPart` = centro dos pés, olhando para **-Z**.
- `CharacterModelFactory.spawn(id, alvo)` = `build` + `PivotTo(alvo)`: pés na superfície,
  centralizado, virado para o `LookVector` do alvo. Os slots da base NÃO mudaram.
- Ajuste individual (se precisar): `Assets[id].VisualOffset = {x, y, z}` — nunca no código.

## Poses (próprias, sem animação do pack)

`R6Poses`: **Idle** (base/inventário/índice), **Reveal** (braço erguido), **Combat**
(card/torres), **Crouch** e **Confident** (Hero Landing). Cada peça guarda a pose de repouso
(`Rest`); posar = calcular CFrames em volta das juntas R6 (pescoço, ombros, quadril). A arma
acompanha o braço porque está no mesmo osso. Nenhum loop por personagem.

## Variantes (7, sem 7 modelos)

`VariantVisualModifier`: anel no chão na cor da variante, acentos (arma/cabelo/acessórios)
puxando para a cor, brilho leve a partir de Gold e luz em Void/Celestial (só no modo Full).
**Nunca** muda corpo, rosto, roupas, BodyColors ou texturas.

## Fallback

Asset ausente, inválido (ex.: Script injetado), falha ao montar ou CharacterId desconhecido →
placeholder em blocos (o atual) + `warn` uma vez no Output. O jogo nunca quebra.

## Onde ficam os assets (decisão)

`assets/Characters.rbxm` → **`ReplicatedStorage.CharacterAssets`** (pelo `build_place.py`).
- O servidor (estações) e o cliente (Reveal, Mochila, Índice e Hero Landing em ViewportFrame)
  precisam do MESMO modelo; ReplicatedStorage é o único lugar visível para os dois.
- Templates ficam fora do Workspace (não renderizam, sem física); só clones aparecem.
- Peso: ~10–25 peças por piloto; 121 personagens ≈ 2–3 mil peças em memória, sem render.
- O `.rbxm` é gerado (não editado à mão) e versionado como os outros arquivos de `assets/`.
- O Anime Pack fica em `third_party/` (fora do Git e do build) — nunca é dependência.

## Como gerar (na sua máquina)

1. No Studio: `Workspace > Anime Pack` → botão direito → **Save to File...** →
   `third_party/AnimePack.rbxm` (já feito na auditoria).
2. `python tools/build_characters.py` → `assets/Characters.rbxm` + `CHARACTER_PILOT_AUDIT.md`.
3. `python tools/build_place.py` → abrir `build/RollLegends.rbxlx` (sem o pack) → Play.
4. `_G.dev("CharacterAssetReport")`, `_G.dev("SourcePackCheck")`, `_G.dev("CharacterGallery")`.

Alternativa sem Lune (Studio em modo **EDIÇÃO**, nunca no Play — no Play os scripts do pack rodam):
`print(require(game.ReplicatedStorage.Shared.Modules.CharacterAssetPipeline).buildInStudio())`
e salve `ReplicatedStorage.CharacterAssets` com **Save to File...** em `assets/Characters.rbxm`.

## Comandos DEV (Studio)

| Comando | O que faz |
|---|---|
| `_G.dev("CharacterGallery")` | Os 10 pilotos lado a lado (asset ou PLACEHOLDER na etiqueta) |
| `_G.dev("ShowCharacterVariants", "char_ichiro_base")` | As 7 variantes lado a lado |
| `_G.dev("ShowCharacterPoses", "char_zabuzo_base")` | Idle/Reveal/Combat/Crouch/Confident |
| `_G.dev("ClearGallery")` | Remove a galeria |
| `_G.dev("GivePilots")` / `_G.dev("GivePilots", "Gold")` | 1 de cada piloto no inventário e no Índice |
| `_G.dev("CharacterAssetReport")` | Validação do runtime de cada asset |
| `_G.dev("SourcePackCheck")` | Monta os pilotos com o pack escondido e procura dependências |
| `_G.dev("PlayReveal", "Divine", "char_goju_base")` | Reveal/Hero Landing com um piloto |

## Performance (meta: 40 por base × 10 bases = 400)

Zero script e zero loop por personagem; nenhum Animator; Humanoid só quando há roupa e inerte;
tudo ancorado sem colisão/toque/consulta e sem juntas; VFX limitados (2 ativos na base) e
desligados pelo LOD; meta de ≤ 40 peças por personagem (acima disso: AVISO no relatório).

## Testes

- `tests/CharacterAssets.spec.luau` (puro): ids, nomes separados, metadados, transformações,
  RNG/roster intocados, regras de segurança e VFX.
- `tests/roblox/CharacterPipelineHarness.luau` (Lune): pack SINTÉTICO com o "lixo" real do pack →
  sanitiza, valida, salva .rbxm, **destrói o pack** e roda o jogo final só com os assets
  (factory, 7 variantes, VFX, poses, spawn, fallback, limpeza).
- `tests/build_characters_test.py`: a ferramenta de ponta a ponta (incluindo o strip de propriedade).
- `GameplayHarness`: base (pés no pedestal), troca de slot, Índice com variantes, Fusão 3→Silver→Gold,
  Torres, comandos DEV. `ClientHarness`: Reveal, Hero Landing (limpeza), Mochila, Índice.
