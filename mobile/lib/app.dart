import 'package:flutter/material.dart';
import 'core/game_controller.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/quest_widgets.dart';
import 'features/character/presentation/character_screen.dart';
import 'features/diagnosis/presentation/diagnosis_screen.dart';
import 'features/focus/presentation/focus_screen.dart';
import 'features/home/home_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/settings/settings_art.dart';
import 'features/adventure/presentation/adventure_screen.dart';

class FocusQuestApp extends StatelessWidget {
  const FocusQuestApp({super.key, required this.controller});
  final GameController controller;
  @override
  Widget build(BuildContext context) => MaterialApp(
      title: 'FocusQuest',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            if (controller.startupError != null) {
              return Scaffold(
                  body: Center(
                      child: Padding(
                          padding: const EdgeInsets.all(24),
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            Text(controller.startupError!),
                            FilledButton(
                                onPressed: controller.load,
                                child: const Text('再試行'))
                          ]))));
            }
            if (controller.state == null) {
              return const Scaffold(
                  body: Center(child: CircularProgressIndicator()));
            }
            if (!controller.state!.onboardingComplete) {
              return DiagnosisScreen(
                  onComplete: (type, name, appearance) => controller
                      .onboard(type, name: name, appearance: appearance));
            }
            return QuestShell(controller: controller);
          }));
}

class QuestShell extends StatefulWidget {
  const QuestShell({super.key, required this.controller});
  final GameController controller;
  @override
  State<QuestShell> createState() => _QuestShellState();
}

class _QuestShellState extends State<QuestShell> {
  int _tab = 0;
  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    void focus() => Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (context) => AnimatedBuilder(
            animation: controller,
            builder: (_, __) => FocusScreen(controller: controller))));
    final pages = [
      HomeScreen(
          controller: controller,
          onFocus: focus,
          onNavigate: (tab) => setState(() => _tab = tab)),
      CharacterScreen(controller: controller),
      SettingsScreen(controller: controller),
      AdventureScreen(controller: controller)
    ];
    return Scaffold(
        body: SafeArea(
            child: _tab == 1 || _tab == 2
                ? pages[_tab]
                : QuestBackdrop(
                    dim: _tab == 0 ? 0 : .14,
                    child: Center(
                        child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 640),
                            child: pages[_tab])))),
        bottomNavigationBar: _tab == 2
            ? SettingsNavigation(onSelect: (tab) => setState(() => _tab = tab))
            : QuestNavigation(
                selected: _tab, onSelect: (tab) => setState(() => _tab = tab)));
  }
}
