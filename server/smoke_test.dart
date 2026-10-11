import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'party_server.dart';

class _Client {
  _Client(this.socket) {
    socket.listen((raw) {
      final message = jsonDecode(raw as String) as Map<String, dynamic>;
      if (message['type'] == 'snapshot') snapshot = message;
      if (message['type'] == 'error') error = message['message'] as String;
    });
  }
  final WebSocket socket;
  Map<String, dynamic>? snapshot;
  String? error;
  void send(String type, [Map<String, dynamic> data = const {}]) =>
      socket.add(jsonEncode({'type': type, ...data}));
}

Future<void> _until(bool Function() check) async {
  for (var i = 0; i < 1000 && !check(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  if (!check()) throw StateError('Party smoke test timed out.');
}

void _check(bool value, String message) {
  if (!value) throw StateError(message);
}

Future<void> main(List<String> args) async {
  final server = PartyServer();
  final clients = <_Client>[];
  final http = HttpClient();
  final local = args.isEmpty;
  if (local) {
    await server.start(address: InternetAddress.loopbackIPv4, port: 0);
  }
  final endpoint = local
      ? Uri.parse('ws://127.0.0.1:${server.port}/party')
      : Uri.parse(args.single);
  final health = endpoint.replace(
      scheme: endpoint.scheme == 'wss' ? 'https' : 'http', path: '/health');
  try {
    final response = await (await http
            .getUrl(health))
        .close();
    _check(response.statusCode == 200, 'Health endpoint must return 200.');
    _check(await utf8.decoder.bind(response).join() == 'ok',
        'Health body must be ok.');
    const member = {
      'name': '冒険者',
      'characterType': 'warrior',
      'appearance': 'male',
      'level': 1
    };
    Future<_Client> connect(String? code) async {
      final client = _Client(
          await WebSocket.connect(endpoint.toString()));
      clients.add(client);
      client.send(
          code == null ? 'create' : 'join', {'code': code, 'member': member});
      await _until(() => client.snapshot != null || client.error != null);
      return client;
    }

    final host = await connect(null);
    final code = host.snapshot!['code'] as String;
    _check(RegExp(r'^[A-Z2-9]{6}$').hasMatch(code),
        'Room code must have six characters.');
    for (var i = 0; i < 3; i++) {
      await connect(code);
    }
    await _until(() => (host.snapshot!['members'] as List).length == 4);
    final extra = await connect(code);
    _check(extra.error != null && extra.snapshot == null,
        'A fifth player must be rejected.');
    host.send('start');
    await _until(() => host.error != null);
    _check(host.snapshot!['session'] == null, 'Unready rooms cannot start.');
    for (final client in clients.take(4)) {
      client.send('ready', {'ready': true});
    }
    await _until(() =>
        (host.snapshot!['members'] as List).every((m) => m['ready'] == true));
    host.send('start');
    await _until(
        () => clients.take(4).every((c) => c.snapshot!['session'] != null));
    final session = host.snapshot!['session'] as Map;
    for (final client in clients.take(4)) {
      final other = client.snapshot!['session'] as Map;
      _check(
          other['id'] == session['id'] &&
              other['startedAt'] == session['startedAt'],
          'All players must share the same start timestamp and session ID.');
    }
    stdout.writeln(
        'PASS: health, code join, four-player limit, readiness, synchronized start.');
  } finally {
    for (final client in clients) {
      await client.socket.close();
    }
    http.close(force: true);
    if (local) await server.close();
  }
}
