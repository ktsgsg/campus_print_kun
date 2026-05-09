import 'package:flutter/cupertino.dart';

import '../features/webprint/webprint.dart';
import '../l10n/app_localizations.dart';
import 'app_colors.dart';

/// 用紙サイズ・向き・N-up・両面の設定に従って PDF が
/// どう印刷されるかを示す模式プレビュー。
/// PDF 中身は描画せず、ページ番号のみセルに表示する。
class PrintLayoutPreview extends StatefulWidget {
  const PrintLayoutPreview({
    super.key,
    required this.pageCount,
    required this.format,
  });

  final int pageCount;
  final PrintFormat format;

  @override
  State<PrintLayoutPreview> createState() => _PrintLayoutPreviewState();
}

class _PrintLayoutPreviewState extends State<PrintLayoutPreview> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fmt = widget.format.toMap();
    final nup = (int.tryParse(fmt['number_up'] ?? '1') ?? 1).clamp(1, 4);
    final duplex = fmt['duplex_type'] == '2';
    final horizontal = fmt['page_sort'] != '2';
    final paperLabel = fmt['paper_type'] == '05' ? 'A3' : 'A4';
    final longEdgeBinding = fmt['print_orientation'] == '1';

    final pagesPerSheet = duplex ? nup * 2 : nup;
    final sheetCount =
        (widget.pageCount / pagesPerSheet).ceil().clamp(1, 9999);

    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _controller,
            itemCount: sheetCount,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, sheetIdx) {
              final firstPage = sheetIdx * pagesPerSheet;
              if (duplex) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _PaperSide(
                          firstPage: firstPage,
                          nup: nup,
                          horizontal: horizontal,
                          totalPages: widget.pageCount,
                          paperLabel: paperLabel,
                          sideLabel: l10n.previewFront,
                          showBinding: true,
                          bindingLongEdge: longEdgeBinding,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _PaperSide(
                          firstPage: firstPage + nup,
                          nup: nup,
                          horizontal: horizontal,
                          totalPages: widget.pageCount,
                          paperLabel: paperLabel,
                          sideLabel: l10n.previewBack,
                          showBinding: true,
                          bindingLongEdge: longEdgeBinding,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return _PaperSide(
                firstPage: firstPage,
                nup: nup,
                horizontal: horizontal,
                totalPages: widget.pageCount,
                paperLabel: paperLabel,
                sideLabel: null,
                showBinding: false,
                bindingLongEdge: longEdgeBinding,
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.previewSheetIndicator(_index + 1, sheetCount),
          style: TextStyle(
            fontSize: 12,
            color: CupertinoDynamicColor.resolve(
              AppColors.secondaryText,
              context,
            ),
          ),
        ),
      ],
    );
  }
}

class _PaperSide extends StatelessWidget {
  const _PaperSide({
    required this.firstPage,
    required this.nup,
    required this.horizontal,
    required this.totalPages,
    required this.paperLabel,
    required this.sideLabel,
    required this.showBinding,
    required this.bindingLongEdge,
  });

  final int firstPage;
  final int nup;
  final bool horizontal;
  final int totalPages;
  final String paperLabel;
  final String? sideLabel;
  final bool showBinding;
  final bool bindingLongEdge;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1 / 1.4142, // A4/A3 portrait
              child: _Paper(
                firstPage: firstPage,
                nup: nup,
                horizontal: horizontal,
                totalPages: totalPages,
                paperLabel: paperLabel,
                showBinding: showBinding,
                bindingLongEdge: bindingLongEdge,
              ),
            ),
          ),
        ),
        if (sideLabel != null) ...[
          const SizedBox(height: 4),
          Text(
            sideLabel!,
            style: TextStyle(
              fontSize: 11,
              color: CupertinoDynamicColor.resolve(
                AppColors.secondaryText,
                context,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Paper extends StatelessWidget {
  const _Paper({
    required this.firstPage,
    required this.nup,
    required this.horizontal,
    required this.totalPages,
    required this.paperLabel,
    required this.showBinding,
    required this.bindingLongEdge,
  });

  final int firstPage;
  final int nup;
  final bool horizontal;
  final int totalPages;
  final String paperLabel;
  final bool showBinding;
  final bool bindingLongEdge;

  @override
  Widget build(BuildContext context) {
    final border = CupertinoDynamicColor.resolve(AppColors.fieldBorder, context);
    final bindingColor = CupertinoDynamicColor.resolve(
      AppColors.primary,
      context,
    ).withValues(alpha: 0.35);
    final (rows, cols) = _gridDims(nup);

    final cells = List<int?>.filled(rows * cols, null);
    for (int i = 0; i < nup; i++) {
      final pageNum = firstPage + i + 1;
      if (pageNum > totalPages) break;
      int r, c;
      if (rows > 1 && cols > 1 && !horizontal) {
        c = i ~/ rows;
        r = i % rows;
      } else {
        r = i ~/ cols;
        c = i % cols;
      }
      cells[r * cols + c] = pageNum;
    }

    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        border: Border.all(color: border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (showBinding)
            Positioned(
              left: 0,
              top: 0,
              right: bindingLongEdge ? null : 0,
              bottom: bindingLongEdge ? 0 : null,
              child: Container(
                width: bindingLongEdge ? 6 : null,
                height: bindingLongEdge ? null : 6,
                color: bindingColor,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              children: [
                for (int r = 0; r < rows; r++)
                  Expanded(
                    child: Row(
                      children: [
                        for (int c = 0; c < cols; c++)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: _PageCell(
                                pageNumber: cells[r * cols + c],
                                border: border,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            right: 4,
            bottom: 2,
            child: Text(
              paperLabel,
              style: TextStyle(
                fontSize: 9,
                color: CupertinoColors.systemGrey.resolveFrom(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  (int, int) _gridDims(int nup) {
    switch (nup) {
      case 2:
        return (2, 1);
      case 3:
        return (3, 1);
      case 4:
        return (2, 2);
      default:
        return (1, 1);
    }
  }
}

class _PageCell extends StatelessWidget {
  const _PageCell({required this.pageNumber, required this.border});

  final int? pageNumber;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: pageNumber == null
            ? const Color(0x00000000)
            : const Color(0xFFF7F7FA),
        border: Border.all(
          color: border,
          style: pageNumber == null ? BorderStyle.none : BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(2),
      ),
      alignment: Alignment.center,
      child: pageNumber == null
          ? null
          : FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Text(
                  '$pageNumber',
                  style: const TextStyle(
                    fontSize: 28,
                    color: Color(0xFF555555),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
    );
  }
}
