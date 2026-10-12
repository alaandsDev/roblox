# CHARACTER PILOT AUDIT — Roll Legends

Gerado por `python tools/build_characters.py` a partir de `AnimePack.rbxm` (nenhum script do pack é executado).
Assets aprovados em `assets/Characters.rbxm` → `ReplicatedStorage.CharacterAssets` no build.

Regras: corpo normalizado para 5 studs (pés ao topo da Head), pivô no centro dos pés olhando para -Z, tudo ancorado sem colisão/toque/consulta, soldas assadas, sem scripts/remotes/sons/animações/estado. Meta de peças: <= 40.

| CharacterId | DisplayName | SourceModelName | Peças (orig → final) | Malhas | Texturas | Decals | Soldas | Motor6D | VFX mantidos | VFX removidos | Scripts | Remotes | Sons | Animações | Caixa final (studs, corpo=5) | Offset | Status |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `char_barbalva_base` | Barbalva | Whitebeard | 17 → 13 | 5 | 0 | 2 | 136 | 8 | — | 15 | 1 | 4 | 34 | 11 | 5.9 × 6.0 × 8.6 | 0, 0, 0 | **OK** |
| `char_goju_base` | Goju | Gojo Satoru | 17 → 13 | 5 | 0 | 2 | 39 | 8 | — | 14 | 1 | 4 | 34 | 11 | 4.0 × 6.1 × 2.3 | 0, 0, 0 | **OK** |
| `char_goko_base` | Goko | Goku | 12 → 9 | 1 | 1 | 3 | 29 | 8 | — | 14 | 1 | 4 | 34 | 11 | 4.0 × 5.7 × 1.3 | 0, 0, 0 | **OK** |
| `char_ichiro_base` | Ichiro | Ichigo | 14 → 10 | 3 | 0 | 2 | 12 | 8 | — | 15 | 1 | 4 | 34 | 11 | 4.0 × 5.7 × 7.8 | 0, 0, 0 | **OK** |
| `char_ichiro_hollow` | Ichiro Mascarado | Hollow Ichigo | 16 → 12 | 4 | 0 | 3 | 33 | 8 | — | 15 | 2 | 5 | 35 | 23 | 4.0 × 5.7 × 6.3 | 0, 0, 0 | **OK** |
| `char_killuo_base` | Killuo | Killua | 12 → 9 | 1 | 0 | 2 | 33 | 8 | — | 14 | 1 | 4 | 34 | 11 | 4.0 × 5.9 × 2.1 | 0, 0, 0 | **OK** |
| `char_killuo_godspeed` | Killuo Relâmpago | Killua Godspeed | 13 → 9 | 2 | 0 | 2 | 9 | 8 | ParticleEmitter Lightning (Light)<br>ParticleEmitter Lightning (Light)<br>ParticleEmitter Lightning (Full)<br>ParticleEmitter Lightning (Full)<br>ParticleEmitter Lightning (Full)<br>ParticleEmitter Lightning (Full) | 24 | 2 | 5 | 35 | 23 | 4.0 × 6.1 × 2.3 | 0, 0, 0 | **OK** |
| `char_sacha_base` | Sacha | Sasha | 8 → 7 | 1 | 1 | 1 | 1 | 6 | — | 0 | 0 | 0 | 0 | 0 | 4.0 × 5.1 × 1.4 | 0, 0, 0 | **WARN** |
| `char_yamamotu_base` | Yamamotu | Yamamoto | 15 → 12 | 2 | 0 | 2 | 101 | 8 | ParticleEmitter Fire (Light)<br>ParticleEmitter Fire (Light)<br>PointLight PointLight (Full) | 16 | 1 | 4 | 34 | 11 | 4.0 × 5.9 × 5.8 | 0, 0, 0 | **OK** |
| `char_zabuzo_base` | Zabuzo | Zabuza | 16 → 12 | 5 | 0 | 2 | 27 | 8 | — | 14 | 1 | 4 | 34 | 11 | 3.9 × 5.8 × 8.5 | 0, 0, 0 | **OK** |

