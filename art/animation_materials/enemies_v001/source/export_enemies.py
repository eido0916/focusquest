from pathlib import Path
from PIL import Image,ImageDraw
import json,sys,shutil,zipfile
import numpy as np
out=Path(__file__).resolve().parent.parent
keys=['slime','goblin','dracula'];allmoves=[];allcycles=[];results={}
for key,filename in zip(keys,sys.argv[1:]):
 folder=out/key
 for sub in ['frames','cycle_24fps','move_left_24fps','preview','source']:(folder/sub).mkdir(parents=True,exist_ok=True)
 shutil.copy2(filename,folder/'source/generated_sheet.png');atlas=Image.open(filename).convert('RGBA');W,H=atlas.size;raw=[]
 for i in range(6):
  x=i%3;y=i//3;im=atlas.crop((round(x*W/3),round(y*H/2),round((x+1)*W/3),round((y+1)*H/2))).resize((64,64),Image.Resampling.NEAREST)
  mask=im.getchannel('A').point(lambda v:255 if v>=128 else 0);yy,xx=np.where(np.array(mask)>0);assert len(xx)>20
  seed=int(np.argmin((xx-32)**2+(yy-36)**2));ImageDraw.floodfill(mask,(int(xx[seed]),int(yy[seed])),128,thresh=0);im.putalpha(mask.point(lambda v:255 if v==128 else 0));raw.append(im)
 boxes=[im.getchannel('A').getbbox() for im in raw]
 scale=min(1.,44/max(b[2]-b[0] for b in boxes),46/max(b[3]-b[1] for b in boxes))
 aligned=[]
 for i,(im,box) in enumerate(zip(raw,boxes)):
  im=im.crop(box);im=im.resize((max(1,round(im.width*scale)),max(1,round(im.height*scale))),Image.Resampling.NEAREST)
  bottom=([56,53,50,53,56,54] if key=='slime' else [55,54,56,55,54,56] if key=='goblin' else [54,53,51,53,54,53])[i]
  canvas=Image.new('RGBA',(64,64));canvas.alpha_composite(im,(32-im.width//2,bottom-im.height));aligned.append(canvas)
 # Quantize once per character for the complete cycle.
 mosaic=Image.new('RGB',(384,64),'#182534')
 for i,im in enumerate(aligned):
  bg=Image.new('RGBA',(64,64),'#182534');bg.alpha_composite(im);mosaic.paste(bg.convert('RGB'),(i*64,0))
 pal=mosaic.quantize(colors=24,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE);small=[];frames=[]
 for i,im in enumerate(aligned):
  q=im.convert('RGB').quantize(palette=pal,dither=Image.Dither.NONE).convert('RGBA');q.putalpha(im.getchannel('A'));small.append(q);fr=q.resize((128,128),Image.Resampling.NEAREST);fr.save(folder/'frames'/f'{key}_move_left_{i:02}.png');frames.append(fr)
 frames[0].save(folder/f'{key}_stand_128.png')
 sheet=Image.new('RGBA',(384,256));contact=Image.new('RGB',(768,560),'#dbe4ed');d=ImageDraw.Draw(contact)
 for i,fr in enumerate(frames):
  x=i%3;y=i//3;sheet.alpha_composite(fr,(128*x,128*y));big=fr.resize((256,256),Image.Resampling.NEAREST);contact.paste(big,(256*x,280*y+24),big);d.text((256*x+8,280*y+8),f'{key} / FRAME {i:02}',fill='#253e55')
 sheet.save(folder/f'{key}_sheet_128.png');contact.save(folder/'preview/all_6_frames.png')
 cycle=[frames[f//2] for f in range(12)];moves=[]
 for f in range(24):
  pose=(f//2)%6;shift=round(6-12*f/23);canvas=Image.new('RGBA',(64,64));canvas.alpha_composite(small[pose],(shift,0));im=canvas.resize((128,128),Image.Resampling.NEAREST);im.save(folder/'move_left_24fps'/f'{key}_move_left_{f:03}.png');moves.append(im)
 for f,fr in enumerate(cycle):fr.save(folder/'cycle_24fps'/f'{key}_cycle_{f:03}.png')
 cycle_time=[round((i+1)*1000/24)-round(i*1000/24) for i in range(12)]
 cycle[0].save(folder/'preview/cycle.webp',save_all=True,append_images=cycle[1:],duration=cycle_time,loop=0,lossless=True)
 # Actual world movement: 2.5s crossing a 384x160 display, without teleport looping.
 stage=[]
 for f in range(60):
  pose=(f//2)%6;root=round(160-128*f/59);canvas=Image.new('RGBA',(192,80),'#dbe4ed');canvas.alpha_composite(small[pose],(root-32,8));stage.append(canvas.resize((384,160),Image.Resampling.NEAREST).convert('RGB'))
 durations=[(round((f+1)*100/24)-round(f*100/24))*10 for f in range(60)]
 stage[0].save(folder/'preview/move_left.gif',save_all=True,append_images=stage[1:],duration=durations,loop=0,disposal=2)
 moves[0].save(folder/'preview/move_left_128.png',save_all=True,append_images=moves[1:],duration=[round((f+1)*1000/24)-round(f*1000/24) for f in range(24)],loop=1,disposal=0,blend=0)
 checks=[];hashes=[];colors=set()
 for kind,seq in [('keyframes',frames),('move_left',moves)]:
  for i,im in enumerate(seq):
   arr=np.array(im);b=im.getchannel('A').getbbox();assert b and b[0]>0 and b[1]>0 and b[2]<128 and b[3]<128,(key,kind,i,b)
   assert im.size==(128,128) and im.mode=='RGBA';assert np.array_equal(arr[::2,::2],arr[1::2,::2]) and np.array_equal(arr[::2,::2],arr[::2,1::2]);assert set(np.unique(arr[:,:,3]))<={0,255}
   colors.update(map(tuple,arr[arr[:,:,3]==255][:,:3]));checks.append({'kind':kind,'frame':i,'bounds':b,'rgba_grid_alpha_margin_pass':True})
 assert len({im.tobytes() for im in frames})==6,(key,'duplicate keyframes')
 spec={'enemy_id':key,'canvas':[128,128],'logical_grid':[64,64],'direction':'left','fps':24,'keyframes':6,'cycle_display_frames':12,'cycle_seconds':.5,'cycle_root_motion':'none','move_display_frames':24,'move_seconds':1,'move_root_x_px':[12,-12],'move_loop':False,'move_per_frame':[{'frame':f,'time_seconds':f/24,'pose_index':(f//2)%6,'root_offset_x_px':2*round(6-12*f/23),'file':f'move_left_24fps/{key}_move_left_{f:03}.png'} for f in range(24)]}
 (folder/'animation.json').write_text(json.dumps(spec,indent=2),encoding='utf-8');(folder/'verification.json').write_text(json.dumps({'checks':checks,'different_poses':6,'opaque_colors':len(colors),'generated_size':[W,H],'normalization_scale':scale},indent=2),encoding='utf-8')
 results[key]={'keyframes':6,'cycle_frames':12,'moving_frames':24,'colors':len(colors)};allmoves.append(stage);allcycles.append(frames);print(key,results[key],flush=True)
comparison=[]
for f in range(60):
 canvas=Image.new('RGB',(384,540),'#dbe4ed');d=ImageDraw.Draw(canvas)
 for row,key in enumerate(keys):canvas.paste(allmoves[row][f],(0,180*row+20));d.text((12,180*row+6),key.upper()+' / RIGHT TO LEFT',fill='#253e55')
 comparison.append(canvas)
comparison[0].save(out/'enemies_move_left.gif',save_all=True,append_images=comparison[1:],duration=durations,loop=0,disposal=2)
overview=Image.new('RGB',(768,280),'#dbe4ed');d=ImageDraw.Draw(overview)
for i,key in enumerate(keys):
 im=allcycles[i][0].resize((256,256),Image.Resampling.NEAREST);overview.paste(im,(256*i,24),im);d.text((256*i+12,8),key.upper(),fill='#253e55')
overview.save(out/'enemies_overview.png');(out/'manifest.json').write_text(json.dumps(results,indent=2),encoding='utf-8')
archive=out.parent/'enemies_slime_goblin_dracula_v001.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
 for p in out.rglob('*'):
  if p.is_file() and '__pycache__' not in p.parts:z.write(p,p.relative_to(out.parent))
print('ZIP',archive.stat().st_size)
