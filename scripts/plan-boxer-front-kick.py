"""Record the visual review; stable source numbers are sheet*5+slot+1."""
import json
import numpy as np
from PIL import Image
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
review = ROOT / 'artifacts/boxer_front_kick_review'
out = ROOT / 'mobile/assets/images/characters/boxer/skills/front_kick'
records = json.loads((review/'candidates.json').read_text(encoding='utf-8'))
hips = [295,735,1110,1510,1890,215,635,1040,1410,1830,
        160,520,925,1340,1780,180,520,1020,1440,1870,
        185,595,1030,1450,1860,220,640,1025,1440,1820,
        215,625,1040,1405,1845]
frames = [4,5,6,7,8,9,10,11,12,13,14,21,22,23,24,26,27]
ticks = [1,1,2,2,2,2,2,1,1,1,2,1,1,2,2,1,1]
notes = {
 1:'走行の大開脚。減速開始には4の接地寄り姿勢を採用',
 2:'走行の重複候補。減速中に腕を再び振らないため除外',
 3:'走行の重複候補。4から構えへの遷移を優先',
 15:'14とほぼ同じ最大伸展。保持時間で強調するため重複を除外',
 16:'前蹴りの途中で頭・胴体が小さくなり蹴り角度が上向きへ変わる',
 17:'16と同じ小さい体格・上向き蹴り。13→14の水平伸展を優先',
 18:'16と同じ体格差。最大伸展を重ねると二度蹴りに見える',
 19:'引き戻し候補だが前区間との体格差。21の同縮尺寄り姿勢を優先',
 20:'膝上げ候補だが頭と胴体の体格差。22の引き戻しを優先',
 25:'24とほぼ同じ着地構え。24の保持で接地を示す',
 28:'走行復帰後の浮遊姿勢。既存走行サイクルへ復帰するため除外',
 29:'走行の重複候補。27の後は既存走行へ復帰',
 30:'走行の重複候補。スキル本体を引き延ばさないため除外',
 31:'走行の重複候補。既存走行を維持',
 32:'走行の重複候補。既存走行を維持',
 33:'浮遊した走行姿勢。着地後の既存走行を維持',
 34:'走行の重複候補。既存走行を維持',
 35:'31に近い走行の重複候補。既存走行を維持',
}
placements = {}
for r, hip in zip(records,hips):
    x0,y0,x1,y1 = r['isolatedBBox']
    mask = np.array(Image.open(review/f"isolated_{r['id']:02d}.png"))[:,:,3] > 64
    foot_y = int(np.flatnonzero(mask.sum(axis=1) >= 14)[-1])
    x = 320-(round(hip*2172/2048)-x0)
    if r['id'] in [9,10,11,12,13,14,21,22]:
        # Keep the planted support boot in place during knee/extension poses.
        yy,xx = np.nonzero(mask[max(0,foot_y-8):foot_y+1])
        x = 340 - round(float(np.median(xx)))
    placements[str(r['id'])] = [x,700-foot_y]
plan = dict(width=768,height=832,columns=5,anchorX=320/768,anchorY=700/832,
    sourcePixelDisplayScale=215/328/2,frames=frames,holdTicks=ticks,fps=24,
    placements=placements,excluded=notes,
    events=dict(impactFrame=14,impactIndex=10,impactTick=sum(ticks[:10]),
        durationTicks=sum(ticks),coordinateMode='fixed_screen_background_scroll',
        screenAnchor=dict(x=345,y=405),
        hitArea=dict(x=345,y=285,width=100,height=105),
        normalScrollPixelsPerSecond=108,
        scrollSpeedEvents=[dict(tick=0,ratio=1),dict(tick=6,ratio=.2),
            dict(tick=14,ratio=.8),dict(tick=17,ratio=.35),dict(tick=25,ratio=1)]),
    review='全35姿勢をsheet_01〜07で目視。膝上げ→水平伸展→屈曲→着地の順。新規描画・画像補間なし。')
(out/'selection.json').write_text(json.dumps(plan,ensure_ascii=False,indent=2),encoding='utf-8')
print('selected',len(frames),'ticks',sum(ticks),'impact',sum(ticks[:10])/24)
