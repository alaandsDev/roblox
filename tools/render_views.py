"""Vistas em PERSPECTIVA do mapa, da altura da câmera do jogador (validação visual fora do Studio).

    python tools/render_views.py [pasta_saida]

Lê build/map_preview.json (gerado pelo tests/roblox/MapHarness.luau, que roda o MapBuilder/
BaseBuilder REAIS) e desenha cada peça como um sólido simples (bloco, cunha, prisma no lugar de
cilindro/bola) com sombreamento pelo sol. É uma aproximação: serve para conferir escala,
silhuetas, o que tampa a câmera e o que aparece de longe — não substitui o Studio.
Saída: build/views/<nome>.png (+ contact sheet build/views/_all.png).
"""
from __future__ import annotations

import json
import math
import sys
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    sys.exit("Instale o Pillow: pip install pillow")

RAIZ = Path(__file__).resolve().parent.parent
W, H = 960, 540
FOV = math.radians(70)
SUN = (0.35, 0.85, -0.4)
SKY_TOP, SKY_BOTTOM = (110, 180, 245), (205, 232, 255)

# Câmera padrão do Roblox: ~12 studs atrás e ~5 acima da cabeça (olhos ~5 do chão)
VIEWS = [
    # nome, posição da câmera (x, y, z), alvo (x, y, z)
    ("01_hub_spawn", (0, 9, -50), (0, 14, 0)),
    ("02_base03_spawn", None, None),  # calculado: atrás do PlayerSpawn da Base03, olhando para dentro
    ("03_base03_saindo", None, None),  # calculado: dentro da Base03 olhando para fora (Hub)
    ("04_esteira_cruzamento", (66, 8, -84 - 14), (100, 2, -84)),
    ("05_lojas", (0, 9, -40), (0, 6, -76)),
    ("06_fusao_do_hub", (-20, 9, 0), (-68, 6, 12)),
    ("07_torres_do_hub", (0, 9, 30), (0, 25, 118)),
    ("08_trocas_rankings", (20, 9, 40), (60, 8, 70)),
    ("09_visao_geral", (0, 160, -330), (0, 0, -20)),
    ("10_borda_ilha", (120, 12, -230), (175, 2, -265)),
]


def sub(a, b):
    return (a[0] - b[0], a[1] - b[1], a[2] - b[2])


def add(a, b):
    return (a[0] + b[0], a[1] + b[1], a[2] + b[2])


def mul(a, k):
    return (a[0] * k, a[1] * k, a[2] * k)


def dot(a, b):
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]


def cross(a, b):
    return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])


def norm(a):
    n = math.sqrt(dot(a, a)) or 1.0
    return (a[0] / n, a[1] / n, a[2] / n)


def solid(p):
    """Faces (lista de polígonos 3D) de uma peça."""
    c = (p["x"], p["y"], p["z"])
    r, u, l = tuple(p["r"]), tuple(p["u"]), tuple(p["l"])
    back = mul(l, -1)  # +Z local = -LookVector
    hx, hy, hz = p["sx"] / 2, p["sy"] / 2, p["sz"] / 2
    shape = p.get("shape", "")

    def pt(x, y, z):
        return add(c, add(mul(r, x), add(mul(u, y), mul(back, z))))

    if "Cylinder" in shape:
        # eixo = X local; seção circular em Y/Z (8 lados)
        ring = []
        for i in range(8):
            a = 2 * math.pi * i / 8
            ring.append((math.cos(a) * hy, math.sin(a) * hz))
        left = [pt(-hx, y, z) for y, z in ring]
        right = [pt(hx, y, z) for y, z in ring]
        faces = [left[::-1], right]
        for i in range(8):
            j = (i + 1) % 8
            faces.append([left[i], left[j], right[j], right[i]])
        return faces
    if "WedgePart" in shape:
        # rampa: alta no +Z local, baixa no -Z
        a, b = pt(-hx, -hy, -hz), pt(hx, -hy, -hz)
        cc, d = pt(hx, -hy, hz), pt(-hx, -hy, hz)
        e, f = pt(-hx, hy, hz), pt(hx, hy, hz)
        return [[a, b, cc, d], [d, cc, f, e], [a, d, e], [b, f, cc], [a, e, f, b]]
    corners = [pt(x, y, z) for x in (-hx, hx) for y in (-hy, hy) for z in (-hz, hz)]
    idx = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
    return [[corners[i] for i in face] for face in idx]


