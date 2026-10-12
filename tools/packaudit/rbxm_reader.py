"""Leitor TOLERANTE de arquivos de modelo do Roblox (.rbxm binário e .rbxmx XML).

Usado quando o Lune recusa um arquivo (ex.: "Property Accessory.Tags should be SharedString,
but it was Tags"). Lê só o que a auditoria precisa e IGNORA qualquer propriedade de tipo
desconhecido ou fora do esperado. Nada do arquivo é executado: scripts viram texto.

    nodes = read_model("third_party/AnimePack.rbxm")
    write_clean_rbxmx(nodes, "third_party/AnimePack_clean.rbxmx")

Formato binário: https://dom.rojo.space/binary (cabeçalho, chunks META/SSTR/INST/PROP/PRNT/END,
compressão LZ4 ou ZSTD por chunk, arrays "interleaved").
"""
from __future__ import annotations

import re
import struct
import subprocess
import sys
import xml.etree.ElementTree as ET
from xml.sax.saxutils import escape

MAGIC = b"<roblox!"
SIGNATURE = b"\x89\xff\r\n\x1a\n"
ZSTD_MAGIC = b"\x28\xb5\x2f\xfd"

# Propriedades copiadas para a cópia limpa (o resto é descartado)
STRING_PROPS = {"Source"}
CONTENT_PROPS = {
    # nome no arquivo -> nome usado na cópia limpa
    "MeshId": "MeshId",
    "MeshContent": "MeshId",
    "TextureID": "TextureID",
    "TextureId": "TextureId",
    "TextureContent": "Texture*",  # Decal.Texture / MeshPart.TextureID (resolvido pela classe)
    "Texture": "Texture",
    "ColorMapContent": "Texture*",
    "ShirtTemplate": "ShirtTemplate",
    "PantsTemplate": "PantsTemplate",
    "Graphic": "Graphic",
    "AnimationId": "AnimationId",
}
BOOL_PROPS = {"Disabled", "Enabled", "Anchored"}
ENUM_PROPS = {"RigType", "AccessoryType"}


class Node:
    __slots__ = ("cls", "name", "props", "children", "parent")

    def __init__(self, cls: str):
        self.cls = cls
        self.name = cls
        self.props: dict[str, object] = {}
        self.children: list[Node] = []
        self.parent: Node | None = None


# ---------------------------------------------------------------------------------
# Descompressão

def lz4_block(src: bytes, size: int) -> bytes:
    out = bytearray()
    i = 0
    n = len(src)
    while i < n:
        token = src[i]
        i += 1
        lit = token >> 4
        if lit == 15:
            while True:
                b = src[i]
                i += 1
                lit += b
                if b != 255:
                    break
        out += src[i:i + lit]
        i += lit
        if i >= n:
            break
        offset = src[i] | (src[i + 1] << 8)
        i += 2
        match = token & 15
        if match == 15:
            while True:
                b = src[i]
                i += 1
                match += b
                if b != 255:
                    break
        match += 4
        start = len(out) - offset
        if offset >= match:
            out += out[start:start + match]
        else:
            for k in range(match):
                out.append(out[start + k])
    if len(out) != size:
        raise ValueError(f"LZ4: tamanho {len(out)} != {size}")
    return bytes(out)


def zstd_decompress(data: bytes, size: int) -> bytes:
    try:
        from compression import zstd  # Python 3.14+

        return zstd.decompress(data)
    except ImportError:
        pass
    try:
        import zstandard
    except ImportError:
        print("Instalando o pacote 'zstandard' (o arquivo usa compressão ZSTD)...")
        subprocess.run([sys.executable, "-m", "pip", "install", "--quiet", "zstandard"], check=True)
        import zstandard
    return zstandard.ZstdDecompressor().decompress(data, max_output_size=max(size, 1))


# ---------------------------------------------------------------------------------
# Leitura binária

