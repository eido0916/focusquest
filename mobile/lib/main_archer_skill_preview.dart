import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'game/runner/female_archer_skill_demo_game.dart';

void main() => runApp(const ArcherSkillPreviewApp());

class ArcherSkillPreviewApp extends StatefulWidget {
  const ArcherSkillPreviewApp({super.key});
  @override
  State<ArcherSkillPreviewApp> createState() => _ArcherSkillPreviewAppState();
}

class _ArcherSkillPreviewAppState extends State<ArcherSkillPreviewApp> {
  final game = FemaleArcherSkillDemoGame();
  @override
  void dispose() {
    game.pauseEngine();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
          appBar: AppBar(title: const Text('女弓使い・走行高威力スキル')),
          body: SingleChildScrollView(
              child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                      width: 1280,
                      height: 900,
                      child: GameWidget(game: game)))),
          bottomNavigationBar: Padding(
              padding: const EdgeInsets.all(12),
              child: ElevatedButton(
                  onPressed: () {
                    game.skill();
                  },
                  child: const Text('スキル（強く引く → 一射 → 走行復帰）')))));
}
