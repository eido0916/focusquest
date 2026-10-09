# Phase 1〜3：実装ファイル全文

差分ではなく、今回の戦闘実装ファイルの全文です。

> これはPhase 1〜3実装時点の記録です。現在の正本は`mobile/lib/`です。旧「冒険」機能との併存部分は、その後の集中ループ統合で削除されています。

## mobile/lib/game/runner/battle_state_controller.dart

```dart
enum BattlePhase {
  running,
  normalBattle,
  skill,
  bossIntro,
  bossBattle,
  bossDefeat,
  resumeRun,
  finished
}

enum HeroMotion { idle, run, attack, skill, bossAttack, victory }

enum EnemyPhase { spawn, move, hit, defeat }

class EnemyData {
  const EnemyData(this.id, {this.expReward = 10});
  final String id;
  final int expReward;
}

class RunnerConfig {
  const RunnerConfig(
      {this.spawnSeconds = .55,
      this.attackSeconds = .55,
      this.enemySpeed = 230,
      this.enemies = const [EnemyData('slime'), EnemyData('goblin')]});
  final double spawnSeconds;
  final double attackSeconds;
  final double enemySpeed;
  final List<EnemyData> enemies;
}

class RunnerEnemy {
  RunnerEnemy(this.id, this.data, {this.x = 1000});
  final int id;
  final EnemyData data;
  double x;
  double age = 0;
  double hitAge = 0;
  EnemyPhase phase = EnemyPhase.spawn;
}

class BattleResultData {
  const BattleResultData(
      {required this.elapsedTime,
      required this.defeatedCount,
      required this.gainedExp,
      this.bossDefeatedCount = 0,
      this.gachaCount = 0});
  final Duration elapsedTime;
  final int defeatedCount;
  final int gainedExp;
  final int bossDefeatedCount;
  final int gachaCount;
}

/// Fixed-step, deterministic simulation. Rendering never awards player rewards.
/// Replaying elapsed focus time restores identical enemies and counters after sleep.
class BattleStateController {
  BattleStateController(
      {this.config = const RunnerConfig(), required this.durationSeconds}) {
    if (durationSeconds <= 0 ||
        config.spawnSeconds <= 0 ||
        config.attackSeconds <= 0 ||
        config.enemySpeed <= 0 ||
        config.enemies.isEmpty) {
      throw ArgumentError(
          'Battle configuration must be positive and include enemies.');
    }
  }
  final RunnerConfig config;
  final double durationSeconds;
  final List<RunnerEnemy> enemies = [];
  BattlePhase phase = BattlePhase.running;
  double elapsedSeconds = 0;
  int defeatedCount = 0;
  int gainedExp = 0;
  int attackSerial = 0;
  int _spawned = 0;
  int _ticks = 0;
  double _spawnTimer = 0;
  double _attackTimer = 0;
  double attackAge = 1;
  static const step = .05;
  HeroMotion get motion => phase == BattlePhase.finished
      ? HeroMotion.victory
      : attackAge < .22
          ? HeroMotion.attack
          : HeroMotion.run;
  void advanceTo(double seconds) {
    final target = seconds.clamp(elapsedSeconds, durationSeconds).toDouble();
    final targetTicks = (target / step + 1e-7).floor();
    while (_ticks < targetTicks) {
      _tick();
      _ticks++;
    }
    elapsedSeconds = target;
    if (target >= durationSeconds) phase = BattlePhase.finished;
  }

  void _tick() {
    _spawnTimer += step;
    _attackTimer += step;
    attackAge += step;
    if (_spawnTimer + 1e-7 >= config.spawnSeconds) {
      _spawnTimer -= config.spawnSeconds;
      enemies.add(RunnerEnemy(
          _spawned, config.enemies[_spawned % config.enemies.length]));
      _spawned++;
    }
    for (final enemy in enemies) {
      enemy.age += step;
      if (enemy.phase == EnemyPhase.hit || enemy.phase == EnemyPhase.defeat) {
        enemy.hitAge += step;
        enemy.x += step * 150;
        if (enemy.hitAge > .12) enemy.phase = EnemyPhase.defeat;
      } else {
        enemy.phase = EnemyPhase.move;
        enemy.x = (enemy.x - config.enemySpeed * step).clamp(280, 1100);
      }
    }
    if (_attackTimer + 1e-7 >= config.attackSeconds) {
      for (final enemy in enemies) {
        if (enemy.phase == EnemyPhase.move && enemy.x <= 350) {
          enemy.phase = EnemyPhase.hit;
          defeatedCount++;
          gainedExp += enemy.data.expReward;
          attackAge = 0;
          attackSerial++;
          _attackTimer = 0;
          break;
        }
      }
    }
    enemies.removeWhere((enemy) => enemy.hitAge > .5);
    phase = attackAge < .22 ? BattlePhase.normalBattle : BattlePhase.running;
  }

  BattleResultData get result => BattleResultData(
      elapsedTime: Duration(milliseconds: (elapsedSeconds * 1000).round()),
      defeatedCount: defeatedCount,
      gainedExp: gainedExp);
}
```

