import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// 生バイト列での HTTP/1.1 レスポンス。
class RawHttpResponse {
  final int statusCode;

  /// ヘッダ名は小文字化して格納。同名複数行（Set-Cookie 等）は List に蓄積。
  final Map<String, List<String>> headers;
  final String body;

  RawHttpResponse({
    required this.statusCode,
    required this.headers,
    required this.body,
  });
}

/// URL のバイト列を一切正規化せずに HTTPS GET を送る。
///
/// Dart の Uri.parse / Uri() は RFC 3986 §6.2.2.2 に従い、percent-encoded
/// unreserved 文字 (A-Z a-z 0-9 - . _ ~) を自動デコードする。これにより
/// `%2E`→`.`、`%2D`→`-` のようにクエリのバイト列が変化し、SAML 署名
/// (元バイト列に対して計算される) の検証が失敗する。
///
/// この関数は Uri を経由せず、SecureSocket で raw な HTTP リクエストを直接
/// 書き込むため、Location ヘッダの URL バイト列をそのままサーバに届けられる。
///
/// 環境変数 `HTTP_PROXY_HOST` (--dart-define) が指定されていれば
/// HTTP CONNECT で TLS をトンネルしてプロキシ経由で送信する (mitmproxy 用)。
Future<RawHttpResponse> rawHttpsGet(
  String url, {
  Map<String, String> headers = const {},
}) async {
  if (!url.startsWith('https://')) {
    throw ArgumentError.value(url, 'url', 'only https is supported');
  }
  const schemePrefix = 'https://';
  var pathStart = url.indexOf('/', schemePrefix.length);
  if (pathStart < 0) pathStart = url.length;
  final authority = url.substring(schemePrefix.length, pathStart);
  final rawPathQuery = pathStart < url.length ? url.substring(pathStart) : '/';

  final colonIdx = authority.indexOf(':');
  final host = colonIdx < 0 ? authority : authority.substring(0, colonIdx);
  final port = colonIdx < 0
      ? 443
      : int.parse(authority.substring(colonIdx + 1));

  final socket = await _connect(host, port, authority);
  try {
    final req = StringBuffer()
      ..write('GET ')
      ..write(rawPathQuery)
      ..write(' HTTP/1.1\r\n')
      ..write('Host: ')
      ..write(authority)
      ..write('\r\n');
    for (final e in headers.entries) {
      req
        ..write(e.key)
        ..write(': ')
        ..write(e.value)
        ..write('\r\n');
    }
    req.write('Connection: close\r\n\r\n');

    socket.add(utf8.encode(req.toString()));
    await socket.flush();

    final all = BytesBuilder();
    await for (final chunk in socket) {
      all.add(chunk);
    }
    return _parseHttpResponse(all.takeBytes());
  } finally {
    try {
      socket.destroy();
    } catch (_) {}
  }
}

Future<Socket> _connect(String host, int port, String authority) async {
  const proxyEnv = String.fromEnvironment('HTTP_PROXY_HOST');
  if (proxyEnv.isEmpty) {
    return SecureSocket.connect(
      host,
      port,
      onBadCertificate: (_) => true,
    );
  }
  // HTTP CONNECT プロキシ経由
  final pParts = proxyEnv.split(':');
  final pHost = pParts[0];
  final pPort = pParts.length > 1 ? int.parse(pParts[1]) : 8080;
  final plain = await Socket.connect(pHost, pPort);

  plain.write('CONNECT $authority HTTP/1.1\r\n');
  plain.write('Host: $authority\r\n');
  plain.write('\r\n');
  await plain.flush();

  // CONNECT 応答を `\r\n\r\n` まで読む
  final completer = Completer<List<int>>();
  final buf = BytesBuilder();
  late StreamSubscription<Uint8List> sub;
  sub = plain.listen(
    (chunk) {
      buf.add(chunk);
      if (_findHeaderEnd(buf.toBytes()) >= 0 && !completer.isCompleted) {
        completer.complete(buf.toBytes());
      }
    },
    onError: (Object e, StackTrace st) {
      if (!completer.isCompleted) completer.completeError(e, st);
    },
    onDone: () {
      if (!completer.isCompleted) {
        completer.completeError(
          StateError('Proxy closed before CONNECT response'),
        );
      }
    },
  );

  try {
    final bytes = await completer.future;
    await sub.cancel();

    final str = ascii.decode(bytes, allowInvalid: true);
    if (!RegExp(r'^HTTP/1\.[01] 2\d\d').hasMatch(str)) {
      plain.destroy();
      throw Exception(
        'Proxy CONNECT failed: ${str.split('\r\n').first}',
      );
    }
  } catch (_) {
    plain.destroy();
    rethrow;
  }

  // TLS にアップグレード
  return SecureSocket.secure(
    plain,
    host: host,
    onBadCertificate: (_) => true,
  );
}

RawHttpResponse _parseHttpResponse(Uint8List bytes) {
  final headerEnd = _findHeaderEnd(bytes);
  if (headerEnd < 0) {
    throw const FormatException('Malformed HTTP response: no header terminator');
  }
  final headerStr = ascii.decode(
    bytes.sublist(0, headerEnd),
    allowInvalid: true,
  );
  final bodyStart = headerEnd + 4;

  final lines = headerStr.split('\r\n');
  final statusParts = lines.first.split(' ');
  if (statusParts.length < 2) {
    throw FormatException('Malformed status line: ${lines.first}');
  }
  final statusCode = int.parse(statusParts[1]);

  final headers = <String, List<String>>{};
  for (var i = 1; i < lines.length; i++) {
    final line = lines[i];
    final colon = line.indexOf(':');
    if (colon < 0) continue;
    final name = line.substring(0, colon).trim().toLowerCase();
    final value = line.substring(colon + 1).trim();
    headers.putIfAbsent(name, () => <String>[]).add(value);
  }

  Uint8List bodyBytes = bodyStart < bytes.length
      ? bytes.sublist(bodyStart)
      : Uint8List(0);

  final te = headers['transfer-encoding']?.first.toLowerCase();
  if (te == 'chunked') {
    bodyBytes = _decodeChunked(bodyBytes);
  }

  return RawHttpResponse(
    statusCode: statusCode,
    headers: headers,
    body: utf8.decode(bodyBytes, allowMalformed: true),
  );
}

int _findHeaderEnd(List<int> bytes) {
  for (var i = 0; i + 3 < bytes.length; i++) {
    if (bytes[i] == 0x0d &&
        bytes[i + 1] == 0x0a &&
        bytes[i + 2] == 0x0d &&
        bytes[i + 3] == 0x0a) {
      return i;
    }
  }
  return -1;
}

Uint8List _decodeChunked(Uint8List body) {
  final out = BytesBuilder();
  var pos = 0;
  while (pos < body.length) {
    var lineEnd = pos;
    while (lineEnd + 1 < body.length &&
        !(body[lineEnd] == 0x0d && body[lineEnd + 1] == 0x0a)) {
      lineEnd++;
    }
    if (lineEnd + 1 >= body.length) break;
    final sizeLine = ascii.decode(body.sublist(pos, lineEnd));
    final size = int.tryParse(sizeLine.split(';').first.trim(), radix: 16);
    if (size == null) break;
    pos = lineEnd + 2;
    if (size == 0) break;
    if (pos + size > body.length) break;
    out.add(body.sublist(pos, pos + size));
    pos += size;
    if (pos + 1 < body.length &&
        body[pos] == 0x0d &&
        body[pos + 1] == 0x0a) {
      pos += 2;
    }
  }
  return out.takeBytes();
}
