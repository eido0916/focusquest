import 'dart:math' as math;
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../focus/domain/focus_session.dart';
import '../data/party_connection.dart';
import '../domain/party_member.dart';

class PartyBattlePage extends StatefulWidget {
  const PartyBattlePage(
      {super.key, required this.session, required this.clock, this.party});
  final FocusSession session;
  final DateTime Function() clock;
  final PartyConnection? party;
  @override
  State<PartyBattlePage> createState() => _PartyBattlePageState();
}

class _PartyBattlePageState extends State<PartyBattlePage> {
  late final PartyBattleGame _game;
  bool _returned = false;
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    _game = PartyBattleGame(
        session: widget.session,
        clock: widget.clock,
        onFinished: () =>
            WidgetsBinding.instance.addPostFrameCallback((_) => _return()),
        party: widget.party);
  }

  void _return() {
    if (mounted && !_returned) {
      _returned = true;
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _game.pauseEngine();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
          child: LayoutBuilder(
              builder: (context, box) => RotatedBox(
                  quarterTurns: box.maxHeight > box.maxWidth ? 1 : 0,
                  child: Center(
                      child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Stack(children: [
                            Positioned.fill(child: GameWidget(game: _game)),
                            Positioned(
                                top: 4,
                                right: 8,
                                child: TextButton.icon(
                                    onPressed: _return,
                                    icon: const Icon(Icons.undo),
                                    label: const Text('タイマーに戻る'))),
                          ])))))));
}

/// Every animation frame is a completed v010 original, drawn at 128×128.
/// Only world coordinates move. Elapsed time deterministically selects poses.
class PartyBattleGame extends FlameGame {
  PartyBattleGame(
      {required this.session,
      required this.clock,
      required this.onFinished,
      this.party});
  final FocusSession session;
  final DateTime Function() clock;
  final VoidCallback onFinished;
  final PartyConnection? party;
  ui.Image? _background;
  final Map<String, Map<String, _OriginalMotion>> _actors = {};
  bool _reported = false;
  String? loadError;
  static const roleNumbers = {
    'warrior': 1,
    'boxer': 2,
    'samurai': 3,
    'guardian': 4,
    'ninja': 5,
    'assassin': 6,
    'ranger': 7,
    'mage': 8,
    'gunner': 9,
    'spellblade': 1,
    'onmyoji': 8,
    'reaper': 3,
    'angel': 8,
    'devil': 8,
    'dragon_knight': 4,
    'berserker': 1
  };
  static const attacks = [
    'attack_down',
    'punch_combo',
    'iai',
    'slam',
    'shuriken',
    'dagger_thrust',
    'bow_shot',
    'fire_cast',
    'gun_shot'
  ];
  static const skills = [
    'skill_wave',
    'spin_kick',
    'energy_flurry',
    'charged_sweep',
    'teleport_stab',
    'critical_strike',
    'rapid_shot',
    'ice_burst',
    'quick_fire'
  ];
  String actorKey(PartyMember member) {
    final number =
        (roleNumbers[member.characterType] ?? 1).toString().padLeft(2, '0');
    return member.appearance == 'female'
        ? 'players_female/character_${number}_female'
        : 'players/character_$number';
  }

  @override
  Color backgroundColor() => const Color(0xff142b23);
  @override
  Future<void> onLoad() async {
    try {
      _background = await images.load('ui/forest_meadow_battlefield.png');
      final catalog = jsonDecode(
              await rootBundle.loadString('assets/images/party/catalog.json'))
          as Map<String, dynamic>;
      final keys = {
        for (final member in session.partyMembers) actorKey(member),
        'enemies/slime',
        'enemies/goblin'
      };
      await Future.wait(keys.map((key) async {
        final motions = Map<String, dynamic>.from(catalog[key] as Map);
        _actors[key] = {};
        final names = key.startsWith('enemies/')
            ? ['locomotion', 'defeat']
            : motions.keys.where((m) => m != 'idle');
        await Future.wait(names.map((name) async {
          final data = Map<String, dynamic>.from(motions[name] as Map);
          final frames = await Future.wait<ui.Image>((data['keyframes'] as List)
              .map(
                  (frame) => images.load('party/$key/$name/${frame['file']}')));
          _actors[key]![name] = _OriginalMotion(data, frames);
        }));
      }));
    } catch (_) {
      loadError = '原画を読み込めませんでした。タイマー画面で集中を続けられます。';
    }
  }

  double get elapsed =>
      session.focusNow(clock()).difference(session.startedAt).inMilliseconds /
      1000;
  @override
  void update(double dt) {
    super.update(dt);
    if (!_reported && elapsed >= session.durationMinutes * 60) {
      _reported = true;
      onFinished();
    }
  }

