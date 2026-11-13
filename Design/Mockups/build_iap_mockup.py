"""Build the design-only IAP review from the current game catalog and atlas metadata."""
from pathlib import Path
import json
import re
import struct

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent

def read(name):
    return json.loads((ROOT / 'data' / name).read_text(encoding='utf-8-sig'))

atlas = {}
for path in (ROOT / 'assets/racing_ui_hd_expansion/sprites').glob('*.tres'):
    text = path.read_text(encoding='utf-8-sig')
    sheet = re.search(r'path="res://([^"]+)"', text)
    region = re.search(r'region = Rect2\(([^)]+)\)', text)
    if not sheet or not region:
        continue
    image = ROOT / sheet[1]
    width, height = struct.unpack('>II', image.read_bytes()[16:24])
    atlas[path.stem] = {'url': '../../' + sheet[1], 'sheet': [width, height],
                        'rect': [float(x) for x in region[1].split(',')]}
data = {'iap': read('iap.json'), 'drivers': read('drivers.json')['drivers'],
        'driverPacks': read('driver_gacha.json')['packs'],
        'gearPacks': read('gear.json')['packs'], 'atlas': atlas}
template = (HERE / 'iap_packs.template.html').read_text(encoding='utf-8')
(HERE / 'iap_packs.html').write_text(template.replace('/*CATALOG*/',
    'const DATA = ' + json.dumps(data, ensure_ascii=False) + ';'), encoding='utf-8')
print('Built Design/Mockups/iap_packs.html from', len(data['iap']['products']), 'SKUs')
