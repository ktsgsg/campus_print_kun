# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this app does

**Campus Print Kun** is an iOS/macOS Flutter app that lets Meijo University students submit print jobs to the university's CC Moon print service from their own device. It automates a multi-step SSO → WebPrint flow that normally requires a campus browser session.

## Commands

```bash
# Run on iOS simulator
flutter run

# Run with mitmproxy for SAML/HTTP debugging
flutter run --dart-define=HTTP_PROXY_HOST=127.0.0.1:8080

# Build for iOS
flutter build ios

# Lint / analyze
flutter analyze

# Run tests
flutter test

# Run a single test file
flutter test test/widget_test.dart
```

## Architecture

### Authentication flow (`lib/features/ccmoon/`)

The SSO flow is the core complexity of this app. It mirrors the Python original exactly:

1. **`auth_token.dart`** — POST to `slbsso.meijo-u.ac.jp/opensso/json/authenticate` to get `iPlanetDirectoryPro` token
2. **`connect_ccmoon.dart`** — Drives the full SSO → SAML → CC Moon session chain, returns `CcMoonSession`
3. **`raw_http.dart`** — `rawHttpsGet()`: sends HTTPS GET via `SecureSocket` without going through `Uri.parse`. **This is critical**: Dart's `Uri.parse` normalizes percent-encoded unreserved chars (`%2E`→`.`, `%2D`→`-`), which changes the SAML query byte sequence and breaks signature verification. This function must be used for the SAML redirect GET.
4. **`f5_st.dart`** — Rewrites the F5 BIG-IP `F5_ST` cookie to a long-lived version
5. **`debug_proxy.dart`** — `applyDebugProxy(dio)`: applies `HTTP_PROXY_HOST` dart-define to a dio instance for mitmproxy capture. Called on both `ssoClient` and the post-auth `dio`.

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

The `baseurl` (e.g. `/f5-w-68747470733a2f2f.../`) is extracted from Webtop HTML at login time; it encodes the upstream hostname in hex for the F5 BIG-IP reverse proxy. Falls back to `_defaultBaseurl` constant if extraction fails.

### UI (`lib/ui/`)

Pure Cupertino widgets, no Material. Three pages:
- `PrintTestPage` — credential entry, PDF picker, print settings summary, launch button; auto-saves/loads credentials via `CredentialStore`
- `PrintSettingsPage` — paper size, duplex, orientation, copies, n-up
- `PrintProgressPage` — step-by-step status display driven by the async `_run()` method

`AppColors` — all colors defined as `CupertinoDynamicColor` for dark mode support.

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

## Debugging SAML

To capture raw HTTP with mitmproxy:
1. `brew install mitmproxy && mitmweb`
2. Import mitmproxy CA into macOS Keychain (System, Always Trust) and Firefox cert store
3. `flutter run --dart-define=HTTP_PROXY_HOST=127.0.0.1:8080`
4. Check the Raw tab in mitmweb to verify `%23` vs `#` in SAML query params

`rawHttpsGet` supports proxy via HTTP CONNECT tunneling when `HTTP_PROXY_HOST` is set.
