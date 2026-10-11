# 拳闘士：スキル前走行の流用と右端までの範囲攻撃

2026-10-10の追加指定を反映。

- 通常走行は`skills/front_kick/frame_01.png`〜`frame_04.png`をそのまま流用する。5は走行から構えへの遷移なのでループに含めない。
- 1→2→3→4、12FPS、1周約0.33秒。スキルと同じ768×832キャンバス・表示倍率・アンカー。原画への補間・変形・再描画はない。
- 新しい`run_from_skill/`にアトラス・個別原画・メタデータを作成。以前の`run/`およびスキル素材は保持。通常走行の読み込み先のみを変更する。
- スキルはゲームの論理座標x=345〜960に中心がある活動中の敵全員へ、最大伸展時に1回ずつダメージを与える。背後と画面外の敵、命中後に範囲へ入った敵は対象外。ダメージ倍率・発動時間・クールダウンは維持する。
- 範囲内の各敵で既存HP・撃破・経験値処理を呼ぶため、ボスを強制撃破せず、各撃破報酬を一度だけ与える。
- 風エフェクトは既存の右端までの表示を維持。攻撃範囲の現行定義は`BoxerFrontKickSequence.hitArea()`。元スキルJSONにある100px幅のイベント記述は以前の制作記録で、ゲームのダメージ判定には使用しない。

変更：`boxer_run_assets.dart`、`boxer_front_kick_sequence.dart`、`battle_state_controller.dart`、`pubspec.yaml`、関連テスト。新規：`scripts/build-boxer-run-from-skill.py`、`mobile/assets/images/characters/boxer/run_from_skill/`、`artifacts/boxer_run_from_skill_review/`。

原画・保存アトラスのRGBA一致と、走行4番がスキルの先頭原画と一致することを検証。24FPS用8連番も各原画を2回ずつそのまま保持する。

確認結果：`boxer_run_test.dart`、`boxer_front_kick_test.dart`、`boxer_wind_effect_test.dart`の計7件が通過。走行ループと攻撃・スキル復帰、左右境界、背後・画面外の除外、範囲内全敵への1回ずつの命中、命中後に入った敵への再命中防止、撃破報酬、ボスHPを検証。変更コード・テストのDart解析は問題なし。

実機更新は接続端末HA2A23ERが見つからず実行できなかった。今回の最終版は実機での再確認は未実施。
