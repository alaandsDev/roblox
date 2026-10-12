"""Gera build/RollLegends.rbxlx a partir do código (src/) + assets salvos do Studio.

Uso:  python tools\\build_place.py

- Baixa sozinho a versão certa do Rojo para tools/bin (versões antigas não leem
  arquivos .rbxm salvos pelo Studio atual, por isso não usamos o Rojo do PATH).
- Se existir assets/Assets.rbxm, vira ReplicatedStorage.Assets (sons, VFX, ícones, modelos).
- Se existir assets/Map.rbxm, vira Workspace.Map (decoração feita no Studio).
- Se existir assets/Characters.rbxm (gerado por tools/build_characters.py), vira
  ReplicatedStorage.CharacterAssets (personagens sanitizados; o Anime Pack nunca entra no build).
"""

import io
import json
import os
import platform
import subprocess
import sys
import urllib.request
import zipfile
from pathlib import Path

ROJO_VERSION = "7.7.1"
RAIZ = Path(__file__).resolve().parent.parent
BUILD = RAIZ / "build"
SAIDA = BUILD / "RollLegends.rbxlx"

# arquivo em assets/ -> (serviço, nome da instância)
ASSETS = {
    "Assets.rbxm": ("ReplicatedStorage", "Assets"),
    # Personagens sanitizados pelo pipeline (python tools/build_characters.py)
    "Characters.rbxm": ("ReplicatedStorage", "CharacterAssets"),
    "Map.rbxm": ("Workspace", "Map"),
}


def baixar_rojo() -> Path:
    sistema = platform.system()
    nome_zip = {
        "Windows": f"rojo-{ROJO_VERSION}-windows-x86_64.zip",
        "Linux": f"rojo-{ROJO_VERSION}-linux-x86_64.zip",
        "Darwin": f"rojo-{ROJO_VERSION}-macos-x86_64.zip",
    }.get(sistema)
    if not nome_zip:
        sys.exit(f"Sistema {sistema} não suportado. Instale o Rojo manualmente.")

    destino = RAIZ / "tools" / "bin" / ROJO_VERSION
    executavel = destino / ("rojo.exe" if sistema == "Windows" else "rojo")
    if executavel.exists():
        return executavel

    url = f"https://github.com/rojo-rbx/rojo/releases/download/v{ROJO_VERSION}/{nome_zip}"
    print(f"Baixando Rojo {ROJO_VERSION}...")
    with urllib.request.urlopen(url) as resposta:
        zipfile.ZipFile(io.BytesIO(resposta.read())).extractall(destino)
    executavel.chmod(0o755)
    return executavel


def encontrar_rojo() -> str:
    return str(baixar_rojo())


def main() -> None:
    import argparse

    parser = argparse.ArgumentParser(description="Gera o place a partir do código + assets/")
    parser.add_argument("--assets", default=str(RAIZ / "assets"), help="pasta dos .rbxm (padrão: assets/)")
    parser.add_argument("--out", default=str(SAIDA), help="arquivo .rbxlx de saída")
    args = parser.parse_args()
    pasta = Path(args.assets).resolve()
    saida = Path(args.out).resolve()

    projeto = json.loads((RAIZ / "default.project.json").read_text(encoding="utf-8"))
    for arquivo, (servico, nome) in ASSETS.items():
        caminho = pasta / arquivo
        if caminho.exists():
            projeto["tree"].setdefault(servico, {"$className": servico})
            projeto["tree"][servico][nome] = {"$path": os.path.relpath(caminho, RAIZ).replace(os.sep, "/")}
            print(f"Incluindo {caminho.name} em {servico}.{nome}")

    # Projeto temporário na raiz para os caminhos relativos funcionarem
    temporario = RAIZ / "build.project.json"
    temporario.write_text(json.dumps(projeto, indent=2), encoding="utf-8")
    saida.parent.mkdir(parents=True, exist_ok=True)
    try:
        subprocess.run([encontrar_rojo(), "build", str(temporario), "-o", str(saida)], check=True)
    finally:
        temporario.unlink(missing_ok=True)

    print(f"Pronto: {saida}")

if __name__ == "__main__":
    main()
