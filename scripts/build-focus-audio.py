"""Original FocusQuest compositions and role-specific synthesized attack sounds.
Run with the bundled Python (numpy). No third-party recordings or melodies.
"""
from pathlib import Path
import json
import wave
import numpy as np

RATE = 44100
DEST = Path(__file__).resolve().parent.parent / 'mobile/assets/audio/focus_adventure'
DEST.mkdir(parents=True, exist_ok=True)
RNG = np.random.default_rng(20261012)
FILES = {}

def write(name, samples, loop=False):
    samples = samples / max(1, np.max(np.abs(samples)) / .75)
    n = min(180, len(samples)//4)
    samples[:n] *= np.linspace(0, 1, n)
    samples[-n:] *= np.linspace(1, 0, n)
    with wave.open(str(DEST / f'{name}.wav'), 'wb') as w:
        w.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        w.writeframes((samples * 32767).round().astype('<i2').tobytes())
    FILES[name] = {'seconds': len(samples)/RATE, 'loop': loop,
                   'peak': float(np.max(np.abs(samples))),
                   'rms': float(np.sqrt(np.mean(samples**2)))}

def note(midi, seconds, volume=.15, soft=True):
    t = np.arange(round(seconds*RATE))/RATE
    f = 440 * 2**((midi-69)/12)
    signal = np.sin(2*np.pi*f*t)
    signal += (.18 if soft else .45)*np.sin(2*np.pi*f*2*t)
    signal += (.06 if soft else .22)*np.sin(2*np.pi*f*3*t)
    env = np.minimum(t/.012, 1)*np.minimum((seconds-t)/.08, 1)
    return signal*env*np.exp(-t*(2 if soft else .8))*volume

def add(buffer, at, samples):
    at = round(at*RATE)
    n = min(len(samples), len(buffer)-at)
    if n > 0: buffer[at:at+n] += samples[:n]

def compose(name, boss):
    beat = 60/(144 if boss else 88)
    buffer = np.zeros(round(32*4*beat*RATE))
    roots = ([45,41,43,40] if boss else [48,53,55,48,57,53,55,48])*8
    motifs = ([[69,72,76,75,74,72,71,68], [65,69,72,74,72,69,67,65],
               [67,71,74,77,76,74,71,67], [64,68,71,76,74,71,68,64]] if boss else
              [[72,76,79,76], [77,76,74,72], [74,79,77,74], [76,74,72,67],
               [76,79,81,79], [77,81,79,76], [74,77,79,71], [72,76,74,72]])
    for bar in range(32):
        root = roots[bar]
        at = bar*4*beat
        melody = motifs[bar%len(motifs)]
        for i, pitch in enumerate(melody):
            add(buffer, at+i*4*beat/len(melody), note(pitch, beat*(.43 if boss else .85), .15, not boss))
        for i in range(8):
            add(buffer, at+i*beat/2, note(root+[12,19,24,19][i%4], beat*.45, .065, not boss))
        for i in range(4):
            add(buffer, at+i*beat, note(root-12, beat*.8, .17))
            if boss:
                t = np.arange(round(.18*RATE))/RATE
                drum = np.sin(2*np.pi*(80*t-100*t*t))*np.exp(-t*30)*.12
                if i%2: drum += RNG.uniform(-1,1,len(t))*np.exp(-t*28)*.08
                add(buffer, at+i*beat, drum)
    write(name, buffer, True)

def effect(name, seconds, start, end, noise, strength, shimmer=False):
    t = np.arange(round(seconds*RATE))/RATE
    phase = 2*np.pi*(start*t+(end-start)*t*t/(2*seconds))
    n = RNG.uniform(-1,1,len(t))
    n = (n + np.roll(n,1))/2
    signal = np.sin(phase)*.6 + n*noise
    if shimmer:
        signal += np.sin(2*np.pi*1760*t)*np.exp(-t*5)*.25
        signal += np.sin(2*np.pi*2637*t)*np.exp(-t*7)*.15
    signal *= np.minimum(t/.006,1)*np.minimum((seconds-t)/.035,1)*np.exp(-t*(6/seconds))*strength
    write(name, signal)

compose('peaceful', False)
compose('boss', True)
# Short weapon transients and longer magical tails, matched to each animation release.
SPECS = {
    'sword': (.22,1200,240,.8,.65), 'sword_wave': (.55,300,1200,.5,.65),
    'punch': (.16,170,45,.75,.8), 'kick': (.3,360,65,1,.75),
    'katana': (.18,2000,280,.7,.65), 'heavy': (.34,130,30,1,.9),
    'shuriken': (.19,2600,900,.4,.55), 'dagger': (.15,1400,500,.7,.6),
    'critical_dagger': (.26,1700,180,.8,.8), 'bow': (.24,750,160,.22,.65),
    'gun': (.18,110,40,2,.95), 'fire': (.5,180,60,1.4,.7),
    'ice': (.65,2200,1100,.4,.55), 'lightning': (.55,80,650,1.7,.75),
    'talisman': (.3,440,880,.12,.55), 'spirits': (.7,330,990,.3,.6),
    'scythe': (.38,820,100,.95,.7), 'holy': (.4,880,1320,.08,.5),
    'holy_sword': (.55,660,1760,.3,.6), 'dark': (.4,260,90,.6,.65),
    'curse': (.75,320,45,.7,.7), 'dragon': (.65,150,35,1.8,.85),
    'earth': (.6,90,25,1.4,.85),
}
for name, spec in SPECS.items():
    effect(name, *spec, shimmer=name in ['ice','holy','holy_sword','spirits','talisman'])
(DEST/'manifest.json').write_text(json.dumps({
    'composition': 'FocusQuest original music and synthesized SFX, 2026-10-12',
    'license': 'Original project assets; no third-party recordings.',
    'sample_rate': RATE, 'channels': 1, 'bits': 16, 'files': FILES,
}, indent=2)+'\n', encoding='utf-8')
print(f'Created {len(FILES)} WAV files ({sum(f["seconds"] for f in FILES.values()):.1f}s)')
