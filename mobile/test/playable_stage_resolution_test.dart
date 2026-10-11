import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/features/playable_stage/presentation/playable_stage_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all nine bosses decode complete 384px original motion frames',
      () async {
    final assets = await PlayableStageAssets.load();
    addTearDown(assets.dispose);
    final bosses = <String>{};
    for (final entry in assets.motions.entries) {
      if (!entry.key.startsWith('boss_')) continue;
      final motion = entry.value;
      bosses.add(motion.metadata['asset'] as String);
      expect(motion.metadata['canvas'], [384, 384]);
      expect(motion.metadata['coordinate_canvas'], [128, 128]);
      expect(motion.metadata['interpolation'], 'none');
      for (final image in motion.images) {
        expect(image.width, 384);
        expect(image.height, 384);
      }
      for (final row in motion.timeline) {
        final frame = motion.frame((row['tick'] as int) / 24 + .000001);
        expect(frame.image, same(motion.images[row['keyframe'] as int]));
      }
    }
    expect(bosses.length, 9);
    expect(assets.motions['hero_run']!.images.first.width, 128);
    expect(assets.motions['slime_locomotion']!.images.first.width, 128);
  });
}
