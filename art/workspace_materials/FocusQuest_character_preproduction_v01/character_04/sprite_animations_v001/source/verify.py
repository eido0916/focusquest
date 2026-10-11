from pathlib import Path
from PIL import Image, ImageSequence
import json, zipfile

root=Path(__file__).resolve().parent.parent
decoded=0
for path in root.rglob('*.png'):
 with Image.open(path) as im:im.load()
 decoded+=1
report={}
for name,expected,ticks,ms in [('run',8,16,667),('slam',8,36,1500),('charged_sweep',12,48,2000)]:
 folder=root/name;meta=json.loads((folder/'animation.json').read_text(encoding='utf-8'))
 assert len(list((folder/'frames').glob('*.png')))==expected
 assert len(list((folder/'frames_24fps').glob('*.png')))==ticks
 assert len(meta['display_frame_sequence'])==ticks
 for tick,keyframe in enumerate(meta['display_frame_sequence']):
  with Image.open(folder/'frames_24fps'/f'frame_{tick:03}.png') as frame,Image.open(folder/'frames'/f'character_04_{name}_{keyframe:02}.png') as original:
   assert frame.tobytes()==original.tobytes()
 with Image.open(folder/'preview/animation.png') as apng:
  duration=sum(f.info.get('duration',0) for f in ImageSequence.Iterator(apng))
  assert abs(duration-ms)<1
 with Image.open(folder/'preview/animation.gif') as gif:
  gifduration=sum(f.info.get('duration',0) for f in ImageSequence.Iterator(gif))
  assert abs(gifduration-ms)<=5
 report[name]={'keyframes':expected,'display_frames':ticks,'apng_duration_ms':duration,'gif_duration_ms':gifduration,'sequence_matches_keyframes':True}
archive=root.parent/'character_04_run_slam_charged_sweep_v001.zip'
with zipfile.ZipFile(archive) as z:
 assert z.testzip() is None
 names=set(z.namelist())
 assert f'{root.name}/README.md' in names
print(json.dumps({'decoded_pngs':decoded,'animations':report,'zip_integrity':'passed','zip_size_mb':round(archive.stat().st_size/1048576,2)},indent=2))