## mobile/lib/game/runner/background_component.dart

```dart
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'battle_state_controller.dart';

class BackgroundComponent extends Component {
  BackgroundComponent(this.state);
  final BattleStateController state;
  @override
  void render(Canvas canvas) {
    final p = Paint();
    canvas.drawRect(
        const Rect.fromLTWH(0, 0, 960, 540),
        p
          ..shader = const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xff64bce4), Color(0xffe4f3d0)])
              .createShader(const Rect.fromLTWH(0, 0, 960, 540)));
    p.shader = null;
    canvas.drawCircle(
        const Offset(760, 100), 43, p..color = const Color(0xffffefbc));
    for (var layer = 0; layer < 3; layer++) {
      final speed = [9.0, 22.0, 55.0][layer];
      final offset = state.elapsedSeconds * speed % 360;
      p.color = [
        const Color(0xff8bbec3),
        const Color(0xff6aa6a0),
        const Color(0xff427b62)
      ][layer];
      for (var i = -1; i < 5; i++) {
        final x = i * 360 - offset;
        final y = 270.0 + layer * 52;
        canvas.drawPath(
            Path()
              ..moveTo(x, 410)
              ..lineTo(x + 160, y - 95)
              ..lineTo(x + 360, 410)
              ..close(),
            p);
      }
    }
    final castleX = 800 - state.elapsedSeconds * 12 % 1200;
    p.color = const Color(0xffd6ddcf);
    canvas.drawRect(Rect.fromLTWH(castleX, 215, 80, 110), p);
    for (var i = 0; i < 3; i++) {
      canvas.drawRect(Rect.fromLTWH(castleX + i * 32 - 10, 188, 20, 135), p);
      canvas.drawPath(
          Path()
            ..moveTo(castleX + i * 32 - 15, 188)
            ..lineTo(castleX + i * 32, 155)
            ..lineTo(castleX + i * 32 + 15, 188)
            ..close(),
          Paint()..color = const Color(0xff527a9d));
    }
    canvas.drawRect(const Rect.fromLTWH(0, 402, 960, 138),
        p..color = const Color(0xff72a55a));
    canvas.drawRect(const Rect.fromLTWH(0, 455, 960, 85),
        p..color = const Color(0xffa8b875));
    for (var i = 0; i < 35; i++) {
      final x = (i * 41 - state.elapsedSeconds * 145) % 1000;
      final y = 432.0 + (i % 4) * 25;
      canvas.drawLine(
          Offset(x, y),
          Offset(x + 12, y - 6),
          p
            ..color = const Color(0xff568649)
            ..strokeWidth = 2);
      if (i % 5 == 0) {
        canvas.drawCircle(Offset(x + 4, y - 7), 2 + math.sin(i).abs(),
            p..color = const Color(0xffffebad));
      }
    }
  }
}
```

## mobile/lib/game/runner/hero_component.dart

