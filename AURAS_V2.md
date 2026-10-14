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
- **Light** (Base/Torre): as MESMAS camadas, assinatura, tamanhos, opacidade e alcance; taxas × 0,55,
  órbitas pela metade (mínimo 1) e assinatura × 0,75.
- **Full** (reveal/hero/galeria): versão completa.

## 6. Movimento e LOD (cliente, um loop central)
- **Órbitas:** raio, altura, velocidade, sentido e oscilação próprios; Void/Gravity "respiram".
- **Raios e fitas:** os raios piscam e mudam de curva; as fitas ondulam.
- **Rajadas:** pulso, shockwave, flash, anel e erupção, com intervalo ±25% e fase aleatória (nada sincronizado).
- **Ranking 2×/s:** anima as 10 mais próximas (`MaxAnimated`); além de 55 studs a taxa cai pela
  metade; desliga além de 110 studs (antes: 75); no máximo 3 Full com taxa cheia; no máximo 10
  contornos (`MaxHighlights`, o Roblox limita a 31); mobile × 0,5.

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
Dev:Invoke("AuraClear")
```
Fique na Base (fundo claro) e afaste a câmera até a distância normal de jogo.
