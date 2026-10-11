import 'dart:ui';
import 'package:flame/game.dart';
import 'female_archer_skill_assets.dart';
import 'female_archer_skill_component.dart';

/// Independent integration example. Run with main_archer_skill_preview.dart.
/// The archer stays on screen; onAdvance scrolls the ground in world space.
class FemaleArcherSkillDemoGame extends FlameGame {
  FemaleArcherSkillComponent? archer;
  double distance = 0;
  int shots = 0;
  @override
  Color backgroundColor() => const Color(0xff344052);
  @override
  Future<void> onLoad() async {
    final assets = await FemaleArcherSkillAssets.load(this);
    archer = FemaleArcherSkillComponent(
        assets: assets,
        position: Vector2(450, 820),
        onAdvance: (d) => distance += d,
        onShot: (_) => shots++);
    await add(archer!);
  }

  bool skill() => archer?.playSkill() ?? false;
  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = const Color(0xff7b8d76);
    canvas.drawRect(const Rect.fromLTWH(0, 820, 1280, 3), paint);
    for (var x = -(distance % 100); x < 1280; x += 100) {
      canvas.drawRect(Rect.fromLTWH(x, 843, 24, 3), paint);
    }
    super.render(canvas);
  }
}
