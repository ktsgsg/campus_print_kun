import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';

import '../features/auth/credential_store.dart';
import '../features/sharing/shared_pdf_service.dart';
import '../features/webprint/webprint.dart';
import 'app_colors.dart';
import 'print_progress_page.dart';
import 'print_settings_page.dart';

class PrintTestPage extends StatefulWidget {
  const PrintTestPage({super.key});

  @override
  State<PrintTestPage> createState() => _PrintTestPageState();
}

class _PrintTestPageState extends State<PrintTestPage> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  final _credentialStore = CredentialStore();
  File? _selectedFile;
  bool _running = false;
  PrintFormat _printFormat = PrintFormat();
  StreamSubscription<String>? _sharingSubscription;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    SharedPdfService.getInitialSharedPdf().then((path) {
      if (path != null) _applySharedPdf(path);
    });
    _sharingSubscription = SharedPdfService.onSharedPdf.listen(_applySharedPdf);
  }

  void _applySharedPdf(String path) {
    if (!mounted) return;
    setState(() => _selectedFile = File(path));
  }

  Future<void> _loadSavedCredentials() async {
    final credentials = await _credentialStore.load();
    if (credentials != null && mounted) {
      _userController.text = credentials.username;
      _passController.text = credentials.password;
    }
  }

  @override
  void dispose() {
    _sharingSubscription?.cancel();
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _showAlert(String title, String message) {
    return showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
  }

  String _formatSummary(PrintFormat format) {
    final map = format.toMap();
    final paper = map['paper_type'] == '05' ? 'A3' : 'A4';
    final duplex = map['duplex_type'] == '2' ? '両面' : '片面';
    final copies = map['copies'] ?? '1';
    final numberUp = map['number_up'] ?? '1';
    return '$paper・$duplex・${copies}部・${numberUp}up';
  }

  Future<void> _openSettings() async {
    final updated = await Navigator.of(context).push<PrintFormat>(
      CupertinoPageRoute(
        builder: (context) => PrintSettingsPage(format: _printFormat),
      ),
    );
    if (updated != null && mounted) {
      setState(() => _printFormat = updated);
    }
  }

  Future<void> _startPrint() async {
    final user = _userController.text.trim();
    final pass = _passController.text;
    final file = _selectedFile;
    if (user.isEmpty || pass.isEmpty) {
      await _showAlert('入力エラー', 'ユーザID / パスワードを入力してください');
      return;
    }
    if (file == null) {
      await _showAlert('入力エラー', 'PDF を選択してください');
      return;
    }
    await _credentialStore.save(Credentials(username: user, password: pass));
    setState(() => _running = true);
    await Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => PrintProgressPage(
          user: user,
          pass: pass,
          file: file,
          format: _printFormat,
        ),
      ),
    );
    if (mounted) setState(() => _running = false);
  }

  @override
  Widget build(BuildContext context) {
    final fileName = _selectedFile?.uri.pathSegments.last;
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('キャンパスプリントくん')),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CupertinoTextField(
                controller: _userController,
                placeholder: 'ユーザID',
                enabled: !_running,
                autocorrect: false,
                autofillHints: const [AutofillHints.username],
                prefix: const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Icon(CupertinoIcons.person),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.fieldFill,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.fieldBorder),
                ),
              ),
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: _passController,
                placeholder: 'パスワード',
                enabled: !_running,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                prefix: const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Icon(CupertinoIcons.lock),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.fieldFill,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.fieldBorder),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      fileName ?? 'PDF が未選択',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: fileName == null
                            ? AppColors.secondaryText
                            : CupertinoColors.label,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CupertinoButton(
                    onPressed: _running ? null : _pickPdf,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: const Row(
                      children: [
                        Icon(CupertinoIcons.doc_text),
                        SizedBox(width: 6),
                        Text('PDFを選択'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatSummary(_printFormat),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.secondaryText),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CupertinoButton(
                    onPressed: _running ? null : _openSettings,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: const Row(
                      children: [
                        Icon(CupertinoIcons.gear),
                        SizedBox(width: 6),
                        Text('印刷設定'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CupertinoButton.filled(
                onPressed: _running ? null : _startPrint,
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_running) ...[
                      const CupertinoActivityIndicator(),
                      const SizedBox(width: 8),
                    ] else ...[
                      const Icon(CupertinoIcons.printer),
                      const SizedBox(width: 8),
                    ],
                    Text(_running ? '実行中...' : '印刷開始'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
