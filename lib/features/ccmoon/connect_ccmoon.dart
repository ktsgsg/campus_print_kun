import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:html/parser.dart' as html_parser;

import 'auth_token.dart';
import 'debug_proxy.dart';
import 'f5_st.dart';
import 'raw_http.dart';

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
/// - Cookie を手動でドメイン別に管理（Python の requests.Session と同等）
///   slbsso Cookie を ccmoon には送らず、ccmoon Cookie を slbsso には送らない
/// - SAML URL は res2.headers['Location'] をそのまま使用（正規化バイパス）
/// - 一時 HTML ファイルへの書き出しは行わず、ベース URL は応答 HTML から抽出する。
/// - 抽出に失敗した場合は静的デフォルト [_defaultBaseurl] にフォールバック。
Future<CcMoonSession> connectCcmoon({
  required String username,
  required String password,
  CookieJar? cookieJar,
}) async {
  // SSO フロー中は CookieManager を使わず手動管理
  final ssoClient = Dio(
    BaseOptions(
      followRedirects: false,
      validateStatus: (s) => s != null && s < 400,
      responseType: ResponseType.plain,
    ),
  );
  applyDebugProxy(ssoClient);

  // WebPrint API 用に CookieJar を準備
  final jar = cookieJar ?? CookieJar();

  // Python の requests.Session に倣い、ドメイン別に Cookie を管理する。
  // slbssoCookies: slbsso.meijo-u.ac.jp 向けのみ（iPlanetDirectoryPro + SSO応答Cookie）
  // manualCookies: ccmoon2.meijo-u.ac.jp 向け全Cookie（WebPrint API用）
  final slbssoCookies = <String, String>{};
  final manualCookies = <String, String>{};

  // 1. Token 取得 → iPlanetDirectoryPro を両ストアにセット
  // Python: session.cookies.set("iPlanetDirectoryPro", token) はドメイン無指定で全送信
  final token = await getToken(username, password);
  slbssoCookies['iPlanetDirectoryPro'] = token;
  manualCookies['iPlanetDirectoryPro'] = token;

  // 2. SSO 開始 → 302 を手動追跡
  // res0, res1 は slbsso.meijo-u.ac.jp への通信 → 両ストアに収集
  final res0 = await ssoClient.get(
    _ssoStartUrl,
    options: Options(headers: {'Cookie': _buildCookieHeader(slbssoCookies)}),
  );
  _collectSetCookie(res0.headers, slbssoCookies);
  _collectSetCookie(res0.headers, manualCookies);
  final loc0 = _requireLocation(res0, 'sso.jsp');

  final res1 = await ssoClient.get(
    loc0,
    options: Options(headers: {'Cookie': _buildCookieHeader(slbssoCookies)}),
  );
  _collectSetCookie(res1.headers, slbssoCookies);
  _collectSetCookie(res1.headers, manualCookies);
  final loc1 = _requireLocation(res1, 'sso redirect 1');

  // res2 は ccmoon2.meijo-u.ac.jp への通信 → manualCookies にのみ収集
  // Python: session は ccmoon2 ドメインの Cookie を slbsso には送らない
  final res2 = await ssoClient.get(
    '$_ccmoonHost$loc1',
    options: Options(headers: {'Cookie': _buildCookieHeader(slbssoCookies)}),
  );
  _collectSetCookie(res2.headers, manualCookies); // slbssoCookies には追加しない
  if (res2.statusCode != 302) {
    throw Exception('ccmoonへの接続に失敗しました (status=${res2.statusCode})');
  }

  // 3. Python: raw_location = res2.headers['Location']
  //            prepared.url = raw_location  # URL 正規化をバイパス
  //
  // Location ヘッダの URL バイト列を一切加工せずに送信する。
  // Dart の Uri.parse / Uri() は RFC 3986 §6.2.2.2 に従って percent-encoded
  // unreserved 文字 (%2E→`.`, %2D→`-` 等) を自動デコードしてしまうため、
  // dio (HttpClient) を通すと SAML 署名検証が落ちる。
  // raw HTTP (SecureSocket 直書き) で URL バイト列を保持して送信する。
  final locationHeader = res2.headers.value('location');
  final rawSamlUrl =
      locationHeader ??
      (() {
        final m = RegExp(r'href="([^"]+)"').firstMatch(res2.data as String);
        if (m == null) throw Exception('SAML リダイレクト URL が見つかりません');
        return _htmlUnescape(m.group(1)!);
      })();

  // slbsso への SAML GET: ccmoon Cookie は送らない（Python と同じドメイン分離）
  final res3 = await rawHttpsGet(
    rawSamlUrl,
    headers: {'Cookie': _buildCookieHeader(slbssoCookies)},
  );
  _collectSetCookieList(res3.headers['set-cookie'], slbssoCookies);
  _collectSetCookieList(res3.headers['set-cookie'], manualCookies);
  if (res3.statusCode != 200) {
    throw Exception('ccmoonへの接続に失敗しました (status=${res3.statusCode})');
  }

  // 4. SAMLResponse を抽出して送信
  final samlHtml = res3.body;
  final samlPostBody = _extractSamlForm(samlHtml);
  final samlRes = await ssoClient.post(
    samlPostBody.actionUrl,
    data: {'SAMLResponse': samlPostBody.samlResponse},
    options: Options(
      contentType: Headers.formUrlEncodedContentType,
      headers: {'Cookie': _buildCookieHeader(manualCookies)},
    ),
  );
  _collectSetCookie(samlRes.headers, manualCookies);

  final webtopLoc = samlRes.headers.value('location');
  String? webtopHtml;
  if (webtopLoc != null) {
    final webtopUrl = webtopLoc.startsWith('http')
        ? webtopLoc
        : '$_ccmoonHost$webtopLoc';
    final webtopRes = await ssoClient.get(
      webtopUrl,
      options: Options(headers: {'Cookie': _buildCookieHeader(manualCookies)}),
    );
    _collectSetCookie(webtopRes.headers, manualCookies);
    if (webtopRes.statusCode == 200 && webtopRes.data is String) {
      webtopHtml = webtopRes.data as String;
    }
  }

  // 5. F5_ST cookie を長寿命に差し替え
  final originalF5St = manualCookies['F5_ST'];
  if (originalF5St == null) {
    throw StateError('F5_ST cookie が取得できませんでした');
  }
  final newF5St = genF5St(originalF5St);
  manualCookies['F5_ST'] = newF5St;
  manualCookies['TIN'] = '18000';
  manualCookies['F5_fullWT'] = '1';

  // 6. 収集した手動 Cookie を CookieJar に移行 (WebPrint API 用)
  await _storeCookiesInJar(jar, manualCookies, _ccmoonDomain);

  // 以降は dio + CookieManager で自動管理
  final dio = Dio(
    BaseOptions(
      followRedirects: false,
      validateStatus: (s) => s != null && s < 400,
      responseType: ResponseType.plain,
    ),
  );
  applyDebugProxy(dio);
  dio.interceptors.add(CookieManager(jar));

  // 7. baseurl を Webtop HTML から抽出 (取れなければ静的デフォルト)
  final baseurl =
      (webtopHtml != null ? _extractBaseurl(webtopHtml) : null) ??
      _defaultBaseurl;

  return CcMoonSession(dio: dio, cookieJar: jar, baseurl: baseurl);
}

