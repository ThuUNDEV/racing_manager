"""Build Workshop GP Godot resources; PNG sources are copied without modification.

Pillow is used only to inspect dimensions/alpha and locate AtlasTexture regions.
Run: python assets/workshop_gp/tools/build_pack.py [--source-dir IMAGEGEN_OUTPUT_DIR]
"""
from __future__ import annotations

import argparse
import hashlib
import json
import shutil
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
RES = "res://assets/workshop_gp"
SOURCES = {
    "textures/workshop_oval.png": "exec-36733453-bd9d-4442-be25-04c3c23e0e3e.png",
    "atlases/cars.png": "exec-d028f13c-68a6-4686-87c4-107e00fbcef9.png",
    "atlases/ui_icons.png": "exec-cf794c39-e4d9-4895-b750-8c6f21241da9.png",
    "portraits/driver_orange.png": "exec-57abaf36-b2cb-4bfb-9796-29a0a546de61.png",
}
COLORS = ["orange", "graphite", "white", "blue", "red", "yellow", "teal", "purple"]
ICONS = ["coins", "gem", "pace", "overtaking", "defense", "car_control", "team", "gear", "driver", "league", "events", "shop"]


def write(relative: str, content: str) -> None:
    dest = ROOT / relative
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(content, encoding="utf-8")


def atlas_resource(relative: str, atlas: str, region: tuple[int, int, int, int]) -> None:
    x, y, w, h = region
    write(relative, f'''[gd_resource type="AtlasTexture" load_steps=2 format=3]

[ext_resource type="Texture2D" path="{RES}/{atlas}" id="1"]

[resource]
atlas = ExtResource("1")
region = Rect2({x}, {y}, {w}, {h})
filter_clip = true
''')


def alpha_bounds(image: Image.Image, box: tuple[int, int, int, int], padding: int = 6) -> tuple[int, int, int, int]:
    # Read alpha only. Do not crop or re-encode any output image.
    alpha = image.getchannel("A")
    x0, y0, x1, y1 = box
    pixels = alpha.load()
    xs, ys = [], []
    for y in range(y0, y1):
        for x in range(x0, x1):
            if pixels[x, y] > 24:
                xs.append(x)
                ys.append(y)
    if not xs:
        raise ValueError(f"Empty atlas cell: {box}")
    left, top = max(x0, min(xs) - padding), max(y0, min(ys) - padding)
    right, bottom = min(x1, max(xs) + padding + 1), min(y1, max(ys) + padding + 1)
    return left, top, right - left, bottom - top


def svg_panel(name: str, top: str, bottom: str, border: str, radius: int = 24, w: int = 512, h: int = 192) -> None:
    # Fresh vector UI source; labels/prices are deliberately not baked into art.
    write(f"ui/{name}.svg", f'''<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">
<defs><linearGradient id="fill" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{top}"/><stop offset="1" stop-color="{bottom}"/></linearGradient></defs>
<rect x="4" y="7" width="{w-8}" height="{h-11}" rx="{radius}" fill="#342919" opacity="0.15"/>
<rect x="3" y="3" width="{w-6}" height="{h-12}" rx="{radius}" fill="url(#fill)" stroke="{border}" stroke-width="2"/>
<rect x="6" y="5" width="{w-12}" height="{h-17}" rx="{max(2,radius-2)}" fill="none" stroke="#ffffff" stroke-opacity="0.48" stroke-width="2"/>
</svg>
''')


