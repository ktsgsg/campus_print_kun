/// 履歴 API (`api/job/histories/search`) のレコード。
class PrintJob {
  const PrintJob({
    required this.jobSc,
    required this.statusName,
    required this.documentName,
    required this.receivedDatetime,
    required this.duplexName,
    required this.colorModeName,
    required this.copies,
  });

  final String jobSc;
  final String statusName;
  final String documentName;
  final String receivedDatetime;
  final String duplexName;
  final String colorModeName;
  final int copies;

  factory PrintJob.fromJson(Map<String, dynamic> j) => PrintJob(
    jobSc: (j['job_sc'] as String?) ?? '',
    statusName: (j['job_completed_status_name'] as String?) ?? '',
    documentName: (j['document_name'] as String?) ?? '',
    receivedDatetime: (j['job_received_datetime'] as String?) ?? '',
    duplexName: (j['pre_duplex_type_name'] as String?) ?? '',
    colorModeName: (j['pre_color_mode_type_name'] as String?) ?? '',
    copies: (j['pre_output_copies'] as int?) ?? 1,
  );
}

/// 印刷状況 API (`api/job/prints/search`) のレコード。
class PrintStatusJob {
  const PrintStatusJob({
    required this.jobSc,
    required this.statusName,
    required this.documentName,
    required this.receivedDatetime,
    required this.duplexName,
    required this.colorModeName,
    required this.copies,
    required this.queueName,
    required this.paperSizeName,
    required this.papersColor,
    required this.papersMono,
  });

  final String jobSc;
  final String statusName;
  final String documentName;
  final String receivedDatetime;
  final String duplexName;
  final String colorModeName;
  final int copies;
  final String queueName;
  final String paperSizeName;
  final int papersColor;
  final int papersMono;

  factory PrintStatusJob.fromJson(Map<String, dynamic> j) => PrintStatusJob(
    jobSc: (j['job_sc'] as String?) ?? '',
    statusName: (j['print_job_status_name'] as String?) ?? '',
    documentName: (j['document_name'] as String?) ?? '',
    receivedDatetime: (j['job_received_datetime'] as String?) ?? '',
    duplexName: (j['pre_duplex_type_name'] as String?) ?? '',
    colorModeName: (j['pre_color_mode_type_name'] as String?) ?? '',
    copies: (j['pre_output_copies'] as int?) ?? 1,
    queueName: (j['print_queue_name'] as String?) ?? '',
    paperSizeName: (j['pre_paper_size_name'] as String?) ?? '',
    papersColor: (j['pre_output_papers_per_copies_color'] as int?) ?? 0,
    papersMono: (j['pre_output_papers_per_copies_mono'] as int?) ?? 0,
  );
}

/// 履歴検索のフィルタ条件。
class HistorySearchFilter {
  const HistorySearchFilter({
    required this.userId,
    required this.startMonth,
    required this.endMonth,
    this.normal = true,
    this.error = true,
    this.cancel = true,
    this.deleteBat = true,
    this.deleteJob = true,
  });

  final String userId;
  final DateTime startMonth;
  final DateTime endMonth;
  final bool normal;
  final bool error;
  final bool cancel;
  final bool deleteBat;
  final bool deleteJob;
}

/// 印刷状況検索のフィルタ条件。
class PrintStatusFilter {
  const PrintStatusFilter({
    required this.userId,
    this.accepting = true,
    this.orderWait = true,
    this.outputWait = true,
    this.outputting = true,
    this.end = true,
    this.acceptingWeb = true,
  });

  final String userId;
  final bool accepting;
  final bool orderWait;
  final bool outputWait;
  final bool outputting;
  final bool end;
  final bool acceptingWeb;
}
