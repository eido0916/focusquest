import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

/// Run behind a TLS reverse proxy exposing /party as wss://…/party.
/// Rooms are deliberately ephemeral; focus records remain on each device.
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
            if (found.session != null) {
              error('このパーティーは集中中です。終了後に参加してください。');
              return;
            }
            if (found.peers.length >= 4) {
              error('パーティーは満員です（最大4人）。');
              return;
            }
            target = found;
          }
          id = _token(20);
          room = target;
          target.hostId ??= id;
          target.peers[id!] = socket;
          target.members[id!] = {
            'id': id,
            'name': (member['name'] as String).trim(),
            'characterType': member['characterType'],
            'appearance': member['appearance'],
            'level': member['level'],
            'ready': false,
            'status': 'waiting'
          };
          joinDeadline.cancel();
          _broadcast(target);
          return;
        }
        final current = room!;
        _expire(current);
        switch (type) {
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
      if (current == null) return;
      current.peers.remove(id);
      if (current.session == null) {
        current.members.remove(id);
      } else {
        current.members[id]?['status'] = 'disconnected';
      }
      if (current.peers.isEmpty) {
        _rooms.remove(current.code);
      } else {
        if (current.hostId == id) current.hostId = current.peers.keys.first;
        _broadcast(current);
      }
    });
  }

  void _expire(_Room room) {
    final session = room.session;
    if (session == null) return;
    final endsAt = DateTime.parse(session['startedAt'] as String)
        .add(Duration(minutes: session['minutes'] as int));
    if (DateTime.now().isBefore(endsAt)) return;
    room.session = null;
    room.members.removeWhere((id, _) => !room.peers.containsKey(id));
    for (final member in room.members.values) {
      member['ready'] = false;
    }
    _broadcast(room);
  }

  void _broadcast(_Room room) {
    for (final peer in room.peers.entries) {
      if (peer.value.readyState != WebSocket.open) continue;
      peer.value.add(jsonEncode({
        'type': 'snapshot',
        'selfId': peer.key,
        'hostId': room.hostId,
        'code': room.code,
        'minutes': room.minutes,
        'members': room.members.values.toList(),
        'session': room.session,
        'serverTime': DateTime.now().toUtc().toIso8601String()
      }));
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
  String? hostId;
  int minutes = 30;
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
