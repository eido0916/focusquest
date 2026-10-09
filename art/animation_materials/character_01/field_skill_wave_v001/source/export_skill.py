from pathlib import Path
from PIL import Image,ImageDraw
import numpy as np
import json,sys,shutil,zipfile,math
out=Path(__file__).resolve().parent.parent
attack=out.parent/'field_attack_down_v001/frames'
for folder in ['frames','frames_24fps','character_frames','effect_frames','effects','preview','source']:(out/folder).mkdir(parents=True,exist_ok=True)
master=Image.open(sys.argv[1]).convert('RGBA');W,H=master.size
shutil.copy2(sys.argv[1],out/'source/generated_fx_atlas.png')
fxnames=['charge_weak','charge_strong','swing_arc','wave_launch','wave_travel','wave_break','wave_fade','sparks'];fx=[]
for i,name in enumerate(fxnames):
 col=i%4;row=i//4
 im=master.crop((round(col*W/4),round(row*H/2),round((col+1)*W/4),round((row+1)*H/2))).resize((64,64),Image.Resampling.NEAREST)
 im.putalpha(im.getchannel('A').point(lambda v:255 if v>=128 else 0));box=im.getchannel('A').getbbox();assert box
 im=im.crop(box);im.save(out/'effects'/f'{name}.png');fx.append(im)
# Original attack art remains intact; every skill frame uses the same 58/64 scale.
heroes=[]
for i in range(8):
 im=Image.open(attack/f'character_01_attack_down_{i:02}.png').convert('RGBA').resize((58,58),Image.Resampling.NEAREST)
 canvas=Image.new('RGBA',(64,64));canvas.paste(im,(-7,5));heroes.append(canvas)
def point(p):return np.array(p)*58/128+np.array([-7,5])
blade={0:((94,81),(113,60)),1:((46,66),(37,36)),2:((54,42),(27,14)),3:((68,43),(101,18)),4:((83,84),(123,88)),5:((80,95),(119,114)),6:((94,81),(113,60))}
def blade_fx(effect,pose,width):
 im=effect;start,end=map(point,blade[pose]);v=end-start;length=float(np.linalg.norm(v));up=v/length;right=np.array([-up[1],up[0]])
 mat=np.eye(3);mat[:2,0]=right*width/im.width;mat[:2,1]=-up*length/max(1,im.height-1)
 mat[:2,2]=start-mat[:2,:2]@np.array([im.width/2,im.height-1])
 inv=np.linalg.inv(mat)
 return im.transform((64,64),Image.Transform.AFFINE,tuple(inv[:2].ravel()),Image.Resampling.NEAREST)
def put_effect(canvas,index,center,size):
 im=fx[index].resize(size,Image.Resampling.NEAREST)
 x=round(center[0]-size[0]/2);y=round(center[1]-size[1]/2);canvas.alpha_composite(im,(x,y))
poses=[0,0,1,2,3,4,5,5,5,6,6,0]
names=['ready','charge_begin','charge_grow','charged_overhead','downstroke','wave_release','wave_near','wave_forward','wave_break','wave_fade_recovery','recovery','ready_return']
holds=[3,5,5,7,1,2,2,2,2,2,3,2]
frames=[];effects=[];characters=[];records=[]
for i,pose in enumerate(poses):
 effect=Image.new('RGBA',(64,64));hero=heroes[pose].copy()
 if i==1:effect.alpha_composite(blade_fx(fx[0],pose,6))
 if i in [2,3,4]:effect.alpha_composite(blade_fx(fx[1],pose,8))
 if i==4:put_effect(effect,2,(32,21),(25,25))
 if i==5:
  put_effect(effect,2,(35,34),(24,24));put_effect(effect,3,(48,44),(6,16))
 if i==6:put_effect(effect,4,(51,44),(8,19))
 if i==7:put_effect(effect,4,(54,44),(8,19))
 if i==8:put_effect(effect,5,(56,44),(8,17))
 if i==9:put_effect(effect,6,(58,44),(7,14))
 composed=hero.copy();composed.alpha_composite(effect)
 frames.append(composed);effects.append(effect);characters.append(hero)
 records.append({'keyframe':i,'phase':names[i],'attack_pose':pose,'hold_frames_24fps':holds[i],'blade_anchors_logical':list(map(lambda p:list(point(p)),blade[pose])) if pose in blade else None,'shockwave_center_logical':[48,44] if i==5 else [51,44] if i==6 else [54,44] if i==7 else [56,44] if i==8 else [58,44] if i==9 else None})
# Common 32-color palette for both separate layers and their re-composition.
mosaic=Image.new('RGB',(64*len(frames),64),'#182534')
for i,fr in enumerate(frames):
 bg=Image.new('RGBA',(64,64),'#182534');bg.alpha_composite(fr);mosaic.paste(bg.convert('RGB'),(64*i,0))
pal=mosaic.quantize(colors=32,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE)
def quant(im):
 q=im.convert('RGB').quantize(palette=pal,dither=Image.Dither.NONE).convert('RGBA');q.putalpha(im.getchannel('A').point(lambda v:255 if v>=128 else 0));return q
