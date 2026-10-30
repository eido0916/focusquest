import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/core/game_controller.dart';
import 'package:focusquest/core/theme/app_theme.dart';
import 'package:focusquest/features/party/presentation/party_lobby_art.dart';
import 'package:focusquest/data/game_catalog.dart';
import 'package:focusquest/features/party/data/party_connection.dart';
import 'package:focusquest/features/party/domain/party_member.dart';
import 'package:focusquest/features/party/presentation/party_page.dart';
import '../../server/party_server.dart';
import 'support/memory_repository.dart';

class LoopbackPartyConnection extends PartyConnection {
  LoopbackPartyConnection(this.uri);
  final Uri uri;
  @override
  Future<void> connect(
          {required String url,
          required PartyMember member,
          String? joinCode}) =>
      // Real sockets need real heartbeat timers, including after a fake-time
      // dialog animation completes and invokes this method.
      runZoned(() => connectForTest(uri, member, code: joinCode),
          zoneSpecification: ZoneSpecification(
              createTimer: (self, parent, zone, duration, callback) => Zone.root
                  .createTimer(duration, () => zone.runGuarded(callback)),
              createPeriodicTimer: (self, parent, zone, duration, callback) =>
                  Zone.root.createPeriodicTimer(duration,
                      (timer) => zone.runUnaryGuarded(callback, timer))));
}

Future<void> networkUntil(WidgetTester tester, bool Function() check) async {
  for (var i = 0; i < 150 && !check(); i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump();
  }
  expect(check(), true);
  await tester.pump();
}

Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_PARTY')) return;
  await tester.runAsync(() async {
    for (final image in tester.widgetList<Image>(find.byType(Image))) {
      await precacheImage(image.image, tester.element(find.byType(Scaffold)));
    }
  });
  await tester.pump(const Duration(milliseconds: 300));
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    final file = File('build/party-review/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = await rootBundle.load('assets/fonts/NotoSerifJP.ttf');
    for (final family in ['SunlitSerif', 'Roboto', 'serif', 'Ahem']) {
      await (FontLoader(family)..addFont(Future.value(font))).load();
    }
    final icons = await rootBundle.load('fonts/MaterialIcons-Regular.otf');
    await (FontLoader('MaterialIcons')..addFont(Future.value(icons))).load();
  });

  for (final size in [const Size(390, 844), const Size(960, 720)]) {
    testWidgets('create and code entry fit $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = GameController(MemoryRepository());
      await controller.load();
      await controller.onboard(GameCatalog.types[15]!);
      final key = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(
          key: key,
          child: MaterialApp(
              theme: AppTheme.dark,
              debugShowCheckedModeBanner: false,
              home: PartyPage(controller: controller))));
      expect(
          tester
              .widget<InkWell>(find.descendant(
                  of: find.byKey(const Key('party-join')),
                  matching: find.byType(InkWell)))
              .onTap,
          isNotNull);
      await tester.tap(find.byKey(const Key('party-join')));
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<TextButton>(find.byKey(const Key('party-join-submit')))
              .onPressed,
          isNull);
      await tester.enterText(
          find.byKey(const Key('party-code-input')), 'ab2cd3');
      await tester.pump();
      expect(
          tester
              .widget<TextField>(find.byKey(const Key('party-code-input')))
              .controller!
              .text,
          'AB2CD3');
      expect(
          tester
              .widget<TextButton>(find.byKey(const Key('party-join-submit')))
              .onPressed,
          isNotNull);
      expect(find.text('オンライン接続の設定'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();
      await capture(tester, key, 'entry-${size.width.toInt()}');
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    });
  }

  testWidgets(
      'UI creates, joins four, rejects full room and transfers leadership',
      (tester) async {
    tester.view.physicalSize = const Size(960, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final server = PartyServer();
    final controllers = <GameController>[];
    await tester.runAsync(() async {
      await server.start(address: InternetAddress.loopbackIPv4, port: 0);
      for (var i = 0; i < 5; i++) {
        final controller = GameController(MemoryRepository(),
            party: LoopbackPartyConnection(
                Uri.parse('ws://127.0.0.1:${server.port}/party')));
        await controller.load();
        await controller.onboard(GameCatalog.types[15]!, name: '冒険者${i + 1}');
        controllers.add(controller);
      }
    });
    final key = GlobalKey();
    Future<void> show(GameController controller) =>
        tester.pumpWidget(RepaintBoundary(
            key: key,
            child: MaterialApp(
                key: ValueKey(controller),
                theme: AppTheme.dark,
                debugShowCheckedModeBanner: false,
                home: PartyPage(
                    key: ValueKey(controller), controller: controller))));
    try {
      final host = controllers.first;
      await show(host);
      await tester
          .runAsync(() => tester.tap(find.byKey(const Key('party-create'))));
      await networkUntil(
          tester, () => host.party.connected && !host.party.connecting);
      await tester.pumpAndSettle();
      final code = host.party.code!;
      expect(code, matches(RegExp(r'^[A-Z2-9]{6}$')));
      expect(find.text('1 / 4人'), findsOneWidget);
      expect(find.byKey(const Key('party-slot-3')), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('party-start')));
      expect(
          tester
              .widget<LobbyAction>(find.byKey(const Key('party-start')))
              .onTap,
          isNull);
      await tester.drag(
          find.byKey(const Key('party-lobby-list')), const Offset(0, 1500));
      await tester.pumpAndSettle();
      for (var i = 1; i < 4; i++) {
        await show(controllers[i]);
        await tester.tap(find.byKey(const Key('party-join')));
        await tester.pumpAndSettle();
        await tester.enterText(
            find.byKey(const Key('party-code-input')), code.toLowerCase());
        await tester.pump();
        await tester.runAsync(
            () => tester.tap(find.byKey(const Key('party-join-submit'))));
        await networkUntil(
            tester,
            () =>
                controllers[i].party.connected &&
                !controllers[i].party.connecting);
        await tester.pumpAndSettle();
      }
      await networkUntil(tester, () => host.party.members.length == 4);
      await show(host);
      await tester.pump();
      expect(find.text('4 / 4人'), findsOneWidget);
      expect(find.text('あなた'), findsOneWidget);
      await capture(tester, key, 'four-members');
      final fifth = controllers.last;
      await show(fifth);
      await tester.tap(find.byKey(const Key('party-join')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('party-code-input')), code);
      await tester.pump();
      await tester.runAsync(
          () => tester.tap(find.byKey(const Key('party-join-submit'))));
      await networkUntil(
          tester,
          () =>
              !fifth.party.connecting &&
              find.byKey(const Key('party-error')).evaluate().isNotEmpty);
      expect(fifth.party.connected, false);
      expect(find.textContaining('パーティーは満員です（最大4人）。'), findsOneWidget);
      expect(host.party.members.length, 4);
      await show(host);
      expect(
          find.byKey(const Key('party-leave')).hitTestable(), findsOneWidget);
      await tester.pump();
      await tester
          .runAsync(() => tester.tap(find.byKey(const Key('party-leave'))));
      await networkUntil(
          tester, () => !host.party.connected && controllers[1].party.isHost);
      expect(controllers[1].party.members.length, 3);
      expect(find.byKey(const Key('party-create')), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(() async {
        // Close all clients together so a rejected client's close handshake
        // cannot hold up cleanup while the server is still awaiting its peers.
        for (final controller in controllers) {
          controller.dispose();
        }
        await server.close();
      });
    }
  });
}
