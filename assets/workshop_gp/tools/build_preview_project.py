"""Assemble an isolated Godot art preview; no game autoload or player save access."""
import argparse
import shutil
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument("destination", type=Path)
parser.add_argument("--width", type=int, default=390)
parser.add_argument("--height", type=int, default=844)
args = parser.parse_args()
source = Path(__file__).resolve().parents[1]
destination = args.destination.resolve()
if destination == source or source in destination.parents:
    raise SystemExit("Preview destination must be outside the asset pack")
target = destination / "assets" / "workshop_gp"
shutil.copytree(source, target, dirs_exist_ok=True, ignore=shutil.ignore_patterns(".godot", "*.import", "*.uid", "__pycache__"))
(destination / "project.godot").write_text(f'''config_version=5

[application]
config/name="Workshop GP Art Preview"
run/main_scene="res://assets/workshop_gp/preview/asset_gallery.tscn"
config/features=PackedStringArray("4.7", "GL Compatibility")

[display]
window/size/viewport_width={args.width}
window/size/viewport_height={args.height}
window/stretch/mode="canvas_items"

[rendering]
renderer/rendering_method="gl_compatibility"
''', encoding="utf-8")
print(destination)
