import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../../../../features/auth/credential_store.dart';
import '../../../../features/pdf/pdf_preview_source.dart';
import '../../../../features/webprint/webprint.dart';

class PrintTestViewModel extends ChangeNotifier {
  PrintTestViewModel(this._credentialStore);

  final CredentialStore _credentialStore;

  File? selectedFile;
  PrintFormat printFormat = PrintFormat();
  PdfPreviewSource? previewSource;
  bool previewLoading = false;
  Credentials? savedCredentials;

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    previewSource?.close();
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> loadSavedCredentials() async {
    savedCredentials = await _credentialStore.load();
    if (savedCredentials != null) _notify();
  }

  Future<void> saveCredentials(Credentials credentials) =>
      _credentialStore.save(credentials);

  Future<void> pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: false,
    );
    if (result == null || result.files.single.path == null) return;
    await applyFile(File(result.files.single.path!));
  }

  Future<void> applyFile(File file) async {
    selectedFile = file;
    _notify();
    await _loadPreview(file);
  }

  Future<void> _loadPreview(File file) async {
    final old = previewSource;
    previewSource = null;
    previewLoading = true;
    _notify();
    await old?.close();

    PdfPreviewSource? source;
    try {
      source = await PdfPreviewSource.open(file.path);
    } catch (_) {
      source = null;
    }

    if (_disposed || selectedFile?.path != file.path) {
      await source?.close();
      return;
    }
    previewSource = source;
    previewLoading = false;
    _notify();
  }

  void setPrintFormat(PrintFormat format) {
    printFormat = format;
    _notify();
  }
}
