import 'package:flame/components.dart';
import 'package:flame/game.dart';

import 'run_slash_skill.dart';

/// Loads the original, unchanged five-column sheets in the explicit user order.
class RunSlashAssets {
  RunSlashAssets._(this.animation, this.frameSize);

  static const sourceFiles = <String>[
    'ChatGPT 画像 2026年10月9日 19_34_42.png',
    'ChatGPT 画像 2026年10月9日 19_34_53.png',
    'ChatGPT 画像 2026年10月9日 19_35_04.png',
    'ChatGPT 画像 2026年10月9日 19_35_10.png',
    'ChatGPT 画像 2026年10月9日 19_35_19.png',
    'ChatGPT 画像 2026年10月9日 19_35_35.png',
  ];

  final SpriteAnimation animation;
  final Vector2 frameSize;
  final Anchor anchor = const Anchor(.5, .92);

  static Future<RunSlashAssets> load(FlameGame game) async {
    final sprites = <Sprite>[];
    Vector2? firstSize;
    for (final filename in sourceFiles) {
      final image = await game.images.load(
        'characters/swordsman/skills/run_slash/$filename',
      );
      // Fractional source coordinates preserve all pixels when width is not
      // divisible by five. No sorting, reversed playback or artwork edits.
      final cellSize = Vector2(image.width / 5, image.height.toDouble());
      firstSize ??= cellSize;
      for (var column = 0; column < 5; column++) {
        sprites.add(Sprite(
          image,
          srcPosition: Vector2(column * cellSize.x, 0),
          srcSize: cellSize,
        ));
      }
    }
    return RunSlashAssets._(
      SpriteAnimation.variableSpriteList(
        sprites,
        stepTimes: RunSlashSkill.frameTimes,
        loop: false,
      ),
      firstSize! * .5,
    );
  }
}
