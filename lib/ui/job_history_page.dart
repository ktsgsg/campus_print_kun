import 'package:flutter/cupertino.dart';

import '../data/repositories/job_history_repository.dart';
import '../domain/models/print_job.dart';
import '../features/ccmoon/ccmoon.dart';
import '../features/webprint/webprint_service.dart';
import '../l10n/app_localizations.dart';
import 'app_colors.dart';

// ─── エントリーポイント ────────────────────────────────────
class JobHistoryPage extends StatelessWidget {
  const JobHistoryPage({super.key, required this.user, required this.pass});

  final String user;
  final String pass;

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: [
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.clock),
            label: AppLocalizations.of(context)!.historyTitle,
          ),
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.printer),
            label: AppLocalizations.of(context)!.printStatus,
          ),
        ],
      ),
      tabBuilder: (context, index) {
        return CupertinoTabView(
          builder: (context) => switch (index) {
            0 => _JobHistoriesPage(user: user, pass: pass),
            _ => _PrintStatusPage(user: user, pass: pass),
          },
        );
      },
    );
  }
}

// ─── 共通: 戻るボタン付きナビバー ─────────────────────────
CupertinoNavigationBar _navBar(BuildContext context, String title) {
  return CupertinoNavigationBar(
    leading: CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
      child: const Icon(CupertinoIcons.chevron_left),
    ),
    middle: Text(title),
  );
}

// ─── 履歴タブ ──────────────────────────────────────────────
class _JobHistoriesPage extends StatefulWidget {
  const _JobHistoriesPage({required this.user, required this.pass});
  final String user;
  final String pass;

  @override
  State<_JobHistoriesPage> createState() => _JobHistoriesPageState();
}

class _JobHistoriesPageState extends State<_JobHistoriesPage> {
  late DateTime _startDate;
  late DateTime _endDate;

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