finals=[]
for i,(hero,eff) in enumerate(zip(characters,effects)):
 hero=quant(hero);eff=quant(eff);combined=hero.copy();combined.alpha_composite(eff)
 for folder,im in [('character_frames',hero),('effect_frames',eff),('frames',combined)]:im.resize((128,128),Image.Resampling.NEAREST).save(out/folder/f'character_01_skill_wave_{i:02}.png')
 finals.append(combined.resize((128,128),Image.Resampling.NEAREST))
assert np.array_equal(np.array(finals[0]),np.array(finals[-1]))
sheet=Image.new('RGBA',(512,384));contact=Image.new('RGB',(1024,840),'#dbe4ed');d=ImageDraw.Draw(contact)
for i,im in enumerate(finals):
 x=i%4;y=i//4;sheet.alpha_composite(im,(128*x,128*y));big=im.resize((256,256),Image.Resampling.NEAREST);contact.paste(big,(256*x,280*y+24),big);d.text((256*x+7,280*y+7),f'{i:02} {names[i]}',fill='#253e55')
sheet.save(out/'character_01_skill_wave_sheet_128.png');contact.save(out/'preview/all_12_frames.png')
timeline=[]
for i,count in enumerate(holds):timeline.extend([i]*count)
for f,i in enumerate(timeline):finals[i].save(out/'frames_24fps'/f'character_01_skill_wave_{f:03}.png')
timing=[round(sum(holds[:i+1])*1000/24)-round(sum(holds[:i])*1000/24) for i in range(12)]
gtime=[(round(sum(holds[:i+1])*100/24)-round(sum(holds[:i])*100/24))*10 for i in range(12)]
gif=[]
for fr in finals:
 bg=Image.new('RGBA',(384,384),'#dbe4ed');bg.alpha_composite(fr.resize((384,384),Image.Resampling.NEAREST));gif.append(bg.convert('RGB'))
gif[0].save(out/'preview/skill_wave.gif',save_all=True,append_images=gif[1:],duration=gtime,loop=0,disposal=2)
finals[0].save(out/'preview/skill_wave.webp',save_all=True,append_images=finals[1:],duration=timing,loop=0,lossless=True)
finals[0].save(out/'preview/skill_wave.png',save_all=True,append_images=finals[1:],duration=timing,loop=0,disposal=0,blend=0)
checks=[];colors=set()
for i,fr in enumerate(finals):
 arr=np.array(fr);box=fr.getchannel('A').getbbox();assert box and box[0]>0 and box[1]>0 and box[2]<128 and box[3]<128,('clipped',i,box)
 assert fr.size==(128,128) and fr.mode=='RGBA';assert np.array_equal(arr[::2,::2],arr[1::2,::2]) and np.array_equal(arr[::2,::2],arr[::2,1::2]);assert set(np.unique(arr[:,:,3]))<={0,255}
 hero=Image.open(out/'character_frames'/f'character_01_skill_wave_{i:02}.png').convert('RGBA');eff=Image.open(out/'effect_frames'/f'character_01_skill_wave_{i:02}.png').convert('RGBA');hero.alpha_composite(eff);assert np.array_equal(np.array(hero),arr)
 colors.update(map(tuple,arr[arr[:,:,3]==255][:,:3]));checks.append({'keyframe':i,'bounds':box,'rgba_pixel_grid_pass':True,'layer_recomposition_exact':True})
for ext in ['gif','png']:
 im=Image.open(out/'preview'/f'skill_wave.{ext}');total=0
 for i in range(im.n_frames):im.seek(i);total+=im.info.get('duration',0)
 assert abs(total-1500)<2
spec={'asset_id':'character_01','animation_id':'skill_wave','size':[128,128],'direction':'right','logical_grid':[64,64],'root_motion':'none','game_loop':False,'preview_loop':True,'fps':24,'duration_seconds':1.5,'display_frame_count':36,'keyframe_count':12,'character_scale_relative_attack':58/64,'attack_original_canvas_to_skill':{'scale':58/128,'translate_logical':[-7,5]},'effect_color':'cyan_blue_white','release_frame_24fps':sum(holds[:5]),'keyframes':records,'timeline':[{'frame':f,'time_seconds':f/24,'keyframe':i,'file':f'frames_24fps/character_01_skill_wave_{f:03}.png'} for f,i in enumerate(timeline)]}
(out/'animation.json').write_text(json.dumps(spec,indent=2),encoding='utf-8')
(out/'verification.json').write_text(json.dumps({'keyframe_checks':checks,'common_opaque_colors':len(colors),'ready_return_exact':True,'master_size':[W,H]},indent=2),encoding='utf-8')
archive=out.parent/'character_01_field_skill_wave_v001.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
 for p in out.rglob('*'):
  if p.is_file() and '__pycache__' not in p.parts:z.write(p,p.relative_to(out.parent))
print(json.dumps({'keyframes':12,'display_frames':len(timeline),'duration':1.5,'colors':len(colors),'bounds':[c['bounds'] for c in checks],'zip_bytes':archive.stat().st_size}))
