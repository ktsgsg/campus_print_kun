import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:html/parser.dart' as html_parser;

import 'auth_token.dart';
import 'f5_st.dart';

const _ccmoonHost = 'https://ccmoon2.meijo-u.ac.jp';
const _ccmoonDomain = 'ccmoon2.meijo-u.ac.jp';
const _ssoStartUrl = 'https://slbsso.meijo-u.ac.jp/opensso/sso.jsp?app=ccmoon';
const _defaultBaseurl =
    r'/f5-w-<REDACTED_BACKEND_URL_HEX>$$/';

/// CC Moon 認証後のセッションを表す。`dio` を使ってログイン済み状態で
/// 後続 API を叩ける。
class CcMoonSession {
  final Dio dio;
  final CookieJar cookieJar;
  final String baseurl;

  CcMoonSession({
    required this.dio,
    required this.cookieJar,
    required this.baseurl,
  });
}

/// 名城大 SSO -> CC Moon Webtop までを通し、ログイン済みセッションを返す。
///
/// Python 版の `connect_ccmoon` を移植したもの。
/// - 一時 HTML ファイルへの書き出しは行わず、ベース URL は応答 HTML から抽出する。
/// - 抽出に失敗した場合は静的デフォルト [_defaultBaseurl] にフォールバック。
Future<CcMoonSession> connectCcmoon({
  required String username,
  required String password,
  CookieJar? cookieJar,
}) async {
  final jar = cookieJar ?? CookieJar();
  final dio = Dio(BaseOptions(
    followRedirects: false,
    validateStatus: (s) => s != null && s < 400,
    responseType: ResponseType.plain,
  ));
  dio.interceptors.add(CookieManager(jar));

  // 1. token 取得 → iPlanetDirectoryPro cookie をセット
  final token = await getToken(username, password);
  await jar.saveFromResponse(
    Uri.parse('https://slbsso.meijo-u.ac.jp/'),
    [Cookie('iPlanetDirectoryPro', token)],
  );

  // 2. SSO 開始 → 302 を手動追跡
  final res0 = await dio.get(_ssoStartUrl);
  final loc0 = _requireLocation(res0, 'sso.jsp');
  final res1 = await dio.get(loc0);
  final loc1 = _requireLocation(res1, 'sso redirect 1');
  final res2 = await dio.get('$_ccmoonHost$loc1');
  if (res2.statusCode != 302) {
    throw Exception('ccmoonへの接続に失敗しました (status=${res2.statusCode})');
  }

  // 3. raw Location をそのまま使って F5 リバースプロキシのエンコード済み URL を保持
  final rawLocation = _requireLocation(res2, 'sso redirect 2');
  final res3 = await dio.getUri(Uri.parse(rawLocation));
  if (res3.statusCode != 200) {
    throw Exception('ccmoonへの接続に失敗しました (status=${res3.statusCode})');
  }

  // 4. SAMLResponse を抽出して送信
  final samlHtml = res3.data as String;
  final samlPostBody = _extractSamlForm(samlHtml);
  final samlRes = await dio.post(
    samlPostBody.actionUrl,
    data: {'SAMLResponse': samlPostBody.samlResponse},
    options: Options(
      contentType: Headers.formUrlEncodedContentType,
      followRedirects: false,
      validateStatus: (s) => s != null && s < 400,
    ),
  );
  final webtopLoc = samlRes.headers.value('location');
  String? webtopHtml;
  if (webtopLoc != null) {
    final webtopRes = await dio.get(
      '$_ccmoonHost$webtopLoc',
      options: Options(
        followRedirects: false,
        validateStatus: (s) => s != null && s < 400,
      ),
    );
    if (webtopRes.statusCode == 200 && webtopRes.data is String) {
      webtopHtml = webtopRes.data as String;
    }
  }

  // 5. F5_ST cookie を長寿命に差し替え
  final cookies = await jar.loadForRequest(Uri.parse('$_ccmoonHost/'));
  final originalF5St = cookies
      .cast<Cookie?>()
      .firstWhere((c) => c?.name == 'F5_ST', orElse: () => null)
      ?.value;
  if (originalF5St == null) {
    throw StateError('F5_ST cookie が取得できませんでした');
  }
  final newF5St = genF5St(originalF5St);
  await jar.saveFromResponse(Uri.parse('$_ccmoonHost/'), [
    Cookie('F5_ST', newF5St)
      ..domain = _ccmoonDomain
      ..path = '/',
    Cookie('TIN', '18000')
      ..domain = _ccmoonDomain
      ..path = '/',
    Cookie('F5_fullWT', '1')
      ..domain = _ccmoonDomain
      ..path = '/',
  ]);

  // 6. baseurl を Webtop HTML から抽出 (取れなければ静的デフォルト)
  final baseurl = (webtopHtml != null ? _extractBaseurl(webtopHtml) : null) ??
      _defaultBaseurl;

  return CcMoonSession(dio: dio, cookieJar: jar, baseurl: baseurl);
}

class _SamlForm {
  final String actionUrl;
  final String samlResponse;
  _SamlForm(this.actionUrl, this.samlResponse);
}

_SamlForm _extractSamlForm(String html) {
  final document = html_parser.parse(html);
  final form = document.querySelector('form');
  if (form == null) {
    throw Exception('SAML form が見つかりません');
  }
  final action = form.attributes['action'];
  final samlInput = form.querySelector('input[name="SAMLResponse"]');
  final samlValue = samlInput?.attributes['value'];
  if (action == null || samlValue == null) {
    throw Exception('SAML form の action / SAMLResponse が見つかりません');
  }
  return _SamlForm(_htmlUnescape(action), samlValue);
}

String? _extractBaseurl(String html) {
  final regex = RegExp(r"var\s+ur_baseurl\s*=\s*'([^']+)'");
  return regex.firstMatch(html)?.group(1);
}

String _requireLocation(Response<dynamic> res, String label) {
  final loc = res.headers.value('location');
  if (loc == null) {
    throw StateError('$label: Location ヘッダがありません (status=${res.statusCode})');
  }
  return loc;
}

String _htmlUnescape(String s) => s
    .replaceAll('&amp;', '&')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'")
    .replaceAll('&#x27;', "'");
