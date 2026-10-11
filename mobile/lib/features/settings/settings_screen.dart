import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/game_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/quest_widgets.dart';

import '../focus/domain/focus_session.dart';
import 'developer_character_screen.dart';

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
              ],
            ));
    if (!mounted || confirmed != true) return;
    await runAction(context, widget.controller.resetForDevelopment);
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
                        '集中開始後、Focus Quest以外のアプリを開くと警告します。ホーム画面・ロック画面は対象外です。'),
                    const SizedBox(height: 10),
                    const Text(
                        '警告には「Focus Questに戻る」と「1分だけ使用する」を表示します。1分の許可はそのアプリだけに適用され、時間が切れると再び警告します。集中タイマーは止まりません。'),
                    if (_error != null)
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('使用状況へのアクセス'),
                      subtitle: Text(_access ? '許可済み' : '未許可'),
                      trailing: OutlinedButton(
                          onPressed: () => runAction(
                              context, controller.monitor.requestAccess),
                          child: const Text('設定を開く')),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('他のアプリの上に表示'),
                      subtitle: Text(_overlayAccess ? '許可済み' : '未許可'),
                      trailing: OutlinedButton(
                          onPressed: () => runAction(
                              context, controller.monitor.requestOverlay),
                          child: const Text('設定を開く')),
                    ),
                    const Text(
                        '使用状況は端末内だけで確認します。警告や1分の使用だけで集中が未達成になることはありません。'),
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
          // Temporary developer tools; remove with their controller methods.
          if (kDebugMode)
            _Section(
                title: '開発者用（仮設）',
                icon: Icons.developer_mode_rounded,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OutlinedButton.icon(
                          onPressed: controller.busy
                              ? null
                              : () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                      builder: (_) => DeveloperCharacterScreen(
                                          controller: controller))),
                          icon: const Icon(Icons.manage_accounts_rounded),
                          label: const Text('職業・性別を選択')),
                      const SizedBox(height: 12),
                      const Text('保存データを初期化して、最初の役職決めからやり直します。'),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                          onPressed:
                              controller.busy ? null : _resetForDevelopment,
                          icon: const Icon(Icons.restart_alt_rounded),
                          label: const Text('アプリをリセット')),
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
