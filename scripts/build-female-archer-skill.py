from pathlib import Path
import importlib.util, json, shutil, hashlib
import numpy as np
from PIL import Image, ImageDraw
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'mobile/assets/images/characters/female_archer/skill'
REV=ROOT/'artifacts/female_archer_skill_review'
TIMES=['17_27_17','17_27_32','17_27_38','17_27_42','17_27_48','17_27_53','17_28_17','17_28_27','17_28_31']
spec=importlib.util.spec_from_file_location('old',ROOT/'scripts/build-female-archer-attack.py'); old=importlib.util.module_from_spec(spec); spec.loader.exec_module(old)
# Native-source pelvis landmarks. No character resizing or pose deformation.
HIP=[[252,686,1102,1540,1980],[246,678,1100,1530,1990],[232,667,1090,1520,1950],[230,670,1090,1520,1930],[235,675,1100,1530,1980],[230,660,1100,1535,1970],[220,665,1095,1530,1980],[235,685,1100,1550,1990],[240,675,1105,1530,1980]]
OMIT={13:'引き絞りの類似姿勢。12→14で段階を保持',15:'照準の類似姿勢。14→16で強い引きを保持',17:'照準保持の重複候補。16→18を採用',20:'飛ぶ矢が右端で切れている発射後姿勢。19→21で一射と反動を保持',33:'走行復帰後の重複した脚運び',35:'30と類似の走行姿勢',37:'36と類似の走行姿勢',40:'39と類似の走行姿勢',42:'終盤の冗長な走行姿勢',43:'終盤の冗長な走行姿勢'}
IDS=[i for i in range(1,46) if i not in OMIT]
# Pose 10 is already fully drawn; pose 11 is a shallower draw.
# Advance 9 -> 11 -> 10 -> 12 instead of briefly relaxing the bow.
IDS[IDS.index(10):IDS.index(12)]=[11,10]
# End at 45; run loop begins with 41, the next complementary stride.
RUN=[41,44,45,1,2,3,4,5]
def phase(i):
    if i<=3:return 'run'
    if i<=5:return 'prepare'
    if i<=9:return 'nock'
    if i<=14:return 'draw'
    if i<=18:return 'aim'
    if i==19:return 'release'
    if i<=22:return 'recoil'
    if i<=26:return 'recover'
    if i<=31:return 'accelerate'
    return 'run'
