"""Roda os testes fora do Roblox + checagens estáticas.

Uso:  python tools\\run_tests.py

1. Checagem de textos: toda chave usada no código existe em Localization/PtBR.luau.
2. Testes puros (binário "luau"): tests/run.luau.
3. Teste headless do mapa (runtime "Lune", que simula Instances do Roblox):
   tests/roblox/MapHarness.luau executa o MapService/MapBuilder/BaseBuilder REAIS,
   roda o MapValidator e testa RB0/RB5/dono. Gera build/map_preview.json.
   tests/roblox/ServiceHarness.luau e GameplayHarness.luau: integração dos Services reais
   (base, roll, inventário, estações, economia, venda, dados, offline, diário).
   tests/roblox/ClientHarness.luau: servidor + interface do cliente de ponta a ponta.
   tests/roblox/SessionHarness.luau: smoke do ciclo completo (save/load) + sessão longa de 10 jogadores.
   tests/roblox/CharacterPipelineHarness.luau: pipeline de personagens com um pack SINTÉTICO
   (sanitização, .rbxm, jogo final SEM o pack, factory/variantes/poses/fallback) e
   tests/build_characters_test.py: a ferramenta tools/build_characters.py de ponta a ponta e
   tests/build_characters_lune_test.py: Tags incompatível em várias classes (fallback do Lune) e
   tests/build_place_test.py: o build inclui ReplicatedStorage.CharacterAssets (10 pilotos).
4. Se o Pillow estiver instalado, desenha build/map_preview.png (vista de cima).
Os binários (versões fixas) são baixados para tools/bin na primeira vez.
"""

import io
import platform
import re
import subprocess
import sys
import urllib.request
import zipfile
from pathlib import Path

LUAU_VERSION = "0.700"
LUNE_VERSION = "0.10.4"
RAIZ = Path(__file__).resolve().parent.parent


def baixar_luau() -> Path:
    sistema = platform.system()
    nome_zip = {"Windows": "luau-windows.zip", "Linux": "luau-ubuntu.zip", "Darwin": "luau-macos.zip"}.get(sistema)
    if not nome_zip:
        sys.exit(f"Sistema {sistema} não suportado.")
    destino = RAIZ / "tools" / "bin" / f"luau-{LUAU_VERSION}"
    executavel = destino / ("luau.exe" if sistema == "Windows" else "luau")
    if not executavel.exists():
        url = f"https://github.com/luau-lang/luau/releases/download/{LUAU_VERSION}/{nome_zip}"
        print(f"Baixando luau {LUAU_VERSION}...")
        with urllib.request.urlopen(url) as resposta:
            zipfile.ZipFile(io.BytesIO(resposta.read())).extractall(destino)
        executavel.chmod(0o755)
    return executavel


def baixar_lune() -> Path:
    sistema = platform.system()
    maquina = platform.machine().lower()
    arquitetura = "aarch64" if maquina in ("arm64", "aarch64") else "x86_64"
    nome = {"Windows": "windows", "Linux": "linux", "Darwin": "macos"}.get(sistema)
    if not nome:
        sys.exit(f"Sistema {sistema} não suportado.")
    destino = RAIZ / "tools" / "bin" / f"lune-{LUNE_VERSION}"
    executavel = destino / ("lune.exe" if sistema == "Windows" else "lune")
    if not executavel.exists():
        url = f"https://github.com/lune-org/lune/releases/download/v{LUNE_VERSION}/lune-{LUNE_VERSION}-{nome}-{arquitetura}.zip"
        print(f"Baixando lune {LUNE_VERSION}...")
        with urllib.request.urlopen(url) as resposta:
            zipfile.ZipFile(io.BytesIO(resposta.read())).extractall(destino)
        executavel.chmod(0o755)
    return executavel


def checar_textos() -> list[str]:
    """Toda chave passada para Notify/Localization.t/kick precisa existir no PtBR."""
    ptbr = (RAIZ / "src/shared/Localization/PtBR.luau").read_text(encoding="utf-8")
    chaves = set(re.findall(r'\["([\w.]+)"\]\s*=', ptbr))
    padroes = [
        r'Net\.fire(?:All)?\("Notify",[^,\n]*,\s*"([\w.]+)"',
        r'Localization\.t\("([\w.]+)"',
        r'kick\(\s*player,\s*"([\w.]+)"',
        r'then\s+"(data\.[\w.]+)"',
        r'else\s+"(data\.[\w.]+)"',
        r'NotificationController\.Show\("([\w.]+)"',
    ]
    erros = []
    for arquivo in (RAIZ / "src").rglob("*.luau"):
        texto = arquivo.read_text(encoding="utf-8")
        for padrao in padroes:
            for chave in re.findall(padrao, texto):
                # "rarity." .. id = família dinâmica (conferida em tests/Config.spec.luau)
                if chave.endswith("."):
                    continue
                if chave not in chaves:
                    erros.append(f"{arquivo.relative_to(RAIZ)}: chave de texto '{chave}' não existe no PtBR.luau")
    return erros


def main() -> None:
    erros = checar_textos()
    for erro in erros:
        print("✗", erro)
    print(f"Checagem de textos: {'OK' if not erros else f'{len(erros)} erro(s)'}")

    luau = baixar_luau()
    puros = subprocess.run([str(luau), "tests/run.luau"], cwd=RAIZ)

    lune = baixar_lune()
    mapa = subprocess.run([str(lune), "run", "tests/roblox/MapHarness.luau"], cwd=RAIZ)
    servicos = subprocess.run([str(lune), "run", "tests/roblox/ServiceHarness.luau"], cwd=RAIZ)
    gameplay = subprocess.run([str(lune), "run", "tests/roblox/GameplayHarness.luau"], cwd=RAIZ)
    cliente = subprocess.run([str(lune), "run", "tests/roblox/ClientHarness.luau"], cwd=RAIZ)
    sessao = subprocess.run([str(lune), "run", "tests/roblox/SessionHarness.luau"], cwd=RAIZ)
    pack = subprocess.run([str(lune), "run", "tests/roblox/PackAuditHarness.luau"], cwd=RAIZ)
    personagens = subprocess.run([str(lune), "run", "tests/roblox/CharacterPipelineHarness.luau"], cwd=RAIZ)
    leitor = subprocess.run([sys.executable, "tests/rbxm_reader_test.py"], cwd=RAIZ)
    ferramenta = subprocess.run([sys.executable, "tests/build_characters_test.py"], cwd=RAIZ)
    compat = subprocess.run([sys.executable, "tests/build_characters_lune_test.py"], cwd=RAIZ)
    place = subprocess.run([sys.executable, "tests/build_place_test.py"], cwd=RAIZ)

    if mapa.returncode == 0:
        try:
            import PIL  # noqa: F401

            subprocess.run([sys.executable, str(RAIZ / "tools" / "render_map_preview.py")], cwd=RAIZ)
        except ImportError:
            print("(Pillow não instalado: pulando a imagem do mapa)")

    if erros or puros.returncode != 0 or mapa.returncode != 0 or servicos.returncode != 0 or gameplay.returncode != 0 or cliente.returncode != 0 or sessao.returncode != 0 or pack.returncode != 0 or personagens.returncode != 0 or leitor.returncode != 0 or ferramenta.returncode != 0 or compat.returncode != 0 or place.returncode != 0:
        sys.exit(1)


if __name__ == "__main__":
    main()