  Future<void> _pickMonth(
      {required bool isStart, required AppLocalizations l10n}) async {
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
                  child: Text(l10n.pickerCancel),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
                CupertinoButton(
                  child: Text(l10n.pickerDone),
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

      final repo = JobHistoryRepository(session);
      final jobs = await repo.searchHistories(
        HistorySearchFilter(
          userId: widget.user,
          startMonth: _startDate,
          endMonth: _endDate,
          normal: _normal,
          error: _error,
          cancel: _cancel,
          deleteBat: _deleteBat,
          deleteJob: _deleteJob,
        ),
      );

      if (mounted) setState(() => _results = jobs);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final deco = _fieldDecoration();
    return CupertinoPageScaffold(
      navigationBar: _navBar(context, l10n.historyTitle),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FilterSection(
                title: l10n.filterPeriod,
                child: Row(
                  children: [
                    Expanded(
                      child: _LabeledField(
                        label: l10n.filterStartMonth,
                        child: _MonthPickerField(
                          label: l10n.monthYearLabel(
                              _startDate.year, _startDate.month),
                          decoration: deco,
                          onTap: () =>
                              _pickMonth(isStart: true, l10n: l10n),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _LabeledField(
                        label: l10n.filterEndMonth,
                        child: _MonthPickerField(
                          label: l10n.monthYearLabel(
                              _endDate.year, _endDate.month),
                          decoration: deco,
                          onTap: () =>
                              _pickMonth(isStart: false, l10n: l10n),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _FilterSection(
                title: l10n.filterStatusType,
                child: Column(
                  children: [
                    _CheckRow(items: [
                      _CheckItem(l10n.statusNormal, _normal,
                          (v) => setState(() => _normal = v)),
                      _CheckItem(l10n.statusError, _error,
                          (v) => setState(() => _error = v)),
                      _CheckItem(l10n.statusCancelLabel, _cancel,
                          (v) => setState(() => _cancel = v)),
                    ]),
                    const SizedBox(height: 8),
                    _CheckRow(items: [
                      _CheckItem(l10n.statusDeleteBat, _deleteBat,
                          (v) => setState(() => _deleteBat = v)),
                      _CheckItem(l10n.statusDeleteJob, _deleteJob,
                          (v) => setState(() => _deleteJob = v)),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              CupertinoButton.filled(
                onPressed: _loading ? null : _search,
                child: _loading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CupertinoActivityIndicator(
                              color: CupertinoColors.white),
                          const SizedBox(width: 8),
                          Text(l10n.searchingLabel),
                        ],
                      )
                    : Text(l10n.searchButton),
              ),
              const SizedBox(height: 24),
              _buildResults(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults(AppLocalizations l10n) {
    if (_errorMessage != null) return _errorBox(_errorMessage!);
    final jobs = _results;
    if (jobs == null) return _emptyPlaceholder(l10n.searchPlaceholder);
    if (jobs.isEmpty) return _emptyPlaceholder(l10n.noJobsFound);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.resultCount(jobs.length),
            style: const TextStyle(
                fontSize: 13, color: AppColors.secondaryText)),
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

// ─── 印刷状況タブ ──────────────────────────────────────────
class _PrintStatusPage extends StatefulWidget {
  const _PrintStatusPage({required this.user, required this.pass});
  final String user;
  final String pass;

  @override
  State<_PrintStatusPage> createState() => _PrintStatusPageState();
}

class _PrintStatusPageState extends State<_PrintStatusPage> {
  bool _accepting = true;
  bool _orderWait = true;
  bool _outputWait = true;
  bool _outputting = true;
  bool _end = true;
  bool _acceptingWeb = true;

  bool _loading = false;
  List<PrintStatusJob>? _results;
  String? _errorMessage;

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

      final repo = JobHistoryRepository(session);
      final jobs = await repo.searchPrints(
        PrintStatusFilter(
          userId: widget.user,
          accepting: _accepting,
          orderWait: _orderWait,
          outputWait: _outputWait,
          outputting: _outputting,
          end: _end,
          acceptingWeb: _acceptingWeb,
        ),
      );

      if (mounted) setState(() => _results = jobs);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return CupertinoPageScaffold(
      navigationBar: _navBar(context, l10n.printStatus),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FilterSection(
                title: l10n.filterStatusType,
                child: Column(
                  children: [
                    _CheckRow(items: [
                      _CheckItem(l10n.statusAccepting, _accepting,
                          (v) => setState(() => _accepting = v)),
                      _CheckItem(l10n.statusOrderWait, _orderWait,
                          (v) => setState(() => _orderWait = v)),
                      _CheckItem(l10n.statusOutputWait, _outputWait,
                          (v) => setState(() => _outputWait = v)),
                    ]),
                    const SizedBox(height: 8),
                    _CheckRow(items: [
                      _CheckItem(l10n.statusOutputting, _outputting,
                          (v) => setState(() => _outputting = v)),
                      _CheckItem(l10n.statusEndLabel, _end,
                          (v) => setState(() => _end = v)),
                      _CheckItem(l10n.statusAcceptingWeb, _acceptingWeb,
                          (v) => setState(() => _acceptingWeb = v)),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              CupertinoButton.filled(
                onPressed: _loading ? null : _search,
                child: _loading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CupertinoActivityIndicator(
                              color: CupertinoColors.white),
                          const SizedBox(width: 8),
                          Text(l10n.searchingLabel),
                        ],
                      )
                    : Text(l10n.searchButton),
              ),
              const SizedBox(height: 24),
              _buildResults(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults(AppLocalizations l10n) {
    if (_errorMessage != null) return _errorBox(_errorMessage!);
    final jobs = _results;
    if (jobs == null) return _emptyPlaceholder(l10n.searchPlaceholder);
    if (jobs.isEmpty) return _emptyPlaceholder(l10n.noJobsFound);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.resultCount(jobs.length),
            style: const TextStyle(
                fontSize: 13, color: AppColors.secondaryText)),
        const SizedBox(height: 8),
        ...jobs.map((job) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PrintStatusCard(job: job),
            )),
      ],
    );
  }
}

// ─── 共通ユーティリティ ────────────────────────────────────
Widget _emptyPlaceholder(String message) => Container(
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.fieldFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Center(
        child: Text(message,
            style: const TextStyle(color: AppColors.secondaryText)),
      ),
    );

Widget _errorBox(String message) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.fieldFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Text(message,
          style: const TextStyle(color: CupertinoColors.systemRed)),
    );

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

// ─── 印刷状況カード ────────────────────────────────────────
class _PrintStatusCard extends StatelessWidget {
  const _PrintStatusCard({required this.job});
  final PrintStatusJob job;

  @override
  Widget build(BuildContext context) {
    final totalPages = job.papersColor + job.papersMono;
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
              if (job.paperSizeName.isNotEmpty) ...[
                _Tag(job.paperSizeName),
                const SizedBox(width: 6),
              ],
              if (job.duplexName.isNotEmpty) ...[
                _Tag(job.duplexName),
                const SizedBox(width: 6),
              ],
              if (job.colorModeName.isNotEmpty) ...[
                _Tag(job.colorModeName),
                const SizedBox(width: 6),
              ],
              _Tag('${job.copies}部'),
              if (totalPages > 0) ...[
                const SizedBox(width: 6),
                _Tag('$totalPages枚'),
              ],
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
            job.queueName.isNotEmpty
                ? '${job.jobSc}  •  ${job.queueName}'
                : job.jobSc,
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
    if (label.contains('正常') || label.contains('出力完了')) {
      return CupertinoColors.systemGreen;
    }
    if (label.contains('出力中')) return CupertinoColors.systemYellow;
    if (label.contains('出力待ち') || label.contains('指示待ち')) {
      return CupertinoColors.systemOrange;
    }
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
      child: Text(label, style: TextStyle(fontSize: 11, color: _color)),
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
              child: Text(label, style: const TextStyle(fontSize: 15)),
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
