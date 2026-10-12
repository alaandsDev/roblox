# third_party — assets de terceiros (NÃO entram no build)

Esta pasta **não** está no `default.project.json`: nada aqui vai para o place.
Serve para auditar packs da Creator Store antes de qualquer integração.

## Anime Pack (asset 14679137059)

1. No Studio, com o pack inserido (ainda sem mexer nele), clique com o botão direito na
   pasta/modelo do pack no Explorer → **Save to File...** → salve como
   `third_party/AnimePack.rbxm`.
2. Commit + push do arquivo (ou me envie o arquivo).
3. Auditoria (só LÊ o arquivo; nenhum script do pack é executado):

```
tools\bin\lune-0.10.4\lune run tools/packaudit/audit_pack.luau third_party/AnimePack.rbxm
```

Gera `ANIME_PACK_AUDIT.md` na raiz: estrutura, rigs, malhas, roupas, rostos, acessórios,
armas, VFX, animações, TODOS os scripts com risco (require por id, loadstring, HttpService,
Teleport, Marketplace, ofuscação...) e uma sugestão visual de raridade.
