"""Package supplied art and split female contact sheets without redrawing.

Original backgrounds and role captions are preserved. Requires Pillow.
"""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'art/role_portraits/source'
OUTPUT = ROOT / 'mobile/assets/images/portraits'
ROLES = ('warrior', 'boxer', 'samurai', 'guardian', 'ninja', 'assassin',
         'ranger', 'gunner', 'mage', 'spellblade', 'onmyoji', 'reaper',
         'angel', 'devil', 'dragon_knight', 'berserker')


def save(image, appearance, role):
    folder = OUTPUT / appearance
    folder.mkdir(parents=True, exist_ok=True)
    image.thumbnail((1024, 1024), Image.Resampling.LANCZOS)
    image.save(folder / f'{role}.webp', quality=95, method=6)


def main():
    male = SOURCE / 'FQ_16_roles_character_assets_improved'
    for number, role in enumerate(ROLES, 1):
        source, = male.glob(f'{number:02d}_*.png')
        with Image.open(source) as image:
            save(image.convert('RGB'), 'male', role)

    female = SOURCE / 'FQ_female_roles_bundle'
    # Nonuniform gutters preserve scarves and wings, unlike equal grid cells.
    bounds = (
        ((40, 0, 390, 544), (405, 0, 710, 544),
         (740, 0, 1040, 544), (1080, 0, 1400, 544),
         (40, 544, 400, 1086), (415, 544, 735, 1086),
         (740, 544, 1055, 1086), (1080, 544, 1400, 1086)),
        ((55, 0, 405, 542), (415, 0, 725, 542),
         (730, 0, 1025, 542), (1040, 0, 1410, 542),
         (40, 542, 410, 1086), (415, 542, 735, 1086),
         (735, 542, 1058, 1086), (1060, 542, 1448, 1086)),
    )
    for sheet_number, rectangles in enumerate(bounds, 1):
        source, = female.glob(f'{sheet_number:02d}_*.png')
        with Image.open(source) as sheet:
            assert sheet.size == (1448, 1086), 'Unexpected sheet dimensions'
            for index, rectangle in enumerate(rectangles):
                save(sheet.crop(rectangle).convert('RGB'), 'female',
                     ROLES[(sheet_number - 1) * 8 + index])
    print(f'Packaged {len(ROLES) * 2} role portraits')


if __name__ == '__main__':
    main()
