import 'dart:convert';
import 'dart:async';
import '../../../core/game_controller.dart';
import '../../focus/presentation/focus_audio.dart';
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
      {super.key,
      required this.session,
      required this.clock,
      this.party,
      this.controller});
  final GameController? controller;
  final FocusSession session;
  final DateTime Function() clock;
  final PartyConnection? party;
  @override
  State<PartyBattlePage> createState() => _PartyBattlePageState();
}

class _PartyBattlePageState extends State<PartyBattlePage> {
  late final PartyBattleGame _game;
  late final FocusAudio _audio;
  bool _returned = false;
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    _audio = FocusAudio(controller: widget.controller);
    _game = PartyBattleGame(
        onAudioFrame: _audio.update,
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
    unawaited(_audio.close());
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(child: LayoutBuilder(builder: (context, box) {
        return RotatedBox(
          quarterTurns: box.maxHeight > box.maxWidth ? 1 : 0,
          child: Center(
              child: AspectRatio(
            aspectRatio: 16 / 9,
            child: LayoutBuilder(builder: (context, surface) {
              final unit = surface.maxWidth / 960;
              return Stack(fit: StackFit.expand, children: [
                GameWidget(game: _game),
                if (widget.controller != null)
                  Positioned(
                      top: 7 * unit,
                      right: 173 * unit,
                      width: 42 * unit,
                      height: 48 * unit,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        tooltip: 'サウンド設定',
                        icon: Icon(Icons.volume_up,
                            color: Colors.white, size: 24 * unit),
                        onPressed: () =>
                            showFocusSoundSettings(context, widget.controller!),
                      )),
                Positioned(
                    top: 7 * unit,
                    right: 16 * unit,
                    width: 156 * unit,
                    height: 48 * unit,
                    child: TextButton(
                      onPressed: _return,
                      style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 5 * unit),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      child: const FittedBox(
                          child: Row(children: [
                        Icon(Icons.undo_rounded, size: 25),
                        SizedBox(width: 7),
                        Text('タイマーに戻る',
                            style: TextStyle(
                                fontFamily: 'SunlitSerif', fontSize: 18)),
                      ])),
                    )),
              ]);
            }),
          )),
        );
      })));
}

