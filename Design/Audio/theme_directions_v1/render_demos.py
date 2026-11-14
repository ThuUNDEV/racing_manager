"""Original instrumental sketches. Python + numpy/scipy; no external samples.

Run from any directory: python render_demos.py
Writes audition masters, a comparison reel and an HTML player beside this file.
These are arrangement demos, not replacements for the game's active music.
"""
from pathlib import Path
import json
import math
import numpy as np
from scipy import signal
from scipy.io import wavfile

SR = 44100
OUT = Path(__file__).resolve().parent
RNG = np.random.default_rng(141126)


def filt(x, hz, kind='lowpass'):
    return signal.sosfilt(signal.butter(2, hz, btype=kind, fs=SR, output='sos'), x)


def tone(note, duration, voice):
    n = max(32, int(duration * SR))
    t = np.arange(n) / SR
    f = 440 * 2 ** ((note - 69) / 12)
    if voice == 'bass':
        x = (np.sin(2*np.pi*f*t) + .28*np.sin(4*np.pi*f*t) + .13*np.sin(6*np.pi*f*t))
        env = (1-np.exp(-t*220))*np.exp(-t*3.8)
    elif voice == 'pluck':
        x = sum(np.sin(2*np.pi*f*k*t)*np.exp(-t*(3+k*1.8))/k for k in range(1, 7))
        env = (1-np.exp(-t*500))
    elif voice == 'keys':
        x = np.sin(2*np.pi*f*t + 1.6*np.sin(2*np.pi*f*2*t)*np.exp(-t*9))
        x += .18*np.sin(2*np.pi*f*3*t)*np.exp(-t*7)
        env = (1-np.exp(-t*300))*np.exp(-t*2.7)
    elif voice in ('guitar', 'rock'):
        # Damped string impulse response (fractional pitch via resampling).
        period = max(8, round(SR/f))
        excitation = RNG.uniform(-1, 1, period)
        excitation -= excitation.mean()
        string = np.zeros(n + period)
        string[:period] = excitation
        for i in range(period, len(string)):
            string[i] = .496*(string[i-period]+string[i-period+1])
        x = string[:n]
        if voice == 'rock':
            x = filt(np.tanh(x*7), 4600)
            env = (1-np.exp(-t*500))*np.exp(-t*2.2)
        else:
            x = filt(x, 6000)
            env = (1-np.exp(-t*700))*np.exp(-t*3)
    elif voice == 'pad':
        x = sum(np.sin(2*np.pi*f*(1+d)*t+p) for d,p in [(-.003,0),(.003,.4),(0,1.1)])/3
        x += .12*np.sin(4*np.pi*f*t)
        env = np.minimum(t/.1, 1)*np.exp(-t*.25)
    else:
        x = sum(np.sin(2*np.pi*f*k*t + .013*k*np.sin(2*np.pi*5*t))/k**1.6 for k in range(1, 7))
        env = (1-np.exp(-t*190))*np.exp(-t*1.8)
    env *= np.minimum((duration-t)/min(.09,duration/3), 1).clip(0)
    return (x*env).astype(np.float32)


def drum(kind):
    dur = {'kick':.42, 'snare':.25, 'clap':.2, 'hat':.095, 'open':.27, 'shaker':.065, 'crash':1.2, 'tom':.3}[kind]
    t = np.arange(int(SR*dur))/SR
    noise = RNG.normal(0, 1, len(t))
    if kind == 'kick':
        x = np.sin(2*np.pi*(48*t + (140-48)*.022*(1-np.exp(-t/.022))))*np.exp(-t*13)
        x += .12*filt(noise, 1800, 'highpass')*np.exp(-t*230)
    elif kind in ('snare','clap'):
        x = .65*filt(noise, 1400, 'highpass')*np.exp(-t*22)
        x += .32*np.sin(2*np.pi*185*t)*np.exp(-t*32)
        if kind == 'clap':
            x *= .5+.5*(np.sin(2*np.pi*90*t)>0)
    elif kind == 'tom':
        x = np.sin(2*np.pi*(110*t+3*(1-np.exp(-t*30))))*np.exp(-t*15)
    else:
        x = filt(noise, 6500, 'highpass')
        x *= np.exp(-t*({'hat':65,'open':15,'shaker':80,'crash':4}[kind]))
        if kind == 'crash':
            x += .16*sum(np.sin(2*np.pi*f*t) for f in [4211,6173,7829])*np.exp(-t*5)
    x *= np.minimum(t/.001,1)*np.minimum((dur-t)/.015,1)
    return x.astype(np.float32)


