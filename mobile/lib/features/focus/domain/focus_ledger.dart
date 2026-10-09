import '../../../data/player_state.dart';
import '../../character/domain/progression_service.dart';
import 'focus_session.dart';
import 'reward_service.dart';

/// Apply inside PlayerRepository.transact, never in a UI timer callback directly.
class FocusLedger {
  PlayerState begin(PlayerState state, FocusSession session) {
    if (state.activeCharacter == null) throw StateError('キャラクターを決定してください。');
    if (state.sessions.containsKey(session.id) ||
        state.sessions.values.any((s) => s.status == FocusStatus.active)) {
      throw StateError('集中セッションはすでに開始されています。');
    }
    if (session.status != FocusStatus.active) {
      throw ArgumentError('開始済みセッションが必要です。');
    }
    return state.copyWith(sessions: {...state.sessions, session.id: session});
  }

  PlayerState settle(
      PlayerState state, String sessionId, FocusStatus status, Reward reward) {
    final operation = 'focus:$sessionId';
    if (state.appliedOperations.contains(operation)) return state;
    final session = state.sessions[sessionId];
    if (session == null ||
        session.status != FocusStatus.active ||
        status == FocusStatus.active) {
      throw StateError('集中セッションを確定できません。');
    }
    var characters = state.characters;
    var coins = state.coins;
    final inventory = {...state.inventory};
    if (status == FocusStatus.succeeded) {
      final hero = state.activeCharacter;
      if (hero == null) throw StateError('キャラクターがありません。');
      characters = {
        ...characters,
        hero.id: ProgressionService().addExp(hero, reward.exp)
      };
      coins += reward.coins;
      for (final item in reward.items) {
        inventory[item] = (inventory[item] ?? 0) + 1;
      }
    }
    return state.copyWith(
        characters: characters,
        coins: coins,
        inventory: inventory,
        sessions: {...state.sessions, sessionId: session.finish(status)},
        appliedOperations: {...state.appliedOperations, operation});
  }
}