def style(name: str, texture: str, margin: int, content: tuple[int, int, int, int] = (12, 10, 12, 10)) -> None:
    left, top, right, bottom = content
    write(f"styles/{name}.tres", f'''[gd_resource type="StyleBoxTexture" load_steps=2 format=3]

[ext_resource type="Texture2D" path="{RES}/ui/{texture}.svg" id="1"]

[resource]
texture = ExtResource("1")
texture_margin_left = {margin}.0
texture_margin_top = {margin}.0
texture_margin_right = {margin}.0
texture_margin_bottom = {margin}.0
content_margin_left = {left}.0
content_margin_top = {top}.0
content_margin_right = {right}.0
content_margin_bottom = {bottom}.0
''')


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source-dir", type=Path)
    args = parser.parse_args()
    if args.source_dir:
        for relative, original in SOURCES.items():
            dest = ROOT / relative
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(args.source_dir / original, dest)
    for relative in SOURCES:
        if not (ROOT / relative).exists():
            raise FileNotFoundError(f"Missing {relative}; supply --source-dir on first build")

    metadata: dict = {"name": "Workshop GP", "version": "0.1", "asset_type": "2D raster sprites + vector UI", "coordinate_origin": "top-left", "source_images_edited": False, "png_sources": [], "cars": [], "icons": []}
    for relative in SOURCES:
        path = ROOT / relative
        with Image.open(path) as image:
            entry = {"path": relative, "width": image.width, "height": image.height, "mode": image.mode, "sha256": hashlib.sha256(path.read_bytes()).hexdigest()}
            if "A" in image.getbands():
                hist = image.getchannel("A").histogram()
                entry["fully_transparent_pixels"] = hist[0]
                assert hist[0] > 0, relative
            metadata["png_sources"].append(entry)

    with Image.open(ROOT / "atlases/cars.png") as image:
        assert image.mode == "RGBA"
        for i, name in enumerate(COLORS):
            col, row = i % 4, i // 4
            box = (col * image.width // 4, row * image.height // 2, (col + 1) * image.width // 4, (row + 1) * image.height // 2)
            region = alpha_bounds(image, box, padding=8)
            target = f"cars/{name}.tres"
            atlas_resource(target, "atlases/cars.png", region)
            metadata["cars"].append({"id": name, "resource": target, "region": list(region), "forward": "+Y", "recommended_draw_size": [11, 21]})

    with Image.open(ROOT / "atlases/ui_icons.png") as image:
        assert image.mode == "RGBA"
        # ImageGen arranged the rows in these measured bands, not exact thirds.
        row_bands = [(int(a * image.height / 1280), int(b * image.height / 1280)) for a, b in [(110, 465), (475, 815), (825, 1155)]]
        for i, name in enumerate(ICONS):
            col, row = i % 4, i // 4
            y0, y1 = row_bands[row]
            region = alpha_bounds(image, (col * image.width // 4, y0, (col + 1) * image.width // 4, y1))
            target = f"icons/{name}.tres"
            atlas_resource(target, "atlases/ui_icons.png", region)
            metadata["icons"].append({"id": name, "resource": target, "region": list(region), "recommended_ui_size": [24, 32, 48]})

    svg_panel("card_cream", "#fffdf8", "#e9e0d5", "#c9bdb0", 14)
    svg_panel("button_orange", "#ff981b", "#ed5c04", "#b64609", 10, 512, 112)
    svg_panel("button_orange_hover", "#ffac3b", "#ff710b", "#c5540a", 10, 512, 112)
    svg_panel("button_orange_pressed", "#da5300", "#f17a05", "#a54006", 10, 512, 112)
    svg_panel("button_disabled", "#e0d8ce", "#c9c0b6", "#b4a99b", 10, 512, 112)
    svg_panel("panel_graphite", "#343d4b", "#18222f", "#58616c", 16)
    svg_panel("capsule_ivory", "#fffefa", "#eee6da", "#c2b6a6", 14, 384, 96)
    svg_panel("stat_chip", "#eee7dd", "#e4dcd0", "#ddd2c5", 8, 384, 88)
    svg_panel("nav_selected", "#ff9a25", "#d75e0b", "#a84a0a", 12, 128, 128)
    write("ui/app_background.svg", '''<svg xmlns="http://www.w3.org/2000/svg" width="390" height="844" viewBox="0 0 390 844">
<defs><linearGradient id="bg" x2="0" y2="1"><stop stop-color="#f6f0e7"/><stop offset="1" stop-color="#e7dfd4"/></linearGradient></defs>
<path fill="url(#bg)" d="M0 0H390V844H0Z"/>
<g fill="#ffffff" opacity=".23"><path d="M0 0H56L0 56Z"/><path d="M0 84L84 0H114L0 114Z"/><path d="M294 0H332L390 58V96Z"/></g>
<g fill="#f47510" opacity=".32"><path d="M0 52L52 0H56L0 56Z"/><path d="M340 0H344L390 46V50Z"/></g>
</svg>
''')

    for name, tex, border, content in [
        ("card", "card_cream", 16, (8, 8, 8, 9)),
        ("button", "button_orange", 12, (10, 5, 10, 7)),
        ("button_hover", "button_orange_hover", 12, (10, 5, 10, 7)),
        ("button_pressed", "button_orange_pressed", 12, (10, 7, 10, 5)),
        ("button_disabled", "button_disabled", 12, (10, 5, 10, 7)),
        ("graphite", "panel_graphite", 20, (6, 6, 6, 8)),
        ("avatar", "panel_graphite", 20, (2, 2, 2, 3)),
        ("capsule", "capsule_ivory", 16, (8, 4, 8, 7)),
        ("stat", "stat_chip", 10, (6, 2, 6, 4)),
        ("nav_selected", "nav_selected", 14, (4, 5, 4, 7)),
    ]:
        style(name, tex, border, content)

    atlas_resource("portraits/driver_avatar.tres", "portraits/driver_orange.png", (300, 0, 660, 820))
    write("theme.tres", f'''[gd_resource type="Theme" load_steps=8 format=3]

[ext_resource type="StyleBox" path="{RES}/styles/card.tres" id="1"]
[ext_resource type="StyleBox" path="{RES}/styles/button.tres" id="2"]
[ext_resource type="StyleBox" path="{RES}/styles/button_hover.tres" id="3"]
[ext_resource type="StyleBox" path="{RES}/styles/button_pressed.tres" id="4"]
[ext_resource type="StyleBox" path="{RES}/styles/button_disabled.tres" id="5"]
[ext_resource type="StyleBox" path="{RES}/styles/capsule.tres" id="6"]
[sub_resource type="StyleBoxFlat" id="focus"]
bg_color = Color(0, 0, 0, 0)
border_width_left = 2
border_width_top = 2
border_width_right = 2
border_width_bottom = 2
border_color = Color(1, 0.48, 0.04, 1)
corner_radius_top_left = 8
corner_radius_top_right = 8
corner_radius_bottom_left = 8
corner_radius_bottom_right = 8

[resource]
default_font_size = 14
Label/colors/font_color = Color(0.11, 0.14, 0.18, 1)
Button/colors/font_color = Color(1, 1, 1, 1)
Button/colors/font_hover_color = Color(1, 1, 1, 1)
Button/colors/font_pressed_color = Color(1, 1, 1, 1)
Button/colors/font_disabled_color = Color(0.44, 0.41, 0.37, 1)
Button/font_sizes/font_size = 13
Button/styles/normal = ExtResource("2")
Button/styles/hover = ExtResource("3")
Button/styles/pressed = ExtResource("4")
Button/styles/disabled = ExtResource("5")
Button/styles/focus = SubResource("focus")
PanelContainer/styles/panel = ExtResource("1")
LineEdit/styles/normal = ExtResource("6")
''')
    write("layout/workshop_oval_path.json", json.dumps({
        "description": "Measured approximate centerline of the generated road; coordinates normalized to texture bounds.",
        "texture": "textures/workshop_oval.png", "texture_size": [1536, 1024],
        "loop_direction": "counterclockwise in screen coordinates starting bottom-left, moving right",
        "car_forward": "+Y",
        "stadium": {"left_center_x": 0.263, "right_center_x": 0.737, "center_y": 0.5, "radius_x": 0.193, "radius_y": 0.275},
        "warning": "Visual guide only. Match render path to gameplay distance/sector mapping before integrating with RaceSim."
    }, indent=2) + "\n")
    metadata["palette"] = {"ivory": "#F6F0E7", "panel": "#FFFDF8", "orange": "#F47510", "graphite": "#202B38", "muted": "#776D61", "green": "#318A30"}
    write("manifest.json", json.dumps(metadata, indent=2) + "\n")
    print(f"Built: {len(COLORS)} car resources, {len(ICONS)} icon resources, 10 vector UI textures, 10 StyleBoxes, 1 Theme, 1 avatar region.")


if __name__ == "__main__":
    main()
