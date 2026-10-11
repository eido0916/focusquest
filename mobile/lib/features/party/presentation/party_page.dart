import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/game_controller.dart';
import '../../../core/widgets/quest_widgets.dart';
import '../../diagnosis/presentation/job_portrait.dart';

class PartyPage extends StatefulWidget {
  const PartyPage({super.key, required this.controller});
  final GameController controller;
  @override
  State<PartyPage> createState() => _PartyPageState();
}

class _PartyPageState extends State<PartyPage> {
  final _code = TextEditingController();
  late final TextEditingController _server;
  String? _error;
  bool _working = false;
  String? _initialSessionId;
  bool _returning = false;
  @override
  void initState() {
    super.initState();
    _server = TextEditingController(text: widget.controller.party.serverUrl);
    _initialSessionId = widget.controller.activeFocus?.id;
    widget.controller.addListener(_changed);
  }

  void _changed() {
    if (!mounted) return;
    setState(() {});
    final focus = widget.controller.activeFocus;
    if (!_returning && focus != null && focus.id != _initialSessionId) {
      _returning = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
          Navigator.pop(context);
        }
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    _code.dispose();
    _server.dispose();
    super.dispose();
  }

  Future<void> _act(Future<void> Function() action) async {
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final party = controller.party;
    final started = party.session != null;
    final enabled = !_working && !party.connecting && !controller.busy;
    const statuses = {
      'waiting': '待機中',
      'starting': '開始準備中',
      'focusing': '集中中',
      'succeeded': '達成',
      'failed': '未達成',
      'cancelled': '中断',
      'cannotStart': '開始できませんでした',
      'disconnected': '接続切れ'
    };
    return Scaffold(
        appBar: AppBar(title: const Text('パーティーを組む')),
        body: QuestBackdrop(
            child: ListView(padding: const EdgeInsets.all(20), children: [
          const Text('離れていても、一緒に集中。', style: TextStyle(fontSize: 22)),
          const SizedBox(height: 8),
          const Text('最大4人。リーダーがコードを共有し、仲間が入力して参加します。'),
          const SizedBox(height: 20),
          if (!party.connected) ...[
            if (_server.text.isEmpty || party.serverUrl.isEmpty)
              const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                      'オンライン接続先がまだ設定されていません。サーバー公開後に接続先を設定すると、別々のWi-Fiから参加できます。')),
            ExpansionTile(
                title: const Text('オンライン接続の設定'),
                initiallyExpanded: _server.text.isEmpty,
                children: [
                  TextField(
                      controller: _server,
                      autocorrect: false,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                          labelText: '接続先', hintText: 'wss://…/party'))
                ]),
            const SizedBox(height: 20),
            QuestActionButton(
                label: 'パーティーを作成',
                icon: Icons.group_add,
                onTap: enabled && controller.activeFocus == null
                    ? () => _act(() => party.connect(
                        url: _server.text, member: controller.partyIdentity))
                    : null),
            const SizedBox(height: 28),
            TextField(
                controller: _code,
                maxLength: 6,
                textCapitalization: TextCapitalization.characters,
                autocorrect: false,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[a-zA-Z2-9]'))
                ],
                decoration: const InputDecoration(
                    labelText: 'パーティーコード', hintText: '6文字のコード')),
            QuestActionButton(
                label: 'コードで参加',
                icon: Icons.login,
                onTap: enabled && controller.activeFocus == null
                    ? () => _act(() => party.connect(
                        url: _server.text,
                        member: controller.partyIdentity,
                        joinCode: _code.text))
                    : null),
          ] else ...[
            QuestCard(
                caption: 'パーティーコード',
                child: Column(children: [
                  SelectableText(party.code!,
                      style: const TextStyle(fontSize: 32, letterSpacing: 6)),
                  TextButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(
                            ClipboardData(text: party.code!));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('コードをコピーしました')));
                        }
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('コードをコピー')),
                ])),
            Text('${party.members.length} / 4人',
                style: const TextStyle(fontSize: 20)),
            for (var i = 0; i < 4; i++)
              Card(
                  child: i >= party.members.length
                      ? const ListTile(
                          leading: Icon(Icons.person_add_outlined),
                          title: Text('仲間の参加を待っています'))
                      : ListTile(
                          leading: SizedBox(
                              width: 48,
                              child: JobPortrait(
                                  typeId: party.members[i].characterType,
                                  appearance: party.members[i].appearance,
                                  height: 64)),
                          title: Text(
                              '${party.members[i].name}${party.members[i].id == party.selfId ? '（あなた）' : ''}'),
                          subtitle: Text(
                              '${JobPortrait.roleNames[party.members[i].characterType] ?? '冒険者'}  Lv.${party.members[i].level}'),
                          trailing: Text(started
                              ? statuses[party.members[i].status] ?? '待機中'
                              : party.members[i].ready
                                  ? '準備OK'
                                  : '待機中'))),
            const SizedBox(height: 16),
            if (!started) ...[
              Text('集中時間：${party.minutes}分'),
              if (party.isHost) ...[
                Wrap(spacing: 8, children: [
                  for (final minutes in [15, 30, 45, 60])
                    ChoiceChip(
                        label: Text('$minutes分'),
                        selected: minutes == party.minutes,
                        onSelected:
                            enabled ? (_) => party.setMinutes(minutes) : null)
                ]),
                const Text('時間を変更すると、全員の準備が解除されます。'),
              ],
              const SizedBox(height: 16),
              QuestActionButton(
                  label: party.ready ? '準備を解除' : '準備OK',
                  icon: Icons.check_circle_outline,
                  onTap: enabled
                      ? () => _act(() => controller.prepareParty(!party.ready))
                      : null),
              if (party.isHost)
                QuestActionButton(
                    label: 'みんなで集中を開始',
                    icon: Icons.play_arrow,
                    onTap: enabled &&
                            party.members.length >= 2 &&
                            party.members.every((m) => m.ready)
                        ? () {
                            party.start();
                          }
                        : null)
              else
                const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('全員の準備ができたら、リーダーが開始します。')),
            ] else ...[
              const Text('パーティーで集中中。各自の集中結果とEXPは、それぞれの端末に保存されます。'),
              QuestActionButton(
                  label: '集中画面へ',
                  icon: Icons.timer,
                  onTap: controller.activeFocus != null
                      ? () => Navigator.pop(context)
                      : null),
            ],
            TextButton(
                onPressed: enabled ? () => _act(party.leave) : null,
                child: Text(started ? 'パーティーから退出（集中は継続）' : 'パーティーから退出')),
          ],
          if (_working || party.connecting) const LinearProgressIndicator(),
          if (_error ?? party.error ?? controller.partyStartError
              case final String error)
            Padding(
                padding: const EdgeInsets.all(12),
                child: Text(error,
                    style: const TextStyle(color: Colors.orangeAccent))),
        ])));
  }
}
