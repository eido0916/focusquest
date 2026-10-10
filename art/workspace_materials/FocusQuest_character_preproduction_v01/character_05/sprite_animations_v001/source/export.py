from pathlib import Path
from PIL import Image, ImageDraw
import numpy as np
import json, zipfile

OUT=Path(__file__).resolve().parent.parent
CONFIG={
 'run':(4,2,[2]*8),
 'shuriken':(4,2,[4,4,3,1,2,4,8,10]),
 'teleport_stab':(4,3,[3,5,7,2,2,2,1,2,1,5,8,10])
}
prepared={};clips={};checks={}
for name,(cols,rows,holds) in CONFIG.items():
 folder=OUT/name
 for sub in ['source','frames','frames_24fps','preview']:(folder/sub).mkdir(parents=True,exist_ok=True)
 atlas=Image.open(folder/'source/generated_atlas.png').convert('RGBA');W,H=atlas.size
 # Generated atlases can have unequal row spacing. Split at the actual clear
 # gutters so boots from one row are not imported into the next sprite.
 occupancy=(np.array(atlas.getchannel('A'))>=128).sum(axis=1)
 rowbounds=[0]
 for row in range(1,rows):
  expected=row*H/rows;lo=max(rowbounds[-1]+1,round(expected-H/rows*.13));hi=min(H-1,round(expected+H/rows*.13))
  gaps=[];start=None
  for y in range(lo,hi+1):
   if occupancy[y]<=2 and start is None:start=y
   if (occupancy[y]>2 or y==hi) and start is not None:
    end=y if occupancy[y]>2 else y+1
    if end-start>=3:gaps.append((end-start,(start+end)//2))
    start=None
  cut=max(gaps,key=lambda g:(g[0],-abs(g[1]-expected)))[1] if gaps else round(expected)
  rowbounds.append(cut)
 rowbounds.append(H)
 side=max(round(W/cols),max(b-a for a,b in zip(rowbounds,rowbounds[1:])))
 if name in ['shuriken','teleport_stab']:side=max(side,round(W/cols*1.10))
 raw=[];boxes=[];face_centers=[];face_tops=[];source_crops=[]
 for i in range(cols*rows):
  col=i%cols;row=i//cols
  bounds=[round(col*W/cols),rowbounds[row],round((col+1)*W/cols),rowbounds[row+1]]
  if (name=='shuriken' and i==4) or (name=='teleport_stab' and i==8):
   # Recover the star/dagger tip in the clear gutter before the next sprite.
   bounds[2]+=round(W/cols*.10)
  logical_width=64
  override=folder/'source'/f'override_{i:02}.png'
  crop=atlas.crop(bounds);square=Image.new('RGBA',(side,side));square.alpha_composite(crop,((side-crop.width)//2,0))
  source_crops.append({'atlas_crop':bounds,'padded_square_size':side,'padding_offset':[(side-crop.width)//2,0]})
  im=Image.open(override).convert('RGBA').resize((64,64),Image.Resampling.BOX) if override.exists() else square.resize((logical_width,64),Image.Resampling.BOX)
  if name=='teleport_stab' and i==5:
   raw.append(Image.new('RGBA',(64,64)));boxes.append((30,36,31,37));face_centers.append(30.);face_tops.append(15)
   continue
  a=np.array(im);rgb=a[:,:,:3].astype(float); yy,xx=np.indices(a.shape[:2])
  energy=(rgb[:,:,2]>145)&(rgb[:,:,2]>rgb[:,:,1]*1.20)
  mask=(a[:,:,3]>=128)
  if name=='teleport_stab':mask|=energy&(a[:,:,3]>=64)
  pending=Image.fromarray((mask*255).astype(np.uint8));keep=np.zeros(a.shape[:2],np.uint8)
  while np.any(np.array(pending)):
   ys,xs=np.where(np.array(pending)>0);marked=pending.copy();ImageDraw.floodfill(marked,(int(xs[0]),int(ys[0])),128,thresh=0)
   component=np.array(marked)==128;ys,xs=np.where(component)
   border_speck=(xs.min()<=2 or xs.max()>=a.shape[1]-2) and component.sum()<100
   if ((name=='shuriken' and i==5) or (name=='teleport_stab' and i==9)) and xs.max()<18 and component.sum()<32:
    border_speck=True # Remove the preceding cell's detached weapon-tip fragment.
   if component.sum()>=2 and not border_speck:keep[component]=255
   pa=np.array(pending);pa[component]=0;pending=Image.fromarray(pa)
  im.putalpha(Image.fromarray(keep));box=im.getchannel('A').getbbox();assert box
  skin=(keep>0)&(rgb[:,:,0]>175)&(rgb[:,:,1]>100)&(rgb[:,:,0]>rgb[:,:,1]*1.20)&(rgb[:,:,0]>rgb[:,:,2]*1.20)&(yy<33)&(xx>12)&(xx<46)
  sy,sx=np.where(skin)
  if len(sy)>2:
   top=int(sy.min());fy,fx=np.where(skin&(yy<top+8))
   face_centers.append(float(fx.mean())-2);face_tops.append(max(0,top-8))
  else:
   face_centers.append(29.);face_tops.append(box[1])
  raw.append(im);boxes.append(box)
 bodyheight=np.median([b[3]-top for i,(b,top) in enumerate(zip(boxes,face_tops)) if not(name=='teleport_stab' and i in [3,4,5])])
 scale=min(1.,44/bodyheight,58/max(b[2]-b[0] for b in boxes),54/max(b[3]-b[1] for b in boxes))
 placed=[];positions=[]
 for i,(im,b,cx) in enumerate(zip(raw,boxes,face_centers)):
  baseline=57-([0,0,0,2,0,0,0,2][i] if name=='run' else 0)
  tx=30-cx*scale;ty=baseline-b[3]*scale
  if name=='teleport_stab' and i==4:
   tx=30-(b[0]+b[2])/2*scale;ty=36-(b[1]+b[3])/2*scale
  tx=max(3-b[0]*scale,min(tx,61-b[2]*scale));ty=max(3-b[1]*scale,min(ty,61-b[3]*scale))
  mat=np.array([[scale,0,tx],[0,scale,ty],[0,0,1]])
  inv=np.linalg.inv(mat)
  placed.append(im.transform((64,64),Image.Transform.AFFINE,tuple(inv[:2].ravel()),Image.Resampling.NEAREST))
  positions.append({'keyframe':i,'source_cell_to_logical_matrix':mat.tolist(),'baseline_logical':baseline,**source_crops[i]})
 if name!='run':placed[-1]=placed[0].copy()
 prepared[name]=(placed,positions)

# Shared palette for all animations, with reserved blade-energy colors.
allraw=[im for placed,_ in prepared.values() for im in placed]
mosaic=Image.new('RGB',(64*len(allraw),64),'#242835')
for i,im in enumerate(allraw):mosaic.paste(im.convert('RGB'),(i*64,0),im.getchannel('A'))
palette=mosaic.quantize(colors=32,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE)
colors=palette.getpalette()[:96]+[88,68,144,150,114,220,203,180,250,234,220,255,255,255,255,100,109,121,157,167,179,211,220,229,245,245,245]
palette.putpalette(colors+[0]*(768-len(colors)))
for name,(cols,rows,holds) in CONFIG.items():
 folder=OUT/name;placed,positions=prepared[name];frames=[];audit=[]
 # Remove only obsolete PNGs produced by earlier exports of this animation.
 expected={f'character_05_{name}_{i:02}.png' for i in range(len(placed))}
 for old in (folder/'frames').glob(f'character_05_{name}_*.png'):
  if old.name not in expected:old.unlink()
 for i,im in enumerate(placed):
  fr=im.convert('RGB').quantize(palette=palette,dither=Image.Dither.NONE).convert('RGBA');fr.putalpha(im.getchannel('A'))
  fr=fr.resize((128,128),Image.Resampling.NEAREST);fr.save(folder/'frames'/f'character_05_{name}_{i:02}.png')
  a=np.array(fr);box=fr.getchannel('A').getbbox()
  if name=='teleport_stab' and i==5:assert box is None
  else:assert box and box[0]>0 and box[1]>0 and box[2]<128 and box[3]<128,(name,i,box)
  assert fr.size==(128,128) and set(np.unique(a[:,:,3]))<={0,255}
  assert np.array_equal(a[::2,::2],a[1::2,::2]) and np.array_equal(a[::2,::2],a[::2,1::2])
  frames.append(fr);audit.append({'keyframe':i,'bounds':box,'transparent_128_2px_grid_safe_margin':True})
 sequence=[i for i,h in enumerate(holds) for _ in range(h)];clips[name]=[frames[i] for i in sequence]
 for tick,i in enumerate(sequence):frames[i].save(folder/'frames_24fps'/f'frame_{tick:03}.png')
 sheet=Image.new('RGBA',(cols*128,rows*128));contact=Image.new('RGB',(cols*256,rows*280),'#dbe4ed');d=ImageDraw.Draw(contact)
 for i,fr in enumerate(frames):
  sheet.alpha_composite(fr,(i%cols*128,i//cols*128));zoom=fr.resize((256,256),Image.Resampling.NEAREST)
  contact.paste(zoom,(i%cols*256,i//cols*280+24),zoom);d.text((i%cols*256+8,i//cols*280+5),f'{name} {i:02} / {holds[i]} ticks',fill='#29384b')
 sheet.save(folder/f'character_05_{name}_sheet.png');contact.save(folder/'preview/keyframes.png')
 preview=[]
 for tick,fr in enumerate(clips[name]):
  advance=64 if name=='teleport_stab' and sequence[tick]>=6 else 0
  bg=Image.new('RGBA',(320,180),'#dbe4ed');bg.alpha_composite(fr,(48+advance,20));preview.append(bg.convert('RGB'))
 durations=[round((i+1)*1000/24)-round(i*1000/24) for i in range(len(preview))]
 gifdur=[(round((i+1)*100/24)-round(i*100/24))*10 for i in range(len(preview))]
 preview[0].save(folder/'preview/animation.gif',save_all=True,append_images=preview[1:],duration=gifdur,loop=0,disposal=2)
 clips[name][0].save(folder/'preview/animation.png',save_all=True,append_images=clips[name][1:],duration=durations,loop=0,disposal=2,blend=0)
 events=[]
 if name=='run':events=[{'event':'foot_contact','keyframe':i,'tick':sum(holds[:i])} for i in [0,4]]
 if name=='shuriken':events=[{'event':'projectile_release','keyframe':3,'tick':sum(holds[:3])}]
 if name=='teleport_stab':events=[{'event':'vanish','keyframe':3,'tick':sum(holds[:3])},{'event':'teleport_forward','keyframe':6,'tick':sum(holds[:6]),'delta_px':[64,0]},{'event':'dagger_hit','keyframe':8,'tick':sum(holds[:8])}]
 meta={'root_motion_keyframes_px':[[64,0] if name=='teleport_stab' and i>=6 else [0,0] for i in range(len(frames))],'character':'05','size':[128,128],'logical_grid':[64,64],'direction':'right','fps':24,'root':[60,114],'loop_in_game':name=='run','preview_loop':True,'keyframe_holds_ticks':holds,'display_frame_sequence':sequence,'duration_seconds':len(sequence)/24,'events_are_timing_suggestions':True,'events':events,'placements':positions,'effect_baked_in':name!='run'}
 (folder/'animation.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2),encoding='utf-8')
 unique=len({im.tobytes() for im in frames});assert unique>=len(frames)-1
 assert name=='run' or frames[0].tobytes()==frames[-1].tobytes()
 checks[name]={'keyframes':len(frames),'distinct_keyframes':unique,'display_frames':len(sequence),'duration_ms':sum(durations),'last_equals_first':frames[-1].tobytes()==frames[0].tobytes(),'frames':audit}
 if name=='shuriken':frames[0].save(OUT/'character_05_stand_128.png')

combined=[]
for i in range(48):
 bg=Image.new('RGB',(960,180),'#dbe4ed');d=ImageDraw.Draw(bg)
 for col,name in enumerate(CONFIG):
  tick=i%len(clips[name]) if name=='run' else min(i,len(clips[name])-1)
  fr=clips[name][tick];advance=64 if name=='teleport_stab' and CONFIG[name][2] and tick>=sum(CONFIG[name][2][:6]) else 0;bg.paste(fr,(col*320+48+advance,20),fr);d.text((col*320+12,9),name,fill='#29384b')
 combined.append(bg)
combined[0].save(OUT/'comparison.gif',save_all=True,append_images=combined[1:],duration=[(round((i+1)*100/24)-round(i*100/24))*10 for i in range(48)],loop=0,disposal=2)
(OUT/'verification.json').write_text(json.dumps(checks,indent=2),encoding='utf-8')
with zipfile.ZipFile(OUT.parent/'character_05_run_shuriken_teleport_stab_v001.zip','w',zipfile.ZIP_DEFLATED) as z:
 for p in OUT.rglob('*'):
  if p.is_file():z.write(p,p.relative_to(OUT.parent))
print(json.dumps({k:{f:v[f] for f in ['keyframes','distinct_keyframes','display_frames','duration_ms']} for k,v in checks.items()}))
