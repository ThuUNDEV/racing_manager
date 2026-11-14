"""Build the complete catalog art package. Copies PNGs; never edits image pixels."""
from pathlib import Path
import csv
import hashlib
import json
import shutil
import zipfile
from PIL import Image
from package_iap_assets import ROOT, OUT, SOURCE, atlas_text, existing_sprite

SOURCES = {
    'feature_scenes': 'exec-7651d311-5269-4883-be8c-94f3d015e6b8.png',
    'resource_scenes': 'exec-e17d47b0-1066-46d3-823c-2bc6731eff9e.png',
    'recruit_scenes': 'exec-d4af0530-193e-4269-8524-048bc3534d53.png',
    'drivers_pro_elite': 'exec-f6e6fb2b-83d9-4cbf-8878-1576c6ad0709.png',
    'drivers_legend': 'exec-fdc4fc22-3553-47a5-8a8b-e33c2245e231.png',
    'ui_panels': 'exec-24dee5c3-04b0-4000-91ec-bc199a17f3ab.png',
    'ui_buttons': 'exec-a1e9d09d-cc1a-4df8-a6de-bb0acf73680b.png',
}
TITLES = {
    'no_ads': 'Đội tự do', 'income_x2': 'Thu nhập ×2', 'income_x3': 'Thu nhập ×3',
    'income_x3_up': 'Nâng cấp ×2 → ×3', 'offline_plus': 'Offline+',
    'starter_1': 'Gói Tân binh', 'starter_2': 'Gói Khởi động', 'starter_3': 'Gói Chuyên nghiệp',
    'offer_combo_1': 'Combo bứt phá I', 'offer_combo_2': 'Combo bứt phá II',
    'offer_noads_bundle': 'Đội tự do + quà', 'daily_gear': 'Gói trang bị ngày',
    'daily_driver': 'Gói tay đua ngày', 'pass_month': 'Pass tháng', 'pass_growth': 'Quỹ gem',
}


def rel(path):
    return path.relative_to(ROOT).as_posix()


def style_text(texture_path, rect, button=False):
    margins = (70, 28, 70, 28) if button else (65, 65, 65, 65)
    text = ('[gd_resource type="StyleBoxTexture" load_steps=2 format=3]\n\n'
            f'[ext_resource type="Texture2D" path="res://{texture_path}" id="1"]\n\n'
            '[resource]\ntexture = ExtResource("1")\n'
            f'region_rect = Rect2({", ".join(map(str, rect))})\n')
    for side, value in zip(['left', 'top', 'right', 'bottom'], margins):
        text += f'texture_margin_{side} = {value}.0\n'
        text += f'content_margin_{side} = {12.0 if button else 14.0}\n'
    return text


