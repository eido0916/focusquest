from pathlib import Path
from PIL import Image
import sys,json,shutil
out=Path(__file__).resolve().parent.parent
src=Path(sys.argv[1])
shutil.copy2(src,out/'source/generated_master.png')
im=Image.open(src).convert('RGBA')
im=im.resize((64,64),Image.Resampling.NEAREST)
alpha=im.getchannel('A').point(lambda x:255 if x>=128 else 0)
im=im.convert('RGB').quantize(colors=24,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE).convert('RGBA')
im.putalpha(alpha)
im.save(out/'character_01_field_logical_64.png')
final=im.resize((128,128),Image.Resampling.NEAREST)
final.save(out/'character_01_field_128.png')
final.resize((512,512),Image.Resampling.NEAREST).save(out/'character_01_field_preview_512.png')
colors=set(final.getdata())
data={'width':128,'height':128,'mode':final.mode,'logical_grid':64,'scaling':'NEAREST 2x','visible_bounds':final.getchannel('A').getbbox(),'alpha_values':sorted(set(final.getchannel('A').getdata())),'opaque_colors':len([c for c in colors if c[3]==255])}
(out/'spec.json').write_text(json.dumps(data,indent=2),encoding='utf-8')
print(json.dumps(data))