/// Every player animation frame is a completed v013 original, drawn at 128×128.
/// Only world coordinates move. Elapsed time deterministically selects poses.
class PartyBattleGame extends FlameGame {
  PartyBattleGame(
      {required this.session,
      required this.clock,
      required this.onFinished,
      this.party,
      this.onAudioFrame}) {
    images = Images();
  }
  final FocusSession session;
  final DateTime Function() clock;
  final VoidCallback onFinished;
  final void Function(double time,
      {required bool boss,
      required bool active,
      required List<FocusSoundPose> poses})? onAudioFrame;
  final PartyConnection? party;
  ui.Image? _background;
  ui.Image? _ghostShip;
  EnemyMotionAssets? _bossAssets;
  final Map<String, Map<String, _OriginalMotion>> _actors = {};
  final Map<String, RoleSkillEffects> _effects = {};
  bool _reported = false;
  double _finishAge = 0;
  String? loadError;
  final Map<String, ui.Image> _roleLogos = {};
  final Map<String, ui.Image> _portraits = {};
  ui.Image? _headerFrame, _memberFrame, _compass;
  String portraitKey(PartyMember member) =>
      '${member.appearance}/${member.characterType}';
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
      _background = await images.load(BackgroundComponent.asset);
      _ghostShip =
          await images.load('stage_backgrounds/ghost_ship_focus_v002.png');
      _bossAssets = await EnemyMotionAssets.load(this);
      _headerFrame = await images.load('party_focus_v001/header_frame.png');
      _memberFrame = await images.load('party_focus_v001/member_frame.png');
      _compass = await images.load('party_focus_v001/compass.png');
      for (final member in session.partyMembers) {
        final key = portraitKey(member);
        _portraits[key] ??=
            await images.load('focus_selection_v001/avatars/$key.png');
      }
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
      loadError = '原画を読み込めませんでした。タイマー画面で集中を続けられます。';
    }
  }

  double get elapsed =>
      session.focusNow(clock()).difference(session.startedAt).inMilliseconds /
      1000;
  @override
  void update(double dt) {
    super.update(dt);
    final time = elapsed.clamp(0.0, session.durationMinutes * 60.0).toDouble();
    final wave = time ~/ 6;
    final age = time % 6 - 2;
    final skill = wave % 4 == 3;
    final poses = <FocusSoundPose>[];
    for (var i = 0; i < session.partyMembers.length; i++) {
      final member = session.partyMembers[i];
      final motion = _actors[actorKey(member)]?[skill ? 'skill' : 'attack'];
      if (motion == null || age < 0 || age >= motion.duration) continue;
      final character = PixelBattleAssets.characterFor(
          member.characterType, member.appearance);
      final events = focusSoundTimes(
          motion.data, skill ? character.skillEvent : character.attackEvent);
      poses.add(
          FocusSoundPose('$i', member.characterType, wave, skill, age, events));
    }
    onAudioFrame?.call(time,
        boss: FocusAdventure.fightingBoss(session.adventureStartSeconds + time),
        active: elapsed >= 0 && elapsed < session.durationMinutes * 60,
        poses: poses);
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

  void _frame(Canvas canvas, ui.Image? image, Rect rect) {
    if (image == null) return;
    canvas.drawImageNine(
        image,
        Rect.fromLTRB(32, 32, image.width - 32.0, image.height - 32.0),
        rect,
        Paint()..filterQuality = FilterQuality.high);
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
    final background =
        FocusAdventure.chapter(adventureTime) == 2 ? _ghostShip : _background;
    if (background != null) {
      BackgroundComponent.paintScenery(canvas, background);
    }
    _frame(canvas, _headerFrame, const Rect.fromLTWH(3, 2, 954, 72));
    if (_compass != null) {
      canvas.drawImage(_compass!, const Offset(13, 10), Paint());
    }
    final remaining = session.remaining(clock()).inSeconds;
    _text(
        canvas,
        '第${FocusAdventure.chapter(adventureTime)}章 · ${FocusAdventure.area(adventureTime)} · ${session.partyMembers.length}人パーティー',
        64,
        10,
        width: 655,
        size: 23,
        color: const Color(0xffffdd98));
    _text(
        canvas,
        bossBattle
            ? 'BOSS · ${FocusAdventure.bossName(adventureTime)} · 撃破まで ${bossLeft ~/ 60}:${(bossLeft % 60).toString().padLeft(2, '0')}'
            : '残り ${remaining ~/ 60}:${(remaining % 60).toString().padLeft(2, '0')}  ·  敵 ${session.partyMembers.length}体 / wave ${time ~/ 6 + 1}',
        64,
        46,
        width: 600,
        size: 17);
    if (elapsed < 0) {
      _text(canvas, '${(-elapsed).ceil()}秒後に一緒に開始', 420, 46,
          width: 280, size: 23);
    }
    if (party != null && !party!.connected) {
      _text(canvas, '接続切れ · 集中は継続中', 600, 46,
          width: 340, color: Colors.orangeAccent);
    }

    final wave = time ~/ 6;
    final age = time % 6;
    final skillWave = wave % 4 == 3;
    for (var i = 0; i < session.partyMembers.length; i++) {
      final member = session.partyMembers[i];
      final cardTop = 84.0 + i * 76;
      _frame(canvas, _memberFrame, Rect.fromLTWH(5, cardTop, 175, 72));
      final portrait = _portraits[portraitKey(member)];
      if (portrait != null) {
        // Existing 64 logical pixel portrait, at its original logical size.
        canvas.drawImageRect(
            portrait,
            const Rect.fromLTWH(0, 0, 128, 128),
            Rect.fromLTWH(34, cardTop + 4, 64, 64),
            Paint()..filterQuality = FilterQuality.none);
      }
      final logo = _roleLogos[member.characterType];
      if (logo != null) {
        paintImage(
            canvas: canvas,
            rect: Rect.fromLTWH(12, cardTop + 12, 28, 36),
            image: logo,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high);
      }
      _text(canvas, member.name, 101, cardTop + 12, width: 70, size: 16);
      _text(canvas, 'Lv.${member.level}', 101, cardTop + 38,
          width: 70, size: 15);
      final live = party?.members.where((m) => m.id == member.id).firstOrNull;
      final status = live?.status;
      if (status == 'disconnected' ||
          status == 'cancelled' ||
          status == 'cannotStart') {
        _text(
            canvas, status == 'disconnected' ? '接続切れ' : '離脱', 101, cardTop + 56,
            width: 70, size: 10, color: Colors.orangeAccent);
      }
      // Two rows on the battlefield, independent of the portrait sidebar.
      // Positions are world coordinates; completed original frames never deform.
      final column = i % 2;
      final row = i ~/ 2;
      final y = (session.partyMembers.length <= 2 ? 380.0 : 332.0) + row * 100;
      final heroX = 210.0 + column * 144;
      final enemyX = 638.0 + column * 136;
      final actor = _actors[actorKey(member)];
      final attack = actor?[skillWave ? 'skill' : 'attack'];
      final attackDuration = attack?.duration ?? 1;
      final hitAt = 2 + attackDuration;
      if (actor != null) {
        final moving = age < 2 || age >= hitAt;
        final motion = moving ? actor['run']! : attack!;
        motion.paint(canvas, Offset(heroX, y - 114),
            moving ? age % motion.duration : age - 2);
      }
      final enemy = _actors[i.isEven ? 'enemies/slime' : 'enemies/goblin'];
      if (enemy != null && !bossBattle) {
        final defeated = age >= hitAt;
        final motion = enemy[defeated ? 'defeat' : 'locomotion']!;
        if (!defeated || age - hitAt < motion.duration) {
          final x = age < 2 ? enemyX + (2 - age) * 55 : enemyX;
          motion.paint(canvas, Offset(x, y - 114),
              defeated ? age - hitAt : age % motion.duration);
        }
      }
      if (skillWave && age >= 2 && age < hitAt && attack != null) {
        final character = PixelBattleAssets.characterFor(
            member.characterType, member.appearance);
        final events = (attack.data['events'] as List)
            .where((e) => e['event'] == character.skillEvent)
            .map((e) => (e['tick'] as num).toDouble() / 24)
            .toList();
        _effects[member.characterType]?.paint(canvas,
            origin: Offset(heroX + 64, y) + attack.offsetAt(age - 2),
            viewport: Rect.fromLTWH(heroX, y - 96, 960 - heroX, 100),
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
          defeatingBoss ? adventureTime - chapterAge - 1 : adventureTime);
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
          const Rect.fromLTWH(0, 0, 128, 128),
          Rect.fromLTWH(
              660 + frame.offset.dx * 2, 180 + frame.offset.dy * 2, 256, 256),
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
