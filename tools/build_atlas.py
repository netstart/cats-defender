#!/usr/bin/env python3
"""Cats Defender - asset pipeline.

Two responsibilities:
1. PLACEHOLDER GENERATION: while the paid CraftPix "Merge Cats Defender"
   pack is not on disk, generates procedural placeholder frames so the game
   is fully functional/testable. Drop real frames in assets/art/raw/<char>/<anim>/
   and this script will use them instead.
2. ATLAS BUILDING: concatenates frames (raw from disk or generated ones) into
   a horizontal spritesheet per (character, animation) plus a JSON metadata
   file with frame size/count so Godot can build SpriteFrames with 1 draw call.

Usage:
    python tools/build_atlas.py
Outputs:
    assets/art/atlases/<char>_<anim>.png
    assets/art/atlases/<char>_<anim>.json
"""
from __future__ import annotations

import json
import math
import os
import sys
from dataclasses import dataclass

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RAW_DIR = os.path.join(ROOT, "assets", "art", "raw")
OUT_DIR = os.path.join(ROOT, "assets", "art", "atlases")
META_PATH = os.path.join(OUT_DIR, "atlas_index.json")

FRAME = 128  # frame size in px (boss uses 192)


@dataclass
class Character:
    name: str
    kind: str  # "cat" | "enemy" | "boss"
    body_rgb: tuple[int, int, int]
    accent_rgb: tuple[int, int, int]
    anims: dict[str, int]  # anim name -> frame count
    size: int = FRAME


CAT_COLORS = [
    (240, 170, 60), (200, 90, 60), (150, 90, 200), (80, 160, 220),
    (90, 200, 120), (230, 120, 170), (240, 220, 90), (120, 120, 130),
    (180, 140, 100), (100, 200, 200), (220, 80, 120), (140, 190, 90),
    (170, 120, 220), (250, 150, 120), (110, 140, 230),
]
ENEMY_COLORS = [
    (110, 160, 70), (160, 110, 70), (90, 90, 110), (150, 70, 90),
    (70, 120, 150), (130, 150, 60), (120, 80, 140), (170, 130, 60),
]

CHARACTERS: list[Character] = []
for i, rgb in enumerate(CAT_COLORS, start=1):
    CHARACTERS.append(Character(
        name=f"cat_{i:02d}", kind="cat", body_rgb=rgb,
        accent_rgb=tuple(min(255, c + 40) for c in rgb),
        anims={"idle": 4, "shoot": 4},
    ))
CHARACTERS.append(Character(
    name="cat_guardian", kind="boss", body_rgb=(200, 60, 60),
    accent_rgb=(250, 180, 80), anims={"idle": 4, "attack": 6}, size=192,
))
CHARACTERS.append(Character(
    name="cat_boxing", kind="cat", body_rgb=(230, 90, 60),
    accent_rgb=(255, 200, 60), anims={"idle": 4, "attack": 4},
))
for i, rgb in enumerate(ENEMY_COLORS, start=1):
    CHARACTERS.append(Character(
        name=f"enemy_{i:02d}", kind="enemy", body_rgb=rgb,
        accent_rgb=tuple(max(0, c - 40) for c in rgb),
        anims={"idle": 4, "walk": 6, "attack": 4, "dead": 6},
    ))


def _shadow(d: ImageDraw.ImageDraw, cx: float, cy: float, w: float) -> None:
    d.ellipse([cx - w / 2, cy - 6, cx + w / 2, cy + 6], fill=(0, 0, 0, 70))


def draw_cat_frame(ch: Character, anim: str, t: float, size: int) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    s = size / 128.0
    bob = math.sin(t * math.tau) * 3 * s if anim == "idle" else 0.0
    kick = -6 * s * math.sin(t * math.pi) if anim in ("shoot", "attack") else 0.0
    cx, cy = size / 2 + kick, size * 0.62 + bob
    r = 30 * s
    _shadow(d, size / 2, size * 0.9, 60 * s)
    # tail
    tw = 8 * s
    tx = cx + r * 0.9
    d.line([tx, cy, tx + 16 * s, cy - 18 * s + bob], fill=ch.body_rgb + (255,), width=int(tw))
    # body
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=ch.body_rgb + (255,), outline=(30, 25, 30, 255), width=max(1, int(2 * s)))
    # ears
    for ex in (-16 * s, 16 * s):
        d.polygon([(cx + ex - 9 * s, cy - r * 0.7), (cx + ex + 9 * s, cy - r * 0.7), (cx + ex, cy - r * 1.5)],
                  fill=ch.accent_rgb + (255,), outline=(30, 25, 30, 255))
    # eyes
    for ex in (-11 * s, 11 * s):
        d.ellipse([cx + ex - 4 * s, cy - 8 * s, cx + ex + 4 * s, cy + 0], fill=(255, 255, 255, 255))
        d.ellipse([cx + ex - 2 * s, cy - 6 * s, cx + ex + 2 * s, cy - 2 * s], fill=(20, 20, 25, 255))
    # muzzle
    d.ellipse([cx - 5 * s, cy + 3 * s, cx + 5 * s, cy + 10 * s], fill=ch.accent_rgb + (255,))
    # gun
    gun_len = 30 * s + (8 * s if anim in ("shoot", "attack") else 0)
    d.rectangle([cx + r * 0.5, cy - 4 * s, cx + r * 0.5 + gun_len, cy + 4 * s], fill=(60, 60, 70, 255))
    if anim in ("shoot", "attack") and t > 0.4:
        fx = cx + r * 0.5 + gun_len
        d.polygon([(fx, cy - 10 * s), (fx + 14 * s, cy), (fx, cy + 10 * s)], fill=(255, 220, 90, 220))
    if ch.kind == "boss":
        # crown for the guardian
        for k in range(3):
            bx = cx + (k - 1) * 14 * s
            d.polygon([(bx - 7 * s, cy - r * 1.45), (bx + 7 * s, cy - r * 1.45), (bx, cy - r * 1.85)],
                      fill=(250, 210, 80, 255), outline=(120, 90, 20, 255))
    return img


