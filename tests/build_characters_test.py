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
    for arquivo in (saida, md, js):
        arquivo.unlink(missing_ok=True)
    r = subprocess.run(
        [sys.executable, "tools/build_characters.py", str(pack), "--out", str(saida), "--report", str(md), "--json", str(js), "--strip", "Part.Anchored"],
        cwd=RAIZ, capture_output=True, text=True, encoding="utf-8", errors="replace",
    )
    print("    " + "\n    ".join(r.stdout.strip().splitlines()[-14:-11]))
    check(r.returncode == 0, f"ferramenta terminou sem falhas (código {r.returncode})")
    check("- Part.Anchored" in r.stdout and "Original Anime Pack modified: NO" in r.stdout, "cópia binária sem a propriedade pedida (--strip), original intacto")
    check("10/10 personagens gerados" in r.stdout, "10/10 pilotos gerados")
    check(saida.exists() and saida.stat().st_size > 0, "assets .rbxm gravado")
    relatorio = json.loads(js.read_text(encoding="utf-8")) if js.exists() else []
    ids = sorted(x["CharacterId"] for x in relatorio)
    check(len(ids) == 10 and len(set(ids)) == 10 and all(i.startswith("char_") for i in ids), "relatório JSON com 10 CharacterIds únicos")
    campos = ["originalParts", "sanitizedParts", "meshes", "textures", "decals", "welds", "motors", "vfxPreserved", "vfxRemoved", "scriptsRemoved", "remotesRemoved", "soundsRemoved", "animationsRemoved", "boundsSize", "visualOffset", "status"]
    check(all(all(c in x for c in campos) for x in relatorio), "relatório com todos os campos (peças, malhas, soldas, VFX, scripts, sons, caixa, status)")
    texto = md.read_text(encoding="utf-8") if md.exists() else ""
    check("| CharacterId | DisplayName | SourceModelName |" in texto and "char_killuo_godspeed" in texto, "CHARACTER_PILOT_AUDIT em Markdown")
    print(f"[Ferramenta build_characters.py] {'OK' if falhas == 0 else f'{falhas} falha(s)'}")
    return 1 if falhas else 0


if __name__ == "__main__":
    sys.exit(main())
