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

for action,folder in [('run','field_run_v001'),('attack_down','field_attack_down_v001'),('skill_wave','field_skill_wave_v001')]:
 register('players','character_01',action,OUT/'source/hero_swordsman_v005'/action)
for actor in range(2,6):
 name=f'character_{actor:02}'
 base=OLD/name/'sprite_animations_v001'
 for source in sorted(base.iterdir()):
  if source.is_dir() and (source/'animation.json').exists():
   m=read(source/'animation.json');off=m.get('root_motion_keyframes_px')
   offsets=[off[k] for k in m['display_frame_sequence']] if off else None
   register('players',name,source.name,source,offsets=offsets)

# Rebuild the two combined hero clips using untouched original keyframes.
for action,attack in [('run_then_attack','attack_down'),('run_then_skill','skill_wave')]:
 run=records[('character_01','run')];hit=records[('character_01',attack)]
 display=run['display']*2+[hit['keys'][0]]*4+hit['display']
 keys=run['keys']+hit['keys']
 register('players','character_01',action,OLD/'character_01'/'motion_bundle_v001'/action,keys=keys,display=display,loop=False,events=[{**ev,'tick':ev['tick']+len(run['display'])*2+4} for ev in hit['meta']['events'] if 'tick' in ev])

for actor in ['slime','goblin','dracula']:
 source=OLD/'enemies_v001'/actor;m=read(source/'animation.json')
 register('enemies',actor,'locomotion',source,loop=True)
 keys=sorted((source/'frames').glob('*.png'))
 display=[keys[row['pose_index']] for row in m['move_per_frame']]
 offsets=[[row['root_offset_x_px'],0] for row in m['move_per_frame']]
 register('enemies',actor,'move_left',source,keys=keys,display=display,offsets=offsets,loop=False)
 register('enemies',actor,'attack',OLD/'enemy_attacks_v001'/actor,loop=False)

idle=WORKSPACE/'FocusQuest_pixel_keyframes_v001'/'players/character_01/idle'
if (idle/'animation.json').exists():register('players','character_01','idle',idle,loop=True)
shutil.copytree(WORKSPACE/'FocusQuest_pixel_keyframes_v004/players/character_01/idle',OUT/'players/character_01/idle',dirs_exist_ok=True)

overview=Image.new('RGB',(640,360),'#dbe4ed');d=ImageDraw.Draw(overview)
actors=[f'character_{i:02}' for i in range(1,6)]+['slime','goblin','dracula']
for i,actor in enumerate(actors):
 rec=records[(actor,'run' if actor.startswith('character') else 'locomotion')]
 im=rec['images'][0];x=i%4*160;y=i//4*180
 overview.paste(im,(x+16,y+36),im);d.text((x+12,y+10),actor,fill='#29384b')
overview.save(OUT/'overview.png')
write(OUT/'catalog.json',{'standard':'original_pixel_keyframes','fps':24,'interpolation':'none','characters':actors,'animations':catalog})
write(OUT/'verification.json',{'animation_count':len(catalog),'character_count':len(actors),'frame_copy_checks':audits})
labels={'idle':'待機','run':'走行','attack_down':'剣の振り下ろし','skill_wave':'剣の蓄力と衝撃波','punch_combo':'連続パンチ','spin_kick':'蓄力と回転蹴り','iai':'居合','energy_flurry':'蓄力と乱舞','slam':'大剣の振り下ろし','charged_sweep':'蓄力と薙ぎ払い','shuriken':'手裏剣投げ','teleport_stab':'瞬間移動と短刀突き','run_then_attack':'走行→停止→攻撃','run_then_skill':'走行→停止→スキル','locomotion':'移動の原画ループ','move_left':'左へ移動','attack':'攻撃'}
groups=[]
for actor in actors:
 cards=[]
 for item in catalog:
  if item['character']!=actor:continue
  folder=item['folder'];label=labels.get(item['action'],item['action'])
  cards.append(f'<article><h3>{html.escape(label)}</h3><img src="{folder}/preview/animation.gif" alt="{actor} {label}"><p>{item["keyframes"]}原画 / {item["duration_seconds"]:.2f}秒</p><a href="{folder}/sprite_sheet.png">原画一覧</a> · <a href="{folder}/animation.json">再生データ</a></article>')
 groups.append(f'<section><h2>{actor}</h2><div class="cards">'+''.join(cards)+'</div></section>')
page='<!doctype html><html lang="ja"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>FocusQuest 原画アニメーション一覧</title><style>body{margin:0;background:#f3f5fa;color:#283447;font:16px system-ui,sans-serif}main{max-width:1120px;margin:auto;padding:32px}h1{font-size:28px}h2{margin-top:36px}h3{font-size:16px}p{color:#64718a}.cards{display:grid;grid-template-columns:repeat(auto-fit,minmax(288px,1fr));gap:18px}article{background:white;border-radius:12px;padding:16px;box-shadow:0 2px 12px #24354a0a}img{width:288px;max-width:100%;height:auto;image-rendering:pixelated;display:block}a{color:#3058a4}</style><main><h1>FocusQuest 原画アニメーション一覧</h1><p>プレイヤー5体・敵3体。原画コマをそのまま切り替える方式。プレビューは確認用に繰り返します。</p>'+''.join(groups)+'</main></html>'
page=page.replace('<h2>character_01</h2>','<h2>character_01 · 新作剣士モーション v005</h2><p>走行8原画・縦斬り8原画・蓄力斬撃12原画。待機はv001を維持。原画だけを切り替えて再生します。</p><img style="width:1024px;max-width:100%" src="swordsman_comparison.png" alt="待機と新作3動作の比較">')
(OUT/'index.html').write_text(page,encoding='utf-8')
with zipfile.ZipFile(WORKSPACE/'FocusQuest_pixel_keyframes_v005.zip','w',zipfile.ZIP_DEFLATED) as z:
 for path in OUT.rglob('*'):
  if path.is_file():z.write(path,path.relative_to(WORKSPACE))
print(json.dumps({'characters':len(actors),'animations':len(catalog),'keyframe_files':sum(r['keyframes'] for r in catalog),'display_frame_files':sum(r['display_frames'] for r in catalog),'exact_pixel_copy':'passed'},ensure_ascii=False))
