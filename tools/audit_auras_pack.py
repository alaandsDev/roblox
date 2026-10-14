"""Auditoria do Auras Pack ("Not mine!", Creator Store 15374038687) sem executar nada do pack.

    python3 tools/audit_auras_pack.py                      (usa third_party/AurasPack.rbxm)
    python3 tools/audit_auras_pack.py caminho/arquivo.rbxm

No Studio (uma vez): botão direito no modelo do Auras Pack > Save to File... >
third_party/AurasPack.rbxm. Gera AURAS_PACK_AUDIT.md + third_party/AurasPack_components.json.
O pack nunca entra no build (tools/build_place.py não o inclui).
"""
import subprocess
import sys

from run_tests import RAIZ, baixar_lune


def main() -> None:
    arquivo = sys.argv[1] if len(sys.argv) > 1 else "third_party/AurasPack.rbxm"
    lune = baixar_lune()
    sys.exit(subprocess.run([str(lune), "run", "tools/packaudit/audit_auras.luau", arquivo], cwd=RAIZ).returncode)


if __name__ == "__main__":
    main()
