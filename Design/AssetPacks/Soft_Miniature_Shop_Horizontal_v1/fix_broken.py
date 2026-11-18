"""Re-matte broken sprites: tight crop -> upscale x2 -> remove_background(refine) -> keep main component."""
import sys
from pathlib import Path
from PIL import Image,ImageFilter
from io import BytesIO
from collections import deque
import base64,json,urllib.request
sys.path.insert(0,str(Path(__file__).parent))
import extract as E
from upscale import call
SRC=E.SOURCE;OUT=Path(__file__).parent/'sprites/illustrations_x2'
def fetch(meta):return Image.open(BytesIO(urllib.request.urlopen(meta['download_url'],timeout=300).read())).convert('RGBA')
def meta_of(res):
    if res.get('error') or res['result'].get('isError'):raise RuntimeError(str(res)[:300])
    return next(json.loads(c['text']) for c in res['result']['content'] if c['type']=='text')
def keep_main(alpha,minfrac=0.02):
    w,h=alpha.size;ap=alpha.load();seen=bytearray(w*h);comps=[]
    for y in range(h):
        for x in range(w):
            if seen[y*w+x] or ap[x,y]<=30:continue
            q=deque([(x,y)]);seen[y*w+x]=1;pts=[]
            while q:
                cx,cy=q.popleft();pts.append((cx,cy))
                for nx,ny in((cx+1,cy),(cx-1,cy),(cx,cy+1),(cx,cy-1)):
                    if 0<=nx<w and 0<=ny<h and not seen[ny*w+nx] and ap[nx,ny]>30:seen[ny*w+nx]=1;q.append((nx,ny))
            comps.append(pts)
    big=max(len(c) for c in comps);out=Image.new('L',(w,h),0);op=out.load()
    for c in comps:
        if len(c)>=big*minfrac:
            for x,y in c:op[x,y]=ap[x,y]
    return out
EXTRA={'income_upgrade':(0,0,16,0),'offline_plus':(0,0,0,12),'combo':(0,10,0,4),'combo_1':(0,12,0,4),'combo_2':(0,12,0,4)}  # l,t,r,b extra px
def run(name,pad_top=3):
    for fn,ents in E.GROUPS.items():
        for n,box in ents:
            if n!=name:continue
            src=Image.open(SRC/fn).convert('RGBA');e=EXTRA.get(name,(0,0,0,0));b=(box[0]-e[0],max(0,box[1]-pad_top-e[1]),box[2]+e[2],box[3]+e[3])
            crop=src.crop(b);buf=BytesIO();crop.save(buf,format='PNG')
            m=meta_of(call('upscale',{'image':base64.b64encode(buf.getvalue()).decode(),'scale':2}))
            big=fetch(m).resize((crop.width*2,crop.height*2),Image.Resampling.LANCZOS)
            buf=BytesIO();big.save(buf,format='PNG')
            m=meta_of(call('remove_background',{'image':base64.b64encode(buf.getvalue()).decode(),'refine':True}))
            a=fetch(m).getchannel('A').resize(big.size,Image.Resampling.LANCZOS)
            a=a.point(lambda v:0 if v<60 else v).filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(0.8))
            a=keep_main(a).point(lambda v:0 if v<40 else min(255,int(v*1.2)))
            big.putalpha(a);bb=a.getbbox();big=big.crop(bb);OUT.mkdir(exist_ok=True);big.save(OUT/f'{name}.png');print(name,big.size,flush=True)
if __name__=='__main__':
    for n in sys.argv[1:]:run(n)
