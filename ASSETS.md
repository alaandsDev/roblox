# Assets externos — Roll Legends

Todo asset de terceiros é auditado antes de entrar no jogo (ver `SECURITY.md`).
Arquivo versionado: `assets/Assets.rbxm` → `ReplicatedStorage.Assets`.

**Personagens:** não vêm de `Assets.Characters`. O pipeline (`CHARACTER_PIPELINE.md`) gera
`assets/Characters.rbxm` → `ReplicatedStorage.CharacterAssets` (sanitizados, validados de novo
em runtime); sem eles o `CharacterModelFactory` usa o placeholder.

Auditoria: o `.rbxm` é convertido para XML com o Rojo e as classes são contadas.
Na FASE 1 foram removidos 1 modelo de demonstração (rig R15 com `AnimationController`,
`Animator` e `KeyframeSequence` com 1.024 poses) e todos os modelos do protótipo.
**Scripts encontrados no arquivo atual: 0.**

| Pasta/Nome | Tipo | Asset ID | Nome original na Store | Criador | Uso | Scripts encontrados | Scripts removidos |
|---|---|---|---|---|---|---|---|
| Sounds/UIClick | Sound | 3665143844 | Click (Sound Effect) | não registrado | clique dos botões do HUD | 0 | 0 |
| Sounds/Purchase | Sound | 6206789925 | Cash/Purchase Sound | não registrado | compras (futuro) | 0 | 0 |
| Sounds/LevelUp | Sound | 796850126 | Cool Level up sound | não registrado | progressão (futuro) | 0 | 0 |
| Sounds/Rebirth | Sound | 2275316480 | Magic Horn - Sound | não registrado | rebirth (futuro) | 0 | 0 |
| Sounds/Impact | Sound | 9462181949 | Block break sound | não registrado | batalha (futuro) | 0 | 0 |
| Sounds/Music | Sound | 124854240351455 | Prclip By LicoLeafy | não registrado | música (futuro; checar licença) | 0 | 0 |
| VFX/Explosion | ParticleEmitter | 9380729331 | Explosion Particle | não registrado | impactos (futuro) | 0 | 0 |
| VFX/LevelUp | ParticleEmitter | 13752908196 | Tycoon Rebirth/Level Up Effect | não registrado | progressão (futuro) | 0 | rig de demonstração removido |
| VFX/Reveal | ParticleEmitter | 5617435676 | hatch effects | não registrado | revelação do roll (futuro) | 0 | 0 |
| VFX/Rainbow | ParticleEmitter | 2553154969 | Rainbow particles | não registrado | raridades altas (futuro) | 0 | 0 |
| VFX/Sparkle | ParticleEmitter | 688891088 | Sparkles Particle | não registrado | compras (futuro) | 0 | 0 |
| Sky/Sky | Sky | 10594688909 | Cartoon Sky | não registrado | céu do mapa (FASE 2) | 0 | 0 |
| Icons/Gift | Decal | 122704810273307 | rewards | não registrado | recompensas (futuro) | 0 | 0 |
| Icons/Potion | Decal | 109019764613949 | money potion tier II | não registrado | poções (futuro) | 0 | 0 |
| Icons/Upgrade | Decal | não registrado | Upgrades | não registrado | melhorias (futuro) | 0 | 0 |
| Icons/Rebirth | Decal | não registrado | Rebirth | não registrado | rebirth (futuro) | 0 | 0 |

"Não registrado": a busca do protótipo não guardou o criador/ID. Antes de publicar
oficialmente, conferir na Store e preencher (o `tools/FindAssets.lua` agora imprime ID e criador).

## FASE 2 — mapa

**Nenhum asset externo novo.** A busca na Creator Store não está acessível a partir do ambiente de
desenvolvimento, e a regra é não usar modelo ruim só para evitar placeholder. Todo o mapa é
construído por código com peças simples e direção de arte própria (`src/server/Map/Decor.luau`):
palmeiras low-poly, pedras, arbustos, cristais, postes de luz, bandeiras, cabanas, portal/torre,
dado mágico e esteira.

Candidatos para substituir os placeholders depois (buscar com `tools/FindAssets.lua`):
low poly palm tree, tropical rocks, fantasy market stand, wooden shop, magic portal,
dice model, crystals, low poly vegetation, cartoon island, ambient sounds.
