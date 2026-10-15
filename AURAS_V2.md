# Auras V2 — Visual Quality Pass

Sistema de auras dos personagens colecionáveis (Lendário, Mítico, Divino e Secreto).
Código: `AuraConfig` (dados), `AuraPlanner` (plano puro, testável), `AuraBuilder` (Instances),
`AuraController` (movimento, num loop central do cliente) e `LodController` (distância).
Aura de personagem ≠ aura do jogador: as Player Auras são um sistema separado, ainda em auditoria.

## 1. Por que a aura antiga sumia no mapa claro
- **Mistura aditiva** (`LightEmission` 0,7–1) com texturas brancas e suaves: sobre céu, chão
  amarelo e grama clara, a cor "lavava" para branco e desaparecia.
- **Partículas pequenas** (0,2–0,5 stud) e **vida curta** (0,35 s no Electric): ~3 partículas vivas
  por camada no modo Light da Base.
- **Tudo nascia dentro do volume do corpo**, com arrasto: nada passava da silhueta e o próprio
  personagem escondia a aura.
- Light reduzia a taxa pela metade sem compensar, e o LOD desligava a aura a 75 studs.

## 2. Nova composição (zonas)
| Zona | Distância do eixo | Camadas |
|---|---|---|
| Inner | no corpo | Body (massa colorida, mistura **alfa**), Contrast (fundo **escuro** atrás do corpo) |
| Mid | ~2–4 studs | Rise (streaks subindo além da cabeça), Depth (frente **e** atrás), órbitas com rastro largo, Ribbon (fitas), assinatura |
| Outer | ~4–7 studs | Outer (coluna externa), Ground (anel/runas no chão), Shockwave (anel que expande), Crown (Secreto) |

Contraste: as camadas principais usam `LightEmission` baixo (a cor fica saturada sobre fundo
claro) e uma camada escura dá recorte; só faíscas, raios e cabeças de órbita brilham. A partir do
Mítico, um **contorno de silhueta** (`Highlight`, preenchimento quase transparente) separa o
personagem do cenário. O `PointLight` continua só como complemento.

## 3. Hierarquia por raridade
| Raridade | Camadas | Silhueta | Composição |
|---|---|---|---|
| Lendário | 3 | 1,2× | Body + Rise + Signature |
| Mítico | 5 | 1,5× | + 2 órbitas, pulso periódico, contorno |
| Divino | 8 | 2,0× | Body, Depth (frente/trás), Rise, 3 órbitas, Ribbon, Ground, Shockwave, Signature |
| Secreto | 11 | 2,5× | + Contrast, Outer, 4 órbitas, Crown com **erupção** periódica exclusiva |

Alcance medido (mesmo personagem): Lendário 1,6 · Mítico 2,4 · Divino 3,8 · Secreto 5,1 studs.

## 4. Estilos (assinatura)
| Estilo | Assinatura |
|---|---|
| Electric | raios saindo do corpo para a zona média + flashes curtos + streaks |
| Flame | coluna de chamas subindo + brasas |
| Void | fragmentos escuros puxados para dentro + faíscas roxas; órbita irregular |
| Dark | sombra densa subindo + faíscas carmim |
| Celestial | estrelas cintilando + halo acima da cabeça |
| Wind | fitas em espiral rápidas + streaks tangenciais |
| Ice | cristais caindo + névoa fria no chão |
| Energy | anéis planos de energia pulsando + streaks |
| Spirit | almas subindo devagar + pontinhos brilhantes |
| Gravity | matéria puxada da borda para o corpo + destroços; órbita irregular |

Mesma raridade = mesmo "espetáculo" (taxa e camadas) para qualquer estilo; só a identidade muda.

## 5. Light × Full
- **Light** (Base/Torre): as MESMAS camadas, assinatura, órbitas, tamanhos, opacidade e alcance;
  só a emissão cai (× 0,55). Desde a V2.1 o Light não corta órbitas nem assinaturas (ver §10).
- **Full** (reveal/hero/galeria): versão completa.

## 6. Movimento e LOD (cliente, um loop central)
- **Órbitas:** raio, altura, velocidade, sentido e oscilação próprios; Void/Gravity "respiram".
- **Raios e fitas:** os raios piscam e mudam de curva; as fitas ondulam.
- **Rajadas:** pulso, shockwave, flash, anel e erupção, com intervalo ±25% e fase aleatória (nada sincronizado).
- **Ranking 2×/s:** anima as 10 mais próximas (`MaxAnimated`); a taxa cai aos poucos com a
  distância (`DistanceRates`: 100% até 30 studs, 85% até 60, 70% até 90, 55% até 110); desliga além
  de 110 studs; no máximo 3 Full com taxa cheia; no máximo 10 contornos (`MaxHighlights`); mobile × 0,5.
- **O LOD nunca esconde o personagem:** só partículas, beams e contorno da aura mudam (regressão
  com 10 estações, perto → longe → perto e troca de andar no `ClientHarness`).

## 7. Orçamento (testado)
| | Full | Light |
|---|---|---|
| Partículas/s por aura (teto) | 260 | 143 |
| Partículas vivas por aura (teto) | 340 | — |
| Instances por aura (teto) | 90 | medido: máx. 34 |

Estresse em Light (`GameplayHarness`):

| Cenário | Partículas/s | Instances | Scripts |
|---|---|---|---|
| 4 Divinos | 279 | 116 | 0 |
| 8 raros | 483 | 174 | 0 |
| 10 raros | 586 | 218 | 0 |

