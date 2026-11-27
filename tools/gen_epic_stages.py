#!/usr/bin/env python3
"""Sinh ảnh sân khấu 2D cho Xe Epic / Bộ sơn Epic, KHỚP model 3D trong game.

Hai ảnh tham chiếu mỗi ảnh: (1) stage_zenith (phong cách sân khấu: bệ ca rô, quầng tím, ruy băng EPIC), (2) ảnh chụp model 3D
(tests/epic_car_ref_capture.gd -> output/imagegen/epic_popup_stage/ref3d_*.png) để giữ đúng dáng xe và màu sơn.
Ảnh thô + prompts.json ở output/imagegen/epic_popup_stage/; hậu xử lý: tools/build_epic_stages.py.
Dùng: python3 tools/gen_epic_stages.py [cars|paints|all]
"""
import json, subprocess, sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
STYLE = ROOT / "assets/epic_popup_v1/stage_zenith_concept.png"
OUT = ROOT / "output/imagegen/epic_popup_stage"
PROMPT = ("Two reference images. Image 1 is the STYLE reference: glossy soft-miniature toy look, round checkered blue-and-cream podium, "
          "purple radial glow with light rays and gold sparkles, purple EPIC ribbon with gold laurel leaves at top-left, three-quarter front camera. "
          "Image 2 is the CAR reference, a 3D model from the game. Draw the car from image 2 in the style of image 1 on that podium. "
          "Keep the car's exact design from image 2: same body shape, proportions, hood vents, double white racing stripes, canopy, rear wing, "
          "wheels and headlights, same body colors and trim colors, same three-quarter pose. Do not redesign it into a different car, "
          "do not add extra wings or parts. Keep the ribbon text exactly 'EPIC'. No other text, no logo, no watermark, no border or frame, "
          "the background fills the whole image edge to edge. ")
CARS = {name: ROOT / f"output/imagegen/epic_popup_stage/ref3d_car_{name}_epic.png" for name in ["pico", "nova", "apex", "titan", "zenith"]}
PAINTS = {f"paint_{name}": ROOT / f"output/imagegen/epic_popup_stage/ref3d_epic_{name}.png" for name in ["aurora", "solar", "midnight", "sakura", "neon"]}
NOTES = {
    "paint_aurora": "The paint is an iridescent pearl violet with teal highlights; keep that paint scheme.",
    "paint_midnight": "The paint is glossy near-black with glowing cyan details; keep that paint scheme.",
}


def run(item):
    name, ref = item
    prompt = PROMPT + NOTES.get(name, "")
    r = subprocess.run([sys.executable, str(ROOT / "tools/gen_image.py"), f"raw_{name}", prompt, "--size", "1536x1024",
                        "--quality", "low", "--opaque", "--ref", str(STYLE), "--ref", str(ref), "--out", str(OUT)],
                       capture_output=True, text=True)
    print(name, (r.stdout.strip() or r.stderr.strip())[:160], flush=True)
    return name, {"prompt": prompt, "refs": [str(STYLE.relative_to(ROOT)), str(ref.relative_to(ROOT))]}


if __name__ == "__main__":
    only = sys.argv[1] if len(sys.argv) > 1 else "all"
    jobs = {}
    if only in ("all", "cars"):
        jobs.update(CARS)
    if only in ("all", "paints"):
        jobs.update(PAINTS)
    with ThreadPoolExecutor(5) as pool:
        results = dict(pool.map(run, jobs.items()))
    path = OUT / "prompts.json"
    data = {"model": "gpt-image-2.6-flare", "quality": "low", "jobs": {}}
    if path.exists():
        old = json.loads(path.read_text())
        if "jobs" in old:
            data = old
    data["jobs"].update(results)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=1))
