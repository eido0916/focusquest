import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flame/game.dart';
import 'archer_wind_arrow_component.dart';
import 'archer_attack_animation_controller.dart';
import 'female_archer_skill_assets.dart';

class ArcherSkillShotEvent {
  ArcherSkillShotEvent(this.position, this.remainingSeconds);
  final Vector2 position;
  final double remainingSeconds;
}

/// One powerful shot while moving. Original RGBA poses only.
/// Position is pelvis x / ground y. onShot fires once, even for a long dt.
/// Wind animation launches at the bow on release; onShot is a gameplay event.
/// Add collision projectiles to the same parent; avoid a second visible arrow
/// during source pose 19. Use remainingSeconds to catch up a new projectile.
/// returnAnimation must use the same native canvas and pelvis/foot anchor.
/// Default run order begins at pose 41, complementary to final skill pose 45.
class FemaleArcherSkillComponent extends SpriteComponent
    with HasGameRef<FlameGame> {
  FemaleArcherSkillComponent(
      {required this.assets,
      Vector2? position,
      this.runSpeed = 120,
      this.onAdvance,
      this.onShot,
      this.onSkillComplete,
      this.showWindEffect = true,
      this.effectRightEdge,
      SpriteAnimation? returnAnimation,
      Map<String, double>? speedRatios})
      : controller = assets.createController(),
        _runTicker = (returnAnimation ?? assets.runAnimation()).createTicker(),
        speedRatios = Map.unmodifiable(speedRatios ?? defaultSpeedRatios),
        super(
            sprite: assets.frames[assets.runIds.first],
            position: position ?? Vector2.zero(),
            size: assets.frameSize,
            anchor: assets.anchor,
            priority: 5,
            paint: Paint()..filterQuality = FilterQuality.none) {
    if (!runSpeed.isFinite ||
        runSpeed < 0 ||
        this.speedRatios.values.any((v) => !v.isFinite || v < 0)) {
      throw ArgumentError('Invalid archer movement settings');
    }
  }
  static const defaultSpeedRatios = <String, double>{
    'run': 1,
    'prepare': .8,
    'nock': .55,
    'draw': .35,
    'aim': .3,
    'release': .3,
    'recoil': .35,
    'recover': .55,
    'accelerate': .85,
  };
  final FemaleArcherSkillAssets assets;
  final ArcherAttackAnimationController controller;
  final SpriteAnimationTicker _runTicker;
  final Map<String, double> speedRatios;
  final double runSpeed;
  final bool showWindEffect;

  /// Camera games must supply the viewport right edge in parent coordinates.
  final double Function()? effectRightEdge;

  /// Fixed-screen runner integration: consume distance to scroll the world.
  /// When present, this callback owns travel and position is held fixed.
  final void Function(double distance)? onAdvance;
  final void Function(ArcherSkillShotEvent event)? onShot;
  final void Function()? onSkillComplete;
  bool get isUsingSkill => controller.isPlaying;
  bool playSkill() {
    if (!controller.play()) return false;
    sprite = assets.frames[controller.currentFrame];
    return true;
  }

  void cancelSkill() {
    controller.cancel();
    _runTicker.reset();
    sprite = _runTicker.getSprite();
  }

  void _advance(double seconds, String phase) {
    final distance = runSpeed * (speedRatios[phase] ?? 1) * seconds;
    if (onAdvance != null) {
      onAdvance!(distance);
    } else {
      position.x += distance;
    }
  }

  void _release(double remainder) {
    final muzzle = position + assets.muzzleOffset;
    if (showWindEffect && parent != null) {
      final wind = ArcherWindArrowComponent(
        frames: assets.windFrames,
        muzzle: muzzle.clone(),
        rightEdge: effectRightEdge ?? () => gameRef.size.x,
      );
      // New children mount after update. Apply the remaining time exactly once.
      wind.update(remainder);
      if (!wind.expired) parent!.add(wind);
    }
    onShot?.call(ArcherSkillShotEvent(muzzle.clone(), remainder));
  }

  @override
  void update(double dt) {
    if (!dt.isFinite || dt < 0) throw ArgumentError.value(dt, 'dt');
    if (isUsingSkill) {
      final remainder = controller.update(dt,
          onAdvance: _advance,
          onRelease: _release,
          onComplete: onSkillComplete);
      if (isUsingSkill) {
        sprite = assets.frames[controller.currentFrame];
      } else {
        _runTicker.reset();
        _runTicker.update(remainder);
        sprite = _runTicker.getSprite();
        _advance(remainder, 'run');
      }
    } else {
      _runTicker.update(dt);
      sprite = _runTicker.getSprite();
      _advance(dt, 'run');
    }
    super.update(dt);
  }
}
