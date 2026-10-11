"""Compose original loopable chiptune music and synthesize combat SFX.
No downloaded recordings or third-party melodies are used.
Requires numpy. Output: mono 16-bit PCM WAV, 44100 Hz.
"""
from pathlib import Path
import json
import wave
import numpy as np

RATE = 44100
DEST = Path(__file__).resolve().parent.parent / 'mobile/assets/audio/playable_stage'
DEST.mkdir(parents=True, exist_ok=True)
RNG = np.random.default_rng(20261010)
FILES = {}

def write(name, audio, loop=False):
    peak = float(np.max(np.abs(audio)))
    # Leave headroom for concurrent SFX and music; never hard clip.
    audio = audio / max(1.0, peak / .72)
    fade = min(len(audio) // 4, int(RATE * .004))
    audio[:fade] *= np.linspace(0, 1, fade)
    audio[-fade:] *= np.linspace(1, 0, fade)
    pcm = (audio * 32767).round().astype('<i2')
    with wave.open(str(DEST / f'{name}.wav'), 'wb') as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes(pcm.tobytes())
    FILES[name] = {'seconds': len(audio) / RATE, 'loop': loop,
                   'peak': float(np.max(np.abs(audio)))}

def tone(midi, seconds, volume=.18, voice='pulse'):
    t = np.arange(int(seconds * RATE)) / RATE
    f = 440 * 2 ** ((midi - 69) / 12)
    if voice == 'triangle':
        signal = 2 / np.pi * np.arcsin(np.sin(2 * np.pi * f * t))
    else:
        # Band-limited pulse, avoiding harsh aliasing from square-wave edges.
        signal = sum(np.sin(2 * np.pi * f * k * t) / k
                     for k in range(1, min(15, int(RATE / (2 * f))), 2)) * .65
    env = np.minimum(t / .008, 1) * np.minimum((seconds - t) / .045, 1)
    return signal * env * volume

def add(buffer, start, audio):
    offset = int(start * RATE)
    end = min(len(buffer), offset + len(audio))
    buffer[offset:end] += audio[:end-offset]

def music(name, bpm, boss):
    beat = 60 / bpm
    bars = 16
    track = np.zeros(round(bars * 4 * beat * RATE))
    roots = [45, 41, 48, 43, 45, 41, 50, 40] * 2
    # Original four melodic motifs, in A minor; variations answer each phrase.
    motifs = [[69,72,76,72,74,72,69,67], [65,69,72,76,74,72,69,65],
              [72,76,79,76,74,72,71,67], [67,71,74,77,76,74,71,68]]
    for bar, root in enumerate(roots):
        start = bar * 4 * beat
        motif = motifs[bar % 4]
        for step, note in enumerate(motif):
            add(track, start + step * beat / 2,
                tone(note + (12 if boss and bar >= 8 else 0), beat * .43, .14))
        for step in range(8):
            add(track, start + step * beat / 2,
                tone(root + [0,7,12,7][step % 4], beat * .42, .18, 'triangle'))
        for step in range(4):
            t = np.arange(int(.15 * RATE)) / RATE
            kick = np.sin(2*np.pi*(85*t-140*t*t)) * np.exp(-t*28) * .17
            add(track, start + step * beat, kick)
            if step % 2:
                snare = RNG.uniform(-1, 1, len(t)) * np.exp(-t*35) * .055
                add(track, start + step * beat, snare)
        for step in range(8 if not boss else 16):
            t = np.arange(int(.045 * RATE)) / RATE
            noise = RNG.uniform(-1, 1, len(t))
            hat = np.diff(noise, prepend=0) * np.exp(-t*100) * .015
            add(track, start + step * beat / (2 if not boss else 4), hat)
    write(name, track, True)

def sweep(name, seconds, f0, f1, volume, noise=0):
    t = np.arange(int(seconds * RATE)) / RATE
    phase = 2*np.pi*(f0*t+(f1-f0)*t*t/(2*seconds))
    signal = np.sin(phase) * .6 + RNG.uniform(-1, 1, len(t)) * noise
    signal *= np.sin(np.pi*t/seconds)**.6 * np.exp(-t*3) * volume
    write(name, signal)

def fanfare(name, notes, step, volume=.23):
    buffer = np.zeros(int((len(notes)*step + .2)*RATE))
    for index, note in enumerate(notes):
        add(buffer, index*step, tone(note, step*.9, volume))
    write(name, buffer)

music('battle', 132, False)
music('boss', 156, True)
sweep('swing', .18, 1300, 180, .28, .5)
sweep('skill', .55, 240, 1500, .32, .15)
sweep('hit', .16, 260, 65, .50, .5)
fanfare('critical', [81, 88, 93], .07, .30)
sweep('miss', .17, 500, 250, .16, .12)
sweep('hurt', .23, 180, 45, .48, .55)
sweep('enemyDefeat', .48, 420, 35, .30, .30)
fanfare('victory', [72,76,79,84,79,84], .14)
fanfare('loss', [64,60,57,52], .22, .18)
(DEST / 'manifest.json').write_text(json.dumps({
    'composition': 'FocusQuest original synthesized chiptune',
    'sample_rate': RATE, 'channels': 1, 'bits': 16, 'files': FILES,
}, indent=2) + '\n', encoding='utf-8')
print(f'Created {len(FILES)} original WAV files in {DEST}')
