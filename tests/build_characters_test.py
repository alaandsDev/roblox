"""Teste da ferramenta tools/build_characters.py (Lune + strip de propriedades), sem o pack real.

Usa build/test_AnimePack.rbxm, gerado pelo tests/roblox/CharacterPipelineHarness.luau a partir
do pack SINTÉTICO, e força a remoção de uma propriedade (como o Lune faz com Accessory.Tags no
pack real) para exercitar o caminho de recuperação. Saída em build/ (nunca em assets/).
"""
import json
import subprocess
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent


def main() -> int:
    falhas = 0

    def check(cond, msg):
        nonlocal falhas
        print(("  ✓ " if cond else "  ✗ ") + msg)
        if not cond:
            falhas += 1

    print("\n[Ferramenta build_characters.py (pack sintético)]")
    pack = RAIZ / "build" / "test_AnimePack.rbxm"
    check(pack.exists(), "pack sintético gerado pelo harness")
    if not pack.exists():
        return 1
    saida, md, js = RAIZ / "build/tool_Characters.rbxm", RAIZ / "build/tool_audit.md", RAIZ / "build/tool_report.json"
    roupas = RAIZ / "build/tool_clothing.md"
    for arquivo in (saida, md, js, roupas):
        arquivo.unlink(missing_ok=True)
    r = subprocess.run(
        [sys.executable, "tools/build_characters.py", str(pack), "--out", str(saida), "--report", str(md), "--json", str(js), "--clothing", str(roupas), "--strip", "Part.Anchored"],
        cwd=RAIZ, capture_output=True, text=True, encoding="utf-8", errors="replace",
    )
    print("    " + "\n    ".join(l for l in r.stdout.splitlines() if "gerados em" in l or l.startswith(("Sanitizer:", "Roupas (", "Otimização:"))))
    check(r.returncode == 0, f"ferramenta terminou sem falhas (código {r.returncode})")
    check("- Part.Anchored" in r.stdout and "Original Anime Pack modified: NO" in r.stdout, "cópia binária sem a propriedade pedida (--strip), original intacto")
    check("121/121 personagens de lançamento gerados" in r.stdout and "(F2P 112/112 · Premium 9/9)" in r.stdout, "121/121 personagens de lançamento gerados (F2P 112 · Premium 9)")
    check("Sanitizer: PASS · source encontrados 121/121 · factory 121/121" in r.stdout, "sanitizer PASS, 121 fontes encontradas, factory monta os 121")
    check(saida.exists() and saida.stat().st_size > 0, "assets .rbxm gravado")
    relatorio = json.loads(js.read_text(encoding="utf-8")) if js.exists() else []
    ids = sorted(x["CharacterId"] for x in relatorio)
    check(len(ids) == 121 and len(set(ids)) == 121 and all(i.startswith("char_") for i in ids), "relatório JSON com 121 CharacterIds únicos")
    check(all(x.get("status") in ("OK", "WARN") for x in relatorio) and all(not x.get("visualLost") for x in relatorio), "nenhum FAIL e nenhuma perda visual no lote")
    campos = ["originalParts", "sanitizedParts", "meshes", "textures", "decals", "welds", "motors", "vfxPreserved", "vfxRemoved", "scriptsRemoved", "remotesRemoved", "soundsRemoved", "animationsRemoved", "boundsSize", "visualOffset", "status"]
    check(all(all(c in x for c in campos) for x in relatorio), "relatório com todos os campos (peças, malhas, soldas, VFX, scripts, sons, caixa, status)")
    texto = md.read_text(encoding="utf-8") if md.exists() else ""
    linhas_tabela = [l for l in texto.splitlines() if l.startswith("| `char_")]
    check("| CharacterId | DisplayName | SourceModelName |" in texto and len({l.split("|")[1].strip(" `") for l in linhas_tabela}) == 121, "CHARACTER_LAUNCH_AUDIT: tabela com os 121 personagens")
    check(all(k in texto for k in ("Launch characters: 121/121", "F2P: 112/112", "Premium: 9/9", "Sanitizer: PASS", "CharacterIds únicos: 121/121", "NEEDS_OPTIMIZATION:", "REVIEW_REQUIRED:")), "CHARACTER_LAUNCH_AUDIT: bloco de resumo (Launch, F2P, Premium, Sanitizer, roupas, otimização)")
    remocoes = [rec for x in relatorio for rec in x.get("visualRemoved", [])]
    check("VISUAL_REMOVED_UNJUSTIFIED: 0" in texto and "## VISUAL_REMOVED_JUSTIFIED" in texto and remocoes and all(rec["verdict"] == "JUSTIFIED" and rec["rule"] != "NO_RULE" and rec["reason"] for rec in remocoes), f"remoções visuais objeto a objeto: {len(remocoes)} com regra e motivo, nenhuma sem justificativa")
    helper = next((rec for rec in remocoes if rec["rule"] == "InvisibleCombatHelper" and rec["className"] == "MeshPart"), {})
    check(helper.get("meshId") == "rbxassetid://5101" and helper.get("joints") and helper.get("bone") == "RightArm" and "Trail Trail" in helper.get("vfxInside", []), "ficha no JSON: MeshId (lido do MeshContent do .rbxm), solda, parte do corpo e VFX")
    audit = roupas.read_text(encoding="utf-8") if roupas.exists() else ""
    linhas = [l for l in audit.splitlines() if l.startswith("| 2065247269 ")]
    check(len(linhas) == 1 and "char_killuo_base" in linhas[0] and "char_killuo_godspeed" in linhas[0] and "REVIEW_REQUIRED" in linhas[0], "CLOTHING_AUDIT: roupa compartilhada em UMA linha com os 2 personagens (REVIEW_REQUIRED)")
    check("| AssetId | Tipo | Status | Personagens | Override |" in audit and "UNCHECKED" in audit and "Total:" in audit, "CLOTHING_AUDIT com tipo, status, personagens, override e ação")
    killuo = next((x for x in relatorio if x["CharacterId"] == "char_killuo_base"), {})
    check(killuo.get("status") == "WARN" and r.returncode == 0, "roupa REVIEW_REQUIRED não derruba o build (AVISO, código 0)")

    # MISSING_SOURCE: 2 modelos ausentes no pack -> relatados, os outros 119 gerados, código 2
    faltante = RAIZ / "build" / "test_AnimePack_missing.rbxm"
    check(faltante.exists(), "pack sintético com 2 modelos ausentes gerado pelo harness")
    if faltante.exists():
        saida2, md2 = RAIZ / "build/tool_missing.rbxm", RAIZ / "build/tool_missing.md"
        r2 = subprocess.run(
            [sys.executable, "tools/build_characters.py", str(faltante), "--out", str(saida2), "--report", str(md2), "--json", str(RAIZ / "build/tool_missing.json"), "--clothing", str(RAIZ / "build/tool_missing_clothing.md")],
            cwd=RAIZ, capture_output=True, text=True, encoding="utf-8", errors="replace",
        )
        texto2 = md2.read_text(encoding="utf-8") if md2.exists() else ""
        faltam = [l for l in texto2.splitlines() if l.startswith("| `char_") and "MISSING_SOURCE" in l]
        check(r2.returncode == 2 and "119/121 personagens de lançamento gerados" in r2.stdout and "source encontrados 119/121" in r2.stdout, f"MISSING_SOURCE: 119/121 gerados, código 2 (recebido {r2.returncode})")
        check(len(faltam) == 2 and any("char_mikaza_formal" in l for l in faltam) and any("char_iskander_base" in l for l in faltam), "MISSING_SOURCE marcado na tabela para os 2 ausentes")
        check("Faltando: char_" in r2.stdout and "ATENÇÃO" in r2.stdout, "ferramenta avisa quais faltam no asset")
    print(f"[Ferramenta build_characters.py] {'OK' if falhas == 0 else f'{falhas} falha(s)'}")
    return 1 if falhas else 0


if __name__ == "__main__":
    sys.exit(main())