class Mix:
    def __init__(self, bpm):
        self.beat = 60/bpm
        self.duration = 80*self.beat+1.4
        self.dry = np.zeros((int(self.duration*SR),2),np.float32)
        self.wet = self.dry.copy()

    def add(self, x, beat, gain, pan=0, send=.1):
        pos = int(beat*self.beat*SR)
        n = min(len(x),len(self.dry)-pos)
        if n <= 0: return
        v = x[:n,None]*np.array([math.sqrt((1-pan)/2),math.sqrt((1+pan)/2)])[None,:]*gain
        self.dry[pos:pos+n] += v
        self.wet[pos:pos+n] += v*send

    def note(self, n, at, length, voice, gain, pan=0, send=.12):
        self.add(tone(n,length*self.beat,voice),at,gain,pan,send)

    def finish(self):
        y = self.dry.copy()
        for delay,gain in [(.113,.24),(.179,.2),(.283,.16),(.367,.12),(.491,.08)]:
            d = int(delay*SR)
            y[d:] += self.wet[:-d,::-1]*gain
        # Remove DC/rumble, gently compress peaks, match audition RMS.
        y = signal.sosfilt(signal.butter(2,30,btype='highpass',fs=SR,output='sos'),y,axis=0)
        y = np.tanh(y*1.25)
        rms = np.sqrt(np.mean(y*y))
        y *= .18/rms
        peak = np.max(np.abs(y))
        if peak>.94: y *= .94/peak
        y[:int(.015*SR)] *= np.linspace(0,1,int(.015*SR))[:,None]
        y[-int(.8*SR):] *= np.linspace(1,0,int(.8*SR))[:,None]
        return y


CONFIG = [
    ('A_sporty_electronic',124,'Sporty Electronic — Modern Racing'),
    ('B_electro_funk',112,'Electro Funk — Casual Racing'),
    ('C_electronic_rock',138,'Electronic Rock — Motorsport'),
    ('D_upbeat_groove',104,'Upbeat Groove — Tycoon Management'),
]


def render(idx,bpm):
    m = Mix(bpm)
    drums = {name:drum(name) for name in ['kick','snare','clap','hat','open','shaker','crash','tom']}
    # Four original harmonic treatments of a compact rising/falling theme.
    roots = [[42,38,45,40],[40,45,38,43],[40,36,43,38],[48,45,41,43]][idx]
    motif = [[0,7,12,10,7,3,5,7],[7,12,14,12,7,4,2,4],[0,7,12,14,12,7,10,7],[4,7,12,11,7,9,7,4]][idx]
    for bar in range(20):
        start = bar*4
        root = roots[bar%4]
        intro = bar<2
        breakdown = 10<=bar<12
        chorus = 12<=bar<18
        ending = bar>=18
        energy = .6 if intro or breakdown else 1
        major = idx in [1,3]
        third = 4 if major else 3
        chord = [root+24,root+24+third,root+31,root+38 if major else root+34]
        if idx == 0:
            for q in range(4):
                if not breakdown or q==0: m.add(drums['kick'],start+q,.62*energy)
                if q in [1,3] and not intro: m.add(drums['clap'],start+q,.33)
                m.add(drums['open'],start+q+.5,.12,-.25)
            for k in range(8):
                m.note(root+(12 if k in [3,7] else 0),start+k*.5+.25,.2,'bass',.33*energy,send=0)
                m.note(chord[k%4]+12,start+k*.5,.28,'pluck',.095,-.35 if k%2 else .35,.4)
            for n in chord: m.note(n,start,3.9,'pad',.055,send=.4)
        elif idx == 1:
            for q in [0,1.5,2.75]: m.add(drums['kick'],start+q,.6*energy)
            for q in [1,3]: m.add(drums['snare'],start+q,.3*energy)
            for at,offset,length in [(0,0,.6),(.75,12,.22),(1.5,0,.3),(2.25,7,.25),(2.75,10,.23),(3.5,12,.27)]:
                m.note(root+offset,start+at,length,'bass',.42*energy,send=.02)
            for q in [.5,1.25,2.5,3.25,3.75]:
                for j,n in enumerate(chord[:3]): m.note(n,start+q+j*.012,.23,'guitar',.24,-.4,.2)
            for n in chord: m.note(n,start+.05,2.5,'keys',.065,.35,.25)
        elif idx == 2:
            for q in [0,.5,2,2.5,3.5]:
                if not breakdown or q==0: m.add(drums['kick'],start+q,.6*energy)
            for q in [1,3]: m.add(drums['snare'],start+q,.4*energy)
            for k in range(8):
                length = .34 if k not in [3,7] else .48
                m.note(root,start+k*.5,length,'bass',.3*energy,send=0)
                for pan in [-.72,.72]:
                    for n in [root+12,root+19]: m.note(n,start+k*.5+(0 if pan<0 else .014),length,'rock',.17*energy,pan,.08)
            for n in chord[:3]: m.note(n+12,start,3.7,'pad',.04,send=.35)
        else:
            for q in [0,1.75,2.5]: m.add(drums['kick'],start+q,.48*energy)
            for q in [1,3]: m.add(drums['clap'],start+q,.22*energy)
            for at,offset,length in [(0,0,.65),(1.25,7,.3),(2,12,.45),(2.75,7,.25),(3.5,2,.3)]:
                m.note(root-12+offset,start+at,length,'bass',.42*energy,send=.02)
            for q in [.5,2.25,3.5]:
                for j,n in enumerate(chord): m.note(n,start+q+j*.014,.65,'keys',.12,-.25,.28)
            for k in range(8): m.add(drums['shaker'],start+k*.5+(.05 if k%2 else 0),.08,.5)
        if not breakdown:
            for k in range(8 if idx!=2 else 16):
                m.add(drums['hat'],start+k*(.5 if idx!=2 else .25),(.07 if k%2==0 else .045)*energy,.3)
        if bar in [2,12]: m.add(drums['crash'],start,.19,0,.3)
        if bar in [9,17]:
            for k in range(4): m.add(drums['tom'],start+3+k*.25,.2,-.5+k*.3)
        if bar>=2 and not breakdown:
            # Phrase call/response; chorus raises melody without adding density.
            base = root+24+(12 if idx in [0,2] else 0)
            rhythm = [0,.5,1,1.75,2.5,3,3.5,3.75] if idx==1 else [0,.5,1,1.5,2.25,2.75,3.25,3.5]
            phrase = motif if bar%2==0 else [12,10 if not major else 11,7,5,3 if not major else 4,7,5,0]
            for k,step in enumerate(phrase):
                if ending and k>3: continue
                voice = ['lead','keys','lead','pluck'][idx]
                m.note(base+step,start+rhythm[k],.4 if k<7 else .65,voice,[.17,.19,.17,.22][idx]*(1.08 if chorus else .85),.08,.35)
                if chorus and idx==0: m.note(base+step-12,start+rhythm[k],.4,'pluck',.055,-.3,.3)
        elif breakdown:
            for k in [0,2]: m.note(chord[k],start+k,1.4,'keys',.16,0,.5)
    return m.finish()


