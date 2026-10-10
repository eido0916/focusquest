# character_10 魔剣士・男女版

男性は10.png、女性は女2.png上段左から2体目を参照。紫と黒の衣装、銀の星形留め具、マントの淡色模様を保持。男性は短髪と長ズボン、女性は長い黒紫髪と参照の脚装備・短い衣装を使用。

|動作|原画|24fps tick|秒|ゲーム再生|
|---|---:|---:|---:|---|
|run 走行|8|16|0.667|ループ|
|sword_slash 停止斬撃|8|24|1.000|1回|
|thunder_slash 雷剣・落雷|12|36|1.500|1回|

通常斬撃はtick12でsword_hit。雷スキルはtick9でthunder_charge_begin、tick20でelectric_sword_hit、tick22でlightning_strike。落雷のゲーム側対象位置はキャラクター原点から右48pxを標準とする。視覚用の落雷・発光は完成原画に描かれており、当たり判定・対象座標・ダメージはゲーム側のイベントで実装する。

出力はplayers/character_10、players_female/character_10_female。各動作にkeyframes、frames_24fps、sprite_sheet.png、animation.json、透過APNGおよび確認用GIFを収録。GIFは確認用に繰り返し、停止攻撃のloop_in_gameはfalse。原画の回転・パーツ変形・補間・クロスフェードは使用しない。128×128透過、64×64論理格子2倍。走行移動はゲーム側で行い、画像の原点オフセットは全tickゼロ。

source/magic_v011にビルトイン画像生成の高解像度原画PNG、生成・修正プロンプト、参照画像、編集可能な個別PNG、配置記録を同梱。build_magic.pyは完成原画の固定解像度・共通パレット書き出しと保持連番を再現する。途中の姿勢は生成しない。

verify_magic.pyで新6動作の寸法、二値透過、ドット格子、余白、原画重複、イベントと原画番号を検証。verify_saved.pyで全素材のRGBA画素一致・時間・ZIPを検証。v010の既存プレイヤーと敵素材はSHA256で同一性を確認する。
