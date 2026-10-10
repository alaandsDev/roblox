"""Gera build/SimuladorEscudo.rbxlx a partir do código (src/) + assets salvos do Studio.

Uso:  python tools\\build_place.py

- Usa o Rojo do PATH/Aftman; se não achar, baixa o Rojo sozinho para tools/bin.
- Se existir assets/Modelos.rbxm, vira ReplicatedStorage.Modelos (pets, ovos, escudos).
- Se existir assets/Mapa.rbxm, vira Workspace.Mapa (decoração feita no Studio).
"""

import io
import json
import os
import platform
import shutil
import subprocess
import sys
import urllib.request
import zipfile
from pathlib import Path

ROJO_VERSION = "7.4.4"
RAIZ = Path(__file__).resolve().parent.parent
BUILD = RAIZ / "build"
SAIDA = BUILD / "SimuladorEscudo.rbxlx"

# arquivo em assets/ -> (serviço, nome da instância)
ASSETS = {
    "Modelos.rbxm": ("ReplicatedStorage", "Modelos"),
    "Mapa.rbxm": ("Workspace", "Mapa"),
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

    destino = RAIZ / "tools" / "bin"
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
    no_path = shutil.which("rojo")
    return no_path if no_path else str(baixar_rojo())


def main() -> None:
    projeto = json.loads((RAIZ / "default.project.json").read_text(encoding="utf-8"))

    for arquivo, (servico, nome) in ASSETS.items():
        caminho = RAIZ / "assets" / arquivo
        if caminho.exists():
            projeto["tree"].setdefault(servico, {"$className": servico})
            projeto["tree"][servico][nome] = {"$path": f"assets/{arquivo}"}
            print(f"Incluindo assets/{arquivo} em {servico}.{nome}")

    # Projeto temporário na raiz para os caminhos relativos funcionarem
    temporario = RAIZ / "build.project.json"
    temporario.write_text(json.dumps(projeto, indent=2), encoding="utf-8")
    BUILD.mkdir(exist_ok=True)
    try:
        subprocess.run([encontrar_rojo(), "build", str(temporario), "-o", str(SAIDA)], check=True)
    finally:
        temporario.unlink(missing_ok=True)

    print(f"Pronto: {SAIDA}")


if __name__ == "__main__":
    main()
