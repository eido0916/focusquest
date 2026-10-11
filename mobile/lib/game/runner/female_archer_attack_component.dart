import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'archer_attack_animation_controller.dart';
import 'archer_arrow_projectile.dart';
import 'female_archer_attack_assets.dart';

class ArcherShotEvent {
  ArcherShotEvent(this.position, this.remainingSeconds);
  final Vector2 position;
  final double remainingSeconds;
}

/// Full original poses, no flip/rotation/tweening. Position is pelvis x and
/// ground y. Add arrows to the same parent, never as a moving player child.
class FemaleArcherAttackComponent extends SpriteComponent {
  FemaleArcherAttackComponent(
      {required this.assets,
      Vector2? position,
      this.runSpeed = 120,
      this.onAdvance,
      this.onShot,
      this.onAttackComplete,
      this.spawnProjectiles = true,
      this.arrowSpeed = ArcherArrowProjectile.defaultSpeed,
      this.arrowLifetime = ArcherArrowProjectile.defaultLifetime,
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
    'prepare': .65,
    'nock': .4,
    'draw': .15,
    'release': .15,
    'recoil': .2,
    'recover': .45,
    'accelerate': .8,
  };
  final FemaleArcherAttackAssets assets;
  final ArcherAttackAnimationController controller;
  final SpriteAnimationTicker _runTicker;
  final Map<String, double> speedRatios;
  final double runSpeed;
  final double arrowSpeed;
  final double arrowLifetime;
  final bool spawnProjectiles;

  /// Fixed-screen runner integration: consume distance to scroll the world.
  /// When present, this callback owns travel and position is held fixed.
  final void Function(double distance)? onAdvance;
  final void Function(ArcherShotEvent event)? onShot;
  final void Function()? onAttackComplete;
  bool get isAttacking => controller.isPlaying;
  bool playNormalAttack() {
    if (!controller.play()) return false;
    sprite = assets.frames[controller.currentFrame];
    return true;
  }

  void cancelAttack() {
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
    if (spawnProjectiles && parent != null) {
      final arrow = ArcherArrowProjectile(
          sprite: assets.arrow,
          position: muzzle.clone(),
          speed: arrowSpeed,
          lifetime: arrowLifetime);
      // Flame mounts new children after update. Catch up this frame exactly
      // once, so a long dt doesn't leave the arrow stuck at an old muzzle.
      arrow.update(remainder);
      if (!arrow.expired) parent!.add(arrow);
    }
    onShot?.call(ArcherShotEvent(muzzle.clone(), remainder));
  }

  @override
  void update(double dt) {
    if (!dt.isFinite || dt < 0) throw ArgumentError.value(dt, 'dt');
    if (isAttacking) {
      final remainder = controller.update(dt,
          onAdvance: _advance,
          onRelease: _release,
          onComplete: onAttackComplete);
      if (isAttacking) {
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
