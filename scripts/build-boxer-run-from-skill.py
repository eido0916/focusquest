"""Reuse the exact original pre-skill run PNGs; never redraw/resample them."""
from pathlib import Path
import json
import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'mobile/assets/images/characters/boxer/skills/front_kick'
OUT = ROOT / 'mobile/assets/images/characters/boxer/run_from_skill'
REVIEW = ROOT / 'artifacts/boxer_run_from_skill_review'
OUT.mkdir(parents=True, exist_ok=True)
REVIEW.mkdir(parents=True, exist_ok=True)
skill = json.loads((SOURCE / 'front_kick.json').read_text(encoding='utf-8'))
ids = [1, 2, 3, 4]  # 5 is the grounded guard transition, not a running pose.
w, h = skill['width'], skill['height']
atlas = Image.new('RGBA', (w*len(ids), h))
poses = []
for slot, number in enumerate(ids):
    pose = Image.open(SOURCE / f'frame_{number:02d}.png').convert('RGBA')
    assert pose.size == (w,h)
    pose.save(OUT / f'frame_{number:02d}.png')
    atlas.paste(pose, (slot*w,0))
    poses.append(pose)
atlas.save(OUT / 'run.png')
saved = Image.open(OUT / 'run.png')
for slot, pose in enumerate(poses):
    assert np.array_equal(np.array(saved.crop((slot*w,0,(slot+1)*w,h))), np.array(pose))
skill_atlas = Image.open(SOURCE / 'front_kick.png')
assert np.array_equal(np.array(poses[-1]), np.array(skill_atlas.crop((0,0,w,h))))
metadata = dict(width=w,height=h,columns=len(ids),frameIds=ids,fps=12,
    stepTimes=[1/12]*len(ids),anchorX=skill['anchorX'],anchorY=skill['anchorY'],
    displayHeight=h*skill['sourcePixelDisplayScale'],
    source='characters/boxer/skills/front_kick/frame_01.png..frame_04.png',
    loopSeconds=len(ids)/12,worldCoordinateEvents=[],
    verification='RGBA identical to pre-skill PNGs; frame 4 identical to skill first atlas frame')
(OUT / 'run.json').write_text(json.dumps(metadata,ensure_ascii=False,indent=2),encoding='utf-8')
ticks = REVIEW / 'frames_24fps'
ticks.mkdir(exist_ok=True)
for tick in range(len(ids)*2):
    path = ticks / f'run_{tick:03d}.png'
    poses[tick//2].save(path)
    assert np.array_equal(np.array(Image.open(path)), np.array(poses[tick//2]))
metadata['ticks'] = [dict(tick=t,frame=ids[t//2]) for t in range(len(ids)*2)]
(REVIEW / 'timeline_24fps.json').write_text(json.dumps(metadata,indent=2),encoding='utf-8')
board = Image.new('RGB', (w*len(ids),h), '#384452')
preview = []
for i, pose in enumerate(poses):
    bg = Image.new('RGB', (w,h), '#384452')
    bg.paste(pose,(0,0),pose)
    ImageDraw.Draw(bg).text((16,16),f'Pre-skill run {ids[i]}',fill='white')
    board.paste(bg,(i*w,0))
    preview.append(bg)
board.save(REVIEW / 'selected.png')
preview[0].save(REVIEW / 'run_preview.gif',save_all=True,append_images=preview[1:],
    duration=[80,90,80,80],loop=0)
print('Verified: 4 original pre-skill run poses, 8 exact repeated 24fps frames')
