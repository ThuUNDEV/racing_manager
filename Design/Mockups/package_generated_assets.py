"""Package imagegen originals and atlas resources. Does not edit image pixels."""
from pathlib import Path
import csv
import hashlib
import json
import shutil
import zipfile
from PIL import Image

ROOT=Path(__file__).resolve().parents[2]
SRC=Path(r'C:\Users\thupv\.codex\generated_images\01a1c996-97d3-7031-a4bd-496e496e6bb3')
OUT=ROOT/'assets/racing_ui_hd_expansion'
(OUT/'sheets').mkdir(parents=True,exist_ok=True)
(OUT/'sprites').mkdir(exist_ok=True)
drivers=json.loads((ROOT/'data/drivers.json').read_text(encoding='utf-8-sig'))['drivers']
gear=json.loads((ROOT/'data/gear.json').read_text(encoding='utf-8-sig'))['items']
with (ROOT/'Design/18_Asset_Backlog.csv').open(encoding='utf-8-sig',newline='') as f:
    backlog=list(csv.DictReader(f))
def item(key,name,backlog_id):return {'id':key,'name':name,'backlog_id':backlog_id}
icons=[item(key,name,f'A{i:02}') for i,(key,name) in enumerate([
    ('engine','Động cơ'),('tyre','Lốp'),('chassis','Khung gầm'),('gearbox','Hộp số'),
    ('ticket','Tiếp thị vé'),('celebration','Ăn mừng chiến thắng'),('parking','Bãi đỗ'),('grandstands','Khán đài')],1)]
icons += [item('attack','Kiếm','A43'),item('defense','Khiên','A44'),item('standard_coupon','Coupon Standard','A41'),item('elite_coupon','Coupon Elite','A42')]
icons += [item(key,'Phong cách '+key,f'A{i:02}') for i,key in enumerate(['inside','sweeper','counter','defender'],57)]
portraits=[item(d['id'],d['name'],f'A{54+i:02}' if i<3 else f'A{45+i-3:02}') for i,d in enumerate(drivers)]
cars=[]
for view in ['showroom','topdown']:
    cars += [item('car_'+name+'_'+view,name.title()+' · '+view,f'A{i:02}') for i,name in enumerate(['pico','nova','apex','titan','zenith'],61)]
