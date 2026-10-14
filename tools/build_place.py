"""Gera build/RollLegends.rbxlx a partir do código (src/) + assets salvos do Studio.

Uso:  python tools\\build_place.py

- Baixa sozinho a versão certa do Rojo para tools/bin (versões antigas não leem
  arquivos .rbxm salvos pelo Studio atual, por isso não usamos o Rojo do PATH).
- Se existir assets/Assets.rbxm, vira ReplicatedStorage.Assets (sons, VFX, ícones, modelos).
- Se existir assets/Map.rbxm, vira Workspace.Map (decoração feita no Studio).
- Se existir assets/ClassicRobloxSky.rbxm, vira Lighting.ClassicRobloxSky (céu escolhido).
- Se existir assets/Characters.rbxm (gerado por tools/build_characters.py), vira
  ReplicatedStorage.CharacterAssets (personagens sanitizados; o Anime Pack nunca entra no build).
"""

import io
import json
import xml.etree.ElementTree as ET
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
    # Céu escolhido (Classic Roblox Sky, asset 339406852) salvo do Studio: Lighting > Sky >
    # botão direito > Save to File... > assets/ClassicRobloxSky.rbxm (o MapBuilder reutiliza)
    "ClassicRobloxSky.rbxm": ("Lighting", "ClassicRobloxSky"),
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


SKY_ASSET = "ClassicRobloxSky.rbxm"


def checar_sky_rbxm(caminho: Path) -> None:
    """O .rbxm do céu precisa ter exatamente 1 Sky (na raiz ou dentro de um contêiner)."""
    sys.path.insert(0, str(RAIZ / "tools" / "packaudit"))
    import rbxm_reader

    raizes = rbxm_reader.read_model(str(caminho))
    skies = []

    def visitar(no):
        if no.cls == "Sky":
            skies.append(no)
        for filho in no.children:
            visitar(filho)

    for r in raizes:
        visitar(r)
    if len(raizes) != 1 or len(skies) != 1:
        sys.exit(f"ERRO: {caminho.name} deve ter 1 raiz e exatamente 1 Sky (achei {len(raizes)} raiz(es), {len(skies)} Sky)")
    raiz = raizes[0]
    forma = "Sky na raiz" if raiz.cls == "Sky" else f"{raiz.cls} com o Sky dentro (o MapBuilder move o Sky para Lighting)"
    print(f"  {caminho.name}: 1 Sky ({forma})")


def validar_sky(saida: Path, com_classic: bool) -> None:
    """Depois do build: Lighting com no máximo 1 Sky; exatamente 1 (o ClassicRobloxSky) quando o
    asset existe. Sem ele, o MapBuilder usa o Sky de ReplicatedStorage.Assets como reserva."""
    raiz = ET.parse(saida).getroot()
    lighting = next((i for i in raiz.iter("Item") if i.get("class") == "Lighting"), None)
    skies = [i for i in lighting.iter("Item") if i.get("class") == "Sky"] if lighting is not None else []
    if com_classic and len(skies) != 1:
        sys.exit(f"ERRO: Lighting deveria ter exatamente 1 Sky (ClassicRobloxSky), tem {len(skies)}")
    if len(skies) > 1:
        sys.exit(f"ERRO: Lighting tem {len(skies)} Skies competindo")
    if com_classic:
        print("Validação do céu: exatamente 1 Sky em Lighting (ClassicRobloxSky)")
    else:
        print(f"AVISO: assets/{SKY_ASSET} ausente — Lighting sem Sky no build; em runtime o MapBuilder usa o Sky de ReplicatedStorage.Assets (reserva)")


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
            if arquivo == SKY_ASSET:
                checar_sky_rbxm(caminho)
            projeto["tree"].setdefault(servico, {"$className": servico})
            projeto["tree"][servico][nome] = {"$path": os.path.relpath(caminho, RAIZ).replace(os.sep, "/")}
            print(f"Incluindo {caminho.name} em {servico}.{nome}")

    # Packs de terceiros (third_party/, ex.: AurasPack.rbxm) nunca entram no build
    if "third_party" in json.dumps(projeto):
        sys.exit("ERRO: o projeto referencia third_party/ (packs de terceiros não entram no build)")

    # Projeto temporário na raiz para os caminhos relativos funcionarem
    temporario = RAIZ / "build.project.json"
    temporario.write_text(json.dumps(projeto, indent=2), encoding="utf-8")
    saida.parent.mkdir(parents=True, exist_ok=True)
    try:
        subprocess.run([encontrar_rojo(), "build", str(temporario), "-o", str(saida)], check=True)
    finally:
        temporario.unlink(missing_ok=True)

    validar_sky(saida, (pasta / SKY_ASSET).exists())
    print(f"Pronto: {saida}")

if __name__ == "__main__":
    main()
