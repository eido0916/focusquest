from pathlib import Path
from PIL import Image,ImageDraw
import json
root=Path(__file__).resolve().parents[1]
art=root/'art/job_reveal_v001'
dest=root/'mobile/assets/images/diagnosis/job_reveal_v001'
dest.mkdir(parents=True,exist_ok=True)
(art/'materials').mkdir(exist_ok=True)
entries=[]
for f in sorted((art/'source').glob('*.png')):
 im=Image.open(f).convert('RGBA')
 if f.stem!='background':
  bounds=im.getchannel('A').point(lambda a:255 if a>16 else 0).getbbox()
  if bounds: im=im.crop(bounds)
 im.save(dest/f.name,optimize=False)
 im.save(art/'materials'/f.name,optimize=False)
 entries.append(dict(file=f.name,width=im.width,height=im.height))
(art/'manifest.json').write_text(json.dumps(entries,indent=2))
sheet=Image.new('RGB',(1200,1200),'#253553');d=ImageDraw.Draw(sheet)
for i,e in enumerate(entries):
 im=Image.open(dest/e['file']);im.thumbnail((370,530)); x=i%3*400;y=i//3*400
 if im.height>350:im.thumbnail((370,350))
 sheet.paste(im,(x+(400-im.width)//2,y),im);d.text((x+12,y+370),e['file'],fill='white')
sheet.save(art/'asset-sheet.jpg')
print(json.dumps(entries))
