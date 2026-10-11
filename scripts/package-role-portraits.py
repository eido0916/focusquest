"""Copy the supplied male/female PNGs; create review sheets and source hashes."""
from pathlib import Path
import hashlib
import io
import json
import shutil
import zipfile
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
SOURCE = Path('C:/Users/eido0/OneDrive/デスクトップ/FQ_16職_ロビー用立ち絵_改訂版')
ZIP = Path('C:/Users/eido0/OneDrive/デスクトップ/FQ_%E5%A5%B3%E6%80%A7%E7%89%88_16%E8%81%B7_%E9%80%8F%E9%81%8E%E7%AB%8B%E3%81%A1%E7%B5%B5.zip')
ROLES = ('warrior', 'boxer', 'samurai', 'guardian', 'ninja', 'assassin',
         'ranger', 'gunner', 'mage', 'spellblade', 'onmyoji', 'reaper',
         'angel', 'devil', 'dragon_knight', 'berserker')
REVIEW = ROOT / 'output/portraits/role-review'
REVIEW.mkdir(parents=True, exist_ok=True)
font = ImageFont.truetype('C:/Windows/Fonts/meiryo.ttc', 22)
records = []
with zipfile.ZipFile(ZIP) as archive:
    for variant in ('male', 'female'):
        tiles = []
        for number, role in enumerate(ROLES, 1):
            if variant == 'male':
                source, = SOURCE.glob(f'{number:02d}_*.png')
                repaired = ROOT / 'art/portrait_alpha_v002/repaired' / f'{role}.png'
                if repaired.exists():
                    source = repaired
                raw = source.read_bytes()
                name = source.name
            else:
                name, = [n for n in archive.namelist() if n.startswith(f'{number:02d}_') and n.endswith('.png')]
                raw = archive.read(name)
            image = Image.open(io.BytesIO(raw)).convert('RGBA')
            assert image.getchannel('A').getextrema()[0] == 0, name
            target = ROOT / 'mobile/assets/images/lobby/portraits'
            if variant == 'female':
                target /= 'female'
            target.mkdir(parents=True, exist_ok=True)
            target /= f'{role}.png'
            target.write_bytes(raw)
            assert target.read_bytes() == raw
            records.append(dict(appearance=variant, role=role, source=name,
                                asset=str(target.relative_to(ROOT)).replace('\\', '/'),
                                size=image.size, alpha_bbox=image.getbbox(),
                                sha256=hashlib.sha256(raw).hexdigest()))
            tile = Image.new('RGB', (400, 660), '#cad8df')
            draw = ImageDraw.Draw(tile)
            draw.text((12, 10), f'{variant} {name}', fill='#16283a', font=font)
            # Review thumbnails only. Runtime assets are byte-for-byte originals.
            preview = image.copy()
            preview.thumbnail((390, 590))
            tile.paste(preview, ((400-preview.width)//2, 55), preview)
            tiles.append(tile)
        for page in range(4):
            sheet = Image.new('RGB', (1600, 660))
            for column, tile in enumerate(tiles[page*4:page*4+4]):
                sheet.paste(tile, (column*400, 0))
            sheet.save(REVIEW / f'{variant}-{page+1}.jpg', quality=95)
(REVIEW / 'manifest.json').write_text(json.dumps(records, ensure_ascii=False, indent=2), encoding='utf-8')
print('Verified and packaged 32 source-identical transparent PNGs.')
