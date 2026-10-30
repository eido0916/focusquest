import 'party_lobby_scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/game_controller.dart';
import 'party_lobby_art.dart';
import 'party_entry_scene.dart';

class PartyPage extends StatefulWidget {
  const PartyPage({super.key, required this.controller});
  final GameController controller;
  @override
  State<PartyPage> createState() => _PartyPageState();
}

class _PartyPageState extends State<PartyPage> {
  final _code = TextEditingController();
  String? _error, _initialSessionId;
  bool _working = false, _returning = false;
  @override
  void initState() {
    super.initState();
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

  Future<void> _copyCode() async {
    final code = widget.controller.party.code;
    if (code == null) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('コードをコピーしました')));
    }
  }

  Future<void> _disband() async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              backgroundColor: const Color(0xff0b2340),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: lobbyGold)),
              title: const Text('パーティーを解散しますか？', style: lobbyTitle),
              content: Text(
                  widget.controller.party.session == null
                      ? '全員がパーティーから退出し、このコードは使えなくなります。'
                      : '全員がパーティーから退出し、このコードは使えなくなります。開始済みの集中は各端末で継続します。',
                  style: lobbyBody),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('キャンセル')),
                TextButton(
                    key: const Key('party-disband-confirm'),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('解散する')),
              ],
            ));
    if (confirmed == true && mounted) {
      await _act(widget.controller.party.disband);
    }
  }

  Future<void> _join() async {
    _code.text = widget.controller.party.code ?? '';
    final submit = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(builder: (context, update) {
              final valid = RegExp(r'^[A-Z2-9]{6}$')
                  .hasMatch(_code.text.trim().toUpperCase());
              return AlertDialog(
                  backgroundColor: const Color(0xff0b2340),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: lobbyGold)),
                  title: const Text('パーティーコード', style: lobbyTitle),
                  content: TextField(
                      key: const Key('party-code-input'),
                      controller: _code,
                      autofocus: true,
                      maxLength: 6,
                      style: lobbyTitle.copyWith(letterSpacing: 5),
                      textCapitalization: TextCapitalization.characters,
                      autocorrect: false,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp('[a-zA-Z2-9]')),
                        TextInputFormatter.withFunction((oldValue, newValue) =>
                            newValue.copyWith(
                                text: newValue.text.toUpperCase()))
                      ],
                      onChanged: (_) => update(() {}),
                      onSubmitted: (_) {
                        if (valid) Navigator.pop(context, true);
                      },
                      decoration: const InputDecoration(
                          hintText: '6文字のコード', helperText: 'リーダーから届いたコードを入力')),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('キャンセル')),
                    TextButton(
                        onPressed:
                            valid ? () => Navigator.pop(context, true) : null,
                        key: const Key('party-join-submit'),
                        child: const Text('参加する')),
                  ]);
            }));
    if (submit == true && mounted) {
      await _act(() => widget.controller.party.connect(
          url: widget.controller.party.serverUrl,
          member: widget.controller.partyIdentity,
          joinCode: _code.text));
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final party = controller.party;

    final enabled = !_working && !party.connecting && !controller.busy;
    final canConnect = enabled;
    final canCreate = enabled && controller.activeFocus == null;

    if (!party.connected) {
      return Scaffold(
          backgroundColor: const Color(0xff1699ff),
          body: PartyEntryScene(
              onBack: () => Navigator.maybePop(context),
              onCreate: canCreate
                  ? () => _act(() => party.connect(
                      url: party.serverUrl, member: controller.partyIdentity))
                  : null,
              onJoin: canConnect ? _join : null,
              connecting: _working || party.connecting,
              reconnecting: controller.activeFocus != null,
              error: _error ?? party.error ?? controller.partyStartError));
    }
    return PartyLobbyScene(
        party: party,
        enabled: enabled,
        working: _working || party.connecting,
        onBack: () => Navigator.maybePop(context),
        onCopy: _copyCode,
        onLeave: () => _act(party.leave),
        onDisband: _disband,
        onFocus: controller.activeFocus != null
            ? () => Navigator.pop(context)
            : null,
        error: _error ?? party.error ?? controller.partyStartError);
  }
}
