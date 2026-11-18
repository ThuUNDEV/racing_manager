#!/usr/bin/env python3
"""Extract original demo pixels, matte foregrounds, and sharpen alpha-safe 2x assets.
Run with NumPy, Pillow and OpenCV. Does not modify gameplay or the source demos.
"""
from pathlib import Path
import json, hashlib, html, zipfile, shutil
import numpy as np
import cv2
from PIL import Image, ImageFilter, ImageDraw, ImageFont

_PORTRAIT_SESSION = None
ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'Design/Demos/SoftMiniature/approved'
OUT = ROOT / 'Design/AssetPacks/Soft_Miniature_UI_v1'
if (ROOT/'sources').is_dir():
    SOURCE=ROOT/'sources';OUT=ROOT
# Pixel rectangles x,y,width,height in the unmodified 887/888px-wide demos.
REGIONS = [
 ('icons','currency_cash','01-race.png',(279,10,86,71)),
 ('icons','currency_gem','01-race.png',(541,12,82,67)),
 ('icons','settings','01-race.png',(800,5,80,83)),
 ('icons','nav_race','06-shop.png',(37,1614,128,109)),
 ('icons','nav_bag','01-race.png',(218,1609,100,108)),
 ('icons','nav_team','01-race.png',(370,1609,140,87)),
 ('icons','nav_league','01-race.png',(565,1608,119,106)),
 ('icons','nav_shop','01-race.png',(744,1608,116,103)),
 ('equipment','engine','02-bag.png',(30,455,255,188)),
 ('equipment','tyre','02-bag.png',(326,467,245,193)),
 ('equipment','spoiler','02-bag.png',(615,473,248,185)),
 ('equipment','gearbox','02-bag.png',(32,899,246,168)),
 ('equipment','brake','02-bag.png',(327,898,247,174)),
 ('equipment','chassis','02-bag.png',(613,897,249,178)),
 ('icons','star_gold','02-bag.png',(142,680,43,42)),
 ('icons','star_locked','02-bag.png',(140,1440,36,38)),
 ('icons','ticket','01-race.png',(40,1402,137,111)),
 ('icons','currency_coins','05-league.png',(486,588,115,91)),
 ('icons','inventory_crate','02-bag.png',(26,325,155,120)),
 ('portraits','driver_an','03-drivers.png',(72,649,343,321)),
 ('portraits','driver_binh','03-drivers.png',(502,653,330,317)),
 ('portraits','driver_chi','03-drivers.png',(66,1190,352,296)),
 ('portraits','driver_lam','03-drivers.png',(502,1196,337,290)),
 ('portraits','driver_my','06-shop.png',(30,1292,185,303)),
 ('portraits','driver_lam_shop','06-shop.png',(465,1309,192,284)),
 ('icons','gift_red','03-drivers.png',(570,476,110,100)),
 ('icons','helmet_pit','03-drivers.png',(626,293,246,178)),
 ('icons','trophy_large','05-league.png',(17,360,224,180)),
 ('icons','speedometer','04-garage.png',(45,1033,164,125)),
 ('icons','rocket_acceleration','04-garage.png',(480,1034,137,126)),
 ('icons','stability_scales','04-garage.png',(480,1187,155,137)),
 ('cars','car_showroom','04-garage.png',(172,463,574,304)),
 ('illustrations','shop_starter','06-shop.png',(34,384,386,222)),
 ('illustrations','shop_income_x2','06-shop.png',(470,385,385,222)),
 ('illustrations','shop_no_ads','06-shop.png',(35,834,386,230)),
 ('illustrations','shop_combo','06-shop.png',(470,834,385,230)),
 ('scenes','garage_with_car','04-garage.png',(0,342,888,487)),
 ('hud','avatar_frame','01-race.png',(18,4,109,99)),
]


def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()


def trim_pad(im, padding=8):
    alpha=im.getchannel('A')
    bbox=alpha.point(lambda x:255 if x>6 else 0).getbbox()
    if not bbox: raise ValueError('Empty extraction')
    im=im.crop(bbox)
    out=Image.new('RGBA',(im.width+padding*2,im.height+padding*2))
    out.paste(im,(padding,padding))
    return out


