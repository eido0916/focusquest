"""Extract supplied run poses without synthesizing pixels or resizing frames."""
from pathlib import Path
import importlib.util
import sys
import json
import shutil
import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'mobile/assets/images/characters/boxer/run'
REVIEW = ROOT / 'artifacts/boxer_run_review'
NAMES = ['ChatGPT 画像 2026年10月10日 21_10_51.png',
         'ChatGPT 画像 2026年10月10日 21_12_14.png']
spec = importlib.util.spec_from_file_location('extract', ROOT / 'scripts/build-swordsman-run-attack.py')
extract = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = extract
spec.loader.exec_module(extract)

def main():
    REVIEW.mkdir(parents=True, exist_ok=True)
    actors = {}
    report = []
    for sheet, name in enumerate(NAMES):
        source = Path('C:/Users/eido0/Downloads') / name
        shutil.copy2(source, REVIEW / name)
        image = Image.open(source).convert('RGBA')
        rgba = np.array(image)
        labels, components = extract.connected_components(rgba[:, :, 3] > 4)
        bodies = sorted(components, key=lambda c: c['area'], reverse=True)[:5]
        bodies.sort(key=lambda c: c['x0'])
        print(name, image.size, image.getchannel('A').getextrema(), bodies)
        if len(bodies) != 5 or min(c['area'] for c in bodies) < 20000:
            raise ValueError('Five independent actors required; do not split overlapping poses')
        owners = np.zeros(labels.shape, dtype=np.int16)
        for c in components:
            owner = min(range(5), key=lambda i: extract._distance_to_bbox(c, bodies[i])) + 1
            owners[labels == c['label']] = owner
        # Retain original low-alpha fringes (including touching alpha 1..4
        # halos) by growing ownership from the five disjoint silhouettes.
        for _ in range(32):
            pending = (rgba[:, :, 3] > 0) & (owners == 0)
            if not pending.any():
                break
            padded = np.pad(owners, 1)
            grown = owners.copy()
            for dy in range(3):
                for dx in range(3):
                    neighbour = padded[dy:dy+owners.shape[0], dx:dx+owners.shape[1]]
                    take = pending & (grown == 0) & (neighbour > 0)
                    grown[take] = neighbour[take]
            if np.array_equal(grown, owners):
                break
            owners = grown
        for y, x in zip(*np.nonzero((rgba[:, :, 3] > 0) & (owners == 0))):
            dot = dict(x0=int(x), x1=int(x), y0=int(y), y1=int(y))
            owners[y, x] = min(range(5), key=lambda i: extract._distance_to_bbox(dot, bodies[i])) + 1
        assert np.count_nonzero(owners) == np.count_nonzero(rgba[:, :, 3])
        for slot, body in enumerate(bodies):
            number = sheet * 5 + slot + 1
            mask = owners == slot + 1
            pixels = rgba.copy()
            pixels[~mask] = 0
            full = Image.fromarray(pixels)
            bbox = full.getbbox()
            actor = full.crop(bbox)
            actor.save(REVIEW / f'isolated_{number:02d}.png')
            actors[number] = (actor, bbox)
            report.append(dict(frame=number, bbox=bbox, area=int(mask.sum())))
    (REVIEW / 'extraction.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
    board = Image.new('RGB', (1500, 720), '#53616b')
    draw = ImageDraw.Draw(board)
    for number, (actor, bbox) in actors.items():
        thumb = actor.copy()
        thumb.thumbnail((290, 325))
        x, y = ((number-1)%5)*300, ((number-1)//5)*360
        board.paste(thumb, (x+(300-thumb.width)//2, y+30), thumb)
        draw.text((x+8,y+8), f'Frame {number} / bbox {bbox}', fill='white')
    board.save(REVIEW / 'all_10_frames.png')
    if '--review' in sys.argv:
        return
    OUT.mkdir(parents=True, exist_ok=True)
    # Reviewed belt/hip x landmarks and sole baseline. Use the substantive
    # alpha silhouette for ground alignment, never the faint PNG halo.
    hips = [266, 651, 1028, 1463, 1880, 255, 650, 1016, 1440, 1873]
    width, height, ground = 640, 768, 680
    # Frame 5 returns to frame 2's planted-foot phase immediately before
    # the loop's extension pose, creating a second forward-foot reversal.
    selected = [1, 2, 3, 4]
    aligned = {}
    for number, (actor, bbox) in actors.items():
        alpha = np.array(actor)[:, :, 3]
        ys, xs = np.nonzero(alpha > 32)
        foot = int(ys.max()) + bbox[1]
        offset = (width//2 - hips[number-1] + bbox[0], ground - foot + bbox[1])
        assert offset[0] >= 0 and offset[1] >= 0
        assert offset[0]+actor.width <= width and offset[1]+actor.height <= height
        canvas = Image.new('RGBA', (width, height))
        canvas.paste(actor, offset)  # Copy RGBA exactly; no alpha resampling.
        assert np.array_equal(np.array(canvas.crop((offset[0], offset[1],
            offset[0]+actor.width, offset[1]+actor.height))), np.array(actor))
        canvas.save(OUT / f'frame_{number:02d}.png')
        aligned[number] = canvas
        report[number-1].update(hipX=hips[number-1], soleY=foot, offset=offset)
    atlas = Image.new('RGBA', (width*len(selected), height))
    previews = []
    for slot, number in enumerate(selected):
        atlas.paste(aligned[number], (slot*width, 0))
        bg = Image.new('RGB', (width, height), '#53616b')
        bg.paste(aligned[number], (0,0), aligned[number])
        ImageDraw.Draw(bg).line((0,ground,width,ground), fill='#bbbbbb')
        previews.append(bg)
    atlas.save(OUT / 'run.png')
    saved = Image.open(OUT / 'run.png')
    for slot, number in enumerate(selected):
        assert np.array_equal(np.array(saved.crop((slot*width,0,(slot+1)*width,height))),
                              np.array(aligned[number]))
    previews[0].save(REVIEW / 'run_preview.gif', save_all=True,
        append_images=previews[1:], duration=[80,90,80,80], loop=0)
    # 24fps delivery repeats the exact selected keyframes twice; runtime 12fps.
    ticks = REVIEW / 'frames_24fps'
    ticks.mkdir(exist_ok=True)
    for old in ticks.glob('run_*.png'):
        if int(old.stem.split('_')[1]) >= len(selected)*2:
            old.unlink()
    for tick in range(len(selected)*2):
        frame = aligned[selected[tick//2]]
        path = ticks / f'run_{tick:03d}.png'
        frame.save(path)
        assert np.array_equal(np.array(Image.open(path)), np.array(frame))
    metadata = dict(width=width, height=height, columns=len(selected), frameIds=selected,
        fps=12, stepTimes=[1/12]*len(selected), anchorX=.5, anchorY=ground/height,
        displayHeight=height*(215/328)/2, sources=NAMES, extraction=report,
        excluded={'5': 'Near-repeat of frame 2 contact phase; 5 to 1 reverses the front foot before loop reset',
            **{str(i): 'Repeated phase of frame '+str(i-5)+' with different body proportions' for i in range(6,11)}},
        loopSeconds=len(selected)/12, tickRate=24, ticks=[dict(tick=i, frame=selected[i//2]) for i in range(len(selected)*2)],
        worldCoordinateEvents=[], pixelVerification='Exact RGBA copy and exact 24fps repeats')
    (OUT / 'run.json').write_text(json.dumps(metadata,ensure_ascii=False,indent=2),encoding='utf-8')
    board = Image.new('RGB', (width*len(selected),height), '#53616b')
    for i, frame in enumerate(previews):
        board.paste(frame, (width*i,0))
        ImageDraw.Draw(board).text((width*i+20,10), str(selected[i]), fill='white')
    board.save(REVIEW / 'selected_aligned.png')
    print('Verified 10 extracted frames, 4 atlas frames, 8 exact 24fps ticks')

if __name__ == '__main__':
    main()