## 8. Auras Pack
O relatório real do pack (`AURAS_PACK_AUDIT.md`) continua **pendente**: o `third_party/AurasPack.rbxm`
não está no repositório. Pela regra "dúvida de segurança/proveniência ⇒ não usar", **nenhum
componente do pack foi aproveitado**. Tudo usa só texturas nativas do Roblox (`rbxasset://`).

## 9. Comparação no Studio (só Studio; Barra de comandos, aba SERVER)
```lua
local Dev = game.ServerStorage.RollLegendsDev
Dev:Invoke("AuraLineup", game.Players:GetPlayers()[1], "Celestial", "Light") -- 4 raridades, mesmo estilo, à sua frente
Dev:Invoke("AuraLineup", game.Players:GetPlayers()[1], "Electric", "Full")   -- versão reveal
Dev:Invoke("AuraStress", game.Players:GetPlayers()[1], 4, "Divine")          -- 4 Divinos lado a lado
Dev:Invoke("AuraStress", game.Players:GetPlayers()[1], 10, "mixed")          -- 10 raros
Dev:Invoke("AuraCompare", game.Players:GetPlayers()[1], "Void")             -- LIGHT (esq.) × FULL (dir.), 4 raridades cada
Dev:Invoke("AuraClear")
```
Os modelos nascem a 24 studs à sua frente (distância normal da câmera na Base); o último argumento
opcional muda isso (`AuraLineup(..., estilo, modo, characterId, distância)`,
`AuraCompare(..., estilo, characterId, distância)`). Faixas para validar: 0–30, 30–60, 60–90 e 90–110 studs.

## 10. V2.1 — inspeção no Studio (personagem sumindo + Light fraco)

**Causa do sumiço (Barbalva, Ulkiorra Liberado):** o `AuraBuilder.attach` media a aura pela
caixa do modelo INTEIRO. Personagens largos por causa da arma (Ulkiorra Liberado 21 studs com a
espada, Barbalva 13,4 com o bisento, Ichiro Vasto, Rika Desperta, Toshiru Bankai) faziam
`math.clamp(x, w/2 + 0,6, OuterMax = 7)` receber mínimo > máximo, o que lança erro. O erro
acontecia dentro do `buildAsset` (protegido por `pcall`), e a fábrica trocava o asset pelo
PLACEHOLDER genérico de blocos: a estação e o letreiro continuavam certos, mas o personagem real
não aparecia. Não era LOD, culling, Highlight nem transparência: nenhum desses mexe no modelo
(provado por regressão). Os testes não pegavam porque o Lune não implementava
`Model:GetBoundingBox` e o AuraBuilder caía num tamanho padrão.

**Correção:** (1) a aura é medida pelo CORPO (largura ≤ 0,6 × altura) e o clamp nunca tem mínimo >
máximo; (2) `rarityAura` protege a aura: se ela falhar, o personagem fica (sem aura) — **a aura
nunca pode sumir com o personagem**; (3) `Model:GetBoundingBox` real nos harnesses; regressão em
`RealAssetsHarness` (todo Lendário+ com asset monta como asset + aura em Light e Full; aura
falhando mantém o asset). Rodada contra o código anterior, ela falha nos 5 personagens acima.

**Light ~2× mais presente, sem engolir o personagem** (`tests/roblox/AuraVisualAudit.luau` projeta
as partículas na visão da câmera e mede presença fora do corpo e oclusão sobre o corpo):
- `Presence` (Size × 1,35, Fade 0,7, pico mínimo 0,9 stud), em Light e Full;
- Light com todas as órbitas e assinaturas do Full (antes: órbitas ÷ 2, assinatura × 0,75);
- Mítico: 3 órbitas, 4 assinaturas, densidade 1,4, pulso a cada 3,2 s; Lendário: densidade
  1,6 e 3 assinaturas; streaks subindo mais grossos;
- toda fumaça/fogo renderiza ATRÁS do corpo (`ZOffset` além do raio externo), fitas/rajadas
  recuadas, estrelas do Celestial em volta (não dentro): a aura emoldura, não esconde.

| Light (P50 dos 10 estilos) | Presença antes | depois | Oclusão máx. antes | depois |
|---|---|---|---|---|
| Lendário | 2,9 | 5,1 | 8% | 6% |
| Mítico | 6,2 | 16,0 | 25% | 18% |
| Divino | 28,7 | 49,2 | 36% | 15% |
| Secreto | 60,9 | 112,2 | 53% | 20% |

(presença = studs² equivalentes-opacos fora do corpo, vista frontal; Light ÷ Full = 63–75%).
Barbalva/Ulkiorra Liberado (Void, Light): oclusão 2%.

Estresse (Light, regras do AuraController), antes → depois:

| Cenário | Partículas/s | Vivas | Beams | Trails | Contornos | Attachments | Instâncias | Animados/frame |
|---|---|---|---|---|---|---|---|---|
| 4 Divinos (15–45 studs) | 279 → 277 | 311 → 295 | 11 → 12 | 8 → 12 | 4 → 4 | 38 → 48 | 126 → 145 | 19 → 24 |
| 8 alta raridade (10–80) | 387 → 499 | 451 → 540 | 12 → 17 | 10 → 20 | 6 → 6 | 44 → 74 | 187 → 242 | 22 → 37 |
| 10 no LOD (10–100) | 500 → 650 | 570 → 719 | 22 → 27 | 14 → 27 | 8 → 8 | 72 → 108 | 268 → 335 | 36 → 54 |

Mobile: metade das partículas (× `LowEndRateScale`). Conexões: as mesmas (1 Heartbeat central +
2 sinais de tag no AuraController; loop de 0,5 s no LodController). O custo novo vem de partículas
MAIORES (mais área de tela por partícula), não de mais objetos — priorizado silhueta, camada
externa, movimento e assinatura em vez de centenas de partículas pequenas.
