import '../../../core/config/game_balance.dart';
import '../../../game/runner/fantasy_battle_hud.dart';
import '../../playable_stage/domain/playable_stage_catalog.dart';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flame/cache.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../focus/domain/focus_session.dart';
import '../data/party_connection.dart';
import '../domain/party_member.dart';
import '../../../game/runner/pixel_battle_assets.dart';
import '../../../game/runner/background_component.dart';
import '../../../game/runner/enemy_motion_assets.dart';
import '../../focus/domain/focus_adventure.dart';
import '../../../game/runner/role_skill_effects.dart';

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
                                    onPressed: () => showDialog<void>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                                title: const Text('集中メニュー'),
                                                content: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      const Text('参加コード'),
                                                      SelectableText(
                                                          widget.party?.code ??
                                                              'コードを取得できません',
                                                          style:
                                                              const TextStyle(
                                                                  fontSize:
                                                                      28)),
                                                      const Text(
                                                          '接続が切れた場合は、このコードを入力して復帰できます。')
                                                    ]),
                                                actions: [
                                                  TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context),
                                                      child:
                                                          const Text('戦闘に戻る')),
                                                  TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                        _return();
                                                      },
                                                      child: const Text(
                                                          'パーティー・集中メニューへ'))
                                                ])),
                                    icon: const Icon(Icons.undo),
                                    label: const Text('メニュー'))),
                          ])))))));
}

/// Every player animation frame is a completed v013 original, drawn at 128×128.
/// Only world coordinates move. Elapsed time deterministically selects poses.
class PartyBattleGame extends FlameGame {
  PartyBattleGame(
      {required this.session,
      required this.clock,
      required this.onFinished,
      this.party}) {
    images = Images();
  }
  final FocusSession session;
  final DateTime Function() clock;
  final VoidCallback onFinished;
  final PartyConnection? party;
  ui.Image? _background;

  EnemyMotionAssets? _bossAssets;
  final Map<String, Map<String, _OriginalMotion>> _actors = {};
  final Map<String, RoleSkillEffects> _effects = {};
  bool _reported = false;
  double _finishAge = 0;
  String? loadError;
  final Map<String, ui.Image> _roleLogos = {};
  String actorKey(PartyMember member) {
    final hero =
        PixelBattleAssets.characterFor(member.characterType, member.appearance);
    return '${hero.female ? 'players_female' : 'players'}/${hero.id}';
  }

