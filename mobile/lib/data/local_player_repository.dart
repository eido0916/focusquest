import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'player_repository.dart';
import 'player_state.dart';

/// One repository instance owns the save file. Writes are serialized, flushed,
/// then renamed atomically. A corrupt save is reported, never reset silently.
class LocalPlayerRepository implements PlayerRepository {
  LocalPlayerRepository(this.directory);
  final Directory directory;
  Future<void> _tail = Future.value();
  File get _file => File('${directory.path}/player-v1.json');

  Future<T> _serialized<T>(Future<T> Function() operation) {
    final result = _tail.then((_) => operation());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<PlayerState> _read(String uid) async {
    if (!await _file.exists()) return PlayerState(uid: uid);
    final state = PlayerState.fromJson(
        jsonDecode(await _file.readAsString()) as Map<String, dynamic>);
    if (state.uid != uid) throw StateError('保存データのユーザーが一致しません。');
    return state;
  }

  @override
  Future<PlayerState> load(String uid) => _serialized(() => _read(uid));
  @override
  Future<PlayerState> transact(
          String uid, PlayerState Function(PlayerState) change) =>
      _serialized(() async {
        final before = await _read(uid);
        final after = change(before);
        if (after.uid != uid) throw StateError('ユーザーを変更できません。');
        if (identical(before, after)) return before;
        await directory.create(recursive: true);
        final temp = File('${_file.path}.pending');
        await temp.writeAsString(jsonEncode(after.toJson()), flush: true);
        await temp.rename(_file.path);
        return after;
      });
}
