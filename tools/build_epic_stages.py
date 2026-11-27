#!/usr/bin/env python3
"""Hậu xử lý ảnh sân khấu Xe Epic sinh bởi tools/gen_epic_stages.py -> assets/epic_popup_v1/stage_<xe>.png (832x596, viền hoà vào màu thẻ)."""
import hashlib, json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "output/imagegen/epic_popup_stage"
OUT = ROOT / "assets/epic_popup_v1"
PANEL = (252, 237, 226)
SIZE = (832, 596)


def fade_edges(img, px):
    base = Image.new("RGBA", img.size, PANEL + (255,))
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rectangle([px, px, img.width - px - 1, img.height - px - 1], fill=255)
    return Image.composite(img, base, mask.filter(ImageFilter.GaussianBlur(px / 2)))


manifest_path = OUT / "manifest.json"
manifest = json.loads(manifest_path.read_text())
for name in ["pico", "nova", "apex", "titan", "zenith", "paint_aurora", "paint_solar", "paint_midnight", "paint_sakura", "paint_neon"]:
    if not (RAW / f"raw_{name}.png").exists():
        continue
    img = Image.open(RAW / f"raw_{name}.png").convert("RGBA")
    img = img.crop((20, 0, img.width - 20, img.height)).resize(SIZE, Image.LANCZOS)
    img = fade_edges(img, 8)
    path = OUT / f"stage_{name}.png"
    img.save(path, optimize=True)
    manifest["assets"][f"stage_{name}"] = {"mode": "stage", "size": list(SIZE), "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
        "provenance": "gpt-image-2.6-flare (tools/gen_epic_stages.py), refs stage_zenith_concept.png + ảnh chụp model 3D (tests/epic_car_ref_capture.gd); prompts: output/imagegen/epic_popup_stage/prompts.json"}
    print("wrote", path)
manifest_path.write_text(json.dumps(manifest, indent=1, ensure_ascii=False))
