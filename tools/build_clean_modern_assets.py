"""Inventory and package ImageGen art. Never modifies source image pixels.

PNG files are copied byte-for-byte. Atlas regions are Godot metadata, not crops.
Original source image pixels remain untouched. Runtime routing is integrated separately.
"""
from pathlib import Path
import argparse
import csv
import html
import hashlib
import json
import re
import shutil
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets' / 'clean_modern'
EXT = {'.png', '.svg', '.jpg', '.jpeg', '.webp'}


def relative(path):
    return path.relative_to(ROOT).as_posix()


def dimensions(path):
    if path.suffix == '.svg':
        text = path.read_text(encoding='utf-8')
        match = re.search(r'viewBox="[\d. -]+? ([\d.]+) ([\d.]+)"', text)
        if match:
            return [float(x) for x in match.groups()]
        return [float(re.search(fr'{key}="([\d.]+)', text)[1]) for key in ('width', 'height')]
    with Image.open(path) as image:
        return list(image.size)


def inventory():
    OUT.mkdir(parents=True, exist_ok=True)
    files = sorted(p for p in (ROOT / 'assets').rglob('*')
                   if p.is_file() and p.suffix.lower() in EXT and OUT not in p.parents)
    entries = [{'source': relative(p), 'size': dimensions(p),
                'sha256': hashlib.sha256(p.read_bytes()).hexdigest()} for p in files]
    (OUT / 'source_inventory.json').write_text(json.dumps(entries, indent=2), encoding='utf-8')
    print(json.dumps({'source_images': len(entries), 'groups': {
        folder: sum(e['source'].split('/')[1] == folder for e in entries)
        for folder in sorted({e['source'].split('/')[1] for e in entries})}}))


def atlas_text(sheet, rect):
    return ('[gd_resource type="AtlasTexture" load_steps=2 format=3]\n\n'
            f'[ext_resource type="Texture2D" path="res://{sheet}" id="1"]\n\n'
            '[resource]\natlas = ExtResource("1")\n'
            f'region = Rect2({", ".join(str(round(v, 3)) for v in rect)})\n'
            'filter_clip = true\n')


