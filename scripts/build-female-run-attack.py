"""Exact five-slot review and deterministic aligned atlas; never redraw originals."""
from pathlib import Path
import json
import shutil
import sys
import importlib.util
from PIL import Image, ImageDraw
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'mobile/assets/images/characters/female_swordsman/normal_attack'
REVIEW = ROOT / 'artifacts/female_attack_review'
NAMES = [
    'ChatGPT 画像 2026年10月10日 10_20_11.png',
    'ChatGPT 画像 2026年10月10日 10_20_31.png',
    'ChatGPT 画像 2026年10月10日 10_23_35.png',
    'ChatGPT 画像 2026年10月10日 10_23_43.png',
    'ChatGPT 画像 2026年10月10日 10_23_48.png',
    'ChatGPT 画像 2026年10月10日 10_23_51.png',
]
SKILL = '--skill' in sys.argv
if SKILL:
    OUT = ROOT / 'mobile/assets/images/characters/female_swordsman/skill'
    REVIEW = ROOT / 'artifacts/female_skill_review'
    NAMES = [f'ChatGPT 画像 2026年10月10日 {time}.png' for time in
             ['10_31_23', '10_32_02', '10_32_13', '10_32_21', '10_32_29', '10_32_36', '10_32_44']]
spec = importlib.util.spec_from_file_location('female_actor_extract', ROOT / 'scripts/build-swordsman-run-attack.py')
extractor = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = extractor
spec.loader.exec_module(extractor)

def main():
    OUT.mkdir(parents=True, exist_ok=True)
    REVIEW.mkdir(parents=True, exist_ok=True)
    isolated = {}
    for sheet, name in enumerate(NAMES):
        source = Path('C:/Users/eido0/Downloads') / name
        if not source.exists():
            source = next(ROOT.rglob(name), None)
        if source is None:
            raise FileNotFoundError(name)
        target = OUT / name
        if source.resolve() != target.resolve():
            shutil.copy2(source, target)
        im = Image.open(target).convert('RGBA')
        board = Image.new('RGB', (1500, 540), '#384452')
        draw = ImageDraw.Draw(board)
        for slot in range(5):
            number = sheet * 5 + slot + 1
            frame = im.crop((round(slot * im.width / 5), 0,
                             round((slot + 1) * im.width / 5), im.height))
            frame.save(REVIEW / f'frame_{number:02d}.png')
            if SKILL:
                frame.save(REVIEW / f'sheet{sheet+1:02d}_frame{slot+1:02d}.png')
            frame.thumbnail((300, 500))
            board.paste(frame, (slot * 300, 30), frame)
            draw.text((slot * 300 + 5, 8), f'frame_{number:02d} / sheet {sheet+1} f{slot+1}', fill='white')
        board.save(REVIEW / f'sheet_{sheet+1:02d}.png')
        actors, diagnostics = extractor.extract_actors(target, 5)
        board = Image.new('RGB', (1500, 540), '#384452')
        draw = ImageDraw.Draw(board)
        for slot, actor in enumerate(actors):
            number = sheet*5+slot+1
            isolated[number] = actor
            actor.pixels.save(REVIEW / f'isolated_{number:02d}.png')
            thumb = actor.pixels.copy()
            thumb.thumbnail((296, 490))
            board.paste(thumb, (slot*300, 35), thumb)
            draw.text((slot*300+5, 8), f'frame_{number:02d}', fill='white')
        board.save(REVIEW / f'isolated_sheet_{sheet+1:02d}.png')
        print(diagnostics)
        print(name, im.size, 'alpha', im.getchannel('A').getextrema())
    if '--review' in sys.argv:
        return
    plan = json.loads((OUT / 'selection.json').read_text(encoding='utf-8'))
    frames = []
    for number in plan['atlasFrames']:
        actor = isolated[number]
        scale = ([1.0]*7 if SKILL else [1.0, 1.12, 1.10, 1.0, 1.04, 1.03])[(number-1)//5]
        pixels = actor.pixels.resize((round(actor.pixels.width*scale), round(actor.pixels.height*scale)), Image.Resampling.LANCZOS)
        frames.append((number, pixels, *(round(a*scale) for a in actor.anchor)))
    half_width = max(max(x, im.width-x) for _, im, x, y in frames) + 16
    above = max(y for _, im, x, y in frames) + 16
    below = max(im.height-y for _, im, x, y in frames) + 16
    width = ((half_width*2+15)//16)*16
    height = ((above+below+15)//16)*16
    atlas = Image.new('RGBA', (width*5, height*((len(frames)+4)//5)))
    canvases = {}
    for index, (number, im, x, y) in enumerate(frames):
        canvas = Image.new('RGBA', (width, height))
        canvas.alpha_composite(im, (width//2-x, above-y))
        canvas.save(REVIEW / f'aligned_{number:02d}.png')
        canvases[number] = canvas
        atlas.alpha_composite(canvas, (index%5*width, index//5*height))
    basename = 'skill' if SKILL else 'normal_attack'
    atlas.resize((atlas.width//2, atlas.height//2), Image.Resampling.LANCZOS).save(OUT / f'{basename}.png')
    plan.update(sources=NAMES, columns=5, width=width//2, height=height//2,
                anchorX=.5, anchorY=above/height)
    (OUT / f'{basename}.json').write_text(json.dumps(plan, ensure_ascii=False, indent=2), encoding='utf-8')
    preview = []
    for number in plan['attackFrames']:
        bg = Image.new('RGB', (width, height), '#384452')
        bg.paste(canvases[number], (0,0), canvases[number])
        preview.append(bg)
    preview[0].save(REVIEW / f'{basename}_preview.gif', save_all=True,
                    append_images=preview[1:], duration=[round(t*1000) for t in plan['stepTimes']], loop=0)

if __name__ == '__main__':
    main()
