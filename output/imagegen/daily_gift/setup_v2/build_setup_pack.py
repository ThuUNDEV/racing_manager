from PIL import Image,ImageDraw,ImageFont,ImageFilter,ImageChops
from pathlib import Path
from collections import deque
import urllib.request,json,io,shutil,zipfile
ROOT=Path(__file__).resolve().parent
BASE='http://192.168.11.181:8790'
for d in ['skins','icons','godot']: (ROOT/d).mkdir(exist_ok=True)
atlas=Image.open(ROOT/'clean_skin_atlas.png').convert('RGBA')
names=['panel_cream','header_cyan','card_normal','card_today','card_claimed','panel_grand','button_claim_orange','badge_claimed_green','badge_today_gold','pill_counter_cyan','pill_hint_cyan','progress_track','progress_fill','milestone_empty','milestone_claimed','button_close']
def post(path,data,ctype):
    req=urllib.request.Request(BASE+path,data=data,headers={'Content-Type':ctype,'Accept':'application/json, text/event-stream'})
    with urllib.request.urlopen(req,timeout=60) as r:return json.loads(r.read())
def largest_mask(alpha):
    w,h=alpha.size;data=alpha.tobytes();visited=bytearray(w*h);best=[]
    for start in range(w*h):
        if visited[start] or data[start]<180:continue
        q=deque([start]);visited[start]=1;comp=[]
        while q:
            p=q.popleft();comp.append(p);x=p%w;y=p//w
            for n in ([p-1] if x else [])+([p+1] if x<w-1 else [])+([p-w] if y else [])+([p+w] if y<h-1 else []):
                if not visited[n] and data[n]>=180:visited[n]=1;q.append(n)
        if len(comp)>len(best):best=comp
    pixels=bytearray(w*h)
    for p in best:pixels[p]=255
    mask=Image.frombytes('L',(w,h),bytes(pixels))
    # Keep the connected sprite and a narrow anti-aliased boundary, discard stray generated specks.
    return mask.filter(ImageFilter.MaxFilter(5)).filter(ImageFilter.GaussianBlur(.5))
