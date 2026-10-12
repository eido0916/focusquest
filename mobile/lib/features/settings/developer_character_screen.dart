import 'package:flutter/material.dart';
import '../../core/game_controller.dart';
import '../../core/widgets/quest_widgets.dart';
import '../../data/game_catalog.dart';
import '../diagnosis/presentation/job_portrait.dart';

/// Temporary developer screen, linked only from debug settings.
class DeveloperCharacterScreen extends StatefulWidget {
  const DeveloperCharacterScreen({super.key, required this.controller});
  final GameController controller;

  @override
  State<DeveloperCharacterScreen> createState() =>
      _DeveloperCharacterScreenState();
}

class _DeveloperCharacterScreenState extends State<DeveloperCharacterScreen> {
  late String _typeId;
  late String _appearance;
  String? _error;

  @override
  void initState() {
    super.initState();
    final hero = widget.controller.state!.activeCharacter!;
    _typeId = hero.characterType;
    _appearance = hero.appearance;
  }

  Future<void> _apply() async {
    setState(() => _error = null);
    try {
      await widget.controller.setCharacterForDevelopment(_typeId, _appearance);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() => _error = '変更を保存できませんでした。もう一度お試しください。');
      }
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        final inProgress = controller.activeFocus != null ||
            controller.playableAdventureActive;
        final enabled = !controller.busy && !inProgress;
        return Scaffold(
            appBar: AppBar(title: const Text('職業・性別を選択（開発者用）')),
            body: SafeArea(
                child: QuestBackdrop(
                    child: Center(
                        child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 640),
                            child: ListView(
                                padding: const EdgeInsets.all(20),
                                children: [
                                  const Text(
                                      '現在のキャラクターの職業と性別を変更します。\n名前・レベル・経験値・履歴は引き継ぎます。'),
                                  const SizedBox(height: 16),
                                  JobPortrait(
                                      typeId: _typeId, appearance: _appearance),
                                  const SizedBox(height: 20),
                                  DropdownButtonFormField<String>(
                                      key: const Key('developer-job'),
                                      value: _typeId,
                                      isExpanded: true,
                                      decoration: const InputDecoration(
                                          labelText: '職業'),
                                      items: [
                                        for (final type
                                            in GameCatalog.types.values)
                                          DropdownMenuItem(
                                              value: type.typeId,
                                              child: Text(type.job)),
                                      ],
                                      onChanged: enabled
                                          ? (value) =>
                                              setState(() => _typeId = value!)
                                          : null),
                                  const SizedBox(height: 16),
                                  DropdownButtonFormField<String>(
                                      key: const Key('developer-gender'),
                                      value: _appearance,
                                      decoration: const InputDecoration(
                                          labelText: '性別'),
                                      items: const [
                                        DropdownMenuItem(
                                            value: 'male', child: Text('男')),
                                        DropdownMenuItem(
                                            value: 'female', child: Text('女')),
                                      ],
                                      onChanged: enabled
                                          ? (value) => setState(
                                              () => _appearance = value!)
                                          : null),
                                  const SizedBox(height: 20),
                                  if (inProgress)
                                    const Text('集中・冒険が終わってから変更してください。'),
                                  if (_error != null)
                                    Text(_error!,
                                        style:
                                            const TextStyle(color: Colors.red)),
                                  FilledButton(
                                      onPressed: enabled ? _apply : null,
                                      child: Text(
                                          controller.busy ? '保存中…' : '変更を適用')),
                                ]))))));
      });
}
