import 'package:flutter/material.dart';
import '../domain/auth_repository.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.repository});
  final AuthRepository repository;
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _busy = false;
  String? _message;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit({bool reset = false}) async {
    if (_busy) return;
    if (reset) {
      if (!_email.text.contains('@')) {
        setState(() => _message = 'メールアドレスを入力してください。');
        return;
      }
    } else if (!_form.currentState!.validate()) {
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      if (reset) {
        await widget.repository.sendPasswordReset(_email.text.trim());
        if (mounted) setState(() => _message = '再設定メールを送信しました。');
      } else if (_register) {
        await widget.repository.register(_email.text.trim(), _password.text);
      } else {
        await widget.repository.signIn(_email.text.trim(), _password.text);
      }
    } catch (_) {
      if (mounted) setState(() => _message = '接続状況と入力内容を確認し、もう一度お試しください。');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
          body: SafeArea(
              child: Center(
        child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                  key: _form,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('FQ',
                            style: Theme.of(context).textTheme.displayLarge),
                        Text('集中した時間が、冒険になる。',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 32),
                        Text(_register ? '新規登録' : 'ログイン',
                            style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 16),
                        TextFormField(
                            controller: _email,
                            enabled: !_busy,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            decoration:
                                const InputDecoration(labelText: 'メールアドレス'),
                            validator: (value) =>
                                value != null && value.contains('@')
                                    ? null
                                    : 'メールアドレスを入力してください。'),
                        const SizedBox(height: 16),
                        TextFormField(
                            controller: _password,
                            enabled: !_busy,
                            obscureText: true,
                            decoration:
                                const InputDecoration(labelText: 'パスワード'),
                            validator: (value) =>
                                value != null && value.length >= 6
                                    ? null
                                    : '6文字以上で入力してください。'),
                        if (_message != null)
                          Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Text(_message!)),
                        const SizedBox(height: 24),
                        FilledButton(
                            onPressed: _busy ? null : () => _submit(),
                            child: Text(_busy
                                ? '接続中…'
                                : _register
                                    ? '登録する'
                                    : 'ログイン')),
                        TextButton(
                            onPressed: _busy
                                ? null
                                : () => setState(() {
                                      _register = !_register;
                                      _message = null;
                                    }),
                            child:
                                Text(_register ? 'アカウントをお持ちの方' : '新規登録はこちら')),
                        TextButton(
                            onPressed:
                                _busy ? null : () => _submit(reset: true),
                            child: const Text('パスワードを忘れた方')),
                      ])),
            )),
      )));
}
