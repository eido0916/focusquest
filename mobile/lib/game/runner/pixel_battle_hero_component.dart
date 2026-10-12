import 'dart:ui';
import 'package:flame/components.dart';
import 'battle_state_controller.dart';
import 'pixel_battle_assets.dart';

/// Select complete originals by battle time; only world coordinates change.
class PixelBattleHeroComponent extends PositionComponent {
  PixelBattleHeroComponent(this.state, this.assets)
      : super(position: Vector2(345, 405), priority: 5);
  final BattleStateController state;
  final PixelBattleAssets assets;
  final Paint pixelPaint = Paint()..filterQuality = FilterQuality.none;

  @override
  void render(Canvas canvas) {
    final action = state.isSkillPlaying
        ? 'skill'
        : state.isNormalAttackPlaying
            ? 'attack'
            : 'run';
    final motion = assets.motions[action]!;
    final age = action == 'skill'
        ? state.visualSkillAge * motion.duration / state.activeSkillDuration
        : action == 'attack'
            ? state.attackAge *
                motion.duration /
                state.config.normalAttackDuration
            : state.elapsedSeconds;
    final frame = motion.frame(age, loop: action == 'run');
    final anchor = motion.metadata['sprite_anchor_px'] as List<dynamic>?;
    final anchorX = anchor == null ? 64.0 : (anchor[0] as num).toDouble();
    final anchorY = anchor == null ? 114.0 : (anchor[1] as num).toDouble();
    // Originals are a 64px logical grid doubled to 128px. Display each logical
    // pixel at 3px (previously 4px), consistently across all actions.
    const scale = 3 / 2;
    canvas.drawImageRect(
        frame.image,
        const Rect.fromLTWH(0, 0, 128, 128),
        Rect.fromLTWH((frame.offset.dx - anchorX) * scale,
            (frame.offset.dy - anchorY) * scale, 128 * scale, 128 * scale),
        pixelPaint);
    if (action == 'skill') {
      assets.effect.paint(canvas,
          origin: Offset(frame.offset.dx * scale, frame.offset.dy * scale),
          viewport: const Rect.fromLTWH(-345, -405, 960, 540),
          age: age,
          duration: motion.duration,
          releases: motion
              .eventTicks(assets.character.skillEvent)
              .map((t) => t / 24)
              .toList(),
          logicalPixel: 3);
    }
  }
}
