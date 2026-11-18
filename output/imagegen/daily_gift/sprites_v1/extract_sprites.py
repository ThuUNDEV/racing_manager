from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import urllib.request, json, io, zipfile

BASE='http://192.168.11.181:8790'
ROOT=Path(__file__).resolve().parent
SOURCE=ROOT.parent/'daily_gift_concept_v1.png'
im=Image.open(SOURCE).convert('RGBA')
manifest={'source':str(SOURCE),'source_size':list(im.size),'method':'Rectangle slicing; transparent art extracted with art-tools MCP remove_background, refine=true. Composite crops retain baked text/art.','sprites':[]}

def request(path,data,ctype):
    req=urllib.request.Request(BASE+path,data=data,headers={'Content-Type':ctype,'Accept':'application/json, text/event-stream'})
    with urllib.request.urlopen(req,timeout=60) as r:return r.read()

def export(name,box,category,alpha=False):
    crop=im.crop(box)
    folder=ROOT/category; folder.mkdir(exist_ok=True)
    out=folder/(name+'.png')
    entry={'name':name,'category':category,'source_rect_xywh':[box[0],box[1],box[2]-box[0],box[3]-box[1]],'file':str(out.relative_to(ROOT)),'transparent':alpha,'baked_content':category!='icons'}
    if alpha:
        raw=io.BytesIO();crop.save(raw,format='PNG')
        uploaded=json.loads(request('/upload',raw.getvalue(),'application/octet-stream'))
        payload={'jsonrpc':'2.0','id':len(manifest['sprites'])+10,'method':'tools/call','params':{'name':'remove_background','arguments':{'image':uploaded['file_id'],'refine':True,'trim':False,'pad':0}}}
        result=json.loads(request('/mcp',json.dumps(payload).encode(),'application/json'))
        if 'error' in result or result['result'].get('isError'):raise RuntimeError(str(result)[:500])
        meta=next(json.loads(c['text']) for c in result['result']['content'] if c['type']=='text')
        with urllib.request.urlopen(meta['download_url'],timeout=60) as r:out.write_bytes(r.read())
        entry['mcp_tool']='art-tools.remove_background'
        # Remove neighboring UI fragments retained by background segmentation.
        if name == 'close_red':
            cleaned=Image.open(out).convert('RGBA'); points=[]
            for y in range(cleaned.height):
                for x in range(cleaned.width):
                    r,g,b,a=cleaned.getpixel((x,y))
                    if 9<=x<=100 and 7<=y<=95 and a>100 and r>g*1.3 and r>b*1.2:points.append((x,y))
            def cross(o,a,b):return (a[0]-o[0])*(b[1]-o[1])-(a[1]-o[1])*(b[0]-o[0])
            points=sorted(set(points));lower=[];upper=[]
            for point in points:
                while len(lower)>=2 and cross(lower[-2],lower[-1],point)<=0:lower.pop()
                lower.append(point)
            for point in reversed(points):
                while len(upper)>=2 and cross(upper[-2],upper[-1],point)<=0:upper.pop()
                upper.append(point)
            mask=Image.new('L',cleaned.size);ImageDraw.Draw(mask).polygon(lower[:-1]+upper[:-1],fill=255)
            from PIL import ImageChops
            cleaned.putalpha(ImageChops.darker(cleaned.getchannel('A'),mask));cleaned.save(out)
            entry['cleanup']='Clip alpha to convex hull of red button; remove adjacent header fragments.'
        elif name.startswith('milestone_node_'):
            cleaned=Image.open(out).convert('RGBA');mask=Image.new('L',cleaned.size)
            if name=='milestone_node_check':bounds=(3,4,53,54)
            else:bounds=(4,5,49,50)
            ImageDraw.Draw(mask).ellipse(bounds,fill=255)
            from PIL import ImageChops
            cleaned.putalpha(ImageChops.darker(cleaned.getchannel('A'),mask));cleaned.save(out)
            entry['cleanup']='Clip alpha to circular node to remove adjoining progress bar.'
    else:crop.save(out)
    with Image.open(out) as saved:
        entry['size']=list(saved.size)
        entry['alpha_range']=list(saved.convert('RGBA').getchannel('A').getextrema())
    manifest['sprites'].append(entry)
    print(name,entry['size'],entry['alpha_range'],flush=True)

