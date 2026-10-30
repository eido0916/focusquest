import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/core/game_controller.dart';
import 'package:focusquest/data/game_catalog.dart';
import 'package:focusquest/features/focus/domain/focus_session.dart';
import 'package:focusquest/features/party/data/party_connection.dart';
import 'package:focusquest/features/party/domain/party_member.dart';
import '../../server/party_server.dart';
import 'support/memory_repository.dart';

const identity = PartyMember(
    id: '',
    name: '冒険者',
    characterType: 'warrior',
    appearance: 'male',
    level: 3);

class FailingPartyConnection extends PartyConnection {
  bool rejectLeave = false;
  bool legacyDisband = false;
  @override
  void send(String type, [Map<String, dynamic> data = const {}]) {
    if (type == 'leave' && rejectLeave) throw StateError('transport closed');
    super.send(
        type == 'disband' && legacyDisband ? 'unsupported-disband' : type,
        data);
  }
}

Future<void> until(bool Function() check) async {
  for (var i = 0; i < 200 && !check(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  expect(check(), isTrue);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PartyServer server;
  late Uri uri;
  final clients = <PartyConnection>[];
  setUp(() async {
    server = PartyServer();
    await server.start(address: InternetAddress.loopbackIPv4, port: 0);
    uri = Uri.parse('ws://127.0.0.1:${server.port}/party');
  });
  tearDown(() async {
    for (final client in clients) {
      await client.leave();
      client.dispose();
    }
    clients.clear();
    await server.close();
  });
  Future<PartyConnection> client({String? code}) async {
    final connection = PartyConnection();
    clients.add(connection);
    await connection.connectForTest(uri, identity, code: code);
    return connection;
  }

  test('leave clears membership even when transport rejects the send',
      () async {
    final host = FailingPartyConnection();
    clients.add(host);
    await host.connectForTest(uri, identity);
    host.rejectLeave = true;
    await host.leave();
    expect(host.connected, isFalse);
    expect(host.code, isNull);
    expect(host.members, isEmpty);
    expect(host.error, isNull);
    await host.connectForTest(uri, identity);
    expect(host.connected, isTrue);
  });

  test('legacy disband rejection explains the failure and still allows exit',
      () async {
    final host = FailingPartyConnection()..legacyDisband = true;
    clients.add(host);
    await host.connectForTest(uri, identity);
    await expectLater(host.disband(), throwsStateError);
    expect(host.error, contains('サーバーが解散操作に対応していません'));
    expect(host.connected, isTrue);
    await host.leave();
    expect(host.connected, isFalse);
  });

  test(
      'code joins four real clients, rejects a fifth, synchronizes and locks a session',
      () async {
    final host = await client();
    final guests = <PartyConnection>[];
    for (var i = 0; i < 3; i++) {
      guests.add(await client(code: host.code));
    }
    await until(() => host.members.length == 4);
    expect(host.code, matches(RegExp(r'^[A-Z2-9]{6}$')));
    final extra = PartyConnection();
    clients.add(extra);
    await expectLater(
        extra.connectForTest(uri, identity, code: host.code), throwsStateError);
    expect(extra.connected, isFalse);
    host.start();
    await until(() => host.error != null);
    expect(host.session, isNull);
    guests.first.start();
    await until(() => guests.first.error != null);
    expect(guests.first.session, isNull);
    for (final connection in [host, ...guests]) {
      connection.setReady(true);
    }
    await until(() => host.members.every((m) => m.ready));
    host.setMinutes(15);
    await until(
        () => host.minutes == 15 && host.members.every((m) => !m.ready));
    for (final connection in [host, ...guests]) {
      connection.setReady(true);
    }
    await until(() => host.members.every((m) => m.ready));
    host.start();
    await until(() => [host, ...guests].every((c) => c.session != null));
    for (final guest in guests) {
      expect(guest.session!['id'], host.session!['id']);
      expect(guest.session!['startedAt'], host.session!['startedAt']);
      expect(guest.session!['members'], hasLength(4));
    }
    host.setMinutes(30);
    await until(() => host.error != null);
    expect(host.minutes, 15);
    await guests.last.disconnect();
    await until(() => host.members.any((m) => m.status == 'disconnected'));
    expect(host.session!['members'], hasLength(4));
    await expectLater(
        extra.connectForTest(uri, identity, code: host.code), throwsStateError);
  });
  test(
      'same code restores the member during focus, including after all peers disconnect',
      () async {
    final host = await client();
    final guest = await client(code: host.code);
    final code = host.code!;
    final originalId = guest.selfId;
    host.setReady(true);
    guest.setReady(true);
    await until(() => host.members.every((m) => m.ready));
    host.start();
    await until(() => guest.session != null);
    final sessionId = guest.session!['id'];
    await guest.disconnect();
    await until(() => !guest.connected);
    expect(guest.code, code);
    await guest.connectForTest(uri, identity, code: code);
    expect(guest.selfId, originalId);
    expect(guest.session!['id'], sessionId);
    expect(guest.members, hasLength(2));
    await host.disconnect();
    await guest.disconnect();
    await until(() => !host.connected && !guest.connected);
    await guest.connectForTest(uri, identity, code: code);
    expect(guest.selfId, originalId);
    expect(guest.session!['id'], sessionId);
    final stranger = PartyConnection();
    clients.add(stranger);
    await expectLater(
        stranger.connectForTest(uri, identity, code: code), throwsStateError);
  });
  test('leader exits waiting room: capacity freed and leadership transfers',
      () async {
    final host = await client();
    final code = host.code!;
    final guest = await client(code: code);
    await host.leave();
    await until(() => guest.isHost && guest.members.length == 1);
    final replacement = await client(code: code);
    await until(() => guest.members.length == 2);
    expect(replacement.isHost, isFalse);
  });
  test('only leader can disband; all members leave and old code is invalid',
      () async {
    final host = await client();
    final code = host.code!;
    final guest = await client(code: code);
    await expectLater(guest.disband(), throwsStateError);
    guest.send('disband');
    await until(() => guest.error != null);
    expect(host.connected, isTrue);
    expect(guest.connected, isTrue);
    await host.disband();
    await until(() => !host.connected && !guest.connected);
    for (final connection in [host, guest]) {
      expect(connection.code, isNull);
      expect(connection.members, isEmpty);
      expect(connection.session, isNull);
      expect(connection.error, isNull);
    }
    final stranger = PartyConnection();
    clients.add(stranger);
    await expectLater(
        stranger.connectForTest(uri, identity, code: code), throwsStateError);
    await host.connectForTest(uri, identity);
    expect(host.isHost, isTrue);
    expect(host.members, hasLength(1));
  });
  test('server rejects malformed identity and unknown code', () async {
    final socket = await WebSocket.connect(uri.toString());
    final response = socket.first;
    socket.add(jsonEncode({
      'type': 'create',
      'member': {'name': 'x'}
    }));
    expect(jsonDecode(await response as String)['type'], 'error');
    await socket.close();
    final connection = PartyConnection();
    clients.add(connection);
    await expectLater(connection.connectForTest(uri, identity, code: 'ZZZZZZ'),
        throwsStateError);
  });
  test(
      'two controllers persist the same session; disconnect never cancels or duplicates EXP',
      () async {
    final controllers = <GameController>[];
    var now = DateTime.now();
    try {
      for (var i = 0; i < 2; i++) {
        final controller = GameController(MemoryRepository(), clock: () => now);
        await controller.load();
        await controller.onboard(GameCatalog.types[15]!);
        controllers.add(controller);
      }
      final a = controllers[0], b = controllers[1];
      await a.party.connectForTest(uri, a.partyIdentity);
      await b.party.connectForTest(uri, b.partyIdentity, code: a.party.code);
      await a.prepareParty(true);
      await b.prepareParty(true);
      await until(() => a.party.members.every((m) => m.ready));
      a.party.start();
      await until(() =>
          a.activeFocus != null && b.activeFocus != null && !a.busy && !b.busy);
      expect(a.activeFocus!.id, b.activeFocus!.id);
      expect(a.activeFocus!.startedAt, b.activeFocus!.startedAt);
      expect(a.activeFocus!.partyMembers, hasLength(2));
      final restored = FocusSession.fromJson(
          jsonDecode(jsonEncode(a.activeFocus!.toJson()))
              as Map<String, dynamic>);
      expect(restored.partyMembers.map((m) => m.name),
          a.activeFocus!.partyMembers.map((m) => m.name));
      await a.party.disband();
      await until(() => !b.party.connected);
      expect(a.activeFocus!.status, FocusStatus.active);
      expect(b.activeFocus!.status, FocusStatus.active);
      expect(await a.finishFocus(), isNull);
      await a.finishFocus(cancel: true);
      expect(a.state!.activeCharacter!.currentExp, 0);
      expect(await a.finishFocus(cancel: true), isNull);
      now = b.activeFocus!.endsAt
          .subtract(Duration(milliseconds: b.activeFocus!.partyClockOffsetMs))
          .add(const Duration(seconds: 1));
      expect((await b.finishFocus())!.status, FocusStatus.succeeded);
      final awarded = b.state!.activeCharacter!.toJson();
      expect(await b.finishFocus(), isNull);
      expect(b.state!.activeCharacter!.toJson(), awarded);
      expect(b.state!.activeCharacter!.level, greaterThan(1));
    } finally {
      for (final controller in controllers) {
        await controller.party.leave();
        controller.dispose();
      }
    }
  });
  test(
      'old saves load, future shared start has zero progress and bounded remaining',
      () {
    final now = DateTime(2026, 10, 11);
    final old =
        FocusSession(id: 'old', startedAt: now, durationMinutes: 30).toJson()
          ..remove('partyMembers')
          ..remove('partyClockOffsetMs');
    expect(FocusSession.fromJson(old).partyMembers, isEmpty);
    final future = FocusSession(
        id: 'party',
        startedAt: now.add(const Duration(seconds: 3)),
        durationMinutes: 30,
        partyMembers: const [identity, identity]);
    expect(future.remaining(now), const Duration(minutes: 30));
  });
}
