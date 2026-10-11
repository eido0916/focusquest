import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'game/runner/female_archer_demo_game.dart';

void main() => runApp(const ArcherPreviewApp());

class ArcherPreviewApp extends StatefulWidget {
  const ArcherPreviewApp({super.key});
  @override
  State<ArcherPreviewApp> createState() => _ArcherPreviewAppState();
}

class _ArcherPreviewAppState extends State<ArcherPreviewApp> {
  final game = FemaleArcherDemoGame();
  @override
  void dispose() {
    game.pauseEngine();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
          appBar: AppBar(title: const Text('女弓使い・走行通常攻撃')),
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
                    game.attack();
                  },
                  child: const Text('通常攻撃（1射 → 走行へ戻る）')))));
}
