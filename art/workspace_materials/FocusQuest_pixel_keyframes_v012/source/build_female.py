from pathlib import Path
from PIL import Image, ImageDraw
import json, shutil, hashlib, html
import numpy as np

def separate_original_cells(atlas,cols=8,rows=3):
 # Segment connected drawn pixels before extraction, so a sword tip crossing
 # a nominal grid line is not truncated or attached to the previous drawing.
 a=np.array(atlas);h,w=a.shape[:2];mask=a[:,:,3]>=128
 runs=[];parent=[];prev=[]
 def root(i):
  while parent[i]!=i:parent[i]=parent[parent[i]];i=parent[i]
  return i
 for y,row in enumerate(mask):
  edges=np.diff(np.r_[False,row,False].astype(np.int8));starts=np.where(edges==1)[0];ends=np.where(edges==-1)[0];cur=[]
  for x0,x1 in zip(starts,ends):
   k=len(runs);runs.append((y,int(x0),int(x1)));parent.append(k);cur.append(k)
   for p in prev:
    _,l,r=runs[p]
    if r<x0:continue
    if l>x1:break
    parent[root(k)]=root(p)
  prev=cur
 components={}
 for i,r in enumerate(runs):components.setdefault(root(i),[]).append(r)
 groups=[[] for _ in range(cols*rows)];counts=[]
 for rr in components.values():
  area=sum(r-l for y,l,r in rr)
  if area<3:continue
  cx=sum((l+r-1)/2*(r-l) for y,l,r in rr)/area;cy=sum(y*(r-l) for y,l,r in rr)/area
  col=max(0,min(cols-1,int(cx/(w/cols))));row=max(0,min(rows-1,round(cy/(h/rows)-.55)))
  groups[row*cols+col].extend(rr)
 bounds=[]
 for i,rr in enumerate(groups):
  assert rr,('empty original cell',i)
  ox=round((i%cols)*w/cols);oy=round((i//cols)*h/rows)
  bounds.append((min(l for y,l,r in rr)-ox,min(y for y,l,r in rr)-oy,max(r for y,l,r in rr)-ox,max(y for y,l,r in rr)+1-oy))
 common=(min(b[0] for b in bounds),min(b[1] for b in bounds),max(b[2] for b in bounds),max(b[3] for b in bounds))
 cells=[]
 for i,rr in enumerate(groups):
  ox=round(i%cols*w/cols);oy=round(i//cols*h/rows);arr=np.zeros((common[3]-common[1],common[2]-common[0],4),dtype=np.uint8)
  for y,l,r in rr:
   arr[y-oy-common[1],l-ox-common[0]:r-ox-common[0]]=a[y,l:r];arr[y-oy-common[1],l-ox-common[0]:r-ox-common[0],3]=255
  cells.append(Image.fromarray(arr))
 return cells,common

OUT=Path(__file__).resolve().parent.parent
OLD=OUT.parent/'FocusQuest_pixel_keyframes_v007'
SRC=OUT/'source/female_v008'
specs=json.loads((SRC/'inputs.json').read_text(encoding='utf-8'))
overrides=json.loads((SRC/'overrides.json').read_text(encoding='utf-8'))
# Reuse only the established exact-copy exporter, not the old production actions.
code=(OLD/'source/build_catalog.py').read_text(encoding='utf-8').split("for action,folder in [('run'")[0]
env={'__file__':str(OUT/'source/build_female.py')}
exec(compile(code,'existing_exact_copy_exporter','exec'),env)
register=env['register']
audits=[];measurements=[]
for s in specs:
 actor=f"character_{s['n']:02}_female"
 dest=SRC/actor;dest.mkdir(parents=True,exist_ok=True)
 shutil.copy2(s['path'],dest/'generated_atlas.png')
 atlas=Image.open(s['path']).convert('RGBA');w,h=atlas.size
 cells,extraction_bounds=separate_original_cells(atlas)
 placements=[];aligned=[]
 for action_index in range(3):
  chosen=cells[action_index*8:action_index*8+8];bounds=extraction_bounds;factor=256/(w/8)
  override=overrides.get(str(s['n']),{}).get(str(action_index))
  if override:
   image=Image.open(override).convert('RGBA');chosen,bounds=separate_original_cells(image,4,2);factor=256/(image.width/4)
   shutil.copy2(override,dest/f'generated_action_{action_index}.png')
  for k,im in enumerate(chosen):
   # Uniformly normalize source resolution, then place the whole drawn key
   # at the foot anchor. This is production registration, not animation tweening.
   im=im.resize((max(1,round(im.width*factor)),max(1,round(im.height*factor))),Image.Resampling.NEAREST)
   im.putalpha(im.getchannel('A').point(lambda v:255 if v>=128 else 0));b=im.getbbox()
   stage=Image.new('RGBA',(512,512));x=128+round(bounds[0]*factor)
   flight=16 if action_index==0 and k in [3,7] else 0
   y=480-flight-b[3]
   stage.alpha_composite(im,(x,y));aligned.append(stage)
   placements.append({'action_index':action_index,'keyframe':k,'source_resolution_factor':factor,'whole_original_registration_px':[x,y],'flight_original_offset_px':flight})
 allboxes=[im.getbbox() for im in aligned]
 extraction_bounds=(min(b[0] for b in allboxes),min(b[1] for b in allboxes),max(b[2] for b in allboxes),max(b[3] for b in allboxes))
 cells=[im.crop(extraction_bounds) for im in aligned]
 (dest/'registration.json').write_text(json.dumps(placements,indent=2),encoding='utf-8')
 boxes=[im.getbbox() for im in cells]
 # One uniform production scale for all poses, never per-action scaling.
 widths=[b[2]-b[0] for b in boxes if b];heights=[b[3]-b[1] for b in boxes if b]
 scale=min(56/max(im.width for im in cells),56/max(im.height for im in cells))
 raw=[]
 for im,b in zip(cells,boxes):
  if not b:
   raw.append(Image.new('RGBA',(64,64)));continue
  # Preserve the original cell coordinates and drawn flight height.
  # The same uniform export sampling applies to all 24 original drawings.
  small=im.resize((max(1,round(im.width*scale)),max(1,round(im.height*scale))),Image.Resampling.NEAREST)
  small.putalpha(small.getchannel('A').point(lambda v:255 if v>=128 else 0))
  frame=Image.new('RGBA',(64,64));frame.alpha_composite(small,((64-small.width)//2,60-small.height));raw.append(frame)
 mosaic=Image.new('RGB',(64*24,64))
 for i,im in enumerate(raw):mosaic.paste(im.convert('RGB'),(i*64,0))
 pal=mosaic.quantize(colors=48,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE)
 frames=[]
 for im in raw:
  q=im.convert('RGB').quantize(palette=pal,dither=Image.Dither.NONE).convert('RGBA');q.putalpha(im.getchannel('A'))
  q=q.resize((128,128),Image.Resampling.NEAREST);frames.append(q)
 for a,action in enumerate(s['actions']):
  source=dest/action
  for sub in ['frames','frames_24fps']:(source/sub).mkdir(parents=True,exist_ok=True)
  keys=frames[a*8:a*8+8]
  holds=[2]*8 if a==0 else ([3,3,3,2,2,3,4,4] if a==1 else [4,4,6,6,2,3,3,4])
  for k,im in enumerate(keys):im.save(source/'frames'/f'frame_{k:03}.png')
  seq=[i for i,n in enumerate(holds) for _ in range(n)]
  for tick,k in enumerate(seq):shutil.copy2(source/'frames'/f'frame_{k:03}.png',source/'frames_24fps'/f'frame_{tick:03}.png')
  events=[];offsets=[[0,0] for _ in seq]
  if a>0:events=[{'event':'attack_active' if a==1 else 'skill_release','tick':sum(holds[:3 if a==1 else 4])}]
  if a==1 and s['n'] in [1,4]:events=[{'event':'attack_active','tick':sum(holds[:4])}]
  if a==1 and s['n']==2:events=[{'event':'punch_hit','tick':sum(holds[:k]),'hit_index':i} for i,k in enumerate([2,4,5])]
  if a==2:
   events.insert(0,{'event':'energy_charge_begin','tick':sum(holds[:2])})
   if s['n']==2:events=[{'event':'energy_charge_begin','tick':sum(holds[:2])},{'event':'kick_hit','tick':sum(holds[:5])}]
   if s['n']==3:events=[{'event':'energy_charge_begin','tick':sum(holds[:2])}]+[{'event':'flurry_hit','tick':sum(holds[:k]),'hit_index':i} for i,k in enumerate([4,5,6])]
  if s['n']==5 and a==2:
   release=sum(holds[:5]);events=[{'event':'teleport','tick':release,'world_delta_px':[40,0]},{'event':'dagger_hit','tick':release}]
   offsets=[[40 if t>=release else 0,0] for t in range(len(seq))]
  m={'fps':24,'loop_in_game':a==0,'holds_ticks':holds,'display_frame_sequence':seq,'events':events,'root_offsets_px':offsets,'interpolation':'none','part_transforms':False,'crossfade':False,'direction':'right','variant':'female','reference':'女.png','production':'24 independently drawn original poses; fixed uniform production sampling, no temporal transforms or interpolated frames.'}
  (source/'animation.json').write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding='utf-8')
  register('players_female',actor,action,source,offsets=offsets,loop=a==0)
  folder=OUT/'players_female'/actor/action
  meta=json.loads((folder/'animation.json').read_text(encoding='utf-8'));meta.update({'variant':'female','corresponding_male':f"character_{s['n']:02}",'root_motion_space':'world_px_absolute_offset'})
  (folder/'animation.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2),encoding='utf-8')
 measurements.append({'character':actor,'fixed_uniform_export_scale':scale,'extraction_bounds':extraction_bounds,'logical_grid':[64,64],'drawn_originals':24,'actions':s['actions']})

# Match the existing swordswoman's idle and combined-action coverage using
# exact original copies; these clips introduce no new in-between artwork.
actor='character_01_female';records=env['records']
rest=records[(actor,'attack_down')]['keys'][0]
idle=SRC/actor/'idle';(idle/'frames').mkdir(parents=True,exist_ok=True);(idle/'frames_24fps').mkdir(exist_ok=True)
shutil.copy2(rest,idle/'frames/frame_000.png')
for t in range(48):shutil.copy2(rest,idle/'frames_24fps'/f'frame_{t:03}.png')
(idle/'animation.json').write_text(json.dumps({'loop_in_game':True,'fps':24,'events':[]}),encoding='utf-8')
register('players_female',actor,'idle',idle,loop=True)
for action,attack in [('run_then_attack','attack_down'),('run_then_skill','skill_wave')]:
 run=records[(actor,'run')];hit=records[(actor,attack)]
 display=run['display']*2+[hit['keys'][0]]*4+hit['display']
 register('players_female',actor,action,SRC/actor/attack,keys=run['keys']+hit['keys'],display=display,loop=False,events=[{**e,'tick':e['tick']+36} for e in hit['meta']['events']])

catalog=json.loads((OLD/'catalog.json').read_text(encoding='utf-8'))
catalog['characters'] += [f'character_{i:02}_female' for i in range(1,7)]
catalog['animations'] += env['catalog']
(OUT/'catalog.json').write_text(json.dumps(catalog,ensure_ascii=False,indent=2),encoding='utf-8')
report={'animation_count':len(catalog['animations']),'character_count':len(catalog['characters']),'frame_copy_checks':json.loads((OLD/'verification.json').read_text(encoding='utf-8'))['frame_copy_checks']+env['audits']}
(OUT/'verification.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
(SRC/'measurements.json').write_text(json.dumps(measurements,indent=2),encoding='utf-8')
labels={'idle':'待機（構え原画を保持）','run_then_attack':'走行→停止→攻撃','run_then_skill':'走行→停止→スキル','run':'走行','attack_down':'停止して縦斬り','skill_wave':'蓄力して斬撃波','punch_combo':'停止して連続パンチ','spin_kick':'蓄力して回転蹴り','iai':'停止して居合','energy_flurry':'蓄力して乱舞','slam':'大剣の振り下ろし','charged_sweep':'蓄力して薙ぎ払い','shuriken':'手裏剣投げ','teleport_stab':'印・瞬間移動・短刀突き','dagger_thrust':'短剣で突く','critical_strike':'蓄力してクリティカル'}
groups=[]
for s in specs:
 actor=f"character_{s['n']:02}_female";cards=[]
 for action in s['actions']+(['idle','run_then_attack','run_then_skill'] if s['n']==1 else []):
  p=f'players_female/{actor}/{action}'
  count=len(json.loads((OUT/p/'animation.json').read_text(encoding='utf-8'))['keyframes'])
  cards.append(f'<article><h3>{labels[action]}</h3><img src="{p}/preview/animation.gif"><p>{count}原画 · 128×128px · 24fps</p><a href="{p}/sprite_sheet.png">原画一覧</a> · <a href="{p}/animation.json">再生データ</a></article>')
 groups.append(f'<section id="{actor}"><h2>character_{s["n"]:02} 女性版 · {s["name"]}</h2><div class="cards">'+''.join(cards)+'</div></section>')
section='<section id="female"><h2>女性版6職業 v008</h2><p>参照画像の女性6体を使用。原画だけを切り替えて再生します。男性版・敵の素材はv007のまま保持しています。</p></section>'+''.join(groups)
page=(OLD/'index.html').read_text(encoding='utf-8').replace('<section id="enemy_defeat">',section+'<section id="enemy_defeat">',1)
(OUT/'index.html').write_text(page,encoding='utf-8')
overview=Image.new('RGB',(768,512),'#dbe4ed');d=ImageDraw.Draw(overview)
for i,s in enumerate(specs):
 actor=f"character_{s['n']:02}_female";im=Image.open(OUT/f'players_female/{actor}/run/keyframes/frame_000.png').convert('RGBA')
 x=i%3*256;y=i//3*256;overview.paste(im.resize((256,256),Image.Resampling.NEAREST),(x,y),im.resize((256,256),Image.Resampling.NEAREST));d.text((x+8,y+8),f'character_{s["n"]:02} female',fill='#29384b')
overview.save(OUT/'female_overview.png')
changed=[];oldfiles=0
for kind in ['players','enemies']:
 for p in (OLD/kind).rglob('*'):
  if p.is_file():
   oldfiles+=1
   if p.read_bytes()!=(OUT/p.relative_to(OLD)).read_bytes():changed.append(str(p))
assert not changed,changed
(OUT/'female_verification.json').write_text(json.dumps({'new_characters':6,'new_animations':21,'distinct_drawn_originals':144,'unchanged_existing_asset_files':oldfiles,'previous_assets_identical':True},indent=2),encoding='utf-8')
print(json.dumps({'new_characters':6,'new_animations':21,'distinct_drawn_originals':144,'existing_assets_unchanged':oldfiles}))

