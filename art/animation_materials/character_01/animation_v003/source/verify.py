from pathlib import Path
from PIL import Image,ImageDraw
import json,numpy as np,hashlib,zipfile
import renderer as m
out=Path(__file__).resolve().parent.parent
checks={}
for style in ['illustration','pixel']:
 frames=sorted((out/style/'runtime/run').glob('*.png'));assert len(frames)==24;low=[];colors=set();sheet=Image.new('RGB',(1536,1120),'#dbe4ed');draw=ImageDraw.Draw(sheet)
 for f,path in enumerate(frames):
  im=Image.open(path);assert im.size==(256,256) and im.mode=='RGBA';a=np.array(im.getchannel('A'));p,fa,c=m.skeleton(f/24)
  for joint in ['shoulder_L','shoulder_R','elbow_L','elbow_R','wrist_L','wrist_R','hip_L','hip_R','knee_L','knee_R','ankle_L','ankle_R','grip']:
   x,y=p[joint];xx,yy=int(round(x)),int(round(y));patch=a[yy-1:yy+2,xx-1:xx+2]
   if patch.max()<128:low.append({'frame':f,'joint':joint,'max_alpha':int(patch.max())})
  if style=='pixel':
   arr=np.array(im);assert np.array_equal(arr[0::2,0::2],arr[1::2,0::2]);assert np.array_equal(arr[0::2,0::2],arr[0::2,1::2]);assert set(np.unique(arr[:,:,3]))=={0,255};colors.update(tuple(int(c) for c in v) for v in arr[arr[:,:,3]==255][:,:3])
  col=f%6;row=f//6;sheet.paste(im,(col*256,row*280+20),im);draw.text((col*256+8,row*280+4),f'{style} / F{f:02}',fill='black')
 sheet.save(out/style/'preview/all_24_poses.jpg');durations={}
 for ext in ['gif','png','webp']:
  im=Image.open(out/style/'preview'/f'run.{ext}');assert im.n_frames==24;total=0
  if ext!='webp':
   for f in range(im.n_frames):im.seek(f);total+=im.info.get('duration',0)
   assert abs(total-1000)<2
  durations[ext]={'frames':im.n_frames,'duration_ms':total if total else 'millisecond_timeline_in_encoder'}
 assert not low,(style,low)
 checks[style]={'files':len(frames),'rgba_dimensions_pass':True,'joint_alpha_coverage_failures':low,'preview_timings':durations,'pixel_2x2_blocks_pass':True if style=='pixel' else None,'opaque_color_count':len(colors) if style=='pixel' else None}
 if style=='pixel':(out/style/'source/runtime_palette_rgb.json').write_text(json.dumps(sorted(colors),indent=2),encoding='utf-8')
 # Export every piece transform so placement can be replayed without guessing pivots.
 artist=m.Artist(style);transforms=[]
 for f in range(24):
  mats,p,c=artist.matrices(f/24);transforms.append({'frame':f,'time_seconds':f/24,'matrix_convention':'column_vector;native_image_pixels_to_256_canvas;homogeneous3x3','parts':{n:mat.tolist() for n,mat in mats.items()}})
 (out/style/'source/frame_transforms.json').write_text(json.dumps(transforms,indent=2),encoding='utf-8')
checks['whole_cycle_ik_samples']=1001
for i in range(1001):m.skeleton(i/1000)
# C1 joins at liftoff and loop contact, using finite differences around boundaries.
velocity={}
for boundary in [0,.38,.52,.64,.80]:
 dt=1e-6;l=(m.foot_path(boundary)[0]-m.foot_path(boundary-dt)[0])/dt;r=(m.foot_path(boundary+dt)[0]-m.foot_path(boundary)[0])/dt;velocity[str(boundary)]={'left':l.tolist(),'right':r.tolist(),'difference':float(np.linalg.norm(l-r))};assert np.linalg.norm(l-r)<.02
checks['foot_velocity_join_checks']=velocity
(out/'verification.json').write_text(json.dumps(checks,indent=2),encoding='utf-8')
print(json.dumps(checks))
