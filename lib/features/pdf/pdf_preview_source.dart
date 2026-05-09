import 'dart:typed_data';

import 'package:pdfx/pdfx.dart';

/// 開いた PDF ドキュメントを保持し、ページレンダリング結果をキャッシュする。
/// プレビュー専用に低解像度 (固定幅) で 1 度だけレンダリングし、
/// 以降は同じバイト列を返す。`close()` で必ず破棄すること。
class PdfPreviewSource {
  PdfPreviewSource._(this._document, this.pageCount);

  static const double _renderWidth = 480;

  final PdfDocument _document;
  final int pageCount;
  final Map<int, Uint8List> _cache = {};
  final Map<int, Future<Uint8List?>> _pending = {};
  bool _closed = false;

  static Future<PdfPreviewSource> open(String path) async {
    final doc = await PdfDocument.openFile(path);
    return PdfPreviewSource._(doc, doc.pagesCount);
  }

  Future<Uint8List?> renderPage(int pageNumber) {
    if (_closed) return Future.value(null);
    final cached = _cache[pageNumber];
    if (cached != null) return Future.value(cached);
    final pending = _pending[pageNumber];
    if (pending != null) return pending;
    final future = _renderInternal(pageNumber);
    _pending[pageNumber] = future;
    return future;
  }

  Future<Uint8List?> _renderInternal(int pageNumber) async {
    PdfPage? page;
    try {
      page = await _document.getPage(pageNumber);
      final aspect = page.height / page.width;
      final image = await page.render(
        width: _renderWidth,
        height: _renderWidth * aspect,
        format: PdfPageImageFormat.png,
        backgroundColor: '#FFFFFF',
      );
      final bytes = image?.bytes;
      if (bytes != null && !_closed) {
        _cache[pageNumber] = bytes;
      }
      return bytes;
    } catch (_) {
      return null;
    } finally {
      await page?.close();
      _pending.remove(pageNumber);
    }
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _cache.clear();
    await _document.close();
  }
}
