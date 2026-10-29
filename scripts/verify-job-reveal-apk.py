from pathlib import Path
import zipfile,hashlib,json,sys
root=Path(__file__).resolve().parents[1]
apk=root/'output/android/FocusQuest-job-reveal-v001-debug.apk'
paths=[]
for directory in ['diagnosis/job_reveal_v001','lobby/portraits','lobby/portraits/female']:
 for file in sorted((root/'mobile/assets/images'/directory).glob('*.png')):
  if directory=='lobby/portraits/female' and file.name=='gunner.png': continue
  if directory=='lobby/portraits/female' and file.name not in ['gunner_dark_brown_transparent_v002.png'] and file.stem not in ['warrior','boxer','samurai','guardian','ninja','assassin','ranger','mage','spellblade','onmyoji','reaper','angel','devil','dragon_knight','berserker']:continue
  paths.append(file)
paths.append(root/'mobile/assets/fonts/NotoSerifJP.ttf')
results=[]
with zipfile.ZipFile(apk) as z:
 for file in paths:
  rel=file.relative_to(root/'mobile').as_posix()
  original=hashlib.sha256(file.read_bytes()).hexdigest()
  included=hashlib.sha256(z.read('assets/flutter_assets/'+rel)).hexdigest()
  assert original==included,rel
  results.append(dict(asset=rel,sha256=original,matches=True))
 assert 'lib/arm64-v8a/libflutter.so' in z.namelist()
 assert 'assets/flutter_assets/kernel_blob.bin' in z.namelist()
report=dict(apk=apk.name,bytes=apk.stat().st_size,sha256=hashlib.file_digest(apk.open('rb'),'sha256').hexdigest(),verified_assets=len(results),assets=results)
(root/'art/job_reveal_v001/android-verification.json').write_text(json.dumps(report,indent=2))
print(json.dumps(dict(apk=apk.name,verified_assets=len(results),bytes=report['bytes'],sha256=report['sha256'])))
