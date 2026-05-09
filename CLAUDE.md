# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this app does

**Campus Print Kun** is a Flutter app (iOS/Android) that lets Meijo University students submit print jobs to the university's CC Moon print service from their own device. It automates a multi-step SSO → WebPrint flow that normally requires a campus browser session. PDFs can be picked from the file system or shared directly from other apps via the OS share sheet.

## Commands

```bash
# Run on iOS simulator
flutter run

# Run with mitmproxy for SAML/HTTP debugging
flutter run --dart-define=HTTP_PROXY_HOST=127.0.0.1:8080

# Run with private backend hex (印刷バックエンドの hex を ccmoon_secrets.json から注入)
flutter run --dart-define-from-file=ccmoon_secrets.json

# Build for iOS
flutter build ios

# Lint / analyze
flutter analyze

# Run tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Regenerate localization Dart files from ARB
flutter gen-l10n
```

> **l10n の注意**: `lib/l10n/app_en.arb` / `app_ja.arb` のみを編集し、`flutter gen-l10n` で再生成する。生成済みの `app_localizations*.dart` を直接編集してもビルド時に上書きされる。

## Architecture

### Authentication flow (`lib/features/ccmoon/`)

The SSO flow is the core complexity of this app. It mirrors the Python original exactly:

1. **`auth_token.dart`** — POST to `slbsso.meijo-u.ac.jp/opensso/json/authenticate` to get `iPlanetDirectoryPro` token
2. **`connect_ccmoon.dart`** — Drives the full SSO → SAML → CC Moon session chain, returns `CcMoonSession`
3. **`raw_http.dart`** — `rawHttpsGet()`: sends HTTPS GET via `SecureSocket` without going through `Uri.parse`. **This is critical**: Dart's `Uri.parse` normalizes percent-encoded unreserved chars (`%2E`→`.`, `%2D`→`-`), which changes the SAML query byte sequence and breaks signature verification. This function must be used for the SAML redirect GET.
4. **`f5_st.dart`** — Rewrites the F5 BIG-IP `F5_ST` cookie to a long-lived version
5. **`debug_proxy.dart`** — `applyDebugProxy(dio)`: applies `HTTP_PROXY_HOST` dart-define to a dio instance for mitmproxy capture. Called on both `ssoClient` and the post-auth `dio`. Guards with `kReleaseMode` so TLS bypass code is compiled out in release builds.

### SSO step-by-step (`connect_ccmoon.dart`)

```
getToken()           → iPlanetDirectoryPro token
GET sso.jsp          → 302 → loc0  (slbsso domain)
GET loc0             → 302 → loc1  (slbsso domain)
GET ccmoon+loc1      → 302, body has <a href="...saml...">  (ccmoon domain)
rawHttpsGet(samlUrl) → 200 with HTML form containing SAMLResponse
POST SAMLResponse    → 302 → webtop
GET webtop           → extract baseurl JS var
genF5St()            → rewrite F5_ST to long-lived
migrate cookies → CookieJar → new dio+CookieManager for WebPrint API
```

### Cookie domain isolation (critical invariant)

Two separate cookie stores are maintained during SSO — this mirrors how Python's `requests.Session` handles domain scoping:

- `slbssoCookies`: sent **only** to `slbsso.meijo-u.ac.jp` (holds `iPlanetDirectoryPro` + SSO response cookies)
- `manualCookies`: sent **only** to `ccmoon2.meijo-u.ac.jp` (holds `iPlanetDirectoryPro` + ccmoon cookies, migrated to `CookieJar` post-auth)

`iPlanetDirectoryPro` is seeded into **both** stores at the start. Cookies set by ccmoon responses (`manualCookies`) are never sent back to slbsso and vice versa.

### SAML URL invariant

The `Location` header from the ccmoon 302 (step 3 above) is passed **verbatim** to `rawHttpsGet`. Any Dart `Uri.parse`/`dio` path would normalize percent-encoded unreserved characters, altering the query byte sequence that the SAML signature was computed over and causing verification to fail. `rawHttpsGet` writes the raw URL directly into the HTTP/1.1 request line via `SecureSocket`.

### WebPrint (`lib/features/webprint/`)

`webprint_service.dart` contains `WebPrint` and `PrintFormat`:
- `WebPrint.initialize()` — fetches print page, authenticates with RSA-encrypted credentials, resolves client IP
- `WebPrint.pdfPrint()` — multipart POST of PDF + format JSON; auto-injects `user_id` and `ip` captured during `initialize()`
- `encripter.dart` — RSA PKCS#1 v1.5 encryption (JSEncrypt-compatible, **not** OAEP) via `pointycastle`

