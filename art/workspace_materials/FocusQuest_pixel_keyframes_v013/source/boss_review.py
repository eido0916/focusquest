from pathlib import Path
from PIL import Image,ImageDraw
import json
OUT=Path(__file__).resolve().parent.parent
specs=json.loads((OUT/'source/bosses_v012/inputs.json').read_text(encoding='utf-8'))
for s in specs:
 canvas=Image.new('RGBA',(1024,896),'#dbe4ed');d=ImageDraw.Draw(canvas)
 for i,action in enumerate(['walk','attack','hurt','defeat']):
  im=Image.open(OUT/'enemies'/s['actor']/action/'sprite_sheet.png').convert('RGBA')
  x=(i%2)*512;y=(i//2)*448;canvas.alpha_composite(im,(x,y+28));d.text((x+8,y+8),action,fill='#26354a')
 canvas.save(OUT/f'{s["actor"]}_review.png')
print('Created four review contact sheets.')
