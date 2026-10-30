import 'package:focusquest/core/widgets/quest_screen_fit.dart';
import 'package:flutter/material.dart';
import '../../core/game_controller.dart';
import '../../core/widgets/quest_widgets.dart';
import 'developer_settings_panel.dart';
import 'settings_art.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen(
      {super.key,
      required this.controller,
      this.onBack,
      this.showDeveloperTools = developerToolsEnabled});
  final GameController controller;
  final VoidCallback? onBack;
  final bool showDeveloperTools;
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
    widget.controller.addListener(_settingsChanged);
    _refresh();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_settingsChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _settingsChanged() {
    if (mounted) setState(() {});
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

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Stack(fit: StackFit.expand, children: [
      Image.asset('${settingsAssetPath}background.png',
          fit: BoxFit.cover, alignment: Alignment.topCenter),
      LayoutBuilder(builder: (context, constraints) {
        final inset =
            constraints.maxWidth > 600 ? 24.0 : constraints.maxWidth * .036;
        final width = (constraints.maxWidth - inset * 2).clamp(0.0, 640.0);
        final unit = (width / 420).clamp(.70, 1.6);
        return QuestScreenFit(
            padding: EdgeInsets.fromLTRB(inset, 12 * unit, inset, 10 * unit),
            child: Center(
                child: SizedBox(
                    width: width,
                    child: DefaultTextStyle(
                      style: TextStyle(
                          color: settingsInk,
                          fontSize: 11.3 * unit,
                          height: 1.35,
                          fontFamily: 'SunlitSerif',
                          fontWeight: FontWeight.w500),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SettingsTitle(unit: unit, onBack: widget.onBack),
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
                                                color: Color(0xffffc390))),
                                      SizedBox(height: 8 * unit),
                                      _permissionRow(
                                          '使用状況へのアクセス',
                                          Icons.smartphone_rounded,
                                          _access,
                                          () => runAction(context,
                                              controller.monitor.requestAccess),
                                          unit),
                                      SizedBox(height: 6 * unit),
                                      _permissionRow(
                                          '他のアプリの上に表示',
                                          Icons.grid_view_rounded,
                                          _overlayAccess,
                                          () => runAction(
                                              context,
                                              controller
                                                  .monitor.requestOverlay),
                                          unit),
                                      SizedBox(height: 6 * unit),
                                      SettingsRow(
                                          unit: unit,
                                          notice: true,
                                          child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                SettingsIcon(
                                                    Icons.error_rounded,
                                                    size: 26 * unit),
                                                SizedBox(width: 6 * unit),
                                                const Expanded(
                                                    child: Text(
                                                        '使用状況は端末内だけで確認します。警告や1分の使用だけで\n集中が未達成になることはありません。')),
                                              ])),
                                    ])),
                            SizedBox(height: 10 * unit),
                            SettingsPanel(
                                title: 'サウンド設定',
                                icon: Icons.music_note_rounded,
                                unit: unit,
                                child: Column(children: [
                                  SettingsSoundRow(
                                      unit: unit,
                                      icon: Icons.music_note_rounded,
                                      label: 'BGM',
                                      value: controller.state!.bgmEnabled,
                                      onChanged: controller.busy
                                          ? null
                                          : (value) => runAction(
                                              context,
                                              () => controller.setSoundSettings(
                                                  bgm: value))),
                                  SizedBox(height: 6 * unit),
                                  SettingsSoundRow(
                                      unit: unit,
                                      icon: Icons.volume_up_rounded,
                                      label: 'SE（効果音）',
                                      value: controller.state!.seEnabled,
                                      onChanged: controller.busy
                                          ? null
                                          : (value) => runAction(
                                              context,
                                              () => controller.setSoundSettings(
                                                  se: value))),
                                ])),
                            SizedBox(height: 10 * unit),
                            SettingsPanel(
                                title: 'アカウント・データ',
                                icon: Icons.cloud_outlined,
                                unit: unit,
                                child: Column(children: [
                                  SettingsValueRow(
                                      icon: Icons.smartphone_rounded,
                                      label: '保存先',
                                      value: 'この端末',
                                      unit: unit),
                                  SizedBox(height: 6 * unit),
                                  SettingsValueRow(
                                      icon: Icons.cloud_outlined,
                                      label: 'クラウド同期',
                                      value: '今後追加予定',
                                      unit: unit),
                                ])),
                            if (widget.showDeveloperTools) ...[
                              SizedBox(height: 10 * unit),
                              DeveloperSettingsPanel(
                                  controller: controller,
                                  unit: unit,
                                  width: width),
                            ],
                          ]),
                    ))));
      }),
    ]);
  }

  Widget _permissionRow(String label, IconData icon, bool allowed,
          VoidCallback onTap, double unit) =>
      SettingsRow(
          unit: unit,
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
                            fontSize: 13 * unit, fontWeight: FontWeight.w600)),
                    Text(allowed ? '許可済み' : '未許可',
                        style: TextStyle(fontSize: 10 * unit)),
                  ])),
            ]);
            final action = SizedBox(
                width: 122 * unit,
                child: SettingsArtButton(
                    label: '設定を開く', unit: unit, onTap: onTap));
            if (MediaQuery.textScalerOf(context).scale(1) > 1.3 ||
                constraints.maxWidth < 270 * unit) {
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
