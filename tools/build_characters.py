"""Gera os CHARACTER ASSETS sanitizados do Roll Legends a partir do Anime Pack (sem executar nada do pack).

    python tools/build_characters.py                          (usa third_party/AnimePack.rbxm)
    python tools/build_characters.py caminho/pack.rbxm         (ou o place inteiro .rbxl)
    python tools/build_characters.py pack.rbxm --out assets/Characters.rbxm --strip Classe.Prop

1. Cópia TEMPORÁRIA para o Lune (build/AnimePack_lune.rbxm): sai, de forma preventiva, a
   propriedade serializada "Tags" (tags do CollectionService) de TODAS as classes — o Lune
   0.10.4 recusa o tipo com que o Studio grava essa propriedade. A cópia é feita chunk a chunk
   (rbxm_reader.strip_properties): os chunks mantidos são idênticos byte a byte.
2. Roda o CharacterAssetPipeline REAL com o Lune (tools/characters/build_characters.luau).
3. Se o Lune ainda recusar uma propriedade ("Property Classe.Prop should be ..."):
   - metadado NÃO visual conhecido (rbxm_reader.LUNE_METADATA_PROPS) -> sai da cópia em todas as
     classes e tenta de novo (uma vez por propriedade: não há limite arbitrário de tentativas);
   - propriedade VISUAL ou desconhecida -> ABORTA com diagnóstico (nada visual é removido);
   - o mesmo erro depois de remover -> ABORTA (sem loop).
4. Confere por estrutura que a cópia só perdeu metadados, que nomes/malhas/texturas/roupas/rostos
   lidos pelo leitor tolerante são idênticos e que o arquivo ORIGINAL não mudou (SHA-256).
5. Gera assets/Characters.rbxm (vira ReplicatedStorage.CharacterAssets no build_place.py),
   CHARACTER_LAUNCH_AUDIT.md, CLOTHING_AUDIT.md (uma linha por AssetId de roupa) e
   third_party/character_launch_report.json.
O pack original nunca é alterado e nunca entra no build.
"""
import argparse
import hashlib
import re
import subprocess
import sys
from pathlib import Path

from run_tests import RAIZ, baixar_lune

sys.path.insert(0, str(RAIZ / "tools" / "packaudit"))
import rbxm_reader  # noqa: E402

SCRIPT = "tools/characters/build_characters.luau"
CONFIG = RAIZ / "src" / "shared" / "Config" / "CharacterAssetConfig.luau"
# Personagens = entradas "char_..." de CharacterAssetConfig.Assets (pilotos curados + bloco gerado)
PILOTOS = sorted(set(re.findall(r"^\t(char_[a-z0-9_]+) = \{", CONFIG.read_text(encoding="utf-8"), re.M)))


def _conteudo_visual(dados: bytes) -> list[tuple]:
    """Leitura ESTRUTURADA (leitor tolerante): classe, nome e propriedades de conteúdo
    (MeshId, TextureID, Decal.Texture, ShirtTemplate, PantsTemplate...) de cada instância."""
    import tempfile

    with tempfile.NamedTemporaryFile(suffix=".rbxm", delete=False) as f:
        f.write(dados)
        caminho = f.name
    try:
        import contextlib
        import io

        with contextlib.redirect_stdout(io.StringIO()):
            raizes = rbxm_reader.read_model(caminho)
    finally:
        Path(caminho).unlink(missing_ok=True)
    out: list[tuple] = []

    def visitar(no, caminho_no):
        atual = f"{caminho_no}.{no.name}"
        visuais = tuple(sorted((k, str(v)) for k, v in no.props.items() if k in rbxm_reader.CONTENT_PROPS))
        out.append((atual, no.cls, visuais))
        for filho in no.children:
            visitar(filho, atual)

    for raiz in raizes:
        visitar(raiz, "")
    return out


def _agrupar(removidos: list[str]) -> list[str]:
    vistos: list[str] = []
    for item in removidos:
        if item not in vistos:
            vistos.append(item)
    return sorted(vistos)


