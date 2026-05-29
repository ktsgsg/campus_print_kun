import 'dart:io';

import 'package:flutter/cupertino.dart';

import '../features/webprint/webprint.dart';
import '../l10n/app_localizations.dart';
import 'app_colors.dart';
import 'features/print_progress/view_models/print_progress_view_model.dart';

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
  late final PrintProgressViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = PrintProgressViewModel();
    _viewModel.run(
      user: widget.user,
      pass: widget.pass,
      file: widget.file,
      format: widget.format,
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  String _stepTitle(AppLocalizations l10n, PrintStepKind kind) =>
      switch (kind) {
        PrintStepKind.connect => l10n.stepConnect,
        PrintStepKind.auth => l10n.stepAuth,
        PrintStepKind.sendPdf => l10n.stepSendPdf,
        PrintStepKind.done => l10n.stepDone,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(l10n.printStatus)),
      child: SafeArea(
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) => DefaultTextStyle(
            style: const TextStyle(color: CupertinoColors.label),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(l10n),
                  const SizedBox(height: 16),
                  Container(height: 1, color: CupertinoColors.separator),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _viewModel.steps.length,
                      itemBuilder: (context, index) =>
                          _buildStepRow(l10n, _viewModel.steps[index]),
                    ),
                  ),
                  if (_viewModel.isDone || _viewModel.isFailed) ...[
                    const SizedBox(height: 12),
                    CupertinoButton.filled(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.close),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    if (_viewModel.isFailed) {
      return Column(
        children: [
          const Icon(
            CupertinoIcons.xmark_circle_fill,
            size: 56,
            color: CupertinoColors.systemRed,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.failed,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.label,
            ),
          ),
          if (_viewModel.errorMessage != null) ...[
            const SizedBox(height: 6),
            Text(
              _viewModel.errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.secondaryText),
            ),
          ],
        ],
      );
    }
    if (_viewModel.isDone) {
      return Column(
        children: [
          const Icon(
            CupertinoIcons.check_mark_circled_solid,
            size: 56,
            color: CupertinoColors.systemGreen,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.success,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.label,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.printJobSent,
            style: const TextStyle(color: AppColors.secondaryText),
          ),
          if (_viewModel.jobStatus != null) ...[
            const SizedBox(height: 6),
            Text(
              l10n.statusLabel(_viewModel.jobStatus!),
              style: const TextStyle(color: AppColors.secondaryText),
            ),
          ],
        ],
      );
    }
    return Column(
      children: [
        const CupertinoActivityIndicator(radius: 16),
        const SizedBox(height: 8),
        Text(
          l10n.printing,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.label,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.pleaseWait,
          style: const TextStyle(color: AppColors.secondaryText),
        ),
      ],
    );
  }

  Widget _buildStepRow(AppLocalizations l10n, PrintStep step) {
    final labelColor =
        CupertinoDynamicColor.resolve(CupertinoColors.label, context);
    final secondaryColor =
        CupertinoDynamicColor.resolve(AppColors.secondaryText, context);
    final pendingIconColor =
        CupertinoDynamicColor.resolve(CupertinoColors.systemGrey3, context);
    final successColor =
        CupertinoDynamicColor.resolve(CupertinoColors.systemGreen, context);
    final failureColor =
        CupertinoDynamicColor.resolve(CupertinoColors.systemRed, context);

    Widget indicator;
    Color textColor = labelColor;
    switch (step.status) {
      case PrintStepStatus.pending:
        indicator =
            Icon(CupertinoIcons.circle, color: pendingIconColor, size: 20);
        textColor = secondaryColor;
      case PrintStepStatus.running:
        indicator = const CupertinoActivityIndicator(radius: 10);
      case PrintStepStatus.success:
        indicator = Icon(CupertinoIcons.check_mark_circled_solid,
            color: successColor, size: 20);
        textColor = successColor;
      case PrintStepStatus.failure:
        indicator = Icon(CupertinoIcons.xmark_circle_fill,
            color: failureColor, size: 20);
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
              _stepTitle(l10n, step.kind),
              style: TextStyle(fontSize: 16, color: textColor),
            ),
          ),
        ],
      ),
    );
  }
}
