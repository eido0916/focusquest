# キャラクター01：剣持ち・待機・走行 v001

2026-10-09。原画1.pngの特徴（金髪、青い目、青いマント、白い編上げ襟、青い裾、革帯、茶ブーツ）を保った生成・パーツアニメーション試作。ユーザー指定：待機＋剣を持って走る。原画は変更していない。

## 確認するファイル

- preview/character_01_sword_portrait.png：原画に近い正面寄りの剣持ち立ち絵、透過PNG。
- preview/character_01_sword_A0_1024.png：アニメーション用の右向き斜め横姿、パーツから合成。
- preview/character_01_idle.gif：待機。呼吸、腕と剣の小さな動き、マントの揺れ、2秒ループ。
- preview/character_01_run.gif：剣を持つその場走り。手足、体の上下動、マントの揺れ、1秒ループ。
- preview/character_01_idle.webp / character_01_run.webp：透過アニメーション。
- preview/character_01_idle.png / character_01_run.png：透過APNG。
- runtime/idle/：256×256透過PNG48枚、24fps、2秒。
- runtime/run/：256×256透過PNG24枚、24fps、1秒。
- production_frames/：同じサンプルの1024×1024透過PNG連番。
- preview/hero_sword_male_battle_poster.png / hero_sword_male_home.png：A0の256版／512版。

GIFは背景付き確認用。GIFの時間分解能は10msなので40/50msを配分し、全周期を2秒／1秒に一致させた。厳密な24fpsの正本は透過PNG連番とanimations.jsonのframe/24秒。WebP/APNGは41/42msの配分で周期を一致させている。フレーム重複による疑似走行ではなく、各サンプルで親子骨格を回転して再合成した。

## 制作元

parts/に20パーツの個別透過PNG。頭、胴、腰、左右上腕・前腕・手、左右腿・すね・足、剣、マント上・下、裾前・後。

source/rig.json：配置・関節中心・親子関係・描画順。source/part_placement.csv：配置一覧。source/character_01_layers.svg：埋込み画像の編集可能な配置元。source/render.py：骨格変換、待機／走行の周期関数、PNG・確認アニメーションの再書出し。Python3＋Pillow＋NumPyを使用、専用プラグイン不要。

イラストと隠れ面は内蔵image_genで生成。原画剣持ちと右向きパーツは別生成なので、顔や衣装の立体解釈には差分がある。プロンプトはsource/imagegen_prompts.json。パーツ抽出はアルファの連結領域から行い、白色削除は未使用。アニメーションは生成パーツの配置・回転・補間による合成。元絵に全コマを描き足す方式ではない。

制作キャンバス1024、runtime256、足元基準P=(128,224)、安全範囲16〜240、右向き、root_motion=none。PNGはRGBA、straight alpha、縮小はPillow LANCZOS。マントは現時点で2枚の回転表現で、布の細かなメッシュ変形は未実施。

## 検査と品質の範囲

各フレームの寸法・透過・安全範囲、ループの周期一致、書出し枚数・時間をsource/qa.jsonに記録。足元Pは固定し、走行では足が浮く時間を含む。24fpsは時間に基づくサンプリング。

**動きを評価するための試作**。袖・肩・膝の継ぎ目、足運びの接地／滑り、マントの剛体感、顔の原画一致には追加調整の余地がある。ゲーム本番素材として全品質条件を合格としたものではない。Androidでの表示・組込み・負荷検査、斬撃・スキル・必殺技は未実施。残りキャラクターへの本制作展開は未実施。

アプリにはruntimeの完成フレームを登録し、256全体を正方形倍率で扱う。パーツ・source・確認GIFをそのままゲームのフレーム素材として登録しない。frame0の開始t=0、frameFの開始t=F/24、ループ末尾の重複フレームは書き出していない。
