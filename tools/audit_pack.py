"""Auditoria do Anime Pack sem executar nada do pack.

    python tools/audit_pack.py                      (usa third_party/AnimePack.rbxm)
    python tools/audit_pack.py caminho/arquivo.rbxm

Baixa o Lune (se preciso, igual ao run_tests.py) e roda tools/packaudit/audit_pack.luau.
"""
import subprocess
import sys

from run_tests import RAIZ, baixar_lune


def main() -> None:
    arquivo = sys.argv[1] if len(sys.argv) > 1 else "third_party/AnimePack.rbxm"
    lune = baixar_lune()
    resultado = subprocess.run([str(lune), "run", "tools/packaudit/audit_pack.luau", arquivo], cwd=RAIZ)
    sys.exit(resultado.returncode)


if __name__ == "__main__":
    main()
