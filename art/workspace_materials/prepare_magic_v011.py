from pathlib import Path
import json,hashlib,shutil
ROOT=Path(__file__).resolve().parent;OLD=ROOT/'FocusQuest_pixel_keyframes_v010';OUT=ROOT/'FocusQuest_pixel_keyframes_v011';SRC=OUT/'source/magic_v011';SRC.mkdir(parents=True,exist_ok=True)
for name in ['catalog.json','verification.json','index.html']:shutil.copy2(OLD/name,SRC/f'v010_{name}')
manifest={}
for kind in ['players','players_female','enemies']:
 for p in (OLD/kind).rglob('*'):
  if p.is_file():manifest[p.relative_to(OLD).as_posix()]=hashlib.sha256(p.read_bytes()).hexdigest()
(SRC/'v010_asset_sha256.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
for name in ['10.png','女2.png']:shutil.copy2(Path('C:/Users/yuusy/Downloads/キャラクター')/name,SRC/name)
s=(OLD/'source/build_gunner.py').read_text(encoding='utf-8').replace('FocusQuest_pixel_keyframes_v009','FocusQuest_pixel_keyframes_v010').replace('gunner_v010','magic_v011').replace('v009_','v010_')
s=s.replace('[3,2,2,1,1,1,1,1,1,1,3,3]','[3,3,3,4,4,3,2,2,3,2,3,4]')
start=s.index("  if action=='gun_shot'");end=s.index('  meta=',start)
s=s[:start]+"  if action=='sword_slash':events=[{'event':'sword_hit','tick':sum(holds[:4]),'keyframe':4,'direction':[1,0]}]\n  if action=='thunder_slash':events=[{'event':'thunder_charge_begin','tick':sum(holds[:3]),'keyframe':3},{'event':'electric_sword_hit','tick':sum(holds[:6]),'keyframe':6,'direction':[1,0]},{'event':'lightning_strike','tick':sum(holds[:7]),'keyframe':7,'target_offset_world_px':[48,0],'direction':[1,0]}]\n"+s[end:]
s=s.replace("'job':'gunner'","'job':'magic_swordsman'").replace("labels={'run':'走行','gun_shot':'停止して単発射撃','quick_fire':'停止して早撃ち・3連射'}","labels={'run':'走行','sword_slash':'停止して剣を振る','thunder_slash':'雷剣で斬り前方へ落雷'}")
s=s.replace('gunner_overview.png','magic_overview.png').replace('id="gunner"','id="magic"').replace('ガンナー 男女版 v010','魔剣士 男女版 v011').replace('ガンナーの男女版','魔剣士の男女版')
s=s.replace("'<section id=\"ranged\">'","'<section id=\"gunner\">'").replace(".replace('男性プレイヤー8体・女性プレイヤー8体・敵3体','男性プレイヤー9体・女性プレイヤー9体・敵3体')",".replace('男性プレイヤー9体・女性プレイヤー9体・敵3体','男性プレイヤー10体・女性プレイヤー10体・敵3体')")
s=s.replace('gunner_verification.json','magic_verification.json')
(OUT/'source/build_magic.py').write_text(s,encoding='utf-8')
s=(OLD/'source/verify_gunner.py').read_text(encoding='utf-8').replace('character_09','character_10').replace("['run','gun_shot']","['run','sword_slash']").replace("if item['action']=='quick_fire':assert len([e for e in m['events'] if e['event']=='bullet_release'])==3","if item['action']=='thunder_slash':assert len([e for e in m['events'] if e['event']=='lightning_strike'])==1").replace('gunner_verification','magic_verification').replace('6 gunner','6 magic swordsman')
(OUT/'source/verify_magic.py').write_text(s,encoding='utf-8')
s=(OLD/'source/verify_saved.py').read_text(encoding='utf-8').replace('FocusQuest_pixel_keyframes_v010.zip','FocusQuest_pixel_keyframes_v011.zip')
(OUT/'source/verify_saved.py').write_text(s,encoding='utf-8')
print('Prepared v011 production scripts and previous asset manifest.')
