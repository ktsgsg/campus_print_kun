import 'package:flutter/foundation.dart';

import '../../../../data/repositories/job_history_repository.dart';
import '../../../../domain/models/print_job.dart';
import '../../../../features/ccmoon/ccmoon.dart';
import '../../../../features/webprint/webprint.dart';

class JobHistoriesViewModel extends ChangeNotifier {
  late DateTime startDate;
  late DateTime endDate;
  bool normal = true;
  bool error = true;
  bool cancel = true;
  bool deleteBat = true;
  bool deleteJob = true;

  bool loading = false;
  List<PrintJob>? results;
  String? errorMessage;

  bool _disposed = false;

  JobHistoriesViewModel() {
    final now = DateTime.now();
    startDate = DateTime(now.year, now.month);
    endDate = DateTime(now.year, now.month);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void setStartDate(DateTime d) {
    startDate = d;
    _notify();
  }

  void setEndDate(DateTime d) {
    endDate = d;
    _notify();
  }

  void setNormal(bool v) {
    normal = v;
    _notify();
  }

  void setError(bool v) {
    error = v;
    _notify();
  }

  void setCancel(bool v) {
    cancel = v;
    _notify();
  }

  void setDeleteBat(bool v) {
    deleteBat = v;
    _notify();
  }

  void setDeleteJob(bool v) {
    deleteJob = v;
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
      results = await repo.searchHistories(HistorySearchFilter(
        userId: user,
        startMonth: startDate,
        endMonth: endDate,
        normal: normal,
        error: error,
        cancel: cancel,
        deleteBat: deleteBat,
        deleteJob: deleteJob,
      ));
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      loading = false;
      _notify();
    }
  }
}
