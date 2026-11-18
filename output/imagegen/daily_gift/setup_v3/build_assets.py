from pathlib import Path
from PIL import Image,ImageEnhance,ImageOps
import urllib.request,json,io,shutil
ROOT=Path(__file__).resolve().parent
DEST=Path.cwd()/'assets/daily_gift_v3'
BASE='http://192.168.11.181:8790'
for d in ['skins','icons','styles','themes','fonts']: (DEST/d).mkdir(parents=True,exist_ok=True)
def post(path,data,ctype):
    q=urllib.request.Request(BASE+path,data=data,headers={'Content-Type':ctype,'Accept':'application/json, text/event-stream'})
    with urllib.request.urlopen(q,timeout=180) as r:return json.load(r)
def mcp_image(image_path,tool,**args):
    up=post('/upload',image_path.read_bytes(),'application/octet-stream')
    r=post('/mcp',json.dumps({'jsonrpc':'2.0','id':1,'method':'tools/call','params':{'name':tool,'arguments':{'image':up['file_id'],**args}}}).encode(),'application/json')
    if r.get('error') or r['result'].get('isError'):raise RuntimeError(str(r)[:500])
    meta=next(json.loads(c['text']) for c in r['result']['content'] if c['type']=='text')
    with urllib.request.urlopen(meta['download_url'],timeout=90) as response:return response.read()
old=json.loads((ROOT.parent/'setup_v2/manifest.json').read_text())
entries=[]
for e in old['sprites']:
    if not e['file'].startswith('skins/'):continue
    name=e['name'];p=DEST/'skins'/f'{name}.png'
    p.write_bytes(mcp_image(ROOT.parent/'setup_v2'/e['file'],'upscale',scale=2))
    with Image.open(p) as im:size=list(im.size)
    entry={'name':name,'file':f'skins/{name}.png','size':size,'origin':'v2 reconstructed skin; art-tools.upscale 2x','slice_margins_ltrb':[n*2 for n in e['slice_margins_ltrb']] if e['slice_margins_ltrb'] else None}
    # Preserve the entire checker accent in the fixed right edge.
    if name=='header_cyan':entry['slice_margins_ltrb']=[90,58,180,58]
    entries.append(entry)
    print('HD skin',name,size,flush=True)

def variant(name,base,mode):
    im=Image.open(DEST/'skins'/f'{base}.png').convert('RGBA');alpha=im.getchannel('A')
    if mode=='hover':rgb=ImageEnhance.Brightness(im.convert('RGB')).enhance(1.06)
    elif mode=='pressed':rgb=ImageEnhance.Brightness(im.convert('RGB')).enhance(.84)
    else:rgb=ImageOps.colorize(ImageOps.grayscale(im),black='#61798c',white='#d6e4ed')
    rgb.putalpha(alpha);rgb.save(DEST/'skins'/f'{name}.png')
    e=next(x for x in entries if x['name']==base)
    entries.append({'name':name,'file':f'skins/{name}.png','size':list(rgb.size),'origin':f'{base}: {mode} state','slice_margins_ltrb':e['slice_margins_ltrb']})
for base in ['button_claim_orange','button_close']:
    for state in ['hover','pressed','disabled']:variant(base+'_'+state,base,state)

def style(e):
    name=e['name'];l,t,r,b=e['slice_margins_ltrb']
    # Border widths are in source texels; display at half scale for 2x assets.
    contents=[12,8,12,8]
    if name.startswith('card_'):contents=[8,6,8,6]
    if name=='panel_cream':contents=[12,12,12,12]
    if name=='header_cyan':contents=[16,8,16,8]
    text=f'''[gd_resource type="StyleBoxTexture" load_steps=2 format=3]

[ext_resource type="Texture2D" path="res://assets/daily_gift_v3/{e['file']}" id="1"]

[resource]
texture = ExtResource("1")
texture_margin_left = {float(l)}
texture_margin_top = {float(t)}
texture_margin_right = {float(r)}
texture_margin_bottom = {float(b)}
axis_stretch_horizontal = 0
axis_stretch_vertical = 0
'''
    # scale border draw widths independently of source margins.
    text+=''+''.join(f'expand_margin_{side} = 0.0\n' for side in ['left','top','right','bottom'])
    text+=''+''.join(f'content_margin_{side} = {float(v)}\n' for side,v in zip(['left','top','right','bottom'],contents))
    # Godot StyleBoxTexture does not expose border_scale; texture margins must
    # remain small enough for a 320px three-column grid.
    (DEST/'styles'/f'{name}.tres').write_text(text)
for e in entries:
    if e['slice_margins_ltrb']:style(e)
shutil.copyfile('assets/clean_modern/fonts/Roboto-Bold.ttf',DEST/'fonts/Roboto-Bold.ttf')
# Actual Theme handles disabled countdown and pressed/hover states.
resources=['button_claim_orange','button_claim_orange_hover','button_claim_orange_pressed','button_claim_orange_disabled']
head='[gd_resource type="Theme" load_steps=6 format=3]\n\n'
for i,n in enumerate(resources,1):head+=f'[ext_resource type="StyleBox" path="res://assets/daily_gift_v3/styles/{n}.tres" id="{i}"]\n'
head+='[ext_resource type="FontFile" path="res://assets/daily_gift_v3/fonts/Roboto-Bold.ttf" id="5"]\n\n[resource]\n'
head+='Button/fonts/font = ExtResource("5")\nButton/font_sizes/font_size = 20\n'
for state,col in [('font_color','Color(1, 1, 1, 1)'),('font_hover_color','Color(1, 1, 1, 1)'),('font_pressed_color','Color(1, 1, 1, 1)'),('font_disabled_color','Color(0.12, 0.22, 0.32, 1)')]:head+=f'Button/colors/{state} = {col}\n'
for state,i in [('normal',1),('hover',2),('pressed',3),('hover_pressed',3),('disabled',4)]:head+=f'Button/styles/{state} = ExtResource("{i}")\n'
(DEST/'themes/claim_button.tres').write_text(head)
(DEST/'manifest.json').write_text(json.dumps({'version':3,'sprites':entries},indent=2)+'\n')
print('SKINS AND STATES COMPLETE',len(entries),flush=True)
