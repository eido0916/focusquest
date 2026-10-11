from pathlib import Path
from PIL import Image,ImageDraw
import numpy as np,json,shutil,hashlib
root=Path(__file__).resolve().parents[1]; out=root/'mobile/assets/images/characters/female_archer/skill';rev=root/'artifacts/female_archer_wind_review';rev.mkdir(parents=True,exist_ok=True)
src=Path('C:/Users/eido0/Downloads/風の矢エフェクト連続スプライト.png');shutil.copy2(src,rev/'source.png');im=Image.open(src).convert('RGBA')
# Unequal artwork columns. Native pixel crops, shared horizontal arrow axis.
edges=[0,175,450,768,1080,1390,1680,1938,2172];top,bottom,axis=240,485,366
w=max(b-a for a,b in zip(edges,edges[1:]));h=bottom-top
atlas=Image.new('RGBA',(w*8,h));board=Image.new('RGB',(w*4,h*2+60),'#344052');draw=ImageDraw.Draw(board)
for i,(a,b) in enumerate(zip(edges,edges[1:])):
    pose=im.crop((a,top,b,bottom));canvas=Image.new('RGBA',(w,h));canvas.paste(pose,(w-pose.width,0));canvas.save(rev/f'frame_{i+1:02d}.png');atlas.paste(canvas,(i*w,0))
    assert atlas.crop((i*w,0,(i+1)*w,h)).tobytes()==canvas.tobytes()
    x=i%4*w;y=i//4*(h+30);board.paste(canvas,(x,y+30),canvas);draw.text((x+4,y+5),str(i+1),fill='white')
atlas.save(out/'wind_arrow.png');board.save(rev/'contact_sheet.png')
(rev/'extraction.json').write_text(json.dumps(dict(sourceSha256=hashlib.sha256(src.read_bytes()).hexdigest(),edges=edges,cropY=[top,bottom],axisY=axis,width=w,height=h,frames=8,rgbaAtlasEquality=True),indent=2))
print(w,h,(axis-top)/h)
