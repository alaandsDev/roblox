# CLOTHING AUDIT — Roll Legends

Gerado por `python tools/build_characters.py` a partir de `pack_tags.rbxm`. Uma linha por AssetId (roupas compartilhadas aparecem uma vez com todos os personagens). Sem chamadas de rede: o status vem de `CharacterAssetConfig.ClothingStatus` (evidência do comando DEV ClothingCheck) e os substitutos aprovados de `ClothingTemplateOverrides`. REVIEW_REQUIRED não impede o build: o personagem é gerado com AVISO.

| AssetId | Tipo | Status | Personagens | Override | Observação | Ação necessária |
|---|---|---|---|---|---|---|
| 2065247269 | Shirt | **REVIEW_REQUIRED** | char_killuo_base<br>char_killuo_godspeed | — | Image "Killua Zoldylock (T)"; não carrega (PreloadAsync sem resposta) | aprovar uma roupa substituta e registrar em ClothingTemplateOverrides |
| 2065252088 | Pants | **REVIEW_REQUIRED** | char_killuo_base<br>char_killuo_godspeed | — | Image "Killua Zoldylock (B)"; não carrega (PreloadAsync sem resposta) | aprovar uma roupa substituta e registrar em ClothingTemplateOverrides |
| 1001 | Shirt | **UNCHECKED** | char_barbalva_base<br>char_goju_base<br>char_goko_base<br>char_ichiro_base<br>char_ichiro_hollow<br>char_sacha_base<br>char_yamamotu_base<br>char_zabuzo_base | — | — | verificar no Studio: Invoke("ClothingCheck") e registrar em ClothingStatus |
| 1002 | Pants | **UNCHECKED** | char_barbalva_base<br>char_goju_base<br>char_goko_base<br>char_ichiro_base<br>char_ichiro_hollow<br>char_sacha_base<br>char_yamamotu_base<br>char_zabuzo_base | — | — | verificar no Studio: Invoke("ClothingCheck") e registrar em ClothingStatus |

Total: 4 AssetId(s) — OK 0 · UNCHECKED 2 · REVIEW_REQUIRED 2 · OVERRIDDEN 0
