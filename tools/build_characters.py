"""Gera os CHARACTER ASSETS sanitizados do Roll Legends a partir do Anime Pack (sem executar nada do pack).

    python tools/build_characters.py                          (usa third_party/AnimePack.rbxm)
    python tools/build_characters.py caminho/pack.rbxm         (ou o place inteiro .rbxl)
    python tools/build_characters.py pack.rbxm --out assets/Characters.rbxm --strip Classe.Prop

1. Roda o CharacterAssetPipeline REAL com o Lune (tools/characters/build_characters.luau).
2. Se o Lune recusar o arquivo (ex.: "Property Accessory.Tags should be SharedString"),
   faz uma cópia binária SEM aquela propriedade (rbxm_reader.strip_properties: geometria,
   malhas, texturas e roupas ficam idênticas) e tenta de novo — quantas vezes precisar.
3. Gera assets/Characters.rbxm (vira ReplicatedStorage.CharacterAssets no build_place.py),
   CHARACTER_PILOT_AUDIT.md e third_party/character_pilot_report.json.
O pack original nunca é alterado e nunca entra no build.
"""
import argparse
import re
import subprocess
import sys
from pathlib import Path

from run_tests import RAIZ, baixar_lune

sys.path.insert(0, str(RAIZ / "tools" / "packaudit"))
import rbxm_reader  # noqa: E402

SCRIPT = "tools/characters/build_characters.luau"
ERRO_PROP = re.compile(r"Property (\w+)\.(\w+) should be")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("pack", nargs="?", default="third_party/AnimePack.rbxm")
    parser.add_argument("--out", default="assets/Characters.rbxm")
    parser.add_argument("--report", default="CHARACTER_PILOT_AUDIT.md")
    parser.add_argument("--json", default="third_party/character_pilot_report.json")
    parser.add_argument("--strip", action="append", default=[], help="Classe.Propriedade a remover antes de ler (repetível)")
    args = parser.parse_args()

    origem = Path(args.pack)
    if not origem.is_absolute():
        origem = RAIZ / origem
    if not origem.exists():
        print(f"Arquivo não encontrado: {origem}")
        print("No Studio: botão direito em Workspace > Anime Pack > Save to File... -> third_party/AnimePack.rbxm")
        return 1
    lune = baixar_lune()

    remover: set[tuple[str | None, str]] = set()
    for item in args.strip:
        classe, _, prop = item.partition(".")
        remover.add((classe or None, prop))
    arquivo = origem
    for tentativa in range(10):
        if remover:
            dados, removidos = rbxm_reader.strip_properties(origem.read_bytes(), remover)
            arquivo = RAIZ / "build" / "AnimePack_lune.rbxm"
            arquivo.parent.mkdir(exist_ok=True)
            arquivo.write_bytes(dados)
            print(f"Cópia para o Lune sem: {', '.join(sorted(set(removidos))) or 'nada'}")
        r = subprocess.run(
            [str(lune), "run", SCRIPT, str(arquivo), args.out, args.report, args.json],
            cwd=RAIZ,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
        )
        sys.stdout.write(r.stdout)
        erro = ERRO_PROP.search(r.stdout + r.stderr)
        if r.returncode in (0, 2) or not erro:
            if r.returncode not in (0, 2):
                sys.stderr.write(r.stderr)
            break
        par = (erro.group(1), erro.group(2))
        if par in remover:
            sys.stderr.write(r.stderr)
            break
        print(f"O Lune recusou {par[0]}.{par[1]}: tentando sem essa propriedade ({tentativa + 1})...")
        remover.add(par)

    if r.returncode in (0, 2):
        print("\nConfira no Studio (_G.dev(\"CharacterGallery\")) e envie:")
        print(f"  git add {args.out} {args.report} {args.json}")
        print('  git commit -m "chore: sanitized pilot character assets"')
        print("  git push")
    return r.returncode


if __name__ == "__main__":
    sys.exit(main())