  void _text(Canvas canvas, String text, double x, double y,
      {double size = 18, Color color = Colors.white, double width = 180}) {
    final painter = TextPainter(
        text: TextSpan(
            text: text,
            style: TextStyle(
                fontFamily: 'SunlitSerif', fontSize: size, color: color)),
        maxLines: 1,
        ellipsis: '…',
        textDirection: TextDirection.ltr)
      ..layout(maxWidth: width);
    painter.paint(canvas, Offset(x, y));
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.save();
    canvas.scale(size.x / 960, size.y / 540);
    final background = _background;
    if (background != null) {
      canvas.drawImageRect(
          background,
          Rect.fromLTWH(
              0, 0, background.width.toDouble(), background.height.toDouble()),
          const Rect.fromLTWH(0, 0, 960, 540),
          Paint());
    }
    canvas.drawRect(const Rect.fromLTWH(0, 0, 960, 80),
        Paint()..color = const Color(0xdd10231c));
    final remaining = session.remaining(clock()).inSeconds;
    _text(canvas, '${session.partyMembers.length}人の集中パーティー', 20, 12,
        width: 400, size: 23, color: const Color(0xffffdd98));
    _text(
        canvas,
        '残り ${remaining ~/ 60}:${(remaining % 60).toString().padLeft(2, '0')}  ·  敵 ${session.partyMembers.length}体 / wave',
        20,
        48,
        width: 600,
        size: 17);
    if (elapsed < 0) {
      _text(canvas, '${(-elapsed).ceil()}秒後に一緒に開始', 450, 20,
          width: 280, size: 23);
    }
    if (party != null && !party!.connected) {
      _text(canvas, '接続切れ · 集中は継続中', 600, 48,
          width: 340, color: Colors.orangeAccent);
    }
    final time = math.max(0.0, elapsed);
    final wave = time ~/ 6;
    final age = time % 6;
    final skillWave = wave % 4 == 3;
    for (var i = 0; i < session.partyMembers.length; i++) {
      final member = session.partyMembers[i];
      final y = 182.0 + i * 104;
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(12, y - 88, 390, 94), const Radius.circular(10)),
          Paint()..color = const Color(0x6610231c));
      _text(canvas, member.name, 22, y - 75,
          width: 148, size: 19, color: const Color(0xffffdd98));
      _text(canvas, 'Lv.${member.level}', 22, y - 42, width: 140, size: 15);
      final live = party?.members.where((m) => m.id == member.id).firstOrNull;
      final status = live?.status;
      if (status == 'disconnected' ||
          status == 'cancelled' ||
          status == 'cannotStart') {
        _text(canvas, status == 'disconnected' ? '接続切れ' : '離脱', 22, y - 18,
            size: 13, color: Colors.orangeAccent);
      }
      final actor = _actors[actorKey(member)];
      final number = (roleNumbers[member.characterType] ?? 1) - 1;
      final attack = actor?[skillWave ? skills[number] : attacks[number]];
      final attackDuration = attack?.duration ?? 1;
      final hitAt = 2 + attackDuration;
      if (actor != null) {
        final moving = age < 2 || age >= hitAt;
        final motion = moving ? actor['run']! : attack!;
        motion.paint(canvas, Offset(220, y - 114),
            moving ? age % motion.duration : age - 2);
      }
      final enemy = _actors[i.isEven ? 'enemies/slime' : 'enemies/goblin'];
      if (enemy != null) {
        final defeated = age >= hitAt;
        final motion = enemy[defeated ? 'defeat' : 'locomotion']!;
        if (!defeated || age - hitAt < motion.duration) {
          final x = age < 2 ? 800 - age * 135 : 530.0;
          motion.paint(canvas, Offset(x, y - 114),
              defeated ? age - hitAt : age % motion.duration);
        }
      }
    }
    if (loadError != null) {
      _text(canvas, loadError!, 220, 270,
          width: 700, color: Colors.orangeAccent);
    }
    canvas.restore();
  }
}

class _OriginalMotion {
  _OriginalMotion(this.data, this.frames);
  final Map<String, dynamic> data;
  final List<ui.Image> frames;
  List get holds => data['holds'] as List;
  double get duration =>
      holds.fold<double>(0, (sum, h) => sum + (h['ticks'] as num).toDouble()) /
      (data['fps'] as num);
  void paint(Canvas canvas, Offset position, double age) {
    var tick = (age * (data['fps'] as num)).floor();
    Map hold = holds.last as Map;
    for (final item in holds) {
      hold = item as Map;
      if (tick < (hold['ticks'] as num)) break;
      tick -= (hold['ticks'] as num).toInt();
    }
    final offset = hold['root_offset_px'] as List? ?? [0, 0];
    canvas.drawImage(
        frames[(hold['keyframe'] as num).toInt()],
        position +
            Offset(
                (offset[0] as num).toDouble(), (offset[1] as num).toDouble()),
        Paint()..filterQuality = FilterQuality.none);
  }
}