## Detalhes

### Barbalva (`char_barbalva_base`) — OK
- Origem: `Anime Pack.One Piece Pack.Whitebeard`
- Escala aplicada na normalização: 0.390 · Humanoid mantido (roupas): sim · Acessórios convertidos: 0
- Removidos: bindables 0, valores de estado 15, GUIs 2, peças invisíveis 3, outros: Attachment 1

### Goju (`char_goju_base`) — OK
- Origem: `Anime Pack.JJK.Gojo Satoru`
- Escala aplicada na normalização: 1.000 · Humanoid mantido (roupas): sim · Acessórios convertidos: 0
- Removidos: bindables 0, valores de estado 14, GUIs 2, peças invisíveis 3, outros: Attachment 1

### Goko (`char_goko_base`) — OK
- Origem: `Anime Pack.DBZ.Goku`
- Escala aplicada na normalização: 1.000 · Humanoid mantido (roupas): sim · Acessórios convertidos: 1
- Removidos: bindables 0, valores de estado 16, GUIs 2, peças invisíveis 2, outros: Attachment 1

### Ichiro (`char_ichiro_base`) — OK
- Origem: `Anime Pack.Bleach Pack.Ichigo`
- Escala aplicada na normalização: 1.000 · Humanoid mantido (roupas): sim · Acessórios convertidos: 0
- Removidos: bindables 0, valores de estado 14, GUIs 2, peças invisíveis 3, outros: Attachment 1

### Ichiro Mascarado (`char_ichiro_hollow`) — OK
- Origem: `Anime Pack.Bleach Pack.Hollow Ichigo.Hollow Ichigo`
- Escala aplicada na normalização: 1.000 · Humanoid mantido (roupas): sim · Acessórios convertidos: 0
- Removidos: bindables 0, valores de estado 14, GUIs 2, peças invisíveis 3, outros: Attachment 1, Folder 1

### Killuo (`char_killuo_base`) — OK
- Origem: `Anime Pack.HXH.Killua`
- Escala aplicada na normalização: 1.000 · Humanoid mantido (roupas): sim · Acessórios convertidos: 0
- Removidos: bindables 0, valores de estado 14, GUIs 2, peças invisíveis 2, outros: Attachment 1

### Killuo Relâmpago (`char_killuo_godspeed`) — OK
- Origem: `Anime Pack.HXH.Killua Godspeed`
- Escala aplicada na normalização: 1.000 · Humanoid mantido (roupas): sim · Acessórios convertidos: 0
- Removidos: bindables 0, valores de estado 15, GUIs 2, peças invisíveis 3, outros: Attachment 1, Folder 1

### Sacha (`char_sacha_base`) — WARN
- Origem: `Anime Pack.AOT.Sasha`
- Escala aplicada na normalização: 1.000 · Humanoid mantido (roupas): sim · Acessórios convertidos: 0
- Removidos: bindables 0, valores de estado 0, GUIs 0, peças invisíveis 0, outros: —
- Avisos: 1 peça(s) sem junta (presas pelo osso mais próximo): Handle

### Yamamotu (`char_yamamotu_base`) — OK
- Origem: `Anime Pack.Bleach Pack.Yamamoto`
- Escala aplicada na normalização: 1.000 · Humanoid mantido (roupas): sim · Acessórios convertidos: 0
- Removidos: bindables 0, valores de estado 14, GUIs 2, peças invisíveis 2, outros: Attachment 1

### Zabuzo (`char_zabuzo_base`) — OK
- Origem: `Anime Pack.NARUTO.Zabuza`
- Escala aplicada na normalização: 0.985 · Humanoid mantido (roupas): sim · Acessórios convertidos: 0
- Removidos: bindables 0, valores de estado 14, GUIs 2, peças invisíveis 3, outros: Attachment 1
