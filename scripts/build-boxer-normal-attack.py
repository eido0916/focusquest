"""Review all 50 provided poses and build a selected, aligned transparent atlas."""
from pathlib import Path
import importlib.util
import sys
import shutil
import json
import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'mobile/assets/images/characters/boxer/normal_attack'
REVIEW = ROOT / 'artifacts/boxer_attack_review'
NAMES = [
    'ChatGPT 画像 2026年10月10日 13_23_49-1.png',
    'ChatGPT 画像 2026年10月10日 13_23_50-2.png',
    'ChatGPT 画像 2026年10月10日 13_23_51-3.png',
    'ChatGPT 画像 2026年10月10日 13_23_52-4.png',
    'ChatGPT 画像 2026年10月10日 13_23_53-5.png',
    'ChatGPT 画像 2026年10月10日 13_23_56-6.png',
    'ChatGPT 画像 2026年10月10日 13_23_57-7.png',
    'ChatGPT 画像 2026年10月10日 13_23_59-8.png',
    'ChatGPT 画像 2026年10月10日 13_24_00-9.png',
    'ChatGPT 画像 2026年10月10日 13_24_01-10.png',
]
spec = importlib.util.spec_from_file_location('boxer_extract', ROOT / 'scripts/build-swordsman-run-attack.py')
extractor = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = extractor
spec.loader.exec_module(extractor)

def main():
    OUT.mkdir(parents=True, exist_ok=True)
    REVIEW.mkdir(parents=True, exist_ok=True)
    actors = {}
    for sheet, name in enumerate(NAMES):
        source = Path('C:/Users/eido0/Downloads') / name
        if not source.exists():
            source = next(ROOT.rglob(name), None)
        if source is None:
            raise FileNotFoundError(name)
        target = OUT / name
        if source.resolve() != target.resolve():
            shutil.copy2(source, target)
        image = Image.open(target).convert('RGBA')
        rgba = np.array(image)
        labels, comps = extractor.connected_components(rgba[:,:,3] > 4)
        # Never use blond-hair segmentation for a red-haired boxer. Only
        # unambiguously separate connected actors may be used in production.
        bodies = sorted(comps, key=lambda c: c['area'], reverse=True)[:5]
        bodies.sort(key=lambda c: c['x0'])
        board = Image.new('RGB', (1500, 550), '#384452')
        draw = ImageDraw.Draw(board)
        for slot in range(5):
            number = sheet*5+slot+1
            crop = image.crop((round(slot*image.width/5), 0,
                               round((slot+1)*image.width/5), image.height))
            crop.save(REVIEW / f'frame_{number:02d}.png')
            crop.thumbnail((300,510))
            board.paste(crop, (slot*300,30), crop)
            draw.text((slot*300+5,8), f'{number:02d} / sheet{sheet+1:02d}_f{slot+1}', fill='white')
            if len(bodies) == 5 and min(c['area'] for c in bodies) > 20000:
                body = bodies[slot]
                mask = labels == body['label']
                pixels = rgba.copy()
                pixels[:,:,3] = np.where(mask, pixels[:,:,3], 0)
                full = Image.fromarray(pixels)
                bbox = full.getbbox()
                isolated = full.crop(bbox)
                # Hip x at ~52% down the body, below forearms and above thighs.
                y = body['y0'] + round((body['y1']-body['y0'])*.52)
                band_y, band_x = np.nonzero(mask[max(0,y-10):y+11])
                waist = int(np.median(band_x))
                foot = extractor._foot_y(mask)
                actors[number] = (isolated, waist-bbox[0], foot-bbox[1])
                isolated.save(REVIEW / f'isolated_{number:02d}.png')
        board.save(REVIEW / f'sheet_{sheet+1:02d}.png')
        print(sheet+1, image.size, image.getchannel('A').getextrema(),
              'body areas', [c['area'] for c in bodies])
    if '--review' in sys.argv:
        return
    plan = json.loads((OUT / 'selection.json').read_text(encoding='utf-8'))
    ids = plan['atlasFrames']
    missing = [i for i in ids if i not in actors]
    if missing:
        raise ValueError(f'Cannot unambiguously separate these poses: {missing}')
    # One scale for all poses; body size never follows stretched fist bounds.
    half_width = max(max(x,im.width-x) for im,x,y in (actors[i] for i in ids))+16
    above = max(actors[i][2] for i in ids)+16
    below = max(actors[i][0].height-actors[i][2] for i in ids)+16
    width = ((half_width*2+15)//16)*16
    height = ((above+below+15)//16)*16
    atlas = Image.new('RGBA', (width*5, height*((len(ids)+4)//5)))
    aligned = {}
    for index, number in enumerate(ids):
        im,x,y = actors[number]
        canvas = Image.new('RGBA', (width,height))
        canvas.alpha_composite(im, (width//2-x,above-y))
        canvas = canvas.resize((width//2,height//2), Image.Resampling.LANCZOS)
        canvas.save(OUT / f'frame_{number:02d}.png')
        aligned[number] = canvas
        atlas.alpha_composite(im, (index%5*width+width//2-x,index//5*height+above-y))
    atlas.resize((atlas.width//2,atlas.height//2), Image.Resampling.LANCZOS).save(OUT / 'normal_attack.png')
    plan.update(sources=NAMES, columns=5, width=width//2, height=height//2,
                anchorX=.5, anchorY=above/height)
    (OUT / 'normal_attack.json').write_text(json.dumps(plan,ensure_ascii=False,indent=2),encoding='utf-8')
    preview = []
    for i in plan['attackFrames']:
        bg = Image.new('RGB', (width//2,height//2), '#384452')
        bg.paste(aligned[i],(0,0),aligned[i])
        preview.append(bg)
    preview[0].save(REVIEW / 'normal_attack_preview.gif',save_all=True,
                    append_images=preview[1:],duration=[round(t*1000) for t in plan['stepTimes']],loop=0)

if __name__ == '__main__':
    main()
