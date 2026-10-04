# FocusQuest Android

ログインなしで遊べる端末内保存版です。
通常起動は `lib/main.dart`、保存なし診断プレビューは `lib/main_preview.dart`。

[環境構築・実機起動・Firebase後続工程・Git運用・素材差替え](../README.md)
および[実装・検証計画](../docs/IMPLEMENTATION.md)を参照してください。

```
flutter analyze --no-pub
flutter test --no-pub
flutter build apk --debug --target-platform android-arm64
flutter run
```
