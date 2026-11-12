# 冒険のオート機能削除

2026-10-30。冒険画面のオートボタン、オートの状態、毎フレームの自動攻撃・自動スキル発動を削除。通常攻撃と技はそれぞれのボタン操作で発動する。

ゲージ満タンのまま待機しても技を自動消費しないこと、手動の技・通常攻撃、一時停止、複数画面サイズのHUDを既存テストで確認する。過去の画像素材は制作履歴として保持。

変更ファイル:
- `mobile/lib/features/playable_stage/presentation/playable_stage_page.dart`
- `mobile/lib/features/playable_stage/presentation/adventure_battle_hud.dart`
- `mobile/test/adventure_battle_hud_test.dart`

最終結果：7件成功、静的解析は指摘なし。オートボタンがないこと、満タンでも自動発動しないこと、手動操作と一時停止を確認。更新コードをコンパイルして起動版へ反映し、ハッシュ一致を検証。
