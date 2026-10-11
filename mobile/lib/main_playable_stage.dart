import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/playable_stage/demo/demo_character_selection_page.dart';
import 'features/playable_stage/presentation/playable_stage_selection_page.dart';

const demoCharacterSelectionEnabled =
    bool.fromEnvironment('DEMO_CHARACTER_SELECTION', defaultValue: true);

/// Native standalone demo; no onboarding, browser, server, or persisted rewards.
void main() => runApp(MaterialApp(
    title: 'Focus Quest ステージ選択',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.dark,
    home: demoCharacterSelectionEnabled
        ? const DemoCharacterSelectionPage()
        : const PlayableStageSelectionPage()));
