import 'package:flutter/material.dart';
import '../../diagnosis/presentation/job_portrait.dart';
import '../domain/party_member.dart';

const lobbyGold = Color(0xffeac982);
const lobbyWhite = Color(0xfffff8e9);
const lobbyTitle = TextStyle(
    fontFamily: 'SunlitSerif',
    color: lobbyWhite,
    fontSize: 23,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.5);
const lobbyBody = TextStyle(
    fontFamily: 'SunlitSerif', color: lobbyWhite, fontSize: 14, height: 1.5);

class LobbyPanel extends StatelessWidget {
  const LobbyPanel(
      {super.key,
      required this.child,
      this.asset = 'panel',
      this.padding = const EdgeInsets.all(18)});
  final Widget child;
  final String asset;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Stack(children: [
        Positioned.fill(
            child: Image.asset('assets/images/party_lobby_v001/$asset.png',
                fit: BoxFit.fill, excludeFromSemantics: true)),
        Padding(padding: padding, child: child),
      ]);
}

class LobbyCompass extends StatelessWidget {
  const LobbyCompass({super.key, this.size = 42});
  final double size;
  @override
  Widget build(BuildContext context) =>
      Image.asset('assets/images/party_lobby_v001/compass.png',
          width: size, height: size, excludeFromSemantics: true);
}

class LobbyAction extends StatelessWidget {
  const LobbyAction(
      {super.key, required this.label, required this.icon, this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Opacity(
      opacity: onTap == null ? .55 : 1,
      child: LobbyPanel(
          asset: 'action',
          padding: EdgeInsets.zero,
          child: Material(
              color: Colors.transparent,
              child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 22),
                      child: Row(children: [
                        const LobbyCompass(size: 34),
                        const SizedBox(width: 12),
                        Icon(icon, color: lobbyWhite, size: 26),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text(label,
                                textAlign: TextAlign.center,
                                style: lobbyTitle.copyWith(fontSize: 20))),
                        const Icon(Icons.chevron_right,
                            color: lobbyWhite, size: 26),
                      ]))))));
}

class LobbyMemberCard extends StatelessWidget {
  const LobbyMemberCard(
      {super.key,
      this.member,
      this.selfId,
      this.hostId,
      required this.started});
  final PartyMember? member;
  final String? selfId, hostId;
  final bool started;
  static const statuses = {
    'waiting': '待機中',
    'starting': '開始準備中',
    'focusing': '集中中',
    'succeeded': '達成',
    'failed': '未達成',
    'cancelled': '中断',
    'cannotStart': '開始できませんでした',
    'disconnected': '接続切れ'
  };
  @override
  Widget build(BuildContext context) {
    final actor = member;
    return LobbyPanel(
        asset: 'member',
        padding: const EdgeInsets.all(5),
        child: actor == null
            ? SizedBox(
                height: 268,
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: lobbyGold.withOpacity(.8))),
                          child: const Icon(Icons.add,
                              color: lobbyGold, size: 34)),
                      const SizedBox(height: 16),
                      Text('仲間の参加を\n待っています',
                          textAlign: TextAlign.center,
                          style: lobbyBody.copyWith(fontSize: 11)),
                    ]))
            : Column(children: [
                SizedBox(
                    height: 22,
                    child: actor.id == hostId
                        ? Image.asset(
                            'assets/images/party_lobby_v001/crown.png',
                            width: 25,
                            excludeFromSemantics: true)
                        : null),
                JobPortrait(
                    typeId: actor.characterType,
                    appearance: actor.appearance,
                    lobby: true,
                    height: 144,
                    alignment: Alignment.bottomCenter),
                const Divider(color: lobbyGold, height: 10),
                Text(actor.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: lobbyBody.copyWith(
                        fontSize: 13, fontWeight: FontWeight.bold)),
                Text(
                    actor.id == selfId
                        ? 'あなた'
                        : actor.id == hostId
                            ? 'リーダー'
                            : '仲間',
                    style: lobbyBody.copyWith(fontSize: 10, color: lobbyGold)),
                Text(JobPortrait.roleNames[actor.characterType] ?? '冒険者',
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style: lobbyBody.copyWith(fontSize: 11)),
                Text('Lv.${actor.level}',
                    style: lobbyBody.copyWith(fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                    started
                        ? statuses[actor.status] ?? '待機中'
                        : actor.ready
                            ? '準備OK'
                            : '待機中',
                    textAlign: TextAlign.center,
                    style: lobbyBody.copyWith(
                        fontSize: 10,
                        color:
                            actor.ready ? const Color(0xffa9f0c6) : lobbyGold)),
                const SizedBox(height: 7),
              ]));
  }
}
