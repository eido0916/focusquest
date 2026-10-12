"""Package individually generated UI assets without changing source artwork."""
from pathlib import Path
import json
from PIL import Image, ImageOps, ImageDraw

root = Path(__file__).resolve().parents[1]
source = root / 'art/diagnosis_ui_v001/source'
dest = root / 'mobile/assets/images/diagnosis/sanctuary_v001'
dest.mkdir(parents=True, exist_ok=True)
entries = []
for file in sorted(source.glob('*.png')):
    image = Image.open(file).convert('RGBA')
    bounds = image.getchannel('A').point(lambda a: 255 if a > 16 else 0).getbbox()
    if file.stem != 'sanctuary' and bounds:
        image = image.crop(bounds)
    image.save(dest / file.name, optimize=True)
    entries.append({'file': file.name, 'width': image.width, 'height': image.height,
                    'source': 'source/' + file.name, 'alpha_bounds': bounds})
(source.parent / 'manifest.json').write_text(json.dumps(entries, indent=2), encoding='utf-8')
sheet = Image.new('RGB', (1000, ((len(entries) + 1) // 2) * 260), '#243653')
draw = ImageDraw.Draw(sheet)
for i, entry in enumerate(entries):
    image = Image.open(dest / entry['file']).convert('RGBA')
    image.thumbnail((460, 215))
    x, y = (i % 2) * 500, (i // 2) * 260
    sheet.paste(image, (x + (500-image.width)//2, y + 10), image)
    draw.text((x+20, y+234), entry['file'], fill='white')
sheet.save(source.parent / 'asset-sheet.jpg')
print(json.dumps(entries, indent=2))
