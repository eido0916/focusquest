import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/core/game_controller.dart';
import 'package:focusquest/data/game_catalog.dart';
import 'package:focusquest/data/player_state.dart';
import 'support/memory_repository.dart';

void main() {
  test('retired adventure data is ignored while earned progress survives',
      () async {
    final repo = MemoryRepository();
    final controller = GameController(repo);
    addTearDown(controller.dispose);
    await controller.load();
    await controller.onboard(GameCatalog.types[8]!, appearance: 'female');
    await controller.startFocus(15);
    await controller.finishFocus(cancel: true);
    final saved = controller.state!.copyWith(
        coins: 100,
        inventory: {'wooden_sword': 1},
        clearedPlayableStages: {1, 2});
    final legacy = saved.toJson()
      ..['clearedStages'] = ['forest_1']
      // Even an incomplete retired run must not prevent loading the save.
      ..['adventureRun'] = {'id': 'old-pending-run'}
      ..['lastAdventure'] = {'runId': 'old-result'};
    repo.state = PlayerState.fromJson(legacy);
    await controller.load();
    expect(controller.state!.toJson(), saved.toJson());
    await controller.beginPlayableAdventure();
    controller.endPlayableAdventure();
    await expectLater(controller.equip('wooden_sword'), throwsStateError);
    await controller.selectCharacter('starter');
    await controller.setCharacterForDevelopment('ranger', 'female');
    await controller.startFocus(15);
    expect(controller.activeFocus, isNotNull);
    expect(controller.state!.coins, 100);
    expect(controller.state!.clearedPlayableStages, {1, 2});
    for (final key in ['clearedStages', 'adventureRun', 'lastAdventure']) {
      expect(repo.state.toJson(), isNot(contains(key)));
    }
  });
}
