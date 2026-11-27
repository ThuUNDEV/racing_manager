#!/usr/bin/env python3
"""Cut the Epic car popup sprites from the approved concept (Design/Concepts/IAP_Epic_Garage_v1/epic_car_popup_v1.png).

python3 tools/build_epic_popup_assets.py [--no-bg]

Rects are logical px of the concept scaled to width 390 (as in Design/Previews/epic_popup_v2/plan.md);
crops are taken from the full-resolution concept. Three kinds of output in assets/epic_popup_v1/:
  stage    opaque crop, edges faded to the panel color so it blends into the card
  cutout   transparent sprite, background removed by the art-tools server (/remove-bg)
  slice    9-slice skin: left cap + one clean column + right cap (right cap may be the mirrored left cap),
           so a box drawn in the concept stretches to any width without its text or icons
Raw crops go to output/imagegen/epic_popup_v1/ with prompts.json-style provenance in the asset manifest.
"""
import argparse
import hashlib
import json
import subprocess
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageOps

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "Design/Concepts/IAP_Epic_Garage_v1/epic_car_popup_v1.png"
RAW = ROOT / "output/imagegen/epic_popup_v1"
OUT = ROOT / "assets/epic_popup_v1"
REMOVE_BG = "http://192.168.11.181:8790/remove-bg"
PANEL = (252, 237, 226)  # inner card color sampled from the concept

# name: (x, y, w, h) logical
STAGE = {"stage_zenith": (18, 140, 354, 254)}
CUTOUTS = {
    "header_gift": (26, 66, 64, 68),
    "close_round": (328, 66, 48, 48),
    "tile_speed": (46, 476, 68, 54),
    "tile_collect": (156, 466, 82, 61),
    "tile_flag": (276, 474, 68, 58),
}
# name: (exact shape rect, corner radius, left cap, clean column x (logical, absolute), right cap)
# Everything outside the rounded shape becomes transparent.
SLICES = {
    "header_bar": ((13, 83, 363, 52), 26, 17, 89, 55),
    "chip": ((56.5, 434, 277, 31), 15.5, 18, 317, 18),
    "tile": ((25, 476, 110, 91), 15, 16, 42, 16),
    "button": ((23.4, 577.4, 343.2, 65), 32.5, 36, 100, 36),
}
# Close button sits on the header's right end in the concept; the header cap repaints that area as bar.
CLOSE = (352.0, 89.0, 21.0)  # centre x, y, radius (with its white rim)

src = Image.open(SRC).convert("RGBA")
F = src.width / 390.0


def crop(rect) -> Image.Image:
    x, y, w, h = rect
    return src.crop((round(x * F), round(y * F), round((x + w) * F), round((y + h) * F)))


def save(img: Image.Image, name: str) -> Path:
    OUT.mkdir(parents=True, exist_ok=True)
    path = OUT / f"{name}.png"
    img.save(path, optimize=True)
    return path


def remove_bg(raw: Path, out: Path) -> None:
    subprocess.run(["curl", "-sSf", "--data-binary", f"@{raw}", f"{REMOVE_BG}?name={raw.name}&refine=1&trim=1&pad=4",
                    "-o", str(out)], check=True)


def fade_edges(img: Image.Image, px: int) -> Image.Image:
    """Blend the crop border into PANEL so the opaque stage has no visible seam."""
    base = Image.new("RGBA", img.size, PANEL + (255,))
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rectangle([px, px, img.width - px - 1, img.height - px - 1], fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(px / 2))
    return Image.composite(img, base, mask)


p = argparse.ArgumentParser()
p.add_argument("--no-bg", action="store_true", help="skip background removal (reuse existing cutouts)")
a = p.parse_args()
RAW.mkdir(parents=True, exist_ok=True)
manifest = {"version": 1, "source": str(SRC.relative_to(ROOT)), "logical_width": 390, "scale": round(F, 4), "assets": {}}

