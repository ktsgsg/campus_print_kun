// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'キャンパスプリントくん';

  @override
  String get userIdLabel => 'ユーザID';

  @override
  String get passwordLabel => 'パスワード';

  @override
  String get pdfNotSelected => 'PDF が未選択';

  @override
  String get selectPdfButton => 'PDFを選択';

  @override
  String get printSettingsButton => '印刷設定';

  @override
  String get running => '実行中...';

  @override
  String get startPrint => '印刷開始';

  @override
  String get ok => 'OK';

  @override
  String get inputError => '入力エラー';

  @override
  String get credentialRequired => 'ユーザID / パスワードを入力してください';

  @override
  String get pdfRequired => 'PDF を選択してください';

  @override
  String get duplexOn => '両面';

  @override
  String get duplexOff => '片面';

  @override
  String summaryFormat(
    String paper,
    String duplex,
    String copies,
    String numberUp,
  ) {
    return '$paper・$duplex・$copies部・${numberUp}up';
  }

  @override
  String get printSettingsTitle => '印刷設定';

  @override
  String get resetDefaults => '規定値に戻す';

  @override
  String get apply => '適用';

  @override
  String get settingsSectionHeader => 'プリント設定';

  @override
  String get settingsSectionFooter => 'queue_id や color_mode_type などは固定値です。';

  @override
  String get paperSize => '用紙サイズ';

  @override
  String get duplexPrinting => '両面印刷';

  @override
  String get duplexNo => 'なし';

  @override
  String get duplexYes => 'あり';

  @override
  String get printOrientation => '印刷向き';

  @override
  String get longEdge => '長辺';

  @override
  String get shortEdge => '短辺';

  @override
  String get pageSort => 'ページ順';

  @override
  String get horizontalLayout => '横';

  @override
  String get verticalLayout => '縦';

  @override
  String get copies => '部数';

  @override
  String get numberUp => '割付';

  @override
  String get stepConnect => 'CC Moon に接続';

  @override
  String get stepAuth => 'Webプリント認証';

  @override
  String get stepSendPdf => 'PDF 送信';

  @override
  String get stepDone => '完了';

  @override
  String get failed => '失敗';

  @override
  String get success => '成功！';

  @override
  String get printJobSent => '印刷ジョブを送信しました';

  @override
  String statusLabel(String status) {
    return 'ステータス: $status';
  }

  @override
  String get printing => '印刷中...';

  @override
  String get pleaseWait => 'このままお待ちください';

  @override
  String get printStatus => '印刷状況';

  @override
  String get close => '閉じる';

  @override
  String get historyTitle => '履歴';

  @override
  String get filterPeriod => '期間';

  @override
  String get filterStartMonth => '開始月';

  @override
  String get filterEndMonth => '終了月';

  @override
  String get filterStatusType => '表示種別';

  @override
  String get pickerCancel => 'キャンセル';

  @override
  String get pickerDone => '完了';

  @override
  String get statusNormal => '正常';

  @override
  String get statusError => 'エラー';

  @override
  String get statusCancelLabel => 'キャンセル';

  @override
  String get statusDeleteBat => 'システム削除(bat)';

  @override
  String get statusDeleteJob => 'システム削除(job)';

  @override
  String get statusAccepting => '受付中';

  @override
  String get statusOrderWait => '指示待ち';

  @override
  String get statusOutputWait => '出力待ち';

  @override
  String get statusOutputting => '出力中';

  @override
  String get statusEndLabel => '出力完了';

  @override
  String get statusAcceptingWeb => '受付中(Web)';

  @override
  String get searchButton => '検索';

  @override
  String get searchingLabel => '検索中...';

  @override
  String get searchPlaceholder => '検索結果がここに表示されます';

  @override
  String get noJobsFound => '該当するジョブはありません';

  @override
  String resultCount(int count) {
    return '$count 件';
  }

  @override
  String monthYearLabel(int year, int month) {
    return '$year年$month月';
  }

  @override
  String get previewFront => '表';

  @override
  String get previewBack => '裏';

  @override
  String previewSheetIndicator(int current, int total) {
    return '$current / $total 枚';
  }

  @override
  String get previewNoPdf => 'PDF を選択するとプレビューが表示されます';

  @override
  String get previewBindLong => '長辺綴じ';

  @override
  String get previewBindShort => '短辺綴じ';
}
