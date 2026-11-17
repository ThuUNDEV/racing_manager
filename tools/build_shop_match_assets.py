#!/usr/bin/env python3
"""Extract reference Shop illustrations; keep quantities rendered by the catalog.

Requires Pillow. Foreground masks retain the source highlights and white keylines.
Explicit outlines isolate overlapping source art; cutouts remove gem quantities.
No source image is modified. The manifest records source geometry and hashes.
"""
import hashlib
import json
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent / "assets/shop_blue_white"
REGIONS = {
 'gem_1':[661,630,107,62],'gem_2':[839,630,122,65],'gem_3':[1027,628,113,77],
 'gem_4':[659,785,122,79],'gem_5':[829,783,147,83],
 'cash_small':[676,1015,81,59],'cash_medium':[842,1009,116,66],'cash_large':[1012,1006,138,70],
 'starter_portrait':[38,267,212,194], 'starter_badge':[22,262,82,76],
 'income_x2_art':[50,484,177,125],'income_x2_multiplier':[233,520,152,87],
 'no_ads_art':[65,643,133,101], 'gift':[62,1104,112,94],
 'driver_coupon':[326,329,59,42],'gear_coupon':[402,326,59,43],
 'elite_gear':[369,865,58,52],'shard_my':[212,860,69,62],'shard_lam':[212,1004,69,62],
 'daily_gear':[641,435,108,83],'daily_driver':[914,434,115,82],
 'first_bonus':[625,598,126,47],'coming_soon':[625,987,95,49],
 'free_ribbon':[621,211,129,85],
 'char_my':[40,817,155,132],'char_lam':[40,960,155,124],
}

STARTER_OUTLINE = [(98,301),(97,291),(111,280),(142,267),(177,270),(193,281),(211,286),(216,305),(211,317),(215,338),(206,355),(205,372),(193,382),(177,391),(179,403),(211,415),(215,402),(215,378),(226,374),(234,388),(231,403),(244,404),(248,418),(244,427),(250,437),(242,449),(235,451),(239,461),(90,461),(87,452),(69,459),(57,454),(50,443),(43,434),(38,425),(45,411),(56,402),(53,394),(58,383),(67,391),(80,389),(84,383),(71,376),(62,361),(64,344),(76,329),(92,321)]

TAG_OUTLINES = {'coming_soon':[(0,22),(12,10),(84,0),(95,7),(80,34),(1,49)],'first_bonus':[(0,22),(12,12),(117,0),(126,9),(115,31),(0,47)],'free_ribbon':[(0,38),(12,24),(118,0),(129,11),(117,43),(0,85)]}


def foreground_mask(image):
    pixels = image.getdata()
    values = [
        255 if min(rgb[:3]) < 145 and (
            max(rgb[:3]) - min(rgb[:3]) > 30 or sum(rgb[:3]) / 3 < 125
        ) else 0
        for rgb in pixels
    ]
    mask = Image.new("L", image.size)
    mask.putdata(values)
    return mask


def polygon_mask(size, points):
    mask = Image.new("L", size)
    ImageDraw.Draw(mask).polygon(points, fill=255)
    return mask


def extract(source, name, region):
    x, y, w, h = region
    image = source.crop((x, y, x + w, y + h))
    mask = foreground_mask(image)
    if name == "starter_portrait":
        points = [(px - x, py - y) for px, py in STARTER_OUTLINE]
        mask = ImageChops.multiply(mask, polygon_mask(image.size, points))
    elif name == "starter_badge":
        mask.putdata([
            value if rgb[0] > rgb[2] * 1.15 else 0
            for value, rgb in zip(mask.getdata(), image.getdata())
        ])
    elif name in TAG_OUTLINES:
        mask = ImageChops.multiply(mask, polygon_mask(image.size, TAG_OUTLINES[name]))
    if name.startswith("gem_"):
        # The original screenshot draws the quantities across the lower icon edge.
        cutouts = {'gem_1':(691-x,674-y,742-x,h),'gem_2':(872-x,674-y,928-x,h),'gem_3':(1053-x,674-y,1118-x,h),'gem_4':(671-x,844-y,771-x,h),'gem_5':(850-x,844-y,954-x,h)}
        ImageDraw.Draw(mask).rectangle(cutouts[name], fill=0)
    if name.startswith("char_"):
        # Retain the pale portrait square, excluding the surrounding card's top edge.
        mask = Image.new("L", image.size, 255)
        draw = ImageDraw.Draw(mask)
        draw.rectangle((0, 0, w, 9), fill=0)
        draw.rectangle((25, 0, 120, 35), fill=255)
    padded = Image.new("L", (w + 2, h + 2))
    padded.paste(mask, (1, 1))
    ImageDraw.floodfill(padded, (0, 0), 128)
    mask = padded.crop((1, 1, w + 1, h + 1)).point(
        lambda value: 0 if value == 128 else 255
    ).filter(ImageFilter.MaxFilter(3))
    if name.startswith("gem_"):
        ImageDraw.Draw(mask).rectangle(cutouts[name], fill=0)
        if name in ["gem_1", "gem_2"]:
            # Exclude a neighboring blue ribbon caught at the source crop's top edge.
            mask.putdata([
                value if rgb[2] <= rgb[0] * 1.1 else 0
                for value, rgb in zip(mask.getdata(), image.getdata())
            ])
    if name in ["daily_gear", "daily_driver"]:
        ImageDraw.Draw(mask).rectangle((58, 56, w, h), fill=0)
    image.putalpha(mask)
    return image


def main():
    source_path = ROOT / "demo_reference.png"
    source = Image.open(source_path).convert("RGBA")
    output = ROOT / "match"
    output.mkdir(exist_ok=True)
    for name, region in REGIONS.items():
        extract(source, name, region).save(output / f"{name}.png")
    manifest = {
        "source": "../demo_reference.png",
        "source_sha256": hashlib.sha256(source_path.read_bytes()).hexdigest(),
        "method": "Reference crops with foreground masks; gem quantities are removed and rendered from catalog. Rebuild with tools/build_shop_match_assets.py.",
        "regions": REGIONS,
        "runtime_surface": {
            "implementation": "ui/shop_demo_skin.gd:reference_surface",
            "source": "demo_reference.png card silhouettes and sampled blue/white palette",
            "gradient": ["#ceeafb", "#ffffff"],
            "free_gradient": ["#a1e4f9", "#c8effc"],
            "border": "#6db4ef",
            "border_design_px": 2.5,
            "radius_design_px": 17,
        },
        "surfaces": {
            name: {
                "source": "Authored SVG following the reference palette, border and rounded silhouette",
                "sha256": hashlib.sha256((ROOT / name).read_bytes()).hexdigest(),
            }
            for name in ["buy_match.svg", "action_match.svg", "section_match.svg"]
        },
    }
    (output / "manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n"
    )


if __name__ == "__main__":
    main()
