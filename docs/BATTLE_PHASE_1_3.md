# 戦闘仕様 Phase 1〜3（2026-10-04）

添付仕様の第46節に従い、横向き・走行・雑魚の自動撃破を先行実装。

## 操作

ホーム → 集中をはじめる → 時間設定 → 集中を開始。
横向きの16:9戦闘画面が開く。戦闘操作は不要。
「タイマーに戻る」は集中を継続したまま表示だけ閉じる。「戦いの様子を見る」で再表示できる。
集中終了でBattleResultDataをFlutterへ返し、既存の集中成功/失敗判定へ戻る。
Androidの横向き指定に加え、指定を無視するタブレットでは表示領域を回転して横画面を維持する。
離脱後はアプリの従来設定である縦向きに戻す。

## 実装範囲

- 青空・山・城・草原を別速度で流す背景。描画素材はプレースホルダー。
- 左側の主人公の走行・攻撃・剣の軌跡・小さな画面揺れ。
- 右側から2種の敵。0.55秒出現、0.55秒攻撃、ワンパン、ノックバック、消滅。
- 浮き上がって消えるダメージ文字（演出用の仮値128）。
- 敵1体につき1 EXPをBattleResultDataへ集計（現行バランス）。
- 画面オフ復帰や表示再入場は開始時刻から固定ステップで再計算。二重加算を防ぐ。
- 180分までのシミュレーションで生存/消滅待ちの敵だけを保持。

## 責務と素材差し替え

`game/runner/` のロジックは `BattleStateController`、描画はFlame Componentに分離。
敵追加は `EnemyData` と `RunnerConfig.enemies`、速度や周期は `RunnerConfig`。
背景は `BackgroundComponent`、人物は `HeroComponent`、敵は `EnemyComponent` のrenderをSprite/SpriteAnimationへ差し替える。
`HeroMotion`にはidle/run/attack/skill/bossAttack/victoryを確保。skill/bossAttackは後続フェーズ用。
配置や判定は960×540の論理座標を利用し、描画素材のピクセル寸法に依存しない。
将来素材は `assets/battle/{backgrounds,hero,enemies,bosses,skills,effects,ui}/` に追加しpubspecへ登録する。

## 次の段階

Phase 4〜8の正式HUD・10秒スキル・600秒ボス・15秒ボス戦・ガチャ報酬確定は未実装。
現時点のEXPは戦闘内の集計値。プレイヤーへの恒久付与は既存の集中報酬規則のまま。
Phase 7でUsageStats成功判定と同一トランザクションに統合し、表示の有無に関係なく同じ報酬にする。
旧来の進行度5消費の冒険は削除済み。集中と自動戦闘を一つのループに統合した。

## 検証

既存とロジックの32件、横向き/縦向き代替表示と自動終了の2件、計34件のテスト成功。新規テストは出現・撃破・EXP、フレーム刻みと一括復帰の一致、
終了時間の上限と重複防止、敵EXP設定と180分時の保持数を検証。
既存画面テストは戦闘の非同期画像読込完了を待つよう修正。

Flutter解析は問題なし、Android APKビルド成功、TB373FU / Android 16へ更新済み。
実機で1分集中を開始し、横向き16:9、背景移動、人物、敵2種、消滅とダメージ数字を確認。
時刻の異なるスクリーンショットで討伐6体/EXP60→76体/EXP760を確認。
`output/android/runner-battle.png` と `runner-battle-later.png` に保存。
画面消灯後の復帰確認は端末のパスワード画面で停止。実機での終了結果画面は未確認。

コード全文: [BATTLE_PHASE_1_3_SOURCE.md](BATTLE_PHASE_1_3_SOURCE.md)
