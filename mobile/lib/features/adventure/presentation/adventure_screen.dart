import 'package:flutter/material.dart';
import '../../../core/game_controller.dart';
import '../../playable_stage/presentation/playable_stage_selection_page.dart';

class AdventureScreen extends StatelessWidget {
  const AdventureScreen({super.key, required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) =>
      PlayableStageSelectionPage(controller: controller, embedded: true);
}
