from pathlib import Path
from PIL import Image,ImageDraw
import numpy as np,json,shutil
ROOT=Path(__file__).resolve().parent.parent
SRC=ROOT/'source/hero_swordsman_v005'
def hair_box(im):
 a=np.asarray(im).astype(float);r,g,b,alpha=a.transpose(2,0,1)
 mask=Image.fromarray(((r>135)&(g>85)&(r>g*1.1)&(b<g*.83)&(alpha>127)).astype('uint8')*255)
 candidates=[]
 while mask.getbbox():
  arr=np.asarray(mask);ys,xs=np.where(arr>0);copy=mask.copy();ImageDraw.floodfill(copy,(int(xs[0]),int(ys[0])),128)
  component=np.asarray(copy)==128;yy,xx=np.where(component)
  candidates.append((len(xx),(int(xx.min()),int(yy.min()),int(xx.max()+1),int(yy.max()+1))))
  arr=np.asarray(mask).copy();arr[component]=0;mask=Image.fromarray(arr)
 return max(candidates)[1]
HOLDS={'run':[2]*8,'attack_down':[3,3,3,4,1,3,3,4],'skill_wave':[3,4,5,6,6,3,3,1,2,3,3,3]}
EVENTS={'run':[{'event':'foot_contact','foot':'right','tick':0},{'event':'foot_contact','foot':'left','tick':8}], 'attack_down':[{'event':'slash_active','tick':13,'keyframe':4}], 'skill_wave':[{'event':'charge_begin','tick':7,'keyframe':2},{'event':'charged','tick':24,'keyframe':5},{'event':'slash_active','tick':30,'keyframe':7},{'event':'wave_release','tick':31,'keyframe':8}]}
inputs=json.loads((SRC/'inputs.json').read_text(encoding='utf-8'));all_frames={};report=[]
for action,p in inputs.items():
 dest=SRC/action
 for sub in ['frames','frames_24fps','source']:(dest/sub).mkdir(parents=True,exist_ok=True)
 shutil.copy2(p,dest/'source/generated_atlas.png')
 atlas=Image.open(p).convert('RGBA');w,h=atlas.size;n=len(HOLDS[action]);rows=n//4;raw=[]
 for i in range(n):
  x,y=i%4,i//4
  im=atlas.crop((round(x*w/4),round(y*h/rows),round((x+1)*w/4),round((y+1)*h/rows))).resize((64,64),Image.Resampling.BOX)
  im.putalpha(im.getchannel('A').point(lambda v:255 if v>=160 else 0))
  head=hair_box(im);bbox=im.getbbox()
  a=np.asarray(im).astype(float);r,g,b,alpha=a.transpose(2,0,1)
  boot=(alpha>0)&(r>g*1.04)&(g>b*1.04)&(r<165);boot[:head[3]+3]=False
  yy,xx=np.where(boot);sole=int(yy.max()+1)
  if i==0:scale=43/(sole-bbox[1])
  ground=57-([0,0,1,3,0,0,1,3][i] if action=='run' else 0)
  tx=33-(head[0]+head[2])/2*scale;ty=ground-sole*scale
  if bbox[2]*scale+tx>63:tx-=bbox[2]*scale+tx-63
  if bbox[0]*scale+tx<1:tx+=1-(bbox[0]*scale+tx)
  assert (bbox[2]-bbox[0])*scale<=62,(action,i,'too wide',bbox,scale)
  assert bbox[1]*scale+ty>=1-1e-6 and bbox[3]*scale+ty<=63,(action,i,'vertical clipping',bbox,scale,ty)
  posed=im.transform((64,64),Image.Transform.AFFINE,(1/scale,0,-tx/scale,0,1/scale,-ty/scale),Image.Resampling.NEAREST)
  raw.append(posed);report.append({'action':action,'keyframe':i,'scale_once_constant_per_action':scale,'sole_y_px':ground*2,'bbox':posed.getbbox()})
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
 (dest/'animation.json').write_text(json.dumps({'fps':24,'loop_in_game':action=='run','events':EVENTS[action],'logical_grid':[64,64],'display_frame_sequence':sequence,'holds_ticks':HOLDS[action],'duration_seconds':len(sequence)/24,'root_motion':'none','reference':'1.png identity and v001 idle proportions','production':'Full original poses generated using built-in imagegen; normalized once at export. No runtime part transforms/interpolation.'},ensure_ascii=False,indent=2),encoding='utf-8')
 all_frames[action]=frames
sheet=Image.new('RGB',(1024,288),'#dbe4ed');d=ImageDraw.Draw(sheet)
idle=Image.open(ROOT/'players/character_01/idle/keyframes/frame_000.png').convert('RGBA')
for i,(action,im) in enumerate([('idle',idle)]+[(a,f[0]) for a,f in all_frames.items()]):
 im=im.resize((256,256),Image.Resampling.NEAREST);sheet.paste(im,(i*256,24),im);d.text((i*256+12,8),action,fill='#29384b')
sheet.save(ROOT/'swordsman_comparison.png')
(SRC/'measurements.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print('Prepared28 original poses,82 exact24fps hold frames')
