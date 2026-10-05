#!/usr/bin/env python3
"""Gera icon.png (512x512) do app — gato laranja em fundo escuro (CC0)."""
import math
import os

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
img = Image.new("RGBA", (512, 512), (26, 27, 34, 255))
d = ImageDraw.Draw(img)
# arco de fundo
d.ellipse([56, 96, 456, 456], fill=(38, 36, 48, 255))
# corpo
d.ellipse([146, 190, 366, 400], fill=(240, 170, 60, 255), outline=(30, 25, 30, 255), width=8)
# orelhas
for ex in (-58, 58):
    d.polygon([(256 + ex - 36, 260), (256 + ex + 36, 260), (256 + ex, 150)],
              fill=(250, 196, 100, 255), outline=(30, 25, 30, 255))
# olhos
for ex in (-42, 42):
    d.ellipse([256 + ex - 15, 250, 256 + ex + 15, 280], fill=(255, 255, 255, 255))
    d.ellipse([256 + ex - 7, 258, 256 + ex + 7, 272], fill=(20, 20, 25, 255))
# focinho
d.ellipse([238, 285, 274, 308], fill=(250, 210, 130, 255))
# boca do gato (W)
d.arc([228, 290, 256, 320], 15, 165, fill=(30, 25, 30), width=5)
d.arc([256, 290, 284, 320], 15, 165, fill=(30, 25, 30), width=5)
# bigodes
for sy in (292, 306):
    d.line([150, sy, 218, sy - 6], fill=(255, 255, 255, 180), width=4)
    d.line([362, sy - 6, 430, sy], fill=(255, 255, 255, 180), width=4)
# rabinho
d.arc([330, 250, 460, 420], 200, 330, fill=(240, 170, 60, 255), width=28)
img.save(os.path.join(ROOT, "icon.png"))
img.resize((192, 192)).save(os.path.join(ROOT, "icon_192.png"))
print("[icon] icon.png, icon_192.png")