```dart
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'battle_state_controller.dart';

class HeroComponent extends Component {
  HeroComponent(this.state);
  final BattleStateController state;
  @override
  void render(Canvas canvas) {
    final c = canvas;
    final t = state.elapsedSeconds;
    final run = state.motion == HeroMotion.run;
    final attack = state.motion == HeroMotion.attack;
    final p = Paint();
    c.drawOval(
        const Rect.fromLTWH(166, 426, 94, 16), p..color = Colors.black26);
    c.save();
    c.translate(
        210 + (attack ? math.sin(state.attackAge / .22 * math.pi) * 18 : 0),
        378 + (run ? math.sin(t * 20) * 3 : 0));
    c.drawPath(
        Path()
          ..moveTo(-13, -27)
          ..lineTo(-48, 34 + math.sin(t * 12) * 5)
          ..lineTo(16, 24)
          ..close(),
        p..color = const Color(0xff246797));
    p
      ..color = const Color(0xff44372e)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    final stride = run ? math.sin(t * 14) * 16 : 5.0;
    c.drawLine(const Offset(-8, 20), Offset(-8 - stride, 49), p);
    c.drawLine(const Offset(9, 20), Offset(9 + stride, 49), p);
    c.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(-19, -29, 40, 57), const Radius.circular(5)),
        p..color = const Color(0xffe5e4ca));
    c.drawRect(const Rect.fromLTWH(-19, 13, 40, 7),
        p..color = const Color(0xff8b6940));
    c.drawCircle(const Offset(0, -48), 19, p..color = const Color(0xffedc196));
    c.drawArc(const Rect.fromLTWH(-22, -70, 42, 38), math.pi, math.pi + .45,
        true, p..color = const Color(0xff674633));
    c.drawCircle(const Offset(10, -48), 2, p..color = const Color(0xff233c48));
    c.save();
    c.translate(17, -12);
    c.rotate(attack ? -.9 + state.attackAge * 10 : -.3);
    c.drawLine(
        Offset.zero,
        const Offset(25, 7),
        p
          ..color = const Color(0xffedc196)
          ..strokeWidth = 10);
    c.drawLine(
        const Offset(25, 7),
        const Offset(32, -55),
        p
          ..color = const Color(0xfff5fcff)
          ..strokeWidth = 6);
    c.drawLine(
        const Offset(14, 0),
        const Offset(36, 4),
        p
          ..color = const Color(0xffe7c96f)
          ..strokeWidth = 5);
    c.restore();
    c.restore();
    if (attack) {
      c.drawArc(
          const Rect.fromLTWH(205, 307, 164, 120),
          -.9,
          1.9,
          false,
          Paint()
            ..color = Colors.white.withOpacity(1 - state.attackAge / .22)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 8);
    }
  }
}
```

## mobile/lib/game/runner/enemy_component.dart

```dart
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'battle_state_controller.dart';

class EnemyComponent extends Component {
  EnemyComponent(this.enemy);
  final RunnerEnemy enemy;
  @override
  void render(Canvas canvas) {
    final c = canvas;
    final opacity = (1 - enemy.hitAge / .5).clamp(0.0, 1.0);
    final p = Paint();
    c.save();
    c.translate(
        enemy.x, 411 - math.sin(enemy.age * 9).abs() * 7 - enemy.hitAge * 45);
    c.drawOval(const Rect.fromLTWH(-25, 15, 50, 10),
        p..color = Colors.black.withOpacity(.15 * opacity));
    p.color = (enemy.phase == EnemyPhase.hit
            ? Colors.white
            : enemy.data.id == 'slime'
                ? const Color(0xff57bcd0)
                : const Color(0xff80a14f))
        .withOpacity(opacity);
    if (enemy.data.id == 'slime') {
      c.drawPath(
          Path()
            ..moveTo(-27, 14)
            ..quadraticBezierTo(-32, -8, 0, -30)
            ..quadraticBezierTo(34, -7, 27, 14)
            ..quadraticBezierTo(0, 29, -27, 14)
            ..close(),
          p);
    } else {
      c.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(-22, -33, 44, 54), const Radius.circular(10)),
          p);
      c.drawPath(
          Path()
            ..moveTo(-20, -22)
            ..lineTo(-38, -33)
            ..lineTo(-20, -4)
            ..close(),
          p);
      c.drawPath(
          Path()
            ..moveTo(20, -22)
            ..lineTo(38, -33)
            ..lineTo(20, -4)
            ..close(),
          p);
    }
    p.color = const Color(0xff153640).withOpacity(opacity);
    c.drawCircle(const Offset(-8, -5), 3, p);
    c.drawCircle(const Offset(8, -5), 3, p);
    c.restore();
  }
}
```

