# 女性版プレイヤー v008

添付の女.pngを外見参照として、上段左から剣士・拳闘士・侍・重騎士、下段左から忍者・アサシンの6体を制作。弓使いとガンナーは今回の対象外です。画像内の文字は作業指示として使用していません。

| 男性版の番号 | 女性版のフォルダ | 走行以外の新作動作 |
|---|---|---|
| character_01 | players_female/character_01_female | 縦斬り、剣の蓄力と斬撃波 |
| character_02 | players_female/character_02_female | 連続パンチ、足の蓄力と回転蹴り |
| character_03 | players_female/character_03_female | 居合、刀の蓄力と乱舞 |
| character_04 | players_female/character_04_female | 大剣の振り下ろし、蓄力と薙ぎ払い |
| character_05 | players_female/character_05_female | 手裏剣投げ、印・瞬間移動・短刀突き |
| character_06 | players_female/character_06_female | 短剣の突き、蓄力クリティカル |

各職業は走行8原画・通常攻撃8原画・スキル8原画、計144枚の新作ポーズです。女性剣士には構え原画を48tick保持する待機、および走行→停止→攻撃/スキルの連結版も含みます。待機は静止原画の保持であり、新たな呼吸動作は含みません。連結版は新作原画をそのまま使用します。

完成画像は128×128px・背景透過、64×64px論理格子を最近傍法で2倍にした素材です。全プレイヤー右向き。24fps連番は原画ファイルの複製だけで制作し、回転・パーツ変形・モーフィング・補間・フェードは行いません。元の大きな生成原画を格子へ変換する制作時のサンプリングと、原画完成後のアニメーション再生は区別しています。同一キャラクターの全動作で同じ最終縮小率・パレットを使用しています。

走行は16tick/0.667秒のループ、通常攻撃24tick/1.00秒、スキル32tick/1.333秒の一回再生。剣士の連結版は走行2周期と4tickの停止から攻撃・スキルへ接続します。忍者の瞬間移動はJSONのworld_delta_pxイベントとroot_offset_px（絶対オフセット）で記録。画像を変形せずゲーム側で一度だけ40px右へ座標を移します。イベントと絶対座標オフセットを重複加算しないでください。

各動作にkeyframes/、frames_24fps/、animation.json、sprite_sheet.png、preview/animation.gif、preview/animation.pngを納品。GIFは確認用の背景付きプレビュー、animation.pngは透過APNG。ゲームではJSONのloop_in_gameに従います。実装時はポイントサンプリング、拡大プレビューは整数倍の最近傍法を使用してください。

制作元：source/female_v008/reference.png、生成原画アトラス、職業ごとの追加原画アトラス、最終の個別原画PNG、registration.json、inputs.json、prompts.json、final_override_prompts.json。ビルトインimage_genで原画を生成し、source/build_female.pyで原画登録と書き出しを再現します。制作元のラスターPNGは編集可能ですが、Asepriteのレイヤー形式ではありません。

男性6体・敵3体の既存の全素材はv007と同一のファイル内容で保持。旧版を上書きせずv008へ追加しました。verification.jsonで連番のRGBA画素と対応原画の完全一致、透過、寸法、APNG時間を確認し、female_verification.jsonで既存素材の一致を記録しています。
