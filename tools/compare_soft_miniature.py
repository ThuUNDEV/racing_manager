#!/usr/bin/env python3
"""Demo left / actual captured Godot viewport right. No retouching game screenshots."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import argparse
ROOT=Path(__file__).resolve().parents[1]
DEMO=ROOT/'Design/Demos/SoftMiniature/approved';SHOTS=ROOT/'Design/Previews/Soft_Miniature_Integrated';OUT=SHOTS/'compare';OUT.mkdir(exist_ok=True)
parser=argparse.ArgumentParser();parser.add_argument('--stage',default='after');args=parser.parse_args()
font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',13)
for width,height in [(320,568),(390,778),(412,915)]:
 for name,runtime in [('01-race','tab_0'),('02-bag','tab_1'),('03-drivers','tab_2'),('04-garage','garage_0'),('05-league','tab_3'),('06-shop','tab_4')]:
  a=Image.open(DEMO/f'{name}.png').convert('RGB');a=a.resize((width,round(a.height*width/a.width)),Image.Resampling.LANCZOS)
  ref=Image.new('RGB',(width,height),'#e8f2f5');ref.paste(a,(0,0))
  b=Image.open(SHOTS/f'{width}_{runtime}.png').convert('RGB')
  c=Image.new('RGB',(width*2,height+24),'white');c.paste(ref,(0,24));c.paste(b,(width,24));d=ImageDraw.Draw(c);d.text((6,4),'DEMO - aspect preserved',font=font,fill='black');d.text((width+6,4),f'GAME {width}x{height} / {args.stage}',font=font,fill='black');c.save(OUT/f'{args.stage}-{width}-{name}.png')
print('Saved 18 scene comparisons.')
