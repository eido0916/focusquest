import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../domain/party_member.dart';

/// One connection per app. The server owns membership, capacity and start time.
class PartyConnection extends ChangeNotifier {
  static const configuredUrl = String.fromEnvironment('PARTY_SERVER_URL',
      defaultValue: 'wss://focusquest-party.onrender.com/party');
  WebSocket? _socket;
  StreamSubscription<dynamic>? _subscription;
  bool _disposed = false;
  String? selfId, code, hostId, error;
  final Map<String, String> _resumeTokens = {};
  int focusAreaIndex = -1;
  List<int> get availableAreas => members.isEmpty
      ? []
      : members.first.unlockedAreas
          .where((a) => members.every((m) => m.unlockedAreas.contains(a)))
          .toList();
  String serverUrl = configuredUrl;
  bool connecting = false;
  int minutes = 30;
  List<PartyMember> members = const [];
  Map<String, dynamic>? session;
  Duration clockOffset = Duration.zero;
  Completer<void>? _joined;
  bool get connected => _socket != null && code != null;
  bool get isHost => connected && hostId == selfId;
  bool get ready => members.any((m) => m.id == selfId && m.ready);
  DateTime serverNow(DateTime now) => now.add(clockOffset);

  Future<void> connect(
      {required String url,
      required PartyMember member,
      String? joinCode}) async {
    if (connecting || connected) throw StateError('すでにパーティーに接続しています。');
    final uri = Uri.tryParse(url.trim());
    if (uri == null ||
        uri.host.isEmpty ||
        uri.scheme != 'wss' ||
        uri.userInfo.isNotEmpty) {
      throw ArgumentError('接続先には wss:// で始まるサーバーURLを指定してください。');
    }
    final normalized = joinCode?.trim().toUpperCase();
    if (normalized != null && !RegExp(r'^[A-Z2-9]{6}$').hasMatch(normalized)) {
      throw ArgumentError('パーティーコードは6文字です。');
    }
    await _open(uri, member, normalized);
  }

  /// Loopback is exposed only for automated integration tests.
  @visibleForTesting
  Future<void> connectForTest(Uri uri, PartyMember member, {String? code}) =>
      _open(uri, member, code);

  Future<void> _open(Uri uri, PartyMember member, String? joinCode) async {
    try {
      final directory = await getApplicationSupportDirectory();
      final file = File('${directory.path}/party-resume.json');
      final saved = await file.exists() ? await file.readAsString() : null;
      if (saved != null) {
        _resumeTokens
            .addAll(Map<String, String>.from(jsonDecode(saved) as Map));
      }
    } catch (_) {/* Unit tests may have no platform preferences. */}
    connecting = true;
    error = null;
    notifyListeners();
    try {
      final socket = await WebSocket.connect(uri.toString())
          // A free hosting instance may need about a minute to wake up.
          .timeout(const Duration(seconds: 90));
      if (_disposed) {
        await socket.close();
        throw StateError('接続を終了しました。');
      }
      socket.pingInterval = const Duration(seconds: 20);
      serverUrl = uri.toString();
      _socket = socket;
      _joined = Completer<void>();
      _subscription = socket.listen((raw) {
        if (!_disposed && _socket == socket) _receive(raw);
      },
          onDone: () => _disconnected(socket),
          onError: (_) => _disconnected(socket));
      socket.add(jsonEncode({
        'type': joinCode == null ? 'create' : 'join',
        'code': joinCode,
        'resumeToken': _resumeTokens['${uri.toString()}|$joinCode'],
        'member': member.toJson()
      }));
      await _joined!.future.timeout(const Duration(seconds: 10));
      serverUrl = uri.toString();
    } catch (failure) {
      final socket = _socket;
      _socket = null;
      await socket?.close();
      code = null;
      selfId = hostId = null;
      members = const [];
      session = null;
      if (failure is TimeoutException) {
        throw StateError('接続に時間がかかっています。少し待ってから再試行してください。');
      }
      if (failure is SocketException ||
          failure is HttpException ||
          failure is WebSocketException) {
        throw StateError('パーティーサーバーに接続できませんでした。通信状況を確認して再試行してください。');
      }
      rethrow;
    } finally {
      _joined = null;
      connecting = false;
      if (!_disposed) notifyListeners();
    }
  }

  void _receive(dynamic raw) {
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      if (data['type'] == 'error') {
        error = data['message'] as String;
        if (_joined != null && !_joined!.isCompleted) {
          _joined!.completeError(StateError(error!));
        }
      } else if (data['type'] == 'snapshot') {
        selfId = data['selfId'] as String;
        focusAreaIndex = data['focusAreaIndex'] as int? ?? -1;
        final token = data['resumeToken'] as String?;
        if (token != null) {
          _resumeTokens['$serverUrl|${data['code']}'] = token;
          unawaited(_saveTokens());
        }
        code = data['code'] as String;
        hostId = data['hostId'] as String;
        minutes = data['minutes'] as int;
        members = (data['members'] as List)
            .map((m) =>
                PartyMember.fromJson(Map<String, dynamic>.from(m as Map)))
            .toList();
        session = data['session'] == null
            ? null
            : Map<String, dynamic>.from(data['session'] as Map);
        clockOffset = DateTime.parse(data['serverTime'] as String)
            .difference(DateTime.now());
        error = null;
        if (_joined != null && !_joined!.isCompleted) _joined!.complete();
      }
      notifyListeners();
    } catch (_) {
      error = 'サーバーからの応答を読み込めませんでした。';
      notifyListeners();
    }
  }

  void _disconnected(WebSocket socket) {
    if (_socket != socket) return;
    _socket = null;
    if (_joined != null && !_joined!.isCompleted) {
      _joined!.completeError(StateError('パーティーへの接続が切れました。'));
    }
    error = '接続が切れました。開始済みの集中は端末で継続します。';
    notifyListeners();
  }

  void send(String type, [Map<String, dynamic> data = const {}]) {
    if (!connected) throw StateError('パーティーに接続してください。');
    _socket!.add(jsonEncode({'type': type, ...data}));
  }

  void setReady(bool value) => send('ready', {'ready': value});
  Future<void> _saveTokens() async {
    try {
      final directory = await getApplicationSupportDirectory();
      await directory.create(recursive: true);
      await File('${directory.path}/party-resume.json')
          .writeAsString(jsonEncode(_resumeTokens), flush: true);
    } catch (_) {}
  }

  void setArea(int value) => send('area', {'focusAreaIndex': value});
  void setMinutes(int value) => send('duration', {'minutes': value});
  void start() => send('start');
  void report(String status) {
    // Presence must never turn a successfully saved focus result into an error.
    if (connected && session != null && _socket!.readyState == WebSocket.open) {
      try {
        send('status', {'status': status});
      } catch (_) {
        // The saved timer and reward remain valid after a network disconnect.
      }
    }
  }

  /// Drop transport while retaining the membership token for reconnection.
  Future<void> disconnect() async {
    final socket = _socket;
    await socket?.close();
  }

  Future<void> leave() async {
    final socket = _socket;
    if (connected) send('leave');
    _resumeTokens.remove('$serverUrl|$code');
    unawaited(_saveTokens());
    _socket = null;
    await _subscription?.cancel();
    _subscription = null;
    code = selfId = hostId = null;
    members = const [];
    session = null;
    error = null;
    notifyListeners();
    await socket?.close();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    _socket?.close();
    _socket = null;
    super.dispose();
  }
}
