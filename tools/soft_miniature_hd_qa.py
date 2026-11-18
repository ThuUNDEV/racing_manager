#!/usr/bin/env python3
"""Create non-destructive alpha QA composites; never modifies generated pixels."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import json
ROOT=Path(__file__).resolve().parents[1]
KIT=ROOT/'assets/soft_miniature_ui_v1'
OUT=ROOT/'Design/Previews/Soft_Miniature_Integrated/compare'
QA=OUT/'asset_qa_200';QA.mkdir(exist_ok=True,parents=True)
manifest=json.loads((KIT/'manifest.json').read_text())
font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',16)
files=sorted((KIT/'restored_hd').glob('*.png'))
summary=Image.new('RGB',(1024, len(files)*300+35),'#eef0f2');d=ImageDraw.Draw(summary);d.text((8,8),'BEFORE / light | BEFORE / dark | RESTORED / light | RESTORED / dark',fill='black',font=font)
for row,path in enumerate(files):
 id=path.stem;after=Image.open(path).convert('RGBA');entry=manifest['assets'].get(id,{})
 if entry.get('method')=='imagegen_hd_restoration':entry=entry.get('previous_revision',{})
 if id=='upgrade_gearbox' and not entry:entry=manifest['assets'].get('gearbox',{}).get('previous_revision',manifest['assets'].get('gearbox',{}))
 before=Image.open(KIT/entry['png_2x']).convert('RGBA') if entry else after
 y=row*300+35
 for col,(im,bg) in enumerate([(before,'#fff8ee'),(before,'#132b41'),(after,'#fff8ee'),(after,'#132b41')]):
  tile=Image.new('RGBA',(256,256),bg);art=im.copy();art.thumbnail((236,236),Image.Resampling.LANCZOS);tile.alpha_composite(art,((256-art.width)//2,(256-art.height)//2));summary.paste(tile.convert('RGB'),(col*256,y))
 d.text((5,y+258),f'{id}: {before.width}x{before.height} -> {after.width}x{after.height}',font=font,fill='black')
 # Every generated asset composited at precisely 200% on both backgrounds.
 for name,bg in [('light','#fff8ee'),('dark','#132b41')]:
  full=Image.new('RGBA',after.size,bg);full.alpha_composite(after);full=full.convert('RGB').resize((after.width*2,after.height*2),Image.Resampling.NEAREST);full.save(QA/f'{id}_{name}_200.png')
 # A native 200% edge sample on light and dark, plus the full silhouette at display size.
 bbox=after.getchannel('A').getbbox()
 if bbox:
  x=(bbox[0]+bbox[2])//2;yedge=bbox[1]
  details=Image.new('RGB',(1024,512),'white')
  for i,name in enumerate(['light','dark']):
   full=Image.open(QA/f'{id}_{name}_200.png');cx=x*2;cy=yedge*2
   detail=full.crop((max(0,cx-256),max(0,cy-100),max(0,cx-256)+512,max(0,cy-100)+512));details.paste(detail,(i*512,0))
  details.save(QA/f'{id}_edge_200.png')
summary.save(OUT/'assets_before_after.png')
print(f'{len(files)} assets, contact sheet {summary.size}')
