"""Pack sprites/illustrations_x2/*.png into <=2048px pages + shop_illustrations_atlas.json."""
from pathlib import Path
from PIL import Image
import json
HERE=Path(__file__).resolve().parent
PAD=4;W=2048;MAXH=2048
files=sorted((HERE/'sprites/illustrations_x2').glob('*.png'),key=lambda f:(-Image.open(f).size[1],f.stem))
pages=[];place={}
def new_page():pages.append({'x':0,'y':0,'rowh':0,'items':[]});return pages[-1]
pg=new_page()
for f in files:
    w,h=Image.open(f).size
    if pg['x']+w+PAD>W:pg['x']=0;pg['y']+=pg['rowh']+PAD;pg['rowh']=0
    if pg['y']+h+PAD>MAXH:pg=new_page();pg['x']=0
    place[f.stem]=(len(pages)-1,pg['x']+PAD//2,pg['y']+PAD//2,w,h);pg['items'].append(f);pg['x']+=w+PAD;pg['rowh']=max(pg['rowh'],h)
for old in HERE.glob('shop_illustrations_atlas*.png*'):old.unlink()
out=[]
for i,p in enumerate(pages):
    H=1
    while H<p['y']+p['rowh']+PAD:H*=2
    img=Image.new('RGBA',(W,H),(0,0,0,0))
    for f in p['items']:
        _,x,y,_,_=place[f.stem];img.paste(Image.open(f).convert('RGBA'),(x,y))
    name=f'shop_illustrations_atlas_{i}.png';img.save(HERE/name);out.append({'image':name,'size':[W,H]});print(name,W,H,len(p['items']))
(HERE/'shop_illustrations_atlas.json').write_text(json.dumps({'pages':out,'sprites':{k:{'page':v[0],'x':v[1],'y':v[2],'w':v[3],'h':v[4]} for k,v in sorted(place.items())}},indent=1))
