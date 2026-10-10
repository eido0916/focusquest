from pathlib import Path
import json,hashlib,shutil
ROOT=Path(__file__).resolve().parent
OLD=ROOT/'FocusQuest_pixel_keyframes_v009'
OUT=ROOT/'FocusQuest_pixel_keyframes_v010'
SRC=OUT/'source/gunner_v010';SRC.mkdir(parents=True,exist_ok=True)
for name in ['catalog.json','verification.json','index.html']:
 shutil.copy2(OLD/name,SRC/f'v009_{name}')
manifest={}
for kind in ['players','players_female','enemies']:
 for p in (OLD/kind).rglob('*'):
  if p.is_file():manifest[p.relative_to(OLD).as_posix()]=hashlib.sha256(p.read_bytes()).hexdigest()
(SRC/'v009_asset_sha256.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
for name in ['8.png','女.png']:shutil.copy2(Path('C:/Users/yuusy/Downloads/キャラクター')/name,SRC/name)
s=(OLD/'source/build_ranged.py').read_text(encoding='utf-8')
s=s.replace("FocusQuest_pixel_keyframes_v008","FocusQuest_pixel_keyframes_v009").replace('ranged_v009','gunner_v010').replace('v008_','v009_')
s=s.replace('[4,3,3,2,3,3,2,3,3,2,4,4]','[3,2,2,1,1,1,1,1,1,1,3,3]')
s=s.replace("if action=='bow_shot'","if action=='gun_shot'").replace("if action=='rapid_shot'","if action=='quick_fire'").replace("'arrow_release'","'bullet_release'")
s=s.replace("'archer' if s['n']==7 else 'mage'","'gunner'")
s=s.replace("labels={'run':'走行','bow_shot':'停止して弓で射る','rapid_shot':'構えて弓を3連射','fire_cast':'杖から火の魔法','ice_burst':'杖から大きな氷結魔法'}","labels={'run':'走行','gun_shot':'停止して単発射撃','quick_fire':'停止して早撃ち・3連射'}")
s=s.replace('(1024,256)','(512,256)').replace('ranged_overview.png','gunner_overview.png').replace('id="ranged"','id="gunner"').replace('弓使い・魔法使い 男女版 v009','ガンナー 男女版 v010').replace('弓使いと魔法使いの男女版','ガンナーの男女版').replace('width:1024px','width:512px')
s=s.replace("'<section id=\"female\">'","'<section id=\"ranged\">'")
s=s.replace(".replace('男性プレイヤー6体・女性プレイヤー6体・敵3体','男性プレイヤー8体・女性プレイヤー8体・敵3体')",".replace('男性プレイヤー8体・女性プレイヤー8体・敵3体','男性プレイヤー9体・女性プレイヤー9体・敵3体')")
s=s.replace('ranged_verification.json','gunner_verification.json').replace("'new_characters':4","'new_characters':2").replace("'new_animations':12","'new_animations':6").replace("'new_drawn_originals':112","'new_drawn_originals':56").replace("'new_originals':112","'new_originals':56")
(OUT/'source/build_gunner.py').write_text(s,encoding='utf-8')
s=(OLD/'source/verify_ranged.py').read_text(encoding='utf-8').replace("['character_07','character_07_female','character_08','character_08_female']","['character_09','character_09_female']").replace("['run','bow_shot','fire_cast']","['run','gun_shot']").replace('rapid_shot','quick_fire').replace('arrow_release','bullet_release').replace('ranged_verification','gunner_verification').replace('len(checks)==12','len(checks)==6').replace('All 12 ranged','All 6 gunner')
(OUT/'source/verify_gunner.py').write_text(s,encoding='utf-8')
s=(OLD/'source/verify_saved.py').read_text(encoding='utf-8').replace('FocusQuest_pixel_keyframes_v009.zip','FocusQuest_pixel_keyframes_v010.zip')
(OUT/'source/verify_saved.py').write_text(s,encoding='utf-8')
print('Prepared v010 with v009 baseline and gunner production/validation scripts.')
