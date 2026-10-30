import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

/// Run behind a TLS reverse proxy exposing /party as wss://…/party.
/// Rooms retain disconnected members for 30 minutes (or while focus is active).
class PartyServer {
  final _random = Random.secure();
  final Map<String, _Room> _rooms = {};
  final Set<WebSocket> _sockets = {};
  HttpServer? _http;
  Timer? _cleanup;
  int get port => _http!.port;
  Future<void> start({InternetAddress? address, int port = 8080}) async {
    _http = await HttpServer.bind(address ?? InternetAddress.anyIPv4, port);
    _cleanup = Timer.periodic(const Duration(seconds: 5), (_) {
      for (final room in _rooms.values.toList()) {
        _expire(room);
      }
    });
    _http!.listen(_request);
  }

  Future<void> _request(HttpRequest request) async {
    if (request.uri.path == '/health') {
      request.response.write('ok');
      await request.response.close();
      return;
    }
    if (request.uri.path != '/party' ||
        !WebSocketTransformer.isUpgradeRequest(request)) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }
    try {
      final socket = await WebSocketTransformer.upgrade(request);
      socket.pingInterval = const Duration(seconds: 20);
      _sockets.add(socket);
      _accept(socket);
    } catch (_) {/* A peer may disconnect during the upgrade. */}
  }

  String _token(int length) {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(
        length, (_) => alphabet[_random.nextInt(alphabet.length)]).join();
  }

  void _accept(WebSocket socket) {
    _Room? room;
    String? id;
    var attempts = 0;
    var window = DateTime.now();
    final joinDeadline = Timer(const Duration(seconds: 15), () {
      if (room == null) socket.close(WebSocketStatus.policyViolation);
    });
    void error(String message) =>
        socket.add(jsonEncode({'type': 'error', 'message': message}));
    socket.listen((raw) {
      try {
        if (DateTime.now().difference(window).inSeconds >= 60) {
          attempts = 0;
          window = DateTime.now();
        }
        if (++attempts > 60 || raw is! String || raw.length > 4096) {
          socket.close(WebSocketStatus.policyViolation);
          return;
        }
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final type = data['type'];
        if (room == null) {
          if (type != 'create' && type != 'join') throw const FormatException();
          if (_rooms.length >= 1000 && type == 'create') {
            error('サーバーが混み合っています。少し待って再試行してください。');
            return;
          }
          final member = Map<String, dynamic>.from(data['member'] as Map);
          if (member['name'] is! String ||
              (member['name'] as String).trim().isEmpty ||
              (member['name'] as String).length > 40 ||
              !roles.contains(member['characterType']) ||
              !['male', 'female'].contains(member['appearance']) ||
              member['level'] is! int ||
              (member['level'] as int) < 1 ||
              (member['level'] as int) > 9999) {
            throw const FormatException();
          }
          _Room target;
          String? returningId;
          if (type == 'create') {
            var code = _token(6);
            while (_rooms.containsKey(code)) {
              code = _token(6);
            }
            target = _Room(code);
            _rooms[code] = target;
          } else {
            final code = (data['code'] as String).trim().toUpperCase();
            final found = _rooms[code];
            if (found == null) {
              error('パーティーが見つかりません。コードを確認してください。');
              return;
            }
            _expire(found);
            if (!_rooms.containsKey(code)) {
              error('復帰できる時間を過ぎています。新しいパーティーを作成してください。');
              return;
            }
            final token = data['resumeToken'];
            if (token is String && token.isNotEmpty) {
              for (final entry in found.tokens.entries) {
                if (entry.value == token) returningId = entry.key;
              }
            }
            if (returningId != null && found.peers.containsKey(returningId)) {
              error('このメンバーはすでに接続しています。');
              return;
            }
            if (found.session != null && returningId == null) {
              error('このパーティーは集中中です。終了後に参加してください。');
              return;
            }
            if (found.members.length >= 4 && returningId == null) {
              error('パーティーは満員です（最大4人）。');
              return;
            }
            target = found;
          }
          id = returningId ?? _token(20);
          target.emptySince = null;
          target.disconnectedAt.remove(id);
          target.tokens.putIfAbsent(id!, () => _token(32));
          room = target;
          if (target.peers.isEmpty) target.hostId = id;
          target.hostId ??= id;
          target.peers[id!] = socket;
          if (returningId == null)
            target.members[id!] = {
              'id': id,
              'name': (member['name'] as String).trim(),
              'characterType': member['characterType'],
              'appearance': member['appearance'],
              'level': member['level'],
              'unlockedAreas': (member['unlockedAreas'] as List? ?? [])
                  .whereType<int>()
                  .where((a) => a >= 0 && a < 9)
                  .toSet()
                  .toList(),
              'ready': false,
              'status': 'waiting'
            };
          if (returningId != null)
            target.members[id]!['status'] =
                target.session == null ? 'waiting' : 'focusing';
          if (target.focusAreaIndex >= 0 &&
              target.members.values.any((m) => !(m['unlockedAreas'] as List)
                  .contains(target.focusAreaIndex))) {
            target.focusAreaIndex = -1;
            for (final m in target.members.values) {
              m['ready'] = false;
            }
          }
          joinDeadline.cancel();
          _broadcast(target);
          return;
        }
        final current = room!;
        if (current.disbanded) return;
        _expire(current);
        switch (type) {
          case 'disband':
            if (id != current.hostId) {
              error('パーティーを解散できるのはリーダーだけです。');
              return;
            }
            current.disbanded = true;
            _rooms.remove(current.code);
            current.tokens.clear();
            for (final peer in current.peers.values.toList()) {
              if (peer.readyState == WebSocket.open) {
                peer.add(jsonEncode({'type': 'disbanded'}));
                peer.close();
              }
            }
            return;
          case 'leave':
            current.members.remove(id);
            current.tokens.remove(id);
            current.disconnectedAt.remove(id);
            socket.close();
            return;
          case 'area':
            final area = data['focusAreaIndex'];
            if (id != current.hostId ||
                current.session != null ||
                area is! int ||
                area < -1 ||
                area > 8 ||
                (area >= 0 &&
                    current.members.values.any(
                        (m) => !(m['unlockedAreas'] as List).contains(area)))) {
              error('全員が解放した集中エリアを選んでください。');
              return;
            }
            current.focusAreaIndex = area;
            for (final m in current.members.values) {
              m['ready'] = false;
            }
          case 'ready':
            if (current.session != null) {
              error('集中が終わってから準備できます。');
              return;
            }
            current.members[id]!['ready'] = data['ready'] == true;
          case 'duration':
            if (id != current.hostId || current.session != null) {
              error('集中時間を変更できません。');
              return;
            }
            final minutes = data['minutes'];
            if (minutes is! int || minutes < 1 || minutes > 180)
              throw const FormatException();
            current.minutes = minutes;
            for (final member in current.members.values) {
              member['ready'] = false;
            }
          case 'start':
            if (id != current.hostId) {
              error('リーダーが集中を開始します。');
              return;
            }
            if (current.session != null) {
              error('すでに集中中です。');
              return;
            }
            if (current.peers.length < 2 ||
                current.members.values.any((m) => m['ready'] != true)) {
              error('2〜4人が参加し、全員の準備ができてから開始してください。');
              return;
            }
            current.session = {
              'id': _token(24),
              'startedAt': DateTime.now()
                  .toUtc()
                  .add(const Duration(seconds: 3))
                  .toIso8601String(),
              'minutes': current.minutes,
              'focusAreaIndex': current.focusAreaIndex,
              'members': current.members.values
                  .map((m) => Map<String, dynamic>.from(m))
                  .toList()
            };
            for (final member in current.members.values) {
              member['status'] = 'starting';
            }
          case 'status':
            if (current.session == null ||
                !['focusing', 'succeeded', 'failed', 'cancelled', 'cannotStart']
                    .contains(data['status'])) {
              throw const FormatException();
            }
            current.members[id]!['status'] = data['status'];
          default:
            throw const FormatException();
        }
        _broadcast(current);
      } catch (_) {
        error('操作を受け付けられませんでした。');
      }
    }, onError: (_) {
      socket.close();
    }, onDone: () {
      joinDeadline.cancel();
      _sockets.remove(socket);
      final current = room;
      if (current == null || current.disbanded) return;
      current.peers.remove(id);
      if (current.members.containsKey(id)) {
        current.members[id]!['status'] = 'disconnected';
        current.members[id]!['ready'] = false;
        current.disconnectedAt[id!] = DateTime.now();
      }
      if (current.peers.isEmpty) {
        current.emptySince = DateTime.now();
      } else if (current.hostId == id) {
        current.hostId = current.peers.keys.first;
      }
      _broadcast(current);
    });
  }

  void _expire(_Room room) {
    if (room.disbanded) return;
    final now = DateTime.now();
    if (room.emptySince != null &&
        now.difference(room.emptySince!).inMinutes >= 30 &&
        room.session == null) {
      _rooms.remove(room.code);
      return;
    }
    if (room.session == null) {
      for (final id in room.disconnectedAt.keys.toList()) {
        if (now.difference(room.disconnectedAt[id]!).inMinutes >= 30) {
          room.disconnectedAt.remove(id);
          room.members.remove(id);
          room.tokens.remove(id);
        }
      }
    }
    final session = room.session;
    if (session == null) return;
    final endsAt = DateTime.parse(session['startedAt'] as String)
        .add(Duration(minutes: session['minutes'] as int));
    if (DateTime.now().isBefore(endsAt)) return;
    room.session = null;
    if (room.peers.isEmpty) room.emptySince = now;
    for (final id in room.disconnectedAt.keys.toList()) {
      room.disconnectedAt[id] = now;
    }

    for (final member in room.members.values) {
      member['ready'] = false;
    }
    _broadcast(room);
  }

  void _broadcast(_Room room) {
    for (final peer in room.peers.entries) {
      if (peer.value.readyState != WebSocket.open) continue;
      try {
        peer.value.add(jsonEncode({
          'type': 'snapshot',
          'selfId': peer.key,
          'resumeToken': room.tokens[peer.key],
          'focusAreaIndex': room.focusAreaIndex,
          'hostId': room.hostId,
          'code': room.code,
          'minutes': room.minutes,
          'members': room.members.values.toList(),
          'session': room.session,
          'serverTime': DateTime.now().toUtc().toIso8601String()
        }));
      } on StateError {
        // A locally closed sink can still report OPEN until onDone runs.
        // The disconnect handler removes the peer and updates the room.
      }
    }
  }

  Future<void> close() async {
    _cleanup?.cancel();
    for (final socket in _sockets.toList()) {
      await socket.close();
    }
    await _http?.close(force: true);
  }

  static const roles = {
    'warrior',
    'boxer',
    'samurai',
    'guardian',
    'ninja',
    'assassin',
    'ranger',
    'mage',
    'gunner',
    'paladin',
    'berserker',
    'monk',
    'priest',
    'druid',
    'bard',
    'alchemist',
    'spellblade',
    'onmyoji',
    'reaper',
    'angel',
    'devil',
    'dragon_knight',
    'engineer',
    'summoner',
    'beastmaster',
    'scholar',
    'cleric',
    'dancer',
    'strategist'
  };
}

class _Room {
  _Room(this.code);
  final String code;
  bool disbanded = false;
  String? hostId;
  int minutes = 30;
  int focusAreaIndex = -1;
  DateTime? emptySince;
  final Map<String, String> tokens = {};
  final Map<String, DateTime> disconnectedAt = {};
  final Map<String, WebSocket> peers = {};
  final Map<String, Map<String, dynamic>> members = {};
  Map<String, dynamic>? session;
}

Future<void> main() async {
  final server = PartyServer();
  await server.start(
      port: int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080);
  stdout.writeln('FocusQuest party server listening on ${server.port}');
  ProcessSignal.sigint.watch().listen((_) async {
    await server.close();
    exit(0);
  });
}
