from pathlib import Path
ROOT=Path(__file__).resolve().parent;OUT=ROOT/'FocusQuest_pixel_keyframes_v011'
readme=OUT/'README.md';s=readme.read_text(encoding='utf-8')
prefix='# FocusQuest 原画ドット絵アニメーション v011\n\ncharacter_10 魔剣士男女版を追加。各版に走行8原画・停止斬撃8原画・雷剣から前方への落雷12原画を収録。男性10.png・女性女2.png上段左から2体目を参照。128×128透過、24fps原画保持方式。既存v010素材は保持。詳細MAGIC_V011.md、プレビューindex.html、新作制作元source/magic_v011。\n\n'
if not s.startswith(prefix):readme.write_text(prefix+s,encoding='utf-8')
agents=ROOT/'AGENTS.md';s=agents.read_text(encoding='utf-8').replace('現行素材は `FocusQuest_pixel_keyframes_v010/`','現行素材は `FocusQuest_pixel_keyframes_v011/`')
if 'v011で10.png' not in s:s+='\n- v011で10.png・女2.png上段左から2体目を基準にcharacter_10魔剣士の男女版を追加。各版に走行8原画・停止斬撃8原画・蓄電雷剣と前方落雷12原画。雷スキル36tick、蓄電開始tick9、雷剣攻撃tick20、落雷tick22。男性・女性・敵の既存素材はv010と同一。全原画128×128透過・補間なし。\n'
agents.write_text(s,encoding='utf-8')
print('Updated v011 documentation and production policy.')
