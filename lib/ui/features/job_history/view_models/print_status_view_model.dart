import 'package:flutter/foundation.dart';

import '../../../../data/repositories/job_history_repository.dart';
import '../../../../domain/models/print_job.dart';
import '../../../../features/ccmoon/ccmoon.dart';
import '../../../../features/webprint/webprint.dart';

class PrintStatusViewModel extends ChangeNotifier {
  bool accepting = true;
  bool orderWait = true;
  bool outputWait = true;
  bool outputting = true;
  bool end = true;
  bool acceptingWeb = true;

  bool loading = false;
  List<PrintStatusJob>? results;
  String? errorMessage;

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void setAccepting(bool v) {
    accepting = v;
    _notify();
  }

  void setOrderWait(bool v) {
    orderWait = v;
    _notify();
  }

  void setOutputWait(bool v) {
    outputWait = v;
    _notify();
  }

  void setOutputting(bool v) {
    outputting = v;
    _notify();
  }

  void setEnd(bool v) {
    end = v;
    _notify();
  }

  void setAcceptingWeb(bool v) {
    acceptingWeb = v;
    _notify();
  }

  Future<void> search({required String user, required String pass}) async {
    loading = true;
    errorMessage = null;
    results = null;
    _notify();
    try {
      final session = await connectCcmoon(username: user, password: pass);
      final wp = WebPrint(session);
      await wp.initialize(username: user, password: pass);
      final repo = JobHistoryRepository(session);
      results = await repo.searchPrints(PrintStatusFilter(
        userId: user,
        accepting: accepting,
        orderWait: orderWait,
        outputWait: outputWait,
        outputting: outputting,
        end: end,
        acceptingWeb: acceptingWeb,
      ));
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      loading = false;
      _notify();
    }
  }
}
