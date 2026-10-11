from pathlib import Path
from PIL import Image,ImageDraw
import sys,json,shutil,zipfile,hashlib
import numpy as np
out=Path(__file__).resolve().parent.parent
for folder in ['frames','frames_24fps','preview','source']:(out/folder).mkdir(parents=True,exist_ok=True)
master=Image.open(sys.argv[1]).convert('RGBA')
shutil.copy2(sys.argv[1],out/'source/generated_run_sheet.png')
W,H=master.size
raw=[]
for i in range(6):
 col=i%3;row=i//3
 cell=master.crop((round(col*W/3),round(row*H/2),round((col+1)*W/3),round((row+1)*H/2)))
 small=cell.resize((60,60),Image.Resampling.NEAREST)
 # Align by the blond hair, not the varying leg/sword bounding boxes.
 # This removes sheet-row layout drift while retaining the intended 1px bob.
 arr=np.array(small);yy,xx=np.indices(arr.shape[:2])
 hair=(arr[:,:,3]>128)&(yy<28)&(arr[:,:,0]>130)&(arr[:,:,1]>75)&(arr[:,:,2]<155)&(arr[:,:,0]>arr[:,:,2]*1.35)
 hy,hx=np.where(hair);assert len(hx)>10
 dx=round(34-float(hx.mean()));top=int(np.where(arr[:,:,3]>=128)[0].min())
 dy=[8,7,9,8,7,9][i]-top
 normalized=Image.new('RGBA',(64,64));normalized.paste(small,(dx,dy))
 raw.append(normalized)
# The entire cycle shares one palette; never independently quantize each frame.
mosaic=Image.new('RGB',(384,64),'#171b29')
for i,im in enumerate(raw):
 bg=Image.new('RGBA',(64,64),'#171b29');bg.alpha_composite(im);mosaic.paste(bg.convert('RGB'),(64*i,0))
palette=mosaic.quantize(colors=24,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE)
frames=[]
for i,im in enumerate(raw):
 alpha=im.getchannel('A').point(lambda v:255 if v>=128 else 0)
 final=im.convert('RGB').quantize(palette=palette,dither=Image.Dither.NONE).convert('RGBA');final.putalpha(alpha)
 final=final.resize((128,128),Image.Resampling.NEAREST)
 final.save(out/'frames'/f'character_01_run_{i:02}.png');frames.append(final)
sheet=Image.new('RGBA',(384,256))
contact=Image.new('RGB',(1152,816),'#dbe4ed');d=ImageDraw.Draw(contact)
for i,im in enumerate(frames):
 x=i%3;y=i//3;sheet.alpha_composite(im,(128*x,128*y))
 big=im.resize((384,384),Image.Resampling.NEAREST);contact.paste(big,(384*x,408*y+24),big)
 d.text((384*x+12,408*y+8),f'FRAME {i:02}',fill='#253e55')
sheet.save(out/'character_01_run_sheet_128.png');contact.save(out/'preview/all_6_frames.png')
gif=[]
for im in frames:
 bg=Image.new('RGBA',(384,384),'#dbe4ed');bg.alpha_composite(im.resize((384,384),Image.Resampling.NEAREST));gif.append(bg.convert('RGB'))
timing=[round((i+1)*500/6)-round(i*500/6) for i in range(6)]
gif_time=[(round((i+1)*50/6)-round(i*50/6))*10 for i in range(6)]
gif[0].save(out/'preview/run.gif',save_all=True,append_images=gif[1:],duration=gif_time,loop=0,disposal=2)
frames[0].save(out/'preview/run.webp',save_all=True,append_images=frames[1:],duration=timing,loop=0,lossless=True)
frames[0].save(out/'preview/run.png',save_all=True,append_images=frames[1:],duration=timing,loop=0,disposal=0,blend=0)
for f in range(12):frames[f//2].save(out/'frames_24fps'/f'character_01_run_{f:03}.png')
poses=['right_knee_up','right_leg_extension','right_contact_down','left_knee_up','left_leg_extension','left_contact_down']
spec={'asset':'character_01','direction':'right','size':[128,128],'logical_grid':[64,64],'root_motion':'none','loop':True,'duration_seconds':.5,'unique_pose_count':6,'pose_fps':12,'display_fps':24,'display_frame_count':12,'frame_hold_at_24fps':2,'reference_urls':['https://dotartplay.com/dot-animation-run','https://dotartplay.com/dot-animation-run-64'],'poses':[{'index':i,'pose':p,'file':f'frames/character_01_run_{i:02}.png','duration_seconds':1/12} for i,p in enumerate(poses)],'timeline_24fps':[{'frame':f,'time_seconds':f/24,'pose_index':f//2,'file':f'frames_24fps/character_01_run_{f:03}.png'} for f in range(12)]}
(out/'animation.json').write_text(json.dumps(spec,indent=2),encoding='utf-8')
checks=[];hashes=[]
for i,im in enumerate(frames):
 arr=np.array(im);bbox=im.getchannel('A').getbbox();assert bbox and bbox[0]>0 and bbox[1]>0 and bbox[2]<128 and bbox[3]<128,('clipped',i,bbox)
 assert im.mode=='RGBA' and im.size==(128,128)
 assert np.array_equal(arr[::2,::2],arr[1::2,::2]) and np.array_equal(arr[::2,::2],arr[::2,1::2])
 assert set(np.unique(arr[:,:,3]))<={0,255}
 hashes.append(hashlib.sha256(im.tobytes()).hexdigest());checks.append({'frame':i,'visible_bounds':bbox,'dimension_alpha_pixel_grid_pass':True})
assert len(set(hashes))==6,'Duplicate poses'
(out/'verification.json').write_text(json.dumps({'frames':checks,'unique_frames':len(set(hashes)),'generated_master_size':[W,H]},indent=2),encoding='utf-8')
archive=out.parent/'character_01_field_run_v001.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
 for p in out.rglob('*'):
  if p.is_file() and '__pycache__' not in p.parts:z.write(p,p.relative_to(out.parent))
print(json.dumps({'unique_frames':6,'display_frames':12,'size':[128,128],'bounds':[c['visible_bounds'] for c in checks],'zip_bytes':archive.stat().st_size}))
