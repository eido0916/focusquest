"""Export a complete, traceable review without modifying source PNGs."""
from pathlib import Path
import json
import shutil

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT/'mobile/assets/images/characters/boxer/skills/front_kick'
REVIEW = ROOT/'artifacts/boxer_front_kick_review'
d = json.loads((OUT/'front_kick.json').read_text(encoding='utf-8'))
(REVIEW/'sources').mkdir(exist_ok=True)
for name in dict.fromkeys(r['source'] for r in d['candidates']):
    shutil.copy2(Path('C:/Users/eido0/Downloads')/name, REVIEW/'sources'/name)
phases = dict(zip(d['frames'], ['減速開始','減速・構え','踏ん張り','溜め','溜め',
    '膝上げ','膝を畳む','膝を保持','脚を伸ばす','伸展','最大伸展・命中',
    '脚を戻す','膝を畳む','足を下ろす','着地','前傾して走行復帰','走行復帰']))
lines = ['# 拳闘士・初期スキル「前蹴り」実装報告', '',
 '既存の集中タイマーから開くFlutter + Flame戦闘画面へ接続。操作キャラクターのcharacterTypeがboxerのとき、既存の10秒周期で前蹴りを自動発動します。独立冒険画面の戦闘仕様は変更していません。', '',
 '## 原画と再生', '',
 '実測：7枚とも2172×724 RGBA。各シートの境界はround(i×幅/5)で計算。raw_01〜35.pngは等幅候補、isolated_01〜35.pngは透過輪郭で隣の人物を分離した候補です。低アルファの輪郭も元画素で復元し、新規描画・補間・回転・パーツ変形はありません。', '',
 'ゲーム用全35姿勢は768×832の共通透過キャンバスへ無変形で配置。通常攻撃側の元画素縮尺に合わせ、全姿勢に共通の表示倍率215/328/2を適用。外接矩形の幅に応じた縮小はしていません。膝上げ〜引き戻しの軸足を固定し、他は腰を基準に整列。接地位置は低アルファのノイズでなくブーツの実輪郭から取得しました。', '',
 '採用17姿勢、25tick / 24fps = 1.041667秒。全35姿勢をsheet_01〜07.pngで目視確認。ファイルの時刻だけで順序を決めず、溜め→膝上げ→水平伸展→屈曲→着地の関係を確認しています。選択後の順序は元番号順のまま、体格と蹴り角度が変わるシート4を抜いて14→21に接続しました。', '',
 '再生順：' + ' → '.join(map(str,d['frames'])), '',
 '## 採用姿勢と時間', '', '|順|元番号|シート内番号|開始秒|保持秒|役割|', '|---|---|---|---|---|---|']
t = 0
for i,(n,ticks) in enumerate(zip(d['frames'],d['holdTicks'])):
    lines.append(f'|{i+1}|{n:02d}|S{(n-1)//5+1}/F{(n-1)%5+1}|{t/24:.6f}|{ticks/24:.6f}|{phases[n]}|')
    t += ticks
lines += ['', '最大伸展：元番号14、シート3の4番目。開始15/24 = 0.625秒、2tick保持。戦闘シミュレーションは既存の50ms刻みなので、HPへの適用は開始後0.65秒の更新（最大伸展表示中）です。描画は戦闘時計の端数も使い、20fpsに制限しません。', '',
 '## 全35姿勢の判断', '', '|元番号|元ファイル|シート内番号|判断|', '|---|---|---|---|']
for r in d['candidates']:
    n = r['id']
    choice = '採用：'+phases[n] if n in phases else '除外：'+d['excluded'][str(n)]
    lines.append(f"|{n:02d}|{r['source']}|{r['sourceFrame']}|{choice}|")
lines += ['', '## 戦闘との統合', '',
 '- BattleReplayPageの拳闘士分岐からfrontKickを自動スキルに指定。通常攻撃用の既存BoxerRunAttackAssetsを再利用。',
 '- BoxerHeroComponentは戦闘状態を観察して原画を切り替えます。通常攻撃はスキルへ割り込めず、スキル終了で既存の走行アセット・サイズ・アンカーに戻ります。連続呼び出しは発動中に拒否します。',
 '- ダメージ計算は既存のnormalDamage×sousenDamageMultiplier、敵HP・討伐・EXPの既存_damageを使用。最大伸展で右前方の敵1体に1回だけ適用。空振りでも引き戻しと着地を再生します。',
 '- 画面内の座標(345,405)は維持。背景のスクロール速度で減速・踏み込み・復帰を表現し、敵AI/敵移動は変更していません。',
 '- エフェクト追加なし。BoxerFrontKickSequence.impactTimeとhitArea()から発動時刻・位置を取得できます。', '',
 '## 変更箇所', '',
 '- mobile/lib/game/runner/boxer_front_kick_sequence.dart：採用原画、保持時間、命中時刻・範囲、速度比。',
 '- mobile/lib/game/runner/boxer_front_kick_assets.dart：Flame SpriteAnimationの読み込み、アセットと戦闘タイムラインの一致検証。',
 '- mobile/lib/game/runner/boxer_hero_component.dart：スキル再生・通常攻撃競合防止・走行復帰。',
 '- mobile/lib/game/runner/battle_state_controller.dart：frontKick、1回命中、描画用時刻、背景移動距離。',
 '- mobile/lib/game/runner/focus_quest_battle_game.dart：拳闘士の前蹴りアセット読み込み。',
 '- mobile/lib/game/runner/background_component.dart：背景速度の反映。',
 '- mobile/lib/features/focus/presentation/battle_replay_page.dart：職業別の初期スキル指定。',
 '- mobile/pubspec.yaml：前蹴りアセット登録。',
 '- mobile/test/boxer_front_kick_test.dart：命中、空振り、周期、再発動、実際のFlameコンポーネントの復帰検証。', '',
 '## 納品データ', '',
 '- sources/：元PNGのコピー（元ファイルは未変更）。',
 '- candidates.json：全35姿勢の元ファイル・番号・分割境界・SHA256。',
 '- raw_*.png / isolated_*.png / sheet_*.png：全候補と目視用一覧。',
 '- mobile/assets/images/characters/boxer/skills/front_kick/frame_*.png：共通キャンバスの全35姿勢。',
 '- front_kick.json / selection.json：採用・除外・配置・保持tick・イベント。',
 '- frames_24fps/：25枚。対応原画とのRGBA完全一致を検証。',
 '- timeline_24fps.json：原画番号、命中・座標方式のイベント。',
 '- front_kick_preview.gif / selected_contact_sheet.png：原画切り替えプレビューと採用一覧。', '',
 '## 動作確認', '',
 '確認結果はvalidation.txtを参照。実機での指操作は未確認。元イラストには人物の角度・衣装・頭身の差があり、原画の追加や変形をせず自然な候補を選ぶ範囲で調整しています。', '']
(REVIEW/'REPORT.md').write_text('\n'.join(lines),encoding='utf-8')
print('Wrote complete 35-pose review and preserved seven sources')