cars += [item('showroom_floor','Sàn showroom','A66'),item('double_stripe','Sọc đôi','A67'),item('lightning','Tia chớp','A68'),item('checker','Ô bàn cờ','A69'),item('car_shadow','Bóng xe','A70')]
packs=[item('standard_gear_pack','Gói gear Standard','A39'),item('elite_gear_pack','Gói gear Elite','A40'),item('standard_driver_pack','Gói tay đua Standard','A76'),item('elite_driver_pack','Gói tay đua Elite','A77')]
packs += [item('facility_tier_'+str(i-70),'Cơ sở bậc '+str(i-70),f'A{i:02}') for i in range(71,76)]
sheets=[
    ('layout_icons','exec-d5090edf-b2ad-4d25-a08e-393aa4d43a0d.png',4,4,icons),
    ('gear_items_01_15','exec-fdf0f9c6-551e-4f8b-b54f-05e7b0689bac.png',5,3,[item(g['id'],g['name'],f'A{i+9:02}') for i,g in enumerate(gear[:15])]),
    ('gear_items_16_30','exec-ffed509a-e5f2-4abb-b17c-dd9c090168b9.png',5,3,[item(g['id'],g['name'],f'A{i+24:02}') for i,g in enumerate(gear[15:])]),
    ('driver_portraits','exec-2b4eccc4-6dbd-4468-9ad1-311f23eda1f6.png',4,3,portraits),
    ('garage','exec-c5f694f6-a80b-43d2-854e-2ff474e96920.png',5,3,cars),
    ('packs_facilities','exec-e1a21ebb-6b7c-4d59-95da-5411ae4312dd.png',3,3,packs)
]
manifest={'name':'Racing UI HD Expansion','date':'2026-11-11','status':'Integrated into game UI; race simulation markers unchanged','source':'OpenAI image generation with local Racing UI HD style references','reference_assets':['assets/racing_ui_hd/icons/car_red.png','assets/racing_ui_hd/icons/avatar.png','assets/racing_ui_hd/surfaces/panel_body.png'],'sheets':[],'sprites':[]}
for name,src,cols,rows,items in sheets:
    dest=OUT/'sheets'/(name+'.png')
    shutil.copy2(SRC/src,dest)
    im=Image.open(dest)
    assert im.mode=='RGBA'
    assert im.getchannel('A').getextrema()==(0,255),(name,im.getchannel('A').getextrema())
    w,h=im.size
    ys=[0,234,475,h] if name=='packs_facilities' else [round(i*h/rows) for i in range(rows+1)]
    xs=[round(i*w/cols) for i in range(cols+1)]
    manifest['sheets'].append({'id':name,'path':str(dest.relative_to(ROOT)).replace('\\','/'),'size':[w,h],'grid':[cols,rows],'sha256':hashlib.sha256(dest.read_bytes()).hexdigest(),'original_filename':src,'alpha_extrema':[0,255]})
    for idx,sprite in enumerate(items):
        c,r=idx%cols,idx//cols
        x,y=xs[c],ys[r]
        sw,sh=xs[c+1]-x,ys[r+1]-y
        assert im.getchannel('A').crop((x,y,x+sw,y+sh)).getbbox() is not None
        cell_region=[x,y,sw,sh]
        # Trim metadata only: leave generated PNG bytes unchanged.
        bounds=im.getchannel('A').crop((x,y,x+sw,y+sh)).point(lambda a:255 if a>48 else 0).getbbox()
        if bounds:
            left,top,right,bottom=bounds
            left,top=max(0,left-2),max(0,top-2)
            right,bottom=min(sw,right+2),min(sh,bottom+2)
            x,y,sw,sh=x+left,y+top,right-left,bottom-top
        rel='res://assets/racing_ui_hd_expansion/sheets/'+name+'.png'
        resource=OUT/'sprites'/(sprite['id']+'.tres')
        resource.write_text('[gd_resource type="AtlasTexture" load_steps=2 format=3]\n\n[ext_resource type="Texture2D" path="'+rel+'" id="1"]\n\n[resource]\natlas = ExtResource("1")\nregion = Rect2('+', '.join(str(n) for n in [x,y,sw,sh])+')\nfilter_clip = true\n',encoding='utf-8')
        manifest['sprites'].append({**sprite,'sheet':name,'row':r+1,'column':c+1,'cell_region':cell_region,'region':[x,y,sw,sh],'resource':str(resource.relative_to(ROOT)).replace('\\','/')})
assert len(manifest['sprites'])==82
assert len({x['id'] for x in manifest['sprites']})==82
assert {x['backlog_id'] for x in manifest['sprites']}=={x['id'] for x in backlog}
native_log=ROOT/'Design/Previews/asset_integration_native.log'
native_text=native_log.read_text(encoding='utf-8-sig') if native_log.exists() else ''
manifest['validation']={'pngs':6,'atlas_resources':82,'backlog_items_covered':77,'checks':['All PNGs RGBA with transparent pixels','All atlas regions in bounds and nonempty','Unique sprite IDs','All A01–A77 mapped'],'godot_runtime_tested':'ASSET_INTEGRATION_TEST failures=0' in native_text and 'SCRIPT ERROR' not in native_text,'native_report':'Design/Previews/asset_integration_native.log','limitations':['Car paint uses a neutral-body shader, not hand-authored per-model masks','Buildings are UI vignettes, not playable tracks','AI raster art may need edge cleanup at final display scale']}
(OUT/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
archive=ROOT/'Design/AssetPacks/Racing_UI_HD_Expansion_2026-11-11.zip'
archive.parent.mkdir(exist_ok=True)
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
    for p in sorted(OUT.rglob('*')):
        if p.is_file() and p.suffix!='.import':z.write(p,p.relative_to(OUT.parent))
print(json.dumps({'pack':str(archive),'pngs':6,'atlas_resources':82,'backlog_items_covered':77,'bytes':archive.stat().st_size},ensure_ascii=False))