icons={
'gift_header':(141,45,284,194),'close_red':(827,84,932,184),
'day01_driver_pro':(163,345,324,437),'day02_gear_standard':(452,344,581,438),'day03_gem_today':(718,351,846,443),
'day04_driver_allstar':(166,607,325,695),'day05_gear_elite':(451,604,577,696),'day06_gem':(721,596,842,689),
'gift_grand':(162,803,360,982),'grand_gem':(466,822,568,900),'grand_driver_allstar':(663,820,800,900),
'milestone10_gem':(164,1175,239,1231),'milestone20_drivers':(358,1176,450,1230),'milestone30_gem':(540,1178,604,1228),'milestone30_drivers':(627,1179,699,1227),'milestone40_gem':(791,1174,865,1231),
'gift_claim':(274,1343,396,1460),'claimed_check_day01':(170,488,203,516),'claimed_check_day02':(439,489,472,517),
'milestone_node_check':(174,1086,234,1144),'milestone_node_empty20':(384,1085,438,1140),'milestone_node_empty30':(587,1085,642,1140),'milestone_node_empty40':(798,1084,852,1139),
}
for name,box in icons.items():export(name,box,'icons',True)
components={
'popup_complete':(60,37,964,1517),'header_complete':(94,45,935,207),'header_cyan_with_title':(97,69,925,204),
'counter_claimed_days':(364,246,660,295),
'day01_claimed_card':(107,300,379,545),'day02_claimed_card':(379,299,649,545),'day03_today_card':(648,298,918,545),
'day04_future_card':(108,544,378,753),'day05_future_card':(379,544,649,753),'day06_future_card':(649,543,918,753),
'day01_claimed_badge':(150,477,342,526),'day02_claimed_badge':(420,477,612,526),'today_badge':(691,477,880,526),
'grand_reward_complete':(93,757,930,1017),'grand_hint_pill':(380,944,781,987),
'cumulative_complete':(116,1024,915,1328),'cumulative_counter':(706,1026,911,1077),'cumulative_progress_complete':(171,1082,857,1146),
'milestone10_complete':(149,1143,277,1265),'milestone20_complete':(329,1143,484,1265),'milestone30_complete':(526,1143,720,1265),'milestone40_complete':(757,1143,890,1265),
'cumulative_hint_pill':(254,1278,770,1325),'claim_button_complete':(124,1332,899,1477),
'progress_track_empty_segment':(442,1101,586,1128),'progress_track_blue_segment':(235,1101,298,1128),
}
for name,box in components.items():export(name,box,'composites')
texts={
'header_title':(294,98,758,165),'subtitle':(237,210,788,246),'counter_text':(407,255,619,285),
'day01_label':(176,312,298,349),'day02_label':(447,312,572,349),'day03_label':(717,312,837,349),
'day01_reward':(180,440,305,474),'day02_reward':(422,440,607,474),'day03_reward':(740,440,830,474),
'day04_label':(177,560,300,597),'day05_label':(448,560,573,597),'day06_label':(718,560,840,597),
'day04_reward':(153,695,328,731),'day05_reward':(450,695,574,731),'day06_reward':(738,695,829,731),
'grand_title':(342,777,875,816),'grand_gem_amount':(465,898,577,934),'grand_driver_amount':(650,898,826,934),
'cumulative_title':(123,1027,424,1075),'claim_label':(421,1359,735,1434)
}
for name,box in texts.items():export(name,box,'text_crops')
(ROOT/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',13)
entries=manifest['sprites']; cellw,cellh=250,190; cols=5
sheet=Image.new('RGB',(cols*cellw,((len(entries)+cols-1)//cols)*cellh),(233,235,240));draw=ImageDraw.Draw(sheet)
for index,entry in enumerate(entries):
    x=(index%cols)*cellw;y=(index//cols)*cellh
    for yy in range(y,y+155,12):
        for xx in range(x,x+cellw,12):draw.rectangle((xx,yy,xx+11,yy+11),fill=(205,209,218) if ((xx-x)//12+(yy-y)//12)%2 else (245,245,247))
    sprite=Image.open(ROOT/entry['file']).convert('RGBA');sprite.thumbnail((230,140))
    sheet.paste(sprite,(x+(cellw-sprite.width)//2,y+(150-sprite.height)//2),sprite)
    draw.text((x+6,y+158),entry['name'],font=font,fill=(20,35,55))
    draw.text((x+6,y+175),entry['category'],font=font,fill=(60,75,90))
sheet.save(ROOT/'contact_sheet.png')
(ROOT/'README.md').write_text('''# Daily Gift concept sprite extraction v1

Source: `../daily_gift_concept_v1.png` (1024 × 1536).

- `icons/`: 23 individual art/icon PNGs with alpha extracted using the art-tools MCP `remove_background` tool, refine=true. Original crop dimensions and positions are preserved.
- `composites/`: 26 rectangle crops of UI components, cards, badges and groups. These retain their original background, baked labels and overlapping artwork; they are reference composites, not empty production skins.
- `text_crops/`: 20 raster label crops with the original background. Prefer live localized text in game.
- `manifest.json`: source rectangles, output dimensions, alpha checks and tool provenance.
- `contact_sheet.png`: visual inventory.
- `extract_sprites.py`: reproducible extraction script; requires Pillow and access to the art-tools server.

The source is one flattened concept image. Hidden pixels behind text/icons cannot be recovered by cropping or background removal. Empty panels/buttons would need a separate reconstruction pass.
''')
zip_path=ROOT.parent/'daily_gift_sprites_v1.zip'
with zipfile.ZipFile(zip_path,'w',zipfile.ZIP_DEFLATED) as z:
    for p in ROOT.rglob('*'):
        if p.is_file() and p.name!='test_team.png':z.write(p,p.relative_to(ROOT.parent))
print('DONE',len(entries),'sprites',zip_path,flush=True)
