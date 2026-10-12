"""Teste do leitor tolerante (tools/packaudit/rbxm_reader.py), sem Roblox nem Lune.

Monta um .rbxm binário à mão com o mesmo problema do Anime Pack real
(Accessory.Tags gravado como SharedString) + chunk comprimido em LZ4 e confere que tudo
o que a auditoria usa é lido e que o resto é ignorado.
"""
import struct
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "tools" / "packaudit"))
import rbxm_reader as R  # noqa: E402


def string(b: bytes) -> bytes:
    return struct.pack("<I", len(b)) + b


def interleave(values, width=4):
    raw = [v.to_bytes(width, "big") for v in values]
    return bytes(raw[k][b] for b in range(width) for k in range(len(values)))


def refs(ids):
    out, prev = [], 0
    for v in ids:
        d = v - prev
        prev = v
        out.append(((d << 1) ^ (d >> 31)) & 0xFFFFFFFF)
    return interleave(out)


def lz4_literals(data: bytes) -> bytes:
    """Bloco LZ4 só com literais (válido para qualquer descompressor)."""
    n = len(data)
    if n < 15:
        return bytes([n << 4]) + data
    out = bytearray([0xF0])
    rest = n - 15
    while rest >= 255:
        out.append(255)
        rest -= 255
    out.append(rest)
    return bytes(out) + data


def chunk(name: bytes, body: bytes, compress=False) -> bytes:
    if compress:
        z = lz4_literals(body)
        return name + struct.pack("<III", len(z), len(body), 0) + z
    return name + struct.pack("<III", 0, len(body), 0) + body


def build() -> bytes:
    # 0 Folder "Anime Pack" > 1 Folder "DBZ" > 2 Model "Goku SSJ" > {3 Humanoid, 4 MeshPart Head > 5 Decal face, 6 Accessory Hair, 7 Script}
    classes = [("Folder", [0, 1]), ("Model", [2]), ("Humanoid", [3]), ("MeshPart", [4]), ("Decal", [5]), ("Accessory", [6]), ("Script", [7])]
    names = {0: "Anime Pack", 1: "DBZ", 2: "Goku SSJ", 3: "Humanoid", 4: "Head", 5: "face", 6: "Hair", 7: "Evil"}
    out = bytearray(R.MAGIC + R.SIGNATURE + struct.pack("<HiiQ", 0, len(classes), 8, 0))
    out += chunk(b"SSTR", struct.pack("<II", 0, 1) + b"\x00" * 16 + string(b"tagdata"))
    for tid, (cls, ids) in enumerate(classes):
        out += chunk(b"INST", struct.pack("<I", tid) + string(cls.encode()) + b"\x00" + struct.pack("<I", len(ids)) + refs(ids), compress=True)
    for tid, (cls, ids) in enumerate(classes):
        body = struct.pack("<I", tid) + string(b"Name") + b"\x01" + b"".join(string(names[i].encode()) for i in ids)
        out += chunk(b"PROP", body, compress=True)
    out += chunk(b"PROP", struct.pack("<I", 3) + string(b"MeshId") + b"\x01" + string(b"rbxassetid://111"))
    out += chunk(b"PROP", struct.pack("<I", 4) + string(b"Texture") + b"\x01" + string(b"rbxassetid://222"))
    # O problema real: Tags como SharedString (o Lune 0.10.4 recusa)
    out += chunk(b"PROP", struct.pack("<I", 5) + string(b"Tags") + b"\x1c" + interleave([0]))
    out += chunk(b"PROP", struct.pack("<I", 5) + string(b"AccessoryType") + b"\x12" + interleave([2]))
    out += chunk(b"PROP", struct.pack("<I", 6) + string(b"Source") + b"\x01" + string(b"require(123)\n"))
    # Tipo desconhecido: deve ser ignorado sem quebrar
    out += chunk(b"PROP", struct.pack("<I", 3) + string(b"Futuro") + b"\x7f" + b"\x01\x02\x03")
    child = [1, 2, 3, 4, 5, 6, 7, 0]
    parent = [0, 1, 2, 2, 4, 2, 2, -1]
    out += chunk(b"PRNT", b"\x00" + struct.pack("<I", 8) + refs(child) + refs(parent))
    out += chunk(b"END\x00", b"</roblox>")
    return bytes(out)


def main() -> int:
    falhas = 0

    def check(cond, msg):
        nonlocal falhas
        print(("  ✓ " if cond else "  ✗ ") + msg)
        if not cond:
            falhas += 1

    print("\n[Leitor tolerante de .rbxm (rbxm_reader.py)]")
    with tempfile.TemporaryDirectory() as tmp:
        path = Path(tmp) / "pack.rbxm"
        path.write_bytes(build())
        roots = R.read_model(str(path))
        check(len(roots) == 1 and roots[0].name == "Anime Pack", "raiz 'Anime Pack' (ignora Tags como SharedString e tipo desconhecido)")
        goku = roots[0].children[0].children[0]
        check(goku.name == "Goku SSJ" and goku.cls == "Model", "hierarquia DBZ > Goku SSJ")
        kids = {c.name: c for c in goku.children}
        check(kids["Head"].props.get("MeshId") == "rbxassetid://111", "MeshId lido")
        check(kids["Head"].children[0].props.get("Texture") == "rbxassetid://222", "rosto (Decal.Texture) lido")
        check(kids["Hair"].props.get("AccessoryType") == 2, "AccessoryType (enum) lido")
        check(kids["Evil"].props.get("Source") == "require(123)\n", "código do script lido como TEXTO")
        clean = Path(tmp) / "clean.rbxmx"
        total = R.write_clean_rbxmx(roots, str(clean))
        xml = clean.read_text(encoding="utf-8")
        check(total == 8 and "Tags" not in xml and "require(123)" in xml, "cópia limpa sem Tags, com o código como texto")
        again = R.read_model(str(clean))
        check(again[0].children[0].children[0].name == "Goku SSJ", "cópia limpa (XML) relida")
        # Cópia binária sem Accessory.Tags (para o Lune ler o pack inteiro no pipeline de personagens)
        data = path.read_bytes()
        stripped, removed = R.strip_properties(data, {("Accessory", "Tags")})
        check(removed == ["Accessory.Tags"] and len(stripped) < len(data), "strip_properties remove só o chunk Accessory.Tags")
        check(b"tagdata" in stripped and stripped.endswith(b"</roblox>"), "resto do arquivo (SSTR, END) preservado")
        (Path(tmp) / "stripped.rbxm").write_bytes(stripped)
        back = R.read_model(str(Path(tmp) / "stripped.rbxm"))
        kids2 = {c.name: c for c in back[0].children[0].children[0].children}
        check(kids2["Head"].props.get("MeshId") == "rbxassetid://111" and kids2["Hair"].props.get("AccessoryType") == 2, "cópia binária relida com malha e enums intactos")
        same, nothing = R.strip_properties(data, {(None, "NaoExiste")})
        check(same == data and nothing == [], "sem nada para remover: arquivo idêntico byte a byte")
    print(f"[Leitor tolerante de .rbxm] {'OK' if falhas == 0 else f'{falhas} falha(s)'}")
    return 1 if falhas else 0


if __name__ == "__main__":
    sys.exit(main())
