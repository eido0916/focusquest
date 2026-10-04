import 'package:focusquest/data/player_repository.dart';
import 'package:focusquest/data/player_state.dart';

class MemoryRepository implements PlayerRepository {
  PlayerState state = PlayerState(uid: 'local-player');
  bool fail = false;
  @override
  Future<PlayerState> load(String uid) async {
    if (fail) throw StateError('disk unavailable');
    return state;
  }

  @override
  Future<PlayerState> transact(
      String uid, PlayerState Function(PlayerState) change) async {
    if (fail) throw StateError('disk unavailable');
    state = change(state);
    return state;
  }
}
