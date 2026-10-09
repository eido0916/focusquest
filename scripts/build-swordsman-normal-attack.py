"""Deterministically split supplied sheets; originals are never modified."""
from pathlib import Path
import shutil
import importlib.util
import sys
import json
import re
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'mobile/assets/images/characters/swordsman/normal_attack'
REVIEW = ROOT / 'artifacts/normal_attack_review'
NAMES = [
    'ChatGPT 画像 2026年10月9日 22_13_33-1.png',
    'ChatGPT 画像 2026年10月9日 22_13_34-2.png',
    'ChatGPT 画像 2026年10月9日 22_13_35-3.png',
    'ChatGPT 画像 2026年10月9日 22_13_35-4.png',
    'ChatGPT 画像 2026年10月9日 22_13_37-5.png',
    'ChatGPT 画像 2026年10月9日 22_13_37-6.png',
    'ChatGPT 画像 2026年10月9日 22_13_38-7.png',
    'ChatGPT 画像 2026年10月9日 22_13_39-8.png',
    'ChatGPT 画像 2026年10月9日 22_13_40-9.png',
    'ChatGPT 画像 2026年10月9日 22_13_40-10.png',
]

spec = importlib.util.spec_from_file_location('fq_actor_extract', ROOT / 'scripts/build-swordsman-run-attack.py')
extractor = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = extractor
spec.loader.exec_module(extractor)

def main():
    OUT.mkdir(parents=True, exist_ok=True)
    REVIEW.mkdir(parents=True, exist_ok=True)
    extracted = {}
    for sheet_index, name in enumerate(NAMES, 1):
        source = Path('C:/Users/eido0/Downloads') / name
        if not source.is_file():
            matches = list(ROOT.rglob(name))
            if not matches:
                raise FileNotFoundError(name)
            source = matches[0]
        target = OUT / name
        if source.resolve() != target.resolve():
            shutil.copy2(source, target)
        image = Image.open(target).convert('RGBA')
        actors, _ = extractor.extract_actors(target, 5)
        board = Image.new('RGB', (1500, 530), '#363c47')
        draw = ImageDraw.Draw(board)
        for frame in range(5):
            # Rational width/5, rounded only for offline review pixel bounds.
            left = round(image.width * frame / 5)
            right = round(image.width * (frame + 1) / 5)
            crop = image.crop((left, 0, right, image.height))
            label = f'file_{sheet_index:02d}_f{frame + 1}'
            crop.save(REVIEW / f'{label}.png')
            crop.thumbnail((300, 500))
            board.paste(crop, (frame * 300, 28), crop)
            draw.text((frame * 300 + 8, 8), label, fill='white')
        board.save(REVIEW / f'sheet_{sheet_index:02d}.png')
        corrected = Image.new('RGB', (1500, 530), '#363c47')
        draw = ImageDraw.Draw(corrected)
        for frame, actor in enumerate(actors):
            label = f'file_{sheet_index:02d}_f{frame + 1}'
            extracted[label] = actor
            actor.pixels.save(REVIEW / f'{label}_isolated.png')
            thumbnail = actor.pixels.copy()
            thumbnail.thumbnail((296, 490))
            corrected.paste(thumbnail, (frame * 300, 35), thumbnail)
            draw.text((frame * 300 + 8, 8), label, fill='white')
        corrected.save(REVIEW / f'isolated_{sheet_index:02d}.png')
        print(f'{sheet_index:02d}: {image.size}, alpha={image.getchannel("A").getextrema()}')

    # Single source of truth for the production animation order (Dart).
    sequence = (ROOT / 'mobile/lib/game/runner/swordsman_normal_attack_sequence.dart').read_text(encoding='utf-8')
    ids = re.findall(r"'file_\d{2}_f\d'", sequence.split('static const stepTimes')[0])
    ids = [value.strip("'") for value in ids]
    frames = [extracted[value] for value in ids]
    left = max(f.anchor[0] for f in frames) + 16
    right = max(f.pixels.width - f.anchor[0] for f in frames) + 16
    above = max(f.anchor[1] for f in frames) + 16
    below = max(f.pixels.height - f.anchor[1] for f in frames) + 16
    width = extractor._round_up(left + right)
    height = extractor._round_up(above + below)
    columns = 5
    atlas = Image.new('RGBA', (width * columns, height * ((len(frames) + columns - 1) // columns)))
    for index, frame in enumerate(frames):
        canvas = Image.new('RGBA', (width, height))
        canvas.alpha_composite(frame.pixels, (left - frame.anchor[0], above - frame.anchor[1]))
        atlas.alpha_composite(canvas, (index % columns * width, index // columns * height))
    atlas = atlas.resize((atlas.width // 2, atlas.height // 2), Image.Resampling.LANCZOS)
    atlas.save(OUT / 'normal_attack.png')
    metadata = {
        'frameIds': ids, 'columns': columns,
        'frameSize': {'width': width // 2, 'height': height // 2},
        'anchor': {'x': left / width, 'y': above / height},
        'sources': NAMES,
        'sourceBounds': {key: list(extracted[key].source_bbox) for key in ids},
        'note': 'Five chronological slots per source; alpha-isolated bounds repair slot clipping. No poses are reordered or redrawn.',
    }
    (OUT / 'normal_attack.json').write_text(json.dumps(metadata, ensure_ascii=False, indent=2), encoding='utf-8')

if __name__ == '__main__':
    main()
