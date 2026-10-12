import '../../core/widgets/game_ui.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/game_controller.dart';
import 'certificate_data.dart';
import 'certificate_renderer.dart';

class CertificateScreen extends StatefulWidget {
  const CertificateScreen({super.key, required this.controller});
  final GameController controller;
  @override
  State<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends State<CertificateScreen> {
  Uint8List? _png;
  String? _error;
  bool _saving = false;
  int _revision = 0;
  Object? _lastData;
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
    _refresh();
  }

  Future<void> _refresh() async {
    final data = CertificateData.fromState(
        widget.controller.state!, widget.controller.clock());
    final signature = (
      data.role,
      data.gender,
      data.name,
      data.level,
      data.focusMinutes,
      data.defeats,
      data.days,
      data.stages,
      data.number,
      data.issuedAt
    );
    if (_lastData == signature && _error == null) return;
    _lastData = signature;
    final revision = ++_revision;
    setState(() => _png = null);
    try {
      final png = await CertificateRenderer.render(data);
      if (mounted && revision == _revision) {
        setState(() {
          _png = png;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted && revision == _revision) {
        setState(() => _error = '冒険者証を読み込めませんでした。');
      }
    }
  }

  Future<void> _save() async {
    if (_saving || _png == null) return;
    final png = _png!;
    setState(() => _saving = true);
    try {
      final directory = Platform.isAndroid
          ? await getExternalStorageDirectory()
          : await getApplicationDocumentsDirectory();
      if (directory == null) throw const FileSystemException('保存先がありません');
      final folder = Directory('${directory.path}/FocusQuest/冒険者証');
      await folder.create(recursive: true);
      final file = File(
          '${folder.path}/冒険者証_${DateTime.now().microsecondsSinceEpoch}.png');
      await file.writeAsBytes(png, flush: true);
      if (mounted) {
        await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
                    title: const Text('PNGを保存しました'),
                    content: SelectableText(file.path),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('閉じる'))
                    ]));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PNGを保存できませんでした。再試行してください。')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: gameInk,
        appBar: GameAppBar(title: const Text('冒険者証'), actions: [
          TextButton.icon(
              onPressed:
                  _png == null || _error != null || _saving ? null : _save,
              icon: const Icon(Icons.download),
              label: Text(_saving ? '保存中' : 'PNG保存'))
        ]),
        body: _error != null
            ? Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(_error!),
                TextButton(onPressed: _refresh, child: const Text('再試行'))
              ]))
            : _png == null
                ? const Center(child: CircularProgressIndicator())
                : InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: Center(
                        child: Image.memory(_png!,
                            fit: BoxFit.contain,
                            semanticLabel:
                                '${widget.controller.state!.activeCharacter!.name}の冒険者証'))),
      );
}
