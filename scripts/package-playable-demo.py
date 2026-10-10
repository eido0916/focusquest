"""Copy only original keyframes needed by the standalone playable demo."""
from pathlib import Path
import hashlib
import json
import shutil

root = Path(__file__).resolve().parent.parent
source = root / 'art/workspace_materials/FocusQuest_pixel_keyframes_v010'
dest = root / 'playable-demo/assets'
animations = {
    'hero/idle': 'players/character_01/idle',
    'hero/run': 'players/character_01/run',
    'hero/attack': 'players/character_01/attack_down',
    'hero/skill': 'players/character_01/skill_wave',
}
for enemy in ['slime', 'goblin', 'dracula']:
    for action in ['locomotion', 'attack', 'defeat']:
        animations[f'{enemy}/{action}'] = f'enemies/{enemy}/{action}'
files = []
for name, relative in animations.items():
    folder = source / relative
    meta = json.loads((folder / 'animation.json').read_text(encoding='utf-8'))
    target = dest / name
    target.mkdir(parents=True, exist_ok=True)
    shutil.copy2(folder / 'animation.json', target / 'animation.json')
    for key in meta['keyframes']:
        output = target / key['file']
        output.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(folder / key['file'], output)
        digest = hashlib.sha256(output.read_bytes()).hexdigest()
        assert digest == hashlib.sha256((folder / key['file']).read_bytes()).hexdigest()
        files.append({'file': output.relative_to(dest).as_posix(), 'sha256': digest})
shutil.copy2(root / 'art/workspace_materials/FocusQuest_stage_backgrounds_v001/grassland_v001.png', dest / 'grassland.png')
(dest / 'manifest.json').write_text(json.dumps({'source': 'FocusQuest_pixel_keyframes_v010', 'animations': list(animations), 'files': files, 'rendering': 'original PNG keyframes; 24fps holds; no interpolation or transforms'}, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(f'Packaged {len(animations)} animations, {len(files)} unchanged PNG keyframes.')
