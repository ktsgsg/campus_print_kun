# 開発進捗メモ

## プロジェクト概要

**Campus Print Kun（キャンパスプリントくん）**  
名城大学の CC Moon プリントサービスに iPhone/Android から PDF を送信するアプリ。  
Python スクリプトを Flutter (iOS/Android) に移植したもの。

---

## 完成している機能

- 名城大 SSO → SAML → CC Moon WebPrint への認証フロー
- RSA 暗号化によるプリントサービス認証
- PDF の multipart アップロード（印刷ジョブ送信）
- 認証情報の Keychain（iOS）/ EncryptedSharedPreferences（Android）保存・自動ロード
- 印刷設定画面（用紙・両面・部数・n-up）
- ステップ表示付き進捗画面
- Cupertino (iOS ネイティブ風) UI・ダークモード対応
- OS シェアシートからの PDF 受け取り（iOS/Android 両対応）
- 印刷履歴画面（月範囲・ステータスフィルタで `api/job/histories/search` を検索）
- 印刷状況画面（ステータスフィルタで `api/job/prints/search` を検索）
- ボトムタブ（履歴 / 印刷状況）による画面切り替え
- 日英対応（システム言語に応じて自動切替）

---

## 認証フロー（核心部分）

```
getToken()            → iPlanetDirectoryPro トークン取得
GET sso.jsp           → 302 → loc0  (slbsso ドメイン)
GET loc0              → 302 → loc1  (slbsso ドメイン)
GET ccmoon + loc1     → 302、ボディに <a href="...saml...">  (ccmoon ドメイン)
rawHttpsGet(samlUrl)  → 200、SAMLResponse を含む HTML フォーム
POST SAMLResponse     → 302 → Webtop
GET Webtop            → baseurl JS 変数を抽出
genF5St()             → F5_ST を長寿命に書き換え
Cookie → CookieJar    → 以降は dio + CookieManager で自動管理
```

---

## 苦労した点・失敗した試み

### 1. SAML リダイレクト URL の URL エンコーディング問題（最大の難関）

**問題:**  
CC Moon からの 302 レスポンスの Location ヘッダには SAML リダイレクト URL が入っており、
クエリパラメータに `%2E`（`.`）や `%2D`（`-`）などのパーセントエンコードが含まれる。

**試み①: `Uri.decodeFull` で全部デコード → 失敗**  
`SigAlg` の値に `%23`（= `#`）が含まれており、デコードすると literal `#` になる。  
Dart の `Uri.parse` はそれ以降をフラグメントと解釈するため、`Signature` パラメータが
リクエストから消え、SAML 署名検証に失敗した。

**試み②: percent-encoded のまま dio で送信 → 失敗**  
サーバ（OpenSSO）が署名検証時に URL を正規化（unreserved 文字をデコード）している模様で、
`%2E` が `.` に、`%2D` が `-` に変わることを期待していた。そのため encoded のまま送ると
署名不一致になった。

**試み③: `_canonicalizeQueryEncoding`（Uri.queryParametersAll + replace）→ 失敗**  
Dart の `encodeQueryComponent` は `+` をエンコードしない場合があり、base64 Signature 値の
`%2B` が `+` のまま送られると空白として解釈されるリスクがある。また再エンコードの差異が
署名不一致を引き起こした。

**試み④: `_normalizeSamlUrl`（`%23`・`%2B` を保護しつつ decodeFull）→ 途中まで**  
プレースホルダで `%23` と `%2B` を保護して `Uri.decodeFull` する方式を試みたが、
根本的には dio の `Uri.parse` を経由する限り同じ問題が再発するリスクがあった。

**最終解: `rawHttpsGet`（SecureSocket 直書き）→ 成功**  
`raw_http.dart` に `SecureSocket` を使った raw HTTP/1.1 クライアントを自作。  
`Uri.parse` を一切経由しないため、Location ヘッダのバイト列をそのままリクエストラインに
書き込める。これで SAML 署名検証が通るようになった。  
chunked transfer encoding のデコードも自前実装。mitmproxy 用の HTTP CONNECT トンネリングも対応。

---

### 2. Cookie のドメイン分離

**問題:**  
当初は `CookieManager` を SSO フロー全体に使っていたが、500 エラーが頻発。

**原因:**  
Python 版の `requests.Session` はドメインスコープを自動で分離するが、
`CookieJar` + `CookieManager` では全ドメインに同じ Cookie を送ってしまった。

**解決:**  
Cookie を 2 つの `Map<String, String>` で手動管理する方式に変更:

| ストア | 送信先 | 内容 |
|--------|--------|------|
| `slbssoCookies` | `slbsso.meijo-u.ac.jp` のみ | `iPlanetDirectoryPro` + SSO レスポンス Cookie |
| `manualCookies` | `ccmoon2.meijo-u.ac.jp` のみ | `iPlanetDirectoryPro` + ccmoon Cookie |

`iPlanetDirectoryPro` は両方のストアに最初に投入する。  
認証完了後に `manualCookies` を `CookieJar` に移行し、WebPrint API 以降は dio で自動管理。

---

### 3. res2 の 302 ボディから href を抽出する必要があった

**問題:**  
ccmoon からの 302 レスポンスは `Location` ヘッダではなく、ボディの HTML に
`<a href="...saml...">here</a>` として SAML リダイレクト URL を埋め込んでいた。

```html
<html><head><h1>302 Moved</h1><a href="https://slbsso...?SAMLRequest=...">here</a></head></html>
```