def matte(crop, name):
    """GrabCut with bounded source-specific foreground/background scribbles, no regeneration."""
    if name.startswith('driver_'):
        from rembg import new_session, remove
        from scipy.ndimage import binary_fill_holes
        global _PORTRAIT_SESSION
        if _PORTRAIT_SESSION is None: _PORTRAIT_SESSION=new_session('u2netp')
        result=remove(crop,session=_PORTRAIT_SESSION,post_process_mask=True)
        alpha=np.asarray(result.getchannel('A')).copy()
        alpha[binary_fill_holes(alpha>128)]=255
        preserve=Image.new('L',crop.size,0);d=ImageDraw.Draw(preserve)
        if name=='driver_an':
            d.polygon([(106,33),(116,23),(143,15),(166,12),(177,18),(176,30),(152,43),(129,50),(109,47)],fill=255)
            d.polygon([(199,13),(211,13),(229,21),(235,32),(230,40),(210,35),(196,26)],fill=255)
        if name=='driver_my':
            d.polygon([(77,61),(88,42),(114,34),(140,42),(157,57),(158,69),(107,76)],fill=255)
        if name=='driver_lam_shop':
            d.ellipse((45,19,94,48),fill=255)
            d.ellipse((112,18,143,43),fill=255)
        alpha=np.maximum(alpha,np.asarray(preserve))
        result=crop.convert('RGBA');result.putalpha(Image.fromarray(alpha))
        return trim_pad(result,8)
    rgb=np.asarray(crop.convert('RGB')).copy()
    h,w=rgb.shape[:2]
    mask=np.full((h,w),cv2.GC_PR_FGD,np.uint8)
    edge=max(2,round(min(w,h)*.012))
    mask[:edge]=mask[-edge:]=cv2.GC_BGD
    mask[:,:edge]=mask[:,-edge:]=cv2.GC_BGD
    # Establish a background ring and foreground core without cutting out light-colored details.
    mask[edge:max(edge+1,int(h*.07)),edge:-edge]=cv2.GC_PR_BGD
    mask[max(edge,h-int(h*.07)):-edge,edge:-edge]=cv2.GC_PR_BGD
    cv2.ellipse(mask,(w//2,h//2),(max(2,int(w*.13)),max(2,int(h*.13))),0,0,360,cv2.GC_FGD,-1)
    if name.startswith('driver_'):
        # The source circle backplates are blue; preserve the torso through explicit center seeds.
        hsv=cv2.cvtColor(rgb,cv2.COLOR_RGB2HSV)
        blue=(hsv[:,:,0]>85)&(hsv[:,:,0]<110)&(hsv[:,:,1]>35)&(hsv[:,:,2]>150)
        # Only the upper/lateral backdrop is forced out, never blue suits inside the body.
        yy,xx=np.mgrid[:h,:w]
        outside=(xx<w*.13)|(xx>w*.9)|((yy<h*.42)&((xx<w*.24)|(xx>w*.82)))
        mask[blue&outside]=cv2.GC_BGD
        # Exclude the nameplates/status bars adjacent to the head crop.
        if name in ['driver_an','driver_binh']:
            mask[:20,:int(w*.39)]=cv2.GC_BGD
        if name in ['driver_chi','driver_lam']:
            mask[:16,:int(w*.38)]=cv2.GC_BGD
    if name=='car_showroom':
        points=np.array([(10,155),(44,119),(143,76),(220,21),(355,5),(486,5),(541,21),(542,68),(502,87),(526,129),(568,179),(555,247),(511,289),(448,294),(405,265),(270,301),(137,298),(53,280),(11,247)],np.int32)
        silhouette=np.zeros((h,w),np.uint8)
        cv2.fillPoly(silhouette,[points],1)
        mask[:]=cv2.GC_BGD
        mask[silhouette>0]=cv2.GC_PR_FGD
        core=cv2.erode(silhouette,np.ones((11,11),np.uint8))
        mask[core>0]=cv2.GC_FGD
    if name in ['settings','nav_race','nav_league']:
        hsv=cv2.cvtColor(rgb,cv2.COLOR_RGB2HSV)
        backdrop=(hsv[:,:,0]>85)&(hsv[:,:,0]<120)&(hsv[:,:,1]>75)&(hsv[:,:,2]>160)
        mask[backdrop]=cv2.GC_BGD
    if name=='car_showroom':
        hsv=cv2.cvtColor(rgb,cv2.COLOR_RGB2HSV);yy,xx=np.mgrid[:h,:w]
        floor=(hsv[:,:,0]>85)&(hsv[:,:,0]<120)&(hsv[:,:,1]>35)&(yy>h*.65)&(xx>w*.65)
        mask[floor]=cv2.GC_BGD
    if name=='car_showroom':
        cv2.fillPoly(mask,[np.array([(352,277),(467,246),(467,h-1),(352,h-1)],np.int32)],cv2.GC_BGD)
        mask[245:,560:]=cv2.GC_BGD
    if name=='helmet_pit':
        cv2.fillPoly(mask,[np.array([(27,39),(47,27),(73,28),(102,40),(119,58),(110,62),(84,47),(52,40),(28,48)],np.int32)],cv2.GC_FGD)
    cv2.setRNGSeed(471)
    cv2.grabCut(cv2.cvtColor(rgb,cv2.COLOR_RGB2BGR),mask,None,np.zeros((1,65),np.float64),np.zeros((1,65),np.float64),7,cv2.GC_INIT_WITH_MASK)
    binary=np.where((mask==cv2.GC_FGD)|(mask==cv2.GC_PR_FGD),255,0).astype(np.uint8)
    # Remove detached dust; preserve useful secondary parts of a multi-object icon.
    n,labels,stats,_=cv2.connectedComponentsWithStats(binary,8)
    minimum=max(7,int(h*w*.003))
    for i in range(1,n):
        if stats[i,cv2.CC_STAT_AREA]<minimum: binary[labels==i]=0
    # Anti-alias a narrow edge, without softening the entire foreground.
    alpha=cv2.GaussianBlur(binary,(3,3),.55)
    alpha[binary==255]=255
    if name=='car_showroom':
        hsv=cv2.cvtColor(rgb,cv2.COLOR_RGB2HSV);yy,xx=np.mgrid[:h,:w]
        alpha[(xx>w*.94)&(hsv[:,:,0]>85)&(hsv[:,:,0]<120)&(hsv[:,:,1]>35)]=0
    result=np.dstack((rgb,alpha))
    result[alpha==0,:3]=0
    return trim_pad(Image.fromarray(result),8)


def sharpen_2x(im):
    # Premultiplied-alpha resize prevents white/black fringes around transparent silhouettes.
    resized=im.convert('RGBa').resize((im.width*2,im.height*2),Image.Resampling.LANCZOS).convert('RGBA')
    alpha=resized.getchannel('A')
    rgb=resized.convert('RGB').filter(ImageFilter.UnsharpMask(radius=1.15,percent=115,threshold=3))
    rgb.putalpha(alpha)
    arr=np.asarray(rgb).copy();arr[arr[:,:,3]==0,:3]=0
    return Image.fromarray(arr)


def export_asset(category,name,im,record,entries):
    native=OUT/'native'/category/(name+'.png')
    hd=OUT/'png_2x'/category/(name+'.png')
    native.parent.mkdir(parents=True,exist_ok=True);hd.parent.mkdir(parents=True,exist_ok=True)
    im.save(native,optimize=True)
    scaled=sharpen_2x(im);scaled.save(hd,optimize=True)
    alpha=im.getchannel('A')
    entries[name]={**record,'category':category,'native':str(native.relative_to(OUT)),'png_2x':str(hd.relative_to(OUT)),'native_size':list(im.size),'size_2x':list(scaled.size),'transparent':alpha.getextrema()[0]<255,'sha256':sha(hd)}


def contact_sheet(entries):
    font_path=ROOT/'assets/clean_modern/fonts/Roboto-Bold.ttf'
    font=ImageFont.truetype(str(font_path),16) if font_path.exists() else ImageFont.load_default(size=16)
    for group in ['icons','equipment','portraits','cars','illustrations','scenes','skins','hud']:
        group_entries=[(n,e) for n,e in entries.items() if e['category']==group]
        if not group_entries: continue
        cols=4;cw,ch=280,248;rows=(len(group_entries)+cols-1)//cols
        sheet=Image.new('RGB',(cols*cw,rows*ch),'#edf2f3');d=ImageDraw.Draw(sheet)
        for i,(name,e) in enumerate(group_entries):
            x,y=(i%cols)*cw,(i//cols)*ch
            # A checkerboard exposes alpha and accidental background remnants.
            for yy in range(y+8,y+209,12):
                for xx in range(x+8,x+cw-8,12):
                    d.rectangle((xx,yy,min(xx+11,x+cw-9),min(yy+11,y+208)),fill='#ffffff' if ((xx-x)//12+(yy-y)//12)%2 else '#dce6e8')
            im=Image.open(OUT/e['png_2x']).convert('RGBA');im.thumbnail((244,184),Image.Resampling.LANCZOS)
            sheet.paste(im,(x+(cw-im.width)//2,y+12+(184-im.height)//2),im)
            d.text((x+12,y+215),name,font=font,fill='#29495c')
        sheet.save(OUT/f'preview_{group}.png')


def write_catalog(entries):
    groups=''.join(f'<button data-filter="{g}">{g}</button>' for g in sorted(set(e['category'] for e in entries.values())))
    figures=''
    for name,e in entries.items():
        figures+=f'<figure data-group="{e["category"]}"><a href="{e["png_2x"]}" target="_blank"><img loading="lazy" src="{e["png_2x"]}" alt="{name}"></a><figcaption><b>{html.escape(name)}</b><small>{e["size_2x"][0]} × {e["size_2x"][1]} · {"alpha" if e["transparent"] else "opaque"}</small><a download href="{e["native"]}">Gốc</a> · <a download href="{e["png_2x"]}">PNG 2×</a></figcaption></figure>'
    doc='''<!doctype html><html lang="vi"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Soft Miniature · Asset Kit</title><style>body{margin:24px;font:14px system-ui;color:#233f52;background:#f4f5f1}header{max-width:1000px}h1{font-size:25px}nav{display:flex;flex-wrap:wrap;gap:7px;margin:18px 0}button{padding:9px 13px;border:1px solid #bfcdd0;border-radius:8px;background:white;color:#233f52;cursor:pointer}button.on{background:#337b9e;color:white}main{display:grid;grid-template-columns:repeat(auto-fit,minmax(210px,1fr));gap:14px}figure{margin:0;border:1px solid #d0dcdd;border-radius:12px;overflow:hidden;background:white}figure>a{display:flex;align-items:center;justify-content:center;height:210px;padding:14px;background:repeating-conic-gradient(#e1e9eb 0% 25%,#fff 0% 50%) 50% /20px 20px}body.dark figure>a{background:repeating-conic-gradient(#263741 0% 25%,#344650 0% 50%) 50% /20px 20px}img{max-width:100%;max-height:190px;object-fit:contain}figcaption{padding:12px}small{display:block;color:#738790;margin:5px 0}a{color:#2f7799}figure[hidden]{display:none}</style><header><h1>Soft Miniature · Bộ asset đã tách</h1><p>Cắt trực tiếp từ 6 demo; bản PNG 2× làm nét giữ alpha. Nền UI che chữ được phục hồi riêng bằng ImageGen, ghi rõ trong manifest. Chưa tích hợp vào game.</p><nav><button class="on" data-filter="all">Tất cả</button>'''+groups+'''<button id="dark">Đổi nền kiểm tra alpha</button></nav></header><main>'''+figures+'''</main><script>document.querySelectorAll('[data-filter]').forEach(b=>b.onclick=()=>{document.querySelectorAll('[data-filter]').forEach(x=>x.classList.toggle('on',x===b));document.querySelectorAll('figure').forEach(x=>x.hidden=b.dataset.filter!=='all'&&x.dataset.group!==b.dataset.filter)});document.getElementById('dark').onclick=()=>document.body.classList.toggle('dark');</script></html>'''
    (OUT/'catalog.html').write_text(doc)


def godot_resources(entries):
    heights={'button_orange':48,'button_blue':48,'button_disabled':48,'panel_upgrade':96,'panel_inventory':144,'panel_inventory_selected':144,'section_blue':36,'navigation_tray':62,'hud_resource':38,'badge_mint':28,'badge_blue':28,'segmented_tray':44}
    for name,height in heights.items():
        if name not in entries: continue
        e=entries[name];im=Image.open(OUT/e['native']).convert('RGBA')
        scale=height/im.height;width=round(im.width*scale)
        texture=im.convert('RGBa').resize((width,height),Image.Resampling.LANCZOS).convert('RGBA')
        relative='godot_textures/skins/'+name+'.png'
        path=OUT/relative;path.parent.mkdir(parents=True,exist_ok=True);texture.save(path)
        margin=min(round(e['nine_slice_radius_native']*scale)+3,(height-1)//2)
        padding=6 if height<=48 else 10
        resource='[gd_resource type="StyleBoxTexture" load_steps=2 format=3]\n\n'
        resource+='[ext_resource type="Texture2D" path="res://assets/soft_miniature_ui_v1/'+relative+'" id="1"]\n\n'
        resource+='[resource]\ntexture = ExtResource("1")\n'
        for side in ['left','top','right','bottom']:
            resource+=f'texture_margin_{side} = {margin}.0\ncontent_margin_{side} = {padding}.0\n'
        (OUT/'godot_styles'/(name+'.tres')).write_text(resource)
        e['godot_texture']=relative;e['godot_style']='godot_styles/'+name+'.tres';e['nine_patch_ltrb_logical']=[margin]*4
        assert margin*2<height and margin*2<width, name


def main():
    for folder in ['crops_original','sources','native','png_2x','godot_styles']:(OUT/folder).mkdir(parents=True,exist_ok=True)
    sources={n:Image.open(SOURCE/n).convert('RGBA') for n in sorted(set(x[2] for x in REGIONS))}
    for n in sources:
        if (SOURCE/n).resolve() != (OUT/'sources'/n).resolve(): shutil.copy2(SOURCE/n,OUT/'sources'/n)
    entries={}
    for obsolete in ['native/scenes/harbor_track_with_demo_overlays.png','png_2x/scenes/harbor_track_with_demo_overlays.png']:
        (OUT/obsolete).unlink(missing_ok=True)
    for category,name,source,rect in REGIONS:
        x,y,w,h=rect;crop=sources[source].crop((x,y,x+w,y+h))
        raw=OUT/'crops_original'/(name+'.png');crop.save(raw)
        record={'method':'direct_crop_u2net_mask_refined' if category=='portraits' else 'direct_crop' if category in ['illustrations','scenes','hud'] else 'direct_crop_grabcut','source':'sources/'+source,'source_rect_xywh':list(rect),'source_sha256':sha(SOURCE/source),'raw_crop':str(raw.relative_to(OUT))}
        im=crop if category in ['illustrations','scenes','hud'] else matte(crop,name)
        export_asset(category,name,im,record,entries)
        print('EXPORTED',name,im.size,flush=True)
    # Optional restored text-free skins generated from these same demo screenshots.
    skin_sheet=OUT/'sources/ui_skins_restored.png'
    if skin_sheet.exists():
        sheet=Image.open(skin_sheet).convert('RGBA')
        skins=[
            ('button_orange',(17,137,327,109),52),('button_blue',(380,138,329,108),52),('button_disabled',(746,137,323,109),52),
            ('panel_upgrade',(15,481,334,157),40),('panel_inventory',(409,395,270,305),43),('panel_inventory_selected',(771,396,274,305),43),
            ('section_blue',(15,859,333,94),44),('navigation_tray',(376,837,338,139),33),('hud_resource',(746,852,324,111),53),
            ('badge_mint',(18,1223,326,105),50),('badge_blue',(380,1223,328,104),50),('segmented_tray',(743,1223,332,104),50)]
        for name,(x,y,w,h),radius in skins:
            crop=sheet.crop((x,y,x+w,y+h)).convert('RGB')
            # The generated sheet contains low-opacity canvas haze. A fitted geometric
            # mask removes that canvas without deleting the near-white card faces.
            mask=Image.new('L',(w*4,h*4),0);draw=ImageDraw.Draw(mask)
            draw.rounded_rectangle((4,4,w*4-4,h*4-8),radius=radius*4,fill=255)
            mask=mask.resize((w,h),Image.Resampling.LANCZOS)
            crop.putalpha(mask)
            im=trim_pad(crop)
            export_asset('skins',name,im,{'method':'imagegen_restored_from_demo_masked','source':'sources/ui_skins_restored.png','source_rect_xywh':[x,y,w,h],'source_sha256':sha(skin_sheet),'nine_slice_radius_native':radius},entries)
    for scene_name,dimensions in [('harbor_background_clean',(887,490)),('garage_background_empty',(888,488))]:
        path=OUT/'sources'/(scene_name+'.png')
        if not path.exists(): continue
        restored=Image.open(path).convert('RGBA')
        native=restored.resize(dimensions,Image.Resampling.LANCZOS)
        export_asset('scenes',scene_name,native,{'method':'imagegen_restored_from_demo','source':'sources/'+path.name,'source_sha256':sha(path),'note':'Restored high-resolution 2D artwork; generated detail may differ slightly from crop.'},entries)
        hd=restored.resize((dimensions[0]*2,dimensions[1]*2),Image.Resampling.LANCZOS).filter(ImageFilter.UnsharpMask(radius=.7,percent=60,threshold=3))
        hd.save(OUT/entries[scene_name]['png_2x'],optimize=True)
        entries[scene_name]['sha256']=sha(OUT/entries[scene_name]['png_2x'])
    manifest={'version':1,'source_demo':'Soft_Miniature_Review_v2','upscale':'2x Lanczos in premultiplied alpha; RGB unsharp mask radius1.15 amount115 threshold3; alpha not sharpened','assets':entries}
    (OUT/'manifest.json').write_text(json.dumps(manifest,indent=2,ensure_ascii=False)+'\n')
    godot_resources(entries)
    (OUT/'manifest.json').write_text(json.dumps(manifest,indent=2,ensure_ascii=False)+'\n')
    contact_sheet(entries);write_catalog(entries)
    print(json.dumps({'asset_count':len(entries),'out':str(OUT)},indent=2))

if __name__=='__main__': main()