def main():
    masters=[]
    records=[]
    for idx,(name,bpm,title) in enumerate(CONFIG):
        y=render(idx,bpm)
        wavfile.write(OUT/(name+'.wav'),SR,(y*32767).astype(np.int16))
        masters.append(y)
        records.append(dict(file=name+'.wav',title=title,bpm=bpm,duration_seconds=round(len(y)/SR,2),peak_dbfs=round(20*np.log10(np.max(np.abs(y))),2),rms_dbfs=round(20*np.log10(np.sqrt(np.mean(y*y))),2)))
        print(json.dumps(records[-1]),flush=True)
    reel=[]
    for y in masters:
        reel.extend([y,np.zeros((SR,2))])
    wavfile.write(OUT/'ABCD_comparison.wav',SR,(np.concatenate(reel[:-1])*32767).astype(np.int16))
    (OUT/'manifest.json').write_text(json.dumps(dict(origin='Original procedural instrumental composition; synthesized instruments; no vocals or external samples.',sample_rate=SR,channels=2,bits=16,tracks=records),indent=2),encoding='utf-8')
    cards=''.join(f'<article><h2>{r["title"]}</h2><p>{r["bpm"]} BPM · {r["duration_seconds"]:.0f} giây</p><audio controls preload="none" src="{r["file"]}"></audio><a href="{r["file"]}" download>Tải WAV</a></article>' for r in records)
    (OUT/'listen.html').write_text('<!doctype html><html lang="vi"><meta charset="utf-8"><title>Workshop GP — Theme demos</title><style>body{background:#101827;color:#eef5ff;font:17px system-ui;max-width:850px;margin:50px auto;padding:20px}h1{color:#73e5eb}article{background:#1c293c;padding:24px;margin:18px 0;border-radius:16px}h2{font-size:20px}p{color:#acbdd4}audio{display:block;width:100%;margin:15px 0}a{color:#73e5eb}</style><h1>Workshop GP · Theme auditions</h1><p>4 demo nhạc cụ tổng hợp nguyên bản. Chọn hướng phối khí trước khi sản xuất bản hoàn chỉnh.</p>'+cards+'<h2>Nghe liên tiếp A → B → C → D</h2><audio controls preload="none" src="ABCD_comparison.wav"></audio><script>document.querySelectorAll("audio").forEach(a=>a.addEventListener("play",()=>document.querySelectorAll("audio").forEach(b=>{if(a!==b)b.pause()})))</script></html>',encoding='utf-8')


if __name__=='__main__': main()
