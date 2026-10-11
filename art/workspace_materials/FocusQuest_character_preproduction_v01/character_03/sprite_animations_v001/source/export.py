from pathlib import Path
from PIL import Image, ImageDraw
import numpy as np
import json, zipfile

OUT=Path(__file__).resolve().parent.parent
CONFIG={
 'run':(4,2,[2]*8),
 'iai':(4,2,[4,5,1,1,5,6,6,8]),
 'energy_flurry':(4,4,[3,3,4,6,7,2,1,1,1,1,1,1,1,3,5,8])
}
prepared={};clips={};checks={}
for name,(cols,rows,holds) in CONFIG.items():
 folder=OUT/name
 for sub in ['source','frames','frames_24fps','preview']:(folder/sub).mkdir(parents=True,exist_ok=True)
 atlas=Image.open(folder/'source/generated_atlas.png').convert('RGBA');W,H=atlas.size
 raw=[];boxes=[];face_centers=[];face_tops=[]
 for i in range(cols*rows):
  col=i%cols;row=i//cols
  bounds=[round(col*W/cols),round(row*H/rows),round((col+1)*W/cols),round((row+1)*H/rows)]
  logical_width=64
  if name=='iai' and i==4:
   # Recover the intact sword tip in the empty left gutter of the next cell.
   bounds[2]+=round(W/cols*.14);logical_width=73
  if name=='energy_flurry' and i==10:
   # Preserve the complete horizontal arc in the next cell's empty gutter.
   bounds[2]+=round(W/cols*.20);logical_width=77
  override=folder/'source'/f'override_{i:02}.png'
  im=Image.open(override).convert('RGBA').resize((64,64),Image.Resampling.BOX) if override.exists() else atlas.crop(bounds).resize((logical_width,64),Image.Resampling.BOX)
  a=np.array(im);rgb=a[:,:,:3].astype(float); yy,xx=np.indices(a.shape[:2])
  cyan=(rgb[:,:,2]>150)&(rgb[:,:,1]>140)&(rgb[:,:,2]>rgb[:,:,0]*1.12)
  mask=(a[:,:,3]>=128)
  if name=='energy_flurry':mask|=cyan&(a[:,:,3]>=64)
  pending=Image.fromarray((mask*255).astype(np.uint8));keep=np.zeros(a.shape[:2],np.uint8)
  while np.any(np.array(pending)):
   ys,xs=np.where(np.array(pending)>0);marked=pending.copy();ImageDraw.floodfill(marked,(int(xs[0]),int(ys[0])),128,thresh=0)
   component=np.array(marked)==128;ys,xs=np.where(component)
   border_speck=(xs.min()<=2 or xs.max()>=a.shape[1]-2) and component.sum()<100
   if name=='energy_flurry' and i==11 and xs.max()<14:border_speck=True
   if component.sum()>=2 and not border_speck:keep[component]=255
   pa=np.array(pending);pa[component]=0;pending=Image.fromarray(pa)
  im.putalpha(Image.fromarray(keep));box=im.getchannel('A').getbbox();assert box
  skin=(keep>0)&(rgb[:,:,0]>135)&(rgb[:,:,1]>80)&(rgb[:,:,0]>rgb[:,:,1]*1.10)&(rgb[:,:,0]>rgb[:,:,2]*1.20)&(yy<33)&(xx>12)&(xx<46)
  sy,sx=np.where(skin)
  if len(sy)>2:
   top=int(sy.min());fy,fx=np.where(skin&(yy<top+8))
   face_centers.append(float(fx.mean())-2);face_tops.append(max(0,top-8))
  else:
   face_centers.append(29.);face_tops.append(box[1])
  raw.append(im);boxes.append(box)
 bodyheight=np.median([b[3]-top for b,top in zip(boxes,face_tops)])
 scale=min(1.,44/bodyheight,58/max(b[2]-b[0] for b in boxes),54/max(b[3]-b[1] for b in boxes))
 placed=[];positions=[]
 for i,(im,b,cx) in enumerate(zip(raw,boxes,face_centers)):
  baseline=57-([0,0,0,3,0,0,0,3][i] if name=='run' else 0)
  tx=30-cx*scale;ty=baseline-b[3]*scale
  tx=max(3-b[0]*scale,min(tx,61-b[2]*scale));ty=max(3-b[1]*scale,min(ty,61-b[3]*scale))
  mat=np.array([[scale,0,tx],[0,scale,ty],[0,0,1]])
  inv=np.linalg.inv(mat)
  placed.append(im.transform((64,64),Image.Transform.AFFINE,tuple(inv[:2].ravel()),Image.Resampling.NEAREST))
  positions.append({'keyframe':i,'source_cell_to_logical_matrix':mat.tolist(),'baseline_logical':baseline})
 if name!='run':placed[-1]=placed[0].copy()
 prepared[name]=(placed,positions)

