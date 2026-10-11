from pathlib import Path
from PIL import Image,ImageDraw
import numpy as np,json,shutil,hashlib

OUT=Path(__file__).resolve().parent.parent
OLD=OUT.parent/'FocusQuest_pixel_keyframes_v009'
SRC=OUT/'source/gunner_v010'
inputs=json.loads((SRC/'inputs.json').read_text(encoding='utf-8'))
# Bundled helpers keep this production script independent of older versions.
from extract_pixels import separate_original_cells as separate
import exact_exporter as exporter
env={'catalog':exporter.catalog,'audits':exporter.audits}
register=exporter.register;measurements=[]
for s in inputs:
 dest=SRC/s['actor'];dest.mkdir(parents=True,exist_ok=True)
 aligned=[];placements=[]
 for action_index,action in enumerate(s['actions']):
  spec=s['atlases'][action];local=dest/f'original_{action}.png'
  if not local.exists():shutil.copy2(spec['path'],local)
  atlas=Image.open(local).convert('RGBA');rows=2 if action_index<2 else 3
  cells,bounds=separate(atlas,4,rows);factor=256/(atlas.width/4)
  for k,im in enumerate(cells):
   im=im.resize((max(1,round(im.width*factor)),max(1,round(im.height*factor))),Image.Resampling.NEAREST)
   im.putalpha(im.getchannel('A').point(lambda v:255 if v>=128 else 0));b=im.getbbox();assert b
   stage=Image.new('RGBA',(512,512));x=128+round(bounds[0]*factor)
   flight=16 if action_index==0 and k in [3,7] else 0;y=480-flight-b[3]
   stage.alpha_composite(im,(x,y));aligned.append(stage)
   placements.append({'action':action,'keyframe':k,'source_canvas':list(atlas.size),'source_resolution_factor':factor,'whole_original_registration_px':[x,y],'flight_original_offset_px':flight})
 boxes=[im.getbbox() for im in aligned]
 common=(min(b[0] for b in boxes),min(b[1] for b in boxes),max(b[2] for b in boxes),max(b[3] for b in boxes))
 cells=[im.crop(common) for im in aligned]
 scale=min(56/cells[0].width,56/cells[0].height);raw=[]
 for im in cells:
  small=im.resize((max(1,round(im.width*scale)),max(1,round(im.height*scale))),Image.Resampling.NEAREST)
  frame=Image.new('RGBA',(64,64));frame.alpha_composite(small,((64-small.width)//2,60-small.height));raw.append(frame)
 mosaic=Image.new('RGB',(64*28,64))
 for i,im in enumerate(raw):mosaic.paste(im.convert('RGB'),(i*64,0))
 pal=mosaic.quantize(colors=48,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE)
 frames=[]
 for im in raw:
  q=im.convert('RGB').quantize(palette=pal,dither=Image.Dither.NONE).convert('RGBA');q.putalpha(im.getchannel('A'))
  q=q.resize((128,128),Image.Resampling.NEAREST);frames.append(q)
 for a,action in enumerate(s['actions']):
  source=dest/action
  for sub in ['frames','frames_24fps']:(source/sub).mkdir(parents=True,exist_ok=True)
  keys=frames[a*8:(a+1)*8] if a<2 else frames[16:28]
  holds=[2]*8 if a==0 else ([3,3,3,3,2,2,4,4] if a==1 else [3,2,2,1,1,1,1,1,1,1,3,3])
  # Run16 ticks / single-shot24 ticks / skill36 ticks, all display at24fps.
  seq=[i for i,n in enumerate(holds) for _ in range(n)]
  for k,im in enumerate(keys):im.save(source/'frames'/f'frame_{k:03}.png')
  for t,k in enumerate(seq):shutil.copy2(source/'frames'/f'frame_{k:03}.png',source/'frames_24fps'/f'frame_{t:03}.png')
  events=[]
  if action=='gun_shot':events=[{'event':'bullet_release','tick':sum(holds[:4]),'keyframe':4,'shot_index':0,'direction':[1,0]}]
  if action=='quick_fire':events=[{'event':'bullet_release','tick':sum(holds[:k]),'keyframe':k,'shot_index':i,'direction':[1,0]} for i,k in enumerate([3,6,9])]
  if action=='fire_cast':events=[{'event':'fire_charge_begin','tick':sum(holds[:3]),'keyframe':3},{'event':'fire_release','tick':sum(holds[:4]),'keyframe':4,'direction':[1,0]}]
  if action=='ice_burst':events=[{'event':'ice_charge_begin','tick':sum(holds[:3]),'keyframe':3},{'event':'ice_release','tick':sum(holds[:6]),'keyframe':6,'direction':[1,0]},{'event':'ice_peak','tick':sum(holds[:7]),'keyframe':7}]
  meta={'fps':24,'loop_in_game':a==0,'holds_ticks':holds,'display_frame_sequence':seq,'events':events,'direction':'right','variant':s['gender'],'reference':s['reference'],'interpolation':'none','part_transforms':False,'crossfade':False,'root_offsets_px':[[0,0] for _ in seq],'root_motion_space':'world_px_absolute_offset','production':'Independently drawn pixel originals; fixed production sampling only. 24fps output consists exclusively of exact original file copies.'}
  (source/'animation.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2),encoding='utf-8')
  register(s['kind'],s['actor'],action,source,loop=a==0)
  final=OUT/s['kind']/s['actor']/action/'animation.json'
  m=json.loads(final.read_text(encoding='utf-8'));m.update({'variant':s['gender'],'job':'gunner','root_motion_space':'world_px_absolute_offset','sprite_anchor_px':[64,120]})
  final.write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding='utf-8')
 measurements.append({'actor':s['actor'],'fixed_uniform_export_scale':scale,'shared_original_bounds':common,'unique_drawn_poses':28,'palette_colors':48,'logical_grid':[64,64]})
 (dest/'registration.json').write_text(json.dumps(placements,indent=2),encoding='utf-8')

catalog=json.loads((SRC/'v009_catalog.json').read_text(encoding='utf-8'))
catalog['characters']+=[s['actor'] for s in inputs];catalog['animations']+=env['catalog']
(OUT/'catalog.json').write_text(json.dumps(catalog,ensure_ascii=False,indent=2),encoding='utf-8')
oldreport=json.loads((SRC/'v009_verification.json').read_text(encoding='utf-8'))
report={'animation_count':len(catalog['animations']),'character_count':len(catalog['characters']),'frame_copy_checks':oldreport['frame_copy_checks']+env['audits']}
(OUT/'verification.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
(SRC/'measurements.json').write_text(json.dumps(measurements,indent=2),encoding='utf-8')
labels={'run':'走行','gun_shot':'停止して単発射撃','quick_fire':'停止して早撃ち・3連射'}
sections=[]
for s in inputs:
 cards=[]
 for item in env['catalog']:
  if item['character']!=s['actor']:continue
  f=item['folder'];cards.append(f'<article><h3>{labels[item["action"]]}</h3><img src="{f}/preview/animation.gif" alt="{s["name"]} {labels[item["action"]]}"><p>{item["keyframes"]}原画 / {item["duration_seconds"]:.2f}秒</p><a href="{f}/sprite_sheet.png">原画一覧</a> · <a href="{f}/animation.json">再生データ</a></article>')
 sections.append(f'<section id="{s["actor"]}"><h2>character_{s["n"]:02} · {s["name"]}</h2><div class="cards">'+''.join(cards)+'</div></section>')
overview=Image.new('RGB',(512,256),'#dbe4ed');draw=ImageDraw.Draw(overview)
for i,s in enumerate(inputs):
 im=Image.open(OUT/s['kind']/s['actor']/'run/keyframes/frame_000.png').convert('RGBA').resize((256,256),Image.Resampling.NEAREST)
 overview.paste(im,(i*256,0),im);draw.text((i*256+8,8),s['actor'],fill='#283447')
overview.save(OUT/'gunner_overview.png')
block='<section id="gunner"><h2>ガンナー 男女版 v010</h2><p>各キャラクター：走行8原画、通常攻撃8原画、スキル12原画。画像変形や中間画像を使わず原画を切り替えて再生します。</p><img style="width:512px;max-width:100%" src="gunner_overview.png" alt="ガンナーの男女版"></section>'+''.join(sections)
page=(SRC/'v009_index.html').read_text(encoding='utf-8').replace('<section id="ranged">',block+'<section id="ranged">',1).replace('男性プレイヤー8体・女性プレイヤー8体・敵3体','男性プレイヤー9体・女性プレイヤー9体・敵3体')
(OUT/'index.html').write_text(page,encoding='utf-8')
baseline=json.loads((SRC/'v009_asset_sha256.json').read_text(encoding='utf-8'));oldfiles=len(baseline)
for path,digest in baseline.items():assert hashlib.sha256((OUT/path).read_bytes()).hexdigest()==digest,path
(OUT/'gunner_verification.json').write_text(json.dumps({'new_characters':2,'new_animations':6,'new_drawn_originals':56,'unchanged_existing_asset_files':oldfiles,'all_previous_assets_identical':True},indent=2),encoding='utf-8')
print(json.dumps({'new_characters':2,'new_animations':6,'new_originals':56,'unchanged_existing_asset_files':oldfiles}))
