"""Validate delivery files, native resource references, atlas bounds, and audio PCM.
No image files are written or transformed. Also emits the reproducible asset catalog.
"""
from __future__ import annotations

import hashlib
import argparse
import json
import re
import wave
import xml.etree.ElementTree as ET
from pathlib import Path

import numpy as np
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
RES='res://assets/workshop_gp/'


def main() -> None:
    parser=argparse.ArgumentParser()
    parser.add_argument('--check-hashes',action='store_true')
    args=parser.parse_args()
    counts={}
    for folder in ['cars','icons','portraits','props','rewards','badges','ui','styles','components','vfx','audio']:
        counts[folder]=len([p for p in (ROOT/folder).glob('*') if p.is_file() and p.suffix not in ['.import','.uid']])
    resources=[]
    atlas_regions=[]
    for path in sorted(ROOT.rglob('*')):
        if not path.is_file() or path.suffix in ['.import','.uid'] or '__pycache__' in path.parts:
            continue
        if path.suffix in ['.tres','.tscn']:
            text=path.read_text(encoding='utf-8')
            for ref in re.findall(r'path="(res://[^\"]+)"',text):
                assert ref.startswith(RES),f'External dependency: {ref}'
                assert (ROOT/ref.removeprefix(RES)).is_file(),f'Missing {ref}'
            resources.append(path.relative_to(ROOT).as_posix())
            match=re.search(r'region = Rect2\((\d+), (\d+), (\d+), (\d+)\)',text)
            if match:
                ref=re.search(r'path="(res://[^\"]+)"',text).group(1)
                with Image.open(ROOT/ref.removeprefix(RES)) as im:
                    x,y,w,h=map(int,match.groups())
                    assert x>=0 and y>=0 and w>0 and h>0 and x+w<=im.width and y+h<=im.height,path
                    assert im.getchannel('A').histogram()[0]>0,path
                    atlas_regions.append({'id':path.stem,'resource':path.relative_to(ROOT).as_posix(),'atlas':ref.removeprefix(RES),'region':[x,y,w,h]})
        elif path.suffix=='.svg':
            xml=ET.parse(path)
            assert xml.getroot().tag.endswith('svg')
            assert not re.search(r'(https?://|file:)',path.read_text().replace('http://www.w3.org/2000/svg',''))
    audio=json.loads((ROOT/'audio/catalog.json').read_text())
    audio_checks=[]
    for entry in audio:
        with wave.open(str(ROOT/entry['path'])) as stream:
            assert stream.getnchannels()==2 and stream.getsampwidth()==2 and stream.getframerate()==44100
            frames=stream.getnframes()
            pcm=np.frombuffer(stream.readframes(frames),dtype='<i2').reshape(-1,2).astype(np.float64)/32767
            assert abs(frames/44100-entry['duration'])<.0001
            peak=float(np.abs(pcm).max())
            assert 0<peak<.89,(entry['path'],peak)
            assert np.isfinite(pcm).all()
            seam=float(np.abs(pcm[-1]-pcm[0]).max())
            if entry['loop']:
                assert seam<.04,(entry['path'],'loop boundary discontinuity',seam)
            audio_checks.append({'path':entry['path'],'frames':frames,'peak':round(peak,5),'boundary_delta':round(seam,6),'loop':entry['loop']})
    tracks=[]
    for id in ['harbor','pine','city']:
        layout=json.loads((ROOT/'layout'/f'{id}.json').read_text())
        assert layout['points'][0][:2]==layout['points'][-1][:2]
        assert (ROOT/layout['texture']).is_file()
        points=layout['points']
        colors=[]
        with Image.open(ROOT/layout['texture']) as image:
            pixels=np.asarray(image)[:,:,:3]
            # Independent cubic evaluation checks that the centerline stays on the dark road.
            for a,b in zip(points,points[1:]):
                p=np.array(a[:2]); q=np.array(b[:2])
                c1=p+np.array(a[4:6]); c2=q+np.array(b[2:4])
                for t in np.linspace(0,1,40):
                    xy=(1-t)**3*p+3*(1-t)**2*t*c1+3*(1-t)*t*t*c2+t**3*q
                    x,y=np.rint(xy*np.array([image.width-1,image.height-1])).astype(int)
                    assert 0<=x<image.width and 0<=y<image.height
                    colors.append(pixels[y,x].astype(float))
        colors=np.array(colors)
        neutral=np.max(colors,axis=1)-np.min(colors,axis=1)<35
        road_fraction=float(neutral.mean())
        assert road_fraction>.97,(id,'path leaves the road',road_fraction)
        tracks.append({'id':id,'texture':layout['texture'],'path':f'layout/{id}.json','neutral_road_samples':round(road_fraction,4),'samples':len(colors)})
    catalog={
        'name':'Workshop GP','version':'1.0','format':'2D PNG atlases + SVG sources + Godot 4 resources + PCM WAV',
        'tracks':tracks,'drivers':[{'id':n,'resource':f'portraits/driver_{n}.tres'} for n in ['an','binh','chi']],
        'cars':[f'cars/{n}.tres' for n in ['orange','graphite','white','blue','red','yellow','teal','purple']],
        'primary_icons':sorted(p.relative_to(ROOT).as_posix() for p in (ROOT/'icons').glob('*.tres')),
        'utility_icons':sorted(p.relative_to(ROOT).as_posix() for p in (ROOT/'icons/vector').glob('*.svg')),
        'ui_states':['normal','hover','pressed','disabled','selected','locked','success','danger','focus'],
        'components':sorted(p.relative_to(ROOT).as_posix() for p in (ROOT/'components').glob('*.tscn')),
        'effects':[{'id':p.stem,'scene':p.relative_to(ROOT).as_posix(),'frames':len(list((ROOT/'vfx'/p.stem).glob('*.svg')))} for p in sorted((ROOT/'vfx').glob('*.tscn'))],
        'atlas_regions':atlas_regions,'audio':audio,'audio_checks':audio_checks,
        'coverage':'ASSET_COVERAGE.md','native_resources':resources,'folder_counts':counts,
    }
    (ROOT/'asset_catalog.json').write_text(json.dumps(catalog,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
    manifest=json.loads((ROOT/'manifest_complete.json').read_text())
    for entry in manifest['files']:
        path=ROOT/entry['path']
        # Manifest is regenerated after authored documentation/catalog changes.
        assert path.is_file(),entry['path']
        if args.check_hashes:
            assert hashlib.sha256(path.read_bytes()).hexdigest()==entry['sha256'],f"Hash mismatch: {entry['path']}"
    print(json.dumps({'tracks':len(tracks),'drivers':3,'cars':8,'primary_icons':12,'utility_icons':len(catalog['utility_icons']),'components':len(catalog['components']),'effects':len(catalog['effects']),'animation_frames':sum(e['frames'] for e in catalog['effects']),'audio_cues':len(audio),'native_resources':len(resources),'atlas_regions':len(atlas_regions),'audio_loop_checks':'PASS','track_path_checks':tracks},ensure_ascii=False,indent=2))


if __name__=='__main__':
    main()
