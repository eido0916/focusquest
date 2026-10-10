from pathlib import Path
import json

base=Path(__file__).resolve().parent
p=base/'verify.py'
s=p.read_text(encoding='utf-8').replace('[0,.32,.48,.62,.79]','[0,7/24,10/24,.5,16/24,19/24,22/24]')
p.write_text(s,encoding='utf-8')
p=base/'renderer.py'
s=p.read_text(encoding='utf-8').replace("'schema_version':4","'schema_version':5").replace('ILLUSTRATION / VIDEO REFERENCE','ILLUSTRATION / POSE REFERENCE')
p.write_text(s,encoding='utf-8')
p=base/'replay_check.py'
s=p.read_text(encoding='utf-8').replace('character_01_recomposition_v004.zip','character_01_recomposition_v005.zip')
# The deliver script creates the final archive after all checks finish.
s=s[:s.index('archive=out.parent/')]
p.write_text(s,encoding='utf-8')
p=base/'deliver.py'
s=p.read_text(encoding='utf-8').replace('v004','v005').replace('(55/.32)','(66/(7/24))').replace('171.875','226.28571428571428')
s=s.replace("'references':['https://www.youtube.com/watch?v=lK6iiZBxJuk','https://www.youtube.com/shorts/3Bzsj4HMpI8']","'references':['reference/run_poses.png']")
a=s.index("readme='''");b=s.index("\n(out/'README.md')",a)
readme='''# 参考画像に合わせた右向き走行 v005

キャラクター01の2Dイラスト版／ドット絵版。右向き、24fps、24枚、1秒ループ。既存の衣装・顔・剣を引き継ぎ、走行の関節軌道を作り直しました。

## 参考画像と対応フレーム

今回の基準は `reference/run_poses.png`（ユーザー提供画像）です。画像の姿勢を寸法に合わせて再構成したもので、厳密なトレースではありません。

| 参考姿勢 | フレーム | 動作 |
|---|---|---|
| 1 (R) | 0 | 前脚をほぼ伸ばして接地、反対の踵は後方へ回収 |
| 2 | 2 | 接地脚を曲げて腰を下げる |
| 3 | 4 | 支持足が腰の下を通り、反対の脚が前へ出る |
| 4 | 6 | 後ろの脚で蹴り出し、前の膝を持ち上げる |
| 5 | 9 | 両足が地面から離れた空中姿勢 |
| 1 (L) | 12 | 左右を入れ替えて次の接地 |

F12〜F23は反対側の脚による半周期です。脚と逆の腕を前へ振り、接地時の脚の伸び、6pxの沈み込み、後ろの踵の回収、空中期の腰の持ち上げを共通の骨格で表現。剣は握り点に固定し、マント・裾を遅れて追従させています。

## ファイル

- `comparison.gif`：その場走りの2D／ドット絵比較。
- `run_right_travel.gif`：右へ移動する3秒比較。
- `key_poses.jpg`：参考画像の6姿勢と同じ並びで骨格・2D・ドット絵を比較。
- `preview.html`：24fps再生、停止、コマ送り。
- 各版 `runtime/run/`：256×256透過PNG24枚。
- 各版 `runtime/run_spritesheet.png`：6列×4行、1536×1024透過PNG。
- 各版 `production_frames/run/`：1024×1024の制作連番。
- 各版 `preview/run.png` / `run.webp` / `run.gif`：透過APNG／WebP／背景付きGIF。
- 各版 `source/rig.json` / `frame_transforms.json`：関節・配置行列。
- 共通 `source/renderer.py`：編集可能な骨格とパーツ配置。

正確な24fpsの正本は連番と1/24秒のメタデータ。GIFは40/50msを配分し1秒周期、APNG／WebPは41/42msです。HTMLは経過時間から24fpsを選び、実表示は画面の更新周波数に依存します。

ドット絵は128×128の論理グリッド、全周期共通パレット31色＋透明、0/255アルファ。256版は整数2倍、1024版は整数8倍。足元の基準位置は(128,224)、ルート移動を含まない素材。移動プレビューは支持足の後退速度226.286px/秒に合わせています。

検証結果は `verification.json` / `recomposition_verification.json` / `delivery_verification.json` / `reference_pose_verification.json` に保存。24枚の連番、透過、寸法、全周期IK、関節被覆、ループ、固定パレット、再合成一致、参考姿勢の前後関係を検査しました。回転する画像パーツ方式のため、服の継ぎ目や靴底の変形には追加の作画余地があります。
'''
s=s[:a]+"readme="+repr(readme)+s[b:]
s=s.replace("# Show actual travel", "# Show actual travel")
s=s.replace('# 226.28571428571428 source px/sec matches the support-foot backward velocity.','# 226.286 source px/sec matches the support-foot backward velocity.')
s=s.replace("archive=out.parent/", "import reference_check\nreference_check.main()\narchive=out.parent/")
p.write_text(s,encoding='utf-8')
print('Delivery scripts updated for image reference v005')
