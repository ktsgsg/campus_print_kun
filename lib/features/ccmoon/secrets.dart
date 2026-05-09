/// CC Moon 印刷バックエンドの非公開な接続情報を、ビルド時の dart-define から
/// 取り込むためのコンテナ。リポジトリには値を含めず、ビルド／実行時に
/// `--dart-define` で注入する。
///
/// 値の意味:
///   * [backendUrlHex] — `https://<print-backend-host>` 全体を hex
///     エンコードした文字列。F5 BIG-IP リバースプロキシのパス
///     `/f5-w-<hex>$$/` に埋め込まれる。
///   * [backendFilterHex] — Webtop HTML 中に複数並ぶ `var ur_baseurl`
///     から印刷用エントリを選別するための部分一致 hex。通常はバックエンド
///     ホスト名の中核部分の hex を指定する。
///
/// 使用例:
///   flutter run \
///     --dart-define=CCMOON_BACKEND_URL_HEX=0102030405ab... \
///     --dart-define=CCMOON_BACKEND_FILTER_HEX=0a0b0c0d0e0f...
class CcmoonSecrets {
  static const String backendUrlHex = String.fromEnvironment(
    'CCMOON_BACKEND_URL_HEX',
  );

  static const String backendFilterHex = String.fromEnvironment(
    'CCMOON_BACKEND_FILTER_HEX',
  );

  /// `backendUrlHex` から組み立てた F5 BIG-IP 用 baseurl。
  /// dart-define が無い場合は `null` を返し、Webtop からの抽出のみに頼る。
  static String? get defaultBaseurl =>
      backendUrlHex.isEmpty ? null : '/f5-w-$backendUrlHex\$\$/';
}