entries=[]
for i,name in enumerate(names):
    x0=round((i%4)*atlas.width/4);x1=round((i%4+1)*atlas.width/4)
    y0=round((i//4)*atlas.height/4);y1=round((i//4+1)*atlas.height/4)
    crop=atlas.crop((x0,y0,x1,y1));raw=io.BytesIO();crop.save(raw,format='PNG')
    upload=post('/upload',raw.getvalue(),'application/octet-stream')
    response=post('/mcp',json.dumps({'jsonrpc':'2.0','id':i+100,'method':'tools/call','params':{'name':'remove_background','arguments':{'image':upload['file_id'],'refine':True,'trim':False}}}).encode(),'application/json')
    if response.get('error') or response['result'].get('isError'):raise RuntimeError(str(response)[:300])
    meta=next(json.loads(c['text']) for c in response['result']['content'] if c['type']=='text')
    with urllib.request.urlopen(meta['download_url'],timeout=60) as r:sprite=Image.open(io.BytesIO(r.read())).convert('RGBA')
    alpha=sprite.getchannel('A');sprite.putalpha(ImageChops.darker(alpha,largest_mask(alpha)))
    bbox=sprite.getchannel('A').point(lambda a:255 if a>12 else 0).getbbox()
    assert bbox,name
    sprite=sprite.crop(bbox)
    padded=Image.new('RGBA',(sprite.width+8,sprite.height+8));padded.paste(sprite,(4,4));sprite=padded
    sprite.save(ROOT/'skins'/f'{name}.png')
    w,h=sprite.size
    margins=[min(34,w//3),min(30,h//3),min(34,w//3),min(30,h//3)]
    if name in ['header_cyan','button_claim_orange','badge_claimed_green','badge_today_gold','pill_counter_cyan','pill_hint_cyan','progress_track','progress_fill']:
        margins=[min(w//3,h//2),max(4,h//3),min(w//3,h//2),max(4,h//3)]
    stretch=not name.startswith('milestone_') and name!='button_close'
    e={'name':name,'file':f'skins/{name}.png','size':[w,h],'alpha':list(sprite.getchannel('A').getextrema()),'slice_margins_ltrb':margins if stretch else None,'mcp_tool':'art-tools.remove_background','blank_skin':name not in ['milestone_claimed','button_close']}
    entries.append(e)
    if stretch:
        l,t,r,b=margins
        texture_path='res://'+str((ROOT/'skins'/f'{name}.png').relative_to(Path.cwd()))
        (ROOT/'godot'/f'{name}.tres').write_text(f'''[gd_resource type="StyleBoxTexture" load_steps=2 format=3]

[ext_resource type="Texture2D" path="{texture_path}" id="1"]

[resource]
texture = ExtResource("1")
texture_margin_left = {float(l)}
texture_margin_top = {float(t)}
texture_margin_right = {float(r)}
texture_margin_bottom = {float(b)}
''')
    print(name,sprite.size,flush=True)
old=ROOT.parent/'sprites_v1'/'icons'
# Reward artwork only; UI states are supplied by the new clean skins.
for path in sorted(old.glob('*.png')):
    if path.stem.startswith('milestone_node') or path.stem=='close_red':continue
    sprite=Image.open(path).convert('RGBA');sprite.putalpha(ImageChops.darker(sprite.getchannel('A'),largest_mask(sprite.getchannel('A'))));bbox=sprite.getchannel('A').getbbox();sprite=sprite.crop(bbox)
    canvas=Image.new('RGBA',(sprite.width+8,sprite.height+8));canvas.paste(sprite,(4,4));canvas.save(ROOT/'icons'/path.name)
    entries.append({'name':path.stem,'file':'icons/'+path.name,'size':list(canvas.size),'alpha':list(canvas.getchannel('A').getextrema()),'mcp_tool':'art-tools.remove_background','source':'original concept sprite crop'})
manifest={'source_concept':'../daily_gift_concept_v1.png','skin_source':'clean_skin_atlas.png','description':'Setup-ready separate transparent sprites. Skins have reconstructed blank surfaces; localized text must be live Godot Labels.','sprites':entries}
(ROOT/'manifest.json').write_text(json.dumps(manifest,indent=2,ensure_ascii=False)+'\n')
font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',14)
cols=4;cw,ch=260,220
sheet=Image.new('RGB',(cols*cw,((len(entries)+cols-1)//cols)*ch),(235,238,243));draw=ImageDraw.Draw(sheet)
for i,e in enumerate(entries):
    x=i%cols*cw;y=i//cols*ch
    for yy in range(y,y+185,12):
        for xx in range(x,x+cw,12):draw.rectangle((xx,yy,xx+11,yy+11),fill=(208,214,223) if ((xx-x)//12+(yy-y)//12)%2 else (246,247,249))
    sprite=Image.open(ROOT/e['file']).convert('RGBA');sprite.thumbnail((240,170));sheet.paste(sprite,(x+(cw-sprite.width)//2,y+(180-sprite.height)//2),sprite)
    draw.text((x+8,y+190),e['name'],font=font,fill=(20,35,55))
sheet.save(ROOT/'setup_sprites_contact_sheet.png')
(ROOT/'SETUP_GODOT.md').write_text('''# Daily Gift — bộ sprite để setup Godot

- `skins/`: 16 PNG RGBA rời; khung/card/button/badge đã bỏ chữ và icon thưởng. Nút đóng có X và mốc đã nhận có tick.
- `icons/`: 18 PNG icon thưởng và dấu tick đã tách nền từ concept gốc.
- `godot/`: 13 StyleBoxTexture `.tres` có sẵn lề 9-slice ban đầu. Các nút mốc tròn và nút đóng dùng TextureRect/TextureButton.
- `manifest.json`: kích thước và lề 9-slice theo thứ tự trái, trên, phải, dưới.

## Cách ráp

1. Dùng `panel_cream.tres` cho PanelContainer ngoài; header dùng `header_cyan.tres`.
2. GridContainer 3 cột, 2 hàng: mỗi PanelContainer dùng `card_normal`, `card_today` hoặc `card_claimed`.
3. Đặt icon thưởng trong TextureRect với STRETCH_KEEP_ASPECT_CENTERED, chữ ngày/số lượng dùng Label riêng.
4. `badge_today_gold` / `badge_claimed_green` là nền trống cho Label HÔM NAY / ĐÃ NHẬN.
5. `panel_grand` là nền quà ngày 7; gắn gift_grand, gem và driver bên trên bằng các TextureRect riêng.
6. Thanh tích lũy dùng progress_track/progress_fill và các milestone; số ngày dùng Label động.
7. Nút nhận dùng button_claim_orange.tres cho theme normal; gift_claim là icon riêng; NHẬN QUÀ là Label.
8. `button_close.png` làm texture_normal của TextureButton. Tạo vùng bấm tối thiểu 48px.

Các `.tres` tham chiếu vị trí hiện tại trong dự án. Nếu chuyển bộ sprite sang `assets/`, hãy cập nhật texture path. Lề 9-slice là gợi ý ban đầu, điều chỉnh theo kích thước hiển thị. Đây là bộ art setup, chưa thay UI runtime.

Khung trống được tái tạo bằng ImageGen từ ảnh concept phẳng, rồi cắt/tách nền bằng MCP art-tools và làm sạch alpha; không phải khôi phục layer gốc 1:1. Icon thưởng giữ art concept ban đầu.
''')
zip_path=ROOT.parent/'daily_gift_setup_v2.zip'
with zipfile.ZipFile(zip_path,'w',zipfile.ZIP_DEFLATED) as z:
    for p in ROOT.rglob('*'):
        if p.is_file():z.write(p,p.relative_to(ROOT.parent))
print('DONE',len(entries),'sprites',zip_path,flush=True)
