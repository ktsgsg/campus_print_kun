# キャンパスプリントくん

名城大学の CC Moon Web プリントサービスへ、スマートフォンから直接 PDF を送信できる iOS / Android アプリです。

通常はキャンパスのブラウザ操作が必要な SSO → WebPrint フローを自動化します。

---

## 機能

- **PDF 印刷** — ファイルアプリや他のアプリからの共有経由で PDF を選択し、印刷ジョブを送信
- **印刷設定** — 用紙サイズ（A4/A3）・両面印刷・部数・N アップ印刷などを設定
- **印刷履歴** — 月別・ステータス別に過去の印刷ジョブを検索
- **印刷状況** — 現在キューにあるジョブのリアルタイム確認
- **認証情報の保存** — Keychain（iOS）/ EncryptedSharedPreferences（Android）に安全に保存
- **日英対応** — システム言語に応じて日本語 / 英語を自動切替

## 動作環境

| プラットフォーム | 最低バージョン |
|---|---|
| iOS | 14.0 以上 |
| Android | API 21 (Android 5.0) 以上 |

## ビルド方法

```bash
# 依存パッケージの取得
flutter pub get

# iOS シミュレータで実行
flutter run

# 実機 (iOS)
flutter run --release

# Android
flutter run -d android
```

### mitmproxy でネットワークをデバッグする場合

```bash
flutter run --dart-define=HTTP_PROXY_HOST=127.0.0.1:8080
```

## プロジェクト構成

```
lib/
├── features/
│   ├── auth/          認証情報の保存（Keychain）
│   ├── ccmoon/        CC Moon SSO 認証フロー
│   ├── sharing/       OS シェアシート連携
│   └── webprint/      WebPrint API クライアント
├── l10n/              国際化リソース（ARB）
└── ui/                画面（Cupertino ウィジェット）
```

## ライセンス

MIT
