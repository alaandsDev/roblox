"""Regressão do auditor do Auras Pack (tools/audit_auras_pack.py).

Bug real: `python tools/audit_auras_pack.py` morria com
    "Failed to read document from buffer - Type mismatch: Property Animator.Tags should be
     SharedString, but it was Tags"
porque o Studio recente grava a propriedade "Tags" (CollectionService) como SharedString e o
Lune 0.10.4 (rbx-dom) espera o tipo Tags. Este teste monta um pack SINTÉTICO com o mesmo defeito
e confere que a auditoria NÃO quebra, registra WARNING, continua e ainda detecta scripts e VFX —
sem executar nada do pack e sem alterar o arquivo original. Também cobre: Tags em todas as
classes, propriedade desconhecida (cai no leitor tolerante), modo só-estático e arquivo truncado
(corrupção estrutural reportada, sem crash).
"""
import hashlib
import json
import os
import struct
import subprocess
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
# Subprocessos Python escrevem em UTF-8 mesmo com a saída capturada: no Windows o padrão em pipe é
# cp1252 e "lançamento"/"·"/"ATENÇÃO" chegavam corrompidos (as checagens de texto falhavam).
UTF8_ENV = {**os.environ, "PYTHONIOENCODING": "utf-8", "PYTHONUTF8": "1"}
sys.path.insert(0, str(RAIZ / "tools"))
sys.path.insert(0, str(RAIZ / "tools" / "packaudit"))
import rbxm_reader as R  # noqa: E402
from run_tests import baixar_lune  # noqa: E402

TMP = RAIZ / "build" / "auras_audit_test"


def _inst_info(raw: bytes) -> tuple[int, str, int]:
    compressed, size = struct.unpack_from("<II", raw, 4)
    payload = raw[16:16 + (compressed or size)]
    body = payload if not compressed else (R.zstd_decompress(payload, size) if payload[:4] == R.ZSTD_MAGIC else R.lz4_block(payload, size))
    r = R.Reader(body)
    type_id = r.u32()
    cls = R._text(r.string())
    r.u8()
    return type_id, cls, r.u32()


def _prop(type_id: int, name: str, kind: int, values: bytes) -> bytes:
    body = struct.pack("<I", type_id) + struct.pack("<I", len(name)) + name.encode() + bytes([kind]) + values
    return b"PROP" + struct.pack("<III", 0, len(body), 0) + body


def _interleave(values, width=4):
    raw = [v.to_bytes(width, "big") for v in values]
    return bytes(raw[k][b] for b in range(width) for k in range(len(values)))


def defeituoso(data: bytes, tag_classes: set[str] | None, extra: tuple[str, str] | None = None) -> bytes:
    """Troca o chunk Tags original por Tags como SharedString (0x1C) nas classes pedidas
    (None = todas) + opcionalmente uma propriedade com tipo errado (String) em outra classe."""
    out = bytearray(data[:32])
    classes: dict[str, tuple[int, int]] = {}
    for name, raw, cls, prop in R.iter_chunks(data):
        if name == "INST":
            type_id, c, count = _inst_info(raw)
            classes[c] = (type_id, count)
        if name == "PROP" and prop == "Tags":
            continue  # o original (tipo String) sai; entra a versão SharedString abaixo
        if name == "PRNT":
            sstr = struct.pack("<II", 0, 1) + b"\x00" * 16 + struct.pack("<I", 12) + b"AuraAnimator"
            out += b"SSTR" + struct.pack("<III", 0, len(sstr), 0) + sstr
            for c, (type_id, count) in sorted(classes.items()):
                if tag_classes is None or c in tag_classes:
                    out += _prop(type_id, "Tags", 0x1C, _interleave([0] * count))
            if extra:
                type_id, count = classes[extra[0]]
                out += _prop(type_id, extra[1], 0x01, b"".join(struct.pack("<I", 0) for _ in range(count)))
        out += raw
    return bytes(out)


