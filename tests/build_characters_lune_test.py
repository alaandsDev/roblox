"""Regressão do fallback do Lune em tools/build_characters.py (bug: "Accessory.Tags",
"Animation.Tags", ... uma classe por execução até estourar 10 tentativas).

Monta, a partir do pack SINTÉTICO (build/test_AnimePack.rbxm, gerado pelo
CharacterPipelineHarness), arquivos com o MESMO defeito do pack real: a propriedade "Tags"
gravada como SharedString em TODAS as classes (o Lune 0.10.4 recusa), e confere:
  1. tudo resolvido em UMA execução da ferramenta, sem loop (Tags preventivo + 1 fallback de
     metadado "Capabilities"), 10 pilotos gerados, nenhuma propriedade visual removida,
     conteúdo visual idêntico e arquivo de origem intacto (SHA-256);
  2. propriedade VISUAL recusada (Part.Transparency) -> aborta sem remover nada;
  3. propriedade desconhecida recusada (Part.Locked) -> aborta com diagnóstico.
"""
import hashlib
import struct
import subprocess
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(RAIZ / "tools" / "packaudit"))
import rbxm_reader as R  # noqa: E402

TMP = RAIZ / "build" / "lune_compat"


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


def defeituoso(data: bytes, extra: tuple[str, str] | None) -> bytes:
    """Tags como SharedString em todas as classes (+ uma propriedade extra com tipo errado em Part)."""
    out = bytearray(data[:32])
    classes: dict[str, tuple[int, int]] = {}
    for name, raw, _cls, _prop_name in R.iter_chunks(data):
        if name == "INST":
            type_id, cls, count = _inst_info(raw)
            classes[cls] = (type_id, count)
        if name == "PRNT":
            sstr = struct.pack("<II", 0, 1) + b"\x00" * 16 + struct.pack("<I", 4) + b"tag1"
            out += b"SSTR" + struct.pack("<III", 0, len(sstr), 0) + sstr
            for cls, (type_id, count) in sorted(classes.items()):
                out += _prop(type_id, "Tags", 0x1C, _interleave([0] * count))
            if extra:
                type_id, count = classes[extra[0]]
                out += _prop(type_id, extra[1], 0x01, b"".join(struct.pack("<I", 0) for _ in range(count)))
        out += raw
    return bytes(out)


def rodar(pack: Path, nome: str):
    saida = TMP / f"{nome}.rbxm"
    saida.unlink(missing_ok=True)
    r = subprocess.run(
        [sys.executable, "tools/build_characters.py", str(pack), "--out", str(saida), "--report", str(TMP / f"{nome}.md"), "--json", str(TMP / f"{nome}.json")],
        cwd=RAIZ, capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=600,
    )
    return r, saida


def main() -> int:
    falhas = 0

    def check(cond, msg):
        nonlocal falhas
        print(("  ✓ " if cond else "  ✗ ") + msg)
        if not cond:
            falhas += 1

    print("\n[build_characters.py: Tags incompatível em várias classes (regressão)]")
    base = RAIZ / "build" / "test_AnimePack.rbxm"
    if not base.exists():
        print("  ✗ build/test_AnimePack.rbxm ausente (rode o CharacterPipelineHarness antes)")
        return 1
    TMP.mkdir(parents=True, exist_ok=True)
    limpo = base.read_bytes()

    # 1) Tags em TODAS as classes + metadado Capabilities: uma execução só
    pack = TMP / "pack_tags.rbxm"
    pack.write_bytes(defeituoso(limpo, ("Part", "Capabilities")))
    hash_antes = hashlib.sha256(pack.read_bytes()).hexdigest()
    classes = sorted({cls for name, _raw, cls, _p in R.iter_chunks(limpo) if name == "INST"})
    r, saida = rodar(pack, "ok")
    log = r.stdout
    execucoes = log.count("Building 10 pilot characters...")
    check(r.returncode == 0, f"UMA execução do usuário chega ao fim (código {r.returncode})")
    check(execucoes == 2, f"sem loop: Tags preventivo + 1 fallback (Capabilities) = {execucoes} leituras do Lune")
    removidas = [linha[2:] for linha in log.splitlines() if linha.startswith("- ") and linha.endswith(".Tags")]
    check(len(removidas) == len(classes) and len(classes) >= 10, f"Tags removido de TODAS as {len(classes)} classes de uma vez (Accessory, Animation, ..., BodyGyro, ...)")
    check("O Lune recusou o metadado Part.Capabilities" in log and "Part.Capabilities" in log.split("Removed incompatible metadata:")[1], "fallback: metadado novo (Capabilities) tratado automaticamente")
    check("Visual properties removed: 0" in log, "nenhuma propriedade visual removida")
    check("Visual content identical (names, MeshId, TextureId, Decals, Shirt/Pants): YES" in log, "MeshId/TextureId/Decals/Shirt/Pants/nomes idênticos (leitura estruturada)")
    check("Kept chunks byte-identical" in log and "YES" in log.split("Kept chunks byte-identical")[1].splitlines()[0], "CFrame/tamanho/cores/BodyColors/soldas: chunks idênticos byte a byte")
    check("Original Anime Pack modified: NO" in log and hashlib.sha256(pack.read_bytes()).hexdigest() == hash_antes, "arquivo de origem intacto (SHA-256)")
    check(saida.exists() and "10 pilotos" in log, "Characters.rbxm gerado com os 10 pilotos")
    removidos_estrutura = R.dropped_properties(pack.read_bytes(), (RAIZ / "build" / "AnimePack_lune.rbxm").read_bytes())
    check(all(x.split(".")[1] in ("Tags", "Capabilities") for x in removidos_estrutura), "cópia temporária perdeu SÓ chunks Tags/Capabilities (conferido chunk a chunk)")

    # 2) Propriedade VISUAL recusada: aborta, nada removido
    pack_v = TMP / "pack_visual.rbxm"
    pack_v.write_bytes(defeituoso(limpo, ("Part", "Transparency")))
    r, saida = rodar(pack_v, "visual")
    check(r.returncode == 1 and "propriedade VISUAL" in r.stdout and "Part.Transparency" in r.stdout and not saida.exists(), "propriedade visual recusada: ABORTA com diagnóstico, sem remover")

    # 3) Propriedade desconhecida: aborta (não remove por palpite)
    pack_u = TMP / "pack_unknown.rbxm"
    pack_u.write_bytes(defeituoso(limpo, ("Part", "Locked")))
    r, saida = rodar(pack_u, "unknown")
    check(r.returncode == 1 and "Part.Locked" in r.stdout and "não está na lista" in r.stdout and not saida.exists(), "propriedade desconhecida recusada: ABORTA com diagnóstico")

    print(f"[build_characters.py: Tags incompatível] {'OK' if falhas == 0 else f'{falhas} falha(s)'}")
    return 1 if falhas else 0


if __name__ == "__main__":
    sys.exit(main())
