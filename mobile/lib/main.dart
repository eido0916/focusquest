import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'app.dart';
import 'core/game_controller.dart';
import 'data/local_player_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  try {
    final directory = await getApplicationSupportDirectory();
    final controller = GameController(LocalPlayerRepository(directory));
    runApp(FocusQuestApp(controller: controller));
    await controller.load();
  } catch (_) {
    runApp(const MaterialApp(
        home: Scaffold(
            body: Center(
                child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('保存先を準備できませんでした。アプリを再起動してください。'))))));
  }
}
