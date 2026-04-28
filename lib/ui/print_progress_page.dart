import 'dart:io';

import 'package:flutter/cupertino.dart';

import '../features/ccmoon/ccmoon.dart';
import '../features/webprint/webprint.dart';
import 'app_colors.dart';

enum _StepStatus { pending, running, success, failure }

class _ProgressStep {
  _ProgressStep(this.title, this.status);

  final String title;
  _StepStatus status;
}

class PrintProgressPage extends StatefulWidget {
  const PrintProgressPage({
    super.key,
    required this.user,
    required this.pass,
    required this.file,
    required this.format,
  });

  final String user;
  final String pass;
  final File file;
  final PrintFormat format;

  @override
  State<PrintProgressPage> createState() => _PrintProgressPageState();
}

class _PrintProgressPageState extends State<PrintProgressPage> {
  final List<_ProgressStep> _steps = [
    _ProgressStep('CC Moon に接続', _StepStatus.pending),
    _ProgressStep('Webプリント認証', _StepStatus.pending),
    _ProgressStep('PDF 送信', _StepStatus.pending),
    _ProgressStep('完了', _StepStatus.pending),
  ];

  int _currentStepIndex = 0;
  String? _errorMessage;
  String? _jobStatus;

  bool get _isFailed =>
      _steps.any((step) => step.status == _StepStatus.failure);
  bool get _isDone => _steps.last.status == _StepStatus.success;

  @override
  void initState() {
    super.initState();
    _run();
  }

  void _setStepStatus(int index, _StepStatus status) {
    if (!mounted) return;
    setState(() => _steps[index].status = status);
  }

  Future<void> _run() async {
    try {
      _currentStepIndex = 0;
      _setStepStatus(_currentStepIndex, _StepStatus.running);
      final session = await connectCcmoon(
        username: widget.user,
        password: widget.pass,
      );
      _setStepStatus(_currentStepIndex, _StepStatus.success);

      _currentStepIndex = 1;
      _setStepStatus(_currentStepIndex, _StepStatus.running);
      final wp = WebPrint(session);
      await wp.initialize(username: widget.user, password: widget.pass);
      _setStepStatus(_currentStepIndex, _StepStatus.success);

      _currentStepIndex = 2;
      _setStepStatus(_currentStepIndex, _StepStatus.running);
      final status = await wp.pdfPrint(
        filename: widget.file.uri.pathSegments.last,
        printDataPath: widget.file.path,
        format: widget.format,
      );
      _setStepStatus(_currentStepIndex, _StepStatus.success);
      if (mounted) setState(() => _jobStatus = status.toString());

      _currentStepIndex = 3;
      _setStepStatus(_currentStepIndex, _StepStatus.success);
    } catch (e, st) {
      _setStepStatus(_currentStepIndex, _StepStatus.failure);
      if (mounted) setState(() => _errorMessage = e.toString());
      debugPrintStack(stackTrace: st, label: 'print error');
    }
  }

  Widget _buildHeader() {
    if (_isFailed) {
      return Column(
        children: [
          const Icon(
            CupertinoIcons.xmark_circle_fill,
            size: 56,
            color: CupertinoColors.systemRed,
          ),
          const SizedBox(height: 8),
          const Text(
            'Failed',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.label,
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 6),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.secondaryText),
            ),
          ],
        ],
      );
    }
    if (_isDone) {
      return Column(
        children: [
          const Icon(
            CupertinoIcons.check_mark_circled_solid,
            size: 56,
            color: CupertinoColors.systemGreen,
          ),
          const SizedBox(height: 8),
          const Text(
            'Success!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.label,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '印刷ジョブを送信しました',
            style: TextStyle(color: AppColors.secondaryText),
          ),
          if (_jobStatus != null) ...[
            const SizedBox(height: 6),
            Text(
              'status: $_jobStatus',
              style: const TextStyle(color: AppColors.secondaryText),
            ),
          ],
        ],
      );
    }
    return const Column(
      children: [
        CupertinoActivityIndicator(radius: 16),
        SizedBox(height: 8),
        Text(
          '印刷中...',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.label,
          ),
        ),
        SizedBox(height: 6),
        Text('このままお待ちください', style: TextStyle(color: AppColors.secondaryText)),
      ],
    );
  }

  Widget _buildStepRow(_ProgressStep step) {
    final labelColor = CupertinoDynamicColor.resolve(
      CupertinoColors.label,
      context,
    );
    final secondaryColor = CupertinoDynamicColor.resolve(
      AppColors.secondaryText,
      context,
    );
    final pendingIconColor = CupertinoDynamicColor.resolve(
      CupertinoColors.systemGrey3,
      context,
    );
    final successColor = CupertinoDynamicColor.resolve(
      CupertinoColors.systemGreen,
      context,
    );
    final failureColor = CupertinoDynamicColor.resolve(
      CupertinoColors.systemRed,
      context,
    );

    Widget indicator;
    Color textColor = labelColor;
    if (step.status == _StepStatus.pending) {
      indicator = Icon(
        CupertinoIcons.circle,
        color: pendingIconColor,
        size: 20,
      );
      textColor = secondaryColor;
    } else if (step.status == _StepStatus.running) {
      indicator = const CupertinoActivityIndicator(radius: 10);
    } else if (step.status == _StepStatus.success) {
      indicator = Icon(
        CupertinoIcons.check_mark_circled_solid,
        color: successColor,
        size: 20,
      );
      textColor = successColor;
    } else {
      indicator = Icon(
        CupertinoIcons.xmark_circle_fill,
        color: failureColor,
        size: 20,
      );
      textColor = failureColor;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          indicator,
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              step.title,
              style: TextStyle(fontSize: 16, color: textColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('印刷状況')),
      child: SafeArea(
        child: DefaultTextStyle(
          style: const TextStyle(color: CupertinoColors.label),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                Container(height: 1, color: CupertinoColors.separator),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: _steps.length,
                    itemBuilder: (context, index) =>
                        _buildStepRow(_steps[index]),
                  ),
                ),
                if (_isDone || _isFailed) ...[
                  const SizedBox(height: 12),
                  CupertinoButton.filled(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('閉じる'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
