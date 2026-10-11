from pathlib import Path
from PIL import Image
import numpy as np,json
root=Path(__file__).resolve().parent.parent;prior=root.parent/'FocusQuest_pixel_keyframes_v005'
colors=set();count=0
for p in (root/'players/character_06').glob('*/keyframes/*.png'):
 im=Image.open(p).convert('RGBA');a=np.array(im)
 assert np.array_equal(a,np.repeat(np.repeat(a[::2,::2],2,0),2,1)),p
 b=im.getbbox();assert b[0]>0 and b[1]>0 and b[2]<128 and b[3]<128,(p,b)
 colors.update(map(tuple,a[a[:,:,3]==255]));count+=1
assert count==28 and len(colors)<=40,(count,len(colors))
other=0
for kind in ['players','enemies']:
 for p in (prior/kind).rglob('*'):
  if p.is_file():assert p.read_bytes()==(root/p.relative_to(prior)).read_bytes(),p;other+=1
result={'new_actor':'character_06','original_keyframes':count,'shared_opaque_colors':len(colors),'all_pixels_aligned_to_2x2_blocks':True,'no_canvas_edge_clipping':True,'existing_files_unchanged':other}
(root/'assassin_verification.json').write_text(json.dumps(result,indent=2),encoding='utf-8');print(json.dumps(result))
