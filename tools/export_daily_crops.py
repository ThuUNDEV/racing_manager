#!/usr/bin/env python3
"""Cut the Daily Gift artwork into standalone PNG files (assets/daily_rewards/crops).

ui/daily_rewards_popup.gd loads these directly, so no code depends on pixel rectangles
of art.png / today.png / skin.png. Re-run after changing REGIONS.
"""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent / "assets" / "daily_rewards"
REGIONS = {  # name: (source file, x, y, w, h)
    "header": ("art.png", 8, 125, 403, 200), "chest": ("art.png", 449, 88, 363, 296),
    "pro": ("art.png", 849, 102, 394, 257), "standard": ("art.png", 12, 502, 399, 259),
    "allstar": ("art.png", 427, 494, 399, 270), "elite": ("art.png", 846, 495, 400, 269),
    "gem": ("art.png", 70, 934, 286, 231), "gems": ("art.png", 432, 927, 379, 258),
    "gift": ("art.png", 892, 893, 306, 300),
    "today": ("today.png", 124, 40, 1072, 1105),
    "marker": ("skin.png", 136, 1227, 62, 62),
}

if __name__ == "__main__":
    out = ROOT / "crops"
    out.mkdir(exist_ok=True)
    sources: dict[str, Image.Image] = {}
    for name, (src, x, y, w, h) in REGIONS.items():
        image = sources.setdefault(src, Image.open(ROOT / src).convert("RGBA"))
        image.crop((x, y, x + w, y + h)).save(out / f"{name}.png")
    print(f"wrote {len(REGIONS)} crops to {out}")