def package():
    plan = json.loads((OUT / 'generation_plan.json').read_text(encoding='utf-8'))
    receipts = {row['id']: row['file'] for row in json.loads((OUT / 'generation_receipts.json').read_text(encoding='utf-8'))}
    for receipt_file in sorted((OUT / 'receipts').glob('*.json')):
        row = json.loads(receipt_file.read_text(encoding='utf-8'))
        receipts[row['id']] = row['file']
    inventory_data = json.loads((OUT / 'source_inventory.json').read_text(encoding='utf-8'))
    inputs = {e['source']: e for e in inventory_data}
    overrides_path = OUT / "region_overrides.json"
    overrides = json.loads(overrides_path.read_text(encoding="utf-8")) if overrides_path.exists() else {}
    covered = {}
    art = []
    for job in plan:
        generated_file = job.get('generated_file') or receipts.get(job['id'])
        if not generated_file:
            continue
        generated = Path(generated_file)
        target = OUT / 'sheets' / (job['id'] + '.png')
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(generated, target)
        with Image.open(target) as image:
            width, height = image.size
            mode = image.mode
            alpha = image.getchannel('A').getextrema() if 'A' in image.getbands() else None
        with Image.open(target) as image:
            image.verify()
        art.append({'id': job['id'], 'path': relative(target), 'size': [width, height],
                    'sha256': hashlib.sha256(target.read_bytes()).hexdigest(),
                    'mode': mode, 'alpha_extrema': alpha, 'source_generation': str(generated)})
        for item in job['items']:
            source = item['source']
            norm = item.get('rect', [0, 0, 1, 1])
            rect = [norm[0] * width, norm[1] * height, norm[2] * width, norm[3] * height]
            if job.get('grid') and alpha:
                with Image.open(target) as image:
                    x0, y0 = int(rect[0]), int(rect[1])
                    x1, y1 = min(width, int(rect[0] + rect[2])), min(height, int(rect[1] + rect[3]))
                    channel = image.getchannel('A').crop((x0, y0, x1, y1))
                    bounds = channel.point(lambda value: 255 if value >= 200 else 0).getbbox()
                    if bounds:
                        left, top = max(x0, x0 + bounds[0] - 2), max(y0, y0 + bounds[1] - 2)
                        right, bottom = min(x1, x0 + bounds[2] + 2), min(y1, y0 + bounds[3] + 2)
                        rect = [left, top, right - left, bottom - top]
            override = overrides.get(source, {})
            rect = override.get('region', rect)
            sheet = override.get('sheet', relative(target))
            resource = OUT / 'replacements' / (source.removeprefix('assets/') + '.tres')
            resource.parent.mkdir(parents=True, exist_ok=True)
            resource.write_text(atlas_text(sheet, rect), encoding='utf-8')
            entry = {'source': source, 'replacement': relative(resource), 'sheet': sheet,
                     'region': rect, 'original_size': inputs[source]['size'], 'job': override.get('job', job['id'])}
            if source in covered:
                raise ValueError('Duplicate source: ' + source)
            covered[source] = entry
    missing = sorted(set(inputs) - set(covered))
    # Rebuild legacy AtlasTexture regions against the newly generated sheets.
    sprites = []
    for resource in sorted((ROOT / 'assets').rglob('*.tres')):
        if OUT in resource.parents:
            continue
        text = resource.read_text(encoding='utf-8')
        if 'type="AtlasTexture"' not in text:
            continue
        match = re.search(r'path="res://([^"]+)"', text)
        region = re.search(r'^region = Rect2\(([^)]+)\)', text, re.M)
        if not match or not region or match[1] not in covered:
            continue
        base = covered[match[1]]
        old = [float(v.strip()) for v in region[1].split(',')]
        x, y, w, h = base['region']
        ow, oh = base['original_size']
        rect = [x + old[0] / ow * w, y + old[1] / oh * h, old[2] / ow * w, old[3] / oh * h]
        dest = OUT / 'resources' / relative(resource).removeprefix('assets/')
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(atlas_text(base['sheet'], rect), encoding='utf-8')
        sprites.append({'source': relative(resource), 'replacement': relative(dest),
                        'sheet': base['sheet'], 'region': rect})
    manifest = {'name': 'Racing Manager — F Clean Modern', 'version': 1,
                'status': 'Enabled in game runtime via ui/clean_modern_art.gd',
                'palette': {'background': '#F1F7FC', 'panel': '#FFFFFF', 'panel_alt': '#E6F2FC',
                            'blue': '#087EE6', 'blue_deep': '#0452B8', 'purchase': '#68D719',
                            'text': '#23394A', 'muted': '#768CA0', 'rim': '#ADC9DE'},
                'source_images': len(inputs), 'covered_images': len(covered),
                'missing_images': missing, 'sheets': art,
                'supplemental_assets': [relative(path) for path in sorted((OUT / 'icons').glob('*.svg'))],
                'replacements': list(covered.values()), 'atlas_resources': sprites,
                'limitations': ['ImageGen raster output; original source pixels are not edited.',
                                'Atlas geometry is proportional; desktop render reviewed at 320/390/412; mobile device review pending.',
                                'Legacy SVGs are supplied as raster AtlasTexture replacements.',
                                'Audio, font files and gameplay data are outside the visual reskin.',
                                'Nine-slice margins and procedural UI colors are integrated in the runtime theme.']}
    (OUT / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding='utf-8')
    with (OUT / 'coverage.csv').open('w', newline='', encoding='utf-8-sig') as handle:
        writer = csv.DictWriter(handle, fieldnames=['source', 'replacement', 'job', 'status'])
        writer.writeheader()
        for source in inputs:
            entry = covered.get(source, {})
            writer.writerow({'source': source, 'replacement': entry.get('replacement', ''),
                             'job': entry.get('job', ''), 'status': 'generated' if entry else 'pending'})
    tiles = ''.join(
        '<figure data-group="' + html.escape(row['id'].split('_')[0]) + '">'
        '<a href="sheets/' + html.escape(row['id']) + '.png" target="_blank">'
        '<img loading="lazy" src="sheets/' + html.escape(row['id']) + '.png" alt="' + html.escape(row['id']) + '"></a>'
        '<figcaption>' + html.escape(row['id']) + '<small>' + str(row['size'][0]) + ' × ' + str(row['size'][1])
        + ' · ' + str(sum(item['job'] == row['id'] for item in covered.values())) + ' source mappings</small></figcaption></figure>' for row in art)
    groups = sorted({row['id'].split('_')[0] for row in art})
    options = ''.join('<option>' + html.escape(group) + '</option>' for group in groups)
    catalog = '''<!doctype html><html lang="vi"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Racing Manager · Clean Modern Assets</title><style>
body{margin:0;background:#f1f7fc;color:#23394a;font:15px/1.5 system-ui,sans-serif}header{padding:28px 32px;background:white;border-bottom:1px solid #adc9de}h1{margin:0;font-size:25px}p{margin:8px 0}select{padding:8px;margin-top:10px;border:1px solid #adc9de;border-radius:8px;background:white;color:#23394a}main{display:grid;grid-template-columns:repeat(auto-fill,minmax(300px,1fr));gap:20px;padding:24px}figure{margin:0;border:1px solid #c9dce9;border-radius:14px;overflow:hidden;background:white}a{height:300px;display:flex;align-items:center;justify-content:center;background:repeating-conic-gradient(#dce5ec 0% 25%,#f7fafc 0% 50%) 0/24px 24px}img{width:100%;height:100%;object-fit:contain}figcaption{padding:12px;font-weight:600}small{display:block;font-weight:400;color:#60778a}[hidden]{display:none}@media(max-width:400px){main{padding:12px;grid-template-columns:1fr}header{padding:20px}}
</style><header><h1>F · Clean Modern</h1><p>''' + str(len(art)) + ' sheets · ' + str(len(covered)) + '/' + str(len(inputs)) + ''' ảnh nguồn · Đã bật trong game · F Clean Modern.</p><label>Nhóm asset <select id="group"><option value="all">Tất cả</option>''' + options + '''</select></label></header><main>''' + tiles + '''</main><script>document.getElementById('group').addEventListener('change',event=>{document.querySelectorAll('figure').forEach(tile=>tile.hidden=event.target.value!=='all'&&tile.dataset.group!==event.target.value)});</script></html>'''
    (OUT / 'catalog.html').write_text(catalog, encoding='utf-8')
    print(json.dumps({'sheets': len(art), 'covered': len(covered), 'total': len(inputs),
                      'remapped_atlas_resources': len(sprites), 'missing_count': len(missing)}))


