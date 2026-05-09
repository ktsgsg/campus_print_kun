import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../ccmoon/connect_ccmoon.dart';
import 'encripter.dart';

/// Web プリントジョブの設定値。Python版 `defaultformat` と互換。
class PrintFormat {
  static const Map<String, String> defaults = {
    'user_id': '0000',
    'queue_id': 'web-ondemand',
    'ip': '0.0.0.0',
    'paper_type': '06',
    'duplex_type': '1',
    'color_mode_type': '1',
    'copies': '1',
    'number_up': '1',
    'orientation_edge': '1',
    'print_orientation': '2',
    'page_sort': '1',
  };

  final Map<String, String> _data;

  PrintFormat([Map<String, String>? overrides])
    : _data = {...defaults, if (overrides != null) ...overrides};

  Map<String, String> toMap() => Map.unmodifiable(_data);

  PrintFormat copyWith(Map<String, String> overrides) =>
      PrintFormat({..._data, ...overrides});
}

/// CC Moon Web プリントサービスのクライアント。
///
/// 利用フロー:
/// ```dart
/// final session = await connectCcmoon(username: u, password: p);
/// final print = WebPrint(session);
/// await print.initialize(username: u, password: p);
/// await print.pdfPrint(filename: 'doc.pdf', printDataPath: '/path/to/doc.pdf');
/// ```
class WebPrint {
  final CcMoonSession session;
  String ipAddress = '';
  String userId = '';

  WebPrint(this.session);

  String get _printserviceUrl => '${WebtopConst.host}${session.baseurl}user/';
  String get _userBase =>
      '${WebtopConst.host}${session.baseurl}user/f5-h-\$\$/';
  String _api(String path) => '$_userBase$path';

  /// プリントトップ取得 → 認証 → IP 取得までを一度に実行。
  /// 完了後 [userId] と [ipAddress] が確定し、[pdfPrint] で自動適用される。
  Future<void> initialize({
    required String username,
    required String password,
  }) async {
    await getPrintservicePage();
    await authenticUser(username: username, password: password);
    userId = username;
    await getOwnIpAddress();
  }

  /// プリント画面の HTML を取得して返す (ファイルには書き出さない)。
  Future<String?> getPrintservicePage({String? url}) async {
    final target = url ?? _printserviceUrl;
    final res = await session.dio.get<String>(
      target,
      options: Options(
        followRedirects: true,
        validateStatus: (s) => s == 200,
        responseType: ResponseType.plain,
      ),
    );
    return res.data;
  }

  /// 認証用 RSA 公開鍵を取得し、PEM 形式に整形して返す。
  Future<String> getPubKey() async {
    final res = await session.dio.get<dynamic>(
      _api('api/auth/getpubkey'),
      options: Options(responseType: ResponseType.plain),
    );
    if (res.statusCode != 200) {
      throw Exception('公開鍵の取得に失敗しました (status=${res.statusCode})');
    }
    final body = res.data;
    final Map decoded = body is String ? jsonDecode(body) as Map : body as Map;
    final raw = decoded['pubkey'] as String;
    return _normalizePem(raw);
  }

  String _normalizePem(String raw) {
    const head = '-----BEGIN PUBLIC KEY-----';
    const tail = '-----END PUBLIC KEY-----';
    if (!raw.startsWith(head) || !raw.contains(tail)) {
      throw FormatException('公開鍵の形式が不正です');
    }
    final body = raw
        .replaceAll(head, '')
        .replaceAll(tail, '')
        .replaceAll(RegExp(r'\s+'), '');
    final wrapped = [
      for (var i = 0; i < body.length; i += 64)
        body.substring(i, i + 64 > body.length ? body.length : i + 64),
    ].join('\n');
    return '$head\n$wrapped\n$tail\n';
  }

