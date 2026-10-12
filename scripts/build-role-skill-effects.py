"""Author independent pixel effect originals; never warp/interpolate source PNGs."""
from pathlib import Path
import json, math, hashlib, shutil
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'art/role_skill_effects_v001'
ASSETS = ROOT / 'mobile/assets/images/role_skill_effects'
ROLES = [
 ('warrior','剣士','蓄力斬撃',('#173877','#248ce8','#79ddff','#eeffff'),'crescent'),
 ('boxer','拳闘士','旋風蹴り',('#145754','#30b79b','#96efd2','#f2fff1'),'wind'),
 ('samurai','侍','連続居合',('#542b65','#b756a0','#ffb8df','#fff2fa'),'cuts'),
 ('guardian','重騎士','蓄力薙ぎ払い',('#674125','#b88036','#f1c46b','#fff1c2'),'earth'),
 ('ninja','忍者','瞬身突き',('#302854','#6953a3','#aaa3eb','#eee7ff'),'shadow'),
 ('assassin','アサシン','蓄力クリティカル',('#531b3c','#b42765','#f16ba2','#ffe0ef'),'dagger'),
 ('ranger','弓使い','三連射',('#17493f','#38a369','#97df89','#efffd4'),'arrows'),
 ('mage','魔法使い','大氷結',('#243f87','#407acc','#8ee8ff','#efffff'),'ice'),
 ('gunner','ガンナー','早撃ち',('#713b22','#cc7429','#ffd079','#fff4cf'),'bullets'),
 ('spellblade','魔剣士','雷剣・落雷',('#3a276b','#8761df','#d3baff','#fcf4ff'),'lightning'),
 ('onmyoji','陰陽師','五行封陣',('#3c295b','#b03e65','#f0c96c','#fff4d7'),'talismans'),
 ('reaper','鎌使い','冥月刈り',('#26264c','#574796','#9d91dc','#d1fff1'),'reap'),
 ('angel','天使','聖光の翼',('#79662d','#d7b961','#fff2b7','#ffffff'),'holy'),
 ('devil','悪魔','獄炎の波',('#3b193e','#8b285d','#ee547c','#ffd5b2'),'hellfire'),
 ('dragon_knight','ドラゴンナイト','竜炎突撃',('#69332b','#d4502a','#ff9b38','#fff0a7'),'dragon'),
 ('berserker','バーサーカー','狂戦裂破',('#631c28','#bb3438','#f37b53','#ffe4b0'),'rage'),
]
W,H = 768,128 # completed originals use the established doubled logical grid
HOLDS = [3,3,3,2,2,2,2,2,3,4,4,6]

