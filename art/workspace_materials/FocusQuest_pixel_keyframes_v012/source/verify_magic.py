from pathlib import Path
from PIL import Image
import json,hashlib,numpy as np
OUT=Path(__file__).resolve().parent.parent
c=json.loads((OUT/'catalog.json').read_text(encoding='utf-8'))
checks=[]
for item in c['animations']:
 if item['character'] not in ['character_10','character_10_female']:continue
 folder=OUT/item['folder'];m=json.loads((folder/'animation.json').read_text(encoding='utf-8'));hashes=[]
 for k in m['keyframes']:
  im=Image.open(folder/k['file']).convert('RGBA');a=np.array(im)
  assert im.size==(128,128) and set(np.unique(a[:,:,3]))<={0,255}
  assert np.array_equal(a[0::2,0::2],a[1::2,1::2]) and np.array_equal(a[0::2,1::2],a[1::2,0::2])
  b=im.getbbox();assert b and min(b[0],b[1])>0 and max(b[2],b[3])<128,(folder,k,b)
  hashes.append(hashlib.sha256(im.tobytes()).hexdigest())
 assert len(set(hashes))==len(hashes),(folder,'duplicate poses')
 assert all(row['root_offset_px']==[0,0] for row in m['timeline'])
 expected=8 if item['action'] in ['run','sword_slash'] else 12
 assert len(hashes)==expected
 assert m['direction']=='right' and m['loop_in_game']==(item['action']=='run')
 for e in m['events']:
  assert m['timeline'][e['tick']]['keyframe']==e['keyframe'],(folder,e)
 if item['action']=='thunder_slash':assert len([e for e in m['events'] if e['event']=='lightning_strike'])==1
 checks.append({'folder':item['folder'],'dimensions_transparency_grid_and_margins_pass':True,'all_original_poses_distinct':True,'release_event_keyframes_match':True})
r=json.loads((OUT/'magic_verification.json').read_text(encoding='utf-8'));r['animation_checks']=checks
(OUT/'magic_verification.json').write_text(json.dumps(r,indent=2),encoding='utf-8')
assert len(checks)==6
print('All 6 magic swordsman animations pass pixel grid, canvas margins, unique poses and release events.')
