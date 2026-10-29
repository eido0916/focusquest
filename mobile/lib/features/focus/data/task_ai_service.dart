import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../domain/focus_task.dart';

class TaskAiException implements Exception {
  const TaskAiException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Calls our server, never Gemini directly; API keys stay on the server.
class TaskAiService {
  TaskAiService({Uri? endpoint, this.timeout = const Duration(seconds: 65)})
      : endpoint = endpoint ??
            Uri.parse(const String.fromEnvironment('TASK_AI_URL',
                defaultValue: 'http://127.0.0.1:8787/task-allocation'));
  final Uri endpoint;
  final Duration timeout;

  Future<FocusTask> assess(String input) async {
    final title = input.trim();
    if (title.isEmpty || title.runes.length > 80) {
      throw const TaskAiException('タスク名は1〜80文字で入力してください。');
    }
    final loopback = ['localhost', '127.0.0.1', '::1'].contains(endpoint.host);
    if (endpoint.scheme != 'https' &&
        !(loopback && endpoint.scheme == 'http')) {
      throw const TaskAiException('AI接続先にはHTTPSが必要です。');
    }
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      return await (() async {
        final request = await client.postUrl(endpoint);
        request.followRedirects = false;
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode({'title': title}));
        final response = await request.close();
        final bytes = <int>[];
        await for (final chunk in response) {
          bytes.addAll(chunk);
          if (bytes.length > 32768) throw const FormatException();
        }
        if (response.statusCode == 503) {
          throw const TaskAiException(
              'Gemini APIの接続設定が必要です。設定後にアプリを起動し直してください。');
        }
        if (response.statusCode == 401) {
          throw const TaskAiException(
              'Gemini APIキーを確認してください。キーの有効性や利用権限を確認後、アプリを起動し直してください。');
        }
        if (response.statusCode == 429) {
          throw const TaskAiException(
              'Geminiの利用上限に達したか、混み合っています。時間をおいて再試行してください。');
        }
        if (response.statusCode == 422) {
          throw const TaskAiException('取り組む内容をもう少し具体的に入力してください。');
        }
        if (response.statusCode != 200) {
          throw const TaskAiException('AI判定に失敗しました。再試行してください。');
        }
        final task = FocusTask.fromJson(
            Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map));
        if (task.title != title ||
            !task.isAiAssessed ||
            task.allocation.keys.toSet().length !=
                FocusTask.parameters.length ||
            task.reason!.runes.length > 240 ||
            (task.model?.isEmpty ?? true)) {
          throw const FormatException();
        }
        return task;
      })()
          .timeout(timeout);
    } on TaskAiException {
      rethrow;
    } on TimeoutException {
      throw const TaskAiException('AI判定が時間切れになりました。再試行してください。');
    } on SocketException {
      throw const TaskAiException('AI判定サーバーに接続できません。接続設定やネットワークを確認してください。');
    } catch (_) {
      throw const TaskAiException('AI判定の結果を確認できませんでした。再試行してください。');
    } finally {
      client.close(force: true);
    }
  }
}
