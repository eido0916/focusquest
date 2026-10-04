import 'package:flutter/material.dart';
import '../../core/game_controller.dart';
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
    return ListView(padding: const EdgeInsets.all(16), children: [
      QuestCard(
          caption: 'さくせん・集中の設定',
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text(
                '選んだアプリが集中中に開かれたかを確認します。アプリを強制終了したり、操作をブロックしたりはしません。使用履歴は端末内で判定し、外部へ送信しません。'),
            const SizedBox(height: 12),
            const Text('許可しなくてもタイマーを使えます。確認機能を使う場合、集中中の権限取消や確認不能は未達成になります。'),
            if (_error != null) Text(_error!),
            Text('使用状況へのアクセス：${_access ? '許可済み' : '未許可'}'),
            TextButton(
                onPressed: () =>
                    runAction(context, controller.monitor.requestAccess),
                child: const Text('Androidの使用状況設定を開く')),
            SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('対象アプリの使用を確認'),
                value: state.monitoring,
                onChanged: controller.busy || controller.activeFocus != null
                    ? null
                    : (enabled) => runAction(context, () async {
                          if (enabled && !_access) {
                            throw StateError('先にAndroid設定でアクセスを許可してください。');
                          }
                          await controller.configureMonitoring(
                              enabled, state.targetPackages);
                        })),
            for (final app in _apps)
              CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(app.name),
                  value: state.targetPackages.contains(app.package),
                  onChanged: controller.busy || controller.activeFocus != null
                      ? null
                      : (selected) => runAction(context, () async {
                            final packages = {...state.targetPackages};
                            if (selected == true) {
                              packages.add(app.package);
                            } else {
                              packages.remove(app.package);
                            }
                            await controller.configureMonitoring(
                                packages.isEmpty ? false : state.monitoring,
                                packages.toList());
                          })),
          ])),
      const QuestCard(
          child: Text('保存先：この端末\nログインとクラウド同期は今後追加予定です。アプリの削除やデータ消去で記録が失われます。')),
      Text('集中履歴', style: Theme.of(context).textTheme.titleLarge),
      for (final session in state.sessions.values.toList().reversed.take(50))
        ListTile(
            title: Text('${session.durationMinutes}分 • ${{
              FocusStatus.active: '集中中',
              FocusStatus.succeeded: '達成',
              FocusStatus.failed: '未達成',
              FocusStatus.cancelled: '中断'
            }[session.status]}'),
            subtitle: Text(
                '${session.startedAt.toLocal()}\n${session.verification == FocusVerification.usageStats ? '使用状況確認' : 'タイマーのみ'}')),
    ]);
  }
}