  /// 認証情報を公開鍵で暗号化してフォーム値を生成。
  Future<Map<String, String>> encryptUserinfo({
    required String username,
    required String password,
    String? pubkeyPem,
  }) async {
    final pem = pubkeyPem ?? await getPubKey();
    return {
      'user_id': encryptForMeijo(username, pem),
      'user_password': encryptForMeijo(password, pem),
    };
  }

  /// `/api/auth/authuserenc` でログイン。`result == "ok"` を期待。
  Future<String> authenticUser({
    required String username,
    required String password,
  }) async {
    final body = await encryptUserinfo(username: username, password: password);
    final res = await session.dio.post<dynamic>(
      _api('api/auth/authuserenc'),
      data: body,
      options: Options(
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
        followRedirects: false,
      ),
    );
    if (res.statusCode != 200) {
      throw Exception('ユーザ認証に失敗しました (status=${res.statusCode})');
    }
    final result = (res.data as Map)['result'] as String?;
    if (result != 'ok') {
      throw Exception('ユーザ認証 result=$result');
    }
    return result!;
  }

  /// プリント設定 JSON を取得して返す (Python版のような settings.json への
  /// 自動書き出しは行わない。必要なら呼び出し側で保存する)。
  Future<Map<String, dynamic>> getSettings() async {
    final res = await session.dio.get<dynamic>(
      _api('api/system/settings'),
      options: Options(responseType: ResponseType.json),
    );
    if (res.statusCode != 200) {
      throw Exception('プリント設定の取得に失敗しました (status=${res.statusCode})');
    }
    return Map<String, dynamic>.from(res.data as Map);
  }

  /// ユーザ情報 JSON を取得して返す。
  Future<Map<String, dynamic>> getUserinfo({
    String userId = '',
    int type = 1,
  }) async {
    final res = await session.dio.get<dynamic>(
      _api('api/user/users/$userId?type=$type'),
      options: Options(responseType: ResponseType.json),
    );
    if (res.statusCode != 200) {
      throw Exception('ユーザ情報の取得に失敗しました (status=${res.statusCode})');
    }
    return Map<String, dynamic>.from(res.data as Map);
  }

  /// 自端末の IP を取得して [ipAddress] に保持。
  Future<String> getOwnIpAddress() async {
    final res = await session.dio.get<dynamic>(
      _api('api/system/notice/ownipaddress'),
      options: Options(responseType: ResponseType.json),
    );
    if (res.statusCode != 200) {
      throw Exception('自端末IPの取得に失敗しました (status=${res.statusCode})');
    }
    ipAddress = (res.data as Map)['ip_address'] as String;
    return ipAddress;
  }

  /// PDF を multipart で投入。
  /// `user_id` と `ip` は [initialize] 後に確定した値を自動で注入する。
  /// [format] で個別の印刷設定を上書きできる。
  Future<int> pdfPrint({
    required String filename,
    required String printDataPath,
    PrintFormat? format,
  }) async {
    // initialize() で確定した userId / ipAddress を注入
    final resolved = (format ?? PrintFormat()).copyWith({
      if (userId.isNotEmpty) 'user_id': userId,
      if (ipAddress.isNotEmpty) 'ip': ipAddress,
    });
    final fmt = resolved.toMap();
    final formData = FormData();
    formData.files.add(
      MapEntry(
        'data',
        MultipartFile.fromString(
          jsonEncode(fmt),
          filename: 'blob',
          contentType: MediaType('application', 'json'),
        ),
      ),
    );
    formData.files.add(
      MapEntry(
        'files',
        await MultipartFile.fromFile(
          printDataPath,
          filename: filename,
          contentType: MediaType('application', 'pdf'),
        ),
      ),
    );
    final res = await session.dio.post<dynamic>(
      _api('api/spool01/files/webprint'),
      data: formData,
      options: Options(followRedirects: false, validateStatus: (_) => true),
    );
    return res.statusCode ?? -1;
  }
}

class WebtopConst {
  static const String host = 'https://ccmoon2.meijo-u.ac.jp';
}
