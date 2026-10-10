from pathlib import Path
from PIL import Image, ImageDraw
import json, numpy as np

OUT=Path(__file__).resolve().parent/'hero_idle'
atlas=Image.open(OUT/'source/generated_atlas.png').convert('RGBA');W,H=atlas.size
raw=[];boxes=[]
for i in range(6):
 x=i%3;y=i//3
 im=atlas.crop((round(x*W/3),round(y*H/2),round((x+1)*W/3),round((y+1)*H/2))).resize((64,64),Image.Resampling.BOX)
 mask=im.getchannel('A').point(lambda v:255 if v>=128 else 0)
 ys,xs=np.where(np.array(mask)>0);seed=int(np.argmin((xs-32)**2+(ys-35)**2))
 marked=mask.copy();ImageDraw.floodfill(marked,(int(xs[seed]),int(ys[seed])),128,thresh=0)
 alpha=marked.point(lambda v:255 if v==128 else 0);im.putalpha(alpha)
 raw.append(im);boxes.append(alpha.getbbox())
scale=min(1.,44/max(b[3]-b[1] for b in boxes),56/max(b[2]-b[0] for b in boxes))
placed=[]
for im,b in zip(raw,boxes):
 tx=32-(b[0]+b[2])/2*scale;ty=57-b[3]*scale
 placed.append(im.transform((64,64),Image.Transform.AFFINE,(1/scale,0,-tx/scale,0,1/scale,-ty/scale),Image.Resampling.NEAREST))
placed[-1]=placed[0].copy()
mosaic=Image.new('RGB',(384,64),'#252938')
for i,im in enumerate(placed):mosaic.paste(im.convert('RGB'),(64*i,0),im.getchannel('A'))
palette=mosaic.quantize(colors=32,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE)
frames=[]
for i,im in enumerate(placed):
 q=im.convert('RGB').quantize(palette=palette,dither=Image.Dither.NONE).convert('RGBA');q.putalpha(im.getchannel('A'))
 q=q.resize((128,128),Image.Resampling.NEAREST);frames.append(q)
 (OUT/'frames').mkdir(parents=True,exist_ok=True);q.save(OUT/'frames'/f'hero_idle_{i:02}.png')
holds=[10,4,2,2,4,26];sequence=[i for i,h in enumerate(holds) for _ in range(h)]
(OUT/'frames_24fps').mkdir(parents=True,exist_ok=True)
for tick,index in enumerate(sequence):frames[index].save(OUT/'frames_24fps'/f'frame_{tick:03}.png')
(OUT/'animation.json').write_text(json.dumps({'fps':24,'loop_in_game':True,'interpolation':'none','part_transforms':False,'keyframe_holds_ticks':holds,'display_frame_sequence':sequence,'duration_seconds':2,'notice':'Each pose is a pixel drawing; production normalization occurs once, no runtime deformation.'},indent=2),encoding='utf-8')
print('Prepared six original idle keyframes and 48 exact hold frames')
