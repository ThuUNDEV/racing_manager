"""Validate artwork in a temporary Godot project without game autoloads or saves."""
from pathlib import Path
import json
import os
import re
import shutil
import subprocess
import tempfile
import zipfile

ROOT = Path(__file__).resolve().parents[1]
PACK = ROOT / 'Design/AssetPacks/Racing_IAP_Complete_v2.zip'
data = json.loads((ROOT / 'assets/iap_offers/manifest.json').read_text(encoding='utf-8'))
catalog = json.loads((ROOT / 'data/iap.json').read_text(encoding='utf-8-sig'))
assert set(data['recipes']) == {p['sku'] for p in catalog['products']}
assert not data['recipes']['weekly_xl']['enabled_by_default']
for kind in ['resources', 'styles', 'art']:
    for path in (ROOT / 'assets/iap_offers' / kind).glob('*.t*'):
        for target in re.findall(r'path="res://([^"]+)"', path.read_text(encoding='utf-8')):
            assert (ROOT / target).is_file(), (path, target)
with zipfile.ZipFile(PACK) as archive:
    assert archive.testzip() is None
    members = set(archive.namelist())
    for value in data['shared_existing_assets'].values():
        assert value in members, value
    for texture in data['textures'].values():
        assert texture['path'] in members
        assert texture['resource'] in members
    staging = Path(tempfile.mkdtemp(prefix='racing_iap_art_qa_'))
    archive.extractall(staging)
(staging / 'project.godot').write_text('config_version=5\n\n[application]\nconfig/name="IAP Art QA"\n\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n', encoding='utf-8')
shutil.copy2(ROOT / 'tools/validate_iap_art.gd', staging / 'validate_iap_art.gd')
engine = Path(os.environ['LOCALAPPDATA']) / 'Programs/Godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe'
log = []
for args in [['--headless', '--editor', '--path', str(staging), '--import', '--quit'],
             ['--headless', '--path', str(staging), '--script', 'res://validate_iap_art.gd']]:
    result = subprocess.run([str(engine), *args], capture_output=True, text=True, encoding='utf-8', errors='replace', timeout=180)
    log.append(result.stdout + result.stderr)
    if result.returncode != 0 or any(x in log[-1] for x in ['SCRIPT ERROR', 'Parse Error', 'ERROR:']):
        print(log[-1])
        raise RuntimeError(f'Godot art validation failed: {result.returncode}; staging kept at {staging}')
report = ROOT / 'Design/Previews/iap_assets_v2_godot_validation.log'
report.write_text('\n'.join(log), encoding='utf-8')
print('PASS: 30/30 catalog, XL flag, resource dependencies, ZIP CRC, isolated Godot import and instantiation.')
print('Staging:', staging)
print(log[-1].strip())
