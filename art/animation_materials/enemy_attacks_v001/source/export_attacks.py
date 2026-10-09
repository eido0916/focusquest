from pathlib import Path
from PIL import Image,ImageDraw,ImageChops
import sys,json,shutil,zipfile
import numpy as np
out=Path(__file__).resolve().parent.parent;keys=['slime','goblin','dracula'];clips={};results={}
for key,filename in zip(keys,sys.argv[1:]):
 folder=out/key
 for sub in ['frames','frames_24fps','character_frames','effect_frames','preview','source']:(folder/sub).mkdir(parents=True,exist_ok=True)
 shutil.copy2(filename,folder/'source/generated_attack_sheet.png');atlas=Image.open(filename).convert('RGBA');W,H=atlas.size;raw=[];bodyboxes=[]
 for i in range(8):
  col=i%4;row=i//4;im=atlas.crop((round(col*W/4),round(row*H/2),round((col+1)*W/4),round((row+1)*H/2))).resize((64,64),Image.Resampling.NEAREST)
  mask=im.getchannel('A').point(lambda v:255 if v>=128 else 0);yy,xx=np.where(np.array(mask)>0);assert len(xx)>20
  sx=40 if key=='dracula' else 34;seed=int(np.argmin((xx-sx)**2+(yy-40)**2));mark=mask.copy();ImageDraw.floodfill(mark,(int(xx[seed]),int(yy[seed])),128,thresh=0)
  bodyalpha=mark.point(lambda v:255 if v==128 else 0);body=im.copy();body.putalpha(bodyalpha);effect=im.copy();effectalpha=ImageChops.subtract(mask,bodyalpha)
  if key=='dracula':
   # Keep detached spell sprites; discard disconnected border artifacts.
   ea=np.array(effectalpha);gridx=np.indices(ea.shape)[1];ea[gridx>=32]=0
   # Preserve whole connected purple spell components, including white cores,
   # while removing stray black cape pixels from neighboring atlas cells.
   pending=Image.fromarray(ea);keep=np.zeros_like(ea);rgb=np.array(im)[:,:,:3].astype(float)
   purple=(rgb[:,:,0]>60)&(rgb[:,:,2]>rgb[:,:,1]*1.3)&(rgb[:,:,2]>rgb[:,:,0]*.65)
   while np.any(np.array(pending)>0):
    py,px=np.where(np.array(pending)>0);component=pending.copy();ImageDraw.floodfill(component,(int(px[0]),int(py[0])),128,thresh=0);cm=np.array(component)==128
    if np.any(cm&purple):keep[cm]=255
    pa=np.array(pending);pa[cm]=0;pending=Image.fromarray(pa)
   effectalpha=Image.fromarray(keep)
  else:effectalpha=Image.new('L',(64,64))
  effect.putalpha(effectalpha);raw.append((body,effect));bodyboxes.append(bodyalpha.getbbox())
 maxw=max(b[2]-b[0] for b in bodyboxes);maxh=max(b[3]-b[1] for b in bodyboxes)
 scale=min(1.,(36 if key=='slime' else 44)/maxw,(30 if key=='slime' else 46)/maxh)
 if key=='dracula':scale=min(scale,.80)
 characters=[];effects=[];placement=[]
 for i,((body,effect),box) in enumerate(zip(raw,bodyboxes)):
  if key=='slime':
   root=[36,38,40,30,24,29,34,36][i];bottom=[56,56,56,53,56,54,55,56][i];cx=(box[0]+box[2])/2
  else:
   root=32 if key=='dracula' else 36;bottom=56+([0,-1,-2,-1,0,0,-1,0][i] if key=='dracula' else 0)
   a=np.array(body);yy,xx=np.indices(a.shape[:2]);upper=yy<box[1]+(box[3]-box[1])*.50
   face=(a[:,:,3]>128)&upper&((a[:,:,0]>150)&(a[:,:,1]>120)&(a[:,:,2]>90) if key=='dracula' else (a[:,:,1]>a[:,:,0]*1.1)&(a[:,:,1]>a[:,:,2]*1.1))
   ys,xs=np.where(face);cx=float(xs.mean()) if len(xs)>5 else (box[0]+box[2])/2
  tx=root-cx*scale;ty=bottom-box[3]*scale
  mat=np.array([[scale,0,tx],[0,scale,ty],[0,0,1]],float)
  def warp(im):
   inv=np.linalg.inv(mat);return im.transform((64,64),Image.Transform.AFFINE,tuple(inv[:2].ravel()),Image.Resampling.NEAREST)
  hero=warp(body);fx=warp(effect);characters.append(hero);effects.append(fx);placement.append({'frame':i,'root_x_logical':root,'baseline_logical':bottom,'source_cell_to_64_matrix':mat.tolist()})
 # One palette for all body/effect frames. End pose exactly returns to start.
 characters[7]=characters[0].copy();effects[7]=Image.new('RGBA',(64,64))
 mosaic=Image.new('RGB',(512,64),'#182534')
 for i,(body,fx) in enumerate(zip(characters,effects)):
  bg=Image.new('RGBA',(64,64),'#182534');bg.alpha_composite(body);bg.alpha_composite(fx);mosaic.paste(bg.convert('RGB'),(64*i,0))
 pal=mosaic.quantize(colors=32 if key=='dracula' else 24,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE)
 def quant(im):
  q=im.convert('RGB').quantize(palette=pal,dither=Image.Dither.NONE).convert('RGBA');q.putalpha(im.getchannel('A').point(lambda v:255 if v>=128 else 0));return q.resize((128,128),Image.Resampling.NEAREST)
 frames=[];checks=[];colors=set()
 for i,(body,fx) in enumerate(zip(characters,effects)):
  body=quant(body);fx=quant(fx);fr=body.copy();fr.alpha_composite(fx)
  for sub,im in [('character_frames',body),('effect_frames',fx),('frames',fr)]:im.save(folder/sub/f'{key}_attack_{i:02}.png')
  arr=np.array(fr);box=fr.getchannel('A').getbbox();assert box and box[0]>0 and box[1]>0 and box[2]<128 and box[3]<128,(key,i,box)
  assert np.array_equal(arr[::2,::2],arr[1::2,::2]) and np.array_equal(arr[::2,::2],arr[::2,1::2]);assert set(np.unique(arr[:,:,3]))<={0,255}
  colors.update(map(tuple,arr[arr[:,:,3]==255][:,:3]));frames.append(fr);checks.append({'frame':i,'bounds':box,'rgba_pixel_grid_margin_pass':True,'body_effect_recomposition_exact':True})
 assert frames[0].tobytes()==frames[7].tobytes();assert len({f.tobytes() for f in frames[:7]})==7,(key,'duplicate poses')
 holds=[3,4,5,2,3,3,2,2] if key=='dracula' else [3,3,4,1,2,4,4,3];timeline=[]
 for i,count in enumerate(holds):timeline.extend([i]*count)
 for f,i in enumerate(timeline):frames[i].save(folder/'frames_24fps'/f'{key}_attack_{f:03}.png')
 sheet=Image.new('RGBA',(512,256));contact=Image.new('RGB',(1024,560),'#dbe4ed');d=ImageDraw.Draw(contact)
 for i,fr in enumerate(frames):
  x=i%4;y=i//4;sheet.alpha_composite(fr,(128*x,128*y));big=fr.resize((256,256),Image.Resampling.NEAREST);contact.paste(big,(256*x,280*y+24),big);d.text((256*x+8,280*y+8),f'{key} / ATTACK {i:02}',fill='#253e55')
 sheet.save(folder/f'{key}_attack_sheet_128.png');contact.save(folder/'preview/all_8_frames.png')
 t=[round(sum(holds[:i+1])*1000/24)-round(sum(holds[:i])*1000/24) for i in range(8)];gt=[(round(sum(holds[:i+1])*100/24)-round(sum(holds[:i])*100/24))*10 for i in range(8)]
 frames[0].save(folder/'preview/attack.webp',save_all=True,append_images=frames[1:],duration=t,loop=0,lossless=True);frames[0].save(folder/'preview/attack.png',save_all=True,append_images=frames[1:],duration=t,loop=0,disposal=0,blend=0)
 gifs=[]
 for fr in frames:
  bg=Image.new('RGBA',(384,384),'#dbe4ed');bg.alpha_composite(fr.resize((384,384),Image.Resampling.NEAREST));gifs.append(bg.convert('RGB'))
 gifs[0].save(folder/'preview/attack.gif',save_all=True,append_images=gifs[1:],duration=gt,loop=0,disposal=2)
 spec={'enemy_id':key,'animation':'attack','attack_type':'body_ram' if key=='slime' else 'club_downstroke' if key=='goblin' else 'magic_orb','direction':'left','canvas':[128,128],'logical_grid':[64,64],'fps':24,'duration_seconds':1,'keyframe_files':8,'different_poses':7,'display_frames':24,'game_loop':False,'preview_loop':True,'root_motion':'left_lunge_and_return_in_frames' if key=='slime' else 'none','active_or_release_frame':12 if key=='dracula' else 11,'holds':holds,'placements':placement,'timeline':[{'frame':f,'time_seconds':f/24,'pose':i,'file':f'frames_24fps/{key}_attack_{f:03}.png'} for f,i in enumerate(timeline)]}
 (folder/'animation.json').write_text(json.dumps(spec,indent=2),encoding='utf-8');(folder/'verification.json').write_text(json.dumps({'checks':checks,'common_opaque_colors':len(colors),'ready_return_exact':True,'source_size':[W,H]},indent=2),encoding='utf-8')
 results[key]={'keyframe_pngs':8,'display_frames':24,'colors':len(colors)};clips[key]=[frames[i] for i in timeline];print(key,results[key],flush=True)
comparison=[]
for f in range(24):
 canvas=Image.new('RGB',(768,280),'#dbe4ed');d=ImageDraw.Draw(canvas)
 for col,key in enumerate(keys):
  im=clips[key][f].resize((256,256),Image.Resampling.NEAREST);canvas.paste(im,(256*col,24),im);d.text((256*col+12,8),key.upper()+' / ATTACK LEFT',fill='#253e55')
 comparison.append(canvas)
comparison[0].save(out/'enemy_attacks_comparison.gif',save_all=True,append_images=comparison[1:],duration=[(round((f+1)*100/24)-round(f*100/24))*10 for f in range(24)],loop=0,disposal=2)
(out/'manifest.json').write_text(json.dumps(results,indent=2),encoding='utf-8')
archive=out.parent/'enemy_attacks_slime_goblin_dracula_v001.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
 for p in out.rglob('*'):
  if p.is_file() and '__pycache__' not in p.parts:z.write(p,p.relative_to(out.parent))
print('ZIP',archive.stat().st_size)