当初 `Location` ヘッダを期待していたため、Location が取れずに例外が発生した。

**解決:**  
`RegExp(r'href="([^"]+)"')` で HTML ボディから href を抽出。
`&amp;` などの HTML エンティティを `_htmlUnescape` で戻してから使用。

---

### 4. PrintFormat の ip・user_id の動的注入

**問題:**  
印刷設定の `ip` と `user_id` は固定値でハードコードされていた。

**解決:**  
`WebPrint.initialize()` 実行後に `userId`・`ipAddress` フィールドに確定値を保持し、
`pdfPrint()` 内で `PrintFormat.copyWith()` を使って自動注入する設計に変更。

---

### 5. OS シェアシート対応（iOS / Android）

**方針:**  
Share Extension（別 Xcode ターゲット）は不要。iOS/Android ともにホストアプリ側で処理する。

**iOS:**  
`Info.plist` に `CFBundleDocumentTypes`（`com.adobe.pdf`、`LSHandlerRank=Alternate`）を
追加するだけで、iOS が `Documents/Inbox/` にコピーして `SceneDelegate` 経由で通知してくれる。

- `FlutterViewController.engine` は non-optional なのに `?.binaryMessenger` と書いてしまい
  コンパイルエラー → `flutterVC.engine.binaryMessenger` に修正
- `setMethodCallHandler` のクロージャ型が推論されず
  `(call: FlutterMethodCall, result: FlutterResult) in` と明示する必要があった
- `willConnectTo` 時点では Flutter エンジンが未初期化のため、
  受け取った URL を `pendingPdfPath` にバッファしておき、
  `sceneDidBecomeActive` でチャンネルが準備できてから flush する設計にした。

**Android:**  
`MainActivity.kt` で `ACTION_VIEW` / `ACTION_SEND` インテントを捕捉。  
`ContentResolver` で PDF を `cacheDir` にコピーし、パスを MethodChannel 経由で Dart 側に送る。  
ファイル名は `OpenableColumns.DISPLAY_NAME` で取得（取れなければ `lastPathSegment` にフォールバック）。

---

### 6. 履歴・印刷状況画面のローカライゼーション

**問題:**  
ARB ファイル（`app_en.arb` / `app_ja.arb`）から `flutter gen-l10n` で Dart ファイルが
自動生成されるため、生成済みの `app_localizations*.dart` を直接編集しても次ビルド時に上書きされる。

**解決:**  
ARB ファイルのみを編集し、`flutter gen-l10n` で再生成する運用に統一。

---

### 7. CupertinoTabView 内からの戻る操作

**問題:**  
`CupertinoTabScaffold` の各タブは独立したナビゲータを持つため、
ネストされたナビゲータの `pop()` を呼ぶとタブ内遷移のスタックが pop されてしまう。

**解決:**  
`Navigator.of(context, rootNavigator: true).pop()` でルートナビゲータを明示的に指定する。

---

### 8. ハードコードされた学籍番号の除去

**問題:**  
`webprint_service.dart` の `getUserinfo()` にデフォルト引数として学籍番号がハードコードされていた。  
`git log -p` で初期コミットから存在することを確認。

**解決:**  
1. 現在のコードで `userId = '241205100'` → `userId = ''` に修正
2. `git filter-repo --replace-text` で全コミット履歴から学籍番号を除去
3. `git push --force origin main` でリモート（GitHub）にも反映

---

## 現在の課題・未検証事項

- **SAML 認証の実機での最終確認未完了**（rawHttpsGet への移行後）
- エラー時のリトライ・タイムアウト処理は未実装
- iOS / Android シェアシートの実機テスト未完了

---

## ファイル構成（主要）

```
lib/
  features/
    ccmoon/
      auth_token.dart        - OpenSSO トークン取得
      connect_ccmoon.dart    - SSO フロー全体 ★コア
      raw_http.dart          - SecureSocket 直書き HTTPS クライアント ★重要
      f5_st.dart             - F5_ST Cookie の長寿命化
      debug_proxy.dart       - mitmproxy 用プロキシ設定
    webprint/
      webprint_service.dart  - WebPrint API クライアント
      encripter.dart         - RSA PKCS#1 v1.5 暗号化
    auth/
      credential_store.dart  - Keychain 認証情報保存
    sharing/
      shared_pdf_service.dart - OS 共有 PDF 受け取り (MethodChannel)
  ui/
    print_test_page.dart     - メイン画面（認証情報・PDF 選択・印刷開始）
    print_progress_page.dart - 印刷進捗画面
    print_settings_page.dart - 印刷設定画面
    job_history_page.dart    - 印刷履歴 + 印刷状況（CupertinoTabScaffold）
    app_colors.dart          - ダークモード対応カラー定義
  l10n/
    app_en.arb               - 英語文言 ★編集はここ
    app_ja.arb               - 日本語文言 ★編集はここ
  main.dart

ios/Runner/
  SceneDelegate.swift        - PDF 共有受け取り・MethodChannel 設定
  Info.plist                 - CFBundleDocumentTypes 登録済み

android/app/src/main/kotlin/.../
  MainActivity.kt            - ACTION_VIEW/ACTION_SEND インテント処理
```

---

## デバッグ方法

```bash
# mitmproxy でワイヤ上の HTTP を確認
brew install mitmproxy && mitmweb
flutter run --dart-define=HTTP_PROXY_HOST=127.0.0.1:8080
# mitmweb の Raw タブで SAML クエリのバイト列を確認

# ローカライゼーション再生成
flutter gen-l10n
```
