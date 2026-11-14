"""Extract the approved League artwork into individual Godot textures."""
from pathlib import Path
import hashlib
import html
import json
import shutil
import zipfile

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/league_redesign'
SOURCE = Path(r'C:/Users/thupv/.codex/generated_images/01a1d83f-1e3f-7132-bade-08138a60bd54')
SHEETS = ['exec-9d85fb0b-fe85-4123-876c-6d5480339252.png', 'exec-387fdce4-2b9e-48eb-a6b7-1124198ddfb4.png']
ICONS = ['speed_tune', 'launch_boost', 'overtake_kit', 'corner_grip',
         'stability_tune', 'race_chassis', 'sponsor', 'grandstand',
         'trophy', 'offense', 'defense', 'income',
         'medal_gold', 'medal_silver', 'medal_bronze', 'lock']
PANELS = ['league_header', 'trophy_summary', 'upgrade_card',
          'upgrade_locked', 'tab_active', 'tab_inactive',
          'buy_normal', 'buy_pressed', 'buy_disabled',
          'reward_pill', 'icon_tile', 'info_button']


def extract(im, rect):
    tile = im.crop(rect)
    pixels = np.array(tile)
    # Separate the main sprite from detached generation residue in its gutter.
    labels, count = ndimage.label(pixels[:, :, 3] > 180)
    if not count:
        raise ValueError(f'Empty sprite at {rect}')
    sizes = np.bincount(labels.ravel())
    sizes[0] = 0
    main = labels == sizes.argmax()
    nearby = ndimage.binary_dilation(main, iterations=2)
    pixels[:, :, 3] = np.where(nearby, pixels[:, :, 3], 0)
    tile = Image.fromarray(pixels)
    tile = tile.crop(tile.getbbox())
    padded = Image.new('RGBA', (tile.width + 16, tile.height + 16))
    padded.alpha_composite(tile, (8, 8))
    return padded


