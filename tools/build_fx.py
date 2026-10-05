#!/usr/bin/env python3
"""Generate FX/bullet/UI placeholder sprites for Cats Defender (CC0, procedural)."""
import math
import os

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "art")
os.makedirs(os.path.join(OUT, "sprites", "bullets"), exist_ok=True)
os.makedirs(os.path.join(OUT, "fx"), exist_ok=True)
os.makedirs(os.path.join(OUT, "ui", "icons"), exist_ok=True)


def bullet(name: str, rgb: tuple[int, int, int], size: int = 32) -> None:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([6, 10, size - 6, size - 10], fill=rgb + (255,), outline=(255, 255, 255, 200))
    d.ellipse([size - 14, 13, size - 7, size - 13], fill=(255, 255, 255, 230))
    img.save(os.path.join(OUT, "sprites", "bullets", f"{name}.png"))


def explosion() -> None:
    frames = 8
    size = 128
    sheet = Image.new("RGBA", (size * frames, size), (0, 0, 0, 0))
    for i in range(frames):
        t = i / (frames - 1)
        d = ImageDraw.Draw(sheet)
        r = 12 + t * 48
        a = int(255 * (1 - t))
        cx = cy = i * size + size // 2 if False else size // 2
        x0 = i * size + size // 2
        d.ellipse([x0 - r, size // 2 - r, x0 + r, size // 2 + r], fill=(255, 160 + int(60 * (1 - t)), 40, a))
        r2 = r * 0.6
        d.ellipse([x0 - r2, size // 2 - r2, x0 + r2, size // 2 + r2], fill=(255, 230, 120, a))
    sheet.save(os.path.join(OUT, "fx", "explosion.png"))


def muzzle() -> None:
    img = Image.new("RGBA", (48, 48), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for k in range(8):
        a = k * math.pi / 4
        d.line([24, 24, 24 + math.cos(a) * 20, 24 + math.sin(a) * 20], fill=(255, 220, 110, 255), width=4)
    img.save(os.path.join(OUT, "fx", "muzzle.png"))


def icon(name: str, rgb: tuple[int, int, int], shape: str) -> None:
    img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    if shape == "coin":
        d.ellipse([8, 8, 56, 56], fill=rgb + (255,), outline=(150, 100, 20), width=3)
        d.ellipse([18, 18, 46, 46], outline=(150, 100, 20), width=3)
    elif shape == "star":
        pts = []
        for k in range(10):
            a = -math.pi / 2 + k * math.pi / 5
            r = 26 if k % 2 == 0 else 11
            pts.append((32 + math.cos(a) * r, 32 + math.sin(a) * r))
        d.polygon(pts, fill=rgb + (255,), outline=(150, 110, 20))
    elif shape == "wrench":
        d.rectangle([28, 10, 36, 44], fill=rgb + (255,))
        d.pieslice([18, 0, 46, 28], 0, 180, fill=rgb + (255,))
        d.rectangle([26, 40, 38, 58], fill=rgb + (255,))
    elif shape == "spike":
        for k in range(3):
            x = 12 + k * 16
            d.polygon([(x, 52), (x + 12, 52), (x + 6, 14)], fill=rgb + (255,), outline=(60, 60, 70))
    elif shape == "tnt":
        d.rectangle([10, 20, 54, 54], fill=rgb + (255,), outline=(90, 30, 20), width=3)
        d.line([20, 20, 20, 54], fill=(90, 30, 20), width=2)
        d.line([44, 20, 44, 54], fill=(90, 30, 20), width=2)
        d.line([32, 20, 38, 8], fill=(200, 160, 90), width=3)
    elif shape == "glove":
        d.ellipse([12, 16, 46, 50], fill=rgb + (255,), outline=(120, 30, 20), width=3)
        d.rectangle([10, 36, 48, 52], fill=rgb + (255,), outline=(120, 30, 20), width=3)
    img.save(os.path.join(OUT, "ui", "icons", f"{name}.png"))


bullet("bullet_yellow", (250, 210, 80))
bullet("bullet_red", (240, 90, 70))
bullet("bullet_blue", (90, 170, 250))
explosion()
muzzle()
icon("coin", (250, 200, 60), "coin")
icon("star", (255, 215, 80), "star")
icon("repair", (150, 200, 255), "wrench")
icon("spikes", (170, 170, 190), "spike")
icon("tnt", (200, 60, 40), "tnt")
icon("glove", (230, 80, 50), "glove")
print("[fx] bullets, explosion, muzzle, icons written")
