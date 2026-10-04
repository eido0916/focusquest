import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/diagnosis/presentation/diagnosis_screen.dart';

/// Explicitly separate non-persistent UI preview from the production entrypoint.
void main() => runApp(MaterialApp(
    title: 'FocusQuest 診断プレビュー',
    theme: AppTheme.dark,
    home: Builder(
        builder: (context) => DiagnosisScreen(onComplete: (type) async {
              await showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                        title: const Text('診断プレビュー完了'),
                        content:
                            Text('${type.job}を選択しました。\nこのプレビューではデータを保存しません。'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('閉じる'))
                        ],
                      ));
            }))));
