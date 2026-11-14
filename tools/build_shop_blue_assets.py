"""Package unchanged generated sprites and create text-free blue/white UI surfaces."""
from pathlib import Path
import hashlib, json, shutil
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/shop_blue_white'
SOURCE = Path('C:/Users/thupv/.codex/generated_images/01a1d4b2-fecc-7ee0-8d39-0fece11c36b3/exec-5af9cea9-775f-47ad-a238-15a38989db76.png')
OUT.mkdir(exist_ok=True)
(OUT/'sprites').mkdir(exist_ok=True)
if not SOURCE.exists():
    SOURCE = OUT/'items.png'
if SOURCE.resolve() != (OUT/'items.png').resolve():
    shutil.copy2(SOURCE, OUT/'items.png')
im=Image.open(SOURCE)
assert im.mode=='RGBA' and im.getchannel('A').getextrema()[0]==0
names=['gem_single','gem_cluster','gem_bag','gem_chest','gem_vault','cash_small','cash_medium','cash_large','income','no_ads','gift','offline']
regions={}
for i,name in enumerate(names):
    x0,x1=(i%4)*im.width//4,(i%4+1)*im.width//4
    y0,y1=(i//4)*im.height//3,(i//4+1)*im.height//3
    bounds=im.getchannel('A').crop((x0,y0,x1,y1)).point(lambda v:255 if v>=190 else 0).getbbox()
    assert bounds,name
    l,t,r,b=bounds
    l,t=max(0,l-5),max(0,t-5)
    r,b=min(x1-x0,r+5),min(y1-y0,b+5)
    region=[x0+l,y0+t,r-l,b-t]
    regions[name]=region
    (OUT/'sprites'/f'{name}.tres').write_text('[gd_resource type="AtlasTexture" load_steps=2 format=3]\n\n[ext_resource type="Texture2D" path="res://assets/shop_blue_white/items.png" id="1"]\n\n[resource]\natlas = ExtResource("1")\nregion = Rect2('+', '.join(map(str,region))+')\nfilter_clip = true\n',encoding='utf-8')

def svg(name,w,h,body):
    (OUT/f'{name}.svg').write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">{body}</svg>',encoding='utf-8')

for name,top,bottom,border in [('banner','#ffffff','#e1f3ff','#64acf1'),('free','#e6fbff','#b9edff','#50b5eb'),('tile','#ffffff','#e9f5ff','#82b8eb')]:
    svg(name,384,144,f'<defs><linearGradient id="g" x2="0" y2="1"><stop stop-color="{top}"/><stop offset="1" stop-color="{bottom}"/></linearGradient><clipPath id="c"><rect x="3" y="2" width="378" height="138" rx="13"/></clipPath></defs><rect x="1" y="4" width="382" height="139" rx="15" fill="#b8d9f2"/><rect x="1" y="1" width="382" height="138" rx="15" fill="url(#g)" stroke="{border}" stroke-width="2"/><g clip-path="url(#c)" fill="#ffffff" opacity=".32"><path d="M35 0h24L-30 144h-24zM300 0h25l-90 144h-25zM360 0h18l-90 144h-18z"/></g><rect x="4" y="4" width="376" height="132" rx="12" fill="none" stroke="white" stroke-width="2"/>')
svg('section',384,38,'<defs><linearGradient id="g" x2="0" y2="1"><stop stop-color="#1395ff"/><stop offset=".4" stop-color="#0075e9"/><stop offset="1" stop-color="#0358c1"/></linearGradient></defs><rect x="1" y="3" width="382" height="34" rx="10" fill="#aacfee"/><rect x="1" y="1" width="382" height="33" rx="10" fill="url(#g)" stroke="#0656b8" stroke-width="2"/><path d="M12 4h360" stroke="#81caff" stroke-width="2"/>')
for name,top,bottom,stroke in [('buy','#78ef10','#35bc00','#258800'),('action','#168fff','#0059c8','#00469e'),('tab','#f9fdff','#d9efff','#8abbeb'),('disabled','#ecf2f7','#d4e1ec','#afc4d7')]:
    svg(name,168,52,f'<defs><linearGradient id="g" x2="0" y2="1"><stop stop-color="{top}"/><stop offset="1" stop-color="{bottom}"/></linearGradient></defs><rect x="1" y="3" width="166" height="48" rx="12" fill="{stroke}"/><rect x="1" y="1" width="166" height="47" rx="12" fill="url(#g)" stroke="{stroke}" stroke-width="2"/><path d="M13 4h142" stroke="white" stroke-opacity=".6" stroke-width="2"/>')
svg('flags',120,42,'<g fill="#57a5e7" transform="skewX(-16)"><path d="M10 7h11v10H10zm22 0h11v10H32zM21 17h11v10H21zm22 0h11v10H43zM10 27h11v10H10zm22 0h11v10H32z"/><path d="M75 7h11v10H75zm22 0h11v10H97zM86 17h11v10H86zm22 0h11v10h-11zM75 27h11v10H75zm22 0h11v10H97z"/></g>')
(OUT/'manifest.json').write_text(json.dumps({'source':str(SOURCE),'sha256':hashlib.sha256(SOURCE.read_bytes()).hexdigest(),'size':im.size,'regions':regions,'note':'Original PNG copied byte-for-byte; integer atlas bounds only. Text/prices/rewards remain dynamic.'},indent=2),encoding='utf-8')
print('Shop blue-white assets: 12 transparent sprites + 8 UI surfaces')
