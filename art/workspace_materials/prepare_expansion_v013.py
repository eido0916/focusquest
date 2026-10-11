from pathlib import Path
ROOT=Path(__file__).resolve().parent;OLD=ROOT/'FocusQuest_pixel_keyframes_v012';OUT=ROOT/'FocusQuest_pixel_keyframes_v013'
s=(OLD/'source/build_bosses.py').read_text(encoding='utf-8').replace('bosses_v012','enemies_v013').replace('FocusQuest_pixel_keyframes_v011','FocusQuest_pixel_keyframes_v012').replace('v011_','v012_')
start=s.index('holds_by_action=');end=s.index('all_checks=',start)
s=s[:start]+"holds_by_action={'walk':[4]*4,'attack':[6,5,3,6],'hurt':[2,3,3,4],'defeat':[5,7,8,8,2]}\n"+s[end:]
start=s.index(" for asset in s['assets']:");end=s.index(' boxes=',start)
s=s[:start]+''' local=dest/'original_atlas.png'
 if not local.exists():shutil.copy2(s['path'],local)
 atlas=Image.open(local).convert('RGBA');cells,bounds=separate_original_cells(atlas,4,4);factor=256/(atlas.width/4)
 for index,im in enumerate(cells):
  im=im.resize((round(im.width*factor),round(im.height*factor)),Image.Resampling.NEAREST)
  im.putalpha(im.getchannel('A').point(lambda v:255 if v>=128 else 0));b=im.getbbox();assert b,(s['actor'],index)
  stage=Image.new('RGBA',(512,512));x=128+round(bounds[0]*factor);y=480-b[3]
  stage.alpha_composite(im,(x,y));aligned.append(stage)
  registration.append({'action':['walk','attack','hurt','defeat'][index//4],'keyframe':index%4,'whole_original_registration_px':[x,y]})
'''+s[end:]
s=s.replace('scale=min(56/',"scale=min((56 if s['boss'] else 40)/").replace(',56/(common[3]',",(56 if s['boss'] else 40)/(common[3]")
s=s.replace("for a,asset in enumerate(s['assets']):","for a,action in enumerate(['walk','attack','hurt','defeat']):").replace("  action=asset['action'];source=dest/action","  source=dest/action").replace('frames[a*8:a*8+8]','frames[a*4:a*4+4]')
s=s.replace('[0,4,8,12,8,4,0,0]','[0,6,12,0]').replace('[0,8,16,24,32,40,44,44,44]','[0,16,32,44,44]')
s=s.replace("'fire_breath_start' if s['actor']=='boss_fire_dragon' else 'boss_attack_hit'","'boss_attack_hit' if s['boss'] else 'enemy_attack_hit'").replace("'tick':sum(holds[:4]),'keyframe':4","'tick':sum(holds[:2]),'keyframe':2").replace("'keyframe':8","'keyframe':4").replace("k==8","k==4").replace("'boss':True","'boss':s['boss']").replace("'reference':'boss_reference.png'","'reference':'Generated original character design, existing enemies used as pixel style reference'")
s=s.replace('boss_verification.json','expansion_verification.json').replace("'new_bosses':4","'new_bosses':5,'new_common_enemies':5").replace("'new_animations':16","'new_animations':40").replace("'new_keyframes':132","'new_keyframes':170").replace("'keys':132","'keys':170")
start=s.index("page=(SRC/'v012_index.html')")
s=s[:start]+'''page=(SRC/'v012_index.html').read_text(encoding='utf-8')
block='<section id="new_enemies"><h2>追加ボス5体・雑魚敵5体 v013</h2><p>移動・攻撃・被弾・撃破、左向き128×128透過の原画切り替え。</p></section>'+''.join(sections)
page=page.replace('<section id="bosses">',block+'<section id="bosses">',1);(OUT/'index.html').write_text(page,encoding='utf-8')
print(json.dumps({'new_bosses':5,'new_common_enemies':5,'new_animations':40,'keys':170,'unchanged_files':len(manifest)}))
'''
(OUT/'source/build_expansion.py').write_text(s,encoding='utf-8')
p=OUT/'source/verify_saved.py';p.write_text(p.read_text(encoding='utf-8').replace('FocusQuest_pixel_keyframes_v012.zip','FocusQuest_pixel_keyframes_v013.zip'),encoding='utf-8')
print('Prepared v013 scripts.')
