from pathlib import Path
from PIL import Image, ImageDraw
import json, zipfile, hashlib
import renderer as r

out=r.OUT
fps=24
frame_count=24
styles=['illustration','pixel']
frames={s:[Image.open(out/s/'runtime/run'/f'character_01_{s}_run_{f:04}.png').convert('RGBA') for f in range(frame_count)] for s in styles}
metadata={'fps':fps,'frame_count':frame_count,'cycle_seconds':1,'direction':'right','root_motion':'none','references':['reference/run_poses.png'],'styles':{}}
for style in styles:
    sprite=Image.new('RGBA',(256*6,256*4))
    for f,im in enumerate(frames[style]):
        sprite.paste(im,((f%6)*256,(f//6)*256))
    sprite.save(out/style/'runtime/run_spritesheet.png')
    metadata['styles'][style]={'sheet':f'{style}/runtime/run_spritesheet.png','columns':6,'rows':4,'frame_size':[256,256],'pivot':[128,224],'frame_time_seconds':1/24}

# Show actual travel separately from the reusable in-place sprites.
# 226.286 source px/sec matches the support-foot backward velocity.
travel=[]
for f in range(72):
    im=Image.new('RGB',(960,560),'#dbe4ed')
    d=ImageDraw.Draw(im)
    rootx=165+(66/(7/24))*f/24
    for row,style in enumerate(styles):
        ground=250+row*270
        d.line((20,ground,940,ground),fill='#98aabf',width=2)
        for marker in range(40,941,80):d.line((marker,ground,marker,ground+6),fill='#98aabf')
        d.text((24,18+row*270),('2D ILLUSTRATION' if row==0 else 'PIXEL ART')+' / RIGHT / 24 FPS',fill='#253e55')
        fr=frames[style][f%24]
        im.paste(fr,(round(rootx)-128,ground-224),fr)
    travel.append(im)
timing=[(round((f+1)*100/24)-round(f*100/24))*10 for f in range(72)]
travel[0].save(out/'run_right_travel.gif',save_all=True,append_images=travel[1:],duration=timing,loop=0,disposal=2)
travel[0].save(out/'run_right_travel.png',save_all=True,append_images=travel[1:],duration=[round((f+1)*1000/24)-round(f*1000/24) for f in range(72)],loop=0,disposal=0,blend=0)
assert Image.open(out/'run_right_travel.gif').n_frames==72

html='''<!doctype html><html lang="ja"><meta charset="utf-8"><title>右向き走行 / 24fps</title>
<style>body{margin:0;background:#edf2f7;color:#20364c;font:16px system-ui;padding:28px}h1{font-size:24px}section{display:flex;flex-wrap:wrap;gap:20px}article{background:white;border-radius:16px;padding:16px}canvas{background:repeating-conic-gradient(#edf2f7 0% 25%,#fff 0% 50%) 50%/24px 24px;max-width:100%;width:384px;height:384px}button,input{margin:8px}#travel{width:960px;height:560px;max-width:100%}.meta{color:#61768b}</style>
<h1>右向き走行モーション</h1><p class="meta">24fps · 24フレーム · 1秒ループ · 透過PNG · 2D / ドット絵</p>
<button id="toggle">一時停止</button><button id="step">1フレーム進める</button><label>フレーム <input id="seek" type="range" min="0" max="23" value="0"></label><span id="counter"></span>
<section><article><h2>2Dイラスト</h2><canvas id="illustration" width="256" height="256"></canvas></article><article><h2>ドット絵</h2><canvas id="pixel" width="256" height="256"></canvas></article></section>
<h2>右へ移動するプレビュー</h2><canvas id="travel" width="960" height="560"></canvas>
<p class="meta">連番の正確な表示時間は各フレーム1/24秒。GIFでは40/50msを配分して周期を合わせています。移動表示は3秒で開始位置へ戻ります。</p>
<script>
const styles=['illustration','pixel'],sheets={},ctx={};let playing=true,frame=0,travelFrame=0,last=performance.now(),acc=0;
const ready=Promise.all(styles.map(s=>new Promise(resolve=>{ctx[s]=document.getElementById(s).getContext('2d');ctx[s].imageSmoothingEnabled=s!=='pixel';const img=new Image();img.onload=()=>{sheets[s]=img;resolve()};img.src=s+'/runtime/run_spritesheet.png'})));
const travel=document.getElementById('travel').getContext('2d');
function draw(){styles.forEach((s,i)=>{const x=frame%6*256,y=Math.floor(frame/6)*256;ctx[s].clearRect(0,0,256,256);ctx[s].drawImage(sheets[s],x,y,256,256,0,0,256,256)});document.getElementById('seek').value=frame;document.getElementById('counter').textContent='F'+String(frame).padStart(2,'0');travel.fillStyle='#dbe4ed';travel.fillRect(0,0,960,560);styles.forEach((s,i)=>{const ground=250+270*i;travel.strokeStyle='#98aabf';travel.beginPath();travel.moveTo(20,ground);travel.lineTo(940,ground);travel.stroke();travel.fillStyle='#20364c';travel.font='16px system-ui';travel.fillText(s+' / RIGHT / 24 FPS',24,24+i*270);travel.imageSmoothingEnabled=s!=='pixel';const f=travelFrame%24;travel.drawImage(sheets[s],f%6*256,Math.floor(f/6)*256,256,256,Math.round(165+226.28571428571428*travelFrame/24)-128,ground-224,256,256)})}
document.getElementById('toggle').onclick=()=>{playing=!playing;document.getElementById('toggle').textContent=playing?'一時停止':'再生'};
document.getElementById('step').onclick=()=>{playing=false;document.getElementById('toggle').textContent='再生';frame=(frame+1)%24;travelFrame=(travelFrame+1)%72;draw()};
document.getElementById('seek').oninput=e=>{playing=false;document.getElementById('toggle').textContent='再生';frame=+e.target.value;travelFrame=frame;draw()};
ready.then(()=>{draw();requestAnimationFrame(function tick(now){const dt=now-last;last=now;if(playing){acc+=dt;const n=Math.floor(acc/(1000/24));if(n){acc-=n*1000/24;frame=(frame+n)%24;travelFrame=(travelFrame+n)%72;draw()}}else acc=0;requestAnimationFrame(tick)})});
</script></html>'''
(out/'preview.html').write_text(html,encoding='utf-8')
(out/'delivery_manifest.json').write_text(json.dumps(metadata,ensure_ascii=False,indent=2),encoding='utf-8')
readme='# 参考画像に合わせた右向き走行 v005\n\nキャラクター01の2Dイラスト版／ドット絵版。右向き、24fps、24枚、1秒ループ。既存の衣装・顔・剣を引き継ぎ、走行の関節軌道を作り直しました。\n\n## 参考画像と対応フレーム\n\n今回の基準は `reference/run_poses.png`（ユーザー提供画像）です。画像の姿勢を寸法に合わせて再構成したもので、厳密なトレースではありません。\n\n| 参考姿勢 | フレーム | 動作 |\n|---|---|---|\n| 1 (R) | 0 | 前脚をほぼ伸ばして接地、反対の踵は後方へ回収 |\n| 2 | 2 | 接地脚を曲げて腰を下げる |\n| 3 | 4 | 支持足が腰の下を通り、反対の脚が前へ出る |\n| 4 | 6 | 後ろの脚で蹴り出し、前の膝を持ち上げる |\n| 5 | 9 | 両足が地面から離れた空中姿勢 |\n| 1 (L) | 12 | 左右を入れ替えて次の接地 |\n\nF12〜F23は反対側の脚による半周期です。脚と逆の腕を前へ振り、接地時の脚の伸び、6pxの沈み込み、後ろの踵の回収、空中期の腰の持ち上げを共通の骨格で表現。剣は握り点に固定し、マント・裾を遅れて追従させています。\n\n## ファイル\n\n- `comparison.gif`：その場走りの2D／ドット絵比較。\n- `run_right_travel.gif`：右へ移動する3秒比較。\n- `key_poses.jpg`：参考画像の6姿勢と同じ並びで骨格・2D・ドット絵を比較。\n- `preview.html`：24fps再生、停止、コマ送り。\n- 各版 `runtime/run/`：256×256透過PNG24枚。\n- 各版 `runtime/run_spritesheet.png`：6列×4行、1536×1024透過PNG。\n- 各版 `production_frames/run/`：1024×1024の制作連番。\n- 各版 `preview/run.png` / `run.webp` / `run.gif`：透過APNG／WebP／背景付きGIF。\n- 各版 `source/rig.json` / `frame_transforms.json`：関節・配置行列。\n- 共通 `source/renderer.py`：編集可能な骨格とパーツ配置。\n\n正確な24fpsの正本は連番と1/24秒のメタデータ。GIFは40/50msを配分し1秒周期、APNG／WebPは41/42msです。HTMLは経過時間から24fpsを選び、実表示は画面の更新周波数に依存します。\n\nドット絵は128×128の論理グリッド、全周期共通パレット31色＋透明、0/255アルファ。256版は整数2倍、1024版は整数8倍。足元の基準位置は(128,224)、ルート移動を含まない素材。移動プレビューは支持足の後退速度226.286px/秒に合わせています。\n\n検証結果は `verification.json` / `recomposition_verification.json` / `delivery_verification.json` / `reference_pose_verification.json` に保存。24枚の連番、透過、寸法、全周期IK、関節被覆、ループ、固定パレット、再合成一致、参考姿勢の前後関係を検査しました。回転する画像パーツ方式のため、服の継ぎ目や靴底の変形には追加の作画余地があります。\n'
(out/'README.md').write_text(readme,encoding='utf-8')
qa=json.loads((out/'qa.json').read_text())
for s in styles:
    assert qa[s]['safe_bounds_pass'],qa[s]
    assert qa[s]['loop_joints_match']
for i in range(10001):r.skeleton(i/10000)
checks={'continuous_ik_samples':10001,'travel_frames':72,'travel_duration_ms':3000,'styles':{}}
for s in styles:
    hashes=[hashlib.sha256(im.tobytes()).hexdigest() for im in frames[s]]
    assert len(set(hashes))==24
    checks['styles'][s]={'unique_frames':24,'fps':24,'dimensions':[256,256],'sheet_dimensions':[1536,1024]}
(out/'delivery_verification.json').write_text(json.dumps(checks,indent=2),encoding='utf-8')
import reference_check
reference_check.main()
archive=out.parent/'character_01_run_right_24fps_v005.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
    for p in out.rglob('*'):
        if p.is_file() and '__pycache__' not in p.parts and p.name not in ['update_motion.py','imagegen_prompts.json','pixel_parts_atlas.png']:
            z.write(p,p.relative_to(out.parent))
print(json.dumps(checks),flush=True)
print('ZIP',archive.name,archive.stat().st_size,flush=True)
