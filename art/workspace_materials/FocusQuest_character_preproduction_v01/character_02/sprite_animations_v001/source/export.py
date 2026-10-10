from pathlib import Path
from PIL import Image, ImageDraw
import numpy as np
import json, shutil, zipfile

OUT=Path(__file__).resolve().parent.parent
GENERATED=Path('C:/Users/yuusy/.codex/generated_images/01a11fcc-8481-74b0-a008-feaf5145dc5e')
CONFIG={
 'run':('exec-efd9d727-8608-4a3c-9948-425185e9068b.png',3,2,[2]*6),
 'punch_combo':('exec-afd97c12-f040-4320-bb47-06ddcb8e0132.png',4,3,[3,3,1,2,2,1,2,2,1,3,5,5]),
 'spin_kick':('exec-9cc4181b-b5bc-44d5-ba40-f39a8c741bab.png',4,3,[3,4,4,6,1,1,1,1,2,3,3,1])
}
clips={}; checks={}
for name,(filename,cols,rows,holds) in CONFIG.items():
 folder=OUT/name
 for sub in ['source','frames','frames_24fps','preview']:(folder/sub).mkdir(parents=True,exist_ok=True)
 atlaspath=folder/'source/generated_atlas.png'
 if not atlaspath.exists():shutil.copy2(GENERATED/filename,atlaspath)
 atlas=Image.open(atlaspath).convert('RGBA'); W,H=atlas.size; raw=[]; boxes=[]; centers=[]
 for i in range(cols*rows):
  x=i%cols;y=i//cols
  im=atlas.crop((round(x*W/cols),round(y*H/rows),round((x+1)*W/cols),round((y+1)*H/rows))).resize((64,64),Image.Resampling.NEAREST)
  rgba=np.array(im);rgb=rgba[:,:,:3].astype(float)
  gold=(rgb[:,:,0]>170)&(rgb[:,:,1]>95)&(rgb[:,:,0]>rgb[:,:,2]*1.4)&(rgb[:,:,1]>rgb[:,:,2]*1.3)
  mask=(rgba[:,:,3]>=128)
  if name=='spin_kick':mask|=gold&(rgba[:,:,3]>=64)
  if name=='spin_kick' and i==7:
   # Crop the neighboring frame's gold arc from the left gutter. Preserve the
   # red sash tip that belongs to this frame in the same gutter.
   red=(rgb[:,:,0]>rgb[:,:,1]*1.5)&(rgb[:,:,0]>rgb[:,:,2]*1.5)
   mask[:,:12]&=red[:,:12]
  alpha=Image.fromarray(np.where(mask,255,0).astype(np.uint8))
  # Remove only tiny detached specks; retain detached energy sparks.
  pending=alpha.copy(); keep=np.zeros((64,64),dtype=np.uint8)
  while np.any(np.array(pending)):
   yy,xx=np.where(np.array(pending)>0); mark=pending.copy();ImageDraw.floodfill(mark,(int(xx[0]),int(yy[0])),128,thresh=0)
   component=np.array(mark)==128
   cy,cx=np.where(component)
   edge_speck=(cx.min()<=1 or cx.max()>=62) and component.sum()<100
   # The generated kick strike spills into the following cell's left margin.
   if name=='spin_kick' and i==7 and cx.max()<16:edge_speck=True
   if component.sum()>=3 and not edge_speck:keep[component]=255
   pa=np.array(pending);pa[component]=0;pending=Image.fromarray(pa)
  alpha=Image.fromarray(keep);im.putalpha(alpha);box=alpha.getbbox()
  arr=np.array(alpha); yy,xx=np.where((arr>0)&(np.indices(arr.shape)[0]<box[1]+14))
  centers.append(float((xx.min()+xx.max())/2));raw.append(im);boxes.append(box)
 # Uniform scaling within a clip preserves limb proportions. Head anchors, rather
 # than whole-image centers, prevent punches and kick trails shifting the torso.
 scale=min(1.,46/max(b[3]-b[1] for b in boxes),58/max(b[2]-b[0] for b in boxes))
 placed=[];positions=[]
 for i,(im,b,cx) in enumerate(zip(raw,boxes,centers)):
  baseline=57-([2,3,0,2,3,0][i] if name=='run' else 0)
  tx=32-cx*scale;ty=baseline-b[3]*scale
  # Constrain effects and extended fists to the safe area without stretching.
  tx=max(3-b[0]*scale,min(tx,61-b[2]*scale))
  mat=np.array([[scale,0,tx],[0,scale,ty],[0,0,1]])
  inv=np.linalg.inv(mat)
  placed.append(im.transform((64,64),Image.Transform.AFFINE,tuple(inv[:2].ravel()),Image.Resampling.NEAREST))
  if name=='spin_kick' and i==7:
   a=np.array(placed[-1]);r=a[:,:,0].astype(float);g=a[:,:,1].astype(float);b=a[:,:,2].astype(float);x=np.indices(a.shape[:2])[1]
   gutter=(x<21)&~((r>g*1.5)&(r>b*1.5))
   a[gutter,3]=0;placed[-1]=Image.fromarray(a)
  positions.append({'keyframe':i,'source_cell_to_logical_matrix':mat.tolist(),'baseline_logical':baseline})
 if name!='run':placed[-1]=placed[0].copy()
 mosaic=Image.new('RGB',(64*len(placed),64),'#33282c')
 for i,im in enumerate(placed):mosaic.paste(im.convert('RGB'),(i*64,0),im.getchannel('A'))
 palette=mosaic.quantize(colors=32 if name=='spin_kick' else 24,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE)
 frames=[];audit=[]
 for i,im in enumerate(placed):
  fr=im.convert('RGB').quantize(palette=palette,dither=Image.Dither.NONE).convert('RGBA');fr.putalpha(im.getchannel('A'))
  fr=fr.resize((128,128),Image.Resampling.NEAREST);fr.save(folder/'frames'/f'character_02_{name}_{i:02}.png')
  a=np.array(fr);b=fr.getchannel('A').getbbox()
  assert b[0]>0 and b[1]>0 and b[2]<128 and b[3]<128,(name,i,b)
  assert set(np.unique(a[:,:,3]))<={0,255}
  assert np.array_equal(a[::2,::2],a[1::2,1::2])
  frames.append(fr);audit.append({'keyframe':i,'bounds':b,'transparent_128_and_safe_margin':True})
 sequence=[i for i,h in enumerate(holds) for _ in range(h)];clips[name]=[frames[i] for i in sequence]
 for n,i in enumerate(sequence):frames[i].save(folder/'frames_24fps'/f'frame_{n:03}.png')
 sheet=Image.new('RGBA',(cols*128,rows*128))
 contact=Image.new('RGB',(cols*256,rows*280),'#dbe4ed');d=ImageDraw.Draw(contact)
 for i,fr in enumerate(frames):
  sheet.alpha_composite(fr,(i%cols*128,i//cols*128))
  contact.paste(fr.resize((256,256),Image.Resampling.NEAREST),(i%cols*256,i//cols*280+24),fr.resize((256,256),Image.Resampling.NEAREST))
  d.text((i%cols*256+8,i//cols*280+5),f'{name} {i:02} / {holds[i]} ticks',fill='#29384b')
 sheet.save(folder/f'character_02_{name}_sheet.png');contact.save(folder/'preview/keyframes.png')
 preview=[]
 for fr in clips[name]:
  bg=Image.new('RGBA',(256,256),'#dbe4ed');bg.alpha_composite(fr.resize((256,256),Image.Resampling.NEAREST));preview.append(bg.convert('RGB'))
 durations=[round((i+1)*1000/24)-round(i*1000/24) for i in range(len(preview))]
 gifdur=[(round((i+1)*100/24)-round(i*100/24))*10 for i in range(len(preview))]
 preview[0].save(folder/'preview/animation.gif',save_all=True,append_images=preview[1:],duration=gifdur,loop=0,disposal=2)
 clips[name][0].save(folder/'preview/animation.png',save_all=True,append_images=clips[name][1:],duration=durations,loop=0,disposal=2,blend=0)
 events=[]
 if name=='punch_combo':events=[{'event':kind,'keyframe':i,'tick':sum(holds[:i])} for kind,i in [('jab',2),('cross',5),('hook',8)]]
 if name=='spin_kick':events=[{'event':'charge_start','keyframe':1,'tick':3},{'event':'kick_hit','keyframe':6,'tick':sum(holds[:6])}]
 meta={'character':'02','size':[128,128],'logical_grid':[64,64],'direction':'right','fps':24,'root':[64,114],'loop_in_game':name=='run','preview_loop':True,'keyframe_holds_ticks':holds,'display_frame_sequence':sequence,'duration_seconds':len(sequence)/24,'events':events,'placements':positions,'effect_baked_in':name=='spin_kick'}
 (folder/'animation.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2),encoding='utf-8')
 checks[name]={'frame_count':len(frames),'display_frames':len(sequence),'last_equals_first':frames[-1].tobytes()==frames[0].tobytes() if name!='run' else None,'frames':audit}
 if name=='punch_combo':frames[0].save(OUT/'character_02_stand_128.png')
combined=[]
for i in range(30):
 bg=Image.new('RGB',(768,284),'#dbe4ed');d=ImageDraw.Draw(bg)
 for col,name in enumerate(CONFIG):
  fr=clips[name][i%len(clips[name])].resize((256,256),Image.Resampling.NEAREST)
  bg.paste(fr,(col*256,28),fr);d.text((col*256+12,9),name,fill='#29384b')
 combined.append(bg)
combined[0].save(OUT/'comparison.gif',save_all=True,append_images=combined[1:],duration=[(round((i+1)*100/24)-round(i*100/24))*10 for i in range(30)],loop=0,disposal=2)
(OUT/'verification.json').write_text(json.dumps(checks,indent=2),encoding='utf-8')
with zipfile.ZipFile(OUT.parent/'character_02_run_punch_spin_kick_v001.zip','w',zipfile.ZIP_DEFLATED) as z:
 for p in OUT.rglob('*'):
  if p.is_file():z.write(p,p.relative_to(OUT.parent))
print(json.dumps({k:{'keyframes':v['frame_count'],'24fps_frames':v['display_frames']} for k,v in checks.items()}))
