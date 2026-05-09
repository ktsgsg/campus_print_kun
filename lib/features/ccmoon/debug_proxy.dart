import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

/// `--dart-define=HTTP_PROXY_HOST=host:port` が指定されていれば、その HTTP
/// プロキシを dio クライアントに設定する。mitmproxy 等で SAML/SSO のワイヤ
/// 形式を確認するための検証用ヘルパ。未指定時は何もしない。
///
/// 使用例:
///   flutter run --dart-define=HTTP_PROXY_HOST=127.0.0.1:8080
void applyDebugProxy(Dio client) {
  const proxyHost = String.fromEnvironment('HTTP_PROXY_HOST');
  if (proxyHost.isEmpty) return;
  client.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      final c = HttpClient();
      c.findProxy = (_) => 'PROXY $proxyHost';
      c.badCertificateCallback = (_, _, _) => true;
      return c;
    },
  );
}
