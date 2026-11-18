"""Close small gaps then fill enclosed transparent holes in alpha (RGB is untouched)."""
import sys
from pathlib import Path
from PIL import Image,ImageFilter
from collections import deque
D=Path(__file__).parent/'sprites/illustrations_x2'
def fill(name,close=5):
    im=Image.open(D/f'{name}.png').convert('RGBA');a=im.getchannel('A')
    pad=close*2;w,h=a.size
    big=Image.new('L',(w+pad*2,h+pad*2),0);big.paste(a,(pad,pad))
    sol=big.point(lambda v:255 if v>60 else 0)
    k=close*2+1;closed=sol.filter(ImageFilter.MaxFilter(k)).filter(ImageFilter.MinFilter(k))
    W,H=closed.size;cp=closed.load();seen=bytearray(W*H);q=deque([(0,0)]);seen[0]=1
    while q:
        x,y=q.popleft()
        for nx,ny in((x+1,y),(x-1,y),(x,y+1),(x,y-1)):
            if 0<=nx<W and 0<=ny<H and not seen[ny*W+nx] and cp[nx,ny]==0:seen[ny*W+nx]=1;q.append((nx,ny))
    ap=big.load();bp=big.copy().load();out=big.copy();op=out.load()
    for y in range(H):
        for x in range(W):
            if not seen[y*W+x] and ap[x,y]<255:op[x,y]=255
    # gaps sealed by closing but connected to outside stay as-is; only enclosed holes are filled
    out=out.crop((pad,pad,pad+w,pad+h));im.putalpha(out);im.save(D/f'{name}.png');print(name,'filled')
for n in sys.argv[1:]:fill(n)