for name, rect in STAGE.items():
    raw = crop(rect)
    raw.save(RAW / f"{name}.png")
    path = save(fade_edges(raw, round(4 * F)), name)
    manifest["assets"][name] = {"mode": "stage", "rect": rect, "size": raw.size}

def rounded_mask(size, radius_px: float) -> Image.Image:
    """Anti-aliased rounded-rect mask (4x supersampled)."""
    s = 4
    big = Image.new("L", (size[0] * s, size[1] * s), 0)
    ImageDraw.Draw(big).rounded_rectangle([0, 0, big.width - 1, big.height - 1], radius=radius_px * s, fill=255)
    return big.resize(size, Image.Resampling.LANCZOS)


def circle_cutout(cx: float, cy: float, r: float) -> Image.Image:
    pad = 1.5
    img = crop((cx - r - pad, cy - r - pad, 2 * (r + pad), 2 * (r + pad)))
    s = 4
    big = Image.new("L", (img.width * s, img.height * s), 0)
    c, rr = big.width / 2, r * F * s
    ImageDraw.Draw(big).ellipse([c - rr, c - rr, c + rr, c + rr], fill=255)
    img.putalpha(big.resize(img.size, Image.Resampling.LANCZOS))
    return img


for name, rect in CUTOUTS.items():
    raw_path = RAW / f"{name}.png"
    crop(rect).save(raw_path)
    if name == "close_round":
        save(circle_cutout(*CLOSE), name)
    elif not a.no_bg:
        remove_bg(raw_path, OUT / f"{name}.png")
    manifest["assets"][name] = {"mode": "cutout", "rect": rect, "size": Image.open(OUT / f"{name}.png").size}

for name, (rect, radius, left, column, right) in SLICES.items():
    raw = crop(rect)
    if name == "header_bar":
        # Paint the close button out of the bar: inside the bar outline use the clean column's colour of that row.
        cx_px = round((column - rect[0]) * F)
        px = raw.load()
        # The left end is hidden behind the gift in the concept, so rebuild it from the clean column too.
        ccx, ccy, cr = ((CLOSE[0] - rect[0]) * F, (CLOSE[1] - rect[1]) * F, (CLOSE[2] + 1.0) * F)
        lw = round(left * F)
        for y in range(raw.height):
            fill = px[cx_px, y]
            for x in range(raw.width):
                if x < lw or (x - ccx) ** 2 + (y - ccy) ** 2 <= cr * cr or (x > ccx and y < ccy) or x >= raw.width - round(4 * F):
                    px[x, y] = fill
    raw.putalpha(Image.composite(raw.getchannel("A"), Image.new("L", raw.size, 0), rounded_mask(raw.size, radius * F)))
    raw.save(RAW / f"{name}.png")
    lw, rw = round(left * F), round(right * F)
    cx = round((column - rect[0]) * F)
    mid = raw.crop((cx, 0, cx + 1, raw.height)).resize((4, raw.height))
    left_img = raw.crop((0, 0, lw, raw.height))
    right_img = raw.crop((raw.width - rw, 0, raw.width, raw.height))
    img = Image.new("RGBA", (lw + 4 + rw, raw.height), (0, 0, 0, 0))
    img.paste(left_img, (0, 0))
    img.paste(mid, (lw, 0))
    img.paste(right_img, (lw + 4, 0))
    save(img, name)
    manifest["assets"][name] = {"mode": "slice", "rect": rect, "size": img.size, "margin_left_px": lw,
                                "margin_right_px": rw, "logical_height": rect[3]}

for name, info in manifest["assets"].items():
    data = (OUT / f"{name}.png").read_bytes()
    info["sha256"] = hashlib.sha256(data).hexdigest()
    info["provenance"] = ("direct crop of the approved concept" + ("" if info["mode"] != "cutout" else
                          ", background removed by art-tools remove-bg (refine=1)"))
(OUT / "manifest.json").write_text(json.dumps(manifest, indent=1, ensure_ascii=False))
print(f"wrote {len(manifest['assets'])} assets to {OUT.relative_to(ROOT)}")
