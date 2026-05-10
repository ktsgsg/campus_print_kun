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

| プラットフォーム | 最低バージョン            |
| ---------------- | ------------------------- |
| iOS              | 14.0 以上                 |
| Android          | API 21 (Android 5.0) 以上 |

## ビルド方法

### 1. 依存パッケージの取得

```bash
flutter pub get
```


### 3. 起動

```bash
# iOS シミュレータ
flutter run --dart-define-from-file=ccmoon_secrets.json

# 実機 (iOS) リリースビルド
flutter run --release --dart-define-from-file=ccmoon_secrets.json

# Android
flutter run -d android --dart-define-from-file=ccmoon_secrets.json
```

### l10n を変更した場合

`lib/l10n/app_en.arb` / `app_ja.arb` を編集後、生成済み Dart ファイルを再生成：

```bash
flutter gen-l10n
```

### mitmproxy でネットワークをデバッグする場合

```bash
flutter run \
  --dart-define-from-file=ccmoon_secrets.json \
  --dart-define=HTTP_PROXY_HOST=127.0.0.1:8080
```

`HTTP_PROXY_HOST` はデバッグ／プロファイルビルド時のみ有効で、リリースビルドでは `kReleaseMode` ガードにより無視されます。

## プロジェクト構成

```
lib/
├── data/
│   └── repositories/  API 呼び出しを集約するリポジトリ
├── domain/
│   └── models/        ドメインモデル（PrintJob 等）
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
