"""Read-only alpha audit and contrast previews. Does not alter runtime assets."""
from pathlib import Path
from PIL import Image, ImageDraw
import json
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'output/portraits/alpha-review'
OUT.mkdir(parents=True, exist_ok=True)
roles = ('warrior', 'boxer', 'samurai', 'guardian', 'ninja', 'assassin', 'ranger', 'gunner', 'mage', 'spellblade', 'onmyoji', 'reaper', 'angel', 'devil', 'dragon_knight', 'berserker')
records = []
for gender in ('male', 'female'):
    tiles = []
    for role in roles:
        path = ROOT / 'mobile/assets/images/lobby/portraits' / ('female' if gender == 'female' else '') / f'{role}.png'
        image = Image.open(path).convert('RGBA')
        alpha = image.getchannel('A')
        mask = alpha.point(lambda v: 255 if v < 180 else 0)
        holes = mask.crop(alpha.getbbox()).histogram()[255]
        records.append(dict(gender=gender, role=role, low_alpha_in_bbox=holes, alpha_max=alpha.getextrema()[1]))
        image.thumbnail((620, 910))
        tile = Image.new('RGBA', (640, 960), '#19e077')
        tile.alpha_composite(image, ((640-image.width)//2, 40))
        ImageDraw.Draw(tile).text((10,10), f'{gender} {role}', fill='black')
        tiles.append(tile.convert('RGB'))
    for page in range(4):
        sheet = Image.new('RGB', (1280, 1920))
        for n, tile in enumerate(tiles[page*4:page*4+4]):
            sheet.paste(tile, ((n%2)*640, (n//2)*960))
        sheet.save(OUT / f'{gender}-{page+1}.jpg', quality=95)
(OUT / 'audit.json').write_text(json.dumps(records, indent=2), encoding='utf-8')
for row in records:
    print(row)
