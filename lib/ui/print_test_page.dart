import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';

import '../features/auth/credential_store.dart';
import '../features/pdf/pdf_preview_source.dart';
import '../features/sharing/shared_pdf_service.dart';
import '../features/webprint/webprint.dart';
import '../l10n/app_localizations.dart';
import 'app_colors.dart';
import 'job_history_page.dart';
import 'print_layout_preview.dart';
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
  PdfPreviewSource? _previewSource;
  bool _previewLoading = false;

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
    final file = File(path);
    setState(() => _selectedFile = file);
    _loadPreview(file);
  }

  Future<void> _loadPreview(File file) async {
    final old = _previewSource;
    setState(() {
      _previewSource = null;
      _previewLoading = true;
    });
    await old?.close();
    PdfPreviewSource? source;
    try {
      source = await PdfPreviewSource.open(file.path);
    } catch (_) {
      source = null;
    }
    if (!mounted) {
      await source?.close();
      return;
    }
    if (_selectedFile?.path != file.path) {
      await source?.close();
      return;
    }
    setState(() {
      _previewSource = source;
      _previewLoading = false;
    });
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
    _previewSource?.close();
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
    final file = File(result.files.single.path!);
    setState(() => _selectedFile = file);
    _loadPreview(file);
  }

  String _formatSummary(AppLocalizations l10n, PrintFormat format) {
    final map = format.toMap();
    final paper = map['paper_type'] == '05' ? 'A3' : 'A4';
    final duplex = map['duplex_type'] == '2' ? l10n.duplexOn : l10n.duplexOff;
    final copies = map['copies'] ?? '1';
    final numberUp = map['number_up'] ?? '1';
    return l10n.summaryFormat(paper, duplex, copies, numberUp);
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
    final l10n = AppLocalizations.of(context)!;
    final user = _userController.text.trim();
    final pass = _passController.text;
    final file = _selectedFile;
    if (user.isEmpty || pass.isEmpty) {
      await _showAlert(l10n.inputError, l10n.credentialRequired);
      return;
    }
    if (file == null) {
      await _showAlert(l10n.inputError, l10n.pdfRequired);
      return;
    }
    final navigator = Navigator.of(context);
    await _credentialStore.save(Credentials(username: user, password: pass));
    setState(() => _running = true);
    await navigator.push(
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
    final l10n = AppLocalizations.of(context)!;
    final fileName = _selectedFile?.uri.pathSegments.last;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(l10n.appTitle),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).push(
            CupertinoPageRoute(
              builder: (_) => JobHistoryPage(
                user: _userController.text.trim(),
                pass: _passController.text,
              ),
            ),
          ),
          child: const Icon(CupertinoIcons.list_bullet),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CupertinoTextField(
                controller: _userController,
                placeholder: l10n.userIdLabel,
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
                placeholder: l10n.passwordLabel,
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
                      fileName ?? l10n.pdfNotSelected,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: fileName == null
                            ? AppColors.secondaryText
                            : AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CupertinoButton(
                    onPressed: _running ? null : _pickPdf,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.doc_text),
                        const SizedBox(width: 6),
                        Text(l10n.selectPdfButton),
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
                      _formatSummary(l10n, _printFormat),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.secondaryText),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CupertinoButton(
                    onPressed: _running ? null : _openSettings,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.gear),
                        const SizedBox(width: 6),
                        Text(l10n.printSettingsButton),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _previewSource != null
                    ? PrintLayoutPreview(
                        key: ValueKey(_selectedFile?.path),
                        source: _previewSource!,
                        format: _printFormat,
                      )
                    : Center(
                        child: _previewLoading
                            ? const CupertinoActivityIndicator()
                            : Text(
                                l10n.previewNoPdf,
                                style: TextStyle(
                                  color: CupertinoDynamicColor.resolve(
                                    AppColors.secondaryText,
                                    context,
                                  ),
                                ),
                              ),
                      ),
              ),
              const SizedBox(height: 12),
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
                    Text(_running ? l10n.running : l10n.startPrint),
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
