import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/core/game_controller.dart';
import 'package:focusquest/core/theme/app_theme.dart';
import 'package:focusquest/data/game_catalog.dart';
import 'package:focusquest/features/party/data/party_connection.dart';
import 'package:focusquest/features/party/domain/party_member.dart';
import 'package:focusquest/features/party/presentation/party_page.dart';
import 'package:focusquest/features/party/presentation/party_lobby_art.dart';
import '../../server/party_server.dart';
import 'support/memory_repository.dart';

Future<void> images(WidgetTester tester) async {
  for (final element in find.byType(Image).evaluate()) {
    await tester.runAsync(
        () => precacheImage((element.widget as Image).image, element));
  }
  await tester.pumpAndSettle();
}

Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_LOBBY')) return;
  await tester.runAsync(() async {
    final render =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await render.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('../output/party-lobby/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> until(WidgetTester tester, bool Function() check) async {
  for (var i = 0; i < 200 && !check(); i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await tester.pump();
  }
  expect(check(), isTrue);
}

void main() {
  setUpAll(() async {
    for (final entry in {
      'SunlitSerif': 'assets/fonts/NotoSerifJP.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf'
    }.entries) {
      await (FontLoader(entry.key)..addFont(rootBundle.load(entry.value)))
          .load();
    }
  });
  for (final size in [
    const Size(390, 844),
    const Size(470, 836),
    const Size(320, 568),
    const Size(844, 390)
  ]) {
    for (final scale in [1.0, 1.6]) {
      testWidgets(
          'entry has no duration settings; join dialog at $size scale $scale',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final controller = GameController(MemoryRepository());
        await controller.load();
        await controller.onboard(GameCatalog.types[1]!, name: 'まさし');
        final key = GlobalKey();
        await tester.pumpWidget(MaterialApp(
            theme: AppTheme.dark,
            debugShowCheckedModeBanner: false,
            home: RepaintBoundary(
                key: key, child: PartyPage(controller: controller))));
        await images(tester);
        expect(find.text('オンライン接続の設定'), findsNothing);
        if (size.width == 390 && scale == 1) {
          await capture(tester, key, 'entry');
        }
        if (size.width == 470 && scale == 1) {
          await capture(tester, key, 'entry-reference');
        }
        expect(find.text('集中時間の設定'), findsNothing);
        expect(find.byType(ChoiceChip), findsNothing);
        expect(find.byKey(const Key('party-create')), findsOneWidget);
        await tester.ensureVisible(find.text('コードで参加'));
        await tester.tap(find.text('コードで参加'));
        await tester.pumpAndSettle();
        expect(find.text('パーティーコード'), findsOneWidget);
        expect(
            tester
                .widget<TextButton>(find.widgetWithText(TextButton, '参加する'))
                .onPressed,
            isNull);
        await tester.enterText(find.byType(TextField), 'ab23cd');
        await tester.pumpAndSettle();
        expect(
            tester
                .widget<TextButton>(find.widgetWithText(TextButton, '参加する'))
                .onPressed,
            isNotNull);
        if (size.width == 390 && scale == 1) await capture(tester, key, 'join');
        await tester.tap(find.text('キャンセル'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        controller.dispose();
      });
    }
  }
  for (final (count, size, scale, guest) in [
    (2, const Size(390, 1100), 1.0, false),
    (4, const Size(390, 1100), 1.0, false),
    (4, const Size(320, 568), 1.6, false),
    (2, const Size(390, 844), 1.0, true),
    (4, const Size(844, 390), 1.0, false),
  ]) {
    testWidgets('live lobby $count members $size scale $scale guest $guest',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final controller = GameController(MemoryRepository());
      await controller.load();
      await controller.onboard(GameCatalog.types[1]!, name: 'まさし');
      final server = PartyServer();
      final other = <PartyConnection>[];
      await tester.runAsync(() async {
        await server.start(address: InternetAddress.loopbackIPv4, port: 0);
        final uri = Uri.parse('ws://127.0.0.1:${server.port}/party');
        final host = guest ? PartyConnection() : controller.party;
        if (guest) other.add(host);
        await host.connectForTest(uri, controller.partyIdentity);
        for (var i = 1; i < count; i++) {
          final client = guest && i == 1 ? controller.party : PartyConnection();
          if (client != controller.party) other.add(client);
          await client.connectForTest(
              uri,
              PartyMember(
                  id: '',
                  name: ['まさし', 'ルーナ', 'カイト', 'ユリ'][i],
                  characterType: ['warrior', 'onmyoji', 'ranger', 'mage'][i],
                  appearance: i.isOdd ? 'female' : 'male',
                  level: 5 + i),
              code: host.code);
        }
      });
      await until(tester, () => controller.party.members.length == count);
      final key = GlobalKey();
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.dark,
          debugShowCheckedModeBanner: false,
          home: RepaintBoundary(
              key: key, child: PartyPage(controller: controller))));
      await images(tester);
      expect(find.byType(LobbyMemberCard), findsNWidgets(4));
      if (size.width == 390 && !guest) {
        await capture(tester, key, 'lobby-$count');
      }
      await tester.ensureVisible(find.widgetWithText(ChoiceChip, '15分'));
      if (guest) {
        expect(
            tester
                .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '15分'))
                .onSelected,
            isNull);
      } else {
        controller.party.setReady(true);
        await until(tester, () => controller.party.ready);
        await tester.tap(find.widgetWithText(ChoiceChip, '15分'));
        await until(tester,
            () => controller.party.minutes == 15 && !controller.party.ready);
        expect(controller.party.members.every((m) => !m.ready), isTrue);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() async {
        await controller.party.leave();
        for (final client in other) {
          await client.leave();
          client.dispose();
        }
        await server.close();
      });
      controller.dispose();
    });
  }
}