ERRO_PROP = re.compile(r"Property (\w+)\.(\w+) should be")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("pack", nargs="?", default="third_party/AnimePack.rbxm")
    parser.add_argument("--out", default="assets/Characters.rbxm")
    parser.add_argument("--report", default="CHARACTER_LAUNCH_AUDIT.md")
    parser.add_argument("--json", default="third_party/character_launch_report.json")
    parser.add_argument("--clothing", default="CLOTHING_AUDIT.md")
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
    original = origem.read_bytes()
    hash_antes = hashlib.sha256(original).hexdigest()
    binario = original[:8] == rbxm_reader.MAGIC and original[8:14] == rbxm_reader.SIGNATURE

    remover: set[tuple[str | None, str]] = set()
    if binario:
        remover |= {(None, prop) for prop in rbxm_reader.LUNE_PREVENTIVE_PROPS}
    for item in args.strip:
        classe, _, prop = item.partition(".")
        remover.add((classe or None, prop))

    temporario = RAIZ / "build" / "AnimePack_lune.rbxm"
    removidos: list[str] = []
    erro_anterior = None
    r = None
    # Cada volta só acontece se uma propriedade NOVA de metadado entrar na lista: termina sempre
    # (no máximo uma volta por metadado conhecido + 1).
    for _ in range(len(rbxm_reader.LUNE_METADATA_PROPS) + len(args.strip) + 2):
        arquivo = origem
        if binario and remover:
            dados, removidos = rbxm_reader.strip_properties(original, remover)
            temporario.parent.mkdir(exist_ok=True)
            temporario.write_bytes(dados)
            arquivo = temporario
        print(f"Building {len(PILOTOS)} launch characters...")
        r = subprocess.run(
            [str(lune), "run", SCRIPT, str(arquivo), args.out, args.report, args.json, origem.name, args.clothing],
            cwd=RAIZ,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
        )
        if r.returncode in (0, 2):
            break
        erro = ERRO_PROP.search(r.stdout + r.stderr)
        if not erro:
            sys.stdout.write(r.stdout)
            sys.stderr.write(r.stderr)
            print("\nABORTADO: o Lune falhou com um erro que não é de propriedade incompatível (acima).")
            return r.returncode or 1
        classe, prop = erro.group(1), erro.group(2)
        tipo = rbxm_reader.classify_property(prop)
        if (classe, prop) == erro_anterior or (None, prop) in remover or (classe, prop) in remover:
            print(f"\nABORTADO: o Lune continua recusando {classe}.{prop} mesmo depois de removida da cópia.")
            print("Sem progresso: nada mais é tentado. Mande esta mensagem para análise.")
            return 1
        if tipo == "visual":
            print(f"\nABORTADO: o Lune recusou {classe}.{prop}, que é uma propriedade VISUAL.")
            print("Ela NÃO é removida automaticamente (mudaria o personagem). Mande esta mensagem para análise.")
            return 1
        if tipo == "unknown":
            print(f"\nABORTADO: o Lune recusou {classe}.{prop}, que não está na lista de metadados não visuais.")
            print("Por segurança ela não é removida. Se for metadado do Studio, adicione em")
            print("tools/packaudit/rbxm_reader.py (LUNE_METADATA_PROPS) ou rode com --strip " + f"{classe}.{prop}")
            return 1
        print(f"O Lune recusou o metadado {classe}.{prop}: removendo '{prop}' de todas as classes na cópia temporária...")
        erro_anterior = (classe, prop)
        remover.add((None, prop))
    else:
        print("\nABORTADO: limite de segurança atingido sem leitura bem-sucedida.")
        return 1

    # Verificação: a cópia só perdeu metadados e o original não mudou
    visuais: list[str] = []
    if binario and removidos:
        conferidos = rbxm_reader.dropped_properties(original, temporario.read_bytes())
        visuais = [x for x in conferidos if rbxm_reader.classify_property(x.split(".", 1)[1]) == "visual"]
        identico = _conteudo_visual(original) == _conteudo_visual(temporario.read_bytes())
    else:
        identico = True
    hash_depois = hashlib.sha256(origem.read_bytes()).hexdigest()
    print("\nTemporary source sanitization:\n")
    print("Removed incompatible metadata:")
    for item in _agrupar(removidos) or ["(nada)"]:
        print(f"- {item}")
    print(f"\nVisual properties removed: {len(visuais)}")
    print(f"Kept chunks byte-identical (CFrame, size, cor, BodyColors, soldas, attachments): {'YES' if binario else 'n/a (XML)'}")
    print(f"Visual content identical (names, MeshId, TextureId, Decals, Shirt/Pants): {'YES' if identico else 'NO'}")
    print(f"Original Anime Pack modified: {'NO' if hash_antes == hash_depois else 'YES'}\n")
    sys.stdout.write(r.stdout)
    if r.returncode == 2:
        sys.stderr.write(r.stderr)
    if visuais or not identico or hash_antes != hash_depois:
        print("ABORTADO: a verificação da cópia temporária falhou (veja acima).")
        return 1
    saida = Path(args.out) if Path(args.out).is_absolute() else RAIZ / args.out
    if r.returncode in (0, 2) and saida.exists():
        import contextlib
        import io

        with contextlib.redirect_stdout(io.StringIO()):
            raizes = rbxm_reader.read_model(str(saida))
        gerados = sorted(n.name for raiz in raizes for n in raiz.children if n.cls == "Model")
        faltando = [p for p in PILOTOS if p not in gerados]
        print(f"\n{saida.name}: {len(gerados)}/{len(PILOTOS)} personagens de lançamento")
        if faltando:
            print(f"Faltando: {', '.join(faltando)}")

    if r.returncode == 2:
        print("\nATENÇÃO: há personagens FAIL ou MISSING_SOURCE (veja o relatório) — o asset contém só os que passaram.")
    if r.returncode in (0, 2):
        print('\nConfira no Studio (Barra de comandos, aba SERVER): game.ServerStorage.RollLegendsDev:Invoke("CharacterGalleryPage", 1)')
        print("e envie:")
        print(f"  git add {args.out} {args.report} {args.json} {args.clothing}")
        print('  git commit -m "chore: sanitized launch character assets"')
        print("  git push")
    return r.returncode


if __name__ == "__main__":
    sys.exit(main())
