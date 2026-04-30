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
}
