import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../../features/ccmoon/ccmoon.dart';
import '../../../../features/webprint/webprint.dart';

enum PrintStepStatus { pending, running, success, failure }

enum PrintStepKind { connect, auth, sendPdf, done }

class PrintStep {
  PrintStep(this.kind) : status = PrintStepStatus.pending;
  final PrintStepKind kind;
  PrintStepStatus status;
}

class PrintProgressViewModel extends ChangeNotifier {
  final steps = PrintStepKind.values.map(PrintStep.new).toList();
  String? errorMessage;
  String? jobStatus;

  bool get isFailed => steps.any((s) => s.status == PrintStepStatus.failure);
  bool get isDone => steps.last.status == PrintStepStatus.success;

  bool _disposed = false;
  int _current = 0;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _setStatus(int index, PrintStepStatus status) {
    steps[index].status = status;
    _notify();
  }

  Future<void> run({
    required String user,
    required String pass,
    required File file,
    required PrintFormat format,
  }) async {
    try {
      _current = 0;
      _setStatus(0, PrintStepStatus.running);
      final session = await connectCcmoon(username: user, password: pass);
      _setStatus(0, PrintStepStatus.success);

      _current = 1;
      _setStatus(1, PrintStepStatus.running);
      final wp = WebPrint(session);
      await wp.initialize(username: user, password: pass);
      _setStatus(1, PrintStepStatus.success);

      _current = 2;
      _setStatus(2, PrintStepStatus.running);
      final status = await wp.pdfPrint(
        filename: file.uri.pathSegments.last,
        printDataPath: file.path,
        format: format,
      );
      _setStatus(2, PrintStepStatus.success);
      jobStatus = status.toString();
      _notify();

      _current = 3;
      _setStatus(3, PrintStepStatus.success);
    } catch (e, st) {
      _setStatus(_current, PrintStepStatus.failure);
      errorMessage = e.toString();
      _notify();
      debugPrintStack(stackTrace: st, label: 'print error');
    }
  }
}
