import 'dart:convert';
import 'dart:io';

/// PDF のページ数を純 Dart で概算する。
///
/// 非圧縮ストリームの `/Type /Page` 出現数を数える簡易実装。
/// オブジェクトストリーム圧縮 (PDF 1.5+) された PDF では検出できないことがあるが、
/// その場合は 1 を返す。プレビュー用途のため厳密性より依存ゼロを優先。
Future<int> countPdfPages(File file) async {
  try {
    final bytes = await file.readAsBytes();
    final text = latin1.decode(bytes, allowInvalid: true);
    final matches = RegExp(r'/Type\s*/Page(?![s/\w])').allMatches(text);
    final count = matches.length;
    return count > 0 ? count : 1;
  } catch (_) {
    return 1;
  }
}