class Reader:
    def __init__(self, data: bytes):
        self.d = data
        self.i = 0

    def u8(self) -> int:
        v = self.d[self.i]
        self.i += 1
        return v

    def u32(self) -> int:
        v = struct.unpack_from("<I", self.d, self.i)[0]
        self.i += 4
        return v

    def raw(self, n: int) -> bytes:
        v = self.d[self.i:self.i + n]
        if len(v) != n:
            raise ValueError("fim inesperado dos dados")
        self.i += n
        return v

    def string(self) -> bytes:
        return self.raw(self.u32())

    def interleaved(self, count: int, width: int = 4) -> list[int]:
        block = self.raw(count * width)
        values = []
        for k in range(count):
            v = 0
            for b in range(width):
                v = (v << 8) | block[b * count + k]
            values.append(v)
        return values

    def i32s(self, count: int) -> list[int]:
        return [(v >> 1) ^ -(v & 1) for v in self.interleaved(count)]

    def referents(self, count: int) -> list[int]:
        out = []
        acc = 0
        for v in self.i32s(count):
            acc += v
            out.append(acc)
        return out


def _text(raw: bytes) -> str:
    return raw.decode("utf-8", errors="replace")


ASSET_RE = re.compile(rb"(rbxassetid://\d+|rbxasset://[^\x00\s\"']+|https?://[^\x00\s\"']*?id=\d+)")


def _content_values(r: Reader, count: int, end: int) -> list[str | None] | None:
    """Tenta ler um array de Content (tipo novo). Devolve None se não reconhecer."""
    start = r.i
    # Tentativa 1: tipos de origem (i32 interleaved) + lista de URIs
    for zigzag in (True, False):
        r.i = start
        try:
            kinds = r.i32s(count) if zigzag else r.interleaved(count)
            if not all(k in (0, 1, 2, 3) for k in kinds):
                continue
            uri_count = r.u32()
            if uri_count != sum(1 for k in kinds if k == 1) or uri_count > count:
                continue
            uris = [_text(r.string()) for _ in range(uri_count)]
            if r.i > end:
                continue
            it = iter(uris)
            return [next(it) if k == 1 else None for k in kinds]
        except (ValueError, IndexError, struct.error):
            continue
    # Tentativa 2: os ids aparecem em ordem e são exatamente um por instância
    found = ASSET_RE.findall(r.d[start:end])
    if len(found) == count:
        return [_text(f) for f in found]
    return None


