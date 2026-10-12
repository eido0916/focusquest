"""Package current original PNG keyframes in a flat Flutter asset directory."""
from pathlib import Path
import hashlib
import json
import shutil
from PIL import Image

root = Path(__file__).resolve().parent.parent
source = next(path for path in [
    root.parent / 'FocusQuest_pixel_keyframes_v016',
    root / 'art/workspace_materials/FocusQuest_pixel_keyframes_v013',
    root.parent / 'FocusQuest_pixel_keyframes_v013',
    root / 'art/workspace_materials/FocusQuest_pixel_keyframes_v012',
    root.parent / 'FocusQuest_pixel_keyframes_v012',
    root / 'art/workspace_materials/FocusQuest_pixel_keyframes_v011',
    root.parent / 'FocusQuest_pixel_keyframes_v011',
    root / 'art/workspace_materials/FocusQuest_pixel_keyframes_v010',
] if path.exists())
dest = root / 'mobile/assets/images/playable_stage'
dest.mkdir(parents=True, exist_ok=True)
motions = {
    'hero_idle': 'players/character_01/idle',
    'hero_run': 'players/character_01/run',
    'hero_attack': 'players/character_01/attack_down',
    'hero_skill': 'players/character_01/skill_wave',
}
reaction_source = root / 'art/workspace_materials/FocusQuest_player_reactions_v017'
actions = [('attack_down', 'skill_wave'), ('punch_combo', 'spin_kick'),
           ('iai', 'energy_flurry'), ('slam', 'charged_sweep'),
           ('shuriken', 'teleport_stab'), ('dagger_thrust', 'critical_strike'),
           ('bow_shot', 'rapid_shot'), ('fire_cast', 'ice_burst'),
           ('gun_shot', 'quick_fire'), ('sword_slash', 'thunder_slash'),
           ('holy_talisman', 'shikigami'), ('scythe_slash', 'chain_scythe'),
           ('holy_orb', 'holy_swords'), ('dark_wave', 'curse'),
           ('spear_thrust', 'dragon_flurry'), ('heavy_punch', 'floor_throw')]
for female in [False, True]:
    for index, (attack, skill) in enumerate(actions, 1):
        character = f"character_{index:02}" + ('_female' if female else '')
        folder = f"{'players_female' if female else 'players'}/{character}"
        for action, original in [('run', 'float' if index in [13,14] else 'run'), ('attack', attack), ('skill', skill)]:
            motions[f'{character}_{action}'] = f'{folder}/{original}'
        if (source / folder / 'idle').exists():
            motions[f'{character}_idle'] = f'{folder}/idle'
        for action in ['hurt', 'defeat']:
            if (reaction_source / folder / action).exists():
                motions[f'{character}_{action}'] = f'{folder}/{action}'
for enemy in ['slime', 'goblin', 'dracula', 'mob_bat', 'mob_wolf', 'mob_skeleton', 'mob_poison_mushroom', 'mob_imp']:
    for action in ['locomotion', 'attack', 'defeat']:
        source_action = 'walk' if enemy.startswith('mob_') and action == 'locomotion' else action
        motions[f'{enemy}_{action}'] = f'enemies/{enemy}/{source_action}'
for boss in ['boss_goblin_king', 'boss_dullahan', 'boss_fire_dragon', 'boss_cyclops', 'boss_lich', 'boss_minotaur', 'boss_stone_golem', 'boss_cerberus', 'boss_demon_lord']:
    for action in ['locomotion', 'attack', 'defeat']:
        source_action = 'walk' if action == 'locomotion' else action
        motions[f'{boss}_{action}'] = f'enemies/{boss}/{source_action}'
files = []
boss_source = root / 'art/workspace_materials/FocusQuest_pixel_keyframes_v014'
for name, relative in motions.items():
    selected_source = boss_source if name.startswith('boss_') and boss_source.exists() else source
    if name.startswith('character_') and name.endswith(('_hurt', '_defeat')):
        selected_source = reaction_source
    folder = selected_source / relative
    meta = json.loads((folder / 'animation.json').read_text(encoding='utf-8'))
    shutil.copy2(folder / 'animation.json', dest / f'{name}.json')
    for key in meta['keyframes']:
        original = folder / key['file']
        target = dest / f"{name}_{key['index']:03}.png"
        shutil.copy2(original, target)
        digest = hashlib.sha256(target.read_bytes()).hexdigest()
        assert digest == hashlib.sha256(original.read_bytes()).hexdigest()
        with Image.open(target) as image:
            assert image.size == tuple(meta['canvas'])
            assert hashlib.sha256(image.convert('RGBA').tobytes()).hexdigest() == key['rgba_sha256']
        source_path = f"{relative}/{key['file']}"
        if selected_source == boss_source:
            source_path = f"{boss_source.name}/{source_path}"
        elif selected_source == reaction_source:
            source_path = f"{reaction_source.name}/{source_path}"
        files.append({'file': target.name, 'source': source_path, 'sha256': digest, 'rgba_sha256': key['rgba_sha256']})
shutil.copy2(root / 'art/workspace_materials/FocusQuest_stage_backgrounds_v001/grassland_v001.png', dest / 'grassland.png')
if (source / 'combat').exists():
    shutil.copy2(source / 'combat/floor_materials.json', dest / 'floor_materials.json')
    for material in (source / 'combat/floors').iterdir():
        for frame in material.glob('frame_*.png'):
            shutil.copy2(frame, dest / f'floor_{material.name}_{frame.stem[-3:]}.png')
    for projectile in (source / 'combat/projectiles').iterdir():
        shutil.copy2(projectile / 'frame_000.png', dest / f'effect_{projectile.name}.png')
(dest / 'manifest.json').write_text(json.dumps({'source': source.name, 'boss_source': boss_source.name if boss_source.exists() else source.name, 'player_reactions_source': reaction_source.name if reaction_source.exists() else None, 'motions': list(motions), 'files': files, 'fps': 24, 'interpolation': 'none'}, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(f'Flutter assets: {len(motions)} motions, {len(files)} original PNGs.')
