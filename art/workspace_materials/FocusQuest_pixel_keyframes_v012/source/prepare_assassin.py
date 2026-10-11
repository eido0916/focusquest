from pathlib import Path
from PIL import Image,ImageDraw
import numpy as np,json,shutil
ROOT=Path(__file__).resolve().parent.parent
SRC=ROOT/'source/assassin_v006'
HOLDS={'run':[2]*8,'dagger_thrust':[3,3,3,3,1,3,3,5],'critical_strike':[3,4,5,6,6,6,3,1,2,3,3,4]}
EVENTS={'run':[{'event':'foot_contact','foot':'right','tick':0},{'event':'foot_contact','foot':'left','tick':8}], 'dagger_thrust':[{'event':'thrust_active','tick':12,'keyframe':4}], 'critical_strike':[{'event':'charge_begin','tick':12,'keyframe':3},{'event':'charged','tick':30,'keyframe':6},{'event':'critical_thrust_active','tick':33,'keyframe':7},{'event':'critical_impact','tick':34,'keyframe':8}]}
def face_center(im):
 a=np.asarray(im).astype(float);r,g,b,alpha=a.transpose(2,0,1)
 mask=((alpha>0)&(r>150)&(g>100)&(b>70)&(r>g*1.12)&(r<g*1.9))
 mask[34:]=False
 y,x=np.where(mask)
 assert len(x),'face not found'
 # The face is the largest warm-light component in the upper half; ignore hands.
 m=Image.fromarray(mask.astype('uint8')*255);c=[]
 while m.getbbox():
  y,x=np.where(np.asarray(m)>0);cp=m.copy();ImageDraw.floodfill(cp,(int(x[0]),int(y[0])),128)
  comp=np.asarray(cp)==128;yy,xx=np.where(comp);c.append((len(xx),float(xx.mean()),int(yy.max())))
  arr=np.asarray(m).copy();arr[comp]=0;m=Image.fromarray(arr)
 return max(c)[1:]
inputs=json.loads((SRC/'inputs.json').read_text(encoding='utf-8'));all_frames={};measurements=[]
for action,p in inputs.items():
 dest=SRC/action
 for sub in ['frames','frames_24fps','source']:(dest/sub).mkdir(parents=True,exist_ok=True)
 shutil.copy2(p,dest/'source/generated_atlas.png')
 atlas=Image.open(p).convert('RGBA');w,h=atlas.size;n=len(HOLDS[action]);rows=n//4;raw=[]
 for i in range(n):
  x,y=i%4,i//4
  im=atlas.crop((round(x*w/4),round(y*h/rows),round((x+1)*w/4),round((y+1)*h/rows))).resize((64,64),Image.Resampling.BOX)
  im.putalpha(im.getchannel('A').point(lambda v:255 if v>=128 else 0))
  # Remove isolated atlas-cell spill from the neighboring row, retaining the complete connected figure/effect.
  m=im.getchannel('A');components=[]
  while m.getbbox():
   yy,xx=np.where(np.asarray(m)>0);cp=m.copy();ImageDraw.floodfill(cp,(int(xx[0]),int(yy[0])),128)
   comp=np.asarray(cp)==128;components.append((int(comp.sum()),comp))
   arr=np.asarray(m).copy();arr[comp]=0;m=Image.fromarray(arr)
  main=max(components,key=lambda v:v[0])[1];ys,xs=np.where(main)
  allowed=np.zeros(main.shape,dtype=bool);allowed[max(0,ys.min()-2):min(64,ys.max()+3),max(0,xs.min()-2):min(64,xs.max()+3)]=True
  im.putalpha(Image.fromarray((np.asarray(im.getchannel('A'))*(allowed)).astype('uint8')))
  head_x,face_y=face_center(im);bbox=im.getbbox()
  a=np.asarray(im).astype(float);r,g,b,alpha=a.transpose(2,0,1)
  boot=(alpha>0)&(r<135)&(g<120)&(b<115);boot[:max(face_y+14,38)]=False
  yy,xx=np.where(boot);sole=int(yy.max()+1)
  if i==0:scale=48/(sole-bbox[1])
  ground=57-([0,0,1,3,0,0,1,3][i] if action=='run' else 0)
  tx=35-head_x*scale;ty=ground-sole*scale
  if bbox[2]*scale+tx>63:tx-=bbox[2]*scale+tx-63
  if bbox[0]*scale+tx<1:tx+=1-(bbox[0]*scale+tx)
  assert (bbox[2]-bbox[0])*scale<=62,(action,i,'too wide',bbox,scale)
  assert bbox[1]*scale+ty>=1-1e-6 and bbox[3]*scale+ty<=63,(action,i,'vertical clipping',bbox,scale,ty)
  posed=im.transform((64,64),Image.Transform.AFFINE,(1/scale,0,-tx/scale,0,1/scale,-ty/scale),Image.Resampling.NEAREST)
  raw.append(posed);measurements.append({'action':action,'keyframe':i,'scale_once_constant_per_action':scale,'sole_y_px':ground*2,'bbox':posed.getbbox()})
 all_frames[action]=raw
mosaic=Image.new('RGB',(64*28,64));i=0
for frames in all_frames.values():
 for im in frames:mosaic.paste(im.convert('RGB'),(i*64,0));i+=1
palette=mosaic.quantize(colors=40,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE)
for action,raw in all_frames.items():
 dest=SRC/action;frames=[]
 for i,im in enumerate(raw):
  q=im.convert('RGB').quantize(palette=palette,dither=Image.Dither.NONE).convert('RGBA');q.putalpha(im.getchannel('A'))
  q=q.resize((128,128),Image.Resampling.NEAREST);frames.append(q);q.save(dest/'frames'/f'frame_{i:03}.png')
 sequence=[i for i,h in enumerate(HOLDS[action]) for _ in range(h)]
 for t,i in enumerate(sequence):frames[i].save(dest/'frames_24fps'/f'frame_{t:03}.png')
 (dest/'animation.json').write_text(json.dumps({'fps':24,'loop_in_game':action=='run','events':EVENTS[action],'logical_grid':[64,64],'display_frame_sequence':sequence,'holds_ticks':HOLDS[action],'duration_seconds':len(sequence)/24,'root_motion':'none','reference':'6.png identity; character03/05 pixel style','production':'Separate original drawings made with built-in imagegen; once normalized for export. No playback transforms/interpolation.'},ensure_ascii=False,indent=2),encoding='utf-8')
 all_frames[action]=frames
sheet=Image.new('RGB',(768,288),'#dbe4ed');d=ImageDraw.Draw(sheet)
for i,(a,f) in enumerate(all_frames.items()):
 im=f[0].resize((256,256),Image.Resampling.NEAREST);sheet.paste(im,(i*256,24),im);d.text((i*256+12,8),a,fill='#29384b')
sheet.save(ROOT/'assassin_comparison.png')
(SRC/'measurements.json').write_text(json.dumps(measurements,indent=2),encoding='utf-8')
print('Prepared character06:28 original drawings')
