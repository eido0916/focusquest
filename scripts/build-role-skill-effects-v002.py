"""Revise the existing code-authored pixel VFX: one focal effect per role.

Each attack original is rasterized independently on the established 2px grid.
No source-image transformation or intermediate-image synthesis is used.
"""
import importlib.util
import json
import math
import shutil
from PIL import Image, ImageDraw, ImageFont

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('legacy', ROOT / 'scripts/build-role-skill-effects.py')
legacy = importlib.util.module_from_spec(spec)
spec.loader.exec_module(legacy)
OUT = ROOT / 'art/role_skill_effects_v002'
ASSETS = ROOT / 'mobile/assets/images/role_skill_effects_v002'
OLD = ROOT / 'mobile/assets/images/role_skill_effects'
DESIGNS = {
    'warrior': '一枚の青白い巨大な三日月斬撃',
    'boxer': '一つの翡翠色の渦巻く旋風',
    'samurai': '桜色の一閃と刀の切先',
    'guardian': '一つの岩盤隆起と金色の衝撃弧',
    'ninja': '一筋の影を引く巨大な苦無',
    'assassin': '紅紫の短剣と一つのクリティカル閃光',
    'ranger': '葉の風をまとった一本の巨大な光矢',
    'mage': '一つの巨大な六角氷晶',
    'gunner': '一発の巨大な銃弾と琥珀色の衝撃尾',
    'spellblade': '一本の雷剣を中心とした落雷',
    'onmyoji': '一つの五行封陣と中央の大符',
    'reaper': '一振りの巨大な冥月鎌',
    'angel': '一対の翼をもつ一つの聖剣',
    'devil': '一つの角をもつ獄炎の波',
    'dragon_knight': '一頭の竜の形をした炎の突撃',
    'berserker': '一振りの巨大な赤い裂斬と地割れ',
}