def validate():
    manifest = json.loads((OUT / 'manifest.json').read_text(encoding='utf-8'))
    errors = []
    for row in json.loads((OUT / 'source_inventory.json').read_text(encoding='utf-8')):
        if hashlib.sha256((ROOT / row['source']).read_bytes()).hexdigest() != row['sha256']:
            errors.append('Original changed: ' + row['source'])
    sheets = {row['path']: row for row in manifest['sheets']}
    for row in manifest['replacements'] + manifest['atlas_resources']:
        width, height = sheets[row['sheet']]['size']
        x, y, w, h = row['region']
        if min(x, y) < -0.01 or min(w, h) <= 0 or x + w > width + .1 or y + h > height + .1:
            errors.append('Invalid region: ' + row['source'])
        if not (ROOT / row['replacement']).is_file():
            errors.append('Missing resource: ' + row['replacement'])
        with Image.open(ROOT / row['sheet']) as image:
            # Inspect alpha only; never write pixels or crop exported images.
            if 'A' in image.getbands():
                bounds = (max(0, int(x)), max(0, int(y)), min(width, int(x+w+.5)), min(height, int(y+h+.5)))
                if image.getchannel('A').crop(bounds).getextrema()[1] == 0:
                    errors.append('Empty region: ' + row['source'])
    if manifest['missing_images']:
        errors.append('Uncovered source images: ' + str(len(manifest['missing_images'])))
    report = {'ok': not errors, 'source_images': manifest['source_images'],
              'generated_sheets': len(sheets), 'replacement_resources': len(manifest['replacements']),
              'remapped_atlas_resources': len(manifest['atlas_resources']), 'errors': errors,
              'scope': 'static_asset_integrity',
              'runtime_verification': 'runtime_verification.json', 'device_tested': False}
    (OUT / 'validation.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
    print(json.dumps(report))
    if errors:
        raise SystemExit(1)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('action', choices=['inventory', 'package', 'validate'])
    args = parser.parse_args()
    globals()[args.action]()
