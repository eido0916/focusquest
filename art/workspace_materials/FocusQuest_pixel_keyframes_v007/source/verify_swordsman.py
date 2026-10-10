from pathlib import Path
from PIL import Image
import numpy as np,json,hashlib
root=Path(__file__).resolve().parent.parent;prior=root.parent/'FocusQuest_pixel_keyframes_v004'
colors=set();count=0
for a in ['run','attack_down','skill_wave']:
 for p in (root/'players/character_01'/a/'keyframes').glob('*.png'):
  im=Image.open(p).convert('RGBA');x=np.array(im)
  assert np.array_equal(x,np.repeat(np.repeat(x[::2,::2],2,0),2,1)),p
  box=im.getbbox();assert box[0]>0 and box[1]>0 and box[2]<128 and box[3]<128,(p,box)
  colors.update(map(tuple,x[x[:,:,3]==255]));count+=1
assert count==28 and len(colors)<=40,(count,len(colors))
other=0
for kind in ['players','enemies']:
 for p in (prior/kind).rglob('*'):
  if p.is_file() and 'character_01' not in p.parts:
   assert p.read_bytes()==(root/p.relative_to(prior)).read_bytes(),p;other+=1
for p in (prior/'players/character_01/idle').rglob('*'):
 if p.is_file():assert p.read_bytes()==(root/p.relative_to(prior)).read_bytes(),p
result={'new_original_poses':count,'shared_palette_opaque_colors':len(colors),'pixel_grid_2x2_pass':True,'no_canvas_edge_clipping':True,'idle_unchanged':True,'all_other_character_files_unchanged':True,'unchanged_other_files_verified':other}
(root/'swordsman_verification.json').write_text(json.dumps(result,indent=2),encoding='utf-8');print(json.dumps(result))
