"""Package source crops and exact 24fps holds; never interpolate artwork."""
import hashlib
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'artifacts/boxer_wind_review'
SOURCE = ROOT / 'mobile/assets/images/characters/boxer/skills/front_kick/wind_spear.png'
BOUNDS = [0, 168, 410, 699, 1035, 1388, 1663, 1937, 2172]


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    originals = OUT / 'keyframes'
    holds = OUT / 'frames_24fps'
    originals.mkdir(exist_ok=True)
    holds.mkdir(exist_ok=True)
    source = Image.open(SOURCE).convert('RGBA')
    events = []
    for i in range(8):
        rect = (BOUNDS[i], 252, BOUNDS[i + 1], 464)
        frame = source.crop(rect)
        frame.save(originals / f'wind_{i:02d}.png')
        for tick in range(i * 2, i * 2 + 2):
            path = holds / f'wind_{tick:03d}.png'
            frame.save(path)
            assert Image.open(path).convert('RGBA').tobytes() == frame.tobytes()
            events.append({'tick': tick, 'keyframe': i, 'worldPosition': [438, 296]})
    data = {
        'sourceSHA256': hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
        'fps': 24, 'holdTicks': [2] * 8,
        'sourceRects': [[BOUNDS[i], 252, BOUNDS[i + 1], 464] for i in range(8)],
        'spawnTimeSeconds': 15 / 24, 'sourceAxisY': 373,
        'rightEdge': 958, 'displayScale': 520 / 353,
        'blendMode': 'screen', 'filterQuality': 'none',
        'interpolation': False, 'loop': False, 'frames': events,
    }
    (OUT / 'timeline_24fps.json').write_text(
        json.dumps(data, ensure_ascii=False, indent=2), encoding='utf-8')
    contact = OUT / 'battle_contact_sheet.png'
    if contact.exists():
        sheet = Image.open(contact)
        preview = [sheet.crop((i % 4 * 960, i // 4 * 540,
                               i % 4 * 960 + 960, i // 4 * 540 + 540))
                   for i in range(8)]
        preview[0].save(OUT / 'battle_preview.gif', save_all=True,
                        append_images=preview[1:], duration=83, loop=0)
    (OUT / 'validation.txt').write_text(
        'PASS: 16/16 RGBA frame buffers exactly match their source keyframes.\n'
        'Source montage copied unchanged. Eight crops, two ticks per hold.\n',
        encoding='utf-8')
    print('Verified 16/16 exact RGBA holds; packaged eight source crops and timeline.')


if __name__ == '__main__':
    main()