def render(parts, eye, target, out_path, label):
    import numpy as np

    fwd = norm(sub(target, eye))
    right = norm(cross(fwd, (0, 1, 0)))
    up = cross(right, fwd)
    focal = (W / 2) / math.tan(FOV / 2)
    sun = norm(SUN)
    near = 0.3

    depth = np.full((H, W), np.inf, dtype=np.float64)
    face_id = np.full((H, W), -1, dtype=np.int32)
    colors = []

    def to_cam(v):
        rel = sub(v, eye)
        return (dot(rel, right), dot(rel, up), dot(rel, fwd))

    def clip(cam):
        out = []
        for i, a in enumerate(cam):
            b = cam[(i + 1) % len(cam)]
            a_in, b_in = a[2] >= near, b[2] >= near
            if a_in:
                out.append(a)
            if a_in != b_in:
                t = (near - a[2]) / (b[2] - a[2])
                out.append((a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, near))
        return out

    def raster(cam_poly, fid):
        pts = [(W / 2 + x * focal / z, H / 2 - y * focal / z, 1.0 / z) for x, y, z in cam_poly]
        for i in range(1, len(pts) - 1):
            (x0, y0, w0), (x1, y1, w1), (x2, y2, w2) = pts[0], pts[i], pts[i + 1]
            minx, maxx = max(int(math.floor(min(x0, x1, x2))), 0), min(int(math.ceil(max(x0, x1, x2))), W - 1)
            miny, maxy = max(int(math.floor(min(y0, y1, y2))), 0), min(int(math.ceil(max(y0, y1, y2))), H - 1)
            if minx > maxx or miny > maxy:
                continue
            area = (x1 - x0) * (y2 - y0) - (x2 - x0) * (y1 - y0)
            if abs(area) < 1e-9:
                continue
            xs = np.arange(minx, maxx + 1) + 0.5
            ys = np.arange(miny, maxy + 1) + 0.5
            px, py = np.meshgrid(xs, ys)
            l0 = ((x1 - px) * (y2 - py) - (x2 - px) * (y1 - py)) / area
            l1 = ((x2 - px) * (y0 - py) - (x0 - px) * (y2 - py)) / area
            l2 = 1 - l0 - l1
            inside = (l0 >= -1e-6) & (l1 >= -1e-6) & (l2 >= -1e-6)
            if not inside.any():
                continue
            winv = l0 * w0 + l1 * w1 + l2 * w2
            zz = 1.0 / np.maximum(winv, 1e-9)
            region = depth[miny:maxy + 1, minx:maxx + 1]
            closer = inside & (zz < region - 1e-4 * zz)
            region[closer] = zz[closer]
            face_id[miny:maxy + 1, minx:maxx + 1][closer] = fid

    def emit(face, color):
        cam = clip([to_cam(v) for v in face])
        if len(cam) >= 3:
            colors.append(color)
            raster(cam, len(colors) - 1)

    emit([(-3000, -1.2, -3000), (3000, -1.2, -3000), (3000, -1.2, 3000), (-3000, -1.2, 3000)], (40, 165, 205))
    for p in parts:
        if p.get("t", 0) >= 0.9 or "r" not in p:
            continue
        base = p["c"]
        neon = "Neon" in p.get("material", "")
        for face in solid(p):
            n = norm(cross(sub(face[1], face[0]), sub(face[2], face[0])))
            centroid = (0.0, 0.0, 0.0)
            for v in face:
                centroid = add(centroid, v)
            centroid = mul(centroid, 1 / len(face))
            if dot(n, sub(eye, centroid)) < 0:
                n = mul(n, -1)
            light = 0.55 + 0.45 * max(0.0, dot(n, sun))
            if neon:
                color = tuple(min(255, int(base[k] * 1.1 + 25)) for k in range(3))
            else:
                color = tuple(min(255, int(base[k] * light)) for k in range(3))
            emit(face, color)

    # Céu em degradê + cor de cada face + contorno onde a face muda (leitura "blocky")
    sky = np.zeros((H, W, 3), dtype=np.uint8)
    t = np.linspace(0, 1, H)[:, None]
    for k in range(3):
        sky[:, :, k] = (SKY_TOP[k] * (1 - t) + SKY_BOTTOM[k] * t).astype(np.uint8)
    palette = np.array(colors + [(0, 0, 0)], dtype=np.uint8)
    img = np.where(face_id[:, :, None] >= 0, palette[face_id], sky)
    edge = np.zeros((H, W), dtype=bool)
    edge[:, 1:] |= (face_id[:, 1:] != face_id[:, :-1]) & (face_id[:, 1:] >= 0) & (face_id[:, :-1] >= 0)
    edge[1:, :] |= (face_id[1:, :] != face_id[:-1, :]) & (face_id[1:, :] >= 0) & (face_id[:-1, :] >= 0)
    # só contorna quando a profundidade muda de verdade (evita linhas entre faces coplanares)
    dz = np.zeros((H, W))
    with np.errstate(invalid="ignore"):  # céu (inf - inf) não é borda
        dz[:, 1:] = np.abs(depth[:, 1:] - depth[:, :-1])
        dz[1:, :] = np.maximum(dz[1:, :], np.abs(depth[1:, :] - depth[:-1, :]))
        edge &= np.nan_to_num(dz, nan=0.0) > 0.02 * np.where(np.isfinite(depth), depth, 1)
    img[edge] = (img[edge] * 0.6).astype(np.uint8)
    image = Image.fromarray(img, "RGB")
    draw = ImageDraw.Draw(image)
    try:
        font = ImageFont.truetype("DejaVuSans-Bold.ttf", 22)
    except OSError:
        font = ImageFont.load_default()
    draw.text((12, 10), label, font=font, fill=(255, 255, 255), stroke_width=3, stroke_fill=(20, 15, 35))
    image.save(out_path)
    return image