def author(kind, frame, palette):
    role = next(row[0] for row in legacy.ROLES if row[-1] == kind)
    # Exact copies of the currently shipped, approved charge originals.
    if frame < 3:
        return Image.open(OLD / f'{role}_{frame:03}.png').convert('RGBA')
    im = Image.new('RGBA', (768, 128))
    if frame == 11:
        return im.resize((1536, 256), Image.Resampling.NEAREST)
    d = ImageDraw.Draw(im)
    dark, main, light, white = palette
    # Independently drawn buildup, peak, sustained impact and broken remnants.
    phase = frame - 3
    strength = [.78, 1, .90, 1, .94, .85, .65, .42][phase]
    jitter = [0, -2, 1, -1, 2, 0, -2, 2][phase]

    def poly(points, color):
        d.polygon([(round(x), round(y)) for x, y in points], fill=color)

    def line(points, color, width=1):
        d.line([(round(x), round(y)) for x, y in points], fill=color, width=width)

    def star(x, y, rx, ry, color):
        poly([(x-rx,y),(x-3,y-3),(x,y-ry),(x+3,y-3),
              (x+rx,y),(x+3,y+3),(x,y+ry),(x-3,y+3)], color)

    def arc(cx, cy, rx, ry, start, end, color, width):
        pts = [(cx+rx*math.cos(a), cy+ry*math.sin(a))
               for a in [start + (end-start)*i/90 for i in range(91)]]
        line(pts, color, width)

    if kind == 'crescent':
        # One broad curved blade, connected to a tapering sword trail.
        x = 122 + jitter; r = 51*strength
        outer = [(x+75*math.cos(a), 65+r*math.sin(a))
                 for a in [-1.5+i*3/60 for i in range(61)]]
        inner = [(x+53*math.cos(a)-12, 65+r*.84*math.sin(a))
                 for a in [1.5-i*3/60 for i in range(61)]]
        poly(outer + inner, dark)
        poly(outer+inner, main)
        arc(x,65,70,r*.94,-1.4,1.4,light,8)
        arc(x+1,65,67,r*.9,-1.32,1.32,white,3)
        poly([(1,96),(117,90),(157,102),(66,101)], main)
        line([(13,94),(100,95),(145,103)],light,2)
    elif kind == 'wind':
        # One large spiral vortex. Nested bands belong to the same funnel.
        cx=117+jitter; cy=64
        arc(cx,cy,69*strength,52*strength,-2.7,2.6,dark,17)
        arc(cx,cy,69*strength,52*strength,-2.7,2.6,main,10)
        arc(cx,cy,69*strength,52*strength,-2.7,2.6,light,3)
        for offset, width, color in [(0,10,main),(0,5,light),(0,2,white)]:
            pts=[]
            for i in range(170):
                a=-1.6+i*.057; radius=(52-i*.23)*strength
                pts.append((cx+radius*1.35*math.cos(a),cy+radius*math.sin(a)))
            line(pts,color,width)
        line([(0,93),(42,85),(70,100),(115,112),(159,99)],main,5)
        line([(12,48),(41,35),(74,25)],light,2)
    elif kind == 'cuts':
        poly([(0,110),(213,24+jitter),(161,57),(81,89)],dark)
        poly([(0,102),(213,24+jitter),(130,66),(25,105)],main)
        poly([(12,100),(213,24+jitter),(151,52)],light)
        line([(19,98),(212,25+jitter)],white,2)
        arc(144,67,31,33,-1.2,1.1,light,2)
        star(151,51,24*strength,34*strength,white)
    elif kind == 'earth':
        # One connected fractured slab with a focal mountain of broken rock.
        poly([(2,124),(30,115),(56,105),(77,78),(100,87),
              (114,44+jitter),(149,56),(168,84),(192,105),(215,124)],dark)
        poly([(21,123),(61,113),(78,88),(103,100),(118,56),
              (141,62),(161,98),(190,115),(207,123)],main)
        poly([(81,94),(99,97),(118,56),(131,64),(120,118),(72,121)],light)
        line([(118,57),(120,117),(151,122)],white,2)
        line([(139,72),(128,91),(149,102),(146,120)],dark,3)
        arc(103,122,99*strength,64*strength,-3.03,-.1,light,4)
        arc(103,122,96*strength,59*strength,-2.9,-.2,white,2)
    elif kind == 'shadow':
        poly([(0,70),(40,66),(93,77),(151,62),(208,83),
              (146,106),(91,92),(36,100),(3,95),(62,83)],dark)
        poly([(3,82),(100,84),(151,66),(208,83),(148,101),(104,90)],main)
        poly([(121,83),(165,70),(208,83),(165,95)],light)
        poly([(132,83),(166,76),(208,83),(164,84)],white)
        d.ellipse((98,76,116,92),outline=light,width=3)
        line([(9,79),(73,81)],light,2)
        line([(34,94),(93,91)],main,3)
    elif kind == 'dagger':
        poly([(0,97),(153,57),(198,77),(156,93),(26,104)],dark)
        poly([(42,92),(159,63),(198,77),(150,83)],main)
        poly([(107,82),(159,68),(198,77),(151,78)],light)
        line([(86,87),(197,77)],white,2)
        line([(124,67),(136,96)],light,4)
        star(169+jitter,77,36*strength,54*strength,main)
        star(169+jitter,77,23*strength,42*strength,light)
        star(169+jitter,77,15*strength,32*strength,white)
    elif kind == 'arrows':
        poly([(0,98),(69,69),(152,79),(205,91),(155,112),(66,107)],dark)
        poly([(9,95),(84,77),(150,84),(193,91),(136,100),(52,101)],main)
        line([(4,93),(169,93)],light,6)
        line([(18,92),(183,92)],white,2)
        poly([(211,92),(173,75),(179,91),(172,109)],light)
        poly([(211,92),(182,85),(190,92)],white)
        poly([(29,92),(7,73),(31,79),(51,91),(25,110),(7,113)],light)
        arc(100,90,76,33,-2.9,-.1,main,3)
        poly([(116,56),(132,48),(124,60),(105,67)],light)
        poly([(90,119),(111,109),(103,122)],light)
    elif kind == 'ice':
        cx=117+jitter
        poly([(23,124),(51,108),(cx-48,47),(cx,10),(cx+48,47),
              (cx+57,99),(cx+79,124)],dark)
        poly([(cx-48,47),(cx,10),(cx+48,47),(cx+31,119),(cx-32,119)],main)
        poly([(cx,10),(cx+16,49),(cx+7,119),(cx-15,119),(cx-19,46)],light)
        poly([(cx,10),(cx+5,46),(cx-4,105),(cx-9,48)],white)
        poly([(cx+16,49),(cx+48,47),(cx+31,119),(cx+8,119)],light)
        line([(cx-48,47),(cx-19,46),(cx,10)],white,2)
        line([(cx-19,46),(cx-32,119)],light,2)
        d.ellipse((21,114,211,126),outline=light,width=3)
        line([(5,123),(49,120),(68,125),(184,123),(218,125)],main,2)
    elif kind == 'bullets':
        poly([(0,73),(106,69),(147,67),(183,76),(205,91),
              (184,105),(145,116),(72,105),(2,107),(58,93)],dark)
        poly([(0,84),(115,79),(159,73),(187,82),(205,91),
              (186,101),(151,108),(92,102),(4,100),(80,93)],main)
        poly([(111,81),(164,78),(188,83),(201,91),(182,98),(135,103)],light)
        poly([(111,88),(178,86),(197,91),(158,95)],white)
        line([(1,92),(116,91)],white,3)
        arc(161,91,35*strength,31*strength,-1.9,1.9,light,3)
    elif kind == 'lightning':
        bolt=[(124,4),(105,31),(122,29),(98,63),(122,53),(108,95),(132,78),(119,120)]
        line(bolt,dark,18); line(bolt,main,13); line(bolt,light,7);line(bolt,white,2)
        poly([(71,112),(151,37),(135,68),(93,119)],light)
        line([(76,111),(146,45)],white,3)
        line([(90,86),(115,108)],main,6)
        line([(101,96),(88,112)],main,5)
        line([(114,62),(65,47),(76,64),(43,79),(61,80)],main,3)
        line([(121,84),(154,69),(148,93),(187,107)],light,3)
        star(119,118,62*strength,13,white)
    elif kind == 'talismans':
        cx=115+jitter; cy=75
        d.ellipse((cx-59,cy-53,cx+59,cy+49),outline=main,width=6)
        d.ellipse((cx-53,cy-47,cx+53,cy+43),outline=light,width=2)
        pts=[(cx+48*math.cos(-math.pi/2+k*4*math.pi/5),cy+43*math.sin(-math.pi/2+k*4*math.pi/5)) for k in range(6)]
        line(pts,light,2)
        poly([(cx-15,39),(cx+19,39),(cx+16,108),(cx-18,108)],main)
        poly([(cx-11,43),(cx+14,43),(cx+11,103),(cx-14,103)],white)
        line([(cx,50),(cx-5,60),(cx+6,66),(cx-6,75),(cx+6,84),(cx-2,97)],main,3)
        line([(cx-8,69),(cx+10,69)],main,2)
        d.ellipse((19,115,213,125),outline=light,width=2)
    elif kind == 'reap':
        # A recognizable single scythe: sweeping blade and one long haft.
        outer=[(115+83*math.cos(a),63+54*math.sin(a)) for a in [-2.8+i*3.75/80 for i in range(81)]]
        inner=[(110+65*math.cos(a),68+39*math.sin(a)) for a in [.95-i*3.75/80 for i in range(81)]]
        poly(outer+inner,dark)
        arc(115,63,78,50,-2.7,.8,main,12)
        arc(115,63,76,49,-2.65,.65,light,4)
        arc(115,63,76,48,-2.3,.6,white,1)
        line([(124,32),(68,121)],dark,9)
        line([(124,32),(68,121)],main,5)
        line([(123,33),(71,119)],light,1)
    elif kind == 'holy':
        cx=123+jitter
        for side in [-1,1]:
            poly([(cx,75),(cx+side*27,36),(cx+side*87,16),
                  (cx+side*70,45),(cx+side*47,70),(cx+side*17,83)],main)
            poly([(cx,73),(cx+side*31,42),(cx+side*83,21),
                  (cx+side*60,44),(cx+side*29,73)],light)
            line([(cx+side*21,68),(cx+side*73,30)],white,3)
            line([(cx+side*30,65),(cx+side*59,54)],white,2)
        poly([(cx,115),(cx-9,68),(cx-6,39),(cx+6,39),(cx+9,68)],light)
        poly([(cx,115),(cx-2,43),(cx+2,43)],white)
        line([(cx-23,62),(cx+23,62)],main,7)
        line([(cx-20,61),(cx+20,61)],white,2)
        d.ellipse((cx-25,19,cx+25,30),outline=light,width=3)
        star(cx,95,23*strength,27*strength,white)
    elif kind == 'hellfire':
        poly([(0,124),(23,98),(38,62),(57,76),(69,26),
              (96,54),(117,10),(137,49),(172,35),(166,70),
              (205,97),(183,122)],dark)
        poly([(12,124),(47,91),(62,60),(81,79),(117,23),
              (126,67),(163,52),(155,87),(195,111),(180,123)],main)
        poly([(44,123),(72,92),(91,101),(117,58),(125,89),
              (150,79),(144,105),(173,122)],light)
        poly([(84,122),(113,93),(122,113),(144,124)],white)
        poly([(69,62),(74,42),(91,65)],light)
        poly([(129,54),(148,44),(140,68)],light)
    elif kind == 'dragon':
        poly([(0,124),(29,90),(15,74),(61,84),(80,57),(78,25),
              (102,44),(122,17),(142,42),(161,40),(208,66),
              (203,84),(176,87),(190,98),(160,106),(119,95),(76,124)],dark)
        poly([(11,122),(61,94),(91,65),(88,34),(105,51),(124,27),
              (137,51),(158,48),(202,68),(192,78),(151,76),
              (180,96),(151,99),(118,85),(69,121)],main)
        poly([(31,122),(95,85),(106,69),(138,62),(180,69),
              (146,78),(122,74),(111,97),(80,122)],light)
        poly([(138,54),(158,57),(147,63)],white)
        line([(154,78),(193,81)],white,2)
        poly([(178,81),(181,88),(186,81)],white)
        line([(6,116),(48,108),(82,105)],light,2)
    elif kind == 'rage':
        poly([(0,111),(148,21),(211,45),(166,57),(113,90),(68,111)],dark)
        poly([(5,103),(148,26),(204,45),(150,62),(68,100)],main)
        poly([(19,101),(149,32),(200,45),(143,55)],light)
        line([(24,97),(149,34),(194,44)],white,2)
        poly([(48,124),(100,117),(115,107),(145,115),(171,101),
              (194,117),(214,124)],dark)
        line([(65,124),(102,120),(115,112),(145,121),(171,107),(207,124)],light,3)
        star(147,60,19*strength,24*strength,white)

    # Sparse, role-colored chips support the one focal silhouette.
    for k in range(5):
        x=34+k*39+((phase*7+k*13)%11)
        y=19+((k*29+phase*11)%96)
        if phase < 6:
            d.rectangle((x,y,x+1,y+1),fill=light)
    if frame >= 9:
        # Authored breakup patterns; no opacity tween or bitmap transforms.
        for y in range(128):
            for x in range(224):
                if (x//4+y//4+frame) % (3 if frame==9 else 2) != 0:
                    im.putpixel((x,y),(0,0,0,0))
    return im.resize((1536,256),Image.Resampling.NEAREST)


def export_bindings():
    # Use the actual current app bindings, including the six expansion roles.
    bindings=json.loads((OLD/'bindings.json').read_text(encoding='utf-8-sig'))
    for key,binding in bindings.items():
        source=binding['source_motion']; role=binding['effect_type']
        meta=json.loads((ROOT/f'mobile/assets/images/playable_stage/{source}_skill.json').read_text(encoding='utf-8-sig'))
        releases=sorted(set(e['tick'] for e in meta['events'] if e['event']==binding['source_event']))
        assert releases,(source,binding['source_event'])
        folder=OUT/'playback'/key
        (folder/'frames_24fps').mkdir(parents=True,exist_ok=True)
        timeline=[]; holds=[]
        for tick,row in enumerate(meta['timeline']):
            index=legacy.frame_index(tick,len(meta['timeline']),releases)
            original=OUT/role/'keyframes'/f'{role}_{index:03}.png'
            target=folder/'frames_24fps'/f'{tick:03}.png'
            shutil.copy2(original,target)
            assert Image.open(target).convert('RGBA').tobytes()==Image.open(original).convert('RGBA').tobytes()
            timeline.append({'tick':tick,'keyframe':index,'root_offset_px':row['root_offset_px'],'file':f'frames_24fps/{tick:03}.png'})
            if holds and holds[-1]['keyframe']==index: holds[-1]['ticks']+=1
            else: holds.append({'keyframe':index,'ticks':1})
        binding.update(timeline=timeline,holds=holds,release_ticks=releases,events=meta['events'],duration_seconds=len(timeline)/24,rgba_matches=True)
        (folder/'animation.json').write_text(json.dumps(binding,ensure_ascii=False,indent=2),encoding='utf-8')
    (ASSETS/'bindings.json').write_text(json.dumps(bindings,ensure_ascii=False),encoding='utf-8')
    return len(bindings)


def main():
    legacy.OUT=OUT; legacy.ASSETS=ASSETS
    legacy.author=author; legacy.export_bindings=export_bindings
    legacy.main()
    for directory in [OUT,ASSETS]:
        manifest=json.loads((directory/'manifest.json').read_text(encoding='utf-8'))
        for role,data in manifest.items():
            data.update(version=2,composition='single',design=DESIGNS[role])
        (directory/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
    charge_checks=[]
    for role in DESIGNS:
        for index in range(3):
            old=Image.open(OLD/f'{role}_{index:03}.png').convert('RGBA')
            new=Image.open(ASSETS/f'{role}_{index:03}.png').convert('RGBA')
            assert old.tobytes()==new.tobytes()
            charge_checks.append({'role':role,'keyframe':index,'rgba_identical':True})
    (OUT/'charge_verification.json').write_text(json.dumps(charge_checks,indent=2),encoding='utf-8')
    html=(OUT/'index.html').read_text(encoding='utf-8').replace('スキル発動時に画面右端まで表示。','発動後は各職業に合う大きな一つのエフェクト。').replace('16役職 · スキルエフェクト原画','16役職 · 単一スキルエフェクト v002')
    # Crop the large transparent margins only in the review UI; originals stay intact.
    html=html.replace('img{width:100%;image-rendering:pixelated}', 'article{overflow:hidden}img{width:350%;max-width:none;image-rendering:pixelated}')
    (OUT/'index.html').write_text(html,encoding='utf-8')
    (OUT/'designs.json').write_text(json.dumps(DESIGNS,ensure_ascii=False,indent=2),encoding='utf-8')
    render_reviews()


def render_reviews():
    font=ImageFont.truetype('C:/Windows/Fonts/meiryo.ttc',18)
    overview=Image.new('RGB',(896,2240),'#172b31')
    for ri,(role,label,skill,_,_) in enumerate(legacy.ROLES):
        originals=[Image.open(OUT/role/'keyframes'/f'{role}_{i:03}.png').convert('RGBA') for i in range(12)]
        sheet=Image.new('RGBA',(448*4,280*3),'#172b31')
        for i,original in enumerate(originals):
            x=(i%4)*448; y=(i//4)*280
            sheet.alpha_composite(original.crop((0,0,448,256)),(x,y+24))
            ImageDraw.Draw(sheet).text((x+8,y),f'{i:02}',font=font,fill='white')
        sheet.convert('RGB').save(OUT/role/'keyframes.png')
        x=(ri%2)*448; y=(ri//2)*280
        overview.paste(sheet.crop((448,0,896,280)).convert('RGB'),(x,y))
        bg=Image.new('RGBA',(448,256),'#172b31')
        bg.alpha_composite(originals[4].crop((0,0,448,256)))
        overview.paste(bg.convert('RGB'),(x,y+24))
        ImageDraw.Draw(overview).text((x+8,y),label+' / '+skill,font=font,fill='white')
        previews=[]
        for original in originals:
            bg=Image.new('RGBA',(448,256),'#172b31')
            bg.alpha_composite(original.crop((0,0,448,256)))
            previews.append(bg.convert('RGB'))
        previews[0].save(OUT/role/'preview.gif',save_all=True,append_images=previews[1:],duration=[round(h*1000/24) for h in legacy.HOLDS],loop=0,disposal=2)
    overview.save(OUT/'overview.png')


if __name__=='__main__':
    main()
