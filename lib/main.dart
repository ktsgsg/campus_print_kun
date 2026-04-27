import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'features/ccmoon/ccmoon.dart';
import 'features/webprint/webprint.dart';

void main() {
  runApp(const CampusPrintKunApp());
}

class CampusPrintKunApp extends StatelessWidget {
  const CampusPrintKunApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Print Kun',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const PrintTestPage(),
    );
  }
}

class PrintTestPage extends StatefulWidget {
  const PrintTestPage({super.key});

  @override
  State<PrintTestPage> createState() => _PrintTestPageState();
}

class _PrintTestPageState extends State<PrintTestPage> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  File? _selectedFile;
  bool _running = false;
  final List<String> _logs = [];

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  void _log(String message) {
    setState(() {
      _logs.add(
        '${DateTime.now().toIso8601String().substring(11, 19)}  $message',
      );
    });
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: false,
    );
    if (result == null || result.files.single.path == null) return;
    setState(() {
      _selectedFile = File(result.files.single.path!);
    });
    _log('PDF を選択: ${_selectedFile!.path}');
  }

  Future<void> _startPrint() async {
    final user = _userController.text.trim();
    final pass = _passController.text;
    final file = _selectedFile;
    if (user.isEmpty || pass.isEmpty) {
      _log('ユーザID / パスワードを入力してください');
      return;
    }
    if (file == null) {
      _log('PDF を選択してください');
      return;
    }
    setState(() => _running = true);
    try {
      _log('CC Moon に接続中...');
      final session = await connectCcmoon(username: user, password: pass);
      _log('セッション確立: baseurl=${session.baseurl}');

      final wp = WebPrint(session);
      _log('Web プリント認証中...');
      await wp.initialize(username: user, password: pass);
      _log('認証 OK / 自端末IP=${wp.ipAddress}');

      _log('PDF を送信中...');
      final status = await wp.pdfPrint(
        filename: file.uri.pathSegments.last,
        printDataPath: file.path,
      );
      _log('印刷ジョブ送信完了 status=$status');
    } catch (e, st) {
      _log('エラー: $e');
      debugPrintStack(stackTrace: st, label: 'print error');
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileName = _selectedFile?.uri.pathSegments.last;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Campus Print Kun (test)'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _userController,
                decoration: const InputDecoration(
                  labelText: 'ユーザID',
                  border: OutlineInputBorder(),
                ),
                enabled: !_running,
                autocorrect: false,
                autofillHints: const [AutofillHints.username],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passController,
                decoration: const InputDecoration(
                  labelText: 'パスワード',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                enabled: !_running,
                autofillHints: const [AutofillHints.password],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      fileName ?? 'PDF が未選択',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: fileName == null ? Colors.grey : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonalIcon(
                    onPressed: _running ? null : _pickPdf,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('PDFを選択'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _running ? null : _startPrint,
                icon: _running
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.print),
                label: Text(_running ? '実行中...' : '印刷開始'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const Text('ログ', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: ListView.builder(
                    itemCount: _logs.length,
                    itemBuilder: (context, i) => Text(
                      _logs[i],
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
