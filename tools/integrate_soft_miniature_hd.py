#!/usr/bin/env python3
"""Integrate selected image_gen restorations without resampling their pixels or alpha.
Run after generation.json has been populated. Keeps original assets for comparison.
"""
from pathlib import Path
from PIL import Image
import json,hashlib,shutil
ROOT=Path(__file__).resolve().parents[1]
KIT=ROOT/'assets/soft_miniature_ui_v1';PACK=ROOT/'Design/AssetPacks/Soft_Miniature_UI_v1'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
m=json.loads((KIT/'manifest.json').read_text());generation=json.loads((KIT/'restored_hd/generation.json').read_text())
for job in generation['assets']:
 id=job['id'];path=KIT/f'restored_hd/{id}.png';im=Image.open(path)
 minimum=1536 if id=='harbor_background_clean' else 512
 assert max(im.size)>=minimum,(id,im.size)
 old=m['assets'].get(id,{})
 if old.get('method')=='imagegen_hd_restoration':old=old['previous_revision']
 entry={'method':'imagegen_hd_restoration','source':job['reference'],'source_sha256':sha(ROOT/job['reference']),'generator':'built-in image_gen','prompt':job['prompt'],'generated_original':job['generated_path'],'png_2x':str(path.relative_to(KIT)),'native':str(path.relative_to(KIT)),'native_size':list(im.size),'size_2x':list(im.size),'transparent':im.mode=='RGBA','sha256':sha(path),'alpha_processing':'Preserved image_gen alpha, no thresholding, resampling or rembg.','previous_revision':old,'note':'Reconstructed illustration; minor generated shape differences remain. No claim of pixel-identical restoration.'}
 if im.mode=='RGBA':
  bbox=im.getchannel('A').point(lambda a: 255 if a>=32 else 0).getbbox()
  if bbox:
   pad=round(max(im.size)*.015)
   x,y=max(0,bbox[0]-pad),max(0,bbox[1]-pad)
   entry['visible_region_xywh']=[x,y,min(im.width,bbox[2]+pad)-x,min(im.height,bbox[3]+pad)-y]
 m['assets'][id]=entry
 dest=PACK/path.relative_to(KIT);dest.parent.mkdir(exist_ok=True,parents=True);shutil.copy2(path,dest)
m['hd_restoration']={'generator':'built-in image_gen','generation_manifest':'restored_hd/generation.json','minimum_icon_long_edge':512,'minimum_island_width':1536,'runtime_filter':'linear_with_mipmaps','qa':'Design/Previews/Soft_Miniature_Integrated/compare/asset_qa_200/'}
(KIT/'manifest.json').write_text(json.dumps(m,ensure_ascii=False,indent=2)+'\n');shutil.copy2(KIT/'manifest.json',PACK/'manifest.json');shutil.copy2(KIT/'restored_hd/generation.json',PACK/'restored_hd/generation.json')
# Apply deterministic import options after Godot has created texture import sidecars.
for p in (KIT/'restored_hd').glob('*.png.import'):
 s=p.read_text().replace('mipmaps/generate=false','mipmaps/generate=true').replace('process/fix_alpha_border=false','process/fix_alpha_border=true').replace('compress/mode=2','compress/mode=0')
 p.write_text(s)
print(f'Integrated {len(generation["assets"])} HD assets; generated pixels/alpha preserved.')
