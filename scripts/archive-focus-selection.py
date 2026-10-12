from pathlib import Path
import zipfile
import json

root = Path(__file__).resolve().parents[1]
art = root / 'art/focus_selection_v001'
output = root / 'output/focus_selection_v001_materials.zip'
output.parent.mkdir(parents=True, exist_ok=True)
avatars = json.loads((art / 'avatar_manifest.json').read_text(encoding='utf-8'))
assert len(avatars) == 32
files = list((art / 'materials').glob('*.png'))
files += list((art / 'avatars').rglob('*.png'))
files += list((art / 'icons').glob('*.svg'))
files += [art / name for name in (
    'README.md', 'layout.json', 'manifest.json', 'avatar_manifest.json', 'prompts.json',
    'avatar_generation.json', 'material_catalog.png', 'avatar_catalog.png',
    'preview_390.png', 'preview_1024.png')]
with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED) as archive:
    for file in files:
        archive.write(file, Path('focus_selection_v001') / file.relative_to(art))
with zipfile.ZipFile(output) as archive:
    assert archive.testzip() is None
print(f'{len(files)} files: {output}')