RATIOS=dict(run=1,prepare=.8,nock=.55,draw=.35,aim=.3,release=.3,recoil=.35,recover=.55,accelerate=.85)
def main():
    OUT.mkdir(parents=True,exist_ok=True); REV.mkdir(parents=True,exist_ok=True)
    for name in ['candidates','isolated','24fps']: (REV/name).mkdir(exist_ok=True)
    actors={}; diag=[]; hashes=[]
    for s,t in enumerate(TIMES):
        src=Path('C:/Users/eido0/Downloads')/f'ChatGPT 画像 2026年10月10日 {t}.png'
        target=REV/f'source_{s+1:02d}.png'; shutil.copy2(src,target)
        im=Image.open(src).convert('RGBA'); a=np.array(im); h,w=a.shape[:2]
        hashes.append(dict(name=src.name,sha256=hashlib.sha256(src.read_bytes()).hexdigest(),size=[w,h],alphaRange=[int(a[:,:,3].min()),int(a[:,:,3].max())]))
        bounds=[np.zeros(h,dtype=int)]+old.seams(a)+[np.full(h,w)]
        xx=np.arange(w)[None,:]
        for slot in range(5):
            i=s*5+slot+1; rect=[round(slot*w/5),0,round((slot+1)*w/5),h]
            im.crop(rect).save(REV/'candidates'/f'raw_{i:02d}.png')
            mask=(xx>=bounds[slot][:,None])&(xx<bounds[slot+1][:,None]); pixels=a.copy();pixels[~mask]=0
            full=Image.fromarray(pixels);box=full.getbbox(); actor=full.crop(box)
            foot=old.extractor._foot_y(pixels[:,:,3]>80);hip=HIP[s][slot]
            actors[i]=(actor,hip-box[0],foot-box[1]);actor.save(REV/'isolated'/f'pose_{i:02d}.png')
            diag.append(dict(id=i,sheet=s+1,slot=slot+1,rawRect=rect,bbox=box,hipX=hip,footY=foot,phase=phase(i),selected=i in IDS,reason=OMIT.get(i,'採用: '+phase(i))))
    half=max(max(x,im.width-x) for im,x,y in actors.values())+8
    top=max(y for im,x,y in actors.values())+8;bottom=max(im.height-y for im,x,y in actors.values())+8
    width,height=2*half,top+bottom; frames={}
    for i,(im,x,y) in actors.items():
        canvas=Image.new('RGBA',(width,height));canvas.paste(im,(half-x,top-y));frames[i]=canvas
        canvas.save(REV/f'frame_{i:02d}.png')
    atlas_ids=sorted(set(IDS+RUN)); cols=min(4,4096//width); rows=min(4,4096//height);cap=cols*rows
    pages=[]
    for start in range(0,len(atlas_ids),cap):
        page=Image.new('RGBA',(width*cols,height*rows))
        for j,i in enumerate(atlas_ids[start:start+cap]):page.paste(frames[i],((j%cols)*width,(j//cols)*height))
        name=f'skill_{len(pages)+1:02d}.png';page.save(OUT/name);pages.append(name)
        for j,i in enumerate(atlas_ids[start:start+cap]):
            assert page.crop(((j%cols)*width,(j//cols)*height,(j%cols+1)*width,(j//cols+1)*height)).tobytes()==frames[i].tobytes()
    holds=[3 if phase(i)=='aim' else 2 if phase(i) in ['nock','draw','recoil','recover'] else 1 for i in IDS]
    release_tick=sum(holds[:IDS.index(19)]); timeline=[];tick=0;distance=0
    for i,hold in zip(IDS,holds):
        for _ in range(hold):
            path=REV/'24fps'/f'tick_{tick:03d}.png';frames[i].save(path)
            assert Image.open(path).convert('RGBA').tobytes()==frames[i].tobytes()
            timeline.append(dict(tick=tick,frame=i,worldPosition=[round(distance,6),0],phase=phase(i),events=['release_arrow'] if tick==release_tick else []))
            tick+=1;distance+=120*RATIOS[phase(i)]/24
    data=dict(sourceFrameCount=45,skillFrames=IDS,removedFrames=OMIT,holdTicks=holds,phases=[phase(i) for i in IDS],releaseFrame=19,releaseTick=release_tick,releaseTime=release_tick/24,duration=tick/24,runFrames=RUN,runHoldTicks=[2]*len(RUN),atlasFrames=atlas_ids,columns=cols,pageCapacity=cap,atlasPages=pages,width=width,height=height,anchorX=half/width,anchorY=top/height,muzzleX=half+130,muzzleY=top-330,phaseSpeedRatios=RATIOS,events=[dict(type='release_arrow',tick=release_tick,frame=19,muzzleOffset=[130,-330])],sources=hashes)
    (OUT/'skill.json').write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')
    (REV/'timeline_24fps.json').write_text(json.dumps(timeline,indent=2),encoding='utf-8')
    (REV/'extraction.json').write_text(json.dumps(diag,ensure_ascii=False,indent=2),encoding='utf-8')
    board=Image.new('RGB',(1250,9*350),'#344052');draw=ImageDraw.Draw(board)
    for i in range(1,46):
        im=frames[i].copy();im.thumbnail((250,310),Image.Resampling.NEAREST);x=(i-1)%5*250;y=(i-1)//5*350
        board.paste(im,(x,y+30),im);draw.text((x+5,y+5),f'{i:02d} {phase(i)} '+('KEEP' if i in IDS else 'OMIT'),fill='white' if i in IDS else '#ff8989')
    board.save(REV/'contact_sheet.png')
    previews=[]
    for i in IDS+RUN*2:
        im=frames[i].copy();im.thumbnail((620,650),Image.Resampling.NEAREST); bg=Image.new('RGB',im.size,'#344052');bg.paste(im,(0,0),im);previews.append(bg)
    previews[0].save(REV/'skill_preview.gif',save_all=True,append_images=previews[1:],duration=[round(t/24*1000) for t in holds]+[83]*(len(RUN)*2),loop=0)
    lines=['# 全45候補の目視選別','', '|番号|元画像/コマ|採否|区間・理由|保持tick (24Hz)|','|---|---|---|---|---|']
    for d in diag:
        i=d['id'];lines.append(f"|{i}|{d['sheet']}/{d['slot']}|{'採用' if i in IDS else '除外'}|{d['reason']}|{holds[IDS.index(i)] if i in IDS else '—'}|")
    (REV/'frame_review.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
    (REV/'verification.json').write_text(json.dumps(dict(candidates=45,selected=len(IDS),ticks=tick,rgbaTickEquality=True,atlasEquality=True,sourcePixelsNotResampled=True,duration=tick/24,releaseTime=release_tick/24),indent=2),encoding='utf-8')
    print(json.dumps(dict(selected=IDS,width=width,height=height,ticks=tick,releaseTick=release_tick)))
if __name__=='__main__':main()
