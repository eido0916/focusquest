from pathlib import Path
from PIL import Image,ImageDraw
import numpy as np,json,shutil
ROOT=Path(__file__).resolve().parent.parent
SRC=ROOT/'source/enemy_defeat_v007'
HOLDS=[2,2,3,3,4,5,5,6]
inputs=json.loads((SRC/'inputs.json').read_text(encoding='utf-8'))
report=[]
for actor,p in inputs.items():
 dest=SRC/actor
 for sub in ['frames','frames_24fps','source']:(dest/sub).mkdir(parents=True,exist_ok=True)
 shutil.copy2(p,dest/'source/generated_atlas.png')
 reference=Image.open(ROOT/f'enemies/{actor}/locomotion/keyframes/frame_000.png').convert('RGBA')
 ref=reference.resize((64,64),Image.Resampling.NEAREST);rb=ref.getbbox()
 atlas=Image.open(p).convert('RGBA');w,h=atlas.size;raw=[];cells=[]
 for i in range(7):
  x,y=i%4,i//4
  im=atlas.crop((round(x*w/4),round(y*h/2),round((x+1)*w/4),round((y+1)*h/2))).resize((64,64),Image.Resampling.BOX)
  im.putalpha(im.getchannel('A').point(lambda v:255 if v>=128 else 0));b=im.getbbox()
  cells.append(im)
 b=cells[0].getbbox();scale=(rb[3]-rb[1])/(b[3]-b[1]);tx=(rb[0]+rb[2])/2-(b[0]+b[2])/2*scale;ty=rb[3]-b[3]*scale
 boxes=[im.getbbox() for im in cells]
 left=min(b[0] for b in boxes);right=max(b[2] for b in boxes);top=min(b[1] for b in boxes);bottom=max(b[3] for b in boxes)
 assert (right-left)*scale<=62 and (bottom-top)*scale<=62,(actor,'atlas pose extent',boxes,scale)
 tx=max(1-left*scale,min(tx,63-right*scale));ty=max(1-top*scale,min(ty,63-bottom*scale))
 for i,im in enumerate(cells):
  b=im.getbbox()
  assert b[0]*scale+tx>=1-1e-6 and b[2]*scale+tx<=63+1e-6 and b[1]*scale+ty>=1-1e-6 and b[3]*scale+ty<=63+1e-6,(actor,i,b,scale,tx,ty)
  posed=im.transform((64,64),Image.Transform.AFFINE,(1/scale,0,-tx/scale,0,1/scale,-ty/scale),Image.Resampling.NEAREST)
  raw.append(posed)
 raw.append(Image.new('RGBA',(64,64)))
 mosaic=Image.new('RGB',(512,64))
 for i,im in enumerate(raw):mosaic.paste(im.convert('RGB'),(i*64,0))
 palette=mosaic.quantize(colors=32,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE)
 frames=[]
 for i,im in enumerate(raw):
  q=im.convert('RGB').quantize(palette=palette,dither=Image.Dither.NONE).convert('RGBA');q.putalpha(im.getchannel('A'))
  q=q.resize((128,128),Image.Resampling.NEAREST)
  if i==0:q=reference.copy()
  if i==7:q=Image.new('RGBA',(128,128))
  frames.append(q);q.save(dest/'frames'/f'frame_{i:03}.png')
 seq=[i for i,n in enumerate(HOLDS) for _ in range(n)]
 offsets=[[round(44*(1-(1-min(t/12,1))**3)),0] for t in range(len(seq))]
 for t,k in enumerate(seq):frames[k].save(dest/'frames_24fps'/f'frame_{t:03}.png')
 meta={'fps':24,'loop_in_game':False,'holds_ticks':HOLDS,'display_frame_sequence':seq,'duration_seconds':len(seq)/24,'root_offsets_px':offsets,'direction':'left','knockback_direction':'right','root_motion_space':'world_px_absolute_offset','events':[{'event':'defeat_begin_disable_attack','tick':0},{'event':'knockback_complete','tick':12},{'event':'hide_sprite','tick':24}],'remove_actor_when_animation_complete':True,'final_keyframe_is_fully_transparent':True,'interpolation':'none','production':'Original drawn dissolution poses. Root coordinates move the actor; no image deformation or opacity fade.'}
 (dest/'animation.json').write_text(json.dumps(meta,indent=2),encoding='utf-8')
 report.append({'actor':actor,'keyframes':8,'display_ticks':30,'first_frame_identical_to_existing_neutral':True,'last_frame_transparent':True,'knockback_px':44,'fixed_export_scale':scale})
(SRC/'measurements.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps(report))
