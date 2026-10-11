"""Lossless extraction and reviewed Flame assets. Requires Pillow and numpy.

No image generation, resampling, warping or interpolation. Input order is
explicit (filename timestamp), independent of attachment display order.
"""
from pathlib import Path
import argparse
import importlib.util
import sys
import json
import shutil
import hashlib
import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'mobile/assets/images/characters/female_archer/normal_attack'
REVIEW = ROOT / 'artifacts/female_archer_attack_review'
TIMES = ['16_20_46', '16_20_55', '16_21_02', '16_21_08', '16_21_17',
         '16_21_25', '16_21_35', '16_21_45', '16_21_53', '16_22_01']
HIP_X = [[250,683,1120,1540,1995], [240,665,1065,1480,1920],
         [240,660,1060,1480,1910], [230,740,1130,1535,1950],
         [210,675,1100,1550,1960], [265,735,1130,1580,2010],
         [310,740,1180,1590,2010], [260,705,1150,1570,2000],
         [260,700,1130,1580,2005]]
SPEED_RATIOS = dict(run=1, prepare=.65, nock=.4, draw=.15, release=.15,
                    recoil=.2, recover=.45, accelerate=.8)
spec = importlib.util.spec_from_file_location('extractor', ROOT / 'scripts/build-swordsman-run-attack.py')
extractor = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = extractor
spec.loader.exec_module(extractor)

