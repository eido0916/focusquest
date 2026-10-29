from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import json
root=Path(__file__).resolve().parents[1]
art=root/'art/job_reveal_v001'
codes=json.loads((art/'role-codes.json').read_text(encoding='utf-8'))['roles']
names={'warrior':'剣士','boxer':'拳闘士','samurai':'侍','guardian':'重騎士','ninja':'忍者','assassin':'アサシン','ranger':'弓使い','gunner':'ガンナー','mage':'魔法使い','spellblade':'魔剣士','onmyoji':'陰陽師','reaper':'鎌使い','angel':'天使','devil':'悪魔','dragon_knight':'ドラゴンナイト','berserker':'バーサーカー'}
font=ImageFont.truetype(str(root/'mobile/assets/fonts/NotoSerifJP.ttf'),18)
for sex in ['male','female']:
 sheet=Image.new('RGB',(840,2000),'#142a49');d=ImageDraw.Draw(sheet)
 for i,(role,code) in enumerate(codes.items()):
  image=Image.open(art/'previews/all_roles'/f'{role}_{sex}.png').convert('RGB')
  image.thumbnail((190,439))
  x=(i%4)*210+10;y=(i//4)*500
  sheet.paste(image,(x,y));d.text((x,y+442),f'{names[role]} / {code}',fill='#f1d29b',font=font)
 sheet.save(art/f'{sex}-all-roles.jpg',quality=92)
print('32 previews, 2 review sheets')