# Shared palette for all animations, with reserved blade-energy colors.
allraw=[im for placed,_ in prepared.values() for im in placed]
mosaic=Image.new('RGB',(64*len(allraw),64),'#242835')
for i,im in enumerate(allraw):mosaic.paste(im.convert('RGB'),(i*64,0),im.getchannel('A'))
palette=mosaic.quantize(colors=32,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE)
colors=palette.getpalette()[:96]+[32,151,232,64,218,255,178,245,255,240,254,255,255,255,255]
palette.putpalette(colors+[0]*(768-len(colors)))
for name,(cols,rows,holds) in CONFIG.items():
 folder=OUT/name;placed,positions=prepared[name];frames=[];audit=[]
 # Remove only obsolete PNGs produced by earlier exports of this animation.
 expected={f'character_03_{name}_{i:02}.png' for i in range(len(placed))}
 for old in (folder/'frames').glob(f'character_03_{name}_*.png'):
  if old.name not in expected:old.unlink()
 for i,im in enumerate(placed):
  fr=im.convert('RGB').quantize(palette=palette,dither=Image.Dither.NONE).convert('RGBA');fr.putalpha(im.getchannel('A'))
  fr=fr.resize((128,128),Image.Resampling.NEAREST);fr.save(folder/'frames'/f'character_03_{name}_{i:02}.png')
  a=np.array(fr);box=fr.getchannel('A').getbbox()
  assert box[0]>0 and box[1]>0 and box[2]<128 and box[3]<128,(name,i,box)
  assert fr.size==(128,128) and set(np.unique(a[:,:,3]))<={0,255}
  assert np.array_equal(a[::2,::2],a[1::2,::2]) and np.array_equal(a[::2,::2],a[::2,1::2])
  frames.append(fr);audit.append({'keyframe':i,'bounds':box,'transparent_128_2px_grid_safe_margin':True})
 sequence=[i for i,h in enumerate(holds) for _ in range(h)];clips[name]=[frames[i] for i in sequence]
 for tick,i in enumerate(sequence):frames[i].save(folder/'frames_24fps'/f'frame_{tick:03}.png')
 sheet=Image.new('RGBA',(cols*128,rows*128));contact=Image.new('RGB',(cols*256,rows*280),'#dbe4ed');d=ImageDraw.Draw(contact)
 for i,fr in enumerate(frames):
  sheet.alpha_composite(fr,(i%cols*128,i//cols*128));zoom=fr.resize((256,256),Image.Resampling.NEAREST)
  contact.paste(zoom,(i%cols*256,i//cols*280+24),zoom);d.text((i%cols*256+8,i//cols*280+5),f'{name} {i:02} / {holds[i]} ticks',fill='#29384b')
 sheet.save(folder/f'character_03_{name}_sheet.png');contact.save(folder/'preview/keyframes.png')
 preview=[]
 for fr in clips[name]:
  bg=Image.new('RGBA',(256,256),'#dbe4ed');bg.alpha_composite(fr.resize((256,256),Image.Resampling.NEAREST));preview.append(bg.convert('RGB'))
 durations=[round((i+1)*1000/24)-round(i*1000/24) for i in range(len(preview))]
 gifdur=[(round((i+1)*100/24)-round(i*100/24))*10 for i in range(len(preview))]
 preview[0].save(folder/'preview/animation.gif',save_all=True,append_images=preview[1:],duration=gifdur,loop=0,disposal=2)
 clips[name][0].save(folder/'preview/animation.png',save_all=True,append_images=clips[name][1:],duration=durations,loop=0,disposal=2,blend=0)
 events=[]
 if name=='run':events=[{'event':'foot_contact','keyframe':i,'tick':sum(holds[:i])} for i in [0,4]]
 if name=='iai':events=[{'event':'draw_cut_hit','keyframe':3,'tick':sum(holds[:3])},{'event':'resheathed','keyframe':6,'tick':sum(holds[:6])}]
 if name=='energy_flurry':events=[{'event':'charge_start','keyframe':2,'tick':sum(holds[:2])}]+[{'event':f'slash_{n+1}','keyframe':i,'tick':sum(holds[:i])} for n,i in enumerate([6,8,10,12])]
 meta={'character':'03','size':[128,128],'logical_grid':[64,64],'direction':'right','fps':24,'root':[60,114],'loop_in_game':name=='run','preview_loop':True,'keyframe_holds_ticks':holds,'display_frame_sequence':sequence,'duration_seconds':len(sequence)/24,'events_are_timing_suggestions':True,'events':events,'placements':positions,'effect_baked_in':name!='run'}
 (folder/'animation.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2),encoding='utf-8')
 unique=len({im.tobytes() for im in frames});assert unique>=len(frames)-1
 assert name=='run' or frames[0].tobytes()==frames[-1].tobytes()
 checks[name]={'keyframes':len(frames),'distinct_keyframes':unique,'display_frames':len(sequence),'duration_ms':sum(durations),'last_equals_first':frames[-1].tobytes()==frames[0].tobytes(),'frames':audit}
 if name=='iai':frames[0].save(OUT/'character_03_stand_128.png')

combined=[]
for i in range(48):
 bg=Image.new('RGB',(768,284),'#dbe4ed');d=ImageDraw.Draw(bg)
 for col,name in enumerate(CONFIG):
  tick=i%len(clips[name]) if name=='run' else min(i,len(clips[name])-1)
  fr=clips[name][tick].resize((256,256),Image.Resampling.NEAREST);bg.paste(fr,(col*256,28),fr);d.text((col*256+12,9),name,fill='#29384b')
 combined.append(bg)
combined[0].save(OUT/'comparison.gif',save_all=True,append_images=combined[1:],duration=[(round((i+1)*100/24)-round(i*100/24))*10 for i in range(48)],loop=0,disposal=2)
(OUT/'verification.json').write_text(json.dumps(checks,indent=2),encoding='utf-8')
with zipfile.ZipFile(OUT.parent/'character_03_run_iai_energy_flurry_v001.zip','w',zipfile.ZIP_DEFLATED) as z:
 for p in OUT.rglob('*'):
  if p.is_file():z.write(p,p.relative_to(OUT.parent))
print(json.dumps({k:{f:v[f] for f in ['keyframes','distinct_keyframes','display_frames','duration_ms']} for k,v in checks.items()}))
