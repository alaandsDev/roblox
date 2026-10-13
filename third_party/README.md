# third_party — assets de terceiros (NÃO entram no build)

Esta pasta **não** está no `default.project.json`: nada aqui vai para o place.
Serve para auditar packs da Creator Store antes de qualquer integração.

## Anime Pack (asset 14679137059) — auditoria SEM executar nada do pack

1. No Studio: botão direito em **Workspace > Anime Pack** → **Save to File...** →
   `third_party/AnimePack.rbxm` (o pack no Studio não é alterado).
   (Também funciona com o place inteiro salvo em `.rbxl`: a ferramenta usa `Workspace.Anime Pack`.)
2. Na pasta do projeto:

```
python tools\audit_pack.py
```

   (baixa o Lune se precisar; só LÊ o arquivo — nenhum script do pack roda). Se o Lune
   recusar o arquivo (ex.: `Accessory.Tags should be SharedString`), o leitor tolerante
   `tools/packaudit/rbxm_reader.py` cria `third_party/AnimePack_clean.rbxmx` e a auditoria
   continua sozinha.
3. Ele gera 3 arquivos pequenos. Faça commit + push **deles**:

```
git add ANIME_PACK_AUDIT.md third_party/AnimePack_summary.json third_party/AnimePack_scripts.txt
git commit -m "Auditoria do Anime Pack"
git push
```

O `.rbxm` fica fora do Git (`.gitignore`) porque packs grandes passam do limite do GitHub
(100 MB). Se ele for pequeno e você quiser enviar mesmo assim: `git add -f third_party/AnimePack.rbxm`.

O relatório traz: categorias (DBZ, NARUTO...), estrutura, rigs, malhas, roupas, rostos,
acessórios, armas, VFX, animações, **formas/transformações do mesmo personagem**, TODOS os
scripts com risco (require por id, loadstring, HttpService, Teleport, Marketplace,
ofuscação...) e uma sugestão visual de raridade. O `AnimePack_scripts.txt` tem o código dos
scripts como texto, para revisão manual.

## Pipeline de personagens (lote de lançamento: 121)

Com `third_party/AnimePack.rbxm` salvo: `python tools/build_characters.py` gera
`assets/Characters.rbxm` (os 121 de `CharacterAssetConfig.Assets`, sanitizados),
`CHARACTER_LAUNCH_AUDIT.md`, `CLOTHING_AUDIT.md` e `third_party/character_launch_report.json`. A propriedade `Tags` (que o Lune recusa em todas as classes) sai
de uma vez de uma cópia temporária (`build/AnimePack_lune.rbxm`); o original não é tocado. Detalhes: `CHARACTER_PIPELINE.md`.
