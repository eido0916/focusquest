from pathlib import Path
from PIL import Image, ImageDraw
import numpy as np, json, shutil

ROOT=Path(__file__).resolve().parent.parent
BASE=ROOT/'players/character_01'
SOURCES={
 'run':r'C:\Users\yuusy\.codex\generated_images\01a11fcc-8481-74b0-a008-feaf5145dc5e\exec-d7b7ecfd-4963-49db-99fa-db2c7ca10a9f.png',
 'attack_down':r'C:\Users\yuusy\.codex\generated_images\01a11fcc-8481-74b0-a008-feaf5145dc5e\exec-746d5d2f-7a40-472d-b9d6-f49431ee2e82.png',
 'skill_wave':r'C:\Users\yuusy\.codex\generated_images\01a11fcc-8481-74b0-a008-feaf5145dc5e\exec-0b608f56-0b99-49b7-85c0-a008ec42c880.png',
}

def hair_box(im):
 a=np.asarray(im).astype(float);r,g,b,alpha=a.transpose(2,0,1)
 mask=((r>135)&(g>85)&(r>g*1.10)&(b<g*.83)&(alpha>127)).astype('uint8')*255
 mask=Image.fromarray(mask)
 candidates=[]
 while mask.getbbox():
  arr=np.asarray(mask);ys,xs=np.where(arr>0);x,y=int(xs[0]),int(ys[0])
  copy=mask.copy();ImageDraw.floodfill(copy,(x,y),128)
  component=np.asarray(copy)==128
  yy,xx=np.where(component);bbox=(int(xx.min()),int(yy.min()),int(xx.max()+1),int(yy.max()+1))
  candidates.append((len(xx),bbox));arr=np.asarray(mask).copy();arr[component]=0;mask=Image.fromarray(arr)
 return max(candidates)[1]

idle=Image.open(BASE/'idle/keyframes/frame_000.png').convert('RGBA').resize((64,64),Image.Resampling.NEAREST)
target_head=hair_box(idle);target_h=target_head[3]-target_head[1]
target_x=(target_head[0]+target_head[2])/2
report=[];samples=[idle.resize((256,256),Image.Resampling.NEAREST)]
for action,p in SOURCES.items():
 atlas=Image.open(p).convert('RGBA');w,h=atlas.size
 n={'run':6,'attack_down':8,'skill_wave':12}[action];rows=(n+3)//4
 dest=ROOT/'source/hero_proportions_v002'/action
 for sub in ['frames','frames_24fps','source']:(dest/sub).mkdir(parents=True,exist_ok=True)
 shutil.copy2(p,dest/'source/generated_atlas.png')
 old=json.loads((BASE/action/'animation.json').read_text(encoding='utf-8'))
 raw=[]
 for i in range(n):
  x,y=i%4,i//4
  im=atlas.crop((round(x*w/4),round(y*h/rows),round((x+1)*w/4),round((y+1)*h/rows))).resize((64,64),Image.Resampling.BOX)
  im.putalpha(im.getchannel('A').point(lambda v:255 if v>=128 else 0))
  head=hair_box(im);bbox=im.getbbox()
  if i==0:action_scale=target_h/(head[3]-head[1])
  scale=action_scale
  a=np.asarray(im).astype(float);r,g,b,alpha=a.transpose(2,0,1)
  boot=(alpha>0)&(r>g*1.04)&(g>b*1.04)&(r<165)
  boot[:head[3]+3]=False
  yy,xx=np.where(boot);sole=int(yy.max()+1)
  ground=57-([2,1,0,2,1,0][i] if action=='run' else 0)
  # One-time raster preparation of freshly redrawn originals, never a runtime transform.
  tx=target_x-(head[0]+head[2])/2*scale;ty=ground-sole*scale
  bbox=im.getbbox();left=bbox[0]*scale+tx;right=bbox[2]*scale+tx
  if right>63:tx-=right-63
  if bbox[0]*scale+tx<1:tx+=1-(bbox[0]*scale+tx)
  assert (bbox[2]-bbox[0])*scale<=62,(action,i,'too wide',bbox,scale)
  posed=im.transform((64,64),Image.Transform.AFFINE,(1/scale,0,-tx/scale,0,1/scale,-ty/scale),Image.Resampling.NEAREST)
  assert posed.getbbox()[0]>0 and posed.getbbox()[2]<64,(action,i,posed.getbbox())
  assert bbox[1]*scale+ty>=1 and bbox[3]*scale+ty<=63,(action,i,'vertical clipping',bbox,scale,ty)
  raw.append(posed)
  report.append({'action':action,'keyframe':i,'head_hair_height_logical_px':hair_box(posed)[3]-hair_box(posed)[1],'ground_logical_px':ground,'source_scale_once':scale})
 # One shared palette for the complete action; retain discrete pixel clusters.
 mosaic=Image.new('RGB',(64*n,64))
 for i,im in enumerate(raw):mosaic.paste(im.convert('RGB'),(i*64,0))
 palette=mosaic.quantize(colors=40,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE)
 frames=[]
 for i,im in enumerate(raw):
  q=im.convert('RGB').quantize(palette=palette,dither=Image.Dither.NONE).convert('RGBA');q.putalpha(im.getchannel('A'))
  q=q.resize((128,128),Image.Resampling.NEAREST);frames.append(q);q.save(dest/'frames'/f'frame_{i:03}.png')
 for row in old['timeline']:frames[row['keyframe']].save(dest/'frames_24fps'/f'frame_{row["tick"]:03}.png')
 (dest/'animation.json').write_text(json.dumps({'fps':24,'loop_in_game':old['loop_in_game'],'events':old['events'],'reference':'unchanged idle keyframes','logical_grid':[64,64],'head_hair_height_logical_px':target_h,'ground_logical_px':57,'production':'Redrawn with built-in imagegen; once normalized for export. All playback images are exact original-frame holds.'},ensure_ascii=False,indent=2),encoding='utf-8')
 samples.append(frames[0].resize((256,256),Image.Resampling.NEAREST))
sheet=Image.new('RGB',(1024,288),'#dbe4ed');draw=ImageDraw.Draw(sheet)
for i,im in enumerate(samples):sheet.paste(im,(i*256,24),im);draw.text((i*256+12,8),['idle','run','attack','skill'][i],fill='#29384b')
sheet.save(ROOT/'character_01_proportions_comparison.png')
(ROOT/'source/hero_proportions_v002/measurements.json').write_text(json.dumps({'reference_hair_bbox_logical':target_head,'reference_ground_y':57,'frames':report},indent=2),encoding='utf-8')
print(json.dumps(report,indent=2))
