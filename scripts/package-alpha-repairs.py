"""Copy reviewed imagegen repairs byte-for-byte, preserving original sources."""
from pathlib import Path
from PIL import Image
import hashlib
import json
import shutil

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'art/portrait_alpha_v002'
jobs = json.loads((ROOT / 'output/portraits/alpha-generated.json').read_text(encoding='utf-8'))
assert len(jobs) == 16 and len({j['role'] for j in jobs}) == 16
records = []
for job in jobs:
    role = job['role']
    source = Path(job['path'])
    asset = ROOT / f'mobile/assets/images/lobby/portraits/{role}.png'
    backup = ART / 'originals_before' / f'{role}.png'
    repaired = ART / 'repaired' / f'{role}.png'
    for folder in (backup.parent, repaired.parent):
        folder.mkdir(parents=True, exist_ok=True)
    if not backup.exists():
        shutil.copy2(asset, backup)
    with Image.open(source) as image:
        assert image.mode == 'RGBA' and image.getchannel('A').getextrema()[0] == 0
    shutil.copy2(source, repaired)
    shutil.copy2(repaired, asset)
    assert source.read_bytes() == asset.read_bytes()
    records.append(dict(role=role, tool='image_gen.imagegen', generated_source=str(source),
                        original_sha256=hashlib.sha256(backup.read_bytes()).hexdigest(),
                        repaired_sha256=hashlib.sha256(asset.read_bytes()).hexdigest()))
(ART / 'manifest.json').write_text(json.dumps(records, ensure_ascii=False, indent=2), encoding='utf-8')
print('Packaged 16 reviewed male repairs; female assets unchanged.')
