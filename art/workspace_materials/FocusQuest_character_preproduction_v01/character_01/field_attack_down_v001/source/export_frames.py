from pathlib import Path
from PIL import Image,ImageDraw
import sys,json,shutil,zipfile,hashlib
import numpy as np
out=Path(__file__).resolve().parent.parent
for folder in ['frames','frames_24fps','preview','source']:(out/folder).mkdir(parents=True,exist_ok=True)
master=Image.open(sys.argv[1]).convert('RGBA')
shutil.copy2(sys.argv[1],out/'source/generated_attack_sheet.png')
W,H=master.size;raw=[];anchors=[]
for i in range(8):
 col=i%4;row=i//4
 cell=master.crop((round(col*W/4),round(row*H/2),round((col+1)*W/4),round((row+1)*H/2)))
 small=cell.resize((60,60),Image.Resampling.NEAREST)
 # Reject detached pixels spilling in from a neighboring atlas cell.
 mask=small.getchannel('A').point(lambda v:255 if v>=128 else 0)
 sy,sx=np.where(np.array(mask)>0);seed=int(np.argmin((sx-30)**2+(sy-32)**2))
 ImageDraw.floodfill(mask,(int(sx[seed]),int(sy[seed])),128,thresh=0)
 small.putalpha(mask.point(lambda v:255 if v==128 else 0))
 arr=np.array(small);yy,xx=np.indices(arr.shape[:2]);visible=arr[:,:,3]>=128
 # Bottom is the planted boots. Sword tip is specified to stay above ground.
 bottom=int(np.where(visible)[0].max())
 boot=visible&(yy>=bottom-5)&(xx>14)&(xx<46)&(arr[:,:,0]>arr[:,:,2]*1.2)&(arr[:,:,0]>=arr[:,:,1])&(arr[:,:,0]<165)
 by,bx=np.where(boot);assert len(bx)>5,('boots not found',i)
 dx=round(32-(int(bx.min())+int(bx.max()))/2);dy=58-bottom
 normalized=Image.new('RGBA',(64,64));normalized.paste(small,(dx,dy));raw.append(normalized)
 anchors.append({'frame':i,'translation_logical':[dx,dy],'boot_ground_y':58})
mosaic=Image.new('RGB',(64*8,64),'#171b29')
for i,im in enumerate(raw):
 bg=Image.new('RGBA',(64,64),'#171b29');bg.alpha_composite(im);mosaic.paste(bg.convert('RGB'),(64*i,0))
pal=mosaic.quantize(colors=24,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE)
frames=[]
for im in raw:
 final=im.convert('RGB').quantize(palette=pal,dither=Image.Dither.NONE).convert('RGBA')
 final.putalpha(im.getchannel('A').point(lambda v:255 if v>=128 else 0))
 frames.append(final.resize((128,128),Image.Resampling.NEAREST))
# Exact ready-pose return avoids a one-pixel pop at the end.
frames[7]=frames[0].copy()
for i,im in enumerate(frames):im.save(out/'frames'/f'character_01_attack_down_{i:02}.png')
holds=[4,3,4,1,1,4,3,4];timeline=[]
for i,count in enumerate(holds):timeline.extend([i]*count)
sheet=Image.new('RGBA',(512,256));contact=Image.new('RGB',(1024,560),'#dbe4ed');d=ImageDraw.Draw(contact)
names=['READY','ANTICIPATION','OVERHEAD','DOWNSWING','STRIKE','FOLLOW THROUGH','RECOVERY','READY RETURN']
for i,im in enumerate(frames):
 x=i%4;y=i//4;sheet.alpha_composite(im,(128*x,128*y))
 big=im.resize((256,256),Image.Resampling.NEAREST);contact.paste(big,(256*x,280*y+24),big)
 d.text((256*x+8,280*y+7),f'{i:02} {names[i]}',fill='#253e55')
sheet.save(out/'character_01_attack_down_sheet_128.png');contact.save(out/'preview/all_8_frames.png')
for f,i in enumerate(timeline):frames[i].save(out/'frames_24fps'/f'character_01_attack_down_{f:03}.png')
timing=[round(sum(holds[:i+1])*1000/24)-round(sum(holds[:i])*1000/24) for i in range(8)]
gtime=[(round(sum(holds[:i+1])*100/24)-round(sum(holds[:i])*100/24))*10 for i in range(8)]
gif=[]
for im in frames:
 bg=Image.new('RGBA',(384,384),'#dbe4ed');bg.alpha_composite(im.resize((384,384),Image.Resampling.NEAREST));gif.append(bg.convert('RGB'))
gif[0].save(out/'preview/attack_down.gif',save_all=True,append_images=gif[1:],duration=gtime,loop=0,disposal=2)
frames[0].save(out/'preview/attack_down.webp',save_all=True,append_images=frames[1:],duration=timing,loop=0,lossless=True)
frames[0].save(out/'preview/attack_down.png',save_all=True,append_images=frames[1:],duration=timing,loop=0,disposal=0,blend=0)
spec={'asset':'character_01','animation_id':'attack_down','direction':'right','size':[128,128],'logical_grid':[64,64],'root_motion':'none','loop_in_game':False,'preview_loop':True,'duration_seconds':1,'display_fps':24,'display_frames':24,'keyframe_files':8,'different_pose_count':7,'ready_return_exact_match':True,'keyframes':[{'index':i,'phase':names[i],'hold_frames':holds[i],'file':f'frames/character_01_attack_down_{i:02}.png'} for i in range(8)],'timeline':[{'frame':f,'time_seconds':f/24,'keyframe_index':i,'file':f'frames_24fps/character_01_attack_down_{f:03}.png'} for f,i in enumerate(timeline)]}
(out/'animation.json').write_text(json.dumps(spec,indent=2),encoding='utf-8')
checks=[];colors=set();hashes=[]
for i,im in enumerate(frames):
 arr=np.array(im);bbox=im.getchannel('A').getbbox();assert bbox and bbox[0]>0 and bbox[1]>0 and bbox[2]<128 and bbox[3]<128,('clipped',i,bbox)
 assert im.size==(128,128) and im.mode=='RGBA';assert np.array_equal(arr[::2,::2],arr[1::2,::2]) and np.array_equal(arr[::2,::2],arr[::2,1::2]);assert set(np.unique(arr[:,:,3]))<={0,255}
 colors.update(map(tuple,arr[arr[:,:,3]==255][:,:3]));hashes.append(hashlib.sha256(im.tobytes()).hexdigest())
 checks.append({'frame':i,'bounds':bbox,'ground_y_max':bbox[3]-1,'dimension_alpha_pixel_grid_pass':True})
assert hashes[0]==hashes[7];assert len(set(hashes[:7]))==7
for ext in ['gif','png']:
 anim=Image.open(out/'preview'/f'attack_down.{ext}');total=0
 for f in range(anim.n_frames):anim.seek(f);total+=anim.info.get('duration',0)
 assert abs(total-1000)<2,(ext,total)
(out/'verification.json').write_text(json.dumps({'frames':checks,'common_opaque_colors':len(colors),'ready_return_exact_match':True,'unique_poses':len(set(hashes)),'normalization':anchors,'generated_master_size':[W,H]},indent=2),encoding='utf-8')
archive=out.parent/'character_01_field_attack_down_v001.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
 for p in out.rglob('*'):
  if p.is_file() and '__pycache__' not in p.parts:z.write(p,p.relative_to(out.parent))
print(json.dumps({'keyframes':8,'different_poses':7,'display_frames_24fps':24,'bounds':[c['bounds'] for c in checks],'colors':len(colors),'zip_bytes':archive.stat().st_size}))
