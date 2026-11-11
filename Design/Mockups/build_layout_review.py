"""Build design-only asset backlog and inline review. Never changes game data."""
from pathlib import Path
from io import BytesIO
import base64
import csv
import json
import re
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
DEST = Path(r'C:\Users\thupv\.codex\visualizations\2026\11\11\01a1c996-97d3-7031-a4bd-496e496e6bb3')

def catalog(name):
    return json.loads((ROOT / 'data' / name).read_text(encoding='utf-8-sig'))

rows = []
def add(num, name, key, priority, screen, size, fallback, brief):
    rows.append(dict(id=f'A{num:02}', name=name, data_id=key, priority=priority,
                     screens=screen, export_px=size, fallback=fallback, brief=brief,
                     status='Đề xuất; chưa sản xuất'))

for i,(key,name) in enumerate([('engine','Động cơ'),('tyre','Lốp'),('chassis','Khung gầm'),('gearbox','Hộp số')],1):
    add(i,name,key,'P0','L01;L06','512x512','HD energy/gear/crane/research (tạm)', 'Icon đúng vật thể; transparent; đọc ở 48px')
for i,(key,name) in enumerate([('ticket','Tiếp thị vé'),('celebration','Ăn mừng chiến thắng'),('parking','Bãi đỗ'),('grandstands','Khán đài')],5):
    add(i,name,key,'P1','L02;L08','768x512','HD cash/crown/garage/seats','Vignette 3/4; không chữ; đọc ở 64px')
for i,g in enumerate(catalog('gear.json')['items'],9):
    add(i,g['name'],g['id'],'P0','L03;L11','512x512','Tên món + placeholder trung tính','Một vật thể riêng; không rarity/level bake; silhouette sinh từ alpha')
for i,(key,name) in enumerate([('standard_gear_pack','Gói gear Standard'),('elite_gear_pack','Gói gear Elite'),('standard_coupon','Coupon Standard'),('elite_coupon','Coupon Elite')],39):
    add(i,name,key,'P0','L03;L09;L11','512x512','shop/icons/gear_crate.tres','Phân biệt bằng hình và nhãn UI; không chỉ màu')
for i,(key,name) in enumerate([('attack','Kiếm'),('defense','Khiên')],43):
    add(i,name,key,'P0','L03','256x256','Nhãn Kiếm/Khiên','Đọc ở 20–24px; không thêm công thức bonus')
drivers=catalog('drivers.json')['drivers']
for i,d in enumerate(drivers[3:],45):
    add(i,'Portrait '+d['name'],d['id'],'P0','L04;L11','512x512','Chữ đầu tên trong UI','Chân dung riêng; avatar crop mặt; khác silhouette')
for i,d in enumerate(drivers[:3],54):
    add(i,'Đồng bộ portrait '+d['name'],d['id'],'P2','L04;L11','512x512','workshop_gp/portraits/'+d['id']+'.tres','Đồng bộ nét/ánh sáng với HD; giữ nhận diện')
for i,key in enumerate(['inside','sweeper','counter','defender'],57):
    add(i,'Badge phong cách '+key,key,'P2','L04','256x256','Tên phong cách bằng chữ','Đọc ở 24px; không thay 7 chỉ số')
for i,name in enumerate(['Pico','Nova','Apex','Titan','Zenith'],61):
    add(i,'Thân xe '+name,'class_'+str(i-60),'P1','L01;L05;L06;L07','1024x640 + 256x256','HD icons/car_red.png; workshop_gp/cars/*.tres','3/4 neutral + top-down; mask sơn/decal; 3 biến thể mỗi hạng')
add(66,'Sàn showroom','showroom','P1','L05;L06;L07','1024x640','Gradient UI','Không xe/không chữ; không gắn bóng xe')
for i,d in enumerate(catalog('garage_cosmetics.json')['decals'][1:],67):
    add(i,'Decal '+d['name'],d['id'],'P1','L07;L01','512x512 + bản đua giản lược','Họa tiết vẽ bằng UI hiện tại','Mask alpha; anchor theo 5 thân; không bonus')
