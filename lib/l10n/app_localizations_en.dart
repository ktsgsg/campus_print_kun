// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Campus Print Kun';

  @override
  String get userIdLabel => 'User ID';

  @override
  String get passwordLabel => 'Password';

  @override
  String get pdfNotSelected => 'No PDF selected';

  @override
  String get selectPdfButton => 'Select PDF';

  @override
  String get printSettingsButton => 'Print settings';

  @override
  String get running => 'Running...';

  @override
  String get startPrint => 'Start printing';

  @override
  String get ok => 'OK';

  @override
  String get inputError => 'Input error';

  @override
  String get credentialRequired => 'Please enter your user ID and password';

  @override
  String get pdfRequired => 'Please select a PDF';

  @override
  String get duplexOn => 'Duplex';

  @override
  String get duplexOff => 'Simplex';

  @override
  String summaryFormat(
    String paper,
    String duplex,
    String copies,
    String numberUp,
  ) {
    return '$paper ・ $duplex ・ $copies copies ・ $numberUp-up';
  }

  @override
  String get printSettingsTitle => 'Print settings';

  @override
  String get resetDefaults => 'Reset';

  @override
  String get apply => 'Apply';

  @override
  String get settingsSectionHeader => 'Print options';

  @override
  String get settingsSectionFooter =>
      'queue_id, color_mode_type, etc. are fixed values.';

  @override
  String get paperSize => 'Paper size';

  @override
  String get duplexPrinting => 'Duplex';

  @override
  String get duplexNo => 'Off';

  @override
  String get duplexYes => 'On';

  @override
  String get printOrientation => 'Orientation';

  @override
  String get longEdge => 'Long edge';

  @override
  String get shortEdge => 'Short edge';

  @override
  String get pageSort => 'Page sort';

  @override
  String get horizontalLayout => 'Horizontal';

  @override
  String get verticalLayout => 'Vertical';

  @override
  String get copies => 'Copies';

  @override
  String get numberUp => 'N-up';

  @override
  String get stepConnect => 'Connect to CC Moon';

  @override
  String get stepAuth => 'WebPrint authentication';

  @override
  String get stepSendPdf => 'Send PDF';

  @override
  String get stepDone => 'Complete';

  @override
  String get failed => 'Failed';

  @override
  String get success => 'Success!';

  @override
  String get printJobSent => 'Print job sent';

  @override
  String statusLabel(String status) {
    return 'status: $status';
  }

  @override
  String get printing => 'Printing...';

  @override
  String get pleaseWait => 'Please wait';

  @override
  String get printStatus => 'Print status';

  @override
  String get close => 'Close';

  @override
  String get historyTitle => 'History';

  @override
  String get filterPeriod => 'Period';

  @override
  String get filterStartMonth => 'Start month';

  @override
  String get filterEndMonth => 'End month';

  @override
  String get filterStatusType => 'Status';

  @override
  String get pickerCancel => 'Cancel';

  @override
  String get pickerDone => 'Done';

  @override
  String get statusNormal => 'Normal';

  @override
  String get statusError => 'Error';

  @override
  String get statusCancelLabel => 'Cancel';

  @override
  String get statusDeleteBat => 'Auto delete (bat)';

  @override
  String get statusDeleteJob => 'Auto delete (job)';

  @override
  String get statusAccepting => 'Accepting';

  @override
  String get statusOrderWait => 'Awaiting order';

  @override
  String get statusOutputWait => 'Output wait';

  @override
  String get statusOutputting => 'Outputting';

  @override
  String get statusEndLabel => 'Output done';

  @override
  String get statusAcceptingWeb => 'Accepting (Web)';

  @override
  String get searchButton => 'Search';

  @override
  String get searchingLabel => 'Searching...';

  @override
  String get searchPlaceholder => 'Search results will appear here';

  @override
  String get noJobsFound => 'No jobs found';

  @override
  String resultCount(int count) {
    return '$count results';
  }

  @override
  String monthYearLabel(int year, int month) {
    return '$month/$year';
  }

  @override
  String get previewFront => 'Front';

  @override
  String get previewBack => 'Back';

  @override
  String previewSheetIndicator(int current, int total) {
    return '$current / $total sheets';
  }

  @override
  String get previewNoPdf => 'Select a PDF to see the preview';
}
