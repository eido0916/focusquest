from pathlib import Path
import json,zipfile
import numpy as np
from PIL import Image
import renderer as m
out=m.OUT
result={}
for style in ['illustration','pixel']:
 artist=m.Artist(style)
 records=json.loads((out/style/'source/frame_transforms.json').read_text(encoding='utf-8'))
 rendered=[];grip_errors=[]
 size=128 if style=='pixel' else 1024
 for record in records:
  canvas=Image.new('RGBA',(size,size))
  for n in sorted(m.NAMES,key=lambda n:m.Z[n]):
   mat=np.array(record['parts'][n]);inv=np.linalg.inv(np.diag([size/256,size/256,1])@mat)
   piece=artist.images[n].transform((size,size),Image.Transform.AFFINE,tuple(inv[:2].ravel()),Image.Resampling.NEAREST if style=='pixel' else Image.Resampling.BICUBIC)
   canvas.alpha_composite(piece)
  rendered.append(canvas if style=='pixel' else canvas.resize((256,256),Image.Resampling.LANCZOS))
  src=artist.sources['sword'][0];sword=artist.images['sword']
  point=np.array(record['parts']['sword'])@np.array([src[0]*sword.width,src[1]*sword.height,1])
  grip_errors.append(float(np.linalg.norm(point[:2]-m.skeleton(record['time_seconds'])[0]['grip'])))
 if style=='pixel':rendered=[f.resize((256,256),Image.Resampling.NEAREST) for f in m.quantize_fixed(rendered,32,True)]
 for f,im in enumerate(rendered):
  actual=Image.open(out/style/'runtime/run'/f'character_01_{style}_run_{f:04}.png').convert('RGBA')
  assert np.array_equal(np.array(im),np.array(actual)),(style,f,'recomposition mismatch')
 assert max(grip_errors)<1e-8
 result[style]={'serialized_matrix_recomposition_exact_frames':len(rendered),'sword_grip_error_max_px':max(grip_errors)}
 print(style,result[style],flush=True)
(out/'recomposition_verification.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
archive=out.parent/'character_01_recomposition_v004.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
 for p in out.rglob('*'):
  if p.is_file() and '__pycache__' not in p.parts:z.write(p,p.relative_to(out.parent))
print('ZIP',archive.stat().st_size,flush=True)
