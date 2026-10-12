"""Desenha uma vista de cima do mapa a partir de build/map_preview.json.

O JSON é gerado pelo teste headless (tests/roblox/MapHarness.luau, via run_tests.py),
que roda o código REAL do MapBuilder/BaseBuilder. Resultado: build/map_preview.png
Requer Pillow (pip install pillow).
"""

import json
import math
import sys
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    sys.exit("Instale o Pillow: pip install pillow")

RAIZ = Path(__file__).resolve().parent.parent
ESCALA = 2.0  # pixels por stud
MIN_X, MAX_X, MIN_Z, MAX_Z = -300, 300, -360, 380

LEGENDAS = [
    ("HUB + DADO", 0, 0), ("TORRES", 0, 130), ("MERCADO", -40, -86), ("LOJA DE DADOS", 0, -96),
    ("VENDER", 40, -86), ("FUSÃO", -68, 25), ("TROCAS", 68, 25), ("MISSÕES", -50, 112),
    ("RANKINGS", 50, 115), ("ENTRADA", 0, -262), ("FUNDO", 0, 268),
]


def para_tela(x, z):
    # norte (Z+) para cima
    return (x - MIN_X) * ESCALA, (MAX_Z - z) * ESCALA


def main() -> None:
    dados = json.loads((RAIZ / "build" / "map_preview.json").read_text(encoding="utf-8"))
    largura = int((MAX_X - MIN_X) * ESCALA)
    altura = int((MAX_Z - MIN_Z) * ESCALA)
    img = Image.new("RGB", (largura, altura), (40, 170, 205))
    draw = ImageDraw.Draw(img)

    for p in sorted(dados, key=lambda p: p["y"] + p["sy"] / 2):
        if p["t"] >= 0.9:
            continue
        cor = tuple(p["c"])
        cx, cy = para_tela(p["x"], p["z"])
        forma = p["shape"]
        if "Cylinder" in forma:
            r = max(p["sy"], p["sz"]) / 2 * ESCALA
            draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=cor)
        elif "Ball" in forma:
            r = p["sx"] / 2 * ESCALA
            draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=cor)
        else:
            # retângulo girado pelo LookVector (yaw): Size.Z vai ao longo do LookVector,
            # Size.X ao longo do vetor perpendicular (no plano XZ)
            norma = math.hypot(p["lx"], p["lz"]) or 1.0
            lx, lz = p["lx"] / norma, p["lz"] / norma
            perp_x, perp_z = -lz, lx
            hx, hz = p["sx"] / 2, p["sz"] / 2
            pontos = []
            for dx, dz in ((-hx, -hz), (hx, -hz), (hx, hz), (-hx, hz)):
                pontos.append(para_tela(p["x"] + perp_x * dx + lx * dz, p["z"] + perp_z * dx + lz * dz))
            draw.polygon(pontos, fill=cor)

    try:
        fonte = ImageFont.truetype("DejaVuSans-Bold.ttf", 22)
        fonte_base = ImageFont.truetype("DejaVuSans-Bold.ttf", 26)
    except OSError:
        fonte = fonte_base = ImageFont.load_default()

    def texto(t, x, z, f):
        px, py = para_tela(x, z)
        caixa = draw.textbbox((0, 0), t, font=f)
        w, h = caixa[2] - caixa[0], caixa[3] - caixa[1]
        draw.text((px - w / 2, py - h / 2), t, font=f, fill=(255, 255, 255), stroke_width=3, stroke_fill=(20, 15, 35))

    for t, x, z in LEGENDAS:
        texto(t, x, z, fonte)
    for i in range(10):
        lado = -1 if i < 5 else 1
        linha = i % 5 + 1
        texto(f"Base{i + 1:02d}", lado * 136, (3 - linha) * 84, fonte_base)

    saida = RAIZ / "build" / "map_preview.png"
    img.save(saida)
    print(f"Imagem: {saida}")


if __name__ == "__main__":
    main()