## mobile/lib/game/runner/enemy_spawner.dart

```dart
import 'package:flame/components.dart';
import 'battle_state_controller.dart';
import 'enemy_component.dart';
import 'damage_text_component.dart';

class EnemySpawner extends Component {
  EnemySpawner(this.state);
  final BattleStateController state;
  final Map<int, EnemyComponent> _visible = {};
  int _attack = 0;
  @override
  void update(double dt) {
    super.update(dt);
    final ids = state.enemies.map((e) => e.id).toSet();
    for (final id in _visible.keys.toList()) {
      if (!ids.contains(id)) _visible.remove(id)!.removeFromParent();
    }
    for (final enemy in state.enemies) {
      if (!_visible.containsKey(enemy.id)) {
        final component = EnemyComponent(enemy);
        _visible[enemy.id] = component;
        add(component);
      }
    }
    if (_attack != state.attackSerial) {
      _attack = state.attackSerial;
      if (state.attackAge < .1) add(DamageTextComponent(330, 128));
    }
  }
}
```

## mobile/lib/game/runner/damage_text_component.dart

```dart
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class DamageTextComponent extends Component {
  DamageTextComponent(this.x, this.damage);
  final double x;
  final int damage;
  double age = 0;
  @override
  void update(double dt) {
    age += dt;
    if (age >= .6) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final text = TextPainter(
        text: TextSpan(
            text: '$damage',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity((1 - age / .6).clamp(0, 1)),
                shadows: const [Shadow(color: Colors.black, blurRadius: 3)])),
        textDirection: TextDirection.ltr)
      ..layout();
    text.paint(canvas, Offset(x - 12, 352 - age * 65));
  }
}
```

## mobile/lib/game/runner/focus_quest_battle_game.dart

```dart
import 'dart:math' as math;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'background_component.dart';
import 'battle_state_controller.dart';
import 'hero_component.dart';
import 'enemy_spawner.dart';

class FocusQuestBattleGame extends FlameGame {
  FocusQuestBattleGame(
      {required this.state, required this.elapsed, required this.onFinished});
  final BattleStateController state;
  final double Function() elapsed;
  final ValueChanged<BattleResultData> onFinished;
  bool _reported = false;
  @override
  Future<void> onLoad() async {
    await addAll([
      BackgroundComponent(state),
      HeroComponent(state),
      EnemySpawner(state)
    ]);
  }

  @override
  void update(double dt) {
    state.advanceTo(elapsed());
    super.update(dt);
    if (!_reported && state.phase == BattlePhase.finished) {
      _reported = true;
      onFinished(state.result);
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.scale(size.x / 960, size.y / 540);
    if (state.attackAge < .08) {
      canvas.translate(math.sin(state.attackAge * 150) * 1.5, 0);
    }
    super.render(canvas);
    final text = TextPainter(
        text: TextSpan(
            text:
                '緑風の高原    討伐 ${state.defeatedCount}    EXP ${state.gainedExp}',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                shadows: [Shadow(color: Colors.black, blurRadius: 4)])),
        textDirection: TextDirection.ltr)
      ..layout();
    text.paint(canvas, const Offset(24, 20));
    canvas.restore();
  }
}
```

## mobile/lib/features/focus/presentation/battle_replay_page.dart

