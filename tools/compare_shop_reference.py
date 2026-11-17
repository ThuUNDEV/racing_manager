#!/usr/bin/env python3
"""Pair the source with native real-main captures at 390px. Run capture fixture first."""
from pathlib import Path
from PIL import Image,ImageDraw
import json
ROOT=Path(__file__).resolve().parent.parent
OUT=ROOT/'Design/Previews'
meta=json.loads((OUT/'shop_match_geometry.json').read_text())['390']
ref=Image.open(ROOT/'assets/shop_blue_white/demo_reference.png').convert('RGB')
shot=Image.open(OUT/'shop_match_390_full.png').convert('RGB')
blocks=meta['blocks'];unit=meta['shop_width']/550

def runtime(name,bleed_top=0,bleed_left=0):
 x,y,w,h=blocks[name]
 if not name.startswith('Offer_'): x=meta['shop_x']
 return shot.crop((round(x-bleed_left*unit),round(y-bleed_top*unit),round(x+w),round(y+h)))
def pair(name,source,actual):
 left=ref.crop(source);left=left.resize((actual.width,round(left.height*actual.width/left.width)),Image.Resampling.LANCZOS)
 # Both keep their measured aspect ratio. Any extra height is visible, not normalized away.
 canvas=Image.new('RGB',(actual.width*2+30,max(left.height,actual.height)+28),'#e8f4fd');d=ImageDraw.Draw(canvas)
 d.text((8,5),'REFERENCE',fill='#102d60');d.text((actual.width+22,5),'REAL MAIN 390px',fill='#102d60')
 canvas.paste(left,(5,25));canvas.paste(actual,(actual.width+20,25));canvas.save(OUT/f'shop_match_{name}.png')

pair('1_starter',(22,260,576,466),runtime('Offer_starter_1',14,8))
pair('2_income',(30,476,576,622),runtime('Offer_income_x2'))
pair('3_no_ads',(30,632,576,755),runtime('Offer_no_ads'))
x,y,w,h=blocks['Offer_char_my'];x2,y2,w2,h2=blocks['Offer_char_lam']
pair('4_drivers',(30,814,576,1095),shot.crop((round(x),round(y-10*unit),round(x+w),round(y2+h2))))
pair('5_gift',(30,1106,576,1202),runtime('DailyGiftBanner',4))
pair('6_free_gem',(621,211,1174,329),runtime('FreeGemBanner',9,4))
# Daily cards, gem grid, cash grid are separate comparisons within required block 6.
daily_names=['Offer_daily_gear','Offer_daily_driver']
x,y,w,h=blocks[daily_names[0]];x2,y2,w2,h2=blocks[daily_names[1]]
pair('6_daily',(625,394,1174,540),shot.crop((round(x),round(y),round(x2+w2),round(y+h))))
for name,rect,node in [('6_gems',(625,598,1174,930),'GemGrid'),('6_cash',(625,987,1174,1168),'CashGrid')]:
 x,y,w,h=blocks[node];pair(name,rect,shot.crop((round(meta['shop_x']),round(y-7*unit),round(meta['shop_x']+w),round(y+h))))
# Entire reference-shaped content, plus the remaining functional catalog, stays in *_full.png.
