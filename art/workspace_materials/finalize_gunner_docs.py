from pathlib import Path
import json
ROOT=Path(__file__).resolve().parent;OUT=ROOT/'FocusQuest_pixel_keyframes_v010'
readme=OUT/'README.md'
s=readme.read_text(encoding='utf-8')
prefix='# FocusQuest 原画ドット絵アニメーション v010\n\ncharacter_09 ガンナー男女版を追加。各版に走行8原画・単発射撃8原画・早撃ち12原画（3発）を収録。128×128透過PNG、24fps原画保持方式。既存v009素材は維持。詳細はGUNNER_V010.md、プレビューはindex.html、新規制作元はsource/gunner_v010。\n\n'
if not s.startswith(prefix):readme.write_text(prefix+s,encoding='utf-8')
agents=ROOT/'AGENTS.md';s=agents.read_text(encoding='utf-8')
s=s.replace('現行素材は `FocusQuest_pixel_keyframes_v009/`','現行素材は `FocusQuest_pixel_keyframes_v010/`')
if 'v010で8.png' not in s:
 s+='\n- v010で8.png・女.png右下を基準にcharacter_09ガンナーの男女版を追加。各版は走行8原画・停止単発射撃8原画・停止早撃ち12原画。早撃ちは20tickで3発、発射tickは7・10・13。男性・女性・敵の既存素材はv009と同一。全原画128×128透過・補間なし。\n'
agents.write_text(s,encoding='utf-8')
print('Updated v010 delivery notes and current production policy.')
