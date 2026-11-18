from pathlib import Path
from PIL import Image,ImageDraw,ImageFont,ImageChops
import json,runpy,io,shutil
ROOT=Path(__file__).resolve().parent
DEST=Path.cwd()/'assets/daily_gift_v3'
# Load helpers without executing their extraction loops.
src=(ROOT.parent/'setup_v2/build_setup_pack.py').read_text().split('entries=[]')[0]
ns={'__file__':str(ROOT.parent/'setup_v2/build_setup_pack.py')};exec(src,ns)
# Reuse the MCP wire protocol helper without running skin upscales.
src2=(ROOT/'build_assets.py').read_text().split('old=json.loads')[0];ns2={'__file__':str(ROOT/'build_assets.py')};exec(src2,ns2)
atlas=Image.open(ROOT/'reward_hd_atlas.png').convert('RGBA')
names=['coupon_driver_pro','coupon_driver_allstar','coupon_gear_standard','coupon_gear_elite','gem','gift','gift_grand','drivers','gear_bag']
m=json.loads((DEST/'manifest.json').read_text())
for i,name in enumerate(names):
    box=(round(i%3*atlas.width/3),round(i//3*atlas.height/3),round((i%3+1)*atlas.width/3),round((i//3+1)*atlas.height/3))
    tmp=ROOT/(name+'_crop.png');atlas.crop(box).save(tmp)
    raw=ns2['mcp_image'](tmp,'remove_background',refine=True,trim=False)
    sprite=Image.open(io.BytesIO(raw)).convert('RGBA');a=sprite.getchannel('A');sprite.putalpha(ImageChops.darker(a,ns['largest_mask'](a)))
    bbox=sprite.getchannel('A').point(lambda a:255 if a>12 else 0).getbbox();sprite=sprite.crop(bbox)
    padded=Image.new('RGBA',(sprite.width+16,sprite.height+16));padded.paste(sprite,(8,8));padded.save(DEST/'icons'/f'{name}.png')
    # Keep every icon at least 512px across its largest axis using the MCP upscaler.
    if max(padded.size)<512:
        (DEST/'icons'/f'{name}.png').write_bytes(ns2['mcp_image'](DEST/'icons'/f'{name}.png','upscale',scale=2))
    with Image.open(DEST/'icons'/f'{name}.png') as final:size=list(final.size)
    m['sprites'].append({'name':name,'file':f'icons/{name}.png','size':size,'origin':'ImageGen reconstructed HD art + art-tools.remove_background/refine + art-tools.upscale 2x','role':'distinct coupon' if name.startswith('coupon_') else 'HD reward icon'})
    print(name,size,flush=True)
# Low cost shared white check glyph from the original icon; MCP upscale it too.
p=ROOT.parent/'sprites_v1/icons/claimed_check_day01.png'
(DEST/'icons/check_white.png').write_bytes(ns2['mcp_image'](p,'upscale',scale=4))
with Image.open(DEST/'icons/check_white.png') as im:size=list(im.size)
m['sprites'].append({'name':'check_white','file':'icons/check_white.png','size':size,'origin':'original concept + art-tools.upscale 4x'})
# Native 1x skins for StyleBoxTexture border widths. Keep HD sources separately.
(DEST/'runtime').mkdir(exist_ok=True)
for e in m['sprites']:
    if not e['file'].startswith('skins/'):continue
    im=Image.open(DEST/e['file']).convert('RGBA');im=im.resize((round(im.width/4),round(im.height/4)),Image.Resampling.LANCZOS);im.save(DEST/'runtime'/f"{e['name']}.png")
    e['runtime_file']=f"runtime/{e['name']}.png"
    if e['slice_margins_ltrb']:
        e['hd_slice_margins_ltrb']=e['slice_margins_ltrb']
        e['slice_margins_ltrb']=[round(x/4) for x in e['slice_margins_ltrb']]
        p=DEST/'styles'/f"{e['name']}.tres";s=p.read_text().replace(e['file'],e['runtime_file'])
        import re
        for side,value in zip(['left','top','right','bottom'],e['slice_margins_ltrb']):
            s=re.sub('texture_margin_'+side+r' = [0-9.]+','texture_margin_'+side+' = '+str(float(value)),s)
        p.write_text(s)
m['logical_density_note']='skins/ contains HD sources; runtime/ contains native logical-size skins for standard Godot StyleBoxTexture. Margin units are runtime texture pixels. Icons remain HD.'
m['button_states']={'normal':'button_claim_orange','hover':'button_claim_orange_hover','pressed':'button_claim_orange_pressed','disabled':'button_claim_orange_disabled','countdown':'disabled style plus live HH:MM:SS text; no text baked in art'}
m['coupon_mapping']={'driver.pro':'coupon_driver_pro','driver.allstar':'coupon_driver_allstar','gear.standard':'coupon_gear_standard','gear.elite':'coupon_gear_elite'}
(DEST/'manifest.json').write_text(json.dumps(m,ensure_ascii=False,indent=2)+'\n')
print('COMPLETE',len(m['sprites']),'unique assets')
