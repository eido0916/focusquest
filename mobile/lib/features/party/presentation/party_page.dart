import '../../../core/widgets/game_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/game_controller.dart';
import '../../../core/widgets/quest_widgets.dart';
import '../../../core/widgets/sunlit_widgets.dart';
import '../../../game/runner/pixel_battle_assets.dart';
import '../domain/party_member.dart';
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
    if (_working) return;
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) {
        setState(() => _error = error is StateError
            ? error.message.toString()
            : error is ArgumentError
                ? error.message.toString()
                : '操作を完了できませんでした。再試行してください。');
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _connect({bool join = false}) =>
      _act(() => widget.controller.party.connect(
          url: _server.text,
          member: widget.controller.partyIdentity,
          joinCode: join ? _code.text.trim().toUpperCase() : null));

  Future<void> _settings() => showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
              title: const Text('オンライン接続の設定'),
              content: TextField(
                  controller: _server,
                  autocorrect: false,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                      labelText: '接続先', hintText: 'wss://…/party')),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('閉じる')),
              ]));

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final party = controller.party;
    final enabled = !_working && !party.connecting && !controller.busy;
    final canConnect = enabled &&
        controller.activeFocus == null &&
        !controller.playableAdventureActive;
    return Scaffold(
        appBar: GameAppBar(title: const Text('パーティーを組む'), actions: [
          if (!party.connected)
            IconButton(
                tooltip: '接続設定',
                onPressed: enabled ? _settings : null,
                icon: const Icon(Icons.settings_outlined)),
        ]),
        body: QuestBackdrop(
            child: Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: ListView(
                        key: const Key('party-lobby-list'),
                        padding: const EdgeInsets.all(20),
                        children: [
                          const Text('離れていても、一緒に集中。',
                              style: TextStyle(
                                  fontFamily: 'SunlitSerif', fontSize: 22)),
                          const SizedBox(height: 8),
                          const Text('最大4人。コードを共有して仲間を招待しよう。'),
                          const SizedBox(height: 20),
                          if (!party.connected) ...[
                            if (controller.activeFocus != null)
                              const Text('集中が終わってからパーティーに参加できます。'),
                            QuestCard(
                                caption: '自分で作成する',
                                child: Column(children: [
                                  const Text('パーティーを作成すると、6文字の招待コードが発行されます。'),
                                  const SizedBox(height: 16),
                                  QuestActionButton(
                                      key: const Key('party-create'),
                                      compact: true,
                                      label: 'パーティーを作成',
                                      icon: Icons.group_add,
                                      onTap:
                                          canConnect ? () => _connect() : null),
                                ])),
                            const SizedBox(height: 12),
                            QuestCard(
                                caption: '仲間のパーティーに参加する',
                                child: Column(children: [
                                  TextField(
                                      key: const Key('party-code-input'),
                                      controller: _code,
                                      enabled: canConnect,
                                      maxLength: 6,
                                      textCapitalization:
                                          TextCapitalization.characters,
                                      textInputAction: TextInputAction.go,
                                      autocorrect: false,
                                      enableSuggestions: false,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                            RegExp('[a-zA-Z2-9]')),
                                        TextInputFormatter.withFunction(
                                            (oldValue, newValue) =>
                                                newValue.copyWith(
                                                    text: newValue.text
                                                        .toUpperCase())),
                                      ],
                                      onChanged: (_) =>
                                          setState(() => _error = null),
                                      onSubmitted: (_) {
                                        if (canConnect &&
                                            _code.text.length == 6) {
                                          _connect(join: true);
                                        }
                                      },
                                      decoration: const InputDecoration(
                                          labelText: 'パーティーコード',
                                          hintText: '6文字のコード')),
                                  const SizedBox(height: 8),
                                  QuestActionButton(
                                      key: const Key('party-join'),
                                      compact: true,
                                      label: 'コードで参加',
                                      icon: Icons.login,
                                      onTap:
                                          canConnect && _code.text.length == 6
                                              ? () => _connect(join: true)
                                              : null),
                                ])),
                          ] else ...[
                            QuestCard(
                                caption: 'パーティーコード',
                                child: Column(children: [
                                  SelectableText(party.code!,
                                      key: const Key('party-invite-code'),
                                      style: const TextStyle(
                                          fontSize: 32, letterSpacing: 6)),
                                  TextButton.icon(
                                      key: const Key('party-copy-code'),
                                      onPressed: () async {
                                        await Clipboard.setData(
                                            ClipboardData(text: party.code!));
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                                  content:
                                                      Text('コードをコピーしました')));
                                        }
                                      },
                                      icon: const Icon(Icons.copy),
                                      label: const Text('コードをコピー')),
                                ])),
                            const SizedBox(height: 8),
                            Text('${party.members.length} / 4人',
                                key: const Key('party-member-count'),
                                style: const TextStyle(fontSize: 20)),
                            const SizedBox(height: 12),
                            LayoutBuilder(builder: (context, bounds) {
                              final columns = bounds.maxWidth >= 600 ? 4 : 2;
                              final width =
                                  (bounds.maxWidth - (columns - 1) * 12) /
                                      columns;
                              return Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    for (var i = 0; i < 4; i++)
                                      SizedBox(
                                          width: width,
                                          child: _memberSlot(
                                              i < party.members.length
                                                  ? party.members[i]
                                                  : null,
                                              i)),
                                  ]);
                            }),
                            const SizedBox(height: 20),
                            if (party.session == null) ...[
                              Text('集中時間：${party.minutes}分'),
                              if (party.isHost) ...[
                                Wrap(spacing: 8, children: [
                                  for (final minutes in [15, 30, 45, 60])
                                    ChoiceChip(
                                        label: Text('$minutes分'),
                                        selected: minutes == party.minutes,
                                        onSelected: enabled
                                            ? (_) => party.setMinutes(minutes)
                                            : null),
                                ]),
                                const Text('時間を変更すると、全員の準備が解除されます。'),
                              ],
                              const SizedBox(height: 16),
                              QuestActionButton(
                                  key: const Key('party-ready'),
                                  compact: true,
                                  label: party.ready ? '準備を解除' : '準備OK',
                                  icon: Icons.check_circle_outline,
                                  onTap: enabled
                                      ? () => _act(() =>
                                          controller.prepareParty(!party.ready))
                                      : null),
                              if (party.isHost) ...[
                                const SizedBox(height: 12),
                                QuestActionButton(
                                    key: const Key('party-start'),
                                    compact: true,
                                    label: 'みんなで集中を開始',
                                    icon: Icons.play_arrow,
                                    onTap: enabled &&
                                            party.members.length >= 2 &&
                                            party.members.every((m) => m.ready)
                                        ? () => _act(() async => party.start())
                                        : null),
                                const SizedBox(height: 8),
                                const Text('2〜4人が参加し、全員が準備OKになると開始できます。'),
                              ] else
                                const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text('全員の準備ができたら、リーダーが開始します。')),
                            ] else ...[
                              const Text('パーティーで集中中。集中結果はそれぞれの端末に保存されます。'),
                              QuestActionButton(
                                  label: '集中画面へ',
                                  icon: Icons.timer,
                                  onTap: controller.activeFocus != null
                                      ? () => Navigator.pop(context)
                                      : null),
                            ],
                            TextButton(
                                key: const Key('party-leave'),
                                onPressed:
                                    enabled ? () => _act(party.leave) : null,
                                child: Text(party.session != null
                                    ? 'パーティーから退出（集中は継続）'
                                    : 'パーティーから退出')),
                          ],
                          if (_working || party.connecting) ...[
                            const LinearProgressIndicator(),
                            const SizedBox(height: 12),
                            const Text('パーティーに接続しています。初回は少し時間がかかる場合があります。'),
                          ],
                          if (_error ??
                                  party.error ??
                                  controller.partyStartError
                              case final String error)
                            Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(error,
                                    key: const Key('party-error'),
                                    style: const TextStyle(
                                        color: Colors.orangeAccent))),
                        ])))));
  }

  Widget _memberSlot(PartyMember? member, int index) {
    final party = widget.controller.party;
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
    final character = member == null
        ? null
        : PixelBattleAssets.characterFor(
            member.characterType, member.appearance);
    return SunlitFrame(
        key: Key('party-slot-$index'),
        compact: true,
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          if (member == null)
            const SizedBox(
                height: 72,
                child: Icon(Icons.person_add_outlined,
                    size: 36, color: Colors.white38))
          else
            Image.asset(
                'assets/images/playable_stage/${character!.id}_attack_000.png',
                height: 72,
                width: 72,
                filterQuality: FilterQuality.none),
          Text(member?.name ?? '空き枠',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
              member == null
                  ? '参加を待っています'
                  : '${JobPortrait.roleNames[member.characterType] ?? '冒険者'} Lv.${member.level}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11)),
          const SizedBox(height: 6),
          Text(
              member == null
                  ? '—'
                  : member.id == party.hostId
                      ? 'リーダー${member.id == party.selfId ? '（あなた）' : ''}'
                      : member.id == party.selfId
                          ? 'あなた'
                          : 'メンバー',
              style: const TextStyle(fontSize: 11, color: sunlitGold)),
          if (member != null)
            Text(
                party.session != null
                    ? statuses[member.status] ?? '待機中'
                    : member.ready
                        ? '準備OK'
                        : '待機中',
                style: TextStyle(
                    fontSize: 12,
                    color: member.ready
                        ? const Color(0xffb4e8ca)
                        : Colors.white70)),
        ]));
  }
}
