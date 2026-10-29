import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/features/focus/data/task_ai_service.dart';
import 'package:focusquest/features/focus/domain/focus_task.dart';
import '../../server/task_ai_server.dart';

Map<String, int> allocation() => {
      'knowledge': 6,
      'creativity': 0,
      'discipline': 2,
      'vitality': 0,
      'insight': 2,
      'empathy': 0
    };
Map<String, dynamic> judgment() => {
      'assessable': true,
      'reason': '読解で知識を深め、要約で洞察力を育てます。',
      'allocation': allocation()
    };
Map<String, dynamic> response(Map<String, dynamic> data) => {
      'candidates': [
        {
          'finishReason': 'STOP',
          'content': {
            'parts': [
              {'text': jsonEncode(data)}
            ]
          }
        }
      ]
    };

void main() {
  test(
      'real HTTP gateway sends structured Gemini request and preserves AI result',
      () async {
    final upstream = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => upstream.close(force: true));
    Map? sent;
    upstream.listen((request) async {
      expect(request.headers.value('x-goog-api-key'), 'test-key');
      expect(request.uri.queryParameters.containsKey('key'), isFalse);
      sent = jsonDecode(await utf8.decoder.bind(request).join()) as Map;
      request.response.write(jsonEncode(response(judgment())));
      await request.response.close();
    });
    final gateway = TaskAiServer(GeminiTaskAssessor(
        apiKey: 'test-key',
        model: 'test-model',
        apiUrl: Uri.parse(
            'http://127.0.0.1:${upstream.port}/v1beta/models/test-model:generateContent')));
    await gateway.start(port: 0);
    addTearDown(gateway.close);
    final task = await TaskAiService(
            endpoint:
                Uri.parse('http://127.0.0.1:${gateway.port}/task-allocation'))
        .assess('  英語の長文を読み要約する  ');
    expect(task.isAiAssessed, isTrue);
    expect(task.title, '英語の長文を読み要約する');
    expect(task.gains(30), {'knowledge': 180, 'discipline': 60, 'insight': 60});
    expect(FocusTask.fromJson(task.toJson()).reason, task.reason);
    expect(task.allocationSource, 'gemini');
    expect(sent!.containsKey('tools'), isFalse);
    expect(
        (sent!['generationConfig'] as Map)['responseFormat']['text']
            ['mimeType'],
        'APPLICATION_JSON');
    expect(sent!['contents'][0]['parts'][0]['text'],
        jsonEncode({'task': task.title}));
    expect(sent!.containsKey('apiKey'), isFalse);
  });

  test('same task reuses validated result without spending another request',
      () async {
    final upstream = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => upstream.close(force: true));
    var calls = 0;
    upstream.listen((request) async {
      await request.drain<void>();
      calls++;
      request.response.write(jsonEncode(response(judgment())));
      await request.response.close();
    });
    final assessor = GeminiTaskAssessor(
        apiKey: 'test-key',
        apiUrl: Uri.parse('http://127.0.0.1:${upstream.port}'));
    final first = await assessor.assess('読書');
    final second = await assessor.assess('読書');
    expect(first.toJson(), second.toJson());
    expect(calls, 1);
    await assessor.assess('英語の勉強');
    expect(calls, 2);
  });

  test(
      'quota and invalid key errors are not retried or sent to a paid fallback',
      () async {
    for (final status in [429, 403]) {
      final upstream = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      var calls = 0;
      upstream.listen((request) async {
        await request.drain<void>();
        calls++;
        request.response.statusCode = status;
        await request.response.close();
      });
      final gateway = TaskAiServer(GeminiTaskAssessor(
          apiKey: 'test-key',
          apiUrl: Uri.parse('http://127.0.0.1:${upstream.port}')));
      await gateway.start(port: 0);
      try {
        await expectLater(
            TaskAiService(
                    endpoint: Uri.parse(
                        'http://127.0.0.1:${gateway.port}/task-allocation'))
                .assess('読書'),
            throwsA(isA<TaskAiException>().having((e) => e.message, 'message',
                contains(status == 429 ? '利用上限' : 'APIキー'))));
        expect(calls, 1);
      } finally {
        await gateway.close();
        await upstream.close(force: true);
      }
    }
  });

  test('new Gemini tasks and old OpenAI tasks both restore from saved JSON',
      () {
    for (final provider in ['gemini', 'openai']) {
      final task = FocusTask(
          title: '読書',
          allocation: allocation(),
          allocationSource: provider,
          reason: '読解力を育てます。',
          model: 'test',
          rubricVersion: 1);
      expect(FocusTask.fromJson(task.toJson()).isAiAssessed, isTrue);
    }
    expect(GeminiTaskAssessor(apiKey: 'test-key').apiUrl.toString(),
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash-lite:generateContent');
  });

  test('invalid sum retries once and never invents a fallback', () async {
    final upstream = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => upstream.close(force: true));
    var calls = 0;
    upstream.listen((request) async {
      await request.drain<void>();
      calls++;
      final data = judgment();
      (data['allocation'] as Map)['knowledge'] = 10;
      request.response.write(jsonEncode(response(data)));
      await request.response.close();
    });
    final assessor = GeminiTaskAssessor(
        apiKey: 'test-key',
        apiUrl: Uri.parse('http://127.0.0.1:${upstream.port}'));
    await expectLater(
        assessor.assess('読書'),
        throwsA(isA<TaskAssessmentFailure>()
            .having((e) => e.status, 'status', 502)));
    expect(calls, 2);
  });

  test('refusal and ambiguous input are actionable errors', () async {
    for (final output in [
      response({...judgment(), 'assessable': false}),
      {
        'promptFeedback': {'blockReason': 'SAFETY'}
      },
    ]) {
      final upstream = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      upstream.listen((request) async {
        await request.drain<void>();
        request.response.write(jsonEncode(output));
        await request.response.close();
      });
      try {
        await expectLater(
            GeminiTaskAssessor(
                    apiKey: 'test-key',
                    apiUrl: Uri.parse('http://127.0.0.1:${upstream.port}'))
                .assess('何か'),
            throwsA(isA<TaskAssessmentFailure>()
                .having((e) => e.status, 'status', 422)));
      } finally {
        await upstream.close(force: true);
      }
    }
  });

  test('gateway without a key fails clearly and blocks browser-origin requests',
      () async {
    final gateway = TaskAiServer(GeminiTaskAssessor(apiKey: ''));
    await gateway.start(port: 0);
    addTearDown(gateway.close);
    final url = Uri.parse('http://127.0.0.1:${gateway.port}/task-allocation');
    await expectLater(
        TaskAiService(endpoint: url).assess('読書'),
        throwsA(isA<TaskAiException>()
            .having((e) => e.message, 'message', contains('接続設定'))));
    final client = HttpClient();
    addTearDown(() => client.close(force: true));
    final request = await client.postUrl(url);
    request.headers.set('origin', 'https://example.com');
    final result = await request.close();
    expect(result.statusCode, 403);
    await result.drain<void>();
  });

  test('client rejects mismatched title and invalid AI provenance', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      await request.drain<void>();
      request.response.write(jsonEncode(
          FocusTask(title: '別のタスク', allocation: allocation()).toJson()));
      await request.response.close();
    });
    await expectLater(
        TaskAiService(endpoint: Uri.parse('http://127.0.0.1:${server.port}'))
            .assess('読書'),
        throwsA(isA<TaskAiException>()));
    await expectLater(
        TaskAiService(endpoint: Uri.parse('http://example.com')).assess('読書'),
        throwsA(isA<TaskAiException>()));
  });
}
