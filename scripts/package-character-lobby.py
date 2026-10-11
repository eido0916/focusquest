"""Package supplied portraits and generated UI artwork without altering sources."""
from pathlib import Path
import shutil
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'mobile/assets/images/lobby'
ART = ROOT / 'art/character_lobby_v001'
SOURCE = Path('C:/Users/eido0/OneDrive/デスクトップ/FQ_16職_ロビー用立ち絵_改訂版')
GENERATED = Path('C:/Users/eido0/.codex/generated_images/01a12434-6b68-74a2-98f7-58a23ac43954')
ROLES = ('warrior', 'boxer', 'samurai', 'guardian', 'ninja', 'assassin',
         'ranger', 'gunner', 'mage', 'spellblade', 'onmyoji', 'reaper',
         'angel', 'devil', 'dragon_knight', 'berserker')
FILES = {
    'ornate_window': 'exec-f8d18294-29aa-4b5c-bd3c-1bc268ec87ed.png',
    'castle_courtyard': 'exec-e26edab4-5b62-48a0-83b1-f8d6a3e530a6.png',
    'equipment_slot': 'exec-d96b6e30-84bc-4ac5-9f92-c1767c51d7c4.png',
}
OUT.mkdir(parents=True, exist_ok=True)
(OUT / 'portraits').mkdir(exist_ok=True)
(ART / 'originals').mkdir(parents=True, exist_ok=True)
for name, filename in FILES.items():
    shutil.copy2(GENERATED / filename, ART / 'originals' / f'{name}.png')
    with Image.open(GENERATED / filename) as image:
        # Remove the slot's empty outer navy gutters for runtime packing.
        if name == 'equipment_slot':
            image = image.crop((0, round(image.height * .12), image.width,
                                round(image.height * .82)))
        if name != 'castle_courtyard':
            image.thumbnail((1024, 1024), Image.Resampling.LANCZOS)
        image.save(OUT / f'{name}.png', optimize=True)
for number, role in enumerate(ROLES, 1):
    source, = SOURCE.glob(f'{number:02d}_*.png')
    with Image.open(source) as image:
        assert image.mode == 'RGBA', f'Expected supplied alpha: {source}'
        assert image.getchannel('A').getextrema()[0] == 0
    shutil.copy2(source, OUT / 'portraits' / f'{role}.png')
print('Packaged 3 UI images and 16 original transparent portraits.')
atlas_path = GENERATED / 'exec-35157a70-cb5f-4c8b-8a5d-cd28d93c44a4.png'
shutil.copy2(atlas_path, ART / 'originals/item_icons.png')
with Image.open(atlas_path) as atlas:
    assert atlas.mode == 'RGBA'
    for index, name in enumerate(('weapon', 'armor', 'accessory')):
        icon = atlas.crop((round(atlas.width * index / 3), 0,
                           round(atlas.width * (index + 1) / 3), atlas.height))
        icon.thumbnail((128, 128), Image.Resampling.LANCZOS)
        icon.save(OUT / f'icon_{name}.png', optimize=True)
