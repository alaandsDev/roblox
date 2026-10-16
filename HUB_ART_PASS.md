# HUB ART PASS: landmarks e máquinas interativas

Objetivo: cada sistema do Hub deve ser reconhecido pela **silhueta**, antes mesmo de alguém ler a placa. Tudo foi feito com Parts (in-house, blocky, studs via `WorldStyle`), sem MeshPart, sem asset externo e sem Script nas estruturas.

**Gameplay e lógica intactos.** Os prompts e as interações são os mesmos. MELHORIAS e RENASCER ganharam landmark novo, que abre as **mesmas** janelas do HUD.

**Fora desta rodada:** Player Auras, AURAS mobile, Magnata, Rankings, Bases, Character Auras, Recent Rolls, AFK e Hero Landing.

## Silhueta por landmark

| Tier | Landmark | Antes | Depois (silhueta) | Microanimação |
|---|---|---|---|---|
| A | LOJA DE DADOS | portal rosa/roxo + dado gigante | **preservado**, mais 3 dados menores flutuando e brilho suave | dados girando/flutuando, 4 brilhos/s |
| A | FUSÃO | plataforma, altar, cristal, 2 pilares | **3 entradas** (pedestais com cristais) → **núcleo** (orbe neon + anel) → **1 saída** (gema dourada) = 3 → 1 | 3 beams de energia correndo para o núcleo (textura), núcleo pulsando, anel e gema girando |
| A | TORRES | portal, torre em degraus, espada, escudo | preservado, com números **1–4** nos andares e 2 bandeiras no topo | portal "respirando" (transparência) |
| B | VENDER | cofre de pedra com moeda | **MÁQUINA**: funil de entrada → mini esteira → processador com visor **$** e chaminés → rampa de saída com bandeja de moedas; moeda gigante em cima | bloco entrando pela esteira, visor pulsando, moedas saindo (2,5/s), moeda girando |
| B | MERCADO | barraca vazia | toldo listrado com franja + balcão com faixa + **produtos grandes** (caixote, saco, moedas) + prateleiras + **sacola de compras gigante** flutuando | sacola girando/flutuando |
| B | MELHORIAS (novo) | — | **3 pilares crescentes** com setas ↑ neon + engrenagem dourada + console | setas subindo em sequência, engrenagem girando |
| B | RENASCER (novo) | — | **anel-portal** com **setas circulares** + estrela no centro + pedestal | setas girando (ciclo), estrela pulsando |
| C | TROCAS | tenda de madeira com mesas | estação **simétrica**: lado azul \| lado laranja, cada um com balcão + moldura de "slot" e item girando; arco com **↔** gigante e a mesa da troca no meio | setas ↔ respirando em sentidos opostos, itens girando |
| C | MISSÕES | placa "MISSÕES • • •" | **quadro de tarefas** com moldura e telhado, 4 cartões com pinos, ✓, ★ e moeda; cabeçalho 📜 MISSÕES; NPC guia original (blocky) com **"!"** flutuando | "!" flutuando, ★ piscando |
| C | RANKINGS / MAGNATA | — | **não mexido** | — |
| — | JACKPOT | não tem landmark físico (é atalho do HUD + giro na tela) | sem mudança | — |

Posições:
- Os landmarks existentes ficaram nos lugares de sempre.
- **MELHORIAS** fica em (−68, −40) e **RENASCER** em (68, −40), entre o Hub e a esteira, fora dos caminhos. Foram adicionados a `MapConfig.Social` e `MapConfig.Landmarks`, então a decoração os evita.

## Arquitetura

- **`Server/Map/Landmarks.luau`:** constrói os landmarks.
- **Peças animadas:** recebem a tag `HubDeco` e os atributos `DecoMode` (Spin, Bob, Pulse, Slide, Tumble), `DecoSpeed`, `DecoAmp`, `DecoPhase`, `DecoAxis`, `DecoWave` e `DecoHz`. São sempre sem colisão e ancoradas.
- **Efeitos:** ParticleEmitter e Beam recebem a tag `HubDecoFx`.
- **`Client/Controllers/HubDecorationController.luau`:**
  - **um único** loop no Heartbeat (~30 Hz) só no cliente;
  - cada elemento atualiza na sua frequência (`DecoHz`, de 10 a 20 Hz);
  - a pose é sempre recalculada a partir da original (não acumula erro);
  - zero custo no servidor.

## LOD (geometria nunca some)

| Distância da câmera | Animação | Efeitos |
|---|---|---|
| até 50 studs | cheia | cheios |
| 50–100 studs | 1/3 da frequência | 50% |
| além de 100 | parada | desligados |

Celular: a frequência e a emissão caem pela metade.

## Custo medido (MapHarness e ClientHarness)

| Landmarks do Hub (Hub, Lojas, Torres, área social) | Antes | Depois |
|---|---|---|
| Parts | 354 | 513 (+159, dos quais 60 são os 2 landmarks novos) |
| Parts com colisão | 66 | 84 |
| MeshParts | 0 | 0 |
| ParticleEmitters | 1 (8/s) | 3 (14/s no total; com LOD fica em ~5–6/s perto e 0 longe) |
| Beams | 0 | 3 (só os da Fusão) |
| Trails | 0 | 0 |
| Attachments | 0 | 4 |
| Lights | 2 | 2 (nenhuma nova) |
| Conexões | 2 (AmbientController) | +1 (HubDecorationController) |
| Escritas por quadro | 0 | centro do Hub ~15 · perto do Mercado ~15 · longe 0 |

Peças por landmark: Mercado 45 · Loja de Dados 77 · Vender 25 · Trocas 27 · Missões 39 · Fusão 36 · Melhorias 31 · Renascer 29 · Rankings 21 (inalterado).

## Colisão, caminhos e câmera

- **Colisão:** tudo que é pequeno, flutuante ou animado tem `CanCollide = false`, inclusive o NPC guia. Os testes reprovam qualquer peça pequena (< 1,8 stud) com colisão nos landmarks.
- **Caminhos e spawns livres** (MapHarness). Na Trocas, os postes do arco foram movidos para dentro da área, porque bloqueavam o caminho da base ao lado.
- **Sem invasões:** nenhum landmark invade outro nem uma base.
- **Sem Scripts:** nenhum Script dentro das estruturas.
- **Câmera:** as estruturas mantêm as alturas da versão anterior. A mais alta nova é a engrenagem de MELHORIAS (~13 studs), longe dos caminhos.

## DEV: HubArtTour

```lua
local Dev = game.ServerStorage:WaitForChild("RollLegendsDev")
local p = game.Players:GetPlayers()[1]
Dev:Invoke("HubArtTour", p, "Overview")
Dev:Invoke("HubArtTour", p, "Market")     -- DiceShop, Sell, Trade, Missions, Fusion, Tower, Upgrades, Rebirth, Rankings
Dev:Invoke("HubArtTour", p, "Fusion", 60) -- distância de leitura: 10 / 30 / 60 / 100
```

O jogador é teleportado na direção do Hub, olhando para o landmark, em pé sobre o que houver no chão (degraus, plataformas). O teste confere que nenhum dos 11 pontos, a 26 e a 60 studs, cai dentro de uma peça sólida.

## Aprovação

Os testes provam estrutura, colisão, caminhos, LOD, custo e existência. **Eles não aprovam a arte.** A aprovação final é visual no Studio: roteiro HA1–HA15 em `STUDIO_SMOKE_TEST.md`.
