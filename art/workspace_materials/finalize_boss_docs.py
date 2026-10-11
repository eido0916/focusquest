from pathlib import Path
ROOT=Path(__file__).resolve().parent;OUT=ROOT/'FocusQuest_pixel_keyframes_v012'
p=OUT/'source/verify_saved.py';p.write_text(p.read_text(encoding='utf-8').replace('FocusQuest_pixel_keyframes_v011.zip','FocusQuest_pixel_keyframes_v012.zip'),encoding='utf-8')
p=OUT/'README.md';s=p.read_text(encoding='utf-8');prefix='# FocusQuest 原画ドット絵アニメーション v012\n\nボス4体（ゴブリンキング・サイクロプス・デュラハン・火竜）に移動、攻撃、被弾、撃破を追加。16動作・132原画、左向き128×128透過PNG、24fps原画保持。v011の既存素材は保持。詳細BOSSES_V012.md、プレビューindex.html、新作制作元source/bosses_v012。\n\n'
if not s.startswith(prefix):p.write_text(prefix+s,encoding='utf-8')
p=ROOT/'AGENTS.md';s=p.read_text(encoding='utf-8').replace('現行素材は `FocusQuest_pixel_keyframes_v011/`','現行素材は `FocusQuest_pixel_keyframes_v012/`')
if 'v012でボス4体' not in s:s+='\n- v012でボス4体（ゴブリンキング・サイクロプス・騎乗デュラハン・火竜）をenemies配下へ追加。各体は移動8原画・攻撃8原画・被弾8原画・撃破9原画（最後は透明）。全コマ左向き。火竜は木装飾を外した火炎ブレス。被弾は右へ最大12px、撃破は44pxのワールド座標ノックバック。v011の既存素材は変更しない。\n'
p.write_text(s,encoding='utf-8')
print('Updated v012 delivery and verification configuration.')
