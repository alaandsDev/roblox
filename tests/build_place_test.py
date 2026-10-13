"""Teste do build (tools/build_place.py) com e sem assets/Characters.rbxm.

Usa build/tool_Characters.rbxm (10 pilotos gerados pelo tests/build_characters_test.py a partir
do pack SINTÉTICO) numa pasta de assets temporária e confere no .rbxlx gerado:
  - ReplicatedStorage.CharacterAssets existe com EXATAMENTE os 10 pilotos (e nenhum script dentro);
  - sem Characters.rbxm, CharacterAssets não aparece (o jogo usa o placeholder);
  - o DevService (interface ServerStorage.RollLegendsDev) está no build e no Bootstrap.
"""
import re
import shutil
import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
PILOTOS = sorted(set(re.findall(r"^\t(char_[a-z0-9_]+) = \{", (RAIZ / "src/shared/Config/CharacterAssetConfig.luau").read_text(encoding="utf-8"), re.M)))


def nome(item) -> str:
    props = item.find("Properties")
    for tag in ("string", "ProtectedString"):
        for prop in props.findall(tag) if props is not None else []:
            if prop.get("name") == "Name":
                return prop.text or ""
    return ""


def filhos(item):
    return [c for c in item.findall("Item")]


def achar(raiz, caminho: list[str]):
    atual = [raiz]
    for parte in caminho:
        prox = [c for item in atual for c in filhos(item) if nome(c) == parte]
        if not prox:
            return None
        atual = prox
    return atual[0]


def build(pasta: Path, saida: Path):
    r = subprocess.run([sys.executable, "tools/build_place.py", "--assets", str(pasta), "--out", str(saida)], cwd=RAIZ, capture_output=True, text=True)
    return r, (ET.parse(saida).getroot() if saida.exists() else None)


def main() -> int:
    falhas = 0

    def check(cond, msg):
        nonlocal falhas
        print(("  ✓ " if cond else "  ✗ ") + msg)
        if not cond:
            falhas += 1

    print("\n[Build com assets/Characters.rbxm]")
    gerado = RAIZ / "build" / "tool_Characters.rbxm"
    if not gerado.exists():
        print("  ✗ build/tool_Characters.rbxm ausente (rode tests/build_characters_test.py antes)")
        return 1
    tmp = RAIZ / "build" / "place_test"
    shutil.rmtree(tmp, ignore_errors=True)
    com, sem = tmp / "com", tmp / "sem"
    for pasta in (com, sem):
        pasta.mkdir(parents=True)
        if (RAIZ / "assets" / "Assets.rbxm").exists():
            shutil.copy(RAIZ / "assets" / "Assets.rbxm", pasta / "Assets.rbxm")
    shutil.copy(gerado, com / "Characters.rbxm")

    r, raiz = build(com, tmp / "com.rbxlx")
    check(r.returncode == 0 and raiz is not None, "build com Characters.rbxm: OK")
    pasta = achar(raiz, ["ReplicatedStorage", "CharacterAssets"]) if raiz is not None else None
    nomes = sorted(nome(c) for c in filhos(pasta)) if pasta is not None else []
    check(pasta is not None, "ReplicatedStorage.CharacterAssets existe no place")
    check(nomes == PILOTOS and len(nomes) == 121, f"CharacterAssets contém exatamente os 121 personagens de lançamento ({len(nomes)})")
    scripts = [c for c in pasta.iter("Item") if c.get("class") in ("Script", "LocalScript", "ModuleScript", "RemoteEvent", "RemoteFunction", "Sound")] if pasta is not None else ["?"]
    check(not scripts, "nenhum Script/Remote/Sound dentro de CharacterAssets")
    dev = achar(raiz, ["ServerScriptService", "Server", "Services", "DevService"]) if raiz is not None else None
    check(dev is not None and dev.get("class") == "ModuleScript", "DevService (ServerStorage.RollLegendsDev) incluído no build")
    bootstrap = (RAIZ / "src/server/Bootstrap.server.luau").read_text(encoding="utf-8")
    check('"DevService"' in bootstrap, "Bootstrap do servidor inicia o DevService")

    r, raiz = build(sem, tmp / "sem.rbxlx")
    check(r.returncode == 0 and raiz is not None and achar(raiz, ["ReplicatedStorage", "CharacterAssets"]) is None, "build sem Characters.rbxm: OK e sem CharacterAssets (placeholder)")
    real = RAIZ / "assets" / "Characters.rbxm"
    if real.exists():
        r, raiz = build(RAIZ / "assets", tmp / "real.rbxlx")
        pasta = achar(raiz, ["ReplicatedStorage", "CharacterAssets"]) if raiz is not None else None
        nomes = sorted(nome(c) for c in filhos(pasta)) if pasta is not None else []
        # O asset real só tem o que a ferramenta já gerou a partir do pack do usuário (hoje: os 10
        # pilotos; com os 121 depois de rodar python tools/build_characters.py)
        check(r.returncode == 0 and len(nomes) >= 10 and set(nomes) <= set(PILOTOS), f"build REAL (assets/Characters.rbxm do repositório): CharacterAssets com {len(nomes)}/{len(PILOTOS)} personagens de lançamento")
    print(f"[Build com assets/Characters.rbxm] {'OK' if falhas == 0 else f'{falhas} falha(s)'}")
    return 1 if falhas else 0


if __name__ == "__main__":
    sys.exit(main())
