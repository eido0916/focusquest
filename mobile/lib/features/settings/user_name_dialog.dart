import 'package:flutter/material.dart';
import '../../core/game_controller.dart';

class UserNameDialog extends StatefulWidget {
  const UserNameDialog({super.key, required this.controller});
  final GameController controller;

  @override
  State<UserNameDialog> createState() => _UserNameDialogState();
}

class _UserNameDialogState extends State<UserNameDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(
        text: widget.controller.state!.activeCharacter!.name);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.controller.changeUserName(_name.text);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = '変更を保存できませんでした。もう一度お試しください。';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: !_saving,
      child: AlertDialog(
          title: const Text('ユーザー名を変更'),
          content: Form(
              key: _form,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextFormField(
                    key: const Key('user-name-input'),
                    controller: _name,
                    autofocus: true,
                    enabled: !_saving,
                    maxLength: 16,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                        labelText: 'ユーザー名', helperText: '1〜16文字で入力してください。'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'ユーザー名を入力してください。'
                        : value.trim().characters.length > 16
                            ? '16文字以内で入力してください。'
                            : null,
                    onFieldSubmitted: (_) => _save()),
                if (_error != null)
                  Text(_error!, style: const TextStyle(color: Colors.red)),
              ])),
          actions: [
            TextButton(
                onPressed: _saving ? null : () => Navigator.of(context).pop(),
                child: const Text('キャンセル')),
            FilledButton(
                key: const Key('save-user-name'),
                onPressed: _saving ? null : _save,
                child: Text(_saving ? '保存中…' : '保存')),
          ]));
}
