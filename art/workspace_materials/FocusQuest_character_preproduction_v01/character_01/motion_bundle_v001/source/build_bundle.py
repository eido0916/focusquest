from pathlib import Path
from PIL import Image,ImageDraw
import numpy as np
import json,shutil,zipfile
out=Path(__file__).resolve().parent.parent;character=out.parent
sources={'run':character/'field_run_v001','attack':character/'field_attack_down_v001','skill':character/'field_skill_wave_v001'}
for name,folder in sources.items():
 dst=out/'original_assets'/name
 shutil.copytree(folder,dst,dirs_exist_ok=True,ignore=shutil.ignore_patterns('__pycache__'))
def load(path):return Image.open(path).convert('RGBA')
def align(im,size,xy):
 small=im.resize((size,size),Image.Resampling.NEAREST);canvas=Image.new('RGBA',(64,64));canvas.paste(small,xy);return canvas.resize((128,128),Image.Resampling.NEAREST)
run=[align(load(sources['run']/'frames'/f'character_01_run_{i:02}.png'),48,(-1,14)) for i in range(6)]
attack=[align(load(sources['attack']/'frames'/f'character_01_attack_down_{i:02}.png'),58,(-7,5)) for i in range(8)]
skill=[load(sources['skill']/'frames'/f'character_01_skill_wave_{i:02}.png') for i in range(12)]
attack_spec=json.loads((sources['attack']/'animation.json').read_text(encoding='utf-8'))
skill_spec=json.loads((sources['skill']/'animation.json').read_text(encoding='utf-8'))
clips={};manifest={};qa={}
for name,poses,spec in [('run_then_attack',attack,attack_spec),('run_then_skill',skill,skill_spec)]:
 dest=out/name;framesdir=dest/'frames_24fps';preview=dest/'preview';framesdir.mkdir(parents=True,exist_ok=True);preview.mkdir(exist_ok=True)
 seq=[run[(f//2)%6] for f in range(24)]+[poses[0]]*4
 seq.extend(poses[r['keyframe_index'] if name=='run_then_attack' else r['keyframe']] for r in spec['timeline'])
 records=[];bounds=[]
 for f,im in enumerate(seq):
  filename=f'character_01_{name}_{f:03}.png';im.save(framesdir/filename)
  arr=np.array(im);box=im.getchannel('A').getbbox();assert box and box[0]>0 and box[1]>0 and box[2]<128 and box[3]<128,(name,f,box)
  assert im.size==(128,128) and im.mode=='RGBA';assert np.array_equal(arr[::2,::2],arr[1::2,::2]) and np.array_equal(arr[::2,::2],arr[::2,1::2]);assert set(np.unique(arr[:,:,3]))<={0,255}
  records.append({'frame':f,'time_seconds':f/24,'phase':'run' if f<24 else 'stop_ready' if f<28 else 'attack' if name=='run_then_attack' else 'skill','file':f'frames_24fps/{filename}'});bounds.append(box)
 duration=[round((f+1)*1000/24)-round(f*1000/24) for f in range(len(seq))]
 seq[0].save(preview/'animation.webp',save_all=True,append_images=seq[1:],duration=duration,loop=0,lossless=True)
 seq[0].save(preview/'animation.png',save_all=True,append_images=seq[1:],duration=duration,loop=0,disposal=0,blend=0)
 gif=[]
 for im in seq:
  bg=Image.new('RGBA',(384,384),'#dbe4ed');bg.alpha_composite(im.resize((384,384),Image.Resampling.NEAREST));gif.append(bg.convert('RGB'))
 gifdur=[(round((f+1)*100/24)-round(f*100/24))*10 for f in range(len(seq))]
 gif[0].save(preview/'animation.gif',save_all=True,append_images=gif[1:],duration=gifdur,loop=0,disposal=2)
 md={'asset_id':'character_01','animation_id':name,'canvas':[128,128],'fps':24,'frames':len(seq),'duration_seconds':len(seq)/24,'root_motion':'none','loop_in_game':False,'preview_loop':True,'sequence':'run for 1s > ready stop for 4/24s > existing stationary action > ready','timeline':records}
 (dest/'animation.json').write_text(json.dumps(md,indent=2),encoding='utf-8')
 manifest[name]={'metadata':f'{name}/animation.json','gif':f'{name}/preview/animation.gif','frames':len(seq),'duration_seconds':len(seq)/24}
 qa[name]={'frame_count':len(seq),'rgba_128_pass':True,'pixel_grid_2x2_pass':True,'hard_alpha_pass':True,'safe_bounds_pass':True,'union_bounds':[min(b[0] for b in bounds),min(b[1] for b in bounds),max(b[2] for b in bounds),max(b[3] for b in bounds)]}
 clips[name]=seq
# Compare both combinations on one common 24fps timeline; short clip holds ready.
comparison=[];allseq=list(clips.values());count=max(map(len,allseq))
for f in range(count):
 canvas=Image.new('RGB',(768,424),'#dbe4ed');draw=ImageDraw.Draw(canvas)
 for col,seq in enumerate(allseq):
  im=seq[min(f,len(seq)-1)].resize((384,384),Image.Resampling.NEAREST);canvas.paste(im,(col*384,40),im);draw.text((col*384+12,14),'RUN > STOP > SWORD' if col==0 else 'RUN > STOP > SKILL',fill='#253e55')
 comparison.append(canvas)
comparison[0].save(out/'comparison.gif',save_all=True,append_images=comparison[1:],duration=[(round((f+1)*100/24)-round(f*100/24))*10 for f in range(count)],loop=0,disposal=2)
contact=Image.new('RGB',(1024,560),'#dbe4ed');draw=ImageDraw.Draw(contact)
for row,(name,seq) in enumerate(clips.items()):
 ids=[10,27,40 if row==0 else 43,44 if row==0 else 53]
 for col,f in enumerate(ids):
  im=seq[f].resize((256,256),Image.Resampling.NEAREST);contact.paste(im,(col*256,row*280+24),im);draw.text((col*256+8,row*280+8),f'{name} / F{f:02}',fill='#253e55')
contact.save(out/'sequence_overview.png')
(out/'bundle.json').write_text(json.dumps({'clips':manifest,'original_assets':{'run':'original_assets/run','stationary_attack':'original_assets/attack','stationary_skill':'original_assets/skill'},'alignment_logical64':{'run':{'resize_canvas':48,'paste':[-1,14]},'attack':{'resize_canvas':58,'paste':[-7,5]},'skill':'existing 128px frames unchanged'},'notice':'Stationary actions after run; simultaneous running attacks have not been created.'},indent=2),encoding='utf-8')
(out/'verification.json').write_text(json.dumps(qa,indent=2),encoding='utf-8')
archive=character/'character_01_motion_bundle_v001.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
 for p in out.rglob('*'):
  if p.is_file() and '__pycache__' not in p.parts:z.write(p,p.relative_to(character))
print(json.dumps({'clips':manifest,'zip_bytes':archive.stat().st_size}))
