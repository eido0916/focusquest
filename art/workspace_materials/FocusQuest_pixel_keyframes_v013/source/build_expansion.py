from pathlib import Path
from PIL import Image,ImageDraw
import numpy as np,json,shutil,hashlib
from extract_pixels import separate_original_cells
import exact_exporter as ex
OUT=Path(__file__).resolve().parent.parent;SRC=OUT/'source/enemies_v013';OLD=OUT.parent/'FocusQuest_pixel_keyframes_v012'
SRC.mkdir(parents=True,exist_ok=True)
inputs=json.loads((SRC/'inputs.json').read_text(encoding='utf-8'))
manifest={}
for kind in ['players','players_female','enemies']:
 for p in (OLD/kind).rglob('*'):
  if p.is_file():manifest[p.relative_to(OLD).as_posix()]=hashlib.sha256(p.read_bytes()).hexdigest()
(SRC/'v012_asset_sha256.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
for n in ['catalog.json','verification.json','index.html']:shutil.copy2(OLD/n,SRC/f'v012_{n}')
holds_by_action={'walk':[4]*4,'attack':[6,5,3,6],'hurt':[2,3,3,4],'defeat':[5,7,8,8,2]}
all_checks=[]
for s in inputs:
 dest=SRC/s['actor'];dest.mkdir(parents=True,exist_ok=True);aligned=[];registration=[]
 local=dest/'original_atlas.png'
 if not local.exists():shutil.copy2(s['path'],local)
 atlas=Image.open(local).convert('RGBA');cells,bounds=separate_original_cells(atlas,4,4);factor=256/(atlas.width/4)
 for index,im in enumerate(cells):
  im=im.resize((round(im.width*factor),round(im.height*factor)),Image.Resampling.NEAREST)
  im.putalpha(im.getchannel('A').point(lambda v:255 if v>=128 else 0));b=im.getbbox();assert b,(s['actor'],index)
  stage=Image.new('RGBA',(512,512));x=128+round(bounds[0]*factor);y=480-b[3]
  stage.alpha_composite(im,(x,y));aligned.append(stage)
  registration.append({'action':['walk','attack','hurt','defeat'][index//4],'keyframe':index%4,'whole_original_registration_px':[x,y]})
 boxes=[im.getbbox() for im in aligned];common=(min(b[0] for b in boxes),min(b[1] for b in boxes),max(b[2] for b in boxes),max(b[3] for b in boxes))
 scale=min((56 if s['boss'] else 40)/(common[2]-common[0]),(56 if s['boss'] else 40)/(common[3]-common[1]));raw=[]
 for im in aligned:
  im=im.crop(common);im=im.resize((round(im.width*scale),round(im.height*scale)),Image.Resampling.NEAREST)
  stage=Image.new('RGBA',(64,64));stage.alpha_composite(im,((64-im.width)//2,60-im.height));raw.append(stage)
 mosaic=Image.new('RGB',(64*len(raw),64))
 for k,im in enumerate(raw):mosaic.paste(im.convert('RGB'),(64*k,0))
 pal=mosaic.quantize(colors=48,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE);frames=[]
 for im in raw:
  q=im.convert('RGB').quantize(palette=pal,dither=Image.Dither.NONE).convert('RGBA');q.putalpha(im.getchannel('A'));frames.append(q.resize((128,128),Image.Resampling.NEAREST))
 (dest/'registration.json').write_text(json.dumps({'fixed_scale_all_actions':scale,'shared_bounds':common,'poses':registration},indent=2),encoding='utf-8')
 for a,action in enumerate(['walk','attack','hurt','defeat']):
  source=dest/action
  for sub in ['frames','frames_24fps']:(source/sub).mkdir(parents=True,exist_ok=True)
  keys=frames[a*4:a*4+4]
  if action=='defeat':keys=keys+[Image.new('RGBA',(128,128))]
  holds=holds_by_action[action];seq=[k for k,n in enumerate(holds) for _ in range(n)]
  root_by_key=[0]*len(keys)
  if action=='hurt':root_by_key=[0,6,12,0]
  if action=='defeat':root_by_key=[0,16,32,44,44]
  offsets=[[root_by_key[k],0] for k in seq]
  events=[]
  if action=='attack':events=[{'event':'boss_attack_hit' if s['boss'] else 'enemy_attack_hit','tick':sum(holds[:2]),'keyframe':2,'direction':[-1,0]}]
  if action=='hurt':events=[{'event':'damage_reaction','tick':sum(holds[:1]),'keyframe':1}]
  if action=='defeat':events=[{'event':'defeat_begin','tick':0,'keyframe':0},{'event':'despawn','tick':sum(holds[:-1]),'keyframe':4}]
  for k,im in enumerate(keys):im.save(source/'frames'/f'frame_{k:03}.png')
  for t,k in enumerate(seq):shutil.copy2(source/'frames'/f'frame_{k:03}.png',source/'frames_24fps'/f'frame_{t:03}.png')
  meta={'fps':24,'loop_in_game':action=='walk','holds_ticks':holds,'display_frame_sequence':seq,'events':events,'direction':'left','interpolation':'none','part_transforms':False,'crossfade':False,'root_offsets_px':offsets,'root_motion_space':'world_px_absolute_offset','reference':'Generated original character design, existing enemies used as pixel style reference','production':'Drawn pixel originals with fixed production sampling; no intermediate poses or image transforms at runtime.'}
  (source/'animation.json').write_text(json.dumps(meta,indent=2),encoding='utf-8')
  ex.register('enemies',s['actor'],action,source,offsets=offsets,loop=action=='walk')
  folder=OUT/'enemies'/s['actor']/action;m=json.loads((folder/'animation.json').read_text(encoding='utf-8'));m.update({'boss':s['boss'],'root_motion_space':'world_px_absolute_offset','sprite_anchor_px':[64,120]});(folder/'animation.json').write_text(json.dumps(m,indent=2),encoding='utf-8')
  hashes=[]
  for k,im in enumerate(keys):
   ar=np.array(im);assert np.array_equal(ar[::2,::2],ar[1::2,1::2]) and np.array_equal(ar[::2,1::2],ar[1::2,::2])
   b=im.getbbox()
   if action=='defeat' and k==4:assert b is None
   else:assert b and min(b[:2])>0 and max(b[2:])<128,(s['actor'],action,k,b)
   hashes.append(hashlib.sha256(im.tobytes()).hexdigest())
  assert len(set(hashes))==len(hashes),(s['actor'],action,'duplicate originals')
  for e in events:assert m['timeline'][e['tick']]['keyframe']==e['keyframe']
  all_checks.append({'actor':s['actor'],'action':action,'keys':len(keys),'grid_margin_distinct_poses_events_pass':True,'world_knockback_only':True})
catalog=json.loads((SRC/'v012_catalog.json').read_text(encoding='utf-8'));catalog['characters'] += [s['actor'] for s in inputs];catalog['animations']+=ex.catalog
(OUT/'catalog.json').write_text(json.dumps(catalog,ensure_ascii=False,indent=2),encoding='utf-8')
oldreport=json.loads((SRC/'v012_verification.json').read_text(encoding='utf-8'));report={'animation_count':len(catalog['animations']),'character_count':len(catalog['characters']),'frame_copy_checks':oldreport['frame_copy_checks']+ex.audits}
(OUT/'verification.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
for p,h in manifest.items():assert hashlib.sha256((OUT/p).read_bytes()).hexdigest()==h,p
(OUT/'expansion_verification.json').write_text(json.dumps({'new_bosses':5,'new_common_enemies':5,'new_animations':40,'new_keyframes':170,'previous_files_unchanged':len(manifest),'checks':all_checks},indent=2),encoding='utf-8')
labels={'walk':'移動','attack':'攻撃','hurt':'被弾','defeat':'撃破・消滅'};sections=[]
for s in inputs:
 cards=[]
 for item in ex.catalog:
  if item['character']!=s['actor']:continue
  f=item['folder'];cards.append(f'<article><h3>{labels[item["action"]]}</h3><img src="{f}/preview/animation.gif" alt="{s["name"]} {labels[item["action"]]}"><p>{item["keyframes"]}原画 / {item["duration_seconds"]:.2f}秒</p><a href="{f}/sprite_sheet.png">原画一覧</a> · <a href="{f}/animation.json">再生データ</a></article>')
 sections.append(f'<section><h2>{s["name"]}</h2><div class="cards">'+''.join(cards)+'</div></section>')
page=(SRC/'v012_index.html').read_text(encoding='utf-8')
block='<section id="new_enemies"><h2>追加ボス5体・雑魚敵5体 v013</h2><p>移動・攻撃・被弾・撃破、左向き128×128透過の原画切り替え。</p></section>'+''.join(sections)
page=page.replace('<section id="bosses">',block+'<section id="bosses">',1);(OUT/'index.html').write_text(page,encoding='utf-8')
print(json.dumps({'new_bosses':5,'new_common_enemies':5,'new_animations':40,'keys':170,'unchanged_files':len(manifest)}))