```dart
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../game/runner/battle_state_controller.dart';
import '../../../game/runner/focus_quest_battle_game.dart';
import '../domain/focus_session.dart';

class BattleReplayPage extends StatefulWidget {
  const BattleReplayPage(
      {super.key, required this.session, required this.clock});
  final FocusSession session;
  final DateTime Function() clock;
  @override
  State<BattleReplayPage> createState() => _BattleReplayPageState();
}

class _BattleReplayPageState extends State<BattleReplayPage> {
  late final FocusQuestBattleGame _game;
  bool _returned = false;
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    _game = FocusQuestBattleGame(
        state: BattleStateController(
            durationSeconds: widget.session.durationMinutes * 60.0),
        elapsed: () =>
            widget.clock().difference(widget.session.startedAt).inMilliseconds /
            1000,
        onFinished: (result) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_returned) {
              _returned = true;
              Navigator.of(context).pop(result);
            }
          });
        });
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
      body: SafeArea(child: LayoutBuilder(builder: (context, constraints) {
        // Android tablets may ignore orientation locks. Rotate the surface as a fallback.
        final portrait = constraints.maxHeight > constraints.maxWidth;
        return RotatedBox(
            quarterTurns: portrait ? 1 : 0,
            child: Stack(children: [
              Center(
                  child: AspectRatio(
                      aspectRatio: 16 / 9, child: GameWidget(game: _game))),
              Positioned(
                  right: 12,
                  top: 8,
                  child: TextButton(
                      style: TextButton.styleFrom(
                          backgroundColor: const Color(0xcc102b43),
                          foregroundColor: Colors.white),
                      onPressed: () {
                        if (!_returned) {
                          _returned = true;
                          Navigator.pop(context, _game.state.result);
                        }
                      },
                      child: const Text('タイマーに戻る'))),
            ]));
      })));
}
```