  @override
  Color backgroundColor() => const Color(0xff142b23);
  @override
  Future<void> onLoad() async {
    try {
      _background = await images.load(
          FocusAdventure.background(0, areaIndex: session.focusAreaIndex));

      _bossAssets = await EnemyMotionAssets.load(this);
      for (final type
          in session.partyMembers.map((m) => m.characterType).toSet()) {
        _roleLogos[type] = await images.load('role_logos/$type.png');
        _effects[type] = await RoleSkillEffects.load(type,
            (path) => images.load(path.replaceFirst('assets/images/', '')));
      }
      final catalog = jsonDecode(
              await rootBundle.loadString('assets/images/party/catalog.json'))
          as Map<String, dynamic>;
      final keys = {
        for (final member in session.partyMembers) actorKey(member),
        'enemies/slime',
        'enemies/goblin'
      };
      await Future.wait(keys.map((key) async {
        if (!key.startsWith('enemies/')) {
          final member =
              session.partyMembers.firstWhere((m) => actorKey(m) == key);
          final assets = await PixelBattleAssets.load(
              this, member.characterType, member.appearance);
          _actors[key] = {
            for (final entry in assets.motions.entries)
              entry.key:
                  _OriginalMotion(entry.value.metadata, entry.value.images),
          };
          return;
        }
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
      loadError = '原画を読み込めませんでした。集中は続いています。メニューから戻って再試行してください。';
    }
  }

  double get elapsed =>
      session.focusNow(clock()).difference(session.startedAt).inMilliseconds /
      1000;
  @override
  void update(double dt) {
    super.update(dt);
    if (elapsed >= session.durationMinutes * 60) _finishAge += dt;
    final end = session.adventureStartSeconds + session.durationMinutes * 60;
    final bossJustDefeated = end >= 1800 && end % 1800 == 0;
    if (!_reported &&
        elapsed >= session.durationMinutes * 60 &&
        (!bossJustDefeated || _finishAge >= 1.3)) {
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
    final time = elapsed.clamp(0.0, session.durationMinutes * 60.0).toDouble();
    final adventureTime = session.adventureStartSeconds + time;
    final bossBattle = FocusAdventure.fightingBoss(adventureTime);
    final bossLeft = (1800 - FocusAdventure.age(adventureTime)).ceil();
    final background = _background;
    if (background != null) {
      BackgroundComponent.paintScenery(canvas, background);
    }
    canvas.drawRect(const Rect.fromLTWH(0, 0, 960, 80),
        Paint()..color = const Color(0xdd10231c));
    final remaining = (session.durationMinutes * 60 - time).ceil();
    _text(
        canvas,
        '第${session.focusAreaIndex + 1}章 · ${FocusAdventure.area(adventureTime, areaIndex: session.focusAreaIndex)} · ${session.partyMembers.length}人パーティー',
        20,
        12,
        width: 400,
        size: 23,
        color: const Color(0xffffdd98));
    _text(
        canvas,
        '経過 ${FantasyBattleHud.clockText(time.floor())}  ·  残り ${FantasyBattleHud.clockText(remaining)}  ·  EXP ${GameBalance.focusExpForSeconds(time, durationSeconds: session.durationMinutes * 60.0)} / ${session.durationMinutes * GameBalance.expPerMinute}',
        20,
        48,
        width: 570,
        size: 17);
    if (bossBattle && (party == null || party!.connected)) {
      _text(
          canvas,
          'BOSS · ${FocusAdventure.bossName(adventureTime, areaIndex: session.focusAreaIndex)} · 撃破まで ${FantasyBattleHud.clockText(bossLeft)}',
          620,
          48,
          width: 320,
          size: 13);
    }
    if (elapsed < 0) {
      _text(canvas, '${(-elapsed).ceil()}秒後に一緒に開始', 450, 20,
          width: 280, size: 23);
    }
    if (party != null && !party!.connected) {
      _text(canvas, '接続切れ · 集中は継続中', 600, 48,
          width: 340, color: Colors.orangeAccent);
    }

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
      final logo = _roleLogos[member.characterType];
      if (logo != null) {
        paintImage(
            canvas: canvas,
            rect: Rect.fromLTWH(20, y - 77, 32, 32),
            image: logo,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high);
      }
      _text(canvas, member.name, 58, y - 75,
          width: 112, size: 19, color: const Color(0xffffdd98));
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
      final attack = actor?[skillWave ? 'skill' : 'attack'];
      final attackDuration = attack?.duration ?? 1;
      final hitAt = 2 + attackDuration;
      if (actor != null) {
        final moving = age < 2 || age >= hitAt;
        final motion = moving ? actor['run']! : attack!;
        motion.paint(canvas, Offset(220, y - 114),
            moving ? age % motion.duration : age - 2);
      }
      final mobIds = session.focusAreaIndex < 0
          ? ['slime', 'goblin']
          : {
              for (final stage in PlayableStageCatalog.stages
                  .skip(session.focusAreaIndex * 4)
                  .take(4))
                for (final enemy in stage.opponents)
                  if (!enemy.isBoss) enemy.id
            }.toList();
      final mobId = mobIds[i % mobIds.length];
      final enemy = _actors['enemies/$mobId'];
      if (enemy != null && !bossBattle) {
        final defeated = age >= hitAt;
        final motion = enemy[defeated ? 'defeat' : 'locomotion']!;
        if (!defeated || age - hitAt < motion.duration) {
          final x = age < 2 ? 800 - age * 135 : 530.0;
          motion.paint(canvas, Offset(x, y - 114),
              defeated ? age - hitAt : age % motion.duration);
        }
      }
      if (enemy == null && _bossAssets != null && !bossBattle) {
        final defeated = age >= hitAt;
        final frame = _bossAssets!.frame(mobId,
            defeated ? 'defeat' : 'locomotion', defeated ? age - hitAt : age,
            loop: !defeated);
        final x = age < 2 ? 800 - age * 135 : 530.0;
        canvas.drawImage(
            frame.image,
            Offset(x + frame.offset.dx, y - 114 + frame.offset.dy),
            Paint()..filterQuality = FilterQuality.none);
      }
      if (skillWave && age >= 2 && age < hitAt && attack != null) {
        final character = PixelBattleAssets.characterFor(
            member.characterType, member.appearance);
        final events = (attack.data['events'] as List)
            .where((e) => e['event'] == character.skillEvent)
            .map((e) => (e['tick'] as num).toDouble() / 24)
            .toList();
        _effects[member.characterType]?.paint(canvas,
            origin: Offset(284, y) + attack.offsetAt(age - 2),
            viewport: Rect.fromLTWH(0, y - 96, 960, 100),
            age: age - 2,
            duration: attackDuration,
            releases: events,
            logicalPixel: 1);
      }
    }
    final chapterAge = FocusAdventure.age(adventureTime);
    final defeatingBoss =
        adventureTime >= 1800 && chapterAge < 1.25 && time > 0;
    if ((bossBattle || defeatingBoss) && _bossAssets != null) {
      final id = FocusAdventure.bossId(
          defeatingBoss ? adventureTime - chapterAge - 1 : adventureTime,
          areaIndex: session.focusAreaIndex);
      final bossAge = bossBattle
          ? chapterAge - 1500
          : (chapterAge == 0 ? _finishAge : chapterAge);
      final action = defeatingBoss
          ? 'defeat'
          : bossAge % 4 >= 3
              ? 'attack'
              : 'locomotion';
      final frame = _bossAssets!.frame(
          id,
          action,
          defeatingBoss
              ? bossAge
              : action == 'attack'
                  ? bossAge % 4 - 3
                  : bossAge,
          loop: !defeatingBoss);
      canvas.drawImageRect(
          frame.image,
          Rect.fromLTWH(0, 0, frame.image.width.toDouble(),
              frame.image.height.toDouble()),
          Rect.fromLTWH(
              540 + frame.offset.dx * 3, 90 + frame.offset.dy * 3, 384, 384),
          Paint()..filterQuality = FilterQuality.none);
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
  Map holdAt(double age) {
    var tick = (age * (data['fps'] as num)).floor();
    Map hold = holds.last as Map;
    for (final item in holds) {
      hold = item as Map;
      if (tick < (hold['ticks'] as num)) break;
      tick -= (hold['ticks'] as num).toInt();
    }
    return hold;
  }

  Offset offsetAt(double age) {
    final offset = holdAt(age)['root_offset_px'] as List? ?? [0, 0];
    return Offset((offset[0] as num).toDouble(), (offset[1] as num).toDouble());
  }

  void paint(Canvas canvas, Offset position, double age) {
    final hold = holdAt(age);
    canvas.drawImage(frames[(hold['keyframe'] as num).toInt()],
        position + offsetAt(age), Paint()..filterQuality = FilterQuality.none);
  }
}
