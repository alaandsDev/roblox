"""Gera o CATÁLOGO DE LANÇAMENTO (121 personagens) a partir de third_party/catalog_proposal.json.

    python tools/characters/gen_launch_catalog.py          (reescreve os blocos gerados)
    python tools/characters/gen_launch_catalog.py --check  (só confere; código 1 se divergir)

Launch = F2P (16 Dice da DICE_PROGRESSION_PROPOSAL) + Premium (PREMIUM_DICE_PROPOSAL).
Fora: reservas futuras (future), evento, limited, banner, stands, duplicatas, quebrados.
ABORTA sem escrever nada se o conjunto não for exatamente 121 = 112 F2P + 9 Premium com
CharacterIds únicos.

CharacterId (estável, nunca derivado do DisplayName): "char_" + id do catálogo, com "_base"
quando o personagem é a forma-base da família (id == família) — a mesma regra dos 10 pilotos.

Escreve, entre marcadores "BEGIN/END LAUNCH CATALOG (gerado)":
  - src/shared/Config/CharacterConfig.luau       metadados de jogo (List = 112 F2P; Premium = 9)
  - src/shared/Config/CharacterAssetConfig.luau  SourcePath + whitelist de VFX por personagem
Os 10 pilotos continuam com as entradas curadas à mão (não são sobrescritos).
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent.parent
CATALOGO = RAIZ / "third_party" / "catalog_proposal.json"
CHAR_CONFIG = RAIZ / "src" / "shared" / "Config" / "CharacterConfig.luau"
ASSET_CONFIG = RAIZ / "src" / "shared" / "Config" / "CharacterAssetConfig.luau"

# Ordem dos 16 Dice F2P (DICE_PROGRESSION_PROPOSAL.md)
F2P_DICE = ["starter", "lucky", "rampart", "flame", "shinobi", "blade", "fighter", "storm",
            "spirit", "arcane", "shadow", "void", "awakened", "colossus", "celestial", "forbidden"]
ESPERADO = {"total": 121, "F2P": 112, "Premium": 9}
PREMIUM_ESPERADO = {  # PREMIUM_DICE_PROPOSAL.md (nome no pack)
    "Iskandar", "Hellflame", "Lancer Mode", "Afro Samurai", "Kizaru", "Shunko Yoruichi", "SSJR", "SALTER", "Bankai Toshiro",
}
# Stats provisórios por raridade (iguais aos pilotos; o balanceamento vem na fase dos Dice)
STATS = {
    "Common": (12, 1), "Uncommon": (50, 4), "Rare": (155, 9), "Epic": (600, 25),
    "Legendary": (2450, 60), "Mythic": (12500, 160), "Divine": (60000, 425), "Secret": (320000, 1200),
}
# VFX próprios que NÃO entram por padrão (golpes/disparos/rastros: só fazem sentido em combate
# animado). Ficam registrados como VFXExcluded e o personagem vai para VFX REVIEW.
VFX_COMBATE = re.compile(r"trail|shoot|charge|beam|hit|slash|blast|wave|projectile|noblade|kame|throw|punch|kick", re.I)
INICIO = "-- BEGIN LAUNCH CATALOG (gerado por tools/characters/gen_launch_catalog.py — não editar à mão)"
FIM = "-- END LAUNCH CATALOG"


def character_id(c: dict) -> str:
    return "char_" + c["id"] + ("_base" if c["id"] == c["family"] else "")


def lua(texto: str) -> str:
    return '"' + str(texto).replace("\\", "\\\\").replace('"', '\\"') + '"'


def carregar() -> tuple[list[dict], list[str]]:
    dados = json.loads(CATALOGO.read_text(encoding="utf-8"))
    launch = [c for c in dados if c["dest"] in F2P_DICE or c["dest"] == "premium"]
    erros = []
    f2p = [c for c in launch if c["dest"] in F2P_DICE]
    premium = [c for c in launch if c["dest"] == "premium"]
    ids = [character_id(c) for c in launch]
    if len(launch) != ESPERADO["total"]:
        erros.append(f"Launch = {len(launch)} (esperado {ESPERADO['total']})")
    if len(f2p) != ESPERADO["F2P"]:
        erros.append(f"F2P = {len(f2p)} (esperado {ESPERADO['F2P']})")
    if len(premium) != ESPERADO["Premium"]:
        erros.append(f"Premium = {len(premium)} (esperado {ESPERADO['Premium']})")
    if len(set(ids)) != len(ids):
        erros.append("CharacterIds repetidos: " + ", ".join(sorted({i for i in ids if ids.count(i) > 1})))
    if {c["source"] for c in premium} != PREMIUM_ESPERADO:
        erros.append(f"Premium diverge do PREMIUM_DICE_PROPOSAL: {sorted({c['source'] for c in premium} ^ PREMIUM_ESPERADO)}")
    caminhos = [c["sourcePath"] for c in launch]
    if len(set(caminhos)) != len(caminhos):
        erros.append("SourcePath repetido (dois ids no mesmo modelo): " + ", ".join(sorted({p for p in caminhos if caminhos.count(p) > 1})))
    nomes = [c["display"] for c in launch]
    if len(set(nomes)) != len(nomes):
        erros.append("DisplayName repetido: " + ", ".join(sorted({n for n in nomes if nomes.count(n) > 1})))
    # Ordem estável: Dice (F2P na ordem de desbloqueio, Premium no fim), raridade, nome
    ordem_raridade = list(STATS)
    launch.sort(key=lambda c: ((F2P_DICE + ["premium"]).index(c["dest"]), ordem_raridade.index(c["rarity"]), c["id"]))
    return launch, erros


def pilotos_existentes() -> set[str]:
    texto = CHAR_CONFIG.read_text(encoding="utf-8")
    bloco = texto.split(INICIO)[0]
    return set(re.findall(r'pilot\(\d+, "(char_[a-z0-9_]+)"', bloco))


def bloco_char_config(launch: list[dict], pilotos: set[str]) -> str:
    linhas = [INICIO, "-- Personagens de LANÇAMENTO (121 = 112 F2P + 9 Premium). F2P = roster do roll (por Dice,",
              "-- campo DefaultDice) e da coleção do Índice; Premium fora dos Dice. Stats provisórios por raridade.",
              "local launchGenerated: { Character } = {"]
    for i, c in enumerate(launch):
        cid = character_id(c)
        if cid in pilotos:
            continue
        power, income = STATS[c["rarity"]]
        pool = "Premium" if c["dest"] == "premium" else "F2P"
        linhas.append(
            f"\tlaunch({1000 + i}, {lua(cid)}, {lua(c['display'])}, {lua(c['source'].strip())}, {lua(c['rarity'])}, "
            f"{lua(c['family'])}, {int(c['tier'])}, {lua(c['category'])}, {lua(c['dest'])}, {lua(pool)}, {lua(c['status'])}, {power}, {income}),"
        )
    linhas.append("}")
    linhas.append("-- Ordem do catálogo de lançamento (Dice, raridade, id); inclui os pilotos")
    linhas.append("local LAUNCH_ORDER: { string } = {")
    for c in launch:
        linhas.append(f"\t{lua(character_id(c))},")
    linhas.append("}")
    linhas.append(FIM)
    return "\n".join(linhas)


def bloco_asset_config(launch: list[dict], pilotos: set[str]) -> str:
    linhas = [INICIO, "local launchAssets: { [string]: AssetSpec } = {"]
    for c in launch:
        cid = character_id(c)
        if cid in pilotos:
            continue
        proprios = [n for n in dict.fromkeys(c.get("vfxNames") or [])]
        permitidos = [n for n in proprios if not VFX_COMBATE.search(n)]
        excluidos = [n for n in proprios if VFX_COMBATE.search(n)]
        leve = next((n for n in permitidos if "aura" in n.lower()), permitidos[0] if permitidos else None)
        partes = [f"SourceModelName = {lua(c['source'].strip())}", f"SourcePath = {lua(c['sourcePath'])}"]
        if permitidos:
            light = f"{{ {lua(leve)} }}" if leve else "{}"
            full = "{ " + ", ".join(lua(n) for n in permitidos) + " }"
            partes.append(f"VFX = {{ Light = {light}, Full = {full} }}")
        if excluidos:
            partes.append("VFXExcluded = { " + ", ".join(lua(n) for n in excluidos) + " }")
        if c["status"] != "APPROVED":
            partes.append(f"CatalogStatus = {lua(c['status'])}")
        linhas.append(f"\t{cid} = {{ {', '.join(partes)} }},")
    linhas.append("}")
    linhas.append("for id, spec in launchAssets do")
    linhas.append('\tassert(CharacterAssetConfig.Assets[id] == nil, "asset repetido: " .. id)')
    linhas.append("\tCharacterAssetConfig.Assets[id] = spec")
    linhas.append("end")
    linhas.append(FIM)
    return "\n".join(linhas)


def substituir(caminho: Path, bloco: str, ancora: str) -> tuple[str, str]:
    texto = caminho.read_text(encoding="utf-8")
    if INICIO in texto:
        antes, resto = texto.split(INICIO, 1)
        _, depois = resto.split(FIM, 1)
        novo = antes + bloco + depois
    else:
        assert ancora in texto, f"âncora não encontrada em {caminho}: {ancora!r}"
        novo = texto.replace(ancora, bloco + "\n\n" + ancora, 1)
    return texto, novo


def main() -> int:
    apenas_conferir = "--check" in sys.argv
    launch, erros = carregar()
    f2p = sum(1 for c in launch if c["dest"] != "premium")
    print(f"Launch: {len(launch)} (F2P {f2p} · Premium {len(launch) - f2p}) · ids únicos: {len({character_id(c) for c in launch})}")
    if erros:
        print("PARADO: o catálogo de lançamento diverge do planejado:")
        for e in erros:
            print("  - " + e)
        return 1
    pilotos = pilotos_existentes()
    faltando = pilotos - {character_id(c) for c in launch}
    if faltando:
        print("PARADO: pilotos fora do catálogo de lançamento: " + ", ".join(sorted(faltando)))
        return 1
    alvos = [
        (CHAR_CONFIG, bloco_char_config(launch, pilotos), "-- Registro do catálogo de lançamento"),
        (ASSET_CONFIG, bloco_asset_config(launch, pilotos), "local byId = CharacterAssetConfig.Assets"),
    ]
    divergente = False
    for caminho, bloco, ancora in alvos:
        antigo, novo = substituir(caminho, bloco, ancora)
        if antigo != novo:
            divergente = True
            if not apenas_conferir:
                caminho.write_text(novo, encoding="utf-8")
                print(f"atualizado: {caminho.relative_to(RAIZ)}")
    if apenas_conferir and divergente:
        print("Blocos gerados desatualizados: rode python tools/characters/gen_launch_catalog.py")
        return 1
    print("OK" if not divergente else "Catálogo de lançamento gerado.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
