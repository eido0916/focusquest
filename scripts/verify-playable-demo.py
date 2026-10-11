"""Verify packaged PNG bytes, source pixel hashes and the 24fps hold timelines."""
from pathlib import Path
import hashlib
import json
from PIL import Image

root = Path(__file__).resolve().parent.parent / 'playable-demo/assets'
manifest = json.loads((root / 'manifest.json').read_text(encoding='utf-8'))
for file in manifest['files']:
    path = root / file['file']
    assert hashlib.sha256(path.read_bytes()).hexdigest() == file['sha256'], path
    with Image.open(path) as image:
        assert image.size == (128, 128) and image.mode == 'RGBA'
        image.verify()
ticks = 0
for name in manifest['animations']:
    folder = root / name
    meta = json.loads((folder / 'animation.json').read_text(encoding='utf-8'))
    assert meta['fps'] == 24 and meta['interpolation'] == 'none'
    assert not meta['part_transforms'] and not meta['crossfade']
    for key in meta['keyframes']:
        with Image.open(folder / key['file']) as image:
            assert hashlib.sha256(image.convert('RGBA').tobytes()).hexdigest() == key['rgba_sha256']
    assert sum(hold['ticks'] for hold in meta['holds']) == len(meta['timeline'])
    assert all(0 <= row['keyframe'] < len(meta['keyframes']) for row in meta['timeline'])
    ticks += len(meta['timeline'])
print(f"{len(manifest['files'])} unchanged original PNGs; {len(manifest['animations'])} animations; {ticks} valid timeline ticks.")
