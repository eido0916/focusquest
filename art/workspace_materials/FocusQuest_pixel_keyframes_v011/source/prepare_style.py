from pathlib import Path
from PIL import Image,ImageDraw
import numpy as np,json,shutil
ROOT=Path(__file__).resolve().parent.parent
SRC=ROOT/'source/hero_style_v003'
BASE=ROOT/'players/character_01'
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
inputs=json.loads((SRC/'inputs.json').read_text(encoding='utf-8'))
all_frames={};metas={};report=[]
for action,p in inputs.items():
 dest=SRC/action
 for sub in ['frames','frames_24fps','source']:(dest/sub).mkdir(parents=True,exist_ok=True)
 shutil.copy2(p,dest/'source/generated_atlas.png')
 atlas=Image.open(p).convert('RGBA');w,h=atlas.size
 old=json.loads((BASE/action/'animation.json').read_text(encoding='utf-8'));n=len(old['keyframes']);rows=(n+3)//4
 raw=[]
 for i in range(n):
  x,y=i%4,i//4
  im=atlas.crop((round(x*w/4),round(y*h/rows),round((x+1)*w/4),round((y+1)*h/rows))).resize((64,64),Image.Resampling.BOX)
  im.putalpha(im.getchannel('A').point(lambda v:255 if v>=160 else 0))
  head=hair_box(im);bbox=im.getbbox()
  a=np.asarray(im).astype(float);r,g,b,alpha=a.transpose(2,0,1)
  boot=(alpha>0)&(r>g*1.04)&(g>b*1.04)&(r<165);boot[:head[3]+3]=False
  yy,xx=np.where(boot);sole=int(yy.max()+1)
  if i==0:scale=43/(sole-bbox[1])
  ground=58-([2,1,0,2,1,0][i] if action=='run' else 0)
  tx=33-(head[0]+head[2])/2*scale;ty=ground-sole*scale
  if bbox[2]*scale+tx>63:tx-=bbox[2]*scale+tx-63
  if bbox[0]*scale+tx<1:tx+=1-(bbox[0]*scale+tx)
  assert (bbox[2]-bbox[0])*scale<=62,(action,i,'too wide',bbox,scale)
  assert bbox[1]*scale+ty>=1-1e-6 and bbox[3]*scale+ty<=63,(action,i,'vertical clipping',bbox,scale,ty)
  posed=im.transform((64,64),Image.Transform.AFFINE,(1/scale,0,-tx/scale,0,1/scale,-ty/scale),Image.Resampling.NEAREST)
  raw.append(posed);report.append({'action':action,'keyframe':i,'preparation_scale_constant_per_action':scale,'ground_y':ground*2,'bbox':posed.getbbox(),'head_color_bbox':hair_box(posed)})
 if action=='idle':raw[-1]=raw[0].copy() # Matching idle endpoints; exclude hallucinated energy at final hold.
 all_frames[action]=raw;metas[action]=old
mosaic=Image.new('RGB',(64*sum(map(len,all_frames.values())),64));i=0
for frames in all_frames.values():
 for im in frames:mosaic.paste(im.convert('RGB'),(i*64,0));i+=1
palette=mosaic.quantize(colors=32,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE)
for action,raw in all_frames.items():
 dest=SRC/action;old=metas[action];frames=[]
 for i,im in enumerate(raw):
  q=im.convert('RGB').quantize(palette=palette,dither=Image.Dither.NONE).convert('RGBA');q.putalpha(im.getchannel('A'))
  q=q.resize((128,128),Image.Resampling.NEAREST);frames.append(q);q.save(dest/'frames'/f'frame_{i:03}.png')
 for row in old['timeline']:frames[row['keyframe']].save(dest/'frames_24fps'/f'frame_{row["tick"]:03}.png')
 (dest/'animation.json').write_text(json.dumps({'fps':24,'loop_in_game':old['loop_in_game'],'events':old['events'],'style_reference':['character_02','character_03','character_04','character_05'],'logical_grid':[64,64],'global_character_palette_colors':32,'production':'Built-in imagegen redraw followed by one-time original PNG export. No runtime deformation or interpolation.'},ensure_ascii=False,indent=2),encoding='utf-8')
 all_frames[action]=frames
comparison=Image.new('RGB',(1280,288),'#dbe4ed');draw=ImageDraw.Draw(comparison)
for i,c in enumerate(range(1,6)):
 im=all_frames['run'][0] if c==1 else Image.open(ROOT/f'players/character_{c:02}/run/keyframes/frame_000.png').convert('RGBA')
 comparison.paste(im.resize((256,256),Image.Resampling.NEAREST),(i*256,24),im.resize((256,256),Image.Resampling.NEAREST));draw.text((i*256+12,8),f'character_{c:02}',fill='#29384b')
comparison.save(ROOT/'player_style_comparison.png')
comparison=Image.new('RGB',(1024,288),'#dbe4ed');draw=ImageDraw.Draw(comparison)
for i,action in enumerate(inputs):
 im=all_frames[action][0].resize((256,256),Image.Resampling.NEAREST);comparison.paste(im,(i*256,24),im);draw.text((i*256+12,8),action,fill='#29384b')
comparison.save(ROOT/'character_01_proportions_comparison.png')
(SRC/'measurements.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print('Prepared32 original pixel drawings; shared32-color palette and64px logical grid')
