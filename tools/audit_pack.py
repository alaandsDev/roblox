"""Auditoria do Anime Pack sem executar nada do pack.

    python tools/audit_pack.py                      (usa third_party/AnimePack.rbxm)
    python tools/audit_pack.py caminho/arquivo.rbxm

1. Tenta ler o arquivo direto com o Lune (tools/packaudit/audit_pack.luau).
2. Se o Lune recusar o arquivo (ex.: "Property Accessory.Tags should be SharedString"),
   o leitor tolerante tools/packaudit/rbxm_reader.py gera uma cópia LIMPA
   (third_party/AnimePack_clean.rbxmx: só nomes, classes, código dos scripts como texto e ids
   de malha/textura/roupa/animação) e a auditoria roda nela.
Nada do pack é executado em nenhum dos caminhos.
"""
import subprocess
import sys
from pathlib import Path

from run_tests import RAIZ, baixar_lune

sys.path.insert(0, str(RAIZ / "tools" / "packaudit"))
import rbxm_reader  # noqa: E402

GERADOS = "ANIME_PACK_AUDIT.md third_party/AnimePack_summary.json third_party/AnimePack_scripts.txt"


def main() -> None:
    arquivo = sys.argv[1] if len(sys.argv) > 1 else "third_party/AnimePack.rbxm"
    if not (RAIZ / arquivo).exists() and not Path(arquivo).exists():
        sys.exit(f"Arquivo não encontrado: {arquivo}\nNo Studio: botão direito em Workspace > Anime Pack > Save to File...")
    lune = baixar_lune()
    script = "tools/packaudit/audit_pack.luau"
    direto = subprocess.run([str(lune), "run", script, arquivo], cwd=RAIZ)
    if direto.returncode != 0:
        print("\nO Lune não conseguiu ler o arquivo. Usando o leitor tolerante (rbxm_reader.py)...")
        limpo = "third_party/AnimePack_clean.rbxmx"
        total = rbxm_reader.write_clean_rbxmx(rbxm_reader.read_model(str(RAIZ / arquivo)), str(RAIZ / limpo))
        print(f"Cópia limpa: {total} instâncias -> {limpo}")
        direto = subprocess.run([str(lune), "run", script, limpo, arquivo], cwd=RAIZ)
    if direto.returncode == 0:
        print("\nPronto. Agora envie os arquivos gerados:")
        print(f"  git add {GERADOS}")
        print('  git commit -m "Auditoria do Anime Pack"')
        print("  git push")
    sys.exit(direto.returncode)


if __name__ == "__main__":
    main()
