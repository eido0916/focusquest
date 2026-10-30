import 'package:flutter/material.dart';
import '../../core/game_controller.dart';
import '../../core/widgets/quest_widgets.dart';
import 'developer_character_screen.dart';
import 'settings_art.dart';

/// Disable the entire temporary section with
/// --dart-define=FOCUSQUEST_DEVELOPER_TOOLS=false.
const developerToolsEnabled = bool.fromEnvironment('FOCUSQUEST_DEVELOPER_TOOLS',
    defaultValue: true);

/// Temporary tools live here so the settings integration can be removed at once.
class DeveloperSettingsPanel extends StatelessWidget {
  const DeveloperSettingsPanel(
      {super.key,
      required this.controller,
      required this.unit,
      required this.width});
  final GameController controller;
  final double unit;
  final double width;

  Future<void> _resetForDevelopment(BuildContext context) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('アプリをリセットしますか？'),
                content: const Text('キャラクター・進行・集中履歴・アプリ内設定を初期化し、最初の役職決めに戻ります。'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('キャンセル')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('リセットする')),
                ]));
    if (!context.mounted || confirmed != true) return;
    await runAction(context, controller.resetForDevelopment);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: controller,
      builder: (context, _) => SettingsPanel(
          title: '開発者用（仮設）',
          icon: Icons.handyman_rounded,
          unit: unit,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                    foregroundColor: settingsBrown,
                    side: const BorderSide(color: Color(0xffc69c52)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7)),
                    textStyle: TextStyle(
                        fontFamily: 'SunlitSerif',
                        fontWeight: FontWeight.bold,
                        fontSize: 11 * unit)),
                onPressed: controller.busy
                    ? null
                    : () => Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) =>
                            DeveloperCharacterScreen(controller: controller))),
                icon: Icon(Icons.person_rounded, size: 18 * unit),
                label: const Text('職業・性別を選択')),
            SizedBox(height: 5 * unit),
            const Text('保存データを初期化して、最初の役職決めからやり直します。'),
            SizedBox(height: 8 * unit),
            Center(
                child: SizedBox(
                    width: width * .60,
                    child: SettingsArtButton(
                        label: 'アプリをリセット',
                        icon: Icons.restart_alt_rounded,
                        red: true,
                        unit: unit,
                        onTap: controller.busy
                            ? null
                            : () => _resetForDevelopment(context)))),
          ])));
}