def draw_enemy_frame(ch: Character, anim: str, t: float, size: int) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    s = size / 128.0
    wob = math.sin(t * math.tau) * 5 * s if anim == "walk" else 0.0
    squash = 1.0 + (0.25 * math.sin(t * math.pi) if anim == "attack" else 0.0)
    fade = max(0.0, 1.0 - t) if anim == "dead" else 1.0
    cx, cy = size / 2 + wob, size * 0.62
    rx, ry = 28 * s / squash, 28 * s * squash
    col = ch.body_rgb + (int(255 * fade),)
    _shadow(d, size / 2, size * 0.9, 56 * s * fade)
    d.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=col, outline=(25, 25, 25, int(255 * fade)), width=max(1, int(2 * s)))
    # spikes
    for k in range(5):
        a = math.pi * (0.15 + 0.7 * k / 4)
        px, py = cx + math.cos(a + math.pi) * rx, cy - math.sin(a) * ry
        tipx, tipy = cx + math.cos(a + math.pi) * (rx + 10 * s), cy - math.sin(a) * (ry + 10 * s)
        d.polygon([(px - 5 * s, py + 3 * s), (px + 5 * s, py + 3 * s), (tipx, tipy)],
                  fill=ch.accent_rgb + (int(255 * fade),))
    # angry eyes
    for ex in (-10 * s, 10 * s):
        d.ellipse([cx + ex - 4 * s, cy - 8 * s, cx + ex + 4 * s, cy], fill=(255, 60, 60, int(255 * fade)))
    if anim == "dead":
        for ex in (-10 * s, 10 * s):
            d.line([cx + ex - 4 * s, cy - 8 * s, cx + ex + 4 * s, cy], fill=(20, 20, 20, 255), width=2)
            d.line([cx + ex + 4 * s, cy - 8 * s, cx + ex - 4 * s, cy], fill=(20, 20, 20, 255), width=2)
    # teeth
    d.polygon([(cx - 10 * s, cy + 8 * s), (cx - 4 * s, cy + 14 * s), (cx + 2 * s, cy + 8 * s),
               (cx + 8 * s, cy + 14 * s), (cx + 12 * s, cy + 8 * s)],
              fill=(240, 240, 230, int(255 * fade)))
    return img


def load_raw_frames(ch: Character, anim: str) -> list[Image.Image] | None:
    d = os.path.join(RAW_DIR, ch.name, anim)
    if not os.path.isdir(d):
        return None
    files = sorted(f for f in os.listdir(d) if f.lower().endswith(".png"))
    if not files:
        return None
    return [Image.open(os.path.join(d, f)).convert("RGBA") for f in files]


def build_atlas(frames: list[Image.Image], size: int) -> Image.Image:
    sheet = Image.new("RGBA", (size * len(frames), size), (0, 0, 0, 0))
    for i, fr in enumerate(frames):
        if fr.size != (size, size):
            fr = fr.resize((size, size))
        sheet.paste(fr, (i * size, 0))
    return sheet


def main() -> int:
    os.makedirs(OUT_DIR, exist_ok=True)
    index: dict[str, dict[str, dict]] = {}
    for ch in CHARACTERS:
        index[ch.name] = {"kind": ch.kind, "size": ch.size, "anims": {}}
        for anim, count in ch.anims.items():
            frames = load_raw_frames(ch, anim)
            if frames is None:
                draw = draw_cat_frame if ch.kind in ("cat", "boss") else draw_enemy_frame
                frames = [draw(ch, anim, i / max(1, count - 1), ch.size) for i in range(count)]
            sheet = build_atlas(frames, ch.size)
            png = os.path.join(OUT_DIR, f"{ch.name}_{anim}.png")
            sheet.save(png)
            index[ch.name]["anims"][anim] = {
                "png": f"{ch.name}_{anim}.png", "frames": len(frames),
                "frame_w": ch.size, "frame_h": ch.size,
            }
        print(f"[atlas] {ch.name}: {', '.join(ch.anims)}")
    with open(META_PATH, "w", encoding="utf-8") as fh:
        json.dump(index, fh, indent=2)
    print(f"[atlas] wrote {META_PATH}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
