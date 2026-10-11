# Roll Legends

Jogo Roblox de **dados + coleção de lutadores + bases + economia + torres + progressão**.
Status: **FASE 2 concluída (mapa, 10 bases, Hub, navegação)**. Ainda não há roll/personagens; veja `MIGRATION_PLAN.md`.

## Documentação

| Arquivo | Conteúdo |
|---|---|
| `MIGRATION_PLAN.md` | Plano de fases, decisões de design e histórico do protótipo |
| `ARCHITECTURE.md` | Estrutura do código, Services/Controllers, rede |
| `DATA_SCHEMA.md` | Formato dos dados salvos, versões e migrações |
| `SECURITY.md` | Regras server-authoritative, validação, rate limit, assets externos |
| `TEST_PLAN.md` | Testes automáticos e roteiro de teste no Studio |
| `ASSETS.md` | Assets externos auditados (IDs, uso, scripts removidos) |

## Comandos (Windows)

```
cd C:\Users\aland\Desktop\projects\roblox
git pull --no-edit origin claude/nice-dirac-ubdorh
python tools\run_tests.py        # testes fora do Roblox + mapa headless + build\map_preview.png
python tools\build_place.py      # gera build\RollLegends.rbxlx (baixa o Rojo sozinho)
.\build\RollLegends.rbxlx        # abre no Studio
python tools\publish_place.py    # publica (precisa de publish.local.json com a api_key)
```

## Estrutura

```
src/shared   -> ReplicatedStorage.Shared   (Config, Modules, Localization, Remotes)
src/server   -> ServerScriptService.Server (Bootstrap.server.luau, Services, Core)
src/client   -> StarterPlayerScripts.Client (Bootstrap.client.luau, Controllers)
assets/Assets.rbxm -> ReplicatedStorage.Assets (sons, VFX, ícones, céu)
assets/Map.rbxm    -> Workspace.Map (decoração feita no Studio, quando existir)
tests/       testes puros rodados com o binário luau
tools/       build, publicação, testes, busca de assets (FindAssets.lua)
```

## Studio

Para salvar dados no Studio: publique e ative *Configurações do jogo > Segurança >
Permitir acesso do Studio aos serviços de API*. Sem isso o jogo usa um perfil temporário
(avisa na tela) e nada é salvo.
