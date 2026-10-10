from pathlib import Path
from PIL import Image
import json,numpy as np
p=Path(__file__).resolve().parent.parent
names=['female_overview_final.png','female_qa_01_run.png','female_qa_01_attack_down.png','female_qa_01_skill_wave.png','female_qa_04_charged_sweep.png','female_final_crisp.png','female_skill_final_crisp.png']
for n in names:(p/n).unlink(missing_ok=True)
page=(p/'index.html').read_text(encoding='utf-8').replace('プレイヤー6体・敵3体','男性プレイヤー6体・女性プレイヤー6体・敵3体')
if 'alt="女性版6体の一覧"' not in page:
 page=page.replace('<h2>女性版6職業 v008</h2>','<h2>女性版6職業 v008</h2><img style="width:768px;max-width:100%" src="female_overview.png" alt="女性版6体の一覧">')
(p/'index.html').write_text(page,encoding='utf-8')
checks=[];c=json.loads((p/'catalog.json').read_text(encoding='utf-8'));fs=[a for a in c['animations'] if a['kind']=='players_female']
for item in fs:
 folder=p/item['folder'];boxes=[]
 for f in (folder/'keyframes').glob('*.png'):
  im=Image.open(f).convert('RGBA');a=np.array(im)
  assert np.array_equal(a[0::2,0::2],a[1::2,1::2])
  assert np.array_equal(a[0::2,1::2],a[1::2,0::2])
  b=im.getbbox();assert b and min(b[0],b[1])>0 and max(b[2],b[3])<128,(f,b);boxes.append(b)
 checks.append({'folder':item['folder'],'logical_grid_pass':True,'canvas_margins_pass':True})
r=json.loads((p/'female_verification.json').read_text(encoding='utf-8'));r['pixel_grid_and_margin_checks']=checks
(p/'female_verification.json').write_text(json.dumps(r,indent=2),encoding='utf-8')
print('Female grid and margins pass:',len(checks))
