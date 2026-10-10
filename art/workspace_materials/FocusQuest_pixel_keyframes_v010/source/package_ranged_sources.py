from pathlib import Path
import hashlib,json,shutil
OUT=Path(__file__).resolve().parent.parent;OLD=OUT.parent/'FocusQuest_pixel_keyframes_v008';SRC=OUT/'source/ranged_v009';SRC.mkdir(parents=True,exist_ok=True)
extract=(OLD/'source/build_female.py').read_text(encoding='utf-8-sig').split('OUT=Path(__file__)')[0]
(OUT/'source/extract_pixels.py').write_text(extract,encoding='utf-8')
exporter=(OLD/'source/build_catalog.py').read_text(encoding='utf-8-sig').split("for action,folder in [('run'")[0]
(OUT/'source/exact_exporter.py').write_text(exporter,encoding='utf-8')
for name in ['catalog.json','verification.json','index.html']:shutil.copy2(OLD/name,SRC/f'v008_{name}')
manifest={}
for kind in ['players','players_female','enemies']:
 for p in (OLD/kind).rglob('*'):
  if p.is_file():manifest[str(p.relative_to(OLD)).replace('\\','/')]=hashlib.sha256(p.read_bytes()).hexdigest()
(SRC/'v008_asset_sha256.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
for name in ['7.png','9.png','女.png']:shutil.copy2(Path('C:/Users/yuusy/Downloads/キャラクター')/name,SRC/name)
print('Packed self-contained extractor, exporter, baseline manifests and character references.')
