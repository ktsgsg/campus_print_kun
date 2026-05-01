import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

import '../features/ccmoon/ccmoon.dart';
import '../features/webprint/webprint_service.dart';
import 'app_colors.dart';

enum _ApiTab { histories, tab2, tab3 }

// ─── モデル ────────────────────────────────────────────────
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

// ─── ページ ────────────────────────────────────────────────
class JobHistoryPage extends StatefulWidget {
  const JobHistoryPage({super.key, required this.user, required this.pass});

  final String user;
  final String pass;

  @override
  State<JobHistoryPage> createState() => _JobHistoryPageState();
}

class _JobHistoryPageState extends State<JobHistoryPage> {
  _ApiTab _selectedTab = _ApiTab.histories;

  late DateTime _startDate;
  late DateTime _endDate;

  // 履歴API固有フィルタ
  bool _normal = true;
  bool _error = true;
  bool _cancel = true;
  bool _deleteBat = true;
  bool _deleteJob = true;

  bool _loading = false;
  List<PrintJob>? _results;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month);
    _endDate = DateTime(now.year, now.month);
  }

  String _toYYYYMM(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}';

  String _toLabel(DateTime d) => '${d.year}年${d.month.toString().padLeft(2, '0')}月';

  Future<void> _pickMonth({required bool isStart}) async {
    final initial = isStart ? _startDate : _endDate;
    DateTime picked = initial;
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => Container(
        height: 300,
        color: CupertinoColors.systemBackground.resolveFrom(ctx),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: const Text('キャンセル'),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
                CupertinoButton(
                  child: const Text('完了'),
                  onPressed: () {
                    setState(() {
                      if (isStart) {
                        _startDate = picked;
                      } else {
                        _endDate = picked;
                      }
                    });
                    Navigator.of(ctx).pop();
                  },
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.monthYear,
                initialDateTime: initial,
                onDateTimeChanged: (d) => picked = DateTime(d.year, d.month),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _search() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
      _results = null;
    });
    try {
      final session = await connectCcmoon(
        username: widget.user,
        password: widget.pass,
      );
      final wp = WebPrint(session);
      await wp.initialize(username: widget.user, password: widget.pass);

      final params = {
        'user_id': widget.user,
        'normal': _normal.toString(),
        'error': _error.toString(),
        'cancel': _cancel.toString(),
        'delete_bat': _deleteBat.toString(),
        'delete_job': _deleteJob.toString(),
        'start_date': _toYYYYMM(_startDate),
        'end_date': _toYYYYMM(_endDate),
      };

      const url =
          'https://ccmoon2.meijo-u.ac.jp/f5-w-<REDACTED_BACKEND_URL_HEX>\$\$/user/f5-h-\$\$/user/f5-h-\$\$/api/job/histories/search';

      final res = await session.dio.get<String>(
        url,
        queryParameters: params,
        options: Options(responseType: ResponseType.plain),
      );

      final body = jsonDecode(res.data!) as Map<String, dynamic>;
      final array = body['job_history_array'] as List<dynamic>;
      final jobs = array
          .map((e) => PrintJob.fromJson(e as Map<String, dynamic>))
          .toList();

      if (mounted) setState(() => _results = jobs);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('プリント管理')),
      child: SafeArea(
        child: Column(
          children: [
            _buildSegmentedControl(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildCommonFilters(),
                    const SizedBox(height: 16),
                    _buildApiFilters(),
                    const SizedBox(height: 16),
                    CupertinoButton.filled(
                      onPressed: _loading ? null : _search,
                      child: _loading
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CupertinoActivityIndicator(
                                  color: CupertinoColors.white,
                                ),
                                SizedBox(width: 8),
                                Text('検索中...'),
                              ],
                            )
                          : const Text('検索'),
                    ),
                    const SizedBox(height: 24),
                    _buildResults(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedControl() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: CupertinoSlidingSegmentedControl<_ApiTab>(
        groupValue: _selectedTab,
        onValueChanged: (tab) {
          if (tab != null) setState(() => _selectedTab = tab);
        },
        children: const {
          _ApiTab.histories: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text('履歴'),
          ),
          _ApiTab.tab2: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text('API 2'),
          ),
          _ApiTab.tab3: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text('API 3'),
          ),
        },
      ),
    );
  }

  Widget _buildCommonFilters() {
    return _FilterSection(
      title: '期間',
      child: Row(
        children: [
          Expanded(
            child: _LabeledField(
              label: '開始月',
              child: _MonthPickerField(
                label: _toLabel(_startDate),
                decoration: _fieldDecoration(),
                onTap: () => _pickMonth(isStart: true),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _LabeledField(
              label: '終了月',
              child: _MonthPickerField(
                label: _toLabel(_endDate),
                decoration: _fieldDecoration(),
                onTap: () => _pickMonth(isStart: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiFilters() {
    return switch (_selectedTab) {
      _ApiTab.histories => _buildHistoriesFilters(),
      _ApiTab.tab2 => _FilterSection(
          title: 'フィルタ',
          child: const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('API 2 のフィルタをここに追加'),
            ),
          ),
        ),
      _ApiTab.tab3 => _FilterSection(
          title: 'フィルタ',
          child: const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('API 3 のフィルタをここに追加'),
            ),
          ),
        ),
    };
  }

  Widget _buildHistoriesFilters() {
    return _FilterSection(
      title: '表示種別',
      child: Column(
        children: [
          _CheckRow(
            items: [
              _CheckItem('正常', _normal, (v) => setState(() => _normal = v)),
              _CheckItem('エラー', _error, (v) => setState(() => _error = v)),
              _CheckItem('キャンセル', _cancel, (v) => setState(() => _cancel = v)),
            ],
          ),
          const SizedBox(height: 8),
          _CheckRow(
            items: [
              _CheckItem('システム削除(bat)', _deleteBat,
                  (v) => setState(() => _deleteBat = v)),
              _CheckItem('システム削除(job)', _deleteJob,
                  (v) => setState(() => _deleteJob = v)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.fieldFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.fieldBorder),
        ),
        child: Text(
          _errorMessage!,
          style: const TextStyle(color: CupertinoColors.systemRed),
        ),
      );
    }

    final jobs = _results;
    if (jobs == null) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.fieldFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.fieldBorder),
        ),
        child: const Center(
          child: Text(
            '検索結果がここに表示されます',
            style: TextStyle(color: AppColors.secondaryText),
          ),
        ),
      );
    }

    if (jobs.isEmpty) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.fieldFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.fieldBorder),
        ),
        child: const Center(
          child: Text(
            '該当するジョブはありません',
            style: TextStyle(color: AppColors.secondaryText),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${jobs.length} 件',
          style: const TextStyle(fontSize: 13, color: AppColors.secondaryText),
        ),
        const SizedBox(height: 8),
        ...jobs.map((job) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _JobCard(job: job),
            )),
      ],
    );
  }

  BoxDecoration _fieldDecoration() => BoxDecoration(
        color: AppColors.fieldFill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.fieldBorder),
      );
}

