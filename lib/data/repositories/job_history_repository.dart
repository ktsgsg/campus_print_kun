import 'dart:convert';

import 'package:dio/dio.dart';

import '../../domain/models/print_job.dart';
import '../../features/ccmoon/connect_ccmoon.dart';
import '../../features/webprint/webprint_service.dart';

/// 履歴 / 印刷状況 API への問い合わせを集約するリポジトリ。
///
/// 認証済みの [CcMoonSession] を受け取り、URL 構築・HTTP・JSON パースを
/// 内部に閉じ込める。UI 層は domain model のみを受け取る。
class JobHistoryRepository {
  JobHistoryRepository(this._session);

  final CcMoonSession _session;

  String _searchUrl(String endpoint) =>
      '${WebtopConst.host}${_session.baseurl}user/f5-h-\$\$/user/f5-h-\$\$/$endpoint';

  String _toYYYYMM(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, "0")}';

  /// 履歴検索 (`api/job/histories/search`)。
  Future<List<PrintJob>> searchHistories(HistorySearchFilter filter) async {
    final params = {
      'user_id': filter.userId,
      'normal': filter.normal.toString(),
      'error': filter.error.toString(),
      'cancel': filter.cancel.toString(),
      'delete_bat': filter.deleteBat.toString(),
      'delete_job': filter.deleteJob.toString(),
      'start_date': _toYYYYMM(filter.startMonth),
      'end_date': _toYYYYMM(filter.endMonth),
    };
    final res = await _session.dio.get<String>(
      _searchUrl('api/job/histories/search'),
      queryParameters: params,
      options: Options(responseType: ResponseType.plain),
    );
    final body = jsonDecode(res.data!) as Map<String, dynamic>;
    final array = body['job_history_array'] as List<dynamic>;
    return array
        .map((e) => PrintJob.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 印刷状況検索 (`api/job/prints/search`)。
  Future<List<PrintStatusJob>> searchPrints(PrintStatusFilter filter) async {
    final params = {
      'user_id': filter.userId,
      'accepting': filter.accepting.toString(),
      'order_wait': filter.orderWait.toString(),
      'output_wait': filter.outputWait.toString(),
      'outputting': filter.outputting.toString(),
      'end': filter.end.toString(),
      'accepting_web': filter.acceptingWeb.toString(),
    };
    final res = await _session.dio.get<String>(
      _searchUrl('api/job/prints/search'),
      queryParameters: params,
      options: Options(responseType: ResponseType.plain),
    );
    final body = jsonDecode(res.data!) as Map<String, dynamic>;
    final array = body['print_job_array'] as List<dynamic>;
    return array
        .map((e) => PrintStatusJob.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
