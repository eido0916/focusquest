"""Composite review images from shipped originals without altering any assets."""
from pathlib import Path
import json
from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parents[1]
ART=ROOT/'art/role_skill_effects_v001'
ASSETS=ROOT/'mobile/assets/images'
manifest=json.loads((ART/'manifest.json').read_text(encoding='utf-8'))
bindings=json.loads((ASSETS/'role_skill_effects/bindings.json').read_text(encoding='utf-8'))
font=ImageFont.truetype('C:/Windows/Fonts/meiryo.ttc',18)
background=Image.open(ASSETS/'ui/forest_meadow_pixel_v001.png').convert('RGBA')
background=background.resize((960,540),Image.Resampling.NEAREST)
overview=Image.new('RGB',(960,16*300//2),'#14272b')
for ri,(role,data) in enumerate(manifest.items()):
    bind=bindings[role+'_male'];source=bind['source_motion']
    meta=json.loads((ASSETS/f'playable_stage/{source}_skill.json').read_text(encoding='utf-8-sig'))
    tick=min(len(meta['timeline'])-1,bind['release_ticks'][0]+2)
    row=meta['timeline'][tick];key=row['keyframe'];dx,dy=row['root_offset_px']
    anchor=meta.get('sprite_anchor_px',[64,114])
    scene=background.copy()
    hero=Image.open(ASSETS/f'playable_stage/{source}_skill_{key:03}.png').convert('RGBA')
    hero=hero.resize((192,192),Image.Resampling.NEAREST)
    scene.alpha_composite(hero,(round(345+(dx-anchor[0])*1.5),round(405+(dy-anchor[1])*1.5)))
    fx=Image.open(ART/role/'keyframes'/f"{role}_{bind['timeline'][tick]['keyframe']:03}.png").convert('RGBA')
    fx=fx.resize((2304,384),Image.Resampling.NEAREST)
    scene.alpha_composite(fx,(round(345+dx*1.5),round(405+dy*1.5-384)))
    draw=ImageDraw.Draw(scene);draw.rectangle((0,0,960,55),fill='#14272b')
    draw.text((18,16),data['role']+' / '+data['skill'],font=font,fill='white')
    scene.convert('RGB').save(ART/role/'battle_preview.png')
    overview.paste(scene.convert('RGB').resize((480,270),Image.Resampling.NEAREST),((ri%2)*480,(ri//2)*300+25))
    ImageDraw.Draw(overview).text(((ri%2)*480+10,(ri//2)*300),data['role']+' / '+data['skill'],font=font,fill='white')
# Full individual previews are authoritative; montage is a convenient crop.
overview.save(ART/'battle_overview.png')
print('16 original-frame battle compositions saved')
