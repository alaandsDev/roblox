# Auditoria — Auras Pack ("Not mine!", Creator Store 15374038687)

> **PENDENTE: o arquivo `third_party/AurasPack.rbxm` não está no repositório** (packs de
> terceiros ficam fora do Git pelo `.gitignore`), então este relatório ainda não foi gerado a
> partir do pack real. Rode no PC onde o arquivo foi salvo:
>
>     python tools\audit_auras_pack.py
>
> Este arquivo é então SOBRESCRITO com as 27 seções (resultado da leitura, parser, fallback,
> warnings, propriedades incompatíveis, totais, classes, scripts, remotes, bindables, sons,
> animações, movers/constraints, emitters, beams, trails, attachments, lights, texturas,
> malhas, asset IDs, hierarquia, grupos de aura, reutilizáveis, proibidos, riscos, conclusão)
> e `third_party/auras_pack_report.json` é criado. Depois: commit + push dos dois arquivos.

## Erro anterior e correção

`python tools/audit_auras_pack.py` falhava com:

    Failed to read document from buffer - Type mismatch: Property Animator.Tags should be SharedString, but it was Tags

- **Causa raiz:** o Studio recente grava a propriedade serializada `Tags` (tags do
  CollectionService) como **SharedString** (tipo binário 0x1C). O esquema do Lune 0.10.4
  (rbx-dom) espera o tipo `Tags` e recusa o arquivo inteiro na primeira divergência. O mesmo
  defeito já tinha aparecido no Anime Pack (`Accessory.Tags`).
- **Parser anterior:** `tools/packaudit/audit_auras.luau` chamava `roblox.deserializeModel` sem
  fallback (o `deserializePlace` de reserva falha pelo mesmo motivo).
- **Correção:** `tools/audit_auras_pack.py` lê em camadas — leitor tolerante estático
  (`rbxm_reader.py`) SEMPRE (integridade + contagem); Lune no original; se recusar um METADADO
  (`Tags`, `Capabilities`, …), registra WARNING e lê uma cópia TEMPORÁRIA sem só esse chunk
  (demais chunks idênticos byte a byte); se recusar algo visual/desconhecido, usa o leitor
  tolerante. Corrupção estrutural grave (INST/PRNT ilegível, arquivo truncado, referência órfã)
  é reportada como erro. O pack nunca é modificado e o Animator não é apagado.
- **Regressão:** `tests/auras_audit_test.py` (na suíte) reproduz o erro exato com um pack
  sintético e prova que a auditoria não quebra, registra o WARNING, continua e detecta scripts,
  remotes, bindables e VFX.

## Situação

- SEGURO TECNICAMENTE: não avaliado no pack real (pendente).
- PROVENIÊNCIA/IP VERIFICADOS: **NÃO**.
- INTEGRADO AO JOGO: **NÃO** — o sistema de auras do jogo é AuraConfig/AuraBuilder/AuraController
  com texturas nativas, só em personagens colecionáveis.
