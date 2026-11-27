#!/usr/bin/env python3
"""Put a demo image and a game capture side by side at the same logical width, with a grid.

python3 tools/compare_ui.py DEMO GAME OUT.png [--width 390] [--crop x,y,w,h] [--grid 50]

--crop cuts the game capture (in logical px of the capture) to the part the demo shows,
e.g. only the popup panel when the demo is a popup without the screen behind it.
Grid lines are in logical px so differences can be written as coordinates.
Never retouch the game capture: this only scales, crops and draws lines.
"""
import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

p = argparse.ArgumentParser()
p.add_argument("demo")
p.add_argument("game")
p.add_argument("out")
p.add_argument("--width", type=int, default=390)
p.add_argument("--crop", default="")
p.add_argument("--grid", type=int, default=50)
a = p.parse_args()

try:
    font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 11)
except OSError:
    font = ImageFont.load_default()


def fit(img: Image.Image, width: int) -> Image.Image:
    return img.resize((width, round(img.height * width / img.width)), Image.Resampling.LANCZOS)


demo = Image.open(a.demo).convert("RGB")
game = Image.open(a.game).convert("RGB")
game = fit(game, a.width)
if a.crop:
    x, y, w, h = (int(v) for v in a.crop.split(","))
    game = game.crop((x, y, x + w, y + h))
w = game.width
demo = fit(demo, w)


def grid(img: Image.Image) -> Image.Image:
    img = img.copy()
    d = ImageDraw.Draw(img, "RGBA")
    for x in range(0, img.width, a.grid):
        d.line([(x, 0), (x, img.height)], fill=(255, 0, 80, 70))
    for y in range(0, img.height, a.grid):
        d.line([(0, y), (img.width, y)], fill=(255, 0, 80, 70))
        d.text((2, y + 1), str(y), font=font, fill=(255, 0, 80, 200))
    return img


h = max(demo.height, game.height)
gap = 10
canvas = Image.new("RGB", (w * 2 + gap, h + 20), "white")
canvas.paste(grid(demo), (0, 20))
canvas.paste(grid(game), (w + gap, 20))
d = ImageDraw.Draw(canvas)
d.text((4, 4), f"DEMO  {Path(a.demo).name}", font=font, fill="black")
d.text((w + gap + 4, 4), f"GAME  {Path(a.game).name}  width {a.width}", font=font, fill="black")
Path(a.out).parent.mkdir(parents=True, exist_ok=True)
canvas.save(a.out)
print(f"saved {a.out} ({canvas.width}x{canvas.height}), logical width {w}")
