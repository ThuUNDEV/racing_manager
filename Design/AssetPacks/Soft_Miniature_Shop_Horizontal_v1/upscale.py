"""Upscale sprites/illustrations -> sprites/illustrations_x2 via art-tools MCP (keeps alpha)."""
from pathlib import Path
from PIL import Image
from io import BytesIO
import base64,json,urllib.request,sys
HERE=Path(__file__).resolve().parent
EP='http://192.168.11.181:8790/mcp'
def call(tool,args):
    req={'jsonrpc':'2.0','id':1,'method':'tools/call','params':{'name':tool,'arguments':args}}
    r=urllib.request.Request(EP,data=json.dumps(req).encode(),headers={'Content-Type':'application/json','Accept':'application/json, text/event-stream'})
    return json.load(urllib.request.urlopen(r,timeout=300))
def up(src,dst,scale=2):
    b=BytesIO();Image.open(src).convert('RGBA').save(b,format='PNG')
    res=call('upscale',{'image':base64.b64encode(b.getvalue()).decode(),'scale':scale})
    if res.get('error') or res['result'].get('isError'):raise RuntimeError(str(res)[:300])
    meta=next(json.loads(c['text']) for c in res['result']['content'] if c['type']=='text')
    im=Image.open(BytesIO(urllib.request.urlopen(meta['download_url'],timeout=300).read())).convert('RGBA')
    tw,th=Image.open(src).size[0]*scale,Image.open(src).size[1]*scale
    if im.size!=(tw,th):im=im.resize((tw,th),Image.Resampling.LANCZOS)
    dst.parent.mkdir(exist_ok=True);im.save(dst);return im.size
if __name__=='__main__':
    names=sys.argv[1:] or [p.stem for p in sorted((HERE/'sprites/illustrations').glob('*.png'))]
    for n in names:
        print(n,up(HERE/'sprites/illustrations'/f'{n}.png',HERE/'sprites/illustrations_x2'/f'{n}.png'),flush=True)
