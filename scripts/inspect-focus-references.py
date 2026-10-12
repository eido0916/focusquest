from pathlib import Path
from PIL import Image, ImageDraw
import json
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'art/focus_selection_v001'
OUT.mkdir(parents=True, exist_ok=True)
roles = ['warrior','boxer','samurai','guardian','ninja','assassin','ranger','mage','gunner','spellblade','onmyoji','reaper','angel','devil','dragon_knight','berserker']
sheet = Image.new('RGB', (1280, 1020), '#17283a')
refs=[]
for sex in ['male','female']:
    for i, role in enumerate(roles):
        src=ROOT / f'mobile/assets/images/portraits/{sex}/{role}.webp'
        im=Image.open(src).convert('RGB')
        im.thumbnail((150,220))
        idx=i+(16 if sex=='female' else 0)
        x,y=idx%8*160,idx//8*255
        sheet.paste(im,(x+(150-im.width)//2,y))
        ImageDraw.Draw(sheet).text((x+3,y+225),f'{sex} {role}',fill='white')
        refs.append(dict(sex=sex,role=role,src=str(src)))
sheet.save(OUT/'portrait_references.png')
(OUT/'references.json').write_text(json.dumps(refs,indent=2),encoding='utf-8')
print('32 reference portraits inspected')
pixels=Image.new('RGBA',(1280,512),'#c0cbd1')
for sex in ['male','female']:
    for i,role in enumerate(roles):
        src=ROOT / f'mobile/assets/images/playable_stage/character_{i+1:02d}{"_female" if sex=="female" else ""}_run_000.png'
        im=Image.open(src).convert('RGBA')
        idx=i+(16 if sex=='female' else 0)
        pixels.alpha_composite(im,(idx%8*160,idx//8*128))
pixels.save(OUT/'pixel_references.png')
