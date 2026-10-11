from pathlib import Path
from PIL import Image, ImageDraw
import html
import hashlib, json, shutil, zipfile
import numpy as np

OUT=Path(__file__).resolve().parent.parent
WORKSPACE=OUT.parent
OLD=WORKSPACE/'FocusQuest_character_preproduction_v01'
catalog=[];audits=[];records={}
def digest(path):
 with Image.open(path) as im:return hashlib.sha256(im.convert('RGBA').tobytes()).hexdigest()
def read(path):return json.loads(path.read_text(encoding='utf-8'))
def write(path,data):path.write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')

def register(kind,actor,action,source,keys=None,display=None,offsets=None,loop=None,events=None):
 folder=OUT/kind/actor/action
 for sub in ['keyframes','frames_24fps','preview','source']:(folder/sub).mkdir(parents=True,exist_ok=True)
 m=read(source/'animation.json') if (source/'animation.json').exists() else {}
 keys=keys or sorted((source/'frames').glob('*.png')) or sorted((source/'keyframes').glob('*.png'))
 if display is None:
  displays=sorted((source/'frames_24fps').glob('*.png'))
  if not displays:displays=sorted((source/'cycle_24fps').glob('*.png'))
  display=displays
 assert keys and display,(actor,action)
 hashes=[digest(p) for p in keys];lookup={}
 for i,h in enumerate(hashes):lookup.setdefault(h,i)
 sequence=[];images=[]
 for i,p in enumerate(keys):
  shutil.copy2(p,folder/'keyframes'/f'frame_{i:03}.png')
  with Image.open(p) as im:images.append(im.convert('RGBA'))
  a=np.array(images[-1]);assert images[-1].size==(128,128),(p,images[-1].size)
  assert set(np.unique(a[:,:,3]))<={0,255},p
 for tick,p in enumerate(display):
  h=digest(p);assert h in lookup,(actor,action,tick,'not an original keyframe')
  index=lookup[h];sequence.append(index)
  # Copy the canonical original file, without resampling, rotation or blending.
  shutil.copy2(keys[index],folder/'frames_24fps'/f'frame_{tick:03}.png')
  assert digest(folder/'frames_24fps'/f'frame_{tick:03}.png')==hashes[index]
 offsets=offsets or [[0,0] for _ in display]
 assert len(offsets)==len(display)
 if loop is None:loop=m.get('loop_in_game',m.get('game_loop',m.get('game_loop',m.get('loop',action in ['run','locomotion','idle']))))
 holds=[]
 for tick,index in enumerate(sequence):
  if holds and holds[-1]['keyframe']==index and holds[-1]['root_offset_px']==offsets[tick]:holds[-1]['ticks']+=1
  else:holds.append({'keyframe':index,'root_offset_px':offsets[tick],'ticks':1})
 direction='left' if kind=='enemies' else 'right'
 ev=events if events is not None else m.get('events',[])
 if not ev and 'active_or_release_frame' in m:ev=[{'event':'attack_active_or_release','tick':m['active_or_release_frame']}]
 if not ev and 'release_frame_24fps' in m:ev=[{'event':'skill_release','tick':m['release_frame_24fps']}]
 meta={'asset':actor,'action':action,'render_mode':'original_pixel_keyframes','canvas':[128,128],'fps':24,'direction':direction,'interpolation':'none','part_transforms':False,'crossfade':False,'loop_in_game':loop,'duration_seconds':len(display)/24,'keyframes':[{'index':i,'file':f'keyframes/frame_{i:03}.png','rgba_sha256':h} for i,h in enumerate(hashes)],'holds':holds,'events':ev,'timeline':[{'tick':i,'keyframe':k,'root_offset_px':offsets[i],'file':f'frames_24fps/frame_{i:03}.png'} for i,k in enumerate(sequence)]}
 write(folder/'animation.json',meta);write(folder/'source/original_animation.json',m)
 write(folder/'source/provenance.json',{'source_folder':str(source.relative_to(WORKSPACE)).replace('\\','/'),'keyframe_sources':[str(k.relative_to(WORKSPACE)).replace('\\','/') for k in keys]})
 cols=min(4,len(keys));rows=(len(keys)+cols-1)//cols;sheet=Image.new('RGBA',(cols*128,rows*128))
 for i,im in enumerate(images):sheet.alpha_composite(im,(i%cols*128,i//cols*128))
 sheet.save(folder/'sprite_sheet.png')
 stage=[];raw=[]
 for tick,k in enumerate(sequence):
  x,y=offsets[tick];bg=Image.new('RGBA',(288,176),'#dbe4ed');bg.alpha_composite(images[k],(64+x,16+y));stage.append(bg.convert('RGB'));raw.append(images[k])
 gifdur=[(round((i+1)*100/24)-round(i*100/24))*10 for i in range(len(display))]
 durations=[round((i+1)*1000/24)-round(i*1000/24) for i in range(len(display))]
 stage[0].save(folder/'preview/animation.gif',save_all=True,append_images=stage[1:],duration=gifdur,loop=0,disposal=2)
 raw[0].save(folder/'preview/animation.png',save_all=True,append_images=raw[1:],duration=durations,loop=0,disposal=2,blend=0)
 item={'kind':kind,'character':actor,'action':action,'folder':str(folder.relative_to(OUT)).replace('\\','/'),'keyframes':len(keys),'display_frames':len(display),'duration_seconds':len(display)/24}
 catalog.append(item);audits.append({**item,'all_display_frames_equal_originals':True,'rgba_128_binary_alpha_pass':True,'source_files_unchanged':True})
 records[(actor,action)]={'keys':keys,'display':display,'offsets':offsets,'meta':meta,'source':source,'images':images}

