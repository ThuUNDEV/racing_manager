"""Cut the Free Gifts concept sheet into reusable transparent Godot textures."""
from pathlib import Path
import argparse
import json
import shutil

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/free_gifts_v1"
NAMES = [
    "header_cyan", "card_daily_gold", "card_gems_lavender",
    "card_gear_mint", "card_driver_blue", "button_claim_green",
    "button_video_blue", "quantity_pill", "icon_gem",
    "icon_gear_ticket", "icon_driver_ticket", "icon_gift",
]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("sheet", type=Path)
    args = parser.parse_args()
    source = Image.open(args.sheet).convert("RGBA")
    OUT.mkdir(parents=True, exist_ok=True)
    styles = OUT / "styles"
    styles.mkdir(exist_ok=True)
    manifest = {"source_size": list(source.size), "assets": {}}
    preview = Image.new("RGB", (1080, 1080), "#eee9e1")
    draw = ImageDraw.Draw(preview)
    for index, name in enumerate(NAMES):
        col, row = index % 3, index // 3
        rect = (round(col * source.width / 3), round(row * source.height / 4),
                round((col + 1) * source.width / 3), round((row + 1) * source.height / 4))
        pixels = np.array(source.crop(rect))
        # Discard detached alpha speckles while preserving the main asset,
        # its antialiased edge and substantial separate details / drop shadows.
        labels, count = ndimage.label(pixels[:, :, 3] > 12)
        areas = np.bincount(labels.ravel())
        areas[0] = 0
        largest = int(areas.max())
        retained = np.flatnonzero(areas >= max(80, largest * 0.012))
        mask = ndimage.binary_dilation(np.isin(labels, retained), iterations=2)
        pixels[:, :, 3][~mask] = 0
        pixels[pixels[:, :, 3] == 0] = 0
        asset = Image.fromarray(pixels)
        bounds = asset.getbbox()
        assert bounds and largest > 1000, name
        asset = asset.crop(bounds)
        padded = Image.new("RGBA", (asset.width + 8, asset.height + 8))
        padded.alpha_composite(asset, (4, 4))
        padded.save(OUT / f"{name}.png")
        entry = {"file": f"{name}.png", "size": list(padded.size), "source_cell": list(rect)}
        if not name.startswith("icon_") and name != "header_cyan":
            # Godot uses slice margins in destination pixels too. Normalize
            # the skin texture to mobile height so corners fit 44px buttons.
            skin_height = 96 if name.startswith("card_") else (28 if name == "quantity_pill" else 44)
            skin = padded.resize((round(padded.width * skin_height / padded.height), skin_height), Image.Resampling.LANCZOS)
            skin_folder = styles / "textures"
            skin_folder.mkdir(exist_ok=True)
            skin.save(skin_folder / f"{name}.png")
            margin = 18 if name.startswith("card_") else (12 if name == "quantity_pill" else 20)
            entry["nine_slice_margin"] = margin
            texture_path = f"res://assets/free_gifts_v1/styles/textures/{name}.png"
            lines = ['[gd_resource type="StyleBoxTexture" load_steps=2 format=3]', '',
                     f'[ext_resource type="Texture2D" path="{texture_path}" id="1"]', '',
                     '[resource]', 'texture = ExtResource("1")']
            for side in ("left", "top", "right", "bottom"):
                lines.append(f"texture_margin_{side} = {float(margin)}")
                lines.append(f"content_margin_{side} = {12.0 if side in ('left', 'right') else 8.0}")
            (styles / f"{name}.tres").write_text("\n".join(lines) + "\n", encoding="utf-8")
        manifest["assets"][name] = entry
        thumb = padded.copy()
        thumb.thumbnail((320, 218), Image.Resampling.LANCZOS)
        x, y = col * 360, row * 270
        # Alternating background makes alpha and stray pixels easy to inspect.
        for cy in range(y + 10, y + 240, 16):
            for cx in range(x + 10, x + 350, 16):
                draw.rectangle((cx, cy, min(cx + 15, x + 349), min(cy + 15, y + 239)),
                               fill="#ffffff" if ((cx - x) // 16 + (cy - y) // 16) % 2 else "#d8d8d8")
        preview.paste(thumb, (x + (360 - thumb.width) // 2, y + 15 + (218 - thumb.height) // 2), thumb)
        draw.text((x + 12, y + 248), name, fill="#16354c")
    (OUT / "manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    preview_path = ROOT / "output/free_gifts_v1_preview.png"
    preview_path.parent.mkdir(exist_ok=True)
    preview.save(preview_path)
    print(f"Exported {len(NAMES)} transparent PNGs and 7 StyleBoxTexture resources to {OUT}")
    print(f"Preview: {preview_path}")


if __name__ == "__main__":
    main()
