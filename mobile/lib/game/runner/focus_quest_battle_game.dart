import 'dart:async';
import 'dart:math' as math;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'background_component.dart';
import 'battle_state_controller.dart';
import 'hero_component.dart';
import 'swordsman_run_attack_assets.dart';
import 'swordsman_sousen_assets.dart';
import 'enemy_spawner.dart';
import 'enemy_motion_assets.dart';
import 'run_slash_assets.dart';

class FocusQuestBattleGame extends FlameGame {
  FocusQuestBattleGame(
      {required this.state, required this.elapsed, required this.onFinished});
  final BattleStateController state;
  final double Function() elapsed;
  final ValueChanged<BattleResultData> onFinished;
  bool _reported = false;
  @override
  Color backgroundColor() => Colors.transparent;
  @override
  Future<void> onLoad() async {
    final scenery = await images.load('ui/forest_meadow_battlefield.png');
    final enemyAssets = await EnemyMotionAssets.load(this);
    await addAll([
      BackgroundComponent(state, image: scenery),
      EnemySpawner(state, enemyAssets),
    ]);
    // Image decoding can take more than one frame on a physical device. Keep
    // the battle clock responsive while the visual asset finishes loading.
    unawaited(_loadHero());
  }

  Future<void> _loadHero() async {
    final assets = await Future.wait([
      SwordsmanRunAttackAssets.load(this),
      SwordsmanSousenAssets.load(this),
      RunSlashAssets.load(this),
    ]);
    await add(
      HeroComponent(
        state,
        assets[0] as SwordsmanRunAttackAssets,
        assets[1] as SwordsmanSousenAssets,
        assets[2] as RunSlashAssets,
      ),
    );
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
    final hudPaint = Paint()..color = const Color(0xe8062039);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(22, 18, 916, 72), const Radius.circular(7)),
        hudPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(22, 18, 916, 72), const Radius.circular(7)),
      Paint()
        ..color = const Color(0xffe4c16c)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    _paintText(
        canvas, '木漏れ日の野原', const Offset(45, 31), 22, const Color(0xfff8e4aa),
        bold: true);
    _paintText(canvas, '経過時間  ${_time(state.elapsedSeconds)}',
        const Offset(280, 31), 18, Colors.white);
    _paintText(canvas, '討伐数  ${state.defeatedCount}', const Offset(525, 31), 18,
        Colors.white);
    _paintText(canvas, 'EXP  ${state.gainedExp}', const Offset(755, 31), 18,
        const Color(0xff75f0ef));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(24, 451, 300, 65), const Radius.circular(6)),
        hudPaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(24, 451, 300, 65), const Radius.circular(6)),
        Paint()
          ..color = const Color(0xffe4c16c)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    _paintText(canvas, 'Lv. 1   戦士', const Offset(126, 470), 22, Colors.white,
        bold: true);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(700, 451, 238, 65), const Radius.circular(6)),
        hudPaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(700, 451, 238, 65), const Radius.circular(6)),
        Paint()
          ..color = const Color(0xffe4c16c)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    _paintText(
        canvas, 'スキル 自動発動', const Offset(736, 466), 17, const Color(0xfff8e4aa),
        bold: true);
    _paintText(
        canvas,
        state.isSkillPlaying
            ? '${state.skillName} 発動中'
            : '${state.skillName}まで ${state.secondsUntilSousen.ceil().toString().padLeft(2, '0')}秒',
        const Offset(736, 490),
        15,
        Colors.white);
    canvas.restore();
  }

  String _time(double seconds) {
    final value = seconds.floor();
    return '${(value ~/ 60).toString().padLeft(2, '0')}:${(value % 60).toString().padLeft(2, '0')}';
  }

  void _paintText(
      Canvas canvas, String value, Offset offset, double size, Color color,
      {bool bold = false}) {
    final painter = TextPainter(
      text: TextSpan(
          text: value,
          style: TextStyle(
              color: color,
              fontSize: size,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              shadows: const [Shadow(color: Colors.black87, blurRadius: 3)])),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }
}