## mobile/lib/features/focus/presentation/focus_screen.dart

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/config/game_balance.dart';
import '../../../core/game_controller.dart';
import '../../../core/widgets/quest_widgets.dart';
import '../domain/focus_session.dart';
import 'battle_replay_page.dart';
import '../../../game/runner/battle_state_controller.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key, required this.controller});
  final GameController controller;
  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> with WidgetsBindingObserver {
  late final Timer _ticker;
  final _custom = TextEditingController();
  int _minutes = 30;
  bool _settling = false;
  bool _automaticFailed = false;
  bool _battleOpen = false;
  BattleResultData? _battleResult;
  String? _error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    WidgetsBinding.instance.addPostFrameCallback((_) => _tick());
  }

  @override
  void dispose() {
    _ticker.cancel();
    _custom.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _tick();
  }

  void _tick() {
    if (!mounted) return;
    setState(() {});
    final session = widget.controller.activeFocus;
    if (session != null &&
        session.remaining(widget.controller.clock()) == Duration.zero &&
        !_settling &&
        !_battleOpen &&
        !_automaticFailed &&
        !widget.controller.busy) {
      _finish();
    }
  }

  Future<void> _openBattle() async {
    final session = widget.controller.activeFocus;
    if (session == null || _battleOpen) return;
    setState(() => _battleOpen = true);
    try {
      _battleResult = await Navigator.of(context).push<BattleResultData>(
          MaterialPageRoute(
              builder: (_) => BattleReplayPage(
                  session: session, clock: widget.controller.clock)));
    } finally {
      if (mounted) {
        setState(() => _battleOpen = false);
        _tick();
      }
    }
  }

  Future<void> _finish({bool cancel = false}) async {
    if (_settling) return;
    setState(() {
      _settling = true;
      _error = null;
    });
    try {
      final result = await widget.controller.finishFocus(cancel: cancel);
      if (mounted && result != null) {
        final succeeded = result.status == FocusStatus.succeeded;
        await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
                    title: Text(succeeded
                        ? '集中クエスト達成！'
                        : cancel
                            ? '集中を中断しました'
                            : '集中クエスト未達成'),
                    content: Text(succeeded
                        ? '${result.durationMinutes}分の冒険の準備ができました。\nEXP +${result.durationMinutes * 10}\nポイント +${result.durationMinutes * 100 ~/ 30}\n冒険進行 +${result.durationMinutes}\n獲得アイテムはキャラクター画面で確認できます。'
                        : cancel
                            ? '報酬はありません。また次の集中で挑戦しましょう。'
                            : '対象アプリの使用、または使用状況を確認できなかったため、報酬はありません。'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('閉じる'))
                    ]));
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _automaticFailed = true;
          _error = '結果を保存できませんでした。再試行してください。';
        });
      }
    } finally {
      if (mounted) setState(() => _settling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final session = controller.activeFocus;
    final seconds = session?.remaining(controller.clock()).inSeconds ?? 0;
    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: SafeArea(
          child: QuestBackdrop(
              child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 64, 20, 24),
                  children: [
                const SizedBox(height: 100),
                QuestCard(
                    caption: session == null ? '旅の支度' : '集中の時間',
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (session == null) ...[
                            const Text('どのくらい集中しますか？',
                                style: TextStyle(fontSize: 16)),
                            const SizedBox(height: 24),
                            Wrap(spacing: 12, children: [
                              for (final minutes in GameBalance.focusPresets)
                                ChoiceChip(
                                    label: Text('$minutes分'),
                                    selected: _minutes == minutes,
                                    onSelected: (_) => setState(() {
                                          _minutes = minutes;
                                          _custom.clear();
                                        }))
                            ]),
                            const SizedBox(height: 16),
                            TextField(
                                controller: _custom,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                    labelText: 'カスタム（1〜180分）'),
                                onChanged: (value) => setState(
                                    () => _minutes = int.tryParse(value) ?? 0)),
                            const SizedBox(height: 24),
                            Text(controller.state!.monitoring
                                ? '選択したアプリの使用を確認します。'
                                : 'タイマーのみ：他のアプリの使用は確認しません。設定から確認機能を有効にできます。'),
                            const SizedBox(height: 24),
                            FilledButton(
                                onPressed: controller.busy ||
                                        _minutes < 1 ||
                                        _minutes > 180
                                    ? null
                                    : () => runAction(context, () async {
                                          await controller.startFocus(_minutes);
                                          if (mounted) {
                                            setState(() {
                                              _automaticFailed = false;
                                              _battleResult = null;
                                            });
                                            await _openBattle();
                                          }
                                        }),
                                child: const Text('集中を開始')),
                          ] else ...[
                            TextButton(
                                onPressed: _openBattle,
                                child: const Text('冒険を眺める')),
                            if (_battleResult != null)
                              Text('冒険中の討伐 ${_battleResult!.defeatedCount}体'),
                            const SizedBox(height: 32),
                            const SizedBox(height: 32),
                            Text(
                                '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
                                textAlign: TextAlign.center,
                                style:
                                    Theme.of(context).textTheme.displayLarge),
                            const SizedBox(height: 24),
                            LinearProgressIndicator(
                                value: (1 -
                                        seconds /
                                            (session.durationMinutes * 60))
                                    .clamp(0, 1)),
                            const SizedBox(height: 24),
                            const Text(
                                '画面を消して、自分の時間に集中しましょう。終了後にアプリへ戻ると結果を確認できます。'),
                            const SizedBox(height: 24),
                            Text(session.verification ==
                                    FocusVerification.usageStats
                                ? '対象アプリの使用を確認する集中'
                                : 'タイマーのみの集中'),
                            if (_error != null) ...[
                              Text(_error!),
                              FilledButton(
                                  onPressed: _settling ? null : () => _finish(),
                                  child: const Text('結果の保存を再試行'))
                            ],
                            TextButton(
                                onPressed: _settling || controller.busy
                                    ? null
                                    : () async {
                                        final confirmed = await showDialog<
                                                bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                                    title: const Text(
                                                        '集中を中断しますか？'),
                                                    content: const Text(
                                                        '途中終了では報酬を獲得できません。'),
                                                    actions: [
                                                      TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                  context,
                                                                  false),
                                                          child: const Text(
                                                              '続ける')),
                                                      TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                  context,
                                                                  true),
                                                          child: const Text(
                                                              '中断する'))
                                                    ]));
                                        if (confirmed == true && mounted) {
                                          await _finish(cancel: true);
                                        }
                                      },
                                child: const Text('集中を中断')),
                          ],
                        ])),
              ])),
        ));
  }
}
```
