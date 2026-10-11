from pathlib import Path
import shutil,json,hashlib
from PIL import Image
root=Path(__file__).resolve().parent
source=root/'FocusQuest_character_preproduction_v01'
repo=root/'focusquest-motion-publish'
dest=repo/'art/animation_materials'
folders=['animation_v001','animation_v002','animation_v003','animation_v004','animation_v005','field_pixel_v001','field_run_v001','field_attack_down_v001','field_skill_wave_v001','motion_bundle_v001','reference']
ignore=shutil.ignore_patterns('__pycache__','*.pyc','*.zip','*.log')
for name in folders:shutil.copytree(source/'character_01'/name,dest/'character_01'/name,dirs_exist_ok=True,ignore=ignore)
for name in ['enemies_v001','enemy_attacks_v001']:shutil.copytree(source/name,dest/name,dirs_exist_ok=True,ignore=ignore)
shutil.copy2(root/'FocusQuest_主人公アニメーション素材受け渡し仕様_v0.1.md',dest/'FocusQuest_主人公アニメーション素材受け渡し仕様_v0.1.md')
# Full file integrity record plus PNG decode verification for published frames.
records=[];pngs=0
for p in sorted(dest.rglob('*')):
 if not p.is_file() or p.name=='file_manifest.json':continue
 assert p.stat().st_size<100*1024*1024,p
 rec={'path':p.relative_to(dest).as_posix(),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
 if p.suffix.lower()=='.png':
  with Image.open(p) as im:im.verify()
  pngs+=1
 records.append(rec)
# Check the current deliverables, not just historical verification reports.
checks={}
for folder,prefix,count,size in [('character_01/field_run_v001/frames','character_01_run_',6,(128,128)),('character_01/field_attack_down_v001/frames','character_01_attack_down_',8,(128,128)),('character_01/field_skill_wave_v001/frames','character_01_skill_wave_',12,(128,128)),('character_01/animation_v005/illustration/runtime/run','character_01_illustration_run_',24,(256,256)),('character_01/animation_v005/pixel/runtime/run','character_01_pixel_run_',24,(256,256))]:
 paths=list((dest/folder).glob('*.png'));assert len(paths)==count,(folder,len(paths))
 for p in paths:
  with Image.open(p) as im:assert im.size==size and im.mode=='RGBA',(p,im.size,im.mode)
 checks[folder]={'frames':count,'rgba_dimensions_pass':True}
for key in ['slime','goblin','dracula']:
 for group,count in [('enemies_v001',6),('enemy_attacks_v001',8)]:
  paths=list((dest/group/key/'frames').glob('*.png'));assert len(paths)==count
  for p in paths:
   with Image.open(p) as im:assert im.size==(128,128) and im.mode=='RGBA'
  checks[f'{group}/{key}/frames']={'frames':count,'rgba_dimensions_pass':True}
(dest/'file_manifest.json').write_text(json.dumps({'files':records,'file_count':len(records),'total_bytes':sum(r['bytes'] for r in records),'png_decode_checks':pngs,'current_motion_checks':checks},ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({'files':len(records),'MB':round(sum(r['bytes'] for r in records)/1024**2,2),'png_decode_checks':pngs,'current_motion_groups':len(checks)},ensure_ascii=False))