The `baseurl` (e.g. `/f5-w-<hex>$$/`) is extracted from Webtop HTML at login time; it encodes the upstream hostname in hex for the F5 BIG-IP reverse proxy. Falls back to `CcmoonSecrets.defaultBaseurl` (built from the `CCMOON_BACKEND_URL_HEX` dart-define) if extraction fails. The Webtop HTML contains multiple `var ur_baseurl` entries for different services; `_extractBaseurl` filters them with `CCMOON_BACKEND_FILTER_HEX` to pick the print backend specifically — without the filter, it may pick a localhost/dev entry and all WebPrint API calls will 302. **Hex values are not committed**: copy `ccmoon_secrets.example.json` to `ccmoon_secrets.json` (gitignored) and fill in the values, then pass via `--dart-define-from-file=ccmoon_secrets.json`.

`WebtopList` (`webtop_list.dart`) provides URL builders (`urlPrint`, `urlMac`, etc.) built from `hostname` + `baseurl`; `webprint_service.dart` uses `WebtopConst.host` (same hostname constant) for all API calls.

### UI (`lib/ui/`)

Pure Cupertino widgets, no Material. Four pages:
- `PrintTestPage` — credential entry, PDF picker, print settings summary, launch button; auto-saves/loads credentials via `CredentialStore`; navigation bar button opens `JobHistoryPage`
- `PrintSettingsPage` — paper size, duplex, orientation, copies, n-up
- `PrintProgressPage` — step-by-step status display driven by the async `_run()` method
- `JobHistoryPage` — `CupertinoTabScaffold` with two bottom tabs:
  - **履歴** (`_JobHistoriesPage`) — searches `api/job/histories/search` with date range + status filters; month picker via `CupertinoDatePicker` in a modal popup
  - **印刷状況** (`_PrintStatusPage`) — searches `api/job/prints/search` with job-status filters (受付中/指示待ち/出力待ち/出力中/出力完了/受付中(Web))

`AppColors` — all colors defined as `CupertinoDynamicColor` for dark mode support.

### PDF sharing (`lib/features/sharing/`)

`SharedPdfService` bridges the OS share sheet to Flutter via `MethodChannel('com.example.campusPrintKun/sharing')`:
- **iOS** — `ios/Runner/SceneDelegate.swift` (`FlutterSceneDelegate` subclass) catches `scene(_:openURLContexts:)` and `willConnectTo`. The engine may not be initialized yet when `willConnectTo` fires, so the URL is buffered in `pendingPdfPath` and flushed in `sceneDidBecomeActive` once the channel is set up. `Info.plist` must declare `CFBundleDocumentTypes` for `com.adobe.pdf` with `LSHandlerRank=Alternate`.
- **Android** — `android/…/MainActivity.kt` handles `ACTION_VIEW` and `ACTION_SEND` intents, copies the PDF to the app's cache dir via `ContentResolver`, and sends the path over the channel. `queryDisplayName()` resolves the real filename from `OpenableColumns.DISPLAY_NAME` before falling back to `lastPathSegment`.
- **Dart** — `SharedPdfService.init()` (called in `main()` before `runApp`) registers the method call handler. `PrintTestPage` calls `getInitialSharedPdf()` in `initState` (cold-start pull) and subscribes to `onSharedPdf` (warm-start push).

### Credential storage (`lib/features/auth/`)

`CredentialStore` wraps `flutter_secure_storage` (Keychain on iOS/macOS). Credentials are saved automatically when the user initiates a print job and loaded on startup. No opt-in toggle.

## Key dependencies

| Package | Purpose |
|---|---|
| `dio` + `dio_cookie_manager` | HTTP client + automatic cookie handling post-auth |
| `cookie_jar` | Cookie storage for the authenticated session |
| `flutter_secure_storage` | Keychain/EncryptedSharedPreferences for credentials |
| `file_picker` | PDF file selection |
| `pointycastle` + `basic_utils` | RSA encryption for WebPrint auth |
| `html` | SAML form parsing from HTML response |
| `intl` + `flutter_localizations` | i18n (ja/en); ARB files in `lib/l10n/` |

## Debugging SAML

To capture raw HTTP with mitmproxy:
1. `brew install mitmproxy && mitmweb`
2. Import mitmproxy CA into macOS Keychain (System, Always Trust) and Firefox cert store
3. `flutter run --dart-define=HTTP_PROXY_HOST=127.0.0.1:8080`
4. Check the Raw tab in mitmweb to verify `%23` vs `#` in SAML query params

`rawHttpsGet` supports proxy via HTTP CONNECT tunneling when `HTTP_PROXY_HOST` is set.
