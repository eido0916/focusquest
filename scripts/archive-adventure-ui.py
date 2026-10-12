from pathlib import Path
import zipfile

root = Path(__file__).resolve().parents[1]
source = root / 'art/adventure_ui_v001'
destination = root / 'output/adventure_ui_v001_materials.zip'
destination.parent.mkdir(parents=True, exist_ok=True)
files = list((source / 'frames').glob('*.png')) + [
    source / name for name in ('README.md', 'manifest.json', 'prompts.json',
                               'frame_catalog.png', 'adventure_preview.png')]
assert len(files) == 15
with zipfile.ZipFile(destination, 'w', zipfile.ZIP_DEFLATED) as archive:
    for file in files:
        archive.write(file, Path('adventure_ui_v001') / file.relative_to(source))
with zipfile.ZipFile(destination) as archive:
    assert archive.testzip() is None
print(destination)
