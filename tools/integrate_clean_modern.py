"""Apply the generated kit to runtime references, preserving a pre-edit backup."""
import json
import re
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BACKUP = Path.home() / '.codex/visualizations/2026/11/13/clean-modern-integration-backup'
manifest = json.loads((ROOT / 'assets/clean_modern/manifest.json').read_text(encoding='utf-8'))
if (ROOT / 'assets/clean_modern/integration_files.json').exists():
    raise SystemExit('Integration already applied. Restore its backup before applying again.')
images = {r['source']: r for r in manifest['replacements']}
paths = {r['source']: r['replacement'] for r in manifest['replacements'] + manifest['atlas_resources']}
changed = []

def save(path, text):
    original = path.read_text(encoding='utf-8')
    if original == text:
        return
    rel = path.relative_to(ROOT)
    backup = BACKUP / rel
    if not backup.exists():
        backup.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, backup)
    path.write_text(text, encoding='utf-8', newline='\n')
    changed.append(rel.as_posix())

# Script loads include dynamic paths, so route them centrally. Audio/scripts fall through.
scripts = list((ROOT / 'ui').glob('*.gd')) + list((ROOT / 'assets/workshop_gp/components').glob('*.gd')) + [ROOT / 'assets/iap_offers/iap_skin.gd']
colors = {'16355c': '23394a', '5a7294': '768ca0', '526a8a': '768ca0', '647d9b': '768ca0',
          'dcebff': 'f1f7fc', 'eaf3ff': 'f1f7fc', 'e4efff': 'ffffff', 'cfe0fb': 'e6f2fc',
          '9db9e3': 'adc9de', '2f6fe0': '087ee6', 'd96a00': '087ee6', '0f2a52': '23394a'}
for path in scripts:
    if path.name == 'clean_modern_art.gd':
        continue
    text = path.read_text(encoding='utf-8')
    if re.search(r'(?<![\w])load\(', text):
        text = re.sub(r'(?<![\w])load\(', 'CleanArt.asset(', text)
        lines = text.splitlines()
        pos = next(i + 1 for i, line in enumerate(lines) if line.startswith('extends '))
        lines.insert(pos, 'const CleanArt = preload("res://ui/clean_modern_art.gd")')
        text = '\n'.join(lines) + '\n'
    for source, target in paths.items():
        text = text.replace('preload("res://' + source + '")', 'preload("res://' + target + '")')
    for old, new in colors.items():
        text = text.replace('Color("' + old + '")', 'Color("' + new + '")')
    save(path, text)

# Serialized scenes, frames and styles must point at the new art as well.
for folder in ['workshop_gp', 'racing_ui_hd_expansion', 'iap_offers', 'tutorial', 'racing_ui_hd']:
    for path in (ROOT / 'assets' / folder).rglob('*'):
        if path.suffix not in ['.tscn', '.tres']:
            continue
        text = path.read_text(encoding='utf-8')
        if 'type="AtlasTexture"' in text.splitlines()[0]:
            continue  # Replaced by the already generated atlas resource.
        if 'type="StyleBoxTexture"' in text.splitlines()[0]:
            match = re.search(r'path="res://([^"]+)"', text)
            row = images.get(match[1]) if match else None
            if row and 'region_rect = Rect2(' in text:
                sx = row['region'][2] / row['original_size'][0]
                sy = row['region'][3] / row['original_size'][1]
                def rect(m):
                    values = [float(v.strip()) for v in m[1].split(',')]
                    return 'region_rect = Rect2(' + ', '.join(f'{v * s:.4f}' for v, s in zip(values, [sx, sy, sx, sy])) + ')'
                text = re.sub(r'region_rect = Rect2\(([^)]+)\)', rect, text)
                text = re.sub(r'(texture_margin_(left|right|top|bottom) = )([\d.]+)',
                              lambda m: m[1] + f'{float(m[3]) * (sx if m[2] in ["left", "right"] else sy):.4f}', text)
            elif row:
                # Scale nine-slice caps when a legacy SVG now uses a new atlas region.
                sx = row['region'][2] / row['original_size'][0]
                sy = row['region'][3] / row['original_size'][1]
                text = re.sub(r'(texture_margin_(left|right|top|bottom) = )([\d.]+)',
                              lambda m: m[1] + f'{float(m[3]) * (sx if m[2] in ["left", "right"] else sy):.4f}', text)
        for source, target in paths.items():
            text = text.replace('path="res://' + source + '"', 'path="res://' + target + '"')
        save(path, text)

(ROOT / 'assets/clean_modern/integration_files.json').write_text(json.dumps(changed, indent=2), encoding='utf-8')
print(json.dumps({'modified': len(changed), 'backup': str(BACKUP)}))
