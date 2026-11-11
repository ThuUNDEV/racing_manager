"""Package generated artwork unchanged; create Godot resources and inventory.

Pillow is used only to inspect image dimensions/alpha, never to edit artwork.
"""
from pathlib import Path
import hashlib
import json
import shutil
import sys
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
IDS = ['daily_reward', 'season_pass', 'monthly_pass', 'gem',
       'no_ads', 'income_boost_small', 'income_boost_large', 'offline_boost',
       'gear_card', 'driver_card', 'gear_crate', 'driver_helmet',
       'cash_small', 'cash_medium', 'cash_large', 'coins']


def write(path, value):
    target = ROOT / path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(value, encoding='utf-8')


def main():
    for folder in ['textures', 'icons', 'styles', 'ui', 'preview']:
        (ROOT / folder).mkdir(parents=True, exist_ok=True)
    for src, name in zip(sys.argv[1:4], ['shop_icons.png', 'offer_combo.png', 'offer_starter.png']):
        shutil.copy2(src, ROOT / 'textures' / name)
    atlas = Image.open(ROOT / 'textures/shop_icons.png').convert('RGBA')
    width, height = atlas.size
    assert width == height, 'Atlas must be square'
    alpha = atlas.getchannel('A')
    assert alpha.getextrema() == (0, 255), 'Atlas requires actual transparent alpha'
    icons = []
    for i, name in enumerate(IDS):
        col, row = i % 4, i // 4
        x, y = col * width // 4, row * height // 4
        w, h = (col + 1) * width // 4 - x, (row + 1) * height // 4 - y
        bounds = alpha.crop((x, y, x+w, y+h)).getbbox()
        assert bounds, f'Empty icon: {name}'
        write(f'icons/{name}.tres', f'''[gd_resource type="AtlasTexture" load_steps=2 format=3]

[ext_resource type="Texture2D" path="res://assets/workshop_gp/shop/textures/shop_icons.png" id="1"]

[resource]
atlas = ExtResource("1")
region = Rect2({x}, {y}, {w}, {h})
filter_clip = true
''')
        icons.append(dict(id=name, resource=f'icons/{name}.tres', region=[x,y,w,h], alpha_bounds=list(bounds)))
    variants = {
        'card': ('#fffdf8', '#f1e5d5', '#bca992'),
        'pass': ('#fff3d7', '#ffcf85', '#d7ad68'),
        'button_normal': ('#ffa51f', '#ee7100', '#b85300'),
        'button_hover': ('#ffba43', '#ff8611', '#c56100'),
        'button_pressed': ('#e57506', '#bf4d00', '#963900'),
        'button_disabled': ('#dfd8ce', '#c5baad', '#b0a291'),
        'reward': ('#f1fff0', '#c5e4ba', '#83b76b'),
        'currency': ('#ffffff', '#f4ecdf', '#bfaf9d'),
    }
    for name, (top, bottom, border) in variants.items():
        write(f'ui/{name}.svg', f'''<svg xmlns="http://www.w3.org/2000/svg" width="128" height="96" viewBox="0 0 128 96">
<defs><linearGradient id="g" x2="0" y2="1"><stop stop-color="{top}"/><stop offset="1" stop-color="{bottom}"/></linearGradient></defs>
<rect x="2" y="6" width="124" height="88" rx="18" fill="#584530" opacity=".17"/>
<rect x="2" y="2" width="124" height="88" rx="18" fill="url(#g)" stroke="{border}" stroke-width="2"/>
<rect x="5" y="5" width="118" height="82" rx="15" fill="none" stroke="#fff" stroke-opacity=".65"/>
</svg>''')
        write(f'styles/{name}.tres', f'''[gd_resource type="StyleBoxTexture" load_steps=2 format=3]

[ext_resource type="Texture2D" path="res://assets/workshop_gp/shop/ui/{name}.svg" id="1"]

[resource]
texture = ExtResource("1")
texture_margin_left = 24.0
texture_margin_top = 24.0
texture_margin_right = 24.0
texture_margin_bottom = 24.0
content_margin_left = 16.0
content_margin_top = 12.0
content_margin_right = 16.0
content_margin_bottom = 16.0
''')
    manifest = dict(name='Workshop GP Shop', version='1.0', icons=icons,
                    banners=['textures/offer_combo.png', 'textures/offer_starter.png'],
                    styles=[f'styles/{name}.tres' for name in variants], files=[])
    for path in sorted(ROOT.rglob('*')):
        if not path.is_file() or path.suffix in ['.import', '.uid', '.zip'] or path.name == 'manifest.json':
            continue
        info = dict(path=path.relative_to(ROOT).as_posix(), sha256=hashlib.sha256(path.read_bytes()).hexdigest())
        if path.suffix == '.png':
            with Image.open(path) as img:
                info.update(size=list(img.size), mode=img.mode)
        manifest['files'].append(info)
    write('manifest.json', json.dumps(manifest, ensure_ascii=False, indent=2))
    print(json.dumps(dict(atlas_size=[width,height], icons=len(icons), styles=len(variants), files=len(manifest['files'])), indent=2))


if __name__ == '__main__':
    main()
