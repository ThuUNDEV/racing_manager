"""Crop approved horizontal concepts, then call the user-provided art-tools MCP.
No text-bearing full cards are exported as runtime assets.
"""
from pathlib import Path
from PIL import Image,ImageChops
from io import BytesIO
import base64,json,urllib.request,sys
ROOT=Path(__file__).resolve().parents[3]
OUT=Path(__file__).resolve().parent
SOURCE=ROOT/'Design/Demos/SoftMiniature/shop_horizontal_v1'
ENDPOINT='http://192.168.11.181:8790/mcp'
GROUPS={
'shop-horizontal-v1.png':[
('starter',(15,320,300,540)),('income_x2',(15,574,302,784)),('no_ads',(20,817,300,1014)),('combo',(20,1045,302,1240)),('driver_my',(20,1365,292,1578))],
'02-daily.png':[
('daily_gift',(15,355,300,578)),('free_gems',(17,615,298,808)),('daily_gear',(17,975,298,1187)),('daily_driver',(17,1227,298,1448))],
'03-currency.png':[
('gems_50',(25,300,280,422)),('gems_275',(25,449,280,573)),('gems_600',(25,602,280,729)),('gems_1300',(25,752,280,881)),('gems_3500',(25,906,280,1044)),('cash_small',(25,1163,280,1280)),('cash_medium',(25,1307,280,1423)),('cash_large',(25,1452,280,1582))],
'04-packs.png':[
('pack_driver_pro',(22,330,255,504)),('pack_driver_allstar',(22,543,255,717)),('pack_gear_standard',(22,755,255,939)),('pack_gear_elite',(22,972,255,1158)),('free_gear_ticket',(22,1285,255,1421)),('free_driver_ticket',(22,1449,255,1585))],
'05-perks-weekly.png':[
('income_x3',(20,246,271,384)),('income_upgrade',(20,412,271,535)),('offline_plus',(20,568,271,687)),('combo_1',(20,792,265,900)),('combo_2',(20,922,265,1034)),('weekly_s',(20,1142,262,1230)),('weekly_m',(20,1257,262,1341)),('weekly_l',(20,1377,262,1460)),('weekly_xl',(20,1491,262,1575))],
'06-drivers-passes.png':[
('driver_lam',(20,291,252,441)),('driver_nhan',(20,465,252,616)),('driver_phuong',(20,641,252,794)),('driver_quang',(20,815,252,970)),('driver_son',(20,992,252,1145)),('pass_month',(20,1265,255,1395)),('pass_growth',(20,1426,255,1559))]}

def clean_alpha(crop,alpha):
    # remove cream ground/background patches + fringe
    from PIL import ImageFilter
    w,h=crop.size;px=crop.load();ap=alpha.load()
    cream=(243,237,235)
    alpha=alpha.point(lambda v:0 if v<40 else v).filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(0.6))
    return alpha.point(lambda v:0 if v<30 else min(255,int(v*1.15)))

def extract(name,filename,box):
    dest=OUT/'sprites/illustrations'/f'{name}.png'
    if dest.exists() and not FORCE:return
    src=Image.open(SOURCE/filename).convert('RGBA')
    box=(max(24,box[0]-2),max(0,box[1]-9),min(290,box[2]+12),min(src.height,box[3]+5))
    crop=src.crop(box)
    big=crop.resize((crop.width*2,crop.height*2),Image.Resampling.LANCZOS)
    buf=BytesIO();big.save(buf,format='PNG')
    req={'jsonrpc':'2.0','id':1,'method':'tools/call','params':{'name':'remove_background','arguments':{'image':base64.b64encode(buf.getvalue()).decode(),'refine':True,'trim':False}}}
    request=urllib.request.Request(ENDPOINT,data=json.dumps(req).encode(),headers={'Content-Type':'application/json','Accept':'application/json, text/event-stream'})
    with urllib.request.urlopen(request,timeout=180) as response:result=json.load(response)
    if result.get('error') or result.get('result',{}).get('isError'):raise RuntimeError(str(result))
    meta=None
    for block in result['result']['content']:
        if block['type']=='text':meta=json.loads(block['text'])
        if block['type']=='image':block.pop('data')
    if not meta:raise RuntimeError('No result for '+name)
    with urllib.request.urlopen(meta['download_url'],timeout=180) as r2:full=Image.open(BytesIO(r2.read())).convert('RGBA')
    alpha=clean_alpha(crop,full.getchannel('A').resize(crop.size,Image.Resampling.LANCZOS))
    # Preserve source RGB; only use the service's alpha, avoiding color changes.
    crop.putalpha(alpha)
    bounds=alpha.getbbox()
    if not bounds:raise RuntimeError('Empty foreground: '+name)
    crop=crop.crop(bounds)
    dest.parent.mkdir(parents=True,exist_ok=True);crop.save(dest)
    (OUT/'mcp_metadata').mkdir(exist_ok=True)
    (OUT/'mcp_metadata'/f'{name}.json').write_text(json.dumps(result,indent=2))
    manifest_path=OUT/'manifest.json'
    manifest=json.loads(manifest_path.read_text()) if manifest_path.exists() else {'source_directory':str(SOURCE.relative_to(ROOT)),'tool':ENDPOINT,'sprites':{}}
    manifest['sprites'][name]={'file':str(dest.relative_to(OUT)),'source':filename,'source_rect':list(box),'trim_rect':list(bounds),'size':list(crop.size),'type':'illustration','contains_text':False}
    manifest_path.write_text(json.dumps(manifest,indent=2))
    print(name,list(crop.size),flush=True)

FORCE=True
if __name__=='__main__':
    selected=set(sys.argv[1:])
    for filename,entries in GROUPS.items():
        for name,box in entries:
            if not selected or name in selected:extract(name,filename,box)
