"""Auditoria ESTÁTICA do Auras Pack ("Not mine!", Creator Store 15374038687).

    python tools/audit_auras_pack.py                      (usa third_party/AurasPack.rbxm)
    python tools/audit_auras_pack.py caminho/arquivo.rbxm [--md SAIDA.md] [--json SAIDA.json]

No Studio (uma vez): botão direito no modelo do Auras Pack > Save to File... >
third_party/AurasPack.rbxm. Gera AURAS_PACK_AUDIT.md + third_party/auras_pack_report.json.

Nada do pack é executado, requerido ou baixado; o arquivo original NUNCA é alterado (SHA-256
conferido antes/depois). O pack não entra no build (tools/build_place.py não o inclui).

Leitura em camadas (cada passo registra WARNING e continua):
  0. leitor tolerante (rbxm_reader.py) SEMPRE: integridade estrutural + contagem independente;
  1. Lune numa cópia TEMPORÁRIA sem "Tags" (metadado do CollectionService que o Studio recente
     grava como SharedString e o Lune 0.10.4 recusa: "Property Animator.Tags should be
     SharedString, but it was Tags");
  2. se o Lune recusar outro METADADO conhecido (LUNE_METADATA_PROPS), ele sai da cópia e tenta de
     novo (sem loop: uma volta por metadado novo);
  3. se ainda falhar (propriedade visual/desconhecida, outro erro), a auditoria usa o leitor
     tolerante (classes, nomes, hierarquia, scripts como texto, asset IDs).
Corrupção estrutural grave (chunk INST/PRNT ilegível, arquivo truncado, referência órfã) é
reportada como ERRO no relatório e o código de saída é 3.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path

from run_tests import RAIZ, baixar_lune

sys.path.insert(0, str(RAIZ / "tools" / "packaudit"))
import auras_report  # noqa: E402
import rbxm_reader  # noqa: E402

ERRO_PROP = re.compile(r"Property (\w+)\.(\w+) should be")
DUMP = "tools/packaudit/auras_dump.luau"
TMP = RAIZ / "build" / "auras_audit"


def _nodes_to_instances(roots: list) -> list[dict]:
    out: list[dict] = []

    def visit(node, parent_index, prefix):
        path = f"{prefix}/{node.name}" if prefix else node.name
        props: dict = {}
        for key, value in node.props.items():
            if key in rbxm_reader.STRING_PROPS:
                continue
            if key in rbxm_reader.CONTENT_PROPS:
                target = rbxm_reader.CONTENT_PROPS[key]
                if target == "Texture*":
                    target = "Texture" if node.cls in ("Decal", "Texture", "ParticleEmitter", "Beam", "Trail") else "TextureID"
                props[target] = value
            else:
                props[key] = value
        record = {"class": node.cls, "name": node.name, "path": path, "parent": parent_index, "props": props}
        if node.cls in auras_report.EXEC:
            record["source"] = node.props.get("Source", "")
        out.append(record)
        index = len(out)
        for child in node.children:
            visit(child, index, path)

    for root in roots:
        visit(root, None, "")
    return out


def _run_lune(lune: Path, arquivo: Path, saida: Path) -> subprocess.CompletedProcess:
    return subprocess.run(
        [str(lune), "run", DUMP, str(arquivo), str(saida)],
        cwd=RAIZ, capture_output=True, text=True, encoding="utf-8", errors="replace",
    )


def auditar(origem: Path, md: Path, js: Path, sem_lune: bool = False) -> int:
    original = origem.read_bytes()
    hash_antes = hashlib.sha256(original).hexdigest()
    binario = original[:8] == rbxm_reader.MAGIC and original[8:14] == rbxm_reader.SIGNATURE
    info: dict = {
        "status": "", "reader": "", "attempts": [], "fallback": None, "warnings": [], "incompatibleProperties": [],
        "structuralErrors": [], "bytes": len(original), "format": "binário (.rbxm)" if binario else "XML (.rbxmx)",
        "sha256Before": hash_antes,
    }

    def warn(msg: str) -> None:
        print(f"WARNING: {msg}")
        info["warnings"].append(msg)

    # 0) leitor tolerante: integridade estrutural + contagem independente
    tolerante = None
    try:
        tolerante = _nodes_to_instances(rbxm_reader.read_model(str(origem)))
        info["tolerantCount"] = len(tolerante)
        info["tolerantSkipped"] = dict(rbxm_reader.LAST_SKIPPED) if binario else {}
        info["structuralErrors"] = list(rbxm_reader.LAST_ERRORS) if binario else []
        info["attempts"].append(f"leitor tolerante (rbxm_reader.py): {len(tolerante)} instâncias")
    except Exception as err:  # noqa: BLE001 — qualquer falha aqui é corrupção estrutural
        info["structuralErrors"].append(f"leitor tolerante falhou: {err}")
        info["attempts"].append(f"leitor tolerante: FALHOU ({err})")
    for e in info["structuralErrors"]:
        print(f"ERRO ESTRUTURAL: {e}")

    # 1-2) Lune numa cópia temporária
    instancias = None
    if not sem_lune:
        lune = baixar_lune()
        TMP.mkdir(parents=True, exist_ok=True)
        saida = TMP / "dump.json"
        remover: set[tuple[str | None, str]] = {(None, p) for p in rbxm_reader.LUNE_PREVENTIVE_PROPS} if binario else set()
        tentativa_original = True
        for _ in range(len(rbxm_reader.LUNE_METADATA_PROPS) + 3):
            arquivo = origem
            if tentativa_original:
                rotulo = "Lune 0.10.4 (rbx-dom) no arquivo original"
            else:
                dados, removidos = rbxm_reader.strip_properties(original, remover)
                arquivo = TMP / "AurasPack_lune.rbxm"
                arquivo.write_bytes(dados)
                rotulo = f"Lune na cópia temporária sem {sorted({p for _c, p in remover})}"
                for item in sorted(set(removidos)):
                    if item not in info["incompatibleProperties"]:
                        info["incompatibleProperties"].append(item)
            if saida.exists():
                saida.unlink()
            r = _run_lune(lune, arquivo, saida)
            if r.returncode == 0 and saida.exists():
                instancias = json.loads(saida.read_text(encoding="utf-8"))["instances"]
                info["attempts"].append(f"{rotulo}: OK ({len(instancias)} instâncias)")
                info["reader"] = "Lune 0.10.4 / rbx-dom" + ("" if tentativa_original else " (cópia temporária sem metadados incompatíveis)")
                break
            texto = (r.stdout + r.stderr).strip()
            erro = ERRO_PROP.search(texto)
            primeira = next((l for l in texto.splitlines() if "Type mismatch" in l or "error" in l.lower()), texto[:200])
            info["attempts"].append(f"{rotulo}: FALHOU ({primeira.strip()[:240]})")
            if not binario or not erro:
                warn(f"o Lune não leu o arquivo ({primeira.strip()[:200]}); usando o leitor tolerante")
                break
            classe, prop = erro.group(1), erro.group(2)
            tipo = rbxm_reader.classify_property(prop)
            if tentativa_original:
                warn(f"Type mismatch em {classe}.{prop} (tipo gravado pelo Studio ≠ esquema do Lune). "
                     f"{'Metadado sem uso na auditoria: ignorado na cópia temporária.' if tipo == 'metadata' else 'Propriedade ' + tipo + '.'}")
                tentativa_original = False
                if tipo == "metadata":
                    remover.add((None, prop))
                continue
            if (None, prop) in remover:
                warn(f"o Lune continua recusando {classe}.{prop} mesmo sem ela; usando o leitor tolerante")
                break
            if tipo != "metadata":
                warn(f"o Lune recusou {classe}.{prop} ({tipo}): não é removida; usando o leitor tolerante")
                break
            warn(f"Type mismatch em {classe}.{prop} (metadado): ignorado na cópia temporária")
            remover.add((None, prop))
        else:
            warn("limite de tentativas do Lune atingido; usando o leitor tolerante")

    if instancias is None:
        if tolerante is None:
            info["status"] = "FALHA: nenhum leitor conseguiu ler o arquivo"
            info["reader"] = "nenhum"
            instancias = []
        else:
            instancias = tolerante
            info["reader"] = "leitor tolerante estático (tools/packaudit/rbxm_reader.py)"
            info["fallback"] = ("Leitor tolerante estático em Python: classes, nomes, hierarquia, scripts como texto, "
                                "asset IDs e flags Disabled/Enabled. Parâmetros numéricos de VFX (Rate, Lifetime…) "
                                "não são decodificados neste modo.")
    elif not info["incompatibleProperties"] and info["attempts"] and "original" in info["attempts"][-1]:
        info["fallback"] = None
    else:
        info["fallback"] = ("Cópia TEMPORÁRIA (build/auras_audit/AurasPack_lune.rbxm) sem os metadados incompatíveis "
                            f"{info['incompatibleProperties']}; os demais chunks são idênticos byte a byte ao original.")
    if tolerante is not None and instancias is not tolerante and len(tolerante) != len(instancias):
        warn(f"contagem divergente: Lune {len(instancias)} × leitor tolerante {len(tolerante)}")

    if not info["status"]:
        info["status"] = "OK com erros estruturais" if info["structuralErrors"] else ("OK com warnings" if info["warnings"] else "OK")
    info["sha256After"] = hashlib.sha256(origem.read_bytes()).hexdigest()
    if info["sha256After"] != hash_antes:
        info["structuralErrors"].append("o arquivo original mudou durante a auditoria")

    rep = auras_report.analyze(instancias, info)
    md.parent.mkdir(parents=True, exist_ok=True)
    js.parent.mkdir(parents=True, exist_ok=True)
    try:
        rotulo = str(origem.resolve().relative_to(RAIZ))
    except ValueError:
        rotulo = origem.name
    auras_report.write_markdown(rep, str(md), rotulo)
    auras_report.write_json(rep, str(js))
    t = rep["totals"]
    print(f"\n{md.name}: {t['instances']} instâncias, {t['scripts']} scripts, {t['remotes']} remotes, "
          f"{t['bindables']} bindables, {t['particleEmitters']} emitters, {t['beams']} beams, {t['trails']} trails, "
          f"{t['groups']} grupos — leitor: {info['reader']}")
    print(f"Relatórios: {md} e {js}. NADA do pack foi integrado ao jogo.")
    if info["status"].startswith("FALHA"):
        return 2
    return 3 if info["structuralErrors"] else 0


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("arquivo", nargs="?", default="third_party/AurasPack.rbxm")
    parser.add_argument("--md", default="AURAS_PACK_AUDIT.md")
    parser.add_argument("--json", default="third_party/auras_pack_report.json")
    parser.add_argument("--sem-lune", action="store_true", help="(testes) usa só o leitor tolerante")
    args = parser.parse_args()
    origem = Path(args.arquivo)
    if not origem.is_absolute():
        origem = RAIZ / origem
    if not origem.is_file():
        print(f"Arquivo não encontrado: {args.arquivo}")
        print("No Studio: botão direito no modelo do Auras Pack > Save to File... > third_party/AurasPack.rbxm")
        sys.exit(1)
    md, js = Path(args.md), Path(args.json)
    sys.exit(auditar(origem, md if md.is_absolute() else RAIZ / md, js if js.is_absolute() else RAIZ / js, args.sem_lune))


if __name__ == "__main__":
    main()
