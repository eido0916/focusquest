from pathlib import Path
from PIL import Image
import numpy as np,hashlib,json
root=Path(__file__).resolve().parent.parent
prior=root.parent/'FocusQuest_pixel_keyframes_v002'
colors=set();hero_count=0;other_count=0
for p in (root/'players/character_01').glob('*/keyframes/*.png'):
 a=np.array(Image.open(p).convert('RGBA'))
 assert np.array_equal(a,np.repeat(np.repeat(a[::2,::2],2,0),2,1)),p
 colors.update(map(tuple,a[a[:,:,3]==255]));hero_count+=1
assert len(colors)<=32,len(colors)
for kind in ['players','enemies']:
 for p in (root/kind).glob('*/*/keyframes/*.png'):
  if 'character_01' in p.parts:continue
  assert hashlib.sha256(p.read_bytes()).digest()==hashlib.sha256((prior/p.relative_to(root)).read_bytes()).digest(),p
  other_count+=1
result={'hero_keyframes':hero_count,'shared_opaque_colors':len(colors),'all_hero_pixels_aligned_to_2x2_blocks':True,'unchanged_other_character_keyframes':other_count,'other_characters_equal_v002':True}
(root/'style_verification.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
print(json.dumps(result))