def main():
    out_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else RAIZ / "build" / "views"
    out_dir.mkdir(parents=True, exist_ok=True)
    parts = json.loads((RAIZ / "build" / "map_preview.json").read_text(encoding="utf-8"))
    # Base03 (mais perto do Hub, lado esquerdo): spawn e direção para dentro
    spawn = next((p for p in parts if p["g"] == "Bases" and p["n"] == "PlayerSpawn" and abs(p["x"] + 136) < 40 and abs(p["z"]) < 40), None)
    images = []
    for name, eye, target in VIEWS:
        if eye is None:
            if not spawn:
                continue
            sx, sz = spawn["x"], spawn["z"]
            inward = (-1.0, 0.0)  # Base03 fica em X < 0, a entrada olha para +X; dentro = -X
            if name == "02_base03_spawn":
                eye = (sx - inward[0] * 12, 9, sz)
                target = (sx + inward[0] * 30, 4, sz)
            else:
                eye = (sx + inward[0] * 6, 8, sz)
                target = (sx - inward[0] * 60, 5, sz)
        path = out_dir / f"{name}.png"
        images.append(render(parts, eye, target, path, name))
    # contact sheet
    cols = 2
    rows = (len(images) + cols - 1) // cols
    sheet = Image.new("RGB", (W // 2 * cols, H // 2 * rows), (20, 20, 30))
    for i, img in enumerate(images):
        sheet.paste(img.resize((W // 2, H // 2)), ((i % cols) * W // 2, (i // cols) * H // 2))
    sheet.save(out_dir / "_all.png")
    print(f"{len(images)} vistas em {out_dir}")


if __name__ == "__main__":
    main()