add(70,'Bóng xe dùng chung','car_shadow','P1','L05;L06;L07','512x256','Bóng UI','Alpha mềm; tách khỏi xe và sàn')
for i in range(71,76):
    add(i,'Cơ sở bậc '+str(i-70),'facility_tier_'+str(i-70),'P2','L08','768x480','Huy hiệu + tên bậc từ dữ liệu','Vignette tăng quy mô; không ám chỉ map mới')
for i,key in enumerate(['standard_driver_pack','elite_driver_pack'],76):
    add(i,'Gói tay đua '+key.split('_')[0],key,'P2','L04;L09;L11','512x512','shop/icons/driver_helmet.tres','Đồng bộ 2 gear pack; nhận diện hình riêng')
assert len(rows)==77
with (ROOT/'Design/18_Asset_Backlog.csv').open('w',encoding='utf-8-sig',newline='') as f:
    w=csv.DictWriter(f,fieldnames=list(rows[0])); w.writeheader(); w.writerows(rows)

hd='assets/racing_ui_hd/icons/'
resources={k:hd+v+'.png' for k,v in {'avatar':'avatar','gem':'gem','flag':'flag','tools':'tools','staff':'staff','trophy':'trophy','shop':'shop','car':'car_red','cash':'cash','energy':'energy','gear':'gear','crane':'crane','research':'research','seats':'seats','crown':'crown','garage':'garage'}.items()}
resources.update(track='assets/workshop_gp/textures/workshop_oval.png',portrait='assets/workshop_gp/portraits/driver_orange.png',gift='assets/workshop_gp/shop/icons/daily_reward.tres',crate='assets/workshop_gp/shop/icons/gear_crate.tres',money='assets/workshop_gp/shop/icons/cash_large.tres',helmet='assets/workshop_gp/shop/icons/driver_helmet.tres')
outdir=ROOT/'Design/Mockups/layout_review_assets';outdir.mkdir(exist_ok=True)
resolved={}
for key,path in resources.items():
    p=ROOT/path
    if p.suffix=='.tres':
        txt=p.read_text(encoding='utf-8-sig')
        atlas=re.search(r'path="res://([^"]+)"',txt).group(1)
        rect=[int(x.strip()) for x in re.search(r'Rect2\(([^)]+)\)',txt).group(1).split(',')]
        x,y,w,h=rect
        im=Image.open(ROOT/atlas).convert('RGBA').crop((x,y,x+w,y+h))
    else: im=Image.open(p).convert('RGBA')
    im.thumbnail((480,320) if key=='track' else (180,160))
    im.save(outdir/(key+'.webp'),quality=82,method=6)
    resolved[key]='layout_review_assets/'+key+'.webp'
htmlpath=ROOT/'Design/Mockups/layout_asset_redesign.html'
html=htmlpath.read_text(encoding='utf-8')
for key,path in resolved.items():
    html=html.replace('@@'+key+'@@',path).replace('layout_review_assets/'+key+'.png',path)
assert '@@' not in html
htmlpath.write_text(html,encoding='utf-8')
inline=html
for key,path in resolved.items():
    data=base64.b64encode((ROOT/'Design/Mockups'/path).read_bytes()).decode('ascii')
    inline=inline.replace(path,'data:image/webp;base64,'+data)
DEST.mkdir(parents=True,exist_ok=True)
(DEST/'pitlane-layout-review.html').write_text(inline,encoding='utf-8')
assert len(inline.encode('utf-8'))<1000000
# Extract JavaScript for syntax checking without needing a browser.
(outdir/'review-script.js').write_text(re.search(r'<script>(.*?)</script>',html,re.S).group(1),encoding='utf-8')
print(json.dumps({'backlog':len(rows),'priorities':{p:sum(r['priority']==p for r in rows) for p in ['P0','P1','P2']},'inline_bytes':len(inline.encode('utf-8')),'images':len(resources)},ensure_ascii=False))
