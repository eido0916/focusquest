import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/core/game_controller.dart';
import 'package:focusquest/core/theme/app_theme.dart';
import 'package:focusquest/core/widgets/quest_widgets.dart';
import 'package:focusquest/data/game_catalog.dart';
import 'package:focusquest/features/home/home_screen.dart';
import 'package:focusquest/features/diagnosis/presentation/job_portrait.dart';
import 'package:focusquest/features/focus/presentation/focus_timer_scene.dart';
import 'support/memory_repository.dart';

const previewRoot = String.fromEnvironment('REFERENCE_CAPTURE_DIRECTORY',
    defaultValue: '../art/home_focus_ui_v002/previews');
Future<void> preload(WidgetTester tester) async {
  await tester.pumpAndSettle();
  for (final element in find.byType(Image).evaluate()) {
    await tester.runAsync(
        () => precacheImage((element.widget as Image).image, element));
  }
  await tester.pumpAndSettle();
}

Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_REFERENCE')) return;
  await tester.runAsync(() async {
    final render =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await render.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('$previewRoot/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    if (name.startsWith('home-')) {
      final geometry = <String, Object>{};
      for (final id in [
        'home-scroll',
        'home-identity',
        'home-showcase',
        'home-start-focus',
        'home-adventure'
      ]) {
        final rect = tester.getRect(find.byKey(Key(id)));
        geometry[id] = {
          'x': rect.left,
          'y': rect.top,
          'width': rect.width,
          'height': rect.height
        };
      }
      await File('$previewRoot/$name.geometry.json')
          .writeAsString(jsonEncode(geometry));
    }
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    final font = await rootBundle.load('assets/fonts/NotoSerifJP.ttf');
    await (FontLoader('SunlitSerif')..addFont(Future.value(font))).load();
    final icons = await rootBundle.load('fonts/MaterialIcons-Regular.otf');
    await (FontLoader('MaterialIcons')..addFont(Future.value(icons))).load();
  });
  for (final size in [
    const Size(280, 653),
    const Size(430, 932),
    const Size(768, 1024),
    const Size(390, 844),
    const Size(320, 568),
    const Size(390, 1150),
    const Size(844, 390),
    const Size(1280, 800)
  ]) {
    for (final scale in [1.0, 1.6, 2.0]) {
      for (final screen in ['home', 'timer']) {
        testWidgets(
            '$screen reference layout ${size.width.toInt()}x${size.height.toInt()} scale $scale',
            (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final repo = MemoryRepository();
          final controller = GameController(repo);
          await controller.load();
          await controller.onboard(
              GameCatalog.types.values.firstWhere((t) => t.typeId == 'warrior'),
              name: scale == 1 ? 'a' : 'とても長い冒険者の名前の表示を確認',
              appearance: size.width == 320 ? 'female' : 'male');
          final hero = repo.state.activeCharacter!;
          repo.state = repo.state.copyWith(characters: {
            hero.id: hero.copyWith(level: 25, currentExp: 1120)
          });
          await controller.load();
          final boundary = GlobalKey();
          var primary = 0, sound = 0, cancel = 0, back = 0;
          int? navigation;
          final page = screen == 'home'
              ? Scaffold(
                  body: HomeScreen(
                      controller: controller,
                      onFocus: () => primary++,
                      onNavigate: (i) => navigation = i),
                  bottomNavigationBar: QuestNavigation(
                      selected: 0, onSelect: (i) => navigation = i))
              : FocusTimerScene(
                  characterName: 'not shown',
                  characterType: 'warrior',
                  level: 25,
                  chapter: 1,
                  durationSeconds: 1800,
                  seconds: 1785,
                  progress: 15 / 1800,
                  onBattle: () => primary++,
                  onCancel: () => cancel++,
                  onSound: () => sound++,
                  onBack: () => back++);
          await tester.pumpWidget(RepaintBoundary(
              key: boundary,
              child: MaterialApp(
                  theme: AppTheme.dark,
                  debugShowCheckedModeBanner: false,
                  home: page)));
          await preload(tester);
          expect(tester.takeException(), isNull);
          if (screen == 'home') {
            final standing =
                tester.widget<JobPortrait>(find.byType(JobPortrait));
            expect(standing.lobby, isTrue);
            final image = tester.widget<Image>(find.descendant(
                of: find.byType(JobPortrait), matching: find.byType(Image)));
            expect((image.image as AssetImage).assetName,
                contains('lobby/portraits/'));
            final name =
                tester.getRect(find.byKey(const Key('home-character-name')));
            final level = tester.getRect(find.text('Lv. 25'));
            expect(name.overlaps(level), isFalse);
            final panel =
                tester.getRect(find.byKey(const Key('home-identity')));
            expect(panel.contains(name.topLeft), isTrue);
            expect(panel.contains(level.bottomRight), isTrue);
            expect(
                tester.getSize(find.byKey(const Key('home-exp-fill'))).height,
                greaterThan(0));
            await capture(tester, boundary,
                'home-${size.width.toInt()}x${size.height.toInt()}-${scale == 1 ? '1' : '1.6'}');
            await tester
                .ensureVisible(find.byKey(const Key('home-start-focus')));
            await tester.tap(find.byKey(const Key('home-start-focus')));
            await tester.pump();
            expect(primary, 1);
            await tester.ensureVisible(find.byKey(const Key('home-adventure')));
            await tester.tap(find.byKey(const Key('home-adventure')));
            await tester.pump();
            expect(navigation, 2);
          } else {
            expect(find.text('29:45'), findsOneWidget);
            expect(find.text('経過 00:15 / 30:00'), findsOneWidget);
            expect(find.text('not shown'), findsNothing);
            expect(find.text('Lv. 25'), findsNothing);
            expect(
                tester
                    .getSize(find.byKey(const Key('focus-progress-fill')))
                    .height,
                greaterThan(0));
            await capture(tester, boundary,
                'timer-${size.width.toInt()}x${size.height.toInt()}-${scale == 1 ? '1' : '1.6'}');
            for (final key in [
              'focus-watch-battle',
              'focus-sound',
              'focus-cancel'
            ]) {
              await tester.ensureVisible(find.byKey(Key(key)));
              await tester.tap(find.byKey(Key(key)));
              await tester.pump();
            }
            expect(primary, 1);
            expect(sound, 1);
            expect(cancel, 1);
            await tester.ensureVisible(find.byTooltip('戻る'));
            await tester.tap(find.byTooltip('戻る'));
            await tester.pump();
            expect(back, 1);
          }
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          controller.dispose();
        });
      }
    }
  }
}
