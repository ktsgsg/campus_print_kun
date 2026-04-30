import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
  ];

  /// Application title shown in the navigation bar
  ///
  /// In en, this message translates to:
  /// **'Campus Print Kun'**
  String get appTitle;

  /// No description provided for @userIdLabel.
  ///
  /// In en, this message translates to:
  /// **'User ID'**
  String get userIdLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @pdfNotSelected.
  ///
  /// In en, this message translates to:
  /// **'No PDF selected'**
  String get pdfNotSelected;

  /// No description provided for @selectPdfButton.
  ///
  /// In en, this message translates to:
  /// **'Select PDF'**
  String get selectPdfButton;

  /// No description provided for @printSettingsButton.
  ///
  /// In en, this message translates to:
  /// **'Print settings'**
  String get printSettingsButton;

  /// No description provided for @running.
  ///
  /// In en, this message translates to:
  /// **'Running...'**
  String get running;

  /// No description provided for @startPrint.
  ///
  /// In en, this message translates to:
  /// **'Start printing'**
  String get startPrint;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @inputError.
  ///
  /// In en, this message translates to:
  /// **'Input error'**
  String get inputError;

  /// No description provided for @credentialRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your user ID and password'**
  String get credentialRequired;

  /// No description provided for @pdfRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select a PDF'**
  String get pdfRequired;

  /// No description provided for @duplexOn.
  ///
  /// In en, this message translates to:
  /// **'Duplex'**
  String get duplexOn;

  /// No description provided for @duplexOff.
  ///
  /// In en, this message translates to:
  /// **'Simplex'**
  String get duplexOff;

  /// No description provided for @summaryFormat.
  ///
  /// In en, this message translates to:
  /// **'{paper} ・ {duplex} ・ {copies} copies ・ {numberUp}-up'**
  String summaryFormat(
    String paper,
    String duplex,
    String copies,
    String numberUp,
  );

  /// No description provided for @printSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Print settings'**
  String get printSettingsTitle;

  /// No description provided for @resetDefaults.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetDefaults;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @settingsSectionHeader.
  ///
  /// In en, this message translates to:
  /// **'Print options'**
  String get settingsSectionHeader;

  /// No description provided for @settingsSectionFooter.
  ///
  /// In en, this message translates to:
  /// **'queue_id, color_mode_type, etc. are fixed values.'**
  String get settingsSectionFooter;

  /// No description provided for @paperSize.
  ///
  /// In en, this message translates to:
  /// **'Paper size'**
  String get paperSize;

  /// No description provided for @duplexPrinting.
  ///
  /// In en, this message translates to:
  /// **'Duplex'**
  String get duplexPrinting;

  /// No description provided for @duplexNo.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get duplexNo;

  /// No description provided for @duplexYes.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get duplexYes;

  /// No description provided for @printOrientation.
  ///
  /// In en, this message translates to:
  /// **'Orientation'**
  String get printOrientation;

  /// No description provided for @longEdge.
  ///
  /// In en, this message translates to:
  /// **'Long edge'**
  String get longEdge;

  /// No description provided for @shortEdge.
  ///
  /// In en, this message translates to:
  /// **'Short edge'**
  String get shortEdge;

  /// No description provided for @pageSort.
  ///
  /// In en, this message translates to:
  /// **'Page sort'**
  String get pageSort;

  /// No description provided for @horizontalLayout.
  ///
  /// In en, this message translates to:
  /// **'Horizontal'**
  String get horizontalLayout;

  /// No description provided for @verticalLayout.
  ///
  /// In en, this message translates to:
  /// **'Vertical'**
  String get verticalLayout;

  /// No description provided for @copies.
  ///
  /// In en, this message translates to:
  /// **'Copies'**
  String get copies;

  /// No description provided for @numberUp.
  ///
  /// In en, this message translates to:
  /// **'N-up'**
  String get numberUp;

  /// No description provided for @stepConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect to CC Moon'**
  String get stepConnect;

  /// No description provided for @stepAuth.
  ///
  /// In en, this message translates to:
  /// **'WebPrint authentication'**
  String get stepAuth;

  /// No description provided for @stepSendPdf.
  ///
  /// In en, this message translates to:
  /// **'Send PDF'**
  String get stepSendPdf;

  /// No description provided for @stepDone.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get stepDone;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success!'**
  String get success;

  /// No description provided for @printJobSent.
  ///
  /// In en, this message translates to:
  /// **'Print job sent'**
  String get printJobSent;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'status: {status}'**
  String statusLabel(String status);

  /// No description provided for @printing.
  ///
  /// In en, this message translates to:
  /// **'Printing...'**
  String get printing;

  /// No description provided for @pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait'**
  String get pleaseWait;

  /// No description provided for @printStatus.
  ///
  /// In en, this message translates to:
  /// **'Print status'**
  String get printStatus;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