// ─── ジョブカード ──────────────────────────────────────────
class _JobCard extends StatelessWidget {
  const _JobCard({required this.job});
  final PrintJob job;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.fieldFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  job.documentName,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _StatusBadge(label: job.statusName),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (job.duplexName.isNotEmpty) ...[
                _Tag(job.duplexName),
                const SizedBox(width: 6),
              ],
              if (job.colorModeName.isNotEmpty) ...[
                _Tag(job.colorModeName),
                const SizedBox(width: 6),
              ],
              _Tag('${job.copies}部'),
              const Spacer(),
              Text(
                job.receivedDatetime,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.secondaryText),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            job.jobSc,
            style: const TextStyle(
                fontSize: 11, color: AppColors.secondaryText),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});
  final String label;

  Color get _color {
    if (label.contains('エラー')) return CupertinoColors.systemRed;
    if (label.contains('キャンセル')) return CupertinoColors.systemOrange;
    if (label.contains('削除')) return AppColors.secondaryText;
    if (label.contains('正常')) return CupertinoColors.systemGreen;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: _color),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.fieldBorder,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

// ─── フィルタ部品 ──────────────────────────────────────────
class _FilterSection extends StatelessWidget {
  const _FilterSection({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 13, color: AppColors.secondaryText)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.fieldFill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.fieldBorder),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: AppColors.secondaryText)),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}

class _MonthPickerField extends StatelessWidget {
  const _MonthPickerField({
    required this.label,
    required this.decoration,
    required this.onTap,
  });
  final String label;
  final BoxDecoration decoration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: decoration,
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 15),
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_down,
              size: 14,
              color: AppColors.secondaryText,
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckItem {
  const _CheckItem(this.label, this.value, this.onChanged);
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.items});
  final List<_CheckItem> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: items
          .map((item) => Expanded(
                child: GestureDetector(
                  onTap: () => item.onChanged(!item.value),
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      Icon(
                        item.value
                            ? CupertinoIcons.checkmark_square_fill
                            : CupertinoIcons.square,
                        color: item.value
                            ? AppColors.primary
                            : AppColors.secondaryText,
                        size: 22,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          item.label,
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }
}