def auditar(pack: Path, nome: str, *extra: str):
    md, js = TMP / f"{nome}.md", TMP / f"{nome}.json"
    md.unlink(missing_ok=True)
    js.unlink(missing_ok=True)
    r = subprocess.run(
        [sys.executable, "tools/audit_auras_pack.py", str(pack), "--md", str(md), "--json", str(js), *extra],
        cwd=RAIZ, capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=300, env=UTF8_ENV,
    )
    rep = json.loads(js.read_text(encoding="utf-8")) if js.exists() else None
    texto = md.read_text(encoding="utf-8") if md.exists() else ""
    return r, rep, texto


def main() -> int:
    falhas = 0

    def check(cond, msg):
        nonlocal falhas
        print(("  ✓ " if cond else "  ✗ ") + msg)
        if not cond:
            falhas += 1

    print("\n[Auditor do Auras Pack: Animator.Tags incompatível (regressão)]")
    TMP.mkdir(parents=True, exist_ok=True)
    base = TMP / "pack.rbxm"
    lune = baixar_lune()
    g = subprocess.run([str(lune), "run", "tests/roblox/SyntheticAurasPack.luau", str(base)], cwd=RAIZ, capture_output=True, text=True, encoding="utf-8", errors="replace")
    if g.returncode != 0 or not base.exists():
        print("  ✗ não gerou o pack sintético:", g.stdout, g.stderr)
        return 1
    limpo = base.read_bytes()

    # 0) reprodução: o Lune puro recusa exatamente como no pack real
    pack = TMP / "pack_animator_tags.rbxm"
    pack.write_bytes(defeituoso(limpo, {"Animator"}))
    probe = TMP / "probe.luau"
    probe.write_text('local r = require("@lune/roblox"); local fs = require("@lune/fs"); local p = require("@lune/process")\n'
                     'local ok, e = pcall(r.deserializeModel, fs.readFile(p.args[1])); print(ok, e)\n')
    pr = subprocess.run([str(lune), "run", str(probe), str(pack)], cwd=RAIZ, capture_output=True, text=True, encoding="utf-8", errors="replace")
    check("Property Animator.Tags should be SharedString, but it was Tags" in pr.stdout + pr.stderr,
          "reproduz o erro real: 'Type mismatch: Property Animator.Tags should be SharedString, but it was Tags'")

    # 1) Animator.Tags incompatível: não quebra, WARNING, continua, detecta scripts e VFX
    hash_antes = hashlib.sha256(pack.read_bytes()).hexdigest()
    r, rep, md = auditar(pack, "animator_tags")
    check(r.returncode == 0, f"auditoria termina sem crash (código {r.returncode})")
    check(rep is not None and md != "", "gera o relatório .md e o .json")
    if rep:
        read, t = rep["read"], rep["totals"]
        check("WARNING: Type mismatch em Animator.Tags" in r.stdout and any("Animator.Tags" in w for w in read["warnings"]), "WARNING registrado (stdout e relatório) para Animator.Tags")
        check(read["reader"].startswith("Lune") and "Animator.Tags" in read["incompatibleProperties"], "análise continua no Lune com a cópia temporária sem Tags")
        check(t["scripts"] == 3 and {s["class"] for s in rep["scripts"]} == {"Script", "LocalScript", "ModuleScript"}, f"scripts detectados ({t['scripts']}: Script, LocalScript, ModuleScript)")
        check(t["particleEmitters"] == 7 and t["beams"] == 1 and t["trails"] == 1 and t["lights"] == 1, f"VFX detectados (emitters {t['particleEmitters']}, beams {t['beams']}, trails {t['trails']}, lights {t['lights']})")
        check(t["remotes"] == 1 and t["bindables"] == 1 and t["moversConstraints"] == 1 and t["humanoids"] == 1, "remotes, bindables, body mover e Humanoid detectados")
        check(rep["catalog"]["Animator"] == 1 and rep["catalog"]["Animation"] == 1, "Animator (com a Tags incompatível) e Animation catalogados — nada foi apagado")
        flags = {f for s in rep["scripts"] for f in s["flags"]}
        check(any("require" in f for f in flags) and "loadstring" in flags, "padrões de risco no código (require(número), loadstring) achados como TEXTO")
        disabled = {s["name"]: s["disabled"] for s in rep["scripts"]}
        check(disabled.get("Spin") is True and all(len(s["sha256"]) == 64 for s in rep["scripts"]), "Disabled e SHA-256 por script")
        check("require(123456789)" not in md and "loadstring('x')" not in md and "OnServerEvent:Connect" not in md
              and "source" not in json.dumps(rep["scripts"]), "código-fonte NÃO aparece no relatório (só tamanho/hash/padrões)")
        ids = {a["id"]: a for a in rep["assets"]}
        check({"1111111", "2222222", "3333333", "4444444", "5555555", "6666666", "123456789"} <= set(ids) and ids["1111111"]["uses"] == 3,
              "asset IDs com tipo, contagem de uso e caminhos (inclusive require no código)")
        estilos = {gp["name"]: gp["style"] for gp in rep["groups"]}
        check(estilos.get("Electric Aura") == "Electric" and estilos.get("Fire Aura") == "Flame" and estilos.get("Void Ring") == "Void",
              f"grupos de aura classificados ({estilos})")
        risco = {gp["name"]: gp["risk"] for gp in rep["groups"]}
        check(risco.get("Electric Aura") == "ALTO" and risco.get("Void Ring") == "BAIXO", "risco por grupo (script = ALTO; só VFX nativo = BAIXO)")
        check(rep["verdict"]["integrated"] is False and rep["verdict"]["provenanceVerified"] is False, "SEGURO TECNICAMENTE separado de PROVENIÊNCIA; integrado = NÃO")
        secoes = [line for line in md.splitlines() if line.startswith("## ")]
        check(len(secoes) == 27, f"relatório com as 27 seções ({len(secoes)})")
    check(hashlib.sha256(pack.read_bytes()).hexdigest() == hash_antes, "arquivo original intacto (SHA-256)")

    # 2) Tags SharedString em TODAS as classes: mesma coisa, uma execução
    pack_all = TMP / "pack_all_tags.rbxm"
    pack_all.write_bytes(defeituoso(limpo, None))
    r, rep, _ = auditar(pack_all, "all_tags")
    check(r.returncode == 0 and rep is not None and rep["totals"]["scripts"] == 3 and rep["totals"]["particleEmitters"] == 7,
          "Tags incompatível em todas as classes: auditoria completa numa execução")

    # 3) propriedade desconhecida com tipo errado: não remove por palpite, cai no leitor tolerante
    pack_u = TMP / "pack_unknown.rbxm"
    pack_u.write_bytes(defeituoso(limpo, {"Animator"}, ("Part", "Locked")))
    r, rep, _ = auditar(pack_u, "unknown")
    check(r.returncode == 0 and rep is not None and rep["read"]["reader"].startswith("leitor tolerante")
          and any("Part.Locked" in w for w in rep["read"]["warnings"]), "propriedade desconhecida: WARNING + fallback para o leitor tolerante")
    if rep:
        check(rep["totals"]["scripts"] == 3 and rep["totals"]["particleEmitters"] == 7 and rep["totals"]["beams"] == 1,
              "leitor tolerante ainda detecta scripts e VFX")

    # 4) modo só estático (sem Lune)
    r, rep, _ = auditar(pack, "static", "--sem-lune")
    check(r.returncode == 0 and rep is not None and rep["totals"]["instances"] > 20 and rep["totals"]["scripts"] == 3, "leitor estático sozinho audita o pack")

    # 5) corrupção estrutural grave: reportada, sem crash
    pack_t = TMP / "pack_truncado.rbxm"
    pack_t.write_bytes(limpo[: len(limpo) // 2])
    r, rep, md = auditar(pack_t, "truncado")
    check(r.returncode in (2, 3) and "Traceback" not in r.stderr and rep is not None and rep["read"]["structuralErrors"],
          f"arquivo truncado: corrupção estrutural reportada (código {r.returncode}), sem crash")

    print(f"[Auditor do Auras Pack] {'OK' if falhas == 0 else f'{falhas} falha(s)'}")
    return 1 if falhas else 0


if __name__ == "__main__":
    sys.exit(main())
