import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/core/game_controller.dart';
import 'package:focusquest/core/theme/app_theme.dart';
import 'package:focusquest/data/game_catalog.dart';
import 'package:focusquest/features/focus/data/usage_monitor.dart';
import 'package:focusquest/features/settings/settings_screen.dart';
import 'package:focusquest/features/settings/settings_art.dart';
import 'support/memory_repository.dart';

class _Monitor extends UsageMonitor {
  int accessRequests = 0;
  int overlayRequests = 0;
  @override
  Future<bool> hasAccess() async => true;
  @override
  Future<Map<String, bool>?> guardPermissions() async =>
      {'overlay': true, 'usage': true};
  @override
  Future<void> requestAccess() async {
    accessRequests++;
  }

  @override
  Future<void> requestOverlay() async {
    overlayRequests++;
  }
}

Future<void> _save(GlobalKey key, String path) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 2);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes!.buffer.asUint8List());
  image.dispose();
}

void main() {
  setUpAll(() async {
    final font = await rootBundle.load('assets/fonts/NotoSerifJP.ttf');
    for (final family in ['SunlitSerif', 'Roboto']) {
      await (FontLoader(family)..addFont(Future.value(font))).load();
    }
    final icons = await rootBundle.load('fonts/MaterialIcons-Regular.otf');
    await (FontLoader('MaterialIcons')..addFont(Future.value(icons))).load();
  });
  for (final size in [
    const Size(470, 1000),
    const Size(390, 844),
    const Size(320, 568),
    const Size(844, 390)
  ]) {
    for (final scale in [1.0, 1.6]) {
      testWidgets('settings controls fit $size scale $scale', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final monitor = _Monitor();
        final controller = GameController(MemoryRepository(), monitor: monitor);
        await controller.load();
        await controller.onboard(GameCatalog.types[3]!, name: '守護者');
        final boundary = GlobalKey();
        await tester.pumpWidget(RepaintBoundary(
            key: boundary,
            child: MaterialApp(
                theme: AppTheme.dark,
                debugShowCheckedModeBanner: false,
                home: Scaffold(
                    body: SettingsScreen(controller: controller),
                    bottomNavigationBar:
                        SettingsNavigation(onSelect: (_) {})))));
        await tester.pumpAndSettle();
        for (final element in find.byType(Image).evaluate()) {
          await tester.runAsync(
              () => precacheImage((element.widget as Image).image, element));
        }
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('集中履歴'), findsNothing);
        expect(find.text('許可済み'), findsNWidgets(2));
        if (const bool.fromEnvironment('CAPTURE_SETTINGS') && scale == 1) {
          await tester.runAsync(() => _save(boundary,
              '../art/settings_ui_v001/preview-${size.width.toInt()}.png'));
        }
        final access = find.widgetWithText(SettingsArtButton, '設定を開く');
        await tester.ensureVisible(access.first);
        await tester.tap(access.first);
        await tester.pumpAndSettle();
        expect(monitor.accessRequests, 1);
        await tester.ensureVisible(access.last);
        await tester.tap(access.last);
        await tester.pumpAndSettle();
        expect(monitor.overlayRequests, 1);
        final reset = find.widgetWithText(SettingsArtButton, 'アプリをリセット');
        await tester.ensureVisible(reset);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(reset);
        await tester.pumpAndSettle();
        expect(find.text('アプリをリセットしますか？'), findsOneWidget);
        await tester.tap(find.text('キャンセル'));
        await tester.pumpAndSettle();
        expect(controller.state!.onboardingComplete, isTrue);
        await tester.pumpWidget(const SizedBox.shrink());
        controller.dispose();
      });
    }
  }
  testWidgets('export each settings icon independently', (tester) async {
    if (!const bool.fromEnvironment('CAPTURE_SETTINGS')) return;
    const icons = <String, IconData>{
      'shield': Icons.shield_rounded,
      'phone': Icons.smartphone_rounded,
      'overlay': Icons.grid_view_rounded,
      'music': Icons.music_note_rounded,
      'sound': Icons.volume_up_rounded,
      'cloud': Icons.cloud_outlined,
      'tools': Icons.handyman_rounded,
      'person': Icons.person_rounded,
      'reset': Icons.restart_alt_rounded,
      'warning': Icons.error_rounded,
      'home': Icons.home_outlined,
      'characters': Icons.people_alt_rounded,
      'settings': Icons.settings_rounded,
      'adventure': Icons.map_outlined,
      'chevron': Icons.chevron_right_rounded,
      'sparkle': Icons.auto_awesome,
    };
    tester.view.physicalSize = const Size(80, 80);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final entry in icons.entries) {
      final key = GlobalKey();
      await tester.pumpWidget(MaterialApp(
          home: Center(
              child: RepaintBoundary(
                  key: key,
                  child: SizedBox.square(
                      dimension: 64,
                      child: Icon(entry.value,
                          size: 48, color: settingsBrown))))));
      await tester.pumpAndSettle();
      await tester.runAsync(() => _save(
          key, '../art/settings_ui_v001/materials/icon-${entry.key}.png'));
    }
    final key = GlobalKey();
    await tester.pumpWidget(MaterialApp(
        home: Center(
            child: RepaintBoundary(
                key: key,
                child: const SettingsMedallion(
                    icon: Icons.smartphone_rounded, unit: 2, blue: true)))));
    await tester.pumpAndSettle();
    await tester.runAsync(() =>
        _save(key, '../art/settings_ui_v001/materials/phone-medallion.png'));
  });
}