def read_binary(data: bytes) -> list[Node]:
    if data[:8] != MAGIC or data[8:14] != SIGNATURE:
        raise ValueError("não é um arquivo binário do Roblox")
    r = Reader(data)
    r.i = 32
    classes: dict[int, tuple[str, list[int]]] = {}
    nodes: dict[int, Node] = {}
    parents: list[tuple[int, int]] = []
    shared: list[bytes] = []
    skipped: dict[str, int] = {}
    while r.i < len(data):
        name = r.raw(4).rstrip(b"\x00").decode("ascii", errors="replace")
        compressed = r.u32()
        size = r.u32()
        r.raw(4)
        if compressed:
            payload = r.raw(compressed)
            body = zstd_decompress(payload, size) if payload[:4] == ZSTD_MAGIC else lz4_block(payload, size)
        else:
            body = r.raw(size)
        if name == "END":
            break
        c = Reader(body)
        try:
            if name == "SSTR":
                c.u32()
                for _ in range(c.u32()):
                    c.raw(16)
                    shared.append(c.string())
            elif name == "INST":
                type_id = c.u32()
                cls = _text(c.string())
                c.u8()
                count = c.u32()
                refs = c.referents(count)
                classes[type_id] = (cls, refs)
                for ref in refs:
                    nodes[ref] = Node(cls)
            elif name == "PROP":
                type_id = c.u32()
                prop = _text(c.string())
                kind = c.u8()
                cls, refs = classes.get(type_id, ("?", []))
                n = len(refs)
                values: list | None = None
                if kind in (0x01, 0x1D):  # String / ProtectedString
                    values = [c.string() for _ in range(n)]
                elif kind == 0x02:  # Bool
                    values = [b != 0 for b in c.raw(n)]
                elif kind == 0x12:  # Enum
                    values = c.interleaved(n)
                elif kind == 0x1C:  # SharedString
                    values = [shared[k] if k < len(shared) else b"" for k in c.interleaved(n)]
                elif prop in CONTENT_PROPS:  # Content (tipo novo) e afins: leitura tolerante
                    values = _content_values(c, n, len(body))
                if values is None:
                    skipped[f"{cls}.{prop} (tipo 0x{kind:02X})"] = skipped.get(f"{cls}.{prop} (tipo 0x{kind:02X})", 0) + 1
                    continue
                for ref, value in zip(refs, values):
                    node = nodes[ref]
                    if prop == "Name" and isinstance(value, bytes):
                        node.name = _text(value)
                    elif prop in STRING_PROPS and isinstance(value, bytes):
                        node.props[prop] = _text(value)
                    elif prop in CONTENT_PROPS and value:
                        text = _text(value) if isinstance(value, bytes) else str(value)
                        if text:
                            node.props[prop] = text
                    elif prop in BOOL_PROPS and isinstance(value, bool):
                        node.props[prop] = value
                    elif prop in ENUM_PROPS and isinstance(value, int):
                        node.props[prop] = value
            elif name == "PRNT":
                c.u8()
                count = c.u32()
                children = c.referents(count)
                owners = c.referents(count)
                parents = list(zip(children, owners))
        except (ValueError, IndexError, struct.error) as err:
            skipped[f"chunk {name} ilegível ({err})"] = skipped.get(f"chunk {name} ilegível ({err})", 0) + 1
    roots = []
    for child, owner in parents:
        node = nodes.get(child)
        if node is None:
            continue
        parent = nodes.get(owner)
        if parent is None:
            roots.append(node)
        else:
            node.parent = parent
            parent.children.append(node)
    if skipped:
        print(f"(ignoradas {len(skipped)} propriedades sem importância para a auditoria)")
    return roots


# ---------------------------------------------------------------------------------
# Leitura XML (.rbxmx)

def read_xml(text: bytes) -> list[Node]:
    root = ET.fromstring(text)

    def build(item) -> Node:
        node = Node(item.get("class", "Folder"))
        props = item.find("Properties")
        if props is not None:
            for p in props:
                pname = p.get("name")
                if pname == "Name":
                    node.name = p.text or ""
                elif pname in STRING_PROPS:
                    node.props[pname] = p.text or ""
                elif pname in CONTENT_PROPS:
                    url = p.find("url")
                    text = (url.text if url is not None else p.text) or ""
                    if text.strip():
                        node.props[pname] = text.strip()
                elif pname in BOOL_PROPS:
                    node.props[pname] = (p.text or "").strip() == "true"
                elif pname in ENUM_PROPS:
                    try:
                        node.props[pname] = int((p.text or "0").strip())
                    except ValueError:
                        pass
        for child in item.findall("Item"):
            c = build(child)
            c.parent = node
            node.children.append(c)
        return node

    return [build(item) for item in root.findall("Item")]


def read_model(path: str) -> list[Node]:
    with open(path, "rb") as f:
        data = f.read()
    if data[:8] == MAGIC and data[8:14] == SIGNATURE:
        return read_binary(data)
    return read_xml(data)


# ---------------------------------------------------------------------------------
# Cópia binária SEM algumas propriedades (para o Lune conseguir ler o arquivo inteiro)

