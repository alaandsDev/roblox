# Roll Legends

Jogo Roblox de **dados + coleção de lutadores + bases + economia + torres + progressão**.
Status: **FASES 1–6 concluídas** (fundação, mapa, roll/RNG/reveal + cinemática, inventário,
estações da base com nível individual, renda/coletor, dados, melhorias, venda/auto-sell, índice,
dinheiro offline, recompensas diárias, HUD). Próximas: Torres, Fusão, Trocas, Rebirth. Veja `MIGRATION_PLAN.md`.

## Documentação

| Arquivo | Conteúdo |
|---|---|
| `MIGRATION_PLAN.md` | Plano de fases, decisões de design e histórico do protótipo |
| `ARCHITECTURE.md` | Estrutura do código, Services/Controllers, rede |
| `DATA_SCHEMA.md` | Formato dos dados salvos, versões e migrações |
| `SECURITY.md` | Regras server-authoritative, validação, rate limit, assets externos |
| `TEST_PLAN.md` | Testes automáticos e roteiro de teste no Studio |
| `ASSETS.md` | Assets externos auditados (IDs, uso, scripts removidos) |
| `RNG.md` | Raridades, fórmula da Luck, pity, fluxo do roll |
| `RNG_SIMULATION.md` | 1.000.000 rolls por cenário (gerado) |
| `ECONOMY.md` | Fórmulas de dinheiro, custos e simulação Casual/Ativo/Hardcore (gerado) |

## Comandos (Windows)

```
cd C:\Users\aland\Desktop\projects\roblox
git pull --no-edit origin claude/nice-dirac-ubdorh
python tools\run_tests.py        # testes puros + mapa/serviços/gameplay headless + build\map_preview.png
tools\bin\lune-0.10.4\lune run tools/sim/simulate_rng.luau       # regenera RNG_SIMULATION.md
tools\bin\lune-0.10.4\lune run tools/sim/simulate_economy.luau   # regenera ECONOMY.md
python tools\build_place.py      # gera build\RollLegends.rbxlx (baixa o Rojo sozinho)
.\build\RollLegends.rbxlx        # abre no Studio
python tools\publish_place.py    # publica (precisa de publish.local.json com a api_key)
```

## Estrutura

```
src/shared   -> ReplicatedStorage.Shared   (Config, Modules, Localization, Remotes)
src/server   -> ServerScriptService.Server (Bootstrap.server.luau, Services, Core)
src/client   -> StarterPlayerScripts.Client (Bootstrap.client.luau, Controllers, UI, Effects)
assets/Assets.rbxm -> ReplicatedStorage.Assets (sons, VFX, ícones, céu)
assets/Map.rbxm    -> Workspace.Map (decoração feita no Studio, quando existir)
tests/       testes puros (luau) + tests/roblox (Lune: mapa, serviços, gameplay)
tools/       build, publicação, testes, simulações (tools/sim), busca de assets (FindAssets.lua)
```

## Studio

Para salvar dados no Studio: publique e ative *Configurações do jogo > Segurança >
Permitir acesso do Studio aos serviços de API*. Sem isso o jogo usa um perfil temporário
(avisa na tela) e nada é salvo.
