import 'package:flutter/material.dart';
import '../../core/game_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/quest_widgets.dart';
import '../focus/data/usage_monitor.dart';
import '../focus/domain/focus_session.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.controller});
  final GameController controller;
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  bool _access = false;
  List<InstalledApp> _apps = [];
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
      final apps = await widget.controller.monitor.apps();
      if (mounted) {
        setState(() {
          _access = access;
          _apps = apps;
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
    final state = controller.state!;
    return ListView(
        padding: const EdgeInsets.fromLTRB(14, 18, 14, 24),
        children: [
          const QuestCard(
              child: Row(children: [
            Icon(Icons.settings_rounded, size: 31),
            SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('設定',
                  style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              Text('冒険を、より快適に', style: TextStyle(fontSize: 12)),
            ]),
          ])),
          _Section(
              title: '集中・使用状況設定',
              icon: Icons.shield_rounded,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                        '選んだアプリが集中中に開かれたかを端末内だけで確認します。許可しなくてもタイマーは使えます。'),
                    const SizedBox(height: 10),
                    if (_error != null)
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    Row(children: [
                      Expanded(
                          child:
                              Text('使用状況へのアクセス：${_access ? '許可済み' : '未許可'}')),
                      OutlinedButton(
                          onPressed: () => runAction(
                              context, controller.monitor.requestAccess),
                          child: const Text('設定を開く')),
                    ]),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('対象アプリの使用を確認'),
                      subtitle: const Text('集中中に選択アプリを開くと未達成になります'),
                      value: state.monitoring,
                      onChanged:
                          controller.busy || controller.activeFocus != null
                              ? null
                              : (enabled) => runAction(context, () async {
                                    if (enabled && !_access) {
                                      throw StateError(
                                          '先にAndroid設定でアクセスを許可してください。');
                                    }
                                    await controller.configureMonitoring(
                                        enabled, state.targetPackages);
                                  }),
                    ),
                    for (final app in _apps)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(app.name),
                        value: state.targetPackages.contains(app.package),
                        onChanged: controller.busy ||
                                controller.activeFocus != null
                            ? null
                            : (selected) => runAction(context, () async {
                                  final packages = {...state.targetPackages};
                                  if (selected == true) {
                                    packages.add(app.package);
                                  } else {
                                    packages.remove(app.package);
                                  }
                                  await controller.configureMonitoring(
                                      packages.isEmpty
                                          ? false
                                          : state.monitoring,
                                      packages.toList());
                                }),
                      ),
                  ])),
          const _Section(
              title: 'サウンド設定',
              icon: Icons.music_note_rounded,
              child: Column(children: [
                _DisplaySetting(
                    icon: Icons.music_note_rounded, label: 'BGM', value: '準備中'),
                Divider(color: Color(0xffb79a62), height: 1),
                _DisplaySetting(
                    icon: Icons.graphic_eq_rounded,
                    label: 'SE（効果音）',
                    value: '準備中'),
              ])),
          const _Section(
              title: 'アカウント・データ',
              icon: Icons.cloud_outlined,
              child: Column(children: [
                _DisplaySetting(
                    icon: Icons.smartphone_rounded,
                    label: '保存先',
                    value: 'この端末'),
                Divider(color: Color(0xffb79a62), height: 1),
                _DisplaySetting(
                    icon: Icons.cloud_off_rounded,
                    label: 'クラウド同期',
                    value: '今後追加予定'),
              ])),
          _Section(
              title: '集中履歴',
              icon: Icons.history_rounded,
              child: Column(children: [
                if (state.sessions.isEmpty)
                  const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('まだ集中履歴はありません。')),
                for (final session
                    in state.sessions.values.toList().reversed.take(50))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                        session.status == FocusStatus.succeeded
                            ? Icons.check_circle
                            : Icons.timelapse,
                        color: const Color(0xff96722e)),
                    title: Text('${session.durationMinutes}分 • ${{
                      FocusStatus.active: '集中中',
                      FocusStatus.succeeded: '達成',
                      FocusStatus.failed: '未達成',
                      FocusStatus.cancelled: '中断'
                    }[session.status]}'),
                    subtitle: Text(
                        '${session.startedAt.toLocal()}\n${session.verification == FocusVerification.usageStats ? '使用状況確認' : 'タイマーのみ'}'),
                  ),
              ])),
        ]);
  }
}

class _Section extends StatelessWidget {
  const _Section(
      {required this.title, required this.icon, required this.child});
  final String title;
  final IconData icon;
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: const BoxDecoration(
              color: Color(0xee082744),
              border:
                  Border(bottom: BorderSide(color: AppTheme.gold, width: 2))),
          child: Row(children: [
            Icon(icon),
            const SizedBox(width: 10),
            Text(title,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.bold))
          ]),
        ),
        QuestCard(
            parchment: true,
            child: Theme(
              data: Theme.of(context).copyWith(
                textTheme: Theme.of(context)
                    .textTheme
                    .apply(bodyColor: AppTheme.ink, displayColor: AppTheme.ink),
                listTileTheme: const ListTileThemeData(
                    textColor: AppTheme.ink, iconColor: Color(0xff8d6a2d)),
                iconTheme: const IconThemeData(color: Color(0xff8d6a2d)),
              ),
              child: DefaultTextStyle.merge(
                  style: const TextStyle(color: AppTheme.ink), child: child),
            )),
      ]);
}

class _DisplaySetting extends StatelessWidget {
  const _DisplaySetting(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        Icon(icon),
        const SizedBox(width: 14),
        Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold))),
        Text(value),
      ]));
}
