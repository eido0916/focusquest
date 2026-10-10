# 女剣士の走行スキル

通常攻撃とは別の非ループスキル。既存の女剣士コンポーネントに追加し、状態管理・移動・通常攻撃との排他を共有する。
魔法・斬撃エフェクトは追加しない。発動瞬間の`onSkillActive`で将来別レイヤーを追加可能。
男剣士・蒼閃・既存戦闘シミュレーションは変更していない。

## 元画像

明示された順番を維持し、元画像の名前・内容を変更せず、同名コピーをアセット内へ保存した。

| シート | ファイル名 | 通し番号 |
|---|---|---|
| 01 | ChatGPT 画像 2026年10月10日 10_31_23.png | 01–05 |
| 02 | ChatGPT 画像 2026年10月10日 10_32_02.png | 06–10 |
| 03 | ChatGPT 画像 2026年10月10日 10_32_13.png | 11–15 |
| 04 | ChatGPT 画像 2026年10月10日 10_32_21.png | 16–20 |
| 05 | ChatGPT 画像 2026年10月10日 10_32_29.png | 21–25 |
| 06 | ChatGPT 画像 2026年10月10日 10_32_36.png | 26–30 |
| 07 | ChatGPT 画像 2026年10月10日 10_32_44.png | 31–35 |

## 全35候補の確認結果

すべて2172×724、アルファの範囲は0–255で本物の透過背景。背景除去は行わない。
まず等間隔5分割を保存。武器が境界をまたぐコマは、元画像のアルファ領域から人物を分離した版も確認した。
全35ポーズの剣・体勢・接続をサムネイルで目視。重なりが復元できないコマは除外し、描き足さない。
「削除」は再生対象からの除外であり、原本や確認用候補PNGは削除していない。

| 通し番号 | 画像内ID | 判定 | 内容・理由 |
|---|---|---|---|
| 01 | sheet01_frame01 | 採用 | 開始走行 |
| 02 | sheet01_frame02 | 採用 | 脚の入れ替え |
| 03 | sheet01_frame03 | 採用 | 走行から前傾移行 |
| 04 | sheet01_frame04 | 除外 | 初動を長くしないため類似走行を間引く |
| 05 | sheet01_frame05 | 採用 | 接地して減速へ |
| 06 | sheet02_frame01 | 採用 | 膝を曲げる |
| 07 | sheet02_frame02 | 採用 | 右腕を引く |
| 08 | sheet02_frame03 | 採用 | 低い構えへ |
| 09 | sheet02_frame04 | 採用 | 最も低い溜め姿勢 |
| 10 | sheet02_frame05 | 除外 | 剣が突然後方へ向き、低姿勢も重複 |
| 11 | sheet03_frame01 | 除外 | 通常構えに戻り、溜めをやり直すように見える |
| 12 | sheet03_frame02 | 除外 | 発動前に走行へ戻ってしまう |
| 13 | sheet03_frame03 | 除外 | 走行の脚運びへ戻り、溜めの流れが逆戻り |
| 14 | sheet03_frame04 | 除外 | 剣先に次の人物の髪・マントが混入 |
| 15 | sheet03_frame05 | 採用 | 大きく振りかぶる |
| 16 | sheet04_frame01 | 採用 | 上方へ振りかぶったキーポーズ |
| 17 | sheet04_frame02 | 除外 | 剣と次のマントが接触、分離後も隣人が混入 |
| 18 | sheet04_frame03 | 除外 | 前後の剣と髪・マント混入。単独の剣を確保できない |
| 19 | sheet04_frame04 | 除外 | 前後の剣混入と、自分の剣先欠け |
| 20 | sheet04_frame05 | 除外 | 前コマの剣が脚へ混入、自分の剣先も右端付近で不明瞭 |
| 21 | sheet05_frame01 | 採用 | 前へ踏み込み、下方へ振り抜く |
| 22 | sheet05_frame02 | 採用 | 振り抜きの余韻 |
| 23 | sheet05_frame03 | 採用 | 体幹を戻す |
| 24 | sheet05_frame04 | 採用 | 重心を上げて復帰 |
| 25 | sheet05_frame05 | 除外 | 直立寄りの重複復帰で、再走行が遅れる |
| 26 | sheet06_frame01 | 採用 | 走行への最初の接地 |
| 27 | sheet06_frame02 | 採用 | 後脚を引く |
| 28 | sheet06_frame03 | 採用 | 脚を交差 |
| 29 | sheet06_frame04 | 採用 | 前脚を出して走行 |
| 30 | sheet06_frame05 | 除外 | 後脚を上げる走行が重複 |
| 31 | sheet07_frame01 | 採用 | 完全復帰の走行 |
| 32 | sheet07_frame02 | 採用 | 走行ループ接続候補 |
| 33 | sheet07_frame03 | 採用 | 脚の交差 |
| 34 | sheet07_frame04 | 採用 | 最後の走行接地 |
| 35 | sheet07_frame05 | 除外 | 両足を広げる終端で、走行ループへの接続が弱い |

採用22コマ／最終再生順序（元の時系列を維持）:

