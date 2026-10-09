# キャラクター01：ミニキャラの右向き走行

128×128pxの個別透過PNG6姿勢。論理64×64の整数2倍、全コマ共通24色以内、透明0/255。剣を持ったまま右へ走る、その場ループ。元の待機PNGは変更していない。

## 参考と姿勢

[DOT ART PLAY：走るドット絵GIFの作り方](https://dotartplay.com/dot-animation-run)で示された脚の伸展と膝曲げの交替、腕の振り、上下動を参照。[64×64版](https://dotartplay.com/dot-animation-run-64)の6コマ構成を採用し、右膝上げ→右脚伸展→右接地・沈み→左膝上げ→左脚伸展→左接地・沈み、の順でループする。サイトの人物画像は納品素材へ転用していない。

今回のフィールド用ミニキャラを参照し、内蔵image_genで1枚の6コマ原稿を生成。髪色、青いマント、白い服、茶色の装備、剣とデフォルメを保持して横向き走行へ変更。原稿はsource/generated_run_sheet.png、正確な生成指示はsource/prompt.txt。

## ファイルと再生

- frames/character_01_run_00.png〜05.png：異なる6姿勢の完成PNG。
- character_01_run_sheet_128.png：128×128セルを3列×2行で配置した透過シート。
- preview/all_6_frames.png：コマ番号入り拡大一覧。
- preview/run.gif：背景付き動作確認用、run.webpとrun.png：透過のWebP/APNG。
- frames_24fps/：24fps再生用の12枚。各姿勢を2フレーム保持、1周期0.5秒。新しい12姿勢を描いたものではない。
- animation.json：姿勢・順番・保持時間・連番・寸法。
- source/export_frames.py：セル分割、ドットと共通色の整理、書出し元。Python＋Pillow＋NumPy。
- verification.json：寸法・アルファ・2×2ブロック・見切れ・6画像の相違を確認。

GIFは80/90ms、WebP/APNGは83/84msを配分し、周期500ms。実装時はanimation.jsonのF/24秒で再生。キャラクターの右方向移動はゲーム側で加える。各コマは同じキャンバスを保持し、個別に自動トリミングしない。

生成された走行は参考画像の特徴を元にした新しい6姿勢。輪郭や小さな装飾の全ピクセルが待機画像と一致するものではない。今回の納品は完成フレームで、独立可動パーツや四方向の走行を含めない。
