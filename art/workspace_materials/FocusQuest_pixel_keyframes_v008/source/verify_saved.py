from pathlib import Path
from PIL import Image, ImageSequence
import hashlib, json, zipfile
import numpy as np

root=Path(__file__).resolve().parent.parent
catalog=json.loads((root/'catalog.json').read_text(encoding='utf-8'))
count=0;key_count=0
for item in catalog['animations']:
 folder=root/item['folder'];meta=json.loads((folder/'animation.json').read_text(encoding='utf-8'))
 assert meta['interpolation']=='none' and meta['part_transforms'] is False and meta['crossfade'] is False
 assert len(meta['timeline'])==item['display_frames']
 hashes=[]
 for key in meta['keyframes']:
  with Image.open(folder/key['file']) as im:
   im=im.convert('RGBA');a=np.array(im);assert im.size==(128,128)
   assert set(np.unique(a[:,:,3]))<={0,255}
   h=hashlib.sha256(im.tobytes()).hexdigest();assert h==key['rgba_sha256'];hashes.append(h);key_count+=1
 for row in meta['timeline']:
  with Image.open(folder/row['file']) as im:h=hashlib.sha256(im.convert('RGBA').tobytes()).hexdigest()
  assert h==hashes[row['keyframe']],(folder,row['tick']);count+=1
 assert sum(row['ticks'] for row in meta['holds'])==len(meta['timeline'])
 with Image.open(folder/'preview/animation.png') as im:
  duration=sum(frame.info.get('duration',0) for frame in ImageSequence.Iterator(im))
  assert abs(duration-round(len(meta['timeline'])*1000/24))<1
report=json.loads((root/'verification.json').read_text(encoding='utf-8'))
report['independent_saved_file_verification']={'keyframes':key_count,'display_frames':count,'all_pixel_hashes_match':True,'all_assets_rgba_128_binary_alpha':True,'all_timelines_and_apng_durations_match':True,'interpolation_and_part_transforms_disabled':True}
(root/'verification.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
archive=root.parent/'FocusQuest_pixel_keyframes_v008.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
 for path in root.rglob('*'):
  if path.is_file():z.write(path,path.relative_to(root.parent))
with zipfile.ZipFile(archive) as z:assert z.testzip() is None
print(json.dumps({'characters':len(catalog['characters']),'animations':len(catalog['animations']),'verified_keyframes':key_count,'verified_display_frames':count,'zip_integrity':'passed','zip_size_mb':round(archive.stat().st_size/1048576,2)},ensure_ascii=False))

