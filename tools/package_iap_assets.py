"""Package generated IAP artwork without modifying source image pixels."""
from pathlib import Path
import hashlib
import json
import re
import shutil
import zipfile
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = Path(r'C:/Users/thupv/.codex/generated_images/01a1d2b3-6866-7051-bc0c-e64a9230e50b')
OUT = ROOT / 'assets/iap_offers'
FILES = {
    'hero_starter': 'exec-c00df1da-e4df-4651-9a53-ba7286e00a15.png',
    'hero_driver_my': 'exec-2b828ad9-5275-4550-a346-76868ab91f62.png',
    'hero_income_x2': 'exec-36df495b-0ff1-4736-af67-39c164dffac2.png',
    'characters': 'exec-08e6be84-cc3d-4836-82e3-7f82f7a475d2.png',
}


def atlas_text(path, rect):
    return ('[gd_resource type="AtlasTexture" load_steps=2 format=3]\n\n'
            f'[ext_resource type="Texture2D" path="res://{path}" id="1"]\n\n'
            '[resource]\natlas = ExtResource("1")\n'
            f'region = Rect2({", ".join(map(str, rect))})\nfilter_clip = true\n')


def existing_sprite(name):
    rel = f'assets/racing_ui_hd_expansion/sprites/{name}.tres'
    data = (ROOT / rel).read_text(encoding='utf-8')
    sheet = re.search(r'path="res://([^"]+)"', data)[1]
    rect = [float(v) for v in re.search(r'Rect2\(([^)]+)\)', data)[1].split(',')]
    with Image.open(ROOT / sheet) as im:
        dims = list(im.size)
    return {'resource': rel, 'path': sheet, 'rect': rect, 'size': dims}


def main():
    (OUT / 'illustrations').mkdir(parents=True, exist_ok=True)
    (OUT / 'sheets').mkdir(exist_ok=True)
    (OUT / 'resources').mkdir(exist_ok=True)
    images = []
    for key, src in FILES.items():
        folder = 'sheets' if key == 'characters' else 'illustrations'
        dest = OUT / folder / (key + '.png')
        shutil.copy2(SOURCE / src, dest)
        with Image.open(dest) as im:
            im.verify()
        with Image.open(dest) as im:
            record = {'id': key, 'path': dest.relative_to(ROOT).as_posix(),
                      'size': list(im.size), 'mode': im.mode,
                      'source': str(SOURCE / src),
                      'sha256': hashlib.sha256(dest.read_bytes()).hexdigest()}
            if im.mode == 'RGBA':
                alpha = im.getchannel('A')
                record['alpha_extrema'] = list(alpha.getextrema())
                assert alpha.getextrema()[0] == 0
                # The generated poses have unequal widths; use verified empty gutters.
                for x in (511, 512, 989, 990):
                    assert alpha.crop((x, 0, x + 1, im.height)).getextrema() == (0, 0), x
            else:
                rect = [0, 0, im.width, im.height]
                (OUT / 'resources' / (key + '.tres')).write_text(
                    atlas_text(record['path'], rect), encoding='utf-8')
                record['resource'] = f'assets/iap_offers/resources/{key}.tres'
        images.append(record)

    poses = []
    for key, rect in [('linh_present', [0, 0, 512, 1024]),
                      ('my_welcome', [512, 0, 478, 1024]),
                      ('linh_victory', [990, 0, 546, 1024])]:
        rel = f'assets/iap_offers/resources/{key}.tres'
        (ROOT / rel).write_text(atlas_text('assets/iap_offers/sheets/characters.png', rect), encoding='utf-8')
        poses.append({'id': key, 'resource': rel, 'rect': rect})

    shared = {key: f'assets/racing_ui_hd/icons/{key}.png' for key in ['gem', 'cash', 'crown']}
    shared.update({'panel': 'assets/racing_ui_hd/surfaces/panel_body.png',
                   'buy_button': 'assets/racing_ui_hd/surfaces/button_claim.png',
                   'close_button': 'assets/racing_ui_hd/icons/close_red.svg'})
    packs = {key: existing_sprite(key) for key in [
        'standard_driver_pack', 'elite_driver_pack', 'standard_gear_pack', 'elite_gear_pack', 'driver_my']}
    manifest = {'name': 'Racing IAP Illustrated Assets', 'version': 1,
                'date': '2026-11-13', 'scope': ['starter_1', 'char_my', 'income_x2'],
                'status': 'Packaged artwork and Godot resources; gameplay UI not integrated',
                'concept': 'Design/Previews/iap_packs_v4_asset_reference_concept.png',
                'images': images, 'poses': poses, 'shared_existing_assets': shared,
                'packs': packs,
                'sku_art': {'starter_1': 'hero_starter', 'char_my': 'hero_driver_my',
                            'income_x2': 'hero_income_x2'},
                'usage': {'hero_aspect': '3:2', 'recommended_hero_size': [366, 244],
                          'illustrations_have_baked_text': False,
                          'keep_source_pixels': True,
                          'character_sheet_has_real_alpha': True,
                          'character_sheet_note': 'Retains generated semi-transparent edge shading; use documented atlas regions.'}}
    (OUT / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    catalog = json.loads((ROOT / 'data/iap.json').read_text(encoding='utf-8-sig'))
    manifest['products'] = {p['sku']: p for p in catalog['products'] if p['sku'] in manifest['scope']}
    template = (OUT / 'preview.template.html').read_text(encoding='utf-8')
    (OUT / 'preview.html').write_text(template.replace('/*ASSET_DATA*/',
        'const DATA = ' + json.dumps(manifest, ensure_ascii=False) + ';'), encoding='utf-8')

    # Include shared art dependencies at their original res:// paths.
    included = {p for p in OUT.rglob('*') if p.is_file() and not p.name.endswith('.import')}
    included.update(ROOT / p for p in shared.values())
    for p in packs.values():
        included.update([ROOT / p['resource'], ROOT / p['path']])
    dest = ROOT / 'Design/AssetPacks/Racing_IAP_Illustrated_v1.zip'
    dest.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(dest, 'w', zipfile.ZIP_DEFLATED) as z:
        for path in sorted(included):
            assert path.is_file(), path
            z.write(path, path.relative_to(ROOT).as_posix())
    print(f'Packaged {len(images)} PNGs, {3 + len(poses)} AtlasTexture resources; {dest.stat().st_size:,} byte ZIP')


if __name__ == '__main__':
    main()
