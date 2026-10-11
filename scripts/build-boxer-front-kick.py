"""Extract supplied PNG poses without generating or interpolating pixels."""
from pathlib import Path
import importlib.util
import sys
import json
import hashlib
import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'mobile/assets/images/characters/boxer/skills/front_kick'
REVIEW = ROOT / 'artifacts/boxer_front_kick_review'
TIMES = ['13_33_22', '13_33_32', '13_33_40', '13_33_45',
         '13_34_23', '13_34_27', '13_34_33']
spec = importlib.util.spec_from_file_location('extract', ROOT / 'scripts/build-swordsman-run-attack.py')
extract = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = extract
spec.loader.exec_module(extract)

def main():
    REVIEW.mkdir(parents=True, exist_ok=True)
    OUT.mkdir(parents=True, exist_ok=True)
    poses, records = {}, []
    if '--reuse' in sys.argv:
        records = json.loads((REVIEW/'candidates.json').read_text(encoding='utf-8'))
        poses = {r['id']: Image.open(REVIEW/f"isolated_{r['id']:02d}.png").convert('RGBA') for r in records}
    for sheet, time in enumerate([] if '--reuse' in sys.argv else TIMES):
        name = f'ChatGPT 画像 2026年10月10日 {time}.png'
        source = Path('C:/Users/eido0/Downloads') / name
        if not source.exists():
            source = REVIEW/'sources'/name
        im = Image.open(source).convert('RGBA')
        rgba = np.asarray(im)
        labels, components = extract.connected_components(rgba[:, :, 3] > 4)
        bodies = sorted(components, key=lambda c: c['area'], reverse=True)[:5]
        bodies.sort(key=lambda c: c['x0'])
        if min(c['area'] for c in bodies) < 20000:
            raise ValueError(f'Cannot isolate five actors: {name}')
        assigned = {b['label']: [] for b in bodies}
        for c in components:
            nearest = min(bodies, key=lambda b: extract._distance_to_bbox(c, b))
            assigned[nearest['label']].append(c['label'])
        owner = np.zeros(labels.shape, dtype=np.uint8)
        for slot, body in enumerate(bodies):
            owner[np.isin(labels, assigned[body['label']])] = slot+1
        # Restore the original low-alpha fringe. Threshold is used only to
        # identify actors; no threshold is applied to exported RGBA pixels.
        for _ in range(16):
            padded = np.pad(owner, 1)
            expanded = owner.copy()
            for dy in range(3):
                for dx in range(3):
                    neighbour = padded[dy:dy+im.height, dx:dx+im.width]
                    use = (expanded == 0) & (rgba[:,:,3] > 0)
                    expanded[use] = neighbour[use]
            owner = expanded
        yy, xx = np.nonzero((owner == 0) & (rgba[:,:,3] > 0))
        for y, x in zip(yy, xx):
            nearest = min(range(5), key=lambda s: extract._distance_to_bbox(
                dict(x0=int(x),x1=int(x),y0=int(y),y1=int(y)), bodies[s]))
            owner[y,x] = nearest+1
        board = Image.new('RGB', (1750, 620), '#384452')
        draw = ImageDraw.Draw(board)
        for slot, body in enumerate(bodies):
            number = sheet * 5 + slot + 1
            boundaries = [round(i * im.width / 5) for i in range(6)]
            im.crop((boundaries[slot], 0, boundaries[slot+1], im.height)).save(
                REVIEW / f'raw_{number:02d}.png')
            mask = owner == slot+1
            pixels = rgba.copy()
            pixels[~mask] = 0
            isolated = Image.fromarray(pixels)
            bbox = isolated.getbbox()
            isolated = isolated.crop(bbox)
            isolated.save(REVIEW / f'isolated_{number:02d}.png')
            poses[number] = isolated
            preview = isolated.copy()
            preview.thumbnail((340, 580), Image.Resampling.NEAREST)
            board.paste(preview, (slot*350, 30), preview)
            draw.text((slot*350+4, 8), f'{number:02d}  S{sheet+1}/F{slot+1}', fill='white')
            records.append(dict(id=number, source=name, sourceFrame=slot+1,
                sourceSize=list(im.size), equalSlot=[boundaries[slot], 0, boundaries[slot+1], im.height],
                isolatedBBox=list(bbox), sourceSHA256=hashlib.sha256(source.read_bytes()).hexdigest()))
        board.save(REVIEW / f'sheet_{sheet+1:02d}.png')
        print(sheet+1, im.size, [b['area'] for b in bodies])
    (REVIEW / 'candidates.json').write_text(json.dumps(records, ensure_ascii=False, indent=2), encoding='utf-8')
    if '--review' in sys.argv:
        return
    plan = json.loads((OUT / 'selection.json').read_text(encoding='utf-8'))
    width, height = plan['width'], plan['height']
    aligned = {}
    for record in records:
        number = record['id']
        canvas = Image.new('RGBA', (width, height))
        x, y = plan['placements'][str(number)]
        canvas.paste(poses[number], (x, y))
        assert np.count_nonzero(np.array(canvas)[:,:,3]) == np.count_nonzero(np.array(poses[number])[:,:,3]), number
        assert canvas.crop((x,y,x+poses[number].width,y+poses[number].height)).tobytes() == poses[number].tobytes(), number
        canvas.save(OUT / f'frame_{number:02d}.png')
        aligned[number] = canvas
    ids = plan['frames']
    atlas = Image.new('RGBA', (width*5, height*((len(ids)+4)//5)))
    for i, number in enumerate(ids):
        atlas.paste(aligned[number], (i%5*width, i//5*height))
    atlas.save(OUT / 'front_kick.png')
    plan['candidates'] = records
    (OUT / 'front_kick.json').write_text(json.dumps(plan,ensure_ascii=False,indent=2),encoding='utf-8')
    preview = []
    tick_ids = []
    (REVIEW / 'frames_24fps').mkdir(exist_ok=True)
    for number, ticks in zip(ids, plan['holdTicks']):
        canvas = aligned[number]
        bg = Image.new('RGB', canvas.size, '#384452')
        bg.paste(canvas, (0,0), canvas)
        preview.append(bg.resize((width//2,height//2), Image.Resampling.NEAREST))
        for _ in range(ticks):
            dest = REVIEW / 'frames_24fps' / f'frame_{len(tick_ids):03d}.png'
            canvas.save(dest)
            assert Image.open(dest).tobytes() == canvas.tobytes()
            tick_ids.append(number)
    preview[0].save(REVIEW / 'front_kick_preview.gif', save_all=True,
        append_images=preview[1:], duration=[round(t*1000/24) for t in plan['holdTicks']], loop=0)
    (REVIEW / 'timeline_24fps.json').write_text(json.dumps(dict(fps=24,frameIds=tick_ids,
        events=plan['events'],rgbaMatches=True),indent=2),encoding='utf-8')
    print('Verified original-pixel placement and 24fps RGBA equality:', len(tick_ids))

if __name__ == '__main__':
    main()
