#!/usr/bin/env python3
"""Cut the shop artwork out of demo_reference.png into standalone PNG files.

The game loads these files directly (ShopSkin.sprite), so no code depends on pixel
rectangles of the reference screenshot any more. Re-run after changing REGIONS.
"""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent / "assets" / "shop_blue_white"
REGIONS = {
    "title_ribbon": (108, 82, 404, 61),
    "gift": (62, 1104, 112, 94),
    "income_x2_art": (50, 484, 177, 125),
    "no_ads_art": (65, 643, 133, 101),
    "income_x2_multiplier": (233, 520, 152, 87),
    "starter_badge": (22, 262, 82, 76),
    "free_gem_art": (621, 211, 180, 112),
    "currency_ribbon": (625, 987, 95, 49),
    "starter_1": (39, 274, 184, 186),
    "char_my": (40, 817, 155, 132),
    "char_lam": (40, 960, 155, 124),
    "driver_coupon": (326, 329, 59, 42),
    "gear_coupon": (402, 326, 59, 43),
    "elite_gear": (369, 865, 58, 52),
    "shard_my": (212, 860, 69, 62),
    "shard_lam": (212, 1004, 69, 62),
    "daily_gear": (641, 435, 108, 83),
    "daily_driver": (914, 434, 115, 82),
}

if __name__ == "__main__":
    source = Image.open(ROOT / "demo_reference.png").convert("RGBA")
    out = ROOT / "crops"
    out.mkdir(exist_ok=True)
    for name, (x, y, w, h) in REGIONS.items():
        source.crop((x, y, x + w, y + h)).save(out / f"{name}.png")
    print(f"wrote {len(REGIONS)} crops to {out}")
