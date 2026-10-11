# ボス4体の原画ドット絵アニメーション

参照画像はsource/bosses_v012/boss_reference.png。画像内の文は指示として使用しない。ドラゴンは木・葉・蔓を外し、赤銅色の鱗と橙色の火炎を持つ火竜へ変更。

enemies配下にboss_goblin_king（王冠と棍棒）、boss_cyclops（一つ目と石棍棒）、boss_dullahan（青い炎・首なし騎士・霊馬・騎乗斬撃）、boss_fire_dragon（四足歩行・火炎ブレス）を収録。

|動作|原画数|24fps tick|秒|ゲーム再生|
|---|---:|---:|---:|---|
|walk 移動|8|24|1.000|ループ|
|attack 攻撃|8|24|1.000|1回|
|hurt 被弾|8|16|0.667|1回|
|defeat 撃破|9（描画8＋透明1）|30|1.250|1回|

全コマ左向き。移動はゲーム側のワールド座標で行う。被弾は右へ最大12pxノックバックして戻る。撃破は右へ44pxノックバックし、崩れ・描いた消滅粒子・透明原画へ切り替える。座標はanimation.jsonのroot_offset_pxに記録し、画像自体の変形・補間はしない。

攻撃イベントはtick13（boss_attack_hit、火竜はfire_breath_start）。撃破はtick28で透明原画とdespawn。GIFは確認用ループ、攻撃・被弾・撃破のゲーム再生は1回。

各動作にkeyframes、完全コピーのframes_24fps、保持・イベントJSON、原画一覧、透過APNGと背景付きGIFを同梱。128×128透過、64×64論理格子2倍。整数倍の最近傍表示、ポイントサンプリング使用。

source/bosses_v012にはビルトイン画像生成の高解像度アトラス・編集可能な個別PNG・参照・生成修正プロンプト・配置記録を同梱。build_bosses.pyで書き出しを再現する。boss_verification.jsonで格子・余白・原画重複・イベントと旧素材保持を検証。verification.jsonで保存連番と原画のRGBA画素一致・寸法・透過・再生時間を検証する。