def seams(rgba):
    """Trace transparent gaps; a bounded minimum-alpha seam at touching cloaks.

    Every original visible pixel is assigned exactly once. Occluded artwork
    cannot be recovered; suspect poses are excluded in selection.json.
    """
    h, w = rgba.shape[:2]
    result = []
    for slot in range(1, 5):
        centre = round(slot*w/5)
        lo, hi = max(0, centre-90), min(w, centre+91)
        xs = np.arange(lo, hi)
        cost = rgba[:, lo:hi, 3].astype(float)/255*100 + abs(xs-centre)*.003
        previous = cost[0].copy()
        parents = np.zeros(cost.shape, dtype=np.int16)
        for y in range(1, h):
            choices = np.full((9, len(xs)), np.inf)
            for j, dx in enumerate(range(-4, 5)):
                valid = (np.arange(len(xs))+dx >= 0) & (np.arange(len(xs))+dx < len(xs))
                choices[j, valid] = previous[np.arange(len(xs))[valid]+dx] + abs(dx)*.15
            best = choices.argmin(axis=0)
            parents[y] = np.arange(len(xs))+best-4
            previous = cost[y] + choices[best, np.arange(len(xs))]
        path = np.empty(h, dtype=int)
        p = int(previous.argmin())
        for y in range(h-1, -1, -1):
            path[y] = p+lo
            p = int(parents[y, p])
        result.append(path)
    return result

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--source-dir', type=Path, default=Path('C:/Users/eido0/Downloads'))
    parser.add_argument('--review', action='store_true')
    args = parser.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)
    REVIEW.mkdir(parents=True, exist_ok=True)
    actors = {}
    diagnostics = []
    source_hashes = []
    for sheet, time in enumerate(TIMES):
        name = f'ChatGPT 画像 2026年10月10日 {time}.png'
        source = args.source_dir / name
        target = OUT / f'source_{sheet+1:02d}.png'
        if source.exists():
            shutil.copy2(source, target)
        elif not target.exists():
            raise FileNotFoundError(source)
        archive_hash = hashlib.sha256(target.read_bytes()).hexdigest()
        if source.exists():
            assert archive_hash == hashlib.sha256(source.read_bytes()).hexdigest()
        source_hashes.append(dict(original=name, archived=target.name, sha256=archive_hash))
        image = Image.open(target).convert('RGBA')
        rgba = np.array(image)
        board = Image.new('RGB', (1500, 540), '#344052')
        draw = ImageDraw.Draw(board)
        if sheet < 9:
            boundaries = [np.zeros(image.height, dtype=int)] + seams(rgba) + [np.full(image.height, image.width)]
            if sheet == 4:
                # Pose 23's detached flying arrow crosses into pose 24's slot.
                # Assign it to its original owner, not to the recoil character.
                boundaries[3][240:285] = 1460
            xx = np.arange(image.width)[None, :]
            for slot in range(5):
                number = sheet*5+slot+1
                rect = (round(slot*image.width/5), 0, round((slot+1)*image.width/5), image.height)
                crop = image.crop(rect)
                crop.save(REVIEW / f'raw_{number:02d}.png')
                crop.thumbnail((300, 500))
                board.paste(crop, (slot*300, 30), crop)
                draw.text((slot*300+5, 8), str(number), fill='white')
                mask = (xx >= boundaries[slot][:, None]) & (xx < boundaries[slot+1][:, None])
                pixels = rgba.copy()
                pixels[~mask] = 0
                # Exact source pixels; no resampling and no compositing.
                full = Image.fromarray(pixels)
                bbox = full.getbbox()
                actor = full.crop(bbox)
                visible = pixels[:, :, 3] > 80
                foot = extractor._foot_y(visible)
                # Source-specific pelvis landmarks, verified on contact sheets.
                hip = HIP_X[sheet][slot]
                actors[number] = (actor, hip-bbox[0], foot-bbox[1])
                actor.save(REVIEW / f'isolated_{number:02d}.png')
                diagnostics.append(dict(id=number, source=target.name, slot=slot+1,
                                        rawRect=list(rect), bbox=list(bbox), hipX=hip, footY=foot))
            board.save(REVIEW / f'sheet_{sheet+1:02d}.png')
        else:
            labels, comps = extractor.connected_components(rgba[:, :, 3] > 0)
            arrows = sorted(sorted(comps, key=lambda c: c['area'], reverse=True)[:8], key=lambda c:c['x0'])
            for i, c in enumerate(arrows):
                arrow = image.crop((c['x0'], c['y0'], c['x1']+1, c['y1']+1))
                arrow.save(REVIEW / f'arrow_{i+1:02d}.png')
            # Horizontal first arrow: no artificial rotations or flight wobble.
            shutil.copy2(REVIEW / 'arrow_01.png', OUT / 'arrow.png')
    (REVIEW / 'extraction.json').write_text(json.dumps(diagnostics, indent=2), encoding='utf-8')
    if args.review:
        return
    plan = json.loads((OUT / 'selection.json').read_text(encoding='utf-8'))
    ids = plan['atlasFrames']
    half = max(max(actors[i][1], actors[i][0].width-actors[i][1]) for i in ids)+8
    top = max(actors[i][2] for i in ids)+8
    bottom = max(actors[i][0].height-actors[i][2] for i in ids)+8
    width, height = half*2, top+bottom
    # Native pixels require two pages: a single atlas would exceed 4096px.
    columns, page_capacity = 4, 16
    atlas_pages = [Image.new('RGBA', (width*columns, height*4))
                   for _ in range((len(ids)+page_capacity-1)//page_capacity)]
    frames = {}
    for index, number in enumerate(ids):
        actor, x, y = actors[number]
        canvas = Image.new('RGBA', (width, height))
        canvas.paste(actor, (half-x, top-y))
        canvas.save(OUT / f'frame_{number:02d}.png')
        frames[number] = canvas
        slot = index % page_capacity
        atlas_pages[index//page_capacity].paste(canvas, (slot%columns*width, slot//columns*height))
    page_names = ['normal_attack.png'] + [f'normal_attack_{i+1:02d}.png' for i in range(1,len(atlas_pages))]
    for page, name in zip(atlas_pages, page_names):
        assert page.width <= 4096 and page.height <= 4096
        page.save(OUT / name)
    for index, number in enumerate(ids):
        slot = index % page_capacity
        page = Image.open(OUT / page_names[index//page_capacity])
        rect = (slot%columns*width, slot//columns*height,
                (slot%columns+1)*width, (slot//columns+1)*height)
        assert page.crop(rect).tobytes() == frames[number].tobytes()
    plan.update(columns=columns, pageCapacity=page_capacity, atlasPages=page_names,
                width=width, height=height, anchorX=half/width,
                anchorY=top/height, sources=[f'source_{i:02d}.png' for i in range(1,11)],
                sourceFrameCount=45, arrowCandidateCount=8,
                muzzleX=half+125, muzzleY=top-400,
                extraction='lossless minimum-alpha seams; integer pelvis/foot placement')
    timeline = []
    ticks = 0
    for number, hold in zip(plan['attackFrames'], plan['holdTicks']):
        for _ in range(hold):
            name = f'tick_{ticks:03d}.png'
            path = REVIEW / '24fps' / name
            path.parent.mkdir(exist_ok=True)
            frames[number].save(path)
            assert Image.open(path).tobytes() == frames[number].tobytes()
            timeline.append(dict(tick=ticks, frame=number, path=f'24fps/{name}',
                                 rgbaSha256=hashlib.sha256(frames[number].tobytes()).hexdigest()))
            ticks += 1
    plan['stepTimes'] = [t/24 for t in plan['holdTicks']]
    plan['releaseTime'] = sum(plan['holdTicks'][:plan['attackFrames'].index(plan['releaseFrame'])])/24
    plan['duration'] = ticks/24
    release_tick = sum(plan['holdTicks'][:plan['attackFrames'].index(plan['releaseFrame'])])
    plan['events'] = [dict(type='spawn_arrow', tick=release_tick,
                           sourceFrame=plan['releaseFrame'], muzzleOffset=[125,-400])]
    plan['movement'] = dict(defaultRunSpeed=120, phaseSpeedRatios=SPEED_RATIOS,
                            space='world; PNG pixels never transformed')
    distance = 0.0
    for row in timeline:
        phase = plan['phases'][plan['attackFrames'].index(row['frame'])]
        row.update(phase=phase, worldPosition=[round(distance,6),0],
                   events=['spawn_arrow'] if row['tick'] == release_tick else [])
        distance += 120*SPEED_RATIOS[phase]/24
    # Rough adjacent-pose comparison on the same integer-aligned canvas.
    metrics = []
    previous = None
    for number in range(1,46):
        actor, x, y = actors[number]
        candidate = Image.new('RGBA', (1000,1000))
        candidate.paste(actor, (500-x,800-y))
        pixels = np.array(candidate)
        visible = pixels[:,:,3] > 80
        ys, xs = np.nonzero(visible)
        row = dict(id=number, centroid=[round(float(xs.mean()),2),round(float(ys.mean()),2)],
                   retained=number in ids, review=plan['review'][str(number)])
        if previous is not None:
            old = previous[:,:,3]>80
            row['silhouetteIoUWithPrevious'] = round(float((old&visible).sum()/max(1,(old|visible).sum())),4)
            row['rgbaMeanAbsDifferenceWithPrevious'] = round(float(np.abs(pixels.astype(np.int16)-previous.astype(np.int16)).mean()),4)
        metrics.append(row)
        previous = pixels
    (REVIEW / 'adjacent_frame_metrics.json').write_text(json.dumps(metrics,ensure_ascii=False,indent=2),encoding='utf-8')
    (OUT / 'normal_attack.json').write_text(json.dumps(plan, ensure_ascii=False, indent=2), encoding='utf-8')
    (REVIEW / 'timeline_24fps.json').write_text(json.dumps(timeline, indent=2), encoding='utf-8')
    board = Image.new('RGB', (1500, 540*((len(ids)+4)//5)), '#344052')
    draw = ImageDraw.Draw(board)
    for index, number in enumerate(ids):
        frame = frames[number].copy()
        frame.thumbnail((300,500), Image.Resampling.NEAREST)
        x, y = index%5*300, index//5*540
        board.paste(frame, (x,y+30), frame)
        draw.text((x+5,y+8), f'{number:02d}', fill='white')
    board.save(REVIEW / 'selected_contact_sheet.png')
    preview = []
    for number in plan['attackFrames']:
        frame = frames[number].copy()
        frame.thumbnail((600,650), Image.Resampling.NEAREST)
        bg = Image.new('RGB', frame.size, '#344052')
        bg.paste(frame,(0,0),frame)
        preview.append(bg)
    preview[0].save(REVIEW / 'attack_preview.gif', save_all=True, append_images=preview[1:],
                    duration=[round(t*1000) for t in plan['stepTimes']], loop=0)
    lines = ['# フレーム採否（番号は時刻順、1始まり）', '', '|番号|採否|区間・理由|秒|', '|---|---|---|---|']
    for d in diagnostics:
        number = d['id']
        kept = number in plan['attackFrames']
        row = plan['review'][str(number)]
        seconds = f"{plan['stepTimes'][plan['attackFrames'].index(number)]:.6f}" if kept else '—'
        lines.append(f"|{number:02d}|{'採用' if kept else '除外'}|{row}|{seconds}|")
    (REVIEW / 'frame_review.md').write_text('\n'.join(lines)+'\n', encoding='utf-8')
    (REVIEW / 'verification.json').write_text(json.dumps(dict(
        sourceArchives=source_hashes, extractedCharacterCandidates=45,
        arrowCandidates=8, retainedFrames=len(ids), verified24fpsTicks=ticks,
        rgbaTickEquality=True, atlasSlotEquality=True,
        atlasDimensions=[list(p.size) for p in atlas_pages],
        duration=plan['duration'], releaseTime=plan['releaseTime']),indent=2),encoding='utf-8')
    print(f'Built {len(ids)} atlas frames, {ticks} verified 24fps ticks; {width}x{height}px')

if __name__ == '__main__':
    main()