// ── ヘルパ ───────────────────────────────────────────────

/// Cookie ヘッダ文字列を組み立てる。
String _buildCookieHeader(Map<String, String> cookies) {
  return cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
}

/// レスポンスの Set-Cookie ヘッダ群を解析してストアに蓄積する。
void _collectSetCookieList(
  List<String>? setCookieList,
  Map<String, String> store,
) {
  if (setCookieList == null) return;
  for (final sc in setCookieList) {
    final nameValue = sc.split(';').first.trim();
    final eq = nameValue.indexOf('=');
    if (eq < 0) continue;
    final name = nameValue.substring(0, eq).trim();
    final value = nameValue.substring(eq + 1).trim();
    store[name] = value;
  }
}

/// dio の Headers から Set-Cookie を取り出してストアに蓄積する。
void _collectSetCookie(Headers headers, Map<String, String> store) {
  _collectSetCookieList(headers['set-cookie'], store);
}

/// 収集した Cookie を CookieJar に書き込む。
Future<void> _storeCookiesInJar(
  CookieJar jar,
  Map<String, String> cookies,
  String domain,
) async {
  final uri = Uri.parse('https://$domain/');
  final dartCookies = cookies.entries.map((e) {
    final c = Cookie(e.key, e.value);
    c.domain = domain;
    c.path = '/';
    return c;
  }).toList();
  await jar.saveFromResponse(uri, dartCookies);
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

String _requireLocation(dynamic res, String label) {
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
