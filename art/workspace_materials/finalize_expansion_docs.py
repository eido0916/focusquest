from pathlib import Path
ROOT=Path(__file__).resolve().parent;OUT=ROOT/'FocusQuest_pixel_keyframes_v013'
p=OUT/'README.md';s=p.read_text(encoding='utf-8');prefix='# FocusQuest 原画ドット絵アニメーション v013\n\n追加ボス5体・雑魚敵5体、移動・攻撃・被弾・撃破の計40動作・170原画。128×128透過・左向き・24fps原画保持。v012の既存素材は保持。詳細ENEMIES_V013.md、プレビューindex.html、新作制作元source/enemies_v013。\n\n'
if not s.startswith(prefix):p.write_text(prefix+s,encoding='utf-8')
p=ROOT/'AGENTS.md';s=p.read_text(encoding='utf-8').replace('現行素材は `FocusQuest_pixel_keyframes_v012/`','現行素材は `FocusQuest_pixel_keyframes_v013/`')
if 'v013で追加ボス5体' not in s:s+='\n- v013で追加ボス5体（リッチ・ミノタウロス・石のゴーレム・ケルベロス・魔王）と雑魚敵5体（コウモリ・狼・スケルトン・毒キノコ・インプ）を追加。各体は移動4原画・攻撃4原画・被弾4原画・撃破5原画（透明1枚含む）。全コマ左向き、原画保持。雑魚敵の表示サイズはボスより小さい。v012の既存素材は保持。\n'
p.write_text(s,encoding='utf-8');print('Updated v013 delivery documentation and production policy.')