def strip_properties(data: bytes, drop: set[tuple[str | None, str]]) -> tuple[bytes, list[str]]:
    """Copia um .rbxm binário chunk a chunk, pulando os chunks PROP de (classe, propriedade)
    em "drop" (classe None = todas as classes). Todo o resto (geometria, malhas, texturas,
    roupas) continua idêntico. Ex.: {("Accessory", "Tags")} — o Lune 0.10.4 recusa Tags
    gravado como SharedString. Devolve (bytes, lista do que foi removido)."""
    if data[:8] != MAGIC or data[8:14] != SIGNATURE:
        raise ValueError("strip_properties só funciona com .rbxm binário")
    out = bytearray(data[:32])
    i = 32
    classes: dict[int, str] = {}
    removed: list[str] = []
    while i < len(data):
        start = i
        name = data[i:i + 4].rstrip(b"\x00").decode("ascii", errors="replace")
        compressed, size = struct.unpack_from("<II", data, i + 4)
        i += 16
        payload = data[i:i + (compressed or size)]
        i += compressed or size
        raw = data[start:i]
        if name in ("INST", "PROP"):
            body = payload if not compressed else (zstd_decompress(payload, size) if payload[:4] == ZSTD_MAGIC else lz4_block(payload, size))
            c = Reader(body)
            type_id = c.u32()
            label = _text(c.string())
            if name == "INST":
                classes[type_id] = label
            else:
                cls = classes.get(type_id, "?")
                if (cls, label) in drop or (None, label) in drop:
                    removed.append(f"{cls}.{label}")
                    continue
        out += raw
        if name == "END":
            out += data[i:]
            break
    return bytes(out), removed


# ---------------------------------------------------------------------------------
# Cópia limpa (.rbxmx) só com o que a auditoria usa

def _cdata(text: str) -> str:
    return "<![CDATA[" + text.replace("]]>", "]]]]><![CDATA[>") + "]]>"


def _clean_text(text: str) -> str:
    # XML 1.0 não aceita caracteres de controle (código ofuscado costuma ter)
    return "".join(ch if ch in "\t\n\r" or ord(ch) >= 32 else f"\\{ord(ch)}" for ch in text)


def write_clean_rbxmx(roots: list[Node], path: str) -> int:
    out = ['<roblox version="4">']
    counter = [0]

    def emit(node: Node, depth: int):
        counter[0] += 1
        pad = "  " * depth
        out.append(f'{pad}<Item class="{escape(node.cls, {chr(34): "&quot;"})}" referent="RBX{counter[0]}">')
        out.append(f"{pad}  <Properties>")
        out.append(f'{pad}    <string name="Name">{escape(_clean_text(node.name))}</string>')
        for key, value in node.props.items():
            if key in STRING_PROPS:
                out.append(f'{pad}    <ProtectedString name="{key}">{_cdata(_clean_text(str(value)))}</ProtectedString>')
            elif key in CONTENT_PROPS:
                target = CONTENT_PROPS[key]
                if target == "Texture*":
                    target = "Texture" if node.cls == "Decal" or node.cls == "Texture" else "TextureID"
                out.append(f'{pad}    <Content name="{target}"><url>{escape(_clean_text(str(value)))}</url></Content>')
            elif key in BOOL_PROPS:
                out.append(f'{pad}    <bool name="{key}">{"true" if value else "false"}</bool>')
            elif key in ENUM_PROPS:
                out.append(f'{pad}    <token name="{key}">{int(value)}</token>')
        out.append(f"{pad}  </Properties>")
        for child in node.children:
            emit(child, depth + 1)
        out.append(f"{pad}</Item>")

    for root in roots:
        emit(root, 1)
    out.append("</roblox>")
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(out))
    return counter[0]


if __name__ == "__main__":
    origem = sys.argv[1]
    destino = sys.argv[2] if len(sys.argv) > 2 else origem.rsplit(".", 1)[0] + "_clean.rbxmx"
    total = write_clean_rbxmx(read_model(origem), destino)
    print(f"{total} instâncias -> {destino}")
