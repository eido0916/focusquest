import '../../core/widgets/game_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/game_controller.dart';
import '../../core/widgets/quest_widgets.dart';
import 'developer_character_screen.dart';
import 'settings_art.dart';
import 'user_name_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.controller});
  final GameController controller;
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  bool _access = false;
  bool _overlayAccess = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    try {
      final access = await widget.controller.monitor.hasAccess();
      final permissions = await widget.controller.monitor.guardPermissions();
      if (mounted) {
        setState(() {
          _access = access;
          _overlayAccess = permissions?['overlay'] == true;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = '使用状況の確認はAndroid端末で利用できます。');
    }
  }

  Future<void> _resetForDevelopment() async {
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
    if (!mounted || confirmed != true) return;
    await runAction(context, widget.controller.resetForDevelopment);
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Stack(fit: StackFit.expand, children: [
      Image.asset(gameBackground,
          fit: BoxFit.cover, alignment: Alignment.topCenter),
      LayoutBuilder(builder: (context, constraints) {
        final inset =
            constraints.maxWidth > 600 ? 40.0 : constraints.maxWidth * .105;
        final width = (constraints.maxWidth - inset * 2).clamp(0.0, 520.0);
        final unit = (width / 360).clamp(.82, 1.35);
        return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(inset, 12 * unit, inset, 10 * unit),
            child: Center(
                child: SizedBox(
                    width: width,
                    child: DefaultTextStyle(
                      style: TextStyle(
                          color: settingsInk,
                          fontSize: 9.5 * unit,
                          height: 1.35,
                          fontFamily: 'SunlitSerif',
                          fontWeight: FontWeight.w500),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SettingsTitle(unit: unit),
                            SizedBox(height: 10 * unit),
                            SettingsPanel(
                                title: '集中・使用状況設定',
                                icon: Icons.shield_rounded,
                                unit: unit,
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      const Text(
                                          '集中開始後、Focus Quest以外のアプリを開くと警告します。\nホーム画面・ロック画面は対象外です。'),
                                      SizedBox(height: 5 * unit),
                                      const Text(
                                          '警告には「Focus Questに戻る」と「1分だけ使用する」を表示します。\n1分の許可はそのアプリだけに適用され、時間が切れると再び警告します。\n集中タイマーは止まりません。'),
                                      if (_error != null)
                                        Text(_error!,
                                            style: const TextStyle(
                                                color: Color(0xff9e251e))),
                                      SizedBox(height: 8 * unit),
                                      SettingsRule(unit: unit),
                                      _permissionRow(
                                          '使用状況へのアクセス',
                                          Icons.smartphone_rounded,
                                          _access,
                                          () => runAction(context,
                                              controller.monitor.requestAccess),
                                          unit),
                                      SettingsRule(unit: unit),
                                      _permissionRow(
                                          '他のアプリの上に表示',
                                          Icons.grid_view_rounded,
                                          _overlayAccess,
                                          () => runAction(
                                              context,
                                              controller
                                                  .monitor.requestOverlay),
                                          unit),
                                      SettingsRule(unit: unit),
                                      SizedBox(height: 6 * unit),
                                      Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Icon(Icons.error_rounded,
                                                size: 18 * unit,
                                                color: settingsBrown),
                                            SizedBox(width: 6 * unit),
                                            const Expanded(
                                                child: Text(
                                                    '使用状況は端末内だけで確認します。警告や1分の使用だけで\n集中が未達成になることはありません。')),
                                          ]),
                                    ])),
                            SizedBox(height: 10 * unit),
                            SettingsPanel(
                                title: 'サウンド設定',
                                icon: Icons.music_note_rounded,
                                unit: unit,
                                child: Column(children: [
                                  SettingsValueRow(
                                      icon: Icons.music_note_rounded,
                                      label: 'BGM',
                                      value: '準備中',
                                      unit: unit),
                                  SettingsRule(unit: unit),
                                  SettingsValueRow(
                                      icon: Icons.volume_up_rounded,
                                      label: 'SE（効果音）',
                                      value: '準備中',
                                      unit: unit),
                                ])),
                            SizedBox(height: 10 * unit),
                            SettingsPanel(
                                title: 'アカウント・データ',
                                icon: Icons.cloud_outlined,
                                unit: unit,
                                child: Column(children: [
                                  InkWell(
                                      key: const Key('change-user-name'),
                                      onTap: controller.busy ||
                                              controller
                                                      .state?.activeCharacter ==
                                                  null
                                          ? null
                                          : () => showDialog<void>(
                                              context: context,
                                              barrierDismissible: false,
                                              builder: (_) => UserNameDialog(
                                                  controller: controller)),
                                      child: SettingsValueRow(
                                          icon: Icons.person_outline_rounded,
                                          label: 'ユーザー名を変更',
                                          value: controller.state
                                                  ?.activeCharacter?.name ??
                                              '',
                                          unit: unit)),
                                  SettingsRule(unit: unit),
                                  SettingsValueRow(
                                      icon: Icons.smartphone_rounded,
                                      label: '保存先',
                                      value: 'この端末',
                                      unit: unit),
                                  SettingsRule(unit: unit),
                                  SettingsValueRow(
                                      icon: Icons.cloud_outlined,
                                      label: 'クラウド同期',
                                      value: '今後追加予定',
                                      unit: unit),
                                ])),
                            if (kDebugMode) ...[
                              SizedBox(height: 10 * unit),
                              SettingsPanel(
                                  title: '開発者用（仮設）',
                                  icon: Icons.handyman_rounded,
                                  unit: unit,
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        OutlinedButton.icon(
                                            style: OutlinedButton.styleFrom(
                                                foregroundColor: settingsBrown,
                                                side: const BorderSide(
                                                    color: Color(0xffc69c52)),
                                                shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(
                                                        7)),
                                                textStyle: TextStyle(
                                                    fontFamily: 'SunlitSerif',
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 11 * unit)),
                                            onPressed: controller.busy
                                                ? null
                                                : () => Navigator.of(context)
                                                    .push(MaterialPageRoute<void>(
                                                        builder: (_) =>
                                                            DeveloperCharacterScreen(
                                                                controller:
                                                                    controller))),
                                            icon: Icon(Icons.person_rounded,
                                                size: 18 * unit),
                                            label: const Text('職業・性別を選択')),
                                        SizedBox(height: 5 * unit),
                                        const Text(
                                            '保存データを初期化して、最初の役職決めからやり直します。'),
                                        SizedBox(height: 8 * unit),
                                        Center(
                                            child: SizedBox(
                                                width: width * .60,
                                                child: SettingsArtButton(
                                                    label: 'アプリをリセット',
                                                    icon: Icons
                                                        .restart_alt_rounded,
                                                    red: true,
                                                    unit: unit,
                                                    onTap: controller.busy
                                                        ? null
                                                        : _resetForDevelopment))),
                                      ])),
                            ],
                          ]),
                    ))));
      }),
    ]);
  }

  Widget _permissionRow(String label, IconData icon, bool allowed,
          VoidCallback onTap, double unit) =>
      Padding(
          padding: EdgeInsets.symmetric(vertical: 2 * unit),
          child: LayoutBuilder(builder: (context, constraints) {
            final description = Row(children: [
              SettingsMedallion(icon: icon, unit: unit, blue: true),
              SizedBox(width: 10 * unit),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(label,
                        style: TextStyle(
                            fontSize: 12 * unit, fontWeight: FontWeight.bold)),
                    Text(allowed ? '許可済み' : '未許可',
                        style: TextStyle(fontSize: 10 * unit)),
                  ])),
            ]);
            final action = SizedBox(
                width: 108 * unit,
                child: SettingsArtButton(
                    label: '設定を開く', unit: unit, onTap: onTap));
            if (MediaQuery.textScalerOf(context).scale(1) > 1.3 ||
                constraints.maxWidth < 265) {
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [description, const SizedBox(height: 4), action]);
            }
            return Row(children: [
              Expanded(child: description),
              SizedBox(width: 5 * unit),
              action
            ]);
          }));
}
