import 'package:dio/dio.dart';

const _authUrl = 'https://slbsso.meijo-u.ac.jp/opensso/json/authenticate';

Future<String> getToken(
  String userid,
  String password, {
  Dio? dio,
  int maxAttempts = 20,
  Duration retryInterval = const Duration(milliseconds: 500),
}) async {
  final client = dio ?? Dio();
  final headers = {'Content-Type': 'application/json'};

  try {
    final initial = await client.post(
      _authUrl,
      options: Options(headers: headers),
    );
    final body = Map<String, dynamic>.from(initial.data as Map);
    body['callbacks'][0]['input'][0]['value'] = userid;
    body['callbacks'][1]['input'][0]['value'] = password;

    Response? token;
    for (var i = 0; i < maxAttempts; i++) {
      token = await client.post(
        _authUrl,
        data: body,
        options: Options(
          headers: headers,
          validateStatus: (_) => true,
        ),
      );
      if (token.statusCode == 200) break;
      await Future.delayed(retryInterval);
    }
    if (token == null || token.statusCode != 200) {
      throw StateError('認証エンドポイント応答異常 (last=${token?.statusCode})');
    }
    return (token.data as Map)['tokenId'] as String;
  } catch (e, st) {
    Error.throwWithStackTrace(
      Exception('tokenを取得することができませんでした.時間をおいて再度試してください. ($e)'),
      st,
    );
  }
}