`01 → 02 → 03 → 05 → 06 → 07 → 08 → 09 → 15 → 16 → 21 → 22 → 23 → 24 → 26 → 27 → 28 → 29 → 31 → 32 → 33 → 34`

除外13コマ: `04,10,11,12,13,14,17,18,19,20,25,30,35`。

素材上の制約：振り下ろしの中割り17–20が使用できないため、16→21はキーポーズ間の切り替えになる。
剣の移動を完全に滑らかに保証することはできない。改善には、隣の人物と重ならない振り下ろし素材が必要。
キャラクターの再描画・生成補間は行っていない。

## 各コマ時間・状態

| 最終番号 | 元番号 | duration（秒） | 区間 |
|---|---|---|---|
| 1 | 01 | .060 | startup・走行 |
| 2 | 02 | .060 | startup・走行 |
| 3 | 03 | .060 | startup・走行 |
| 4 | 05 | .060 | startup・減速 |
| 5 | 06 | .080 | startup・構え |
| 6 | 07 | .080 | startup・構え |
| 7 | 08 | .080 | startup・構え |
| 8 | 09 | .100 | startup・低姿勢 |
| 9 | 15 | .140 | startup・振りかぶり |
| 10 | 16 | .140 | startup・振りかぶり |
| 11 | 21 | .100 | active・振り抜き |
| 12 | 22 | .140 | recovery・余韻 |
| 13 | 23 | .100 | recovery |
| 14 | 24 | .080 | recovery |
| 15 | 26 | .060 | recovery・走行復帰 |
| 16 | 27 | .060 | recovery・走行復帰 |
| 17 | 28 | .060 | recovery・走行復帰 |
| 18 | 29 | .060 | recovery・走行復帰 |
| 19 | 31 | .070 | recovery・走行 |
| 20 | 32 | .070 | recovery・走行 |
| 21 | 33 | .070 | recovery・走行 |
| 22 | 34 | .070 | recovery・走行 |

- startup: 0–0.860秒、active: 0.860–0.960秒、recovery: 0.960–1.800秒。
- activeは最終11コマ目（元sheet05_frame01）。JSONの0始まりインデックスは`[10]`。
- 1.800秒で通常攻撃用アセットのrunループへ戻る。走行画面位置は巻き戻さない。
- `onSkillHit`は1回だけ。大きなdtで区間を通過しても呼び落とさない。敵不在なら受け側で何もしない。
- `playSkill()`は通常攻撃を中断、再生中のスキル再発動を拒否。スキル中は`playRunAttack()`も拒否。
- 移動は走行速度から最初の0.24秒で25%まで減速、溜め中25%、active70%、復帰で35%から100%へ加速。
- `onAdvance`を渡せば固定画面方式にも対応。移動を既存背景が担当する場合は空コールバックを渡す。
- 共通透過キャンバス、胴体X基準と足元Y基準を使用し、剣・髪の領域を含めて余白を確保する。

設定は`assets/images/characters/female_swordsman/skill/skill.json`の`stepTimes`など。
全体の速度は`FemaleSkillAssets.load(game, timeScale: 1.2)`で20%長くできる。
生成時設定は同フォルダーの`selection.json`。通常攻撃用画像は変更していない。

## 実装・呼び出し

実装は`female_skill_assets.dart`と拡張した`female_run_attack_component.dart`。
同じコンポーネントがrun/通常攻撃/スキルの状態を管理し、Playerを二重に追加しない。

```dart
import 'package:flame/components.dart';
import 'female_run_attack_assets.dart';
import 'female_skill_assets.dart';
import 'female_run_attack_component.dart';

// FlameGame.onLoad内
final normal = await FemaleRunAttackAssets.load(this);
final skill = await FemaleSkillAssets.load(this);
final player = FemaleRunAttackComponent(
  assets: normal,
  skillAssets: skill,
  position: Vector2(345, 405),
  onSkillHit: (area) {
    // 既存の敵管理から範囲内の敵を選び、スキルダメージを1回適用。
    // 敵がいなければ何もしない。倍率・HPは既存の戦闘側が所有する。
  },
  onSkillActive: (position) {
    // 後から別レイヤーの演出をここに追加できる。今回は何も追加しない。
  },
);
await add(player);
player.playSkill(); // 通常攻撃は player.playRunAttack()
```

既存集中画面への自動差し替え・10秒クールダウン登録は今回行っていない。
現在の男剣士の戦闘状態に二重でダメージを適用しないため、女剣士画面への接続時は戦闘側か上のコールバックの片方だけをダメージ所有者にする。

## 素材確認・生成物

`scripts/build-female-run-attack.py --skill --review`で35等分候補と分離候補を生成。
`--skill`で採用アトラス・JSON・プレビューを生成。いずれも原本を変更しない。
`artifacts/female_skill_review/sheet01_frame01.png`～`sheet07_frame05.png`が候補。
`isolated_XX.png`が分離候補、`aligned_XX.png`が採用コマ整列結果。
`skill_preview.gif`は確認しやすい繰り返しプレビュー。ゲーム用は非ループ。

実装後のテスト・静的解析・端末確認はユーザーのご指定に従い実行していない。Androidインストールも未実施。
