#!/usr/bin/env python3
"""Score how close a game capture is to a demo image (0-100) and show where they differ.

python3 tools/ui_similarity.py DEMO GAME OUT_PREFIX [--demo-crop x,y,w,h] [--game-crop x,y,w,h] [--width 390] [--cell 24]

Both images are scaled to --width logical px first; crops are in those logical px.
Crop both to the same area (e.g. the popup panel edge to edge) so they line up.
The area is cut into cells of --cell px. Each cell gets:
  color     how close the average color is (blurred, so anti-aliasing and font details do not count)
  structure how close the edges are (shapes, borders, text blocks, icons in the same place)
score = mean over cells of (0.5 color + 0.5 structure), as a percentage.
Writes OUT_PREFIX_heatmap.png (red = differs) and OUT_PREFIX_score.json (worst cells listed).
Only scales and crops: the game capture is never retouched. Pure PIL, no numpy.
"""
import argparse
import json
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

p = argparse.ArgumentParser()
p.add_argument("demo")
p.add_argument("game")
p.add_argument("out")
p.add_argument("--demo-crop", default="")
p.add_argument("--game-crop", default="")
p.add_argument("--width", type=int, default=390)
p.add_argument("--cell", type=int, default=24)
a = p.parse_args()


def load(path: str, crop: str) -> Image.Image:
    img = Image.open(path).convert("RGB")
    img = img.resize((a.width, round(img.height * a.width / img.width)), Image.Resampling.LANCZOS)
    if crop:
        x, y, w, h = (int(v) for v in crop.split(","))
        img = img.crop((x, y, x + w, y + h))
    return img


demo = load(a.demo, a.demo_crop)
game = load(a.game, a.game_crop)
ratio = (demo.width / demo.height) / (game.width / game.height)
if abs(ratio - 1) > 0.03:
    print(f"WARNING: crops have different shapes ({demo.size} vs {game.size}); align the crops first")
game = game.resize(demo.size, Image.Resampling.LANCZOS)
W, H, C = demo.width, demo.height, a.cell
cols, rows = max(1, W // C), max(1, H // C)


def color_grid(img: Image.Image) -> list:
    return list(img.filter(ImageFilter.GaussianBlur(6)).resize((cols, rows), Image.Resampling.BOX).getdata())


def edge_grid(img: Image.Image) -> list:
    edges = img.convert("L").filter(ImageFilter.GaussianBlur(1.5)).filter(ImageFilter.FIND_EDGES)
    # Thicken edges so a shift of a few px still overlaps; small offsets cost a little, not everything.
    edges = edges.point(lambda v: 255 if v > 24 else 0).filter(ImageFilter.MaxFilter(7))
    return list(edges.resize((cols * 3, rows * 3), Image.Resampling.BOX).getdata())


def shifted(img: Image.Image, dx: int, dy: int) -> Image.Image:
    return img.transform(img.size, Image.AFFINE, (1, 0, -dx, 0, 1, -dy), resample=Image.Resampling.BILINEAR,
                         fillcolor=img.getpixel((img.width // 2, 2)))


def score_cells(dc: list, de: list, gc: list, ge: list) -> list:
    out = []
    for r in range(rows):
        for c in range(cols):
            i = r * cols + c
            dist = math.dist(dc[i], gc[i])  # 0..441
            color = max(0.0, 1 - dist / 160)
            # Edges per sub-cell (3x3 inside the cell): overlap of where they are, and how many.
            # A missing or extra shape costs; empty in both counts as a match.
            both = either = d_sum = g_sum = 0.0
            for sr in range(3):
                for sc in range(3):
                    j = (r * 3 + sr) * cols * 3 + c * 3 + sc
                    both += min(de[j], ge[j])
                    either += max(de[j], ge[j])
                    d_sum += de[j]
                    g_sum += ge[j]
            place = 1.0 if either < 255 * 0.15 else both / either
            amount = 1.0 if max(d_sum, g_sum) < 255 * 0.15 else min(d_sum, g_sum) / max(d_sum, g_sum)
            structure = 0.5 * place + 0.5 * amount
            out.append((color, structure))
    return out


# Each cell may line up with the game moved by up to SHIFT px in any direction, so an element that is
# a few px off still counts as matching (AI demos are never pixel exact). Bigger offsets cost.
SHIFT = 4
dc, de = color_grid(demo), edge_grid(demo)
best = None
for dx in (-SHIFT, 0, SHIFT):
    for dy in (-SHIFT, 0, SHIFT):
        g = shifted(game, dx, dy)
        trial = score_cells(dc, de, color_grid(g), edge_grid(g))
        best = trial if best is None else [max(b, t, key=lambda v: v[0] + v[1]) for b, t in zip(best, trial)]
cells = []
for i, (color, structure) in enumerate(best):
    cells.append({"x": (i % cols) * C, "y": (i // cols) * C, "color": round(color, 3), "structure": round(structure, 3),
                  "score": round(0.5 * color + 0.5 * structure, 3)})

score = 100 * sum(c["score"] for c in cells) / len(cells)
color = 100 * sum(c["color"] for c in cells) / len(cells)
structure = 100 * sum(c["structure"] for c in cells) / len(cells)

# Heatmap: demo | game | game with red cells where it differs.
heat = game.copy()
d = ImageDraw.Draw(heat, "RGBA")
for cell in cells:
    bad = 1 - cell["score"]
    if bad > 0.1:
        d.rectangle([cell["x"], cell["y"], cell["x"] + C - 1, cell["y"] + C - 1], fill=(255, 0, 0, int(min(1, bad * 1.6) * 170)))
try:
    font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 12)
except OSError:
    font = ImageFont.load_default()
canvas = Image.new("RGB", (W * 3 + 20, H + 22), "white")
for k, img in enumerate([demo, game, heat]):
    canvas.paste(img, (k * (W + 10), 22))
t = ImageDraw.Draw(canvas)
t.text((4, 4), "DEMO", font=font, fill="black")
t.text((W + 14, 4), "GAME", font=font, fill="black")
t.text((2 * W + 24, 4), f"score {score:.1f}%  color {color:.0f}  structure {structure:.0f}", font=font, fill="black")
Path(a.out).parent.mkdir(parents=True, exist_ok=True)
canvas.save(f"{a.out}_heatmap.png")
worst = sorted(cells, key=lambda c: c["score"])[:12]
Path(f"{a.out}_score.json").write_text(json.dumps({
    "score": round(score, 1), "color": round(color, 1), "structure": round(structure, 1),
    "size": [W, H], "cell": C, "worst_cells": worst}, indent=1))
print(f"score {score:.1f}%  (color {color:.1f}, structure {structure:.1f})  -> {a.out}_heatmap.png")
