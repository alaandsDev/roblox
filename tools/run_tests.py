"""Roda os testes puros (fora do Roblox) + checagens estáticas.

Uso:  python tools\\run_tests.py

- Baixa o interpretador "luau" (versão fixa) para tools/bin na primeira vez.
- Roda tests/run.luau (TableUtil, NumberFormatter, RateLimiter, Validator,
  ProfileCore/session lock, ReceiptCore/idempotência, Configs, Localization).
- Confere se toda chave de texto usada no código existe em Localization/PtBR.luau.
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
                if chave not in chaves:
                    erros.append(f"{arquivo.relative_to(RAIZ)}: chave de texto '{chave}' não existe no PtBR.luau")
    return erros


def main() -> None:
    erros = checar_textos()
    for erro in erros:
        print("✗", erro)
    print(f"Checagem de textos: {'OK' if not erros else f'{len(erros)} erro(s)'}")

    luau = baixar_luau()
    resultado = subprocess.run([str(luau), "tests/run.luau"], cwd=RAIZ)
    if erros or resultado.returncode != 0:
        sys.exit(1)


if __name__ == "__main__":
    main()
