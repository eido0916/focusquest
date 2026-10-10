from pathlib import Path
from PIL import Image
import numpy as np,json
root=Path(__file__).resolve().parent.parent;prior=root.parent/'FocusQuest_pixel_keyframes_v006'
for actor in ['slime','goblin','dracula']:
 f=root/f'enemies/{actor}/defeat';m=json.loads((f/'animation.json').read_text(encoding='utf-8'))
 assert len(m['keyframes'])==8 and len(m['timeline'])==30 and m['loop_in_game'] is False
 first=Image.open(f/'keyframes/frame_000.png').convert('RGBA')
 ref=Image.open(prior/f'enemies/{actor}/locomotion/keyframes/frame_000.png').convert('RGBA')
 assert first.tobytes()==ref.tobytes()
 assert Image.open(f/'keyframes/frame_007.png').getchannel('A').getbbox() is None
 xs=[v['root_offset_px'][0] for v in m['timeline']];assert xs==sorted(xs) and xs[0]==0 and xs[-1]==44
 for p in (f/'keyframes').glob('*.png'):
  im=Image.open(p).convert('RGBA');a=np.array(im);assert np.array_equal(a,np.repeat(np.repeat(a[::2,::2],2,0),2,1)),p
  b=im.getbbox()
  if b:assert b[0]>0 and b[1]>0 and b[2]<128 and b[3]<128,(p,b)
count=0
for kind in ['players','enemies']:
 for p in (prior/kind).rglob('*'):
  if p.is_file():assert p.read_bytes()==(root/p.relative_to(prior)).read_bytes(),p;count+=1
result={'new_defeat_animations':3,'new_original_keyframes':24,'all_first_frames_equal_existing_neutral':True,'all_last_frames_fully_transparent':True,'world_knockback_right_44px':True,'all_pixel_grids_and_canvas_margins_pass':True,'unchanged_existing_asset_files':count}
(root/'defeat_verification.json').write_text(json.dumps(result,indent=2),encoding='utf-8');print(json.dumps(result))