def main():
    for folder in ['sheets', 'resources', 'styles', 'art']:
        (OUT / folder).mkdir(exist_ok=True)
    for key, filename in SOURCES.items():
        target = OUT / 'sheets' / (key + '.png')
        shutil.copy2(SOURCE / filename, target)
        with Image.open(target) as im:
            im.verify()

    textures = {}
    def texture(key, path, rect, purpose):
        resource = OUT / 'resources' / (key + '.tres')
        resource.write_text(atlas_text(path, rect), encoding='utf-8')
        with Image.open(ROOT / path) as im:
            dims = list(im.size)
        textures[key] = {'id': key, 'path': path, 'rect': rect, 'sheet_size': dims,
                         'resource': rel(resource), 'purpose': purpose}
        return textures[key]

    for key in ['hero_starter', 'hero_driver_my', 'hero_income_x2']:
        path = f'assets/iap_offers/illustrations/{key}.png'
        assert (ROOT / path).is_file(), 'Run package_iap_assets.py to restore v1 originals first'
        texture(key, path, [0, 0, 1536, 1024], 'hero')
    scenes = {
        'feature_scenes': ['hero_noads', 'hero_offline', 'hero_month', 'hero_growth'],
        'resource_scenes': ['hero_combo', 'hero_weekly', 'hero_gems', 'hero_daily_gear'],
        'recruit_scenes': ['background_pro', 'background_elite', 'background_legend', 'hero_daily_driver'],
    }
    for sheet, keys in scenes.items():
        for i, key in enumerate(keys):
            texture(key, f'assets/iap_offers/sheets/{sheet}.png',
                    [(i % 2) * 768, (i // 2) * 512, 768, 512], 'hero')

    character_cells = [
        ('characters', [('linh_present', 0, 512), ('my_welcome', 512, 990), ('linh_victory', 990, 1536)]),
        ('drivers_pro_elite', [('ha_welcome', 0, 512), ('lam_welcome', 512, 1024), ('nhan_welcome', 1024, 1536)]),
        ('drivers_legend', [('phuong_welcome', 0, 490), ('quang_welcome', 490, 1040), ('son_welcome', 1040, 1536)]),
    ]
    for sheet, cells in character_cells:
        path = f'assets/iap_offers/sheets/{sheet}.png'
        with Image.open(ROOT / path) as im:
            assert im.mode == 'RGBA'
            alpha = im.getchannel('A')
            assert alpha.getextrema()[0] == 0
            for _, left, right in cells:
                if left:
                    assert alpha.crop((left, 0, left + 1, 1024)).getextrema()[1] <= 1, (sheet, left)
            for key, left, right in cells:
                cell = alpha.crop((left, 0, right, 1024))
                # Read alpha only to bound the silhouette. Source PNG bytes remain unchanged.
                bounds = cell.point(lambda v: 255 if v >= 200 else 0).getbbox()
                assert bounds
                x0, y0, x1, y1 = bounds
                x0, y0 = max(0, x0 - 8), max(0, y0 - 8)
                x1, y1 = min(right - left, x1 + 8), min(1024, y1 + 8)
                texture(key, path, [left + x0, y0, x1 - x0, y1 - y0], 'character')

    styles = {}
    for sheet, cols, names in [
        ('ui_panels', 2, ['panel_blue', 'panel_purple', 'panel_gold', 'panel_teal']),
        ('ui_buttons', 3, ['buy_normal', 'buy_hover', 'buy_pressed', 'buy_disabled', 'button_blue', 'button_amber'])]:
        path = f'assets/iap_offers/sheets/{sheet}.png'
        with Image.open(ROOT / path) as im:
            assert im.mode == 'RGBA' and im.getchannel('A').getextrema()[0] == 0
            for i, key in enumerate(names):
                cx, cy = (i % cols) * (1536 // cols), (i // cols) * 512
                alpha = im.getchannel('A').crop((cx, cy, cx + 1536 // cols, cy + 512))
                box = alpha.point(lambda v: 255 if v >= 200 else 0).getbbox()
                x0, y0, x1, y1 = box
                rect = [cx + x0 - 2, cy + y0 - 2, x1 - x0 + 4, y1 - y0 + 4]
                t = texture(key, path, rect, 'button' if cols == 3 else 'panel')
                target = OUT / 'styles' / (key + '.tres')
                target.write_text(style_text(path, rect, cols == 3), encoding='utf-8')
                styles[key] = {'texture': key, 'resource': rel(target),
                               'slice': [70, 28, 70, 28] if cols == 3 else [65, 65, 65, 65]}

    shared = {key: f'assets/racing_ui_hd/icons/{key}.png' for key in ['gem', 'cash', 'crown', 'research', 'energy', 'trophy']}
    shared['close_button'] = 'assets/racing_ui_hd/icons/close_red.svg'
    shared['racetrack_background'] = 'assets/racing_ui_hd/backgrounds/racetrack_background.png'
    all_drivers = json.loads((ROOT / 'data/drivers.json').read_text(encoding='utf-8-sig'))['drivers']
    drivers = {d['id']: d for d in all_drivers}
    packs = {key: existing_sprite(key) for key in [
        'standard_driver_pack', 'elite_driver_pack', 'standard_gear_pack', 'elite_gear_pack',
        'driver_ha', 'driver_lam', 'driver_my', 'driver_nhan', 'driver_phuong', 'driver_quang', 'driver_son']}
    catalog = json.loads((ROOT / 'data/iap.json').read_text(encoding='utf-8-sig'))
    recipes = {}
    for p in catalog['products']:
        sku, kind, grant = p['sku'], p['kind'], p['grant']
        foreground = None
        panel = 'panel_blue'
        if kind == 'gems':
            hero = 'hero_gems'; panel = 'panel_gold'
        elif kind == 'weekly':
            hero = 'hero_weekly'; panel = 'panel_teal'
        elif sku in ['income_x2', 'income_x3', 'income_x3_up']:
            hero = 'hero_income_x2'; panel = 'panel_gold'
        elif sku in ['no_ads', 'offer_noads_bundle']:
            hero = 'hero_noads'
        elif sku == 'offline_plus':
            hero = 'hero_offline'
        elif sku == 'starter_1':
            hero = 'hero_starter'
        elif sku == 'starter_2':
            hero, foreground = 'background_pro', 'ha_welcome'
        elif sku in ['starter_3', 'char_my']:
            hero = 'hero_driver_my'; panel = 'panel_purple'
        elif kind == 'character':
            name = grant['driver'].removeprefix('driver_')
            elite = drivers[grant['driver']]['tier'] == 2
            hero = 'background_elite' if elite else 'background_legend'
            foreground = name + '_welcome'
            panel = 'panel_purple' if elite else 'panel_gold'
        elif sku.startswith('offer_combo'):
            hero = 'hero_combo'; panel = 'panel_purple'
        elif sku == 'daily_driver':
            hero = 'hero_daily_driver'; panel = 'panel_purple'
        elif sku == 'daily_gear':
            hero = 'hero_daily_gear'; panel = 'panel_purple'
        elif sku == 'pass_month':
            hero = 'hero_month'
        elif sku == 'pass_growth':
            hero = 'hero_growth'; panel = 'panel_gold'
        else:
            raise AssertionError('Unmapped SKU: ' + sku)
        assert hero in textures and (foreground is None or foreground in textures)
        title = TITLES.get(sku)
        if kind == 'character':
            title = 'Chiêu mộ ' + drivers[grant['driver']]['name']
        elif kind == 'weekly':
            title = 'Gói tuần ' + sku.split('_')[-1].upper()
        elif kind == 'gems':
            title = format(grant['gems'], ',').replace(',', '.') + ' gem'
        recipe = {'sku': sku, 'title': title, 'kind': kind, 'hero': hero, 'foreground': foreground,
                  'panel': panel, 'scene': f'assets/iap_offers/art/{sku}.tscn',
                  'size': [366, 244], 'enabled_by_default': not p.get('flag') or catalog['flags'][p['flag']],
                  'ui_labels_not_baked': True}
        if sku.startswith('income_x'):
            recipe['multiplier_label'] = '×2' if sku == 'income_x2' else '×3'
        recipes[sku] = recipe
        background_resource = textures[hero]['resource']
        scene = ('[gd_scene load_steps=' + ('3' if foreground else '2') + ' format=3]\n\n'
                 f'[ext_resource type="Texture2D" path="res://{background_resource}" id="1"]\n')
        if foreground:
            scene += f'[ext_resource type="Texture2D" path="res://{textures[foreground]["resource"]}" id="2"]\n'
        scene += ('\n[node name="OfferArt" type="Control"]\nlayout_mode = 3\n'
                  'anchors_preset = 0\noffset_right = 366.0\noffset_bottom = 244.0\n'
                  'custom_minimum_size = Vector2(0, 0)\nmouse_filter = 2\n'
                  '\n[node name="Background" type="TextureRect" parent="."]\nlayout_mode = 1\n'
                  'anchors_preset = 15\nanchor_right = 1.0\nanchor_bottom = 1.0\n'
                  'grow_horizontal = 2\ngrow_vertical = 2\nmouse_filter = 2\n'
                  'texture = ExtResource("1")\nexpand_mode = 1\nstretch_mode = 5\n')
        if foreground:
            scene += ('\n[node name="Character" type="TextureRect" parent="."]\nlayout_mode = 1\n'
                      'anchor_right = 0.46\nanchor_bottom = 1.0\noffset_left = 6.0\n'
                      'offset_top = 4.0\noffset_bottom = -1.0\nmouse_filter = 2\n'
                      'texture = ExtResource("2")\nexpand_mode = 1\nstretch_mode = 5\n')
        (ROOT / recipe['scene']).write_text(scene, encoding='utf-8')

    assert set(recipes) == {p['sku'] for p in catalog['products']}
    images = []
    for path in sorted(OUT.rglob('*.png')):
        with Image.open(path) as im:
            images.append({'path': rel(path), 'size': list(im.size), 'mode': im.mode,
                           'alpha_extrema': list(im.getchannel('A').getextrema()) if im.mode == 'RGBA' else None,
                           'sha256': hashlib.sha256(path.read_bytes()).hexdigest()})
    manifest = {'name': 'Racing IAP Complete Art Kit', 'version': 2, 'date': '2026-11-13',
                'scope': list(recipes), 'catalog_sha256': hashlib.sha256((ROOT / 'data/iap.json').read_bytes()).hexdigest(),
                'status': 'Art for all catalog SKUs; Shop integration separate',
                'images': images, 'textures': textures, 'styles': styles, 'recipes': recipes,
                'shared_existing_assets': shared, 'packs': packs,
                'sources': {k: str(SOURCE / v) for k, v in SOURCES.items()},
                'backdrop_color': '#081b34b3',
                'button_states': {'normal': 'buy_normal', 'hover': 'buy_hover', 'pressed': 'buy_pressed',
                                  'disabled': 'buy_disabled', 'busy': 'buy_normal + dynamic spinner/label'},
                'usage': {'draw_size': [366, 244], 'hero_text_baked': False,
                          'atlas_cells_trimmed_without_editing_pixels': True,
                          'weekly_xl_kept_disabled': True}}
    (OUT / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    with (OUT / 'coverage.csv').open('w', encoding='utf-8-sig', newline='') as f:
        fields = ['sku', 'title', 'hero', 'foreground', 'panel', 'scene', 'enabled_by_default']
        writer = csv.DictWriter(f, fieldnames=fields, extrasaction='ignore')
        writer.writeheader(); writer.writerows(recipes.values())
    preview_data = dict(manifest, products={p['sku']: p for p in catalog['products']}, drivers=drivers,
                        driver_packs=json.loads((ROOT / 'data/driver_gacha.json').read_text(encoding='utf-8-sig'))['packs'],
                        gear_packs=json.loads((ROOT / 'data/gear.json').read_text(encoding='utf-8-sig'))['packs'])
    template = (OUT / 'catalog.template.html').read_text(encoding='utf-8')
    (OUT / 'preview.html').write_text(template.replace('/*ASSET_DATA*/',
        'const DATA = ' + json.dumps(preview_data, ensure_ascii=False) + ';'), encoding='utf-8')
    included = {p for p in OUT.rglob('*') if p.is_file() and not p.name.endswith(('.import', '.uid'))}
    included.update(ROOT / p for p in shared.values())
    for pack in packs.values():
        included.update([ROOT / pack['resource'], ROOT / pack['path']])
    dest = ROOT / 'Design/AssetPacks/Racing_IAP_Complete_v2.zip'
    with zipfile.ZipFile(dest, 'w', zipfile.ZIP_DEFLATED) as z:
        for path in sorted(included):
            assert path.is_file(), path
            z.write(path, rel(path))
    print(f'{len(images)} PNGs; {len(textures)} atlas textures; {len(styles)} 9-slice styles; {len(recipes)}/30 SKU scenes; ZIP {dest.stat().st_size:,} bytes')


if __name__ == '__main__':
    main()
