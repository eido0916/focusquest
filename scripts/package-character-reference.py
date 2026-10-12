"""Package individual reference-inspired UI assets and supplied role logos."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import zipfile, shutil, json, hashlib, re

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'art/character_ui_v002'
OUT = ROOT / 'mobile/assets/images/character_ui_v002'
GEN = Path('C:/Users/eido0/.codex/generated_images/01a12def-cf98-7153-bdf0-80bce61ef943')
FILES = {
    'identity_panel': 'c10b87b0-5fe0-4c07-b73f-d03173aa0f7d',
    'parchment_panel': '23dd6553-1b43-4f7e-b254-7d0c879581f4',
    'header_banner': 'a8e245af-fa76-4d62-931c-e47623570111',
    'equipment_row': 'fd5dda23-0e92-4c91-ba9d-5ed7f0f0ee1f',
}
ROLES = ('warrior','boxer','samurai','guardian','ninja','assassin','ranger','gunner','mage','spellblade','onmyoji','reaper','angel','devil','dragon_knight','berserker')
for folder in (ART / 'originals', ART / 'materials', ART / 'role_logos', OUT, ROOT / 'mobile/assets/images/role_logos'):
    folder.mkdir(parents=True, exist_ok=True)
manifest = []
shutil.copy2('C:/flutter/bin/cache/artifacts/material_fonts/materialicons_license.txt', ART / 'materialicons_license.txt')
for name, identifier in FILES.items():
    source = GEN / f'exec-{identifier}.png'
    shutil.copy2(source, ART / 'originals' / f'{name}.png')
    with Image.open(source) as im:
        assert im.mode == 'RGBA' and im.getchannel('A').getextrema()[0] == 0
        # Trim empty export padding; preserve generated alpha and artwork.
        im = im.crop(im.getchannel('A').point(lambda a: 255 if a > 32 else 0).getbbox())
        im.thumbnail((1280, 720), Image.Resampling.LANCZOS)
        im.save(OUT / f'{name}.png')
        im.save(ART / 'materials' / f'{name}.png')
        manifest.append({'asset': name, 'size': im.size, 'source': str(source)})
for name in ('castle_courtyard','icon_weapon','icon_armor','icon_accessory'):
    shutil.copy2(ROOT / f'mobile/assets/images/lobby/{name}.png', ART / 'materials' / f'{name}.png')
    manifest.append({'asset': name, 'source': f'Existing lobby/{name}.png'})
icons_source = Path('C:/flutter/packages/flutter/lib/src/material/icons.dart').read_text(encoding='utf-8')
for path in (ART / 'materials/title_list_panel.png', OUT / 'title_list_panel.png'):
    shutil.copy2(ROOT / 'mobile/assets/images/lobby/ornate_window.png', path)
manifest.append({'asset': 'title_list_panel', 'source': 'Existing lobby/ornate_window.png'})
icon_font = ImageFont.truetype('C:/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf', 112)
for name, glyph in {
    'stat_hp': 'favorite', 'stat_attack': 'bolt', 'stat_defense': 'shield',
    'stat_speed': 'directions_run', 'stat_critical': 'auto_awesome',
    'bag_icon': 'shopping_bag_outlined', 'certificate_icon': 'badge_outlined',
    'edit_icon': 'edit_outlined', 'level_icon': 'workspace_premium_outlined',
    'chevron_icon': 'chevron_right',
}.items():
    code = re.search(r'static const IconData ' + glyph + r' = IconData\((0x[0-9a-f]+)', icons_source).group(1)
    character = chr(int(code, 16))
    im = Image.new('RGBA', (128, 128))
    draw = ImageDraw.Draw(im)
    box = draw.textbbox((0, 0), character, font=icon_font)
    draw.text(((128 - box[2] + box[0]) / 2 - box[0], (128 - box[3] + box[1]) / 2 - box[1]),
              character, font=icon_font, fill='#ffd58b')
    im.save(OUT / f'{name}.png')
    im.save(ART / 'materials' / f'{name}.png')
    manifest.append({'asset': name, 'source': f'MaterialIcons.{glyph}', 'size': im.size})
zip_path = Path('C:/Users/eido0/Downloads/FQ_16%E8%81%B7%E3%83%AD%E3%82%B4_%E8%83%8C%E6%99%AF%E9%80%8F%E9%81%8EPNG (1).zip')
with zipfile.ZipFile(zip_path) as z:
    for role, entry in zip(ROLES, sorted(z.namelist())):
        data = z.read(entry)
        for path in (ART / 'role_logos' / f'{role}.png', ROOT / 'mobile/assets/images/role_logos' / f'{role}.png'):
            path.write_bytes(data)
        manifest.append({'asset': role, 'supplied_file': entry, 'sha256': hashlib.sha256(data).hexdigest()})
(ART / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding='utf-8')
print('Packaged 19 individual UI materials and 16 byte-identical supplied logos.')
