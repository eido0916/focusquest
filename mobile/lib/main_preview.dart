import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/diagnosis/presentation/diagnosis_screen.dart';

/// Explicitly separate non-persistent UI preview from the production entrypoint.
void main() => runApp(MaterialApp(
    title: 'FocusQuest 診断プレビュー',
    theme: AppTheme.dark,
    home: Builder(
        builder: (context) =>
            DiagnosisScreen(onComplete: (type, name, appearance) async {
              await showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                        title: const Text('診断プレビュー完了'),
                        content: Text(
                            '$name（${type.job}）として旅立ちます。\nこのプレビューではデータを保存しません。'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('閉じる'))
                        ],
                      ));
            }))));