def frame_index(tick,total,events):
    if tick>=total:return 11
    events=sorted(set(events)) or [int(total*.55)]
    first=events[0]
    if tick<first:return min(2,tick*3//max(1,first))
    if len(events)>=3:
        for i in range(2):
            if tick<events[i+1]:return 3+i*2+min(1,(tick-events[i])*2//max(1,events[i+1]-events[i]))
        return min(11,7+(tick-events[2])*5//max(1,total-events[2]))
    return min(11,3+(tick-first)*9//max(1,total-first))

def export_bindings():
    events_by_role=[('wave_release','skill_release'),('kick_hit','kick_hit'),('slash_1','flurry_hit'),('sweep_hit','skill_release'),('dagger_hit','dagger_hit'),('critical_impact','skill_release'),('arrow_release','arrow_release'),('ice_release','ice_release'),('bullet_release','bullet_release'),('lightning_strike','lightning_strike')]
    bindings={}
    for ri,(role,*_) in enumerate(ROLES):
        for female in [False,True]:
            source=f'character_{ri+1:02}'+('_female' if female else '') if ri<10 else 'character_01'
            meta=json.loads((ROOT/f'mobile/assets/images/playable_stage/{source}_skill.json').read_text(encoding='utf-8-sig'))
            event=events_by_role[ri][int(female)] if ri<10 else 'wave_release'
            releases=[e['tick'] for e in meta['events'] if e['event']==event]
            assert releases,(source,event)
            total=len(meta['timeline']);key=role+('_female' if female else '_male')
            folder=OUT/'playback'/key;(folder/'frames_24fps').mkdir(parents=True,exist_ok=True)
            timeline=[];holds=[]
            for tick in range(total):
                index=frame_index(tick,total,releases)
                path=folder/'frames_24fps'/f'{tick:03}.png'
                original=OUT/role/'keyframes'/f'{role}_{index:03}.png'
                shutil.copy2(original,path)
                assert Image.open(path).convert('RGBA').tobytes()==Image.open(original).convert('RGBA').tobytes()
                timeline.append({'tick':tick,'keyframe':index,'root_offset_px':meta['timeline'][tick]['root_offset_px'],'file':f'frames_24fps/{tick:03}.png'})
                if holds and holds[-1]['keyframe']==index:holds[-1]['ticks']+=1
                else:holds.append({'keyframe':index,'ticks':1})
            binding={'effect_type':role,'source_motion':source,'source_event':event,'fps':24,'duration_seconds':total/24,'release_ticks':releases,'holds':holds,'timeline':timeline,'events':meta['events'],'rgba_matches':True,'coordinate_space':'world_px','interpolation':'none'}
            (folder/'animation.json').write_text(json.dumps(binding,ensure_ascii=False,indent=2),encoding='utf-8')
            bindings[key]=binding
    (ASSETS/'bindings.json').write_text(json.dumps(bindings,ensure_ascii=False),encoding='utf-8')
    return len(bindings)

def author(kind, frame, palette):
    im = Image.new('RGBA',(W,H)); d = ImageDraw.Draw(im)
    dark,main,light,white = palette
    def poly(points,c): d.polygon([(round(x),round(y)) for x,y in points],fill=c)
    def line(points,c,width=1): d.line([(round(x),round(y)) for x,y in points],fill=c,width=width)
    def star(x,y,r,c):
        poly([(x-r,y),(x-2,y-2),(x,y-r),(x+2,y-2),(x+r,y),(x+2,y+2),(x,y+r),(x-2,y+2)],c)
    def crescent(x,y,r,c,reverse=False):
        sign=-1 if reverse else 1
        outer=[(x+sign*r*math.cos(a),y+r*math.sin(a)) for a in [(-1.5+i*3/24) for i in range(25)]]
        inner=[(x+sign*(r*.78*math.cos(a)-r*.12),y+r*.86*math.sin(a)) for a in [(1.5-i*3/24) for i in range(25)]]
        poly(outer+inner,c)
    if frame == 11: return im.resize((W*2,H*2),Image.Resampling.NEAREST)
    if frame < 3:
        r=[9,16,25][frame]
        crescent(8,83,r,main); crescent(10,83,r-4,light)
        for j in range(5):
            a=j*1.3+frame*.4
            star(18+math.cos(a)*r,83+math.sin(a)*r,2+frame,white)
        if kind in ('ice','lightning','holy','talismans'): star(20,83,5+frame*2,white)
        return im.resize((W*2,H*2),Image.Resampling.NEAREST)
    power=[0,0,0,0.7,1,0.9,1,0.85,0.65,0.4,0.2][frame]
    active=frame<9
    # Every attack original is drawn afresh over the whole range. No source
    # bitmap translation, rotation, tweening, alpha fades, or resampling.
    for j,x in enumerate(range(0,W,72)):
        y=78+((j*7+frame*3)%13)-6
        if kind=='crescent':
            crescent(x+23,y,round(37*power),dark)
            crescent(x+25,y,round(34*power),main)
            crescent(x+29,y,round(29*power),light)
            crescent(x+31,y,round(25*power),white)
            line([(x,y+21),(x+48,y+15),(x+68,y+10)],main,2)
        elif kind=='wind':
            for k in range(3):
                yy=y+(k-1)*22
                points=[(x+t,yy+math.sin((t+j*8+frame*9)/16)*8*power) for t in range(0,85,3)]
                line(points,dark,7);line(points,main,5);line(points,light,2)
            crescent(x+32,y,30*power,white)
        elif kind in ('cuts','rage'):
            for k in range(3 if kind=='cuts' else 2):
                yy=y+(k-1)*20
                poly([(x-10,yy+17*power),(x+80,yy-25*power),(x+38,yy+2),(x,yy+23*power)],dark)
                poly([(x,yy+15*power),(x+80,yy-25*power),(x+34,yy+3)],main)
                line([(x,yy+15*power),(x+80,yy-25*power)],light,2)
            if kind=='rage':
                poly([(x+4,123),(x+20,102),(x+25,114),(x+40,98),(x+50,123)],main)
                star(x+48,y,8*power,white)
        elif kind=='earth':
            crescent(x+29,107,34*power,main)
            poly([(x,124),(x+12,105),(x+25,115),(x+31,94),(x+43,104),(x+58,122)],dark)
            poly([(x+12,120),(x+20,109),(x+28,120),(x+32,101),(x+40,108),(x+49,121)],light)
            line([(x,117),(x+18,113),(x+28,116),(x+45,111),(x+71,117)],white,2)
        elif kind=='shadow':
            poly([(x,y-15),(x+64,y-3),(x+30,y+2),(x+67,y+8),(x,y+16),(x+14,y)],dark)
            poly([(x+8,y-9),(x+69,y),(x+21,y+6),(x+44,y)],main)
            line([(x+12,y),(x+68,y)],light,2)
            star(x+48,y,8*power,white)
        elif kind=='dagger':
            poly([(x,y-10),(x+65,y),(x,y+10),(x+15,y)],main)
            line([(x+4,y),(x+65,y)],white,2)
            poly([(x+35,y-27*power),(x+41,y),(x+33,y+27*power),(x+26,y)],light)
            star(x+36,y,7,white)
        elif kind in ('arrows','bullets'):
            for k in range(min(3, 1+(frame-3)//2) if active else 3):
                yy=60+k*17; xx=x+((frame*9+k*11)%28)
                line([(xx-27,yy),(xx+31,yy)],main,3)
                line([(xx-8,yy),(xx+31,yy)],white)
                if kind=='arrows':
                    poly([(xx+43,yy),(xx+29,yy-6),(xx+33,yy),(xx+29,yy+6)],light)
                    line([(xx-10,yy-5),(xx-2,yy),(xx-10,yy+5)],light,2)
                else:
                    poly([(xx+38,yy),(xx+32,yy-3),(xx+24,yy-3),(xx+24,yy+3),(xx+32,yy+3)],light)
            if kind=='bullets' and x==0: star(14,77,23*power,white)
        elif kind=='ice':
            h=round((35+(j%3)*16)*power)
            poly([(x,124),(x+8,124-h),(x+19,109-h),(x+31,124-h),(x+43,124)],dark)
            poly([(x+8,121),(x+19,110-h),(x+30,121-h),(x+34,121)],main)
            poly([(x+19,110-h),(x+26,119-h),(x+20,120),(x+13,118)],light)
            line([(x+19,110-h),(x+20,117)],white,2)
            star(x+54,61+((j+frame)%3)*9,4,light)
        elif kind=='lightning':
            bolt=[(x,77),(x+20,63),(x+13,86),(x+37,70),(x+29,92),(x+73,77)]
            line(bolt,dark,9);line(bolt,main,6);line(bolt,white,2)
            if (j+frame)%2==0:
                bolt=[(x+41,10),(x+27,41),(x+48,34),(x+31,71),(x+48,63),(x+29,115)]
                line(bolt,main,7);line(bolt,light,4);line(bolt,white,1)
                star(x+29,115,9,white)
        elif kind=='talismans':
            xx=x+25; yy=51+(j+frame)%3*12
            poly([(xx-10,yy-15),(xx+11,yy-12),(xx+8,yy+17),(xx-12,yy+13)],main)
            poly([(xx-8,yy-12),(xx+8,yy-9),(xx+5,yy+13),(xx-9,yy+10)],white)
            for k in range(4): line([(xx-5,yy-7+k*5),(xx+4,yy-6+k*5)],main,1)
            d.ellipse((x,94,x+57,121),outline=light,width=2)
            star(x+28,107,12,light)
        elif kind=='reap':
            crescent(x+22,75,43*power,dark,True)
            crescent(x+24,75,39*power,main,True)
            crescent(x+25,75,34*power,light,True)
            d.rectangle((x+45,74,x+57,86),fill=main)
            d.rectangle((x+47,77,x+49,80),fill=white)
            d.rectangle((x+53,77,x+55,80),fill=white)
            line([(x+48,88),(x+56,88)],light,2)
        elif kind=='holy':
            line([(x,82),(x+73,82)],main,13);line([(x,82),(x+73,82)],light,7);line([(x,82),(x+73,82)],white,2)
            poly([(x+16,43),(x+37,55),(x+39,66),(x+11,57)],light)
            line([(x+13,54),(x+37,60)],white,2)
            star(x+53,80,16*power,white)
            if active: d.ellipse((x+19,23,x+40,31),outline=light,width=2)
        elif kind in ('hellfire','dragon'):
            for k in range(3):
                xx=x+k*25; tip=35+((j*11+k*17+frame*7)%35)
                poly([(xx-12,112),(xx-7,78),(xx+5,tip),(xx+10,72),(xx+22,63),(xx+19,93),(xx+29,116)],dark)
                poly([(xx-5,110),(xx+6,tip+12),(xx+10,91),(xx+19,79),(xx+15,113)],main)
                poly([(xx+2,111),(xx+9,87),(xx+11,99),(xx+16,110)],light)
            if kind=='dragon' and j%3==1:
                poly([(x+6,70),(x+19,42),(x+24,54),(x+36,49),(x+62,66),(x+45,79),(x+25,83)],main)
                poly([(x+31,62),(x+58,68),(x+43,74)],light)
                d.rectangle((x+35,58,x+40,60),fill=white)
        # Dissipation uses separately drawn sparse chips, not opacity changes.
        if frame>=9:
            for yy in range(H):
                for xx in range(max(0,x), min(W,x+72)):
                    if (xx//4+yy//4+frame)% (3 if frame==9 else 2)!=0: im.putpixel((xx,yy),(0,0,0,0))
        for k in range(3 if active else 1):
            star(x+((j*13+k*23+frame*7)%69),38+(k*29+j*5+frame*3)%73,2,light)
    return im.resize((W*2,H*2),Image.Resampling.NEAREST)

def main():
    OUT.mkdir(parents=True,exist_ok=True);ASSETS.mkdir(parents=True,exist_ok=True)
    font=ImageFont.truetype('C:/Windows/Fonts/meiryo.ttc',18)
    overview=Image.new('RGB',(1536,16*150//2),'#172b31'); od=ImageDraw.Draw(overview)
    manifest={}; verified=[]
    for ri,(role,label,skill,palette,kind) in enumerate(ROLES):
        folder=OUT/role;(folder/'keyframes').mkdir(parents=True,exist_ok=True);(folder/'frames_24fps').mkdir(exist_ok=True)
        frames=[author(kind,i,palette) for i in range(12)]
        timeline=[]; hashes=[]
        for i,im in enumerate(frames):
            name=f'{role}_{i:03}.png'; im.save(folder/'keyframes'/name);shutil.copy2(folder/'keyframes'/name,ASSETS/name)
            hashes.append(hashlib.sha256(im.tobytes()).hexdigest())
            for _ in range(HOLDS[i]):
                tick=len(timeline);target=folder/'frames_24fps'/f'{tick:03}.png'
                shutil.copy2(folder/'keyframes'/name,target)
                assert Image.open(target).convert('RGBA').tobytes()==im.tobytes()
                timeline.append({'tick':tick,'keyframe':i,'file':f'frames_24fps/{tick:03}.png','root_offset_px':[0,0]})
        meta={'role':label,'skill':skill,'kind':kind,'palette':palette,'fps':24,'size':[W*2,H*2],'anchor_px':[0,H*2], 'interpolation':'none','loop':False,
              'keyframes':[{'index':i,'file':f'keyframes/{role}_{i:03}.png'} for i in range(12)],
              'holds':[{'keyframe':i,'ticks':h} for i,h in enumerate(HOLDS)],'timeline':timeline,
              'events':[{'tick':9,'event':'release','world_offset_px':[0,0]},{'tick':sum(HOLDS)-6,'event':'clear','world_offset_px':[0,0]}], 'rgba_sha256':hashes}
        (folder/'animation.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2),encoding='utf-8')
        sheet=Image.new('RGBA',(1536,384),'#172b31')
        for i,im in enumerate(frames):sheet.alpha_composite(im.resize((384,64),Image.Resampling.NEAREST),((i%4)*384,(i//4)*128+32))
        sheet.convert('RGB').save(folder/'keyframes.png')
        previews=[]
        for im in frames:
            bg=Image.new('RGBA',im.size,'#172b31');bg.alpha_composite(im);previews.append(bg.convert('RGB').resize((768,128),Image.Resampling.NEAREST))
        previews[0].save(folder/'preview.gif',save_all=True,append_images=previews[1:],duration=[round(h*1000/24) for h in HOLDS],loop=0,disposal=2)
        x=(ri%2)*768;y=(ri//2)*150
        overview.paste(previews[4],(x,y+22));od.text((x+10,y),label+' / '+skill,font=font,fill='white')
        manifest[role]={k:meta[k] for k in ['role','skill','kind','palette','fps','size','anchor_px','holds','interpolation']}
        verified.append({'role':role,'originals':12,'ticks':len(timeline),'rgba_matches':True,'transparent_end':frames[-1].getbbox() is None})
    overview.save(OUT/'overview.png')
    (ASSETS/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
    (OUT/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
    (OUT/'verification.json').write_text(json.dumps(verified,indent=2),encoding='utf-8')
    # Self-contained preview: embed exact original PNGs so file:// also works.
    import base64
    cards=[]
    for role,label,skill,_,_ in ROLES:
        urls=['data:image/png;base64,'+base64.b64encode((OUT/role/'keyframes'/f'{role}_{i:03}.png').read_bytes()).decode() for i in range(12)]
        cards.append({'role':label,'skill':skill,'frames':urls})
    html='''<!doctype html><meta charset="utf-8"><title>FocusQuest · 16役職 スキルエフェクト</title><style>body{background:#11252d;color:#f6eddb;font:16px sans-serif;margin:24px}main{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:18px}article{background:#1a3038;padding:16px;border:1px solid #52626a}img{width:100%;image-rendering:pixelated}button{padding:8px 20px}h1{font-size:24px}@media(max-width:800px){main{grid-template-columns:1fr}}</style><h1>16役職 · スキルエフェクト原画</h1><p>24fps・原画保持。左端がキャラクター位置。スキル発動時に画面右端まで表示。</p><button id="toggle">一時停止</button><main></main><script>const cards=CARDS,holds=HOLDS;let tick=0,playing=true;const total=holds.reduce((a,b)=>a+b,0);for(const c of cards){const a=document.createElement('article');const h=document.createElement('h2');h.textContent=c.role+' / '+c.skill;const img=new Image();img.src=c.frames[0];a.append(h,img);document.querySelector('main').append(a);c.img=img;}document.querySelector('button').onclick=()=>{playing=!playing;document.querySelector('button').textContent=playing?'一時停止':'再生'};setInterval(()=>{if(!playing)return;let t=tick%total,i=0;while(t>=holds[i])t-=holds[i++];for(const c of cards)c.img.src=c.frames[i];tick++;},1000/24);</script>'''
    (OUT/'index.html').write_text(html.replace('CARDS',json.dumps(cards,ensure_ascii=False)).replace('HOLDS',json.dumps(HOLDS)),encoding='utf-8')
    print(json.dumps({'roles':len(verified),'originals':len(verified)*12,'ticks':sum(HOLDS),'bindings':export_bindings(),'verification':'all RGBA identical'},ensure_ascii=False))

if __name__=='__main__':main()
