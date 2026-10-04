import 'player_state.dart';

/// UI never accesses Firestore directly. The transaction callback must be pure:
/// Firestore may call it multiple times on contention. Roll rewards beforehand.
abstract interface class PlayerRepository {
  Future<PlayerState> load(String uid);
  Future<PlayerState> transact(
      String uid, PlayerState Function(PlayerState) change);
}