def main():
    for folder in ['icons', 'panels', 'styles', 'source']:
        (OUT / folder).mkdir(parents=True, exist_ok=True)
    manifest = {'version': 2, 'finish': 'soft satin, reduced highlights', 'approved_mockup': 'source/approved_mockup.png',
                'sources': [], 'assets': {}, 'upgrade_icons': {k: f'icons/{k}.png' for k in ICONS[:8]}}
    shutil.copy2(SOURCE / 'exec-6929f4db-4bd9-448b-8c5c-6508cd518f28.png', OUT / 'source/approved_mockup.png')
    previews = []
    for source_name, names, cols, folder in [(SHEETS[0], ICONS, 4, 'icons'), (SHEETS[1], PANELS, 3, 'panels')]:
        src = SOURCE / source_name
        shutil.copy2(src, OUT / 'source' / source_name)
        manifest['sources'].append({'path': f'source/{source_name}', 'sha256': hashlib.sha256(src.read_bytes()).hexdigest()})
        im = Image.open(src).convert('RGBA')
        for index, name in enumerate(names):
            col, row = index % cols, index // cols
            rect = (round(col * im.width / cols), round(row * im.height / 4),
                    round((col + 1) * im.width / cols), round((row + 1) * im.height / 4))
            tile = extract(im, rect)
            if folder == 'panels':
                tile = tile.resize((tile.width // 2, tile.height // 2), Image.Resampling.LANCZOS)
                # Keep rounded button ends in the corners of the nine-patch.
                heights = {'buy_normal': 40, 'buy_pressed': 40, 'buy_disabled': 40,
                           'reward_pill': 30, 'tab_active': 44, 'tab_inactive': 44,
                           'icon_tile': 76}
                if name in heights:
                    height = heights[name]
                    tile = tile.resize((round(tile.width * height / tile.height), height), Image.Resampling.LANCZOS)
            relative = f'{folder}/{name}.png'
            tile.save(OUT / relative)
            entry = {'path': relative, 'size': list(tile.size), 'source': f'source/{source_name}', 'source_rect': list(rect)}
            if folder == 'panels':
                margin = min(20 if name == 'icon_tile' else 16, (tile.height - 1) // 2) if name != 'info_button' else 0
                entry['nine_patch_margin'] = margin
                if margin:
                    style = ('[gd_resource type="StyleBoxTexture" load_steps=2 format=3]\n\n'
                             f'[ext_resource type="Texture2D" path="res://assets/league_redesign/{relative}" id="1"]\n\n'
                             '[resource]\ntexture = ExtResource("1")\n')
                    for side in ['left', 'top', 'right', 'bottom']:
                        style += f'texture_margin_{side} = {margin}.0\ncontent_margin_{side} = 12.0\n'
                    (OUT / 'styles' / f'{name}.tres').write_text(style, encoding='utf-8')
            manifest['assets'][name] = entry
            previews.append((name, tile, relative))
    (OUT / 'manifest.json').write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
    width, cell_w, cell_h = 1200, 300, 235
    contact = Image.new('RGB', (width, ((len(previews) + 3) // 4) * cell_h), '#e6eff9')
    draw = ImageDraw.Draw(contact)
    for index, (name, tile, _) in enumerate(previews):
        x, y = (index % 4) * cell_w, (index // 4) * cell_h
        tile = tile.copy()
        tile.thumbnail((270, 185), Image.Resampling.LANCZOS)
        contact.paste(tile, (x + (cell_w - tile.width) // 2, y + 10 + (185 - tile.height) // 2), tile)
        draw.text((x + 15, y + 205), name, fill='#16395a')
    contact.save(OUT / 'preview.png')
    cards = ''.join(f'<figure><img src="{relative}"><figcaption>{html.escape(name)}</figcaption></figure>' for name, _, relative in previews)
    (OUT / 'preview.html').write_text('<!doctype html><meta charset="utf-8"><title>League asset kit</title><style>body{margin:24px;background:#e6eff9;color:#16395a;font:16px system-ui}main{display:grid;grid-template-columns:repeat(auto-fit,minmax(230px,1fr));gap:16px}figure{margin:0;background:#f7fbff;border:1px solid #b4cce6;border-radius:16px;padding:16px;text-align:center}img{width:100%;height:180px;object-fit:contain}figcaption{margin-top:12px}</style><h1>League asset kit · 28 sprites</h1><main>' + cards + '</main>', encoding='utf-8')
    (OUT / 'README.md').write_text('''# League redesign asset kit

Artwork generated from the approved League mockup on 2026-11-14. Version 2 uses the softer finish requested by the user: reduced reflections, glow, bevels and shadows.

- 16 transparent icon PNGs, including all 8 configured trophy upgrades.
- 12 transparent, text-free component PNGs.
- 11 Godot StyleBoxTexture resources with initial nine-patch margins.
- `manifest.json`: sprite dimensions, source rectangles, hashes and upgrade ID mappings.
- `preview.html` / `preview.png`: asset contact sheets.
- `source/`: unmodified generated sheets and approved mockup.

Text, amounts, rank numbers, info symbol, level segments and progress bars must be rendered by Godot. Medal centers are intentionally blank. Keep the existing HUD and bottom navigation assets.

The extraction script removes generation haze and detached residue from transparent gutters, trims and adds an 8 px transparent border. Panels are exported at half sheet resolution for mobile nine-patch borders. Header and summary motifs retain their approved composition. UI integration: `ui/trophy_panel.gd`. Economy data is unchanged.

Rebuild: `python tools/package_league_assets.py` (Pillow, NumPy, SciPy; original generation files must be available at the source path in the script).
''', encoding='utf-8')
    archive = ROOT / 'Design/AssetPacks/League_Redesign_v2_Soft.zip'
    archive.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as z:
        for path in sorted(OUT.rglob('*')):
            if path.is_file() and not path.name.endswith('.import'):
                z.write(path, Path('league_redesign') / path.relative_to(OUT))
    print(json.dumps({'sprites': len(previews), 'manifest': str(OUT / 'manifest.json'), 'archive': str(archive)}, indent=2))


if __name__ == '__main__':
    main()
